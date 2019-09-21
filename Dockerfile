# ---------------------------------------------- Build Time Arguments --------------------------------------------------

ARG PHP_VERSION="7.3.9"
ARG SERVER_NAME="php-app"

# A Json Object with Bitbucket or Github token to clone private Repos
# Reference: https://getcomposer.org/doc/03-cli.md#composer-auth
ARG COMPOSER_AUTH={}
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

# ----------------------------------------------- Environment Variables ------------------------------------------------

# Inherit ARGs from global scope.
ARG SERVER_NAME
ARG COMPOSER_AUTH

# Setup ENV
ENV SERVER_NAME $SERVER_NAME
ENV COMPOSER_AUTH $COMPOSER_AUTH
ENV COMPOSER_ALLOW_SUPERUSER 1

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

# Setup Apache
#-- Generate Default Self-signed SSL Certificate
RUN openssl genrsa -des3 -passout pass:xxxxx -out server.pass.key 2048              && \
    openssl rsa -passin pass:xxxxx -in server.pass.key -out server.key              && \
    openssl req -new -key server.key -out server.csr -subj "/CN=${SERVER_NAME}"     && \
    openssl x509 -req -days 3650 -in server.csr -signkey server.key -out server.crt && \
    mkdir /etc/apache2/certs && cp server.key server.crt /etc/apache2/certs         && \
#-- Remove Apache Default Sites
    rm -rf /etc/apache2/sites-*/*  /var/www/*

# Copy Image Config
COPY .docker/conf/apache2/apache2.conf  /etc/apache2/apache2.conf
COPY .docker/conf/apache2/main.conf     /etc/apache2/main.conf
COPY .docker/conf/apache2/site.conf     /etc/apache2/sites-available/site.conf

# Enable SSL and Enable image's site (Enables both HTTP & HTTPS)
RUN a2enmod ssl && a2ensite site

# ---------------------------------------------------- Composer --------------------------------------------------------

# Install Composer
COPY --from=composer /usr/bin/composer /usr/bin/composer

# -------------------------------------------------- DIR & PORT --------------------------------------------------------

WORKDIR /var/www/app
EXPOSE 80 433

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

FROM base AS vendor

ENV COMPOSER_RUNTIME_DEPS "git make openssh-client unzip zip"

# Install Composer Runtime Dependencies
RUN apt-get -yqq update && apt-get -yqq --no-install-recommends install \
    # -----  Needed For Composer  ------------------
    ${COMPOSER_RUNTIME_DEPS} \
    && apt-get -qq autoremove --purge -y  \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Quicken Composer Installation by paralleizing downloads
RUN composer global require hirak/prestissimo --prefer-dist

# Copy Dependencies files
COPY composer.json composer.json
COPY composer.lock composer.lock

# Install Dependeinces
RUN composer install --no-interaction --no-plugins --no-scripts --no-autoloader --no-dev --prefer-dist

# ======================================================================================================================
#                                                   --- PROD ---
# ---------------------  Copies Source Code and Dependinces into Image, and run autoload/env dump  ---------------------
# ======================================================================================================================

FROM base AS prod

ENV APP_ENV prod
ENV APP_DEBUG 0

# Add Vendor Packages
COPY --from=vendor /var/www/app/vendor /var/www/app/vendor

# Copy Source Code
COPY . .

# Dump optimzed autoload for vendor and app classes.
# Dump env from .env and .env.prod to .env.local.php for env variables defaults and optimzed loading.
# --no-scripts as scripts are run on runtime via entrypoint.
RUN composer dump-autoload -n -o --no-scripts --no-dev && composer dump-env prod

# Copy In prod PHP config
COPY .docker/conf/php/php-prod.ini  $PHP_INI_DIR/php.ini

VOLUME ["/etc/apache2/certs"]

# ======================================================================================================================
#                                                   --- DEV ---
# --------------  Install Development Utilits and Add Dev Entrypoint that support source code mounting  ----------------
# ======================================================================================================================

FROM base AS dev

ENV APP_ENV dev
ENV APP_DEBUG 1
ENV COMPOSER_RUNTIME_DEPS "git make openssh-client unzip zip"
ENV DEV_IMAGE_UTILS "curl wget nano htop iputils-ping sysstat dnsutils"

# --------------------------------------------------- Packages ---------------------------------------------------------

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
