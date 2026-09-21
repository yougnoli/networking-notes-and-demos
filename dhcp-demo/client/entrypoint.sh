#!/bin/sh
# entrypoint.sh — this is the whole demo.
#
# Docker already gave this container an IP address automatically the
# moment it started (that's Docker's own IPAM acting like a tiny DHCP
# server). To actually see DHCP happen — the DORA handshake described in
# docs/04-the-endpoint-nic-dhcp-gateway.md — we deliberately throw that
# address away and ask for a real one from dnsmasq instead, with tcpdump
# capturing every packet of the exchange so nothing is hidden.
set -e

echo "[client] my Docker-assigned address, before we throw it away:"
ip addr show eth0 | grep "inet "

echo
echo "[client] starting a packet capture of DHCP traffic (UDP ports 67 and 68)..."
tcpdump -i eth0 -n -vv 'udp port 67 or udp port 68' &
TCPDUMP_PID=$!
sleep 1

echo
echo "[client] flushing our address — as far as this NIC is concerned, we now"
echo "[client] have no IP at all, exactly like a freshly booted machine."
ip addr flush dev eth0

echo
echo "[client] requesting a lease via DHCP. Watch the tcpdump output below for"
echo "[client] the four-way handshake: Discover -> Offer -> Request -> Ack."
echo "----------------------------------------------------------------------"
udhcpc -i eth0 -f -v -n -t 5 -q || echo "[client] udhcpc exited (see output above for why)"
echo "----------------------------------------------------------------------"

sleep 2
kill "$TCPDUMP_PID" 2>/dev/null || true
wait "$TCPDUMP_PID" 2>/dev/null || true

echo
echo "[client] our address, subnet, and gateway AFTER the DHCP handshake:"
ip addr show eth0 | grep "inet "
ip route show

echo
echo "[client] done. Compare the numbers above to dhcp-demo/dnsmasq/dnsmasq.conf —"
echo "[client] every one of them (the address range, the gateway, the DNS server)"
echo "[client] was handed to us by the DHCP server, not configured locally."
echo "[client] Re-run with: docker compose restart client"

# Keep the container alive so you can inspect it / re-run manually.
tail -f /dev/null
