# /infra/variables.tf

variable "aws_region" {
    description = "The AWS region to deploy resources in"
    type        = string
    default     = "us-east-1"
}

variable "project_name" {
    description = "The name of the project for tagging resources"
    type        = string
    default     = "tasknest"
}

variable "vpc_cidr" {
    description = "The CIDR block for the VPC"
    type        = string
    default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
    description = "List of CIDR blocks for the public subnets"
    type        = list(string)
    default     = ["10.0.1.0/24", "10.0.4.0/24"]
}

variable "private_subnet_cidrs" {
    description = "List of CIDR blocks for the private subnets"
    type        = list(string)
    default     = ["10.0.2.0/24", "10.0.3.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "availability_zones" {
    description = "List of availability zones for subnets"
    type        = list(string)
    default     = ["us-east-1a", "us-east-1b"]
}

variable "ecr_repos" {
    type = list(string)
    default = ["users-repo", "frontend-repo", "tasks-repo"]
}

variable "db_name" {
    description = "Postgres Database Name"
    type        = string
    default     = "tasknest"
}

variable "client_secret" {
    description = "Client secret for Cognito user pool client"
    type        = string
    sensitive   = true
}