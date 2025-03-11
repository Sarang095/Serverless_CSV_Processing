# Event-Driven CSV Processing with AWS Services

## Project Overview

This project demonstrates an event-driven architecture using AWS services (run locally with LocalStack) to process CSV files. The workflow automatically triggers whenever a file is uploaded to an S3 bucket, processes the data, and stores it in a DynamoDB database - all without manual intervention.

## Architecture

![Architecture Diagram](https://via.placeholder.com/800x400)

### Key Components:

- **S3 Bucket**: Storage for uploaded CSV files
- **Lambda Function**: Serverless compute that processes the CSV files
- **DynamoDB**: NoSQL database for storing processed data
- **Event Notifications**: S3 events that trigger the Lambda function

## Design Approach & Practices Used

### 1. Lightweight CSV Processing

We deliberately chose the standard Python `csv` module instead of pandas for processing CSV files. This approach offers several advantages:

- **Deployment Package Size**: Lambda has a deployment package size limit (50MB for direct uploads, 250MB for layers). The standard library keeps our package small.
- **Cold Start Performance**: Smaller packages lead to faster Lambda cold starts.
- **Memory Efficiency**: The built-in CSV module uses less memory than pandas for simple operations.

### 2. Efficient Data Processing

The Lambda function implements several efficiency patterns:

- **Streaming Downloads**: Files are downloaded from S3 to a temporary location and processed incrementally.
- **Progress Logging**: For large files, progress is logged every 100 records to provide visibility.
- **Clean Data Handling**: Empty strings are converted to `None` values, ensuring proper JSON representation in DynamoDB.


### 4. Infrastructure as Code

The entire infrastructure is defined as code:

- **Shell Scripts**: Deployment and testing are automated through shell scripts.
- **Docker Compose**: LocalStack environment is defined in a compose file for consistent execution.
- **Parameterized Configuration**: Endpoint URLs and region settings are parameterized.

```

## Setup and Execution

### Prerequisites

- Docker and Docker Compose
- AWS CLI
- Python 3.9

### DO TRY RUNNING IT LOCALLY

1. **Start LocalStack**:
   ```bash
   docker-compose up -d
   ```

2. **Deploy the infrastructure**:
   ```bash
   chmod +x manual_deploy.sh
   ./manual_deploy.sh
   ```

3. **Run a test**:
   ```bash
   chmod +x manual_test.sh
   ./manual_test.sh
   ```

### Testing with Your Own CSV Files

1. Upload a CSV file to the S3 bucket:
   ```bash
   aws --endpoint-url=http://localhost:4566 s3 cp your_file.csv s3://csv-upload-bucket/
   ```

2. Check the results in DynamoDB:
   ```bash
   aws --endpoint-url=http://localhost:4566 dynamodb scan --table-name csv-data
   ```


