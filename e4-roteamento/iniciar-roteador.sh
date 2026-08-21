#!/bin/sh
# Roda dentro de r1 e r2. A variável ROLE diz qual dos dois é.
ip route del default 2>/dev/null || true
sysctl -w net.ipv4.ip_forward=1 2>/dev/null || true

# ---------- MODO ATUAL: rotas estáticas ----------
# Funciona: host-a alcança host-b pelo trânsito 1. Mas é uma decisão congelada
# na mão de quem escreveu. Derrube o trânsito 1 e nada se refaz sozinho.
case "$ROLE" in
  r1) ip route add 10.0.20.0/24 via 10.0.30.12 ;;
  r2) ip route add 10.0.10.0/24 via 10.0.30.11 ;;
esac
exec sleep infinity

# ---------- TAREFA DO GRUPO ----------
# Troque o bloco acima por roteamento dinâmico, apagando o `case`/`exec` e
# deixando a linha abaixo. Antes disso, abra bird-r1.conf e bird-r2.conf: cada
# roteador precisa do SEU próprio `router id`, e está faltando em um deles.
#
#   mkdir -p /run/bird && exec bird -f -c "/lab/bird-$ROLE.conf"
