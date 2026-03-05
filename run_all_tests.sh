#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTDIR="$SCRIPT_DIR/test_logs"

mkdir -p "$OUTDIR"

# Get all unique test names
tests=$("$SCRIPT_DIR/track_test.sh" | sed -n '/^PERF_/p')

for test in $tests; do
    outfile="$OUTDIR/${test}.log"
    "$SCRIPT_DIR/track_test.sh" "$test" > "$outfile"
    echo "Saved $outfile"
done

echo
echo "Done. $(echo "$tests" | wc -l | tr -d ' ') test logs saved to $OUTDIR/"
