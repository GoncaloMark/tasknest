# /infra/main.tf

provider "aws" {
    region = var.aws_region
    profile = "default"
}

module "vpc" {
    source = "./modules/vpc"

    project              = var.project_name
    vpc_cidr             = var.vpc_cidr
    public_subnet_cidrs  = var.public_subnet_cidrs
    private_subnet_cidrs = var.private_subnet_cidrs
    availability_zones   = var.availability_zones
}

module "ecr" {
    source  = "./modules/ecr"
    name = var.ecr_repos
    vpc_id = module.vpc.vpc_id
    private_subnet_ids = module.vpc.private_subnet_ids
    private_route_table_ids = [module.vpc.private_route_table_ids]
    ecs_task_execution_role_arn = aws_iam_role.ecs_execution_role.arn
}

module "security_groups" {
    source      = "./modules/security_groups"
    project_name = var.project_name
    vpc_id      = module.vpc.vpc_id
    vpc_cidr    = var.vpc_cidr
}

module "elb" {
    source = "./modules/elb"

    project_name          = var.project_name
    vpc_id                = module.vpc.vpc_id
    subnet_ids     =        module.vpc.public_subnet_ids 
    private_subnet_ids    = [module.vpc.private_subnet_ids[1], module.vpc.private_subnet_ids[2]]  # Use only the microservices private subnet for internal ALB
    security_group_id   = module.security_groups.public_alb_sg_id
    internal_security_group_id = module.security_groups.internal_alb_sg_id
}

resource "aws_iam_role" "ecs_execution_role" {
    name               = "${var.project_name}-ecs-execution-role"
    assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
}

data "aws_iam_policy_document" "ecs_assume_role_policy" {
    statement {
        actions = ["sts:AssumeRole"]
        principals {
            type        = "Service"
            identifiers = ["ecs-tasks.amazonaws.com"]
        }
        effect = "Allow"
    }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
    role       = aws_iam_role.ecs_execution_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy" "ecs_task_policy" {
    name   = "${var.project_name}-ecs-task-policy"
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "s3:PutObject",
                    "s3:GetObject",
                    "s3:ListBucket",
                    "ecr:GetAuthorizationToken",
                    "ecr:BatchCheckLayerAvailability",
                    "ecr:GetDownloadUrlForLayer",
                    "ecr:BatchGetImage",
                    "logs:CreateLogStream",
                    "logs:PutLogEvents",
                    "logs:CreateLogGroup",
                ]
                Resource = "*"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "secretsmanager:GetSecretValue"
                ],
                "Resource": "arn:aws:secretsmanager:*:*:secret:*"
                },
                {
                "Effect": "Allow",
                "Action": [
                    "ssm:GetParameter",
                    "ssm:GetParameters",
                    "ssm:GetParametersByPath"
                ],
                "Resource": "arn:aws:ssm:*:*:parameter/*"
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_policy_attachment" {
    policy_arn = aws_iam_policy.ecs_task_policy.arn
    role       = aws_iam_role.ecs_task_role.name
}


resource "aws_iam_policy" "ecs_execution_policy" {
    name   = "${var.project_name}-ecs-execution-policy"
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "ecr:GetAuthorizationToken",
                    "ecr:BatchCheckLayerAvailability",
                    "ecr:GetDownloadUrlForLayer",
                    "ecr:BatchGetImage",
                    "logs:CreateLogStream",
                    "logs:PutLogEvents",
                    "logs:CreateLogGroup",
                    "s3:GetObject",
                    "s3:ListBucket"
                ]
                Resource = "*"
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy_attachment" {
    policy_arn = aws_iam_policy.ecs_execution_policy.arn
    role       = aws_iam_role.ecs_execution_role.name
}

resource "aws_iam_role" "ecs_task_role" {
    name               = "${var.project_name}-ecs-task-role"
    assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_policy.json
}

data "aws_iam_policy_document" "ecs_task_assume_role_policy" {
    statement {
        actions = ["sts:AssumeRole"]
        principals {
        type        = "Service"
        identifiers = ["ecs-tasks.amazonaws.com"]
        }
        effect = "Allow"
    }
}

resource "aws_security_group" "ecs_service_sg" {
    name   = "${var.project_name}-ecs-sg"
    vpc_id = module.vpc.vpc_id

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]  # Change this to restrict access as needed
    }

    ingress {
        from_port   = 3000
        to_port     = 3000
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]  # Change this to restrict access as needed
    }

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

    tags = {
        Name = "${var.project_name}-ecs-sg"
    }
}

module "cloudfront" {
    source = "./modules/cloudfront"
    alb_dns = module.elb.public_elb_dns_name
    api_gw = module.api_gateway.api_gateway_url
}

module "ecs" {
    source = "./modules/ecs"
    project = var.project_name
    private_subnet_ids = [module.vpc.private_subnet_ids[1], module.vpc.private_subnet_ids[2]] 
    execution_role_arn =  aws_iam_role.ecs_execution_role.arn
    task_role_arn = aws_iam_role.ecs_task_role.arn
    users_target_group_arn = module.elb.users_target_group_arn
    frontend_target_group_arn =  module.elb.frontend_target_group_arn
    security_group_id = aws_security_group.ecs_service_sg.id
}

resource "aws_security_group" "internal_sg" {
    name        = "${var.project_name}-internal-sg"
    description = "Security group for internal resources"
    vpc_id      = module.vpc.vpc_id

    # Allow incoming traffic on port 80 from the VPC
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = [var.vpc_cidr]
    }

    ingress {
        from_port   = 80
        to_port     = 3000
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 3000
        to_port     = 3000
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Allow incoming traffic on port 443 from the VPC (if you're using HTTPS)
    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = [var.vpc_cidr]
    }

    # Allow all outbound traffic
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.project_name}-internal-sg"
    }
}

module "api_gateway" {
    source = "./modules/api_gateway"

    project_name           = var.project_name
    integration_uri        = module.elb.user_elb_listener_arn
    private_subnet_ids = module.vpc.private_subnet_ids
    internal_security_group_id = aws_security_group.internal_sg.id
    api_authorizer = module.lambda.authorizer_function_arn
    aws_region = var.aws_region
}

module "rds" {
    source = "./modules/rds"

    project_name            = var.project_name  
    db_name                 = var.db_name          
    subnet_ids              = module.vpc.private_subnet_ids 
    security_group_ids      = [module.security_groups.db_sg_id]  # ID do Security Group
}

module "cognito" {
    source        = "./modules/cognito"
    aws_region  = var.aws_region
    project_name  = var.project_name
    client_secret = var.client_secret
}

module "lambda" {
    source = "./modules/lambda"
    vpc_id = module.vpc.vpc_id
    private_subnet_ids = module.vpc.private_subnet_ids 
    rds_sg_id = module.security_groups.db_sg_id
    cognito_app_client_id = module.cognito.user_pool_client_id
    cognito_user_pool_id = module.cognito.user_pool_id
    aws_region = var.aws_region

    depends_on = [
        module.vpc
    ]
}

resource "aws_vpc_endpoint" "secrets_manager" {
    vpc_id            = module.vpc.vpc_id
    service_name      = "com.amazonaws.${var.aws_region}.secretsmanager"
    vpc_endpoint_type = "Interface"
    subnet_ids        = [module.vpc.private_subnet_ids[0], module.vpc.private_subnet_ids[1]]

    security_group_ids = [aws_security_group.secrets_manager_endpoint_sg.id]
}

resource "aws_security_group" "secrets_manager_endpoint_sg" {
    name   = "secrets-manager-endpoint-sg"
    vpc_id = module.vpc.vpc_id

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

module "ssm" {
    source = "./modules/ssm"
    db_name = var.db_name
    rds_endpoint = module.rds.db_endpoint
    vpc_id = module.vpc.vpc_id
    aws_region = var.aws_region
    private_subnet_ids = module.vpc.private_subnet_ids 
    cognito_ui = module.cognito.cognito_ui
}