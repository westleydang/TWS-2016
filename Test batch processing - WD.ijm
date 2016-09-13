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
File.makeDirectory(inputDirectory+"\\Split Temps");
//outputDirectory = getDirectory("Choose a Directory");

// change the slashes the other way to avoid escaping
//inputDirectory = replace(inputDirectory, "\\", "/");
//outputDirectory = replace(outputDirectory, "\\", "/");

setBatchMode(false);
inputFileList = getFileList(inputDirectory);
inputFileList = excludeNonImages(inputFileList);

print("*****I sense "+inputFileList.length+" files");



// Run the TWS
newImage("Dummy", "8-bit black", 1,1,1);
run("Trainable Weka Segmentation");
// Ask user for the classifier, then load it

  classifier = replace(File.openDialog("Choose the classifier"), "\\", "/");
  print(classifier);
  call("trainableSegmentation.Weka_Segmentation.loadClassifier", classifier);

for (currentFile = 0; currentFile < inputFileList.length; currentFile++) {
  selectWindow("Trainable Weka Segmentation v3.1.0");  call("trainableSegmentation.Weka_Segmentation.applyClassifier", inputDirectory,    inputFileList[currentFile], "showResults=false", "storeResults=true",    "probabilityMaps=false", outputDirectory);  print("***    done classifying  "+ inputFileList[currentFile]);/*  selectWindow("Classification result");  rename("result of "+inputFileList[currentFile]);  selectWindow("\\"+inputFileList[currentFile]);  close();*/}

print("*** DONE WITH MACRO");







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
