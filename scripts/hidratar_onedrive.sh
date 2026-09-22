#!/usr/bin/env bash
#
# hidratar_onedrive.sh
#
# Monitor e assistente de hidratação (download) de vídeos do OneDrive para o Mac.
# Detecta arquivos 'dataless' (apenas na nuvem) e acompanha o download em tempo real.
#
set -euo pipefail

TARGET_DIR="${1:-/Users/gcostabe/Library/CloudStorage/OneDrive-NTTDATAEMEAL/REEF Formación - 02. Formaciones Mapfre}"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Erro: pasta não encontrada: $TARGET_DIR" >&2
  exit 1
fi

echo "=============================================================="
echo " AXET - Verificador de Hidratação do OneDrive"
echo "=============================================================="
echo "Pasta analisada: $TARGET_DIR"
echo "--------------------------------------------------------------"

python3 - <<PYEOF
import os, sys, time, subprocess

base = "$TARGET_DIR"
UF_DATALESS = 0x40000000

def get_stats():
    total = 0
    dataless = []
    for root, dirs, files in os.walk(base):
        for f in files:
            if f.lower().endswith(('.mp4', '.mov', '.mkv', '.avi', '.m4v')):
                total += 1
                p = os.path.join(root, f)
                try:
                    st = os.stat(p)
                    if st.st_flags & UF_DATALESS:
                        dataless.append(p)
                except Exception:
                    pass
    return total, dataless

total, pending = get_stats()
hydrated = total - len(pending)

print(f"Total de vídeos identificados : {total}")
print(f"Vídeos já baixados no Mac (💾): {hydrated}")
print(f"Vídeos pendentes na nuvem (☁️): {len(pending)}")
print("--------------------------------------------------------------")

if len(pending) == 0:
    print("✅ Todos os vídeos já estão baixados e disponíveis localmente!")
    sys.exit(0)

print(f"⚠️  Existem {len(pending)} vídeos que precisam ser baixados do OneDrive.")
print("")
print("👉 Abrindo o Finder na pasta raiz dos vídeos...")
subprocess.run(["open", "-R", base])
print("")
print("💡 AÇÃO NECESSÁRIA (apenas 1 vez para baixar todos):")
print("   1. No Finder que acabou de abrir, a pasta já está selecionada.")
print("   2. Clique com o BOTÃO DIREITO nela.")
print("   3. Selecione 'Sempre Manter Neste Dispositivo' (ou 'Baixar Agora').")
print("")
print("Acompanhando o download em tempo real (Ctrl+C para sair):")

prev_count = len(pending)
while True:
    time.sleep(3)
    t, pend = get_stats()
    curr_count = len(pend)
    baixados = total - curr_count
    pct = (baixados / total * 100) if total > 0 else 100
    
    diff = prev_count - curr_count
    status_str = f"📥 Baixados: {baixados}/{total} ({pct:.1f}%) | Pendentes na nuvem: {curr_count}"
    if diff > 0:
        status_str += f" (-{diff} novos baixados!)"
    
    print(f"\r{status_str}", end="", flush=True)
    prev_count = curr_count
    
    if curr_count == 0:
        print("\n\n🎉 Todos os vídeos foram 100% baixados com sucesso para o Mac!")
        print("Agora você pode executar os lotes no AXET Cockpit sem nenhum erro de extração.")
        break
PYEOF
