#Ver4 : A partir des données reçue par le POST, juste récupérer les variables (non-utilisé dans l'opération destroy)
import os
import json
import boto3

def lambda_handler(event, context):
  
    # The body is already a dictionary, no need for json.loads()
    body = event['body']
    
    instance_type = body.get('instance_type', '')
    region = body.get('region', '')
    subnet_id = body.get('subnet_id', '')
    name_tag = body.get('name_tag', '')
    yaml_config = body.get('yaml_config')    

    print(f"instance_type : {instance_type}")
    print(f"region : {region}")
    print(f"subnet_id : {subnet_id}")
    print(f"name_tag : {name_tag}")
    print(f"yaml_config : {yaml_config}")
 
    

    # Find the latest Amazon Linux 2023 AMI
    ec2 = boto3.client('ec2', region_name=region)
    response = ec2.describe_images(
        Owners=['amazon'],
        Filters=[
            {'Name': 'name', 'Values': ['al2023-ami-2023.*-x86_64']},
            {'Name': 'state', 'Values': ['available']}
        ]
    )
        # Sort the images by creation date and get the most recent one
    images = sorted(response['Images'], key=lambda x: x['CreationDate'], reverse=True)
    if images:
        latest_ami = images[0]['ImageId']
    else:
        latest_ami = "ami-not-found"
    
    print(f"Latest Amazon Linux 2023 AMI: {latest_ami}")
    
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
variable "ami_id" {{
  default = "{latest_ami}"
}}
variable "name_tag" {{
  default = "{name_tag}"
}}

"""
    print ("contenu du formulaire", variables_content)

    # À la fin de l'exécution, invoquez la deuxième fonction
    client = boto3.client('lambda')
    
    payload = {
        "key1": "value1",
        "key2": "value2"
    }
    
    response = client.invoke(
        FunctionName='lambda-terraform-destroy',
        InvocationType='Event',  # Asynchrone
        Payload=json.dumps(payload)
    )
    
    return {
        'statusCode': 200,
        'body': json.dumps('First function completed and second function DESTROY invoked !')
    }

