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

arrayFileList = getFileList(inputDirectory); // returns array
Array.print(arrayFileList);
// Remove non images from the array
arrayFileList = excludeNonImages(arrayFileList);
Array.print(arrayFileList);

run("ROI Manager...");
roiManager("reset");

arrayROIIndex = newArray(numberofROI * lengthOf(arrayFileList));
arrayROINames = newArray(numberofROI * lengthOf(arrayFileList));

for (eachImage = 0; eachImage < (lengthOf(arrayFileList)); eachImage++) {
    open(inputDirectory + arrayFileList[eachImage]);
    for (eachROI = 0; eachROI < numberofROI; eachROI++) {
      selectWindow(arrayFileList[eachImage]);
      run("Select None");
      setTool("polygon");

      waitForUser("Draw "+arrayROILabels[eachROI]+" -- then click OK");

      // because you can only select ROI by index:
      currentIndex = ((eachImage*numberofROI)+eachROI);
      // If no selection, then tag for skipping
      if (selectionType() == (-1)) {
        run("Select All");
        roiManager("Add");
        currentName = "SKIP"+"]]"+currentIndex+"]]"+arrayFileList[eachImage];
      }
      else {
        roiManager("Add");
        currentName = arrayROILabels[eachROI]+"]]"+currentIndex+"]]"+arrayFileList[eachImage];
      }
      // rename it as, ex: CA1]]i34]]filename
      roiManager("Select", currentIndex);
      roiManager("rename", currentName);
      arrayROIIndex[currentIndex] = currentIndex;
      arrayROINames[currentIndex] = currentName;
    } // finish for each ROI

    // save then close image
    roiManager("save", inputDirectory+getFormattedDate()+"_ROIset.zip");
    close(arrayFileList[eachImage]);
}
call("java.lang.System.gc"); // garbage collection cleans RAM

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


function getFormattedDate() {
	 getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
     MonthNames = newArray("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
     resultDate = ""+dayOfMonth+"-"+MonthNames[month]+"-"+year;
     return resultDate;
}
