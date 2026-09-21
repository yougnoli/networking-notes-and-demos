#!/usr/bin/env bash
# generate-certs.sh — creates a throwaway self-signed TLS certificate for
# the WAF (docs/08-waf.md) to terminate HTTPS with.
#
# This is deliberately NOT a real, trusted certificate — nobody's browser
# will trust it, which is why every curl example in this repo uses `-k`
# (skip verification) and why a real browser will show a warning page.
# That's expected and fine for a lab. A real deployment would use a
# certificate from an actual CA (or something like Let's Encrypt).
set -euo pipefail
cd "$(dirname "$0")/.."   # lab/

mkdir -p certs

if [[ -f certs/lab.crt && -f certs/lab.key ]]; then
  echo "certs/lab.crt and certs/lab.key already exist — leaving them alone."
  echo "(delete lab/certs/*.{crt,key} and re-run this script to regenerate)"
  exit 0
fi

openssl req -x509 -nodes -newkey rsa:2048 \
  -keyout certs/lab.key \
  -out certs/lab.crt \
  -days 365 \
  -subj "/CN=lab.local" \
  -addext "subjectAltName=DNS:lab.local,IP:203.0.113.10"

chmod 644 certs/lab.crt
chmod 600 certs/lab.key

echo "Generated certs/lab.crt and certs/lab.key (self-signed, valid 365 days)."
