#!/usr/bin/env bash

if [[ -z $1 ]]; then
	{
		echo "Usage: $0 database_dir [desired_cpu_load]"
		exit 0
	}
fi

CPU_LOAD=${2:-100}
DB_DIR="$(pwd)/$1"

EXEC_DIR="$(dirname "$0")/"
if [[ ! ${EXEC_DIR:0:1} == "/" ]]; then
	EXEC_DIR="$(pwd)/$EXEC_DIR"
fi

pushd "$EXEC_DIR" || exit 1

MAIN_LOG="$DB_DIR/rules_loop_full.log"

while true; do
	{
		START=$(date +%s)
		echo "$(date '+%F %T'): area update started"
		
        ./osm3s_query --progress --rules <"/app/etc/rules/areas.osm3s" >> "$MAIN_LOG" 2>&1
		
		echo "$(date '+%F %T'): area update finished"
		
		WORK_TIME=$(($(date +%s) - START))
		SLEEP_TIME=$((WORK_TIME * 100 / CPU_LOAD - WORK_TIME))
		SLEEP_TIME=$((SLEEP_TIME < 3 ? 3 : SLEEP_TIME))
		
		echo "It took $WORK_TIME to run the loop. Desired load is: ${CPU_LOAD}%. Sleeping: $SLEEP_TIME" | tee -a "$MAIN_LOG"
		
		sleep "$SLEEP_TIME"
	} 2>&1 | tee -a "$MAIN_LOG"
done
