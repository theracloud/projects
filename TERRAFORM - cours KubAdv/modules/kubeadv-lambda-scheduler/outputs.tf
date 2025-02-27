output "all_resource_names" {
  value = [for resource in local.all_resources : resource.function_name]
  description = "Names of all resources created by this Terraform configuration"
}

locals {
  all_resources = [
    aws_lambda_function.kubeadv_lambda_ec2_control

    # Ajoutez ici toutes les autres ressources que vous voulez inclure
  ]
}
