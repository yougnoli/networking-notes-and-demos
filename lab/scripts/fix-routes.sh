#!/usr/bin/env bash
# fix-routes.sh — point the DMZ containers at the firewall as their
# actual default gateway.
#
# Why this is needed at all: Docker automatically gives every container
# a default route pointing at its own network's bridge gateway — a
# plumbing detail of the Docker host, not any container we control. For
# most Compose stacks that's irrelevant, because containers only ever
# talk to direct neighbors on the same network. But in this lab, the
# load balancer and the VPN server both receive traffic whose *source*
# address is on a completely different network (an internet client, or a
# VPN peer) — see docs/05-firewall-and-nat.md and docs/11 for exactly
# why. Replying to that traffic means looking up a route to a foreign
# subnet, and Docker's automatic route is a dead end for that. So we
# manually point these two containers at our own firewall/VPN server
# instead, exactly the way a real machine's default gateway would be
# configured by hand or by DHCP (docs/04-the-endpoint-nic-dhcp-gateway.md).
#
# Run this once after `docker compose up -d`, before testing anything.
set -euo pipefail
cd "$(dirname "$0")/.."   # lab/

echo "==> loadbalancer: default route via the firewall (10.10.10.1)"
docker compose exec -T loadbalancer ip route replace default via 10.10.10.1

echo "==> loadbalancer: route the VPN's client pool (10.13.13.0/24) via the VPN server (10.10.10.5)"
echo "    (so replies to a connected VPN client find their way back through the tunnel)"
docker compose exec -T loadbalancer ip route replace 10.13.13.0/24 via 10.10.10.5 || \
  echo "    (skipped — harmless if you haven't brought the VPN up yet; re-run this script after you do)"

echo "==> vpn: default route via the firewall (10.10.10.1)"
docker compose exec -T vpn ip route replace default via 10.10.10.1 || \
  echo "    (if this failed with 'ip: not found', see the troubleshooting section in lab/README.md)"

echo "==> done. See docs/05-firewall-and-nat.md for why this step exists."
