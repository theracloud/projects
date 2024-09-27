variable "ami" {}
variable "region" {}
variable "instance_type" {}
variable "access_key" {}
variable "secret_key" {}
variable "subnet_id" {}


# Création de l'instance EC2
resource "aws_instance" "web-terraform-cloud" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  tags = {
    Name = self.id
  }
}
