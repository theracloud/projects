terraform {
   backend "s3" {
     bucket         = "theracloud-terraform"
     key            = "create-EC2-instance/terraform.tfstate"
     region         = "eu-west-1"
   }
}





