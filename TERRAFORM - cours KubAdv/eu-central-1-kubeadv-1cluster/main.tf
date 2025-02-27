module "eu-central-1_kubeadv-cluster0" {
  source = "../modules/kubeadv-cluster0"
  ami    = "ami-03b3b5f65db7e5c6f"
  subnet_id         = module.eu-central-1_kubeadv-vpc.public0a
  security_group_id = module.eu-central-1_kubeadv-vpc.security_group_id
  key_name          = module.eu-central-1_kubeadv-vpc.key_name
  instance_profile  = module.eu-central-1_kubeadv-iam.instance_profile
}

module "eu-central-1_kubeadv-vpc" {
  source = "../modules/kubeadv-vpc"
  availability_zone_a = "eu-central-1a"
  availability_zone_b = "eu-central-1b"
}

module "eu-central-1_kubeadv-iam" {
  source = "../modules/kubeadv-iam"
}

module "eu-central-1_kubeadv-lambda-scheduler" {
  source = "../modules/kubeadv-lambda-scheduler"
}

####################### OUTPUT MODULE VPC ########################
output "security_group_id" {
  value = module.eu-central-1_kubeadv-vpc.security_group_id
}

output "key_name" {
  value = module.eu-central-1_kubeadv-vpc.key_name
}

output "public0a" {
  value = module.eu-central-1_kubeadv-vpc.public0a
}
output "public0b" {
  value = module.eu-central-1_kubeadv-vpc.public0b
}
output "public1a" {
  value = module.eu-central-1_kubeadv-vpc.public1a
}
output "public1b" {
  value = module.eu-central-1_kubeadv-vpc.public1b
}
output "public2a" {
  value = module.eu-central-1_kubeadv-vpc.public2a
}
output "public2b" {
  value = module.eu-central-1_kubeadv-vpc.public2b
}
output "public3a" {
  value = module.eu-central-1_kubeadv-vpc.public3a
}
output "public3b" {
  value = module.eu-central-1_kubeadv-vpc.public3b
}

####################### OUTPUT MODULE IAM ########################
output "private_key_pem" {
  value = module.eu-central-1_kubeadv-vpc.private_key_pem
  sensitive = true
}

output "student0_password" {
  value = module.eu-central-1_kubeadv-iam.student0_password
  sensitive = true
}

output "student0_key" {
  value = module.eu-central-1_kubeadv-iam.student0_key
  sensitive = true
}

output "student1_password" {
  value = module.eu-central-1_kubeadv-iam.student1_password
  sensitive = true
}

output "student1_key" {
  value = module.eu-central-1_kubeadv-iam.student1_key
  sensitive = true
}

output "instance_profile" {
  value = module.eu-central-1_kubeadv-iam.instance_profile
}

####################### OUTPUT MODULE LAMBDA-SCHEDULER ########################
output "all_resource_names" {
  value = module.eu-central-1_kubeadv-lambda-scheduler.all_resource_names
}


