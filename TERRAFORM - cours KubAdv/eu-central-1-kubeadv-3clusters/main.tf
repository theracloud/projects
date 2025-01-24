module "eu-central-1_kubeadv-cluster0" {
  source = "../modules/kubeadv-cluster0"
  region = "eu-central-1"
  ami = "ami-03b3b5f65db7e5c6f"
  availability_zone = "eu-central-1a"
  subnet_id         = module.eu-central-1_kubeadv-vpc.subnet_id
  security_group_id = module.eu-central-1_kubeadv-vpc.security_group_id
}

module "eu-central-1_kubeadv-cluster1" {
  source = "../modules/kubeadv-cluster1"
  region = "eu-central-1"
  ami = "ami-03b3b5f65db7e5c6f"
  availability_zone = "eu-central-1a"
  subnet_id         = module.eu-central-1_kubeadv-vpc.subnet_id
  security_group_id = module.eu-central-1_kubeadv-vpc.security_group_id
}

module "eu-central-1_kubeadv-cluster2" {
  source = "../modules/kubeadv-cluster2"
  region = "eu-central-1"
  ami = "ami-03b3b5f65db7e5c6f"
  availability_zone = "eu-central-1a"
  subnet_id         = module.eu-central-1_kubeadv-vpc.subnet_id
  security_group_id = module.eu-central-1_kubeadv-vpc.security_group_id
}

module "eu-central-1_kubeadv-vpc" {
  source = "../modules/kubeadv-vpc"
  availability_zone = "eu-central-1a"
}