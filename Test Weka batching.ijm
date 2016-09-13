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


// Get input and output directory
// note: should ask user where you want it
// inputDirectory = "C:\\Users\\westley\\Desktop\\wdtest92\\";

// Ask user for directories
inputDirectory = getDirectory("Choose a Directory");
File.makeDirectory(inputDirectory+"\\Weka Output");
File.makeDirectory(inputDirectory+"\\Split Temp 1\\");
File.makeDirectory(inputDirectory+"\\Split Temp 2\\");
File.makeDirectory(inputDirectory+"\\Classifiers\\");
//outputDirectory = getDirectory("Choose a Directory");

// change the slashes the other way to avoid escaping
//inputDirectory = replace(inputDirectory, "\\", "/");
//outputDirectory = replace(outputDirectory, "\\", "/");

setBatchMode(false);
inputFileList = getFileList(inputDirectory);
inputFileList = excludeNonImages(inputFileList);

print("*****I sense "+inputFileList.length+" files");



// Run the TWS
// Ask user for the classifier, then load it
classifierArray = chooseClassifiers();
tempList1 = getFileList(inputDirectory+"\\Split Temp 1\\");
tempList1 = Array.sort(tempList1);



for (eachImage=0; eachImage < lengthOf(inputFileList); eachImage++) {
    splitAndSave(inputDirectory+inputFileList[eachImage]);

    newImage("Dummy", "8-bit black", 1,1,1);
    run("Trainable Weka Segmentation");
    for (eachSplit = 0; eachSplit < lengthOf(tempList1); eachSplit++) {
        print(classifierArray[eachSplit]);
        selectWindow("Trainable Weka Segmentation v3.1.0");
        call("trainableSegmentation.Weka_Segmentation.loadClassifier", classifierArray[eachSplit]);
        // Applies to image file from Split Temp 1 where the split files are
        // Stores in Split Temp 2
        print("Trying to apply... "+ tempList1[eachSplit]);
        call("trainableSegmentation.Weka_Segmentation.applyClassifier", inputDirectory+"\\Split Temp 1\\",
          tempList1[eachSplit], "showResults=false", "storeResults=true",
          "probabilityMaps=false", inputDirectory+"\\Split Temp 2");

        File.delete(inputDirectory+"\\Split Temp 1\\"+tempList1[eachSplit]);
        print("***    done classifying  "+ tempList1[eachSplit]);
    }
    restackImages();
}



/*
  selectWindow("Classification result");
  rename("result of "+inputFileList[currentFile]);
  selectWindow("\\"+inputFileList[currentFile]);
  close();
*/


print("*** DONE WITH MACRO");


function closeAllWindows() {
      while (nImages>0) {
          selectImage(nImages);
          close();
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


function restackImages() {
    tempArray2 = getFileList(inputDirectory+"\\Split Temp 2\\");
    Array.print(tempArray2);
    for (eachImage = 0; eachImage < lengthOf(tempArray2); eachImage++) {
        print(tempArray2[eachImage]);
        open(inputDirectory+"\\Split Temp 2\\"+tempArray2[eachImage]);
    }
    run("Images to Stack", "method=[Copy (center)] name=[og] title=slice000 use");
    selectWindow("og");

    // Parses out the original file name from the first sliced image
    origFilename = substring(tempArray2[0], 10, lengthOf(tempArray2[0]));
    saveAs("tif", inputDirectory+"\\Weka Output\\"+origFilename);
    close();
    for (eachImage = 0; eachImage < lengthOf(tempArray2); eachImage++) {
        File.delete(inputDirectory+"\\Split Temp 2\\"+tempArray2[eachImage]);
    }
}


function splitAndSave(img) {
    open(img);
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
        else {print("not a match"); }
    }
    closeAllWindows();
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
