# Full request walkthrough

Everything from docs 02–10, traced through one concrete request, with the
actual addresses and ports this lab uses. Two versions: the normal public
path, and the VPN path to the internal-only resource.

## Path A: a normal visitor hitting the public site

**Starting point — the endpoint.** Your laptop (played by the `client`
container, `203.0.113.50`) wants `https://203.0.113.10:8443/`. Before it
can send anything, it already did the doc-04 setup: it has an IP, a
subnet mask, and a default gateway, all either statically configured or
handed out by DHCP when it joined the `internet` network. `203.0.113.10`
is outside its own subnet only in the sense that it's a different host on
the *same* subnet in this simplified lab (in real life it'd typically be
many hops away) — either way, if it weren't directly reachable, the
client would hand the packet to its gateway and let routing take over.

1. **DNS/addressing (skipped in the lab)** — in real life, the client
   would resolve a hostname to `203.0.113.10` first. The lab skips this
   and hits the IP directly, since DNS is a separate topic from this
   diagram.

2. **TLS handshake begins** — the client opens a TCP connection to
   `203.0.113.10:8443` and starts a TLS handshake (`ClientHello`, etc.).
   Note: this handshake's *bytes* pass through the firewall and the load
   balancer completely untouched — neither of them decrypts anything.

3. **Firewall (doc 05)** — sees a new inbound TCP SYN to
   `203.0.113.10:8443`. This matches an explicit DNAT rule, so it
   rewrites the destination to `10.10.10.10:443` (the load balancer,
   inside the DMZ) and forwards it. If this port weren't explicitly
   forwarded, the packet would simply be dropped here — nothing else
   downstream would ever see it.

4. **Load balancer (doc 07)** — HAProxy, in TCP/L4 mode, accepts the
   connection on `10.10.10.10:443` and — without looking inside it at
   all — picks the next backend in round-robin order: say, `waf1`
   (`10.10.10.21:443`). It relays raw bytes in both directions from here
   on; it never sees a URL, a header, or plaintext of any kind.

5. **WAF (doc 08)** — `waf1` actually holds the TLS certificate, so it
   completes the TLS handshake with the client and decrypts the request.
   Now, for the first time, something in the chain can actually see
   `GET / HTTP/1.1` and the headers. It runs its rule checks (SQLi, XSS,
   path traversal, known bad user agents, oversized bodies). This
   request is clean, so it's forwarded — as **plain HTTP** now, TLS's job
   is done — to the reverse proxy at `reverse-proxy-1:8080`.

6. **Reverse proxy (doc 09)** — receives the plain HTTP request. It adds
   `X-Forwarded-For: 203.0.113.50` (the *original* client IP, which it
   knows because HAProxy's TCP passthrough preserved the source address
   all the way through, and the WAF's TLS termination point saw it
   directly), `X-Real-IP: 203.0.113.50`, and
   `X-Forwarded-Proto: https` (so the backend knows the original
   connection was encrypted, even though this hop isn't). Forwards to
   `web1:8080`.

7. **Web server (doc 10)** — `web1` generates the actual response: a
   small HTML page saying "Served by web-1", built entirely from
   information already available to it (including the headers set two
   hops back).

8. **The response** retraces the same path in reverse: web server →
   reverse proxy → WAF (which re-encrypts it as part of the same TLS
   session established in step 5) → load balancer (still just relaying
   bytes) → firewall (which un-DNATs the source, so it looks like it came
   from `203.0.113.10:8443`, not `10.10.10.21`) → client.

The client never sees any address except `203.0.113.10` from start to
finish — everything from the load balancer inward is invisible to it by
design.

## Path B: an internal-only resource, over the VPN

Same client, but now it wants HAProxy's stats dashboard —
`http://10.10.10.10:8404/` — which has **no** firewall DNAT rule at all.

**Without connecting the VPN:** step 3 above never finds a matching DNAT
rule for this destination/port combination, and the connection attempt
is simply dropped by the firewall. No load balancer, no WAF, nothing else
downstream is even reached.

**With the VPN connected (doc 06):**

1. The client first establishes a WireGuard tunnel to
   `203.0.113.10:51820` — this UDP port *is* explicitly DNAT'd by the
   firewall, straight to the VPN server (`10.10.10.5:51820`).
2. The VPN server authenticates the client and hands it an address from
   its own pool, e.g. `10.13.13.2` — a brand-new virtual NIC appears on
   the client (doc 04's multihoming, happening live).
3. The client's routing table now sends traffic bound for `10.10.10.0/24`
   out through that new tunnel interface instead of its normal one.
4. The request to `10.10.10.10:8404` now leaves the client already
   inside the tunnel, arrives decrypted at the VPN server, and gets
   routed directly onto the `dmz` network — **it never passes through
   the public-facing firewall path or any DNAT rule at all**, because as
   far as the DMZ is concerned, this traffic originated internally.
5. HAProxy answers directly with its stats page.

Same client, same physical laptop, two completely different levels of
access — the only thing that changed is whether the VPN tunnel was up.
That's the entire value proposition of a VPN, made concrete.

## Try both paths yourself

See [`lab/README.md`](../lab/README.md) for the exact commands — this doc
is the map, that one is the walk.
