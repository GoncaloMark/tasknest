# /infra/outputs.tf

output "vpc_id" {
    description = "The ID of the VPC"
    value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
    description = "The IDs of the public subnets"
    value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
    description = "The IDs of the private subnets"
    value       = module.vpc.private_subnet_ids
}

output "internet_gateway_id" {
    description = "The ID of the Internet Gateway"
    value       = module.vpc.internet_gateway_id
}

output "nat_gateway_id" {
    description = "The ID of the NAT Gateway"
    value       = module.vpc.nat_gateway_id
}

output "ecr_repository_url" {
    description = "URLs of the created ECR repositories"
    value       = { for key, repo in module.ecr.repository_urls : key => repo }
}

# Cognito User Pool
output "cognito_id" {
  description = "The ID of the Cognito User Pool"
  value       = module.cognito.user_pool_id
}

output "cognito_client_id" {
  description = "The ID of the Cognito User Pool Client"
  value       = module.cognito.user_pool_client_id
}

output "cognito_client_secret" {
  description = "The secret of the Cognito User Pool Client"
  value       = module.cognito.user_pool_client_secret
  sensitive   = true
}

output "cognito_domain" {
  description = "The domain for the Cognito User Pool hosted UI"
  value       = module.cognito.user_pool_domain
}

output "cognito_auth_endpoint" {
  description = "The URL for the Cognito hosted UI authorization endpoint"
  value       = "https://${module.cognito.user_pool_domain}.auth.${var.aws_region}.amazoncognito.com/oauth2/authorize"
}

output "cognito_logout_endpoint" {
  description = "The URL for the Cognito hosted UI logout endpoint"
  value       = "https://${module.cognito.user_pool_domain}.auth.${var.aws_region}.amazoncognito.com/logout"
}

