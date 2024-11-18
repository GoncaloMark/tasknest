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

    identity_sources = ["$request.header.cookie.id_token"]
    authorizer_payload_format_version = "2.0"
}
resource "aws_apigatewayv2_route" "health_check" {
    api_id    = aws_apigatewayv2_api.main.id
    route_key = "ANY /api/tasks/"
    target    = "integrations/${aws_apigatewayv2_integration.private_elb.id}"
}

resource "aws_apigatewayv2_route" "proxy_protected" {
    api_id    = aws_apigatewayv2_api.main.id
    route_key = "ANY /api/tasks/{proxy+}"
    target    = "integrations/${aws_apigatewayv2_integration.private_elb.id}"

    authorizer_id = aws_apigatewayv2_authorizer.lambda_authorizer.id
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
}

# Route
resource "aws_apigatewayv2_route" "proxy" {
    api_id    = aws_apigatewayv2_api.main.id
    route_key = "ANY /api/{proxy+}"
    target    = "integrations/${aws_apigatewayv2_integration.private_elb.id}"
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
        "overwrite:path" = "$request.path"
    }
}

