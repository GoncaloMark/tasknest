resource "aws_vpc_endpoint" "ssm" {
    vpc_id            = var.vpc_id
    service_name      = "com.amazonaws.${var.aws_region}.ssm"
    vpc_endpoint_type = "Interface"
    subnet_ids        = [var.private_subnet_ids[0], var.private_subnet_ids[1]]

    security_group_ids = [aws_security_group.ssm_endpoint_sg.id]
}

resource "aws_vpc_endpoint" "ssm_messages" {
    vpc_id            = var.vpc_id
    service_name      = "com.amazonaws.${var.aws_region}.ssmmessages"
    vpc_endpoint_type = "Interface"
    subnet_ids        = [var.private_subnet_ids[0], var.private_subnet_ids[1]]

    security_group_ids = [aws_security_group.ssm_endpoint_sg.id]
}

resource "aws_security_group" "ssm_endpoint_sg" {
    name   = "ssm-endpoint-sg"
    vpc_id = var.vpc_id

    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_ssm_parameter" "rds_endpoint" {
    name        = "rds_endpoint"
    type        = "String"
    value       = var.rds_endpoint
    description = "The endpoint of the RDS instance"
}

resource "aws_ssm_parameter" "db_name" {
    name        = "db_name"
    type        = "String"
    value       = var.db_name
    description = "The name of the database"
}

resource "aws_ssm_parameter" "cognito_ui" {
    name        = "cognito_ui"
    type        = "String"
    value       = var.cognito_ui
    description = "The endpoint of the cognito UI"
}

resource "aws_vpc_endpoint" "ec2_messages" {
    service_name = "com.amazonaws.us-east-1.ec2messages"
    vpc_id       = var.vpc_id
    vpc_endpoint_type = "Interface"
    subnet_ids   = [var.private_subnet_ids[0], var.private_subnet_ids[1]]
    security_group_ids = [aws_security_group.ssm_endpoint_sg.id]

    tags = {
        Name = "EC2 Messages VPC Endpoint"
    }
}