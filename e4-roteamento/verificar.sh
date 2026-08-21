#!/bin/sh
# Provas da Entrega 4. Mede a rede em três momentos: normal, com o trânsito 1
# derrubado, e restaurada. Convergência é diferença entre momentos — medir um
# só não diz nada.
falhas=0
ok()  { printf '  \033[32m OK \033[0m %s\n' "$1"; }
nok() { printf '  \033[31mNAO \033[0m %s\n' "$1"; falhas=$((falhas+1)); }
obs() { printf '        observado: %s\n' "$1"; }
via(){ docker exec e4-r1 sh -c "ip route get 10.0.20.10 2>/dev/null" | head -1; }
alcanca(){ docker exec e4-host-a ping -c1 -W2 10.0.20.10 >/dev/null 2>&1; }
esperar(){ i=0; while [ $i -lt "$1" ]; do alcanca && return 0; i=$((i+1)); sleep 2; done; return 1; }

echo; echo "=== ENTREGA 4 — a rota se refaz sozinha ==="; echo
docker network connect --ip 10.0.30.11 e4_seg-t1 e4-r1 >/dev/null 2>&1
sleep 8

if alcanca; then ok "estado normal: host-a alcança host-b"; obs "$(via)"; else nok "estado normal já está quebrado"; obs "$(via)"; fi
ANTES=$(via)
case "$ANTES" in *10.0.30.12*) ok "o caminho normal usa o trânsito 1"; obs "$ANTES";;
  *10.0.40.12*) ok "o caminho normal usa o trânsito 2"; obs "$ANTES";;
  *) nok "não consegui ler o próximo salto em r1"; obs "${ANTES:-<vazio>}";; esac
echo

echo "  derrubando o trânsito 1 e cronometrando a recuperação..."
docker network disconnect e4_seg-t1 e4-r1 >/dev/null 2>&1
I=$(date +%s)
if esperar 30; then
  F=$(date +%s); DEPOIS=$(via)
  ok "a rede se recuperou sozinha"; obs "levou $((F-I))s"
  [ $((F-I)) -le 2 ] && obs "praticamente instantâneo: com custos iguais o RIP já tinha os DOIS caminhos instalados, e derrubar um só deixou o outro em pé"
  if [ "$DEPOIS" != "$ANTES" ]; then ok "o próximo salto MUDOU de caminho"; obs "antes: $ANTES / depois: $DEPOIS"
  else nok "o caminho é idêntico ao de antes — nada convergiu"; obs "$DEPOIS"; fi
else
  nok "60s depois a rede continua morta — rota estática não se refaz"
  obs "r1 ainda diz: $(via)"
fi
echo

echo "  religando o trânsito 1..."
docker network connect --ip 10.0.30.11 e4_seg-t1 e4-r1 >/dev/null 2>&1
if esperar 20; then ok "a rede continua de pé com os dois caminhos"; obs "$(via)"; else nok "a rede não voltou após religar"; fi

echo
[ "$falhas" -eq 0 ] && { printf '\033[32mENTREGA 4 COMPLETA\033[0m\n\n'; } || { printf '\033[31m%s prova(s) vermelha(s).\033[0m\n\n' "$falhas"; exit 1; }
