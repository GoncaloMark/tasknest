variable "project_name" {
    description = "Project name"
    type        = string
}

variable "subnet_ids" {
    description = "List of subnet IDs for the ELB"
    type        = list(string)
}

variable "private_subnet_ids" {
    description = "List of subnet IDs for the ELB"
    type        = list(string)
}

variable "security_group_id" {
    description = "Security group ID for the ELB"
    type        = string
}

variable "internal_security_group_id" {
    description = "Security group ID for the internal ELB"
    type        = string
}

variable "vpc_id" {
    description = "ID of the VPC"
    type        = string
}