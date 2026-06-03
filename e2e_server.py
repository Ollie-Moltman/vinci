#!/usr/bin/env python3
"""
Vinci E2E Test Server — serves Flutter web app + proxies API with CORS.
Runs on port 8080, proxies /api/* to localhost:8765 with proper CORS headers.
"""
import http.server
import json
import os
import socketserver
import urllib.request
import urllib.parse
from http.server import SimpleHTTPRequestHandler

PORT = 8080
API_BASE = "http://localhost:8765"
WEB_ROOT = "/data/.openclaw/workspace/vinci/build/web"

class VinciProxyHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEB_ROOT, **kwargs)

    def add_cors_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def proxy_api(self, path, method="GET"):
        """Proxy API request to backend with CORS headers."""
        # Strip leading slash to avoid double-slash in URL
        clean_path = path.lstrip('/')
        # Reconstruct full URL with query string
        url = f"{API_BASE}/{clean_path}"
        if self.path.find('?') >= 0:
            qs = self.path.split('?', 1)[1]
            url = f"{API_BASE}/{clean_path}?{qs}"
        try:
            if method == "GET":
                req = urllib.request.Request(url)
            else:
                body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
                req = urllib.request.Request(url, data=body, method=method)
                req.add_header("Content-Type", "application/json")

            with urllib.request.urlopen(req, timeout=30) as resp:
                data = resp.read()
                self.send_response(resp.status)
                self.send_header("Content-Type", "application/json")
                self.add_cors_headers()
                self.send_header("Content-Length", len(data))
                self.end_headers()
                self.wfile.write(data)
        except Exception as e:
            import traceback
            traceback.print_exc()
            self.send_response(502)
            self.send_header("Content-Type", "application/json")
            self.add_cors_headers()
            self.end_headers()
            error = json.dumps({"error": str(e)}).encode()
            self.wfile.write(error)

    def do_OPTIONS(self):
        self.send_response(200)
        self.add_cors_headers()
        self.end_headers()

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path.startswith("/api/") or parsed.path in ("/health", "/tokenize", "/embed_text", "/search", "/index", "/indexed"):
            # Strip /api/ prefix for backend (use slicing, not lstrip which strips all matching chars)
            api_path = parsed.path[5:] if parsed.path.startswith('/api/') else parsed.path
            self.proxy_api(api_path)
        elif parsed.path == "/":
            self.path = "/index.html"
            super().do_GET()
        else:
            super().do_GET()

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path.startswith("/api/") or parsed.path in ("/index", "/index_bytes"):
            api_path = parsed.path.lstrip("/api/")
            self.proxy_api(api_path, "POST")
        else:
            self.send_response(404)
            self.end_headers()

class ReuseAddrTCPServer(socketserver.TCPServer):
    allow_reuse_address = True

if __name__ == "__main__":
    os.chdir(WEB_ROOT)
    with ReuseAddrTCPServer(("", PORT), VinciProxyHandler) as srv:
        print(f"✅ Vinci E2E Server ready on http://localhost:{PORT}")
        print(f"   Web app: http://localhost:{PORT}/")
        print(f"   API proxy: http://localhost:{PORT}/api/* -> localhost:8765/*")
        srv.serve_forever()