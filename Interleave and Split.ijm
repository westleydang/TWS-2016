/*
Aids the user in making the training.

Asks user to move 4-5 images to a folder
Gets the folder
Interleaves pairs
Interleaves pairs of pairs
Splits them by number of channels


*/

inputDirectory = getDirectory("What images do you want to feed me?");

// Get list of images
arrayFood = getFileList(inputDirectory);
arrayFood = excludeNonImages(arrayFood);
Array.print(arrayFood);
// Get number of images to food trainer
numberOfImages = lengthOf(arrayFood);

j=1;
// For each odd image, take the next image
for (i = 0; i < numberOfImages; i++) {
    // if odd (if counter is even):
    if (i % 2 == 0) {
        // Have to rename the files because the Interleave function
        // has trouble if the filenames start with the same word
        // and just interleves the image onto itself
        open(inputDirectory+arrayFood[i]);
        rename("stack_"+arrayFood[i]);
        open(inputDirectory+arrayFood[(i+1)]);
        rename("stack_"+arrayFood[(i+1)]);
        interleaveString = "stack=[stack_"+arrayFood[i]+"] stack=[stack_"+arrayFood[(i+1)]+"]";
        print(i +", "+ interleaveString);
        run("Interleave", interleaveString);
        selectWindow("Combined Stacks");
        rename("CS-"+j);
        j = j+1;
        openWindows = getListOpenWindows();
        Array.print(openWindows);

        // Close source files, keep the combined stack (CS)
        for (w = 0; w < lengthOf(openWindows); w++) {
            if (startsWith(openWindows[w], "CS-") == 0) {
                print(openWindows[w]);
                selectWindow(openWindows[w]);
                close();
            }
        }
    }
    else {}
}

run("Interleave", "stack=CS-1 stack=CS-2");
selectWindow("Combined Stacks");
run("Stack Splitter", "number=3");

print("==> END MACRO. ")

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

function getListOpenWindows() {
    list = newArray(nImages);
    for (i=0; i <nImages; i++) {
        selectImage(i+1);
        list[i] = getTitle();
    }
    return list;
}
