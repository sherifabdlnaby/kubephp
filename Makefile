.DEFAULT_GOAL:=help

COMPOSE_PREFIX_CMD := DOCKER_BUILDKIT=1 COMPOSE_DOCKER_CLI_BUILD=1

COMMAND ?= /bin/sh

# --------------------------

.PHONY: deploy up build-up build down start stop logs images ps command \
	command-root shell-root shell restart rm help demo-clean demo-deploy demo-setup demo-up

deploy:			## Start using Prod Image in Prod Mode
	${COMPOSE_PREFIX_CMD} docker compose -f docker-compose.prod.yml up --build -d

up:				## Start service
	@echo "Starting Application \n (note: Web container will wait App container to start before starting)"
	${COMPOSE_PREFIX_CMD} docker compose up -d

build-up:       ## Start service, rebuild if necessary
	${COMPOSE_PREFIX_CMD} docker compose up --build -d

build:			## Build The Image
	${COMPOSE_PREFIX_CMD} docker compose build

down:			## Down service and do clean up
	${COMPOSE_PREFIX_CMD} docker compose down

start:			## Start Container
	${COMPOSE_PREFIX_CMD} docker compose start

stop:			## Stop Container
	${COMPOSE_PREFIX_CMD} docker compose stop

logs:			## Tail container logs with -n 1000
	@${COMPOSE_PREFIX_CMD} docker compose logs --follow --tail=100

images:			## Show Image created by this Makefile (or Docker-compose in docker)
	@${COMPOSE_PREFIX_CMD} docker compose images

ps:			## Show Containers Running
	@${COMPOSE_PREFIX_CMD} docker compose ps

command:	  ## Execute command ( make command COMMAND=<command> )
	@${COMPOSE_PREFIX_CMD} docker compose run --rm app ${COMMAND}

command-root:	 ## Execute command as root ( make command-root COMMAND=<command> )
	@${COMPOSE_PREFIX_CMD} docker compose run --rm -u root app ${COMMAND}

shell-root:			## Enter container shell as root
	@${COMPOSE_PREFIX_CMD} docker compose exec -u root app /bin/sh

shell:			## Enter container shell
	@${COMPOSE_PREFIX_CMD} docker compose exec app /bin/sh

restart:		## Restart container
	@${COMPOSE_PREFIX_CMD} docker compose restart

rm:				## Remove current container
	@${COMPOSE_PREFIX_CMD} docker compose rm -f

# Demo app setup
demo-setup:		## Download the latest Symfony Demo app for testing
	@if [ -d "app" ]; then \
		echo "Warning: 'app' directory already exists. Remove it first if you want a fresh install."; \
		exit 1; \
	fi
	@echo "Downloading latest Symfony Demo application..."
	docker run --rm -v $(PWD):/app -w /app composer:2 \
		create-project symfony/symfony-demo app --no-install --no-scripts
	@echo "Installing composer dependencies..."
	docker run --rm -v $(PWD)/app:/app -w /app composer:2 \
		install --ignore-platform-reqs --no-scripts
	@echo "Demo app downloaded to ./app/"
	@echo "Run 'make demo-up' to start the development environment"

demo-up:		## Start the demo app in dev mode (APP_BASE_DIR=app)
	APP_BASE_DIR=./app make build-up

demo-deploy:		## Start the demo app in prod mode (APP_BASE_DIR=app)
	APP_BASE_DIR=./app make deploy

demo-clean:		## Remove the demo app directory
	rm -rf app
	@echo "Demo app removed"