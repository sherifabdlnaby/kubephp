#!/bin/sh
set -eu

# ----------------------------------------------------------------------------------------------------------------------

echo "► Starting Production Entrypoint..."

# ----------------------------------------------------------------------------------------------------------------------

echo "► Running 'post-build-base && post-build-prod' script(s)..."
post-build-base.sh && post-build-prod.sh

# Run custom ad-hoc pre-run script
echo "► Running custom pre-run (prod) script..."
pre-run-prod.sh

# ----------------------------------------------------------------------------------------------------------------------

# Run Entrypoint and pass CMD to it (Don't forget exec)
exec entrypoint-base.sh "${@}"
