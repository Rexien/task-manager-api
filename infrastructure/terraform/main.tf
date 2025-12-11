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

# 1. Create a Random ID to prevent name collisions in stateless CI
resource "random_id" "sg_suffix" {
  byte_length = 4
}

# 2. Create a Security Group (Firewall)
# Name includes random suffix so it never conflicts
resource "aws_security_group" "app_sg" {
  name        = "${var.project_name}-sg-${random_id.sg_suffix.hex}"
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
              
              # 1. Install Docker & Docker Compose
              apt-get update
              apt-get install -y docker.io docker-compose git
              
              # 2. Start Docker
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ubuntu

              # 3. Clone the Repo
              cd /home/ubuntu
              git clone https://github.com/Rexien/task-manager-api.git
              cd task-manager-api

              # 4. Start the App (Background)
              # Use the checked-in deployment script or direct docker-compose
              docker-compose up -d

              echo "Setup complete! App is running on port 80."
              EOF

  tags = {
    Name = "${var.project_name}-server"
  }
}
