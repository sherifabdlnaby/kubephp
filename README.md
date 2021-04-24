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
**Production Grade Docker Image for PHP 7+ Application** running for **Nginx + PHP FPM** based on [PHP](https://hub.docker.com/_/php) & [Nginx](https://hub.docker.com/_/nginx) **Official Images**, compatible with popular PHP Frameworks such as [Laravel 5+](https://laravel.com/) & [Symfony 4+](https://symfony.com/) and their variants.

This is a pre-configured template image for your PHP Project, **and you shall extend and edit it according to your app requirements.**

The Image utilizes multistage builds to create multiple targets optimized for **production** and **development**.

> ⚠️ This image is for PHP applications that uses a single-entrypoint framework in `public/index.php`, such as Laravel, Symfony, and all their variants.

## Main Points 📜

- Designed to run in orchestrated environments like Kubernetes.
- Multi-Container setup with `Nginx` & `PHP-FPM` communicating via TCP.
- Production Image that are **immutable** and **fully contained** with source code and dependencies inside.
- Multi-stage builds for an optimized cache layers.
- Transparent configuration, all configuration determine app behavior are captured in VCS, such as PHP, FPM, and Nginx Config
- Production configuration with saint defaults tuned for performance.
- Easily extend the image with extra configuration, and scripts; with predictable execution. 
- Fast container start time.
- Development Image supports mounting code and hot-reloading.
- Image tries to fail at build time as much as possible by running all sort of checks.

## How to add to my project ?

- Copy this repository`Dockerfile`, `docker` Directory, `Makefile`, and `.dockerignore` to your application root directory and configure it to your needs.

## How to configure image to run my project ?

- You'll need to iterate over your application's dependency system packages, and required PHP Extensions; and add them to their respective locations in the image. (instructions below) 

-----
# Requirements 

- [Docker 20.05 or higher](https://docs.docker.com/install/) 
- [Docker-Compose 3.5 or higher](https://docs.docker.com/compose/install/) (optional)
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
1. PHP `base` Configuration that are common in all environments in `docker/php/base-php.ini`[🔗](https://github.com/sherifabdlnaby/symdocker/blob/master/docker/php/base-php.ini) 
1. PHP `prod` Only Configuration  `docker/conf/php/php-prod.ini`[🔗](https://github.com/sherifabdlnaby/symdocker/blob/master/docker/php/prod-php.ini) 
2. PHP `dev` Only Configuration  `docker/conf/php/php-dev.ini`[🔗](https://github.com/sherifabdlnaby/symdocker/blob/master/docker/php/dev-php.ini) 


### PHP FPM Configuration

Nginx defaults are all defined in `docker/conf/nginx/` [🔗](https://github.com/sherifabdlnaby/symdocker/blob/master/docker/conf/nginx/)

Nginx is pre-configured with:
1. HTTP, HTTPS, and HTTP2.
2. Rate limit (`rate=5r/s`)
3. Access & Error logs to `stdout/err`
4. Recommended Security Headers
5. Serving Static content with default cache `7d`
6. Metrics endpoint at `:8080/stub_status` from localhost only.

--------

# Misc Notes
- Your application [should log app logs to stdout.](https://stackoverflow.com/questions/38499825/symfony-logs-to-stdout-inside-docker-container). Read about [12factor/logs](https://12factor.net/logs) 
- By default, `php-fpm` access & error logs are disabled as they're mirrored on `nginx`, this is so that `php-fpm` image will contain **only** application logs written by PHP.
- During Build, Image will run `composer dump-autoload` and `composer dump-env` to optimize for performance.
- In **production**, Image contains source-code, however, you must sync both `php-fpm` and `nginx` images so that they contain the same code.

# License 
[MIT License](https://raw.githubusercontent.com/sherifabdlnaby/symdocker/blob/master/LICENSE)
Copyright (c) 2021 Sherif Abdel-Naby

# Contribution

PR(s) are Open and welcomed.