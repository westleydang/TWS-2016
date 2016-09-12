/*
Trying to make the ROI stuff from KK's Code

1. Get the number of ROI
2. Get labels of ROI
3. Get directory
4. For each file in directory, open each image
5. For each image, draw each ROI
6. Finish
*/

inputDirectory = getDirectory("Choose a Directory");

// Get the number of ROI from user, then get labels for them
// and then set them to the array
numberofROI = askHowManyROI(); // returns numberofROI
arrayROILabels = newArray(numberofROI);
askForROILabels(arrayROILabels);

// Draw ROI for each image
drawROI();

/*
============================FUNCTION LIBRARIES BELOW============================
*/


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

function removeNonImages(array) {
  for (i = 0; i < lengthOf(array); i++) {
    // User-defined function: isImage(filename), checks if it's an image
    if (isImage(arrayFileList[i]) == false) {
      // Create two slices of the array flanking the desired removee
      concat1 = Array.slice(array, 0, i);
      concat2 = Array.slice(array, i+1, array.length);
      // Create a new array that excludes the removee
      array = Array.concat(concat1, concat2);
    }
  }
  return array;
} // returns the cleaned array

function askHowManyROI() {
  Dialog.create("ROI Setup");
  Dialog.addNumber("Number of ROIs to be Analyzed Per Image: ", 1);
  Dialog.show();
  input = Dialog.getNumber();
  return input;
}

function askForROILabels(a) {
  // Make dialog to get labels
  Dialog.create("ROI Labels");
	for (r = 0; r < numberofROI; r++) {
		Dialog.addString("ROI "+(r+1)+": ", "");
	}
  Dialog.show();
  // Get the labels, add to the array of names
	for (r = 0; r < numberofROI; r++) {
    // a is the arrayROILabels that was passed in
		a[r] = Dialog.getString();
	}
}


function drawROI() {
  arrayFileList = getFileList(inputDirectory); // returns array
  // Remove non images from the array
  arrayFileList = removeNonImages(arrayFileList);
  arrayROIIndex = newArray(numberofROI * lengthOf(arrayFileList));
  arrayROINames = newArray(numberofROI * lengthOf(arrayFileList));

  run("ROI Manager...");
  roiManager("reset");

  for (eachImage = 0; eachImage < (lengthOf(arrayFileList)); eachImage++) {
    // open the image
    open(inputDirectory+arrayFileList[eachImage]);

    print(File.getName(arrayFileList[eachImage]));
    print(File.getParent(arrayFileList[eachImage]));

    for (eachROI = 0; eachROI < numberofROI; eachROI++) {
      selectWindow(arrayFileList[eachImage]);
      run("Select None");
      setTool("polygon");

      waitForUser("Draw "+arrayROILabels[eachROI]+" -- then click OK");

      // because you can only select by index:
      currentIndex = ((eachImage*numberofROI)+eachROI);
      // If no selection, then tag for skipping
      if (selectionType() == (-1)) {
        run("Select All");
        roiManager("Add");
        currentName = "SKIP"+"_i"+currentIndex+"_"+arrayFileList[eachImage];
      }
      else {
        roiManager("Add");
        currentName = arrayROILabels[eachROI]+"_i"+currentIndex+"__"+arrayFileList[eachImage];
      }
      // rename it as, ex: CA1_i34_filename
      roiManager("Select", currentIndex);
      roiManager("rename", currentName);
      arrayROIIndex[currentIndex] = currentIndex;
      arrayROINames[currentIndex] = currentName;
    } // finish for each ROI

    // save then close image
    roiManager("save", inputDirectory+getFormattedDate()+"_ROIset.zip");
    close(arrayFileList[eachImage]);
  } // finish for each image

} // finish drawROI function

function getFormattedDate() {
	 getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
     MonthNames = newArray("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
     resultDate = ""+dayOfMonth+"-"+MonthNames[month]+"-"+year;
     return resultDate;
}
