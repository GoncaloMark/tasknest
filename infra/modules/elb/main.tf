# Public ALB for Frontend
resource "aws_lb" "public_lb" {
    name               = "${var.project_name}-public-elb"
    internal           = false
    load_balancer_type = "application"
    security_groups    = [var.security_group_id]
    subnets            = var.subnet_ids  # Public subnets for the public ALB

    tags = {
        Name = "${var.project_name}-public-elb"
    }
}

resource "aws_lb_listener" "public_http" {
    load_balancer_arn = aws_lb.public_lb.arn
    port              = 80
    protocol          = "HTTP"

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.frontend.arn  # Target group for frontend
    }
}

resource "aws_lb_target_group" "frontend" {
    name     = "${var.project_name}-frontend-tg"
    port     = 80
    protocol = "HTTP"
    vpc_id   = var.vpc_id  
    target_type = "ip"

    # Define health check settings for the frontend
    health_check {
        path                = "/"  # Adjust based on health check endpoint
        interval            = 20
        timeout             = 5
        healthy_threshold  = 3
        unhealthy_threshold = 10
    }
}

resource "aws_lb_target_group" "users" {
    name     = "${var.project_name}-users-tg"
    port     = 3000
    protocol = "HTTP"
    vpc_id   = var.vpc_id
    target_type = "ip"

    health_check {
        path                = "/"  # Adjust based on health check endpoint
        interval            = 20
        timeout             = 5
        healthy_threshold  = 3
        unhealthy_threshold = 10
    }
}

# Internal ALB for Microservices
resource "aws_lb" "internal_lb" {
    name               = "${var.project_name}-private-elb"
    internal           = true  # Set to true for internal ALB
    load_balancer_type = "application"
    security_groups    = [var.internal_security_group_id]
    subnets            = var.private_subnet_ids  # Private subnets for the internal ALB

    tags = {
        Name = "${var.project_name}-private-elb"
    }
}

resource "aws_lb_listener" "internal_http" {
    load_balancer_arn = aws_lb.internal_lb.arn
    port              = 80
    protocol          = "HTTP"

    default_action {
        type = "fixed-response"
        fixed_response {
        content_type = "text/plain"
        message_body = "Not Found"
        status_code  = "404"
        }
    }
}

resource "aws_lb_listener_rule" "users_internal_rule" {
    listener_arn = aws_lb_listener.internal_http.arn
    action {    
        type             = "forward"    
        target_group_arn = aws_lb_target_group.users.arn
    }   

    condition {    
        path_pattern {
            values = ["/api/users*"]
        }
    }
}


