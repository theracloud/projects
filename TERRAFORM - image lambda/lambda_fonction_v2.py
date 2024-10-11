#Ver2 : A partir des données reçue par le POST, créer un fichier variables.tf sur S3 avec les bonnes valeurs
import os
import json
import boto3

def lambda_handler(event, context):
    # The body is already a dictionary, no need for json.loads()
    body = event['body']
    
    instance_type = body.get('instance_type', '')
    region = body.get('region', '')
    subnet_id = body.get('subnet_id', '')
    yaml_config = body.get('yaml_config')    

    print(f"instance_type : {instance_type}")
    print(f"region : {region}")
    print(f"subnet_id : {subnet_id}")
    print(f"yaml_config : {yaml_config}")
    
    # Create variables.tf content
    variables_content = f"""
variable "instance_type" {{
  default = "{instance_type}"
}}
variable "region" {{
  default = "{region}"
}}
variable "subnet_id" {{
  default = "{subnet_id}"
}}
"""

    # Upload variables.tf to S3
    s3 = boto3.client('s3')
    bucket_name = 'theracloud-terraform'
    file_key = 'create-EC2-instance/variables.tf'
    
    try:
        s3.put_object(Bucket=bucket_name, Key=file_key, Body=variables_content)
        print(f"variables.tf uploaded successfully to s3://{bucket_name}/{file_key}")
    except Exception as e:
        print(f"Error uploading to S3: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps('Error uploading variables.tf to S3.')
        }
    
    return {
        'statusCode': 200,
        'body': json.dumps('Data processed successfully. variables.tf uploaded to S3.')
    }
