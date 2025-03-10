#!/bin/bash
set -e

# LocalStack endpoint
ENDPOINT="http://localhost:4566"
REGION="us-east-1"

# Prepare directories
echo "Creating project directories..."
mkdir -p src
mkdir -p pandas_layer/python

# Create the layer - simpler approach for LocalStack
echo "Preparing minimal layer for LocalStack..."
mkdir -p pandas_layer/python/pandas_layer
echo "# Placeholder for pandas layer" > pandas_layer/python/pandas_layer/__init__.py

# Zip the Lambda function code
echo "Packaging Lambda function..."
cd src
zip -r ../lambda_function.zip .
cd ..

# Create DynamoDB table
echo "Creating DynamoDB table..."
aws --endpoint-url=$ENDPOINT dynamodb create-table \
  --table-name csv-data \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region $REGION

# Create S3 bucket
echo "Creating S3 bucket..."
aws --endpoint-url=$ENDPOINT s3api create-bucket \
  --bucket csv-upload-bucket \
  --region $REGION

# Create Lambda function
echo "Creating Lambda function..."
aws --endpoint-url=$ENDPOINT lambda create-function \
  --function-name csv-processor \
  --runtime python3.12 \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://lambda_function.zip \
  --role arn:aws:iam::000000000000:role/lambda-role \
  --region $REGION

# Add S3 permission to Lambda
echo "Adding S3 trigger permission..."
aws --endpoint-url=$ENDPOINT lambda add-permission \
  --function-name csv-processor \
  --statement-id s3-trigger \
  --action lambda:InvokeFunction \
  --principal s3.amazonaws.com \
  --source-arn arn:aws:s3:::csv-upload-bucket \
  --region $REGION

# Configure S3 bucket notification
echo "Configuring S3 bucket notification..."
aws --endpoint-url=$ENDPOINT s3api put-bucket-notification-configuration \
  --bucket csv-upload-bucket \
  --notification-configuration '{
    "LambdaFunctionConfigurations": [
      {
        "LambdaFunctionArn": "arn:aws:lambda:'$REGION':000000000000:function:csv-processor",
        "Events": ["s3:ObjectCreated:*"]
      }
    ]
  }' \
  --region $REGION

echo "Deployment complete!"
echo "Try uploading a CSV file to the S3 bucket:"
echo "aws --endpoint-url=$ENDPOINT s3 cp your-data.csv s3://csv-upload-bucket/"
echo ""
echo "Then check the DynamoDB table:"
echo "aws --endpoint-url=$ENDPOINT dynamodb scan --table-name csv-data"