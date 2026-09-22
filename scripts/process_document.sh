#!/usr/bin/env bash
#
# process_document.sh
#
# Pipeline automatizado e não-interativo para ingestão de documentos corporativos:
#   1. Extrair texto hierárquico, tabelas e notas (PDF, DOCX, PPTX)
#   2. Interpretar e estruturar o conhecimento via axet-code com prompt RAG de alta densidade
#   3. Gerar relatório final enriquecido em Markdown (.md)
#
# Telemetria:
#   Emite eventos em tempo real para o dashboard (dashboard/server.js) via POST /telemetry.
#
# Uso:
#   ./scripts/process_document.sh <caminho_do_documento> [modelo_axet]
#
set -euo pipefail

DOC_PATH="${1:-}"
AXET_MODEL_PARAM="${2:-}"

if [[ -z "$DOC_PATH" ]]; then
  echo "Uso: $0 <caminho_do_documento> [modelo_axet]" >&2
  exit 1
fi

if [[ ! -f "$DOC_PATH" ]]; then
  echo "Erro: arquivo de documento não encontrado: $DOC_PATH" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

OUTPUT_DIR="${OUTPUT_DIR:-$ROOT_DIR/output}"
PROMPT_TEMPLATE="${PROMPT_TEMPLATE:-$ROOT_DIR/prompts/analise_documento_rag.md}"
MODEL="${AXET_MODEL_PARAM:-${AXET_MODEL:-gpt-5.6-terra}}"

VENV_PYTHON="$ROOT_DIR/.venv/bin/python"
if [[ ! -x "$VENV_PYTHON" ]]; then
  VENV_PYTHON="python3"
fi

BASENAME="$(basename "$DOC_PATH")"
FILENAME_NOEXT="${BASENAME%.*}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

# Diretório de saída dedicado para este documento específico
if [[ -n "${OUTPUT_DIR:-}" && "$OUTPUT_DIR" != "$ROOT_DIR/output" ]]; then
  DOC_OUTPUT_DIR="$OUTPUT_DIR"
else
  OUTPUT_DIR="${OUTPUT_DIR:-$ROOT_DIR/output}"
  if [[ -n "${INPUT_DIR:-}" && "$DOC_PATH" == "$INPUT_DIR"* ]]; then
    _REL_PATH="${DOC_PATH#$INPUT_DIR/}"
    _REL_DIR="$(dirname "$_REL_PATH")"
    if [[ "$_REL_DIR" != "." && -n "$_REL_DIR" && "$_REL_DIR" != "/" ]]; then
      OUTPUT_DIR="$OUTPUT_DIR/$_REL_DIR"
    fi
  fi
  DOC_OUTPUT_DIR="$OUTPUT_DIR/$FILENAME_NOEXT"
fi

mkdir -p "$DOC_OUTPUT_DIR"
mkdir -p "$DOC_OUTPUT_DIR/logs"

DASHBOARD_PORT="${DASHBOARD_PORT:-4545}"
TELEMETRY_URL="http://localhost:${DASHBOARD_PORT}/telemetry"
RUN_ID="run_doc_${TIMESTAMP}_$$"

TEMP_WORKSPACE="/tmp/axet-workspace/${RUN_ID}"
mkdir -p "$TEMP_WORKSPACE"

safe_cleanup_temp() {
  if [[ -n "${TEMP_WORKSPACE:-}" && "$TEMP_WORKSPACE" == /tmp/axet-workspace/* && -d "$TEMP_WORKSPACE" ]]; then
    rm -rf "$TEMP_WORKSPACE" 2>/dev/null || true
  fi
}

RAW_TXT_PATH="$DOC_OUTPUT_DIR/${FILENAME_NOEXT}_${RUN_ID}_raw.txt"
META_JSON_PATH="$DOC_OUTPUT_DIR/${FILENAME_NOEXT}_${RUN_ID}_meta.json"
FINAL_MD="$DOC_OUTPUT_DIR/${FILENAME_NOEXT}_rag_${RUN_ID}.md"

# Salvaguarda de limite de caminho do OneDrive (máx 300 caracteres)
if [[ ${#FINAL_MD} -gt 300 ]]; then
  RAW_TXT_PATH="$DOC_OUTPUT_DIR/raw_${RUN_ID}.txt"
  META_JSON_PATH="$DOC_OUTPUT_DIR/meta_${RUN_ID}.json"
  FINAL_MD="$DOC_OUTPUT_DIR/rag_${RUN_ID}.md"
fi

FULL_PROMPT_FILE="$TEMP_WORKSPACE/full_prompt.txt"

now_iso() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

emit_telemetry() {
  local json_payload="$1"
  curl -s -m 2 -X POST "$TELEMETRY_URL" \
    -H "Content-Type: application/json" \
    -d "$json_payload" >/dev/null 2>&1 || true
}

emit_run_start() {
  local safe_basename="${BASENAME//\"/\\\"}"
  emit_telemetry "$(cat <<EOF
{"type":"run_start","run_id":"$RUN_ID","video":"$safe_basename","media_type":"document","axet_model":"$MODEL","ts":"$(now_iso)"}
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
  local duration_s="${3:-0}"
  local message="${4:-}"
  local safe_message="${message//\"/\\\"}"
  emit_telemetry "$(cat <<EOF
{"type":"step_end","run_id":"$RUN_ID","step":"$step","status":"$status","duration_s":$duration_s,"message":"$safe_message","ts":"$(now_iso)"}
EOF
)"
}

emit_log() {
  local level="$1"
  local step="$2"
  local message="${3:-}"
  local safe_message="${message//\"/\\\"}"
  emit_telemetry "$(cat <<EOF
{"type":"log","run_id":"$RUN_ID","level":"$level","step":"$step","message":"$safe_message","ts":"$(now_iso)"}
EOF
)"
}

emit_run_end() {
  local status="$1"
  local duration_s="${2:-0}"
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
CURRENT_STEP=""

on_sigterm_trap() {
  stop_heartbeat
  safe_cleanup_temp
  CANCELLED=1
  emit_log "WARN" "$CURRENT_STEP" "Processo de ingestão do documento recebeu sinal de cancelamento (SIGTERM)."
  exit 143
}
trap on_sigterm_trap TERM INT

on_error_trap() {
  local exit_code=$?
  stop_heartbeat
  safe_cleanup_temp
  if [[ $exit_code -ne 0 ]]; then
    local total_dur=$(( $(date +%s) - PIPELINE_START_TS ))
    if [[ "$CANCELLED" -eq 1 ]]; then
      emit_log "WARN" "$CURRENT_STEP" "Ingestão cancelada manualmente pelo usuário."
      emit_run_end "cancelled" "$total_dur"
    else
      local err_msg="Falha durante a etapa '$CURRENT_STEP' (exit code $exit_code)"
      emit_log "ERROR" "$CURRENT_STEP" "$err_msg"
      if [[ -n "$CURRENT_STEP" ]]; then
        emit_step_end "$CURRENT_STEP" "error" "$(( $(date +%s) - PIPELINE_START_TS ))" "$err_msg"
      fi
      emit_run_end "error" "$total_dur"
    fi
  fi
}
trap on_error_trap EXIT

echo "=============================================================="
echo " AXET Multimodal Pipeline - Ingestão de Documento para RAG"
echo "=============================================================="
echo "Documento         : $DOC_PATH"
echo "Modelo axet-code  : $MODEL"
echo "Saída             : $FINAL_MD"
echo "Run ID            : $RUN_ID"
echo "=============================================================="

emit_run_start
emit_run_pid "$$"
start_heartbeat
emit_log "INFO" "" "Iniciando ingestão para '$BASENAME' (modelo: $MODEL)."

# ---------------------------------------------------------------------------
# Salvaguarda Pré-Voo: Verificação de arquivo dataless / apenas na nuvem
# ---------------------------------------------------------------------------
CURRENT_STEP="extracao_documento"
emit_step_start "extracao_documento" "Iniciando extração do documento..."
emit_log "INFO" "extracao_documento" "Verificando integridade e hidratação do documento no disco..."

DOC_PREFLIGHT_ERROR=""
if ! head -c 1024 "$DOC_PATH" >/dev/null 2>&1; then
  DOC_PREFLIGHT_ERROR="Arquivo não pôde ser lido no disco local (pode ser um atalho do OneDrive 'dataless' pendente de download)."
fi

if [[ -n "$DOC_PREFLIGHT_ERROR" ]]; then
  echo "ERRO PRÉ-VOO: $DOC_PREFLIGHT_ERROR" >&2
  emit_log "ERROR" "extracao_documento" "Pré-voo falhou: $DOC_PREFLIGHT_ERROR"
  emit_step_end "extracao_documento" "error" "$(( $(date +%s) - PIPELINE_START_TS ))" "$DOC_PREFLIGHT_ERROR"
  exit 196
fi

# ---------------------------------------------------------------------------
# Etapa 1: Extração estruturada do documento via Python
# ---------------------------------------------------------------------------
STEP1_START=$(date +%s)
emit_log "INFO" "extracao_documento" "Executando parser multi-formato (extract_document.py)..."

EXTRACTION_JSON="$("$VENV_PYTHON" "$ROOT_DIR/scripts/extract_document.py" "$DOC_PATH" "$RAW_TXT_PATH" --json-meta "$META_JSON_PATH")" || {
  echo "Erro ao extrair conteúdo do documento: $DOC_PATH" >&2
  emit_log "ERROR" "extracao_documento" "Falha na extração com extract_document.py."
  emit_step_end "extracao_documento" "error" "$(( $(date +%s) - STEP1_START ))" "Falha ao extrair documento."
  exit 1
}

RAW_SIZE="$(wc -c < "$RAW_TXT_PATH" | tr -d ' ')"
if [[ "$RAW_SIZE" -lt 20 ]]; then
  echo "Aviso: conteúdo extraído é muito pequeno ($RAW_SIZE bytes)." >&2
  emit_log "WARN" "extracao_documento" "Conteúdo extraído é muito curto ($RAW_SIZE bytes)."
fi

STEP1_DUR=$(( $(date +%s) - STEP1_START ))
echo "      -> Conteúdo extraído com sucesso ($RAW_SIZE bytes)."
emit_log "INFO" "extracao_documento" "Extração concluída com sucesso: $RAW_SIZE bytes extraídos em ${STEP1_DUR}s."
emit_step_end "extracao_documento" "success" "$STEP1_DUR" "Extraído ($RAW_SIZE bytes)"

# Salvaguarda: detecta se o arquivo é um placeholder/em branco (0 caracteres textuais reais e 0 imagens)
IS_BLANK_DOC=false
if grep -q '"is_blank": true' "$META_JSON_PATH" 2>/dev/null; then
  IS_BLANK_DOC=true
elif [[ "$RAW_SIZE" -lt 150 ]] && grep -q "Página em branco ou apenas elementos visuais/imagem" "$RAW_TXT_PATH" 2>/dev/null; then
  IS_BLANK_DOC=true
fi

if [[ "$IS_BLANK_DOC" == true ]]; then
  echo "      -> Documento identificado como em branco / placeholder (sem texto/imagens)."
  emit_step_start "interpretacao_axet" "Registrando documento em branco..."
  emit_log "INFO" "interpretacao_axet" "Documento em branco/placeholder identificado. Gerando registro descritivo formal..."
  {
    echo "# Relatório de Documento: $BASENAME"
    echo
    echo "## 1. Metadados do Documento"
    echo "- **Arquivo de Origem:** \`$BASENAME\`"
    echo "- **Tipo de Documento:** Documento em Branco / Placeholder"
    echo "- **Data de Processamento:** $(date '+%d/%m/%Y %H:%M:%S')"
    echo "- **Status Operacional:** Sem conteúdo textual ou elementos visuais no arquivo original."
    echo
    echo "---"
    echo
    echo "## 2. Resumo da Ingestão"
    echo "O arquivo foi verificado pelo parser estruturado do pipeline. A análise confirmou a ausência de camadas de texto extraíveis e ausência de imagens incorporadas no documento de origem."
    echo
    echo "Este registro é gerado para assegurar 100% de cobertura, rastreabilidade e integridade no índice RAG corporativo."
  } > "$FINAL_MD"

  emit_step_end "interpretacao_axet" "success" 0 "Documento em branco (placeholder)"
  emit_step_start "geracao_markdown" "Gravando relatório final..."
  emit_step_end "geracao_markdown" "success" 0 "Relatório salvo: $(basename "$FINAL_MD")"
  stop_heartbeat
  safe_cleanup_temp
  CURRENT_STEP=""
  PIPELINE_TOTAL_DUR=$(( $(date +%s) - PIPELINE_START_TS ))
  emit_log "INFO" "" "Ingestão do documento '$BASENAME' concluída com sucesso em ${PIPELINE_TOTAL_DUR}s."
  emit_run_end "success" "$PIPELINE_TOTAL_DUR"
  echo "=============================================================="
  echo "Relatório RAG salvo em: $FINAL_MD"
  echo "=============================================================="
  exit 0
fi

# ---------------------------------------------------------------------------
# Etapa 2: Interpretação e estruturação RAG via axet-code
# ---------------------------------------------------------------------------
CURRENT_STEP="interpretacao_axet"
STEP2_START=$(date +%s)
emit_step_start "interpretacao_axet" "Processando com IA para RAG..."
emit_log "INFO" "interpretacao_axet" "Montando prompt RAG de alta densidade (analise_documento_rag.md)."

"$VENV_PYTHON" - "$PROMPT_TEMPLATE" "$RAW_TXT_PATH" "$FULL_PROMPT_FILE" <<'PYEOF'
import sys

template_path, raw_txt_path, out_path = sys.argv[1:4]

with open(template_path, "r", encoding="utf-8") as f:
    template = f.read()

with open(raw_txt_path, "r", encoding="utf-8") as f:
    raw_content = f.read()

if "{{CONTEUDO_DOCUMENTO}}" in template:
    final_prompt = template.replace("{{CONTEUDO_DOCUMENTO}}", raw_content)
else:
    final_prompt = f"{template}\n\n---\n\n# CONTEÚDO BRUTO DO DOCUMENTO\n\n```text\n{raw_content}\n```\n"

with open(out_path, "w", encoding="utf-8") as f:
    f.write(final_prompt)
PYEOF

PROMPT_BYTES="$(wc -c < "$FULL_PROMPT_FILE" | tr -d ' ')"
echo "Prompt RAG montado: $PROMPT_BYTES bytes."
emit_log "INFO" "interpretacao_axet" "Enviando prompt ao axet-code (modelo: $MODEL, tamanho: $PROMPT_BYTES bytes)..."

AXET_ERR_FILE="$TEMP_WORKSPACE/axet_err.txt"
AXET_SUCCESS=false
AXET_OUTPUT=""

for attempt in 1 2; do
  emit_log "INFO" "interpretacao_axet" "Invocando axet-code (tentativa $attempt de 2, modelo: $MODEL)..."
  mkdir -p "$TEMP_WORKSPACE"
  if AXET_OUTPUT="$(cat "$FULL_PROMPT_FILE" | axet-code run --model "$MODEL" -c /tmp --quiet 2>"$AXET_ERR_FILE")"; then
    AXET_OUT_LEN=$(printf '%s' "$AXET_OUTPUT" | wc -c | tr -d ' ')
    # Rejeita saídas curtas ou mensagens de erro/banner que axet-code cospe no stdout
    if [[ "$AXET_OUT_LEN" -ge 500 && "$AXET_OUTPUT" != *"Failed to change directory"* && "$AXET_OUTPUT" != *"Not authenticated"* ]]; then
      AXET_SUCCESS=true
      break
    else
      SHORT_SNIP="$(printf '%s' "$AXET_OUTPUT" | tr '\n' ' ' | cut -c 1-150)"
      echo "Aviso: axet-code retornou saída curta ou erro ($AXET_OUT_LEN bytes: $SHORT_SNIP). Retentando em 5s..." >&2
      emit_log "WARN" "interpretacao_axet" "Tentativa $attempt: resposta inválida/curta ($AXET_OUT_LEN bytes). Retentando..."
    fi
  else
    ERR_SNIP="$(tail -n 5 "$AXET_ERR_FILE" 2>/dev/null | tr '\n' ' ' || echo 'Sem detalhes')"
    echo "Aviso: falha na execução do axet-code: $ERR_SNIP" >&2
    emit_log "WARN" "interpretacao_axet" "Tentativa $attempt falhou ($ERR_SNIP). Aguardando 5s..."
  fi
  sleep 5
done

rm -f "$FULL_PROMPT_FILE"

if [[ "$AXET_SUCCESS" != true ]]; then
  ERR_SNIP="$(tail -n 5 "$AXET_ERR_FILE" 2>/dev/null | tr '\n' ' ' || echo 'Erro desconhecido')"
  echo "Erro: axet-code encerrou com falha após 2 tentativas ($ERR_SNIP)." >&2
  emit_log "ERROR" "interpretacao_axet" "axet-code falhou: $ERR_SNIP"
  emit_step_end "interpretacao_axet" "error" "$(( $(date +%s) - STEP2_START ))" "axet-code: $ERR_SNIP"
  rm -f "$AXET_ERR_FILE"
  exit 1
fi
rm -f "$AXET_ERR_FILE"

STEP2_DUR=$(( $(date +%s) - STEP2_START ))
echo "      -> Análise RAG gerada com sucesso pelo axet-code."
emit_log "INFO" "interpretacao_axet" "Análise RAG concluída com sucesso em ${STEP2_DUR}s."
emit_step_end "interpretacao_axet" "success" "$STEP2_DUR" "Análise RAG concluída"

# ---------------------------------------------------------------------------
# Etapa 3: Geração do Markdown Final
# ---------------------------------------------------------------------------
CURRENT_STEP="geracao_markdown"
STEP3_START=$(date +%s)
emit_step_start "geracao_markdown" "Montando relatório final em Markdown..."
emit_log "INFO" "geracao_markdown" "Gravando relatório RAG estruturado em $FINAL_MD"

printf '%s\n' "$AXET_OUTPUT" > "$FINAL_MD"

if [[ ! -s "$FINAL_MD" ]]; then
  echo "Erro: relatório RAG final não foi gravado." >&2
  emit_log "ERROR" "geracao_markdown" "Relatório RAG final vazio após a geração."
  emit_step_end "geracao_markdown" "error" "$(( $(date +%s) - STEP3_START ))" "Relatório RAG final vazio."
  exit 1
fi

STEP3_DUR=$(( $(date +%s) - STEP3_START ))
echo "      -> Relatório final salvo em: $FINAL_MD"
emit_log "INFO" "geracao_markdown" "Relatório salvo com sucesso: $(basename "$FINAL_MD") (${STEP3_DUR}s)."
emit_step_end "geracao_markdown" "success" "$STEP3_DUR" "Relatório: $(basename "$FINAL_MD")"

stop_heartbeat
safe_cleanup_temp
CURRENT_STEP=""
PIPELINE_TOTAL_DUR=$(( $(date +%s) - PIPELINE_START_TS ))
emit_log "INFO" "" "Ingestão do documento '$BASENAME' concluída com sucesso em ${PIPELINE_TOTAL_DUR}s."
emit_run_end "success" "$PIPELINE_TOTAL_DUR"

echo "=============================================================="
echo "Relatório RAG salvo em: $FINAL_MD"
echo "=============================================================="
