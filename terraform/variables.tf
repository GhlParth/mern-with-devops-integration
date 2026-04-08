variable "aws_region" {
  description = "AWS Region to deploy resource"
  type        = string
  default     = "us-east-1" # As suggested in the plan
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "mern-devops"
}

variable "domain_name" {
  description = "The domain name for the application"
  type        = string
  default     = "devhubbusiness.online"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets_cidrs" {
  description = "CIDR blocks for the public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_app_subnets_cidrs" {
  description = "CIDR blocks for the private app subnets"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}


variable "instance_type" {
  description = "Instance type for the EC2 instances"
  type        = string
  default     = "t3.micro"
}


variable "github_token" {
  description = "GitHub Personal Access Token for GHCR login"
  type        = string
  sensitive   = true
}

variable "mongodb_uri" {
  description = "MongoDB Atlas Connection String"
  type        = string
  sensitive   = true
}

variable "key_name" {
  description = "Name of the EC2 Key Pair to use for SSH access to EC2 instances"
  type        = string
}

variable "notification_email" {
  description = "Email address for alert notifications"
  type        = string
  default     = "parthnghl001@gmail.com"
}
