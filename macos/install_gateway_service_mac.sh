#!/usr/bin/env bash
# ==============================================================================
# install_gateway_service_mac.sh
# Instala o serviço do Local AI Gateway e de Renovação de Tokens no macOS via Launchd
# ==============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GATEWAY_PLIST="$HOME/Library/LaunchAgents/com.axet.local-ai-gateway.gateway.plist"
REFRESH_PLIST="$HOME/Library/LaunchAgents/com.axet.local-ai-gateway.refresh-token.plist"

mkdir -p "$HOME/Library/LaunchAgents" "$REPO_DIR/gateway/logs"

echo "[1/4] Gerando LaunchAgent para o Gateway (porta 8766)..."
cat <<EOF > "$GATEWAY_PLIST"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>com.axet.local-ai-gateway.gateway</string>
    <key>ProgramArguments</key>
    <array>
      <string>/bin/zsh</string>
      <string>-lc</string>
      <string>cd "$REPO_DIR" && python3 gateway/local_ai_gateway.py</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>ThrottleInterval</key>
    <integer>10</integer>
    <key>StandardOutPath</key>
    <string>$REPO_DIR/gateway/logs/gateway.out.log</string>
    <key>StandardErrorPath</key>
    <string>$REPO_DIR/gateway/logs/gateway.err.log</string>
    <key>WorkingDirectory</key>
    <string>$REPO_DIR</string>
  </dict>
</plist>
EOF

echo "[2/4] Gerando LaunchAgent para Renovação Automática de Token Okta..."
cat <<EOF > "$REFRESH_PLIST"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>com.axet.local-ai-gateway.refresh-token</string>
    <key>ProgramArguments</key>
    <array>
      <string>/bin/zsh</string>
      <string>-lc</string>
      <string>cd "$REPO_DIR" && python3 refresh_axet_token.py</string>
    </array>
    <key>StartInterval</key>
    <integer>300</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>StandardOutPath</key>
    <string>$REPO_DIR/gateway/logs/token-refresh.log</string>
    <key>StandardErrorPath</key>
    <string>$REPO_DIR/gateway/logs/token-refresh.error.log</string>
    <key>WorkingDirectory</key>
    <string>$REPO_DIR</string>
  </dict>
</plist>
EOF

echo "[3/4] Registrando serviços no launchd..."
launchctl bootout "gui/$(id -u)" "$GATEWAY_PLIST" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$GATEWAY_PLIST"
launchctl enable "gui/$(id -u)/com.axet.local-ai-gateway.gateway" >/dev/null 2>&1 || true
launchctl kickstart -k "gui/$(id -u)/com.axet.local-ai-gateway.gateway" >/dev/null 2>&1 || true

launchctl bootout "gui/$(id -u)" "$REFRESH_PLIST" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$REFRESH_PLIST"
launchctl enable "gui/$(id -u)/com.axet.local-ai-gateway.refresh-token" >/dev/null 2>&1 || true

echo "[4/4] Concluído com sucesso!"
echo "Gateway rodando a partir de: $REPO_DIR"
echo "Logs disponíveis em: $REPO_DIR/gateway/logs/"
