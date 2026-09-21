# Firewall & NAT

Your original notes on the firewall were:

> it knows the IP range and says "here it's me"; it acts as router as
> well, it does NATTING

That's three separate jobs bundled into one box. Let's take them one at a
time.

## Job 1: it's a router

At its most basic, a firewall in this position is also a **router** — a
device with a leg in two (or more) networks that forwards packets
between them. In our lab, the firewall container has one interface on
`internet` (`203.0.113.10`) and one on `dmz` (`10.10.10.1`). Every DMZ
host's default gateway (doc 04) points at that second address.

For a Linux box to actually forward packets between interfaces instead of
just receiving traffic addressed to itself, one kernel setting has to be
on:

```bash
sysctl -w net.ipv4.ip_forward=1
```

Without this, a Linux machine with two NICs is just a machine with two
NICs — it won't relay anything between them, on principle. This is the
very first line of [`lab/firewall/firewall-rules.sh`](../lab/firewall/firewall-rules.sh).

## Job 2: it filters ("the firewall part")

This is the part actually named after the word "firewall": a set of
rules that decide, per packet, whether it's allowed through. The default
posture in almost every real deployment (and in this lab) is **default
deny**: block everything, then explicitly allow the small list of things
that should work. This is the same principle as least-privilege IAM —
start from zero access, grant exactly what's needed.

Concretely, this repo's firewall:

- Allows established/related traffic to return (so a response to a
  request you made is allowed back in, without needing its own explicit
  rule — this is what makes a "stateful" firewall stateful).
- Allows exactly two kinds of *new inbound* connections from the
  internet: TCP to port 8443 (the public HTTPS entry point) and UDP to
  port 51820 (the VPN).
- Drops everything else inbound from the internet, no explanation given.

Try connecting to literally any other port from the `client` container
and watch it hang or get refused — that silence *is* the firewall doing
its job.

## Job 3: NAT ("here it's me")

**NAT (Network Address Translation)** rewrites the source or destination
address of packets as they cross the firewall. Two different directions,
two different purposes:

### Outbound: SNAT / "masquerade" — "here it's me"

Every container on the `dmz` network has a private address
(`10.10.10.x`) that means nothing on the public internet — it's not
globally unique and isn't supposed to be routed there (doc 03). So when,
say, `web1` (`10.10.10.41`) needs to reach something out on the internet,
the firewall rewrites the packet's source address on the way out to its
*own* public address (`203.0.113.10`) before forwarding it. To the
outside world, it looks like the firewall itself made the request — "here
it's me" — even though it's relaying on behalf of an internal host. The
firewall keeps a table of these translations so that when the reply comes
back addressed to `203.0.113.10`, it knows to rewrite it back to
`10.10.10.41` and deliver it to the right internal host.

This specific flavor of NAT — many internal addresses sharing one public
address — is often called **PAT** (Port Address Translation) or, in Linux
`iptables` terms, **MASQUERADE**, because the firewall also has to juggle
port numbers to keep track of which internal host each outbound
connection belongs to (since many internal hosts might use the same
source port independently). The `iptables` rule looks like:

```bash
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

**Data-engineering analogy:** this is a connection pool. Many app-layer
connections (internal IPs) get multiplexed onto a small number of pooled
connections (the one public IP), and the pool keeps a mapping so
responses get routed back to the right caller.

### Inbound: DNAT / "port forwarding"

The reverse direction: the firewall has a public IP, but nothing useful
is actually running *on* the firewall. When an inbound connection arrives
for `203.0.113.10:8443`, the firewall rewrites the *destination* address
to `10.10.10.10:443` (the load balancer, inside the DMZ) and forwards it
there. This is **DNAT** (Destination NAT), commonly known as **port
forwarding**:

```bash
iptables -t nat -A PREROUTING -p tcp --dport 8443 -j DNAT --to-destination 10.10.10.10:443
```

This is also, not coincidentally, exactly how a home router's "port
forwarding" settings page works, and it's why nothing on the `dmz`
network is reachable from the internet **unless a DNAT rule explicitly
says so** — there is no rule for, say, the load balancer's stats page, so
it's simply unreachable from outside, full stop, regardless of any
allow-listing further inside. That's the point.

## Firewall + NAT together

Putting it all together, the firewall in this lab:

1. Forwards packets between `internet` and `dmz` (job 1).
2. Refuses everything except two explicitly allowed inbound ports (job 2).
3. DNATs those two allowed ports to the right internal host (job 3,
   inbound direction).
4. MASQUERADEs any outbound traffic from the DMZ so internal hosts can
   reach the internet without exposing their private addresses (job 3,
   outbound direction).

See [`lab/firewall/firewall-rules.sh`](../lab/firewall/firewall-rules.sh)
for the actual, fully-commented `iptables` ruleset that does exactly this.

## Try it in the lab

```bash
# From the "client" container (playing an external internet user):

# This works — port 8443 is explicitly forwarded to the load balancer.
docker compose exec client curl -sk https://203.0.113.10:8443/

# This does NOT work — nothing forwards this port. Expect a timeout/refusal.
docker compose exec client curl -sk --max-time 5 http://203.0.113.10:8404/
```

Then look at the rules directly:

```bash
docker compose exec firewall iptables -t nat -L -n -v
docker compose exec firewall iptables -L -n -v
```
