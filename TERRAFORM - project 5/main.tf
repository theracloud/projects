provider "aws" {
  region = var.region
}

module "reseau" {
  source = "./modules/reseau"
  vpc_cidr = var.vpc_cidr
}

module "serveur" {
  source = "./modules/serveur"
  vpc_id = module.reseau.vpc_id
  subnet_id = module.reseau.subnet_id
  instance_type = var.instance_type
}
