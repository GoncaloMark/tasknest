package main

import (
	"time"

	"github.com/google/uuid"

	_ "github.com/jinzhu/gorm/dialects/postgres"
)

type User struct {
	UserID uuid.UUID `gorm:"primary_key;type:uuid;default:uuid_generate_v4()"`
	Email  string    `gorm:"not null;unique"`
}

type Task struct {
	TaskID       uuid.UUID  `gorm:"type:uuid;default:uuid_generate_v4();primary_key" json:"task_id"`
	UserID       uuid.UUID  `gorm:"type:uuid;not null" json:"user_id"`
	Title        string     `gorm:"size:50;not null" json:"title"`
	Description  string     `gorm:"type:text" json:"description"`
	CreationDate time.Time  `gorm:"type:date;default:current_date;not null" json:"creation_date"`
	Deadline     *time.Time `gorm:"type:date" json:"deadline"`
	Status       string     `gorm:"type:enum('TODO', 'IN_PROGRESS', 'DONE');not null" json:"status"`
	Priority     string     `gorm:"type:enum('LOW', 'MEDIUM', 'HIGH');not null" json:"priority"`
	User         User       `gorm:"foreignkey:UserID;references:UserID" json:"user"`
}
