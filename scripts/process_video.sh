#!/usr/bin/env bash
#
# process_video.sh
#
# Pipeline não-interativo para:
#   1. Extrair áudio de um vídeo (ffmpeg)
#   2. Transcrever o áudio (openai-whisper, modelo local)
#   3. Interpretar/humanizar a transcrição via axet-code (sem alucinações)
#   4. Gerar um relatório final em Markdown
#
# Telemetria (opcional):
#   Se houver um dashboard de telemetria rodando (dashboard/server.js),
#   este script envia eventos de progresso via HTTP POST para
#   http://localhost:$DASHBOARD_PORT/telemetry, permitindo acompanhar a
#   execução em tempo real no cockpit visual. Se o dashboard não estiver
#   ativo, os envios falham silenciosamente e o pipeline continua normal.
#
# Uso:
#   ./scripts/process_video.sh <caminho_do_video> [modelo_whisper] [idioma]
#
# Exemplos:
#   ./scripts/process_video.sh videos/aula.mp4
#   ./scripts/process_video.sh videos/aula.mp4 small pt
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Configuração / argumentos
# ---------------------------------------------------------------------------
VIDEO_PATH="${1:-}"
WHISPER_MODEL="${2:-small}"     # tiny, base, small, medium, large
LANGUAGE="${3:-es}"             # idioma padrão do pipeline (es = espanhol REEF/Mapfre, pt, en, etc.)

if [[ -z "$VIDEO_PATH" ]]; then
  echo "Uso: $0 <caminho_do_video> [modelo_whisper] [idioma]" >&2
  exit 1
fi

if [[ ! -f "$VIDEO_PATH" ]]; then
  echo "Erro: arquivo de vídeo não encontrado: $VIDEO_PATH" >&2
  exit 1
fi

# Diretório raiz do projeto (um nível acima de scripts/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

OUTPUT_DIR="${OUTPUT_DIR:-$ROOT_DIR/output}"
PROMPT_TEMPLATE="${PROMPT_TEMPLATE:-$ROOT_DIR/prompts/analise_transcricao_avancada.md}"

VENV_WHISPER="$ROOT_DIR/.venv/bin/whisper"
WHISPER_CPP_BIN="$(command -v whisper-cli 2>/dev/null || echo "/opt/homebrew/bin/whisper-cli")"
GGML_MODEL_DIR="$ROOT_DIR/models"

BASENAME="$(basename "$VIDEO_PATH")"
FILENAME_NOEXT="${BASENAME%.*}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

# Diretório de saída dedicado para este vídeo específico
# Se OUTPUT_DIR já terminar com o nome do vídeo, já é o diretório final dedicado passado pelo dashboard/servidor
if [[ "$OUTPUT_DIR" == *"/$FILENAME_NOEXT" || "$(basename "$OUTPUT_DIR")" == "$FILENAME_NOEXT" ]]; then
  VIDEO_OUTPUT_DIR="$OUTPUT_DIR"
else
  # Caso contrário (ex.: execução direta via CLI), espelha subpastas caso INPUT_DIR esteja definido
  if [[ -n "${INPUT_DIR:-}" && "$VIDEO_PATH" == "$INPUT_DIR"* ]]; then
    _REL_PATH="${VIDEO_PATH#$INPUT_DIR/}"
    _REL_DIR="$(dirname "$_REL_PATH")"
    if [[ "$_REL_DIR" != "." && -n "$_REL_DIR" && "$_REL_DIR" != "/" ]]; then
      if [[ "$OUTPUT_DIR" != *"$_REL_DIR"* ]]; then
        OUTPUT_DIR="$OUTPUT_DIR/$_REL_DIR"
      fi
    fi
  fi
  VIDEO_OUTPUT_DIR="$OUTPUT_DIR/$FILENAME_NOEXT"
fi

mkdir -p "$VIDEO_OUTPUT_DIR"
mkdir -p "$VIDEO_OUTPUT_DIR/logs"

AXET_MODEL_LABEL="${AXET_MODEL:-gpt-5.6-terra}"

# ---------------------------------------------------------------------------
# Telemetria: helpers
# ---------------------------------------------------------------------------
DASHBOARD_PORT="${DASHBOARD_PORT:-4545}"
TELEMETRY_URL="http://localhost:${DASHBOARD_PORT}/telemetry"
# RUN_ID inclui timestamp + PID do processo, garantindo unicidade mesmo
# quando o MESMO vídeo é processado em paralelo (ex: testando modelos
# diferentes ao mesmo tempo). Todos os arquivos intermediários usam este
# ID para evitar colisão/sobrescrita entre execuções concorrentes.
RUN_ID="run_${TIMESTAMP}_$$"

# ---------------------------------------------------------------------------
# Área Temporária de Trabalho Segura (/tmp/axet-workspace)
# Garante que vídeos e arquivos intermediários possam ser manipulados em /tmp
# e limpos imediatamente, mantendo o OneDrive 100% intocado.
# ---------------------------------------------------------------------------
TEMP_WORKSPACE="/tmp/axet-workspace/${RUN_ID}"
mkdir -p "$TEMP_WORKSPACE"

# Salvaguarda de Segurança Absoluta contra deleção acidental no OneDrive
assert_safe_path_for_deletion() {
  local target="$1"
  if [[ "$target" == *"OneDrive"* || "$target" == *"CloudStorage"* || "$target" != /tmp/* ]]; then
    echo "ERRO DE SEGURANÇA: Tentativa de remoção fora de /tmp detectada e bloqueada: $target" >&2
    emit_log "ERROR" "" "Tentativa de remoção fora de /tmp bloqueada por salvaguarda de segurança: $target"
    return 1
  fi
  return 0
}

safe_cleanup_temp() {
  if [[ -n "${TEMP_WORKSPACE:-}" && "$TEMP_WORKSPACE" == /tmp/axet-workspace/* && -d "$TEMP_WORKSPACE" ]]; then
    rm -rf "$TEMP_WORKSPACE" 2>/dev/null || true
  fi
}

AUDIO_PATH="$VIDEO_OUTPUT_DIR/${FILENAME_NOEXT}_${RUN_ID}_audio.wav"
TRANSCRIPT_TXT="$VIDEO_OUTPUT_DIR/${FILENAME_NOEXT}_${RUN_ID}.txt"
FINAL_MD="$VIDEO_OUTPUT_DIR/${FILENAME_NOEXT}_resumo_${RUN_ID}.md"

now_iso() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Envia um evento JSON para o dashboard. Falha silenciosamente se o
# dashboard não estiver rodando (não deve interromper o pipeline).
emit_telemetry() {
  local json_payload="$1"
  curl -s -m 2 -X POST "$TELEMETRY_URL" \
    -H "Content-Type: application/json" \
    -d "$json_payload" >/dev/null 2>&1 || true
}

emit_run_start() {
  emit_telemetry "$(cat <<EOF
{"type":"run_start","run_id":"$RUN_ID","ts":"$(now_iso)","video":"$BASENAME","whisper_model":"$WHISPER_MODEL","axet_model":"$AXET_MODEL_LABEL"}
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
  # escapa aspas duplas simples para não quebrar o JSON
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

emit_step_progress() {
  local step="$1"
  local pct="$2"
  emit_telemetry "$(cat <<EOF
{"type":"step_progress","run_id":"$RUN_ID","step":"$step","pct":$pct,"ts":"$(now_iso)"}
EOF
)"
}

# ---------------------------------------------------------------------------
# Heartbeat em background para evitar timeouts em etapas longas
# (carga do modelo Whisper na memória, inferência sob alta carga de CPU, etc.)
# ---------------------------------------------------------------------------
HEARTBEAT_PID=""

start_heartbeat() {
  stop_heartbeat
  (
    # Executa em background enquanto o processo pai ($$) estiver vivo
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

# Converte um timestamp no formato "MM:SS.mmm" ou "HH:MM:SS.mmm" (como
# impresso pelo whisper com --verbose True) para segundos inteiros.
# Usado apenas para calcular percentual de progresso (precisão de segundo
# é suficiente; frações de milissegundo são descartadas).
timestamp_to_seconds() {
  local ts="$1"
  local colon_count
  colon_count=$(awk -F':' '{print NF-1}' <<< "$ts")
  if [[ "$colon_count" -eq 1 ]]; then
    ts="00:$ts"
  fi
  awk -F'[:.]' '{ printf "%d", ($1*3600)+($2*60)+$3 }' <<< "$ts"
}

PIPELINE_START_TS=$(date +%s)
CANCELLED=0

# Trata cancelamento manual via SIGTERM (enviado pelo endpoint POST /cancel
# do dashboard). Marca a flag CANCELLED antes de deixar o `set -e`/trap EXIT
# tratar a saída, para que o run_end seja emitido com status "cancelled" em
# vez de "error".
on_sigterm_trap() {
  stop_heartbeat
  safe_cleanup_temp
  CANCELLED=1
  emit_log "WARN" "" "Pipeline recebeu sinal de cancelamento (SIGTERM). Área temporária limpa."
  exit 143
}
trap on_sigterm_trap TERM INT

# Garante que, em caso de erro em qualquer etapa, o run_end seja emitido
# como "error" (ou "cancelled", se cancelado manualmente) para o dashboard
# não ficar travado em "running".
on_error_trap() {
  local exit_code=$?
  stop_heartbeat
  safe_cleanup_temp
  if [[ $exit_code -ne 0 ]]; then
    local total_dur=$(( $(date +%s) - PIPELINE_START_TS ))
    if [[ "$CANCELLED" -eq 1 ]]; then
      emit_log "WARN" "" "Pipeline cancelado manualmente pelo usuário."
      emit_run_end "cancelled" "$total_dur"
    else
      emit_log "ERROR" "" "Pipeline finalizado com erro (exit code $exit_code)."
      emit_run_end "error" "$total_dur"
    fi
  fi
}
trap on_error_trap EXIT

echo "=============================================================="
echo " AXET Video Pipeline"
echo "=============================================================="
echo "Vídeo de entrada : $VIDEO_PATH"
echo "Modelo Whisper   : $WHISPER_MODEL"
echo "Idioma           : $LANGUAGE"
echo "Saída            : $VIDEO_OUTPUT_DIR"
echo "Run ID           : $RUN_ID"
echo "=============================================================="

emit_run_start
emit_run_pid "$$"
start_heartbeat
emit_log "INFO" "" "Pipeline iniciado para o vídeo '$BASENAME'."

# ---------------------------------------------------------------------------
# 1. Extração de áudio com ffmpeg
# ---------------------------------------------------------------------------
STEP1_START=$(date +%s)
echo
echo "[1/4] Extraindo áudio do vídeo com ffmpeg..."
emit_step_start "extracao_audio"
emit_log "INFO" "extracao_audio" "Iniciando extração de áudio com ffmpeg."

EFFECTIVE_VIDEO_PATH="$VIDEO_PATH"
IS_TMP_VIDEO=false

if [[ "${STAGE_VIDEO_TO_TMP:-false}" == "true" ]]; then
  TEMP_VIDEO_FILE="$TEMP_WORKSPACE/$BASENAME"
  emit_log "INFO" "extracao_audio" "Copiando vídeo para área temporária de trabalho (/tmp/axet-workspace)..."
  cp "$VIDEO_PATH" "$TEMP_VIDEO_FILE"
  EFFECTIVE_VIDEO_PATH="$TEMP_VIDEO_FILE"
  IS_TMP_VIDEO=true
fi

ffmpeg -y -nostdin -i "$EFFECTIVE_VIDEO_PATH" -vn -acodec pcm_s16le -ar 16000 -ac 1 "$AUDIO_PATH" \
  -loglevel error </dev/null

# OTIMIZAÇÃO CRÍTICA DE ARMAZENAMENTO:
# Se o vídeo foi processado a partir de área temporária /tmp, remove-o IMEDIATAMENTE
# após a extração do áudio pelo ffmpeg, reduzindo a pegada em disco de dezenas de GB para centenas de MB.
if [[ "$IS_TMP_VIDEO" == true && -f "$EFFECTIVE_VIDEO_PATH" ]]; then
  if assert_safe_path_for_deletion "$EFFECTIVE_VIDEO_PATH"; then
    rm -f "$EFFECTIVE_VIDEO_PATH"
    emit_log "INFO" "extracao_audio" "Vídeo temporário removido de /tmp. Espaço liberado imediatamente."
  fi
fi

STEP1_DUR=$(( $(date +%s) - STEP1_START ))
echo "      -> Áudio extraído: $AUDIO_PATH"
emit_log "INFO" "extracao_audio" "Áudio extraído com sucesso: $(basename "$AUDIO_PATH")."
emit_step_end "extracao_audio" "success" "$STEP1_DUR" "Áudio extraído: $(basename "$AUDIO_PATH")"

# ---------------------------------------------------------------------------
# 2. Transcrição com Whisper (modelo local, sem API externa)
# ---------------------------------------------------------------------------
STEP2_START=$(date +%s)
echo
emit_step_start "transcricao_whisper"

GGML_MODEL_FILE="$GGML_MODEL_DIR/ggml-${WHISPER_MODEL}.bin"
USE_WHISPER_CPP=false
if [[ -x "$WHISPER_CPP_BIN" && -f "$GGML_MODEL_FILE" ]]; then
  USE_WHISPER_CPP=true
fi

if [[ "$USE_WHISPER_CPP" == true ]]; then
  echo "[2/4] Transcrevendo áudio com whisper.cpp Metal acelerado (modelo: $WHISPER_MODEL)..."
  emit_log "INFO" "transcricao_whisper" "Motor ativo: whisper.cpp Nativo C++ com aceleração Metal (Apple M4 Pro). Modelo: ggml-${WHISPER_MODEL}.bin"
else
  echo "[2/4] Transcrevendo áudio com Whisper Python (modelo: $WHISPER_MODEL)..."
  emit_log "INFO" "transcricao_whisper" "Iniciando transcrição com Whisper Python (modelo: $WHISPER_MODEL, idioma: $LANGUAGE)."
  emit_log "INFO" "transcricao_whisper" "Carregando modelo Whisper '$WHISPER_MODEL' na memória..."
  if [[ ! -x "$VENV_WHISPER" ]]; then
    echo "Erro: nem whisper.cpp nem openai-whisper foram encontrados em $VENV_WHISPER" >&2
    emit_log "ERROR" "transcricao_whisper" "Nenhum motor Whisper encontrado."
    emit_step_end "transcricao_whisper" "error" 0 "Whisper não encontrado."
    exit 1
  fi
fi

# Duração total do áudio (em segundos), usada como denominador para
# calcular o percentual de progresso
AUDIO_DURATION_S="$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$AUDIO_PATH" 2>/dev/null || echo 0)"
AUDIO_DURATION_S="${AUDIO_DURATION_S%.*}"
if [[ -z "$AUDIO_DURATION_S" || "$AUDIO_DURATION_S" -le 0 ]]; then
  AUDIO_DURATION_S=1
fi

WHISPER_LOG="$VIDEO_OUTPUT_DIR/logs/${FILENAME_NOEXT}_${RUN_ID}_whisper.log"
WHISPER_EXIT_CODE=0

set +e
if [[ "$USE_WHISPER_CPP" == true ]]; then
  WHISPER_CMD=(
    "$WHISPER_CPP_BIN"
    -m "$GGML_MODEL_FILE"
    -f "$AUDIO_PATH"
    -t 4
    --flash-attn
    -pp
    --suppress-nst
    -mc 256
    -otxt
    -of "${TRANSCRIPT_TXT%.txt}"
  )
  WHISPER_LANG_RESOLVED="$LANGUAGE"
  if [[ -z "$WHISPER_LANG_RESOLVED" || "$WHISPER_LANG_RESOLVED" == "auto" || "$WHISPER_LANG_RESOLVED" == "None" ]]; then
    WHISPER_LANG_RESOLVED="es"
  fi
  WHISPER_CMD+=(-l "$WHISPER_LANG_RESOLVED")

  "${WHISPER_CMD[@]}" 2>&1 | tee "$WHISPER_LOG" | while IFS= read -r line; do
    if [[ "$line" =~ progress\ =\ *([0-9]+)% ]]; then
      pct="${BASH_REMATCH[1]}"
      emit_step_progress "transcricao_whisper" "$pct"
    else
      end_ts="$(grep -oE '\--> *[0-9]{2}:[0-9]{2}(:[0-9]{2})?\.[0-9]{3}' <<< "$line" | sed -E 's/--> *//' | head -n1)"
      if [[ -n "$end_ts" ]]; then
        end_s="$(timestamp_to_seconds "$end_ts")"
        if [[ -n "$end_s" && "$AUDIO_DURATION_S" -gt 0 ]]; then
          pct=$(( end_s * 100 / AUDIO_DURATION_S ))
          [[ $pct -gt 100 ]] && pct=100
          emit_step_progress "transcricao_whisper" "$pct"
        fi
      fi
    fi
  done
  WHISPER_EXIT_CODE=${PIPESTATUS[0]:-0}

else
  WHISPER_CMD=(
    "$VENV_WHISPER"
    "$AUDIO_PATH"
    --model "$WHISPER_MODEL"
  )
  if [[ -n "$LANGUAGE" && "$LANGUAGE" != "auto" && "$LANGUAGE" != "None" ]]; then
    WHISPER_CMD+=(--language "$LANGUAGE")
  fi
  WHISPER_CMD+=(
    --task transcribe
    --output_format txt
    --output_dir "$VIDEO_OUTPUT_DIR"
    --fp16 False
    --condition_on_previous_text False
    --no_speech_threshold 0.6
    --verbose True
  )

  export OMP_NUM_THREADS=4
  PYTHONUNBUFFERED=1 "${WHISPER_CMD[@]}" 2>&1 | tee "$WHISPER_LOG" | while IFS= read -r line; do
    end_ts="$(grep -oE '\--> *[0-9]{2}:[0-9]{2}(:[0-9]{2})?\.[0-9]{3}' <<< "$line" | sed -E 's/--> *//' | head -n1)"
    if [[ -n "$end_ts" ]]; then
      end_s="$(timestamp_to_seconds "$end_ts")"
      if [[ -n "$end_s" ]]; then
        pct=$(( end_s * 100 / AUDIO_DURATION_S ))
        [[ $pct -gt 100 ]] && pct=100
        emit_step_progress "transcricao_whisper" "$pct"
      fi
    fi
  done
  WHISPER_EXIT_CODE=${PIPESTATUS[0]:-0}
fi
set -e

if [[ "$WHISPER_EXIT_CODE" -ne 0 ]]; then
  echo "Erro: whisper terminou com código $WHISPER_EXIT_CODE." >&2
  if [[ -f "$WHISPER_LOG" ]]; then
    tail -n 15 "$WHISPER_LOG" >&2 || true
  fi
  emit_log "ERROR" "transcricao_whisper" "Whisper terminou com código $WHISPER_EXIT_CODE."
  emit_step_end "transcricao_whisper" "error" 0 "Whisper falhou (exit $WHISPER_EXIT_CODE)."
  exit "$WHISPER_EXIT_CODE"
fi
rm -f "$WHISPER_LOG"

# O whisper Python gera com sufixo _audio.txt; movemos se necessário
GENERATED_TXT="$VIDEO_OUTPUT_DIR/${FILENAME_NOEXT}_${RUN_ID}_audio.txt"
if [[ -f "$GENERATED_TXT" ]]; then
  mv "$GENERATED_TXT" "$TRANSCRIPT_TXT"
fi

if [[ ! -f "$TRANSCRIPT_TXT" ]]; then
  echo "Erro: transcrição não foi gerada." >&2
  emit_log "ERROR" "transcricao_whisper" "Arquivo de transcrição não foi gerado."
  emit_step_end "transcricao_whisper" "error" 0 "Transcrição não gerada."
  exit 1
fi

# Sanitização: remove linhas residuais que contenham apenas [BLANK_AUDIO]
TMP_CLEAN="$(mktemp -t transcript_clean_XXXXXX.txt)"
grep -v -E "^\s*\[BLANK_AUDIO\]\s*$" "$TRANSCRIPT_TXT" > "$TMP_CLEAN" || true
if [[ -s "$TMP_CLEAN" ]]; then
  mv "$TMP_CLEAN" "$TRANSCRIPT_TXT"
else
  rm -f "$TMP_CLEAN"
fi

STEP2_DUR=$(( $(date +%s) - STEP2_START ))
echo "      -> Transcrição gerada: $TRANSCRIPT_TXT"
emit_log "INFO" "transcricao_whisper" "Transcrição gerada com sucesso: $(basename "$TRANSCRIPT_TXT")."
emit_step_end "transcricao_whisper" "success" "$STEP2_DUR" "Transcrição: $(basename "$TRANSCRIPT_TXT")"

# ---------------------------------------------------------------------------
# 3. Interpretação/Análise Avançada via axet-code (anti-alucinação)
# ---------------------------------------------------------------------------
STEP3_START=$(date +%s)
echo
echo "[3/4] Interpretando a transcrição com axet-code (modelo: $AXET_MODEL_LABEL)..."
emit_step_start "interpretacao_axet"
emit_log "INFO" "interpretacao_axet" "Iniciando análise avançada com axet-code (modelo: $AXET_MODEL_LABEL)."

PROMPT_FILE="$(mktemp -t axet_prompt_XXXXXX.txt)"

if [[ -f "$PROMPT_TEMPLATE" ]]; then
  emit_log "INFO" "interpretacao_axet" "Montando prompt avançado com template: $(basename "$PROMPT_TEMPLATE")."
  python3 - "$PROMPT_TEMPLATE" "$TRANSCRIPT_TXT" "$PROMPT_FILE" <<'PYEOF'
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
else
  emit_log "WARN" "interpretacao_axet" "Template de prompt não encontrado em $PROMPT_TEMPLATE. Usando template básico."
  TRANSCRIPT_CONTENT="$(cat "$TRANSCRIPT_TXT")"
  cat > "$PROMPT_FILE" <<PROMPT_EOF
Você é um especialista sênior em análise de transcrições, documentação funcional, arquitetura de sistemas e processos de negócio.
Sua tarefa é analisar profundamente a transcrição e produzir um documento estruturado completo sem alucinações.

---
TRANSCRIÇÃO ORIGINAL:
$TRANSCRIPT_CONTENT
PROMPT_EOF
fi

PROMPT_SIZE=$(wc -c < "$PROMPT_FILE" | tr -d ' ')
emit_log "INFO" "interpretacao_axet" "Enviando prompt (${PROMPT_SIZE} bytes) para axet-code (modelo: $AXET_MODEL_LABEL)..."

AXET_CMD=(axet-code run --quiet)
if [[ -n "${AXET_MODEL:-}" && "$AXET_MODEL" != "default" && "$AXET_MODEL" != "auto" ]]; then
  AXET_CMD+=(-m "$AXET_MODEL")
fi

AXET_ERR_FILE="$(mktemp -t axet_err_XXXXXX.txt)"
if ! AXET_OUTPUT="$(cat "$PROMPT_FILE" | "${AXET_CMD[@]}" 2>"$AXET_ERR_FILE")"; then
  echo "Erro: axet-code encerrou com falha." >&2
  if [[ -f "$AXET_ERR_FILE" ]]; then
    tail -n 20 "$AXET_ERR_FILE" >&2 || true
  fi
  emit_log "ERROR" "interpretacao_axet" "Falha na chamada ao axet-code (modelo: $AXET_MODEL_LABEL)."
  emit_step_end "interpretacao_axet" "error" 0 "axet-code falhou."
  rm -f "$PROMPT_FILE" "$AXET_ERR_FILE"
  exit 1
fi
rm -f "$PROMPT_FILE" "$AXET_ERR_FILE"

if [[ -z "$AXET_OUTPUT" ]]; then
  echo "Erro: axet-code não retornou conteúdo." >&2
  emit_log "ERROR" "interpretacao_axet" "axet-code não retornou conteúdo."
  emit_step_end "interpretacao_axet" "error" 0 "axet-code sem retorno."
  exit 1
fi

STEP3_DUR=$(( $(date +%s) - STEP3_START ))
echo "      -> Análise avançada gerada pelo axet-code (${STEP3_DUR}s)."
emit_log "INFO" "interpretacao_axet" "Análise avançada gerada com sucesso pelo axet-code."
emit_step_end "interpretacao_axet" "success" "$STEP3_DUR" "Análise avançada concluída."

# ---------------------------------------------------------------------------
# 4. Montagem do Markdown final
# ---------------------------------------------------------------------------
STEP4_START=$(date +%s)
echo
echo "[4/4] Montando o relatório final em Markdown..."
emit_step_start "geracao_markdown"
emit_log "INFO" "geracao_markdown" "Montando relatório final em Markdown."

{
  echo "# Relatório de Análise Avançada de Transcrição"
  echo
  echo "**Arquivo de origem:** \`$BASENAME\`"
  echo "**Data de processamento:** $(date '+%d/%m/%Y %H:%M:%S')"
  if [[ "$USE_WHISPER_CPP" == true ]]; then
    echo "**Modelo de transcrição:** whisper.cpp Metal ($WHISPER_MODEL) — idioma: ${LANGUAGE:-auto}"
  else
    echo "**Modelo de transcrição:** Whisper Python ($WHISPER_MODEL) — idioma: ${LANGUAGE:-auto}"
  fi
  echo "**Modelo de interpretação IA:** axet-code ($AXET_MODEL_LABEL)"
  echo "**Prompt utilizado:** análise sênior avançada (documentação funcional, arquitetura, negócio, riscos, Q&A, anti-alucinação)"
  echo
  echo "---"
  echo
  echo "$AXET_OUTPUT"
} > "$FINAL_MD"

# Validação explícita de integridade do relatório Markdown gerado
FINAL_MD_SIZE="$(wc -c < "$FINAL_MD" 2>/dev/null || echo 0)"
if [[ ! -s "$FINAL_MD" || "$FINAL_MD_SIZE" -lt 150 ]]; then
  echo "Erro: O relatório Markdown não passou na validação de integridade (< 150 bytes: $FINAL_MD_SIZE bytes)." >&2
  emit_log "ERROR" "geracao_markdown" "Falha na validação do relatório Markdown (conteúdo vazio ou menor que 150 bytes)."
  emit_step_end "geracao_markdown" "error" 0 "Falha na validação do relatório."
  safe_cleanup_temp
  exit 1
fi

STEP4_DUR=$(( $(date +%s) - STEP4_START ))
echo "      -> Relatório final salvo em: $FINAL_MD (validado: ${FINAL_MD_SIZE} bytes)"
emit_log "INFO" "geracao_markdown" "Relatório final validado e salvo com sucesso: $(basename "$FINAL_MD")."
emit_step_end "geracao_markdown" "success" "$STEP4_DUR" "Relatório: $(basename "$FINAL_MD")"

# Limpeza garantida da área temporária de trabalho (/tmp/axet-workspace)
safe_cleanup_temp

stop_heartbeat
PIPELINE_TOTAL_DUR=$(( $(date +%s) - PIPELINE_START_TS ))
emit_log "INFO" "" "Pipeline concluído com sucesso em ${PIPELINE_TOTAL_DUR}s. Área temporária liberada."
emit_run_end "success" "$PIPELINE_TOTAL_DUR"

echo
echo "=============================================================="
echo " Pipeline concluído com sucesso!"
echo " Resultado: $FINAL_MD"
echo "=============================================================="
