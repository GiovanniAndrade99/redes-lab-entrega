#!/bin/sh
# Provas da Entrega 5. As duas metades se sustentam: se a captura estivesse
# quebrada, "o segredo não apareceu" passaria sozinho. Por isso o primeiro
# teste exige ACHAR o segredo, e o segundo exige que houve tráfego capturado.
falhas=0
ok()  { printf '  \033[32m OK \033[0m %s\n' "$1"; }
nok() { printf '  \033[31mNAO \033[0m %s\n' "$1"; falhas=$((falhas+1)); }
obs() { printf '        observado: %s\n' "$1"; }

TOKEN=$(tr -d ' \n\r' < token.txt 2>/dev/null)
echo; echo "=== ENTREGA 5 — o pacote entrega o segredo ==="; echo

if [ -z "$TOKEN" ] || [ "$TOKEN" = "GRUPO-EXEMPLO-TROQUE-ISTO" ]; then
  nok "token.txt ainda é o de exemplo"
  obs "ponha o identificador do SEU grupo: a evidência tem de ser do grupo, não copiável"
  printf '\n\033[31m1 prova vermelha.\033[0m\n\n'; exit 1
fi
ok "token do grupo definido"; obs "$TOKEN"

IB=$(docker exec e5-router sh -c "ip -4 -o addr show | awk '/10.0.20.254\//{print \$2}'" 2>/dev/null | head -1)
[ -n "$IB" ] && { ok "roteador com perna no segmento do servidor"; obs "$IB"; } || { nok "não achei a perna do roteador no segmento B"; }
echo

capturar(){ # $1=porta $2=arquivo
  docker exec e5-router sh -c "rm -f /lab-cap/$2" 2>/dev/null
  docker exec -d e5-router sh -c "mkdir -p /lab-cap; tcpdump -i $IB -n -s0 -w /lab-cap/$2 tcp port $1" 2>/dev/null
  sleep 2
}
parar(){ docker exec e5-router sh -c "pkill tcpdump" 2>/dev/null; sleep 1; }
pacotes(){ docker exec e5-router sh -c "tcpdump -r /lab-cap/$1 2>/dev/null | wc -l" 2>/dev/null | tr -d ' '; }
achou(){ docker exec e5-router sh -c "tcpdump -A -r /lab-cap/$1 2>/dev/null | grep -c '$TOKEN'" 2>/dev/null | tr -d ' '; }

# --- 1) sem proteção: o segredo TEM de aparecer ---
capturar 8080 claro.pcap
R1=$(docker exec e5-cliente curl -s -m 3 -H "Authorization: Bearer $TOKEN" http://10.0.20.20:8080/ 2>&1)
parar
N1=$(pacotes claro.pcap); A1=$(achou claro.pcap)
case "$R1" in *"area restrita"*) ok "HTTP: o cliente entrou na área restrita"; obs "$R1";;
  *) nok "HTTP: o cliente não obteve a página"; obs "${R1:-<vazio>}";; esac
if [ "${A1:-0}" -gt 0 ] 2>/dev/null; then
  ok "HTTP: o segredo do grupo APARECE na captura do roteador"; obs "$A1 pacote(s) contendo \"$TOKEN\", em $N1 capturados"
else nok "HTTP: não encontrei o segredo na captura"; obs "$N1 pacote(s) capturados, 0 com o token"; fi
echo

# --- 2) com TLS: o segredo NÃO pode aparecer, mas tem de haver tráfego ---
capturar 8443 cifrado.pcap
R2=$(docker exec e5-cliente curl -sk -m 5 -H "Authorization: Bearer $TOKEN" https://10.0.20.20:8443/ 2>&1)
parar
N2=$(pacotes cifrado.pcap); A2=$(achou cifrado.pcap)
if [ "${N2:-0}" -gt 0 ] 2>/dev/null; then ok "HTTPS: houve tráfego capturado (a captura está viva)"; obs "$N2 pacote(s)"
else nok "HTTPS: captura vazia — sem tráfego não há o que provar"; obs "porta 8443 no ar?"; fi
if [ "${N2:-0}" -gt 0 ] 2>/dev/null && [ "${A2:-1}" -eq 0 ] 2>/dev/null; then
  ok "HTTPS: o segredo NÃO aparece na captura"; obs "0 ocorrências de \"$TOKEN\" em $N2 pacotes"
elif [ "${A2:-0}" -gt 0 ] 2>/dev/null; then nok "HTTPS: o segredo apareceu mesmo assim"; obs "$A2 ocorrência(s) — a conexão foi mesmo cifrada?"; fi

echo
if [ "$falhas" -eq 0 ]; then
  docker exec e5-router sh -c "cat /lab-cap/claro.pcap"   > claro.pcap   2>/dev/null
  docker exec e5-router sh -c "cat /lab-cap/cifrado.pcap" > cifrado.pcap 2>/dev/null
  printf '\033[32mENTREGA 5 COMPLETA\033[0m — claro.pcap e cifrado.pcap salvos.\n'
  printf 'Abra os dois no Wireshark: a imagem do primeiro é a capa da cartilha.\n\n'
else printf '\033[31m%s prova(s) vermelha(s).\033[0m\n\n' "$falhas"; exit 1; fi
