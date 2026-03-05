#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$SCRIPT_DIR/.."
LOG_DIR="$BASE_DIR/log"
OUTPUT_FILE="$BASE_DIR/test_logs/PERF_PV_HDF5.log"

# Write header
printf "%-14s%s\n" "Date" "Time" > "$OUTPUT_FILE"
printf "%-14s%s\n" "----------" "----------" >> "$OUTPUT_FILE"

for logfile in "$LOG_DIR"/perf-*.log; do
    filename=$(basename "$logfile")
    date="${filename#perf-}"
    date="${date%.log}"
    # Format date as YYYY-MM-DD
    formatted_date="${date:0:4}-${date:4:2}-${date:6:2}"

    # Check if the file contains the PASS line for this test
    if ! grep -q "PASS src/performance/PERF_PV_HDF5.test.ts" "$logfile"; then
        printf "%-14s%s\n" "$formatted_date" "N/A" >> "$OUTPUT_FILE"
        continue
    fi

    # Extract the elapsed time from the target line after the PASS line
    elapsed=$(awk '
        /PASS src\/performance\/PERF_PV_HDF5\.test\.ts/ { found=1; next }
        found && /\(Step 5\): PV Response should arrived within 200000 ms/ {
            n = split($0, a, "(")
            for (i = 1; i <= n; i++) {
                if (a[i] ~ /^[0-9]+ ms\)/) {
                    sub(/ ms\).*/, "", a[i])
                    print a[i]
                }
            }
            found=0
        }
        /^PASS / && found { found=0 }
    ' "$logfile")

    if [ -n "$elapsed" ]; then
        printf "%-14s%s ms\n" "$formatted_date" "$elapsed" >> "$OUTPUT_FILE"
    else
        printf "%-14s%s\n" "$formatted_date" "N/A" >> "$OUTPUT_FILE"
    fi
done

echo "Results saved to $OUTPUT_FILE"
