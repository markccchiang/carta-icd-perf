#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$SCRIPT_DIR/.."
LOGDIR="$BASE_DIR/test_logs"
OUTFILE="$BASE_DIR/dashboard.html"

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

cat > "$OUTFILE" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>CARTA ICD Performance Tests</title>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.7/dist/chart.umd.min.js"></script>
<link rel="stylesheet" href="dashboard.css">
</head>
<body>

<h1>CARTA ICD Performance Tests</h1>
<p class="subtitle">Elapsed time trends across test runs</p>

<div class="controls">
  <select id="filter">
    <option value="ALL">All Tests</option>
  </select>
</div>

<div class="grid" id="grid"></div>

<!-- Modal for enlarged chart -->
<div class="modal-overlay" id="modal">
  <div class="modal-content">
    <h3 id="modalTitle"></h3>
    <div class="modal-chart-wrap">
      <canvas id="modalCanvas"></canvas>
    </div>
  </div>
</div>

<script>
HTMLEOF

# Inject the JSON data
echo "const DATA = ${json_data};" >> "$OUTFILE"

cat >> "$OUTFILE" << 'HTMLEOF2'

</script>
<script src="dashboard.js"></script>
</body>
</html>
HTMLEOF2

echo "Dashboard generated: $OUTFILE"
