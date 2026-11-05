# Entrega 4 — A rota se refaz sozinha

## Tempo de convergência medido

Na nossa execução, a rede levou **17 segundos** para voltar a alcançar `host-b` depois de o trânsito 1 ser derrubado nas duas pontas, convergindo para o desvio de dois saltos por `r3` (confirmado pela mudança do próximo salto em `r1`, de `10.0.30.12` para `10.0.40.13`).

## E com 50 roteadores em vez de 3?

RIP é vetor de distância: cada roteador só troca sua tabela completa com os vizinhos diretos, em ciclos periódicos (a cada 30 segundos, por padrão), e uma rota só é considerada morta depois de um temporizador de até 180 segundos sem atualização. Isso significa que uma mudança de topologia não se propaga instantaneamente — ela avança um salto por ciclo de anúncio. Em uma rede de 3 roteadores como a nossa, a notícia de que o trânsito 1 caiu precisa atravessar poucos saltos até chegar a todo mundo, por isso convergiu em segundos.

Numa rede de 50 roteadores, na pior hipótese a notícia de uma falha pode precisar atravessar dezenas de saltos até alcançar o roteador mais distante, e cada salto custa um ciclo de anúncio inteiro — ou seja, o tempo de convergência cresce proporcionalmente ao diâmetro da rede (número de saltos entre os pontos mais distantes), não ao tamanho dela. Pior ainda: durante essa propagação lenta, RIP é vulnerável ao problema de contagem até o infinito (count-to-infinity) — roteadores podem ficar repassando uns aos outros uma rota que na verdade já morreu, incrementando a métrica a cada troca, até ela alcançar o valor que o protocolo trata como "inalcançável" (16, no RIP). Isso pode levar a convergência de segundos, na nossa rede pequena, para minutos numa rede de 50 roteadores — tempo em que o tráfego pode ficar sendo roteado por caminhos que não existem mais, ou até em loop. É exatamente esse limite de escala que torna RIP inadequado para redes grandes, e é a razão de protocolos como OSPF (estado de enlace, convergência quase simultânea em toda a rede) existirem.
