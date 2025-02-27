variable "ami" {
  description = "AMI Ubuntu pour la région"
  type = string
}

variable "subnet_id" {
  description = "ID du subnet"
  type        = string
}

variable "security_group_id" {
  description = "ID du security group"
  type        = string
}

variable "key_name" {
  description = "key pair pour eu-central-1"
  type        = string
}

variable "instance_profile" {
  description = "Nom de l'instance profile pour les instances"
  type        = string
}