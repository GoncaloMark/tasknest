# Output Lambda Authorizer ARN (Optional)
output "authorizer_function_arn" {
    value = aws_lambda_function.api_authorizer.arn
}