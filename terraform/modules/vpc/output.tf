output "publicsubnets_id" {
  value = aws_subnet.publicsubnets.id
}

output "privatesubnets_id" {
  value = aws_subnet.privatesubnets.id
}

output "vpc_id" {
  value = aws_vpc.Main.id
}
