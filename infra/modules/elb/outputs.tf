output "public_elb_arn" {
    description = "ARN of the created Public ELB"
    value       = aws_lb.public_lb.arn
}

output "public_elb_dns_name" {
    description = "DNS name of the Public ELB"
    value       = aws_lb.public_lb.dns_name
}

output "private_elb_arn" {
    description = "ARN of the created Private ELB"
    value       = aws_lb.internal_lb.arn
}

output "user_elb_listener_arn" {
    description = "ARN of the created Private ELB"
    value       = aws_lb_listener.internal_http.arn
}

output "private_elb_dns_name" {
    description = "DNS name of the Private ELB"
    value       = aws_lb.internal_lb.dns_name
}

output "users_target_group_arn" {
    value = aws_lb_target_group.users.arn
}

output "tasks_target_group_arn" {
    value = aws_lb_target_group.tasks.arn
}

output "frontend_target_group_arn" {
    value = aws_lb_target_group.frontend.arn
}