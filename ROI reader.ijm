/*
- Reads the ROI as an array
- Parses the array into index and ROI label and file names
- reads according to the file names

All ROI names are formatted as:
ROI label _i index __ filename

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
// User defined function roiAsArray() makes an array as big as the ROI manager
// then imports all the names to an array
arrayROIImportedNames = newArray(roiManager("count"));
arrayROIImportedNames = roiAsArray(arrayROIImportedNames);


for (eachImage = 0; eachImage < lengthOf(arrayFileList); eachImage++) {
    // Open each image
    open(inputDirectory+arrayFileList[eachImage]);
    crossref = newArray();
    // Check if the image has any corresponding ROIs in the entire array
    for (check = 0; check < lengthOf(arrayROIImportedNames); check++) {
        // If yes, then make add to the list of ROIs to count
        print("ends " + endsWith(arrayROIImportedNames[check], arrayFileList[eachImage]));
        print("starts " + startsWith(arrayROIImportedNames[check], "SKIP"));

        if (endsWith(arrayROIImportedNames[check], arrayFileList[eachImage]) == true
            && startsWith(arrayROIImportedNames[check], "SKIP") == false) {
                crossref = Array.concat(crossref, check);
        }
    }
    Array.print(crossref);
    // Count at that image for each ROI given by the index at crossref
    for (applicableROI = 0; applicableROI < lengthOf(crossref); applicableROI++) {
        roiManager("Select", crossref[applicableROI]);
        run("Measure");
    }
    // Save to the results
    tableName = "" ;
    run("New... ", "name="+tableName+" type=Table");
    print(tableName, "\\Headings:[File Name]	[ROI]	[ROI Area]	[Ch1 Count]	[Ch2 Count]	[Ch3 Count]	[Ch2-3 OL Count]");

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
