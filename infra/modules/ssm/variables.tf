variable "rds_endpoint" {
    description = "The endpoint of the RDS instance"
    type        = string
}

variable "db_name" {
    description = "The name of the database"
    type        = string
}

variable "vpc_id"{
    type = string
}

variable "aws_region" {
    type = string
}

variable "private_subnet_ids" {
    type = list(string)
}

variable "cognito_logout" {
    type = string
}

variable "userpool_id"{
    type = string
}

variable "cognito_ui"{
    type = string
}

variable "cognito_domain" {
    type = string
}

variable "redirect_uri" {
    type = string
}

variable "frontend_url" {
    type = string
}

variable "cognito_client_id" {
    type = string
}