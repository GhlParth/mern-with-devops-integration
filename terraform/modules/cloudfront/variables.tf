variable "alb_dns_name" {
  type        = string
  description = "DNS name of the ALB"
}

variable "project_name" {
  type        = string
  description = "Project name"
}

variable "domain_name" {
  type        = string
  description = "Domain name for the aliases"
}

variable "acm_certificate_arn" {
  type        = string
  description = "ARN of the ACM certificate"
}

variable "hosted_zone_id" {
  type        = string
  description = "Route 53 hosted zone ID for alias records"
}
