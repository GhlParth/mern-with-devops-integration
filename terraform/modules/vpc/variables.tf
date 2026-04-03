variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "project_name" {
  type        = string
  description = "Project name for tagging"
}

variable "public_subnets_cidrs" {
  type        = list(string)
  description = "CIDR blocks for public subnets"
}

variable "private_app_subnets_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private application subnets"
}

variable "private_db_subnets_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private database subnets"
}
