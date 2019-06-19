#!/bin/sh

set -e

cat <<END > /etc/nginx/var.conf

set \$PWA_DOC_ROOT '$PWA_DOC_ROOT';

END

exec "$@"
