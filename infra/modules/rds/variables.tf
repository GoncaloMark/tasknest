# modules/rds/variables.tf

variable "project_name" {
    description = "Project name"
    type        = string
}

variable "db_name" {
    description = "The name of the database to be created"
    type        = string
}

variable "subnet_ids" {
    description = "List of subnet IDs for the RDS subnet group"
    type        = list(string)
}

variable "security_group_ids" {
    description = "List of security group IDs for the RDS instance"
    type        = list(string)
}
