#!/bin/sh
set -eu
# Put Custom Ad-hoc scripts after build. Like framework specific checks, etc.

echo "► Running Composer Install..."
composer install --optimize-autoloader --apcu-autoloader --no-dev -n --no-progress

echo "► Checking Platform Requirements"
composer check-platform-reqs