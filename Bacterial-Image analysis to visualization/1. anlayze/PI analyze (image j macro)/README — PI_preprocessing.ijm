ImageJ macro for PI-channel preprocessing & quantitative feature extraction

This macro performs preprocessing and feature extraction from PI (propidium iodide) fluorescence images used in antibiotic-treated bacterial imaging assays.
It automatically handles resolution-specific background subtraction, RenyiEntropy thresholding, and particle-based quantitative measurements.

This script is designed for reproducible image processing prior to downstream high-throughput analysis.


1. Features

This macro performs the following steps for PI image:
Resolution-aware background subtraction
Automatically detects whether the current image is 1920×1200 or 1920×1080
Subtracts the corresponding PI background image
Background exposure time & file naming are user-definable
RenyiEntropy thresholding
Converts to 8-bit
Applies pixel-intensity thresholding optimized for PI (dead/permeable cell signal)
Particle-based feature extraction
Uses ImageJ's built-in Analyze Particles
Outputs quantitative measurements (size, area, counts, etc.)
Results are summarized into the Results table
Automated batch processing
Processes all currently opened images
Skips background files automatically
Closes images after processing to ensure clean workflow


2. Required Input Files
You must prepare PI background images matching the resolutions used during acquisition.
Placeholders in the script:
background_1200 = "YOUR_PI_BACKGROUND_1920x1200.jpg";
background_1080 = "YOUR_PI_BACKGROUND_1920x1080.jpg";
Rename these to match actual background filenames before running the macro.

3. How It Works
The macro iterates through all opened image windows:

Step 1 — Identify resolution
w = getWidth();
h = getHeight();

Step 2 — Subtract matching background image
imageCalculator("Subtract create", currentImageTitle, background_1200);

Step 3 — Threshold (RenyiEntropy)
run("8-bit");
run("Auto Threshold", "method=RenyiEntropy white");

Step 4 — Particle analysis
run("Analyze Particles...", "summarize");

Step 5 — Output results

A summary table named Results will appear at the end.


4. How to Run
1) Open ImageJ or Fiji
2) Open all PI images you want to process
3) Open PI_preprocessing.ijm
4) Modify these lines to point to correct background images:
  background_1200 = "xxxx.jpg";
  background_1080 = "xxxx.jpg";
5) Run the macro


5. Output
The macro generates:
A Results table containing particle statistics for each PI image
One summary row per processed image
No intermediate images (result images are closed automatically)
Results include (depending on ImageJ settings): Count, Total Area, Average Size, %Area, Mean
%Area values are used downstream to compute Y-values (PI-derived viability/permeability metrics).

6. Notes
If the background images are not opened, the script will skip the affected images and print warnings.
Only PI images should be opened when running this macro (BF images are handled separately).
This macro performs primary feature extraction, not full HTS analysis.

7. Attribution
Image processing and feature extraction were performed using 
a custom FIJI/ImageJ macro written by Sujin Kim (PI_preprocessing.ijm).
