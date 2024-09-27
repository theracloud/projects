resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "VPC Principal"
  }
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, 1)

  tags = {
    Name = "Subnet Principal"
  }
}
