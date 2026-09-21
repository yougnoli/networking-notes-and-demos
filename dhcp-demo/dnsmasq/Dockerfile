FROM alpine:3.20

RUN apk add --no-cache dnsmasq

COPY dnsmasq.conf /etc/dnsmasq.conf

# -d = stay in the foreground and log to stderr, so `docker compose logs`
# shows every DHCP transaction as it happens.
CMD ["dnsmasq", "-C", "/etc/dnsmasq.conf", "-d"]
