# CARTA ICD Performance Tests

A set of bash scripts that parse Jest performance test logs and generate an interactive web dashboard to visualize elapsed time trends.

## Directory Structure

```
carta-icd-perf/
├── log/                              # Source log files (perf-YYYYMMDD.log)
├── test_logs/                        # Generated per-test elapsed time logs
├── scripts/
│   ├── extract_perf_*.sh             # Individual extraction scripts per test
│   ├── run_all_tests.sh              # Run all extraction scripts
│   └── generate_dashboard.sh         # Generate data.js from test_logs/
├── dashboard.html                    # Static dashboard page
├── dashboard.css                     # Dashboard styles
├── dashboard.js                      # Dashboard logic (charts, UI, modal)
├── data.js                           # Generated test data (refreshed by script)
└── README.md
```

## Prerequisites

- Bash
- A modern web browser (for viewing the dashboard)

## Quick Start

Generate everything and open the dashboard:

```bash
./scripts/run_all_tests.sh && ./scripts/generate_dashboard.sh
open dashboard.html
```

## Scripts

### scripts/extract_perf_*.sh

Individual scripts that extract elapsed times for a specific test from all `perf-*.log` files in `log/` and write results to `test_logs/`. Each script targets a specific test and search pattern.

```bash
# Run a single extraction
./scripts/extract_perf_pv_casa.sh
```

### scripts/run_all_tests.sh

Runs all `extract_perf_*.sh` scripts and saves the results as individual log files in `test_logs/`.

```bash
./scripts/run_all_tests.sh
```

### scripts/generate_dashboard.sh

Reads all log files in `test_logs/` and generates `data.js`. The dashboard HTML, CSS, and JS files are static and do not need to be regenerated.

```bash
./scripts/generate_dashboard.sh
```

## Dashboard Features

- **Grouped charts** overlaying CASA/FITS/HDF5 (or Mode0/Mode1/Mode2) variants
- **Stats** per variant: Min, Max, Avg, and Trend (ms/day)
- **Filter dropdown** to view tests by category (e.g., PV, MOMENTS, CUBE HISTOGRAM)
- **Click any chart** to enlarge it in a modal view

## Workflow

The dashboard is split into static files (`dashboard.html`, `dashboard.css`, `dashboard.js`) and a generated data file (`data.js`). This means:

- **To refresh data only:** run `./scripts/generate_dashboard.sh` — this regenerates `data.js` without touching the dashboard files
- **To rebuild everything from raw logs:** run `./scripts/run_all_tests.sh && ./scripts/generate_dashboard.sh`

### Adding New Logs

1. Place new `perf-YYYYMMDD.log` files in the `log/` directory
2. Re-run the pipeline:
   ```bash
   ./scripts/run_all_tests.sh && ./scripts/generate_dashboard.sh
   ```
3. Refresh `dashboard.html` in your browser

### Modifying the Dashboard

The dashboard UI can be changed by editing these static files directly — no regeneration needed:

- `dashboard.html` — page structure
- `dashboard.css` — styles
- `dashboard.js` — chart rendering, filtering, modal logic
