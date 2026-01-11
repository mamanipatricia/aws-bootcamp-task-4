# AWS Bootcamp Task 4 - Signed URL File Gateway

A serverless file upload/download service using AWS Lambda, API Gateway, and S3 with pre-signed URLs for secure file transfers.

## Overview

This project implements a secure file gateway that:
- Generates pre-signed S3 upload URLs for client-side file uploads
- Generates pre-signed S3 download URLs via HTTP redirects
- Uses Flask (WSGI) with serverless-wsgi for AWS Lambda
- Deployed using AWS SAM (Serverless Application Model)
- No direct file handling by the Lambda function (scalable & cost-effective)

## Architecture

```
Client → API Gateway → Lambda (Flask) → S3 (Pre-signed URLs)
                                      ↓
                              Returns signed URL
                                      ↓
Client ← ─ ─ ─ ─ ─ ─ ─ ─ ─ ← Direct S3 access
```

### Key Components

- **Flask Application**: Lightweight Python web framework (WSGI)
- **serverless-wsgi**: Adapter for running Flask on AWS Lambda
- **API Gateway (HTTP API)**: Serverless REST API endpoints
- **AWS Lambda**: Serverless compute for generating signed URLs
- **S3**: Object storage with private bucket access
- **Pre-signed URLs**: Temporary authenticated URLs for secure file operations

## Features

### 1. Upload Endpoint
**POST** `/files`

Generates a pre-signed PUT URL for uploading files directly to S3.

**Request:**
```json
{
  "filename": "hello3.txt",
  "contentType": "text/plain"
}
```

**Response:**
```json
{
  "objectKey": "uploads/26d68758eb1d4a819b62dd98f1014b2a/hello3.txt",
  "uploadUrl": "https://file-gateway-156876768906.s3.amazonaws.com/uploads/26d68758eb1d4a819b62dd98f1014b2a/hello3.txt?..."
}
```

### 2. Download Endpoint
**GET** `/files/{objectKey}`

Returns an HTTP 307 redirect to a pre-signed GET URL for downloading files.

**Response:**
- **307 Temporary Redirect** → Pre-signed S3 URL
- **404 Not Found** → File doesn't exist

## Project Structure

```
aws-bootcamp-task-4/
├── src/
│   ├── app.py              # Flask application with Lambda handler
│   └── requirements.txt     # Python dependencies
├── template.yml            # AWS SAM template
├── test-file-gateway.sh    # End-to-end test script
```

## Technologies

- **Python 3.12**
- **Flask 2.3.3** - Web framework
- **serverless-wsgi 3.0.3** - Lambda WSGI adapter
- **boto3** - AWS SDK for Python
- **AWS Lambda** - Serverless compute
- **API Gateway (HTTP API)** - RESTful API
- **Amazon S3** - Object storage
- **AWS SAM** - Infrastructure as Code

## Testing

### Prerequisites
- jq (for testing scripts)

### Run the test script:

```bash
./test-file-gateway.sh
```

This script:
1. Creates a test file
2. Requests a pre-signed upload URL
3. Uploads the file directly to S3
4. Downloads the file via the API
5. Verifies content integrity

### Manual testing:

**Upload a file:**
```bash
# Get pre-signed URL
RESPONSE=$(curl -s -X POST "https://xpy2knv2yk.execute-api.us-east-1.amazonaws.com/files" \
  -H "Content-Type: application/json" \
  -d '{"filename":"hello3.txt","contentType":"text/plain"}')

OBJECT_KEY=$(echo "$RESPONSE" | jq -r .objectKey) && UPLOAD_URL=$(echo "$RESPONSE" | jq -r .uploadUrl)


# Upload to S3 using the returned URL
curl -i -X PUT "$UPLOAD_URL" -T hello3.txt -H "Content-Type: text/plain"
```

**Download a file:**
```bash
curl -L "https://xpy2knv2yk.execute-api.us-east-1.amazonaws.com/files/${OBJECT_KEY}"
```



## Related Resources

**Project Document**: [Google Doc](https://docs.google.com/document/d/1xP4Xw-R4Pgrd6Hp9EWur8nzfIxOHSZQrgByo3pq7Cak/edit?usp=sharing)

## License

This project is part of the AWS Bootcamp curriculum.

## Author

**Patricia Mamani** - [@mamanipatricia](https://github.com/mamanipatricia)

---

*Last updated: January 10, 2026*

