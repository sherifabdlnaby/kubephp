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

FROM php:${PHP_VERSION}-fpm-alpine AS base

# Required Args ( inherited from start of file, or passed at build )
ARG XDEBUG_VERSION

# Maintainer label
LABEL maintainer="sherifabdlnaby@gmail.com"

# Set SHELL flags for RUN commands to allow -e and pipefail
# Rationale: https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# ------------------------------------- Install Packages Needed Inside Base Image --------------------------------------

RUN IMAGE_DEPS="tini gettext"; \
    RUNTIME_DEPS="fcgi"; \
    apk add --no-cache ${IMAGE_DEPS} ${RUNTIME_DEPS}

# ---------------------------------------- Install / Enable PHP Extensions ---------------------------------------------


RUN apk add --no-cache --virtual .build-deps \
      $PHPIZE_DEPS  \
      libzip-dev    \
      icu-dev       \
 # PHP Extensions --------------------------------- \
 && docker-php-ext-install -j$(nproc) \
      intl        \
      opcache     \
      pdo_mysql   \
      zip         \
 # Pecl Extensions -------------------------------- \
 && pecl install apcu-5.1.20 && docker-php-ext-enable apcu \
 # ---------------------------------------------------------------------
 # Install Xdebug at this step to make editing dev image cache-friendly, we delete xdebug from production image later
 && pecl install xdebug-${XDEBUG_VERSION} \
 # Cleanup ---------------------------------------- \
 # - Detect Runtime Dependencies of the installed extensions. \
 # - src: https://github.com/docker-library/wordpress/blob/master/latest/php7.4/fpm-alpine/Dockerfile \
 && runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
			| tr ',' '\n' | sort -u | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }'  \
    )"; \
  # Save Runtime Deps in a virtual deps
	apk add --no-network --virtual .php-extensions-rundeps $runDeps; \
  # Uninstall Everything we Installed (minus the runtime Deps)
	apk del --no-network .build-deps

# ------------------------------------------------- Permissions --------------------------------------------------------

# - Clean bundled config/users & recreate them with UID 1000 for docker compatability in dev container.
# - Create composer directories (since we run as non-root later)
RUN deluser --remove-home www-data && adduser -u1000 -D www-data && rm -rf /var/www /usr/local/etc/php-fpm.d/* && \
    mkdir -p /var/www/.composer /app && chown -R www-data:www-data /app /var/www/.composer

# ------------------------------------------------ PHP Configuration ---------------------------------------------------

# Add Default Config
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Add in Base PHP Config
COPY docker/php/base-*   $PHP_INI_DIR/conf.d

# ---------------------------------------------- PHP FPM Configuration -------------------------------------------------

# PHP-FPM config
COPY docker/fpm/*.conf  /usr/local/etc/php-fpm.d/


# --------------------------------------------------- Scripts ----------------------------------------------------------

COPY docker/*-base          \
     docker/healthcheck-*   \
     docker/command-loop    \
     # to
     /usr/local/bin/

RUN  chmod +x /usr/local/bin/*-base /usr/local/bin/healthcheck-* /usr/local/bin/command-loop

# ---------------------------------------------------- Composer --------------------------------------------------------

COPY --from=composer /usr/bin/composer /usr/bin/composer

# ----------------------------------------------------- MISC -----------------------------------------------------------

WORKDIR /app
USER www-data

# Common PHP Frameworks Env Variables
ENV APP_ENV prod
ENV APP_DEBUG 0

# Validate FPM config (must use the non-root user)
RUN php-fpm -t

# ---------------------------------------------------- HEALTH ----------------------------------------------------------

HEALTHCHECK CMD ["healthcheck-liveness"]

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
RUN composer install -n --no-progress --ignore-platform-reqs --no-dev --prefer-dist --no-scripts --no-autoloader

# ======================================================================================================================
# ==============================================  PRODUCTION IMAGE  ====================================================
#                                                   --- PROD ---
# ======================================================================================================================

FROM base AS app

USER root

# Copy Prod Scripts && delete xdebug
COPY docker/*-prod /usr/local/bin/
RUN  chmod +x /usr/local/bin/*-prod && pecl uninstall xdebug

# Copy PHP Production Configuration
COPY docker/php/prod-*   $PHP_INI_DIR/conf.d/

USER www-data

# ----------------------------------------------- Production Config -----------------------------------------------------

# Copy Vendor
COPY --chown=www-data:www-data --from=vendor /app/vendor /app/vendor

# Copy App Code
COPY --chown=www-data:www-data . .

# Run Composer Install again
# ( this time to run post-install scripts, autoloader, and post-autoload scripts using one command )
RUN post-build-base && post-build-prod

ENTRYPOINT ["entrypoint-prod"]
CMD ["php-fpm"]

# ======================================================================================================================
# ==============================================  DEVELOPMENT IMAGE  ===================================================
#                                                   --- DEV ---
# ======================================================================================================================

FROM base as app-dev


ENV APP_ENV dev
ENV APP_DEBUG 1

# Switch root to install stuff
USER root

# For Composer Installs
RUN apk add git openssh; \
 # Enable Xdebug
 docker-php-ext-enable xdebug

# For Xdebuger to work, it needs the docker host ID
# - in Mac AND Windows, `host.docker.internal` resolve to Docker host IP
# - in Linux, `172.17.0.1` is the host IP
ENV XDEBUG_CLIENT_HOST="host.docker.internal"

# ----------------------------------------  ---------- Scripts ---------------------------------------------------------

# Copy Dev Scripts
COPY docker/*-dev /usr/local/bin/
RUN  chmod +x /usr/local/bin/*-dev

# ------------------------------------------------------ PHP -----------------------------------------------------------

RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
COPY docker/php/dev-*   $PHP_INI_DIR/conf.d/

USER www-data
# ------------------------------------------------- Entry Point --------------------------------------------------------

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
RUN chown -R www-data /etc/nginx/ && chmod +x /usr/local/bin/nginx-*

# The PHP-FPM Host
## Localhost is the sensible default assuming image run on a k8S Pod
ENV PHP_FPM_HOST "localhost"
ENV PHP_FPM_PORT "9000"
ENV NGINX_LOG_FORMAT "json"

# For Documentation
EXPOSE 8080

# Switch User
USER www-data

# Add Healthcheck
HEALTHCHECK CMD ["nginx-healthcheck"]

# Add Entrypoint
ENTRYPOINT ["nginx-entrypoint"]

# ======================================================================================================================
#                                                 --- NGINX PROD ---
# ======================================================================================================================

FROM nginx AS web

# Copy Public folder + Assets that's going to be served from Nginx
COPY --chown=www-data:www-data --from=app /app/public /app/public

# ----------------------------------------------------- NGINX ----------------------------------------------------------
FROM nginx AS web-dev

ENV NGINX_LOG_FORMAT "combined"
