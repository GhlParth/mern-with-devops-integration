variable "vpc_id" {
  type        = string
  description = "ID of the VPC"
}

variable "project_name" {
  type        = string
  description = "Project name"
}

variable "alb_sg_id" {
  type        = string
  description = "Security Group ID for the ALB"
}

variable "public_subnets" {
  type        = list(string)
  description = "Public subnets for the ALB"
}
