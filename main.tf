terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
    region = "us-east-1"
}

resource "aws_instance" "ec2-1" {
  ami           = "ami-087c17d1fe0178315"
  instance_type = "t2.micro"

  tags = {
    Name = "tf ec2 instance"
  }
}