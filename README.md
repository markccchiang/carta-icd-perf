# Performance Test Dashboard

A set of bash scripts that parse Jest performance test logs and generate an interactive web dashboard to visualize elapsed time trends.

## Directory Structure

```
perf-dashboard/
├── log/                    # Source log files (perf-YYYYMMDD.log)
├── test_logs/              # Generated per-test elapsed time logs
├── extract_times.sh        # List all test times from each log file
├── track_test.sh           # Track a specific test across all dates
├── run_all_tests.sh        # Generate per-test log files into test_logs/
├── generate_dashboard.sh   # Generate dashboard.html from test_logs/
├── dashboard.html          # Generated interactive dashboard
└── README.md
```

## Prerequisites

- Bash
- A modern web browser (for viewing the dashboard)

## Quick Start

Generate everything and open the dashboard:

```bash
./run_all_tests.sh && ./generate_dashboard.sh
open dashboard.html
```

## Scripts

### extract_times.sh

Lists all test names and their elapsed times from every `perf-*.log` file in `log/`.

```bash
./extract_times.sh
```

### track_test.sh

Tracks a specific test's elapsed time across all dates. Supports exact and partial matching.

```bash
# List all available test names
./track_test.sh

# Track a specific test
./track_test.sh PERF_PV_CASA

# Partial match (shows all PV tests: CASA, FITS, HDF5)
./track_test.sh PERF_PV
```

### run_all_tests.sh

Runs `track_test.sh` for every test and saves the results as individual log files in `test_logs/`.

```bash
./run_all_tests.sh
```

### generate_dashboard.sh

Reads all log files in `test_logs/` and generates a self-contained `dashboard.html`.

```bash
./generate_dashboard.sh
```

## Dashboard Features

- **Time vs. Date charts** for all 24 performance tests
- **Trend line** (dashed red) showing linear regression
- **Stats** per test: Min, Max, Avg, and Trend (s/day)
- **Filter dropdown** to view tests by category (e.g., PV, MOMENTS, CUBE HISTOGRAM)
- **Sort** by name or by trend (worst-degrading first)
- **Click any chart** to enlarge it in a modal view

## Adding New Logs

1. Place new `perf-YYYYMMDD.log` files in the `log/` directory
2. Re-run the pipeline:
   ```bash
   ./run_all_tests.sh && ./generate_dashboard.sh
   ```
3. Refresh `dashboard.html` in your browser
