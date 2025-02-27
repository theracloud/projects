output "student0_password" {
  value = aws_iam_user_login_profile.student0_profile.password
  sensitive = true
}

output "student1_password" {
  value = aws_iam_user_login_profile.student1_profile.password
  sensitive = true
}

output "student0_key" {
  value = format("%s / %s", aws_iam_access_key.student0_key.id, aws_iam_access_key.student0_key.secret)
  sensitive = true
}

output "student1_key" {
  value = format("%s / %s", aws_iam_access_key.student1_key.id, aws_iam_access_key.student1_key.secret)
  sensitive = true
}

output "kubeadv_student_policy" {
  value = aws_iam_policy.kubeadv_student_policy.name
}

output "instance_profile" {
  value = aws_iam_instance_profile.kubeadv_ec2_instance_profile.name
  description = "Nom de l'instance profile pour les instances EC2"
}
