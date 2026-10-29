# MATLAB run instructions (English version)

## Package contents
- `model/`: 1D RC-NTU transient heat-transfer, flow and hydraulic calculations.
- `inputs/paper_cases.csv`: five-city heating dates, insulation thicknesses, weather-file names, and wall orientations.
- `inputs/weather/`: meteorological MAT files; verify that redistribution is permitted.
- `inputs/water/`: temperature-dependent water properties.
- `run_reproduction.m`: computation entry point; supports serial or process-based `parfor`.
- `results/`: generated CSV outputs; initially empty in this distribution.

## Run by clicking MATLAB Editor > Run
1. Open MATLAB R2023b. Set Current Folder to this package directory.
2. Open `RUN_CHECK_INPUTS.m` and click **Run** to validate input configuration and tests.
3. Open `RUN_TAIYUAN_PARALLEL.m` and click **Run** to run four Taiyuan orientations.
4. Open `RUN_ALL_PARALLEL.m` and click **Run** to run all five-city cases.

Change the `workers` variable near the top of the parallel scripts to select the number of local workers. The actual worker count depends on the local Parallel Computing Toolbox profile. A pool is initialized after input checks. Independent cases run in parallel; individual transient time steps are sequential.


