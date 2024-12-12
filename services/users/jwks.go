package main

import (
	"crypto/rsa"
	"encoding/base64"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"math/big"
	"net/http"
	"sync"
	"time"
)

type JWKS struct {
	Keys []JWK `json:"keys"`
}

type JWK struct {
	Kid string `json:"kid"`
	Alg string `json:"alg"`
	Kty string `json:"kty"`
	E   string `json:"e"`
	N   string `json:"n"`
	Use string `json:"use"`
}

var jwksCache struct {
	keys map[string]*rsa.PublicKey
	mu   sync.RWMutex
	exp  time.Time
}

func getPublicKeyFromJWKS(jwksURL, kid string) (*rsa.PublicKey, error) {
	// Check cache first
	jwksCache.mu.RLock()
	if jwksCache.exp.After(time.Now()) {
		if key, exists := jwksCache.keys[kid]; exists {
			jwksCache.mu.RUnlock()
			return key, nil
		}
	}
	jwksCache.mu.RUnlock()

	// Cache miss or expired, fetch new JWKS
	jwksCache.mu.Lock()
	defer jwksCache.mu.Unlock()

	// Double-check after acquiring write lock
	if jwksCache.exp.After(time.Now()) {
		if key, exists := jwksCache.keys[kid]; exists {
			return key, nil
		}
	}

	// Fetch JWKS from Cognito
	resp, err := http.Get(jwksURL)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch JWKS: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("failed to fetch JWKS: status code %d", resp.StatusCode)
	}

	var jwks JWKS
	if err := json.NewDecoder(resp.Body).Decode(&jwks); err != nil {
		return nil, fmt.Errorf("failed to decode JWKS: %v", err)
	}

	// Create new cache
	jwksCache.keys = make(map[string]*rsa.PublicKey)
	jwksCache.exp = time.Now().Add(24 * time.Hour) // Cache for 24 hours

	// Parse all keys in the JWKS
	for _, key := range jwks.Keys {
		if key.Kty != "RSA" {
			continue // Skip non-RSA keys
		}

		// Decode the modulus (n) and exponent (e)
		nBytes, err := base64.RawURLEncoding.DecodeString(key.N)
		if err != nil {
			continue
		}

		eBytes, err := base64.RawURLEncoding.DecodeString(key.E)
		if err != nil {
			continue
		}

		// Convert exponent bytes to int
		var eInt uint64
		switch len(eBytes) {
		case 4:
			eInt = uint64(binary.BigEndian.Uint32(eBytes))
		case 8:
			eInt = binary.BigEndian.Uint64(eBytes)
		default:
			// Handle non-standard exponent size
			var e big.Int
			e.SetBytes(eBytes)
			if !e.IsUint64() {
				continue
			}
			eInt = e.Uint64()
		}

		// Create RSA public key
		pubKey := &rsa.PublicKey{
			N: new(big.Int).SetBytes(nBytes),
			E: int(eInt),
		}

		jwksCache.keys[key.Kid] = pubKey
	}

	// Return requested key
	if key, exists := jwksCache.keys[kid]; exists {
		return key, nil
	}

	return nil, fmt.Errorf("key ID %s not found in JWKS", kid)
}
