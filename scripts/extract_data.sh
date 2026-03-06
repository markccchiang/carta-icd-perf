#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$SCRIPT_DIR/.."
LOGDIR="$BASE_DIR/test_logs"
OUTFILE="$BASE_DIR/data.js"

# Build JSON data from all log files
json_data="{"
first_test=true

for logfile in "$LOGDIR"/PERF_*.log; do
    testname=$(basename "$logfile" .log)

    if [ "$first_test" = true ]; then
        first_test=false
    else
        json_data+=","
    fi

    json_data+="\"$testname\":{\"dates\":["
    json_data+=$(tail -n +3 "$logfile" | while IFS= read -r line; do
        [ -z "$line" ] && continue
        date=$(echo "$line" | awk '{print $1}')
        [ -z "$date" ] && continue
        # Skip N/A entries
        echo "$line" | grep -q 'N/A' && continue
        # Match either "123 ms" or "123.456 s"
        if echo "$line" | grep -q '[0-9]\+ ms'; then
            printf '"%s"\n' "$date"
        elif echo "$line" | grep -q '[0-9.]\+ s'; then
            printf '"%s"\n' "$date"
        fi
    done | paste -sd ',' -)

    json_data+="],\"times\":["

    json_data+=$(tail -n +3 "$logfile" | while IFS= read -r line; do
        [ -z "$line" ] && continue
        # Skip N/A entries
        echo "$line" | grep -q 'N/A' && continue
        # Match "123 ms" and convert to ms, or match "123.456 s" and convert to ms
        if echo "$line" | grep -q '[0-9]\+ ms'; then
            time=$(echo "$line" | grep -o '[0-9]\+ ms' | awk '{print $1}')
            [ -z "$time" ] && continue
            printf '%s\n' "$time"
        elif echo "$line" | grep -q '[0-9.]\+ s'; then
            time=$(echo "$line" | grep -o '[0-9.]\+ s' | awk '{printf "%.0f", $1 * 1000}')
            [ -z "$time" ] && continue
            printf '%s\n' "$time"
        fi
    done | paste -sd ',' -)

    json_data+="]}"
done

json_data+="}"

# Write data.js
echo "const DATA = ${json_data};" > "$OUTFILE"

echo "Data generated: $OUTFILE"
