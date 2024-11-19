package main

import (
	"fmt"
	"log"
	"net/http"
	"os"

	"context"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/secretsmanager"
	"github.com/aws/aws-sdk-go-v2/service/ssm"
	"github.com/jinzhu/gorm"
)

var (
	db *gorm.DB
)

func getEnv(key, defaultValue string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return defaultValue
}

func main() {
	ctx := context.Background()
	cfg, err := config.LoadDefaultConfig(ctx,
		config.WithRegion(getEnv("AWS_REGION", "us-east-1")),
	)
	if err != nil {
		log.Fatalf("Failed to create AWS config: %v", err)
	}

	ssmClient := ssm.NewFromConfig(cfg)

	secretsManagerClient := secretsmanager.NewFromConfig(cfg)
	dbCreds, err := getSecretValue(secretsManagerClient, "postgres", ctx)
	if err != nil {
		log.Fatal("Can't get credentials:", err)
	}

	rdsEndpoint := getParameter(ssmClient, "rds_endpoint", ctx)
	dbName := getParameter(ssmClient, "db_name", ctx)

	InitDB(rdsEndpoint, dbCreds.Username, dbCreds.Password, dbName)

	http.HandleFunc("GET /api/tasks/{$}", handleHealthCheck)
	http.HandleFunc("POST /api/tasks/create", handleCreateTask)
	http.HandleFunc("PUT /api/tasks/update/{id}", handleUpdateTask)
	http.HandleFunc("DELETE /api/tasks/delete/{id}", handleDeleteTask)
	http.HandleFunc("GET /api/tasks/read", handleGetTasks)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	fmt.Printf("Starting server on port %s\n", port)
	if err = http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatalf("Failed to create AWS session: %v", err)
	}
}
