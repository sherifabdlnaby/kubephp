#!/bin/sh
set -e

# Dev entry point does steps that is done in prod image, only that it does it at
# container runtime not image build time, as dev container expects the code to be
# mounted.

# Install Dependencies
echo "Running Composer Install..."
composer install --prefer-dist --no-progress --no-suggest --no-interaction --no-scripts
echo "Finished Composer Install."

# Run Parent Entrypoint
echo "Starting..."
exec docker-entrypoint