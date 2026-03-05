#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOGDIR="$SCRIPT_DIR/test_logs"
OUTFILE="$SCRIPT_DIR/dashboard.html"

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
<title>Performance Test Dashboard</title>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.7/dist/chart.umd.min.js"></script>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    background: #0f172a;
    color: #e2e8f0;
    padding: 20px;
  }
  h1 {
    text-align: center;
    margin-bottom: 8px;
    font-size: 1.8rem;
    color: #f1f5f9;
  }
  .subtitle {
    text-align: center;
    color: #94a3b8;
    margin-bottom: 24px;
    font-size: 0.9rem;
  }
  .controls {
    display: flex;
    justify-content: center;
    gap: 12px;
    margin-bottom: 24px;
    flex-wrap: wrap;
  }
  .controls select, .controls button {
    padding: 8px 16px;
    border-radius: 6px;
    border: 1px solid #334155;
    background: #1e293b;
    color: #e2e8f0;
    font-size: 0.9rem;
    cursor: pointer;
  }
  .controls button:hover { background: #334155; }
  .controls button.active { background: #3b82f6; border-color: #3b82f6; }
  .grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(560px, 1fr));
    gap: 20px;
  }
  .chart-card {
    background: #1e293b;
    border-radius: 12px;
    padding: 16px;
    border: 1px solid #334155;
    transition: border-color 0.2s;
  }
  .chart-card:hover { border-color: #3b82f6; }
  .chart-card h3 {
    font-size: 0.85rem;
    color: #94a3b8;
    margin-bottom: 8px;
    font-weight: 500;
    letter-spacing: 0.5px;
  }
  .chart-card canvas { width: 100% !important; }
  .stats {
    display: flex;
    gap: 16px;
    margin-top: 8px;
    font-size: 0.75rem;
    color: #64748b;
  }
  .stats span { display: inline-flex; align-items: center; gap: 4px; }
  .stats .val { color: #cbd5e1; font-weight: 600; }

  /* Modal overlay for enlarged chart */
  .modal-overlay {
    display: none;
    position: fixed;
    top: 0; left: 0; right: 0; bottom: 0;
    background: rgba(0,0,0,0.8);
    z-index: 1000;
    justify-content: center;
    align-items: center;
    cursor: pointer;
  }
  .modal-overlay.active { display: flex; }
  .modal-content {
    background: #1e293b;
    border-radius: 16px;
    padding: 24px;
    width: 90vw;
    max-width: 1100px;
    height: 70vh;
    border: 1px solid #334155;
    cursor: default;
  }
  .modal-content h3 {
    color: #e2e8f0;
    margin-bottom: 12px;
    font-size: 1.1rem;
  }
  .modal-chart-wrap { position: relative; height: calc(100% - 40px); }
</style>
</head>
<body>

<h1>Performance Test Dashboard</h1>
<p class="subtitle">Elapsed time trends across test runs</p>

<div class="controls">
  <select id="filter">
    <option value="ALL">All Tests</option>
  </select>
  <button id="sortName" class="active">Sort by Name</button>
  <button id="sortTrend">Sort by Trend</button>
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

// Colors for each variant
const VARIANT_COLORS = {
  'CASA':  '#3b82f6',
  'FITS':  '#10b981',
  'HDF5':  '#f59e0b',
  'Mode0': '#3b82f6',
  'Mode1': '#10b981',
  'Mode2': '#f59e0b',
};

// Identify the variant suffix for a test name
const SUFFIXES = ['CASA', 'FITS', 'HDF5', 'Mode0', 'Mode1', 'Mode2'];

function getVariant(testName) {
  for (const s of SUFFIXES) {
    if (testName.endsWith('_' + s) || testName.endsWith(s)) return s;
  }
  return null;
}

function getGroupName(testName) {
  const variant = getVariant(testName);
  if (!variant) return testName;
  // Remove trailing _VARIANT or VARIANT
  if (testName.endsWith('_' + variant)) return testName.slice(0, -(variant.length + 1));
  return testName.slice(0, -variant.length);
}

// Group tests by base name
function groupTests() {
  const groups = {};
  Object.keys(DATA).forEach(name => {
    const group = getGroupName(name);
    if (!groups[group]) groups[group] = {};
    const variant = getVariant(name) || name;
    groups[group][variant] = DATA[name];
  });
  return groups;
}

function getStats(times) {
  const min = Math.min(...times);
  const max = Math.max(...times);
  const avg = times.reduce((a,b) => a+b, 0) / times.length;
  const n = times.length;
  const xMean = (n - 1) / 2;
  const yMean = avg;
  let num = 0, den = 0;
  for (let i = 0; i < n; i++) {
    num += (i - xMean) * (times[i] - yMean);
    den += (i - xMean) ** 2;
  }
  const slope = den ? num / den : 0;
  return { min, max, avg, slope };
}

function createGroupChart(canvas, groupName, variants, showLegend = false) {
  // Collect all unique dates across variants
  const allDates = new Set();
  Object.values(variants).forEach(v => v.dates.forEach(d => allDates.add(d)));
  const labels = [...allDates].sort();

  const datasets = [];
  Object.entries(variants).forEach(([variant, data]) => {
    const color = VARIANT_COLORS[variant] || '#94a3b8';
    // Map data to unified date labels (null for missing dates)
    const dateMap = {};
    data.dates.forEach((d, i) => { dateMap[d] = data.times[i]; });
    const values = labels.map(d => dateMap[d] !== undefined ? dateMap[d] : null);

    datasets.push({
      label: variant,
      data: values,
      borderColor: color,
      backgroundColor: color + '20',
      fill: false,
      tension: 0.3,
      pointRadius: 3,
      pointHoverRadius: 6,
      borderWidth: 2,
      spanGaps: true,
    });
  });

  return new Chart(canvas, {
    type: 'line',
    data: { labels, datasets },
    options: {
      responsive: true,
      maintainAspectRatio: !showLegend,
      aspectRatio: showLegend ? undefined : 2,
      interaction: { intersect: false, mode: 'index' },
      plugins: {
        legend: { display: true, labels: { color: '#94a3b8' } },
        tooltip: {
          backgroundColor: '#1e293b',
          titleColor: '#e2e8f0',
          bodyColor: '#cbd5e1',
          borderColor: '#334155',
          borderWidth: 1,
          callbacks: {
            label: ctx => ctx.parsed.y !== null ? `${ctx.dataset.label}: ${ctx.parsed.y} ms` : null
          }
        }
      },
      scales: {
        x: {
          ticks: { color: '#64748b', maxRotation: 45, font: { size: 10 } },
          grid: { color: '#1e293b' }
        },
        y: {
          title: { display: true, text: 'Milliseconds', color: '#64748b' },
          ticks: { color: '#64748b' },
          grid: { color: '#283548' }
        }
      }
    }
  });
}

// Populate filter dropdown
const groups = groupTests();
const filterEl = document.getElementById('filter');
Object.keys(groups).sort().forEach(group => {
  const opt = document.createElement('option');
  opt.value = group;
  opt.textContent = group.replace('PERF_', '').replace(/_/g, ' ');
  filterEl.appendChild(opt);
});

let currentSort = 'name';
let charts = [];

function renderGrid(filter = 'ALL', sort = 'name') {
  const grid = document.getElementById('grid');
  grid.innerHTML = '';
  charts.forEach(c => c.destroy());
  charts = [];

  let entries = Object.entries(groups);
  if (filter !== 'ALL') {
    entries = entries.filter(([name]) => name === filter);
  }

  if (sort === 'trend') {
    entries.sort((a, b) => {
      // Sort by max avg slope across variants
      const maxSlope = variants => Math.max(...Object.values(variants).map(v => getStats(v.times).slope));
      return maxSlope(b[1]) - maxSlope(a[1]);
    });
  } else {
    entries.sort((a, b) => a[0].localeCompare(b[0]));
  }

  entries.forEach(([groupName, variants]) => {
    const card = document.createElement('div');
    card.className = 'chart-card';

    // Build stats for each variant
    let statsHtml = '';
    Object.entries(variants).forEach(([variant, data]) => {
      const stats = getStats(data.times);
      const color = VARIANT_COLORS[variant] || '#94a3b8';
      statsHtml += `
        <div class="stats">
          <span style="color:${color};font-weight:600">${variant}:</span>
          <span>Min: <span class="val">${stats.min} ms</span></span>
          <span>Max: <span class="val">${stats.max} ms</span></span>
          <span>Avg: <span class="val">${stats.avg.toFixed(0)} ms</span></span>
          <span>Trend: <span class="val" style="color:${stats.slope > 1 ? '#f87171' : stats.slope < -1 ? '#34d399' : '#94a3b8'}">${stats.slope > 0 ? '+' : ''}${stats.slope.toFixed(1)} ms/day</span></span>
        </div>`;
    });

    card.innerHTML = `
      <h3>${groupName}</h3>
      <canvas></canvas>
      ${statsHtml}
    `;
    grid.appendChild(card);

    const canvas = card.querySelector('canvas');
    const chart = createGroupChart(canvas, groupName, variants);
    charts.push(chart);

    // Click to enlarge
    card.style.cursor = 'pointer';
    card.addEventListener('click', () => openModal(groupName, variants));
  });
}

// Modal
let modalChart = null;
const modal = document.getElementById('modal');

function openModal(groupName, variants) {
  modal.classList.add('active');
  document.getElementById('modalTitle').textContent = groupName;
  if (modalChart) modalChart.destroy();
  modalChart = createGroupChart(document.getElementById('modalCanvas'), groupName, variants, true);
  modalChart.options.maintainAspectRatio = false;
  modalChart.resize();
}

modal.addEventListener('click', (e) => {
  if (e.target === modal) {
    modal.classList.remove('active');
    if (modalChart) { modalChart.destroy(); modalChart = null; }
  }
});

// Controls
filterEl.addEventListener('change', () => renderGrid(filterEl.value, currentSort));

document.getElementById('sortName').addEventListener('click', () => {
  currentSort = 'name';
  document.getElementById('sortName').classList.add('active');
  document.getElementById('sortTrend').classList.remove('active');
  renderGrid(filterEl.value, currentSort);
});

document.getElementById('sortTrend').addEventListener('click', () => {
  currentSort = 'trend';
  document.getElementById('sortTrend').classList.add('active');
  document.getElementById('sortName').classList.remove('active');
  renderGrid(filterEl.value, currentSort);
});

renderGrid();
</script>
</body>
</html>
HTMLEOF2

echo "Dashboard generated: $OUTFILE"
