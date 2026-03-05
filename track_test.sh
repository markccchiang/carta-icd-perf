#!/bin/bash

# Usage: ./track_test.sh <test_name>
# Example: ./track_test.sh PERF_PV_CASA
#          ./track_test.sh PERF_MOMENTS  (partial match)
#
# If no argument is given, lists all available test names.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOGDIR="$SCRIPT_DIR/log"

if [ -z "$1" ]; then
    echo "Available tests:"
    grep -h 'PASS src/performance/PERF_' "$LOGDIR"/perf-*.log \
        | sed 's/.*PASS src\/performance\/\([^ ]*\)\.test\.ts.*/\1/' \
        | sort -u
    echo
    echo "Usage: $0 <test_name> (exact or partial match)"
    exit 0
fi

PATTERN="$1"

printf "%-12s  %s\n" "Date" "Time"
printf "%-12s  %s\n" "----------" "----------"

for logfile in "$LOGDIR"/perf-*.log; do
    filename=$(basename "$logfile")
    # Extract date from filename: perf-YYYYMMDD.log -> YYYY-MM-DD
    raw_date=${filename#perf-}
    raw_date=${raw_date%.log}
    date="${raw_date:0:4}-${raw_date:4:2}-${raw_date:6:2}"

    match=$(grep "PASS src/performance/.*${PATTERN}.*\.test\.ts" "$logfile")
    if [ -n "$match" ]; then
        while IFS= read -r line; do
            testname=$(echo "$line" | sed 's/.*PASS src\/performance\/\([^ ]*\)\.test\.ts.*/\1/')
            time=$(echo "$line" | grep -o '([0-9.]*\s*s)' | tr -d '()')
            if [ -n "$time" ]; then
                printf "%-12s  %-50s  %s\n" "$date" "$testname" "$time"
            else
                printf "%-12s  %-50s  %s\n" "$date" "$testname" "N/A"
            fi
        done <<< "$match"
    fi
done
