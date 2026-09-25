from http.server import BaseHTTPRequestHandler, HTTPServer


REQUESTS = 0


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        global REQUESTS
        REQUESTS += 1

        if self.path == "/healthz":
            body = b"ok\n"
        elif self.path == "/metrics":
            body = (
                "# HELP hello_requests_total Total HTTP requests\n"
                "# TYPE hello_requests_total counter\n"
                f"hello_requests_total {REQUESTS}\n"
            ).encode()
        else:
            body = b"Hello from hello teste de novo!\n"

        self.send_response(200)
        self.send_header("Content-Type", "text/plain; version=0.0.4")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


HTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
