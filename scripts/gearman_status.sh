#!/bin/bash
# gearman_status.sh -- Gearman metrics for Zabbix
GEARADMIN=${GEARADMIN:-/usr/bin/gearadmin}
FUNC="$1"
HOST="${2:-localhost}"
PORT="${3:-4730}"
FIELD="${4:-workers}"   # queued | running | workers

LINE=$($GEARADMIN --host "$HOST" --port "$PORT" --status | awk -F'\t' -v f="$FUNC" '$1==f {print $0}')
[ -z "$LINE" ] && { echo 0; exit 0; }

case "$FIELD" in
  queued)  COL=2 ;;
  running) COL=3 ;;
  workers) COL=4 ;;
  *) echo 0; exit 0 ;;
esac

echo "$LINE" | awk -F'\t' "{print \$$COL+0}"
