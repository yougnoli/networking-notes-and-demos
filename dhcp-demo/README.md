# DHCP demo

A small, standalone stack (separate from `../lab/`) with exactly one job:
make the DHCP handshake from
[`docs/04-the-endpoint-nic-dhcp-gateway.md`](../docs/04-the-endpoint-nic-dhcp-gateway.md)
visible, packet by packet, instead of abstract.

## What's here

- **`dnsmasq/`** — a DHCP server (using [dnsmasq](https://thekelleys.org.uk/dnsmasq/doc.html),
  a small, widely-used, real DHCP/DNS server — not a toy reimplementation)
  handing out addresses from `192.168.50.100`–`192.168.50.200`.
- **`client/`** — a container that starts with a Docker-assigned address
  (courtesy of Docker's own built-in IPAM — which is, itself, doing
  something DHCP-shaped), then **deliberately throws it away** and
  requests a real lease from the dnsmasq server via `udhcpc`, while
  `tcpdump` captures every packet of the exchange.

## Run it

```bash
cd dhcp-demo
docker compose up --build
```

Then, in another terminal:

```bash
docker compose logs -f client
```

You should see, in order:

1. The client's original Docker-assigned address (thrown away next).
2. `tcpdump` starting.
3. The address being flushed — the NIC genuinely has no address for a
   moment, just like a machine that just booted or just plugged in.
4. `udhcpc` running, and underneath it, `tcpdump`'s raw view of the same
   conversation: a **Discover** (broadcast — "is anyone a DHCP server?"),
   an **Offer** (dnsmasq proposing an address), a **Request** (the client
   asking to actually have it, still broadcast), and an **Ack**
   (confirmed, plus the extra configuration: subnet mask, default
   gateway, DNS server).
5. The client's final address, subnet, and route table — all three
   values traceable directly back to `dnsmasq/dnsmasq.conf`.

Re-run the handshake without rebuilding anything:

```bash
docker compose restart client
docker compose logs -f client
```

Watch the server's side of the same exchange:

```bash
docker compose logs dhcp-server
```

## Tear down

```bash
docker compose down
```
