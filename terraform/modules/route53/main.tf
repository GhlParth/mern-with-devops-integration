terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "aws_route53_zone" "primary" {
  name = var.domain_name

  tags = {
    Project = var.project_name
  }
}

# The A records for the domain will be added in main.tf/cloudfront module 
# after the CloudFront distribution is created.

output "hosted_zone_id" {
  value = aws_route53_zone.primary.zone_id
}

output "name_servers" {
  value = aws_route53_zone.primary.name_servers
}

# ==================== MOVED BLOCKS (State Migration) ====================
moved {
  from = aws_route53_zone.this
  to   = aws_route53_zone.primary
}
