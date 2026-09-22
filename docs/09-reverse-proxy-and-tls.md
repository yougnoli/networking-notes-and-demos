# Reverse Proxy & TLS

## Forward proxy vs. reverse proxy

These two terms confuse almost everyone at first because they describe
the same mechanism (something in the middle, forwarding requests) from
opposite perspectives:

- A **forward proxy** sits in front of *clients*, on their behalf,
  usually to reach the outside world (a corporate proxy that all
  employees' browsers are configured to use before reaching the
  internet). The server on the other end often doesn't even know a proxy
  is involved.
- A **reverse proxy** sits in front of *servers*, on their behalf. The
  client thinks it's talking directly to "the website," but it's really
  talking to the reverse proxy, which forwards the request to whichever
  actual backend should handle it.

If you've ever put an API gateway in front of a set of backend services,
or pointed a notebook at `localhost:8888` while something else quietly
proxied requests to the actual model server, you've already used a
reverse proxy, even if nobody called it that at the time.

## What a reverse proxy adds beyond "just forwarding"

By the time a request reaches the reverse proxy in this lab, the load
balancer has already picked a backend stack and the WAF has already
decided the request is clean. So what's left for the reverse proxy to
do? A handful of things that are genuinely its job and nobody else's:

- **Preserving the real client's identity.** Once a request has passed
  through several hops, the *immediate* source IP the web server would
  see is the reverse proxy's own IP, not the original client's. The
  reverse proxy fixes this by adding headers:
  - `X-Forwarded-For` — the original client's IP (and, in a longer
    chain, every hop along the way, comma-separated).
  - `X-Real-IP` — the original client's IP, singular.
  - `X-Forwarded-Proto` — whether the *original* client connection was
    `http` or `https`, since by this point the reverse proxy might be
    talking plain HTTP to the backend and the backend would otherwise
    have no way to know the original request was encrypted.
- **URL/path rewriting.** Mapping an external-facing path to whatever
  internal path/service actually handles it — e.g. exposing `/api/*`
  while the backend actually expects just `/*`.
- **Buffering and timeouts.** Protecting slow or misbehaving backends
  from slow clients, and vice versa.
- **A single place to add caching, compression, or rate limiting later**,
  without touching application code at all.

**In data/AI terms:** it's the same value proposition as an API gateway
sitting in front of several backend services or model endpoints — a
shared layer for concerns that would otherwise need to be duplicated
inside every single service: adding auth headers, enforcing rate limits,
reshaping requests and responses.

## Where TLS termination actually happens in this lab

Doc 08 explained that TLS terminates at the WAF layer, because the WAF
needs plaintext to inspect. That means, by the time a request reaches the
reverse proxy, it's already plain HTTP, on the private `dmz` network.
The reverse proxy in this lab does **not** re-encrypt to talk to the web
server — it's plain HTTP the rest of the way.

Is that safe? In this lab, yes — the `dmz` network is private, only
reachable by containers that are supposed to be there, matching how a
lot of real internal traffic inside a single trusted cloud network is
often left unencrypted, trusting the network boundary itself rather than
re-encrypting every internal hop. Some organizations go further and require
**mTLS (mutual TLS)** even between internal hops — every service proves
its identity to every other service with its own certificate, an
approach often called **zero trust** because it doesn't rely on network
location ("it's inside the DMZ") as a substitute for actual
authentication. That's a legitimate, increasingly common design — just
one this lab doesn't implement, to keep the moving parts learnable.

## Try it in the lab

Add a header the reverse proxy doesn't set, and watch the web server
receive the ones it *does* set:

```bash
docker compose exec client curl -sk -H "X-Debug: yes" https://203.0.113.10:8443/headers
```

The response (served by the `/headers` route in
[`lab/web/server.py`](../lab/web/server.py)) will show you exactly what
headers the web server actually received — including `X-Forwarded-For`
populated with the client's address, even though the web server's own
TCP connection is only ever with the reverse proxy on the same private
network, never with the original client directly.
