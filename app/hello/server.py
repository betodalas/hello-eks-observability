from collections import defaultdict
from http.server import BaseHTTPRequestHandler, HTTPServer

# Contagem de requisições por status HTTP, usada pelo AnalysisTemplate do
# Argo Rollouts pra decidir se promove ou aborta um canary automaticamente.
REQUESTS_BY_CODE = defaultdict(int)


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/healthz":
            body = b"ok\n"
        elif self.path == "/metrics":
            lines = [
                "# HELP hello_requests_total Total HTTP requests by status code",
                "# TYPE hello_requests_total counter",
            ]
            for code, count in sorted(REQUESTS_BY_CODE.items()):
                lines.append(f'hello_requests_total{{code="{code}"}} {count}')
            body = ("\n".join(lines) + "\n").encode()
        else:
            REQUESTS_BY_CODE[200] += 1
            body = b"Hello from hello teste de novo!\n"

        self.send_response(200)
        self.send_header("Content-Type", "text/plain; version=0.0.4")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


HTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
# trigger canary 1790351173
