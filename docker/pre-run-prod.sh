#!/bin/sh
set -e

# Load .env and .env.<APP_ENV>, and .env.<APP_ENV>.local into script (won't overwrite OS env vars.)
#set -a
#    env_overwrite="./.env.${APP_ENV-prod}"
#    env_local_overwrite="./.env.${APP_ENV-prod}.local"
#    export -p >> /tmp/envsrc && if [ -f "./.env" ]; then . ./.env; fi && if [ -f "${env_overwrite}" ]; then . $env_overwrite; fi && if [ -f "${env_local_overwrite}" ]; then . $env_local_overwrite; fi && . /tmp/envsrc \
#    && rm /tmp/envsrc && unset env_overwrite && unset env_local_overwrite
#set +a


# This script working dir is application's directory, and all ENV variables from .env and OS are available here
# using ${ENV_NAME} with defaults taken from .env and .env.<env>
#
# Ex:
#   { echo ${DATABASE_URL};  echo "stdin input"; } | vendor/bin/<script that need stdin input>


# Put Custom Ad-hoc scripts below:

## Run Envsubst on .env to expand embedded Env Variables
echo "► Expanding Dotenv files with Environment Variables..."
for f in $(find . -name ".env*"); do cat $f | envsubst "$(env | sed -e 's/=.*//' -e 's/^/\$/g')" > "$f.tmp"; mv "$f.tmp" "$f"; done
