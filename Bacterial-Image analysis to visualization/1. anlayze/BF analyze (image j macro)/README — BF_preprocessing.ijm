ImageJ macro for brightfield (BF) preprocessing and morphological feature extraction for X, Z values
This macro preprocesses brightfield (BF) images obtained from antibiotic-treated bacterial cultures 
and extracts morphological measurements required for generating X and Z values in downstream high-throughput screening (HTS) analysis.

The macro applies 8-bit conversion, bandpass filtering, threshold-based mask generation, and particle-based quantification.
The extracted features—including total particle count, total area, average particle size, and percent area—serve as fundamental BF-derived metrics for the HTS dataset.

1. Features
- 8-bit conversion: Standardizes image depth to ensure consistent filtering and segmentation across all BF images.

- Bandpass filtering: Enhances cell-like mid-frequency structures while suppressing background noise.
(Default ImageJ parameters are used, as these settings were empirically validated for this workflow.)

- Mask generation
  :Applies ImageJ’s Default thresholding method to generate a binary mask for particle detection.
  Thresholding is intentionally fixed to Default to maintain reproducibility across experiments.
  Alternative methods (e.g., Otsu, Triangle, Mean, Minimum, Yen) are not recommended and therefore excluded.

- Particle-based quantitative extraction
  :ImageJ’s Analyze Particles function produces the following morphological summary features:
    Count
    Total area
    Average size
    % area
    Among these outputs:
      Z-value corresponds to the Average Size metric, representing BF-derived cell-size morphology.
      X-value is derived from BF metrics during downstream integration (performed in Excel).
        # NOTE: X-value computation depends on comparison with mock/control conditions and is handled outside ImageJ.
- Batch processing
  : The macro automatically processes all open BF images, enabling efficient high-throughput quantification.


2. Input Requirements
Open only BF brightfield images before running the macro.
PI images should not be open simultaneously (use PI_preprocessing.ijm separately).
Image resolution does not matter for BF preprocessing.
No background subtraction is required (unlike PI preprocessing).


3. How to Run
1) Open ImageJ/Fiji.
2) Load all BF images you want to process.
3) Open BF_preprocessing.ijm.
4) Run the macro.
5) After processing completes, a Results table appears.


4. Output
The macro generates a single Results table containing one summary row per processed image.
Typical output columns include:
  Count
  Total Area
  Average Size → used as Z-value
  %Area
  Mean
  Downstream integration
All BF (X/Z) and PI (Y) extracted values are merged in Excel and subsequently used as input for R/Python visualization and subgroup analysis.
  # NOTE: X-value definition depends on comparison against mock/control wells and is computed during the Excel integration step (not within ImageJ).


5. Customization Policy
To preserve consistency across HTS experiments:
Threshold method is fixed (“Default”).
Other thresholding methods should not be used.
Bandpass filter settings should remain unchanged, as the defaults match the experimental imaging conditions.
Particle Analyzer options must remain unchanged.
No size/circularity constraints should be added.
This ensures reproducibility across plates and antibiotic conditions.


6. Notes
This macro provides primary BF feature extraction for cell size–related HTS metrics.
PI measurements (Y-values) require the separate macro PI_preprocessing.ijm.
The combined dataset (BF + PI) is exported to Excel and used for higher-level visualization (ggplot2 / Plotly) and Z-subgroup modeling.


7. Citation
Brightfield preprocessing and morphological feature extraction were performed 
using a custom ImageJ macro (BF_preprocessing.ijm) written by Sujin Kim.
