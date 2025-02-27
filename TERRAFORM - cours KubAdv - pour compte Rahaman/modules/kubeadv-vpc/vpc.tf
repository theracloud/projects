# Définition du VPC
resource "aws_vpc" "k8s-vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "k8s-vpc"
  }
}

# Subnet public 0
resource "aws_subnet" "public0" {
  vpc_id     = aws_vpc.k8s-vpc.id
  cidr_block = "10.0.0.0/25"
  availability_zone = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "k8s-vpc-public-subnet0"
  }
}

# Subnet privé 0
resource "aws_subnet" "private0" {
  vpc_id     = aws_vpc.k8s-vpc.id
  cidr_block = "10.0.0.128/25"
  availability_zone = var.availability_zone

  tags = {
    Name = "k8s-vpc-private-subnet0"
  }
}

# Subnet public 1
resource "aws_subnet" "public1" {
  vpc_id     = aws_vpc.k8s-vpc.id
  cidr_block = "10.0.1.0/25"
  availability_zone = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "k8s-vpc-public-subnet1"
  }
}

# Subnet privé 1
resource "aws_subnet" "private1" {
  vpc_id     = aws_vpc.k8s-vpc.id
  cidr_block = "10.0.1.128/25"
  availability_zone = var.availability_zone

  tags = {
    Name = "k8s-vpc-private-subnet1"
  }
}

# Subnet public 2
resource "aws_subnet" "public2" {
  vpc_id     = aws_vpc.k8s-vpc.id
  cidr_block = "10.0.2.0/25"
  availability_zone = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "k8s-vpc-public-subnet2"
  }
}

# Subnet privé 2
resource "aws_subnet" "private2" {
  vpc_id     = aws_vpc.k8s-vpc.id
  cidr_block = "10.0.2.128/25"
  availability_zone = var.availability_zone

  tags = {
    Name = "k8s-vpc-private-subnet2"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.k8s-vpc.id

  tags = {
    Name = "k8s-vpc-igw"
  }
}

# Route table pour le subnet public
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.k8s-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "k8s-vpc-public-rt"
  }
}

# Association de la route table au subnet public 0
resource "aws_route_table_association" "public0" {
  subnet_id      = aws_subnet.public0.id
  route_table_id = aws_route_table.public.id
}

# Association de la route table au subnet public 1
resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

# Association de la route table au subnet public 2
resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

/* Tout ce paragraphe sera ignoré pour éviter la dépense d'une NatGW
# NAT Gateway pour le subnet privé
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "k8s-vpc-nat"
  }
}

# Elastic IP pour le NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
}
*/


# Route table pour le subnet privé
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.k8s-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
   # nat_gateway_id = aws_nat_gateway.nat.id
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "k8s-vpc-private-rt"
  }
}

# Association de la route table au subnet privé 0
resource "aws_route_table_association" "private0" {
  subnet_id      = aws_subnet.private0.id
  route_table_id = aws_route_table.private.id
}

# Association de la route table au subnet privé 1
resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private.id
}

# Association de la route table au subnet privé 2
resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "k8s_sg" {
  name        = "k8s-SG"
  vpc_id      = aws_vpc.k8s-vpc.id  # Référence au VPC précédemment créé

  # Règle d'entrée pour le port custom 6643 depuis mon IP
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["176.189.59.253/32"]  # Remplacer par votre adresse IP réelle
  }

  # Règle d'entrée pour tout le trafic depuis le SG lui-même
  ingress {
    from_port                = 0
    to_port                  = 0
    protocol                 = "-1"
    self                     = true
  }

  # Règle d'entrée pour ICMP-All depuis mon IP
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["176.189.59.253/32"]  # Remplacer par votre adresse IP réelle
  }

  # Règle de sortie par défaut (tout le trafic autorisé)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k8s-SG"
  }
}

