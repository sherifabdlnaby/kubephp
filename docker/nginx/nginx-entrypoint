#!/bin/sh
set -eu

# Envsubset all files and only replace exported envs.
for f in $(find /etc/nginx/ -name "*.conf"); do cat $f | envsubst "$(env | sed -e 's/=.*//' -e 's/^/\$/g')" > "$f.tmp"; mv "$f.tmp" "$f"; done

# Give FPM some time to warmup
sleep 1

# Validate & Test nginx config (retry to wait if fpm host hasn't started yet)
timeout 30 sh -c "until nginx -t -q; do echo 'Runtime Test Failed, Retrying...'; sleep 5; done"

echo "► Started Nginx"

exec nginx -g 'daemon off;'
