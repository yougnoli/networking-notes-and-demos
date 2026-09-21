# Networking Notes & Demos

A hands-on knowledge base for learning practical enterprise networking —
built for people who already think in systems (pipelines, services, data
flow) but have never had to reason about IP addresses, NAT, or TLS
termination on purpose.

This repo grew out of one whiteboard diagram of "how a request gets from
the internet to a web server," so that's exactly how it's organized: read
the diagram, read the docs that explain each box in it, then run a real
(if miniature) version of the whole thing on your laptop with Docker.

```
INTERNET
   |
   v
Firewall  (knows the IP range, does NAT, acts as a router)
   |
   v
VPN Server  (hands out an IP from a private range to remote clients)
   |
   v
Load Balancer  (spreads traffic across many web servers)
   |
   v
WAF  (Web Application Firewall — inspects the actual HTTP request)
   |
   v
Reverse Proxy
   |
   v
Web Server  (the HTTPS session's content ultimately comes from here)
```

Plus a separate, equally important story about the **Endpoint (EP)** —
the laptop/phone/server making the request in the first place:
multihoming, DHCP, subnets, default gateways, and public vs. private IPs.

## How to use this repo

1. **Read, in order.** The docs in [`docs/`](docs/) are numbered and build
   on each other. Each one is written for someone with a data/software
   background but no networking background — expect analogies to things
   like APIs, load balancers you've already used (e.g. an ALB in front of
   a service), and packet flow explained the way you'd explain a request
   flowing through a pipeline.
2. **Run the lab.** [`lab/`](lab/) is a `docker compose` stack that
   actually implements the diagram above: a real firewall doing NAT and
   port-forwarding, a real WireGuard VPN server, a real load balancer, a
   hand-written (and fully commented) WAF, a real reverse proxy, and two
   backend web servers. You attack it, curl it, and watch it work.
3. **Poke the endpoint.** [`dhcp-demo/`](dhcp-demo/) is a tiny bonus stack
   that shows an actual DHCP handshake (Discover/Offer/Request/Ack)
   happening between a client and a DHCP server, with `tcpdump` capturing
   every packet, so the abstract "the DHCP server gives you an IP" becomes
   something you've watched happen.

## Reading order

| # | Doc | What it covers |
|---|-----|-----------------|
| 00 | [How this repo is organized](docs/00-how-to-use-this-repo.md) | Map of the repo, how docs relate to the lab |
| 01 | [A networking glossary for data people](docs/01-glossary-for-data-people.md) | Translates networking terms into things you already know |
| 02 | [The big picture](docs/02-big-picture-architecture.md) | Walks the whole diagram end to end before we zoom in |
| 03 | [IP addresses & subnets](docs/03-ip-addresses-and-subnets.md) | What an IP, a subnet mask, and CIDR actually mean |
| 04 | [The Endpoint: NICs, DHCP, gateways](docs/04-the-endpoint-nic-dhcp-gateway.md) | Multihoming, DHCP lease history, default gateway, public IP |
| 05 | [Firewall & NAT](docs/05-firewall-and-nat.md) | What a firewall actually filters, and how NAT hides your internal IPs |
| 06 | [VPN](docs/06-vpn.md) | Tunnels, encryption, and "an IP from that range" |
| 07 | [Load Balancer](docs/07-load-balancer.md) | L4 vs L7 balancing, algorithms, health checks |
| 08 | [WAF](docs/08-waf.md) | What it inspects, why TLS termination location matters |
| 09 | [Reverse Proxy & TLS](docs/09-reverse-proxy-and-tls.md) | What a reverse proxy adds beyond "just forwarding" |
| 10 | [Web Server](docs/10-web-server.md) | Where the request finally lands |
| 11 | [Full request walkthrough](docs/11-full-request-walkthrough.md) | One request, traced hop by hop through the whole lab |

## Running the lab

```bash
cd lab
./scripts/generate-certs.sh   # creates a local self-signed cert
docker compose up --build
```

Then see [`lab/README.md`](lab/README.md) for the full set of exercises:
normal traffic through the whole chain, a blocked SQL-injection attempt at
the WAF, load-balancer round robin, a port the firewall refuses to forward,
and (optional/advanced) connecting your own device over the VPN to reach
an internal-only resource.

**A note on where this repo was built:** this repo was authored and its
configs validated (syntax-checked, linted, `docker compose config`
verified) inside a sandbox whose network policy blocks pulling images
from Docker Hub. That means the full stack was **not** run end-to-end
during authoring — it needs to be run on a machine with normal internet
access (your laptop, a cloud VM, GitHub Codespaces, etc.). Everything in
[`lab/README.md`](lab/README.md) that says "expected output" is a
prediction based on how each documented piece of software behaves, not a
transcript. If something doesn't match, that's useful too — the docs will
help you figure out why, which is the actual point of this repo.

## Prerequisites

- Docker Engine + Docker Compose v2 (Docker Desktop on Mac/Windows, or
  `docker` + `docker-compose-plugin` on Linux)
- ~2 GB of free RAM for the containers
- A terminal and `curl`. That's it — no networking background assumed.

## Who this is for

You, specifically: a data engineer who is comfortable with distributed
systems, APIs, and Docker, but has always treated "the network" as
somebody else's layer. Every doc leans on that background instead of
assuming CCNA-level prior knowledge.
