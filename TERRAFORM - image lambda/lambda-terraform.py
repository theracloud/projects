import os
import subprocess
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info("Starting Lambda function")
    
    logger.info(f"Current PATH: {os.environ['PATH']}")
    logger.info(f"Content of /opt/bin: {os.listdir('/opt/bin')}")
    
    os.environ['PATH'] = f"/opt/bin:{os.environ['PATH']}"
    logger.info(f"Updated PATH: {os.environ['PATH']}")
    
    try:
        terraform_version = subprocess.run(["terraform", "-version"], capture_output=True, text=True)
        logger.info(f"Terraform version: {terraform_version.stdout}")
    except Exception as e:
        logger.error(f"Error running terraform -version: {str(e)}")
    

    
    # Récupérez les fichiers Terraform depuis S3
    s3 = boto3.client('s3')
    s3.download_file('theracloud-terraform', 'create-EC2-instance/main.tf', '/tmp/main.tf')
    s3.download_file('theracloud-terraform', 'create-EC2-instance/variables.tf', '/tmp/variables.tf')
    s3.download_file('theracloud-terraform', 'create-EC2-instance/backend.tf', '/tmp/backend.tf')
    
    logger.info("Initializing Terraform")
    init_result = subprocess.run(["terraform", "init"], cwd="/tmp", capture_output=True, text=True)
    logger.info(f"Terraform init output: {init_result.stdout}\n{init_result.stderr}")

    logger.info("Applying Terraform configuration")
    apply_result = subprocess.run(["terraform", "apply", "-auto-approve"], cwd="/tmp", capture_output=True, text=True)
    logger.info(f"Terraform apply output: {apply_result.stdout}\n{apply_result.stderr}")
    
    try:
        tmp_contents = os.listdir('/tmp')
        logger.info("Contenu du répertoire /tmp:")
        for item in tmp_contents:
            logger.info(f"- {item}")
    except Exception as e:
        logger.error(f"Erreur lors de la lecture du répertoire /tmp: {str(e)}")

    return {
        'statusCode': 200,
        'body': apply_result.stdout + apply_result.stderr
    }