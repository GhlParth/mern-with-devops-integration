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
# Receives all /* traffic from the default listener rule

resource "aws_lb_target_group" "frontend" {
  name_prefix = "fe-tg-"    # max 6 chars for ELBv2 name_prefix
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
# Receives /api/* traffic from the priority-100 listener rule

data "aws_elb_service_account" "main" {}

moved {
  from = aws_lb.this
  to   = aws_lb.alb
}

resource "aws_lb_target_group" "backend" {
  name_prefix = "be-tg-"    # max 6 chars for ELBv2 name_prefix
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/health"    # Dedicated health endpoint
    interval            = 30           # Faster check for stabilization
    timeout             = 15           # Longer timeout for small instances
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200-399"    # Accept redirects as success for health
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-backend-tg"
  }
}

# ==================== HTTP LISTENER (port 80) ====================
# Default action → frontend target group
# Priority-100 rule: /api/* → backend target group

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  # Default: all /* traffic goes to frontend
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_listener_rule" "api_to_backend" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100   # Evaluated before the default rule

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  # Match all /api and /api/* paths → route to backend ASG
  condition {
    path_pattern {
      values = ["/api", "/api/*"]
    }
  }
}

# HTTPS Listener (uncomment when ACM cert is ready and you want HTTPS on the ALB too)
# CloudFront already terminates HTTPS so this is optional.
# resource "aws_lb_listener" "https" {
#   load_balancer_arn = aws_lb.alb.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = var.acm_certificate_arn
#
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.frontend.arn
#   }
# }
