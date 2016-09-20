/*
Make TWS batch a folder of images under the TWS

- get input directory for
- get output directory or make one
- ask classifier FOR EACH channel
- open image
- split image
- check if temp folder 1 exists
- if not then make temp folder 1
- name and save image to a temp folder 1
- get temp folder list of files
- for each channel
- open the image
- load corresponding classifier
- apply classifier
- output to secure output directory

*/

// Subdirectories names
SUBDIR_CLASSIFIERS = "Classifiers\\";
SUBDIR_TEMP1 = "Split Temp 1\\"; // where split channels are stored
SUBDIR_TEMP2 = "Split Temp 2\\"; // output for Weka on split channels
SUBDIR_FINALOUTPUT = "Weka Output\\"; // restacked Weka output

// Ask user for directories, make subdirectories
inputDirectory = getDirectory("Where are the images I'm working with?");
File.makeDirectory(inputDirectory+SUBDIR_CLASSIFIERS);
File.makeDirectory(inputDirectory+SUBDIR_TEMP1);
File.makeDirectory(inputDirectory+SUBDIR_TEMP2);
File.makeDirectory(inputDirectory+SUBDIR_FINALOUTPUT);

setBatchMode(true);
inputFileList = getFileList(inputDirectory);
inputFileList = excludeNonImages(inputFileList);

print("==>  I sense "+inputFileList.length+" files...");

// Ask the user to choose classifiers, save to array
classifierArray = chooseClassifiers();

newImage("Dummy", "8-bit black", 2,2,1);
run("Trainable Weka Segmentation");

for (eachImage=0; eachImage < lengthOf(inputFileList); eachImage++) {
    // Split the channels into sep images in subfolder
    print("==> Splitting and saving... "+ inputDirectory+inputFileList[eachImage]);
    splitAndSave(inputDirectory+inputFileList[eachImage], inputDirectory+SUBDIR_TEMP1);

    tempList1 = getFileList(inputDirectory+SUBDIR_TEMP1);
    // Sort to make sure the channels are in order with classifier
    tempList1 = Array.sort(tempList1);
    print("Here are the split channel images: ");
    Array.print(tempList1);

    // For each channel/image , WEKA and then save each classified image
    for (eachSplit = 0; eachSplit < lengthOf(tempList1); eachSplit++) {
        print("==> Here are the classifiers I will be using...");
        print(classifierArray[eachSplit]);
        selectWindow("Trainable Weka Segmentation v3.1.0");

        // Load the appropriate classifier
        call("trainableSegmentation.Weka_Segmentation.loadClassifier", classifierArray[eachSplit]);

        // Applies to image file from Split Temp 1 where the split files are
        // Stores in SUBDIR_TEMP2
        print("==> Trying to apply classifier... "+ tempList1[eachSplit]);
        call("trainableSegmentation.Weka_Segmentation.applyClassifier",
            inputDirectory+SUBDIR_TEMP1, tempList1[eachSplit],
            "showResults=false", "storeResults=true","probabilityMaps=false",
            inputDirectory+SUBDIR_TEMP2);
        // Deletes the temp channels because we don't need it any more
        print("==> Deleting... "+ inputDirectory+SUBDIR_TEMP1+tempList1[eachSplit]);
        File.delete(inputDirectory+SUBDIR_TEMP1+tempList1[eachSplit]);
        print("==> Finished classifying... "+ tempList1[eachSplit]);
        closeAllImages();
    }

    // restack images from input dir to output dir
    restackImages(inputDirectory+SUBDIR_TEMP2, inputDirectory+SUBDIR_FINALOUTPUT);
    call("java.lang.System.gc");
    call("java.lang.System.gc");
    call("java.lang.System.gc");
}
print("==> DONE WITH MACR0 at " + getFormattedTime);


/*
=============================== MACRO ENDS HERE ===============================
============================ FUNCTION LIBRARY BELOW ===========================
*/

// Takes image, splits channels and saves it to specified path
// Notice: Channels saved as slice000x_FILENAME.tif
function splitAndSave(img, toWhere) {
    open(img);
    run("Stack Splitter", "number="+nSlices); // outputs as slice000x_FILENAME
    listOpenImages = getListOpenImages();
    print("==> Listing open images.. ");
    Array.print(listOpenImages);
    for (openImages=0; openImages < lengthOf(listOpenImages); openImages++) {
        selectWindow(listOpenImages[openImages]);
        print(listOpenImages[openImages]);
        if (startsWith(getTitle(), "slice000") == true) {
            saveAs("tif", toWhere+getTitle());
            print("found a match, saving");
            close();
        }
        else {print("not a match");  }
    }
    print("done split and save");
}

// Takes directory where temp channels are split, recombines and then
// outputs to the specified output directory
function restackImages(fromWhere, toWhere) {
    tempArray2 = getFileList(fromWhere);
    print("here is tempArray2");
    Array.print(tempArray2);
    for (eachImage = 0; eachImage < lengthOf(tempArray2); eachImage++) {
        print(tempArray2[eachImage]);
        open(fromWhere+tempArray2[eachImage]);
    }
    run("Images to Stack", "method=[Copy (center)] name=[og] title=slice000 use");
    selectWindow("og");

    // Parses out the original file name from the first sliced image
    origFilename = substring(tempArray2[0], 10, lengthOf(tempArray2[0]));
    saveAs("tif", toWhere+origFilename);
    close();
    for (eachImage = 0; eachImage < lengthOf(tempArray2); eachImage++) {
        File.delete(fromWhere+tempArray2[eachImage]);
    }
}

// Asks user to choose classifiers
function chooseClassifiers() {
    Dialog.create("Step 1. ")
    Dialog.addNumber("How many channels? ", 3);
    Dialog.show();
    numberOfChannels = Dialog.getNumber();
    print(numberOfChannels + " channels");
    array = newArray(numberOfChannels);
    for (eachChannel = 0; eachChannel < numberOfChannels; eachChannel++) {
        array[eachChannel] = File.openDialog("Choose classifier for channel "+(eachChannel+1));
        print(array[eachChannel]);
    }
    return array;
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

function closeAllWindows() {
      while (nImages>0) {
          selectImage(nImages);
          close();
      }
  }

function getListOpenImages() {
    list = newArray();
    for (i=0; i < nImages; i++) {
        selectImage(i+1);
        t = getTitle();
        if (isImage(t) == true) {
            list = Array.concat(list, t);
        }
    }
    return list;
}

function closeAllImages() {
    list = getListOpenImages();
    for (i=0; i <nImages; i++) {
        selectImage(i+1);
        t = getTitle();
        if (isImage(t) == true) {
            close();
        }
    }
}

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
