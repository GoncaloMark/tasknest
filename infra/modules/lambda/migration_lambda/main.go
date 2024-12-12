package main

import (
	"context"
	"database/sql"
	"embed"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/secretsmanager"
	"github.com/aws/aws-sdk-go-v2/service/ssm"
	"github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	"github.com/golang-migrate/migrate/v4/source/iofs"
)

//go:embed migrations/*.sql
var migrationFiles embed.FS

// Secrets structure to match JSON format in Secrets Manager
type Secrets struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

// getDBCredentials retrieves database credentials from AWS Secrets Manager
func getDBCredentials(ctx context.Context, secretName string) (string, string, error) {
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		return "", "", fmt.Errorf("unable to load SDK config: %v", err)
	}

	client := secretsmanager.NewFromConfig(cfg)
	input := &secretsmanager.GetSecretValueInput{
		SecretId: &secretName,
	}

	result, err := client.GetSecretValue(ctx, input)
	if err != nil {
		return "", "", fmt.Errorf("error retrieving secret: %v", err)
	}

	var secrets Secrets
	if err := json.Unmarshal([]byte(*result.SecretString), &secrets); err != nil {
		return "", "", fmt.Errorf("error parsing secret: %v", err)
	}

	return secrets.Username, secrets.Password, nil
}

// getSSMParameter retrieves parameter from AWS Systems Manager Parameter Store
func getSSMParameter(ctx context.Context, parameterName string) (string, error) {
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		return "", fmt.Errorf("unable to load SDK config: %v", err)
	}

	client := ssm.NewFromConfig(cfg)
	input := &ssm.GetParameterInput{
		Name:           &parameterName,
		WithDecryption: aws.Bool(true),
	}

	result, err := client.GetParameter(ctx, input)
	if err != nil {
		return "", fmt.Errorf("error retrieving parameter: %v", err)
	}

	return *result.Parameter.Value, nil
}

// runMigrations handles database migrations using go-migrate with embedded files
func runMigrations(connStr string) error {
	// Open database connection
	db, err := sql.Open("postgres", connStr)
	if err != nil {
		return fmt.Errorf("failed to open database: %v", err)
	}
	defer db.Close()

	// Create driver for the database
	driver, err := postgres.WithInstance(db, &postgres.Config{})
	if err != nil {
		return fmt.Errorf("failed to create postgres driver: %v", err)
	}

	// Create source driver from embedded files
	source, err := iofs.New(migrationFiles, "migrations")
	if err != nil {
		return fmt.Errorf("failed to create source driver: %v", err)
	}

	// Create migrate instance
	m, err := migrate.NewWithInstance(
		"iofs",
		source,
		"postgres",
		driver,
	)
	if err != nil {
		return fmt.Errorf("failed to create migrate instance: %v", err)
	}
	defer m.Close()

	// Run migrations
	if err := m.Up(); err != nil && err != migrate.ErrNoChange {
		return fmt.Errorf("migration failed: %v", err)
	}

	return nil
}

// Handler is the Lambda function handler
func Handler(ctx context.Context) (map[string]interface{}, error) {
	// Get configuration from environment variables
	secretName := os.Getenv("DB_SECRET_NAME")

	// Retrieve credentials and parameters
	username, password, err := getDBCredentials(ctx, secretName)
	if err != nil {
		return nil, fmt.Errorf("error getting credentials: %v", err)
	}

	host, err := getSSMParameter(ctx, "rds_endpoint")
	if err != nil {
		return nil, fmt.Errorf("error getting host: %v", err)
	}
	parts := strings.Split(host, ":")

	dbName, err := getSSMParameter(ctx, "db_name")
	if err != nil {
		return nil, fmt.Errorf("error getting database name: %v", err)
	}

	// Construct connection string
	connStr := fmt.Sprintf("postgres://%s:%s@%s:5432/%s?sslmode=require",
		username, password, parts[0], dbName)

	// Run migrations
	if err := runMigrations(connStr); err != nil {
		return nil, fmt.Errorf("error running migrations: %v", err)
	}

	log.Println("Database migrations completed successfully")
	return map[string]interface{}{
		"statusCode": 200,
		"body":       "Database migrations completed successfully",
	}, nil
}

func main() {
	lambda.Start(Handler)
}
