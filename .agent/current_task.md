# CURRENT TASK

Task ID: TASK-20260920-1605-SETUP-GITIGNORE-AND-REPO

Created: 2026-09-20 16:05 America/Sao_Paulo

Status: COMPLETED (2026-09-20 16:09)

Resume Authorization: NO (concluído)

---

## User Request

"antes configure um .gitignere completo"
(contexto anterior: "crie um rep no git agora e faca o push")

---

## Objective

Configurar um `.gitignore` completo, robusto e padronizado para o projeto Axet Video Pipeline, isolando:
1. Modelos de IA pesados (>100MB, Whisper ggml bin);
2. Vídeos de entrada (.mp4, .mkv, .mov, etc.);
3. Saídas e artefatos de execução (`output/*`), mantendo `.gitkeep`;
4. Ambiente virtual Python (`.venv/`) e caches (`__pycache__/`);
5. Dependências Node e logs (`node_modules/`, `*.log`);
6. Arquivos e caches internos do Axet (`.axet-code/`);
7. Arquivos temporários e artefatos de sessão transitórios conforme regras de `AGENTS.md` (`.graphify/`, `smoke-run/`, `legacy_piloto/`, `scratch/`, `_*.*`, `*.tmp`, `*.temp`, `*.bak`, `test_segment.*`);
8. Arquivos de sistema e IDEs (`.DS_Store`, `.idea/`, mantendo `.vscode/settings.json`);
9. Credenciais e variáveis de ambiente sensíveis (`.env*`, `*.key`, `*.pem`, `credentials.json`).

Em seguida, preparar o repositório Git local com `.gitkeep` estruturais, validar a exclusão das pastas pesadas e proceder com as etapas de versionamento/push solicitadas.

---

## Plan

1. Registrar `TASK-20260920-1605-SETUP-GITIGNORE-AND-REPO` em `current_task.md`, `state.md` e `execution_journal.md`.
2. Criar `.gitkeep` estruturais em `videos/`, `output/`, `output/logs/` e `models/`.
3. Escrever `.gitignore` abrangente cobrindo todas as categorias do projeto.
4. Validar as regras do `.gitignore` com `git check-ignore` e simulação de `git status`.
5. Registrar checkpoint de validação em `execution_journal.md` e atualizar `state.md`.
