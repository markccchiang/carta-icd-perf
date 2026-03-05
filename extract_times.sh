#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

for logfile in "$SCRIPT_DIR"/log/perf-*.log; do
    echo "=== $logfile ==="
    grep 'PASS src/performance/.*\.test\.ts' "$logfile" | while read -r line; do
        testname=$(echo "$line" | sed 's/PASS \(src\/performance\/[^ ]*\.test\.ts\).*/\1/')
        time=$(echo "$line" | grep -o '([0-9.]*\s*s)' | tr -d '()')
        if [ -n "$time" ]; then
            echo "  $testname  $time"
        else
            echo "  $testname  (no time)"
        fi
    done
    echo
done
