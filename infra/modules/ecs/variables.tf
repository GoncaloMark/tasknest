variable "project" {
    description = "Project name"
    type        = string
}

variable "cpu" {
    description = "CPU units for the ECS task"
    type        = string
    default = "256"
}

variable "memory" {
    description = "Memory size for the ECS task"
    type        = string
    default = "512"
}

variable "execution_role_arn" {
    description = "ARN of the execution role for the ECS task"
    type        = string
}

variable "task_role_arn" {
    description = "ARN of the task role for the ECS task"
    type        = string
}

variable "container_definitions" {
    description = "Container definitions in JSON format"
    type = list(object({
        name      = string
        image     = string  # ECR image URL
        cpu       = optional(number)
        memory    = optional(number)
        essential = optional(bool)
        portMappings = list(object({
            containerPort = number
            hostPort      = optional(number)
        }))
    }))

    default = [
        {
        name  = "users"
        image = "public.ecr.aws/ecs-sample-image/amazon-ecs-sample:latest"
        essential = true
        portMappings = [
            {
            containerPort = 3000
            hostPort      = 3000
            }
        ]
        },

        {
        name  = "frontend"
        image = "public.ecr.aws/ecs-sample-image/amazon-ecs-sample:latest"
        essential = true
        portMappings = [
            {
            containerPort = 80
            hostPort      = 80
            }
        ]
        }
    ]
}


        # {
        # name  = "users"
        # image = "908776941646.dkr.ecr.us-east-1.amazonaws.com/users-repo:latest"
        # memory = 512
        # cpu    = 256
        # essential = true
        # portMappings = [
        #     {
        #     containerPort = 3000
        #     hostPort      = 3000
        #     }
        # ]
        # },
        # {
        # name  = "frontend"
        # image = "908776941646.dkr.ecr.us-east-1.amazonaws.com/frontend-repo:latest"
        # memory = 512
        # cpu    = 256
        # essential = true
        # portMappings = [
        #     {
        #     containerPort = 80
        #     hostPort      = 80
        #     }
        # ]
        # }

variable "desired_count" {
    description = "Desired count of running tasks"
    type        = number
    default = 1
}

variable "private_subnet_ids" {
    description = "List of private subnet IDs for the ECS service"
    type        = list(string)
}

variable "security_group_id" {
    description = "Security group ID for the ECS service"
    type        = string
}

variable "users_target_group_arn" {
    description = "ARN of the target group for users"
    type        = string
}

variable "frontend_target_group_arn" {
    description = "ARN of the target group for microservices"
    type        = string
}