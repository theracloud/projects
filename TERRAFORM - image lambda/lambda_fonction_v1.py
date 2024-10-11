#Ver1 : A partir des données reçue par le POST, afficher les valeurs pour que Cloudwatch logs les montrent
import json
import boto3

def lambda_handler(event, context):
    # The body is already a dictionary, no need for json.loads()
    body = event['body']
    
    instance_type = body.get('instance_type')
    region = body.get('region')
    subnet_id = body.get('subnet_id')
    yaml_config = body.get('yaml_config')    

    
    print(f"instance_type : {instance_type}")
    print(f"region : {region}")
    print(f"subnet_id : {subnet_id}")
    print(f"yaml_config : {yaml_config}")
    
    
    return {
        'statusCode': 200,
        'body': json.dumps('Data processed successfully.')
    }
