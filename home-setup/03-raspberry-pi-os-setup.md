# Step 3 — Setting up the Raspberry Pi

The Raspberry Pi is going to be the machine that actually runs `lab/` (and
optionally `dhcp-demo/`) for real, sitting on your now-secured home
network behind the ASUS router. This doc gets it from "bare board" to
"reachable over SSH" — no monitor or keyboard needed for any of this.

## What you need

- A Raspberry Pi (any model with Ethernet and enough RAM to run several
  small Docker containers comfortably — a Pi 4 or Pi 5 with 4 GB+ RAM is
  a good fit for `lab/`'s ten-ish lightweight containers).
- A microSD card, 32 GB or larger (8 GB technically boots, but Docker
  images and logs fill it up fast — give yourself room).
- The Pi's power supply.
- The Cat 6 Ethernet cable from the [previous shopping list](README.md).
- A computer (any OS) to prepare the SD card from.

## 3.1 — Flash Raspberry Pi OS

1. Install **Raspberry Pi Imager** — the official tool from the Raspberry
   Pi Foundation — on your regular computer.
2. Insert the microSD card into that computer (via a USB adapter if
   needed).
3. Open Raspberry Pi Imager:
   - **Device**: pick your specific Pi model.
   - **Operating System**: choose **Raspberry Pi OS Lite (64-bit)**. You
     don't need the desktop version — this machine has no monitor and no
     GUI, it's a small server. 64-bit matters: Docker and most container
     images run best (and sometimes only) on 64-bit ARM.
   - **Storage**: select your SD card. Double-check you've picked the SD
     card and not another drive — this step erases the target.
4. Before writing, click the **gear/advanced-options icon** (or press
   `Ctrl+Shift+X`) and set these up in advance — this is what makes the
   Pi reachable over SSH the moment it boots, with no keyboard or monitor
   ever needed:
   - **Hostname** — pick something memorable, e.g. `networklab`.
   - **Enable SSH**, with password authentication (or your own SSH key,
     if you already use one).
   - **Set username and password** for the Pi's own login.
   - **Configure locale/timezone** if you want it right from first boot.
5. Write the image, then move the SD card to the Pi.

## 3.2 — First boot

1. Insert the SD card into the Pi.
2. Connect the Cat 6 Ethernet cable from the Pi directly into one of the
   ASUS router's LAN ports.
3. Connect power. Give it a minute or two for the first boot (it resizes
   the filesystem to fill the SD card on this boot, which takes a little
   longer than later boots).

## 3.3 — Find it on the network

The Pi just went through exactly the DHCP handshake described in
[`docs/04-the-endpoint-nic-dhcp-gateway.md`](../docs/04-the-endpoint-nic-dhcp-gateway.md)
and demonstrated in [`dhcp-demo/`](../dhcp-demo/) — except this time it's
your real router handing out a real lease, not a container. Find the
address it got, one of:

- Open the ASUS router's admin page → **Network Map** / connected
  devices list. It should show up by the hostname you set
  (e.g. `networklab`).
- Try `ping networklab.local` from your computer (replace with whatever
  hostname you chose) — Raspberry Pi OS advertises itself this way by
  default on most home networks.

## 3.4 — Connect over SSH

```bash
ssh <your-username>@networklab.local
# or, if that name doesn't resolve:
ssh <your-username>@<the-ip-you-found>
```

Accept the host key prompt the first time, then log in with the password
you set in Raspberry Pi Imager.

## 3.5 — Give the Pi a fixed address

Right now the Pi's IP could change if its DHCP lease expires and it gets
renewed with a different address later — annoying if you're used to
SSHing into a specific IP. Fix this the same way real networks do it: a
**DHCP reservation**, not a manually hardcoded static IP on the Pi itself
(which would fight with the router's own DHCP server).

In the ASUS router's admin UI, look for something like *LAN* →
*DHCP Server* → *Manual Assignment*, and bind the Pi's MAC address
(visible on the router's connected-devices list, or via `ip addr` on the
Pi) to a fixed address of your choosing. This is exactly the "the DHCP
server always hands this specific device the same lease" pattern —
still DHCP, just with a pinned outcome for one known device.

## 3.6 — Basic first-boot housekeeping

```bash
sudo apt update && sudo apt full-upgrade -y
sudo reboot
```

Wait a minute, then SSH back in. You're ready to install Docker.

## Checkpoint before moving on

- [ ] Raspberry Pi OS Lite (64-bit) flashed with SSH pre-enabled
- [ ] Pi is on Ethernet, connected to the ASUS router
- [ ] You can SSH into it by hostname or IP
- [ ] It has a DHCP reservation so its address won't change later
- [ ] System packages are updated

Continue to [Step 4 — Installing Docker and running the lab for real](04-run-the-lab-on-the-pi.md).
