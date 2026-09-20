/**
 * dashboard/app.js
 *
 * Cliente do cockpit: conecta via SSE em /events, carrega snapshot inicial
 * em /state, e renderiza em tempo real:
 *   - N cards de execuções ATIVAS simultaneamente (multi-run), cada um com
 *     seu próprio status, etapas, barra de progresso e log stream.
 *   - histórico de execuções (ativas + finalizadas)
 *
 * NOTA IMPORTANTE (fix de bug):
 *   A versão anterior usava uma única variável global `currentRunId` que
 *   era sobrescrita a cada evento recebido (run_start, step_start, log...).
 *   Isso fazia a UI "pular" de uma execução para outra quando dois ou mais
 *   pipelines rodavam em paralelo (ex: mesmo vídeo com modelos diferentes),
 *   pois o painel único sempre mostrava apenas o run do ÚLTIMO evento
 *   recebido, escondendo o progresso das demais execuções em andamento.
 *
 *   A correção troca o painel único por uma GRADE de cards, um por run
 *   ativo (status === 'running'), renderizados e atualizados de forma
 *   independente. Não há mais uma variável "run atual": cada evento
 *   atualiza APENAS o card do seu próprio run_id.
 */

const STEP_ORDER = [
  "extracao_audio",
  "transcricao_whisper",
  "interpretacao_axet",
  "geracao_markdown",
];

const STEP_LABELS = {
  extracao_audio: "Extração de Áudio",
  transcricao_whisper: "Transcrição (Whisper)",
  interpretacao_axet: "Interpretação (axet-code)",
  geracao_markdown: "Geração do Markdown",
};

const STEP_SHORT_NAMES = {
  extracao_audio: "Áudio",
  transcricao_whisper: "Whisper",
  interpretacao_axet: "Axet",
  geracao_markdown: "Relatório",
};

const STEP_DESCRIPTIONS = {
  extracao_audio: "Extração do stream de áudio PCM 16kHz mono via ffmpeg",
  transcricao_whisper: "Processamento acústico/temporal linha a linha via Whisper",
  interpretacao_axet: "Síntese humanizada e estruturação funcional via axet-code",
  geracao_markdown: "Montagem do documento executivo final em Markdown com evidências",
};

const expandedHistoryRows = new Set();

const MAX_LOG_LINES_DOM = 200; // por card, para não pesar o DOM
const FINISHED_CARD_LINGER_MS = 5000; // tempo que um card finalizado fica visível antes de sair da grade

const $ = (id) => document.getElementById(id);

const activeRunsGrid = $("active-runs-grid");
const activeRunsEmpty = $("active-runs-empty");
const activeCountEl = $("active-count");
const historyBody = $("history-body");
const connDot = $("conn-dot");
const connStatus = $("conn-status");

// allRuns: run_id -> run object (estado completo, espelha o servidor)
// runOrderList: ordem de chegada dos run_ids (para o histórico)
let allRuns = {};
let runOrderList = [];

// Mantém referência aos elementos DOM já criados por run_id, para evitar
// recriar o card inteiro a cada evento (apenas atualizamos partes dele).
const runCardEls = {}; // run_id -> { root, stepsEl, progressBarEl, logStreamEl, statusEl, ... }

const lingerTimers = {}; // run_id -> timeoutId

// ---------------------------------------------------------------------------
// Helpers de formatação
// ---------------------------------------------------------------------------

function statusLabel(status) {
  switch (status) {
    case "running": return "em andamento...";
    case "success": return "concluído";
    case "error": return "falhou";
    case "cancelled": return "cancelado";
    default: return "pendente";
  }
}

function statusLabelRun(status) {
  switch (status) {
    case "running": return "em execução";
    case "success": return "concluído";
    case "error": return "erro";
    case "cancelled": return "cancelado";
    default: return "aguardando";
  }
}

function formatDuration(seconds) {
  if (seconds == null) return "—";
  const s = Math.round(seconds);
  const m = Math.floor(s / 60);
  const rem = s % 60;
  if (m > 0) return `${m}m ${rem}s`;
  return `${rem}s`;
}

function formatTime(isoStr) {
  if (!isoStr) return "—";
  try {
    const d = new Date(isoStr);
    if (isNaN(d.getTime())) return "—";
    return d.toLocaleTimeString("pt-BR", { hour: "2-digit", minute: "2-digit", second: "2-digit" });
  } catch (_) {
    return "—";
  }
}

function formatDateTime(isoStr) {
  if (!isoStr) return "—";
  try {
    const d = new Date(isoStr);
    if (isNaN(d.getTime())) return "—";
    return d.toLocaleString("pt-BR", {
      day: "2-digit",
      month: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
    });
  } catch (_) {
    return "—";
  }
}

function escapeHtml(str) {
  const div = document.createElement("div");
  div.textContent = str;
  return div.innerHTML;
}

// ---------------------------------------------------------------------------
// Criação / atualização de cards de execução ATIVA
// ---------------------------------------------------------------------------

function createRunCard(runId) {
  const root = document.createElement("div");
  root.className = "run-card";
  root.dataset.runId = runId;

  root.innerHTML = `
    <div class="run-card-header">
      <div class="run-card-title">
        <span class="run-card-id">${escapeHtml(runId)}</span>
        <div class="run-card-title-actions">
          <span class="value status-pill running" data-role="status">em execução</span>
          <button type="button" class="btn-cancel" data-role="cancel-btn" title="Cancelar execução">Cancelar</button>
        </div>
      </div>
      <div class="run-card-meta">
        <span class="meta-item"><span class="meta-lbl">Vídeo:</span> <strong data-role="video">—</strong></span> ·
        <span class="meta-item"><span class="meta-lbl">Whisper:</span> <strong data-role="whisper">—</strong></span> ·
        <span class="meta-item"><span class="meta-lbl">axet-code:</span> <strong data-role="axet">—</strong></span> ·
        <span class="meta-item"><span class="meta-lbl">Início:</span> <strong data-role="started">—</strong></span> ·
        <span class="meta-item"><span class="meta-lbl">Fim:</span> <strong data-role="finished">—</strong></span> ·
        <span class="meta-item"><span class="meta-lbl">Duração:</span> <strong data-role="duration" class="meta-dur">—</strong></span>
      </div>
    </div>

    <div class="progress-bar-wrap">
      <div class="progress-bar" data-role="progress-bar"></div>
    </div>

    <div class="steps" data-role="steps"></div>

    <div class="panel logs-panel run-card-logs">
      <div class="panel-header">Log em tempo real</div>
      <div class="log-stream" data-role="log-stream"></div>
    </div>
  `;

  const els = {
    root,
    statusEl: root.querySelector('[data-role="status"]'),
    videoEl: root.querySelector('[data-role="video"]'),
    whisperEl: root.querySelector('[data-role="whisper"]'),
    axetEl: root.querySelector('[data-role="axet"]'),
    startedEl: root.querySelector('[data-role="started"]'),
    finishedEl: root.querySelector('[data-role="finished"]'),
    durationEl: root.querySelector('[data-role="duration"]'),
    progressBarEl: root.querySelector('[data-role="progress-bar"]'),
    stepsEl: root.querySelector('[data-role="steps"]'),
    logStreamEl: root.querySelector('[data-role="log-stream"]'),
    cancelBtnEl: root.querySelector('[data-role="cancel-btn"]'),
  };

  els.cancelBtnEl.addEventListener("click", () => cancelRun(runId));

  runCardEls[runId] = els;

  renderStepCardsForRun(runId);

  return root;
}

// Envia a solicitação de cancelamento manual para o backend (POST /cancel),
// que por sua vez envia SIGTERM para o PID do processo Bash do pipeline.
async function cancelRun(runId) {
  const els = runCardEls[runId];
  if (els && els.cancelBtnEl) {
    els.cancelBtnEl.disabled = true;
    els.cancelBtnEl.textContent = "Cancelando...";
  }
  try {
    const res = await fetch("/cancel/" + encodeURIComponent(runId), {
      method: "POST",
    });
    if (!res.ok) {
      const data = await res.json().catch(() => ({}));
      console.error("Falha ao cancelar run:", data.error || res.statusText);
      if (els && els.cancelBtnEl) {
        els.cancelBtnEl.disabled = false;
        els.cancelBtnEl.textContent = "Cancelar";
      }
    }
  } catch (e) {
    console.error("Erro de rede ao cancelar run:", e);
    if (els && els.cancelBtnEl) {
      els.cancelBtnEl.disabled = false;
      els.cancelBtnEl.textContent = "Cancelar";
    }
  }
}

function ensureRunCard(runId) {
  if (!runCardEls[runId]) {
    const card = createRunCard(runId);
    activeRunsGrid.appendChild(card);
    renderRunCardInfo(runId);
    renderInitialLogsForRun(runId);
  }
  return runCardEls[runId];
}

function removeRunCard(runId) {
  const els = runCardEls[runId];
  if (els && els.root && els.root.parentNode) {
    els.root.parentNode.removeChild(els.root);
  }
  delete runCardEls[runId];
  renderActiveRunsEmptyState();
}

function renderActiveRunsEmptyState() {
  const hasActiveCards = Object.keys(runCardEls).length > 0;
  activeRunsEmpty.style.display = hasActiveCards ? "none" : "block";
  activeCountEl.textContent = String(Object.keys(runCardEls).length);
}

function renderStepCardsForRun(runId) {
  const els = runCardEls[runId];
  if (!els) return;
  const run = allRuns[runId];

  els.stepsEl.innerHTML = "";

  STEP_ORDER.forEach((stepKey, idx) => {
    const stepData = run && run.steps ? run.steps[stepKey] : null;
    const status = stepData ? stepData.status : "pending";

    const card = document.createElement("div");
    card.className = `step-card ${status}`;

    // 1. Cabeçalho da etapa com número, nome e tag de status
    const topRow = document.createElement("div");
    topRow.className = "step-card-top";

    const name = document.createElement("div");
    name.className = "step-name";
    name.textContent = `Passo ${idx + 1}/4 · ${STEP_LABELS[stepKey] || stepKey}`;
    topRow.appendChild(name);

    const statusBadge = document.createElement("span");
    statusBadge.className = `step-status-tag ${status}`;
    statusBadge.textContent = statusLabel(status);
    topRow.appendChild(statusBadge);
    card.appendChild(topRow);

    // 2. Horários de início e fim e duração
    const timingRow = document.createElement("div");
    timingRow.className = "step-timing-row";

    const startStr = stepData && stepData.started_at ? formatTime(stepData.started_at) : "—";
    const endStr = stepData && stepData.finished_at
      ? formatTime(stepData.finished_at)
      : (status === "running" ? "em andamento..." : "—");

    let durStr = "";
    if (stepData && stepData.duration_s != null) {
      durStr = formatDuration(stepData.duration_s);
    } else if (status === "running" && stepData && stepData.started_at) {
      const elap = Math.max(0, (Date.now() - new Date(stepData.started_at).getTime()) / 1000);
      durStr = formatDuration(elap);
    }

    timingRow.innerHTML = `
      <span class="timing-item" title="Hora de início da etapa"><span class="timing-lbl">Início:</span> <strong>${startStr}</strong></span>
      <span class="timing-sep">·</span>
      <span class="timing-item" title="Hora de término da etapa"><span class="timing-lbl">Fim:</span> <strong>${endStr}</strong></span>
      ${durStr ? `<span class="timing-sep">·</span><span class="timing-dur" title="Duração da etapa">⏱ <strong>${durStr}</strong></span>` : ""}
    `;
    card.appendChild(timingRow);

    // 3. Detalhes técnicos do passo
    const detail = document.createElement("div");
    detail.className = "step-detail";
    const detailText = stepData && stepData.detalhes
      ? stepData.detalhes
      : (STEP_DESCRIPTIONS[stepKey] || statusLabel(status));
    detail.textContent = detailText;
    card.appendChild(detail);

    // 4. Sub-barra de progresso do step ativo (running)
    if (status === "running") {
      const progWrap = document.createElement("div");
      progWrap.className = "step-progress-wrap";
      progWrap.dataset.step = stepKey;

      const progFill = document.createElement("div");
      progFill.className = "step-progress-fill";
      const initialPct = stepData && stepData.progress_pct != null ? stepData.progress_pct : 0;
      progFill.style.width = `${Math.max(0, Math.min(100, initialPct))}%`;
      progWrap.appendChild(progFill);

      const progLabel = document.createElement("div");
      progLabel.className = "step-progress-label";
      progLabel.dataset.role = "step-progress-label";
      progLabel.textContent = `${Math.round(initialPct)}%`;
      progWrap.appendChild(progLabel);

      card.appendChild(progWrap);
    }

    els.stepsEl.appendChild(card);
  });

  updateProgressBarForRun(runId);
}

// Atualiza apenas a sub-barra de progresso (fill + label) de um step já
// renderizado no DOM, sem recriar todos os step-cards do run — evita
// flicker e é chamada a cada evento "step_progress" (potencialmente
// muitos eventos por segundo durante a transcrição do whisper).
function updateStepProgressUI(runId, stepKey) {
  const els = runCardEls[runId];
  if (!els) return;
  const run = allRuns[runId];
  if (!run || !run.steps || !run.steps[stepKey]) return;

  const stepData = run.steps[stepKey];
  const progWrap = els.stepsEl.querySelector(`.step-progress-wrap[data-step="${stepKey}"]`);
  if (!progWrap) {
    // Sub-barra ainda não existe no DOM (ex.: o evento "step_progress"
    // chegou antes do card ter sido re-renderizado pelo "step_start") —
    // força a reconstrução completa dos step-cards para criá-la.
    renderStepCardsForRun(runId);
    return;
  }

  const pct = Math.max(0, Math.min(100, stepData.progress_pct != null ? stepData.progress_pct : 0));
  const fillEl = progWrap.querySelector(".step-progress-fill");
  const labelEl = progWrap.querySelector('[data-role="step-progress-label"]');
  if (fillEl) fillEl.style.width = `${pct}%`;
  if (labelEl) labelEl.textContent = `${Math.round(pct)}%`;
}

function updateProgressBarForRun(runId) {
  const els = runCardEls[runId];
  if (!els) return;
  const run = allRuns[runId];

  if (!run) {
    els.progressBarEl.style.width = "0%";
    return;
  }
  const total = STEP_ORDER.length;
  let done = 0;
  STEP_ORDER.forEach((k) => {
    const s = run.steps && run.steps[k];
    if (s && (s.status === "success" || s.status === "error")) done++;
  });
  const pct = Math.round((done / total) * 100);
  els.progressBarEl.style.width = `${pct}%`;
}

function renderRunCardInfo(runId) {
  const els = runCardEls[runId];
  if (!els) return;
  const run = allRuns[runId];
  if (!run) return;

  els.videoEl.textContent = run.video || "—";
  els.whisperEl.textContent = run.whisper_model || "—";
  els.axetEl.textContent = run.axet_model || "—";

  els.statusEl.textContent = statusLabelRun(run.status);
  els.statusEl.className = `value status-pill ${run.status}`;

  if (els.cancelBtnEl) {
    els.cancelBtnEl.style.display = run.status === "running" ? "inline-block" : "none";
  }

  if (els.startedEl) {
    els.startedEl.textContent = run.started_at ? formatTime(run.started_at) : "—";
  }
  if (els.finishedEl) {
    els.finishedEl.textContent = run.finished_at ? formatTime(run.finished_at) : (run.status === "running" ? "em execução..." : "—");
  }

  if (run.duration_total_s != null) {
    els.durationEl.textContent = formatDuration(run.duration_total_s);
  } else if (run.started_at) {
    const elapsed = Math.max(0, (Date.now() - new Date(run.started_at).getTime()) / 1000);
    els.durationEl.textContent = `${formatDuration(elapsed)} (em execução...)`;
  } else {
    els.durationEl.textContent = "—";
  }
}

function appendLogLineToRun(runId, entry) {
  const els = runCardEls[runId];
  if (!els) return;

  const line = document.createElement("div");
  line.className = `log-line level-${entry.level || "INFO"}`;

  const time = new Date(entry.ts || Date.now()).toLocaleTimeString("pt-BR");
  const stepTag = entry.step ? `[${STEP_LABELS[entry.step] || entry.step}] ` : "";

  line.innerHTML = `<span class="ts">${time}</span> <span class="lvl">${entry.level || "INFO"}</span> ${stepTag}${escapeHtml(entry.message || "")}`;

  els.logStreamEl.appendChild(line);
  els.logStreamEl.scrollTop = els.logStreamEl.scrollHeight;

  while (els.logStreamEl.children.length > MAX_LOG_LINES_DOM) {
    els.logStreamEl.removeChild(els.logStreamEl.firstChild);
  }
}

function renderInitialLogsForRun(runId) {
  const els = runCardEls[runId];
  const run = allRuns[runId];
  if (!els || !run) return;
  els.logStreamEl.innerHTML = "";
  if (Array.isArray(run.logs)) {
    run.logs.forEach((entry) => appendLogLineToRun(runId, entry));
  }
}

// Reavalia quais runs devem ter card ativo na grid: todo run com
// status === 'running' recebe um card; ao finalizar (success/error), o
// card permanece visível por FINISHED_CARD_LINGER_MS para o usuário ver
// o resultado, depois é removido da grade (o run continua no histórico).
function syncActiveRunCards() {
  Object.keys(allRuns).forEach((runId) => {
    const run = allRuns[runId];
    if (run.status === "running") {
      ensureRunCard(runId);
      if (lingerTimers[runId]) {
        clearTimeout(lingerTimers[runId]);
        delete lingerTimers[runId];
      }
    } else if (run.status === "success" || run.status === "error" || run.status === "cancelled") {
      if (runCardEls[runId] && !lingerTimers[runId]) {
        lingerTimers[runId] = setTimeout(() => {
          removeRunCard(runId);
          delete lingerTimers[runId];
        }, FINISHED_CARD_LINGER_MS);
      }
    }
  });
  renderActiveRunsEmptyState();
}

// ---------------------------------------------------------------------------
// Histórico de execuções
// ---------------------------------------------------------------------------

function toggleHistoryDetails(runId) {
  if (expandedHistoryRows.has(runId)) {
    expandedHistoryRows.delete(runId);
  } else {
    expandedHistoryRows.add(runId);
  }
  renderHistory();
}

function renderHistory() {
  if (!historyBody) return;
  historyBody.innerHTML = "";

  const historyList = runOrderList.filter((id) => allRuns[id] && allRuns[id].status !== "running");
  const historyCountBadge = $("history-count");
  if (historyCountBadge) {
    historyCountBadge.textContent = String(historyList.length);
  }

  // ordem mais recente primeiro
  const ids = [...runOrderList].reverse();

  ids.forEach((runId) => {
    const run = allRuns[runId];
    if (!run) return;

    const tr = document.createElement("tr");
    tr.className = "history-main-row";

    const tdId = document.createElement("td");
    tdId.innerHTML = `<span class="run-id-cell" title="${escapeHtml(runId)}">${escapeHtml(runId)}</span>`;
    tr.appendChild(tdId);

    const tdVideo = document.createElement("td");
    tdVideo.textContent = run.video || "—";
    tdVideo.title = run.video || "";
    tr.appendChild(tdVideo);

    const tdStatus = document.createElement("td");
    const pill = document.createElement("span");
    pill.className = `status-pill ${run.status}`;
    pill.textContent = statusLabelRun(run.status);
    tdStatus.appendChild(pill);
    tr.appendChild(tdStatus);

    const tdDuration = document.createElement("td");
    tdDuration.textContent = run.duration_total_s != null ? formatDuration(run.duration_total_s) : "—";
    tr.appendChild(tdDuration);

    const tdStarted = document.createElement("td");
    tdStarted.textContent = run.started_at ? formatDateTime(run.started_at) : "—";
    tr.appendChild(tdStarted);

    const tdFinished = document.createElement("td");
    tdFinished.textContent = run.finished_at
      ? formatDateTime(run.finished_at)
      : (run.status === "running" ? "em execução..." : "—");
    tr.appendChild(tdFinished);

    // Badges das 4 etapas
    const tdSteps = document.createElement("td");
    tdSteps.className = "history-steps-cell";
    STEP_ORDER.forEach((stepKey, idx) => {
      const stepData = run.steps ? run.steps[stepKey] : null;
      const stepStatus = stepData ? stepData.status : "pending";
      const badge = document.createElement("span");
      badge.className = `step-badge ${stepStatus}`;
      const durText = stepData && stepData.duration_s != null ? formatDuration(stepData.duration_s) : "";
      badge.textContent = `${idx + 1}. ${STEP_SHORT_NAMES[stepKey] || stepKey}${durText ? ` (${durText})` : ""}`;

      const sStart = stepData && stepData.started_at ? formatTime(stepData.started_at) : "—";
      const sEnd = stepData && stepData.finished_at ? formatTime(stepData.finished_at) : "—";
      const sDet = stepData && stepData.detalhes ? stepData.detalhes : "";
      badge.title = `Passo ${idx + 1}/4 · ${STEP_LABELS[stepKey] || stepKey}\nStatus: ${statusLabel(stepStatus)}\nInício: ${sStart}\nFim: ${sEnd}${durText ? `\nDuração: ${durText}` : ""}${sDet ? `\nDetalhes: ${sDet}` : ""}`;

      tdSteps.appendChild(badge);
    });
    tr.appendChild(tdSteps);

    // Botão de expandir detalhes dos passos
    const tdAction = document.createElement("td");
    const isExpanded = expandedHistoryRows.has(runId);
    const btn = document.createElement("button");
    btn.type = "button";
    btn.className = `btn-toggle-details ${isExpanded ? "active" : ""}`;
    btn.innerHTML = isExpanded ? "Ocultar ▲" : "Passos ▼";
    btn.addEventListener("click", () => toggleHistoryDetails(runId));
    tdAction.appendChild(btn);
    tr.appendChild(tdAction);

    historyBody.appendChild(tr);

    // Linha expandida com os 4 passos detalhados
    if (isExpanded) {
      const trDetails = document.createElement("tr");
      trDetails.className = "history-details-row";
      const tdCol = document.createElement("td");
      tdCol.colSpan = 8;

      const grid = document.createElement("div");
      grid.className = "history-steps-expanded-grid";

      STEP_ORDER.forEach((stepKey, idx) => {
        const stepData = run.steps ? run.steps[stepKey] : null;
        const stepStatus = stepData ? stepData.status : "pending";
        const stepCard = document.createElement("div");
        stepCard.className = `history-step-card ${stepStatus}`;

        const sStart = stepData && stepData.started_at ? formatTime(stepData.started_at) : "—";
        const sEnd = stepData && stepData.finished_at ? formatTime(stepData.finished_at) : (stepStatus === "running" ? "em andamento..." : "—");
        const durText = stepData && stepData.duration_s != null ? formatDuration(stepData.duration_s) : "—";
        const detText = stepData && stepData.detalhes ? stepData.detalhes : (STEP_DESCRIPTIONS[stepKey] || "—");

        stepCard.innerHTML = `
          <div class="h-step-top">
            <span class="h-step-num">Passo ${idx + 1}/4</span>
            <span class="step-status-tag ${stepStatus}">${statusLabel(stepStatus)}</span>
          </div>
          <div class="h-step-name">${STEP_LABELS[stepKey] || stepKey}</div>
          <div class="h-step-timing">
            <div><span class="timing-lbl">Início:</span> <strong>${sStart}</strong></div>
            <div><span class="timing-lbl">Fim:</span> <strong>${sEnd}</strong></div>
            <div><span class="timing-lbl">Duração:</span> <strong>⏱ ${durText}</strong></div>
          </div>
          <div class="h-step-detail"><span class="timing-lbl">Detalhes:</span> ${escapeHtml(detText)}</div>
        `;
        grid.appendChild(stepCard);
      });

      tdCol.appendChild(grid);
      trDetails.appendChild(tdCol);
      historyBody.appendChild(trDetails);
    }
  });
}

// ---------------------------------------------------------------------------
// Aplicação de eventos (espelha applyEvent do server.js no cliente)
// ---------------------------------------------------------------------------

function getOrCreateLocalRun(runId) {
  if (!allRuns[runId]) {
    allRuns[runId] = {
      run_id: runId,
      video: null,
      whisper_model: null,
      axet_model: null,
      started_at: null,
      status: "running",
      finished_at: null,
      duration_total_s: null,
      steps: {},
      logs: [],
    };
    if (!runOrderList.includes(runId)) {
      runOrderList.push(runId);
    }
  }
  return allRuns[runId];
}

function updateSystemMetrics(metrics) {
  if (!metrics) return;
  const rawCpu = metrics.cpu_pct !== undefined ? metrics.cpu_pct : metrics.cpuPct;
  const rawRam = metrics.mem_pct !== undefined ? metrics.mem_pct : metrics.ramPct;
  const rawRamUsed = metrics.mem_used_gb !== undefined ? metrics.mem_used_gb : metrics.ramUsedGb;
  const rawRamTotal = metrics.mem_total_gb !== undefined ? metrics.mem_total_gb : metrics.ramTotalGb;
  const cores = metrics.cpu_cores || metrics.cores || 12;

  const cpuPct = Math.min(100, Math.max(0, Math.round(rawCpu || 0)));
  const ramPct = Math.min(100, Math.max(0, Math.round(rawRam || 0)));
  const ramUsedGb = Number(rawRamUsed || 0).toFixed(1);
  const ramTotalGb = Number(rawRamTotal || 0).toFixed(1);

  // CPU Gauge
  const cpuFill = $("gauge-cpu-fill");
  const cpuNeedle = $("gauge-cpu-needle");
  const cpuVal = $("gauge-cpu-val");
  const cpuSub = $("gauge-cpu-sub");
  const cpuCard = $("gauge-cpu-card");

  if (cpuFill) {
    const offset = 125.66 * (1 - cpuPct / 100);
    cpuFill.style.strokeDashoffset = offset;
  }
  if (cpuNeedle) {
    const angle = -90 + (cpuPct / 100) * 180;
    cpuNeedle.setAttribute("transform", `rotate(${angle.toFixed(1)}, 55, 55)`);
    cpuNeedle.style.transform = `rotate(${angle.toFixed(1)}deg)`;
    cpuNeedle.style.transformOrigin = "55px 55px";
  }
  if (cpuVal) cpuVal.textContent = `${cpuPct}%`;
  if (cpuSub) cpuSub.textContent = `${cores} Cores`;

  if (cpuCard) {
    cpuCard.classList.remove("level-normal", "level-warm", "level-hot");
    if (cpuPct >= 85) cpuCard.classList.add("level-hot");
    else if (cpuPct >= 60) cpuCard.classList.add("level-warm");
    else cpuCard.classList.add("level-normal");
  }

  // RAM Gauge
  const memFill = $("gauge-mem-fill");
  const memNeedle = $("gauge-mem-needle");
  const memVal = $("gauge-mem-val");
  const memSub = $("gauge-mem-sub");
  const memCard = $("gauge-mem-card");

  if (memFill) {
    const offset = 125.66 * (1 - ramPct / 100);
    memFill.style.strokeDashoffset = offset;
  }
  if (memNeedle) {
    const angle = -90 + (ramPct / 100) * 180;
    memNeedle.setAttribute("transform", `rotate(${angle.toFixed(1)}, 55, 55)`);
    memNeedle.style.transform = `rotate(${angle.toFixed(1)}deg)`;
    memNeedle.style.transformOrigin = "55px 55px";
  }
  if (memVal) memVal.textContent = `${ramPct}%`;
  if (memSub) memSub.textContent = `${ramUsedGb} / ${ramTotalGb} GB`;

  if (memCard) {
    memCard.classList.remove("level-normal", "level-warm", "level-hot");
    if (ramPct >= 85) memCard.classList.add("level-hot");
    else if (ramPct >= 70) memCard.classList.add("level-warm");
    else memCard.classList.add("level-normal");
  }
}

function applyEventLocally(evt) {
  if (evt.type === "system_metrics" && evt.metrics) {
    updateSystemMetrics(evt.metrics);
    return;
  }

  if (evt.type === "batch_update" && evt.batch) {
    renderBatchState(evt.batch);
    return;
  }

  const {
    run_id,
    type,
    step,
    status,
    ts,
    duration_s,
    message,
    level,
    video,
    whisper_model,
    axet_model,
  } = evt;

  if (!run_id) return;
  const run = getOrCreateLocalRun(run_id);
  const timestamp = ts || new Date().toISOString();

  switch (type) {
    case "run_start":
      run.video = video || run.video;
      run.whisper_model = whisper_model || run.whisper_model;
      run.axet_model = axet_model || run.axet_model;
      run.status = "running";
      run.started_at = timestamp;
      break;

    case "run_status":
      run.status = evt.status || run.status;
      if (run.status === "running") {
        run.finished_at = null;
        run.duration_total_s = null;
        if (lingerTimers[run_id]) {
          clearTimeout(lingerTimers[run_id]);
          delete lingerTimers[run_id];
        }
        Object.keys(run.steps || {}).forEach((stepKey) => {
          if (run.steps[stepKey].status === "error") {
            run.steps[stepKey].status = "running";
            run.steps[stepKey].finished_at = null;
          }
        });
      }
      break;

    case "heartbeat":
      if (run.status === "running" && lingerTimers[run_id]) {
        clearTimeout(lingerTimers[run_id]);
        delete lingerTimers[run_id];
      }
      break;

    case "step_start":
      if (run.status === "error") {
        run.status = "running";
        run.finished_at = null;
        run.duration_total_s = null;
        if (lingerTimers[run_id]) {
          clearTimeout(lingerTimers[run_id]);
          delete lingerTimers[run_id];
        }
      }
      run.steps[step] = run.steps[step] || {};
      run.steps[step].status = "running";
      run.steps[step].started_at = timestamp;
      run.steps[step].progress_pct = 0;
      break;

    case "step_progress":
      if (run.status === "error") {
        run.status = "running";
        run.finished_at = null;
        run.duration_total_s = null;
        if (lingerTimers[run_id]) {
          clearTimeout(lingerTimers[run_id]);
          delete lingerTimers[run_id];
        }
      }
      run.steps[step] = run.steps[step] || {};
      if (run.steps[step].status === "error") {
        run.steps[step].status = "running";
        run.steps[step].finished_at = null;
      }
      run.steps[step].progress_pct = evt.pct != null ? evt.pct : run.steps[step].progress_pct;
      break;

    case "step_end":
      run.steps[step] = run.steps[step] || {};
      run.steps[step].status = status || "success";
      run.steps[step].finished_at = timestamp;
      run.steps[step].duration_s = duration_s != null ? duration_s : null;
      run.steps[step].detalhes = message || null;
      run.steps[step].progress_pct = 100;
      break;

    case "log":
      run.logs.push({
        ts: timestamp,
        level: level || "INFO",
        step: step || null,
        message: message || "",
      });
      break;

    case "run_end":
      run.status = status || "success";
      run.finished_at = timestamp;
      run.duration_total_s = duration_s != null ? duration_s : null;
      // Se o run foi cancelado/encerrado com alguma etapa ainda "running",
      // marca essa etapa como "cancelled" para não deixar o card travado
      // mostrando uma etapa "em andamento" para sempre.
      if (run.status === "cancelled" || run.status === "error") {
        Object.keys(run.steps || {}).forEach((stepKey) => {
          if (run.steps[stepKey].status === "running") {
            run.steps[stepKey].status = run.status === "cancelled" ? "cancelled" : "error";
            run.steps[stepKey].finished_at = timestamp;
          }
        });
      }
      break;

    default:
      break;
  }

  // Atualiza a UI referente a este run_id especificamente
  // outros runs simultâneos — é aqui que o bug antigo de currentRunId
  // global foi eliminado).
  syncActiveRunCards();

  if (runCardEls[run_id]) {
    renderRunCardInfo(run_id);
    if (type === "step_start" || type === "step_end" || type === "run_status") {
      renderStepCardsForRun(run_id);
    }
    if (type === "step_progress") {
      renderStepCardsForRun(run_id);
      updateStepProgressUI(run_id, step);
      updateQueueItemProgress(run_id, step, evt.pct);
    }
    if (type === "log") {
      appendLogLineToRun(run_id, {
        ts: timestamp,
        level: level || "INFO",
        step: step || null,
        message: message || "",
      });
    }
    if (type === "run_end") {
      renderRunCardInfo(run_id);
      updateProgressBarForRun(run_id);
    }
  }

  // Atualiza em tempo real a etapa e progresso do vídeo na fila do lote
  if (currentBatch && currentBatch.queue && currentBatch.queue.length > 0) {
    if (type === "step_start" || type === "step_end" || type === "run_start" || type === "run_end") {
      renderQueueTable(currentBatch.queue);
    }
  }

  renderHistory();
}

// ---------------------------------------------------------------------------
// Processamento em Lote (Batch) e Varredura Recursiva
// ---------------------------------------------------------------------------

function formatBytes(bytes) {
  if (!bytes || bytes <= 0) return "0 B";
  const k = 1024;
  const sizes = ["B", "KB", "MB", "GB"];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + " " + sizes[i];
}

const batchStartBtn = $("batch-start-btn");
const batchStopBtn = $("batch-stop-btn");
const batchStatusBadge = $("batch-status-badge");
const batchInputDir = $("batch-input-dir");
const batchOutputDir = $("batch-output-dir");
const btnBrowseInput = $("btn-browse-input");
const btnBrowseOutput = $("btn-browse-output");
const btnScanVideos = $("btn-scan-videos");
const scanCountBadge = $("scan-count-badge");
const batchParallelism = $("batch-parallelism");
const btnDecPar = $("btn-dec-par");
const btnIncPar = $("btn-inc-par");
const parallelismHint = $("parallelism-hint");
const batchWhisperModel = $("batch-whisper-model");
const batchWhisperLang = $("batch-whisper-lang");
const batchAxetModel = $("batch-axet-model");
const batchProgressText = $("batch-progress-text");
const batchWorkersText = $("batch-workers-text");
const batchProgressFill = $("batch-progress-fill");
const statTotal = $("stat-total");
const statRunning = $("stat-running");
const statCompleted = $("stat-completed");
const statPending = $("stat-pending");
const statErrors = $("stat-errors");
const statCancelled = $("stat-cancelled");
const queueTableBody = $("queue-table-body");
const queueSummaryCount = $("queue-summary-count");

// Telemetria Dinâmica de Lote (Volume em MB, Vazão MB/s, s/MB, Média e ETA)
const metricVolume = $("metric-volume");
const metricVolumeSub = $("metric-volume-sub");
const metricSpeed = $("metric-speed");
const metricSecMb = $("metric-sec-mb");
const metricAvgVideo = $("metric-avg-video");
const metricAvgVideoSub = $("metric-avg-video-sub");
const metricEta = $("metric-eta");
const metricEtaTime = $("metric-eta-time");

// Telemetria de Armazenamento e Hidratação OneDrive
const metricOnedriveStorage = $("metric-onedrive-storage");
const metricOnedriveSub = $("metric-onedrive-sub");
const storageOnedriveBadge = $("storage-onedrive-badge");
const storageHydrationBar = $("storage-hydration-bar");
const metricMacFree = $("metric-mac-free");
const metricMacSub = $("metric-mac-sub");
const storageMacBadge = $("storage-mac-badge");
const metricTmpSize = $("metric-tmp-size");
const metricTmpSub = $("metric-tmp-sub");
const storageTmpBadge = $("storage-tmp-badge");

function formatEta(seconds) {
  if (seconds == null) return "Calculando...";
  if (seconds <= 0) return "Concluído";
  if (seconds < 60) return `~${seconds}s restantes`;
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  if (m < 60) return `~${m}m ${s}s restantes`;
  const h = Math.floor(m / 60);
  const remM = m % 60;
  return `~${h}h ${remM}m restantes`;
}

function formatDurationSec(seconds) {
  if (!seconds || seconds <= 0) return "--";
  if (seconds < 60) return `${seconds}s / vídeo`;
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return `${m}m ${s}s / vídeo`;
}

// Abas de Execuções (Ativas vs Histórico)
const tabBtnActive = $("tab-btn-active");
const tabBtnHistory = $("tab-btn-history");
const tabContentActive = $("tab-content-active");
const tabContentHistory = $("tab-content-history");

function switchRunsTab(tab) {
  if (tab === "active") {
    if (tabBtnActive) tabBtnActive.classList.add("active");
    if (tabBtnHistory) tabBtnHistory.classList.remove("active");
    if (tabContentActive) tabContentActive.style.display = "block";
    if (tabContentHistory) tabContentHistory.style.display = "none";
  } else {
    if (tabBtnActive) tabBtnActive.classList.remove("active");
    if (tabBtnHistory) tabBtnHistory.classList.add("active");
    if (tabContentActive) tabContentActive.style.display = "none";
    if (tabContentHistory) tabContentHistory.style.display = "block";
  }
}

if (tabBtnActive) tabBtnActive.addEventListener("click", () => switchRunsTab("active"));
if (tabBtnHistory) tabBtnHistory.addEventListener("click", () => switchRunsTab("history"));

// Modal de Pastas
const folderModal = $("folder-modal");
const folderModalTitle = $("folder-modal-title");
const folderModalCurrentPath = $("folder-modal-current-path");
const folderModalClose = $("folder-modal-close");
const folderModalUpBtn = $("folder-modal-up-btn");
const folderModalList = $("folder-modal-list");
const folderModalCancel = $("folder-modal-cancel");
const folderModalSelect = $("folder-modal-select");
const chipWs = $("chip-ws");
const chipVideos = $("chip-videos");
const chipOutput = $("chip-output");
const chipHome = $("chip-home");

let currentBatch = null;
let activeFolderTarget = "input"; // 'input' | 'output'
let currentBrowsePath = "";
let browseParentPath = null;
let browseShortcuts = {};

function updateParallelismHint(val) {
  const num = parseInt(val, 10) || 2;
  if (!parallelismHint) return;
  if (num === 1) {
    parallelismHint.textContent = "1 execução sequencial (ideal para menor uso de CPU)";
  } else if (num === 2) {
    parallelismHint.textContent = "2 execuções simultâneas (recomendado / balanceado)";
  } else if (num >= 3 && num <= 4) {
    parallelismHint.textContent = `${num} execuções simultâneas (alta utilização de CPU)`;
  } else {
    parallelismHint.textContent = `${num} execuções simultâneas (máximo paralelismo)`;
  }
}

async function saveBatchConfigToServer(config) {
  try {
    const res = await fetch("/api/batch/config", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(config),
    });
    const data = await res.json();
    if (data.ok && data.batch) {
      currentBatch = data.batch;
    }
  } catch (_) {}
}

function renderBatchState(batch) {
  if (!batch) return;
  currentBatch = batch;

  const isRunning = batch.status === "running";
  const isStopping = batch.status === "stopping";
  const isCompleted = batch.status === "completed";
  const isStopped = batch.status === "stopped";

  // Se o lote estiver em execução, reflete os valores fixos do lote ativo.
  // Se o lote estiver ocioso/parado, JAMAIS sobrescreve a escolha manual ou seleção de pasta feita pelo usuário!
  if (isRunning || isStopping) {
    if (batchInputDir && batch.inputDir) batchInputDir.value = batch.inputDir;
    if (batchOutputDir && batch.outputDir) batchOutputDir.value = batch.outputDir;
    if (batchParallelism && batch.parallelism) {
      batchParallelism.value = batch.parallelism;
      updateParallelismHint(batch.parallelism);
    }
    if (batchWhisperModel && batch.whisperModel) batchWhisperModel.value = batch.whisperModel;
    if (batchWhisperLang && batch.whisperLanguage) batchWhisperLang.value = batch.whisperLanguage;
    if (batchAxetModel && batch.axetModel) batchAxetModel.value = batch.axetModel;
  } else {
    // Quando ocioso, só preenche campos que ainda estiverem vazios na tela
    if (batchInputDir && !batchInputDir.value.trim() && batch.inputDir) {
      const savedIn = localStorage.getItem("axet_batch_input_dir");
      batchInputDir.value = savedIn || batch.inputDir;
    }
    if (batchOutputDir && !batchOutputDir.value.trim() && batch.outputDir) {
      const savedOut = localStorage.getItem("axet_batch_output_dir");
      batchOutputDir.value = savedOut || batch.outputDir;
    }
    if (batchParallelism && !batchParallelism.value && batch.parallelism) {
      batchParallelism.value = batch.parallelism;
      updateParallelismHint(batch.parallelism);
    }
  }

  if (batchStatusBadge) {
    if (isRunning) {
      batchStatusBadge.textContent = "Em Execução";
      batchStatusBadge.className = "batch-badge running";
    } else if (isStopping) {
      batchStatusBadge.textContent = "Interrompendo...";
      batchStatusBadge.className = "batch-badge stopped";
    } else if (isCompleted) {
      batchStatusBadge.textContent = "Concluído";
      batchStatusBadge.className = "batch-badge completed";
    } else if (isStopped) {
      batchStatusBadge.textContent = "Interrompido";
      batchStatusBadge.className = "batch-badge stopped";
    } else {
      batchStatusBadge.textContent = "Pronto";
      batchStatusBadge.className = "batch-badge";
    }
  }

  if (batchStartBtn) batchStartBtn.disabled = isRunning || isStopping;
  if (batchStopBtn) {
    batchStopBtn.disabled = !isRunning;
    if (!isRunning && isStopArmed) {
      resetStopButton(false);
    }
  }
  if (batchInputDir) batchInputDir.disabled = isRunning || isStopping;
  if (batchOutputDir) batchOutputDir.disabled = isRunning || isStopping;
  if (batchParallelism) batchParallelism.disabled = isRunning || isStopping;
  if (batchWhisperModel) batchWhisperModel.disabled = isRunning || isStopping;
  if (batchWhisperLang) batchWhisperLang.disabled = isRunning || isStopping;
  if (batchAxetModel) batchAxetModel.disabled = isRunning || isStopping;
  if (btnBrowseInput) btnBrowseInput.disabled = isRunning || isStopping;
  if (btnBrowseOutput) btnBrowseOutput.disabled = isRunning || isStopping;
  if (btnScanVideos) btnScanVideos.disabled = isRunning || isStopping;

  if (batchWhisperModel && batch.whisperModel) batchWhisperModel.value = batch.whisperModel;
  if (batchWhisperLang && batch.whisperLanguage) batchWhisperLang.value = batch.whisperLanguage;
  if (batchAxetModel && batch.axetModel) batchAxetModel.value = batch.axetModel;

  // Atualiza estatísticas
  const stats = batch.stats || { total: 0, running: 0, completed: 0, pending: 0, errors: 0, cancelled: 0 };
  if (statTotal) statTotal.textContent = stats.total;
  if (statRunning) statRunning.textContent = stats.running;
  if (statCompleted) statCompleted.textContent = stats.completed;
  if (statPending) statPending.textContent = stats.pending;
  if (statErrors) statErrors.textContent = stats.errors;
  if (statCancelled) statCancelled.textContent = stats.cancelled;

  // Atualiza barra de progresso
  const total = stats.total || 0;
  const done = (stats.completed || 0) + (stats.errors || 0) + (stats.cancelled || 0);
  const pct = total > 0 ? Math.round((done / total) * 100) : 0;

  if (batchProgressFill) batchProgressFill.style.width = `${pct}%`;
  if (batchProgressText) {
    batchProgressText.textContent = `Progresso Geral do Lote: ${done} de ${total} vídeos processados (${pct}%)`;
  }
  if (batchWorkersText) {
    batchWorkersText.textContent = `${batch.activeWorkersCount || 0} ativos / paralelismo: ${batch.parallelism || 2}`;
  }

  if (queueSummaryCount) queueSummaryCount.textContent = `${total} vídeos`;
  if (scanCountBadge && total > 0) {
    scanCountBadge.textContent = `${total} vídeos identificados na árvore`;
    scanCountBadge.className = "scan-badge active";
  }

  // Atualiza métricas de telemetria dinâmica de volume, velocidade e ETA
  const tel = batch.telemetry || calculateClientBatchTelemetry(batch);
  if (tel) {
    if (metricVolume) {
      metricVolume.textContent = `${formatBytes(tel.completedBytes || 0)} / ${formatBytes(tel.totalBytes || 0)}`;
    }
    if (metricVolumeSub) {
      const remainingStr = tel.remainingBytes > 0 ? `(${formatBytes(tel.remainingBytes)} restantes)` : `(todos concluídos)`;
      metricVolumeSub.textContent = `${tel.processedPct || 0}% processado ${remainingStr}`;
    }
    if (metricSpeed) {
      metricSpeed.textContent = tel.mbPerSec ? `${tel.mbPerSec} MB/s` : `-- MB/s`;
    }
    if (metricSecMb) {
      metricSecMb.textContent = tel.secPerMb ? `${tel.secPerMb} s / MB` : (isRunning ? "Calculando vazão..." : "-- s / MB");
    }
    if (metricAvgVideo) {
      metricAvgVideo.textContent = tel.avgVideoDurationSeconds ? formatDurationSec(tel.avgVideoDurationSeconds) : `--`;
    }
    if (metricAvgVideoSub) {
      const compCount = (batch.stats && batch.stats.completed) || 0;
      metricAvgVideoSub.textContent = compCount > 0 ? `${compCount} vídeo${compCount > 1 ? "s" : ""} processado${compCount > 1 ? "s" : ""}` : (isRunning ? "Aguardando 1º vídeo..." : "Nenhum vídeo concluído");
    }
    if (metricEta) {
      if (isCompleted || (tel.remainingBytes === 0 && (batch.stats && batch.stats.total > 0))) {
        metricEta.textContent = "Concluído";
      } else if (!isRunning && !isStopping) {
        metricEta.textContent = "--";
      } else if (tel.etaSeconds != null) {
        metricEta.textContent = formatEta(tel.etaSeconds);
      } else {
        metricEta.textContent = isRunning ? "Calculando..." : "--";
      }
    }
    if (metricEtaTime) {
      if (isCompleted || (tel.remainingBytes === 0 && (batch.stats && batch.stats.total > 0))) {
        metricEtaTime.textContent = "Lote finalizado com sucesso";
      } else if (!isRunning && !isStopping) {
        metricEtaTime.textContent = "Aguardando início do lote";
      } else if (tel.estimatedFinishIso) {
        const d = new Date(tel.estimatedFinishIso);
        metricEtaTime.textContent = `Término previsto: ${d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}`;
      } else {
        metricEtaTime.textContent = isRunning ? "Estimando taxa de processamento..." : "Aguardando início";
      }
    }
  }

  // Atualiza Telemetria de Armazenamento e Hidratação OneDrive
  const stg = (batch.telemetry && batch.telemetry.storage) || batch.storage || null;
  if (stg) {
    if (metricOnedriveStorage) {
      metricOnedriveStorage.textContent = `${stg.inputAllocatedGb != null ? stg.inputAllocatedGb : "0.00"} GB / ${stg.inputLogicalGb != null ? stg.inputLogicalGb : "0.00"} GB`;
    }
    if (storageHydrationBar) {
      storageHydrationBar.style.width = `${Math.min(100, Math.max(0, stg.hydrationPct || 0))}%`;
    }
    if (metricOnedriveSub) {
      const hydCount = stg.hydratedCount || 0;
      const onlCount = stg.onlineOnlyCount || 0;
      metricOnedriveSub.textContent = `${hydCount} baixados no Mac • ${onlCount} na nuvem (online-only)`;
    }
    if (storageOnedriveBadge) {
      if (stg.isHydrating) {
        storageOnedriveBadge.textContent = "Hidratando...";
        storageOnedriveBadge.className = "storage-status-badge badge-downloading";
      } else if (stg.hydrationPct < 25) {
        storageOnedriveBadge.textContent = "On-Demand Seguro";
        storageOnedriveBadge.className = "storage-status-badge badge-safe";
      } else {
        storageOnedriveBadge.textContent = `${stg.hydrationPct}% Hidratado`;
        storageOnedriveBadge.className = "storage-status-badge";
      }
    }

    if (metricMacFree) {
      metricMacFree.textContent = `${stg.diskFreeGb != null ? stg.diskFreeGb : "--"} GB Livres`;
    }
    if (metricMacSub) {
      metricMacSub.textContent = `Total SSD: ${stg.diskTotalGb != null ? stg.diskTotalGb : "--"} GB • Salvaguarda: 20 GB`;
    }
    if (storageMacBadge) {
      if (stg.diskSafetyAlert) {
        storageMacBadge.textContent = "ALERTA (<20GB)";
        storageMacBadge.className = "storage-status-badge badge-alert";
      } else {
        storageMacBadge.textContent = "Seguro (>20GB)";
        storageMacBadge.className = "storage-status-badge badge-safe";
      }
    }

    if (metricTmpSize) {
      metricTmpSize.textContent = `${stg.tempWorkspaceMb != null ? stg.tempWorkspaceMb : "0.0"} MB`;
    }
    if (metricTmpSub) {
      metricTmpSub.textContent = "Vídeo .tmp deletado pós-áudio • OneDrive intacto";
    }
    if (storageTmpBadge) {
      if (stg.tempWorkspaceMb > 500) {
        storageTmpBadge.textContent = "Em uso";
        storageTmpBadge.className = "storage-status-badge";
      } else {
        storageTmpBadge.textContent = "Otimizado";
        storageTmpBadge.className = "storage-status-badge badge-clean";
      }
    }
  }

  // Renderiza tabela da fila
  renderQueueTable(batch.queue || []);
}

function calculateClientBatchTelemetry(batch) {
  if (!batch || !Array.isArray(batch.queue)) return null;
  let totalBytes = 0;
  let completedBytes = 0;
  let completedDurationSeconds = 0;
  let completedCount = 0;
  let runningBytes = 0;
  let runningCount = 0;
  let pendingBytes = 0;
  let pendingCount = 0;

  for (const q of batch.queue) {
    const sz = q.sizeBytes || 0;
    totalBytes += sz;
    if (q.status === "completed") {
      completedBytes += sz;
      completedCount++;
      const dur = typeof q.duration_s === "number" && q.duration_s > 0
        ? q.duration_s
        : (q.startedAt && q.finishedAt ? Math.max(1, Math.round((new Date(q.finishedAt) - new Date(q.startedAt)) / 1000)) : 0);
      completedDurationSeconds += dur;
    } else if (q.status === "running") {
      runningBytes += sz;
      runningCount++;
    } else if (q.status === "pending") {
      pendingBytes += sz;
      pendingCount++;
    }
  }

  const remainingBytes = Math.max(0, totalBytes - completedBytes);
  const totalMb = totalBytes / (1024 * 1024);
  const completedMb = completedBytes / (1024 * 1024);
  const remainingMb = remainingBytes / (1024 * 1024);

  let secPerMb = 0;
  let mbPerSec = 0;
  if (completedMb > 0.05 && completedDurationSeconds > 0) {
    secPerMb = completedDurationSeconds / completedMb;
    mbPerSec = completedMb / completedDurationSeconds;
  }

  const avgVideoDurationSeconds = completedCount > 0 ? Math.round(completedDurationSeconds / completedCount) : null;
  let etaSeconds = null;
  let estimatedFinishIso = null;
  const isRunning = batch.status === "running";
  const parallelism = Math.max(1, batch.parallelism || 2);
  const remainingVideos = pendingCount + runningCount;

  if (batch.status === "completed" || (totalBytes > 0 && remainingVideos === 0 && completedCount === batch.queue.length)) {
    etaSeconds = 0;
  } else if (isRunning && remainingBytes > 0) {
    const effectiveWorkers = Math.max(1, Math.min(parallelism, remainingVideos));
    if (secPerMb > 0) {
      etaSeconds = Math.round((remainingMb * secPerMb) / effectiveWorkers);
      estimatedFinishIso = new Date(Date.now() + etaSeconds * 1000).toISOString();
    }
  }

  return {
    totalBytes,
    totalMb: parseFloat(totalMb.toFixed(1)),
    completedBytes,
    completedMb: parseFloat(completedMb.toFixed(1)),
    remainingBytes,
    remainingMb: parseFloat(remainingMb.toFixed(1)),
    processedPct: totalBytes > 0 ? Math.round((completedBytes / totalBytes) * 100) : 0,
    secPerMb: secPerMb > 0 ? parseFloat(secPerMb.toFixed(2)) : null,
    mbPerSec: mbPerSec > 0 ? parseFloat(mbPerSec.toFixed(2)) : null,
    avgVideoDurationSeconds,
    etaSeconds,
    estimatedFinishIso,
  };
}

function getPipelineStepInfo(item) {
  if (item.status === "pending") {
    return {
      label: "Aguardando na fila",
      stepNum: 0,
      pct: null,
      badgeClass: "step-pending",
      subtext: "Aguardando worker livre",
    };
  }

  if (item.status === "completed") {
    return {
      label: "[4/4] Concluído",
      stepNum: 4,
      pct: 100,
      badgeClass: "step-completed",
      subtext: "Todas as 4 etapas finalizadas",
    };
  }

  if (item.status === "cancelled") {
    return {
      label: "Cancelado",
      stepNum: null,
      pct: null,
      badgeClass: "step-cancelled",
      subtext: "Interrompido antes da conclusão",
    };
  }

  if (item.status === "error") {
    return {
      label: "Falha na execução",
      stepNum: null,
      pct: null,
      badgeClass: "step-error",
      subtext: item.error || "Erro durante o processamento",
    };
  }

  // Se running: verificar run ativo correspondente em memória
  let stepKey = item.currentStep;
  let pct = item.currentStepProgress;
  let detailMsg = item.currentStepMessage;

  if (item.runId && allRuns[item.runId]) {
    const run = allRuns[item.runId];
    const runningStepKey = STEP_ORDER.find((s) => run.steps && run.steps[s] && run.steps[s].status === "running");
    if (runningStepKey) {
      stepKey = runningStepKey;
      if (run.steps[runningStepKey].progress_pct != null) {
        pct = run.steps[runningStepKey].progress_pct;
      }
      if (run.steps[runningStepKey].detalhes) {
        detailMsg = run.steps[runningStepKey].detalhes;
      }
    }
  }

  if (stepKey === "extracao_audio") {
    return {
      label: "[1/4] Extração de Áudio",
      stepNum: 1,
      pct: null,
      badgeClass: "step-audio",
      subtext: "ffmpeg: gerando áudio PCM 16kHz mono",
    };
  } else if (stepKey === "transcricao_whisper") {
    const hasPct = pct != null && pct > 0;
    return {
      label: hasPct ? `[2/4] Whisper: ${pct}%` : "[2/4] Transcrição (Whisper)",
      stepNum: 2,
      pct: pct || 0,
      badgeClass: "step-whisper",
      subtext: hasPct ? `${pct}% do áudio transcrito` : (detailMsg || "Carregando modelo Whisper..."),
    };
  } else if (stepKey === "interpretacao_axet") {
    return {
      label: "[3/4] Análise IA (axet-code)",
      stepNum: 3,
      pct: null,
      badgeClass: "step-axet",
      subtext: "Estruturação sênior anti-alucinação",
    };
  } else if (stepKey === "geracao_markdown") {
    return {
      label: "[4/4] Geração do Markdown",
      stepNum: 4,
      pct: null,
      badgeClass: "step-markdown",
      subtext: "Montando relatório executivo .md",
    };
  }

  return {
    label: "Iniciando pipeline...",
    stepNum: 1,
    pct: 0,
    badgeClass: "step-audio",
    subtext: "Preparando ambiente de execução",
  };
}

function renderQueueTable(queue) {
  if (!queueTableBody) return;
  if (!queue || queue.length === 0) {
    queueTableBody.innerHTML = `
      <tr class="queue-empty-row">
        <td colspan="7">Nenhum vídeo carregado. Selecione a pasta raiz de vídeos e clique em "Escanear".</td>
      </tr>
    `;
    return;
  }

  queueTableBody.innerHTML = queue
    .map((item, idx) => {
      let statusClass = "pending";
      let statusText = "Pendente";
      if (item.status === "running") {
        statusClass = "running";
        statusText = "Em Execução";
      } else if (item.status === "completed") {
        statusClass = "completed";
        statusText = "Concluído";
      } else if (item.status === "error") {
        statusClass = "error";
        statusText = "Erro";
      } else if (item.status === "cancelled") {
        statusClass = "cancelled";
        statusText = "Cancelado";
      }

      const stepInfo = getPipelineStepInfo(item);

      const relFolder = item.relativePath && item.relativePath.includes("/") ? item.relativePath.substring(0, item.relativePath.lastIndexOf("/")) : "";

      let durationText = "—";
      if (item.duration_s != null) {
        durationText = formatDuration(item.duration_s);
      } else if (item.startedAt && item.status === "running") {
        const elapsed = Math.round((Date.now() - new Date(item.startedAt).getTime()) / 1000);
        durationText = `${formatDuration(elapsed)}...`;
      }

      let runCol = "—";
      if (item.runId) {
        runCol = `<span class="queue-run-id" title="${item.runId}">run #${item.runId.slice(-8)}</span>`;
        if (item.status === "completed") {
          runCol += `<div style="font-size: 10px; color: #10b981; margin-top: 3px;" title="Arquivos salvos na pasta espelhada">✓ Salvo na subpasta</div>`;
        }
      }

      let cloudBadge = "";
      if (item.isOnlineOnly) {
        cloudBadge = `<span class="storage-tag-cloud" title="Arquivo na nuvem (Online-Only / Dataless)">☁️ Nuvem</span>`;
      } else if (item.isHydrated) {
        cloudBadge = `<span class="storage-tag-local" title="Arquivo baixado no Mac (Hidratado)">💾 Local</span>`;
      }

      return `
        <tr class="queue-row queue-row-${statusClass}" id="queue-row-${escapeHtml(item.id)}">
          <td>${idx + 1}</td>
          <td>
            <strong>${escapeHtml(item.relativePath || item.filename)}</strong>
            ${relFolder ? `<div class="queue-item-dest" style="font-size: 10px; color: var(--text-dim); margin-top: 2px;">📁 saída: <code>${escapeHtml(relFolder)}/</code></div>` : ""}
            ${item.error ? `<div class="queue-item-error" style="color: var(--error); font-size: 10px; margin-top: 2px;">${escapeHtml(item.error)}</div>` : ""}
          </td>
          <td>
            <div style="display: flex; align-items: center; gap: 4px; flex-wrap: wrap;">
              <span>${formatBytes(item.sizeBytes)}</span>
              ${cloudBadge}
            </div>
          </td>
          <td>
            <div class="queue-step-cell" id="queue-step-cell-${escapeHtml(item.id)}">
              <div class="queue-step-header">
                <span class="queue-step-tag ${stepInfo.badgeClass}">${escapeHtml(stepInfo.label)}</span>
                ${stepInfo.pct != null ? `<span class="queue-step-pct">${stepInfo.pct}%</span>` : ""}
              </div>
              ${
                stepInfo.pct != null
                  ? `<div class="queue-mini-bar-bg"><div class="queue-mini-bar-fill ${stepInfo.badgeClass}" style="width: ${stepInfo.pct}%"></div></div>`
                  : ""
              }
              <div class="queue-step-subtext">${escapeHtml(stepInfo.subtext)}</div>
            </div>
          </td>
          <td><span class="status-badge-mini ${statusClass}">${statusText}</span></td>
          <td>${durationText}</td>
          <td>${runCol}</td>
        </tr>
      `;
    })
    .join("");
}

function updateQueueItemProgress(runId, step, pct) {
  if (!currentBatch || !currentBatch.queue) return;
  const item = currentBatch.queue.find((q) => q.runId === runId);
  if (!item) return;
  item.currentStep = step;
  if (pct != null) item.currentStepProgress = pct;
  const cell = document.getElementById(`queue-step-cell-${item.id}`);
  if (!cell) return;
  const stepInfo = getPipelineStepInfo(item);
  cell.innerHTML = `
    <div class="queue-step-header">
      <span class="queue-step-tag ${stepInfo.badgeClass}">${escapeHtml(stepInfo.label)}</span>
      ${stepInfo.pct != null ? `<span class="queue-step-pct">${stepInfo.pct}%</span>` : ""}
    </div>
    ${
      stepInfo.pct != null
        ? `<div class="queue-mini-bar-bg"><div class="queue-mini-bar-fill ${stepInfo.badgeClass}" style="width: ${stepInfo.pct}%"></div></div>`
        : ""
    }
    <div class="queue-step-subtext">${escapeHtml(stepInfo.subtext)}</div>
  `;
}

// ---------------------------------------------------------------------------
// Varredura e Seleção de Pastas
// ---------------------------------------------------------------------------

async function scanVideos() {
  if (!batchInputDir) return;
  const dir = (batchInputDir.value || "").trim();
  if (!dir) {
    alert("Informe o diretório de entrada de vídeos.");
    return;
  }
  if (scanCountBadge) {
    scanCountBadge.textContent = "Varrendo pastas e subpastas...";
    scanCountBadge.className = "scan-badge";
  }

  try {
    const res = await fetch("/api/batch/scan", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ inputDir: dir }),
    });
    const data = await res.json();
    if (!data.ok) {
      if (scanCountBadge) {
        scanCountBadge.textContent = `Erro: ${data.error}`;
        scanCountBadge.className = "scan-badge";
      }
      alert(`Erro na varredura: ${data.error}`);
      return;
    }

    if (scanCountBadge) {
      scanCountBadge.textContent = `${data.count} vídeos encontrados em pastas e subpastas!`;
      scanCountBadge.className = "scan-badge active";
    }
    if (queueSummaryCount) queueSummaryCount.textContent = `${data.count} vídeos`;

    const previewQueue = (data.videos || []).map((v) => ({
      id: v.id,
      relativePath: v.relativePath,
      filename: v.filename,
      sizeBytes: v.sizeBytes,
      status: "pending",
      duration_s: null,
      runId: null,
    }));
    renderQueueTable(previewQueue);

    // Atualiza imediatamente o volume total dos vídeos detectados na varredura
    const totalScanBytes = previewQueue.reduce((acc, q) => acc + (q.sizeBytes || 0), 0);
    if (metricVolume) {
      metricVolume.textContent = `0 MB / ${formatBytes(totalScanBytes)}`;
    }
    if (metricVolumeSub) {
      metricVolumeSub.textContent = `0% processado (${data.count} vídeos escaneados)`;
    }
    if (metricSpeed) metricSpeed.textContent = "-- MB/s";
    if (metricSecMb) metricSecMb.textContent = "Pronto para iniciar";
    if (metricAvgVideo) metricAvgVideo.textContent = "--";
    if (metricAvgVideoSub) metricAvgVideoSub.textContent = `${data.count} vídeos aguardando`;
    if (metricEta) metricEta.textContent = "--";
    if (metricEtaTime) metricEtaTime.textContent = "Clique em 'Iniciar Lote'";
  } catch (err) {
    if (scanCountBadge) scanCountBadge.textContent = `Falha na conexão: ${err.message}`;
  }
}

async function handleBrowseFolder(target) {
  activeFolderTarget = target;
  const currentVal = (target === "input" ? batchInputDir.value : batchOutputDir.value).trim();

  // Tenta abrir o diálogo nativo do SO via macOS osascript
  try {
    const res = await fetch("/api/fs/choose-folder", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ defaultDir: currentVal }),
    });
    const data = await res.json();
    if (data.ok && data.path) {
      if (target === "input") {
        batchInputDir.value = data.path;
        localStorage.setItem("axet_batch_input_dir", data.path);
        saveBatchConfigToServer({ inputDir: data.path });
        scanVideos();
      } else {
        batchOutputDir.value = data.path;
        localStorage.setItem("axet_batch_output_dir", data.path);
        saveBatchConfigToServer({ outputDir: data.path });
      }
      return;
    }
    if (data.cancelled) {
      return; // Usuário cancelou normalmente
    }
  } catch (_) {}

  // Fallback: abre modal web de navegação de pastas
  openFolderModal(target, currentVal);
}

function openFolderModal(target, initialPath) {
  activeFolderTarget = target;
  if (folderModalTitle) {
    folderModalTitle.textContent =
      target === "input" ? "Selecionar Diretório de Entrada (Vídeos)" : "Selecionar Diretório de Saída (Resultados)";
  }
  if (folderModal) folderModal.style.display = "flex";
  loadFolderBrowser(initialPath || "");
}

function closeFolderModal() {
  if (folderModal) folderModal.style.display = "none";
}

async function loadFolderBrowser(targetDir) {
  if (!folderModalList) return;
  folderModalList.innerHTML = `<div class="folder-item">Carregando pastas...</div>`;
  try {
    const res = await fetch(`/api/fs/browse?dir=${encodeURIComponent(targetDir)}`);
    const data = await res.json();
    if (data.error) {
      folderModalList.innerHTML = `<div class="folder-item" style="color: var(--error);">${escapeHtml(data.error)}</div>`;
      return;
    }

    currentBrowsePath = data.current;
    browseParentPath = data.parent;
    browseShortcuts = {
      ws: data.workspace,
      videos: data.defaultVideos,
      output: data.defaultOutput,
      home: data.home,
    };

    if (folderModalCurrentPath) folderModalCurrentPath.value = currentBrowsePath;
    if (folderModalUpBtn) folderModalUpBtn.disabled = !browseParentPath;

    if (!data.subdirs || data.subdirs.length === 0) {
      folderModalList.innerHTML = `<div class="folder-item" style="color: var(--text-dim);">Nenhuma subpasta encontrada aqui.</div>`;
      return;
    }

    folderModalList.innerHTML = data.subdirs
      .map(
        (sub) => `
        <div class="folder-item" data-path="${escapeHtml(sub.path)}">
          <span class="folder-item-icon">📁</span>
          <span>${escapeHtml(sub.name)}</span>
        </div>
      `
      )
      .join("");

    folderModalList.querySelectorAll(".folder-item[data-path]").forEach((el) => {
      el.addEventListener("click", () => {
        const nextPath = el.getAttribute("data-path");
        if (nextPath) loadFolderBrowser(nextPath);
      });
    });
  } catch (err) {
    folderModalList.innerHTML = `<div class="folder-item" style="color: var(--error);">Falha ao carregar: ${escapeHtml(err.message)}</div>`;
  }
}

// ---------------------------------------------------------------------------
// Disparo e Interrupção do Lote
// ---------------------------------------------------------------------------

async function startBatchExecution() {
  const inputDir = (batchInputDir.value || "").trim();
  const outputDir = (batchOutputDir.value || "").trim();
  const parallelism = parseInt(batchParallelism.value, 10) || 2;
  const whisperModel = (batchWhisperModel.value || "small").trim();
  const whisperLanguage = (batchWhisperLang ? batchWhisperLang.value : "es").trim().toLowerCase();
  const axetModel = (batchAxetModel ? batchAxetModel.value : "gpt-5.6-terra").trim();

  if (!inputDir) {
    alert("Informe o diretório de entrada de vídeos.");
    return;
  }
  if (!outputDir) {
    alert("Informe o diretório de saída de resultados.");
    return;
  }

  if (batchStartBtn) batchStartBtn.disabled = true;
  if (batchStatusBadge) {
    batchStatusBadge.textContent = "Iniciando...";
    batchStatusBadge.className = "batch-badge running";
  }

  try {
    const res = await fetch("/api/batch/start", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ inputDir, outputDir, parallelism, whisperModel, whisperLanguage, axetModel }),
    });
    const data = await res.json();
    if (!data.ok) {
      alert(`Falha ao iniciar processamento: ${data.error}`);
      if (batchStartBtn) batchStartBtn.disabled = false;
      if (batchStatusBadge) {
        batchStatusBadge.textContent = "Pronto";
        batchStatusBadge.className = "batch-badge";
      }
      return;
    }

    renderBatchState(data.batch);
  } catch (err) {
    alert(`Erro de rede ao iniciar lote: ${err.message}`);
    if (batchStartBtn) batchStartBtn.disabled = false;
  }
}

let isStopArmed = false;
let stopArmTimeout = null;

function resetStopButton(enable = true) {
  isStopArmed = false;
  if (stopArmTimeout) {
    clearTimeout(stopArmTimeout);
    stopArmTimeout = null;
  }
  if (batchStopBtn) {
    batchStopBtn.innerHTML = '<span class="btn-icon">⏹</span> Interromper com Segurança';
    batchStopBtn.classList.remove("btn-danger-armed");
    if (!enable) batchStopBtn.disabled = true;
  }
}

async function stopBatchExecution() {
  // Confirmação inline sem popup nativo (Two-Click Arm & Fire)
  // Elimina fechamento acidental por ciclos de renderização e SSE
  if (!isStopArmed) {
    isStopArmed = true;
    if (batchStopBtn) {
      batchStopBtn.innerHTML = '<span class="btn-icon">⚠️</span> <strong>Confirmar Parada Imediata?</strong>';
      batchStopBtn.classList.add("btn-danger-armed");
    }
    stopArmTimeout = setTimeout(() => {
      resetStopButton(true);
    }, 5000);
    return;
  }

  // Segundo clique confirmado: dispara interrupção imediata
  if (stopArmTimeout) {
    clearTimeout(stopArmTimeout);
    stopArmTimeout = null;
  }
  isStopArmed = false;

  if (batchStopBtn) {
    batchStopBtn.innerHTML = '<span class="btn-icon">⏳</span> <strong>Interrompendo...</strong>';
    batchStopBtn.classList.remove("btn-danger-armed");
    batchStopBtn.disabled = true;
  }
  if (batchStatusBadge) {
    batchStatusBadge.textContent = "Interrompendo...";
    batchStatusBadge.className = "batch-badge stopped";
  }

  try {
    const res = await fetch("/api/batch/stop", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
    });
    const data = await res.json();
    if (data.ok && data.batch) {
      renderBatchState(data.batch);
    }
  } catch (err) {
    console.error("Erro ao interromper lote:", err);
  } finally {
    resetStopButton(false);
    if (batchStartBtn) batchStartBtn.disabled = false;
    if (batchStopBtn) batchStopBtn.disabled = true;
  }
}

if (btnBrowseInput) btnBrowseInput.addEventListener("click", () => handleBrowseFolder("input"));
if (btnBrowseOutput) btnBrowseOutput.addEventListener("click", () => handleBrowseFolder("output"));
if (btnScanVideos) btnScanVideos.addEventListener("click", scanVideos);

if (batchOutputDir) {
  batchOutputDir.addEventListener("change", () => {
    const val = batchOutputDir.value.trim();
    if (val) {
      localStorage.setItem("axet_batch_output_dir", val);
      saveBatchConfigToServer({ outputDir: val });
    }
  });
}

if (batchInputDir) {
  batchInputDir.addEventListener("change", () => {
    const val = batchInputDir.value.trim();
    if (val) {
      localStorage.setItem("axet_batch_input_dir", val);
      saveBatchConfigToServer({ inputDir: val });
    }
  });
}

if (btnDecPar) {
  btnDecPar.addEventListener("click", () => {
    let val = parseInt(batchParallelism.value, 10) || 2;
    if (val > 1) {
      val--;
      batchParallelism.value = val;
      updateParallelismHint(val);
    }
  });
}

if (btnIncPar) {
  btnIncPar.addEventListener("click", () => {
    let val = parseInt(batchParallelism.value, 10) || 2;
    if (val < 8) {
      val++;
      batchParallelism.value = val;
      updateParallelismHint(val);
    }
  });
}

if (batchParallelism) {
  batchParallelism.addEventListener("input", () => {
    let val = parseInt(batchParallelism.value, 10) || 2;
    if (val < 1) val = 1;
    if (val > 8) val = 8;
    updateParallelismHint(val);
  });
}

if (batchStartBtn) batchStartBtn.addEventListener("click", startBatchExecution);
if (batchStopBtn) batchStopBtn.addEventListener("click", stopBatchExecution);

if (folderModalClose) folderModalClose.addEventListener("click", closeFolderModal);
if (folderModalCancel) folderModalCancel.addEventListener("click", closeFolderModal);
if (folderModalUpBtn) {
  folderModalUpBtn.addEventListener("click", () => {
    if (browseParentPath) loadFolderBrowser(browseParentPath);
  });
}
if (folderModalSelect) {
  folderModalSelect.addEventListener("click", () => {
    if (currentBrowsePath) {
      if (activeFolderTarget === "input") {
        batchInputDir.value = currentBrowsePath;
        localStorage.setItem("axet_batch_input_dir", currentBrowsePath);
        saveBatchConfigToServer({ inputDir: currentBrowsePath });
        scanVideos();
      } else {
        batchOutputDir.value = currentBrowsePath;
        localStorage.setItem("axet_batch_output_dir", currentBrowsePath);
        saveBatchConfigToServer({ outputDir: currentBrowsePath });
      }
      closeFolderModal();
    }
  });
}

if (chipWs) chipWs.addEventListener("click", () => browseShortcuts.ws && loadFolderBrowser(browseShortcuts.ws));
if (chipVideos) chipVideos.addEventListener("click", () => browseShortcuts.videos && loadFolderBrowser(browseShortcuts.videos));
if (chipOutput) chipOutput.addEventListener("click", () => browseShortcuts.output && loadFolderBrowser(browseShortcuts.output));
if (chipHome) chipHome.addEventListener("click", () => browseShortcuts.home && loadFolderBrowser(browseShortcuts.home));

// ---------------------------------------------------------------------------
// Conexão SSE + snapshot inicial
// ---------------------------------------------------------------------------

function setConnectionStatus(connected) {
  if (connected) {
    connDot.classList.add("connected");
    connDot.classList.remove("disconnected");
    connStatus.textContent = "conectado";
  } else {
    connDot.classList.add("disconnected");
    connDot.classList.remove("connected");
    connStatus.textContent = "desconectado — tentando reconectar...";
  }
}

async function loadAxetModels() {
  try {
    const res = await fetch("/api/axet/models");
    const data = await res.json();
    if (data.ok && Array.isArray(data.models) && data.models.length > 0 && batchAxetModel) {
      const selectedVal = (currentBatch && currentBatch.axetModel) || batchAxetModel.value || "gpt-5.6-terra";
      batchAxetModel.innerHTML = data.models
        .map(
          (m) =>
            `<option value="${escapeHtml(m.id)}"${
              m.id === selectedVal || m.id === "gpt-5.6-terra" ? " selected" : ""
            }>${escapeHtml(m.name)}</option>`
        )
        .join("");
      if (selectedVal) batchAxetModel.value = selectedVal;
    }
  } catch (e) {
    console.warn("Não foi possível carregar modelos axet-code:", e);
  }
}

async function loadInitialState() {
  await loadAxetModels();
  try {
    const res = await fetch("/state");
    const data = await res.json();
    allRuns = data.runs || {};
    runOrderList = data.order || Object.keys(allRuns);

    syncActiveRunCards();
    Object.keys(runCardEls).forEach((runId) => {
      renderRunCardInfo(runId);
      renderStepCardsForRun(runId);
      renderInitialLogsForRun(runId);
    });
    renderHistory();
  } catch (e) {
    console.error("Falha ao carregar /state:", e);
  }

  try {
    const savedOut = localStorage.getItem("axet_batch_output_dir");
    if (savedOut && batchOutputDir) {
      batchOutputDir.value = savedOut;
      saveBatchConfigToServer({ outputDir: savedOut });
    }
    const savedIn = localStorage.getItem("axet_batch_input_dir");
    if (savedIn && batchInputDir) {
      batchInputDir.value = savedIn;
      saveBatchConfigToServer({ inputDir: savedIn });
    }

    const batchRes = await fetch("/api/batch/status");
    const batchData = await batchRes.json();
    if (batchData.ok && batchData.batch) {
      renderBatchState(batchData.batch);
    }
  } catch (e) {
    console.error("Falha ao carregar /api/batch/status:", e);
  }

  try {
    const sysRes = await fetch("/api/system/metrics");
    const sysData = await sysRes.json();
    if (sysData.ok && sysData.metrics) {
      updateSystemMetrics(sysData.metrics);
    }
  } catch (e) {
    console.warn("Falha ao carregar métricas de sistema iniciais:", e);
  }
}

function connectSSE() {
  const es = new EventSource("/events");

  es.onopen = () => setConnectionStatus(true);
  es.onerror = () => setConnectionStatus(false);

  es.onmessage = (msg) => {
    try {
      const evt = JSON.parse(msg.data);
      applyEventLocally(evt);
    } catch (e) {
      console.error("Evento SSE inválido:", e, msg.data);
    }
  };
}

// ---------------------------------------------------------------------------
// Inicialização
// ---------------------------------------------------------------------------

renderActiveRunsEmptyState();
loadInitialState().then(() => {
  connectSSE();
});
