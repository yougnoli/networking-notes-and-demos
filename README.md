# Networking Notes & Demos

A hands-on knowledge base for learning practical, real-world networking
— written for **data analysts, data engineers, and AI engineers** who
work with data, APIs, and cloud tools every day but have never had a
reason to learn how a request actually travels across a network. No
computer science degree, no networking certification, and no prior
infrastructure experience assumed. Every concept is explained from
scratch and tied back to things you already do: writing SQL, calling an
API from a notebook, building a pipeline, or hitting rate limits on an
LLM provider.

If you've ever wondered what actually happens between typing a URL (or
calling `requests.get(...)` in Python) and getting data back — or what
people mean by "the API is behind a load balancer" or "that database is
VPN-only" — this repo answers it, then lets you build a miniature,
working version of the whole thing so you can watch it happen instead of
just reading about it.

This repo is organized around one diagram: "how a request travels from
the internet to a web server, and everything it passes through along the
way." Read the diagram, read the docs that explain each box in it, then
run a real (if miniature) version of the whole thing on your own machine
with Docker.

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
   on each other. Each one starts from zero and leans on things people
   who work with data already know — SQL, spreadsheets, REST APIs,
   rate limits, data pipelines — rather than assuming any prior
   networking or systems-administration background.
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
4. **Take it home.** [`home-setup/`](home-setup/) is a worked example of
   turning these same concepts into a real, physical home network — using
   a real consumer router instead of a container, so you stop depending on
   your ISP's box for your own firewall and VPN.

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

## Taking it home

Once the concepts click in the simulated lab, [`home-setup/`](home-setup/)
walks through applying them for real: putting your ISP's gateway into
bridge mode, setting up your own router as the firewall, and turning on a
real VPN server — using an actual consumer router (an ASUS RT-BE92U, in
that worked example) as the stand-in for `lab/firewall/` and the VPN
container. The router model is just an example; the steps generalize to
any router with real firewall/VPN settings.

## Prerequisites

- Docker Engine + Docker Compose v2 (Docker Desktop on Mac/Windows, or
  `docker` + `docker-compose-plugin` on Linux)
- ~2 GB of free RAM for the containers
- A terminal and `curl`. That's it — no networking background assumed.

## Who this is for

Anyone who works with data or builds on top of APIs and has always
treated "the network" as somebody else's problem:

- A **data analyst** who writes SQL and builds dashboards, and has
  noticed that some data sources are reachable and others say
  "connection refused" or "connection timed out," without knowing why.
- A **data engineer** who builds pipelines, calls APIs, and uses Docker,
  but has never had to reason about IP addresses, firewalls, or TLS on
  purpose — those were always already working, or somebody else's job.
- An **AI engineer** who calls model APIs, maybe self-hosts one behind a
  load balancer, and has heard terms like "VPN-only endpoint" or "WAF
  blocked the request" without a clear mental model of what's actually
  happening underneath.

No prior networking knowledge, cloud certification, or computer science
background is assumed anywhere in this repo. Every term is defined the
first time it's used, and every analogy points back to something from
the data/API world you already know.
