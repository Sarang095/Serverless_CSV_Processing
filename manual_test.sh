#!/bin/bash

ENDPOINT="http://localhost:4566"
REGION="us-east-1"

echo "Creating a sample CSV file..."
cat > sample_data.csv << EOF
name,age,email,city
John Doe,30,john@example.com,New York
Jane Smith,25,jane@example.com,San Francisco
Bob Johnson,45,bob@example.com,Chicago
Alice Williams,35,alice@example.com,Boston
EOF

echo "Uploading CSV file to S3 bucket..."
aws --endpoint-url=$ENDPOINT s3 cp sample_data.csv s3://csv-upload-bucket/ --region $REGION

echo "Manually invoking Lambda with a test event..."
aws --endpoint-url=$ENDPOINT lambda invoke \
  --function-name csv-processor \
  --payload '{
    "Records": [
      {
        "s3": {
          "bucket": {
            "name": "csv-upload-bucket"
          },
          "object": {
            "key": "sample_data.csv"
          }
        }
      }
    ]
  }' \
  --region $REGION \
  output.txt

echo "Checking DynamoDB table contents..."
aws --endpoint-url=$ENDPOINT dynamodb scan --table-name csv-data --region $REGION