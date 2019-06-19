#!/usr/bin/env bash

set -e

declare -a cmd=('docker' 'exec' '-i')

if [ -t 0 ]; then
    TTY="Yes"
else
    TTY=
fi

for p in "$@"; do
    [[ "$p" != "-"* ]] && break
    shift
    case "$p" in
        -T) TTY= ;;
        -e)
            cmd+=("-e" "$1")
            shift
            ;;
        *)
            echo >&2 "Unkown option : '$p'"
            exit 1
    esac
done

CONTAINER_NAME=$1
shift

if [ -f "/.dockerenv" ]; then
    exec "$@"
fi

case "$CONTAINER_NAME" in
    php|*-php)
        CONTAINER_TYPE=ux
        if [ "$SYMFONY_ENV" != '' ]; then
            cmd+=("-e" "SYMFONY_ENV=$SYMFONY_ENV")
        fi
        ;;
    *)
        CONTAINER_TYPE="$CONTAINER_NAME"
        ;;
esac

current_dir=$(realpath "$PWD")
cd $(dirname $0)/..

. .env

if [ "$TTY" ]; then
    cmd+=("-t")
fi

CONTAINER_NAME="$(docker inspect --format '{{.Name}}' $(docker-compose ps -q "$CONTAINER_NAME"))"
# TODO: inspect to test if user_id, and if current_dir in bind path
if [ "$CONTAINER_TYPE" = 'ux' ]; then
    if [ "$USER_ID" != '' ]; then
        if [ "$GROUP_ID" != '' ]; then
            cmd+=("-u" "$USER_ID:$GROUP_ID")
        else
            cmd+=("-u" "$USER_ID")
        fi
    fi
    cmd+=("-w" "$current_dir")
fi
cmd+=("$CONTAINER_NAME")

set -x
exec "${cmd[@]}" "$@"

# vim: ts=4 sts=4 sw=4 et:
