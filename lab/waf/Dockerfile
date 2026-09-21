# The WAF: stock nginx plus one of the two config files below, selected
# at build time. waf1 and waf2 use the exact same image — the only
# difference between them is which reverse proxy they forward to, which
# is baked into the config rather than templated at runtime, so the
# whole config is always something you can read as plain, static text.
FROM nginx:1.27-alpine

ARG NGINX_CONF=nginx-1.conf
COPY ${NGINX_CONF} /etc/nginx/nginx.conf
