# How this repo is organized

## The shape of the problem

Almost every system that serves data or an API to the outside world,
drawn simply, looks like the same straight line:

```
INTERNET -> Firewall -> VPN Server -> Load Balancer -> WAF -> Reverse Proxy -> Web Server
```

Separately, there's a short list of things that describe the **Endpoint
(EP)** — the device making the request in the first place (your laptop,
a notebook server, a phone):

```
- multihomed (more than one NIC)
- has a history of DHCP-assigned IPs
- has a subnet
- has a default gateway
- gets its address from a DHCP server
- sometimes has a public IP directly
```

That's actually two different stories, and this repo treats them as two
different stories that meet in the middle:

1. **The path a request takes** through an organization's infrastructure
   once it leaves some device and heads toward a web server or an API
   (docs 05–10).
2. **What "a device on a network" even means** — the thing at the very
   start of that path (doc 04).

Doc 02 walks the whole path once, at a high level, before we zoom into
each box. Doc 03 gives you the IP/subnet vocabulary you need for both
stories, since it comes up everywhere.

## Docs vs. lab

The `docs/` folder is **conceptual** — it explains what each component
does and why it exists, using plain language and analogies to things
people who work with data already know: SQL and databases, spreadsheets,
REST APIs, rate limits, notebooks, dashboards, data pipelines.

The `lab/` folder is **literal** — it's the same diagram, rebuilt as
actual Docker containers with actual config files, so you can `curl`
against it, break it on purpose, and watch logs to see what each
component actually did with a request.

Read a doc, then go run the matching piece of the lab. Doc 05 (Firewall)
pairs with `lab/firewall/`. Doc 07 (Load Balancer) pairs with
`lab/haproxy.cfg`. And so on — each doc ends with a short "Try it in the
lab" pointer.

## A note on real-world variation

Every organization's actual setup differs from this diagram in some way —
some skip the WAF, some put the load balancer after the WAF, some
terminate TLS in a different place, some don't have a separate reverse
proxy at all. The docs call out these variations explicitly, especially
in doc 08 (WAF) and doc 09 (Reverse Proxy), because the "correct" order
depends on a real constraint (a WAF needs to see unencrypted traffic to
inspect it) that's worth understanding rather than memorizing.
