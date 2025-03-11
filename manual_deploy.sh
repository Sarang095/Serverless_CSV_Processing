#!/bin/bash
set -e

ENDPOINT="http://localhost:4566"
REGION="us-east-1"

echo "Packaging Lambda function..."
cd src
zip -r ../lambda_function.zip .
cd ..

echo "Creating DynamoDB table..."
aws --endpoint-url=$ENDPOINT dynamodb create-table \
  --table-name csv-data \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region $REGION

echo "Creating S3 bucket..."
aws --endpoint-url=$ENDPOINT s3api create-bucket \
  --bucket csv-upload-bucket \
  --region $REGION

echo "Creating Lambda function..."
aws --endpoint-url=$ENDPOINT lambda create-function \
  --function-name csv-processor \
  --runtime python3.12 \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://lambda_function.zip \
  --role arn:aws:iam::000000000000:role/lambda-role \
  --region $REGION

echo "Adding S3 trigger permission..."
aws --endpoint-url=$ENDPOINT lambda add-permission \
  --function-name csv-processor \
  --statement-id s3-trigger \
  --action lambda:InvokeFunction \
  --principal s3.amazonaws.com \
  --source-arn arn:aws:s3:::csv-upload-bucket \
  --region $REGION

echo "Adding S3 trigger permission..."
aws --endpoint-url=$ENDPOINT lambda add-permission \
  --function-name csv-processor \
  --statement-id s3-trigger \
  --action lambda:InvokeFunction \
  --principal s3.amazonaws.com \
  --source-arn arn:aws:s3:::csv-upload-bucket \
  --region $REGION
sleep 5

echo "Configuring S3 bucket notification..."
aws --endpoint-url=$ENDPOINT s3api put-bucket-notification-configuration \
  --bucket csv-upload-bucket \
  --notification-configuration '{
    "LambdaFunctionConfigurations": [
      {
        "LambdaFunctionArn": "arn:aws:lambda:us-east-1:000000000000:function:csv-processor",
        "Events": ["s3:ObjectCreated:*"]
      }
    ]
  }' \
  --region $REGION

if [ $? -ne 0 ]; then
  echo "Standard notification configuration failed. Trying LocalStack-specific approach..."
  
  # Alternative approach for LocalStack free tier
  echo '{
    "LambdaFunctionConfigurations": [
      {
        "LambdaFunctionArn": "arn:aws:lambda:us-east-1:000000000000:function:csv-processor",
        "Events": ["s3:ObjectCreated:*"]
      }
    ]
  }' > notification.json
  
  aws --endpoint-url=$ENDPOINT s3api put-bucket-notification-configuration \
    --bucket csv-upload-bucket \
    --notification-configuration file://notification.json \
    --region $REGION
fi