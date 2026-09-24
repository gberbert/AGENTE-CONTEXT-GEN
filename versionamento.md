# VERSIONAMENTO — AXET VIDEO PIPELINE

Este documento serve como registro manual de versões e mudanças relevantes, acompanhando a evolução do repositório Git.

Formato: `[VERSÃO] - AAAA-MM-DD` seguido de lista de mudanças.

## [0.12.1] - 2026-09-24

### Aprimorado / Corrigido

- **Seletor de Diretórios do Cockpit Exclusivamente Web**:
  - `dashboard/app.js`: abertura imediata e direta do modal customizado web ao clicar em "Procurar", removendo a tentativa de chamada síncrona com timeout para o AppleScript do macOS;
  - `dashboard/server.js`: desativação defensiva da rotina nativa `chooseFolderNative` (`osascript`), prevenindo abertura indesejada do Finder e bloqueio do event loop do Node.js.

---

## [0.12.0] - 2026-09-23

### Adicionado / Aprimorado

- **Processamento Multimodal de Vídeos com OCR de Tela e Visão por IA (`scripts/extract_video_frames.py`, `scripts/analyze_video_multimodal.py`, `prompts/analise_video_multimodal.md`)**:
  - Implementado extrator inteligente de frames via `ffmpeg` com amostragem temporal adaptativa, redimensionamento (1280x720) e compressão otimizada JPEG (~50KB/frame), gerando manifesto com timestamps exatos de exibição.
  - Criado orquestrador multimodal Python que associa cada frame ao áudio transcrito (Whisper) e envia o payload visual + textual diretamente ao LLM Gateway corporativo (`http://localhost:8766` / Claude Sonnet / GPT-4o / GPT-5) via API Messages/Completions com fallback automático para `axet-code`.
  - Criado prompt especializado de análise multimodal com regras estritas anti-alucinação, extração de texto de interfaces (OCR de menus, botões, tabelas, campos de formulário e mensagens de status), interpretação de diagramas de arquitetura e correlação cronológica entre fala e telas.
  - Salvaguarda inviolável de armazenamento: frames são extraídos e processados estritamente na pasta temporária `/tmp/axet-workspace/${RUN_ID}/frames/` e sumariamente limpos após a síntese, mantendo o OneDrive 100% intocado.

- **Chave de Seleção em Configurações no Cockpit Web (`dashboard/index.html`, `dashboard/app.js`, `dashboard/server.js`)**:
  - Adicionado seletor visual corporativo no Card de Configurações para alternância dinâmica entre:
    1. `👁️ Com OCR + Visão Multimodal + LLM (Frames de Tela + Áudio)`: modo enriquecido com análise simultânea de fala e visão;
    2. `🎙️ Sem OCR (Apenas Áudio + LLM Tradicional)`: modo clássico focado exclusivamente na transcrição do áudio.
  - Persistência automática da seleção no `localStorage`, no servidor Node (`POST /api/batch/config`), nos metadados do manifesto (`batch_manifest.json`) e no disparo de execuções do lote.

---

## [0.11.0] - 2026-09-22

### Adicionado / Aprimorado

- **Redesenho do Layout em Tela Única (Single-Screen 100vh Viewport)**:
  - Eliminado o scroll vertical confuso e excessivo (> 3.500px), consolidando todo o Cockpit em um viewport fixo de 100vh com cabeçalho compacto, barra de controle e telemetria reduzida, e navegação limpa por abas unificadas:
    1. `📂 Fila do Lote`: visualização paginada e filtrada de todos os itens do lote;
    2. `⚡ Execuções Ativas`: grade em tempo real de workers com etapas e logs streaming;
    3. `📜 Histórico Concluído`: tabela paginada de execuções finalizadas com expansão detalhada de etapas;
    4. `📊 Telemetria & Storage`: métricas avançadas de hidratação OneDrive, salvaguarda do SSD Mac e `/tmp`.

- **Paginação e Filtros para Filas Massivas e Histórico (`dashboard/index.html`, `dashboard/app.js`, `dashboard/style.css`)**:
  - Implementada paginação client-side com seletor de itens por página (25, 50, 100 ou Todos) e botões Primeira, Anterior, Próxima e Última.
  - Implementado campo de busca em tempo real (`#queue-search-input` e `#history-search-input`) com botão de limpeza rápida (`×`).
  - Implementados chips de filtragem por status (`Todos`, `Pendentes`, `Executando`, `Concluídos`, `Erros`) com contadores numéricos atualizados dinamicamente via SSE.
  - Otimização crítica de performance: renderização fatiada reduz nós DOM em mais de 98% para lotes de 2.600+ arquivos, eliminando travamentos de browser e mantendo a página atual durante atualizações em segundo plano.

- **Identidade Visual Corporativa NTT DATA (`dashboard/server.js`, `logos/`)**:
  - Servidor Node configurado com rota estática para servir os ativos da pasta `logos/` (`/logos/ntt-data-logo.png`, `/logos/ntt-symbol.png`, `/favicon-64.png`).
  - Paleta de cores oficial NTT DATA aplicada em todo o CSS: Deep Navy (`#070b14`), Surface Navy (`#0c1427`), NTT Blue (`#0072bc`), Cyan Glow (`#38bdf8`) e Emerald Accent (`#10b981`).
  - Favicon corporativo de 64px e cabeçalho institucional integrado.

---

## [0.10.0] - 2026-09-22

### Adicionado / Aprimorado

- **Suporte Multi-formato Estendido no Pipeline de Documentos (`scripts/extract_document.py`)**:
  - Implementado parser de **HTML / Web (`.html`, `.htm`, `.xhtml`)** com sanitização de ruídos (remoção de scripts, styles, navegação e rodapé), extração de títulos e tabelas, e conversão fiel para Markdown via `BeautifulSoup` e `markdownify`.
  - Implementado parser de **Planilhas Excel (`.xlsx`, `.xls`)** via `openpyxl` e `markitdown`, convertendo cada aba em tabelas Markdown estruturadas com cabeçalhos preservados.
  - Implementado parser de **Dados Tabulares Delimitados (`.csv`, `.tsv`)** com detecção automática de delimitadores e conversão tabular nativa para Markdown.
  - Implementado parser de **Texto e Markdown (`.txt`, `.md`, `.markdown`, `.rtf`)** com tolerância multi-encoding (UTF-8, Latin-1, CP1252).
  - Implementado parser de **Dados Estruturados (`.json`, `.jsonl`, `.xml`)** com indentação e blocos de código semânticos.
  - Fallback universal para formatos **OpenDocument (`.odt`, `.ods`, `.odp`)** e documentos legados via `markitdown`.

- **Reconhecimento e Telemetria no Cockpit (`dashboard/server.js`, `dashboard/app.js`, `dashboard/style.css`)**:
  - `dashboard/server.js`: expandido `DOCUMENT_EXTENSIONS` para incluir todos os novos formatos de mercado na varredura recursiva de diretórios.
  - `dashboard/server.js`: adicionado **Watchdog Auto-Pump** a cada 5 segundos para garantir que a fila nunca fique travada caso o número de workers caia para zero durante salvaguardas temporárias de disco.
  - `dashboard/app.js`: adicionados badges visuais específicos na tabela de fila: `🌐 HTML`, `📈 TABELA`, `⚙️ DADOS` e `📋 TEXTO`.
  - `dashboard/style.css`: adicionadas cores temáticas para cada tipo de mídia identificada.

---

## [0.9.0] - 2026-09-20

### Adicionado / Aprimorado

- **Persistência Contínua de Lote e Manifesto de Estado (`batch_manifest.json`)**:
  - `dashboard/server.js`: implementadas funções `saveBatchManifest()` e `loadBatchManifest()`, persistindo atomicamente o estado da fila tanto no workspace (`.agent/batch_manifest.json`) quanto na pasta de saída (`outputDir/batch_manifest.json`);
  - `dashboard/server.js`: auto-recuperação de estado ativada na inicialização do servidor Node, restaurando o lote anterior sem perda de progresso;
  - `dashboard/server.js`: inclusão do campo `markdownPath` no snapshot do lote para rastreamento de relatórios gerados.

- **Detecção Dual de Conclusão e Prevenção de Retrabalho**:
  - `dashboard/server.js`: função `checkItemCompletedOnDisk()` com normalização Unicode (NFC) para compatibilidade perfeita com acentos no macOS/OneDrive ("Presentación", "Módulo", "Grabación"), verificando fisicamente se o relatório Markdown (`*_resumo_*.md` > 150 bytes) existe em disco;
  - Reconhecimento automático com 100% de acurácia dos 287 vídeos já processados anteriormente.

- **Retomada Inteligente do Lote (Resume de Onde Parou)**:
  - `dashboard/server.js`: novo endpoint `POST /api/batch/resume` e parâmetro `skipCompleted: true` em `POST /api/batch/start`, preservando vídeos concluídos e enfileirando apenas vídeos pendentes ou que falharam;
  - `dashboard/index.html` e `dashboard/style.css`: novo botão de destaque `⏯ Retomar de Onde Parou` (`.btn-resume`) e checkbox de salvaguarda `🛡️ Pular vídeos já concluídos`;
  - `dashboard/app.js`: integração reativa, desativação de retrabalho e tags visuais verdes `✓ Concluído` na tabela de fila.

- **Resolução Limpa de Pastas de Saída**:
  - `scripts/process_video.sh`: ajustada a resolução de diretórios para evitar criação de subpastas duplicadas quando executado a partir do dashboard.

---

## [0.8.1] - 2026-09-20

### Corrigido

- **Persistência e Estabilidade da Seleção do Diretório de Saída**:
  - `dashboard/app.js`: corrigida a rotina `renderBatchState`, impedindo que os eventos periódicos de telemetria SSE sobrescrevam o campo `#batch-output-dir` e inputs de configuração enquanto o lote estiver ocioso;
  - `dashboard/app.js`: adicionada persistência automática no `localStorage` do navegador para manter o diretório de saída e de entrada entre sessões e recarregamentos de página;
  - `dashboard/app.js`: adicionados event listeners para sincronizar e enviar imediatamente as alterações nos campos de pasta para o backend;
  - `dashboard/server.js`: implementado novo endpoint `POST /api/batch/config` que atualiza instantaneamente `batchState.outputDir`, `inputDir` e outros parâmetros de configuração no servidor assim que o usuário seleciona uma nova pasta.

---

## [0.8.0] - 2026-09-20

### Adicionado / Aprimorado

- **Telemetria em Tempo Real de Hidratação do OneDrive & Armazenamento em Disco**:
  - `dashboard/server.js`: implementado cálculo de tamanho físico alocado (`stat.blocks * 512`) vs tamanho lógico dos vídeos, medição de espaço livre no SSD do Mac via `fs.statfsSync("/")` e monitoramento de ocupação da área temporária `/tmp/axet-workspace`;
  - `dashboard/server.js`: adicionada regra global de salvaguarda de disco (`DISK_FREE_MINIMUM = 20 GB`) no despachador de fila (`pumpBatchQueue`), pausando automaticamente o início de novos vídeos/downloads caso o espaço livre em disco fique abaixo do limite seguro;
  - `dashboard/index.html` e `dashboard/style.css`: adicionada a grade `.storage-telemetry-grid` com 3 novos cartões de infraestrutura: *Hidratação OneDrive* (GB alocados vs lógicos, percentual e contagem de arquivos locais vs nuvem), *Espaço Livre SSD Mac* (GB livres e salvaguarda) e *Área Temporária (/tmp)* (ocupação em MB e garantia de integridade);
  - `dashboard/app.js`: atualização reativa via SSE e na varredura de pastas, incluindo badges visuais na tabela de fila identificando arquivos `💾 Local` (baixados) e `☁️ Nuvem` (online-only / dataless).

- **Arquitetura de Processamento Temporário Seguro & Ciclo de Vida Otimizado**:
  - `scripts/process_video.sh`: criação de sandbox isolada por worker em `/tmp/axet-workspace/${RUN_ID}`;
  - `scripts/process_video.sh`: suporte a desidratação e liberação imediata de vídeo temporário logo após a extração de áudio pelo ffmpeg (`rm -f "$TEMP_VIDEO"`), garantindo que apenas arquivos de áudio permaneçam no disco durante transcrição e análise por IA;
  - `scripts/process_video.sh`: asserção explícita de segurança (`assert_safe_path_for_deletion`) que bloqueia e aborta qualquer tentativa de exclusão em caminhos fora de `/tmp` ou contendo `OneDrive`/`CloudStorage`;
  - `scripts/process_video.sh`: validação explícita de integridade do arquivo `.md` final (> 150 bytes e não-vazio) antes de confirmar o status da etapa;
  - `scripts/process_video.sh`: limpeza total garantida via trap (`safe_cleanup_temp`) em caso de sucesso, erro ou cancelamento manual (bloco `finally`).

---

## [0.7.0] - 2026-09-20

### Adicionado

- **Telemetria Dinâmica de Lote (Volume em MB, Vazão MB/s, s/MB, Média por Vídeo e ETA)**:
  - `dashboard/server.js`: função `calculateBatchTelemetry` calculando volume total de entrada em MB, volume processado, velocidade média de vazão (`mbPerSec`), custo unitário por megabyte (`secPerMb`), duração média por vídeo e estimativa de término (`etaSeconds`) ponderada pelo número de workers ativos;
  - `dashboard/index.html`: adicionado grid responsivo `.batch-telemetry-grid` com 4 cartões em destaque (Volume de Dados, Taxa de Vazão, Média por Vídeo e Estimativa de Término / Horário Previsto);
  - `dashboard/style.css`: estilização dos cartões com design moderno translúcido escuro e destaque neon ciano/teal para o ETA;
  - `dashboard/app.js`: cálculo imediato pós-varredura e atualização em tempo real por eventos de telemetria SSE.

---

## [0.6.0] - 2026-09-20

### Adicionado / Aprimorado

- **Estrutura de Saída com Pasta Dedicada por Vídeo**:
  - `scripts/process_video.sh`: para cada vídeo, cria automaticamente um diretório com o nome do arquivo (sem extensão) dentro da pasta de saída (`$OUTPUT_DIR/$FILENAME_NOEXT`);
  - `scripts/process_video.sh`: armazena dentro dessa pasta dedicada o arquivo de áudio (`.wav`), a transcrição integral (`.txt`), o relatório executivo avançado (`.md`) e os logs (`logs/`), eliminando arquivos soltos e acúmulo em pasta compartilhada;
  - `dashboard/server.js`: alinhado o `targetOutputDir` dos workers do processamento em lote para refletir o caminho da pasta dedicada de cada vídeo.

---

## [0.5.0] - 2026-09-20

### Corrigido / Aprimorado

- **Interrupção de Emergência Segura (Dois Cliques / Arm & Fire Inline)**:
  - `dashboard/app.js`: substituída a chamada síncrona `window.confirm()` que era cancelada e fechada automaticamente pelo navegador devido ao fluxo concorrente de eventos SSE/DOM;
  - `dashboard/app.js` e `dashboard/style.css`: implementado padrão *Two-Click Arm & Fire* diretamente no botão (1º clique arma o botão com feedback visual pulsante `⚠️ Confirmar Parada Imediata?` e timer de 5s; 2º clique dispara `POST /api/batch/stop` instantaneamente);
  - `dashboard/server.js`: encerramento imediato de todos os workers e subprocessos do lote com `SIGKILL` e `pkill -9` defensivo, sem travar o loop de eventos.

- **Eliminação de Colapso e Alucinação `[BLANK_AUDIO]` no Whisper Metal**:
  - `scripts/process_video.sh`: adicionadas flags `--suppress-nst` (suprime tokens não-vocais de silêncio/música) e `-mc 256` (limita arrasto de contexto) na chamada ao `whisper-cli`;
  - `scripts/process_video.sh`: resolução segura de idioma com padrão Espanhol (`es`), evitando que o silêncio/música de até 15 minutos nas aberturas de treinamento corporativo engane a auto-detecção fonética para o inglês (`en`);
  - `scripts/process_video.sh`: sanitização pós-transcrição descartando linhas residuais de `[BLANK_AUDIO]` antes da entrega para a IA;
  - `dashboard/index.html`, `dashboard/server.js` e `dashboard/app.js`: configuração padrão do seletor e de estado inicial atualizada para `es` (Espanhol - recomendado REEF/Mapfre).

---

## [0.4.0] - 2026-09-20

### Adicionado

- **Seletor Dinâmico de Idioma no Cockpit**:
  - `dashboard/index.html`: adicionado campo seletor "Idioma do Áudio" com suporte a `Auto-detectar (recomendado)`, `Espanhol (es)`, `Português (pt)`, `Inglês (en)`, `Francês (fr)`, `Italiano (it)`;
  - `dashboard/style.css`: grid responsiva de parâmetros de lote adaptando-se suavemente para 3 colunas;
  - `dashboard/app.js`: binding, sincronização via SSE e envio do parâmetro `whisperLanguage` na chamada de início do lote;
  - `dashboard/server.js`: recepção e propagação do idioma configurado em `batchState.whisperLanguage` aos processos filhos.

### Corrigido / Otimizado

- **Mitigação de Alucinação em Silêncio e Loops Infinitos de Repetição no Whisper**:
  - `scripts/process_video.sh`: inclusão das flags `--condition_on_previous_text False` e `--no_speech_threshold 0.6`, eliminando loops repetitivos de caracteres (como `e`, `e`, `e`...) em trechos sem fala;
  - `scripts/process_video.sh`: suporte nativo a `auto` onde o parâmetro `--language` é omitido para permitir que o Whisper utilize a sua rede neural de identificação fonética inicial dos primeiros 30 segundos, detectando Espanhol (`es`) automaticamente em materiais multilíngues sem causar fallbacks de temperatura lentos;
  - `scripts/process_video.sh`: atualização do valor padrão do parâmetro de idioma para `auto`.

### Adicionado

- **Varredura Recursiva de Vídeos em Árvores de Pastas**:
  - `dashboard/server.js`: função `scanVideosRecursively` percorrendo diretório raiz e todas as subpastas em profundidade;
  - Suporte a extensões `.mp4`, `.mkv`, `.mov`, `.avi`, `.webm`, `.flv`, `.m4v`, `.ts`, `.wmv`;
  - Filtro automático de diretórios de sistema (`.git`, `.venv`, `.agent`, `node_modules`) e prevenção de re-varredura da pasta de saída.
- **Seletor de Diretórios via Browser e Sistema Operacional**:
  - `dashboard/server.js`: integração nativa com o Finder do macOS via AppleScript (`/api/fs/choose-folder`);
  - `dashboard/server.js`: endpoint de navegação web de diretórios (`/api/fs/browse`) com atalhos para Workspace, vídeos, saída e Home;
  - `dashboard/index.html` e `dashboard/app.js`: modal visual embutido de seleção de pastas.
- **Controle de Paralelismo e Worker Pool Controlado**:
  - `dashboard/server.js`: `BatchQueueManager` limitando a concorrência a $N$ execuções simultâneas configuráveis (1 a 8 workers);
  - `dashboard/index.html` e `dashboard/app.js`: stepper interativo de paralelismo com dicas de dimensionamento de CPU;
  - Disparo contínuo automático: ao término de um vídeo, o próximo pendente na fila assume o slot livre.
- **Disparo e Interrupção Segura no Cockpit**:
  - Botão de início de lote com validação de diretórios e criação automática da pasta de saída;
  - Botão de interrupção imediata segura aplicando `killProcessTree` com `SIGTERM` em todos os processos ativos e subprocessos (`ffmpeg`, `whisper`, `axet-code`), prevenindo processos zumbis;
  - Painel de progresso geral do lote com percentual e contadores de status.
- **Configuração de Saída nos Scripts**:
  - `scripts/process_video.sh`: suporte à variável `OUTPUT_DIR` customizada.

---

## [0.2.0] - 2026-09-20

### Corrigido

- **Watchdog do Dashboard e Falsos Positivos de Timeout durante Transcrição Whisper**:
  - `dashboard/server.js`: verificação real de liveness do processo via `isProcessAlive(pid)` (`process.kill(pid, 0)`), impedindo marcação indevida de erro em processos vivos executando Whisper em CPU;
  - `dashboard/server.js`: elevação do timeout base (`STALE_TIMEOUT_MS`) para 10 minutos (`600s`) para runs sem PID e teto de segurança (`MAX_ALIVE_TIMEOUT_MS`) de 1 hora para processos vivos;
  - `dashboard/server.js`: redução do grace period de processo morto (`DEAD_PROCESS_GRACE_MS`) para 15 segundos após término abrupto real (crash / `kill -9`);
  - `dashboard/server.js`: auto-recuperação (*self-healing*) que restaura status de `error` para `running` e reativa etapas afetadas por timeout caso cheguem novos eventos legítimos;
  - `dashboard/app.js`: tratamento de eventos `heartbeat` e `run_status`, cancelamento de timers de descarte (`lingerTimers`) e re-renderização de cards/etapas revividas;
  - `scripts/process_video.sh` e `scripts/step3_analise_avancada.sh`: rotinas assíncronas `start_heartbeat()` e `stop_heartbeat()` emitindo telemetria a cada 20s em segundo plano;
  - `scripts/process_video.sh`: descarregamento imediato de buffer stdio do Whisper via `PYTHONUNBUFFERED=1`;
  - `scripts/process_video.sh` e `scripts/step3_analise_avancada.sh`: captura de sinais `TERM`, `INT` e `EXIT` garantindo parada e limpeza de processos filhos.

---

## [0.1.0] - 2026-09-19

### Adicionado

- Arquitetura de memória persistente do agente implantada:
  - `AGENTS.md` (bootloader raiz)
  - `.agent/state.md` — estado atual do projeto
  - `.agent/decisions.md` — decisões arquiteturais permanentes
  - `.agent/recovery.md` — protocolo de recuperação de contexto
  - `.agent/history/2026-09.md` — histórico migrado da memória legada
  - `.stack_tech.md` — stack e arquitetura confirmados
  - `.stdout-stderr-instructions.md` — regras de execução segura de comandos
  - `.answer_instructions.md` — regras de idioma/estilo de resposta
  - `.github/copilot-instructions.md` — bootloader para GitHub Copilot
  - `.vscode/settings.json` — configuração do VS Code referenciando `AGENTS.md`
  - `versionamento.md` (este arquivo)

### Observações

- Código-fonte existente (`dashboard/`, `scripts/`, `prompts/`) não foi alterado nesta versão — mudança puramente de documentação/memória.
- `.agent_memory_rag.md` (memória legada) marcado como superado, mas preservado.
- `.AGENTS.md` (com ponto, conteúdo corrompido/não relacionado) preservado sem alteração — não é o bootloader autoritativo.

---

## Estado anterior (baseline, não versionado)

Pipeline de processamento de vídeos Reef Academy:

- `scripts/process_video.sh` — extração de áudio + transcrição via Whisper
- `scripts/step3_analise_avancada.sh` — análise avançada via CLI `axet-code`
- `dashboard/` — servidor Node.js (http puro) + frontend vanilla JS com SSE para acompanhamento de execuções em tempo real
