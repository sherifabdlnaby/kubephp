# ---------------------------------------------- Build Time Arguments --------------------------------------------------

ARG PHP_VERSION="7.3.9"
ARG ALPINE_VERSION="3.10"
ARG NGINX_VERSION="1.17.4"
ARG COMPOSER_VERSION="1.9.0"

# -------------------------------------------------- Composer Image ----------------------------------------------------

FROM composer:${COMPOSER_VERSION} as composer

# ======================================================================================================================
#                                                   --- Base ---
# ---------------  This stage install needed extenstions, plugins and add all needed configurations  -------------------
# ======================================================================================================================

FROM php:${PHP_VERSION}-fpm-alpine${ALPINE_VERSION} AS base

# Maintainer label
LABEL maintainer="sherifabdlnaby@gmail.com"

# ------------------------------------- Install Packages Needed Inside Base Image --------------------------------------

RUN apk add --no-cache		\
#    # - Please define package version too ---
#    # -----  Needed for Image----------------
	fcgi tini \
#    # -----  Needed for PHP -----------------
    curl

# ---------------------------------------- Install / Enable PHP Extensions ------------------------------------------

# - base image has helper scripts docker-php-ext-configure, docker-php-ext-install, and docker-php-ext-enable to
#   more easily install PHP extensions.
#   head to: https://github.com/docker-library/docs/tree/master/php#how-to-install-more-php-extensions
#   EX: RUN docker-php-ext-install curl pdo pdo_mysql mysqli
#   EX: RUN pecl install memcached && docker-php-ext-enable memcached

RUN docker-php-ext-install opcache

# ------------------------------------------------------ PHP -----------------------------------------------------------

COPY docker/conf/php/php-prod.ini  $PHP_INI_DIR/php.ini
COPY docker/conf/php/symfony.ini   $PHP_INI_DIR/conf.d/symfony.ini

# ---------------------------------------------------- Composer --------------------------------------------------------

ENV COMPOSER_ALLOW_SUPERUSER 1
COPY --from=composer /usr/bin/composer /usr/bin/composer

# ----------------------------------------------------- MISC -----------------------------------------------------------

WORKDIR /var/www/app
ENV APP_ENV prod
ENV APP_DEBUG 0

# -------------------------------------------------- ENTRYPOINT --------------------------------------------------------

# Add scripts and Entrypoint + clean!
COPY docker/healthcheck.sh			/usr/local/bin/docker-healthcheck
COPY docker/post-deployment.sh		/usr/local/bin/docker-post-deployment
COPY docker/.scripts/base/*		/usr/local/bin/
RUN  chmod +x /usr/local/bin/docker* && rm -rf /var/www/* /usr/local/etc/php-fpm.d/*

HEALTHCHECK CMD ["docker-healthcheck"]
CMD ["docker-base-entrypoint"]

# ======================================================================================================================
#                                                   --- FPM ---
# ---------------  This stage will install composer runtime dependinces and install app dependinces.  ------------------
# ======================================================================================================================

FROM base AS fpm

# Copy PHP-FPM config, scripts, and validate syntax.
COPY docker/conf/php-fpm/	/usr/local/etc/php-fpm.d/
COPY docker/.scripts/fpm/	/usr/local/bin/

# Chmod scripts, validate Syntax
RUN  chmod +x /usr/local/bin/docker-fpm-* && php-fpm -t

HEALTHCHECK CMD ["docker-fpm-healthcheck"]
ENTRYPOINT ["docker-fpm-entrypoint"]

# ======================================================================================================================
#                                                  --- NGINX ---
# ---------------  This stage will install composer runtime dependinces and install app dependinces.  ------------------
# ======================================================================================================================
FROM nginx:${NGINX_VERSION}-alpine AS nginx

ARG SERVER_NAME="symdocker"
ENV SERVER_NAME=$SERVER_NAME

RUN apk add --no-cache openssl											&& \
 	openssl dhparam -out "/etc/nginx/dhparam.pem" 2048					&& \
 	rm -rf /var/www/* /etc/nginx/conf.d/* /usr/local/etc/php-fpm.d/*	&& \
 	adduser -u 82 -D -S -G www-data www-data

COPY docker/.scripts/nginx /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-nginx-*

# Init SSL Certificates & Validate Conf Syntax
RUN docker-nginx-init-certs $SERVER_NAME "server" "/etc/nginx/ssl" && nginx -t

# Copy Nginx Config
COPY docker/conf/nginx/ /etc/nginx/

# Add Healthcheck
HEALTHCHECK CMD ["docker-nginx-healthcheck"]

# Add Entrypoint
ENTRYPOINT ["docker-nginx-entrypoint"]

# ======================================================================================================================
#                                             --- CRON & SUPERVISOR ---
# ---------------  This stage will install composer runtime dependinces and install app dependinces.  ------------------
# ======================================================================================================================
# ----------------------------------------------------- CRON -----------------------------------------------------------

FROM base AS cron
COPY docker/conf/crontab /etc/crontab
RUN crontab /etc/crontab
ENTRYPOINT ["docker-base-cron-entrypoint"]

# -------------------------------------------------- SUPERVISOR --------------------------------------------------------

FROM base AS supervisor
RUN apk add --no-cache supervisor
COPY /docker/conf/supervisor/ /etc/supervisor/
ENTRYPOINT ["docker-base-supervisor-entrypoint"]

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
# ==========================================  DEVELOPMENT FINAL STAGES  ================================================
#                                                    --- DEV ---
# ======================================================================================================================

# ------------------------------------------------------ FPM -----------------------------------------------------------
FROM fpm AS fpm-dev

ENV APP_ENV dev
ENV APP_DEBUG 1

# Install Composer runtime deps, and dev utilits
RUN apk add --no-cache git make openssh-client unzip zip curl nano htop

# Xdebug
RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS	&& \
    pecl install xdebug										&& \
    docker-php-ext-enable xdebug							&& \
    apk del -f .build-deps
COPY docker/conf/php/xdebug.ini /usr/local/etc/php/conf-available/docker-php-ext-xdebug.ini

# PHP dev config
COPY docker/conf/php/php-dev.ini  $PHP_INI_DIR/php.ini

# Entrypoint Scripts
COPY docker/.scripts/dev/	/usr/local/bin/
RUN  chmod +x /usr/local/bin/docker-dev-*
ENTRYPOINT ["docker-dev-fpm-entrypoint"]

# For Runtime `composer install`
ARG COMPOSER_AUTH={}
ENV COMPOSER_AUTH $COMPOSER_AUTH

# ----------------------------------------------------- NGINX ----------------------------------------------------------
FROM nginx AS nginx-dev
ENV APP_ENV dev
COPY docker/conf/php/php-dev.ini  $PHP_INI_DIR/php.ini

# ======================================================================================================================
# ===========================================  PRODUCTION FINAL STAGES  ================================================
#                                                   --- PROD ---
# ======================================================================================================================

# ----------------------------------------------------- NGINX ----------------------------------------------------------
FROM nginx AS nginx-prod
COPY public /var/www/app/public
VOLUME ["/etc/nginx/ssl"]
EXPOSE 80 443

# ------------------------------------------------------ FPM -----------------------------------------------------------
FROM fpm AS fpm-prod
COPY --from=vendor /app/vendor /var/www/app/vendor
COPY . .
RUN docker-base-prod-install

# ----------------------------------------------------- CRON -----------------------------------------------------------
FROM cron AS cron-prod
COPY --from=vendor /app/vendor /var/www/app/vendor
COPY . .
RUN docker-base-prod-install

# -------------------------------------------------- SUPERVISOR --------------------------------------------------------
FROM supervisor AS supervisor-prod
COPY --from=vendor /app/vendor /var/www/app/vendor
COPY . .
RUN docker-base-prod-install