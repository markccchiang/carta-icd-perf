#!/bin/bash
# Generic extraction script for performance test elapsed times.
#
# Usage: extract_perf.sh TEST_NAME STEP_PATTERN [INTERMEDIATE_PATTERN]
#
#   TEST_NAME            - e.g. PERF_PV_CASA
#   STEP_PATTERN         - awk regex to match the line containing elapsed time
#   INTERMEDIATE_PATTERN - (optional) awk regex for a line that must appear
#                          between the PASS line and STEP_PATTERN

TEST_NAME="$1"
STEP_PATTERN="$2"
INTERMEDIATE_PATTERN="$3"

if [ -z "$TEST_NAME" ] || [ -z "$STEP_PATTERN" ]; then
    echo "Usage: $0 TEST_NAME STEP_PATTERN [INTERMEDIATE_PATTERN]"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$SCRIPT_DIR/.."
LOG_DIR="$BASE_DIR/log"
OUTPUT_FILE="$BASE_DIR/test_logs/${TEST_NAME}.log"

# Write header
printf "%-17s%s\n" "Date" "Time" > "$OUTPUT_FILE"
printf "%-17s%s\n" "----------" "----------" >> "$OUTPUT_FILE"

# Escape test name for awk regex (dots)
AWK_TEST_NAME=$(echo "$TEST_NAME" | sed 's/\./\\./g')

# Export patterns as environment variables so awk can read them via ENVIRON
# (unlike -v, ENVIRON preserves regex escapes exactly)
export _PASS_PAT="PASS src/performance/${AWK_TEST_NAME}\\.test\\.ts"
export _STEP_PAT="$STEP_PATTERN"
export _INTER_PAT="$INTERMEDIATE_PATTERN"

for logfile in "$LOG_DIR"/perf-*.log; do
    filename=$(basename "$logfile")
    date="${filename#perf-}"
    date="${date%.log}"
    # Format date as YYYY-MM-DD-HH
    formatted_date="${date:0:4}-${date:4:2}-${date:6:2}-${date:9:2}"

    # Check if the file contains the PASS line for this test
    if ! grep -q "PASS src/performance/${TEST_NAME}.test.ts" "$logfile"; then
        printf "%-17s%s\n" "$formatted_date" "N/A" >> "$OUTPUT_FILE"
        continue
    fi

    if [ -n "$INTERMEDIATE_PATTERN" ]; then
        # Two-step matching: PASS -> intermediate -> step pattern
        elapsed=$(awk '
            BEGIN { pass_pat=ENVIRON["_PASS_PAT"]; inter_pat=ENVIRON["_INTER_PAT"]; step_pat=ENVIRON["_STEP_PAT"] }
            $0 ~ pass_pat { found=1; next }
            found && $0 ~ inter_pat { step2=1; next }
            found && step2 && $0 ~ step_pat {
                n = split($0, a, "(")
                for (i = 1; i <= n; i++) {
                    if (a[i] ~ /^[0-9]+ ms\)/) {
                        sub(/ ms\).*/, "", a[i])
                        print a[i]
                    }
                }
                step2=0; found=0
            }
            /^PASS / && found { found=0; step2=0 }
        ' "$logfile")
    else
        # Single-step matching: PASS -> step pattern
        elapsed=$(awk '
            BEGIN { pass_pat=ENVIRON["_PASS_PAT"]; step_pat=ENVIRON["_STEP_PAT"] }
            $0 ~ pass_pat { found=1; next }
            found && $0 ~ step_pat {
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
    fi

    if [ -n "$elapsed" ]; then
        printf "%-17s%s ms\n" "$formatted_date" "$elapsed" >> "$OUTPUT_FILE"
    else
        printf "%-17s%s\n" "$formatted_date" "N/A" >> "$OUTPUT_FILE"
    fi
done

echo "Results saved to $OUTPUT_FILE"
