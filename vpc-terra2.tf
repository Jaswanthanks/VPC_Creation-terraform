//Terraform block

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~>4.0"
    }
  }
}

//Provider Block

provider "aws" {
  region = "ap-south-1"
  
}

// VPC creation block

resource "aws_vpc" "jash-vpc" {
  cidr_block = ""
  instance_tenancy = "default"
  

  tags = {
    Name = "TF-VPC"
  }
}

// VPC (TF-VPC) PUBLIC SUBNET :

resource "aws_subnet" "public_Subnet" {
  vpc_id = aws_vpc.jash-vpc.id
  cidr_block = ""
  availability_zone = "ap-south-1a"

  tags = {
    Name  = "TF-Public_Subnet"
  }
}

// Creating Internet Gateway - IGW

resource "aws_internet_gateway" "tigw" {
  vpc_id = aws_vpc.jash-vpc.id
  tags = {
    Name = "TF-IGW"
  }
}

// Creating Route Table for Public Subnet

resource "aws_route_table" "public_routetable" {
  vpc_id = aws_vpc.jash-vpc.id
  
  route{
    cidr_block = ""
    gateway_id = aws_internet_gateway.tigw.id
  }
  tags = {
    Name = "TF-Public-routetable"
  }
}

// Associating Route Table to the Subnet

resource "aws_route_table_association" "publicassociation" {
  subnet_id = aws_subnet.public_Subnet.id
  route_table_id = aws_route_table.public_routetable.id
}


// Create Private Subnet :

resource "aws_subnet" "Private_Subnet" {
  vpc_id = aws_vpc.jash-vpc.id
  cidr_block = ""
  availability_zone = "ap-south-1b"
  tags = {
    Name = "TF-PrivateSubnet"
  }
}

//Create Elastic IP for NAT usage : 

resource "aws_eip" "t-elastic_ip" {
  vpc = true
}

//Creating NAT Gateway : 

resource "aws_nat_gateway" "tf-nat" {
  allocation_id = aws_eip.t-elastic_ip.id
  subnet_id = aws_subnet.Private_Subnet.id

  tags = {
    Name = "TF-NAT"
  }
}

// Creating Route table for Private subnet

resource "aws_route_table" "Private_routetable" {
  vpc_id = aws_vpc.jash-vpc.id

  route{
    cidr_block = ""
    gateway_id = aws_nat_gateway.tf-nat.id
  }
  tags = {
    Name = "TF-Private_rt"
  }
}

// Allow all inbound traffic Security Group

resource "aws_security_group" "allow_all" {
  name = "Allow-all"
  description = "Allow all inbound traffic"
  vpc_id = aws_vpc.jash-vpc.id

  ingress{
    description = "TLS from vpc"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [""]
  }

  egress{
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [""]
  }
  tags = {
    Name = "tf-sg"
  }
}

//Public Access EC2 - Instance : 

resource "aws_instance" "public" {
  ami = "ami-0b7207e48d1b6c06f"
  instance_type = "t2.micro"
  availability_zone = "ap-south-1a"
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.allow_all.id]
  subnet_id = aws_subnet.public_Subnet.id

  tags = {
    Name = "Public-instance"
  }
}

//Private EC2 - Instance : 

resource "aws_instance" "private" {
  ami = "ami-0b7207e48d1b6c06f"
  instance_type = "t2.micro"
  availability_zone = "ap-south-1b"
  associate_public_ip_address = false
  vpc_security_group_ids = [aws_security_group.allow_all.id]
  subnet_id = aws_subnet.Private_Subnet.id
  tags = {
    Name = "Private-instance"
  }
  
}