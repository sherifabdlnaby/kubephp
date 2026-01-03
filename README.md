<p align="center">
<img width="320px" src="https://user-images.githubusercontent.com/16992394/132966279-6f4bd8a6-9d50-4940-96f0-7edb73688ab9.png">
</p>
<h2 align="center">KubePHP - Production Grade, Rootless, Optimized, PHP Container Image for Cloud Native PHP Apps 🐳 </h2>
<p align="center">Compatible with popular PHP Frameworks such as <a href="https://laravel.com/">Laravel</a> &amp; <a href="https://symfony.com/">Symfony</a> and their variants. </br> Typically deployed on Kubernetes. </p>

<p align="center">
	<a>
		<img src="https://img.shields.io/github/v/tag/sherifabdlnaby/kubephp?label=release&amp;sort=semver">
    </a>
	<a href="https://github.com/sherifabdlnaby/kubephp/actions/workflows/build-test-scan.yml">
		<img src="https://img.shields.io/github/actions/workflow/status/sherifabdlnaby/kubephp/build-test-scan.yml?label=Build&amp;branch=main" alt="Build Status">
	</a>
	<a href="https://github.com/sherifabdlnaby/kubephp/actions/workflows/build-test-scan.yml">
		<img src="https://img.shields.io/github/actions/workflow/status/sherifabdlnaby/kubephp/build-test-scan.yml?label=Tests&amp;branch=main" alt="Test Status">
	</a>
	<a>
		<img src="https://img.shields.io/badge/PHP-8.4-%23777BB4?logo=php" alt="PHP 8.4">
	</a>
	<a>
		<img src="https://img.shields.io/badge/Platform-amd64%20%7C%20arm64-blue" alt="Multi-arch">
	</a>
	<a href="https://github.com/sherifabdlnaby/kubephp/network">
		<img src="https://img.shields.io/github/forks/sherifabdlnaby/kubephp.svg" alt="GitHub forks">
	</a>
	<a href="https://github.com/sherifabdlnaby/kubephp/issues">
        <img src="https://img.shields.io/github/issues/sherifabdlnaby/kubephp.svg" alt="GitHub issues">
	</a>
	<a href="https://raw.githubusercontent.com/sherifabdlnaby/kubephp/blob/master/LICENSE">
		<img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="GitHub license">
	</a>
	<a>
		<img src="https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat" alt="contributions welcome">
	</a>
</p>

# Introduction
**Production Grade Image for PHP 8.4+ Applications** running **Nginx + PHP FPM** based on [PHP](https://hub.docker.com/_/php) & [Nginx](https://hub.docker.com/_/nginx) **Official Images**, compatible with popular PHP Frameworks such as [Laravel](https://laravel.com/) & [Symfony](https://symfony.com/) and their variants.

- This is a pre-configured template image for your PHP Application, **and you shall extend and edit it according to your app requirements.** See [Requirements](#requirements) first, then follow [How to use with my project](#how-to-use-with-my-project-) and [How to configure image to run my project](#how-to-configure-image-to-run-my-project-) for setup instructions.
- The Image utilizes [multistage builds](#building-configuring-and-extending-image) to create multiple targets optimized for **production** OR **development** use cases. Hyper-optimized for caching and build time. See [Image Targets and Build Arguments](#image-targets-and-build-arguments) for details.
- [Demo applications](#running-the-demo-applications) are available for both frameworks to give you a quick start:
    - use `make demo/symfony/setup` for **Symfony Demo** (latest Symfony 7.x)
    - use `make demo/laravel/setup` for **Laravel** (latest Laravel 11.x).

## Features 📜

- Designed to run in orchestrated environments like Kubernetes. See [How is it deployed?](#how-is-it-deployed-) for architecture details.
- **Multi-architecture support** - native images for AMD64 and ARM64.
- Uses Alpine based images and multistage builds for minimal images. (~135 MB)
- Multi-Container setup with `Nginx` & `PHP-FPM` communicating via TCP.
- Productions Image that are **immutable** and **fully contained**.
- **Runs as non-root** in both application containers.
- Configured for graceful shutdowns/restarts, **zero downtime deployments, auto-healing, and auto-scaling**.
- **PHP 8.4 optimizations** including JIT compilation and OPcache file caching.
- Easily extend the image with extra configuration, and scripts; such as [post-build & pre-run scripts](#post-build-and-pre-run-optional-scripts).
- Minimal startup time, container almost start serving requests almost instantly.
- Image tries to fail at build time as much as possible by running all sort of checks.
- Ability to run Commands, Consumers and Crons using same image. (No supervisor or crontab)
- Development Image **supports mounting code and hot-reloading and [XDebug out of the box](#debugging-with-xdebug)**.
- Cache-friendly mechanism to update OS packages and auto-patch security vulnerabilities ([see cache mechanism](#cache-friendly-os-package-updates-and-auto-patching)).

## How to use with my project ?

This is a template, it's expected from you to tailor it to your needs. And then generate a build pipeline to build the image and push it to your registry.

- Copy this repository `Dockerfile`, `docker` Directory, `Makefile`, `docker-compose.yml`, `docker-compose.prod.yml` and `.dockerignore` to your application root directory and configure it to your needs.

## How to configure image to run my project ?

You'll need to iterate over your application's dependency system packages, and required PHP Extensions; and add them to their respective locations in the image.

1. Add System Dependencies and PHP Extensions your application depends on to the Image.
2. Port in any configuration changes you made for PHP.ini to the image, otherwise use the sane defaults.
3. `make build && make up` for development setup, `make deploy` to run the production variant.

These steps explained in details below.

## How is it deployed ?

<img src="https://user-images.githubusercontent.com/16992394/116017065-dd8b2900-a63e-11eb-917e-6b04a4e6e89b.png">

Your application will be split into two components.

1. **The Webserver** -> Server Static Content and proxy dynamic requests to PHP-FPM over TCP, webserver also applies rate limiting, security headers... and whatever it is configured for.
2. **The PHP Process** -> PHP FPM process that will run you PHP Code.

> Other type of deployments such as a cron-job, or a supervised consumer can be achieved by overriding the default image CMD.

-----

# Requirements

- [Docker 20.10.0 or higher](https://docs.docker.com/install/)
- [Docker Compose V2](https://docs.docker.com/compose/install/) (included with Docker Desktop)
- PHP >= 8.2 Application

# Setup

#### 1. Add Template to your repo.

1. Download This Repository
2. Copy `Dockerfile`, `docker` Directory, `Makefile`, `docker-compose.yml`, `docker-compose.prod.yml` and `.dockerignore` Into your Application Repository.

OR

<a href="https://github.com/sherifabdlnaby/kubephp/generate">
<img src="https://user-images.githubusercontent.com/16992394/133710871-178f9cb6-922e-41e1-9c69-dff8f9773b97.png" alt="create repository from template"></a>

#### 2. Start
1. Modify `Dockerfile` to your app needs, and add your app needed OS Packages, and PHP Extensions.
    1. Dockerfile Header has Build Time Arguments, customize it, most notably the `RUNTIME_DEPS` argument.
    2. Below in the `base` image, add the PHP Extensions your application depends on.
2. Run `make up` for development or `make deploy` for production.
    1. For Dev: `make up` is just an alias for `docker compose up -d`
    1. For Dev: Make sure to delete previous `vendor` directory if you had it before.
    2. Docker-Compose will start App container first, and only start Web server when it's ready, on initial install, it might take some time.
4. Go to [http://localhost:8080](http://localhost:8080)

> Makefile is just a wrapper over docker compose commands.

## Building, Configuring and Extending Image

### Image Targets and Build Arguments
- The image comes with a handy _Makefile_ to build the image using Docker-Compose files, it's handy when manually building the image for development or in a not-orchestrated docker host.
However, in an environment where CI/CD pipelines will build the image, they will need to supply some build-time arguments for the image. (tho defaults exist.)

    #### Build Time Arguments

    | **ARG**              | **Description** | **Default** |
    |----------------------|-----------------|-------------|
    | `PHP_VERSION`        | PHP Version used in the Image | `8.4` |
    | `PHP_ALPINE_VERSION` | Alpine Version for the PHP Image | `3.21` |
    | `NGINX_VERSION`      | Nginx Version | `1.28` |
    | `COMPOSER_VERSION`   | Composer Version used in Image | `2` |
    | `COMPOSER_AUTH`      | A Json Object with Bitbucket or Github token to clone private Repos with composer.</br>[Reference](https://getcomposer.org/doc/03-cli.md#composer-auth) | `{}` |
    | `XDEBUG_VERSION`     | Xdebug Version to use in Development Image | `3.5.0` |
    | `OS_PACKAGE_UPGRADE_TRIGGER` | Cache buster for OS packages. Changing this value triggers a fresh installation and update of all OS packages. See [OS Package Cache Busting](#os-package-cache-busting) for details. | `1` |

    #### Image Targets

    | **Target** | Env         | Desc                                                                                                                                                                                                                                                                             | Size   | Based On                      |
    |------------|-------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------|-------------------------------|
    | app        | Production  | The PHP Application with immutable code/dependencies. By default starts `PHP-FPM` process listening on `9000`.  Command can be extended to run any PHP Consumer/Job, entrypoint will still start the pre-run setup and then run the supplied command.                            | ~135mb | PHP Official Image (Alpine)   |
    | web        | Production  | The webserver, an Nginx container that is configured to server static content and forward dynamic requests to the PHP-FPM container running in the `app` image variant                                                                                                           | ~21mb  | Nginx Official Image (Alpine) |
    | app-dev    | Development | Development PHP Application variant with dependencies inside. Image expects the code to be mounted on `/app` to support hot-reloading. You need to mount dummy `/app/vendor` volume too to avoid code volume to overwrite dependencies already inside the image. | ~150mb | PHP Official Image (Alpine)   |
    | web-dev    | Development | Development Webserver with the exact configuration as the production configuration. Expects public directory to be mounted at `/app/public`                                                                                                                              |    ~21mb     |   Nginx Official Image (Alpine)                            |

### Install System Dependencies and PHP Extensions
- The image is to be used as a base for your PHP application image, you should modify its Dockerfile to your needs.

    1. Install System Packages in the following section in the Dockerfile.
        - Add OS Packages needed in `RUNTIME_DEPS` in Dockerfile.
    2. Install PHP Extensions In the following section in the Dockerfile.
    ```dockerfile
    # ---------------------------------------- Install / Enable PHP Extensions ---------------------------------------------
    RUN docker-php-ext-install \
    opcache     \
    intl        \
    pdo_mysql   \
    # Pecl Extentions
    RUN pecl install apcu-5.1.20 && docker-php-ext-enable apcu
    #   EX: RUN pecl install memcached && docker-php-ext-enable memcached
    ```
##### Note
> At build time, Image will run `composer check-platform-reqs` to check that PHP and extensions versions match the platform requirements of the installed packages.

### OS Package Cache Busting

The `OS_PACKAGE_UPGRADE_TRIGGER` build argument allows you to force a fresh installation and update of all OS packages by changing its value. This is helpful to force a fresh installation (and patch security vulnerabilities) every time you build the image. A common use case is to set it based on date (e.g week of year, month, year, etc.) that will determine how often you want to update the OS packages.

Note: It's a common recommendation to pin package versions. However in practice this is always a cause of hassle because you'll have to manually commit a change for every little dependency update. You can rely on Alpine Linux to maintain backward compatibility as they patch updates. The template rely on trust in Alpine plus all the pre-flight checks to make sure updates are safe to install. 

### PHP Configuration
1. PHP `base` Configuration that are common in all environments in `docker/php/base-php.ini`[🔗](https://github.com/sherifabdlnaby/kubephp/blob/master/docker/php/base-php.ini)
1. PHP `prod` Only Configuration  `docker/php/php-prod.ini`[🔗](https://github.com/sherifabdlnaby/kubephp/blob/master/docker/php/prod-php.ini)
2. PHP `dev` Only Configuration  `docker/php/php-dev.ini`[🔗](https://github.com/sherifabdlnaby/kubephp/blob/master/docker/php/dev-php.ini)

### PHP FPM Configuration
1. PHP FPM Configuration  `docker/fpm/*.conf` [🔗](https://github.com/sherifabdlnaby/kubephp/blob/master/docker/fpm)

### Nginx Configuration
1. Nginx Configuration  `docker/nginx/*.conf && docker/nginx/conf.d/* ` [🔗](https://github.com/sherifabdlnaby/kubephp/blob/master/docker/nginx)

### Debugging with XDebug

The development image includes XDebug 3.5.0 pre-configured and ready to use. This setup has been tested with **PHPStorm**.

#### XDebug Configuration

XDebug is automatically enabled in the `app-dev` target with the following settings:
- **Port**: `9000` (DBGp protocol)
- **IDE Key**: `kubephp`
- **Mode**: `debug`
- **Client Host**: `host.docker.internal` (automatically resolves to your Docker host)

The configuration file is located at `docker/php/dev-xdebug.ini` and can be customized if needed.
These configuration should work for most default IDEs setups. Tested with **PHPStorm**.


## Post Build and Pre Run optional scripts.

In `docker/` directory there is `post-build-*` and `pre-run-*` scripts that are used **to extend the image** and add extra behavior.

1. `post-build` command runs at the end of Image build.

    Run as the last step during the image build. Are Often framework specific commands that generate optimized builds, generate assets, etc.

2. `pre-run` command runs **in runtime** before running the container main command

    Runs before the container's CMD, but after the composer's post-install and post-autload-dump. Used for commands that needs to run at runtime before the application is started. Often are scripts that depends on other services or runtime parameters.

3. `*-base` scripts run on both `production` and `development` images.
--------

# Misc Notes
- Your application [should log app logs to stdout.](https://stackoverflow.com/questions/38499825/symfony-logs-to-stdout-inside-docker-container). Read about [12factor/logs](https://12factor.net/logs)
- By default, `php-fpm` access logs are disabled as they're mirrored on `nginx`, this is so that `php-fpm` image will contain **only** application logs written by PHP.
- In **production**, Image contains source-code, however, you must sync both `php-fpm` and `nginx` images so that they contain the same build.

--------

# FAQ

1. Why two containers instead of one ?

    -  In containerized environment, you need to only run one process inside the container. This allows us to better instrument our application for many reasons like separation of health status, metrics, logs, etc.

2. Image Build Fails as it try to connect to DB.

    - A typical scenario in most frameworks that comes with `Doctrine` ORM is that if Doctrine not configured with a DB
      Ver esion, will try to access the DB at php's script initialization (even at the post-install cmd's), and it will
      fail when it cannot connect to
      DB. [Make sure you configure doctrine to avoid this extra DB Check connection.](https://symfony.com/doc/current/reference/configuration/doctrine.html#:~:text=The-,server_version,-option%20was%20added)

--------

# Running the Demo Applications

This repository includes demo applications for both **Symfony** and **Laravel** to show you how an application is expected to be used with this template.

## Symfony Demo

The [Symfony Demo application](https://github.com/symfony/symfony-demo) is a full-featured demo that showcases best practices for Symfony development.

**Quick Start:**
```bash
make demo/symfony/setup  # Set up the demo
make demo/symfony/up     # Start in dev mode
# Visit http://localhost:8080
```

<details>
<summary><strong>Setup Details</strong></summary>

```bash
# Download and set up the Symfony demo application
make demo/symfony/setup
```

This will download the latest [Symfony Demo application](https://github.com/symfony/symfony-demo), install dependencies, and prepare it for use.

</details>

<details>
<summary><strong>Running Options</strong></summary>

```bash
# Start in development mode (with hot-reloading)
make demo/symfony/up

# Start in production mode (optimized)
make demo/symfony/deploy
```

Visit [http://localhost:8080](http://localhost:8080) to see the Symfony demo app.

</details>

<details>
<summary><strong>Cleanup</strong></summary>

```bash
# Remove the Symfony demo app
make demo/symfony/clean
```

</details>

## Laravel Demo

The [Laravel application](https://github.com/laravel/laravel) is the official Laravel framework skeleton with all the features you need to get started.

**Quick Start:**
```bash
make demo/laravel/setup  # Set up the demo
make demo/laravel/up     # Start in dev mode
# Visit http://localhost:8080
```

<details>
<summary><strong>Setup Details</strong></summary>

```bash
# Download and set up the Laravel application
make demo/laravel/setup
```

This will:
- Download the latest Laravel application
- Install composer dependencies
- Set up the `.env` file
- Generate the application encryption key
- Create the SQLite database file
- Run database migrations

</details>

<details>
<summary><strong>Running Options</strong></summary>

```bash
# Start in development mode (with hot-reloading)
make demo/laravel/up

# Start in production mode (optimized)
make demo/laravel/deploy
```

Visit [http://localhost:8080](http://localhost:8080) to see the Laravel application.

</details>

<details>
<summary><strong>Cleanup</strong></summary>

```bash
# Remove the Laravel demo app
make demo/laravel/clean
```

</details>

<details>
<summary><strong>Additional Commands</strong></summary>

While the demo applications are running, you can use these commands:

```bash
# View container logs
make logs

# Execute artisan/console commands
make command COMMAND="php artisan migrate"        # Laravel
make command COMMAND="php bin/console cache:clear" # Symfony

# Access container shell
make shell

# Stop the containers
make down
```

</details>

<details>
<summary><strong>Important Notes</strong></summary>

- Both demos use the same `./app` directory. To switch between frameworks, clean the current demo first.
- The Laravel demo uses SQLite by default (database file at `app/database/database.sqlite`).
- In development mode, code changes are hot-reloaded automatically.
- In production mode, applications are optimized with cached config, routes, views, and events.

</details>

--------

# License

[MIT License](https://raw.githubusercontent.com/sherifabdlnaby/kubephp/blob/master/LICENSE)
Copyright (c) 2022-2026 Sherif Abdel-Naby

# Contribution

PR(s) are Open and welcomed.
