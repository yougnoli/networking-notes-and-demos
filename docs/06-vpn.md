# VPN

Here's the one-sentence version of what a VPN server does:

> Gives an IP address to that IP range

That single sentence is actually the crux of what a VPN is *for*, so
let's unpack it properly.

## The problem a VPN solves

Some resources only trust "internal" traffic — traffic that appears to
come from inside the private network (the DMZ, in our diagram). A
firewall enforces this by simply not forwarding any port to those
resources (doc 05) — there is no legitimate way in from the public
internet, on purpose.

But sometimes a legitimate user genuinely needs access from outside — a
remote employee, someone on a client site, whatever. The VPN's job is to
make that person's device **appear to be inside the private network**,
without punching a hole in the firewall for the general public.

**In data terms:** this is exactly the situation behind a data warehouse
or a model-serving endpoint that's configured to only accept connections
from inside a private network (a "VPN-only" or "private-link" data
source, in the language a data platform team might use). The data itself
never moves anywhere different — what changes is whether your laptop is
allowed to ask for it at all.

## How it does that

1. The client establishes an **encrypted tunnel** to the VPN server (in
   our lab, over UDP port 51820, forwarded by the firewall — doc 05's
   Job 3, inbound direction).
2. The VPN server authenticates the client (a pre-shared key pair, in the
   case of WireGuard — no passwords, no certificates to manage, just a
   public/private keypair like SSH).
3. The VPN server **hands the client an IP address from its own private
   pool** — in this lab, something like `10.13.13.2`, from the
   `10.13.13.0/24` range. This is the "gives an IP from that range" part.
4. A new virtual network interface appears on the client (this is exactly
   the "multihoming" from doc 04 — the laptop now has an extra NIC that
   didn't exist a moment ago, e.g. `wg0`).
5. The client's routing table is updated so that traffic destined for the
   private network's address range gets sent out through that new virtual
   interface, into the tunnel, instead of out through the normal Wi-Fi/
   Ethernet interface.

From that point on, as far as the private network is concerned, the
client's traffic really is coming from inside — because, logically, it
is: it arrives already decrypted, from an internal-range address
(`10.13.13.x`), on the private side of the VPN server, having never
touched the firewall's "traffic from the internet" path at all.

## Full tunnel vs. split tunnel

Two common modes:

- **Full tunnel** — *all* of the client's internet traffic routes through
  the VPN, even traffic bound for ordinary public websites. Common for
  corporate security policies that want to inspect/filter all traffic.
- **Split tunnel** — only traffic bound for the private network's address
  range goes through the tunnel; everything else uses the normal internet
  connection directly. More efficient, common for "I just need to reach
  our internal tools."

This repo's lab uses split-tunnel-style behavior by default (only the
`10.10.10.0/24` DMZ range is routed through the tunnel), because the
whole point of this VPN, here, is reaching the internal-only resource
described below — not proxying general internet traffic.

## Why WireGuard, specifically

There are several VPN protocols/technologies (IPsec, OpenVPN, WireGuard).
This lab uses **WireGuard** because it's the simplest to reason about:
it's a small, modern protocol built on well-known cryptographic
primitives, configuration is just a handful of lines (a private key, a
peer's public key, an allowed IP range, an endpoint), and it ships in the
Linux kernel itself. The lab uses
[wg-easy](https://github.com/wg-easy/wg-easy), a small web UI wrapped
around WireGuard, specifically so you can watch the "hand out a config,
hand out an IP" process happen through a browser instead of hand-editing
config files.

## The concrete demonstration in this lab

The lab includes one resource that is **only** reachable from inside the
DMZ and is never forwarded through the firewall: HAProxy's statistics
dashboard, on port 8404. There is no `iptables DNAT` rule for it
anywhere — it's simply invisible from the public internet, the same way
an internal admin tool would be in a real company.

- **Without the VPN**, hitting it from the `client` container (playing
  the public internet) times out — there's no path in.
- **With the VPN connected**, your traffic enters the DMZ network
  directly through the tunnel, bypassing the public-facing firewall path
  entirely, and the dashboard becomes reachable.

That contrast — unreachable, then reachable, with nothing about the
dashboard itself changing — is the entire point of a VPN in one demo.

## Try it in the lab

The full walkthrough (creating a VPN peer in the wg-easy UI, installing a
WireGuard client on your own machine, and reaching the internal
dashboard) is in [`lab/README.md`](../lab/README.md#optionaladvanced-connect-your-own-device-over-the-vpn),
since it requires steps on your actual device, not just inside Docker.

One thing worth doing right away, without connecting anything: open the
wg-easy admin UI (`http://localhost:51821` once the stack is up) and
look at how little information it needs from you to create a fully
functioning VPN peer — a name, and it generates the keypair and the IP
assignment for you.
