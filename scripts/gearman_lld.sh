#!/bin/bash
# gearman_lld.sh -- Gearman LLD for Zabbix
GEARADMIN=${GEARADMIN:-/usr/bin/gearadmin}
HOST="${1:-localhost}"
PORT="${2:-4730}"

$GEARADMIN --host "$HOST" --port "$PORT" --status | \
awk -F'\t' 'BEGIN{printf("{\"data\":[")}
    $1 && $1!="." {printf("%s{\"{#GMFUNC}\":\"%s\"}",(n++?",":""),$1)}
    END{print "]}"}'
