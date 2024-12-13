# VPC Link
resource "aws_apigatewayv2_vpc_link" "private_integrations" {
    name               = "${var.project_name}-vpc-link"
    security_group_ids = [var.internal_security_group_id]
    subnet_ids         = var.private_subnet_ids

    tags = {
        Name = "${var.project_name}-vpc-link"
    }
}

resource "aws_apigatewayv2_authorizer" "lambda_authorizer" {
    api_id        = aws_apigatewayv2_api.main.id
    name          = "lambda-authorizer"
    authorizer_type = "REQUEST"
    authorizer_uri = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions:${var.api_authorizer}/invocations"

    identity_sources = ["$request.header.Cookie"]
    authorizer_payload_format_version = "2.0"

    authorizer_result_ttl_in_seconds = 0
}

resource "aws_apigatewayv2_route" "health_check" {
    api_id    = aws_apigatewayv2_api.main.id
    route_key = "GET /api/tasks"
    target    = "integrations/${aws_apigatewayv2_integration.private_elb.id}"
    authorization_type = "NONE"  # No authorization for this route
}

resource "aws_apigatewayv2_route" "swagger" {
    api_id    = aws_apigatewayv2_api.main.id
    route_key = "ANY /api/tasks/swagger"
    target    = "integrations/${aws_apigatewayv2_integration.private_elb.id}"
    authorization_type = "NONE"  # No authorization for this route
}

resource "aws_apigatewayv2_route" "proxy_protected" {
    api_id    = aws_apigatewayv2_api.main.id
    route_key = "ANY /api/tasks/{proxy+}"
    target    = "integrations/${aws_apigatewayv2_integration.private_elb.id}"
    authorization_type = "CUSTOM"

    authorizer_id = aws_apigatewayv2_authorizer.lambda_authorizer.id
} 

resource "aws_apigatewayv2_route" "auth_protected" {
    api_id    = aws_apigatewayv2_api.main.id
    route_key = "GET /api/users/auth"
    target    = "integrations/${aws_apigatewayv2_integration.private_elb.id}"
    authorization_type = "CUSTOM"

    authorizer_id = aws_apigatewayv2_authorizer.lambda_authorizer.id
} 

resource "aws_apigatewayv2_route" "proxy" {
    api_id    = aws_apigatewayv2_api.main.id
    route_key = "ANY /api/{proxy+}"
    target    = "integrations/${aws_apigatewayv2_integration.private_elb.id}"
}

# HTTP API
resource "aws_apigatewayv2_api" "main" {
    name          = "${var.project_name}-api-gw"
    protocol_type = "HTTP"
}


# Default Stage
resource "aws_apigatewayv2_stage" "default" {
    api_id      = aws_apigatewayv2_api.main.id
    name        = "$default"
    auto_deploy = true

    # Enable access logging
    access_log_settings {
        destination_arn = aws_cloudwatch_log_group.api_gateway.arn
        format          = jsonencode({
            requestId        = "$context.requestId",
            ip               = "$context.identity.sourceIp",
            caller           = "$context.identity.caller",
            user             = "$context.identity.user",
            requestTime      = "$context.requestTime",
            httpMethod       = "$context.httpMethod",
            resourcePath     = "$context.resourcePath",
            status           = "$context.status",
            responseLength   = "$context.responseLength",
            integrationError = "$context.integrationErrorMessage",
        })
    }

    default_route_settings {
        logging_level      = "INFO"  
        data_trace_enabled = true    # Logs request/response payloads
        throttling_burst_limit = 5000
        throttling_rate_limit = 10000
    }
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
    name              = "/aws/api-gateway/${var.project_name}"
    retention_in_days = 7 
    tags = {
        Name = "${var.project_name}-api-logs"
    }
}

# IAM Role for API Gateway Logging
resource "aws_iam_role" "api_gateway_logs" {
    name = "${var.project_name}-api-gateway-logs-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Effect = "Allow",
                Principal = {
                    Service = "apigateway.amazonaws.com"
                },
                Action = "sts:AssumeRole"
            }
        ]
    })

    tags = {
        Name = "${var.project_name}-api-gateway-logs-role"
    }
}

resource "aws_iam_policy" "api_gateway_logging_policy" {
    name   = "${var.project_name}-api-gateway-logging-policy"
    policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Effect = "Allow",
                Action = [
                    "logs:CreateLogGroup",
                    "logs:CreateLogStream",
                    "logs:PutLogEvents"
                ],
                Resource = [
                    "${aws_cloudwatch_log_group.api_gateway.arn}:*"
                ]
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "api_gateway_logs_attach" {
    role       = aws_iam_role.api_gateway_logs.name
    policy_arn = aws_iam_policy.api_gateway_logging_policy.arn
}

# Integration
resource "aws_apigatewayv2_integration" "private_elb" {
    api_id           = aws_apigatewayv2_api.main.id
    integration_type = "HTTP_PROXY"

    integration_uri    = var.integration_uri
    integration_method = "ANY"
    connection_type    = "VPC_LINK"
    connection_id      = aws_apigatewayv2_vpc_link.private_integrations.id

    request_parameters = {
        "overwrite:path"               = "$request.path"
        "overwrite:header.Cookie"      = "$request.header.Cookie"
        "overwrite:header.X-User-ID" = "$context.authorizer.userId"
    }
}