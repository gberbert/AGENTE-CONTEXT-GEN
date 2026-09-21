# CURRENT PROJECT STATE

Last updated: 2026-09-20 08:56 (America/Sao_Paulo)

Agent/session: Axet Plugin — integração do prompt avançado (`prompts/analise_transcricao_avancada.md`) ao pipeline oficial e remoção da transcrição bruta do arquivo `.md`.

---

## Current Version

Ver `versionamento.md` para o histórico de versões do projeto.

---

## Current Objective

Cockpit totalmente operacional em http://localhost:4545/ com pipeline executando o prompt avançado sênior via `gpt-5.6-terra`, velocímetro de telemetria de hardware em tempo real calibrado para o kernel do macOS e motor de transcrição acelerado nativamente via `whisper.cpp` (Metal no Apple Silicon M4 Pro).

---

## Active Task

Status: COMPLETED (2026-09-20 22:49)

Task ID: TASK-20260920-2240-BATCH-PERSISTENCE-AND-RESUME

Description: Implementação de persistência atômica do lote (batch_manifest.json), detecção dual de vídeos concluídos no disco e suporte a retomada inteligente (resume de onde parou sem reprocessar os 287 vídeos já concluídos).

Result: Concluído e validado. Implementada persistência de manifesto (`batch_manifest.json`) no workspace (.agent/) e na pasta de saída (OneDrive), detector dual com normalização NFC para acentos no macOS, suporte a `skipCompleted` nos endpoints `/api/batch/scan`, `/api/batch/start` e `/api/batch/resume`, botão "Retomar de Onde Parou" no Cockpit e validação no navegador confirmando 287 concluídos e 336 pendentes.

---

## Current Implementation State

- `dashboard/server.js` — persistência contínua em `batch_manifest.json`, detecção dual de relatórios Markdown em disco (`checkItemCompletedOnDisk`), auto-recuperação na inicialização (`loadBatchManifest`), endpoints `/api/batch/scan`, `/api/batch/start`, `/api/batch/resume` com salvaguarda `skipCompleted`.
- `dashboard/index.html` e `dashboard/style.css` — botão visual `⏯ Retomar de Onde Parou` (`.btn-resume`), checkbox `🛡️ Pular vídeos já concluídos` e tags `✓ Concluído`.
- `dashboard/app.js` — integração completa de retomada sem reprocessamento, exibição de contagens `287 concluídos • 336 a processar` e links diretos para relatórios gerados.
- `scripts/process_video.sh` — prevenção de aninhamento duplo de pastas de saída e compatibilidade retroativa com caminhos históricos.

---

## Latest Relevant Changes

- Implementado sistema de persistência atômica de lote (`batch_manifest.json`) salvo em `.agent/` e na pasta de saída do lote, com recarga automática ao reiniciar o servidor Node.
- Implementado detector dual de vídeos concluídos (`checkItemCompletedOnDisk`) com normalização Unicode NFC e validação de tamanho (> 150 bytes), garantindo reconhecimento dos 287 vídeos já processados.
- Adicionado botão "Retomar de Onde Parou" no Cockpit Web e endpoint `/api/batch/resume` com `skipCompleted: true` por padrão.
- Adicionado checkbox de salvaguarda "Pular vídeos já concluídos" no Cockpit para prevenção de retrabalho.
- Corrigida a duplicação de pastas de saída em `scripts/process_video.sh` quando invocado pelo servidor.

- Corrigida a reversão involuntária do diretório de saída (`#batch-output-dir`) para o padrão `/Users/gcostabe/dev/TESTE-AXET-CODE/output`, adicionando proteção em `renderBatchState`, persistência no `localStorage` e novo endpoint `POST /api/batch/config`.
- Implementada telemetria de hidratação do OneDrive em tempo real: medição de GBs alocados em disco vs volume lógico, taxa de hidratação e contagem de vídeos baixados vs online-only na nuvem.
- Implementada salvaguarda de disco (`DISK_FREE_MINIMUM = 20 GB`) no despachador do lote: pausa novos trabalhos caso o espaço livre no SSD fique abaixo de 20 GB.
- Implementada arquitetura temporária segura em `scripts/process_video.sh`: criação de sandbox em `/tmp/axet-workspace/`, remoção imediata de vídeo temporário pós-extração de áudio e garantia inviolável de não deletar arquivos no OneDrive.
- Adicionadas tags visuais na fila de vídeos do Cockpit (`💾 Local` vs `☁️ Nuvem`).
- Implementada telemetria dinâmica de lote: cálculo de volume total em MB/GB, taxa de vazão em tempo real (MB/s e s/MB), duração média por vídeo e estimativa de término (ETA com horário previsto).
- Reestruturada a saída do pipeline: cada vídeo gera uma pasta dedicada com o nome do vídeo, acomodando o .wav, .txt, .md e logs isolados.
- Implementada confirmação inline segura de dois cliques (Arm & Fire) no botão "Interromper com Segurança", eliminando popup do navegador que fechava sozinho.
- Corrigida a emissão de [BLANK_AUDIO] no Whisper Metal com adição de `--suppress-nst`, `-mc 256`, idioma Espanhol (es) como padrão e sanitizador pós-transcrição.
- Calibrada a leitura de RAM no macOS para espelhar o Monitor de Atividade oficial (caiu do falso 93% para os 63% reais).
- Corrigida a agulha de RAM que ficava travada em 0° por conflito de folha de estilo CSS.
- Instalado `whisper.cpp` v1.9.4 nativo para Apple Silicon via Homebrew.
- Validada execução real com transcrição em menos de 2 segundos.
- Adicionado seletor de modelos da IA (`axet-code models`).
- Adicionadas abas "Execuções Ativas" e "Histórico de Execuções".

---

## Known Problems

- `.AGENTS.md` (dotfile, com ponto) contém conteúdo de bootstrap diagnostic — mantido intocado por política de não deletar arquivos. O arquivo autoritativo de regras é `AGENTS.md`.
- Workspace versionado no Git em https://github.com/gberbert/AGENTE-CONTEXT-GEN.git (branch `main`).
- Servidor do dashboard mantém `runs` apenas em memória (reinício do Node reinicia o mapa de runs).

---

## Pending Work

- [x] Correção dos falsos positivos de timeout do watchdog durante Whisper (CONCLUÍDO).
- [x] Geração dos 6 arquivos `output/*_resumo_*.md` do lote REEF Intro (TODOS CONCLUÍDOS).
- [x] Geração do relatório detalhado para `tesorería-contabilidad-2` (CONCLUÍDO).
- [ ] Nenhuma pendência técnica imediata.

---

## Important Constraints

- Não deletar nenhum arquivo existente.
- Não sobrescrever `.vscode/settings.json` sem merge.
- Não fazer bump de versão sem mudança relevante correspondente em `versionamento.md`.
- Não realizar operações destrutivas ou de produção sem aprovação explícita do usuário.

---

## Next Recommended Action

Nenhuma ação técnica pendente. O pipeline e o cockpit estão operacionais e validados com proteção ativa contra falsos positivos de timeout.
