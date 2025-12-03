#!/bin/bash
# Caddy certificate renewal hook for Shelly devices
# This script uploads renewed certificates to the Shelly device

DOMAIN="your-domain.example.com"
SHELLY_HOST="192.168.1.100"
CERT_DIR="/var/lib/caddy/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory"

# Log file
LOG_FILE="/var/log/caddy-cert-hook.log"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_message "Certificate renewal hook triggered"

# Find the certificate directory for this domain
CERT_PATH="$(find "$CERT_DIR" -type d -name "*$DOMAIN*" | head -1)"

if [[ -z "$CERT_PATH" ]]; then
    log_message "Error: Could not find certificate directory for $DOMAIN"
    exit 1
fi

log_message "Found certificate directory: $CERT_PATH"

# Upload certificate
CERT="$CERT_PATH/$DOMAIN.crt"
KEY="$CERT_PATH/$DOMAIN.key"

if [[ -f "$CERT" ]]; then
    log_message "Uploading certificate to Shelly device at $SHELLY_HOST..."
    if /usr/local/bin/shelly-upload-cert.sh -host "$SHELLY_HOST" -file "$CERT" -type PutTLSClientCert >> "$LOG_FILE" 2>&1; then
        log_message "Certificate uploaded successfully!"
    else
        log_message "Error: Failed to upload certificate"
        exit 1
    fi
else
    log_message "Error: Certificate file not found at $CERT"
    exit 1
fi

# Upload private key
if [[ -f "$KEY" ]]; then
    log_message "Uploading private key to Shelly device..."
    if /usr/local/bin/shelly-upload-cert.sh -host "$SHELLY_HOST" -file "$KEY" -type PutTLSClientKey >> "$LOG_FILE" 2>&1; then
        log_message "Private key uploaded successfully!"
    else
        log_message "Error: Failed to upload private key"
        exit 1
    fi
else
    log_message "Error: Private key file not found at $KEY"
    exit 1
fi

log_message "Certificate renewal hook completed successfully"
