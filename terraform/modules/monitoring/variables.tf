variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "notification_email" {
  description = "Email address for alert notifications"
  type        = string
}

variable "alb_arn" {
  description = "ARN of the Application Load Balancer"
  type        = string
}

variable "frontend_asg_name" {
  description = "Name of the Frontend Auto Scaling Group"
  type        = string
}

variable "backend_asg_name" {
  description = "Name of the Backend Auto Scaling Group"
  type        = string
}
