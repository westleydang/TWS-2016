/*
@Author: Westley Dang
This macro uses the Trainable WEKA Segmentation plugin to create a
results of the cells locattion, then uses that image to create masks
for each channel and counts the overlap.
*/

// Variables and constants, change these CAPITALIZED parameters to fit your image resolution and stuff
setBatchMode(true);
MASK_ENLARGE = 5; // this is how big your cell masks will be
MASK_MAXIMA = 50; // this is the noise tolerance for Finding Maxima
EXCLUSION_SIZE = 40; // everything under this many pixels is excluded in mask
EXCLUSION_CIRC = 0.30; // everything under this circularity is excluded in mask
OUTLIERS_SIZE = 4; // removing outliers
//maskNameArray = newArray(nSlices);


// Open the TWS and make the probability map
// Batch all the images at once in one function
// Call the batch function with a command


inputDirectory = getDirectory("Select your folder of images");
inputFileList = getFileList(inputDirectory);
inputFileList = excludeNonImages(inputFileList);

for (eachImage = 0; eachImage < lengthOf(inputFileList); eachImage++) {
    call("java.lang.System.gc"); // garbage collection cleans RAM
    open(inputFileList[eachImage]);
    FILENAME = getInfo("image.filename"); // this is the original file name of the opened file
    NAME_NO_EXT = File.nameWithoutExtension; // file name without extension
    doTheThing();
}


function doTheThing() {
    print("working on " + FILENAME) + getFormattedTime();
    // Duplicate the original PM; new working file is DuplicatePM, original file is the var filename
    run("Duplicate...", "duplicate");
    rename("Duplicate");

    // Process the image binary
    // results in Binary_Duplicate
    processImageBinary(OUTLIERS_SIZE, EXCLUSION_SIZE, EXCLUSION_CIRC);

    // Create masks for each slice in the processed binary, passed with these mask parameters
    createMasksForEachSlice(MASK_ENLARGE, MASK_MAXIMA);


    // Create new original intersection
    selectWindow(FILENAME);
    run("Stack Splitter", "number="+nSlices);
    // images as slice000x_FILENAME

    intersect("slice0002_"+FILENAME, "slice0003_"+FILENAME);
    print("intersected 1");
    rename("sliceOL23_"+NAME_NO_EXT);
    run("Images to Stack", "method=[Copy (center)] name=[OG] title=slice use");

    // Create mask intersection
    intersect("Mask-2", "Mask-3");
    rename("Mask-OL23");

    // Concatenate all the masks to analyze for overlap, then save.
    run("Concatenate...", "  title=[CombinedMasks] image1=Mask-1 image2=Mask-2 image3=Mask-3 image4=Mask-OL23 create");

    // save the real channel masks to compare to the original image
    selectWindow("CombinedMasks");
    run("Duplicate...", "duplicate");
    rename("CombinedMasksDuplicate");
    setSlice(4);
    run("Delete Slice");
    selectWindow(FILENAME);
    saveWhatAsWhere("CombinedMasksDuplicate", "tif", getInfo("image.directory")+"\\toCompareToOrig_"+FILENAME);
    close();

    // save all the masks into one file
    selectWindow("CombinedMasks");
    run("Duplicate...", "duplicate");
    rename("CombinedMasksDuplicate");
    selectWindow(FILENAME); // you have to select this otherwise you can't grab the image directory
    saveWhatAsWhere("CombinedMasksDuplicate", "tif", getInfo("image.directory")+"\\allMasks_"+FILENAME);
    close();

    // Save the combined masks
    selectWindow("CombinedMasks");

    // Overlay the masks onto the orignial channels, then save.
    //run("Concatenate...", "  title=[overlaid] image1=[all da masks] image2=["+filename+"]");

    run("Merge Channels...", "  title=[Overlay] c1=[CombinedMasks] c2=[OG] create");
    closeAllWindows();

}



function closeAllWindows() {
      while (nImages>0) {
          selectImage(nImages);
          close();
      }
  }


/* =====================================================
End of macro. Library of functions are below.
=======================================================*/


function processImageBinary(outliers, sizeExclusion, circExclusion) {

  // check if Binary

  // Binarize the PM.
  // Results in image called "Mask of DuplicatePM"
  run("Make Binary", "method=Default background=Dark calculate black");
  rename("Binary_Duplicate");

  // Clean the image by filling in the holes and removing noise.
  // this file is called "<filename>"
  run("Dilate", "stack");
  run("Fill Holes", "stack");
  // run("Remove Outliers...", "radius=2 threshold=1 which=Bright stack");
  // run("Dilate", "stack");
  // run("Fill Holes", "stack");
  // run("Erode", "stack");
  run("Remove Outliers...", "radius=5 threshold=1 which=Bright stack");
  run("Watershed", "stack");

  // Make new mask that excludes small and non circular particles
  // this file is called "Mask of <filename>"
  // note: variabilize the size and circularity
  run("Analyze Particles...", "size="+sizeExclusion+"-Infinity circularity="+circExclusion+"-1.00 show=Masks stack");
  run("Select None");
  run("Invert", "stack");
} // end function processImageBinary(), results in image "Binary_Duplicate"


function createMasksForEachSlice(enlargeConstant, maximaConstant) {

  // Find maxima in the new mask, create one for each slice
  // note: variabilize the noise and enlargement variable for diff resolutions
  // note: new mask is called "Mask"
  for (currentSlice = 1; currentSlice < nSlices+1; currentSlice++) {
    selectWindow("Mask of Binary_Duplicate");
    print("on " + currentSlice);
    setSlice(currentSlice);
  	run("Select None");
    run("Find Maxima...", "noise="+maximaConstant+" output=[Point Selection]");
    run("Enlarge...", "enlarge="+enlargeConstant+"");
    run("Create Mask"); // creates a new image with masks
  	run("Watershed", "stack");
    rename("Mask-"+currentSlice);
    //maskNameArray[currentSlice-1] = "Mask-"+currentSlice+"";
    selectWindow("Mask of Binary_Duplicate");
  }

} // end function of createMasksForEachSlice, results in 3 masks in images, NOT STACK



function intersect(ch1, ch2) {
  imageCalculator("AND create", ch1, ch2);
}


function saveWhatAsWhere(what, as, where) {
  selectWindow(what);
  saveAs(as, where);
}


function isImage(filename) {
 extensions = newArray("tif", "tiff", "jpg", "bmp");
 result = false;
 for (i=0; i<extensions.length; i++) {
   if (endsWith(toLowerCase(filename), "." + extensions[i])) {
     result = true;
   }
 }
 return result;
}

function excludeNonImages(array) {
  for (i = 0; i < lengthOf(array); i++) {
    // User-defined function: isImage(filename), checks if it's an image
    if (isImage(array[i]) == false) {
      // Create two slices of the array flanking the desired removee
      concat1 = Array.slice(array, 0, i);
      concat2 = Array.slice(array, i+1, array.length);
      // Create a new array that excludes the removee
      array = Array.concat(concat1, concat2);
    }
  }
  return array;
} // returns the cleaned array


function getFormattedTime() {
   getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
   TimeString = "\nTime: ";
   if (hour<10) {TimeString = TimeString+"0";}
   TimeString = TimeString+hour+":";
   if (minute<10) {TimeString = TimeString+"0";}
   TimeString = TimeString+minute+":";
   if (second<10) {TimeString = TimeString+"0";}
   TimeString = TimeString+second;
   return TimeString;
}
