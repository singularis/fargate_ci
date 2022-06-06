# Main VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Main VPC"
  }
}

# Public Subnet with Default Route to Internet Gateway
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.11.0/24"

  tags = {
    Name = "Public Subnet"
  }
}

# Private Subnet with Default Route to NAT Gateway
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.21.0/24"

  tags = {
    Name = "Private Subnet"
  }
}

# Main Internal Gateway for VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Main IGW"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
  tags = {
    Name = "NAT Gateway EIP"
  }
}

# Main NAT Gateway for VPC
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "Main NAT Gateway"
  }
}

# Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
    route {
    cidr_block = "172.31.0.0/16"
    gateway_id = aws_vpc_peering_connection.todef.id
  }
  tags = {
    Name = "Public Route Table"
  }
}

# Association between Public Subnet and Public Route Table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Route Table for Private Subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }
  route {
    cidr_block = "172.31.0.0/16"
    gateway_id = aws_vpc_peering_connection.todef.id
  }

  tags = {
    Name = "Private Route Table"
  }
}

# Association between Private Subnet and Private Route Table
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "iva-sg-master-slave" {
  name        = "Terraform Security Group Slave"
  description = "Terraform Security Group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0",
    "172.31.0.0/16"
    ]
  }
  ingress {
  cidr_blocks = ["0.0.0.0/0"]
  from_port   = 8
  to_port     = 0
  protocol    = "icmp"
  description = "Allow all ping4"
}
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

}

resource "aws_instance" "Master"{
  ami                    = "ami-092cce4a19b438926"
  instance_type          = "t3.micro"
  key_name               = "dante-new"
  subnet_id              = aws_subnet.public.id
  associate_public_ip_address = true
  private_ip             = "10.0.11.10"
  vpc_security_group_ids = [aws_security_group.iva-sg-master-slave.id]
    tags = {
    Name = "Master"
  }
}

resource "aws_instance" "Slave" {
  ami                    = "ami-092cce4a19b438926"
  instance_type          = "t3.micro"
  key_name               = "dante-new"
  subnet_id              = aws_subnet.private.id
  private_ip             = "10.0.21.10"
  vpc_security_group_ids = [aws_security_group.iva-sg-master-slave.id]
    tags = {
    Name = "Slave"
  }
}

resource "aws_vpc_peering_connection" "todef" {
  peer_vpc_id   = aws_vpc.main.id
  vpc_id        = "vpc-063df4e9508599d88"
  auto_accept   = true
  tags = {
    Name = "todef"
  }
}

resource "aws_vpc_peering_connection_accepter" "peer" {
  vpc_peering_connection_id = aws_vpc_peering_connection.todef.id
  auto_accept               = true

  tags = {
    Side = "Accepter"
  }
}

resource "aws_route" "primary2secondary" {
  # ID of VPC 1 main route table.
  route_table_id = "rtb-03c4fab2363018ae5"

  # CIDR block / IP range for VPC 2.
  destination_cidr_block = "${aws_vpc.main.cidr_block}"

  # ID of VPC peering connection.
  vpc_peering_connection_id = "${aws_vpc_peering_connection.todef.id}"
}

resource "aws_route" "secondary2primary" {
  # ID of VPC 2 main route table.
  route_table_id = "${aws_vpc.main.main_route_table_id}"

  # CIDR block / IP range for VPC 2.
  destination_cidr_block = "172.31.0.0/16"

  # ID of VPC peering connection.
  vpc_peering_connection_id = "${aws_vpc_peering_connection.todef.id}"
}