#!/bin/sh
set -eu

# ----------------------------------------------------------------------------------------------------------------------

echo "► Starting Development Entrypoint..."

# ----------------------------------------------------------------------------------------------------------------------

echo "► Running 'post-build-base && post-build-dev' script(s)..."
post-build-base.sh && post-build-dev.sh

# Run custom ad-hoc pre-run script
echo "► Running custom pre-run (dev) script..."
pre-run-dev.sh

# Run Entrypoint and pass CMD to it (Don't forget exec)
exec entrypoint-base.sh "${@}"
