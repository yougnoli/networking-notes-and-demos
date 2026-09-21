# Official HAProxy image, plus iproute2 so scripts/fix-routes.sh (run
# from the host via `docker compose exec`) can fix up this container's
# routing table. See docs/05-firewall-and-nat.md for why that's needed.
FROM haproxy:2.9-alpine

USER root
RUN apk add --no-cache iproute2
