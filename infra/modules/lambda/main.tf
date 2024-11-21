resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_rds_migration_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

data "aws_secretsmanager_secret" "db_secret" {
  name = "postgres"  
}

resource "aws_iam_policy" "lambda_policy" {
  name = "lambda_rds_migration_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = ["secretsmanager:GetSecretValue"],
        Effect   = "Allow",
        Resource = data.aws_secretsmanager_secret.db_secret.arn
      },
      {
        Action   = ["rds-db:connect"],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action   = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action   = [
            "ssm:GetParameters",
            "ssm:GetParameter",
            "ssm:GetParametersByPath"
            ],  
        Effect   = "Allow",
        Resource = [
          var.db_name_arn,
          var.rds_endpoint_arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_iam_role_policy_attachment" "basic_execution_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_security_group" "lambda_sg" {
  name   = "lambda-db-access-sg"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [var.rds_sg_id] // Allow inbound from RDS security group
  }

  depends_on = [ aws_iam_role_policy_attachment.sto-lambda-vpc-role-policy-attach ]
}

data "aws_iam_policy" "LambdaVPCAccess" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "sto-lambda-vpc-role-policy-attach" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = data.aws_iam_policy.LambdaVPCAccess.arn
}

resource "aws_lambda_function" "db_migrate" {
  function_name    = "db-migrate"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.10"
  timeout          = 60
  memory_size      = 256

  filename         = "${path.module}/sql_lambda.zip"

  environment {
    variables = {
      DB_SECRET_NAME = "postgres"
      REGION     = "us-east-1"
    }
  }

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  depends_on = [
    aws_security_group.lambda_sg
  ]
}

resource "aws_iam_role" "lambda_authorizer_role" {
  name = "lambda_authorizer_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Lambda Policy for Accessing Cognito Public Keys (JWKS) and CloudWatch Logging
resource "aws_iam_policy" "lambda_authorizer_policy" {
  name = "lambda_authorizer_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents", "logs:CreateLogGroup"],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action   = ["ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:DeleteNetworkInterface"],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action   = ["secretsmanager:GetSecretValue"],
        Effect   = "Allow",
        Resource = data.aws_secretsmanager_secret.db_secret.arn
      },
      {
        Action   = [
            "ssm:GetParameters",
            "ssm:GetParameter",
            "ssm:GetParametersByPath"
            ],  
        Effect   = "Allow",
        Resource = [
        var.db_name_arn,
        var.rds_endpoint_arn
        ]
      }
    ]
  })
}

# Attach Policies to Lambda Authorizer Role
resource "aws_iam_role_policy_attachment" "authorizer_policy_attachment" {
  role       = aws_iam_role.lambda_authorizer_role.name
  policy_arn = aws_iam_policy.lambda_authorizer_policy.arn
}

resource "aws_iam_role_policy_attachment" "authorizer_basic_policy_attachment" {
  role       = aws_iam_role.lambda_authorizer_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Security Group for Lambda (if needed for VPC configuration)
resource "aws_security_group" "authorizer_sg" {
  name   = "lambda-authorizer-sg"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Lambda Authorizer Function
resource "aws_lambda_function" "api_authorizer" {
  function_name    = "api-authorizer"
  role             = aws_iam_role.lambda_authorizer_role.arn
  handler          = "authorizer.lambda_handler"
  runtime          = "python3.10"
  timeout          = 10
  memory_size      = 128

  filename         = "${path.module}/lambda_authorizer.zip"

  environment {
    variables = {
      COGNITO_REGION         = var.aws_region
      COGNITO_USER_POOL_ID   = var.cognito_user_pool_id 
      COGNITO_APP_CLIENT_ID  = var.cognito_app_client_id 
    }
  }

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.authorizer_sg.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.authorizer_policy_attachment,
    aws_iam_role_policy_attachment.authorizer_basic_policy_attachment
  ]
}

resource "aws_lambda_permission" "allow_api_gateway_invoke_authorizer" {
  statement_id  = "AllowApiGatewayInvokeAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  
  source_arn    = "${var.api_gw_execution_arn}/authorizers/${var.authorizer_id}"
}