# The reverse proxy: stock nginx plus one of the two config files below.
# Same pattern as lab/waf/Dockerfile — see that file's comment.
FROM nginx:1.27-alpine

ARG NGINX_CONF=nginx-1.conf
COPY ${NGINX_CONF} /etc/nginx/nginx.conf
