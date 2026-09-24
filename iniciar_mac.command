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

# 1. Verificar se o servidor já está rodando
if curl -s -I http://localhost:4545/ >/dev/null 2>&1; then
    echo "[OK] Cockpit já está rodando em http://localhost:4545/"
    open "http://localhost:4545/"
    exit 0
fi

# 2. Ativar virtualenv se existir
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
