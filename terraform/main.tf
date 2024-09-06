terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "5.60.0"
    }
  }
}

provider "aws" {
    region = "eu-central-1"
}

variable "vpc_id" {
    type = string
}

variable "subnet" {
    type = string
}

variable "client_cidr" {
    type = string
}

variable "os_type" {
    description = "Operating system to use"
    type = string
    validation {
        condition = contains(["ubuntu", "amazon"], var.os_type)
        error_message = "Only the following choices are available: 'ubuntu', 'amazon'"
    }
}

locals {
    ami_name_regexp = (var.os_type == "amazon" ? "al2023-ami-*-x86_64" : "ubuntu/images/*24.04-amd64-server-*" )
    ami_owner = (var.os_type == "amazon" ? "137112412989" : "099720109477" )
    ansible_user = (var.os_type == "amazon" ? "ec2-user" : "ubuntu" )
}

data "aws_ami" "linux" {
    most_recent = true

    filter {
        name = "name"
        values = [local.ami_name_regexp]
    }

    owners = [local.ami_owner]
}

resource "aws_security_group" "whitelist" {
    name = "allow_only_client"
    vpc_id = var.vpc_id

    tags = {
        Name = "allow_only_client"
    }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
    security_group_id = aws_security_group.whitelist.id
    cidr_ipv4 = var.client_cidr
    from_port = 22
    to_port = 22
    ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_jenkins_port" {
    security_group_id = aws_security_group.whitelist.id
    cidr_ipv4 = var.client_cidr
    from_port = 8080
    to_port = 8080
    ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_ipv4" {
  security_group_id = aws_security_group.whitelist.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_ipv6" {
  security_group_id = aws_security_group.whitelist.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1"
}

resource "aws_instance" "jenkins" {
    ami =  data.aws_ami.linux.id
    instance_type = "t3.small"

    associate_public_ip_address = true
    key_name = aws_key_pair.ansible.key_name
    vpc_security_group_ids = [aws_security_group.whitelist.id]
    subnet_id = var.subnet


    tags = {
        Name = "jenkins"
    }
}

resource "aws_key_pair" "ansible" {
    key_name = "ansible"
    public_key = file("~/.ssh/ansible.pub")
}

output "ami_linux_id" {
    value = data.aws_ami.linux.id
}

output "ec2_public_ip" {
    value = aws_instance.jenkins.public_ip
}

resource "local_file" "ansible_inventory" {
  content  = templatefile("${path.module}/inventory_template.ini.tftpl", {
    instance_ip = aws_instance.jenkins.public_ip
    ansible_user = local.ansible_user
  })
  filename = "${path.module}/../ansible/inventory.ini"
}
