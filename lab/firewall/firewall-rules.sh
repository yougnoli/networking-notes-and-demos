#!/bin/sh
# firewall-rules.sh — the actual firewall/NAT/routing config for the lab.
#
# This one file does everything docs/05-firewall-and-nat.md describes:
#   1. Turns this box into an actual router (ip_forward).
#   2. Filters: default-deny, explicitly allow only what should work.
#   3. NATs: DNAT for inbound port-forwarding, MASQUERADE for outbound.
#
# Read it top to bottom — every rule has a comment explaining why it
# exists, and there's nothing in the actual ruleset that isn't explained
# somewhere below.

set -e

echo "[firewall] enabling IPv4 forwarding — this is the one setting that"
echo "[firewall] turns 'a Linux box with two NICs' into an actual router."
sysctl -w net.ipv4.ip_forward=1 >/dev/null

# Docker doesn't guarantee which of our two attached networks ends up as
# eth0 vs eth1 inside the container, so instead of hardcoding an
# interface name, we find each interface by the address we know it holds
# (set explicitly in docker-compose.yml).
INTERNET_IF=$(ip -o -4 addr show | awk '$4 ~ /^203\.0\.113\./ {print $2; exit}')
DMZ_IF=$(ip -o -4 addr show | awk '$4 ~ /^10\.10\.10\./ {print $2; exit}')

echo "[firewall] internet-facing interface: $INTERNET_IF (203.0.113.10)"
echo "[firewall] dmz-facing interface:      $DMZ_IF (10.10.10.1)"

# ---------------------------------------------------------------------
# Job 2: filtering. Default posture is deny-everything, then explicitly
# allow the small list of things that should actually work. This is the
# same instinct as least-privilege IAM: start from zero, grant exactly
# what's needed.
# ---------------------------------------------------------------------

iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT   # the firewall itself may always originate traffic

# Loopback and "this is a reply to something we already allowed out" are
# always fine. This ESTABLISHED/RELATED rule is what makes this a
# *stateful* firewall: a response doesn't need its own mirror-image rule.
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Let ping through, in both directions — purely so you can play with
# `ping`/`traceroute` from the client container while learning. A real
# edge firewall would think much harder about this.
iptables -A INPUT -p icmp -j ACCEPT
iptables -A FORWARD -p icmp -j ACCEPT

# The only two brand-new inbound connections this firewall will ever
# forward from the internet into the DMZ: the public HTTPS entry point,
# and the VPN. Try anything else from the client container and it will
# simply hang — see docs/05-firewall-and-nat.md.
iptables -A FORWARD -i "$INTERNET_IF" -o "$DMZ_IF" -p tcp --dport 8443 -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -i "$INTERNET_IF" -o "$DMZ_IF" -p udp --dport 51820 -m conntrack --ctstate NEW -j ACCEPT

# This lab doesn't restrict outbound/east-west traffic — anything already
# inside the DMZ can freely start new connections toward the internet
# network. (In a real network you'd likely restrict this too; kept open
# here to keep the lab focused on the inbound side of the firewall.)
iptables -A FORWARD -i "$DMZ_IF" -o "$INTERNET_IF" -m conntrack --ctstate NEW -j ACCEPT

# ---------------------------------------------------------------------
# Job 3a: DNAT ("port forwarding") — rewrite the *destination* of an
# allowed inbound connection so it actually reaches something running
# inside the DMZ. Nothing else in the DMZ is reachable from the internet
# network, because nothing else has a rule here.
# ---------------------------------------------------------------------

iptables -t nat -A PREROUTING -i "$INTERNET_IF" -p tcp --dport 8443 \
  -j DNAT --to-destination 10.10.10.10:443

iptables -t nat -A PREROUTING -i "$INTERNET_IF" -p udp --dport 51820 \
  -j DNAT --to-destination 10.10.10.5:51820

# ---------------------------------------------------------------------
# Job 3b: SNAT/MASQUERADE ("here it's me") — rewrite the *source* of
# outbound DMZ traffic to look like it came from this firewall's own
# public-side address, so replies know where to come back to, and so the
# DMZ's private addresses are never exposed to the internet network.
# ---------------------------------------------------------------------

iptables -t nat -A POSTROUTING -o "$INTERNET_IF" -j MASQUERADE

echo "[firewall] rules loaded:"
echo "----------------------------------------------------------------"
iptables -t nat -L -n -v
echo "----------------------------------------------------------------"
iptables -L -n -v
echo "----------------------------------------------------------------"

# Keep the container (and these rules) running.
exec tail -f /dev/null
