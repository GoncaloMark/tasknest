package main

type DBCreds struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

type TaskRequest struct {
	UserID      string  `json:"user_id"`
	Title       string  `json:"title"`
	Description string  `json:"description"`
	Deadline    *string `json:"deadline"`
	Status      string  `json:"status"`
	Priority    string  `json:"priority"`
}

type Filters struct {
	Status   string
	Priority string
	Sort     string
	Order    string
}
