variable "project_name" {
  type        = string
  description = "Project name"
}

variable "private_db_subnets" {
  type        = list(string)
  description = "Private DB subnets for the RDS instance"
}

variable "db_sg_id" {
  type        = string
  description = "Security Group ID for the Database Tier"
}

variable "db_name" {
  type        = string
  description = "Database name"
  default     = "taskdb"
}

variable "db_username" {
  type        = string
  description = "Database username"
}

variable "db_password" {
  type        = string
  description = "Database password"
  sensitive   = true
}
