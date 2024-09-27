resource "aws_instance" "serveur" {
  ami           = "ami-0fed63ea358539e44"  # Amazon Linux 2 AMI (exemple)
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  tags = {
    Name = "Serveur Principal"
  }
}
