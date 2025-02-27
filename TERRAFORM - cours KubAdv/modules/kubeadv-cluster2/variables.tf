variable "ami" {
  description = "AMI Ubuntu pour la région"
  type = string
}

variable "key_pair" {
  description = "Key pair pour eu-central-1"
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
