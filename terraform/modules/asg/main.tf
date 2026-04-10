terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# ==================== DATA SOURCE ====================
# Ubuntu 22.04 LTS (Jammy) — official Canonical AMI
# Owner 099720109477 = Canonical (official Ubuntu publisher on AWS)

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# ==============================================================
# FRONTEND TIER — Public Subnets (Multi-AZ), Public IP, Port 80
# Runs: taskflow-frontend (Nginx + React build)
# ALB routes: /* → this ASG on port 80
# SSH user: ubuntu
# ==============================================================

resource "aws_launch_template" "frontend" {
  name_prefix   = "${var.project_name}-frontend-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name

  network_interfaces {
    associate_public_ip_address = true   # Direct SSH access possible
    security_groups             = [var.app_sg_id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.app_profile.name
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              set -e

              # ── Helper Functions ──────────────────────────────────────────
              wait_for_apt() {
                echo "Checking for apt locks..."
                while fuser /var/lib/dpkg/lock >/dev/null 2>&1 || fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ; do
                  echo "Waiting for other software managers to finish..."
                  sleep 5
                done
              }

              retry() {
                local n=1; local max=5; local delay=15
                while true; do
                  "$@" && break || {
                    if [[ $n -lt $max ]]; then
                      ((n++)); echo "Command failed. Attempt $n/$max. Retrying in $delay..."; sleep $delay;
                    else
                      echo "Command failed after $n attempts."; return 1
                    fi
                  }
                done
              }

              # Redirect output to log file for debugging
              exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
              echo "Starting resilient user_data script..."

              # ── Install Docker on Ubuntu 22.04 ──────────────────────────
              wait_for_apt
              retry apt-get update -y
              retry apt-get install -y ca-certificates curl gnupg lsb-release unzip

              # Add Docker's official GPG key
              install -m 0755 -d /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
              chmod a+r /etc/apt/keyrings/docker.asc

              # Add Docker apt repository
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

              wait_for_apt
              retry apt-get update -y
              retry apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
              systemctl start docker
              systemctl enable docker

              # ── Install AWS CLI v2 ───────────────────────────────────────
              retry curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
              retry unzip -q /tmp/awscliv2.zip -d /tmp/awscli
              retry /tmp/awscli/aws/install
              rm -rf /tmp/awscliv2.zip /tmp/awscli

              # ── Fetch secrets from SSM Parameter Store ───────────────────
              REGION="${var.aws_region}"
              GITHUB_TOKEN=$(retry aws ssm get-parameter --name "/taskflow/github_token" --with-decryption --region $REGION --query "Parameter.Value" --output text)

              # ── Login to GitHub Container Registry ───────────────────────
              echo "$GITHUB_TOKEN" | retry docker login ghcr.io -u GhlParth --password-stdin

              # ── Create custom nginx.conf ─────────────────────────────────
              mkdir -p /home/ubuntu/app
              cat > /home/ubuntu/app/nginx.conf << 'NGINX_CONF'
              server {
                  listen 8080;
                  server_name _;
                  root /usr/share/nginx/html;
                  index index.html index.htm;
                  gzip on;
                  gzip_types text/plain text/css text/javascript application/javascript application/json;
                  gzip_min_length 1000;
                  location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
                      expires 1y;
                      add_header Cache-Control "public, immutable";
                  }
                  
                  resolver 169.254.169.253 valid=30s;
                  
                  # API proxy - forward to backend via ALB DNS
                  location /api {
                      set $backend_url http://ALB_DNS_PLACEHOLDER;
                      proxy_pass $backend_url;
                      proxy_http_version 1.1;
                      proxy_set_header Upgrade $http_upgrade;
                      proxy_set_header Connection 'upgrade';
                      proxy_set_header Host $host;
                      proxy_set_header X-Real-IP $remote_addr;
                      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                      proxy_set_header X-Forwarded-Proto $scheme;
                      proxy_cache_bypass $http_upgrade;
                      
                      # Longer timeouts for backend processing
                      proxy_connect_timeout 60s;
                      proxy_send_timeout 60s;
                      proxy_read_timeout 60s;
                  }

                  # React Router SPA fallback
                  location / {
                      try_files $uri $uri/ /index.html;
                  }
                  location ~ /\. {
                      deny all;
                      access_log off;
                      log_not_found off;
                  }
              }
NGINX_CONF

              # Replace placeholder with actual ALB DNS name (crucial for Nginx startup)
              sed -i "s/ALB_DNS_PLACEHOLDER/${var.alb_dns_name}/g" /home/ubuntu/app/nginx.conf

              # ── Pull and run frontend container ──────────────────────────
              retry docker pull ghcr.io/ghlparth/taskflow-frontend:latest

              docker run -d \
                --name taskflow-frontend \
                --user root \
                --restart always \
                -p 80:8080 \
                -v /home/ubuntu/app/nginx.conf:/etc/nginx/conf.d/default.conf:ro \
                ghcr.io/ghlparth/taskflow-frontend:latest

              docker image prune -f
              echo "Resilient user_data script completed successfully!"
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-frontend"
      Tier = "frontend"
      OS   = "Ubuntu-22.04"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "frontend" {
  name                      = "${var.project_name}-frontend-asg"
  vpc_zone_identifier       = var.public_subnets
  target_group_arns         = [var.frontend_target_group_arn]
  health_check_type         = "ELB"
  health_check_grace_period = 600

  min_size         = 1
  max_size         = 3
  desired_capacity = 2

  launch_template {
    id      = aws_launch_template.frontend.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 100
      instance_warmup        = 300
    }
    triggers = ["tag"]
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-frontend"
    propagate_at_launch = true
  }

  tag {
    key                 = "Tier"
    value               = "frontend"
    propagate_at_launch = true
  }
}

# --- Frontend Auto Scaling Policies ---

resource "aws_autoscaling_policy" "frontend_scale_out" {
  name                   = "${var.project_name}-frontend-scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.frontend.name
}

resource "aws_cloudwatch_metric_alarm" "frontend_cpu_high" {
  alarm_name          = "${var.project_name}-frontend-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Scale out frontend ASG when avg CPU > 70%"
  alarm_actions       = [aws_autoscaling_policy.frontend_scale_out.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.frontend.name
  }
}

resource "aws_autoscaling_policy" "frontend_scale_in" {
  name                   = "${var.project_name}-frontend-scale-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.frontend.name
}

resource "aws_cloudwatch_metric_alarm" "frontend_cpu_low" {
  alarm_name          = "${var.project_name}-frontend-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 30
  alarm_description   = "Scale in frontend ASG when avg CPU < 30%"
  alarm_actions       = [aws_autoscaling_policy.frontend_scale_in.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.frontend.name
  }
}


# ==============================================================
# BACKEND TIER — Private Subnets (Multi-AZ), No Public IP, Port 5000
# Runs: taskflow-backend (Express.js REST API)
# ALB routes: /api/* → this ASG on port 5000
# SSH access: only via bastion (ssh -J ubuntu@<bastion_ip> ubuntu@<backend_private_ip>)
# ==============================================================

resource "aws_launch_template" "backend" {
  name_prefix   = "${var.project_name}-backend-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name

  network_interfaces {
    associate_public_ip_address = false  # Private only — SSH via bastion
    security_groups             = [var.app_sg_id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.app_profile.name
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              set -e

              # ── Helper Functions ──────────────────────────────────────────
              wait_for_apt() {
                echo "Checking for apt locks..."
                while fuser /var/lib/dpkg/lock >/dev/null 2>&1 || fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ; do
                  echo "Waiting for other software managers to finish..."
                  sleep 5
                done
              }

              retry() {
                local n=1; local max=5; local delay=15
                while true; do
                  "$@" && break || {
                    if [[ $n -lt $max ]]; then
                      ((n++)); echo "Command failed. Attempt $n/$max. Retrying in $delay..."; sleep $delay;
                    else
                      echo "Command failed after $n attempts."; return 1
                    fi
                  }
                done
              }

              # Redirect output to log file for debugging
              exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
              echo "Starting resilient user_data script (Backend)..."

              # ── Install Docker on Ubuntu 22.04 ──────────────────────────
              wait_for_apt
              retry apt-get update -y
              retry apt-get install -y ca-certificates curl gnupg lsb-release unzip

              install -m 0755 -d /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
              chmod a+r /etc/apt/keyrings/docker.asc

              echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

              wait_for_apt
              retry apt-get update -y
              retry apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
              systemctl start docker
              systemctl enable docker

              # ── Install AWS CLI v2 ───────────────────────────────────────
              retry curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
              retry unzip -q /tmp/awscliv2.zip -d /tmp/awscli
              retry /tmp/awscli/aws/install
              rm -rf /tmp/awscliv2.zip /tmp/awscli

              # ── Fetch secrets from SSM Parameter Store ───────────────────
              REGION="${var.aws_region}"
              GITHUB_TOKEN=$(retry aws ssm get-parameter --name "/taskflow/github_token" --with-decryption --region $REGION --query "Parameter.Value" --output text)
              MONGODB_URI=$(retry aws ssm get-parameter --name "/taskflow/mongodb_uri" --with-decryption --region $REGION --query "Parameter.Value" --output text)

              # ── Login to GitHub Container Registry ───────────────────────
              echo "$GITHUB_TOKEN" | retry docker login ghcr.io -u GhlParth --password-stdin

              # ── Pull and run backend container ────────────────────────────
              retry docker pull ghcr.io/ghlparth/taskflow-backend:latest

              docker run -d \
                --name taskflow-backend \
                --restart always \
                -p 5000:5000 \
                -e NODE_ENV=production \
                -e MONGODB_URI="$MONGODB_URI" \
                -e PORT=5000 \
                --health-cmd "node -e \"require('http').get('http://localhost:5000/health', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})\"" \
                --health-interval 30s \
                --health-retries 3 \
                ghcr.io/ghlparth/taskflow-backend:latest

              docker image prune -f
              echo "Backend deployment completed at $(date)"
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-backend"
      Tier = "backend"
      OS   = "Ubuntu-22.04"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "backend" {
  name                      = "${var.project_name}-backend-asg"
  vpc_zone_identifier       = var.private_app_subnets
  target_group_arns         = [var.backend_target_group_arn]
  health_check_type         = "ELB"
  health_check_grace_period = 600

  min_size         = 2
  max_size         = 4
  desired_capacity = 2

  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 100
      instance_warmup        = 300
    }
    triggers = ["tag"]
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-backend"
    propagate_at_launch = true
  }

  tag {
    key                 = "Tier"
    value               = "backend"
    propagate_at_launch = true
  }
}

# --- Backend Auto Scaling Policies ---

resource "aws_autoscaling_policy" "backend_scale_out" {
  name                   = "${var.project_name}-backend-scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.backend.name
}

resource "aws_cloudwatch_metric_alarm" "backend_cpu_high" {
  alarm_name          = "${var.project_name}-backend-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Scale out backend ASG when avg CPU > 70%"
  alarm_actions       = [aws_autoscaling_policy.backend_scale_out.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.backend.name
  }
}

resource "aws_autoscaling_policy" "backend_scale_in" {
  name                   = "${var.project_name}-backend-scale-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.backend.name
}

resource "aws_cloudwatch_metric_alarm" "backend_cpu_low" {
  alarm_name          = "${var.project_name}-backend-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 30
  alarm_description   = "Scale in backend ASG when avg CPU < 30%"
  alarm_actions       = [aws_autoscaling_policy.backend_scale_in.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.backend.name
  }
}
