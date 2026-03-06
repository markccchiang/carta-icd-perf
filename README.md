# CARTA ICD Performance Tests

A set of bash scripts that parse Jest performance test logs and generate an interactive web dashboard to visualize elapsed time trends.

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

## Quick Start

Generate everything and open the dashboard:

```bash
./scripts/run_all_tests.sh && ./scripts/extract_data.sh
open dashboard.html
```

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

The dashboard is split into static files (`dashboard.html`, `dashboard.css`, `dashboard.js`) and a generated data file (`data.js`). This means:

- **To refresh data only:** run `./scripts/extract_data.sh` — this regenerates `data.js` without touching the dashboard files
- **To rebuild everything from raw logs:** run `./scripts/run_all_tests.sh && ./scripts/extract_data.sh`

### Adding New Logs

1. Place new `perf-YYYYMMDD-HH.log` files in the `log/` directory
2. Re-run the pipeline:
   ```bash
   ./scripts/run_all_tests.sh && ./scripts/extract_data.sh
   ```
3. Refresh `dashboard.html` in your browser

### Modifying the Dashboard

The dashboard UI can be changed by editing these static files directly — no regeneration needed:

- `dashboard.html` — page structure
- `dashboard.css` — styles
- `dashboard.js` — chart rendering, filtering, modal logic

## Docker

Build and run the dashboard as a containerized nginx server:

```bash
docker build -t carta-icd-perf .
docker run -p 8080:80 carta-icd-perf
```

Then open `http://localhost:8080`.

You can choose any available host port by changing the `-p` mapping. For example, to serve the dashboard on port `9090`:

```bash
docker run -p 9090:80 carta-icd-perf
```

The format is `-p <host-port>:80`, where `<host-port>` is the port you want to access on your machine.

To update data without rebuilding the image, mount `data.js` as a volume:

```bash
docker run -p 8080:80 -v $(pwd)/data.js:/usr/share/nginx/html/data.js carta-icd-perf
```

This way you just run `./scripts/run_all_tests.sh && ./scripts/extract_data.sh` and refresh the browser — no image rebuild needed. The nginx config sets `no-cache` headers on `data.js` so the browser always fetches fresh data.
