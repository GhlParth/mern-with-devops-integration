terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# ==================== APPLICATION LOAD BALANCER ====================

resource "aws_lb" "alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnets

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# ==================== FRONTEND TARGET GROUP (port 80) ====================

resource "aws_lb_target_group" "frontend" {
  name_prefix = "fe-tg-"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-frontend-tg"
  }
}

# ==================== BACKEND TARGET GROUP (port 5000) ====================

resource "aws_lb_target_group" "backend" {
  name_prefix = "be-tg-"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-backend-tg"
  }
}

# ==================== HTTP LISTENER (port 80) ====================

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_listener_rule" "api_to_backend" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = ["/api", "/api/*"]
    }
  }
}
