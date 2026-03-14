#!/usr/bin/env bash
set -e

ROOT_DIR="$(git rev-parse --show-toplevel)"
CERT_PATH="$ROOT_DIR/deploy/nginx/certs"

mkdir -p "$CERT_PATH"

openssl req -x509 -nodes -days 30 -newkey rsa:2048 \
-keyout "$CERT_PATH/rentar.key" \
-out "$CERT_PATH/rentar.crt" \
-subj "/CN=rentar.local" \
-addext "subjectAltName=DNS:rentar.local,DNS:localhost"

echo "TLS certificates generated in $CERT_PATH"