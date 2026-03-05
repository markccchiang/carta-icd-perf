#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$SCRIPT_DIR/.."

mkdir -p "$BASE_DIR/test_logs"

count=0
for script in "$SCRIPT_DIR"/extract_perf_*.sh; do
    bash "$script"
    count=$((count + 1))
done

echo
echo "Done. $count extraction scripts executed."
