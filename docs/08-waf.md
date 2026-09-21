# WAF (Web Application Firewall)

## How this differs from "the firewall"

The firewall from doc 05 operates on IP addresses and ports — it has no
idea what an HTTP request even looks like. A **WAF** operates one layer
up: it actually reads the HTTP request — the URL, the headers, the
body — and decides whether it looks malicious, independent of whether the
source IP and port were "allowed" by the network firewall.

**Data-engineering analogy:** if the firewall is a network ACL, the WAF
is input validation/sanitization, applied centrally, before the request
ever reaches your application code. It's the network-appliance version of
"never trust user input."

## Why it has to sit where TLS gets decrypted

This is the callout from doc 02, worth repeating here because it's the
reason this lab's architecture looks the way it does: a WAF that sits in
front of an HTTPS connection it can't decrypt sees nothing but encrypted
bytes. It cannot inspect a URL, header, or body it cannot read. So
**TLS has to terminate at or before the WAF** for it to do anything at
all.

This lab terminates TLS **at the WAF itself** — it holds the certificate
and private key, decrypts incoming HTTPS connections, inspects the
plaintext HTTP request, and (if it passes) forwards it as plain HTTP to
the reverse proxy behind it, over the private `dmz` network.

## What this lab's WAF actually checks

Commercial/open-source WAFs (Cloudflare's WAF, AWS WAF, F5, and
especially the widely-used open-source **OWASP ModSecurity Core Rule
Set**) run thousands of regularly-updated rules with anomaly scoring,
IP reputation feeds, rate limiting, and more. That's real infrastructure,
but it's also a black box you can't easily read line by line — which
works against the goal of this repo.

So instead, [`lab/waf/nginx.conf`](../lab/waf/nginx.conf) is a **small,
fully commented, hand-written WAF** that checks for the same handful of
attack *categories* the real thing checks for, using plain nginx
`location` blocks and regex matching, so every single rule is something
you can read and understand — no hidden rule database:

| Attack category | What it looks like | How the rule matches it |
|---|---|---|
| **SQL injection** | `' OR '1'='1`, `UNION SELECT`, `; DROP TABLE` | Regex on the query string / body for SQL keywords next to quote/comment characters |
| **Cross-site scripting (XSS)** | `<script>alert(1)</script>` | Regex for `<script`, `javascript:`, `onerror=` in the query string |
| **Path traversal** | `../../../../etc/passwd` | Regex for `../` sequences in the URL |
| **Known attack tooling** | Automated scanners like `sqlmap`, `nikto` | Match on the `User-Agent` header |
| **Oversized requests** | An abnormally large POST body, often used to smuggle payloads or cause resource exhaustion | `client_max_body_size` |

Anything matching returns an HTTP `403 Forbidden` immediately — the
request never reaches the reverse proxy or the web server at all.

This is a genuinely useful teaching tool but is **not** a production
WAF: it doesn't handle encoding tricks (double URL-encoding, unicode
normalization), doesn't do anomaly scoring, and has a tiny fraction of
the coverage of the OWASP Core Rule Set. Once these concepts feel solid,
the natural next step is looking at [OWASP CRS](https://coreruleset.org/)
itself and, in ModSecurity's terms, understanding **paranoia levels** and
**anomaly scoring thresholds** — the real-world version of "how
aggressive should blocking be."

## Detection mode vs. blocking mode

A subtlety worth knowing: real WAFs are often first deployed in
**detection-only** (or "log") mode — they evaluate every rule and log
what *would* have been blocked, without actually blocking anything. This
lets a team tune out false positives (legitimate traffic that happens to
match a rule) before flipping to **blocking mode**, where matches
actually get a `403`. Rolling straight to blocking mode on day one is a
common way to take down legitimate traffic by accident. This lab's WAF
is always in blocking mode, since it's small enough to reason about
directly — but the concept of a staged rollout is worth carrying into
any real WAF deployment.

## Try it in the lab

```bash
# Normal request — passes straight through:
docker compose exec client curl -sk "https://203.0.113.10:8443/?q=hello"

# SQL-injection-shaped request — blocked with 403, never reaches the backend:
docker compose exec client curl -sk "https://203.0.113.10:8443/?q=1' OR '1'='1"

# XSS-shaped request — also blocked:
docker compose exec client curl -sk "https://203.0.113.10:8443/?q=<script>alert(1)</script>"

# Path traversal — also blocked:
docker compose exec client curl -sk "https://203.0.113.10:8443/../../etc/passwd"
```

Then watch it happen live:

```bash
docker compose logs -f waf1
```

Every blocked request logs which rule matched and why — read
[`lab/waf/nginx.conf`](../lab/waf/nginx.conf) alongside the log output so
you can match cause to effect directly.
