# Imagem única do laboratório. Pequena de propósito: a VM do Cloud Shell é
# efêmera e recicla o cache de imagens — imagem grande = aula perdida no pull.
FROM alpine:3.20

RUN apk add --no-cache \
      iproute2 \
      iputils \
      tcpdump \
      curl \
      busybox-extras \
      openssl \
      netcat-openbsd \
 && mkdir -p /srv /lab

# Sem processo de init: cada serviço define seu próprio `command` no compose.
CMD ["sleep", "infinity"]
