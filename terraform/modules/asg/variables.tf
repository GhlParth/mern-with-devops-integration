variable "project_name" {
  type        = string
  description = "Project name prefix for all resource names"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for both frontend and backend ASGs"
}

variable "key_name" {
  type        = string
  description = "Name of the EC2 Key Pair for SSH access"
}

variable "app_sg_id" {
  type        = string
  description = "Security Group ID shared by frontend and backend EC2 instances"
}

variable "public_subnets" {
  type        = list(string)
  description = "List of public subnet IDs — frontend ASG spans these (Multi-AZ)"
}

variable "private_app_subnets" {
  type        = list(string)
  description = "List of private subnet IDs — backend ASG spans these (Multi-AZ)"
}

variable "frontend_target_group_arn" {
  type        = string
  description = "ARN of the ALB Target Group for the frontend (port 80)"
}

variable "backend_target_group_arn" {
  type        = string
  description = "ARN of the ALB Target Group for the backend (port 5000)"
}

variable "aws_region" {
  type        = string
  description = "AWS region — used inside EC2 user_data to call SSM"
}
