# Plays the role of "an external internet user" for the exercises in
# lab/README.md and docs/11-full-request-walkthrough.md. Just a small
# toolbox of the commands you'd actually reach for.
FROM alpine:3.20

RUN apk add --no-cache \
    curl \
    bind-tools \
    iproute2 \
    iputils \
    busybox-extras \
    tcpdump \
    python3

WORKDIR /root
