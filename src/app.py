import os
import uuid
from flask import Flask, request, jsonify, redirect
from mangum import Mangum
import boto3
from botocore.exceptions import ClientError

# Initialize Flask app
app = Flask(__name__)

# S3 client (uses IAM role in Lambda)
s3_client = boto3.client('s3')
BUCKET = os.environ['BUCKET_NAME']
# BUCKET = 'test-bucket-lab-3-patricia'

# --- Endpoint A: Prepare Upload ---
@app.route('/files', methods=['POST'])
def prepare_upload():
    try:
        data = request.json
        if not data or 'filename' not in data:
            return jsonify({'error': 'filename is required'}), 400

        filename = data['filename']
        content_type = data.get('contentType', 'application/octet-stream')

        # Generate unique object key to avoid collisions
        safe_filename = os.path.basename(filename)  # prevent path traversal
        print(safe_filename) # TEST WITH different type of name files (spaces, special characters, ...) 
        object_key = f"uploads/{uuid.uuid4().hex}/{safe_filename}"

        # Generate pre-signed PUT URL (valid 15 minutes)
        presigned_url = s3_client.generate_presigned_url(
            'put_object',
            Params={
                'Bucket': BUCKET,
                'Key': object_key,
                'ContentType': content_type
            },
            ExpiresIn=900  # 15 minutes
        )

        return jsonify({
            'objectKey': object_key,
            'uploadUrl': presigned_url
        }), 201

    except Exception as e:
        return jsonify({'error': str(e)}), 500

# --- Endpoint B: Download via Redirect ---
@app.route('/files/<path:object_key>', methods=['GET'])
def download_file(object_key):
    try:
        # Generate pre-signed GET URL (valid 1 hour)
        presigned_url = s3_client.generate_presigned_url(
            'get_object',
            Params={'Bucket': BUCKET, 'Key': object_key},
            ExpiresIn=3600  # 1 hour
        )

        # Return HTTP 307 Temporary Redirect
        return redirect(presigned_url, code=307)

    except ClientError as e:
        if e.response['Error']['Code'] == 'NoSuchKey':
            return jsonify({'error': 'File not found'}), 404
        return jsonify({'error': 'Server error'}), 500
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Wrap for AWS Lambda
handler = Mangum(app, lifespan="off")

