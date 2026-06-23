# Bound2Learn Lab Manual and Annotated Code

This repository contains an annotated version of the Bound2Learn analysis code used in the Reyes Lab, along with practical notes for running the workflow on lab data.

Bound2Learn is a machine-learning-based workflow for classifying DNA-bound proteins from single-molecule tracking experiments and estimating residence times. The original method was developed by Kapadia, El-Hajj, and Reyes-Lamothe and published in *Nucleic Acids Research*.

## Original Reference

Kapadia, N., El-Hajj, Z. W., & Reyes-Lamothe, R.
**Bound2Learn: a machine learning approach for classification of DNA-bound proteins from single-molecule tracking experiments.**
*Nucleic Acids Research*, 49(14), e79, 2021.
https://doi.org/10.1093/nar/gkab186

## Purpose of This Repository

This repository is intended as a lab reference for people who need to understand, run, or adapt the Bound2Learn workflow on Reyes Lab datasets.

The goal is not to provide a fully refactored or production-ready software package. These scripts were annotated and documented as useful research utilities, especially for understanding the logic of the analysis pipeline and the practical steps needed to run it. 
The codebase needs to be refactored or migrated to python if intended to be used long-term. 

## Workflow Overview

At a high level, the analysis involves:

1. Preparing microscopy images and segmentation masks (using Cellpose2)
2. Tracking single molecules using TrackMate/Fiji
3. Exporting TrackMate results in the expected format
4. Filtering tracks based on cell or nuclear masks
5. Combining training data
6. Training machine-learning models to classify bound versus non-bound tracks
7. Applying the trained models to experimental data
8. Estimating residence time or dwell time from classified bound tracks

The workflow uses TrackMate outputs as input for downstream MATLAB analysis. The original Bound2Learn approach uses machine learning to classify tracks representing genuine DNA-bound molecules, then fits track durations to estimate residence times.

## Important Notes

This repository is not fully refactored, optimized, or generalized.

Users should expect that:

* Some scripts require manual path changes.
* Some parameters must be adjusted for each dataset.
* Input files may need to follow a specific format.
* TrackMate output files must contain the expected columns.
* Fiji/TrackMate version compatibility can affect the workflow.
* Some steps may require troubleshooting before running successfully.
* The documentation reflects practical lab usage and may not cover every edge case.

This repository should be treated as a reference manual, not as a polished command-line package.

## Requirements

The exact requirements may depend on the dataset and analysis step, but the workflow generally uses:

* MATLAB
* Fiji/ImageJ
* TrackMate plugin
* Python, for TrackMate batch-processing scripts when needed
* Microscopy image files
* Segmentation masks
* TrackMate output files

For some older scripts, specific Fiji versions may be required. In previous lab usage, newer Fiji versions caused compatibility issues with some TrackMate batch scripts, so older archived Fiji versions may be needed.

## Suggested Repository Structure

```text
Bound2Learn/
├── README.md
├── src/
├── docs/
├── Data/
└──   └── example_data
└──   └── models


```

## Basic Usage

Because the workflow is not fully automated, users should follow the manual documentation rather than expecting a single command to run the full pipeline.

A typical analysis follows this order:

1. Prepare image projections and segmentation masks.
2. Run TrackMate tracking in Fiji.
3. Export TrackMate tracking results in the expected format.
4. Run the MATLAB script that filters tracks using the segmentation masks.
5. Run the main Bound2Learn machine-learning analysis script.
6. Check the classification outputs.
7. Run dwell-time or residence-time analysis.
8. Inspect plots and output files manually.

## Known Limitations

* The workflow depends strongly on file naming, folder structure, and exported TrackMate format.
* Some scripts may fail if TrackMate output columns differ from the expected order.
* Some parameters, including ML hyperparameters are dataset-specific.
* Some functions call other helper functions, so users should keep the full codebase together.

## Recommended Use

Before using this workflow on a new dataset:

1. Start with a small test dataset.
2. Confirm that TrackMate output files are readable by MATLAB.
3. Confirm that segmentation masks correctly identify the relevant cells or nuclei.
4. Run each step separately before running a full batch.
5. Check intermediate outputs before trusting final dwell-time results.
6. Record any parameter changes used for the dataset.

## Citation

If this workflow or codebase is used in scientific work, cite the original Bound2Learn paper:

Kapadia, N., El-Hajj, Z. W., & Reyes-Lamothe, R.
**Bound2Learn: a machine learning approach for classification of DNA-bound proteins from single-molecule tracking experiments.**
*Nucleic Acids Research*, 49(14), e79, 2021.
https://doi.org/10.1093/nar/gkab186
