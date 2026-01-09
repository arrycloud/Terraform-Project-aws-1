// Terraform Project Task 1 //
#1.Create vpc
#2.Create internet Gateway
#3.Create Custom Route Table
#4.Create a Subnet
#5.Associate subnet with Route Table
#6.Create Security Group to allow port 22,80,443
#7.Create a network interface with an ip in the subnet that was created in step 4
#8.Assign an elastic IP to the network interface created in step 7
#9.Create ubuntu server and install/enable apache2


# main.tf
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                   = "us-east-1" # Change to your preferred region
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "dipo-vs-aws-terraform"
}

# 1. Create VPC
resource "aws_vpc" "web_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "WebServer-VPC"
  }
}

# 2. Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.web_vpc.id
  tags = {
    Name = "WebServer-IGW"
  }
}

# 3. Create Custom Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.web_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public-RouteTable"
  }
}

# 4. Create Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.web_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a" # Change to your AZ
  map_public_ip_on_launch = true
  tags = {
    Name = "Public-Subnet"
  }
}

# 5. Associate Subnet with Route Table
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# 6. Create Security Group
resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  description = "Allow SSH, HTTP, HTTPS"
  vpc_id      = aws_vpc.web_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict to your IP in production
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "WebServer-SG"
  }
}

# 7. Create Network Interface
resource "aws_network_interface" "web_nic" {
  subnet_id       = aws_subnet.public_subnet.id
  private_ips     = ["10.0.1.5"]
  security_groups = [aws_security_group.web_sg.id]
  tags = {
    Name = "WebServer-NIC"
  }
}

# 8. Assign Elastic IP
resource "aws_eip" "web_eip" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.web_nic.id
  associate_with_private_ip = "10.0.1.5"
  depends_on                = [aws_internet_gateway.igw]
  tags = {
    Name = "WebServer-EIP"
  }
}

# NOTE
resource "aws_key_pair" "test-keypair" {
  key_name   = "dipokey"
  public_key = file("~/.ssh/dipokeypair.pub")
}

# 9. Create Ubuntu Server with Apache
resource "aws_instance" "web_server" {
  ami               = "ami-084568db4383264d4" # Ubuntu 22.04 LTS in us-east-1
  instance_type     = "t2.micro"
  key_name          = aws_key_pair.test-keypair.id # Change to your existing key pair
  availability_zone = "us-east-1a"

  network_interface {
    network_interface_id = aws_network_interface.web_nic.id
    device_index         = 0
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y apache2
              systemctl start apache2
              systemctl enable apache2
              echo "<h1>Hello from Terraform!</h1>" > /var/www/html/index.html
              EOF

  # NOTE: Below script is another approach to install Apache2
  //user_data = <<-EDF
  //#!/bin/bash
  //sudo apt update -y
  //sudo apt install apache2 -y
  //sudo systemctl start apache2
  //sudo bash -c 'echo your very first web server > /var/www/html/index.html
  //EDF                             

  tags = {
    Name = "WebServer"
  }
}

output "public_ip" {
  value = aws_eip.web_eip.public_ip
}

output "website_url" {
  value = "http://${aws_eip.web_eip.public_ip}"
}