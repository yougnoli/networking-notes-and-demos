# Web Server

## The end of the line

The one-line description of this box was:

> HTTPS session ends up to the web server

By the time a request reaches here, it has been: allowed through the
firewall, DNAT'd to the right internal service, possibly arrived via a
VPN tunnel, load-balanced to one of several identical backends, inspected
and cleared by the WAF, decrypted, and had identifying headers attached
by the reverse proxy. The web server's job, after all of that, is simple
by comparison: **generate the actual response**.

That's the sense in which "the HTTPS session ends up" here — this is the
origin. Every layer before it was infrastructure making sure the request
that arrives here is legitimate, healthy-routed, and clean. Nothing
before this point actually produces the content the client asked for.

## What this lab's web server is

Real web servers range from static file servers (nginx, serving HTML/
CSS/JS straight off disk) to full application servers running someone's
own code (Django, Flask, Express, Rails, or a model-serving framework
like FastAPI wrapping a machine learning model). This lab's web server
([`lab/web/server.py`](../lab/web/server.py), used by both replicas) is
deliberately tiny: plain Python, using only the standard library's
`http.server` module — no framework, no dependencies, nothing to
install — specifically so you can read the entire thing in under a
minute and see exactly what happens to a request once it finally lands.

Each one does three things:

1. Answers `GET /` with a small HTML page that says which web server
   instance handled the request (`web-1` or `web-2`) — this is what
   makes the load-balancing demo in doc 07 visible.
2. Answers `GET /headers` by echoing back, as readable JSON, every HTTP
   header it actually received — this is what makes the reverse proxy's
   header injection (doc 09) visible: you'll see `X-Forwarded-For`,
   `X-Real-IP`, and `X-Forwarded-Proto` show up here, added by a layer
   two hops back, even though this server's own TCP connection is only
   ever with the reverse proxy.
3. Answers `GET /health` with a bare `200 OK`, for the load balancer's
   health checks (doc 07).

## Why this matters even though "it's just a web server"

It's worth sitting with how little the web server itself had to do to
participate correctly in all of this: it didn't implement any access
control, any encryption, any load-balancing awareness, any attack
detection. It trusts that everything reaching it has already been
filtered, decrypted, balanced, and inspected — and it's *correct* to
trust that, because the network architecture in front of it enforces it.
This is the whole value of the layered design in doc 02: each component
handles exactly one concern, so the application code doesn't have to.

## Try it in the lab

```bash
# See which instance answers, repeatedly (ties into the load-balancer demo):
docker compose exec client curl -sk https://203.0.113.10:8443/

# See exactly what headers survived the whole trip:
docker compose exec client curl -sk https://203.0.113.10:8443/headers | python3 -m json.tool

# See the health check endpoint HAProxy is polling:
docker compose exec loadbalancer wget -qO- http://web1:8080/health
```
