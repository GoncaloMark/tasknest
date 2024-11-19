variable "project_name" {
    description = "The name of the project for tagging resources"
    type        = string
    default     = "tasknest"
}

variable "api_path" {
    description = "The path for the API resource"
    type        = string
    default     = "v1"
}

variable "integration_uri" {
    description = "The URI for the API Gateway to forward the requests to"
    type        = string
}

variable "internal_security_group_id"{
    type = string
}

variable "private_subnet_ids" {
    type = list(string)
}

variable "api_authorizer" {
    type = string
}

variable "aws_region" {
    type = string
}

variable "frontend_url" {
    type = string
}