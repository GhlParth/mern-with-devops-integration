output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain (use this to access the app)"
  value       = module.cloudfront.cloudfront_domain_name
}

output "route53_name_servers" {
  description = "Name servers for the Route53 hosted zone — configure these at your registrar"
  value       = module.route53.name_servers
}

# ==================== COMPUTE OUTPUTS ====================

output "frontend_asg_name" {
  description = "Frontend Auto Scaling Group name (public subnets, port 80)"
  value       = module.asg.frontend_asg_name
}

output "backend_asg_name" {
  description = "Backend Auto Scaling Group name (private subnets, port 5000)"
  value       = module.asg.backend_asg_name
}

# ==================== BASTION SSH ACCESS ====================

output "bastion_public_ip" {
  description = "Public IP of the Bastion host — SSH jump server for backend instances"
  value       = module.bastion.bastion_public_ip
}

output "bastion_instance_id" {
  description = "Instance ID of the Bastion host"
  value       = module.bastion.bastion_instance_id
}

# ==================== SSH QUICK REFERENCE ====================
# Use these in terraform output after apply:
#
# Direct SSH to a FRONTEND instance (get its public IP from EC2 console):
#   ssh -i my-keypair.pem ubuntu@<frontend_instance_public_ip>
#
# SSH to a BACKEND instance via Bastion jump:
#   ssh -i my-keypair.pem -J ubuntu@<bastion_public_ip> ubuntu@<backend_private_ip>
#
# Or configure ~/.ssh/config for convenience:
#   Host bastion
#     HostName <bastion_public_ip>
#     User ubuntu
#     IdentityFile ~/.ssh/my-keypair.pem
#
#   Host backend-*
#     User ubuntu
#     IdentityFile ~/.ssh/my-keypair.pem
#     ProxyJump bastion

# output "rds_endpoint" {
#   value = module.database.db_instance_endpoint
# }
