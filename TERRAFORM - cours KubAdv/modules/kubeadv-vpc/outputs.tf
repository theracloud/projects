output "subnet_id" {
  value = aws_subnet.public0.id
}

output "security_group_id" {
  value = aws_security_group.k8s_sg.id
}
