# ---------------------------------------------- Build Time Arguments --------------------------------------------------
ARG PHP_VERSION="7.4"
ARG NGINX_VERSION="1.17.4"
ARG COMPOSER_VERSION="2.0"
ARG XDEBUG_VERSION="3.0.3"
ARG COMPOSER_AUTH

# -------------------------------------------------- Composer Image ----------------------------------------------------

FROM composer:${COMPOSER_VERSION} as composer

# ======================================================================================================================
#                                                   --- Base ---
# ---------------  This stage install needed extenstions, plugins and add all needed configurations  -------------------
# ======================================================================================================================

FROM php:${PHP_VERSION}-fpm AS base

# Maintainer label
LABEL maintainer="sherifabdlnaby@gmail.com"

# ------------------------------------- Install Packages Needed Inside Base Image --------------------------------------

RUN apt-get update && apt-get -y --no-install-recommends install \
    # Needed for Image
    libfcgi-bin                 \
    tini                        \
    # Needed for PHP

    # Clean metadata and clear caches
    && apt-get autoremove --purge -y && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ---------------------------------------- Install / Enable PHP Extensions ---------------------------------------------

# - base image has helper scripts docker-php-ext-configure, docker-php-ext-install, and docker-php-ext-enable to
#   more easily install PHP extensions.
#   head to: https://github.com/docker-library/docs/tree/master/php#how-to-install-more-php-extensions
#   EX: RUN docker-php-ext-install curl pdo pdo_mysql mysqli
#   EX: RUN pecl install memcached && docker-php-ext-enable memcached
RUN docker-php-ext-install \
    opcache     \
    pdo_mysql
    # Pecl Extentions
#   EX: RUN pecl install memcached && docker-php-ext-enable memcached

# ------------------------------------------------------ PHP -----------------------------------------------------------

# Add Basic Config
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
COPY docker/php/base-*   $PHP_INI_DIR/conf.d/

# ------------------------------------------------------ FPM -----------------------------------------------------------

# Clean bundled basic config & create composer directories (since we run as non-root later)
RUN rm -rf /var/www /usr/local/etc/php-fpm.d/* && \
    mkdir -p /var/www/.composer /var/www/app && chown -R www-data:www-data /var/www/

# Copy PHP-FPM config, scripts, and validate syntax.
COPY docker/fpm/*.conf          /usr/local/etc/php-fpm.d/
COPY docker/fpm/docker-*	    /usr/local/bin/
COPY docker/docker-base-*       /usr/local/bin/
COPY docker/docker-healthcheck  /usr/local/bin/docker-healthcheck
RUN  chmod +x /usr/local/bin/docker-*

# ---------------------------------------------------- Composer --------------------------------------------------------

ENV COMPOSER_ALLOW_SUPERUSER 1
COPY --from=composer /usr/bin/composer /usr/bin/composer

# ----------------------------------------------------- MISC -----------------------------------------------------------

WORKDIR /var/www/app
ENV APP_ENV prod
ENV APP_DEBUG 0

# ---------------------------------------------------- HEALTH ----------------------------------------------------------

HEALTHCHECK CMD ["docker-healthcheck"]

# -------------------------------------------------- ENTRYPOINT --------------------------------------------------------

ENTRYPOINT ["docker-base-entrypoint"]
CMD ["php-fpm"]

# ======================================================================================================================
#                                                  --- NGINX ---
# ---------------  This stage will install composer runtime dependinces and install app dependinces.  ------------------
# ======================================================================================================================
FROM nginx:${NGINX_VERSION}-alpine AS nginx

RUN rm -rf /var/www/* /etc/nginx/conf.d/* /usr/local/etc/php-fpm.d/* && \
 	adduser -u 82 -D -S -G www-data www-data

COPY docker/nginx/docker-* /usr/local/bin/
COPY docker/nginx/ /etc/nginx/
RUN chmod +x /usr/local/bin/docker-*

# The PHP-FPM Host
## Localhost is the sensible default assuming image run on a k8S Pod
ENV PHP_FPM_HOST "localhost"
ENV PHP_FPM_PORT "9000"

# Allow Nginx to run as non-root.
RUN chown -R www-data:www-data /var/cache/nginx /etc/nginx/ /etc/nginx/conf.d/

# Change to non root user
USER www-data

# For Documentation
EXPOSE 8080

# Add Healthcheck
HEALTHCHECK CMD ["docker-nginx-healthcheck"]

# Add Entrypoint
ENTRYPOINT ["docker-nginx-entrypoint"]

# ======================================================================================================================
#                                                  --- Vendor ---
# ---------------  This stage will install composer runtime dependinces and install app dependinces.  ------------------
# ======================================================================================================================

FROM composer as vendor

ARG PHP_VERSION
ARG COMPOSER_AUTH
# A Json Object with Bitbucket or Github token to clone private Repos with composer
# Reference: https://getcomposer.org/doc/03-cli.md#composer-auth
ENV COMPOSER_AUTH $COMPOSER_AUTH

# Copy Dependencies files
COPY composer.json composer.json
COPY composer.lock composer.lock

# Set PHP Version of the Image && create the vendor directory
RUN composer config platform.php ${PHP_VERSION}

# Install Dependeinces
## * Platform requirments are checked at the next image steps.
## * Scripts and Autoload are run at the next image steps.
RUN composer install -n --no-progress --ignore-platform-reqs --no-plugins --no-scripts --no-autoloader --prefer-dist

# ======================================================================================================================
# ===========================================  PRODUCTION FINAL STAGES  ================================================
#                                                   --- PROD ---
# ======================================================================================================================

# ----------------------------------------------------- NGINX ----------------------------------------------------------
FROM nginx AS web

# Copy Public folder + Assets that's going to be served from Nginx
COPY public /var/www/app/public

# ------------------------------------------------------ FPM -----------------------------------------------------------
FROM base AS app

# Copy Vendor
COPY --from=vendor /app/vendor /var/www/app/vendor

# Copy App Code
COPY . .

# Copy Entrypoint
COPY docker/docker-prod-*       /usr/local/bin/
RUN  chmod +x /usr/local/bin/docker-prod-* && \
     chown -R www-data:www-data /var/www/app/vendor && chown www-data:www-data /var/www/app

# Run as non-root
USER www-data

# 1. Dump optimzed autoload for vendor and app classes.
# 2. Dump env from .env and .env.prod to .env.local.php for env variables defaults and optimzed loading.
# 	 --no-scripts as scripts are run on runtime via entrypoint.
# 3. checks that PHP and extensions versions match the platform requirements of the installed packages.
RUN composer dump-autoload -n --optimize --no-scripts --no-dev && composer check-platform-reqs

# Validate FPM config
RUN php-fpm -t

ENTRYPOINT ["docker-prod-entrypoint"]
CMD ["php-fpm"]

# ======================================================================================================================
# ===========================================  DEVELOPMENT FINAL STAGES  ===============================================
#                                                   --- DEV ---
# ======================================================================================================================

# ----------------------------------------------------- NGINX ----------------------------------------------------------
FROM nginx AS web-dev
## Place holder to have a consistent naming.

# ------------------------------------------------------ FPM -----------------------------------------------------------
FROM base as app-dev

ARG COMPOSER_AUTH
ARG XDEBUG_VERSION
ENV COMPOSER_AUTH $COMPOSER_AUTH
ENV APP_ENV dev
ENV APP_DEBUG 1

# --------------------------------------------------- Packages ---------------------------------------------------------

# Switch Back to root to install stuff
USER root

RUN apt-get update && apt-get -y --no-install-recommends install \
    # Needed for Dev luxery when you shell inside the container for debugging
    curl    \
    ## For Composer cloning in dev env
    unzip     \
    && apt-get autoremove --purge -y && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
# ---------------------------------------------------- Xdebug ----------------------------------------------------------

RUN pecl install xdebug-${XDEBUG_VERSION} && docker-php-ext-enable xdebug

# ------------------------------------------------------ PHP -----------------------------------------------------------

RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
COPY docker/php/dev-*   $PHP_INI_DIR/conf.d/

# ------------------------------------------------- Entry Point --------------------------------------------------------

# Copy Entrypoint
COPY docker/docker-dev-*       /usr/local/bin/
RUN  chmod +x /usr/local/bin/docker-dev-*

USER www-data

# Validate FPM config
RUN php-fpm -t
ENTRYPOINT ["docker-dev-entrypoint"]
CMD ["php-fpm"]
