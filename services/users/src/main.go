package main

import (
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/cognitoidentityprovider"
	"github.com/aws/aws-sdk-go/service/secretsmanager"
	"github.com/aws/aws-sdk-go/service/ssm"
	"github.com/jinzhu/gorm"
)

var (
	cognitoClient *cognitoidentityprovider.CognitoIdentityProvider
	clientID      string
	cognitoDomain string
	frontendURL   string
	redirectURL   string
	userPoolID    string
	db            *gorm.DB
)

func getEnv(key, defaultValue string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return defaultValue
}

func main() {
	awsSession, err := session.NewSession(&aws.Config{
		Region: aws.String(getEnv("AWS_REGION", "us-east-1")),
	})
	if err != nil {
		log.Fatalf("Failed to create AWS session: %v", err)
	}

	ssmClient := ssm.New(awsSession)
	clientID = getParameter(ssmClient, "cognito_client_id")
	cognitoDomain = getParameter(ssmClient, "cognito_domain")
	frontendURL = getParameter(ssmClient, "frontend_url")
	redirectURL = getParameter(ssmClient, "redirect_uri")
	userPoolID = getParameter(ssmClient, "userpool_id")

	cognitoClient = cognitoidentityprovider.New(awsSession)

	secretsManagerClient := secretsmanager.New(awsSession)
	dbCreds, err := getSecretValue(secretsManagerClient, "postgres")
	if err != nil {
		log.Fatal("Can't get credentials:", err)
	}

	rdsEndpoint := getParameter(ssmClient, "rds_endpoint")
	dbName := getParameter(ssmClient, "db_name")

	InitDB(rdsEndpoint, dbCreds.Username, dbCreds.Password, dbName)

	http.HandleFunc("GET /api/users/{$}", handleHealthCheck)
	http.HandleFunc("/api/users/callback", handleCognitoCallback)
	http.HandleFunc("/api/users/logout", handleLogoutCallback)
	http.HandleFunc("/api/users/auth/check", handleAuthCheck)
	http.HandleFunc("/api/users/refresh", handleTokenRefresh)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	fmt.Printf("Starting server on port %s\n", port)
	if err = http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatalf("Failed to create AWS session: %v", err)
	}
}
