variable "vpc_id" {
  description = "ID du VPC où le serveur sera déployé"
  type        = string
}

variable "subnet_id" {
  description = "ID du sous-réseau où le serveur sera déployé"
  type        = string
}

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t2.micro"
}
