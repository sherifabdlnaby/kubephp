#!/bin/sh
set -eu
# Put Custom Ad-hoc scripts after build. Like framework specific checks, etc.

# Install Public Assets if they're not generated.
echo "► Running Composer Install..."
composer install

echo "► Checking Platform Requirements"
composer check-platform-reqs