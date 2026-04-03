output "alb_sg_id" {
  description = "Security Group ID for the Application Load Balancer"
  value       = aws_security_group.alb_sg.id
}

output "app_sg_id" {
  description = "Security Group ID shared by frontend and backend EC2 instances"
  value       = aws_security_group.app_sg.id
}

output "bastion_sg_id" {
  description = "Security Group ID for the Bastion host"
  value       = aws_security_group.bastion_sg.id
}

# output "db_sg_id" {
#   value = aws_security_group.db_sg.id
# }
