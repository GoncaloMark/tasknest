# Cognito User Pool for 
resource "aws_cognito_user_pool" "user_pool" {
  name                = "${var.project_name}"
  username_attributes = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length                   = 12
    require_lowercase               = true
    require_numbers                 = true
    require_symbols                 = true
    require_uppercase               = true
    temporary_password_validity_days = 7
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  schema {
    attribute_data_type = "String"
    name               = "email"
    required           = true
    mutable            = false

    string_attribute_constraints {
      min_length = 3
      max_length = 256
    }
  }

  schema {
    attribute_data_type = "String"
    name                = "phone_number"
    required            = true
    mutable             = true
  }

  schema {
    attribute_data_type = "String"
    name                = "given_name"
    required            = true
    mutable             = true
  }

  schema {
    attribute_data_type = "String"
    name                = "family_name"
    required            = true
    mutable             = true
  }

  schema {
    attribute_data_type = "String"
    name                = "address"
    required            = true
    mutable             = true
  }
}

# Cognito User Pool Client for 
resource "aws_cognito_user_pool_client" "user_pool_client" {
  name                   = "${var.project_name}-client"
  user_pool_id           = aws_cognito_user_pool.user_pool.id
  generate_secret        = true
  allowed_oauth_flows    = ["code"]
  allowed_oauth_scopes   = ["email", "openid", "profile"]
  callback_urls          = [var.callback_url]
  logout_urls            = [var.logout_url]
  supported_identity_providers = ["COGNITO"]

  prevent_user_existence_errors        = "ENABLED"
  
  enable_token_revocation             = true
  
  access_token_validity               = 1  
  id_token_validity                   = 1  
  refresh_token_validity              = 30 

  token_validity_units {
    access_token  = "hours"
    id_token     = "hours"
    refresh_token = "days"
  }

  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
}

# Cognito User Pool Domain for 
resource "aws_cognito_user_pool_domain" "user_pool_domain" {
  domain       = "${var.project_name}-auth"
  user_pool_id = aws_cognito_user_pool.user_pool.id
}

output "cognito_ui" {
  value = "https://${aws_cognito_user_pool_domain.user_pool_domain.domain}.auth.${var.aws_region}.amazoncognito.com/oauth2/authorize?client_id=${aws_cognito_user_pool_client.user_pool_client.id}&response_type=code&scope=email+openid&redirect_uri=${var.callback_url}"
}

output "cognito_logout" {
  value = "https://${aws_cognito_user_pool_domain.user_pool_domain.domain}.auth.${var.aws_region}.amazoncognito.com/logout?client_id=${aws_cognito_user_pool_client.user_pool_client.id}&logout_uri=${var.logout_url}"
}