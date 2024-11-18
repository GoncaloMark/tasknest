output "db_instance_id" {
  description = "The ID of the RDS DB instance"
  value       = aws_db_instance.rds_instance.id
}

output "db_instance_status" {
  description = "The status of the RDS DB instance"
  value       = aws_db_instance.rds_instance.status
}

output "db_endpoint" {
  description = "The endpoint of the RDS DB instance"
  value       = aws_db_instance.rds_instance.endpoint
}

output "db_instance_class" {
  description = "The class of the RDS DB instance"
  value       = aws_db_instance.rds_instance.instance_class
}
