#!/bin/sh
set -e

# Dev entry point does steps that is done in prod image, only that it does it at
# container runtime not image build time, as dev container expects the code to be
# mounted.

# Install Dependencies ( --no-scripts here as scripts ar run in main entrypoint )
echo "Running Composer Install..."
composer install --prefer-dist --no-interaction --no-scripts

# Checks that PHP and extensions versions match the platform requirements of the installed packages.
echo "Checking Platform requirements"
composer check-platform-reqs

# Run Parent Entrypoint
echo "Starting..."
exec docker-entrypoint