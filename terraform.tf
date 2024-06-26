provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "terraformvpc"
  }
}
resource "aws_subnet" "pubsub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "publicsubnet"
  }
}
resource "aws_subnet" "privsub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "privatesubnet"
  }
}
resource "aws_internet_gateway" "tigw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "IGW"
  }
}
resource "aws_route_table" "pubrt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tigw.id
  }



  tags = {
    Name = "publicRT"
  }
}
resource "aws_route_table_association" "pubassociation" {
  subnet_id      = aws_subnet.pubsub.id
  route_table_id = aws_route_table.pubrt.id
}
resource "aws_eip" "eip" {
  vpc      = true
}
resource "aws_nat_gateway" "tnat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.pubsub.id
  tags = {
    Name = "natgw"
  }
}
resource "aws_route_table" "privrt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.tnat.id
  }



  tags = {
    Name = "privateRT"
  }
}
resource "aws_route_table_association" "privassociation" {
  subnet_id      = aws_subnet.privsub.id
  route_table_id = aws_route_table.privrt.id
}
resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "allow_all"
  }
}
resource "aws_instance" "publicmachine" {
  ami                         =  "ami-007020fd9c84e18c7"
  instance_type               =  "t2.micro"  
  subnet_id                   =  aws_subnet.pubsub.id
  key_name                    =  "Mumbai"
  vpc_security_group_ids      =  ["${aws_security_group.allow_all.id}"]
  associate_public_ip_address =  true
}
resource "aws_instance" "private" {
  ami                         =  "ami-007020fd9c84e18c7"
  instance_type               =  "t2.micro"  
  subnet_id                   =  aws_subnet.privsub.id
  key_name                    =  "Mumbai"
  vpc_security_group_ids      =  ["${aws_security_group.allow_all.id}"]
  
}
