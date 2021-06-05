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
    tini=0.18.0-1               \
    libfcgi-bin=2.4.0-10        \
    libicu-dev=63.1-6+deb10u1   \
    gettext-base                \
    # Needed for Application Runtime

    # Clean metadata and clear caches
    && apt-get autoremove --purge -y && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ---------------------------------------- Install / Enable PHP Extensions ---------------------------------------------

# - base image has helper scripts docker-php-ext-configure, docker-php-ext-install, and docker-php-ext-enable to
#   more easily install PHP extensions.
#   head to: https://github.com/docker-library/docs/tree/master/php#how-to-install-more-php-extensions
#   EX: RUN docker-php-ext-install curl pdo pdo_mysql mysqli
#   EX: RUN pecl install memcached && docker-php-ext-enable memcached
RUN docker-php-ext-install -j$(nproc) \
    opcache     \
    intl        \
    pdo_mysql
    # Pecl Extentions
RUN pecl install apcu-5.1.20 && docker-php-ext-enable apcu
#   EX: RUN pecl install memcached && docker-php-ext-enable memcached

# ------------------------------------------------ PHP Configuration ---------------------------------------------------

# Add Default Config
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Add in Base PHP Config
COPY docker/php/base-*   $PHP_INI_DIR/conf.d

# ---------------------------------------------- PHP FPM Configuration -------------------------------------------------

# Clean bundled config & create composer directories (since we run as non-root later)
RUN usermod -u 1000 www-data && rm -rf /var/www /usr/local/etc/php-fpm.d/* && \
    mkdir -p /var/www/.composer /var/www/app && chown -R www-data:www-data /var/www/app /var/www/.composer

# Copy scripts and PHP-FPM config
COPY docker/fpm/*.conf          /usr/local/etc/php-fpm.d/

# --------------------------------------------------- Scripts ----------------------------------------------------------

COPY docker/entrypoints             /usr/local/bin/
COPY docker/healthcheck             /usr/local/bin/
COPY docker/post-build              /usr/local/bin/
COPY docker/pre-run                 /usr/local/bin/
COPY docker/fpm/fpm-healthcheck     /usr/local/bin/
RUN  chmod +x /usr/local/bin/entrypoint-* /usr/local/bin/post-build /usr/local/bin/pre-run /usr/local/bin/*healthcheck

# ---------------------------------------------------- Composer --------------------------------------------------------

COPY --from=composer /usr/bin/composer /usr/bin/composer

# ----------------------------------------------- NON-ROOT SWITCH ------------------------------------------------------

USER www-data

# ----------------------------------------------------- MISC -----------------------------------------------------------

WORKDIR /var/www/app
ENV APP_ENV prod
ENV APP_DEBUG 0

# Run as non-root
USER www-data

# Validate FPM config
RUN php-fpm -t

# ---------------------------------------------------- HEALTH ----------------------------------------------------------

HEALTHCHECK CMD ["healthcheck"]

# -------------------------------------------------- ENTRYPOINT --------------------------------------------------------

ENTRYPOINT ["entrypoint-base"]
CMD ["php-fpm"]

# ======================================================================================================================
#                                                  --- Vendor ---
# ---------------  This stage will install composer runtime dependinces and install app dependinces.  ------------------
# ======================================================================================================================

FROM composer as vendor

ARG PHP_VERSION
ARG COMPOSER_AUTH
# A Json Object with remote repository token to clone private Repos with composer
# Reference: https://getcomposer.org/doc/03-cli.md#composer-auth
ENV COMPOSER_AUTH $COMPOSER_AUTH

# Copy Dependencies files
COPY composer.json composer.json
COPY composer.lock composer.lock

# Set PHP Version of the Image
RUN composer config platform.php ${PHP_VERSION}

# Install Dependeinces
## * Platform requirments are checked at the later steps.
## * Scripts and Autoload are run at later steps.
RUN composer install -n --no-progress --ignore-platform-reqs --no-plugins --no-scripts --no-dev --no-autoloader --prefer-dist

# ======================================================================================================================
# ==============================================  PRODUCTION IMAGE  ====================================================
#                                                   --- PROD ---
# ======================================================================================================================

FROM base AS app

COPY docker/php/prod-*   $PHP_INI_DIR/conf.d/

# Copy Vendor
COPY --chown=www-data:www-data --from=vendor /app/vendor /var/www/app/vendor

# Copy App Code
COPY --chown=www-data:www-data . .

# 1. Dump optimzed autoload for vendor and app classes.
# 2. checks that PHP and extensions versions match the platform requirements of the installed packages.
RUN composer dump-autoload -n --optimize --no-dev --apcu && \
    composer check-platform-reqs && \
    composer run-script -n post-install-cmd && \
    post-build

ENTRYPOINT ["entrypoint-prod"]
CMD ["php-fpm"]

# ======================================================================================================================
# ==============================================  DEVELOPMENT IMAGE  ===================================================
#                                                   --- DEV ---
# ======================================================================================================================

FROM base as app-dev

ARG XDEBUG_VERSION
ENV APP_ENV dev
ENV APP_DEBUG 1

# Switch to root to install stuff
USER root

# Packages
RUN apt-get update && apt-get -y --no-install-recommends install \
    # Needed for Dev luxery when you shell inside the container for debugging
    curl     \
    htop     \
    dnsutils \
    && apt-get autoremove --purge -y && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ---------------------------------------------------- Xdebug ----------------------------------------------------------

RUN pecl install xdebug-${XDEBUG_VERSION} && docker-php-ext-enable xdebug

# ------------------------------------------------------ PHP -----------------------------------------------------------

RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
COPY docker/php/dev-*   $PHP_INI_DIR/conf.d/

# ------------------------------------------------- Entry Point --------------------------------------------------------

# Run as non-root
USER www-data

# Entrypoints
ENTRYPOINT ["entrypoint-dev"]
CMD ["php-fpm"]


# ======================================================================================================================
# ======================================================================================================================
#                                                  --- NGINX ---
# ======================================================================================================================
# ======================================================================================================================
FROM nginx:${NGINX_VERSION}-alpine AS nginx

RUN rm -rf /var/www/* /etc/nginx/conf.d/* && adduser -u 1000 -D -S -G www-data www-data

COPY docker/nginx/nginx-*   /usr/local/bin/
COPY docker/nginx/          /etc/nginx/
RUN chmod +x /usr/local/bin/nginx-*

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
HEALTHCHECK CMD ["nginx-healthcheck"]

# Add Entrypoint
ENTRYPOINT ["nginx-entrypoint"]

# ======================================================================================================================
#                                                 --- NGINX PROD ---
# ======================================================================================================================

FROM nginx AS web

# Copy Public folder + Assets that's going to be served from Nginx
COPY public /var/www/app/public


# ----------------------------------------------------- NGINX ----------------------------------------------------------
FROM nginx AS web-dev
## Place holder to have a consistent naming.