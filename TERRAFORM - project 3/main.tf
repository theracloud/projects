resource "aws_instance" "web" {
  ami           = var.ami
  instance_type = var.instance_type
  count         = length(var.webservers)
  tags = {
    Name = var.webservers[count.index]
  } 
}

variable "instance_names" {
  type    = list(string)
  default = []
}

locals {
  webservers = var.instance_names != [] ? var.instance_names : var.webservers
}

resource "null_resource" "prompt_for_instances" {
  count = var.instance_names == [] ? 1 : 0

  provisioner "local-exec" {
    command = <<EOT
      echo "Entrez les noms des instances (terminez par #) :"
      names=""
      while true; do
        read -p "Nom de l'instance (ou # pour terminer) : " name
        if [ "$name" = "#" ]; then
          break
        fi
        names="$names \"$name\""
      done
      echo "instance_names = [$names]" >> terraform.tfvars
    EOT
    interpreter = ["bash", "-c"]
  }
}
