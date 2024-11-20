output "user_pool_id" {
  value = aws_cognito_user_pool.user_pool.id
}

output "user_pool_client_id" {
  value = aws_cognito_user_pool_client.user_pool_client.id
}

output "user_pool_domain" {
  value = aws_cognito_user_pool_domain.user_pool_domain.domain
}

output "user_pool_client_secret" {
  value     = aws_cognito_user_pool_client.user_pool_client.client_secret
  sensitive = true
}

output "cognito_user_pool_login_url" {
  description = "The login URL for the Cognito Buyer User Pool"
  value       = "https://${aws_cognito_user_pool_domain.user_pool_domain.domain}.auth.${var.aws_region}.amazoncognito.com/login?client_id=${aws_cognito_user_pool_client.user_pool_client.id}&response_type=code&scope=email+openid+profile&redirect_uri=https://google.com"
}

output "cognito_domain" {
  value = "https://${aws_cognito_user_pool_domain.user_pool_domain.domain}.auth.${var.aws_region}.amazoncognito.com"
}