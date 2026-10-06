# Entrega 2 — O roteador e o encapsulamento

## Rotas adicionadas

No `docker-compose.yml`, dois hosts receberam uma rota explícita para a sub-rede do outro segmento, apontando para a perna do roteador no próprio segmento:

| Host | Segmento | Rota adicionada | Via (roteador) |
|---|---|---|---|
| e2-host-a1 | A (10.0.10.0/24) | `10.0.20.0/24` | 10.0.10.254 |
| e2-host-b1 | B (10.0.20.0/24) | `10.0.10.0/24` | 10.0.20.254 |
| e2-host-a2 | A (10.0.10.0/24) | — (nenhuma, grupo de controle) | — |

`e2-host-a2` foi deliberadamente mantido sem rota: ele prova que o isolamento entre segmentos continua existindo por padrão, e que só quem recebeu rota explícita consegue atravessar o roteador.

## Por que o endereço MAC muda e o IP não

Um pacote IP viaja encapsulado dentro de um quadro Ethernet, e os dois endereços vivem em camadas diferentes do modelo OSI com propósitos diferentes. O endereço IP (camada 3) identifica a origem e o destino **de ponta a ponta** — ele não muda ao longo do caminho porque representa "quem enviou" e "para quem", informação que só faz sentido fim a fim, continuando válida em cada roteador do percurso.

Já o endereço MAC (camada 2) identifica apenas o próximo salto dentro de um único segmento de rede (domínio de broadcast). Quando o roteador recebe o quadro Ethernet pela interface do segmento A, ele descarta esse quadro inteiramente — o cabeçalho Ethernet já cumpriu seu papel ao entregar o pacote até ali — e extrai só o pacote IP de dentro dele. Em seguida, para repassar esse mesmo pacote IP pela interface do segmento B, o roteador monta um quadro Ethernet novo, com seu próprio MAC de origem (da interface em B) e o MAC de destino do host B que vai receber o pacote.

É exatamente isso que as capturas `perna-a.pcap` e `perna-b.pcap` mostram: o mesmo pacote ICMP, com o mesmo IP de origem (10.0.10.10) nas duas capturas, mas com MAC de origem diferente em cada perna — porque o quadro Ethernet é reconstruído a cada segmento que o pacote atravessa, enquanto o endereçamento IP permanece como a identidade estável de ponta a ponta. O TTL caindo de 64 para 63 confirma que esse encaminhamento (um "salto" de roteamento) realmente aconteceu.

## Evidências

- `perna-a.pcap` e `perna-b.pcap` — capturas simultâneas nas duas interfaces do roteador, geradas automaticamente por `make verificar E=2` quando todos os testes passam.
- `evidencias/verificacao.txt` — saída de `make verificar E=2` (gerado por `make evidencias E=2`).
- Print do Wireshark (`evidencias/wireshark-mac-vs-ip.png`) com o campo de MAC de origem destacado (mudou entre as duas capturas) e o campo de IP de origem destacado (permaneceu igual).
