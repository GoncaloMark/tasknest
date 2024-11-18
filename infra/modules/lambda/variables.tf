variable "private_subnet_ids" {
    description = "List of subnet IDs"
    type        = list(string)
}

variable "vpc_id" {
    description = "ID of the VPC"
    type        = string
}

variable "rds_sg_id" {
    description = "security group ID"
    type        = string
}

variable "aws_region" {
    type = string
}

variable "cognito_user_pool_id"{
    type = string
}

variable "cognito_app_client_id" {
    type = string
}