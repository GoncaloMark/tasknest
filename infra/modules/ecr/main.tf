resource "aws_ecr_repository" "repo" {
    for_each = toset(var.name)

    name = "${each.key}"

    image_scanning_configuration {
        scan_on_push = true
    }

    tags = {
        Name = "${each.key}"
    }
}

resource "aws_security_group" "vpc_endpoints" {
    name        = "vpc-endpoints-sg"
    description = "Security group for VPC endpoints"
    vpc_id      = var.vpc_id

    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
    vpc_id       = var.vpc_id
    service_name = "com.amazonaws.us-east-1.ecr.dkr"
    subnet_ids   = [var.private_subnet_ids[0], var.private_subnet_ids[1]]
    vpc_endpoint_type  = "Interface"
    security_group_ids  = [aws_security_group.vpc_endpoints.id]  # Associate security group
    private_dns_enabled = true

    policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Effect = "Allow"
            Principal = {
            AWS = var.ecs_task_execution_role_arn
            }
            Action = [
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:BatchCheckLayerAvailability"
            ]
            Resource = "*"
        }
        ]
    })
}

resource "aws_vpc_endpoint" "ecr_api" {
    vpc_id       = var.vpc_id
    service_name = "com.amazonaws.us-east-1.ecr.api"
    subnet_ids   = [var.private_subnet_ids[0], var.private_subnet_ids[1]]
    vpc_endpoint_type  = "Interface"
    security_group_ids  = [aws_security_group.vpc_endpoints.id]  # Associate security group
    private_dns_enabled = true

    policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Effect = "Allow"
            Principal = {
            AWS = var.ecs_task_execution_role_arn
            }
            Action = [
            "ecr:GetAuthorizationToken",
            "ecr:DescribeRepositories",
            "ecr:ListImages"
            ]
            Resource = "*"
        }
        ]
    })
}

resource "aws_vpc_endpoint" "s3" {
    vpc_id            = var.vpc_id
    service_name      = "com.amazonaws.us-east-1.s3"
    vpc_endpoint_type = "Gateway"
    route_table_ids   = var.private_route_table_ids
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Sid    = "AllowECRActions"
                Effect = "Allow"
                Principal = "*"
                Action = [
                "s3:GetBucketLocation",
                "s3:GetObject",
                "s3:ListBucket"
                ]
                Resource = [
                "arn:aws:s3:::prod-us-east-1-starport-layer-bucket",
                "arn:aws:s3:::prod-us-east-1-starport-layer-bucket/*",
                "arn:aws:s3:::us-east-1-starport-layer-bucket",
                "arn:aws:s3:::us-east-1-starport-layer-bucket/*"
                ]
            }
        ]
    })
}