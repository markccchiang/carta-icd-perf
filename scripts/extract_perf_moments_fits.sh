#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$SCRIPT_DIR/.."
LOG_DIR="$BASE_DIR/log"
OUTPUT_FILE="$BASE_DIR/test_logs/PERF_MOMENTS_FITS.log"

# Write header
printf "%-17s%s\n" "Date" "Time" > "$OUTPUT_FILE"
printf "%-17s%s\n" "----------" "----------" >> "$OUTPUT_FILE"

for logfile in "$LOG_DIR"/perf-*.log; do
    filename=$(basename "$logfile")
    date="${filename#perf-}"
    date="${date%.log}"
    # Format date as YYYY-MM-DD-HH
    formatted_date="${date:0:4}-${date:4:2}-${date:6:2}-${date:9:2}"

    # Check if the file contains the PASS line for this test
    if ! grep -q "PASS src/performance/PERF_MOMENTS_FITS.test.ts" "$logfile"; then
        printf "%-17s%s\n" "$formatted_date" "N/A" >> "$OUTPUT_FILE"
        continue
    fi

    # Extract the elapsed time from the target line after the PASS line
    elapsed=$(awk '
        /PASS src\/performance\/PERF_MOMENTS_FITS\.test\.ts/ { found=1; next }
        found && /\(Step 3\).*S255_IR_sci\.spw25\.cube\.I\.pbcor\.fits.*Receive a series of moment progress within 400000ms/ {
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
        printf "%-17s%s ms\n" "$formatted_date" "$elapsed" >> "$OUTPUT_FILE"
    else
        printf "%-17s%s\n" "$formatted_date" "N/A" >> "$OUTPUT_FILE"
    fi
done

echo "Results saved to $OUTPUT_FILE"
