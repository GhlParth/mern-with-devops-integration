module "vpc" {
  source = "./modules/vpc"

  project_name              = var.project_name
  vpc_cidr                  = var.vpc_cidr
  public_subnets_cidrs      = var.public_subnets_cidrs
  private_app_subnets_cidrs = var.private_app_subnets_cidrs
  private_db_subnets_cidrs  = var.private_db_subnets_cidrs
}

module "security_groups" {
  source = "./modules/security_groups"

  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
}

module "alb" {
  source = "./modules/alb"

  project_name   = var.project_name
  vpc_id         = module.vpc.vpc_id
  alb_sg_id      = module.security_groups.alb_sg_id
  public_subnets = module.vpc.public_subnets
}

# ==================== COMPUTE (Frontend + Backend ASGs) ====================
# Frontend ASG: public subnets, public IP, port 80, scale on CPU
# Backend ASG:  private subnets, no public IP, port 5000, scale on CPU
module "asg" {
  source = "./modules/asg"

  project_name              = var.project_name
  instance_type             = var.instance_type
  key_name                  = var.key_name
  app_sg_id                 = module.security_groups.app_sg_id
  public_subnets            = module.vpc.public_subnets
  private_app_subnets       = module.vpc.private_app_subnets
  frontend_target_group_arn = module.alb.frontend_target_group_arn
  backend_target_group_arn  = module.alb.backend_target_group_arn
  aws_region                = var.aws_region
}

# ==================== BASTION HOST ====================
# Single t2.micro in public_subnets[1] (different AZ from common ops)
# SSH jump server for accessing private backend instances
module "bastion" {
  source = "./modules/bastion"

  project_name     = var.project_name
  public_subnet_id = module.vpc.public_subnets[1]   # Use second public subnet (AZ-b)
  bastion_sg_id    = module.security_groups.bastion_sg_id
  key_name         = var.key_name
}

# module "database" {
#   source = "./modules/database"
#
#   project_name       = var.project_name
#   private_db_subnets = module.vpc.private_db_subnets
#   db_sg_id           = module.security_groups.db_sg_id
#   db_name            = var.db_name
#   db_username        = var.db_username
#   db_password        = var.db_password
# }

module "route53" {
  source = "./modules/route53"

  project_name = var.project_name
  domain_name  = var.domain_name
}

module "acm" {
  source = "./modules/acm"
  providers = {
    aws = aws.us_east_1
  }

  project_name   = var.project_name
  domain_name    = var.domain_name
  hosted_zone_id = module.route53.hosted_zone_id
}

module "cloudfront" {
  source = "./modules/cloudfront"

  project_name        = var.project_name
  domain_name         = var.domain_name
  alb_dns_name        = module.alb.alb_dns_name
  acm_certificate_arn  = module.acm.certificate_arn
  hosted_zone_id      = module.route53.hosted_zone_id
}

# ==================== SSM PARAMETERS ====================
# Secrets fetched by EC2 user_data scripts at boot time

resource "aws_ssm_parameter" "github_token" {
  name      = "/taskflow/github_token"
  type      = "SecureString"
  value     = var.github_token
  overwrite = true
}

resource "aws_ssm_parameter" "env_file" {
  name        = "/taskflow/env_file"
  description = "Environment variables for TaskFlow containers"
  type        = "SecureString"
  value       = "PORT=5000"  # Placeholder; updated by GitHub Actions deploy.yml
  overwrite   = true
  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "mongodb_uri" {
  name      = "/taskflow/mongodb_uri"
  type      = "SecureString"
  value     = var.mongodb_uri
  overwrite = true
}
