// defining the provider and profile
provider "aws" {
 region = "ap-south-1"
 profile = "sarthakphatate"
}

// Creating the key for remote login or SSH

resource "tls_private_key" "skey" {
  algorithm  = "RSA"
  rsa_bits   = 4096
}
resource "aws_key_pair" "sshkey-2" {
  key_name   = "sshkey-2"
  public_key = tls_private_key.skey.public_key_openssh
}

// Creating VPC with CIDR Block

resource "aws_vpc" "vpc1"{
cidr_block = "192.168.0.0/16"
instance_tenancy = "default"
enable_dns_hostnames = "true"

tags = {
Name = "vpc1"
}
}

// Creating Public Subnet

resource "aws_subnet" "public" {

vpc_id = aws_vpc.vpc1.id

cidr_block = "192.168.10.0/24"

availability_zone = "ap-south-1a"

map_public_ip_on_launch = "true"

tags = {

Name = "public-subnet"

}

}

// Creating Private Subnet

resource "aws_subnet" "private" {

vpc_id = aws_vpc.vpc1.id

cidr_block = "192.168.20.0/24"

availability_zone = "ap-south-1b"

tags = {

Name = "private-subnet"

}

}

// Creating Internet Gateway for public subnet for internet access
resource "aws_internet_gateway" "gateway" {

vpc_id = aws_vpc.vpc1.id

tags = {

Name = "gateway"

}

}

// routing table for Internet gateway so that instance can connect to outside world, update and associate it with public subnet.

resource "aws_route_table" "route" {

vpc_id = aws_vpc.vpc1.id

route {
cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.gateway.id
}

tags = {
Name = "route"
}

}

resource "aws_route_table_association" "asso"{
subnet_id = aws_subnet.public.id
route_table_id = aws_route_table.route.id
}

// Creating Security Group for wordpress

resource "aws_security_group" "wpSG" {

name = "wpSG"

description = "Allow inbound traffic"

vpc_id = aws_vpc.vpc1.id

ingress {
from_port = 80
to_port = 80
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

ingress {
from_port = 22
to_port = 22
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

egress {
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
}

tags = {

Name = "wpSG"

}

}

// Creating Security Group for mysql

resource "aws_security_group" "mysqlSG"{
 name = "mysqlSG"
 vpc_id = aws_vpc.vpc1.id

 ingress {

 from_port = 3306
 to_port   = 3306
 protocol  = "tcp"
 cidr_blocks = ["0.0.0.0/0"]
 }
  ingress {
 
  from_port = 22
  to_port   = 22
  protocol  = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
   from_port  = 0
   to_port    = 0
   protocol   = "-1"
   cidr_blocks  = ["0.0.0.0/0"]
  }
}

// Launching ec2 instance which has wordpress installed and user can connect on port 80

resource "aws_instance" "wordpress"{
ami   = "ami-00116985822eb866a"
instance_type = "t2.micro"
key_name = "sshkey-2"
vpc_security_group_ids = [ aws_security_group.wpSG.id]
subnet_id = aws_subnet.public.id

tags = {
 Name = "wordpress"
  }
} 

resource "aws_instance" "webserver" {
ami      = "ami-08706cb5f68222d09"
instance_type = "t2.micro"
key_name = "sshkey-2"
vpc_security_group_ids = [ aws_security_group.mysqlSG.id]
subnet_id = aws_subnet.private.id

 tags = {
 Name = "mysql"
 }
}
