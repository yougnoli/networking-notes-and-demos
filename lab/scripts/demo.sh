#!/usr/bin/env bash
# demo.sh — runs through the core exercises from lab/README.md in order,
# printing what it's doing and why before each one. Meant to be read
# alongside the docs, not just run silently.
#
# Requires: docker compose up -d (and fix-routes.sh) already done.
set -uo pipefail
cd "$(dirname "$0")/.."   # lab/

exec_client() { docker compose exec -T client "$@"; }

section() { echo; echo "=== $* ==="; }

section "1. Normal request through the whole chain (docs/11)"
echo "client -> firewall(DNAT) -> loadbalancer -> waf -> reverse-proxy -> web"
exec_client curl -sk https://203.0.113.10:8443/ | grep -o "Served by [a-z0-9-]*"

section "2. Load-balancer round robin (docs/07)"
for i in $(seq 1 6); do
  exec_client curl -sk https://203.0.113.10:8443/ | grep -o "Served by [a-z0-9-]*"
done

section "3. Headers added along the way, seen at the web server (docs/09, docs/11)"
exec_client curl -sk https://203.0.113.10:8443/headers

section "4. WAF blocking a SQL-injection-shaped request (docs/08)"
exec_client curl -sk -o /dev/null -w "HTTP %{http_code}\n" \
  "https://203.0.113.10:8443/?q=1' OR '1'='1"

section "5. WAF blocking an XSS-shaped request (docs/08)"
exec_client curl -sk -o /dev/null -w "HTTP %{http_code}\n" \
  "https://203.0.113.10:8443/?q=<script>alert(1)</script>"

section "6. WAF blocking a path-traversal-shaped request (docs/08)"
exec_client curl -sk -o /dev/null -w "HTTP %{http_code}\n" \
  "https://203.0.113.10:8443/../../etc/passwd"

section "7. Firewall refusing a port with no forwarding rule (docs/05)"
echo "(expect this to time out after 5 seconds — that's the firewall working)"
exec_client curl -sk --max-time 5 http://203.0.113.10:8404/ \
  || echo "  -> no response, as expected: nothing forwards this port."

section "Done. See lab/README.md for the VPN exercise (requires a step on your own device)."
