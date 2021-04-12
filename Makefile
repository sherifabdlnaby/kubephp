.DEFAULT_GOAL:=help

COMPOSE_PREFIX_CMD := DOCKER_BUILDKIT=1 COMPOSE_DOCKER_CLI_BUILD=1 

# --------------------------

.PHONY: build deploy start stop logs restart shell up rm help

deploy:			## Deploy Prod Image (alias for `make up ENV=prod`)
	${COMPOSE_PREFIX_CMD} docker-compose -f docker-compose.prod.yml up --build -d

up:				## Start service
	${COMPOSE_PREFIX_CMD} docker-compose up -d

build-up:       ## Start service, rebuild if necessary
	${COMPOSE_PREFIX_CMD} docker-compose up --build -d

build:			## Build The Image
	${COMPOSE_PREFIX_CMD} docker-compose build

down:			## Down service and do clean up
	${COMPOSE_PREFIX_CMD} docker-compose down

start:			## Start Container
	${COMPOSE_PREFIX_CMD} docker-compose start

stop:			## Stop Container
	${COMPOSE_PREFIX_CMD} docker-compose stop

logs:			## Tail container logs with -n 1000
	@${COMPOSE_PREFIX_CMD} docker-compose logs --follow --tail=100

images:			## Show Image created by this Makefile (or Docker-compose in docker)
	@${COMPOSE_PREFIX_CMD} docker-compose images

ps:			## Show Containers Running
	@${COMPOSE_PREFIX_CMD} docker-compose ps

shell:			## Enter container shell
	@${COMPOSE_PREFIX_CMD} docker-compose exec app /bin/bash

shell-root:			## Enter container shell
	@${COMPOSE_PREFIX_CMD} docker-compose exec -u root app /bin/bash

restart:		## Restart container
	@${COMPOSE_PREFIX_CMD} docker-compose restart

rm:				## Remove current container
	@${COMPOSE_PREFIX_CMD} docker-compose rm -f

help:       	## Show this help.
	@echo "Make Application Docker Images and Containers using Docker-Compose files in 'docker' Dir."
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m ENV=<prod|dev> (default: dev)\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)