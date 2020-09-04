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
resource "aws_key_pair" "sshkey" {
  key_name   = "sshkey"
  public_key = tls_private_key.skey.public_key_openssh
}

// Creating VPC with CIDR Block

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"

  tags = {
    Name = "vpc"
  }
}

// Creating Public Subnet

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "public-subnet"
  }
}

// Creating Private Subnet

resource "aws_subnet" "private" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "private-subnet"
  }
}

// Creating Internet Gateway for public subnet for internet access
resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.vpc.id
  
  tags = {
    Name = "gateway"
  }
}

// routing table for Internet gateway so that instance can connect to outside world, update and associate it with public subnet.

resource "aws_route_table" "route" {
  vpc_id = aws_vpc.vpc.id

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

resource "aws_eip" "EIP" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.EIP.id
  subnet_id  = aws_subnet.public.id

  tags = {
    Name= "nat"
  }
}

resource "aws_route_table" "nat_route" {
  vpc_id = aws_vpc.vpc.id

  route{
    cidr_block= "0.0.0.0/0"
    nat_gateway_id=aws_nat_gateway.nat.id
 }

  tags = {
    Name= "nat_route" 
  }
}

resource "aws_route_table_association" "nat_asso" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.nat_route.id
}

// Creating Security Group for wordpress

resource "aws_security_group" "wpSG" {
  name = "wpSG"
  description = "Allow inbound traffic"
  vpc_id = aws_vpc.vpc.id

  ingress {
    description = "Tcp"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ssh"
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
  vpc_id = aws_vpc.vpc.id

  ingress {
    description = "Tcp"
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
  
  ingress {
    from_port  = -1
    to_port    = -1
    protocol   = "icmp"
    cidr_blocks  = ["0.0.0.0/0"]
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
  ami = "ami-000cbce3e1b899ebd"
  instance_type = "t2.micro"
  key_name = "sshkey"
  vpc_security_group_ids = [ aws_security_group.wpSG.id]
  subnet_id = aws_subnet.public.id

  tags = {
    Name = "wordpress"
  }
}

resource "aws_instance" "mysql" {
  ami = "ami-0019ac6129392a0f2"
  instance_type = "t2.micro"
  key_name = "sshkey"
  vpc_security_group_ids = [ aws_security_group.mysqlSG.id]
  subnet_id = aws_subnet.private.id
  
  tags = {
    Name = "mysql"
 }
}
