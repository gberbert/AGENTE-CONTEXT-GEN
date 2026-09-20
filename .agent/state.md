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

Status: IN_PROGRESS (2026-09-20 16:05)

Task ID: TASK-20260920-1605-SETUP-GITIGNORE-AND-REPO

Description: Configuração de um .gitignore completo e robusto para o pipeline de vídeos e preparação do repositório Git.

Result: Concluído localmente. .gitignore completo com 10 seções implementado, .gitkeep estruturais criados, git init executado e commit inicial realizado (27 arquivos, ~300KB). Aguardando definição do repositório remoto para efetuar o git push.

---

## Current Implementation State

- `dashboard/server.js` — endpoint `POST /api/batch/config` para persistência imediata de parâmetros de lote, amostragem de armazenamento via `fs.statfsSync("/")` e salvaguarda de 20 GB.
- `dashboard/index.html` e `dashboard/style.css` — novos cartões de hidratação OneDrive, espaço livre no Mac e área temporária `/tmp`, com tags `💾 Local` e `☁️ Nuvem` na tabela de fila.
- `dashboard/app.js` — proteção de inputs de configuração em `renderBatchState` (não sobrescreve quando ocioso), persistência no `localStorage` e envio assíncrono para o backend.
- `scripts/process_video.sh` — sandbox temporária isolada `/tmp/axet-workspace/${RUN_ID}`, extração de áudio com remoção imediata de vídeo temporário, salvaguarda absoluta de exclusão fora de `/tmp` e validação do markdown gerado.

---

## Latest Relevant Changes

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
- Workspace não é um repositório git — histórico de versões registrado em `versionamento.md` e `.agent/history/`.
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
