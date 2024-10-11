terraform {
   backend "s3" {
     bucket         = "theracloud-terraform"
     key            = "terraform_project_3/terraform.tfstate"
     region         = "eu-west-1"
   }
}

resource "aws_instance" "web" {
  ami           = var.ami
  instance_type = var.instance_type
  count         = length(var.webservers)
  tags = {
    Name = var.webservers[count.index]
  } 
}




