"""
Proxy local para o Axet Plugin (Codex CLI).

Intercepta chamadas em http://localhost:8080 e adiciona os headers
obrigatorios da API axet.nttdata.com antes de encaminhar.

Uso:
    py C:\\Robo\\axet_proxy.py

Config.toml deve ter:
    base_url = "http://localhost:8080"
    wire_api  = "responses"
"""

import http.server
import urllib.request
import urllib.error
import json
import ssl

# â”€â”€â”€ Configuracao do endpoint real â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
TARGET_BASE = "https://axet.nttdata.com/api/llm-enabler/v2/openai/ntt/f8de6928-9f95-43f1-a1bd-410971ec1221/v1"
ASSET_ID    = "90a0d375-5456-468c-9f8c-1aebe084e32d"
PROJECT_ID  = "f8de6928-9f95-43f1-a1bd-410971ec1221"
USER_ID     = "0db9142f-5059-4bf5-84ec-2216ab1ad5d5"
TOKENS_FILE = r"C:\Users\apaffrat\OneDrive - NTT DATA EMEAL\Ondrive\local-ai-gateway\gateway\tokens.json"
PORT        = 8080

# â”€â”€â”€ SSL sem verificacao (rede corporativa) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
SSL_CTX = ssl.create_default_context()
SSL_CTX.check_hostname = False
SSL_CTX.verify_mode = ssl.CERT_NONE


def get_access_token():
    """Le o access_token atual de C:\\Robo\\tokens.json."""
    try:
        with open(TOKENS_FILE, "r", encoding="utf-8") as f:
            return json.load(f).get("access_token", "")
    except Exception:
        return ""


def add_axet_headers(req, auth_header):
    req.add_header("Authorization", auth_header)
    req.add_header("axet-asset-id", ASSET_ID)
    req.add_header("axet-project-id", PROJECT_ID)
    req.add_header("axet-user-id", USER_ID)


class AxetProxyHandler(http.server.BaseHTTPRequestHandler):

    def log_message(self, fmt, *args):
        status = args[1] if len(args) > 1 else "?"
        print(f"[axet-proxy] {self.command} {self.path} -> {status}")

    def _get_auth(self):
        header = self.headers.get("Authorization", "")
        if header:
            return header
        token = get_access_token()
        return f"Bearer {token}" if token else ""

    def _forward_response(self, resp):
        self.send_response(resp.status)
        for key, value in resp.headers.items():
            if key.lower() in ("transfer-encoding", "connection", "content-length"):
                continue
            self.send_header(key, value)
        self.end_headers()
        while True:
            chunk = resp.read(8192)
            if not chunk:
                break
            self.wfile.write(chunk)
            self.wfile.flush()

    def do_GET(self):
        target_url = TARGET_BASE + self.path
        auth = self._get_auth()
        req = urllib.request.Request(target_url, method="GET")
        add_axet_headers(req, auth)
        try:
            with urllib.request.urlopen(req, timeout=60, context=SSL_CTX) as resp:
                self._forward_response(resp)
        except urllib.error.HTTPError as e:
            body = e.read()
            self.send_response(e.code)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        except Exception as e:
            msg = str(e).encode()
            self.send_response(500)
            self.end_headers()
            self.wfile.write(msg)

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length)
        target_url = TARGET_BASE + self.path
        auth = self._get_auth()
        content_type = self.headers.get("Content-Type", "application/json")
        req = urllib.request.Request(target_url, data=body, method="POST")
        req.add_header("Content-Type", content_type)
        add_axet_headers(req, auth)
        try:
            with urllib.request.urlopen(req, timeout=300, context=SSL_CTX) as resp:
                self._forward_response(resp)
        except urllib.error.HTTPError as e:
            body = e.read()
            self.send_response(e.code)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        except Exception as e:
            msg = str(e).encode()
            self.send_response(500)
            self.end_headers()
            self.wfile.write(msg)


if __name__ == "__main__":
    server = http.server.HTTPServer(("127.0.0.1", PORT), AxetProxyHandler)
    print(f"Axet proxy rodando em http://localhost:{PORT}")
    print(f"Encaminhando para: {TARGET_BASE}")
    print("Pressione Ctrl+C para parar.\n")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nProxy encerrado.")
