# A networking glossary for data people

Short, blunt translations. Each of these gets a full doc later — this is
just so nothing in the early reading stops you cold.

| Term | Data/software analogy |
|---|---|
| **IP address** | A row's primary key on the network. Uniquely identifies a machine (or interface) so packets know where to go. |
| **Subnet** | A partition key. Machines in the same subnet can talk directly; machines in different subnets need a router in between, the same way cross-partition joins need a shuffle. |
| **Subnet mask / CIDR (`/24`)** | The partitioning scheme itself — how many bits of the IP are "which partition" vs. "which row in the partition." |
| **Default gateway** | The address a machine sends a packet to when it doesn't know how to reach the destination itself — like a catch-all route in an API gateway, or `default:` in a `switch` statement. |
| **DHCP** | An auto-increment service for IP addresses, with a lease/TTL. Your laptop asks "give me an ID," a DHCP server hands one out from a pool, and it expires unless renewed. |
| **NIC (Network Interface Card)** | A physical or virtual "port" a machine uses to join a network — analogous to a network interface in a VM, or one ENI on an EC2 instance. **Multihomed** = more than one NIC = more than one ENI attached to more than one VPC. |
| **NAT (Network Address Translation)** | Like column-level masking, but for addresses: many internal IPs get rewritten to look like one external IP as they leave, and the firewall remembers the mapping to undo it on the way back — the same idea as a connection pool multiplexing many app connections onto a handful of DB connections. |
| **Firewall** | An allow-list / access-control layer, evaluated per-packet instead of per-query. Default posture is usually "deny everything, explicitly allow what's needed" — same philosophy as least-privilege IAM. |
| **VPN (Virtual Private Network)** | An encrypted tunnel that makes a remote device act as if it's plugged into a private network — like an SSH tunnel or a bastion host, but for *all* traffic, not just one connection. |
| **Load balancer** | Exactly what it sounds like if you've used one in front of a service (an ALB/NLB, an nginx upstream block, a Kubernetes Service). Same concept, same purpose: don't let one instance take all the traffic. |
| **WAF (Web Application Firewall)** | Input validation as a network appliance. It looks at the actual HTTP request body/headers/URL — not just IP:port like a regular firewall — and blocks requests that look like SQL injection, XSS, path traversal, etc. |
| **Reverse proxy** | A layer that sits in front of your "real" servers and forwards requests to them on the client's behalf, while doing bookkeeping (adding headers, rewriting URLs, sometimes caching) — think of an API gateway that fronts several backend services. |
| **TLS termination** | The point in the chain where "HTTPS" (encrypted) traffic gets decrypted back into plain HTTP. Whatever sits *after* that point sees plaintext; whatever sits *before* it only sees encrypted bytes. |
| **Port** | A sub-address on a machine, like a table name within a database — the IP gets you to the machine, the port gets you to the right process on it. |
| **Packet** | One unit of data on the wire, roughly like one row/message on a queue — has a header (metadata: source, destination, protocol) and a payload. |

Keep this page open. Everything below builds on it.
