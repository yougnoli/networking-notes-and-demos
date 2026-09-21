# The lab

A real (miniature) implementation of the diagram in
[`docs/02-big-picture-architecture.md`](../docs/02-big-picture-architecture.md):
a firewall doing NAT and port-forwarding, a WireGuard VPN server, an
HAProxy load balancer, a hand-written (fully commented) WAF, a reverse
proxy, and two backend web servers — as real containers on two real,
separate Docker networks.

Read the numbered docs in [`../docs/`](../docs/) first — this file is the
"now go run it" companion, not a replacement for them.

**Built in a network-restricted sandbox** — see the note at the bottom of
the top-level [`README.md`](../README.md). This has not been run
end-to-end during authoring. Run it somewhere with normal internet access
to pull images (your laptop, a cloud VM, a Codespace).

## 1. Prerequisites

- Docker Engine + Docker Compose v2
- `openssl` (for generating a self-signed cert — almost certainly already
  on your machine)
- `curl`

## 2. Start it up

```bash
cd lab
./scripts/generate-certs.sh    # creates lab/certs/lab.{crt,key}
docker compose up --build -d
./scripts/fix-routes.sh        # see why this step exists below
```

### Why the extra `fix-routes.sh` step?

Docker automatically gives every container a default route pointing at
its own network's bridge gateway — a detail of the Docker host, not any
container we control. That's a dead end for two specific containers in
this lab (the load balancer and the VPN server) that need to reply to
traffic whose source is on a *different* network than their own. This
script points them at the firewall/VPN server instead, the same way a
real machine's default gateway gets configured. Full explanation in
[`docs/05-firewall-and-nat.md`](../docs/05-firewall-and-nat.md) and
[`docs/11-full-request-walkthrough.md`](../docs/11-full-request-walkthrough.md).

Check everything came up:

```bash
docker compose ps
```

## 3. Run the guided demo

```bash
./scripts/demo.sh
```

This runs through the exercises below in order, with a short explanation
printed before each one. Or run them by hand — see the next section.

## 4. Exercises, one at a time

### a) A normal request through the whole chain

```bash
docker compose exec client curl -sk https://203.0.113.10:8443/
```

Or, from your actual browser/terminal (not inside a container), since
port 8443 is also published to your host:

```
https://localhost:8443/
```

(Your browser will warn you about the certificate — it's self-signed on
purpose, see `scripts/generate-certs.sh`. Click through / use `curl -k`.)

### b) Load-balancer round robin

```bash
for i in $(seq 1 6); do
  docker compose exec client curl -sk https://203.0.113.10:8443/ | grep "Served by"
done
```

Watch it alternate between `web-1` and `web-2`. Then take one down and
watch HAProxy stop sending it traffic:

```bash
docker compose stop web1
for i in $(seq 1 4); do
  docker compose exec client curl -sk https://203.0.113.10:8443/ | grep "Served by"
done
docker compose start web1
```

### c) Headers picked up along the way

```bash
docker compose exec client curl -sk https://203.0.113.10:8443/headers
```

Look for `X-Forwarded-For` / `X-Real-IP` (set by the WAF, from the real
client address recovered via HAProxy's PROXY protocol) and `X-Served-By`
(set by the reverse proxy). See
[`docs/09-reverse-proxy-and-tls.md`](../docs/09-reverse-proxy-and-tls.md).

### d) The WAF blocking attacks

```bash
# SQL-injection-shaped:
docker compose exec client curl -sk "https://203.0.113.10:8443/?q=1' OR '1'='1"

# XSS-shaped:
docker compose exec client curl -sk "https://203.0.113.10:8443/?q=<script>alert(1)</script>"

# Path-traversal-shaped:
docker compose exec client curl -sk "https://203.0.113.10:8443/../../etc/passwd"
```

Each should return `403` with a message saying which rule matched.
Compare against [`waf/nginx-1.conf`](waf/nginx-1.conf) to see exactly why.
Watch it happen live: `docker compose logs -f waf1`.

### e) The firewall refusing an unforwarded port

```bash
docker compose exec client curl -sk --max-time 5 http://203.0.113.10:8404/
```

This should simply time out — there's no DNAT rule forwarding port 8404
anywhere. See [`docs/05-firewall-and-nat.md`](../docs/05-firewall-and-nat.md).

### f) Optional/advanced: connect your own device over the VPN

This is the one exercise that involves your actual laptop/phone, not just
containers, because it's demonstrating what a VPN does for a *real*
endpoint (docs/04, docs/06).

1. Open the wg-easy admin UI: `http://localhost:51821`. Set up an admin
   password on first visit (the exact first-run flow depends on which
   wg-easy version you pulled — that's fine, the concept is what matters).
2. Create a new client/peer. wg-easy will generate a keypair and a config
   for you, downloadable as a file or a QR code.
3. **If you want to actually connect a device outside this machine**
   (your phone, say), you'll first need to change the `WG_HOST` value in
   `docker-compose.yml` from `127.0.0.1` to an address your device can
   actually reach (your computer's LAN IP, or a public IP with port 51820
   forwarded on your real router), then `docker compose up -d vpn` to
   apply it, before creating the peer config. Connecting from the *same*
   machine the lab is running on works fine with the `127.0.0.1` default,
   using the WireGuard desktop app.
4. Install a WireGuard client, import the config, connect.
5. **Without the VPN connected**, this should fail/time out:
   ```bash
   curl -s --max-time 5 http://<your-docker-host-LAN-IP-or-localhost>:8404/
   ```
   (Port 8404 isn't published to your host at all in this compose file,
   by design — with the VPN off, there is genuinely no path to it from
   outside the DMZ network, matching how it behaves from the internet.)
6. **With the VPN connected**, reach the stats page directly by its
   internal DMZ address, now reachable because your traffic enters the
   DMZ network through the tunnel:
   ```bash
   curl -s http://10.10.10.10:8404/
   ```
   If this works, you've just watched a VPN do the one thing it exists to
   do: make a resource that was genuinely unreachable a moment ago,
   reachable, without changing anything about the resource itself.

## 5. Look under the hood

```bash
# The actual iptables rules doing NAT and filtering:
docker compose exec firewall iptables -t nat -L -n -v
docker compose exec firewall iptables -L -n -v

# Any container's own view of its network config (docs/03, docs/04):
docker compose exec web1 ip addr show
docker compose exec web1 ip route show

# HAProxy's live view of backend health:
docker compose exec client curl -s http://10.10.10.10:8404/ | head -40

# Logs from any hop:
docker compose logs -f waf1
docker compose logs -f reverse-proxy-1
```

## 6. Tear down

```bash
docker compose down -v
```

(`-v` also removes the VPN's saved state volume, so the next `up` starts
completely fresh.)

## Troubleshooting / known risk areas

This lab was authored without being able to run it end-to-end (see the
top-level README). The design is built on standard, well-understood
Linux networking primitives (`iptables` DNAT/MASQUERADE, `ip_forward`,
manual routes, HAProxy's PROXY protocol, nginx's `realip` module) rather
than anything exotic, but a few specific spots are worth knowing about if
something doesn't work on the first try:

- **`fix-routes.sh` fails on the `vpn` service with "ip: not found"** —
  this means that particular build of the `wg-easy` image doesn't bundle
  `iproute2`. Check what's available with
  `docker compose exec vpn sh -c "which ip busybox"` and adjust the
  command (e.g. `busybox ip route replace ...`).
- **HAProxy shows both WAF backends as down** on the stats page — check
  `docker compose logs loadbalancer` and `docker compose logs waf1`.
  This is most likely a `send-proxy`/`check-send-proxy` mismatch (see the
  comments in [`haproxy.cfg`](haproxy.cfg)) — HAProxy config option names
  occasionally shift between versions; check the version's own docs
  (`docker compose exec loadbalancer haproxy -v`) against
  https://docs.haproxy.org/ if the exact keyword has moved.
- **`wg-easy`'s exact environment variable names** (`WG_HOST`,
  `WG_DEFAULT_ADDRESS`) are based on that project's documented interface
  at the time of writing, but VPN admin-UI projects iterate quickly —
  check https://github.com/wg-easy/wg-easy's current README against
  `docker-compose.yml` if the container doesn't come up cleanly.

None of these affect the *concepts* in the docs — they're exactly the
kind of "the exact flag changed in v15" friction that's normal when
working with real infrastructure, which is arguably still a useful thing
to practice debugging.
