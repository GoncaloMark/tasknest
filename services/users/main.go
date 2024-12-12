package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"context"

	_ "users/docs"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/cognitoidentityprovider"
	"github.com/aws/aws-sdk-go-v2/service/secretsmanager"
	"github.com/aws/aws-sdk-go-v2/service/ssm"
	httpSwagger "github.com/swaggo/http-swagger/v2"
	"gorm.io/gorm"
)

// @title User Management API
// @version 1.0
// @description API for managing Users
// @BasePath /api

var (
	cognitoClient *cognitoidentityprovider.Client
	clientID      string
	cognitoDomain string
	frontendURL   string
	redirectURL   string
	userPoolID    string
	clientSecret  string
	db            *gorm.DB
)

func getEnv(key, defaultValue string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return defaultValue
}

func main() {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	cfg, err := config.LoadDefaultConfig(ctx,
		config.WithRegion(getEnv("AWS_REGION", "us-east-1")),
	)
	if err != nil {
		log.Fatalf("Failed to create AWS config: %v", err)
	}

	ssmClient := ssm.NewFromConfig(cfg)
	clientID = getParameter(ssmClient, "cognito_client_id", ctx)
	cognitoDomain = getParameter(ssmClient, "cognito_domain", ctx)
	frontendURL = getParameter(ssmClient, "frontend_url", ctx)
	redirectURL = getParameter(ssmClient, "redirect_uri", ctx)
	userPoolID = getParameter(ssmClient, "userpool_id", ctx)

	cognitoClient = cognitoidentityprovider.NewFromConfig(cfg)

	secretsManagerClient := secretsmanager.NewFromConfig(cfg)
	val, err := getSecretValue(secretsManagerClient, "postgres", ctx)
	if err != nil {
		log.Fatal("Can't get credentials:", err)
	}

	var creds DBCreds
	if err := json.Unmarshal(val, &creds); err != nil {
		log.Fatalf("unable to parse secret: %v", err)
	}

	rdsEndpoint := getParameter(ssmClient, "rds_endpoint", ctx)
	dbName := getParameter(ssmClient, "db_name", ctx)

	db, err = InitDB(rdsEndpoint, creds.Username, creds.Password, dbName)
	if err != nil {
		log.Fatalf("Error initializing database: %v\n", err)
	}

	sqlDB, err := db.DB()
	if err != nil {
		log.Fatalf("failed to get sql.DB from gorm.DB: %v", err)
	}

	if err := sqlDB.Ping(); err != nil {
		log.Fatalf("database connection test failed: %v", err)
	}

	log.Println("Database initialized successfully")
	defer sqlDB.Close()

	val, err = getSecretValue(secretsManagerClient, "cognitoSecret", ctx)
	if err != nil {
		log.Fatal("Can't get CognitoSecret:", err)
	}
	clientSecret = strings.TrimSpace(string(val))

	http.HandleFunc("GET /api/users/swagger/", httpSwagger.WrapHandler)
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
