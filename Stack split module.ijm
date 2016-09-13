

inputDirectory = getDirectory("Choose a Directory");
File.makeDirectory(inputDirectory+"\\Weka Output");
File.makeDirectory(inputDirectory+"\\Split Temp 1\\");
File.makeDirectory(inputDirectory+"\\Split Temp 2\\");
File.makeDirectory(inputDirectory+"\\Classifiers\\");



inputFileList = getFileList(inputDirectory);
inputFileList = excludeNonImages(inputFileList);

print("*****I sense "+inputFileList.length+" files");
Array.print(inputFileList);

// classifierArray = chooseClassifiers(); // returns array of classifier paths


//splitAndSave();



//restackImages();

/*

*/







/*
go to the temp dir
get list of images
open them in order
combine them in order
output to the temp 2 directory
delete each file in list of images
*/
function restackImages() {
    tempArray1 = getFileList(inputDirectory+"\\Split Temp 1\\");
    Array.print(tempArray1);
    for (eachImage = 0; eachImage < lengthOf(tempArray1); eachImage++) {
        print(tempArray1[eachImage]);
        open(inputDirectory+"\\Split Temp 1\\"+tempArray1[eachImage]);
    }
    run("Images to Stack", "method=[Copy (center)] name=[og] title=slice000 use");
    selectWindow("og");

    // Parses out the original file name from the first sliced image
    origFilename = substring(tempArray1[0], 10, lengthOf(tempArray1[0]));
    saveAs("tif", inputDirectory+"\\Weka Output\\"+origFilename);
    close();
    for (eachImage = 0; eachImage < lengthOf(tempArray1); eachImage++) {
        File.delete(inputDirectory+"\\Split Temp 1\\"+tempArray1[eachImage]);
    }
}

function parseSlicePrefix(str) {
    split(str, "_")
}

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


function splitAndSave() {
    for (eachImage=0; eachImage < lengthOf(inputFileList); eachImage++) {
        print("Trying to open... "+inputFileList[eachImage]);
        open(inputFileList[eachImage]);
        run("Stack Splitter", "number="+nSlices); // outputs as slice000x_FILENAME
        listOpenImages = getListOpenImages();
        Array.print(listOpenImages);
        for (openImages=0; openImages < lengthOf(listOpenImages); openImages++) {
            selectWindow(listOpenImages[openImages]);
            print(listOpenImages[openImages]);
            if (startsWith(getTitle(), "slice000") == true) {
                saveAs("tif", inputDirectory+"\\Split Temp 1\\"+getTitle());
                print("found a match, saving");
                close();
            }
            else {print("not a match"); close();}
        }
    }
}

function getListOpenImages() {
    list = newArray(nImages);
    for (i=0; i <nImages; i++) {
        selectImage(i+1);
        list[i] = getTitle();
    }
    return list;
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
