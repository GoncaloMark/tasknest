package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
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

// handleHealthCheck godoc
// @Summary Check API health
// @Description Returns OK if the API is running
// @Tags Health
// @Success 200 {string} string "OK"
// @Router /api/health [get]
func handleHealthCheck(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
}

var validSort = map[string]bool{
	"creation_date": true,
	"deadline":      true,
	"priority":      true,
	"status":        true,
}

// handleGetTasks godoc
// @Summary Get tasks for the user
// @Description Retrieve a paginated list of tasks
// @Tags Tasks
// @Param page query int false "Page number"
// @Param limit query int false "Number of items per page"
// @Param status query string false "Filter by status"
// @Param priority query string false "Filter by priority"
// @Param sort query string false "Sort by field"
// @Param order query string false "Order direction (asc/desc)"
// @Success 200 {object} map[string]interface{}
// @Failure 401 {string} string "Unauthorized"
// @Failure 500 {string} string "Internal server error"
// @Router /api/tasks [get]
func handleGetTasks(w http.ResponseWriter, r *http.Request) {
	userID := r.Header.Get("X-User-ID")
	if userID == "" {
		http.Error(w, "Unauthorized User", http.StatusUnauthorized)
		return
	}

	page, limit := getPaginationParams(r)

	// Create a base query
	query := db.Model(&Task{}).Where("user_id = ?", userID)

	qs := r.URL.Query()

	filters := Filters{
		Status:   qs.Get("status"),
		Priority: qs.Get("priority"),
		Sort:     qs.Get("sort"),
		Order:    qs.Get("order"),
	}

	if filters.Status != "" {
		query = query.Where("status = ?", filters.Status)
	}

	if filters.Priority != "" {
		query = query.Where("priority = ?", filters.Priority)
	}

	// Apply ordering
	if filters.Sort != "" && validSort[filters.Sort] {
		query = query.Order(clause.OrderByColumn{
			Column: clause.Column{Name: filters.Sort},
			Desc:   strings.ToLower(filters.Order) == "desc",
		})
	}

	// Count total before pagination
	var total int64
	if err := query.Count(&total).Error; err != nil {
		log.Printf("Error counting tasks: %v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Apply pagination
	var tasks []Task
	if err := query.
		Offset((page - 1) * limit).
		Limit(limit).
		Find(&tasks).Error; err != nil {
		log.Printf("No Tasks Found: %v", err)
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

// @Summary Create a new task
// @Description Create a new task for the authenticated user
// @Tags Tasks
// @Accept json
// @Produce json
// @Param X-User-ID header string true "User ID"
// @Param task body TaskRequest true "Task details"
// @Success 201 {object} Task "Task created successfully"
// @Failure 400 {string} string "Invalid input or date format"
// @Failure 401 {string} string "Unauthorized User"
// @Failure 500 {string} string "Internal Server Error"
// @Router /tasks [post]
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

// @Summary Update an existing task
// @Description Update the details of an existing task for the authenticated user
// @Tags Tasks
// @Accept json
// @Produce json
// @Param X-User-ID header string true "User ID"
// @Param id path string true "Task ID"
// @Param task body Task true "Updated task details"
// @Success 200 {object} Task "Task updated successfully"
// @Failure 400 {string} string "Invalid input"
// @Failure 401 {string} string "Unauthorized User"
// @Failure 404 {string} string "Task not found"
// @Failure 500 {string} string "Internal Server Error"
// @Router /tasks/{id} [put]
func handleUpdateTask(w http.ResponseWriter, r *http.Request) {
	userID := r.Header.Get("X-User-ID")
	if userID == "" {
		http.Error(w, "Unauthorized User", http.StatusUnauthorized)
		return
	}

	taskID := r.PathValue("id")

	var task TaskRequest
	if err := json.NewDecoder(r.Body).Decode(&task); err != nil {
		http.Error(w, "Invalid input", http.StatusBadRequest)
		return
	}

	var existingTask Task
	if err := db.Where("user_id = ? AND task_id = ?", userID, taskID).First(&existingTask).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			log.Printf("Task wasn't found: %v\n", err)
			http.Error(w, "Task not found", http.StatusNotFound)
		} else {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}
		return
	}

	var parsedDeadline *time.Time
	var err error
	if *task.Deadline == "" {
		parsedDeadline = nil
	} else {
		parsedDeadline, err = ParseDate(*task.Deadline)
		if err != nil {
			http.Error(w, "Invalid date format", http.StatusBadRequest)
			return
		}
	}

	existingTask.Title = task.Title
	existingTask.Description = task.Description
	existingTask.Status = task.Status
	existingTask.Priority = task.Priority
	existingTask.Deadline = parsedDeadline

	if err := db.Save(&existingTask).Error; err != nil {
		http.Error(w, "Failed to update task", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(task)
}

// @Summary Delete a task
// @Description Delete a specific task for the authenticated user
// @Tags Tasks
// @Param X-User-ID header string true "User ID"
// @Param id path string true "Task ID"
// @Success 200 {string} string "Task deleted successfully"
// @Failure 401 {string} string "Unauthorized User"
// @Failure 404 {string} string "Task not found"
// @Failure 500 {string} string "Internal Server Error"
// @Router /tasks/{id} [delete]
func handleDeleteTask(w http.ResponseWriter, r *http.Request) {
	userID := r.Header.Get("X-User-ID")
	if userID == "" {
		http.Error(w, "Unauthorized User", http.StatusUnauthorized)
		return
	}

	taskID := r.PathValue("id")

	if err := db.Where("user_id = ? AND task_id = ?", userID, taskID).Delete(&Task{}).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			log.Printf("Task Wasnt't Found: %v\n", err)
			http.Error(w, "Task not found", http.StatusNotFound)
		} else {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}
		return
	}

	w.WriteHeader(http.StatusOK)
}
