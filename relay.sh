#!/data/data/com.termux/files/usr/bin/bash
# Ponte celular -> relógio (gerado pelo painel_claude_github.py)
# Uso no Termux:  bash relay.sh            (usa o IP padrão abaixo)
#                 bash relay.sh 192.168.X.Y (se o relógio mudar de IP)
IP="${1:-192.168.65.131}"
REPO="coelhoparceria-cloud/painel-smalltv"
BRANCH="main"
NOME="painel_claude.jpg"
INTERVALO="${INTERVALO:-300}"        # segundos entre verificações
RAW="${RAW_BASE:-https://raw.githubusercontent.com}"
APIGH="${API_BASE:-https://api.github.com}"

command -v termux-wake-lock >/dev/null && termux-wake-lock
cd "$(dirname "$0")"
ultimo=""
echo "Ponte iniciada: GitHub $REPO -> relógio $IP (Ctrl+C para parar)"
while true; do
  hora=$(date +%H:%M)
  # versão mais recente (commit) - evita cache antigo do GitHub
  sha=$(curl -fsS -m 20 "$APIGH/repos/$REPO/commits/$BRANCH" 2>/dev/null | grep -m1 '"sha"' | cut -d'"' -f4)
  if [ -n "$sha" ]; then url="$RAW/$REPO/$sha/painel.jpg"; else sha="t$(date +%s)"; url="$RAW/$REPO/$BRANCH/painel.jpg?t=$sha"; fi
  if [ "$sha" = "$ultimo" ]; then
    echo "$hora sem novidade"
  elif curl -fsSL -m 30 -o painel_novo.jpg "$url"; then
    curl -s -m 10 -o /dev/null "http://$IP/photo/delete?name=$NOME"
    cod=$(curl -s -m 60 -o /dev/null -w '%{http_code}' -F "file=@painel_novo.jpg;filename=$NOME;type=image/jpeg" "http://$IP/photo/upload")
    if [ "${cod#2}" != "$cod" ]; then
      curl -s -m 10 -o /dev/null "http://$IP/photo/toggle?name=$NOME&state=1"
      ultimo="$sha"; echo "$hora painel atualizado no relógio"
    else
      echo "$hora o relógio não respondeu em $IP (código $cod). Celular está no Wi-Fi certo?"
    fi
  else
    echo "$hora não consegui baixar o painel do GitHub"
  fi
  sleep "$INTERVALO"
done
