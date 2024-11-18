output "public_alb_sg_id" {
    description = "Security Group ID for the public ALB"
    value       = aws_security_group.public_alb_sg.id
}

output "internal_alb_sg_id" {
    description = "Security Group ID for the internal ALB"
    value       = aws_security_group.internal_alb_sg.id
}

output "db_sg_id" {
    description = "Security Group ID for RDS"
    value       = aws_security_group.db_sg.id
}