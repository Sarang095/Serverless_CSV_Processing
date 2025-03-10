#!/bin/bash

ENDPOINT="http://localhost:4566"

echo "Creating a sample CSV file..."
cat > sample_data.csv << EOF
name,age,email,city
John Doe,30,john@example.com,New York
Jane Smith,25,jane@example.com,San Francisco
Bob Johnson,45,bob@example.com,Chicago
Alice Williams,35,alice@example.com,Boston
EOF

echo "Uploading CSV file to S3 bucket..."
aws --endpoint-url=$ENDPOINT s3 cp sample_data.csv s3://csv-upload-bucket/

echo "Waiting for Lambda processing..."
sleep 5

echo "Checking DynamoDB table contents..."
aws --endpoint-url=$ENDPOINT dynamodb scan --table-name csv-data