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
arrayFileList = excludeNonImages(arrayFileList);

Array.print(arrayFileList);
// Ask user to select the ROI
roiFilePath = File.openDialog("Choose the ROI set:");

// Load the ROI
roiManager("reset");
roiManager("open", roiFilePath);


// User defined function roiAsArray() makes an array as big as the ROI manager
// then imports all the names to an array
arrayROIImportedNames = newArray(roiManager("count"));
arrayROIImportedNames = roiAsArray(arrayROIImportedNames);

resultsChannel = newArray();
resultsRegion = newArray();
resultsName = newArray();
resultsCount = newArray();
resultsFilename = "Measurements from "+getFormattedDate();

setBatchMode(true);
// For each image
for (eachImage = 0; eachImage < lengthOf(arrayFileList); eachImage++) {
    print("==> On image... "+arrayFileList[eachImage]);
    // For the specified image passed in, check if the
    // image has any corresponding ROIs in the entire array,
    // then eturns new array of non-skipped pointers
    crossrefTrue = getNonSkippedROI(arrayFileList[eachImage], arrayROIImportedNames);
    print("==> Here is array crossrefTrue:");
    Array.print(crossrefTrue);

    // Count at that image for each ROI given by the index in crossrefTrue
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
            run("Find Maxima...", "noise=1 output=[Count]");
            resultsName = Array.concat(resultsName, parsedName[2]);
            resultsRegion = Array.concat(resultsRegion, parsedName[0]);
            resultsChannel = Array.concat(resultsChannel, (slice+1));
            resultsCount = Array.concat(resultsCount, getResult("Count"));
            print(parsedName[2]);
            print(parsedName[0]);
            print((slice+1));
            print(getResult("Count"));
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

/*
Passes in the array of ROI names, and then crossreferences the passed image
to find the ROI names that correspond to that image. Then checks for which
regions to skip, and then returns an array of all the non-skipped regions.
*/

function getNonSkippedROI(img, roiList) {
    array = newArray();
    // Open the image
    open(inputDirectory+img);
    for (check = 0; check < lengthOf(roiList); check++) {
        // If yes, then make add to the list of ROIs to count
        print("==> Assessing file: "+img);
        parse1 = split(img, "]]");
        print("file match " + endsWith(roiList[check], parse1[lengthOf(parse1)-1]));
        print(parse1[lengthOf(parse1)-1]);
        print(roiList[check]);
        print("skip " + startsWith(roiList[check], "SKIP"));

        if (endsWith(roiList[check], parse1[lengthOf(parse1)-1]) == true
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
