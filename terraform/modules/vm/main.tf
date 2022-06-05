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

resource "aws_network_interface" "default_server" {
  subnet_id   = var.publicsubnets_id
  private_ips = ["10.0.0.129"]

  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  network_interface {                                                          
    network_interface_id = aws_network_interface.default_server.id
    device_index         = 0
  }
  key_name = "dante-new"

  credit_specification {
    cpu_credits = "unlimited"
  }
  tags = {
    Name = "ExampleAppServerInstance"
  }
  depends_on = [
    data.aws_ami.ubuntu,
    aws_network_interface.default_server
  ]
}

resource "aws_network_interface" "default_slave" {
  subnet_id   = var.privatesubnets_id
  private_ips = ["10.0.0.193"]

  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_instance" "app_slave" {
  count         = var.count_slave
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  network_interface {                                                          
    network_interface_id = aws_network_interface.default_slave.id
    device_index         = 0
  }
  key_name = "dante-new"

  credit_specification {
    cpu_credits = "unlimited"
  }
  tags = {
    Name = "ExampleAppServerInstance"
  }
  depends_on = [
    data.aws_ami.ubuntu,
    aws_network_interface.default_slave
  ]
}