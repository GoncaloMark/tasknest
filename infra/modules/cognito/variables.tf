# /modules/cognito/buyers/variables.tf

variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type = string
}

variable "project_name" {
  description = "The name of the project for tagging resources"
  type        = string
}

variable "client_secret" {
  description = "Client secret for Cognito user pool client"
  type        = string
  sensitive   = true
}

variable "cognito_user_pool_name" {
  description = "The name of the Cognito User Pool"
  type        = string
  default     = "buyer-user-pool"
}

variable "cognito_user_pool_client_name" {
  description = "The name of the Cognito User Pool Client"
  type        = string
  default     = "buyer-user-pool-client"
}

