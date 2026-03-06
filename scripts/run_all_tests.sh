#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$SCRIPT_DIR/.."
EXTRACT="$SCRIPT_DIR/extract_perf.sh"

mkdir -p "$BASE_DIR/test_logs"

count=0

run() {
    bash "$EXTRACT" "$@"
    count=$((count + 1))
}

# ANIMATOR_CONTOUR (two-step: Case 1 -> Image should return)
ANIM_INTER='\(Case 1\):Play some channels forwardly'
ANIM_STEP='Image should return one after one and the last channel is correct'
run PERF_ANIMATOR_CONTOUR_CASA "$ANIM_STEP" "$ANIM_INTER"
run PERF_ANIMATOR_CONTOUR_FITS "$ANIM_STEP" "$ANIM_INTER"
run PERF_ANIMATOR_CONTOUR_HDF5 "$ANIM_STEP" "$ANIM_INTER"

# CONTOUR_DATA
run PERF_CONTOUR_DATA_Mode0 'smoothingMode of 0 ContourImageData responses should arrive within 12000 ms'
run PERF_CONTOUR_DATA_Mode1 'smoothingMode of 1 ContourImageData responses should arrive within 12000 ms'
run PERF_CONTOUR_DATA_Mode2 'smoothingMode of 2 ContourImageData responses should arrive within 12000 ms'

# CUBE_HISTOGRAM
run PERF_CUBE_HISTOGRAM_CASA 'cube_B_06400_z00100\.image.*REGION_HISTOGRAM_DATA should arrive completely within 300000 ms:'
run PERF_CUBE_HISTOGRAM_FITS 'cube_B_06400_z00100\.fits.*REGION_HISTOGRAM_DATA should arrive completely within 300000 ms:'
run PERF_CUBE_HISTOGRAM_HDF5 'cube_B_06400_z00100\.hdf5.*REGION_HISTOGRAM_DATA should arrive completely within 500 ms:'

# LOAD_IMAGE
run PERF_LOAD_IMAGE_CASA 'cube_B_06400_z00100\.image.*OPEN_FILE_ACK and REGION_HISTOGRAM_DATA should arrive within 20000 ms'
run PERF_LOAD_IMAGE_FITS 'cube_B_06400_z00100\.fits.*OPEN_FILE_ACK and REGION_HISTOGRAM_DATA should arrive within 20000 ms'
run PERF_LOAD_IMAGE_HDF5 'cube_B_06400_z00100\.hdf5.*OPEN_FILE_ACK and REGION_HISTOGRAM_DATA should arrive within 20000 ms'

# MOMENTS
run PERF_MOMENTS_CASA 'S255_IR_sci\.spw25\.cube\.I\.pbcor\.image.*Receive a series of moment progress within 400000ms'
run PERF_MOMENTS_FITS 'S255_IR_sci\.spw25\.cube\.I\.pbcor\.fits.*Receive a series of moment progress within 400000ms'
run PERF_MOMENTS_HDF5 'S255_IR_sci\.spw25\.cube\.I\.pbcor\.hdf5.*Receive a series of moment progress within 400000ms'

# PV
run PERF_PV_CASA 'PV Response should arrived within 200000 ms'
run PERF_PV_FITS 'PV Response should arrived within 200000 ms'
run PERF_PV_HDF5 'PV Response should arrived within 200000 ms'

# RASTER_TILE_DATA
run PERF_RASTER_TILE_DATA_CASA 'cube_B_06400_z00100\.image.*RasterTileData responses should arrive within 10000 ms'
run PERF_RASTER_TILE_DATA_FITS 'cube_B_06400_z00100\.fits.*RasterTileData responses should arrive within 10000 ms'
run PERF_RASTER_TILE_DATA_HDF5 'cube_B_06400_z00100\.hdf5.*RasterTileData responses should arrive within 10000 ms'

# REGION_SPECTRAL_PROFILE
run PERF_REGION_SPECTRAL_PROFILE_CASA 'cube_B_03200_z01000\.image.*SPECTRAL_PROFILE_DATA stream should arrive within 120000 ms'
run PERF_REGION_SPECTRAL_PROFILE_FITS 'cube_B_03200_z01000\.fits.*SPECTRAL_PROFILE_DATA stream should arrive within 120000 ms'
run PERF_REGION_SPECTRAL_PROFILE_HDF5 'cube_B_03200_z01000\.hdf5.*SPECTRAL_PROFILE_DATA stream should arrive within 120000 ms'

echo
echo "Done. $count extraction scripts executed."
