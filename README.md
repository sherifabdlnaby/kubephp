<p align="center">
<img width="520px" src="https://user-images.githubusercontent.com/16992394/116017444-e03a4e00-a63f-11eb-8070-1cdf9fc8678e.png">
</p>
<h2 align="center">🐳 Production Grade, Rootless, Pre-configured, Extendable, and Multistage

PHP Docker Image for Cloud Native Deployments (and Kubernetes)</h2>

<h4 align="center">compatible with popular PHP Frameworks such as <a href="https://laravel.com/">Laravel 5+</a> &amp; <a href="https://symfony.com/">Symfony 4+</a> and their variants.</h4>

<p align="center">
	<a>
		<img src="https://img.shields.io/github/v/tag/sherifabdlnaby/phpdocker?label=release&amp;sort=semver">
    </a>
	<a>
		<img src="https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat" alt="contributions welcome">
	</a>
	<a>
		<img src="https://img.shields.io/badge/PHP-%3E=7-blueviolet" alt="PHP >=7^">
	</a>
	<a href="https://github.com/sherifabdlnaby/phpdocker/network">
		<img src="https://img.shields.io/github/forks/sherifabdlnaby/phpdocker.svg" alt="GitHub forks">
	</a>
	<a href="https://github.com/sherifabdlnaby/phpdocker/issues">
        <img src="https://img.shields.io/github/issues/sherifabdlnaby/phpdocker.svg" alt="GitHub issues">
	</a>
	<a href="https://raw.githubusercontent.com/sherifabdlnaby/phpdocker/blob/master/LICENSE">
		<img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="GitHub license">
	</a>
</p>

# Introduction
**Production Grade Docker Image for PHP 7+ Application** running for **Nginx + PHP FPM** based on [PHP](https://hub.docker.com/_/php) & [Nginx](https://hub.docker.com/_/nginx) **Official Images**, compatible with popular PHP Frameworks such as [Laravel 5+](https://laravel.com/) & [Symfony 4+](https://symfony.com/) and their variants.

This is a pre-configured template image for your PHP Project, **and you shall extend and edit it according to your app requirements.**

The Image utilizes multistage builds to create multiple targets optimized for **production** and **development**.

> ⚠️ This image is for PHP applications that uses a single-entrypoint framework in `public/index.php`, such as Laravel, Symfony, and all their variants.

## Main Points 📜

- Designed to run in orchestrated environments like Kubernetes.
- Multi-Container setup with `Nginx` & `PHP-FPM` communicating via TCP.
- Production Image that are **immutable** and **fully contained** with source code and dependencies inside.
- **Runs as non-root** in both application containers.
- Configured for graceful shutdowns/restarts, and correctly pass termination signal.
- Multi-stage builds for an optimized cache layers.
- Transparent configuration, all configuration determine app behavior are captured in VCS, such as PHP, FPM, and Nginx Config
- Production configuration with sane defaults tuned for performance.
- Easily extend the image with extra configuration, and scripts; such as post-build & pre-run scripts. 
- Fast container start time done by only doing the necessary steps at application start and offload anything else to build.
- Override-able container CMD, used to run PHP Commands, to be used for cron-jobs/consumers.
- Image tries to fail at build time as much as possible by running all sort of checks.
- Default Healtchecks embedded for PHP FPM and Nginx
- Development Image supports mounting code and hot-reloading.

## How to add to my project ?

- Copy this repository`Dockerfile`, `docker` Directory, `Makefile`, and `.dockerignore` to your application root directory and configure it to your needs.

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

- [Docker 20.05 or higher](https://docs.docker.com/install/) 
- [Docker-Compose 3.7 or higher](https://docs.docker.com/compose/install/) (optional)
- PHP >= 7 Application

# Setup

#### 1. Add Template to your repo.

1. Download This Repository
2. Copy `Dockerfile`, `docker` Directory, `Makefile`, and `.dockerignore` Into your Symfony Application Repository.

OR

<a href="https://github.com/sherifabdlnaby/phpdocker/generate">
<img src="https://user-images.githubusercontent.com/16992394/65464461-20c95880-de5a-11e9-9bf0-fc79d125b99e.png" alt="create repository from template"></a>

#### 2. Start
1. Modify `Dockerfile` to your app needs, and add your app needed PHP Extensions and Required Packages.
2. Run `make up` for development or `make deploy` for production. 
4. Go to [http://localhost](http://localhost:8080) 

> Makefile is just a wrapper over docker-compose commands.
      
## Building, Configuring and Extending Image 

### Image Targets and Build Arguments
- The image comes with a handy _Makefile_ to build the image using Docker-Compose files, it's handy when manually building the image for development or in a not-orchestrated docker host.
However, in an environment where CI/CD pipelines will build the image, they will need to supply some build-time arguments for the image. (tho defaults exist.)
    
    #### Build Time Arguments
    | **ARG**            | **Description**                                                                                                                                      | **Default** |
    |--------------------|------------------------------------------------------------------------------------------------------------------------------------------------------|-------------|
    | `PHP_VERSION`      | PHP Version used in the Image                                                                                                                        | `7.4`     |
    | `NGINX_VERSION`    | Nginx Version                                                                                                                                        | `1.17.4`    |
    | `COMPOSER_VERSION` | Composer Version used in Image                                                                                                                       | `2.0`     |
    | `COMPOSER_AUTH`    | A Json Object with Bitbucket or Github token to clone private Repos with composer.</br>[Reference](https://getcomposer.org/doc/03-cli.md#composer-auth) | `{}`        | 
    
    #### Runtime Environment Variables
    | **ENV**     | **Description** | **Default**                                                 |
    |-------------|-----------------|-------------------------------------------------------------|
    | `APP_ENV`   | App Environment | - `prod` for Production image</br> - `dev` for Development image     |
    | `APP_DEBUG` | Enable Debug    | - `0` for Production image</br>- `1` for Development image           |
    
    #### Image Targets
    
    | **Target** | Env         | Desc                                                                                                                                                                                                                                                                             | Size   | Based On                      |
    |------------|-------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------|-------------------------------|
    | app        | Production  | The PHP Application with immutable code/dependencies. By default starts `PHP-FPM` process listening on `9000`.  Command can be extended to run any PHP Consumer/Job, entrypoint will still start the pre-run setup and then run the supplied command.                            | ~450mb | PHP Official Image (Debian)   |
    | web        | Production  | The webserver, an Nginx container that is configured to server static content and forward dynamic requests to the PHP-FPM container running in the `app` image variant                                                                                                           | ~21mb  | Nginx Official Image (Alpine) |
    | app-dev    | Development | Development PHP Application variant with dependencies inside. Image expects the code to be mounted on `/var/www/app` to support hot-reloading. You need to mount dummy `/var/www/app/vendor` volume too to avoid code volume to overwrite dependencies already inside the image. | ~450mb | PHP Official Image (Debian)   |
    | web-dev    | Development | Development Webserver with the exact configuration as the production configuration. Expects public directory to be mounted at `/var/www/app/public`                                                                                                                              |    ~21mb     |   Nginx Official Image (Alpine)                            |

### Install System Dependencies and PHP Extensions
- The image is to be used as a base for your PHP application image, you should modify its Dockerfile to your needs.

    1. Install System Packages in the following section in the Dockerfile.
    ```dockerfile
    # ------------------------------------- Install Packages Needed Inside Base Image --------------------------------------
    
    RUN apt-get update && apt-get -y --no-install-recommends install \
        # Needed for Image
        ...
        # Needed for Application Runtime
        ...
        < INSTALL YOU APPLICATION DEPENDENCY SYSTEM PACKAGES HERE>
        ...
    ```
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

### PHP Configuration
1. PHP `base` Configuration that are common in all environments in `docker/php/base-php.ini`[🔗](https://github.com/sherifabdlnaby/phpdocker/blob/master/docker/php/base-php.ini) 
1. PHP `prod` Only Configuration  `docker/conf/php/php-prod.ini`[🔗](https://github.com/sherifabdlnaby/phpdocker/blob/master/docker/php/prod-php.ini) 
2. PHP `dev` Only Configuration  `docker/conf/php/php-dev.ini`[🔗](https://github.com/sherifabdlnaby/phpdocker/blob/master/docker/php/dev-php.ini) 

### PHP FPM Configuration
1. PHP FPM Configuration  `docker/fpm/*.conf` [🔗](https://github.com/sherifabdlnaby/phpdocker/blob/master/docker/fpm)

### Nginx Configuration
1. Nginx Configuration  `docker/nginx/*.conf && docker/nginx/conf.d/* ` [🔗](https://github.com/sherifabdlnaby/phpdocker/blob/master/docker/nginx)

## Post Build and Pre Run optional scripts.

In `docker/` directory there is `post-build` and `post-install` scripts that are used **to extend the image** and add extra behavior.

1. `post-build` command runs at the end of Image build.
   
    Run as the last step during the image build. Are Often framework specific commands that generate optimized builds.
   
2. `pre-run` command runs **in runtime** before running the container main command
   
    Runs before the container's CMD, but after the composer's post-install and post-autload-dump. Used for commands that needs to run at runtime before the application is started. Often are scripts that depends on other services or runtime parameters.

--------

# Misc Notes
- Your application [should log app logs to stdout.](https://stackoverflow.com/questions/38499825/symfony-logs-to-stdout-inside-docker-container). Read about [12factor/logs](https://12factor.net/logs) 
- By default, `php-fpm` access logs are disabled as they're mirrored on `nginx`, this is so that `php-fpm` image will contain **only** application logs written by PHP.
- In **production**, Image contains source-code, however, you must sync both `php-fpm` and `nginx` images so that they contain the same code.


--------

# FAQ

1. Why two containers instead of one ?

    1. In containerized environment, you need to only run one process inside the container. This allows us to better instrument our application for many reasons like separation of health status, metrics, logs, etc.

2. Why `debian` based image not `alpine` ?
    
    1. While a smaller image is very desired, and PHP image is infamous of being big. Alpine lacks a lot of packages (Available via `apk`) that a typical PHP would need. Some packages are not even available for alpine as they link to glibc not musl.
    2. The image is `alpine` compatible, even the entrypoint and helper scripts are `sh` compatible, modifying the image to use `alpine` variant is possible with minimal changes to the image, you'll need to install the same package you're already using but for `alpine` and using `apk`.  
3. Image Build Fails as it try to connect to DB.
    
    - A typical application in most Frameworks comes with `Doctrine` ORM, Doctrine if not configured with a DB Version, will try to access the DB at php's script initialization (even at the post-install cmd's), and it will fail when it cannot connect to DB. Make sure you configure doctrine to avoid this extra DB Check connection.


# License 
[MIT License](https://raw.githubusercontent.com/sherifabdlnaby/phpdocker/blob/master/LICENSE)
Copyright (c) 2021 Sherif Abdel-Naby

# Contribution

PR(s) are Open and welcomed.
