# PEEW variable-position RC–NTU model: MATLAB reproduction code

This repository contains MATLAB source code implementing the variable-position transient RC–NTU model for pipe-embedded external walls, with case definitions and postprocessing for envelope-side equivalent electricity use and IEU-based pipe-location screening.

## Requirements
MATLAB R2023b (the development version) and Parallel Computing Toolbox for `parfor` execution. The model may also be run in serial mode.

## Run
1. Open MATLAB and change the current folder to this repository root.
2. Run `RUN_CHECK_INPUTS.m` to check inputs and dependencies.
3. Run `RUN_TAIYUAN_PARALLEL.m` for Taiyuan orientations, or `RUN_ALL_PARALLEL.m` for all cases in `inputs/paper_cases.csv`.
4. Alternatively run `run_reproduction('Taiyuan','full','parallel',32)` or `run_reproduction('paper','full','serial')`.

## Inputs
- `inputs/paper_cases.csv`: city, heating season, orientation and insulation setup.
- `inputs/weather/`: meteorological inputs; **distribution rights must be checked before public release** because they may derive from Meteonorm data.
- Water properties and other model inputs used by the calculation are provided in the input directories.
- `peew_config.m`: geometry, materials, time stepping, pump and source-side equivalent hydraulic assumptions.

## Outputs
- `results/all_cases.csv`: simulated heat-transfer and electricity totals, IEU and screening flags.
- `results/reference_CW.csv`: corresponding conventional-wall baseline results.
- `results/recommended_locations.csv`: computed near-optimal pipe-location sets.
- `results/run_archive/`: automatically archived run output files.

The program calculates indices from the simulated data. Published manuscript table values are **not embedded** in the computation or used to determine the recommended locations.

## Numerical and scientific notes
The supply temperature is prescribed. The source-side piping is modeled as an equivalent hydraulic resistance and is not a coupled thermal source model. The heating-load electricity treatment is signed in this study and represents envelope-side equivalent demand, not measured whole-system electricity. The pipe-location recommendations are limited to the simulated wall configurations and the specified case grid.


## Citation and license
Add the paper citation/DOI when available. Choose a software license only after confirming redistribution rights for all included third-party files and data.
