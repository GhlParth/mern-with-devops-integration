terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# ==================== DATA SOURCE ====================
# Ubuntu 22.04 LTS (Jammy) — Canonical official AMI

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# ==================== BASTION HOST ====================
# SSH jump server — sits in public subnet with a public IP
# Use this to reach backend instances in private subnets:
#   ssh -i my-keypair.pem -J ubuntu@<bastion_ip> ubuntu@<backend_private_ip>

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"   # t3.micro is Free Tier eligible in ap-south-1
  subnet_id                   = var.public_subnet_id
  associate_public_ip_address = true
  vpc_security_group_ids      = [var.bastion_sg_id]
  key_name                    = var.key_name

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              hostnamectl set-hostname ${var.project_name}-bastion
              EOF

  tags = {
    Name = "${var.project_name}-bastion"
    Role = "Bastion"
    OS   = "Ubuntu-22.04"
  }
}
