#!/usr/bin/env bash
# ==============================================================================
# scripts/setup_wsl_internal.sh
# Provisionamento automático e silencioso dentro do WSL2 (Ubuntu)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "===================================================================="
echo " [AXET-AGENT-CONTEXT-GEN] Provisionando ambiente interno WSL2..."
echo " Diretório do projeto: $PROJECT_DIR"
echo "===================================================================="

# 1. Atualizar repositórios de pacotes
echo ">>> [1/5] Atualizando repositórios APT do Ubuntu..."
sudo apt-get update -y

# 2. Instalar utilitários essenciais e FFmpeg
echo ">>> [2/5] Instalando FFmpeg, Python e ferramentas de compilação..."
sudo apt-get install -y ffmpeg python3 python3-pip python3-venv curl wget git build-essential

# 3. Garantir Node.js 20 LTS
echo ">>> [3/5] Verificando versão do Node.js..."
NODE_VER=""
if command -v node >/dev/null 2>&1; then
    NODE_VER="$(node -v | cut -d'.' -f1 | tr -d 'v' || echo '0')"
fi

if [[ -z "$NODE_VER" || "$NODE_VER" -lt 18 ]]; then
    echo "    Instalando Node.js 20 LTS via NodeSource..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi
echo "    Node.js ativo: $(node -v)"

# 4. Criar e configurar o ambiente virtual Python
echo ">>> [4/5] Configurando ambiente virtual Python e Whisper..."
cd "$PROJECT_DIR"
if [[ ! -d ".venv" ]]; then
    python3 -m venv .venv
fi

source .venv/bin/activate
pip install --upgrade pip

# Detectar suporte a GPU NVIDIA CUDA via WSL
if command -v nvidia-smi >/dev/null 2>&1; then
    echo "    GPU NVIDIA detectada! Instalando PyTorch com aceleração CUDA..."
    pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118
else
    echo "    Nenhuma GPU NVIDIA detectada. Instalando PyTorch otimizado para CPU..."
    pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu
fi

echo "    Instalando OpenAI Whisper e dependências do Gateway..."
pip install openai-whisper
pip install cryptography tomli

# 5. Ajustar permissões dos scripts
echo ">>> [5/5] Ajustando permissões de execução dos scripts..."
chmod +x "$PROJECT_DIR"/scripts/*.sh "$PROJECT_DIR"/scripts/*.py 2>/dev/null || true

echo "===================================================================="
echo " [OK] Ambiente WSL2 configurado com sucesso!"
echo "===================================================================="
