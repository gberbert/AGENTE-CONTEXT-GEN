"""
Verifica modelos do projeto f8de6928 e testa o endpoint com gpt-5.3-codex.
"""
import json, ssl, socket, urllib.request, urllib.error, time

TOKENS_FILE = r"C:\Users\apaffrat\OneDrive - NTT DATA EMEAL\Ondrive\local-ai-gateway\gateway\tokens.json"
GAIA_PROJECT = "f8de6928-9f95-43f1-a1bd-410971ec1221"
USER_ID = "403c1b33-5fe5-4745-bf94-c106c0f84916"
ASSET_GAIA = "90a0d375-5456-468c-9f8c-1aebe084e32d"
HOST = "axet.nttdata.com"
ENABLER_MANAGER = "https://axet.nttdata.com/api/enabler-manager"

token = json.load(open(TOKENS_FILE))["access_token"]

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE


def get(url):
    req = urllib.request.Request(url)
    req.add_header("Authorization", f"Bearer {token}")
    req.add_header("axet-plugin-version", "2.8.0")
    try:
        with urllib.request.urlopen(req, timeout=10, context=ctx) as r:
            return json.loads(r.read())
    except urllib.error.HTTPError as e:
        return {"_error": e.code, "_body": e.read().decode()[:200]}
    except Exception as e:
        return {"_error": str(e)}


def post(url, body):
    data = json.dumps(body).encode()
    req = urllib.request.Request(url, data=data, method="POST")
    req.add_header("Authorization", f"Bearer {token}")
    req.add_header("Content-Type", "application/json")
    req.add_header("axet-plugin-version", "2.8.0")
    try:
        with urllib.request.urlopen(req, timeout=10, context=ctx) as r:
            return json.loads(r.read())
    except urllib.error.HTTPError as e:
        return {"_error": e.code, "_body": e.read().decode()[:200]}
    except Exception as e:
        return {"_error": str(e)}


def test_model(model_id):
    """Testa POST no endpoint v2/openai com projeto f8de6928."""
    body = json.dumps({
        "model": model_id,
        "input": "hi",
        "max_output_tokens": 16,
        "store": False,
        "stream": False,
    }).encode()

    path = f"/api/llm-enabler/v2/openai/ntt/{GAIA_PROJECT}/v1/responses"
    raw_req = (
        f"POST {path} HTTP/1.1\r\n"
        f"Host: {HOST}\r\n"
        f"Content-Type: application/json\r\n"
        f"Content-Length: {len(body)}\r\n"
        f"Authorization: Bearer {token}\r\n"
        f"axet-asset-id: {ASSET_GAIA}\r\n"
        f"axet-project-id: {GAIA_PROJECT}\r\n"
        f"axet-user-id: {USER_ID}\r\n"
        f"Connection: close\r\n\r\n"
    ).encode() + body

    try:
        raw = socket.create_connection((HOST, 443), timeout=8)
        sock = ctx.wrap_socket(raw, server_hostname=HOST)
        sock.settimeout(8)
        sock.sendall(raw_req)
        # LÃª status line e headers completos
        resp_bytes = b""
        while b"\r\n\r\n" not in resp_bytes:
            chunk = sock.recv(4096)
            if not chunk:
                break
            resp_bytes += chunk
        # Tenta ler o body tambÃ©m
        body_bytes = b""
        try:
            while True:
                chunk = sock.recv(4096)
                if not chunk:
                    break
                body_bytes += chunk
        except Exception:
            pass
        sock.close()

        status_line = resp_bytes.split(b"\r\n")[0].decode()
        status_code = int(status_line.split()[1])
        body_str = body_bytes.decode("utf-8", errors="replace")[:300]
        return status_code, body_str
    except Exception as e:
        return 0, str(e)


print(f"=== Modelos do projeto f8de6928 ===")
proj_models = get(f"{ENABLER_MANAGER}/llm-models/projects/{GAIA_PROJECT}/models")
if "_error" in proj_models:
    print(f"  ERRO: {proj_models}")
else:
    data = proj_models.get("data", proj_models if isinstance(proj_models, list) else [])
    print(f"  {len(data)} modelos atribuidos ao projeto:")
    for m in data:
        print(f"    {m.get('name','')} | {m.get('displayName','')} | public={m.get('isPublic','')} | clientSlug={m.get('clientSlug','')}")

print()
print("=== Teste direto dos modelos no endpoint f8de6928 ===")
models_to_test = [
    "gpt-5.3-codex",
    "gpt-4o",
    "gpt-4.1",
    "gpt-5.2",
    "gpt-4o-mini",
    "gpt-4.1-mini",
    "gpt-5-mini",
]
for m in models_to_test:
    code, body_resp = test_model(m)
    status = "OK" if code < 300 else f"HTTP {code}"
    print(f"  {m:<25} -> {status}  {body_resp[:100] if code >= 300 else ''}")
    time.sleep(0.1)
