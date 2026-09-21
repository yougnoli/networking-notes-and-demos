# The big picture

This doc walks the whole request path once, end to end, in plain language.
Every component gets its own deep-dive doc later — the goal here is just
to see how they fit together and *why* they're in this order, before the
details make it hard to see the shape.

## The design, as given

```
INTERNET
   |
   v
+-------------------------------------------------------------+
| FIREWALL                                                     |
| - knows which IP ranges are "inside" vs "outside"            |
| - says "here it's me" to the outside world (NAT)              |
| - also acts as a router between the internet and the LAN      |
+-------------------------------------------------------------+
   |
   v
+-------------------------------------------------------------+
| VPN SERVER                                                    |
| - hands a connecting device an IP from a private range         |
+-------------------------------------------------------------+
   |
   v
+-------------------------------------------------------------+
| LOAD BALANCER                                                  |
| - if there are 20 web servers, spreads traffic across them      |
+-------------------------------------------------------------+
   |
   v
+-------------------------------------------------------------+
| WAF (Web Application Firewall)                                  |
| - inspects the actual HTTP request for attacks                   |
+-------------------------------------------------------------+
   |
   v
+-------------------------------------------------------------+
| REVERSE PROXY                                                     |
+-------------------------------------------------------------+
   |
   v
+-------------------------------------------------------------+
| WEB SERVER                                                          |
| - the HTTPS session's content ultimately comes from here             |
+-------------------------------------------------------------+
```

Separately, every request *starts* at an **Endpoint (EP)** — a laptop,
phone, or server — which has its own small pile of concepts (doc 04):
it might have more than one network interface (multihomed), it got its
IP from a DHCP server and has a history of leases, it belongs to a
subnet, it has a default gateway it sends unfamiliar traffic to, and it
may or may not have a public IP of its own.

## Why this order makes sense

Read it as "narrowing scope and increasing intelligence" as the request
gets closer to the actual application:

1. **Firewall** — the coarsest filter. Operates on IP addresses and
   ports only. Doesn't know or care what an HTTP request even is. Its job
   is "should this packet be allowed to go from A to B at all."
2. **VPN server** — only relevant for *remote* traffic that needs to look
   like it's on the internal network. Traffic already on the LAN skips
   this hop entirely.
3. **Load balancer** — still mostly protocol-agnostic (it can operate at
   the TCP level without understanding HTTP at all). Its job is purely
   "which of the N identical backends should handle this connection."
4. **WAF** — the first component that actually reads the HTTP request:
   the URL, headers, body. It needs the traffic to be **decrypted** to do
   this, which is the single most important gotcha in the whole diagram
   (see the callout below).
5. **Reverse proxy** — HTTP-aware bookkeeping: rewriting paths, adding
   headers like `X-Forwarded-For` so the backend knows the real client
   IP, sometimes caching.
6. **Web server** — the actual application. Everything before this was
   infrastructure making sure only clean, legitimate, appropriately
   routed traffic gets here.

## The TLS termination gotcha

The diagram says the **web server** is where "the HTTPS session ends up"
— and that's true in the sense that the web server is the true origin of
the content. But it does *not* mean the bytes stay encrypted the whole
way there. They can't:

> **A WAF cannot inspect what it cannot read.** If the WAF sits in front
> of an HTTPS connection it doesn't hold the private key for, all it sees
> is encrypted noise — no URL, no headers, no body. It cannot do its job.

So in any real deployment (and in this repo's lab), TLS has to be
**terminated** — decrypted — at or before the WAF. Everything after that
point can safely run as plain HTTP, because it's inside infrastructure
you control (a private network segment), the same way you wouldn't
bother re-encrypting traffic between two services inside the same VPC
subnet that only your own load balancer and app can reach.

This repo's lab terminates TLS **at the WAF layer**: the load balancer in
front of it never decrypts anything (it operates purely on IP:port, so it
can sit in front of encrypted traffic just fine), and everything behind
the WAF — reverse proxy, web server — talks plain HTTP over a private
Docker network. Doc 08 and doc 09 explain this in detail, including the
trade-offs of terminating TLS earlier vs. later.

## Two networks, one firewall in between

The lab models this with two separate Docker networks:

- **`internet`** — represents the public internet. Only the firewall and
  a "client" container (playing the role of an external user) sit here.
- **`dmz`** — represents the private internal network where the VPN
  server, load balancer, WAF, reverse proxies, and web servers all live.

The firewall container is the *only* thing with a leg in both networks —
exactly like a real firewall/router sitting at the edge of a company's
network. Nothing on the `dmz` network is reachable from `internet` unless
the firewall explicitly forwards a port to it. That single rule is most
of what a firewall actually does, and doc 05 + the lab make it concrete.

## Try it in the lab

Nothing to run yet — just read [doc 03](03-ip-addresses-and-subnets.md)
next so the vocabulary (subnet, gateway, NAT) is solid before we zoom
into the firewall.
