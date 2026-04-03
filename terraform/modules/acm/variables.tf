variable "domain_name" {
  type        = string
  description = "Domain name for the certificate"
}

variable "project_name" {
  type        = string
  description = "Project name"
}

variable "hosted_zone_id" {
  type        = string
  description = "ID of the Route 53 Hosted Zone"
}
