// BF_preprocessing.ijm
// Author: Sujin Kim
// Created: 2025-09-26
// Last Modified: 2025-12-08
//  Description: Generic BF preprocessing pipeline template


// Get list of open images
imageTitles = getList("image.titles");

for (i = 0; i < imageTitles.length; i++) {
    title = imageTitles[i];
    selectImage(title);

    // Convert to 8-bit
    run("8-bit");
    run("Flatten");

    // Example: bandpass filter (customize ROI for your experiment)
    run("Bandpass Filter...", "filter_large=40 filter_small=3 suppress=None tolerance=5 autoscale");
    run("Select None");

    // Mask + particle analysis
    run("8-bit");
    setAutoThreshold("Default");
    setOption("BlackBackground", false);
    run("Convert to Mask");
    run("Analyze Particles...", "summarize");
}

// Show final table
if (isOpen("Results")) run("Show Results");
