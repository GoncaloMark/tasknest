resource "aws_security_group" "public_alb_sg" {
    name        = "${var.project_name}-public-alb-sg"
    description = "Security group for Public ALB"
    vpc_id      = var.vpc_id

    ingress {
        description = "Allow inbound HTTP traffic"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]  # Allow HTTP from anywhere
    }

    ingress {
        description = "Allow inbound HTTPS traffic"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]  # Allow HTTPS from anywhere
    }

    egress {
        description = "Allow all outbound traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.project_name}-public-alb-sg"
    }
}

resource "aws_security_group" "internal_alb_sg" {
    name        = "${var.project_name}-internal-alb-sg"
    description = "Security group for Internal ALB"
    vpc_id      = var.vpc_id

    ingress {
        description = "Allow inbound HTTP traffic from within the VPC"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = [var.vpc_cidr]  # Allow traffic only from within the VPC
    }

    egress {
        description = "Allow all outbound traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.project_name}-internal-alb-sg"
    }
    }

resource "aws_security_group" "db_sg" {
    name        = "${var.project_name}-db-sg"
    description = "Security Group for RDS"
    vpc_id      = var.vpc_id

    ingress {
        from_port   = 5432 
        to_port     = 5432
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        description = "Allow all outbound traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}