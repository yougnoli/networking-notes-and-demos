# Worked example: doing this for real, from scratch

Everything in `docs/` and `lab/` is a simulation — real concepts, but
running in Docker containers so nobody needs to touch their actual home
network to learn from it. This is the opposite: a complete, from-scratch,
step-by-step build of the real thing, using:

- a **Telenet** internet connection, put into bridge mode so it stops
  being the firewall,
- an **ASUS RT-BE92U** (marketed as the "BE9700") as the real router,
  firewall, and VPN server, and
- a **Raspberry Pi**, running `lab/` for real, sitting behind that
  router on your actual home network.

The specific ISP, router, and single-board computer named here are just
the worked example. The steps generalize to almost any consumer router
with real firewall/VPN settings, behind almost any ISP gateway, running
the lab on any small always-on Linux machine.

## The goal, in one sentence

Stop trusting the ISP's gateway to be your firewall, router, and (if you
use it) VPN endpoint, and make your own hardware do those jobs instead —
the exact jobs described in
[`docs/05-firewall-and-nat.md`](../docs/05-firewall-and-nat.md) and
[`docs/06-vpn.md`](../docs/06-vpn.md), running for real.

## Shopping list

- The router (ASUS RT-BE92U / BE9700 in this example).
- A Raspberry Pi (4 or 5, 4 GB+ RAM recommended) + a 32 GB+ microSD card
  + its power supply.
- **Two Ethernet cables**: ISP gateway → router WAN port, and
  router LAN port → Raspberry Pi. **Cat 6, U/UTP** is the right choice for
  both — plenty for the router's 2.5 Gbps ports and the Pi's 1 Gbps port,
  at normal home cable lengths. Skip S/FTP/Cat 8 unless a run has to pass
  right alongside mains power cabling for several meters — the extra
  shielding does nothing for a normal patch cable and just makes it
  stiffer to route. (If S/FTP is genuinely all that's available in the
  length you need, it works exactly the same electrically — it's not
  worse, just unnecessary.)
- Nothing extra for Wi-Fi-only devices.
- Only if you're wiring a different room too: more Cat 6 cable, and a
  small unmanaged switch if that room needs more wired ports than the
  router gives you directly.

## Build it in this order

| # | Doc | What it covers |
|---|-----|-----------------|
| 1 | [Bridge the ISP gateway](01-bridge-the-isp-gateway.md) | Stopping the Telenet box from routing at all, so double-NAT doesn't undo everything after it |
| 2 | [Router setup and hardening](02-router-setup-and-hardening.md) | First login, firmware, firewall posture, and the VPN server — all on the ASUS router itself |
| 3 | [Raspberry Pi setup](03-raspberry-pi-os-setup.md) | Flashing Raspberry Pi OS headless, first boot, SSH access, a fixed DHCP lease |
| 4 | [Run the lab for real](04-run-the-lab-on-the-pi.md) | Installing Docker on the Pi, cloning the repo, running `lab/` and `dhcp-demo/` behind your own firewall |

Each doc ends with a checkpoint — don't move to the next one until every
box is checked. Getting step 1 wrong (still double-NATed) is the single
most common way for everything after it to behave strangely for reasons
that look unrelated.

## What doesn't translate directly

The **load balancer, WAF, and reverse proxy** boxes from the main diagram
exist to protect and scale a *public-facing service* — they're not really
"home network" concerns unless you're also self-hosting something public
(a personal website, a game server, a Home Assistant instance reachable
from outside). If you ever do that, the same concepts still apply: put a
reverse proxy in front of whatever you're hosting, and consider a
lightweight WAF if it's genuinely public-facing. For a normal home
network, the firewall and VPN server are the two pieces that matter, and
both are covered above.

## Full verification checklist

- [ ] Telenet gateway confirmed in bridge mode
- [ ] ASUS router's WAN page shows a real public IP, not a private one
- [ ] Router admin password and Wi-Fi password changed from defaults
      (and are different from each other)
- [ ] Router firmware updated
- [ ] SPI firewall on, remote/WAN admin off, UPnP off, no unexplained
      port forwards
- [ ] VPN server enabled on the router and tested from outside your home
      network
- [ ] Raspberry Pi flashed, reachable over SSH, with a fixed DHCP lease
- [ ] Docker + Compose installed on the Pi
- [ ] `lab/` running on the Pi, reachable at `https://<pi-ip>:8443/` from
      another device on your home network
- [ ] (Optional) IoT devices moved to an isolated guest network
- [ ] (Optional) `dhcp-demo/` also running on the Pi
