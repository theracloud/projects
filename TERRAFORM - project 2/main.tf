resource "aws_instance" "web" {
  ami = var.ami
  instance_type = var.instance_type
  count = length(var.webservers)
  tags = {
    Name = var.webservers[count.index]
  } 
}