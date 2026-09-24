# TAREFA: Manter Somente Seletor de Diretórios Customizado no Cockpit

- **Task ID**: TASK-20260924-CUSTOM-FOLDER-PICKER-ONLY
- **Status**: COMPLETED
- **Phase**: VERIFICATION
- **Data/Hora**: 2026-09-24 10:36 America/Sao_Paulo
- **Workspace**: /Users/gcostabe/dev/AGENTE-CONTEXT-GEN

## Entregas Concluídas

1. **Frontend (`dashboard/app.js`)**:
   - `handleBrowseFolder(target)` refatorado para invocar diretamente e de forma síncrona `openFolderModal(target, currentVal)`.
   - Removida a requisição `POST /api/fs/choose-folder` e a espera de timeout de 2.5s.
   - O modal web customizado de diretórios agora abre instantaneamente ao clicar em "Procurar".

2. **Backend (`dashboard/server.js`)**:
   - `chooseFolderNative` refatorado para não disparar chamadas síncronas de `osascript` / AppleScript para o Finder do macOS.
   - Retorno imediato defensivo `{ ok: false, customOnly: true }`.

3. **Validação**:
   - `node --check dashboard/app.js` e `node --check dashboard/server.js` passaram sem erros de sintaxe.
