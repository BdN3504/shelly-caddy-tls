#!/bin/bash
# shelly-cert.sh - Upload certificates to Shelly Gen2/Gen3 device
# Usage: shelly-cert.sh -host <IP> -file <cert_file> -type <PutTLSClientCert|PutTLSClientKey>

set -e

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -host)
      HOST="$2"
      shift 2
      ;;
    -file)
      CERT_FILE="$2"
      shift 2
      ;;
    -type)
      TYPE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Validate inputs
if [[ -z "$HOST" || -z "$CERT_FILE" || -z "$TYPE" ]]; then
  echo "Usage: $0 -host <IP> -file <cert_file> -type <PutTLSClientCert|PutTLSClientKey>"
  exit 1
fi

if [[ ! -f "$CERT_FILE" ]]; then
  echo "Error: Certificate file '$CERT_FILE' not found"
  exit 1
fi

# Validate type and add Shelly. prefix
if [[ ! "$TYPE" =~ ^(PutTLSClientCert|PutTLSClientKey)$ ]]; then
  echo "Error: Invalid type. Must be PutTLSClientCert or PutTLSClientKey"
  exit 1
fi
METHOD="Shelly.$TYPE"

# Read certificate content and escape for JSON
CERT_CONTENT=$(cat "$CERT_FILE" | sed 's/$/\\n/g' | tr -d '\n')

# Create JSON payload
DATA=$(cat <<EOF
{
  "id": 1,
  "method": "$METHOD",
  "params": {
    "data": "$CERT_CONTENT",
    "append": false
  }
}
EOF
)

# Upload certificate via HTTP POST
echo "Uploading certificate to $HOST using method $METHOD..."
RESPONSE=$(curl -s -X POST "http://$HOST/rpc" \
  -H "Content-Type: application/json" \
  -d "$DATA")

# Check response
if echo "$RESPONSE" | grep -q '"error"'; then
  echo "Error uploading certificate:"
  echo "$RESPONSE"
  exit 1
else
  echo "Certificate uploaded successfully!"
  echo "Response: $RESPONSE"
fi
