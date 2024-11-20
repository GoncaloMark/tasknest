# Output the API Gateway URL
output "api_gateway_url" {
    value = aws_apigatewayv2_stage.default.invoke_url
}

output "api_gw_execution_arn" {
    value = aws_apigatewayv2_api.main.execution_arn
}

output "authorizer_id" {
    value = aws_apigatewayv2_authorizer.lambda_authorizer.id
}