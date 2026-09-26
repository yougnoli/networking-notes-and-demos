# Worked example: doing this for real on an ASUS RT-BE92U

Everything in `docs/` and `lab/` is a simulation — real concepts, but running
in Docker containers so nobody needs to touch their actual home network to
learn from it. This doc is the opposite: it's a concrete walkthrough of
turning those same concepts into a real, physical home network, using one
specific router (an **ASUS RT-BE92U**, marketed as the "BE9700") in front of
a Telenet internet connection.

The router and ISP named here are just the worked example. The steps are the
same shape for almost any consumer router with real firewall/VPN settings
(most of the ASUS lineup, and equivalents on other brands) sitting behind
almost any ISP-provided modem/gateway.

## The goal, in one sentence

Stop trusting the ISP's gateway to be your firewall, router, and (if you use
it) VPN endpoint, and make your own router do those jobs instead — the exact
jobs described in [`docs/05-firewall-and-nat.md`](../docs/05-firewall-and-nat.md)
and [`docs/06-vpn.md`](../docs/06-vpn.md), just running on real hardware
instead of an `alpine` container.

## What you need

- The router (ASUS RT-BE92U / BE9700 in this example).
- **One Ethernet cable** from the ISP's gateway to the router's WAN
  (usually blue/labeled) port. Most routers include a short one in the box —
  check the contents sticker before buying another. If you need one anyway,
  get **Cat 6**, not Cat 5e: it costs almost nothing extra and won't
  bottleneck a fast connection.
- **Cat 6 (or Cat 6a)** for anything you plug into the router's 2.5 Gbps
  LAN ports at full speed (a NAS, a desktop, a games console). A Cat 5e
  cable will quietly cap those ports at 1 Gbps.
- Nothing extra for Wi-Fi-only devices.
- Only if you're wiring a different room: more Cat 6 cable, and a small
  unmanaged switch if that room needs more wired ports than the router
  gives you directly.

## Step 1 — Stop the ISP gateway from routing at all

This is the step that actually matters most, and it's easy to skip by
accident. If you just plug the new router in downstream of the Telenet
gateway without changing anything, you get **double NAT**: the Telenet
gateway does NAT and firewalling, then your ASUS router does *another*
layer of NAT and firewalling behind it. Nothing you configure on the ASUS
router — port forwards, the VPN server, custom firewall rules — reliably
works through two layers of translation. You have to remove the first
layer.

The fix is **bridge mode** (sometimes called "modem-only mode"): it tells
the ISP gateway to stop being a router entirely and just pass the raw
internet connection straight through to whatever's plugged into it.

1. Log into the Telenet gateway's admin page, or the My Telenet
   app/portal, and look for a bridge mode / modem-only setting.
2. Before enabling it, check Telenet's support pages for your specific
   plan — on some plans, features tied to the gateway itself (interactive
   TV features, in particular) can stop working once it's bridged. If you
   don't use those, this doesn't matter.
3. Once bridged, the Telenet gateway hands out a public IP directly to
   whatever's connected to it — which is about to be your ASUS router's
   WAN port.

If your ISP genuinely cannot do bridge mode on your plan, you can still
improve things by putting the ASUS router in "AP mode" instead and
accepting that the ISP box remains the real firewall — but that gives up
the actual goal here (your own firewall and VPN, not the ISP's), so bridge
mode is worth pushing for.

## Step 2 — Physical setup

```
Telenet ONT/gateway (bridged)  --Ethernet-->  ASUS RT-BE92U [WAN port]
                                                     |
                                          [LAN ports]  (Wi-Fi)
                                                |            |
                                          wired devices   your phone/laptop
```

This is the exact same shape as
[`docs/02-big-picture-architecture.md`](../docs/02-big-picture-architecture.md)'s
opening box — the router is now the one and only thing standing between
"the internet" and everything in your home.

## Step 3 — Initial router setup

1. Connect a device to the ASUS router (Wi-Fi is fine for setup) and open
   its admin page (usually `http://router.asus.com` or `192.168.50.1` by
   default — check the quick-start card in the box for this exact model).
2. Set a real admin password immediately. This page is the single most
   security-critical page in your home — never leave it on a default.
3. Update the firmware before doing anything else. New routers frequently
   ship with several security patches already available.
4. Confirm the WAN page shows a public IP address, not another private
   one (like `10.x.x.x` or `192.168.x.x`) — if it shows a private address,
   bridge mode isn't actually active yet and you're still double-NATed.
   This is worth double-checking against
   [`docs/03-ip-addresses-and-subnets.md`](../docs/03-ip-addresses-and-subnets.md)'s
   public-vs-private explanation if the distinction isn't obvious from the
   number alone.

## Step 4 — Firewall hardening

This maps directly to [`docs/05-firewall-and-nat.md`](../docs/05-firewall-and-nat.md):
the same "default deny, explicitly allow only what's needed" posture, just
configured through a web UI instead of hand-written `iptables` rules.

In the router's admin UI (under something like *Advanced Settings →
Firewall* — exact wording varies by firmware version):

- Confirm the firewall (SPI — stateful packet inspection) is **on**. This
  is the same "stateful" behavior the lab's firewall gets from
  `conntrack`/`ESTABLISHED,RELATED` — replies to connections you made are
  let back in automatically, nothing else is.
- Turn **off remote/WAN administration** — the router's own admin page
  should never be reachable from the internet side. This is the real-world
  version of "there is no DNAT rule for this port" from the lab.
- Turn **off UPnP** unless something you actually use depends on it. UPnP
  lets *any* device on your network ask the router to open a port to the
  internet on its behalf, with no confirmation — it quietly undoes the
  default-deny posture you just set up.
- Only forward the specific ports something genuinely needs, the same
  narrow, explicit exception described in the lab's DNAT section — and
  when in doubt, prefer the VPN over a forwarded port (next step).

## Step 5 — Set up your own VPN server

This is [`docs/06-vpn.md`](../docs/06-vpn.md), for real. Under something
like *Advanced Settings → VPN → VPN Server* in the admin UI:

1. Enable the **WireGuard** server if this firmware version offers it
   (newer and simpler than OpenVPN — same reasoning as the lab's choice of
   WireGuard over other options). If not available yet, OpenVPN works the
   same way conceptually.
2. Note one real difference from the lab: in `lab/`, the VPN server was a
   separate container, so the firewall needed an explicit DNAT rule to
   reach it (`lab/firewall/firewall-rules.sh`). Here, the VPN server runs
   *on* the router itself, so there's no separate forwarding rule to add —
   enabling the feature is what opens the port, on the router's own
   firewall, for the router's own service.
3. Generate a client config (the router will do this for you) and install
   the matching WireGuard/OpenVPN app on your phone or laptop.
4. Test it while away from home: turn off Wi-Fi, connect over mobile data
   with the VPN client, and confirm you can reach something on your home
   network that isn't otherwise exposed to the internet — the same
   "unreachable, then reachable, nothing else changed" demonstration from
   [`docs/11-full-request-walkthrough.md`](../docs/11-full-request-walkthrough.md)'s
   Path B, just with your own devices instead of lab containers.

## Step 6 (optional) — Separate your IoT devices

Most ASUS routers support a **Guest Network** that's actually a separate
subnet with client isolation, not just a separate Wi-Fi password. Putting
smart-home/IoT devices on it is a real-world instance of the subnetting
idea from [`docs/03-ip-addresses-and-subnets.md`](../docs/03-ip-addresses-and-subnets.md):
a device on that subnet can reach the internet, but can't casually reach
your laptop or NAS on the main network, the same way the lab's `dmz` and
`internet` networks can't reach each other without something explicitly
allowing it.

## What doesn't translate directly

The **load balancer, WAF, and reverse proxy** boxes from the diagram exist
to protect and scale a *public-facing service* — they're not really
"home network" concerns unless you're also self-hosting something public
(a personal website, a game server, a Home Assistant instance reachable
from outside). If you ever do that, the same concepts apply: put a reverse
proxy in front of whatever you're hosting, and consider a lightweight WAF
if it's genuinely public. For a normal home network, the firewall and VPN
server above are the two pieces that matter.

## Verification checklist

- [ ] Telenet gateway is in bridge mode (WAN page on the ASUS router shows
      a public IP, not a private one)
- [ ] Router admin password changed from default, firmware updated
- [ ] Remote/WAN administration disabled
- [ ] UPnP disabled (unless something specific needs it)
- [ ] No port forwards except ones you can explain the need for
- [ ] VPN server enabled and tested from outside your home network
- [ ] (Optional) IoT devices moved to the guest/isolated network
