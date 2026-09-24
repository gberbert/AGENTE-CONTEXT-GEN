# -*- coding: utf-8 -*-
"""Versao estavel: compara ASSET GAIA vs PLUGIN e depois testa mensagem real."""
import json
import ssl
import urllib.request
import urllib.error

TOKENS_FILE = "gateway/tokens.json"
USER_ID = "0db9142f-5059-4bf5-84ec-2216ab1ad5d5"
ASSET_GAIA = "90a0d375-5456-468c-9f8c-1aebe084e32d"
ASSET_PLUGIN = "f4f99f6a-6b56-4c9b-9caf-055304bb22e1"
PLUGIN_VER = "2.8.0"

PROJECTS = [
    "f8de6928-9f95-43f1-a1bd-410971ec1221",
    "22276aff-f601-43c6-9f51-769f9ee2fbd2",
    "49784ee0-9e9e-4063-89ef-dcd9782a9d4e",
    "5d02b3d7-d778-4a5f-9889-2185ebcc4b8d",
    "f8de6928-9f95-43f1-a1bd-410971ec1221",
]
MODELS = ["gpt-5.3-codex", "gpt-5.2", "gpt-5-mini", "gpt-4o-mini", "gpt-4.1-mini"]


def tls_context():
    c = ssl.create_default_context()
    c.check_hostname = False
    c.verify_mode = ssl.CERT_NONE
    return c


def tag(code):
    if code in (200, 400):
        return "[OK]"
    if code in (401, 403, 404, -1):
        return "[ERRO]"
    return "[AVISO]"


def post_json(url, token, body, headers=None):
    req = urllib.request.Request(url, data=json.dumps(body).encode("utf-8"), method="POST")
    req.add_header("Authorization", f"Bearer {token}")
    req.add_header("Content-Type", "application/json")
    if headers:
        for k, v in headers.items():
            req.add_header(k, v)
    try:
        with urllib.request.urlopen(req, timeout=25, context=tls_context()) as resp:
            return resp.status, resp.read().decode("utf-8", errors="replace")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", errors="replace")
    except Exception as e:
        return -1, str(e)


def list_projects(token):
    status, raw = post_json(
        "https://axet.nttdata.com/api/core/v1/projects/search",
        token,
        {
            "search": {"ids": PROJECTS, "active": True},
            "pagination": {"size": 20},
            "orders": [{"name": "displayName", "direction": "asc"}],
        },
        {"axet-plugin-version": PLUGIN_VER},
    )
    if status != 200:
        return status, raw, []
    return status, raw, json.loads(raw).get("data", [])


def test_responses(project_id, model, token, asset):
    url = f"https://axet.nttdata.com/api/llm-enabler/v2/openai/ntt/{project_id}/v1/responses"
    body = {
        "model": model,
        "input": "Responda apenas: OK_AXET",
        "max_output_tokens": 32,
        "store": False,
        "stream": False,
    }
    headers = {
        "axet-asset-id": asset,
        "axet-project-id": project_id,
        "axet-user-id": USER_ID,
    }
    return post_json(url, token, body, headers)


def short(txt):
    return txt.replace("\n", " ")[:180]


def main():
    token = json.load(open(TOKENS_FILE, encoding="utf-8"))["access_token"]
    print(f"Token: {token[:35]}...")

    status, raw, projects = list_projects(token)
    print(f"projects/search => {tag(status)} HTTP {status}")
    if status != 200:
        print(short(raw))
        return

    print(f"\n{'ID':<38} {'DisplayName':<36} {'billingClientName'}")
    print("-" * 104)
    for p in projects:
        print(f"{p.get('id',''):<38} {p.get('displayName',''):<36} {p.get('billingClientName','')}")

    print("\n=== BLOCO 1: teste estavel (GAIA vs PLUGIN) ===")
    for p in projects:
        pid = p.get("id", "")
        pname = p.get("displayName", "")
        print(f"\nProjeto: {pname} ({pid})")
        for model in MODELS:
            s1, b1 = test_responses(pid, model, token, ASSET_GAIA)
            s2, b2 = test_responses(pid, model, token, ASSET_PLUGIN)
            print(f"  {model:<14} | {tag(s1)} GAIA HTTP {s1:<3} | {tag(s2)} PLUGIN HTTP {s2:<3}")
            if s1 not in (200, 400):
                print(f"    GAIA   => {short(b1)}")
            if s2 not in (200, 400):
                print(f"    PLUGIN => {short(b2)}")

    print("\n=== BLOCO 2: teste de mensagem (somente GAIA) ===")
    test_project = "f8de6928-9f95-43f1-a1bd-410971ec1221"
    test_model = "gpt-4o-mini"
    status_msg, body_msg = test_responses(test_project, test_model, token, ASSET_GAIA)
    print(f"Mensagem projeto BSA/modelo {test_model}: {tag(status_msg)} HTTP {status_msg}")
    print(f"Resposta curta: {short(body_msg)}")


if __name__ == "__main__":
    main()
