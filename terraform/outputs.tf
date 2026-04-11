# ==================== NETWORKING OUTPUTS ====================

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "nat_gateway_ips" {
  description = "Public IPs of the NAT Gateways (Whitelist these in MongoDB Atlas)"
  value       = module.vpc.nat_gateway_ips
}

# ==================== ACCESS & DELIVERY OUTPUTS ====================

output "alb_dns_name" {
  description = "DNS name of the Load Balancer"
  value       = module.alb.alb_dns_name
}

output "cloudfront_domain_name" {
  description = "CloudFront URL (The recommended way to access your app)"
  value       = module.cloudfront.cloudfront_domain_name
}

output "route53_name_servers" {
  description = "Name servers for the Route53 hosted zone"
  value       = module.route53.name_servers
}

# ==================== COMPUTE (ASG) OUTPUTS ====================

output "frontend_asg_name" {
  description = "Name of the Frontend Auto Scaling Group"
  value       = module.asg.frontend_asg_name
}

output "backend_asg_name" {
  description = "Name of the Backend Auto Scaling Group"
  value       = module.asg.backend_asg_name
}

# ==================== BASTION SSH ACCESS ====================

output "bastion_public_ip" {
  description = "Public IP of the Bastion jump server"
  value       = module.bastion.bastion_public_ip
}

# ==================== DEPLOYMENT TIPS ====================
#
# Direct SSH to Frontend (via Public IP):
#   ssh -i keypair.pem ubuntu@<frontend_public_ip>
#
# SSH to Backend via Bastion:
#   ssh -i keypair.pem -J ubuntu@${module.bastion.bastion_public_ip} ubuntu@<backend_private_ip>
#
# To watch boot logs on an instance:
#   tail -f /var/log/user-data.log
