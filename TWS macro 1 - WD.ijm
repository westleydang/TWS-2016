/*
@Author: Westley Dang
This macro uses the Trainable WEKA Segmentation plugin to create a
probability map of the cells, then uses that image to create masks
for each channel and counts the overlap.
*/

// Variables and constants, change these CAPITALIZED parameters to fit your image resolution and stuff
setBatchMode(false);
FILENAME = getInfo("image.filename"); // this is the original file name of the opened fileMASK_ENLARGE = 10; // this is how big your cell masks will be
MASK_MAXIMA = 50; // this is the noise tolerance for Finding Maxima
EXCLUSION_SIZE = 100; // everything under this many pixels is excluded in mask
EXCLUSION_CIRC = 0.30 // everything under this circularity is excluded in mask
OUTLIERS_SIZE = 5 // removing outliers
maskNameArray = newArray(nSlices)


// Open the TWS and make the probability map
// Batch all the images at once in one function
// Call the batch function with a command




// Process the probability map (PM)

// Open the image and dupilicate the slice so that only the
// dark-background image is in the slice. Close the orignal PM. Rename new PM.




// Duplicate the original PM; new working file is DuplicatePM, original file is the var filename
run("Duplicate...", "duplicate");
rename("DuplicatePM");

// Process the image binary
processImageBinary(OUTLIERS_SIZE, EXCLUSION_SIZE, EXCLUSION_CIRC);

// Create masks for each slice in the processed binary, passed with these mask parameters
createMasksForEachSlice(MASK_ENLARGE, MASK_MAXIMA);


// Concatenate all the masks to analyze for overlap, then save.
run("Concatenate...", "  title=[CombinedMasks] image1=Mask-1 image2=Mask-2 image3=Mask-3 create");

// Overlay the masks onto the orignial channels, then save.
//run("Concatenate...", "  title=[overlaid] image1=[all da masks] image2=["+filename+"]");
run("Merge Channels...", "  title=[OG and mask] c1=[CombinedMasks] c2=["+FILENAME+"] create");
rename("OG and mask");





/* =====================================================
End of macro. All functions defined below.
=======================================================*/


function processImageBinary(outliers, sizeExclusion, circExclusion) {
  // Binarize the PM.
  run("Make Binary", "method=Default background=Dark calculate black");

  // Clean the image by filling in the holes and removing noise.
  // this file is called "<filename>"
  run("Fill Holes", "stack");
  run("Dilate", "stack");
  run("Remove Outliers...", "radius=2 threshold=1 which=Bright stack");
  run("Dilate", "stack");
  run("Fill Holes", "stack");
  run("Erode", "stack");
  run("Remove Outliers...", "radius=5 threshold=1 which=Bright stack");
  run("Watershed", "stack");

  // Make new mask that excludes small and non circular particles
  // this file is called "Mask of <filename>"
  // note: variabilize the size and circularity
  run("Analyze Particles...", "size="+sizeExclusion+"-Infinity circularity="+circExclusion+"-1.00 show=Masks stack");
  run("Select None");
  run("Invert", "stack");

} // end function processImageBinary()


function createMasksForEachSlice(enlargeConstant, maximaConstant) {

  // Find maxima in the new mask, create one for each slice
  // note: variabilize the noise and enlargement variable for diff resolutions
  // note: new mask is called "Mask"
  for (currentSlice = 1; currentSlice < nSlices+1; currentSlice++) {
    selectWindow("Mask of DuplicatePM");
    print("on " + currentSlice);
    setSlice(currentSlice);
  	run("Select None");
    run("Find Maxima...", "noise="+maximaConstant+" output=[Point Selection]");
    run("Enlarge...", "enlarge="+enlargeConstant+"");
    run("Create Mask");
  	run("Watershed", "stack");
    rename("Mask-"+currentSlice+"");
    //maskNameArray[currentSlice-1] = "Mask-"+currentSlice+"";
    selectWindow("Mask of DuplicatePM");
  }
}
 // end function createMasksForEachSlice()
