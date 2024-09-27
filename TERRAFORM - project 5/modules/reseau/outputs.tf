output "vpc_id" {
  value       = aws_vpc.main.id
  description = "L'ID du VPC créé"
}

output "subnet_id" {
  value       = aws_subnet.main.id
  description = "L'ID du sous-réseau créé"
}
