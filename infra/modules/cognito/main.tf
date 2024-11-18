# Cognito User Pool for Buyers
resource "aws_cognito_user_pool" "user_pool" {
  name                = "${var.project_name}-buyers"
  username_attributes = ["email"]
  auto_verified_attributes = ["email"]

  schema {
    attribute_data_type = "String"
    name                = "email"
    required            = true
    mutable             = false
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

# Cognito User Pool Client for Buyers
resource "aws_cognito_user_pool_client" "user_pool_client" {
  name                   = "${var.project_name}-buyers-client"
  user_pool_id           = aws_cognito_user_pool.user_pool.id
  generate_secret        = true
  allowed_oauth_flows    = ["code"]
  allowed_oauth_scopes   = ["email", "openid"]
  callback_urls          = ["https://google.com"]
  logout_urls            = ["https://google.com"]
  supported_identity_providers = ["COGNITO"]
}

# Cognito User Pool Domain for Buyers
resource "aws_cognito_user_pool_domain" "user_pool_domain" {
  domain       = "${var.project_name}-buyers-auth"
  user_pool_id = aws_cognito_user_pool.user_pool.id
}

# S3 Bucket for Login URL Storage
resource "aws_s3_bucket" "url_bucket" {
  bucket = "${var.project_name}-login-urls"
}

resource "aws_s3_object" "login_url" {
  bucket = aws_s3_bucket.url_bucket.id
  key    = "login_url.json"
  content = jsonencode({
    buyers_url = "https://${aws_cognito_user_pool_domain.user_pool_domain.domain}.auth.${var.aws_region}.amazoncognito.com/oauth2/authorize?client_id=${aws_cognito_user_pool_client.user_pool_client.id}&response_type=code&scope=email+openid&redirect_uri=https%3A%2F%2Fgoogle.com"
  })
}

resource "aws_s3_bucket_public_access_block" "url_bucket_block" {
  bucket                  = aws_s3_bucket.url_bucket.id
  block_public_acls       = false  # Allow public ACLs
  block_public_policy     = false  # Allow public policies
  ignore_public_acls      = true   # Ignore any public ACLs
  restrict_public_buckets = false  # Allow the bucket to be publicly accessible
}

resource "aws_s3_bucket_policy" "url_bucket_policy" {
  bucket = aws_s3_bucket.url_bucket.id
  policy = jsonencode({
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.url_bucket.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.url_bucket_block]
}

resource "aws_s3_bucket_cors_configuration" "url_bucket_cors" {
  bucket = aws_s3_bucket.url_bucket.id

  cors_rule {
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    allowed_headers = ["*"]
    expose_headers = ["ETag"]
    max_age_seconds = 3000
  }
}
