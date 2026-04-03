terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# ==================== ALB SECURITY GROUP ====================
# Accepts HTTP/HTTPS from the internet

resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from internet"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from internet"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# ==================== APP SECURITY GROUP ====================
# Shared by BOTH frontend and backend EC2 instances.
#   Frontend (public subnet): port 80 from ALB + SSH 22 from internet
#   Backend  (private subnet): port 5000 from ALB + SSH 22 from bastion (bastion
#     can reach it because it also uses CIDR 0.0.0.0/0 on the SG rule, which
#     means the bastion can SSH since it has VPC-level connectivity to the private IP)

resource "aws_security_group" "app_sg" {
  name        = "${var.project_name}-app-sg"
  description = "Security group for frontend and backend EC2 instances"
  vpc_id      = var.vpc_id

  # Frontend: ALB sends port 80 traffic
  ingress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.alb_sg.id]
    description     = "HTTP from ALB to frontend"
  }

  # Backend: ALB sends port 5000 traffic (for /api/* routes)
  ingress {
    protocol        = "tcp"
    from_port       = 5000
    to_port         = 5000
    security_groups = [aws_security_group.alb_sg.id]
    description     = "API traffic from ALB to backend"
  }

  # SSH: open to all (frontend direct SSH; backend reachable via bastion over VPC)
  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH from anywhere (use bastion for private instances)"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound (Docker pulls, SSM, MongoDB Atlas)"
  }

  tags = {
    Name = "${var.project_name}-app-sg"
  }
}

# ==================== BASTION SECURITY GROUP ====================
# Dedicated SG for the bastion SSH jump box

resource "aws_security_group" "bastion_sg" {
  name        = "${var.project_name}-bastion-sg"
  description = "Security group for Bastion host (SSH jump server)"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH from internet"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound (to reach private subnet instances)"
  }

  tags = {
    Name = "${var.project_name}-bastion-sg"
  }
}

# Database SG (commented out — using MongoDB Atlas instead of RDS)
# resource "aws_security_group" "db_sg" { ... }
