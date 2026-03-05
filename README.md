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
│   └── generate_dashboard.sh         # Generate dashboard.html from test_logs/
├── dashboard.html                    # Generated interactive dashboard
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

Reads all log files in `test_logs/` and generates a self-contained `dashboard.html`.

```bash
./scripts/generate_dashboard.sh
```

## Dashboard Features

- **Grouped charts** overlaying CASA/FITS/HDF5 (or Mode0/Mode1/Mode2) variants
- **Stats** per variant: Min, Max, Avg, and Trend (ms/day)
- **Filter dropdown** to view tests by category (e.g., PV, MOMENTS, CUBE HISTOGRAM)
- **Click any chart** to enlarge it in a modal view

## Adding New Logs

1. Place new `perf-YYYYMMDD.log` files in the `log/` directory
2. Re-run the pipeline:
   ```bash
   ./scripts/run_all_tests.sh && ./scripts/generate_dashboard.sh
   ```
3. Refresh `dashboard.html` in your browser
