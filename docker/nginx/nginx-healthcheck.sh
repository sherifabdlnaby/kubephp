#!/bin/sh
set -eu

# Test Nginx
wget --quiet --tries=1 --spider localhost:8090/stub_status || exit 1;