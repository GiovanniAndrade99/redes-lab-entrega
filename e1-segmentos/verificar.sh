#!/bin/sh
# Provas da Entrega 1. Testa os DOIS lados: o que tem de funcionar e o que
# tem de falhar. Um teste só do lado negativo passaria com tudo desligado.
falhas=0
ok()  { printf '  \033[32m OK \033[0m %s\n' "$1"; }
nok() { printf '  \033[31mNAO \033[0m %s\n' "$1"; falhas=$((falhas+1)); }
obs() { printf '        observado: %s\n' "$1"; }

echo
echo "=== ENTREGA 1 — dois segmentos e um serviço ==="
echo

for c in e1-host-a1 e1-host-a2 e1-srv-a e1-host-b1 e1-host-b2; do
  if docker inspect -f '{{.State.Running}}' "$c" 2>/dev/null | grep -q true; then
    ip=$(docker exec "$c" sh -c "ip -4 -o addr show eth0 | awk '{print \$4}'" 2>/dev/null)
    ok "contêiner $c no ar"; obs "$ip"
  else
    nok "contêiner $c NÃO existe ou não está no ar"
    # Sem isto, um servidor que morre na largada aparece só como um curl vazio
    # lá embaixo — erro real, pista nenhuma.
    log=$(docker logs --tail 2 "$c" 2>&1 | tr '\n' ' ')
    [ -n "$log" ] && obs "última saída do contêiner: $log" || obs "o contêiner nem chegou a existir (make up E=1?)"
  fi
done
echo

# --- lado positivo: dentro do mesmo segmento tem de funcionar ---
o=$(docker exec e1-host-a1 ping -c1 -W1 10.0.10.11 2>&1 || true)
case "$o" in *" 0% packet loss"*) ok "A: host-a1 alcança host-a2";
    obs "$(echo "$o" | sed -n '2p')";; *) nok "A: host-a1 NÃO alcança host-a2"; obs "$(echo "$o" | tail -2 | tr '\n' ' ')";; esac

o=$(docker exec e1-host-b1 ping -c1 -W1 10.0.20.11 2>&1 || true)
case "$o" in *" 0% packet loss"*) ok "B: host-b1 alcança host-b2";
    obs "$(echo "$o" | sed -n '2p')";; *) nok "B: host-b1 NÃO alcança host-b2"; obs "$(echo "$o" | tail -2 | tr '\n' ' ')";; esac

o=$(docker exec e1-host-a2 curl -s -m 2 http://10.0.10.20:8080/ 2>&1 || true)
case "$o" in *"srv-a"*) ok "A: host-a2 obtém a página do servidor"; obs "$o";;
    *) nok "A: host-a2 não obteve a página"; obs "${o:-<vazio>}";; esac
echo

# --- lado negativo: e tem de falhar PELO MOTIVO CERTO ---
o=$(docker exec e1-host-a1 ping -c1 -W1 10.0.20.10 2>&1 || true)
case "$o" in
  *nreachable*) ok "isolamento: A não alcança B (camada 3)"; obs "$(echo "$o" | grep -i unreach | head -1)";;
  *) nok "isolamento: falhou, mas NÃO por 'Network is unreachable'"; obs "$(echo "$o" | tail -2 | tr '\n' ' ')";;
esac

o=$(docker exec e1-host-b1 curl -s -m 2 http://10.0.10.20:8080/ 2>&1; echo "rc=$?")
case "$o" in *"srv-a"*) nok "isolamento QUEBRADO: B chegou no servidor de A"; obs "$o";;
    *) ok "isolamento: B não chega no servidor de A"; obs "curl terminou sem resposta ($(echo "$o" | tail -1))";; esac

echo
if [ "$falhas" -eq 0 ]; then
  printf '\033[32mENTREGA 1 COMPLETA\033[0m — gere as evidências: make evidencias E=1\n\n'
else
  printf '\033[31m%s prova(s) ainda vermelha(s).\033[0m É esperado no começo: seu trabalho é deixar tudo verde.\n\n' "$falhas"
  exit 1
fi
