variable "region" {
  description = "Région pour toutes les ressources"
  type = string
}

variable "ami" {
  description = "AMI Ubuntu pour la région"
  type = string
}

variable "availability_zone" {
  description = "AZ pour le subnet"
  type        = string
}

variable "subnet_id" {
  description = "ID du subnet"
  type        = string
}

variable "security_group_id" {
  description = "ID du security group"
  type        = string
}
