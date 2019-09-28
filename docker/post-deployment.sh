#!/bin/sh
set -eu

composer run-script --no-interaction post-install-cmd

# Scripts that will run after deployment and composer install.
# Should only used for ad-hoc commands, It's recommended to use composer scripts if possible.
# This script working dir is application's directory, and all ENV variables from .env and OS are available here
# using ${ENV_NAME} with defaults taken from .env and .env.<env>
#
# Ex:
#   { echo ${DATABASE_URL};  echo "stdin input"; } | vendor/bin/<script that need stdin input>


# Put Custom Ad-hoc scripts below: