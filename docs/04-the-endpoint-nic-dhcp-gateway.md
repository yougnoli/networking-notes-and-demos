# The Endpoint: NICs, DHCP, and the default gateway

Every request in the big diagram starts somewhere: a laptop, a phone, a
server. That thing is the **Endpoint (EP)**. This doc unpacks the short
list of properties that describe it:

- multihomed (more than one NIC)
- a history of DHCP-assigned IPs
- a subnet
- a default gateway
- an address from a DHCP server
- sometimes a public IP directly

## Multihoming: more than one NIC

A **NIC (Network Interface Card)** is a network "port," physical or
virtual. A device is **multihomed** when it has more than one — each
with its own IP address, possibly on entirely different networks.

Your own laptop is almost certainly multihomed right now: a Wi-Fi
adapter, an Ethernet adapter (even if unplugged, it still exists as an
interface), and once you connect a VPN, a *virtual* NIC created just for
that tunnel (often named something like `wg0`, `tun0`, or `utun3`). Each
one gets its own IP, its own subnet, and — this is the important
part — its own routing behavior.

**In data/cloud terms:** if you've provisioned a cloud VM or a database
instance with more than one network attachment (for example, one for a
private data network and one for a public/management network), you've
already seen multihoming — one machine, but "which network am I talking
to" depends on which interface a piece of traffic goes out of.

Why does this matter practically? Because when a device has multiple
NICs, the operating system has to decide, for every outgoing packet,
*which interface to send it out of*. That decision is made using the
routing table (see "default gateway" below) — and it's why VPN clients
work the way they do: connecting a VPN doesn't just add an IP, it usually
changes which interface handles which destinations, sometimes routing
*all* your traffic through the tunnel, sometimes only traffic bound for
the private network on the other end ("split tunneling" — see doc 06).

## DHCP and lease history

**DHCP (Dynamic Host Configuration Protocol)** is how a device gets an IP
address automatically instead of a human typing one in. When a NIC comes
up on a network, it doesn't have an address yet, so it can't even be
"found" to receive one — DHCP solves this with a broadcast-based
handshake, often abbreviated **DORA**:

1. **Discover** — the client broadcasts "is anyone a DHCP server? I need
   an address" to the whole local subnet (it has no address yet, so it
   can't address anyone directly).
2. **Offer** — a DHCP server on that subnet replies with an offered
   address ("you can have `10.10.10.87`").
3. **Request** — the client broadcasts back "yes, I'll take
   `10.10.10.87`" (broadcast again, so any *other* DHCP server that also
   made an offer knows it lost and can reclaim that address).
4. **Acknowledge** — the server confirms, and includes the extra
   configuration the client needs to actually function: the **subnet
   mask**, the **default gateway**, and usually DNS server addresses.

This is a **lease**, not a permanent assignment — it comes with a TTL
(commonly somewhere between minutes and days depending on network
policy). The client has to renew it before it expires, and if it moves to
a different network, it'll get a completely different lease from a
different DHCP server. That's where a device's "history" of addresses
comes from: over its life, a laptop that moves between home, office, and
coffee-shop Wi-Fi accumulates a whole history of different leased IPs,
each valid only on the network it was issued on, each eventually
expiring or getting released when the NIC disconnects.

**In data terms:** DHCP behaves like an auto-incrementing ID with an
expiry — closer to a temporary access token or a database session ID
that gets reissued each time you reconnect than to a fixed, hand-picked
value. Nobody hardcodes it; it's handed out from a pool on request and
reclaimed once it's no longer being renewed.

You can watch this exact handshake happen, packet by packet, in
[`dhcp-demo/`](../dhcp-demo/) — a client container gives up its
auto-assigned Docker IP on purpose and requests a real one from a DHCP
server via DORA, while `tcpdump` captures every packet.

## Subnet (from the endpoint's point of view)

Once the endpoint has an address and a mask (say `10.10.10.87/24`), it
now knows something important: **which other addresses it can reach
directly**, without needing help. Anything from `10.10.10.0` to
`10.10.10.255` is "local" — same subnet, reachable by putting a frame
directly on the wire (technically: via ARP + a local Ethernet frame, no
routing needed). Anything outside that range requires a router.

This is the same "am I in the same partition" check as doc 03, just from
the perspective of the device asking the question rather than the
network being partitioned.

## Default gateway

For every destination *outside* its own subnet, the endpoint doesn't
know the full path — it just knows to hand the packet to its **default
gateway**, which is a router (usually the first or last address in the
subnet, by convention — e.g. `10.10.10.1`) responsible for figuring out
the next hop. It's the same idea as a catch-all `ELSE` branch in a SQL
`CASE WHEN`, or the default route in an API gateway: "I don't have a
specific rule for this destination, so send it here and let that thing
deal with it."

In our lab, the firewall container **is** the default gateway for every
host on the `dmz` network. Every container's routing table has a line
like:

```
default via 10.10.10.1 dev eth0
```

which is exactly what makes the firewall the mandatory choke point for
any traffic leaving the DMZ — nothing can skip it, because nothing else
in the DMZ knows how to reach the internet on its own.

## Public IP, directly on the endpoint

Most endpoints (your laptop, your phone) sit behind NAT and never have a
public IP of their own — their traffic is translated by a
firewall/router on the way out (doc 05). But some endpoints *do* get a
public IP directly: a cloud VM with a public IP attached, a server
colocated in a data center with no NAT in front of it, or (historically)
a home computer directly connected to a cable modem in bridge mode.

Having a public IP means the device is directly reachable from the
internet, for better and worse: it doesn't need port-forwarding to
receive inbound connections, but it also isn't shielded by the NAT
boundary that (incidentally) blocks a lot of unsolicited inbound
traffic. In this repo's lab, exactly one thing has a public IP: the
firewall's internet-facing interface (`203.0.113.10`). Every other
container is reachable only through it.

## Try it in the lab

```bash
# See the endpoint-style view from inside any lab container:
docker compose exec web1 sh -c "ip addr show"     # every NIC and its IP/subnet
docker compose exec web1 sh -c "ip route show"    # its default gateway
```

For the full DHCP handshake, see [`dhcp-demo/`](../dhcp-demo/) — that
stack is specifically built to make DORA visible.
