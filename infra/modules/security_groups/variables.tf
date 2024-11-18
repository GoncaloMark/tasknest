variable "project_name" {
    description = "Project name for tagging"
    type        = string
}

variable "vpc_id" {
    description = "VPC ID where the ALBs are deployed"
    type        = string
}

variable "vpc_cidr" {
    description = "CIDR block for the VPC"
    type        = string
}
