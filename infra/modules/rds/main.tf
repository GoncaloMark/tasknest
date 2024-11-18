# modules/rds/main.tf

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.project_name}-rds-subnet-group"
  subnet_ids = var.subnet_ids  

  tags = {
    Name = "${var.project_name}-rds-subnet-group"
  }
}

data "aws_secretsmanager_secret" "db_secret" {
  name = "postgres"  
}

data "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id = data.aws_secretsmanager_secret.db_secret.id
}

locals {
  db_password = jsondecode(data.aws_secretsmanager_secret_version.db_secret_version.secret_string)["password"]
  db_username = jsondecode(data.aws_secretsmanager_secret_version.db_secret_version.secret_string)["username"]
}

resource "aws_db_instance" "rds_instance" {
  identifier              = "${var.project_name}-postgres-db"  # RDS instance
  allocated_storage       = 20               #  GB
  engine                  = "postgres"          
  engine_version          = "16.4"           
  instance_class          = "db.t3.micro"    
  db_name                 = var.db_name      
  username                = local.db_username 
  password                = local.db_password 
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids  = var.security_group_ids  # Security Group

  skip_final_snapshot = true
  
  tags = {
    Name = "${var.project_name}-postgres-db-instance"
  }
}
