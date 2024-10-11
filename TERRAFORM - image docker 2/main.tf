provider "aws" {
  region = "eu-west-1"  # Remplacez par votre région AWS préférée
}

resource "aws_security_group" "web_server_sg" {
  name        = "web-server-sg"
  description = "Security group for web server"

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_http"
  }
}

resource "aws_instance" "web" {
  ami = var.ami
  instance_type = var.instance_type
  count = length(var.webservers)
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello trainees from $(hostname -f)</h1>" > /var/www/html/index.html
              EOF

  vpc_security_group_ids = [aws_security_group.web_server_sg.id]
  iam_instance_profile   = "AmazonSSMRoleForInstancesQuickSetup"
  tags = {
    Name = var.webservers[count.index]
  } 
}