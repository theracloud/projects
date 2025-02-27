# Définition du VPC
resource "aws_vpc" "kubeadv-vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "kubeadv-vpc"    
  }
}

# Subnet public 0a
resource "aws_subnet" "public0a" {
  vpc_id     = aws_vpc.kubeadv-vpc.id
  cidr_block = "10.0.0.0/26"
  availability_zone = var.availability_zone_a
  map_public_ip_on_launch = true

  tags = {
    Name = "kubeadv-vpc-public-subnet0a"
    "kubernetes.io/role/elb" = "1"
  }
}
# Subnet public 0b
resource "aws_subnet" "public0b" {
  vpc_id     = aws_vpc.kubeadv-vpc.id
  cidr_block = "10.0.0.64/26"
  availability_zone = var.availability_zone_b
  map_public_ip_on_launch = true

  tags = {
    Name = "kubeadv-vpc-public-subnet0b"
    "kubernetes.io/role/elb" = "1"
  }
}
# Subnet public 1a
resource "aws_subnet" "public1a" {
  vpc_id     = aws_vpc.kubeadv-vpc.id
  cidr_block = "10.0.1.0/26"
  availability_zone = var.availability_zone_a
  map_public_ip_on_launch = true

  tags = {
    Name = "kubeadv-vpc-public-subnet1a"
    "kubernetes.io/role/elb" = "1"
  }
}
# Subnet public 1b
resource "aws_subnet" "public1b" {
  vpc_id     = aws_vpc.kubeadv-vpc.id
  cidr_block = "10.0.1.64/26"
  availability_zone = var.availability_zone_b
  map_public_ip_on_launch = true

  tags = {
    Name = "kubeadv-vpc-public-subnet1b"
    "kubernetes.io/role/elb" = "1"
  }
}
# Subnet public 2a
resource "aws_subnet" "public2a" {
  vpc_id     = aws_vpc.kubeadv-vpc.id
  cidr_block = "10.0.2.0/26"
  availability_zone = var.availability_zone_a
  map_public_ip_on_launch = true

  tags = {
    Name = "kubeadv-vpc-public-subnet2a"
    "kubernetes.io/role/elb" = "1"
  }
}
# Subnet public 2b
resource "aws_subnet" "public2b" {
  vpc_id     = aws_vpc.kubeadv-vpc.id
  cidr_block = "10.0.2.64/26"
  availability_zone = var.availability_zone_b
  map_public_ip_on_launch = true

  tags = {
    Name = "kubeadv-vpc-public-subnet2b"
    "kubernetes.io/role/elb" = "1"
  }
}
# Subnet public 3a
resource "aws_subnet" "public3a" {
  vpc_id     = aws_vpc.kubeadv-vpc.id
  cidr_block = "10.0.3.0/26"
  availability_zone = var.availability_zone_a
  map_public_ip_on_launch = true

  tags = {
    Name = "kubeadv-vpc-public-subnet2a"
    "kubernetes.io/role/elb" = "1"
  }
}
# Subnet public 3b
resource "aws_subnet" "public3b" {
  vpc_id     = aws_vpc.kubeadv-vpc.id
  cidr_block = "10.0.3.64/26"
  availability_zone = var.availability_zone_b
  map_public_ip_on_launch = true

  tags = {
    Name = "kubeadv-vpc-public-subnet3b"
    "kubernetes.io/role/elb" = "1"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.kubeadv-vpc.id

  tags = {
    Name = "kubeadv-vpc-igw"
  }
}

# Route table pour le subnet public
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.kubeadv-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "kubeadv-vpc-public-rt"
  }
}

# Association de la route table au subnet public 0a
resource "aws_route_table_association" "public0a" {
  subnet_id      = aws_subnet.public0a.id
  route_table_id = aws_route_table.public.id
}
# Association de la route table au subnet public 0b
resource "aws_route_table_association" "public0b" {
  subnet_id      = aws_subnet.public0b.id
  route_table_id = aws_route_table.public.id
}
# Association de la route table au subnet public 1a
resource "aws_route_table_association" "public1a" {
  subnet_id      = aws_subnet.public1a.id
  route_table_id = aws_route_table.public.id
}
# Association de la route table au subnet public 1b
resource "aws_route_table_association" "public1b" {
  subnet_id      = aws_subnet.public1b.id
  route_table_id = aws_route_table.public.id
}
# Association de la route table au subnet public 2a
resource "aws_route_table_association" "public2a" {
  subnet_id      = aws_subnet.public2a.id
  route_table_id = aws_route_table.public.id
}
# Association de la route table au subnet public 2b
resource "aws_route_table_association" "public2b" {
  subnet_id      = aws_subnet.public2b.id
  route_table_id = aws_route_table.public.id
}
# Association de la route table au subnet public 3a
resource "aws_route_table_association" "public3a" {
  subnet_id      = aws_subnet.public3a.id
  route_table_id = aws_route_table.public.id
}
# Association de la route table au subnet public 3b
resource "aws_route_table_association" "public3b" {
  subnet_id      = aws_subnet.public3b.id
  route_table_id = aws_route_table.public.id
}

/*--------Tout ce paragraphe sera ignoré pour éviter de mettre en place une NatGW et des subnets privés
# Subnet privé 0a
resource "aws_subnet" "private0a" {
  vpc_id     = aws_vpc.kubeadv-vpc.id
  cidr_block = "10.0.0.128/26"
  availability_zone = var.availability_zone_a

  tags = {
    Name = "kubeadv-vpc-private-subnet0"
  }
}
# Subnet privé 1a
resource "aws_subnet" "private1a" {
  vpc_id     = aws_vpc.kubeadv-vpc.id
  cidr_block = "10.0.1.128/26"
  availability_zone = var.availability_zone_a

  tags = {
    Name = "kubeadv-vpc-private-subnet1a"
  }
}

# Subnet privé 2a
resource "aws_subnet" "private2a" {
  vpc_id     = aws_vpc.kubeadv-vpc.id
  cidr_block = "10.0.2.128/26"
  availability_zone = var.availability_zone_a

  tags = {
    Name = "kubeadv-vpc-private-subnet2a"
  }
}
# Subnet privé 3a
resource "aws_subnet" "private3a" {
  vpc_id     = aws_vpc.kubeadv-vpc.id
  cidr_block = "10.0.3.128/26"
  availability_zone = var.availability_zone_a

  tags = {
    Name = "kubeadv-vpc-private-subnet3a"
  }
}

# NAT Gateway pour les subnets privés
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "kubeadv-vpc-nat"
  }
}

# Elastic IP pour la NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
}

# Route table pour le subnet privé
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.kubeadv-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
   # nat_gateway_id = aws_nat_gateway.nat.id
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "kubeadv-vpc-private-rt"
  }
}

# Association de la route table au subnet privé 0a
resource "aws_route_table_association" "private0a" {
  subnet_id      = aws_subnet.private0a.id
  route_table_id = aws_route_table.private.id
}

# Association de la route table au subnet privé 1a
resource "aws_route_table_association" "private1a" {
  subnet_id      = aws_subnet.private1a.id
  route_table_id = aws_route_table.private.id
}

# Association de la route table au subnet privé 2a
resource "aws_route_table_association" "private2a" {
  subnet_id      = aws_subnet.private2a.id
  route_table_id = aws_route_table.private.id
}

# Association de la route table au subnet privé 3a
resource "aws_route_table_association" "private3a" {
  subnet_id      = aws_subnet.private3a.id
  route_table_id = aws_route_table.private.id
}
---------*/




resource "aws_ec2_managed_prefix_list" "kubeadv_ip_prefix_list" {
  name           = "kubeadv-ip-prefix-list"
  address_family = "IPv4"
  max_entries    = 3  # Augmentez cette valeur pour permettre plus d'entrées

  entry {
    cidr        = "176.189.59.253/32"
    description = "My first IP address"
  }

  entry {
    cidr        = "1.1.1.1/32"
    description = "My second IP address"
  }
}

resource "aws_security_group" "kubeadv_instance_sg" {
  name        = "kubeadv-instance-sg"
  vpc_id      = aws_vpc.kubeadv-vpc.id  # Référence au VPC précédemment créé

  # Règle d'entrée pour le port HTTP depuis Internet
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic from anywhere"
  }

  # Règle d'entrée pour le port HTTPS depuis Internet
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS traffic from anywhere"
  }

  # Règle d'entrée pour le port TCP 6443 depuis kubeadv-ip-prefix-list
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    prefix_list_ids  = [aws_ec2_managed_prefix_list.kubeadv_ip_prefix_list.id]
    description = "Allow Kubectl traffic from kubeadv-ip-prefix-list"
  }

  # Règle d'entrée pour le port SSH depuis kubeadv-ip-prefix-list
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    prefix_list_ids  = [aws_ec2_managed_prefix_list.kubeadv_ip_prefix_list.id]
    description = "Allow Kubectl traffic from kubeadv-ip-prefix-list"
  }

  # Règle d'entrée pour le port TCP 8080 depuis kubeadv-ip-prefix-list
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    prefix_list_ids  = [aws_ec2_managed_prefix_list.kubeadv_ip_prefix_list.id]
    description = "Allow TCP 8080 traffic from kubeadv-ip-prefix-list"
  }

  # Règle d'entrée pour le range TCP 30000-32767 depuis kubeadv-ip-prefix-list
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    prefix_list_ids  = [aws_ec2_managed_prefix_list.kubeadv_ip_prefix_list.id]
    description = "Allow NodePort traffic from kubeadv-ip-prefix-list"
  }

  # Règle d'entrée pour ICMP-All depuis kubeadv-ip-prefix-list
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    prefix_list_ids  = [aws_ec2_managed_prefix_list.kubeadv_ip_prefix_list.id]
    description = "Allow ICMP traffic from kubeadv-ip-prefix-list"
  }

  # Règle d'entrée pour tout le trafic depuis le SG lui-même
  ingress {
    from_port                = 0
    to_port                  = 0
    protocol                 = "-1"
    self                     = true
    description = "Allow traffic inside the SG itself"
  }

  # Règle de sortie par défaut (tout le trafic autorisé)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "kubeadv-instance-sg"
  }
}

# Création d'une Key Pair pour les instances EC2
  resource "tls_private_key" "this" {
    algorithm = "RSA"
    rsa_bits  = 4096
  }
  resource "aws_key_pair" "eu_central_1_kp" {
    key_name   = "eu-central-1-kp"
    public_key = tls_private_key.this.public_key_openssh
  }


