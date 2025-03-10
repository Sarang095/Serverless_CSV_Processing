#!/bin/bash
set -e

# Prepare the pandas layer
echo "Preparing pandas layer..."
bash prepare_layer.sh

# Make sure the src directory has the necessary files
mkdir -p src
if [ ! -f "src/lambda_function.py" ]; then
  echo "Lambda function file not found. Creating a sample one."
  # Copy lambda_function.py and csv_processor.py to src directory if needed
fi

# Deploy using AWS SAM with LocalStack endpoint
echo "Deploying resources to LocalStack..."
sam build --use-container  # Use container to avoid local Python version issues

# Deploy to LocalStack
sam deploy --stack-name csv-processor \
  --no-confirm-changeset \
  --region=us-east-1 \
  --force-upload \
  --endpoint-url=http://localhost:4566 \
  --parameter-overrides ParameterKey=Stack,ParameterValue=csv-processor

echo "Deployment complete!"