#!/usr/bin/env bash
# ==============================================================================
# iniciar_mac.command
# Lançador de duplo clique para macOS (Finder / Mesa)
# ==============================================================================
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

echo "==============================================================================="
echo "  🚀 NTT DATA — AXET-AGENT-CONTEXT-GEN (macOS Launcher)"
echo "==============================================================================="
echo ""

# 1. Verificar e inicializar Local AI Gateway (:8766)
if curl -s -I http://127.0.0.1:8766/auth/status >/dev/null 2>&1 || curl -s -I http://127.0.0.1:8766/ >/dev/null 2>&1; then
    echo "[OK] Local AI Gateway corporativo já está ativo na porta 8766"
else
    echo "[INFO] Iniciando Local AI Gateway na porta 8766..."
    nohup python3 gateway/local_ai_gateway.py > /tmp/axet-local-gateway.log 2>&1 &
    sleep 1
fi

# 2. Verificar se o servidor Cockpit já está rodando
if curl -s -I http://localhost:4545/ >/dev/null 2>&1; then
    echo "[OK] Cockpit já está rodando em http://localhost:4545/"
    open "http://localhost:4545/"
    exit 0
fi

# 3. Ativar virtualenv se existir
if [ -f ".venv/bin/activate" ]; then
    source .venv/bin/activate
fi

# 3. Subir o servidor Node.js em background
echo "[INFO] Iniciando servidor do Cockpit na porta 4545..."
nohup node dashboard/server.js 4545 > /tmp/axet-cockpit-server.log 2>&1 &
SERVER_PID=$!

# 4. Aguardar o servidor responder
ATTEMPTS=0
while [ $ATTEMPTS -lt 10 ]; do
    if curl -s -I http://localhost:4545/ >/dev/null 2>&1; then
        break
    fi
    sleep 1
    ATTEMPTS=$((ATTEMPTS + 1))
done

echo ""
echo "==============================================================================="
echo "  ✅ Cockpit online! Abrindo navegador..."
echo "  Acesse: http://localhost:4545/"
echo "  PID do servidor: $SERVER_PID"
echo "==============================================================================="
echo ""

open "http://localhost:4545/"

# Manter a janela informativa aberta por 5 segundos antes de fechar
sleep 5
