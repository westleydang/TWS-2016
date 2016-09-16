/*
- Reads the ROI as an array
- Parses the array into index and ROI label and file names
- reads according to the file names

*/

// I don't know why, but the ROI manager fucks up without an open image
newImage("Untitled", "8-bit black", 1, 1, 1);

// Ask user to select the folder of images to count
inputDirectory = getDirectory("Choose a Directory");
arrayFileList = getFileList(inputDirectory);
arrayFileList = removeNonImages(arrayFileList);

// Ask user to select the ROI
roiFilePath = File.openDialog("Choose the ROI set:");

// Load the ROI
roiManager("reset");
roiManager("open", roiFilePath);
selectWindow("Untitled");
close();


// User defined function roiAsArray() makes an array as big as the ROI manager
// then imports all the names to an array
arrayROIImportedNames = newArray(roiManager("count"));
arrayROIImportedNames = roiAsArray(arrayROIImportedNames);

resultsChannel = newArray();
resultsRegion = newArray();
resultsName = newArray();
resultsCount = newArray();
resultsFilename = "Measurements from "+getFormattedDate();

// For each image
for (eachImage = 0; eachImage < lengthOf(arrayFileList); eachImage++) {
    // Open each image
    open(inputDirectory+arrayFileList[eachImage]);
    // Check if the image has any corresponding ROIs in the entire array
    // Returns new array of non-skipped pointers
    crossrefTrue = getNonSkippedROI(arrayROIImportedNames);
    Array.print(crossrefTrue);

    // Count at that image for each ROI given by the index in crossref
    // For each non-skipped ROI
    for (i = 0; i < lengthOf(crossrefTrue); i++) {
        roiManager("Select", crossrefTrue[i]);
        print("ROI is "+Roi.getName());
        parsedName = split(Roi.getName(), "]]");
        Array.print(parsedName);
        // parsedName[0] should be the region
        // parsedName[1] should be the index
        // parsedName[2] should be the file name

        // For each slice
        for(slice = 0; slice < nSlices; slice++) {
            setSlice(slice+1);
            run("Measure");
            run("Find Maxima...", "noise=0 output=[Count]");
            resultsName = Array.concat(resultsName, parsedName[2]);
            resultsRegion = Array.concat(resultsRegion, parsedName[0]);
            resultsChannel = Array.concat(resultsChannel, (slice+1));
            resultsCount = Array.concat(resultsCount, getResult("Count"));
        }
    }
    selectWindow(arrayFileList[eachImage]);
    close();
    call("java.lang.System.gc"); // garbage collection cleans RAM
}

Array.show(resultsFilename, resultsName, resultsRegion, resultsChannel, resultsCount);
selectWindow(resultsFilename);
saveAs(resultsFilename, inputDirectory+resultsFilename+".csv");
close();

/* =====================================================
End of macro. Library of functions are below.
=======================================================*/
function getNonSkippedROI(roiList) {
    array = newArray();
    for (check = 0; check < lengthOf(roiList); check++) {
        // If yes, then make add to the list of ROIs to count
        print("file match " + endsWith(roiList[check], arrayFileList[eachImage]));
        print("skip " + startsWith(roiList[check], "SKIP"));

        if (endsWith(roiList[check], arrayFileList[eachImage]) == true
            && startsWith(roiList[check], "SKIP") == false) {
                array = Array.concat(array, check);
        }
    }
    return array;
}


function roiAsArray(array) {
    for (each = 0; each < roiManager("count"); each++) {
        roiManager("Select", each);
        array[each] = Roi.getName();
    }
    return array;
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


function closeAllImages() {
    list = getListOpenImages();
    for (i=0; i <nImages; i++) {
        selectImage(i+1);
        if (isImage(list[i]) == true) {
            close();
        }
    }
}

function getListOpenImages() {
    list = newArray(nImages);
    for (i=0; i <nImages; i++) {
        if (isImage(list[i]) == true) {
            selectImage(i+1);
            list[i] = getTitle();
        }
    }
    return list;
}
function getFormattedDate() {
	 getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
     MonthNames = newArray("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
     resultDate = ""+dayOfMonth+"-"+MonthNames[month]+"-"+year;
     return resultDate;
}
