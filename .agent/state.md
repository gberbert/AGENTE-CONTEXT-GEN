# CURRENT PROJECT STATE

Last updated: 2026-09-22 12:15 (America/Sao_Paulo)

Agent/session: Axet Multimodal Pipeline — Redesenho de Layout em Tela Única (Single-Screen 100vh), Paginação e Filtros para Filas e Histórico, e Identidade Visual NTT DATA.

---

## Current Version

v0.12.0 (Ver `versionamento.md` para o histórico detalhado).

---

## Current Objective

Processamento multimodal enriquecido de vídeos com OCR de telas, formulários e diagramas via LLM Gateway (:8766), mantendo compatibilidade com áudio clássico e controle dinâmico no Cockpit Web (http://localhost:4545/).

---

## Active Task

Status: COMPLETED (2026-09-23)

Task ID: TASK-20260923-LOCAL-INSTALLERS-ONECLICK

Description: Criada solução de instalação e lançamento local One-Click para Windows (WSL2 automatizado) e macOS (`instalar_windows.bat`, `iniciar_cockpit.bat`, `scripts/setup_wsl_internal.sh`, `setup_mac.sh`, `iniciar_mac.command`). O instalador cuida de toda a configuração interna de FFmpeg, Python, Whisper e Node, criando um atalho na Área de Trabalho do Windows e na Mesa do Mac para execução com duplo clique e abertura automática do navegador em `http://localhost:4545/`.

Validation: Sintaxe dos scripts Bash validada com `bash -n`, teste de execução do lançador macOS realizado com sucesso e documentação completa atualizada no `README.md`.

---

## Current Implementation State

- `instalar_windows.bat` & `scripts/setup_wsl_internal.sh` — Instalador One-Click para Windows via WSL2 com detecção de GPU NVIDIA CUDA.
- `iniciar_cockpit.bat` — Lançador diário de duplo clique para Windows que inicia o Cockpit e abre o navegador padrão.
- `setup_mac.sh` & `iniciar_mac.command` — Instalador e lançador de duplo clique para macOS.
- `dashboard/server.js` — Resolvedor dinâmico `resolveOktaIdentity()` com decodificação de JWT e verificação de saúde do gateway (:8766 / :3001); endpoints `/api/auth/status`, `/api/auth/refresh`, `/api/fs/open`; sincronização de itens do manifesto em `/state`; auto-refresh de token gateway.
- `dashboard/index.html` — Layout com badge Okta SSO dinâmico, modal enriquecido com metadados OIDC (Login corporativo, Okta User ID, TTL de sessão, IdP OneNTT), barra multissegmentada no KPI 2, simetria em diretórios e Card 3 de Telemetria de Tokens.
- `dashboard/style.css` — Estilos corporativos do modal Okta SSO, cards ativos, grid simétrico e paleta NTT DATA.
- `dashboard/app.js` — Função `syncAuthStatus()` para binding dinâmico de todos os claims corporativos, status em tempo real a cada 60s, sincronização de filas e histórico.



---

## Latest Relevant Changes

- Atualizado `relatorio_tecnico_multimodal_reef_tron.md` com relatório técnico-funcional de 27 seções, baseado exclusivamente na transcrição Whisper e em oito frames OCR fornecidos (03:56–30:55). A entrega contém 20 blocos de Q&A, arquitetura lógica restrita às evidências, mapa cronológico revisado e divergência DUP/RTE explicitada e resolvida pela resposta completa do Frame 03.
- Implementado redesenho completo de tela única (Single-Screen 100vh Viewport) eliminando scroll confuso de 3.500px.
- Implementada paginação e busca instantânea com chips de status na Fila do Lote e no Histórico Concluído.
- Integrados os logos oficiais da NTT DATA na pasta `logos/` (`ntt-data-logo.png`, `ntt-symbol.png`, `favicon-64.png`).
- Implementado suporte a `.html`, `.htm` e `.xhtml` com sanitização de scripts/estilos/navegação e conversão direta para Markdown estruturado.
- Implementado suporte a `.xlsx`, `.xls`, `.csv` e `.tsv` com conversão automática de abas em tabelas Markdown.
- Implementado suporte a `.txt`, `.md`, `.markdown`, `.json`, `.jsonl`, `.xml` e formatos OpenDocument (.odt, .ods, .odp).
- Adicionado watchdog auto-pump de 5s no servidor Node para evitar pausas acidentais na fila.

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
- Ajustada a etapa final de `scripts/process_document.sh`: o artefato Markdown agora contém somente o relatório RAG estruturado retornado pela IA; a referência fiel do conteúdo bruto é mantida na seção 9 do template.

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
- [x] Conformidade do Markdown final de documentos com o template RAG, sem duplicação de corpus (CONCLUÍDO).

---

## Important Constraints

- Não deletar nenhum arquivo existente.
- Não sobrescrever `.vscode/settings.json` sem merge.
- Não fazer bump de versão sem mudança relevante correspondente em `versionamento.md`.
- Não realizar operações destrutivas ou de produção sem aprovação explícita do usuário.

---

## Next Recommended Action

Nenhuma ação técnica pendente. O pipeline e o cockpit estão operacionais e validados com proteção ativa contra falsos positivos de timeout.
