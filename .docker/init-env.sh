#!/usr/bin/env bash
set -e
declare -A vars


CLIENT_NAME=sade
PROJECT_NAME=vigisade-web
vars[IP]=127.0.24.1
vars[SUBNET]=10.210.26.0/24


# the folowwing should be ok for any projet
# but you can change anything you need

FILE=.env

cd $(dirname $0)/..

container_proxy=$(docker container ps --filter name=proxy_dockergen-nginx -q)
container_mail=$(docker container ps --filter name=mail_mail -q)
container_logstash=$(docker container ps --filter name=elk_logstash -q)

function sed_i () {
    if [[ "$OSTYPE" = "darwin"* ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

touch "$FILE"

vars[COMPOSE_FILE]=docker-compose.yml
vars[PROJECT_PATH]=$PWD
vars[USER_HOME]=$HOME
vars[USER_ID]=
vars[GROUP_ID]=
vars[XDEBUG]=Off
vars[GELF_IP]=
vars[PROXY_VIRTUAL_HOST]="$PROJECT_NAME$(basename $PWD | sed -E -e 's/[-_]+/-/g' -e "s/-*($CLIENT_NAME|$PROJECT_NAME)-*//g" -e 's/^(.)/-\1/').$CLIENT_NAME"

if [[ "$OSTYPE" = "darwin"* ]]; then
    true
elif [ "$OS" = "Windows_NT" ]; then
    vars[IP]=0.0.0.0
else
    vars[USER_ID]=$(id -u)
    vars[GROUP_ID]=$(id -g)
fi

if [ "$container_mail" != "" ]; then
    vars[COMPOSE_FILE]="${vars[COMPOSE_FILE]}:docker-compose.mail.yml"
fi

if [ "$container_proxy" = "" ]; then
    vars[COMPOSE_FILE]="${vars[COMPOSE_FILE]}:docker-compose.ports.yml"
else
    vars[COMPOSE_FILE]="${vars[COMPOSE_FILE]}:docker-compose.proxy.yml"
fi

if [ "$container_logstash" != "" ]; then
    vars[GELF_IP]=$(docker inspect --format '{{ .NetworkSettings.Networks.elk_default.IPAddress }}' "$container_logstash" 2>/dev/null)
fi

if [ "${vars[GELF_IP]}" != "" ]; then
    vars[COMPOSE_FILE]="${vars[COMPOSE_FILE]}:docker-compose.log.yml"
    sed_i '/^GELF_IP=/d' "$FILE"
fi

command -v get-available-docker-network.sh 2>&1 >/dev/null && vars[SUBNET]=$(get-available-docker-network.sh)

for k in ${!vars[@]}; do
    grep=$(grep "^$k=" "$FILE" &2>/dev/null)
    if [ "$grep" = "" ]; then
        grep="$k=${vars[$k]}"
        echo "$grep" >> "$FILE"
    fi
    eval "$grep"
done


if [[ "$OSTYPE" = "darwin"* ]] && [[ "$IP" = "127."* ]] && [ "$IP" != "127.0.0.1" ]; then
    grep=$(ifconfig | grep "$IP" &2>/dev/null)
    if [ "$grep" = "" ]; then
        echo "sudo ifconfig lo0 alias $IP up"
        sudo ifconfig lo0 alias "$IP" up
    fi
fi

function addComposeMode () {
    _addComposeMode $1
    if [[  "$1" =~ ^(pma|pga)$ ]]; then
        [[ "$COMPOSE_FILE" = *".proxy."* ]] && mode=${1}_proxy || mode=${1}_ports
        _addComposeMode $mode
        if [[ "$COMPOSE_FILE" = *".log."* ]]; then
            _addComposeMode ${1}_log
        fi
    fi
}
function _addComposeMode () {
    file="docker-compose.$1.yml"
    if [ -f "$file" ] && [[ "$COMPOSE_FILE" != *":$file"* ]]; then
        COMPOSE_FILE=$COMPOSE_FILE:$file
    fi
}

if [ $# != 0 ]; then
    if [ "$1" = "+" ]; then
        shift
    else
        COMPOSE_FILE=$COMPOSE_FILE
    fi
    for mode in "$@"; do
        addComposeMode $mode
    done
    sed_i '/^COMPOSE_FILE=/d' "$FILE"
    echo "COMPOSE_FILE=$COMPOSE_FILE" >> "$FILE"
fi

# vim: ts=4 sts=4 sw=4 et:
