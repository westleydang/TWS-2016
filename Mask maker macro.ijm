/*
@Author: Westley Dang
This macro uses the Trainable WEKA Segmentation plugin to create a
results of the cells locattion, then uses that image to create masks
for each channel and counts the overlap.
*/

// Variables and constants, change these CAPITALIZED parameters to fit your image resolution and stuff
setBatchMode(false);
MASK_ENLARGE = 4; // this is how big your cell masks will be
MASK_MAXIMA = 50; // this is the noise tolerance for Finding Maxima, this is irrelevant
EXCLUSION_RADIUS = 2; // this is how much to clean up in Remove Outliers
EXCLUSION_SIZE = 20; // everything under this many pixels is excluded in mask
EXCLUSION_CIRC = 0.00; // everything under this circularity is excluded in mask
//maskNameArray = newArray(nSlices);

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
    print("working on " + FILENAME + getFormattedTime());
    // Duplicate the original PM; new working file is DuplicatePM, original file is the var filename
    run("Duplicate...", "duplicate");
    rename("Duplicate");

    intersectedOG = createOriginalIntersection();

    // Process the image binary
    // results in "Mask of Binary_Duplicate"
    processedImg = processImageBinary(intersectedOG, EXCLUSION_RADIUS, EXCLUSION_SIZE, EXCLUSION_CIRC);

    // Create masks for each slice in the processed binary, passed with these mask parameters
    createMasksForEachSlice(processedImg, MASK_ENLARGE, MASK_MAXIMA);


    // Create mask intersection
    // intersect("Mask-2", "Mask-3");
    // rename("Mask-OL23");

    // Concatenate all the masks to analyze for overlap, then save.
    run("Concatenate...", "  title=[CombinedMasks] image1=Mask-1 image2=Mask-2 image3=Mask-3 image4=Mask-4 create");

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

    run("Merge Channels...", "  title=[Overlay] c1=[CombinedMasks] c2=["+processedImg+"] create");
    closeAllWindows();
}


/* =====================================================
End of macro. Library of functions are below.
=======================================================*/
function createOriginalIntersection() {
    selectWindow(FILENAME);
    run("Stack Splitter", "number="+nSlices);
    // images as slice000x_FILENAME

    intersect("slice0002_"+FILENAME, "slice0003_"+FILENAME);
    print("intersected 1");
    rename("sliceOL23_"+NAME_NO_EXT);
    run("Images to Stack", "method=[Copy (center)] name=[OG] title=slice use");
    print(getTitle()+" ...created at createOriginalIntersection. ");
    return getTitle();
}

function closeAllWindows() {
      while (nImages>0) {
          selectImage(nImages);
          close();
      }
  }

function processImageBinary(img, radiusExclusion, sizeExclusion, circExclusion) {
  // Binarize the image
  // Results in image called "Mask of Duplicate"
  selectWindow(img);
  run("Make Binary", "method=Default background=Dark calculate black");
  rename("Binary_Duplicate");

  // Clean the image by filling in the holes and removing noise.
  // this file is called "<filename>"
  run("Watershed", "stack");
  for (i=0; i<2; i++) {
      run("Remove Outliers...", "radius=1 threshold=1 which=Bright stack");
      run("Dilate", "stack");
      run("Fill Holes", "stack");
      run("Erode", "stack");
      run("Watershed", "stack");
  }
  run("Remove Outliers...", "radius="+radiusExclusion+" threshold=1 which=Bright stack");
  run("Dilate", "stack");
  run("Watershed", "stack");

  // Make new mask that excludes small and non circular particles
  // this file is called "Mask of <filename>"
  // note: variabilize the size and circularity
  run("Analyze Particles...", "size="+sizeExclusion+"-Infinity circularity="+circExclusion+"-1.00 show=Masks stack");
  run("Select None");
  //run("Invert", "stack");
  run("Invert LUT");
  print(getTitle()+" ...created at processImageBinary. ");
  return getTitle();
} // end function processImageBinary(), results in image "Mask of Binary_Duplicate"

function createMasksForEachSlice(img, enlargeConstant, maximaConstant) {
  // Find maxima in the new mask, create one for each slice
  // note: variabilize the noise and enlargement variable for diff resolutions
  // note: new mask is called "Mask"
  for (currentSlice = 1; currentSlice < nSlices+1; currentSlice++) {
    selectWindow(img);
    print("on " + currentSlice);
    setSlice(currentSlice);
  	run("Select None");
    run("Find Maxima...", "noise="+maximaConstant+" output=[Point Selection]");
    run("Enlarge...", "enlarge="+enlargeConstant+"");
    run("Create Mask"); // creates a new image with masks
  	run("Watershed", "stack");
    rename("Mask-"+currentSlice);
    //maskNameArray[currentSlice-1] = "Mask-"+currentSlice+"";
    selectWindow(img);
  }

} // end function of createMasksForEachSlice, results in 3 masks in images, NOT STACK

function intersect(ch1, ch2) {
  imageCalculator("AND create", ch1, ch2);
}

function saveWhatAsWhere(what, as, where) {
  selectWindow(what);
  saveAs(as, where);
}

// Tests whether the file is an image, returns boolean
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

// Takes file array, returns array of only the images
function excludeNonImages(array) {
  array2 = newArray();
  for (i = 0; i < lengthOf(array); i++) {
    // User-defined function: isImage(filename), checks if it's an image
    if (isImage(array[i]) == true) {
      concat1 = Array.slice(array, i, (i+1));
      array2 = Array.concat(array2, concat1);
    }
  }
  return array2;
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
