#!/bin/bash

# Generate SSL certificates for NGINX
# Usage: ./generate-ssl.sh [domain] [days]

DOMAIN=${1:-localhost}
DAYS=${2:-365}
SSL_DIR="./nginx/ssl"

echo "Generating SSL certificate for domain: $DOMAIN"
echo "Valid for: $DAYS days"

# Create SSL directory if it doesn't exist
mkdir -p "$SSL_DIR"

# Generate private key
openssl genrsa -out "$SSL_DIR/$DOMAIN.key" 2048

# Generate certificate signing request
openssl req -new -key "$SSL_DIR/$DOMAIN.key" -out "$SSL_DIR/$DOMAIN.csr" -subj "/CN=$DOMAIN"

# Generate self-signed certificate
openssl x509 -req -in "$SSL_DIR/$DOMAIN.csr" -signkey "$SSL_DIR/$DOMAIN.key" -out "$SSL_DIR/$DOMAIN.crt" -days $DAYS

# Create combined certificate file for HAProxy
cat "$SSL_DIR/$DOMAIN.crt" "$SSL_DIR/$DOMAIN.key" > "$SSL_DIR/$DOMAIN.pem"

# Clean up CSR
rm "$SSL_DIR/$DOMAIN.csr"

echo "SSL certificate generated successfully!"
echo "Certificate: $SSL_DIR/$DOMAIN.crt"
echo "Private key: $SSL_DIR/$DOMAIN.key"
echo "Combined PEM: $SSL_DIR/$DOMAIN.pem"