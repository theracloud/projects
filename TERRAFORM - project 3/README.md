## TERRAFORM - project 3   
-Ne pas mettre de default dans variables.tf pour entrer le nom des instances sous la forme d'une liste  
-Exemple: ["web1","web2"]  
-Utiliser un remote backend s3 pour enregistrer le terraform.tfstate dans S3 
-J'ai créé un sous-répertoire "terraform destroy - remote backend" afin de faire un terraform destroy depuis un répertoire vierge  
-Il ne contient qu'un fichier main.tf avec les informations du remote backend s3 seulement:  

*terraform {*  
*backend "s3" {*  
*bucket         = "theracloud-terraform"*  
*key            = "terraform_project_3/terraform.tfstate"*  
*region         = "eu-west-1"*  
*}*  
*}*  

-Pour supprimer les ressources depuis ce sous-folder, il faut taper:

*terraform init*  
*terraform state pull > terraform.tfstate*  
*terraform destroy*  

 
