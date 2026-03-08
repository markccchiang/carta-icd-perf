# CARTA ICD Performance Tests Dashboard

This repo presents the daily performance test results for CARTA ICD. It includes a set of bash scripts that parse Jest performance test logs and generate an interactive web dashboard to visualize elapsed time trends.

## Directory Structure

```
carta-icd-perf/
├── log/                              # Source log files (perf-YYYYMMDD-HH.log)
├── test_logs/                        # Generated per-test elapsed time logs
├── scripts/
│   ├── extract_perf.sh               # Generic extraction script (called by run_all_tests.sh)
│   ├── run_all_tests.sh              # Run all extractions with test-specific patterns
│   └── extract_data.sh               # Generate data.js from test_logs/
├── dashboard.html                    # Static dashboard page
├── dashboard.css                     # Dashboard styles
├── dashboard.js                      # Dashboard logic (charts, UI, modal)
├── data.js                           # Generated test data (refreshed by script)
├── Dockerfile                        # Docker image definition (nginx)
├── nginx.conf                        # Nginx configuration
└── README.md
```

## Prerequisites

- Bash
- A modern web browser (for viewing the dashboard)
- Docker (optional, for containerized deployment)

## Scripts

### scripts/extract_perf.sh

Generic extraction script that takes a test name and search pattern as arguments. Called by `run_all_tests.sh` — not typically run directly.

```bash
# Run a single extraction
./scripts/extract_perf.sh PERF_PV_CASA 'PV Response should arrived within 200000 ms'
```

### scripts/run_all_tests.sh

Runs `extract_perf.sh` for all tests with their specific patterns, saving results to `test_logs/`.

```bash
./scripts/run_all_tests.sh
```

### scripts/extract_data.sh

Reads all log files in `test_logs/` and generates `data.js`. The dashboard HTML, CSS, and JS files are static and do not need to be regenerated.

```bash
./scripts/extract_data.sh
```

## Dashboard Features

- **Grouped charts** overlaying CASA/FITS/HDF5 (or Mode0/Mode1/Mode2) variants
- **Stats** per variant: Min, Max, Avg, and Trend (ms/day)
- **Filter dropdown** to view tests by category (e.g., PV, MOMENTS, CUBE HISTOGRAM)
- **Click any chart** to enlarge it in a modal view

## Workflow

The dashboard is split into static files (`dashboard.html`, `dashboard.css`, `dashboard.js`) and a generated data file (`data.js`).

**Important:** Before running any scripts, make sure your `perf-YYYYMMDD-HH.log` files are placed in the `log/` directory. The scripts read from this directory to extract test results.

- **To rebuild everything from raw logs:** run `./scripts/run_all_tests.sh && ./scripts/extract_data.sh`
- **To refresh data only** (if `test_logs/` is already up to date): run `./scripts/extract_data.sh` — this regenerates `data.js` without touching the dashboard files
- After running the scripts, refresh `dashboard.html` in your browser

### Modifying the Dashboard

The dashboard UI can be changed by editing these static files directly — no regeneration needed:

- `dashboard.html` — page structure
- `dashboard.css` — styles
- `dashboard.js` — chart rendering, filtering, modal logic

## Docker

Build and run the dashboard as a containerized nginx server. The `-d` flag runs the container in detached mode (in the background), so your terminal remains free for other tasks:

```bash
docker build -t carta-icd-perf .
docker run -d -p 8080:80 carta-icd-perf
```

Then open `http://localhost:8080`.

You can choose any available host port by changing the `-p` mapping. For example, to serve the dashboard on port `9090`:

```bash
docker run -d -p 9090:80 carta-icd-perf
```

To update data without rebuilding the image, mount `data.js` as a volume:

```bash
docker run -d -p 8080:80 -v $(pwd)/data.js:/usr/share/nginx/html/data.js carta-icd-perf
```

Place new `perf-YYYYMMDD-HH.log` files in the `log/` directory, then run `./scripts/run_all_tests.sh && ./scripts/extract_data.sh` and refresh the browser — or simply replace `data.js` directly. No image rebuild is needed. The nginx config sets `no-cache` headers on `data.js`, so the browser always fetches fresh data.
