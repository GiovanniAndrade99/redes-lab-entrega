#!/bin/sh
ip route del default 2>/dev/null || true
echo "area restrita do sistema" > /srv/index.html

# Versão desprotegida, na porta 8080. Continua no ar de propósito: o trabalho
# é mostrar a diferença entre as duas, não fingir que a insegura não existe.
busybox httpd -f -p 8080 -h /srv &

# ---------- TAREFA DO GRUPO ----------
# Suba a MESMA área restrita protegida por TLS, na porta 8443. Duas linhas:
#
#   openssl req -x509 -newkey rsa:2048 -nodes -days 30 -subj /CN=srv \
#           -keyout /lab/key.pem -out /lab/cert.pem 2>/dev/null
#   openssl s_server -accept 8443 -cert /lab/cert.pem -key /lab/key.pem -www -quiet &
#
# (o certificado é assinado por vocês mesmos, então o cliente usa `curl -k`.
#  Vale uma linha na cartilha explicando por que o navegador reclama disso.)

wait
