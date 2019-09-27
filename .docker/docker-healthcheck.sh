#!/bin/sh
set -eu


# Test PHP-FPM
export FCGI_CONNECT="/var/run/php-php-fpm.sock"
docker-core-fpm-healthcheck || exit 1;

# Test Nginx
curl -f localhost:8080/stub_status || exit 1;

# Test App
# > If App has a Healthceck, add it here < #