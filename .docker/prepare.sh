#!/usr/bin/env bash

set -e

cd $(dirname $0)/..

declare -A vars

CLIENT_NAME=vigisade
DEFAULT_COMPOSE_PROJECT_NAME="$CLIENT_NAME"
DEFAULT_PROXY_VIRTUAL_HOST_SUFFIX=".$CLIENT_NAME"
vars[IP]=127.0.24.1
DEFAULT_SUBNET_DEFAULT=10.210.26.0/24

vars[DB_USER]="$CLIENT_NAME"
vars[DB_NAME]="$CLIENT_NAME"
vars[DB_PWD]=xxx


# functions
. ~/dev/docker/.bin/functions.sh


container_proxy=$(docker container ps --filter name=^/proxy_dockergen-nginx -q)
container_client_mail=$(docker container ps --filter name=^/${CLIENT_NAME}_mail -q)
container_mail=$(docker container ps --filter name=^/mail_mail -q)
container_logstash=$(docker container ps --filter name=^/elk_logstash -q)

FILE=.env

touch "$FILE"

vars[COMPOSE_PROJECT_NAME]=$(basename $PWD | sed -E 's/[^a-zA-Z0-9]//g')
suffix=${vars[COMPOSE_PROJECT_NAME]#$DEFAULT_COMPOSE_PROJECT_NAME}
vars[PROXY_VIRTUAL_HOST_SUFFIX]="${suffix:+-$suffix}$DEFAULT_PROXY_VIRTUAL_HOST_SUFFIX"

COMPOSE_FILE=docker-compose.yml
if [ "$container_proxy" = "" ]; then
    _addComposeMode ports
else
    _addComposeMode proxy
fi
vars[GELF_ADDRESS]=
if [ "$container_logstash" != '' ]; then
    gelf_ip_port=$(docker port "$container_logstash" 12201/udp)
    if [ "$gelf_ip_port" != '' ]; then
        vars[GELF_ADDRESS]="udp://$gelf_ip_port"
        _addComposeMode log
    fi
fi

if [ "$container_client_mail" != "" ]; then
    vars[MAIL_NETWORK_NAME]="${CLIENT_NAME}mail_default"
    addComposeMode mail
elif [ "$container_mail" != "" ]; then
    vars[MAIL_NETWORK_NAME]="mail_default"
    addComposeMode mail
fi

vars[COMPOSE_FILE]="$COMPOSE_FILE"
vars[PROJECT_PATH]=$(realpath $PWD)
vars[USER_HOME]=$(realpath $HOME)
vars[USER_ID]=$(id -u)
vars[GROUP_ID]=$(id -g)

vars[VOLUME_OPTION]=rw

vars[BLACKFIRE_CLIENT_ID]=
vars[BLACKFIRE_CLIENT_TOKEN]=
vars[BLACKFIRE_SERVER_ID]=
vars[BLACKFIRE_SERVER_TOKEN]=

vars[NEWRELIC_LICENSE]=

if [[ "$OSTYPE" = "darwin"* ]]; then
    vars[USER_ID]=1000
    vars[GROUP_ID]=1000
    vars[VOLUME_OPTION]=delegated
fi

if command -v get-available-docker-network.sh 2>&1 >/dev/null; then
    available_network=$(get-available-docker-network.sh)
    vars[SUBNET_DEFAULT]=${available_network%/*}/28
else
    vars[SUBNET_DEFAULT]="$DEFAULT_SUBNET_DEFAULT"
fi


# loading .env and adding missing vars in it
for k in ${!vars[@]}; do
    grep=$(grep "^$k=" "$FILE" || true)
    if [ "$grep" = '' ]; then
        grep="$k=${vars[$k]}"
        echo "$grep" >> "$FILE"
    fi
    eval $grep
done

# updating sub-projects vars
for project in ${DEFAULT_COMPOSE_PROJECT_NAME}-*; do
    global_env="$project/.docker/env"
    if [ -f "$global_env" ]; then
        subvars=$(grep -Ei '^[a-z][a-z0-9_]+=' "$global_env" | sed -E 's/^([A-Za-z0-9_]+)=.*$/\1/')
        sed_i "\=^# $global_env.*=d" "$FILE"
        for v in $subvars; do
            sed_i "/^$v=/d" "$FILE"
        done
        echo "# $global_env:" >> "$FILE"
        cat "$global_env" >> "$FILE"
    fi
done

# add or remove config files
if [ $# != 0 ]; then
    op=add
    if [ "$1" = '+' ]; then
        shift
    elif [ "$1" = '-' ]; then
        op=del
        shift
    else
        COMPOSE_FILE=docker-compose.yml
    fi
    for mode in "$@"; do
        ${op}ComposeMode $mode
    done
fi
_delComposeMode override
_addComposeMode override
sed_i "s/^COMPOSE_FILE=.*\$/COMPOSE_FILE=$COMPOSE_FILE/" "$FILE"


# preparing volumes
set +e
if [[ "$OSTYPE" = "darwin"* ]]; then
    for k in ${!vars[@]}; do
        case $k in
            IP|IP_*)
                ip=${vars[$k]}
                if [[ "$ip" = '127.'* ]] && [ "$ip" != '127.0.0.1' ]; then
                    if ! ifconfig | grep "$ip" >/dev/null; then
                        echo "sudo ifconfig lo0 alias $ip up"
                        sudo ifconfig lo0 alias "$ip" up
                    fi
                fi
        esac
    done
fi
cd "$USER_HOME"
mkdir -p \
    .ssh \
    .composer \
    .config \
    .console \
    .npm \
    .cache \
    .local
touch \
    .php_history
cd "$PROJECT_PATH"
mkdir -p \
    vigisade-pwa/dist

# vim: ts=4 sts=4 sw=4 et:
