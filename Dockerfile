# ---------------------------------------------- Build Time Arguments --------------------------------------------------

ARG PHP_VERSION="7.3.9"
ARG COMPOSER_VERSION="1.9.0"

# -------------------------------------------------- Composer Image ----------------------------------------------------

FROM composer:${COMPOSER_VERSION} as composer

# ======================================================================================================================
#                                                   --- BASE ---
# ---------------  This stage install needed extenstions, plugins and add all needed configurations  -------------------
# ======================================================================================================================
FROM php:${PHP_VERSION}-apache-stretch AS base

# Maintainer label
LABEL maintainer="sherifabdlnaby@gmail.com"

# ------------------------------------- Install Packages Needed Inside Base Image --------------------------------------

RUN apt-get -yqq update && apt-get -yqq --no-install-recommends install \
    # -----  Needed for PHP -----------------
    # - Please define package version too ---
    curl=7.52\* \
    # ---------------------------------------
    && apt-get -qq autoremove --purge -y  \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ---------------------------------------- Install / Enable PHP Extensions ------------------------------------------

# - base image has helper scripts docker-php-ext-configure, docker-php-ext-install, and docker-php-ext-enable to
#   more easily install PHP extensions.
#   head to: https://github.com/docker-library/docs/tree/master/php#how-to-install-more-php-extensions
#   EX: RUN docker-php-ext-install curl pdo pdo_mysql mysqli
#   EX: RUN pecl install memcached && docker-php-ext-enable memcached

RUN docker-php-ext-install opcache

# ------------------------------------------------------ PHP -----------------------------------------------------------

# Copy Symfony PHP config
COPY .docker/conf/php/symfony.ini   $PHP_INI_DIR/conf.d/symfony.ini

# ---------------------------------------------------- Apache ----------------------------------------------------------

ARG SERVER_NAME="php-app"
ENV SERVER_NAME $SERVER_NAME

#-- Generate Default Self-signed SSL Certificate
RUN openssl genrsa -des3 -passout pass:xxxxx -out server.pass.key 2048              && \
    openssl rsa -passin pass:xxxxx -in server.pass.key -out server.key              && \
    openssl req -new -key server.key -out server.csr -subj "/CN=${SERVER_NAME}"     && \
    openssl x509 -req -days 3650 -in server.csr -signkey server.key -out server.crt && \
    mkdir /etc/apache2/certs && cp server.key server.crt /etc/apache2/certs         && \
#-- Enable SSL
    a2enmod ssl																		&& \
#-- Remove Apache Default Sites
    rm -rf /etc/apache2/sites-*/*  /var/www/*

# Copy Image Config
COPY .docker/conf/apache2/apache2.conf  /etc/apache2/apache2.conf
COPY .docker/conf/apache2/main.conf		/etc/apache2/conf-available/main.conf
COPY .docker/conf/apache2/site.conf		/etc/apache2/sites-available/site.conf

# Enable image's site (Enables both HTTP & HTTPS), and Test all config is OK.
RUN a2ensite site && apachectl configtest

# ---------------------------------------------------- Composer --------------------------------------------------------

ENV COMPOSER_ALLOW_SUPERUSER 1
COPY --from=composer /usr/bin/composer /usr/bin/composer

# -------------------------------------------------- DIR & PORT --------------------------------------------------------

WORKDIR /var/www/app
EXPOSE 80 443

# -------------------------------------------------- ENTRYPOINT --------------------------------------------------------

# Main entrypoint and Post-deployment custom command
COPY .docker/.scripts/docker-entrypoint.sh          /usr/local/bin/docker-entrypoint
COPY .docker/.scripts/docker-post-deploy-wrapper.sh /usr/local/bin/docker-post-deploy-wrapper
COPY .docker/post-deployment.sh                     /usr/local/bin/docker-post-deployment
RUN chmod +x /usr/local/bin/docker-*

ENTRYPOINT ["docker-entrypoint"]

# ======================================================================================================================
#                                                  --- Vendor ---
# ---------------  This stage will install composer runtime dependinces and install app dependinces.  ------------------
# ======================================================================================================================

FROM composer as vendor

# Quicken Composer Installation by paralleizing downloads
RUN composer global require hirak/prestissimo --prefer-dist

# Copy Dependencies files
COPY composer.json composer.json
COPY composer.lock composer.lock

# Set PHP Version of the Image
RUN composer config platform.php ${PHP_VERSION}

# A Json Object with Bitbucket or Github token to clone private Repos with composer
# Reference: https://getcomposer.org/doc/03-cli.md#composer-auth
ARG COMPOSER_AUTH={}
ENV COMPOSER_AUTH $COMPOSER_AUTH

# Install Dependeinces
RUN composer install -n --ignore-platform-reqs --no-plugins --no-scripts --no-autoloader --no-dev --prefer-dist

# ======================================================================================================================
#                                                   --- PROD ---
# ---------------------  Copies Source Code and Dependinces into Image, and run autoload/env dump  ---------------------
# ======================================================================================================================

FROM base AS prod

ENV APP_ENV prod
ENV APP_DEBUG 0

# Copy In prod PHP config
COPY .docker/conf/php/php-prod.ini  $PHP_INI_DIR/php.ini

# Add Vendor Packages
COPY --from=vendor /app/vendor /var/www/app/vendor

# Copy Source Code
COPY . .

# 1. Dump optimzed autoload for vendor and app classes.
# 2. Dump env from .env and .env.prod to .env.local.php for env variables defaults and optimzed loading.
# 	 --no-scripts as scripts are run on runtime via entrypoint.
# 3. checks that PHP and extensions versions match the platform requirements of the installed packages.
RUN composer dump-autoload -n -o --no-scripts --no-dev && composer dump-env prod && composer check-platform-reqs

VOLUME ["/etc/apache2/certs"]

# ======================================================================================================================
#                                                   --- DEV ---
# --------------  Install Development Utilits and Add Dev Entrypoint that support source code mounting  ----------------
# ======================================================================================================================

FROM base AS dev

ENV APP_ENV dev
ENV APP_DEBUG 1

# --------------------------------------------------- Packages ---------------------------------------------------------

ARG COMPOSER_RUNTIME_DEPS="git make openssh-client unzip zip"
ARG DEV_IMAGE_UTILS="curl wget nano htop iputils-ping sysstat dnsutils"
RUN apt-get -yqq update && apt-get -yqq  --no-install-recommends install \
    # ----- Needed For Composer  --------------------
    ${COMPOSER_RUNTIME_DEPS} \
    # ----- Utilites --------------------------------
    ${DEV_IMAGE_UTILS}

# ---------------------------------------------------- Xdebug ----------------------------------------------------------

RUN pecl install xdebug && docker-php-ext-enable xdebug
COPY .docker/conf/php/xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# ------------------------------------------------------ PHP -----------------------------------------------------------

# Copy In dev PHP config
COPY .docker/conf/php/php-dev.ini  $PHP_INI_DIR/php.ini

# ------------------------------------------------- Entry Point --------------------------------------------------------

COPY .docker/.scripts/docker-dev-entrypoint.sh /usr/local/bin/docker-dev-entrypoint
RUN chmod +x /usr/local/bin/docker-dev-entrypoint

ENTRYPOINT ["docker-dev-entrypoint"]

# A Json Object with Bitbucket or Github token to clone private Repos with composer (needed in dev entrypoint)
# Reference: https://getcomposer.org/doc/03-cli.md#composer-auth
ARG COMPOSER_AUTH={}
ENV COMPOSER_AUTH $COMPOSER_AUTH