# Step 2 — Router setup and hardening (ASUS RT-BE92U)

By now the Telenet gateway is bridged (previous doc) and is just a
transparent pass-through. This step turns the ASUS router into the real
firewall, router, and VPN endpoint for your home — everything
[`docs/05-firewall-and-nat.md`](../docs/05-firewall-and-nat.md) and
[`docs/06-vpn.md`](../docs/06-vpn.md) describe, running on real hardware.

## 2.1 — Unbox and cable up

1. Note the router's default admin password and default Wi-Fi name/password,
   both usually on a sticker on the underside of the device — you'll
   change both shortly, but you need them for the very first login.
2. Connect **one Ethernet cable** from the (now bridged) Telenet gateway
   to the router's **WAN port** — usually a different color or explicitly
   labeled "WAN"/"Internet," separate from the numbered LAN ports.
3. Plug in power and wait roughly a minute for it to fully boot (the
   status LEDs settling down is a reasonable sign it's ready).

## 2.2 — First login

1. Connect a laptop/phone to the router's **default Wi-Fi network** (name
   and password from the sticker), or plug your laptop into one of its
   LAN ports with a spare cable — Ethernet is more reliable for this
   first setup step.
2. Open a browser and go to `http://router.asus.com` or `192.168.50.1`
   (check the quick-start card in the box for the exact default for this
   model — ASUS has used both `192.168.1.1` and `192.168.50.1` as
   defaults across different product lines).
3. The setup wizard should detect the WAN connection automatically
   (most common for Telenet after bridging) and walk you through:
   - **Setting a new admin password.** This is the password for the
     router's *management page* — different from the Wi-Fi password
     below. Mixing these two up is the single most common setup mistake;
     keep them distinct in your head (or a password manager) from the
     start.
   - **Setting your new Wi-Fi network name and password.** This is what
     your phones/laptops actually connect to day-to-day.
4. If the wizard asks for a connection type and doesn't auto-detect, pick
   **DHCP/Automatic IP** first — that's what Telenet uses in the large
   majority of cases. Only use PPPoE if Telenet explicitly told you your
   account needs it.

## 2.3 — Update firmware immediately

Before configuring anything else: check *Administration* → *Firmware
Upgrade* (menu wording may vary slightly by firmware version) and install
any available update. New routers frequently ship with several security
fixes already available by the time you unbox them.

## 2.4 — Confirm bridging actually worked

Check the router's **WAN status page** (usually on the main Network Map /
dashboard). It should show a real public IP address — something that
does *not* start with `10.`, `172.16.` through `172.31.`, or `192.168.` —
see [`docs/03-ip-addresses-and-subnets.md`](../docs/03-ip-addresses-and-subnets.md)
if that distinction isn't obvious at a glance. If the WAN IP is still a
private-looking address, bridge mode isn't actually active — go back and
re-check the previous doc before continuing, since nothing past this
point will work reliably through a second layer of NAT.

## 2.5 — Firewall hardening

Under *Advanced Settings* → *Firewall* (exact wording varies by firmware
version):

- Confirm the firewall (**SPI** — stateful packet inspection) is **on**.
  This is the real-world version of the lab's `conntrack`-based
  `ESTABLISHED,RELATED` rule: replies to connections you started are let
  back in automatically; nothing else is.
- Turn **off remote/WAN administration**. The router's own login page
  should never be reachable from the internet side — the real-world
  equivalent of "there's no DNAT rule for this port" in
  [`docs/05-firewall-and-nat.md`](../docs/05-firewall-and-nat.md).
- Turn **off UPnP**, unless something specific you actually use depends
  on it. UPnP lets any device on your network ask the router to open a
  port to the internet on its own behalf, with no confirmation from you —
  it quietly works against the default-deny posture you just set up.
- Leave port forwarding empty unless you have a specific, explainable
  reason for a specific port. Prefer the VPN (next section) over a
  forwarded port whenever you have the choice.

## 2.6 — Set up the VPN server

Under *Advanced Settings* → *VPN* → *VPN Server*:

1. Enable **WireGuard** if this firmware version offers it (simpler and
   more modern than OpenVPN — the same reasoning behind the lab's choice
   of WireGuard in [`docs/06-vpn.md`](../docs/06-vpn.md)). OpenVPN works
   the same way conceptually if WireGuard isn't available yet.
2. One real difference from the Docker lab worth noticing: in `lab/`, the
   VPN was a separate container, so the firewall needed an explicit DNAT
   rule to reach it. Here, the VPN server runs *on* the router itself —
   enabling the feature is what opens the port on the router's own
   firewall, for the router's own service. No separate forwarding rule to
   add.
3. Create a client profile — the router generates the config (often as a
   QR code) for you. Install the matching WireGuard or OpenVPN app on
   your phone and scan/import it.
4. **Test it from outside your home network**: turn off Wi-Fi on your
   phone, connect over mobile data using the VPN app, and confirm you can
   reach something on your home network that isn't otherwise exposed to
   the internet. This is
   [`docs/11-full-request-walkthrough.md`](../docs/11-full-request-walkthrough.md)'s
   Path B, happening on your actual phone instead of lab containers.

## 2.7 (optional) — Separate your IoT devices

Most ASUS routers offer a **Guest Network** that's a genuinely separate
subnet with client isolation, not just a second Wi-Fi password. Putting
smart-home/IoT gear on it is a real instance of the subnetting idea from
[`docs/03-ip-addresses-and-subnets.md`](../docs/03-ip-addresses-and-subnets.md):
a device there can reach the internet but can't casually reach your
laptop or the Raspberry Pi you're about to set up, the same way the lab's
`dmz` and `internet` networks can't reach each other without something
explicitly allowing it.

## Checkpoint before moving on

- [ ] Admin password and Wi-Fi password both changed from defaults, and
      are two different values
- [ ] Firmware updated
- [ ] WAN page shows a real public IP
- [ ] SPI firewall on, remote admin off, UPnP off
- [ ] No unexplained port forwards
- [ ] VPN server enabled and successfully tested from outside your home
      network

Continue to [Step 3 — Setting up the Raspberry Pi](03-raspberry-pi-os-setup.md).
