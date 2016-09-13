

inputDirectory = getDirectory("Choose a Directory");
File.makeDirectory(inputDirectory+"\\Weka Output");
File.makeDirectory(inputDirectory+"\\Split Temps");

inputFileList = getFileList(inputDirectory);
inputFileList = excludeNonImages(inputFileList);

print("*****I sense "+inputFileList.length+" files");
splitAndSave();






function splitAndSave() {
    for (eachImage=0; eachImage < lengthOf(inputFileList); eachImage++) {
        open(inputFileList[eachImage]);
        run("Stack Splitter", "number="+nSlices); // outputs as slice000x_FILENAME
        listOpenImages = getListOpenImages();
        Array.print(listOpenImages);
        for (openImages=0; openImages < lengthOf(listOpenImages); openImages++) {
            selectWindow(listOpenImages[openImages]);
            print(listOpenImages[openImages]);
            if (startsWith(getTitle(), "slice000") == true) {
                saveAs("tif", inputDirectory+"\\Split Temps\\"+getTitle());
                print("found a match, saving");
                close();
            }
            else {print("not a match"); close();}
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
  for (i = 0; i < lengthOf(array); i++) {
    // User-defined function: isImage(filename), checks if it's an image
    if (isImage(array[i]) == false) {
      // Create two slices of the array flanking the desired removee
      concat1 = Array.slice(array, 0, i);
      concat2 = Array.slice(array, i+1, array.length);
      // Create a new array that excludes the removee
      array = Array.concat(concat1, concat2);
    }
  }
  return array;
} // returns the cleaned array
