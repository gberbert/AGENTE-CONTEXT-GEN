# TAREFA: Montagem dos Instaladores e Lançadores Locais One-Click (Windows WSL2 & macOS)

- **Task ID**: TASK-20260923-LOCAL-INSTALLERS-ONECLICK
- **Status**: COMPLETED
- **Phase**: VERIFICATION
- **Data/Hora**: 2026-09-23 22:27 America/Sao_Paulo
- **Workspace**: /Users/gcostabe/dev/AGENTE-CONTEXT-GEN

## Entrega

1. **`instalar_windows.bat`**: Assistente automatizado de 1 clique para Windows que verifica/instala o WSL2 (Ubuntu), dispara o provisionamento de dependências e cria o atalho `Iniciar Cockpit NTT DATA.bat` na Área de Trabalho do Windows.
2. **`scripts/setup_wsl_internal.sh`**: Script interno de provisionamento do Linux/WSL que instala FFmpeg, Node.js 20, Python 3, Whisper e PyTorch (com detecção automática de CUDA para GPUs NVIDIA).
3. **`iniciar_cockpit.bat`**: Lançador diário para Windows que inicializa o serviço via WSL e abre o navegador padrão automaticamente em `http://localhost:4545/`.
4. **`setup_mac.sh`**: Instalador automatizado para macOS.
5. **`iniciar_mac.command`**: Lançador clicável para macOS.
6. **`README.md`**: Atualizado com guias claros e diretos de uso para colaboradores no Windows e macOS.

## Validação

- Validação de sintaxe de todos os scripts bash com `bash -n`.
- Validação do fluxo do lançador macOS `iniciar_mac.command`.
- Validação de sintaxe e chamadas do Windows Batch.
