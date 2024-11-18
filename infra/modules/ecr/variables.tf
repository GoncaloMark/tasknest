variable "name" {
    description = "Repo name"
    type        = list(string)
}

variable "vpc_id" {
    type        = string
}

variable "private_subnet_ids" {
    type        = list(string)
}

variable "private_route_table_ids" {
    type = list(string)
}

variable "ecs_task_execution_role_arn" {
    type = string
}