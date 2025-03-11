import os
import json
import uuid
import boto3
import csv
import tempfile

LOCALSTACK_HOSTNAME = os.environ.get('LOCALSTACK_HOSTNAME', 'localhost')
LOCALSTACK_ENDPOINT = f'http://{LOCALSTACK_HOSTNAME}:4566'

s3_client = boto3.client('s3', endpoint_url=LOCALSTACK_ENDPOINT)
dynamodb = boto3.resource('dynamodb', endpoint_url=LOCALSTACK_ENDPOINT)

def process_csv_file(file_path):
    """Process CSV without pandas to keep dependencies minimal"""
    records = []
    with open(file_path, 'r', newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            clean_row = {k: (None if v == '' else v) for k, v in row.items()}
            records.append(clean_row)
    return records

def lambda_handler(event, context):
    try:
        bucket = event['Records'][0]['s3']['bucket']['name']
        key = event['Records'][0]['s3']['object']['key']
        
        print(f"Processing file: {key} from bucket: {bucket}")
        
        table_name = 'csv-data'
        table = dynamodb.Table(table_name)
        
        with tempfile.NamedTemporaryFile(delete=False) as temp_file:
            s3_client.download_file(bucket, key, temp_file.name)
            
            # Process the CSV and get the records
            records = process_csv_file(temp_file.name)
            
            # Write each record to DynamoDB
            record_count = 0
            for record in records:
                if 'id' not in record:
                    record['id'] = str(uuid.uuid4())
                
                table.put_item(Item=record)
                record_count += 1
                
                if record_count % 100 == 0:
                    print(f"Processed {record_count} records so far...")
            
            os.unlink(temp_file.name)
        
        return {
            'statusCode': 200,
            'body': json.dumps(f'Successfully processed {record_count} records from {key}')
        }
        
    except Exception as e:
        print(f"Error processing S3 event: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error processing file: {str(e)}')
        }