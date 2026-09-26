# Step 1 — Put the Telenet gateway into bridge mode

Do this **before** you touch the new router. Everything after this step —
the firewall rules, the VPN server, all of it — depends on the ASUS router
being the *only* thing doing NAT and firewalling on your connection. If
you skip this, you get **double NAT** (explained in the main
[`README.md`](README.md)) and nothing forwards or connects reliably.

## Before you start

- Have your Telenet account details ready (login for My Telenet).
- Find the gateway's default login. It's usually on a sticker on the
  device itself (login/password, and sometimes a WPA key — different
  thing, ignore that one for this).
- **Write down your current Wi-Fi name and password from that sticker
  anyway**, even though you're about to stop using this device's Wi-Fi —
  if anything goes wrong and you need to temporarily fall back to it,
  you'll want it.

## Why this doc can't give you an exact click-by-click path

Telenet's self-service portal and app change their layout over time, and
the exact steps also depend on which specific gateway model they gave
you. Rather than hand you a screenshot-perfect path that might already be
stale by the time you read this, here's the reliable way to find the
*current* real steps, plus what to actually look for once you're there.

## Finding the setting

Try these in order — stop as soon as one works:

1. **The gateway's own local admin page.** Connect to it (Wi-Fi or
   Ethernet) and browse to its management address — commonly
   `192.168.0.1` or `192.168.1.1` for Telenet gateways, check the sticker
   on the device if neither works. Look for a menu item along the lines
   of *Gateway* → *Connection* → *Bridge Mode*, or *Advanced* →
   *Bridge Mode*.
2. **The My Telenet app or web portal.** Look under something like
   *Internet* → *Modem/Gateway settings*. Some Telenet hardware only
   exposes bridge mode here, not on the device's own local page.
3. **Telenet support directly** (chat or phone). Some gateway models
   need Telenet to flip this on from their side rather than you doing it
   yourself locally. Just ask for "bridge mode" or "modem-only mode" for
   your gateway — this is a completely standard, common request, not
   an unusual one.

Search Telenet's own support site for "bridge mode" plus your exact
gateway model name (printed on the device) if you want the current
official instructions for your specific hardware — that'll always be more
current than anything written here.

## What to expect once it's on

- The Telenet gateway's own Wi-Fi will typically switch off (or stop
  being useful) — that's expected, your ASUS router is about to take
  over that job entirely.
- The gateway stops handing out private IPs to your devices and instead
  passes the connection straight through.
- **This is also the moment your home network goes offline** until the
  ASUS router is plugged in and configured (next doc) — plan this for a
  time you don't mind being briefly without internet.

## If something goes wrong

If bridge mode causes problems and you want to undo it: the same menu
you used to enable it should let you disable it again, or Telenet support
can revert it from their side. Most gateways also have a physical reset
button that restores factory settings if the admin page becomes
unreachable — check the device's own documentation before using it, since
a factory reset undoes more than just bridge mode.

## Checkpoint before moving on

- [ ] Bridge mode is confirmed enabled (the gateway's status page, if
      still reachable, should say so)
- [ ] You have your original Telenet Wi-Fi credentials written down
      somewhere, just in case
- [ ] You're ready to physically connect the ASUS router next

Continue to [Step 2 — Router setup and hardening](02-router-setup-and-hardening.md).
