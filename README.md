<p align="center">
<img width="520px" src="https://user-images.githubusercontent.com/16992394/65461542-697e1300-de54-11e9-8e4f-34adcc448747.png">
</p>
<h2 align="center">🐳 A preconfigured, extendable, multistage, PHP Symfony 4.3+ Docker Image for Production and Development</h2>
<p align="center">.</p>
<p align="center">
	<a>
		<img src="https://img.shields.io/github/v/tag/sherifabdlnaby/symdocker?label=release&amp;sort=semver">
    </a>
	<a>
		<img src="https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat" alt="contributions welcome">
	</a>
	<a>
		<img src="https://img.shields.io/badge/PHP-%3E=7-blueviolet" alt="PHP >=7^">
	</a>
	<a>
		<img src="https://img.shields.io/badge/Symfony-4%5E-black" alt="Symfony 4^">
	</a>
	<a href="https://github.com/sherifabdlnaby/symdocker/network">
		<img src="https://img.shields.io/github/forks/sherifabdlnaby/symdocker.svg" alt="GitHub forks">
	</a>
	<a href="https://github.com/sherifabdlnaby/symdocker/issues">
        <img src="https://img.shields.io/github/issues/sherifabdlnaby/symdocker.svg" alt="GitHub issues">
	</a>
	<a href="https://raw.githubusercontent.com/sherifabdlnaby/symdocker/blob/master/LICENSE">
		<img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="GitHub license">
	</a>
</p>

# Introduction
**Docker Image for Symfony 4.3+ Application** running **Nginx + PHP FPM** based on [PHP](https://hub.docker.com/_/php) & [Nginx](https://hub.docker.com/_/nginx) **Alpine Official Images**.

This is a pre-configured template image for your Symfony Project, **and you shall extend and edit it according to your app requirements.**
The Image utilizes docker's multistage builds to create multiple targets optimized for **production** and **development**.

You should copy this repository`Dockerfile`, `docker` Directory, `Makefile`, and `.dockerignore` to your Symfony application repository and configure it to your needs.

### Main Points 📜

- Multi-Container setup with `Nginx` & `PHP-FPM` communicating via TCP.

- Production Images is **immutable** and **fully contained Image** with source code and dependencies inside, Development image is set up for mounting source code on runtime with hot-reload.

- Image configuration is transparent, all configuration and default configurations that determine app behavior are present in the image directory.

- Nginx is pre-configured with **HTTP**, **HTTPS**, and **HTTP2**. and uses a self-signed certificate generated at build-time. For production, you'll need to mount your own signed certificates to `/etc/nginx/ssl/server.(crt/key)`.

- The image has set up **healthchecks** for `Nginx` and `PHP-FPM`, and you can add application logic healthcheck by adding it in `healthcheck.sh`[🔗](https://github.com/sherifabdlnaby/symdocker/blob/master/docker/healthcheck.sh).

- Image tries to fail at build time as much as possible by running all sort of Checks.

- Dockerfile is arranged for optimizing prod builds so that changes won't invalidate cache as much as possible.

- Available a `Supervisord` and `Crond` image variant for your consumers and cron commands.


<p align="center">
<img src="https://user-images.githubusercontent.com/16992394/65840420-40102c00-e319-11e9-952b-6e1267661c29.png">
</p>


-----

# Requirements 

- [Docker 17.05 or higher](https://docs.docker.com/install/) 
- [Docker-Compose 3.4 or higher](https://docs.docker.com/compose/install/) (optional) 
- Symfony 4+ Application
- PHP >= 7 Application

# Setup

#### 1. Add Template to your repo.

1. Download This Repository
2. Copy `Dockerfile`, `docker` Directory, `Makefile`, and `.dockerignore` Into your Symfony Application Repository.

OR

<a href="https://github.com/sherifabdlnaby/symdocker/generate">
<img src="https://user-images.githubusercontent.com/16992394/65464461-20c95880-de5a-11e9-9bf0-fc79d125b99e.png" alt="create repository from template"></a>

#### 2. Start
1. Modify `Dockerfile` to your app needs, and add your app needed PHP Extensions and Required Packages.
2. Go to `docker/.composer/.env` and modify `SERVER_NAME` to your app's name.
3. Run `make up` for development or `make deploy` for production. 
4. Go to [https://localhost](https://localhost) 

> Makefile is just a wrapper over docker-compose commands.

> Production runs on port `80` and `443`, Development runs on `8080` and `443`.
      
# Building and Extending Image 

1. The image is to be used as a base for your Symfony application image, you should modify its Dockerfile to your needs.

2. The image comes with a handy _Makefile_ to build the image using Docker-Compose files, it's handy when manually building the image for development or in a not-orchestrated docker host.
However, in an environment where CI/CD pipelines will build the image, they will need to supply some build-time arguments for the image. (tho defaults exist.)

### Build Time Arguments
| **ARG**            | **Description**                                                                                                                                      | **Default** |
|--------------------|------------------------------------------------------------------------------------------------------------------------------------------------------|-------------|
| `PHP_VERSION`      | PHP Version used in the Image                                                                                                                        | `7.3.9`     |
| `ALPINE_VERSION`   | Alpine Version                                                                                                                                       | `3.10`      |
| `NGINX_VERSION`    | Nginx Version                                                                                                                                        | `1.17.4`    |
| `COMPOSER_VERSION` | Composer Version used in Image                                                                                                                       | `1.9.0`     |
| `SERVER_NAME`      | Server Name</br> (In production, and using SSL, this must match certificate's *common name*)                                                              | `php-app`   |
| `COMPOSER_AUTH`    | A Json Object with Bitbucket or Github token to clone private Repos with composer.</br>[Reference](https://getcomposer.org/doc/03-cli.md#composer-auth) | `{}`        | 

### Runtime Environment Variables
| **ENV**     | **Description** | **Default**                                                 |
|-------------|-----------------|-------------------------------------------------------------|
| `APP_ENV`   | App Environment | - `prod` for Production image</br> - `dev` for Development image     |
| `APP_DEBUG` | Enable Debug    | - `0` for Production image</br>- `1` for Development image           |

### Image Targets

| **Target**       | **Description**                                                                                      |  **Size**    |          **Stdout**              |             **Targets**              |
|--------------    |----------------------------------------------------------------------------------------------------  |--------------    |:----------------------------:    |:-----------------------------------: |
| `nginx`          | The Webserver, serves static content and replay others requests `php-fpm`                            | 21 MB            | Nginx Access and Error logs.     |      `nginx-prod`, `nginx-dev`       |
| `fpm`            | PHP_FPM, which will actually run the PHP Scripts for web requests.                                   | 78 MB            |  PHP Application logs only.      |        `fpm-prod`, `fpm-dev`         |
| `supervisor`     | Contains supervisor and source-code, for your consumers. (config at `docker/conf/supervisor/`)       | 120 MB           |    Stdout of all Commands.       |           `supervisor-prod`           |
| `cron`           | Loads crontab and your app source-code, for your cron commands. (config at `docker/conf/crontab`)    | 78 MB            |     Stdout of all Crons.         |              `cron-prod`             |

> All Images are **Alpine** based.  Official PHP-Alpine-CLI image size is 79.4MB. 

> Size stated above are calculated excluding source code and vendor directory. 

## Tips for building Image in different environments

### Production
1. For SSL: Mount your signed certificates as secrets to `/etc/nginx/ssl/server.key` & `/etc/nginx/ssl/server.crt`
2. Make sure build argument `SERVER_NAME` matches certificate's **common name**.
2. Expose container port `80` and `443`.    

> By default, Image has a generated self-signed certificate for SSL connections added at build time.
### Development
1. Mount source code root to `/var/www/app`
2. Expose container port `8080` and `443`. (or whatever you need actually)

----

# Configuration

## 1. PHP Extensions, Dependencies, and Configuration

### Modify PHP Configuration
1. PHP `prod` Configuration  `docker/conf/php/php-prod.ini`[🔗](https://github.com/sherifabdlnaby/symdocker/blob/master/docker/conf/php/php-prod.ini) 
2. PHP `dev` Configuration  `docker/conf/php/php-dev.ini`[🔗](https://github.com/sherifabdlnaby/symdocker/blob/master/docker/conf/php/php-dev.ini) 
3. PHP additional [Symfony recommended configuration](https://symfony.com/doc/current/performance.html#configure-opcache-for-maximum-performance) at `docker/conf/php/symfony.ini` [🔗](https://github.com/sherifabdlnaby/symdocker/blob/master/docker/conf/php/symfony.ini) 

### Add Packages needed for PHP runtime
Add Packages needed for PHP runtime in this section of the `Dockerfile`.
```Dockerfile
...
# ------------------------------------- Install Packages Needed Inside Base Image --------------------------------------
RUN apk add --no-cache    \
#    # - Please define package version too ---
#    # -----  Needed for Image----------------
   fcgi tini \
#    # -----  Needed for PHP -----------------
    <HERE>
...
``` 

### Add & Enable PHP Extensions
Add PHP Extensions using `docker-php-ext-install <extensions...>` or `pecl install <extensions...>`  and Enable them by `docker-php-ext-enable <extensions...>`
in this section of the `Dockerfile`.
```Dockerfile
...
# --------------------- Install / Enable PHP Extensions ------------------------
RUN docker-php-ext-install opcache && pecl install memcached && docker-php-ext-enable memcached
...
```

##### Note

> At build time, Image will run `composer check-platform-reqs` to check that PHP and extensions versions match the platform requirements of the installed packages.

## 2. Nginx Configuration

Nginx defaults are all defined in `docker/conf/nginx/` [🔗](https://github.com/sherifabdlnaby/symdocker/blob/master/docker/conf/nginx/)

Nginx is pre-configured with:
1. HTTP, HTTPS, and HTTP2.
2. Rate limit (`rate=5r/s`)
3. Access & Error logs to `stdout/err`
4. Recommended Security Headers
5. Serving Static content with default cache `7d`
6. Metrics endpoint at `:8080/stub_status` from localhost only.

##### Note

> At build time, Image will run `nginx -t` to check config file syntax is OK.

## 3. Post Deployment Custom Scripts

Post Installation scripts should be configured in `composer.json` in the `post-install-cmd` [part](https://getcomposer.org/doc/articles/scripts.md#command-events).

However, Sometimes, some packages have commands that need to be run on startup, that are not compatible with composer, provided in the image a shell script `post-deployment.sh`[🔗](https://github.com/sherifabdlnaby/symdocker/blob/master/docker/post-deployment.sh) that will be executed after deployment. 
Special about this file that it comes loaded with all OS Environment variables **as well as defaults from `.env` and `.env.${APP_ENV}` files.** so it won't need a special treatment handling parameters.

> It is still discouraged to be used if it's possible to run these commands using composer scripts.

## 3. Supervisor Consumers

If you have consumers (e.g rabbitMq or Kafka consumers) that need to be run under supervisor, you can define these at `docker/conf/supervisor/*`, which will run by the `supervisor` image target.

## 4. Cron Commands

If you have cron jobs, you can define them in `docker/conf/crontab`, which will run by the `cron` image target.

--------

# Misc Notes
- Your application [should log app logs to stdout.](https://stackoverflow.com/questions/38499825/symfony-logs-to-stdout-inside-docker-container). Read about [12factor/logs](https://12factor.net/logs) 
- By default, `php-fpm` access & error logs are disabled as they're mirrored on `nginx`, this is so that `php-fpm` image will contain **only** application logs written by PHP.
- During Build, Image will run `composer dump-autoload` and `composer dump-env` to optimize for performance.
- In **production**, Image contains source-code, however, you must sync both `php-fpm` and `nginx` images so that they contain the same code.

# License 
[MIT License](https://raw.githubusercontent.com/sherifabdlnaby/symdocker/blob/master/LICENSE)
Copyright (c) 2019 Sherif Abdel-Naby

# Contribution

PR(s) are Open and welcomed.

This image has so little to do with Symfony itself and more with Setting up a PHP Website with Nginx and FPM, hence it can be extended for other PHP Frameworks (e.g Laravel, etc). maybe if you're interested to build a similar image for another framework we can collaborate. 

### Possible Ideas

- [x] Add a slim image with supervisor for running consumers.
- [x] Add a slim image with cron tab for cron job instances.
- [ ] Add node build stage that compiles javascript.
- [ ] Recreate the image for Symfony 3^
- [ ] Recreate the image for Laravel
