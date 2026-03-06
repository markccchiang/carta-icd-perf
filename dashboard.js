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

let charts = [];

function renderGrid(filter = 'ALL') {
  const grid = document.getElementById('grid');
  grid.innerHTML = '';
  charts.forEach(c => c.destroy());
  charts = [];

  let entries = Object.entries(groups);
  if (filter !== 'ALL') {
    entries = entries.filter(([name]) => name === filter);
  }

  entries.sort((a, b) => a[0].localeCompare(b[0]));

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
filterEl.addEventListener('change', () => renderGrid(filterEl.value));

renderGrid();
