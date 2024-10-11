provider "aws" {
  alias  = "eu_west_1"
  region = "eu-west-1"
}

provider "aws" {
  alias  = "eu_west_3"
  region = "eu-west-3"
}

data "aws_ami" "amazon_linux_2023_eu_west_1" {
  provider    = aws.eu_west_1
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.5.2024*x86_64"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


data "aws_ami" "amazon_linux_2023_eu_west_3" {
  provider    = aws.eu_west_3
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.5.2024*x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Définition des VPCs
resource "aws_vpc" "vpc_1" {
  provider   = aws.eu_west_1
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "VPC 1"
  }
}

resource "aws_vpc" "vpc_2" {
  provider   = aws.eu_west_3
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "VPC 2"
  }
}

# Création des subnets publics
resource "aws_subnet" "public_subnet_1" {
  provider                = aws.eu_west_1
  vpc_id                  = aws_vpc.vpc_1.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public Subnet VPC 1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  provider                = aws.eu_west_3
  vpc_id                  = aws_vpc.vpc_2.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-3a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public Subnet VPC 2"
  }
}

resource "aws_internet_gateway" "igw_1" {
  provider = aws.eu_west_1
  vpc_id   = aws_vpc.vpc_1.id

  tags = {
    Name = "IGW VPC 1"
  }
}

resource "aws_internet_gateway" "igw_2" {
  provider = aws.eu_west_3
  vpc_id   = aws_vpc.vpc_2.id

  tags = {
    Name = "IGW VPC 2"
  }
}

resource "aws_route_table" "rt_1" {
  provider = aws.eu_west_1
  vpc_id   = aws_vpc.vpc_1.id

  tags = {
    Name = "Route Table VPC 1"
  }
}

resource "aws_route_table" "rt_2" {
  provider = aws.eu_west_3
  vpc_id   = aws_vpc.vpc_2.id

  tags = {
    Name = "Route Table VPC 2"
  }
}

resource "aws_route_table_association" "rt_1_public_subnet_1" {
  provider = aws.eu_west_1
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.rt_1.id
}

resource "aws_route_table_association" "rt_2_public_subnet_2" {
  provider = aws.eu_west_3
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.rt_2.id
}


resource "aws_route" "default_route_1" {
  provider               = aws.eu_west_1
  route_table_id         = aws_route_table.rt_1.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw_1.id
}

resource "aws_route" "default_route_2" {
  provider               = aws.eu_west_3
  route_table_id         = aws_route_table.rt_2.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw_2.id
}


# Création de l'instance profile pour pouvoir se connecter à chacune des instances
resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "SSMInstanceProfile"
  role = "AmazonSSMRoleForInstancesQuickSetup"
}

# Création du groupe de sécurité pour le serveur web instance 2
resource "aws_security_group" "web_sg" {
  provider    = aws.eu_west_3
  name        = "allow_http"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.vpc_2.id

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

# Création des instances EC2
resource "aws_instance" "instance_1" {
  provider             = aws.eu_west_1
  ami                  = data.aws_ami.amazon_linux_2023_eu_west_1.id
  instance_type        = "t3.micro"
  subnet_id            = aws_subnet.public_subnet_1.id
  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name
  tags = {
    Name = "Instance 1"
  }
}

resource "aws_instance" "instance_2" {
  provider             = aws.eu_west_3
  ami                  = data.aws_ami.amazon_linux_2023_eu_west_3.id
  instance_type        = "t3.micro"
  subnet_id            = aws_subnet.public_subnet_2.id
  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from Instance 2 in VPC 2</h1>" > /var/www/html/index.html
              EOF
  tags = {
    Name = "Instance 2"
  }
}

# NLB in VPC2
resource "aws_lb" "nlb" {
  provider           = aws.eu_west_3
  name               = "vpc2-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = [aws_subnet.public_subnet_2.id]
}

# Création du Target Group
resource "aws_lb_target_group" "instance_tg" {
  provider    = aws.eu_west_3
  name        = "instance-target-group"
  port        = 80
  protocol    = "TCP"
  vpc_id      = aws_vpc.vpc_2.id
  target_type = "instance"

  health_check {
    protocol = "TCP"
    port     = 80
  }
}

# Création du Listener pour le NLB
resource "aws_lb_listener" "front_end" {
  provider    = aws.eu_west_3
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"

  depends_on = [aws_lb.nlb]

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.instance_tg.arn
  }
}

# Enregistrement de l'instance comme cible
resource "aws_lb_target_group_attachment" "instance_attachment" {
  provider           = aws.eu_west_3
  target_group_arn = aws_lb_target_group.instance_tg.arn
  target_id        = aws_instance.instance_2.id
  port             = 80
}


# Endpoint Service in VPC2
resource "aws_vpc_endpoint_service" "endpoint_service" {
  provider                   = aws.eu_west_3
  acceptance_required        = false
  network_load_balancer_arns = [aws_lb.nlb.arn]
}

# VPC Endpoint in VPC1
resource "aws_vpc_endpoint" "vpc_endpoint" {
  provider            = aws.eu_west_1
  vpc_id              = aws_vpc.vpc_1.id
  service_name        = aws_vpc_endpoint_service.endpoint_service.service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.public_subnet_1.id]
  security_group_ids  = [aws_security_group.endpoint_sg.id]
  private_dns_enabled = false
    depends_on = [aws_vpc_endpoint_service.endpoint_service]
}

# Security Group for VPC Endpoint
resource "aws_security_group" "endpoint_sg" {
  provider = aws.eu_west_1
  vpc_id   = aws_vpc.vpc_1.id
  
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc_1.cidr_block]
  }
}