# IP addresses & subnets

This is the vocabulary doc. Everything after this uses these terms
constantly, so it's worth getting concrete before moving on.

## What an IP address is

An IPv4 address is 32 bits, written as four decimal numbers (each 0–255)
separated by dots: `10.10.10.41`. Each number is one byte ("octet") —
8 bits. That's the whole trick: `10.10.10.41` is really
`00001010.00001010.00001010.00101001` in binary, just written in a more
human-friendly base.

It identifies a network interface, not a "device" — a machine with two
NICs has (at least) two IP addresses, one per interface. More on this in
doc 04.

## Subnets: partitioning the address space

A **subnet** is a contiguous block of IP addresses that are all
considered "on the same local network" — meaning any two of them can
talk to each other directly, without needing a router to forward the
traffic. Addresses in *different* subnets need something in between (a
router — which is one of the jobs the firewall does in our diagram) to
relay traffic.

This is the same trade-off as data partitioning: things in the same
partition are "close" (cheap to access together); crossing a partition
boundary costs a hop.

### CIDR notation: `10.10.10.0/24`

The `/24` is the **prefix length** — how many of the 32 bits are fixed
("network bits") vs. free to vary ("host bits"). `/24` means the first 24
bits (the first three octets: `10.10.10`) are fixed, and the last 8 bits
(the last octet) can be anything from `0` to `255` — giving you 256
addresses in that subnet, from `10.10.10.0` to `10.10.10.255`.

| CIDR | Network bits | Host bits | Usable addresses (roughly) |
|---|---|---|---|
| `/24` | 24 | 8 | 254 |
| `/16` | 16 | 16 | 65,534 |
| `/32` | 32 | 0 | 1 (a single, specific address) |

Two addresses are conventionally reserved and **not assignable** to a
host in a subnet:

- The **network address** — all host bits zero (`10.10.10.0`). Identifies
  the subnet itself.
- The **broadcast address** — all host bits one (`10.10.10.255`). A
  packet sent here is meant to reach every host in the subnet at once.

So a `/24` gives you 256 total addresses but 254 *usable* ones.

### This repo's lab subnets

To make the abstract concrete, here's exactly what the `lab/` Docker
Compose stack uses (see [`lab/docker-compose.yml`](../lab/docker-compose.yml)):

| Network | CIDR | Role | Notable addresses |
|---|---|---|---|
| `internet` | `203.0.113.0/24` | The simulated public internet | firewall: `203.0.113.10`, client: `203.0.113.50` |
| `dmz` | `10.10.10.0/24` | The private internal network | firewall: `10.10.10.1`, haproxy: `10.10.10.10`, web-1: `10.10.10.41` |
| `wg` (VPN tunnel) | `10.13.13.0/24` | Addresses handed to VPN clients | assigned dynamically by wg-easy |

`203.0.113.0/24` is not a random choice: it's one of three blocks
(`192.0.2.0/24`, `198.51.100.0/24`, `203.0.113.0/24`) that the IETF
formally reserved *specifically for documentation and examples*
(RFC 5737) — precisely so nobody accidentally uses a real company's
public IP in a diagram or a demo. It's the "acme.example.com" of IP
addresses.

## Public vs. private addresses

Some address ranges are reserved (RFC 1918) for **private** use — they're
not globally unique and are not supposed to be routable on the public
internet at all:

- `10.0.0.0/8` (`10.x.x.x`)
- `172.16.0.0/12` (`172.16.x.x`–`172.31.x.x`)
- `192.168.0.0/16` (`192.168.x.x`)

Every home router's LAN, every company's internal network, and this
lab's `dmz` and VPN networks use addresses from these ranges. That's
*why* NAT (doc 05) has to exist: a private address means nothing to the
public internet, so something has to translate it to a real, globally
routable **public** address before traffic can leave.

A device has a **public IP** when it's reachable directly from the
internet under its own address — no NAT in front of it. In our diagram,
that's the firewall's outward-facing interface. Almost nothing else in a
typical company network has one directly; everything else sits behind
the firewall's NAT (or is deliberately exposed via a forwarded port,
which is a narrow, explicit exception — see doc 05).

## The default gateway (preview)

If a device wants to send a packet to an address that is **not** in its
own subnet, it doesn't know how to get there directly — it hands the
packet to its **default gateway** (almost always the router at the edge
of its subnet) and lets that device figure out the next hop. This is
covered fully in doc 04, but it's worth planting here: subnetting is what
makes a device able to answer the question "can I reach this directly, or
do I need to ask my gateway?"

## Try it in the lab

Once the stack is up (`docker compose up` in `lab/`), get a shell in any
container and look at its actual configuration:

```bash
docker compose exec web1 sh -c "ip addr show eth0"
docker compose exec web1 sh -c "ip route show"
```

The `ip addr show` output will show something like
`inet 10.10.10.41/24` — that `/24` is exactly the CIDR prefix from the
table above, attached to the actual live address. `ip route show` will
show a default route pointing at `10.10.10.1` — the firewall, acting as
this container's gateway onto the wider world.
