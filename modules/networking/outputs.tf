output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "pseudo_private_subnet_ids" {
  value = aws_subnet.pseudo_private[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}