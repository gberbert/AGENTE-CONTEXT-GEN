#!/usr/bin/env bash
#
# step3_analise_avancada.sh
#
# Executa a etapa 3 (interpretação/humanização) do pipeline usando o PROMPT
# AVANÇADO de análise sênior de transcrições (documentação funcional,
# arquitetura, negócio, riscos, Q&A, etc.), com anti-alucinação.
#
# Reaproveita uma transcrição já existente e permite escolher o modelo do
# axet-code.
#
# Telemetria (opcional):
#   Se houver um dashboard de telemetria rodando (dashboard/server.js),
#   este script envia eventos de progresso via HTTP POST para
#   http://localhost:$DASHBOARD_PORT/telemetry, permitindo acompanhar a
#   execução em tempo real no cockpit visual. Se o dashboard não estiver
#   ativo, os envios falham silenciosamente e o script continua normal.
#
# Uso:
#   ./scripts/step3_analise_avancada.sh <transcricao.txt> <modelo> [nome_video]
#
# Exemplo:
#   ./scripts/step3_analise_avancada.sh output/reef_full.txt gpt-5.6-terra reef_full.mp4
#
set -euo pipefail

TRANSCRIPT_PATH="${1:-}"
MODEL="${2:-}"
VIDEO_NAME="${3:-desconhecido}"

if [[ -z "$TRANSCRIPT_PATH" || -z "$MODEL" ]]; then
  echo "Uso: $0 <caminho_transcricao.txt> <modelo> [nome_video]" >&2
  exit 1
fi

if [[ ! -f "$TRANSCRIPT_PATH" ]]; then
  echo "Erro: transcrição não encontrada: $TRANSCRIPT_PATH" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$ROOT_DIR/output"
PROMPT_TEMPLATE="$ROOT_DIR/prompts/analise_transcricao_avancada.md"

if [[ ! -f "$PROMPT_TEMPLATE" ]]; then
  echo "Erro: template de prompt não encontrado: $PROMPT_TEMPLATE" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
FILENAME_NOEXT="$(basename "$TRANSCRIPT_PATH" .txt)"

# ---------------------------------------------------------------------------
# Telemetria: helpers
# ---------------------------------------------------------------------------
DASHBOARD_PORT="${DASHBOARD_PORT:-4545}"
TELEMETRY_URL="http://localhost:${DASHBOARD_PORT}/telemetry"
# RUN_ID inclui timestamp + PID, garantindo unicidade mesmo quando a MESMA
# transcrição é analisada em paralelo com modelos diferentes.
RUN_ID="run_${TIMESTAMP}_$$"

FINAL_MD="$OUTPUT_DIR/${FILENAME_NOEXT}_analise_avancada_${MODEL}_${RUN_ID}.md"
FULL_PROMPT_FILE="$(mktemp -t axet_prompt_XXXXXX.txt)"

now_iso() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Envia um evento JSON para o dashboard. Falha silenciosamente se o
# dashboard não estiver rodando (não deve interromper o script).
emit_telemetry() {
  local json_payload="$1"
  curl -s -m 2 -X POST "$TELEMETRY_URL" \
    -H "Content-Type: application/json" \
    -d "$json_payload" >/dev/null 2>&1 || true
}

emit_run_start() {
  emit_telemetry "$(cat <<EOF
{"type":"run_start","run_id":"$RUN_ID","ts":"$(now_iso)","video":"$VIDEO_NAME","whisper_model":"(reaproveitada)","axet_model":"$MODEL"}
EOF
)"
}

emit_step_start() {
  local step="$1"
  local message="${2:-}"
  local safe_message="${message//\"/\\\"}"
  emit_telemetry "$(cat <<EOF
{"type":"step_start","run_id":"$RUN_ID","step":"$step","message":"$safe_message","ts":"$(now_iso)"}
EOF
)"
}

emit_step_end() {
  local step="$1"
  local status="$2"
  local duration_s="$3"
  local message="$4"
  emit_telemetry "$(cat <<EOF
{"type":"step_end","run_id":"$RUN_ID","step":"$step","status":"$status","duration_s":$duration_s,"message":"$message","ts":"$(now_iso)"}
EOF
)"
}

emit_log() {
  local level="$1"
  local step="$2"
  local message="$3"
  local safe_message="${message//\"/\\\"}"
  emit_telemetry "$(cat <<EOF
{"type":"log","run_id":"$RUN_ID","level":"$level","step":"$step","message":"$safe_message","ts":"$(now_iso)"}
EOF
)"
}

emit_run_end() {
  local status="$1"
  local duration_s="$2"
  emit_telemetry "$(cat <<EOF
{"type":"run_end","run_id":"$RUN_ID","status":"$status","duration_s":$duration_s,"ts":"$(now_iso)"}
EOF
)"
}

emit_run_pid() {
  local pid="$1"
  emit_telemetry "$(cat <<EOF
{"type":"run_pid","run_id":"$RUN_ID","pid":$pid,"ts":"$(now_iso)"}
EOF
)"
}

# ---------------------------------------------------------------------------
# Heartbeat em background para evitar timeouts durante inferência longa no LLM
# ---------------------------------------------------------------------------
HEARTBEAT_PID=""

start_heartbeat() {
  stop_heartbeat
  (
    while kill -0 "$$" 2>/dev/null; do
      sleep 20
      emit_telemetry "{\"type\":\"heartbeat\",\"run_id\":\"$RUN_ID\",\"ts\":\"$(now_iso)\"}"
    done
  ) &
  HEARTBEAT_PID=$!
}

stop_heartbeat() {
  if [[ -n "${HEARTBEAT_PID:-}" ]] && kill -0 "$HEARTBEAT_PID" 2>/dev/null; then
    kill "$HEARTBEAT_PID" 2>/dev/null || true
    wait "$HEARTBEAT_PID" 2>/dev/null || true
  fi
  HEARTBEAT_PID=""
}

PIPELINE_START_TS=$(date +%s)
CANCELLED=0

# Trata cancelamento manual via SIGTERM (enviado pelo endpoint POST /cancel
# do dashboard). Marca a flag CANCELLED antes de deixar o trap EXIT tratar
# a saída, para que o run_end seja emitido com status "cancelled" em vez
# de "error".
on_sigterm_trap() {
  stop_heartbeat
  CANCELLED=1
  emit_log "WARN" "" "Análise avançada recebeu sinal de cancelamento (SIGTERM)."
  exit 143
}
trap on_sigterm_trap TERM INT

# Garante que, em caso de erro, o run_end seja emitido como "error" (ou
# "cancelled", se cancelado manualmente) para o dashboard não ficar
# travado em "running".
on_error_trap() {
  local exit_code=$?
  stop_heartbeat
  if [[ $exit_code -ne 0 ]]; then
    local total_dur=$(( $(date +%s) - PIPELINE_START_TS ))
    if [[ "$CANCELLED" -eq 1 ]]; then
      emit_log "WARN" "" "Análise avançada cancelada manualmente pelo usuário."
      emit_run_end "cancelled" "$total_dur"
    else
      emit_log "ERROR" "" "Análise avançada finalizada com erro (exit code $exit_code)."
      emit_run_end "error" "$total_dur"
    fi
  fi
}
trap on_error_trap EXIT

echo "=============================================================="
echo " AXET Video Pipeline - Etapa 3 (Análise Avançada / Sênior)"
echo "=============================================================="
echo "Transcrição       : $TRANSCRIPT_PATH"
echo "Template de prompt: $PROMPT_TEMPLATE"
echo "Modelo axet-code   : $MODEL"
echo "Saída              : $FINAL_MD"
echo "Run ID             : $RUN_ID"
echo "=============================================================="

emit_run_start
emit_run_pid "$$"
start_heartbeat
emit_log "INFO" "" "Análise avançada iniciada para a transcrição '$(basename "$TRANSCRIPT_PATH")' (modelo: $MODEL)."

# ---------------------------------------------------------------------------
# Etapa: interpretação/análise avançada via axet-code
# ---------------------------------------------------------------------------
STEP_START=$(date +%s)
emit_step_start "interpretacao_axet"
emit_log "INFO" "interpretacao_axet" "Montando prompt avançado com a transcrição embutida."

# Substitui o marcador {{TRANSCRICAO}} pelo conteúdo real da transcrição.
# Usamos Python para evitar problemas de heredoc/escape do shell com
# textos grandes contendo caracteres especiais, aspas, cifrões etc.
python3 - "$PROMPT_TEMPLATE" "$TRANSCRIPT_PATH" "$FULL_PROMPT_FILE" <<'PYEOF'
import sys

template_path, transcript_path, out_path = sys.argv[1:4]

with open(template_path, "r", encoding="utf-8") as f:
    template = f.read()

with open(transcript_path, "r", encoding="utf-8") as f:
    transcript = f.read()

if "{{TRANSCRICAO}}" in template:
    final_prompt = template.replace("{{TRANSCRICAO}}", transcript)
else:
    final_prompt = f"{template}\n\n---\n\n# TRANSCRIÇÃO ORIGINAL PARA ANÁLISE\n\n```\n{transcript}\n```\n"

with open(out_path, "w", encoding="utf-8") as f:
    f.write(final_prompt)
PYEOF

echo "Prompt final montado em arquivo temporário: $FULL_PROMPT_FILE"
echo "Tamanho do prompt: $(wc -c < "$FULL_PROMPT_FILE") bytes"
echo
echo "Chamando axet-code (modelo: $MODEL)... isso pode levar alguns minutos."
echo

emit_log "INFO" "interpretacao_axet" "Enviando prompt para axet-code (modelo: $MODEL). Tamanho: $(wc -c < "$FULL_PROMPT_FILE") bytes."

# Usamos stdin (pipe) em vez de passar o prompt como argumento, pois o
# prompt final (com a transcrição embutida) pode ser muito grande e
# ultrapassar o limite de tamanho de argumentos do shell/OS.
AXET_OUTPUT="$(cat "$FULL_PROMPT_FILE" | axet-code run --model "$MODEL" --quiet)" || {
  echo "Erro ao executar axet-code." >&2
  emit_log "ERROR" "interpretacao_axet" "Erro ao executar axet-code (modelo: $MODEL)."
  emit_step_end "interpretacao_axet" "error" "$(( $(date +%s) - STEP_START ))" "Falha na chamada ao axet-code."
  rm -f "$FULL_PROMPT_FILE"
  exit 1
}

rm -f "$FULL_PROMPT_FILE"

if [[ -z "$AXET_OUTPUT" ]]; then
  echo "Erro: axet-code não retornou conteúdo." >&2
  emit_log "ERROR" "interpretacao_axet" "axet-code não retornou conteúdo."
  emit_step_end "interpretacao_axet" "error" "$(( $(date +%s) - STEP_START ))" "axet-code sem retorno."
  exit 1
fi

STEP_DUR=$(( $(date +%s) - STEP_START ))
echo "      -> Análise avançada gerada pelo axet-code."
emit_log "INFO" "interpretacao_axet" "Análise avançada gerada com sucesso pelo axet-code."
emit_step_end "interpretacao_axet" "success" "$STEP_DUR" "Análise avançada concluída."

# ---------------------------------------------------------------------------
# Montagem do Markdown final
# ---------------------------------------------------------------------------
STEP4_START=$(date +%s)
emit_step_start "geracao_markdown"
emit_log "INFO" "geracao_markdown" "Montando relatório final em Markdown."

TRANSCRIPT_CONTENT="$(cat "$TRANSCRIPT_PATH")"

{
  echo "# Relatório de Análise Avançada de Transcrição"
  echo
  echo "**Arquivo de origem:** \`${VIDEO_NAME}\`"
  echo "**Transcrição utilizada:** \`${TRANSCRIPT_PATH}\`"
  echo "**Data de processamento:** $(date '+%d/%m/%Y %H:%M:%S')"
  echo "**Modelo de interpretação (etapa 3):** ${MODEL} (axet-code)"
  echo "**Prompt utilizado:** análise sênior avançada (documentação funcional, arquitetura, negócio, riscos, Q&A, anti-alucinação)"
  echo
  echo "---"
  echo
  echo "$AXET_OUTPUT"
  echo
  echo "---"
  echo
  echo "## Transcrição Completa (bruta)"
  echo
  echo '```'
  echo "$TRANSCRIPT_CONTENT"
  echo '```'
} > "$FINAL_MD"

STEP4_DUR=$(( $(date +%s) - STEP4_START ))
echo "      -> Relatório final salvo em: $FINAL_MD"
emit_log "INFO" "geracao_markdown" "Relatório final salvo: $(basename "$FINAL_MD")."
emit_step_end "geracao_markdown" "success" "$STEP4_DUR" "Relatório: $(basename "$FINAL_MD")"

stop_heartbeat
PIPELINE_TOTAL_DUR=$(( $(date +%s) - PIPELINE_START_TS ))
emit_log "INFO" "" "Análise avançada concluída com sucesso em ${PIPELINE_TOTAL_DUR}s."
emit_run_end "success" "$PIPELINE_TOTAL_DUR"

echo "=============================================================="
echo "Relatório salvo em: $FINAL_MD"
echo "=============================================================="
