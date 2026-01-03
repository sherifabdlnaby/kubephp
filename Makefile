.DEFAULT_GOAL:=help

COMMAND ?= /bin/sh

# --------------------------

.PHONY: deploy up build-up build down start stop logs images ps command \
	command-root shell-root shell restart rm help \
	demo/symfony/setup demo/symfony/up demo/symfony/deploy demo/symfony/clean \
	demo/laravel/setup demo/laravel/up demo/laravel/deploy demo/laravel/clean

deploy:			## Start using Prod Image in Prod Mode
	docker compose -f docker-compose.prod.yml up --build -d

up:				## Start service
	@echo "Starting Application \n (note: Web container will wait App container to start before starting)"
	docker compose up -d

build-up:       ## Start service, rebuild if necessary
	docker compose up --build -d

build:			## Build The Image
	docker compose build

down:			## Down service and do clean up
	docker compose down

start:			## Start Container
	docker compose start

stop:			## Stop Container
	docker compose stop

logs:			## Tail container logs with -n 1000
	@docker compose logs --follow --tail=100

images:			## Show Image created by this Makefile (or Docker-compose in docker)
	@docker compose images

ps:			## Show Containers Running
	@docker compose ps

command:	  ## Execute command ( make command COMMAND=<command> )
	@docker compose run --rm app ${COMMAND}

command-root:	 ## Execute command as root ( make command-root COMMAND=<command> )
	@docker compose run --rm -u root app ${COMMAND}

shell-root:			## Enter container shell as root
	@docker compose exec -u root app /bin/sh

shell:			## Enter container shell
	@docker compose exec app /bin/sh

restart:		## Restart container
	@docker compose restart

rm:				## Remove current container
	@docker compose rm -f

# Symfony demo app setup
demo/symfony/setup:		## Download the latest Symfony Demo app for testing
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
	@echo "Run 'make demo/symfony/up' to start the development environment"

demo/symfony/up:		## Start the Symfony demo app in dev mode (APP_BASE_DIR=app)
	APP_BASE_DIR=./app make build-up
	@echo "Visit http://localhost:8080 to see the Symfony demo app"

demo/symfony/deploy:		## Start the Symfony demo app in prod mode (APP_BASE_DIR=app)
	APP_BASE_DIR=./app make deploy

demo/symfony/clean:		## Remove the Symfony demo app directory
	rm -rf app
	@echo "Symfony demo app removed"

# Laravel demo app setup
demo/laravel/setup:		## Download the latest Laravel application for testing
	@if [ -d "app" ]; then \
		echo "Warning: 'app' directory already exists. Remove it first if you want a fresh install."; \
		exit 1; \
	fi
	@echo "Downloading latest Laravel application..."
	docker run --rm -v $(PWD):/app -w /app composer:2 \
		create-project laravel/laravel app --no-install --no-scripts
	@echo "Installing composer dependencies..."
	docker run --rm -v $(PWD)/app:/app -w /app composer:2 \
		install --ignore-platform-reqs --no-scripts
	@echo "Setting up Laravel environment..."
	@if [ ! -f "app/.env" ] && [ -f "app/.env.example" ]; then \
		cp app/.env.example app/.env; \
	fi
	@echo "Generating Laravel application key..."
	docker run --rm -v $(PWD)/app:/app -w /app composer:2 \
		sh -c "composer dump-autoload --no-interaction && php artisan key:generate --force --no-interaction || true"
	@echo "Creating SQLite database..."
	@mkdir -p app/database
	@touch app/database/database.sqlite
	@echo "Running database migrations..."
	docker run --rm -v $(PWD)/app:/app -w /app composer:2 \
		sh -c "php artisan migrate --force --no-interaction || true"
	@echo "Laravel demo app downloaded to ./app/"
	@echo "Run 'make demo/laravel/up' to start the development environment"

demo/laravel/up:		## Start the Laravel demo app in dev mode (APP_BASE_DIR=app)
	APP_BASE_DIR=./app make build-up
	@echo "Visit http://localhost:8080 to see the Laravel base app"

demo/laravel/deploy:		## Start the Laravel demo app in prod mode (APP_BASE_DIR=app)
	APP_BASE_DIR=./app make deploy

demo/laravel/clean:		## Remove the Laravel demo app directory
	rm -rf app
	@echo "Laravel demo app removed"