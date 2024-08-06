## Requires https://github.com/daplanet/datagrid or simular stack
export RELEASE_VERSION		:= $(shell date +%s)
export DEFAULT_NETWORK		:= public
export DOMAINNAME		:= 3umgroup.com

NETWORKS		:= public internal
STACK_NAME		:= $(shell basename "$$(pwd)")
CHART			:= docker-compose.yml

.DEFAULT_GOAL		:= all
.DEFAULT: all
.PHONY: all deploy network image clean

all: deploy

clean:
	@-docker stack rm $(STACK_NAME)

down stop start:
	@-docker compose $@ $(SERVICE)

up:
	@-docker compose $@ -d $(SERVICE)

deploy: image network 
	@docker stack deploy -c docker-compose.yml $(STACK_NAME)

$(NETWORKS):
	@-docker network create -d overlay --scope swarm $@

network: $(NETWORKS)

image:
	@exit 0

scan:
	@docker image ls | awk '/ago/ { system("docker run --rm -v /var/run/docker.sock:/var/run/docker.sock oliviabarnett/actuary:latest "$$3); }'

distclean: clean
	@-docker system prune -af

lint:
	@pipx run yamllint $(CHART)
