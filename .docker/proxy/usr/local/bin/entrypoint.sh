#!/bin/sh

set -e

cat <<END > /etc/nginx/var.conf

set \$PWA_DOC_ROOT '$PWA_DOC_ROOT';

END


if [ "$DEFAULT_PROXY_PASS" != '' ]; then

    cat <<END >> /etc/nginx/var.conf

location / {
    proxy_set_header Host \$host;
    proxy_set_header X-Forwarded-For   \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-Port  \$server_port;
    proxy_pass $DEFAULT_PROXY_PASS;
}

END

fi

exec "$@"
