output "ssm_rds_endpoint" {
    description = "The RDS endpoint stored in SSM Parameter Store"
    value       = aws_ssm_parameter.rds_endpoint.arn
}

output "ssm_db_name" {
    description = "The DB name stored in SSM Parameter Store"
    value       = aws_ssm_parameter.db_name.arn
}