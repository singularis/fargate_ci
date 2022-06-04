resource "aws_vpc" "Main" { # Creating VPC here
  cidr_block       = var.main_vpc_cidr
  instance_tenancy = "default"
  tags = {
    Name = "main"
  }
}

resource "aws_internet_gateway" "IGW" { # Creating Internet Gateway
  vpc_id = aws_vpc.Main.id
  tags = {
    Name = "igw for main"
  }
}

resource "aws_subnet" "publicsubnets" { # Creating Public Subnets
  vpc_id     = aws_vpc.Main.id
  cidr_block = var.public_subnets
  tags = {
    Name = "publicsubnets for main"
  }
}

resource "aws_subnet" "privatesubnets" {
  vpc_id     = aws_vpc.Main.id
  cidr_block = var.private_subnets # CIDR block of private subnets
  tags = {
    Name = "privatesubnets for main"
  }
}

resource "aws_route_table" "PublicRT" { # Creating RT for Public Subnet
  vpc_id = aws_vpc.Main.id
  route {
    cidr_block = "0.0.0.0/0" # Traffic from Public Subnet reaches Internet via Internet Gateway
    gateway_id = aws_internet_gateway.IGW.id
  }
  tags = {
    Name = "PublicRT for main"
  }
}

resource "aws_route_table" "PrivateRT" { # Creating RT for Private Subnet
  vpc_id = aws_vpc.Main.id
  route {
    cidr_block     = "0.0.0.0/0" # Traffic from Private Subnet reaches Internet via NAT Gateway
    nat_gateway_id = aws_nat_gateway.NATgw.id

  }
  tags = {
    Name = "PrivateRT for main"
  }
}

resource "aws_route_table_association" "PublicRTassociation" {
  subnet_id      = aws_subnet.publicsubnets.id
  route_table_id = aws_route_table.PublicRT.id

}

resource "aws_route_table_association" "PrivateRTassociation" {
  subnet_id      = aws_subnet.privatesubnets.id
  route_table_id = aws_route_table.PrivateRT.id

}

resource "aws_eip" "nateIP" {
  vpc = true
}

resource "aws_nat_gateway" "NATgw" {
  allocation_id = aws_eip.nateIP.id
  subnet_id     = aws_subnet.publicsubnets.id
}