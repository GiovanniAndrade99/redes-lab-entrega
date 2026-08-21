# Laboratório de Redes e Sistemas Distribuídos
# Uso:  make base      → constrói a imagem (uma vez por sessão do Cloud Shell)
#       make up E=1    → sobe a topologia da entrega 1
#       make verificar E=1
#       make down E=1
#       make evidencias E=1

E ?= 1
DIR := $(firstword $(wildcard e$(E)-*))

# Cloud Shell usa o plugin v2 (`docker compose`); algumas máquinas têm o v1.
COMPOSE := $(shell docker compose version >/dev/null 2>&1 && echo "docker compose" || echo "docker-compose")

.PHONY: base up down verificar evidencias limpar ajuda autoteste

ajuda:
	@echo "make base            constrói a imagem redes-lab-base:1"
	@echo "make up E=<1..5>     sobe a topologia da entrega"
	@echo "make verificar E=<n> roda as provas da entrega (começa VERMELHO de propósito)"
	@echo "make evidencias E=<n> gera evidencias/ para anexar na entrega"
	@echo "make down E=<n>      derruba a topologia"
	@echo "make limpar          derruba TODAS as entregas e remove redes órfãs"

base:
	docker build -t redes-lab-base:1 base/

up: base
	@test -n "$(DIR)" || (echo "Entrega E=$(E) não existe"; exit 1)
	cd $(DIR) && $(COMPOSE) up -d
	@echo "Topologia da entrega $(E) no ar. Rode: make verificar E=$(E)"

down:
	cd $(DIR) && $(COMPOSE) down -v --remove-orphans

verificar:
	@cd $(DIR) && sh verificar.sh

evidencias:
	@cd $(DIR) && mkdir -p evidencias && sh verificar.sh 2>&1 | tee evidencias/verificacao.txt
	@echo "Gravado em $(DIR)/evidencias/ — commite e anexe na entrega."

limpar:
	-@for d in e1-* e2-* e3-* e4-* e5-*; do (cd $$d && $(COMPOSE) down -v --remove-orphans 2>/dev/null); done
	-@docker network prune -f

autoteste:
	@sh autoteste.sh
