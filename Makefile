# Default make ENV is development. use make [target] ENV=prod for production
ENV ?= dev

.DEFAULT_GOAL:=help

ifeq ($(filter $(ENV),dev prod),)
$(error The ENV variable is invalid. must be one of <prod|dev> )
endif

COMPOSE_FILES_PATH := -f docker-compose.yml -f ./$(ENV).yml
COMPOSE_PREFIX_CMD := cd docker/.compose && COMPOSE_DOCKER_CLI_BUILD=1

# --------------------------

.PHONY: build deploy start stop logs restart shell up rm help

deploy:			## Deploy Prod Image (alias for `make up ENV=prod`)
	@make up ENV=prod

up:				## Start service, rebuild if necessary
	${COMPOSE_PREFIX_CMD} docker-compose $(COMPOSE_FILES_PATH) up --build -d

build:			## Build The Image
	${COMPOSE_PREFIX_CMD} docker-compose $(COMPOSE_FILES_PATH) build

down:			## Down service and do clean up
	${COMPOSE_PREFIX_CMD} docker-compose $(COMPOSE_FILES_PATH) down

start:			## Start Container
	${COMPOSE_PREFIX_CMD} docker-compose $(COMPOSE_FILES_PATH) start

stop:			## Stop Container
	${COMPOSE_PREFIX_CMD} docker-compose $(COMPOSE_FILES_PATH) stop

logs:			## Tail container logs with -n 1000
	@${COMPOSE_PREFIX_CMD} docker-compose $(COMPOSE_FILES_PATH) logs --follow --tail=1000

images:			## Show Image created by this Makefile (or Docker-compose in docker)
	@${COMPOSE_PREFIX_CMD} docker-compose $(COMPOSE_FILES_PATH) images

shell:			## Enter container shell
	@${COMPOSE_PREFIX_CMD} docker-compose $(COMPOSE_FILES_PATH) exec app /bin/sh

restart:		## Restart container
	@${COMPOSE_PREFIX_CMD} docker-compose $(COMPOSE_FILES_PATH) restart

rm:				## Remove current container
	@${COMPOSE_PREFIX_CMD} docker-compose $(COMPOSE_FILES_PATH) rm -f

help:       	## Show this help.
	@echo "Make Application Docker Images and Containers using Docker-Compose files in 'docker' Dir."
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m ENV=<prod|dev> (default: dev)\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
