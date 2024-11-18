# /modules/vpc/variables.tf

variable "project" {
    description = "The name of the project for tagging purposes"
    type        = string
}

variable "vpc_cidr" {
    description = "The CIDR block for the VPC"
    type        = string
}

variable "public_subnet_cidrs" {
    description = "A list of CIDR blocks for the public subnets"
    type        = list(string)
}

variable "private_subnet_cidrs" {
    description = "A list of CIDR blocks for the private subnets"
    type        = list(string)
}

variable "availability_zones" {
    description = "List of availability zones to deploy the subnets into"
    type        = list(string)
}
