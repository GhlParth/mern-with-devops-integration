variable "project_name" {
  description = "Project name prefix for resource naming"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID where the bastion will be placed"
  type        = string
}

variable "bastion_sg_id" {
  description = "Security Group ID for the bastion host"
  type        = string
}

variable "key_name" {
  description = "Name of the EC2 Key Pair for SSH access"
  type        = string
}
