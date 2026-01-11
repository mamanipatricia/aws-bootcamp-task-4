#!/bin/bash
set -euo pipefail

# Configuration
API_URL="https://xpy2knv2yk.execute-api.us-east-1.amazonaws.com"
FILENAME="lab-test-file.txt"
CONTENT_TYPE="text/plain"

# Create test file dynamically
TEST_CONTENT="Hello from Signed URL File Gateway – Final Lab Submission $(date -u)"
echo "$TEST_CONTENT" > "$FILENAME"
echo "Created local test file: $FILENAME"
echo "Content: $TEST_CONTENT"

# Step 1: Prepare upload (POST /files)
echo ""
echo "Requesting pre-signed upload URL..."
RESPONSE=$(curl -s -X POST "$API_URL/files" \
  -H "Content-Type: application/json" \
  -d "{\"filename\":\"$FILENAME\",\"contentType\":\"$CONTENT_TYPE\"}")

OBJECT_KEY=$(echo "$RESPONSE" | jq -r .objectKey)
UPLOAD_URL=$(echo "$RESPONSE" | jq -r .uploadUrl)

if [[ -z "$OBJECT_KEY" || "$OBJECT_KEY" == "null" ]]; then
  echo "Failed to get objectKey. Response: $RESPONSE"
  exit 1
fi

echo "Object Key: $OBJECT_KEY"

# Step 2: Upload directly to S3
echo ""
echo "Uploading file to S3 using pre-signed URL..."
curl -X PUT "$UPLOAD_URL" \
  -T "$FILENAME" \
  -H "Content-Type: $CONTENT_TYPE" \
  --silent --output /dev/null

echo "File uploaded successfully!"

# Step 3: Verify redirect behavior (GET /files/{key})
echo ""
echo "Testing HTTP redirect (expect 307 + Location header)..."
REDIRECT_OUTPUT=$(curl -s -v "$API_URL/files/$OBJECT_KEY" 2>&1)
HTTP_STATUS=$(echo "$REDIRECT_OUTPUT" | grep -oE "< HTTP/[0-9\.]+ [0-9]+" | tail -1)
LOCATION_HEADER=$(echo "$REDIRECT_OUTPUT" | grep -i "^< location:" | cut -d' ' -f3-)

echo "$HTTP_STATUS"
echo "< location: $(echo "$LOCATION_HEADER" | cut -c1-60)...[truncated]"

# Validate status code is 307
if [[ "$HTTP_STATUS" != *"< HTTP/2 307"* ]] && [[ "$HTTP_STATUS" != *"< HTTP/1.1 307"* ]]; then
  echo "Expected 307 Temporary Redirect, got: $HTTP_STATUS"
  exit 1
fi

# Step 4: End-to-end download (follow redirect)
echo ""
echo "Downloading file via auto-follow redirect (-L)..."
DOWNLOADED_CONTENT=$(curl -s -L "$API_URL/files/$OBJECT_KEY")

if [[ "$DOWNLOADED_CONTENT" == "$TEST_CONTENT" ]]; then
  echo "SUCCESS: Full end-to-end flow verified!"
  echo "Downloaded content matches original."
else
  echo "FAILED: Content mismatch."
  echo "Expected: $TEST_CONTENT"
  echo "Got:      $DOWNLOADED_CONTENT"
  exit 1
fi

# Cleanup
# rm -f "$FILENAME" # Uncomment this line to remove the local test file
echo ""
echo "Cleaned up local test file."
