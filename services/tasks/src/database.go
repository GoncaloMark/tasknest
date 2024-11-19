package main

import (
	"log"
	"strings"

	"github.com/jinzhu/gorm"
	_ "github.com/jinzhu/gorm/dialects/postgres"
)

func InitDB(rdsEndpoint, dbUser, dbPassword, dbName string) {
	parts := strings.Split(rdsEndpoint, ":")
	host := parts[0]
	dsn := "host=" + host + " user=" + dbUser + " password=" + dbPassword + " dbname=" + dbName + " port=5432 sslmode=require"
	db, err := gorm.Open("postgres", dsn)
	if err != nil {
		log.Fatal("Failed to connect to the database:", err)
		return
	}

	db.AutoMigrate(&User{})
}
