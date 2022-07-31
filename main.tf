variable "aws_access_key" {}


variable "aws_secret_key" {}

variable "ssh_Key_name" {}

variable "private_Key_path" {}

variable "region" {
  default = "ap-south-1"
}
variable "vpccidr" {
  default = "172.31.0.0/16"
}
variable "subnet" {
  default = "172.31.0.0/24"
}

provider "aws" {
  aws_access_key = var.aws_access_key
  aws_secret_key = var.aws_secret_key
  region         = var.region
}

resource "aws_vpc" "vpc1" {
  Cidr_block           = var.vpccidr
  enable_dns_hostnames = "true"
}

resource "aws_subnet" "sub" {
  vpc_id     = aws_vpc.vpc1.id
  cidr_block = var.subnet
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc1.id
}
resource "aws_route_table" "rc" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = var.subnet
    gateway_id = aws_internet_gateway.gw.id
  }
}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.sub.id
  route_table_id = aws_route_table.rc.id
}
resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc1.id


  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.vpc1.cidr_block]
    ipv6_cidr_blocks = [aws_vpc.vpc1.ipv6_cidr_block]
  }
  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.vpc1.cidr_block]
    ipv6_cidr_blocks = [aws_vpc.vpc1.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.sub.id
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  key_name               = var.ssh_Key_name
  connection {
    type        = "ssh"
    host        = self.public
    user        = ubuntu
    private_key = file(var.private_Key_path)
  }
}
