output "public0a" {
  value = aws_subnet.public0a.id
}
output "public0b" {
  value = aws_subnet.public0b.id
}
output "public1a" {
  value = aws_subnet.public1a.id
}
output "public1b" {
  value = aws_subnet.public1b.id
}
output "public2a" {
  value = aws_subnet.public2a.id
}
output "public2b" {
  value = aws_subnet.public2b.id
}
output "public3a" {
  value = aws_subnet.public3a.id
}
output "public3b" {
  value = aws_subnet.public3b.id
}

output "security_group_id" {
  value = aws_security_group.kubeadv_instance_sg.id
}

output "key_name" {
  value = aws_key_pair.eu_central_1_kp.key_name
}

output "private_key_pem" {
  value     = tls_private_key.this.private_key_pem
  sensitive = true
}
