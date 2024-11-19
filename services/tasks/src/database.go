package main

import (
	"fmt"
	"log"
	"strings"

	"github.com/jinzhu/gorm"
	_ "github.com/jinzhu/gorm/dialects/postgres"
)

func InitDB(rdsEndpoint, dbUser, dbPassword, dbName string) (*gorm.DB, error) {
	parts := strings.Split(rdsEndpoint, ":")

	host := parts[0]
	dsn := fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=5432 sslmode=require",
		host, dbUser, dbPassword, dbName,
	)

	db, err := gorm.Open("postgres", dsn)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to the database: %w", err)
	}

	if err := db.AutoMigrate(&User{}).Error; err != nil {
		return nil, fmt.Errorf("failed to run migrations: %w", err)
	}

	if err := db.DB().Ping(); err != nil {
		return nil, fmt.Errorf("database connection test failed: %w", err)
	}

	log.Println("Database initialized successfully")

	return db, nil
}
