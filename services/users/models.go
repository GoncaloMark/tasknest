package main

import (
	"github.com/google/uuid"
	_ "github.com/jinzhu/gorm/dialects/postgres"
)

type User struct {
	UserID uuid.UUID `gorm:"primary_key;type:uuid;default:uuid_generate_v4()"`
	Email  string    `gorm:"not null;unique"`
}
