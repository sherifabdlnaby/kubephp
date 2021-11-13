#!/bin/sh
set -eu

# ----------------------------------------------------------------------------------------------------------------------

echo "► Starting Production Entrypoint..."

# ----------------------------------------------------------------------------------------------------------------------

# Run custom ad-hoc pre-run script
echo "► Running custom pre-run (prod) script..."
pre-run-prod

# ----------------------------------------------------------------------------------------------------------------------

# Run Entrypoint and pass CMD to it (Don't forget exec)
exec entrypoint-base "${@}"
