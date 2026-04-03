terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_db_subnets

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

resource "aws_db_instance" "this" {
  identifier           = "${var.project_name}-db"
  allocated_storage     = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.mysql8.0"
  db_subnet_group_name = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.db_sg_id]
  multi_az             = true # High Availability
  skip_final_snapshot  = true

  tags = {
    Name = "${var.project_name}-rds"
  }
}
