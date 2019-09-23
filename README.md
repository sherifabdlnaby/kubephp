<p align="center">
<img width="520px" src="https://user-images.githubusercontent.com/16992394/65461542-697e1300-de54-11e9-8e4f-34adcc448747.png">
</p>
<h2 align="center">🐳 An extendable multistage PHP Symfony 4.3+ Docker Image for Production and Development</h2>
<p align="center">A Base Template Image to be added to your Symfony Application.</p>
<p align="center">
	<a>
		<img src="https://img.shields.io/github/v/tag/sherifabdlnaby/symdocker?label=release&amp;sort=semver">
    </a>
	<a>
		<img src="https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat" alt="contributions welcome">
	</a>
	<a>
		<img src="https://img.shields.io/badge/PHP-7%5E-blueviolet" alt="PHP 7^">
	</a>
	<a>
		<img src="https://img.shields.io/badge/Apache-2.4%5E-red" alt="Apache 2.4^">
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
**Docker Image for Symfony 4.3+ Application** running on **Apache 2.4** based on [PHP Official Image](https://hub.docker.com/_/php).
This image should be used as a **base** image for your Symfony Project, and you shall extend and edit it according to your app needs.
The Image utilizes docker's multistage builds to create multiple targets optimized for **production** and **development**.


You should copy this repository`Dockerfile`, `.docker` Directory, `Makefile`, and `.dockerignore` to your Symfony application repository and configure it to your needs.

## Main Points 📜

- **Production Image is a fully contained Image with source code and dependencies inside**, Development image is set up for mounting source code on runtime to allow development and debugging using the container.

- Image configuration is transparent, you can view and modify any of Apache's `*.conf` files, PHP `*.ini` files or Entrypoint `*.sh` scripts in the `.docker` directory. 

- **Apache SSL is enabled**, and hence run **HTTP** and **HTTPS** endpoints, with **HTTPS** it uses self-signed certificate generated at runtime. however, for production you'll need to mount your own signed certificates to `/etc/apache2/certs` amd overwrite defaults.

- Image tries to fail at build time as much as possible by running all sort of Checks.

- Dockerfile is arranged for optimize builds, so that changed won't invalidate cache as much as possible.

- As Symfony 4+ [Uses Environment Variables](https://symfony.com/doc/4.3/configuration.html#configuration-based-on-environment-variables) for parameters, and only passing environment variables to the container is enough to be read by symfony. (no need to pass them through Apache2 conf too).

# Requirements 

- [Docker 17.05 or higher](https://docs.docker.com/install/) 
- [Docker-Compose 3.4 or higher](https://docs.docker.com/compose/install/) (optional) 
- Symfony 4+ Application

# Setup

### Get Template
#### 1. Generate Repo from this Template

1. Download This Repository
2. Copy `Dockerfile`, `.docker` Directory, `Makefile`, and `.dockerignore` Into your Symfony Application Repository.
3. Modify `Dockerfile` to your app needs, and add your app needed PHP Extensions and Required Packages.
4. Situational:
    - If you will use `Makefile` and `Docker-Compose`: go to `.docker/.composer/.env` and modify `SERVER_NAME` to your app's name.
    - If you will expose SSL port to Production: Mount your signed certificates `server.crt` & `server.key` to `/etc/apache2/certs`.
      Also make sure `SERVER_NAME` build ARG matches Certificate's **Common Name**.
5. run `make up` for development or `make deploy` for production. 

OR

<a href="https://github.com/sherifabdlnaby/symdocker/generate">
<img src="https://user-images.githubusercontent.com/16992394/65464461-20c95880-de5a-11e9-9bf0-fc79d125b99e.png" alt="create repository from template"></a>

<p> <small>And start from step 3..</small> </p>

      
## Building Image

1. The image is to be used as a base for your Symfony application image, you should modify its Dockerfile to your needs.

2. The image come with a handy _Makefile_ to build the image using Docker-Compose files, it's handy when manually building the image for development or in a not-orchestrated docker hosts.
However in an environment where CI/CD pipelines will build the image, they will need to supply some build-time arguments for the image. (tho defaults exist.)

### Build Time Arguments
| **ARG**            | **Description**                                                                                                                                      | **Default** |
|--------------------|------------------------------------------------------------------------------------------------------------------------------------------------------|-------------|
| `PHP_VERSION`      | PHP Version used in the Image                                                                                                                        | `7.3.9`     |
| `COMPOSER_VERSION` | Composer Version used in Image                                                                                                                       | `1.9.0`     |
| `SERVER_NAME`      | Server Name (In production, and using SSL, this must match certificate's *common name*)                                                              | `php-app`   |
| `COMPOSER_AUTH`    | A Json Object with Bitbucket or Github token to clone private Repos with composer.  [Reference](https://getcomposer.org/doc/03-cli.md#composer-auth) | `{}`        | 

### Runtime Environment Variables
| **ENV**     | **Description** | **Default**                                                 |
|-------------|-----------------|-------------------------------------------------------------|
| `APP_ENV`   | App Environment | - `prod` for Production image                               |
|             |                 | - `dev` for Development image                               |
| `APP_DEBUG` | Enable Debug    | - `0` for Production image                                  |
|             |                 | - `1` for Development image                                 |

## Tips for building Image in different environments

### Production
1. For SSL: Mount your signed certificates as secrets to `/etc/apache2/certs/server.key` & `/etc/apache2/certs/server.crt`
2. Make sure build argument `SERVER_NAME` matches certificate's **common name**.
2. Expose container port `80` and `443`.

> You can disable SSL by modifying `site.conf` in `.docker/conf/apache2` config if you don't need HTTPS or is having it using a front loadbalancer/proxy.

> By default, Image has a generated self-signed certificate for SSL connections added at run time.
### Development
1. Mount source code root to `/var/www/app`
2. Expose container port `8080` and `443`. (or whatever you need actually)

# Configuration

## 1. PHP Extensions, Dependencies, and Configuration

### Modify PHP Configuration
1. PHP `prod` Configuration  `.docker/conf/php/php-prod.ini`[🔗](https://github.com/sherifabdlnaby/symdocker/blob/master/.docker/conf/php/php-prod.ini) 
2. PHP `dev` Configuration  `.docker/conf/php/php-dev.ini`[🔗](https://github.com/sherifabdlnaby/symdocker/blob/master/.docker/conf/php/php-dev.ini) 
3. PHP additional [Symfony recommended configuration](https://symfony.com/doc/current/performance.html#configure-opcache-for-maximum-performance) at `.docker/conf/php/symfony.ini` [🔗](https://github.com/sherifabdlnaby/symdocker/blob/master/.docker/conf/php/symfony.ini) 

### Add Packages needed for PHP runtime
Add Packages needed for PHP runtime in this section of the `Dockerfile`.
```Dockerfile
...
# ---------------- Install Packages Needed Inside Base Image ------------------
RUN apt-get -yqq update && apt-get -yqq --no-install-recommends install \
    # -----  Needed for PHP -----------------
    # - Please define package version too ---
    curl=7.52\* \
    # ---------------------------------------
    && apt-get -qq autoremove --purge -y  \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
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

## 2. Apache Configuration

1. Apache defaults are all defined in `.docker/conf/apache2/apache2.conf` [🔗](https://github.com/sherifabdlnaby/symdocker/blob/master/.docker/conf/apache2/apache2.conf)
2. Site configurations are defined in `.docker/conf/apache2/main.conf` [🔗](https://github.com/sherifabdlnaby/symdocker/blob/master/.docker/conf/apache2/main.conf) and default using [optimized recommended config by Symfony](https://symfony.com/doc/current/setup/web_server_configuration.html#apache-with-mod-php-php-cgi).
3. Virtualhost configurations are defined in `.docker/conf/apache2/site.conf` [🔗](https://github.com/sherifabdlnaby/symdocker/blob/master/.docker/conf/apache2/site.conf) that configure both HTTP and HTTPS hosts and Include `main.conf`[🔗](https://github.com/sherifabdlnaby/symdocker/blob/master/.docker/conf/apache2/main.conf) to keep things DRY.

##### Note

> At build time, Image will run `apachectl configtest` to check Apache config file syntax is OK.

## 3. Post Deployment Custom Scripts

Post Installation scripts should be configured in `composer.json` in the `post-install-cmd` [part](https://getcomposer.org/doc/articles/scripts.md#command-events).

However, Sometimes, some packages has commands that need to be run on startup, that are not compatible with composer, provided in the image a shell script `post-deployment.sh`[🔗](https://github.com/sherifabdlnaby/symdocker/blob/master/.docker/post-deployment.sh) that will be executed after deployment. 
Special about this file that it comes loaded with all OS Environment variables **as well as defaults from `.env` and `.env.${APP_ENV}` files.** so it won't need a special treatment handling parameters.

> It is still discouraged to be used if it's possible to run these commands using composer scripts.

# License 
[MIT License](https://raw.githubusercontent.com/sherifabdlnaby/symdocker/blob/master/LICENSE)
Copyright (c) 2019 Sherif Abdel-Naby

# Contribution

PR(s) are Open and welcomed.

This image has so little to do with Symfony itself and more with Setting up a PHP Website with Apache, hence it can be extended for other PHP Frameworks (e.g Laravel, etc). maybe if you're interested to build a similar image for another framework we can collaborate. 

### Possible Ideas

- [ ] Add a slim image with supervisor(and no apache) for running consumers.
- [ ] Add a slim image with cron tab(and no apache) for cron job instances.
- [ ] Add node build stage that compiles javascript.
- [ ] Recreate the image for Symfony 3^
- [ ] Recreate the image for Laravel
