package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/google/uuid"
	"github.com/jinzhu/gorm"
)

func ParseDate(dateStr string) (*time.Time, error) {
	var parsedDate time.Time
	var err error

	parsedDate, err = time.Parse(time.RFC3339, dateStr)
	if err == nil {
		return &parsedDate, nil
	}

	parsedDate, err = time.Parse("2006-01-02", dateStr)
	if err == nil {
		parsedDate = parsedDate.UTC()
		return &parsedDate, nil
	}

	return nil, err
}

func getPaginationParams(r *http.Request) (int, int) {
	pageStr := r.URL.Query().Get("page")
	limitStr := r.URL.Query().Get("limit")

	page := 1
	limit := 10

	if pageStr != "" {
		page, _ = strconv.Atoi(pageStr)
	}
	if limitStr != "" {
		limit, _ = strconv.Atoi(limitStr)
	}

	return page, limit
}

func handleHealthCheck(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
}

func handleGetTasks(w http.ResponseWriter, r *http.Request) {
	userID := r.Header.Get("X-User-ID")
	if userID == "" {
		http.Error(w, "Unauthorized User", http.StatusUnauthorized)
		return
	}

	page, limit := getPaginationParams(r)

	var tasks []Task
	var total int64

	if err := db.Model(&Task{}).
		Where("user_id = ?", userID).
		Count(&total).
		Offset((page - 1) * limit).
		Limit(limit).
		Find(&tasks).Error; err != nil {
		log.Printf("No Tasks Found For Use\nr %v", err)
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"tasks": tasks,
		"total": total,
	})
}

func handleCreateTask(w http.ResponseWriter, r *http.Request) {
	userID := r.Header.Get("X-User-ID")
	if userID == "" {
		http.Error(w, "Unauthorized User", http.StatusUnauthorized)
		return
	}

	var taskReq TaskRequest
	if err := json.NewDecoder(r.Body).Decode(&taskReq); err != nil {
		log.Printf("Couldn't decode Body: %v\n", err)
		http.Error(w, "Invalid input", http.StatusBadRequest)
		return
	}
	var err error
	user_id, err := uuid.Parse(userID)
	if err != nil {
		http.Error(w, "Invalid User ID", http.StatusBadRequest)
		return
	}

	var parsedDeadline *time.Time

	if *taskReq.Deadline == "" {
		parsedDeadline = nil
	} else {
		parsedDeadline, err = ParseDate(*taskReq.Deadline)
		if err != nil {
			http.Error(w, "Invalid date format", http.StatusBadRequest)
			return
		}
	}

	var task Task

	if err := db.FirstOrCreate(&task, Task{
		UserID:       user_id,
		CreationDate: time.Now(),
		Status:       taskReq.Status,
		Description:  taskReq.Description,
		Title:        taskReq.Title,
		Deadline:     parsedDeadline,
		Priority:     taskReq.Priority,
	}).Error; err != nil {
		fmt.Printf("Couldn't Create Task: %v\n", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(task)
}

func handleUpdateTask(w http.ResponseWriter, r *http.Request) {
	userID := r.Header.Get("X-User-ID")
	if userID == "" {
		http.Error(w, "Unauthorized User", http.StatusUnauthorized)
		return
	}

	taskID := r.PathValue("id")

	var task Task
	if err := json.NewDecoder(r.Body).Decode(&task); err != nil {
		http.Error(w, "Invalid input", http.StatusBadRequest)
		return
	}

	var existingTask Task
	if err := db.Where("user_id = ? AND task_id = ?", userID, taskID).First(&existingTask).Error; err != nil {
		if gorm.IsRecordNotFoundError(err) {
			log.Printf("Task wasn't found: %v\n", err)
			http.Error(w, "Task not found", http.StatusNotFound)
		} else {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}
		return
	}

	existingTask.Title = task.Title
	existingTask.Description = task.Description
	existingTask.Status = task.Status
	existingTask.Priority = task.Priority
	existingTask.Deadline = task.Deadline

	if err := db.Save(&existingTask).Error; err != nil {
		http.Error(w, "Failed to update task", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(task)
}

func handleDeleteTask(w http.ResponseWriter, r *http.Request) {
	userID := r.Header.Get("X-User-ID")
	if userID == "" {
		http.Error(w, "Unauthorized User", http.StatusUnauthorized)
		return
	}

	taskID := r.PathValue("id")

	if err := db.Where("user_id = ? AND task_id = ?", userID, taskID).Delete(&Task{}).Error; err != nil {
		if gorm.IsRecordNotFoundError(err) {
			log.Printf("Task Wasnt't Found: %v\n", err)
			http.Error(w, "Task not found", http.StatusNotFound)
		} else {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}
		return
	}

	w.WriteHeader(http.StatusOK)
}
