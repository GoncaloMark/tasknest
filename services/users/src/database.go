package main

import (
	"log"

	"github.com/jinzhu/gorm"
	_ "github.com/jinzhu/gorm/dialects/postgres"
)

func InitDB(rdsEndpoint, dbUser, dbPassword, dbName string) {
	dsn := "host=" + rdsEndpoint + " user=" + dbUser + " password=" + dbPassword + " dbname=" + dbName + " port=5432 sslmode=require"
	db, err := gorm.Open("postgres", dsn)
	if err != nil {
		log.Fatal("Failed to connect to the database:", err)
		return
	}

	db.AutoMigrate(&User{})
}
