# Entrega 3 — O serviço não pode cair

## O cliente distingue réplica morta de réplica particionada?

Não. Do ponto de vista do `cliente.sh`, os dois casos produzem exatamente o mesmo sintoma: a ausência de resposta dentro do tempo limite (`curl -m 1`). Quando `replica1` é parada (`docker stop`), ela simplesmente deixa de existir na rede — não há nada para responder. Quando `replica3` é particionada (`docker network disconnect`), ela continua rodando e processando normalmente, só que nenhum pacote chega até ela nem sai dela. Para quem está do lado de fora fazendo a chamada, as duas situações chegam da mesma forma: silêncio, até o timeout expirar. Não existe, nesse protocolo (HTTP sobre TCP/IP), um sinal diferente que separe "a máquina não existe mais" de "a máquina existe mas está inalcançável" — essa é justamente a dificuldade central de sistemas distribuídos descrita no enunciado.

## Isso é um problema?

Para o que esse cliente faz — balanceamento simples por tentativa e erro, escolhendo a primeira réplica que responder — **não é um problema prático**: a ação correta é a mesma nos dois casos (ignorar a réplica que não respondeu e tentar a próxima, ou declarar `INDISPONIVEL` se nenhuma responder), então a distinção não mudaria o comportamento do cliente.

Mas a distinção **passaria a importar** em qualquer camada que precise tomar uma decisão permanente baseada na falha — por exemplo, um orquestrador que remove definitivamente uma réplica da lista de membros do cluster, ou um mecanismo de eleição de líder. Se o orquestrador trata "particionada" como se fosse "morta" e promove outra réplica a líder, e depois a réplica particionada volta a se comunicar (a partição acaba, mas o processo nunca parou), ficam **duas réplicas acreditando ser a autoridade correta ao mesmo tempo** — o problema clássico de *split-brain*. Então a resposta depende da camada: para um cliente que só quer "qualquer resposta válida, rápido", a ambiguidade é inofensiva; para qualquer sistema que precise de consenso sobre quem está vivo, ela é um risco real.
