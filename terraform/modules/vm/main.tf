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

resource "aws_network_interface" "default" {
  subnet_id   = var.privatesubnets_id
  private_ips = ["172.16.10.100"]

  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_instance" "app_server" {
  count         = var.count
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  network_interface {                                                          
    network_interface_id = aws_network_interface.default.id
    device_index         = 0
  }

  credit_specification {
    cpu_credits = "unlimited"
  }
  tags = {
    Name = "ExampleAppServerInstance"
  }
  depends_on = [
    aws_ami.ubuntu,
    aws_network_interface.default
  ]
}