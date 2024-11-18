package main

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/google/uuid"
	"github.com/jinzhu/gorm"
)

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
		http.Error(w, err.Error(), http.StatusInternalServerError)
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

	var task Task
	if err := json.NewDecoder(r.Body).Decode(&task); err != nil {
		http.Error(w, "Invalid input", http.StatusBadRequest)
		return
	}
	var err error
	task.UserID, err = uuid.Parse(userID)
	if err != nil {
		http.Error(w, "Invalid User ID", http.StatusBadRequest)
		return
	}

	task.CreationDate = time.Now()

	if err := db.Create(&task).Error; err != nil {
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

	if err := db.Where("user_id = ? AND task_id = ?", userID, taskID).First(&task).Error; err != nil {
		if gorm.IsRecordNotFoundError(err) {
			http.Error(w, "Task not found", http.StatusNotFound)
		} else {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}
		return
	}

	if err := db.Save(&task).Error; err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
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
			http.Error(w, "Task not found", http.StatusNotFound)
		} else {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}
		return
	}

	w.WriteHeader(http.StatusOK)
}
