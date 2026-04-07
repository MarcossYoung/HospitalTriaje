#!/bin/sh
# Set defaults so nginx.conf substitution works even if env vars are not set.
export BASE_PATH="${BASE_PATH:-}"
export BACKEND_HOST="${BACKEND_HOST:-backend:8000}"

envsubst '${BASE_PATH} ${BACKEND_HOST}' \
  < /etc/nginx/templates/default.conf.template \
  > /etc/nginx/conf.d/default.conf

exec nginx -g 'daemon off;'
