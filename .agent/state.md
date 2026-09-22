# CURRENT PROJECT STATE

Last updated: 2026-09-22 10:10 (America/Sao_Paulo)

Agent/session: Axet Multimodal Pipeline — Ingestão Multi-formato de Documentos de Mercado (.html, .xlsx, .csv, .txt, .json, etc.) e Watchdog de Fila no Cockpit.

---

## Current Version

v0.10.0 (Ver `versionamento.md` para o histórico detalhado).

---

## Current Objective

Cockpit totalmente operacional em http://localhost:4545/ com suporte multimodal estendido (Vídeos + Documentos PDF, DOCX, PPTX, HTML, Planilhas XLSX/CSV, Texto e Dados Estruturados), pipeline executando prompt RAG de alta densidade via `gpt-5.6-terra`, velocímetro de telemetria em tempo real e watchdog auto-pump ativo.

---

## Active Task

Status: COMPLETED (2026-09-22)

Task ID: TASK-20260922-EXTENSOES-DOCUMENTOS-MERCADO

Description: Expansão do pipeline de documentos corporativos para reconhecimento, extração e conversão RAG de formatos de mercado: HTML (.html, .htm, .xhtml), Planilhas (.xlsx, .xls), Dados Tabulares (.csv, .tsv), Texto (.txt, .md, .markdown, .rtf) e Dados Estruturados (.json, .jsonl, .xml). Inclusão de watchdog auto-pump de 5s no servidor para proteção contra starvation de fila.

Result: Concluído e 100% validado em testes automatizados. Servidor atualizado rodando na porta 4545.

---

## Current Implementation State

- `scripts/extract_document.py` — parsers dedicados de alta fidelidade para HTML (`BeautifulSoup` + `markdownify`), Excel (`openpyxl`), CSV (`csv`), Texto e JSON, com fallback universal via `markitdown`.
- `dashboard/server.js` — `DOCUMENT_EXTENSIONS` estendido com 17 novas extensões de mercado; watchdog auto-pump periódico de 5s para evitar starvation da fila; auto-recuperação via manifesto.
- `dashboard/app.js` — detecção de extensões e badges específicos (`🌐 HTML`, `📈 TABELA`, `⚙️ DADOS`, `📋 TEXTO`).
- `dashboard/style.css` — estilos cromáticos temáticos para cada novo tipo de mídia.
- `dashboard/index.html` — descrições de interface e tooltips atualizados.

---

## Latest Relevant Changes

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
