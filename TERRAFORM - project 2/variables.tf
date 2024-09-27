variable "ami" {
  default = "ami-0fed63ea358539e44"  # AMI Amazon Linux 2023 pour eu-west-1
}
variable "instance_type" {
  default = "t3.micro"
}
variable "webservers" {
  type = list
  default = ["web1", "web2", "web3"]
}