# Load Balancer

The one-line reason this box exists:

> if there are 20 web servers

That's the whole reason load balancers exist: once you have more than one
instance of something serving traffic, *something* has to decide which
instance handles each incoming connection. If you've ever deployed an API
with "3 replicas," used a managed load balancer in front of a web app, or
sent inference requests to a self-hosted model that's scaled across
several GPU instances, something upstream was already doing this job —
this doc just makes it explicit.

## L4 vs. L7 load balancing

This is the single most important distinction, and it connects directly
back to the TLS termination gotcha from doc 02.

- **L4 (transport layer)** — the load balancer looks only at IP addresses
  and TCP/UDP ports. It doesn't know or care what protocol is riding on
  top, doesn't decrypt anything, doesn't parse HTTP. It just picks a
  backend and shuffles bytes back and forth ("passthrough"). Very fast,
  very simple, works for any protocol — but it can't make decisions based
  on the *content* of the request (can't route `/api` differently from
  `/static`, can't add a header) because it never looks that deep.
- **L7 (application layer)** — the load balancer terminates the
  connection, actually understands HTTP, and can route based on the URL
  path, hostname, headers, cookies, etc. To do this with HTTPS traffic,
  it has to hold the TLS certificate and decrypt the traffic itself —
  meaning it becomes a TLS termination point.

This repo's lab uses **HAProxy in L4/TCP mode**: it balances the raw
encrypted connection across backends without ever decrypting it,
precisely because in this diagram, TLS termination happens one hop
later, at the WAF (doc 08 explains why). This is a deliberate, documented
trade-off: it means the load balancer itself can't add a header like
`X-Forwarded-For`, because it never parses the request enough to know
where to put one — you'll see this called out directly in
[`lab/haproxy.cfg`](../lab/haproxy.cfg).

## What "balancing" actually means: algorithms

Given several healthy backends, how does the load balancer pick one for
a new connection? A few common strategies:

- **Round robin** — backend 1, then 2, then 1, then 2… in strict rotation.
  Simple, fair if all requests are roughly equal cost. This is what the
  lab uses.
- **Least connections** — send the new connection to whichever backend
  currently has the fewest open connections. Better when requests vary
  wildly in duration.
- **Weighted** — some backends get more traffic than others (e.g. a
  bigger instance gets weight 2, handling roughly twice the share).
- **Consistent hashing / sticky sessions** — the same client keeps
  landing on the same backend, useful when a backend holds session state
  in memory rather than in a shared store.

## Health checks

A load balancer is only useful if it actively avoids sending traffic to a
backend that's down. It periodically checks each backend (a TCP connect,
or an HTTP request to a `/health` endpoint) and takes unhealthy ones out
of rotation automatically, putting them back once they recover — the
same idea as a scheduled job that pings a service and pages someone if
it stops responding, except here the "page" is just "stop sending it
traffic," fully automatic, checked every few seconds.

## Try it in the lab

This lab replicates the WAF → reverse proxy → web server chain **twice**
(imagine 20, not 2 — the concept scales, the lab just keeps it small
enough to read) and has HAProxy balance across the two copies:

```bash
for i in $(seq 1 6); do
  docker compose exec client curl -sk https://203.0.113.10:8443/ | grep "Served by"
done
```

You should see the response alternate between "Served by web-1" and
"Served by web-2" in strict round-robin order — that's the load balancer
doing its one job, made visible.

Then take one backend down on purpose and watch HAProxy stop sending it
traffic:

```bash
docker compose stop web1
for i in $(seq 1 4); do
  docker compose exec client curl -sk https://203.0.113.10:8443/ | grep "Served by"
done
# Every response should now say "Served by web-2" — web1 was removed from rotation.
docker compose start web1
```

You can also check HAProxy's own view of backend health directly on its
stats dashboard — internal-only, reachable only via the VPN (doc 06) or
directly on the `dmz` network:

```bash
docker compose exec client curl -s http://10.10.10.10:8404/ | head -30
```
