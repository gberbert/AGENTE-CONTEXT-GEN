#!/usr/bin/env bash
# ==============================================================================
# setup_mac.sh
# Instalador e configurador automatizado de ambiente local para macOS
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "==============================================================================="
echo "  🧠 NTT DATA — AXET-AGENT-CONTEXT-GEN"
echo "  Instalador Automatizado de Ambiente Local para macOS"
echo "==============================================================================="
echo ""

# 1. Verificar Homebrew
echo "[1/4] Verificando gerenciador de pacotes Homebrew..."
if ! command -v brew >/dev/null 2>&1; then
    echo "    Homebrew não encontrado. Para instalar o FFmpeg automaticamente, instale o Homebrew:"
    echo "    /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
else
    echo "    Homebrew detectado: $(brew --version | head -n 1)"
    # Instalar FFmpeg se necessário
    if ! command -v ffmpeg >/dev/null 2>&1; then
        echo "    Instalando FFmpeg via Homebrew..."
        brew install ffmpeg
    else
        echo "    FFmpeg já instalado: $(ffmpeg -version | head -n 1)"
    fi
fi

# 2. Verificar Python 3 e Node.js
echo "[2/4] Verificando Python e Node.js..."
if ! command -v python3 >/dev/null 2>&1; then
    echo "    [ERRO] Python 3 não encontrado. Instale via Homebrew: brew install python@3.11"
    exit 1
fi
echo "    Python ativo: $(python3 --version)"

if ! command -v node >/dev/null 2>&1; then
    echo "    [ERRO] Node.js não encontrado. Instale via Homebrew: brew install node"
    exit 1
fi
echo "    Node.js ativo: $(node -v)"

# 3. Configurar virtualenv Python e Whisper
echo "[3/4] Configurando ambiente virtual Python e Whisper..."
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
fi

source .venv/bin/activate
pip install --upgrade pip
pip install torch torchvision
pip install openai-whisper

# 4. Ajustar permissões e criar atalho na Mesa/Desktop
echo "[4/4] Criando atalho na Mesa (Desktop)..."
chmod +x scripts/*.sh scripts/*.py iniciar_mac.command 2>/dev/null || true

DESKTOP_DIR="$HOME/Desktop"
SHORTCUT="$DESKTOP_DIR/Iniciar Cockpit NTT DATA.command"

cat <<EOF > "$SHORTCUT"
#!/usr/bin/env bash
cd "$SCRIPT_DIR"
exec ./iniciar_mac.command
EOF
chmod +x "$SHORTCUT"

echo ""
echo "==============================================================================="
echo "  ✅ INSTALAÇÃO CONCLUÍDA COM SUCESSO NO MACOS!"
echo "==============================================================================="
echo ""
echo "Atalho criado na sua Mesa:"
echo "  $SHORTCUT"
echo ""
echo "Deseja iniciar o Cockpit agora mesmo?"
read -p "Iniciar agora? (S/n): " RESP
RESP="${RESP:-s}"
if [[ "$RESP" =~ ^[Ss]$ ]]; then
    exec ./iniciar_mac.command
fi
