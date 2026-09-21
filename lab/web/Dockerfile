# The web server: plain Python 3 standard library, nothing else — see
# docs/10-web-server.md for why. web1 and web2 share this exact image;
# which one a running container "is" comes entirely from the SERVER_NAME
# environment variable set in docker-compose.yml.
FROM python:3.12-alpine

COPY server.py /app/server.py
WORKDIR /app

CMD ["python3", "server.py"]
