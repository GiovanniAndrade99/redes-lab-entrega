#!/bin/sh
# Roda UMA vez, numa Cloud Shell limpa, antes de liberar o laboratório para a
# turma. Confere as quatro capacidades de que o trabalho depende e que não
# estão garantidas por documentação nenhuma.
falhas=0
ok(){ printf '  \033[32m OK \033[0m %s\n' "$1"; }
nok(){ printf '  \033[31mNAO\033[0m %s — %s\n' "$1" "$2"; falhas=$((falhas+1)); }

echo; echo "=== Autoteste do ambiente ==="; echo

docker info >/dev/null 2>&1 && ok "docker responde sem sudo" || nok "docker" "sem acesso ao daemon"
docker compose version >/dev/null 2>&1 && ok "docker compose (plugin v2)" || \
  { docker-compose version >/dev/null 2>&1 && ok "docker-compose (v1)" || nok "compose" "nenhuma versão encontrada"; }

if docker network create --subnet 10.0.99.0/24 _autoteste >/dev/null 2>&1; then
  ok "criação de rede com sub-rede própria"; docker network rm _autoteste >/dev/null 2>&1
else nok "docker network create" "não consegui criar bridge com subnet"; fi

docker build -t redes-lab-base:1 base/ >/dev/null 2>&1 && ok "imagem base construída" || nok "build" "apk falhou? veja: docker build base/"

if docker run --rm redes-lab-base:1 sh -c 'tcpdump --version' >/dev/null 2>&1; then ok "tcpdump existe na imagem"; else nok "tcpdump" "pacote ausente"; fi

if docker run --rm --cap-add NET_RAW redes-lab-base:1 sh -c 'timeout 2 tcpdump -i any -c1 >/dev/null 2>&1; [ $? -le 124 ]'; then
  ok "tcpdump consegue abrir a interface (NET_RAW efetivo)"
else nok "captura" "NET_RAW negado — E2 e E5 não funcionam"; fi

if docker run --rm --cap-add NET_ADMIN --sysctl net.ipv4.ip_forward=1 redes-lab-base:1 \
     sh -c 'grep -q 1 /proc/sys/net/ipv4/ip_forward' 2>/dev/null; then
  ok "sysctl net.ipv4.ip_forward por contêiner"
else nok "ip_forward" "sysctl recusado — E2/E4/E5 não roteiam"; fi

if docker run --rm redes-lab-base:1 sh -c 'apk add --no-cache bird >/dev/null 2>&1 && bird --version' >/dev/null 2>&1; then
  ok "pacote bird disponível no Alpine (E4)"
else nok "bird" "sem pacote: E4 precisa de outro roteador dinâmico"; fi

echo
[ "$falhas" -eq 0 ] && printf '\033[32mAmbiente aprovado — pode liberar para a turma.\033[0m\n\n' \
  || { printf '\033[31m%s item(ns) falharam. NÃO libere antes de resolver.\033[0m\n\n' "$falhas"; exit 1; }
