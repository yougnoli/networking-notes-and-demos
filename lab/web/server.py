#!/usr/bin/env python3
"""
The web server. See docs/10-web-server.md.

Deliberately built with nothing but the Python standard library's
http.server module — no Flask, no Django, no dependencies to install —
so the whole "application" fits on one screen and there's nothing here
you can't read in full.

Three routes:

  GET /         -> a small HTML page announcing which replica answered
                   (this is what makes the load-balancer demo in
                   docs/07-load-balancer.md visible)
  GET /headers  -> every HTTP header this server actually received, as
                   JSON (this is what makes the reverse proxy's header
                   injection in docs/09-reverse-proxy-and-tls.md visible)
  GET /health   -> a bare 200 OK, for the load balancer's health checks
"""

import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

# Which replica this instance is ("web-1" or "web-2") — set per-container
# in docker-compose.yml. Both web1 and web2 run this exact same file.
SERVER_NAME = os.environ.get("SERVER_NAME", "web-unknown")


class Handler(BaseHTTPRequestHandler):
    # Quiet down the default per-request stderr logging; we don't need it
    # for this lab and it clutters `docker compose logs`.
    def log_message(self, fmt, *args):
        pass

    def do_GET(self):
        if self.path.startswith("/headers"):
            self._handle_headers()
        elif self.path.startswith("/health"):
            self._handle_health()
        else:
            self._handle_index()

    def _handle_index(self):
        body = f"""<!doctype html>
<html>
  <head><title>{SERVER_NAME}</title></head>
  <body style="font-family: sans-serif; padding: 2rem;">
    <h1>Served by {SERVER_NAME}</h1>
    <p>This response came from the actual web server at the end of the
       chain in docs/02-big-picture-architecture.md.</p>
    <p>Run this a few times through the load balancer and watch it
       alternate with the other replica — see docs/07-load-balancer.md.</p>
    <p><a href="/headers">See every header I actually received</a></p>
  </body>
</html>
"""
        self._send(200, "text/html", body.encode())

    def _handle_headers(self):
        # self.headers behaves like a dict of everything the client (in
        # this case, the reverse proxy) sent. This is the single most
        # useful debugging view in the whole lab: it shows you exactly
        # what survived the trip through every hop before this one.
        headers = {k: v for k, v in self.headers.items()}
        payload = {
            "served_by": SERVER_NAME,
            "path": self.path,
            "headers_received": headers,
        }
        body = json.dumps(payload, indent=2)
        self._send(200, "application/json", body.encode())

    def _handle_health(self):
        self._send(200, "text/plain", b"OK")

    def _send(self, status, content_type, body_bytes):
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body_bytes)))
        self.end_headers()
        self.wfile.write(body_bytes)


if __name__ == "__main__":
    port = 8080
    print(f"[{SERVER_NAME}] listening on :{port}")
    ThreadingHTTPServer(("0.0.0.0", port), Handler).serve_forever()
