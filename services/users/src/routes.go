package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/cognitoidentityprovider"
	"github.com/aws/aws-sdk-go-v2/service/cognitoidentityprovider/types"
	"github.com/golang-jwt/jwt"
)

func handleHealthCheck(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
}

func handleAuthCheck(w http.ResponseWriter, r *http.Request) {
	// Get the ID token from cookies
	idTokenCookie, err := r.Cookie("id_token")
	if err != nil {
		// No ID token found, user is not logged in
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"isAuthenticated": false,
			"error":           "No authentication token found",
		})
		return
	}

	// Verify the ID token
	claims, err := verifyIDToken(idTokenCookie.Value)
	if err != nil {
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"isAuthenticated": false,
			"error":           "Invalid or expired token",
		})
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"isAuthenticated": true,
		"user": map[string]interface{}{
			"email": claims["email"],
		},
	})
}

func handleCognitoCallback(w http.ResponseWriter, r *http.Request) {
	code := r.URL.Query().Get("code")
	if code == "" {
		http.Error(w, "Authorization code missing", http.StatusBadRequest)
		return
	}

	tokenURL := fmt.Sprintf("https://%s/oauth2/token", cognitoDomain)

	reqBody := url.Values{}
	reqBody.Set("grant_type", "authorization_code")
	reqBody.Set("client_id", clientID)
	reqBody.Set("redirect_uri", redirectURL)
	reqBody.Set("code", code)

	req, err := http.NewRequest("POST", tokenURL, strings.NewReader(reqBody.Encode()))
	if err != nil {
		http.Error(w, "Failed to create token exchange request", http.StatusInternalServerError)
		return
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		http.Error(w, "Failed to send token exchange request", http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		http.Error(w, "Token exchange failed", http.StatusUnauthorized)
		return
	}

	var tokenResponse struct {
		IdToken      string `json:"id_token"`
		AccessToken  string `json:"access_token"`
		RefreshToken string `json:"refresh_token"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&tokenResponse); err != nil {
		http.Error(w, "Failed to decode token response", http.StatusInternalServerError)
		return
	}

	claims, err := verifyIDToken(tokenResponse.IdToken)
	if err != nil {
		http.Error(w, "Failed to parse ID token", http.StatusInternalServerError)
		return
	}

	user := User{
		Email: claims["email"].(string),
	}
	if err := db.Create(&user).Error; err != nil {
		http.Error(w, "Error creating user in database: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// Set tokens as cookies
	http.SetCookie(w, &http.Cookie{
		Name:     "id_token",
		Value:    tokenResponse.IdToken,
		Path:     "/",
		Expires:  time.Now().Add(time.Hour),
		HttpOnly: true,
		Secure:   true,
		SameSite: http.SameSiteStrictMode,
	})
	http.SetCookie(w, &http.Cookie{
		Name:     "refresh_token",
		Value:    tokenResponse.RefreshToken,
		Path:     "/",
		Expires:  time.Now().Add(30 * 24 * time.Hour),
		HttpOnly: true,
		Secure:   true,
		SameSite: http.SameSiteStrictMode,
	})

	http.Redirect(w, r, frontendURL, http.StatusFound)
}

func verifyIDToken(idToken string) (map[string]interface{}, error) {
	jwksURL := fmt.Sprintf("https://cognito-idp.%s.amazonaws.com/%s/.well-known/jwks.json",
		getEnv("AWS_REGION", "us-east-1"),
		userPoolID)

	token, _, err := new(jwt.Parser).ParseUnverified(idToken, jwt.MapClaims{})
	if err != nil {
		return nil, fmt.Errorf("error parsing token: %v", err)
	}

	kid, ok := token.Header["kid"].(string)
	if !ok {
		return nil, fmt.Errorf("kid not found in token header")
	}

	key, err := getPublicKeyFromJWKS(jwksURL, kid)
	if err != nil {
		return nil, fmt.Errorf("error getting public key: %v", err)
	}

	// Verify the token
	token, err = jwt.Parse(idToken, func(token *jwt.Token) (interface{}, error) {
		// Verify signing algorithm
		if _, ok := token.Method.(*jwt.SigningMethodRSA); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return key, nil
	})

	if err != nil {
		return nil, fmt.Errorf("error verifying token: %v", err)
	}

	if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
		if err := claims.Valid(); err != nil {
			return nil, fmt.Errorf("invalid claims: %v", err)
		}

		if !claims.VerifyAudience(clientID, true) {
			return nil, fmt.Errorf("invalid audience")
		}

		expectedIssuer := fmt.Sprintf("https://cognito-idp.%s.amazonaws.com/%s",
			getEnv("AWS_REGION", "us-east-1"),
			userPoolID)
		if !claims.VerifyIssuer(expectedIssuer, true) {
			return nil, fmt.Errorf("invalid issuer")
		}

		return claims, nil
	}

	return nil, fmt.Errorf("invalid token")
}

func handleTokenRefresh(w http.ResponseWriter, r *http.Request) {
	refreshTokenCookie, err := r.Cookie("refresh_token")
	if err != nil {
		http.Error(w, "Refresh token missing", http.StatusUnauthorized)
		return
	}

	input := &cognitoidentityprovider.InitiateAuthInput{
		AuthFlow: types.AuthFlowTypeRefreshTokenAuth,
		ClientId: aws.String(clientID),
		AuthParameters: map[string]string{
			"REFRESH_TOKEN": refreshTokenCookie.Value,
		},
	}

	result, err := cognitoClient.InitiateAuth(r.Context(), input)
	if err != nil {
		http.Error(w, err.Error(), http.StatusUnauthorized)
		return
	}

	http.SetCookie(w, &http.Cookie{
		Name:     "id_token",
		Value:    *result.AuthenticationResult.IdToken,
		Path:     "/",
		Expires:  time.Now().Add(time.Hour),
		HttpOnly: true,
		Secure:   true,
	})

	w.WriteHeader(http.StatusOK)
	fmt.Fprint(w, "Token refreshed successfully!")
}

func handleLogoutCallback(w http.ResponseWriter, r *http.Request) {
	// Delete the authentication cookies
	http.SetCookie(w, &http.Cookie{
		Name:     "id_token",
		Value:    "",
		Path:     "/",
		Expires:  time.Unix(0, 0), // Expire the cookie
		HttpOnly: true,
		Secure:   true,
		SameSite: http.SameSiteStrictMode,
	})
	http.SetCookie(w, &http.Cookie{
		Name:     "refresh_token",
		Value:    "",
		Path:     "/",
		Expires:  time.Unix(0, 0), // Expire the cookie
		HttpOnly: true,
		Secure:   true,
		SameSite: http.SameSiteStrictMode,
	})

	http.Redirect(w, r, frontendURL, http.StatusFound)
}
