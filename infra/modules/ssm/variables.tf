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

variable "cognito_ui"{
    type = string
}