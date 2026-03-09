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

// Filter a single test's data by date range
function filterByDateRange(data, fromDate, toDate) {
  const filtered = { dates: [], times: [] };
  data.dates.forEach((d, i) => {
    const dateOnly = d.slice(0, 10);
    if (dateOnly >= fromDate && dateOnly <= toDate) {
      filtered.dates.push(d);
      filtered.times.push(data.times[i]);
    }
  });
  return filtered;
}

// Group tests by base name, applying date filter
function groupTests(fromDate, toDate) {
  const groups = {};
  Object.keys(DATA).forEach(name => {
    const group = getGroupName(name);
    if (!groups[group]) groups[group] = {};
    const variant = getVariant(name) || name;
    const filtered = filterByDateRange(DATA[name], fromDate, toDate);
    if (filtered.dates.length > 0) {
      groups[group][variant] = filtered;
    }
  });
  return groups;
}

// Compute daily statistics (avg, min, max) from date+time arrays
function computeDailyStats(dates, times) {
  const dayMap = {};
  dates.forEach((d, i) => {
    const day = d.slice(0, 10);
    if (!dayMap[day]) dayMap[day] = [];
    dayMap[day].push(times[i]);
  });
  const days = Object.keys(dayMap).sort();
  const avg = [], min = [], max = [];
  days.forEach(day => {
    const vals = dayMap[day];
    avg.push(vals.reduce((a, b) => a + b, 0) / vals.length);
    min.push(Math.min(...vals));
    max.push(Math.max(...vals));
  });
  return { days, avg, min, max };
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
    data.dates.forEach((d, i) => { dateMap[d] = data.times[i] / 1000; });
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
            label: ctx => ctx.parsed.y !== null ? `${ctx.dataset.label}: ${ctx.parsed.y.toFixed(1)} s` : null,
            afterBody: (items) => {
              const casaItem = items.find(i => i.dataset.label === 'CASA');
              if (!casaItem || casaItem.parsed.y === null || casaItem.parsed.y === 0) return '';
              const casaVal = casaItem.parsed.y;
              const lines = ['\nRatios (vs CASA):'];
              items.forEach(i => {
                if (i.parsed.y === null) return;
                const ratio = i.parsed.y / casaVal;
                lines.push(`  ${i.dataset.label}: ${ratio.toFixed(2)}`);
              });
              return lines.join('\n');
            }
          }
        }
      },
      scales: {
        x: {
          ticks: { color: '#64748b', maxRotation: 45, font: { size: 10 } },
          grid: { color: '#1e293b' }
        },
        y: {
          title: { display: true, text: 'Seconds', color: '#64748b' },
          ticks: { color: '#64748b' },
          grid: { color: '#283548' }
        }
      }
    }
  });
}

function createDailyStatsChart(canvas, groupName, variants, showLegend = false) {
  const datasets = [];
  Object.entries(variants).forEach(([variant, data]) => {
    const color = VARIANT_COLORS[variant] || '#94a3b8';
    const stats = computeDailyStats(data.dates, data.times);

    // Min-Max range (filled area)
    datasets.push({
      label: variant + ' Max',
      data: stats.days.map((d, i) => ({ x: d, y: stats.max[i] / 1000 })),
      borderColor: 'transparent',
      backgroundColor: color + '25',
      fill: '+1',
      pointRadius: 0,
      borderWidth: 0,
      tension: 0.3,
      order: 3,
    });
    datasets.push({
      label: variant + ' Min',
      data: stats.days.map((d, i) => ({ x: d, y: stats.min[i] / 1000 })),
      borderColor: color + '50',
      backgroundColor: 'transparent',
      fill: false,
      pointRadius: 2,
      borderWidth: 1,
      borderDash: [4, 3],
      tension: 0.3,
      order: 2,
    });
    // Avg line (solid, prominent)
    datasets.push({
      label: variant + ' Avg',
      data: stats.days.map((d, i) => ({ x: d, y: stats.avg[i] / 1000 })),
      borderColor: color,
      backgroundColor: color + '40',
      fill: false,
      pointRadius: 4,
      pointHoverRadius: 7,
      borderWidth: 2.5,
      tension: 0.3,
      order: 1,
    });
  });

  // Collect all unique days for labels
  const allDays = new Set();
  Object.values(variants).forEach(v => {
    const stats = computeDailyStats(v.dates, v.times);
    stats.days.forEach(d => allDays.add(d));
  });
  const labels = [...allDays].sort();

  return new Chart(canvas, {
    type: 'line',
    data: { labels, datasets },
    options: {
      responsive: true,
      maintainAspectRatio: !showLegend,
      aspectRatio: showLegend ? undefined : 2,
      interaction: { intersect: false, mode: 'index' },
      plugins: {
        legend: {
          display: true,
          labels: {
            color: '#94a3b8',
            filter: item => item.text.endsWith('Avg'),
          }
        },
        tooltip: {
          backgroundColor: '#1e293b',
          titleColor: '#e2e8f0',
          bodyColor: '#cbd5e1',
          borderColor: '#334155',
          borderWidth: 1,
          callbacks: {
            label: ctx => {
              if (ctx.parsed.y === null) return null;
              return `${ctx.dataset.label}: ${ctx.parsed.y.toFixed(2)} s`;
            }
          }
        }
      },
      scales: {
        x: {
          ticks: { color: '#64748b', maxRotation: 45, font: { size: 10 } },
          grid: { color: '#1e293b' }
        },
        y: {
          title: { display: true, text: 'Seconds', color: '#64748b' },
          ticks: { color: '#64748b' },
          grid: { color: '#283548' }
        }
      }
    }
  });
}

// Set up date inputs with defaults (180 days ago to today)
const dateFromEl = document.getElementById('dateFrom');
const dateToEl = document.getElementById('dateTo');
const today = new Date();
const defaultFrom = new Date(today);
defaultFrom.setDate(defaultFrom.getDate() - 30);
dateFromEl.value = defaultFrom.toISOString().slice(0, 10);
dateToEl.value = today.toISOString().slice(0, 10);

// Populate filter dropdown (use full data for dropdown options)
const allGroups = groupTests('0000-00-00', '9999-99-99');
const filterEl = document.getElementById('filter');
Object.keys(allGroups).sort().forEach(group => {
  const opt = document.createElement('option');
  opt.value = group;
  opt.textContent = group.replace('PERF_', '').replace(/_/g, ' ');
  filterEl.appendChild(opt);
});

let charts = [];
let viewMode = 'raw'; // 'raw' or 'daily'

const viewToggleEl = document.getElementById('viewToggle');
viewToggleEl.addEventListener('click', () => {
  viewMode = viewMode === 'raw' ? 'daily' : 'raw';
  viewToggleEl.textContent = viewMode === 'raw' ? 'Daily Stats View' : 'Raw Data View';
  viewToggleEl.classList.toggle('active', viewMode === 'daily');
  renderGrid(filterEl.value);
});

function renderGrid(filter = 'ALL') {
  const grid = document.getElementById('grid');
  grid.innerHTML = '';
  charts.forEach(c => c.destroy());
  charts = [];

  const groups = groupTests(dateFromEl.value, dateToEl.value);
  let entries = Object.entries(groups);
  if (filter === 'ALL') {
    entries = entries.filter(([name]) => name !== 'PERF_CONTOUR_DATA');
  } else {
    entries = entries.filter(([name]) => name === filter);
  }

  entries.sort((a, b) => a[0].localeCompare(b[0]));

  entries.forEach(([groupName, variants]) => {
    const card = document.createElement('div');
    card.className = 'chart-card';

    // Build stats for each variant
    let statsHtml = '';
    Object.entries(variants).forEach(([variant, data]) => {
      const color = VARIANT_COLORS[variant] || '#94a3b8';

      if (viewMode === 'daily') {
        const daily = computeDailyStats(data.dates, data.times);
        const overallAvg = daily.avg.reduce((a, b) => a + b, 0) / daily.avg.length;
        const overallMin = Math.min(...daily.min);
        const overallMax = Math.max(...daily.max);
        statsHtml += `
          <div class="stats">
            <span style="color:${color};font-weight:600">${variant}:</span>
            <span>Daily Avg: <span class="val">${(overallAvg / 1000).toFixed(2)} s</span></span>
            <span>Daily Min: <span class="val">${(overallMin / 1000).toFixed(2)} s</span></span>
            <span>Daily Max: <span class="val">${(overallMax / 1000).toFixed(2)} s</span></span>
            <span>Days: <span class="val">${daily.days.length}</span></span>
          </div>`;
      } else {
        const stats = getStats(data.times);
        statsHtml += `
          <div class="stats">
            <span style="color:${color};font-weight:600">${variant}:</span>
            <span>Min: <span class="val">${(stats.min / 1000).toFixed(1)} s</span></span>
            <span>Max: <span class="val">${(stats.max / 1000).toFixed(1)} s</span></span>
            <span>Avg: <span class="val">${(stats.avg / 1000).toFixed(1)} s</span></span>
            <span>Trend: <span class="val" style="color:${stats.slope > 1 ? '#f87171' : stats.slope < -1 ? '#34d399' : '#94a3b8'}">${stats.slope > 0 ? '+' : ''}${(stats.slope / 1000).toFixed(2)} s/day (${stats.slope / stats.avg * 100 > 0 ? '+' : ''}${(stats.slope / stats.avg * 100).toFixed(2)} %/day)</span></span>
          </div>`;
      }
    });

    card.innerHTML = `
      <h3>${groupName.replace('PERF_', '').replace(/_/g, ' ')}</h3>
      <canvas></canvas>
      ${statsHtml}
    `;
    grid.appendChild(card);

    const canvas = card.querySelector('canvas');
    const chart = viewMode === 'daily'
      ? createDailyStatsChart(canvas, groupName, variants)
      : createGroupChart(canvas, groupName, variants);
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
  document.getElementById('modalTitle').textContent = groupName.replace('PERF_', '').replace(/_/g, ' ');
  if (modalChart) modalChart.destroy();
  modalChart = viewMode === 'daily'
    ? createDailyStatsChart(document.getElementById('modalCanvas'), groupName, variants, true)
    : createGroupChart(document.getElementById('modalCanvas'), groupName, variants, true);
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
filterEl.addEventListener('change', () => renderGrid(filterEl.value));
dateFromEl.addEventListener('change', () => renderGrid(filterEl.value));
dateToEl.addEventListener('change', () => renderGrid(filterEl.value));

renderGrid();
