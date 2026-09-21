# The firewall/router: a plain Alpine box with iptables and iproute2.
# Nothing fancy — the interesting part is entirely in firewall-rules.sh.
FROM alpine:3.20

RUN apk add --no-cache iptables iproute2

COPY firewall-rules.sh /firewall-rules.sh
RUN chmod +x /firewall-rules.sh

ENTRYPOINT ["/firewall-rules.sh"]
