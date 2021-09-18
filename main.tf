terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  // Creds are local env
}


// Create new vpc
resource "aws_vpc" "vpc-1" {
  cidr_block = "10.0.0.0/16"
  tags = {
      Name = "vpc-1 with tf"
  }
}

// Create new internet gateway
resource "aws_internet_gateway" "gw-1" {
  vpc_id = aws_vpc.vpc-1.id
  tags = {
    Name = "main internet gateway"
  }
}

// Create custom route table
resource "aws_route_table" "route-table-1" {
  vpc_id = aws_vpc.vpc-1.id

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.gw-1.id
  }
  route {
      ipv6_cidr_block        = "::/0"
      gateway_id = aws_internet_gateway.gw-1.id
  }
  

  tags = {
    Name = "Custom route table"
  }
}

// Create subnet
resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.vpc-1.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "prod-subnet"
  }
}

// Associate subnet with route table
resource "aws_route_table_association" "a" {
    subnet_id = aws_subnet.subnet-1.id
    route_table_id = aws_route_table.route-table-1.id
}

// Create security group
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.vpc-1.id

  ingress {
      description      = "HTTPS"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
      description      = "HTTP"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
  }
  
  ingress {
      description      = "SSH"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
  }

  
  egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-web"
  }
}

// Create network interface
resource "aws_network_interface" "web-serve-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}

// Create elastic ip
resource "aws_eip" "eip-1" {
    vpc = true
    network_interface = aws_network_interface.web-serve-nic.id
    associate_with_private_ip = "10.0.1.50"
    depends_on = [aws_internet_gateway.gw-1]
}

// Create new ec2 instance 
resource "aws_instance" "ec2-1" {
    ami           = "ami-09e67e426f25ce0d7"
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"
    key_name = "main-key"
    network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.web-serve-nic.id
    }

    // Install apache2 server
    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y 
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo your very first web server > /var/www/html/index.html'
                EOF
    tags = {
        Name = "terraform ec2 instance"
    }
}