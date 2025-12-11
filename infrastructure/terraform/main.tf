terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# 1. Create a Security Group (Firewall)
# This defines who can talk to our server.
resource "aws_security_group" "app_sg" {
  name        = "${var.project_name}-sg-v2"
  description = "Allow web and ssh traffic"

  # Allow HTTP traffic on port 5000 (where our Flask app runs)
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow from anywhere
  }

  # Allow SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow standard HTTP (for later if we use Nginx)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outgoing traffic to anywhere (needed to download Docker, etc)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. Find the latest Ubuntu 22.04 AMI (Amazon Machine Image)
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical (creators of Ubuntu)
}

# 3. Create the EC2 Instance (Server)
resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  # User Data: This script runs ONLY once when the server first boots.
  # We use it to install Docker so the server is ready to run our containers.
  user_data = <<-EOF
              #!/bin/bash
              echo "Starting setup..."
              
              # Update and install Docker
              apt-get update
              apt-get install -y docker.io docker-compose
              
              # Start Docker service
              systemctl start docker
              systemctl enable docker
              
              # Add current user to docker group
              usermod -aG docker ubuntu
              
              echo "Setup complete!"
              EOF

  tags = {
    Name = "${var.project_name}-server"
  }
}
