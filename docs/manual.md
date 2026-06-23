# Bound2Learn Manual

This manual explains the practical steps for running the annotated Bound2Learn workflow in the Reyes Lab.

The goal of this document is to help lab users understand the order of the analysis, the expected input files, the pop-up windows they will see, and the common issues that may happen when running the workflow.

## 1. Overview

Bound2Learn is used to classify DNA-bound single-molecule tracks and estimate residence time or dwell time from microscopy data.

A typical analysis includes:

1. Preparing projected microscopy images
2. Generating segmentation masks
3. Tracking single molecules using Fiji/TrackMate
4. Exporting TrackMate tracking files
5. Filtering tracks based on segmentation masks
6. Running the Bound2Learn MATLAB machine-learning workflow
7. Classifying bound tracks
8. Estimating dwell time or residence time

## 2. Required Software

The workflow may require:

* MATLAB
* Fiji/ImageJ
* TrackMate plugin in Fiji
* Python, for TrackMate batch scripts
* Cellpose2, for segmentation
* The Bound2Learn MATLAB scripts and helper functions

Some scripts may depend on older Fiji/TrackMate behavior. In previous lab usage, the archived Fiji version `20191216-2110` was used because newer Fiji versions caused compatibility issues with some TrackMate batch scripts.

## 3. Input Data

The expected inputs depend on the analysis step, but generally include:

* Microscopy image files
* Projected images, such as maximum intensity projections
* Segmentation masks
* TrackMate output files
* Training data files for the machine-learning model
* MATLAB scripts and helper functions from the Bound2Learn codebase

The workflow is sensitive to file names, folder structure, and file format. Before running the full analysis, test the workflow on a small dataset.

## 4. Image Projection

For z-stack data, such as the green channel PCNA z-stack, image projection should be performed before segmentation and tracking.

You can use the lab image projection script:

```text
https://github.com/thereyeslab/research-toolkit/blob/main/preprocessing/image_projection.ijm
```

In previous testing, both SME projection and maximum intensity projection were tested. SME projection made the images noisy, while maximum intensity projection worked better for the tested PCNA z-stack data.

Recommended starting point:

1. Generate maximum intensity projected images.
2. Visually inspect the projected images.
3. Confirm that the relevant signal is visible and not too noisy.
4. Use these projected images for segmentation and downstream analysis.

## 5. Segmentation

Segmentation is used to identify the relevant cells or nuclei so that tracks can later be filtered based on whether they fall inside the correct region.

In the updated lab workflow, segmentation can be done using Cellpose2.

Important checks:

1. Confirm that segmented masks match the correct cells or nuclei.
2. Compare segmentation results with brightfield or reference images.
3. Check whether the cells or nuclei assigned to the expected cell-cycle phase are correctly identified.

For example, if the goal is to analyze molecules in S-phase nuclei, the binary mask should represent the nuclei or cells that should be included in the analysis.

In earlier testing, many nuclei were correctly assigned as S phase, but less bright or heterogeneous nuclei were sometimes missed. This means segmentation should always be visually inspected before continuing.

## 6. TrackMate Tracking in Fiji

Single molecules are tracked using Fiji/TrackMate.

There are two possible ways to do this:

1. Manual tracking through the TrackMate interface
2. Batch tracking using a Python script in Fiji

For this workflow, manual tracking is not recommended for final analysis because the downstream MATLAB code expects TrackMate output files in a specific format. Manual export may produce files with unexpected columns or strings that MATLAB cannot read correctly.

However, manual TrackMate testing can be useful before batch tracking. You can use it to identify good tracking parameters for your dataset, such as intensity threshold, linking distance, and gap-closing distance.

The batch TrackMate script used previously is available here:

```text
https://github.com/thereyeslab/research-toolkit/blob/main/tracking
```

General procedure:

1. Open Fiji.
2. Load or drag the TrackMate batch script into Fiji.
3. Edit the input path in the script.
4. Edit the output path in the script.
5. Set the tracking parameters based on your dataset.
6. Check that the path separators match your operating system.
7. Run the script.
8. Confirm that TrackMate output files were created.

## 7. Important TrackMate Export Notes

The MATLAB downstream scripts expect the TrackMate output files to have a specific format.

The expected files are:

```text
*_spots.csv
*_tracks.csv
```

The `spots.csv` file is expected to contain 5 columns:

```text
track_identifier, track_frame, x_position, y_position, intensity
```

The `tracks.csv` file is expected to contain 18 columns:

```text
Track_IDs
spt_tr
spt_width
mean_speed
max_speed
min_speed
median_speed
std_speed
mean_quality
max_quality
min_quality
median_quality
std_quality
track_duration
track_start
track_finish
x_location
y_location
```

Common issues include:

* The file has the wrong number of columns.
* The columns are not in the expected order.
* The file contains strings or headers that MATLAB cannot read with `csvread`.
* The file was exported manually and does not match the expected batch format.
* The path to the input or output directory is written incorrectly.

Before running the MATLAB analysis, open one TrackMate output file and confirm that it looks similar to the expected format.

## 8. Path Formatting

Path formatting can cause errors, especially when switching between macOS, Windows, and Linux.

Use the correct path separator:

```text
macOS/Linux: /path/to/data/
Windows: C:\path\to\data\
```

If the TrackMate batch script runs but does not stop, or if it cannot find or save files, check both the input path and output path carefully.

## 9. Filtering Tracks with Segmentation Masks

After TrackMate tracking, the next step is to filter tracks using the segmentation masks.

The script used for this step is:

```text
Trackmate_outputter_BATCH_FINAL.m
```

This script keeps only tracks that fall inside the binary mask. For example, if your binary mask represents S-phase nuclei, this step keeps tracks that land inside those nuclei.

### Before running the script

In MATLAB:

1. Navigate to the directory containing your data.
2. Make sure the folder contains the segmentation masks, `spots.csv` files, and `tracks.csv` files.
3. Add the data folder to the MATLAB path.
4. Add the Bound2Learn source-code folder to the MATLAB path.
5. Run:

```matlab
Trackmate_outputter_BATCH_FINAL
```

### Pop-up windows

When the script runs, MATLAB will ask you to select files in this order:

#### 1. `Pick Binary Image Files`

Select the binary segmentation mask files.

Expected format:

```text
*.png
```

These should be binary masks, where the included cell or nuclear regions are non-zero and the background is zero.

#### 2. `Pick spots.csv`

Select the TrackMate spot files.

Expected format:

```text
*spots.csv
```

#### 3. `Pick tracks.csv`

Select the TrackMate track files.

Expected format:

```text
*tracks.csv
```

Important: the selected binary masks, spot files, and track files should be in the same order. The script pairs files by their position in the selected lists.

#### 4. `Tracks Information`

A parameter window will open with the following fields:

```text
What was the time interval
Min # of localizations for track
# of localizations for Intensity
Intensity Thresh
Track Window
Spot Thresh
```

Default values:

```text
1
4
4
500
3
1.5
```

### Parameter meanings

#### `What was the time interval`

The time interval between frames (in second).

Default:

```text
1
```

Use the real acquisition time interval for your dataset. This value is important later for dwell-time estimation.

#### `Min # of localizations for track`

Minimum number of spots/localizations required for a track to be kept.

Default:

```text
4
```

Tracks shorter than this value are removed.

#### `# of localizations for Intensity`

Number of localizations used for intensity-related calculations.

Default:

```text
4
```

In this version of the script, this parameter is collected from the user, but it is not strongly used in the downstream filtering logic. Keep the default unless you are modifying the code.

#### `Intensity Thresh`

Intensity threshold.

Default:

```text
500
```

In this version of the script, this value is used mainly in the output folder name. It is useful for documenting the analysis settings, even if the main filtering is not directly based on this parameter.

#### `Track Window`

Track window.

Default:

```text
3
```

In this version of the script, this value is also mainly used in the output folder name. Keep it documented because it may reflect the tracking settings used upstream in TrackMate.

#### `Spot Thresh`

Spot threshold used for filtering suspicious tracks.

Default:

```text
1.5
```

The script removes tracks when the ratio between the number of spots and track duration is higher than this threshold:

```text
number_of_spots / (track_duration + 1) > Spot Thresh
```

### Output folder

The script automatically creates an output folder with a name based on the selected parameters, for example:

```text
AnalysisMLnew_S_Time_Int1_500_Trkwd_3_datpt_4_Spt_Thr_1.5
```

### Output files

For each TrackMate `tracks.csv` file, the script saves a corresponding MATLAB file:

```text
*tracksdata.mat
```

Each `tracksdata.mat` file contains a MATLAB struct called:

```text
data_tracks
```

with two fields:

```text
Segmented_Tracks
Training
```

#### `Segmented_Tracks`

This contains the filtered TrackMate tracks that landed inside the binary mask.

It has 18 columns from the TrackMate track file.

#### `Training`

This contains the 13 features used for machine-learning classification:

```text
spot_width
mean_speed
max_speed
min_speed
median_speed
std_speed
mean_quality
max_quality
min_quality
median_quality
std_quality
mean_intensity
max_intensity
```

Before continuing, check that the `tracksdata.mat` files are not empty.

## 10. Main Bound2Learn MATLAB Analysis

The main MATLAB script is:

```text
Trackmate_ML_batch_FINAL_REVISED_yst_ML.m
```

Run it from MATLAB:

```matlab
Trackmate_ML_batch_FINAL_REVISED_yst_ML
```

A menu will appear:

```text
What do you want to do?

Learning
Training
Training Combiner
Classifier 1
Analysis
Concatenate
Classifier 2
```

The expected order depends on whether you are training a new model or using existing trained models.

## 11. Recommended Workflow Using Existing Models

If you are using the trained models already provided in the repository, the usual order is:

```text
1. Concatenate
2. Classifier 1
3. Concatenate
4. Classifier 2
5. Analysis
```

This assumes that you already have:

* `tracksdata.mat` files from `Trackmate_outputter_BATCH_FINAL.m`
* trained classifier model files, usually containing `mod` in the file name
* all required helper functions in the MATLAB path

## 12. Step 1 — Concatenate Initial Tracks

From the main menu, select:

```text
Concatenate
```

A window will ask:

```text
Combine Initial Tracks?
```

Default:

```text
Y
```

Enter:

```text
Y
```

Then MATLAB will ask you to select files:

```text
Training
```

Select all:

```text
*tracksdata.mat
```

This step combines the `Training` and `Segmented_Tracks` fields from all selected files.

### Outputs

The script saves the following files in the current MATLAB working directory:

```text
tracks_training_combined.mat
tracks_seg_combined.mat
```

These files are used later for GMM fitting and scaling during `Classifier 1`. (Check the paper for more information)

Important: the output files are saved in the current MATLAB directory, not necessarily in the same folder as the input files. Before running the step, make sure MATLAB is currently in the folder where you want the combined files to be saved.

## 13. Step 2 — Classifier 1

From the main menu, select:

```text
Classifier 1
```

This step classifies tracks as bound or diffusive based mainly on speed-related features.

### Pop-up windows

#### 1. `Pick Classifier file`

Select the first trained model file.

Expected format:

```text
*mod*.mat
```

#### 2. `Predictors`

A window will ask which predictors to use.

The fields are:

```text
Spot Width
Mean Speed
Max Speed
Min Speed
Median Speed
Sigma Speed
Mean Quality
Max Quality
Min Quality
Median Quality
Sigma Quality
Mean Total Intensity
Max Intensity
```

Default values:

```text
0
1
1
1
1
0
0
0
0
0
0
0
0
```

With these defaults, the classifier uses:

```text
Mean Speed
Max Speed
Min Speed
Median Speed
```

Keep the same predictors that were used to train the selected model. If the predictor selection does not match the trained model, classification can fail or give unreliable results.

#### 3. `Pick new data files`

Select the files to classify:

```text
*tracksdata.mat
```

You can select multiple files.

#### 4. `Pick tracks combined file`

Select:

```text
tracks_training_combined.mat
```

This file is used to fit the mean-speed distribution and estimate the immobile population for scaling.

#### 5. `Fraction Factors`

The window asks for:

```text
Speed Factor
```

Default:

```text
1.31
```

This value represents the reference mean speed from the training dataset. In the code comments, the default value `1.31` corresponds to the H3 training dataset.

#### 6. `Fit Correction`

After GMM fitting, a window will ask for:

```text
Log(MeanSP)
```

The default value is estimated by the GMM fit.

Use the displayed default if the fit looks reasonable. If the GMM fit is clearly wrong, manually adjust this value.

### Outputs

For each input `tracksdata.mat` file, the script saves:

```text
*NOQ.mat
```

Each `NOQ.mat` file contains a struct called:

```text
data_tracks_pred
```

with fields:

```text
Tracks_pred
Prediction_class
Training_Scaled
TrainingQ
```

#### `Tracks_pred`

The 18-column TrackMate features for tracks classified as bound by Classifier 1.

#### `Prediction_class`

The predicted class for each track:

```text
0 = diffusive / not bound
1 = bound
```

#### `Training_Scaled`

The scaled predictor variables used for classification.

#### `TrainingQ`

The speed and quality-related features for tracks classified as bound. This is used in the second classification step.

After this step, check that the `NOQ.mat` files are not empty.

## 14. Step 3 — Concatenate After Classifier 1

From the main menu, select again:

```text
Concatenate
```

A window will ask:

```text
Combine Initial Tracks?
```

This time, enter:

```text
N
```

Then select all:

```text
*NOQ*.mat
```

This step combines the `TrainingQ` and `Tracks_pred` fields from all `NOQ.mat` files.

### Outputs

The script saves:

```text
tracks_training_combined_2.mat
tracks_seg_combined_2.mat
```

These files are used by `Classifier 2`.

## 15. Step 4 — Classifier 2

From the main menu, select:

```text
Classifier 2
```

This step applies a second classifier using speed and quality-related information.

### Pop-up windows

#### 1. `Pick Classifier file`

Select the second trained model file.

Expected format:

```text
*mod*.mat
```

#### 2. `Predictors`

The predictor window contains:

```text
Mean Speed
Max Speed
Min Speed
Median Speed
Max Quality
```

Default values:

```text
1
1
1
1
1
```

With these defaults, all listed predictors are used.

Keep the predictor choices consistent with the model that was trained.

#### 3. `Pick new data files`

Select:

```text
*NOQ*.mat
```

#### 4. `Pick tracks combined file`

Select:

```text
tracks_training_combined_2.mat
```

#### 5. `Fraction Factors`

The window asks for:

```text
Quality Factor
```

Default:

```text
3000
```

This value is used to scale the max-quality variable relative to the quality distribution in the selected combined file.

#### 6. `Fit Correction`

After GMM fitting, a window will ask for:

```text
Log(MeanQ)
```

The default value is estimated by the GMM fit.

Use the default if the fit looks reasonable. If the GMM fit is clearly wrong, manually adjust the value.

### Outputs

For each input `NOQ.mat` file, the script saves:

```text
*Q.mat
```

Each `Q.mat` file contains a struct called:

```text
data_tracks_pred
```

with fields:

```text
Tracks_pred
Prediction_class
Training_Scaled
TrainingFinal
```

The `Q.mat` files are the main inputs for the final dwell-time or residence-time analysis.

## 16. Step 5 — Final Analysis

From the main menu, select:

```text
Analysis
```

This step estimates track duration and optionally bound time after photobleaching correction.

### Pop-up windows

#### 1. `Existing Data?`

The window asks:

```text
Would you like to skip filtering tests?
```

Default:

```text
N
```

Use:

```text
N
```

if you want to start from the `Q.mat` files and perform the intensity-based filtering.

Use:

```text
Y
```

only if you already have saved intermediate analysis files, such as:

```text
TrackMate_tracks_bound_single.mat
TrackMate_On_time_bound_single.mat
TrackMate_intensities_bound_single.mat
```

#### 2. `Options`

If you select `N`, a window opens with:

```text
Intensities components
Time Interval
Truncation Point
```

Default values:

```text
4
1
3
```

Parameter meanings:

##### `Intensities components`

Number of GMM components to test for intensity clustering.

Default:

```text
4
```

This is used to identify tracks likely corresponding to single molecules based on intensity.

##### `Time Interval`

Time interval between frames.

Default:

```text
1
```

Use the real acquisition time interval for your dataset.

##### `Truncation Point`

Minimum observable duration used in the truncated exponential fit.

Default for 1s interval. Adjust for other interval. Example: (interval = 0.5 s, put 1.5):

```text
3
```

This value should match the experimental and analysis assumptions for the dataset.

#### 3. `Pick the segmented tracks .mat files`

Select the final classified files:

```text
*_Q*.mat
```

These are the outputs of `Classifier 2`.

#### 4. `GMM Intensity`

The window asks:

```text
Use Mean Intensity?
```

Default:

```text
Y
```

Use:

```text
Y
```

to use mean intensity.

Use:

```text
N
```

to use max intensity.

The script fits the selected intensity values using GMM clustering and keeps the lowest-intensity population as the likely single-molecule population.

#### 5. `Two Exponentials`

The window asks:

```text
Would you like to test for two exponentials?
```

Default:

```text
N
```

Use:

```text
N
```

for the standard one-exponential residence-time analysis.

Use:

```text
Y
```

only if you want to test whether the dwell-time distribution is better described by two exponential components.

#### 6. `Outlier Removals`

The window asks:

```text
Eliminate Outliers?
```

Default:

```text
Y
```

Use:

```text
Y
```

to remove outliers based on quartiles before fitting.

Use:

```text
N
```

to fit the original dwell-time distribution without outlier removal.

#### 7. `Error Calculator`

The window asks:

```text
Do you want to calculate bound time?
```

Default:

```text
Y
```

Use:

```text
Y
```

if you want to estimate bound time after photobleaching correction.

Use:

```text
N
```

if you only want the fitted track duration without photobleaching correction.

#### 8. `Errors`

If you choose to calculate bound time, a window asks for:

```text
Bleach Time
Variation in bleach
```

Default values:

```text
20
0.10
```

Parameter meanings:

##### `Bleach Time`

Estimated photobleaching time. (depends on the dye and time interval used)

##### `Variation in bleach`

Expected variation or uncertainty in the bleach time.

After this step, a message box will show:

```text
Bound time
Bound time confidence interval
Bound time standard error
```

#### 9. `Save`

The window asks:

```text
Save Results?
```

Default:

```text
Y
```

Use:

```text
Y
```

to save the results and intermediate files.

#### 10. `Save Folder`

The window asks:

```text
Pick a name for the folder
```

Default:

```text
Analysis Files
```

Choose a folder name that describes your dataset and analysis settings.

### Outputs

Depending on the options selected, the script saves files such as:

```text
Results.mat
Trackmate_On_time_bound_single_filtered.mat
Trackmate_intensities_bound_single_filtered.mat
Trackmate_tracks_bound_single_filtered.mat
Trackmate_On_time_bound_single.mat
Trackmate_intensities_bound_single.mat
Trackmate_tracks_bound_single.mat
Trackmate_tracks_TOTAL.mat
```

The main summary file is:

```text
Results.mat
```

This may contain fields such as:

```text
BoundTimeFiltered
BoundTimeCIFiltered
BoundTimeSTDErrorFiltered
TrackDurationFiltered
TrackDurationCIFiltered
TrackDurationSEFiltered
```

or, if outlier removal was not used:

```text
BoundTime
BoundTimeCI
BoundTimeSTDError
TrackDuration
TrackDurationCI
TrackDurationSE
```

## 17. Optional Workflow: Training a New Model

If you want to train a new model instead of using existing models, use the following steps:

```text
1. Training
2. Training Combiner
3. Learning
```

This is only needed if the existing trained models are not appropriate for your dataset.

## 18. Training

From the main menu, select:

```text
Training
```

This step lets the user manually classify tracks as noise or bound.

### Pop-up windows

#### 1. `Pick tracks file`

Select one:

```text
*tracksdata.mat
```

#### 2. `Pick Image`

Select the original image stack:

```text
*.tif
```

The script will display each track on the image using MATLAB `implay`.

For each track, a dialog appears:

```text
Classification of Molecule
```

Options:

```text
Noise
Bound
```

Select:

```text
Noise
```

for non-bound or bad tracks.

Select:

```text
Bound
```

for tracks that appear to represent bound molecules.

If you close the dialog or provide no answer, the training process stops.

#### 3. `Saving Classification`

The window asks:

```text
Save?
```

Default:

```text
Y
```

### Output

The script saves:

```text
*classification.mat
```

This file contains the manual labels for the selected tracks.

## 19. Training Combiner

From the main menu, select:

```text
Training Combiner
```

This step combines manually classified files and their corresponding training features.

### Pop-up windows

#### 1. `Pick the classification.mat files`

Select all:

```text
*classification*.mat
```

#### 2. `Training`

Select the matching:

```text
*tracksdata.mat
```

Important: select the files in the same order as the classification files.

### Outputs

The script saves:

```text
classification_combined.mat
training_combined.mat
```

These are used to train the model in the `Learning` step.

## 20. Learning

From the main menu, select:

```text
Learning
```

This step trains a machine-learning model.

### Pop-up windows

#### 1. `Training`

The window asks:

```text
Use Combined training data set?
```

Default:

```text
Combined
```

Use:

```text
Combined
```

if you created `training_combined.mat` and `classification_combined.mat`.

#### 2. `Predictors`

The predictor window contains:

```text
Spot Width
Mean Speed
Max Speed
Min Speed
Median Speed
Sigma Speed
Mean Quality
Max Quality
Min Quality
Median Quality
Sigma Quality
Mean Total Intensity
Max Intensity
```

Default values:

```text
0
1
1
1
1
0
0
1
0
0
0
0
0
```

With these defaults, the model uses:

```text
Mean Speed
Max Speed
Min Speed
Median Speed
Max Quality
```

#### 3. `Pick training file`

If using combined data, select:

```text
training_combined.mat
```

#### 4. `Pick Classification file`

Select:

```text
classification_combined.mat
```

#### 5. `Learner`

The window asks:

```text
Algorithm?
```

Default:

```text
SVM
```

Options supported by the code include:

```text
Linear
SVM
Tree
Bag
```

If you choose `Bag`, another window asks for:

```text
Trees
Leaf Size
Predictor Samples
InFraction
```

Default values:

```text
150
15
2
0.25
```

### Outputs

The script saves a trained model file with `mod` in the name, for example:

```text
mod_SVM...
mod_Tree...
mod_Bag...
```

The exact file name depends on the algorithm and predictor settings.

## 21. Recommended End-to-End Order

For most users using existing trained models:

```text
1. Generate projected images.
2. Generate segmentation masks.
3. Run TrackMate batch tracking in Fiji.
4. Confirm that spots.csv and tracks.csv files were generated correctly.
5. Run Trackmate_outputter_BATCH_FINAL.m.
6. Confirm that tracksdata.mat files were created and are not empty.
7. Run Trackmate_ML_batch_FINAL_REVISED_yst_ML.m.
8. Select Concatenate and enter Y.
9. Select Classifier 1.
10. Select Concatenate again and enter N.
11. Select Classifier 2.
12. Select Analysis.
13. Save the final results.
```

## 22. Common Problems and Fixes

### Problem: TrackMate output cannot be read by MATLAB

Possible causes:

* Wrong export format
* Wrong number of columns
* Unexpected strings or headers
* Manual export instead of batch export

Possible solution:

Regenerate the TrackMate output using the expected batch script and check the file structure.

### Problem: MATLAB output is empty after the outputter script

Possible causes:

* The binary mask removed most or all tracks.
* The selected binary masks, spots files, and tracks files were not in the same order.
* The minimum number of localizations is too strict.
* The TrackMate coordinates do not match the mask coordinates.
* The wrong mask files were selected.

Possible solution:

Run one file at a time and visually compare the mask, TrackMate tracks, and original image.

### Problem: `NOQ.mat` or `Q.mat` files are empty

Possible causes:

* Classifier parameters are too strict.
* Predictor selection does not match the trained model.
* The speed or quality scaling was not appropriate.
* The GMM fit selected an incorrect mean speed or quality value.
* The dataset has too few detectable bound tracks.

Possible solution:

Check the GMM fit, inspect the `Log(MeanSP)` or `Log(MeanQ)` correction value, and confirm that the selected model expects the same predictors.

### Problem: Final analysis fails during fitting

Possible causes:

* Too few tracks remain after classification or intensity filtering.
* The dwell-time distribution is not suitable for the selected fit.
* The bootstrapping or fitting function fails for the current dataset.
* Required helper functions are missing from the MATLAB path.

Possible solution:

Check the number of tracks before fitting, run the analysis without outlier removal, or test the fitting function on a smaller known dataset.

## 23. Best Practices

Before running a full dataset:

1. Run one small test dataset first.
2. Keep raw data separate from processed outputs.
3. Save parameter choices for each experiment.
4. Visually inspect projections and masks.
5. Check TrackMate outputs before MATLAB analysis.
6. Keep intermediate outputs.
7. Do not overwrite previous results unless you are sure.
8. Document any manual changes made to scripts or parameters.
9. Keep all helper functions in the MATLAB path.
10. Check that each output file is not empty before moving to the next step.

## 24. Notes for Future Users

For technical understanding of the method refer to the paper. 

The trained models provided in the repository were trained and often used on budding yeast datasets. They can be used as a baseline, but users should consider whether the training data is appropriate for their biological system, imaging setup, and tracking conditions.

This codebase is useful as a lab reference, but it should be refactored or migrated to Python if it is intended for long-term use.
