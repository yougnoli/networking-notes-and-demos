# Step 4 — Installing Docker and running the lab for real

The Raspberry Pi is now a normal, reachable Linux box on your hardened
home network. This step turns it into the Docker host for
[`lab/`](../lab/) and [`dhcp-demo/`](../dhcp-demo/) — the exact same
containers described throughout `docs/`, just running on real hardware in
your house with a real internet connection behind them, instead of the
sandbox this repo was originally authored in.

All commands below run **over SSH, on the Pi** — not on your laptop.

## 4.1 — Install Docker

Raspberry Pi OS is Debian-based, so Docker's official convenience script
works directly:

```bash
curl -fsSL https://get.docker.com | sh
```

Let your own user run Docker without `sudo` every time:

```bash
sudo usermod -aG docker $USER
```

Log out and back in (or just `exit` and SSH in again) for that group
change to take effect, then confirm both pieces are present:

```bash
docker --version
docker compose version
```

## 4.2 — Install git and clone the repo

```bash
sudo apt install -y git
git clone https://github.com/yougnoli/networking-notes-and-demos.git
cd networking-notes-and-demos
```

## 4.3 — Run the lab

```bash
cd lab
./scripts/generate-certs.sh
docker compose up --build -d
./scripts/fix-routes.sh
```

If `generate-certs.sh` complains that `openssl` is missing:
`sudo apt install -y openssl` first.

Then run the guided walkthrough:

```bash
./scripts/demo.sh
```

## 4.4 — Reaching it from your other devices

Because this is now running on a separate machine (the Pi) rather than
your own laptop, `localhost` won't reach it from anywhere except the Pi
itself. From your laptop or phone (on the same home network), use the
Pi's address instead:

```
https://<pi-ip-or-hostname>:8443/
```

Everything else in [`lab/README.md`](../lab/README.md) works exactly as
written — `docker compose exec client ...`, the WAF-blocking examples,
the load-balancer round robin — just run from an SSH session on the Pi.

## A genuine caveat: ARM architecture

This repo's configs were written and validated in an x86-64 sandbox with
no internet access to actually pull images (explained in the main
[`README.md`](../README.md)). Every image `lab/` uses (`alpine`,
`python`, `nginx`, `haproxy`, `ghcr.io/wg-easy/wg-easy`) publishes
multi-architecture manifests that include `arm64`, so `docker compose up
--build` should pull the right variant for the Pi automatically without
you doing anything differently — but this specific combination, on this
specific hardware, has not actually been run end to end by the time this
doc was written. If one image fails to pull or start:

```bash
docker compose logs <service-name>
```

will usually say plainly whether it's an architecture mismatch. Check
that image's tags on Docker Hub or GHCR for an explicit `arm64` tag if
the default one doesn't work.

## 4.5 (optional) — Run the DHCP demo too

```bash
cd ../dhcp-demo
docker compose up --build
```

Same as [`dhcp-demo/README.md`](../dhcp-demo/README.md) describes — now
watching a real DHCP handshake happen on hardware that's also, separately,
holding a real lease from your own ASUS router on its main interface.

## 4.6 — Shutting it down / bringing it back later

```bash
cd ~/networking-notes-and-demos/lab
docker compose down       # stop everything
docker compose up -d      # bring it back later, no rebuild needed
```

The Pi can happily run this stack continuously if you want to leave it up
as a standing reference to poke at — none of it needs the internet-facing
side of your home network to do anything risky, since it's all built on
its own isolated Docker networks (`internet` and `dmz` inside the
containers, not your home LAN).

## Checkpoint

- [ ] Docker + Compose installed on the Pi, working without `sudo`
- [ ] Repo cloned
- [ ] `lab/` stack up and `fix-routes.sh` run
- [ ] `demo.sh` walkthrough completes
- [ ] You can reach `https://<pi-ip>:8443/` from another device on your
      home network

That's the whole path from "boxes on the floor" to "the entire repo
running for real behind your own firewall and VPN." From here, everything
in `docs/` and `lab/README.md` applies directly — you're just running it
on hardware you own instead of a sandbox.
