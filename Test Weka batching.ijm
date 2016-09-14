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

// Ask the user to choose classifiers, save to array
classifierArray = chooseClassifiers();
print("Here are the classifiers: ");
Array.print(classifierArray);

for (eachImage=0; eachImage < lengthOf(inputFileList); eachImage++) {
    // Split the channels into sep images in subfolder
    print("split and saving.. "+ inputDirectory+inputFileList[eachImage]);
    splitAndSave(inputDirectory+inputFileList[eachImage]);

    tempList1 = getFileList(inputDirectory+"Split Temp 1");
    tempList1 = Array.sort(tempList1);
    print("Here is the tempList1: ");
    Array.print(tempList1);

    newImage("Dummy", "8-bit black", 1,1,1);
    run("Trainable Weka Segmentation");

    // For each channel/image , WEKA and then save each classified image
    for (eachSplit = 0; eachSplit < lengthOf(tempList1); eachSplit++) {
        print(classifierArray[eachSplit]);
        selectWindow("Trainable Weka Segmentation v3.1.0");
        // Load the appropriate classifier
        // classifierArray is sorted, and so is tempList1
        call("trainableSegmentation.Weka_Segmentation.loadClassifier", classifierArray[eachSplit]);

        // Applies to image file from Split Temp 1 where the split files are
        // Stores in Split Temp 2
        print("Trying to apply... "+ tempList1[eachSplit]);
        call("trainableSegmentation.Weka_Segmentation.applyClassifier",
            inputDirectory+"Split Temp 1", tempList1[eachSplit],
            "showResults=false", "storeResults=true","probabilityMaps=false",
            inputDirectory+"Split Temp 2");


        print("Deleting... "+ inputDirectory+"Split Temp 1\\"+tempList1[eachSplit]);
        File.delete(inputDirectory+"Split Temp 1\\"+tempList1[eachSplit]);
        print("***    done classifying  "+ tempList1[eachSplit]);
    }
    print("waiting 2000");
    wait(2000);

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
    tempArray2 = getFileList(inputDirectory+"Split Temp 2");
    print("here is tempArray2");
    Array.print(tempArray2);
    for (eachImage = 0; eachImage < lengthOf(tempArray2); eachImage++) {
        print(tempArray2[eachImage]);
        open(inputDirectory+"Split Temp 2\\"+tempArray2[eachImage]);
    }
    run("Images to Stack", "method=[Copy (center)] name=[og] title=slice000 use");
    selectWindow("og");

    // Parses out the original file name from the first sliced image
    origFilename = substring(tempArray2[0], 10, lengthOf(tempArray2[0]));
    saveAs("tif", inputDirectory+"Weka Output\\"+origFilename);
    close();
    for (eachImage = 0; eachImage < lengthOf(tempArray2); eachImage++) {
        File.delete(inputDirectory+"Split Temp 2\\"+tempArray2[eachImage]);
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
            saveAs("tif", inputDirectory+"Split Temp 1\\"+getTitle());
            print("found a match, saving");
            close();
        }
        else {print("not a match"); }
    }
    closeAllWindows();
    print("done split and save");
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
