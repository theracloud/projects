module "eu-central-1_kubeadv-ubuntu0" {
  source = "../modules/kubeadv-ubuntu0"
  region = "eu-central-1"
  ami = "ami-03b3b5f65db7e5c6f"
  availability_zone = "eu-central-1a"
  subnet_id         = "subnet-0b6ab9fb8c9b0f1db"
  security_group_id = "sg-0151dfb1b604ac25f"
}



