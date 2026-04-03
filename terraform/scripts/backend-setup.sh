#!/bin/bash

# Configuration
BUCKET_NAME="taskflow-terraform-state-parth"
TABLE_NAME="taskflow-terraform-locks"
REGION="ap-south-1"

echo "🚀 Setting up Terraform Remote Backend Infrastructure..."

# 1. Create S3 Bucket
echo "Creating S3 bucket: $BUCKET_NAME in $REGION..."
aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION"

# 2. Enable Versioning (Crucial for state files)
echo "Enabling versioning on bucket..."
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

# 3. Create DynamoDB Table for State Locking
echo "Creating DynamoDB table for state locking: $TABLE_NAME..."
aws dynamodb create-table \
    --table-name "$TABLE_NAME" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region "$REGION"

echo "✅ Backend infrastructure setup complete!"
echo "Now you can run 'terraform init' to migrate your state."
