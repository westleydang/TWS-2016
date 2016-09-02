/*

Make TWS batch a folder of images under the TWS
*/


// Get input and output directory
// note: should ask user where you want it
// inputDirectory = "C:\\Users\\westley\\Desktop\\wdtest92\\";

// Ask user for directories
inputDirectory = getDirectory("Choose a Directory");
outputDirectory = getDirectory("Choose a Directory");

// change the slashes the other way to avoid escaping
inputDirectory = replace(inputDirectory, "\\", "/");
outputDirectory = replace(outputDirectory, "\\", "/");

setBatchMode(false);
inputFileList = getFileList(inputDirectory);
print("*****I sense "+inputFileList.length+" files");

// Run the TWS
run("Trainable Weka Segmentation");
// Ask user for the classifier, then load it

  classifier = replace(File.openDialog("Choose the classifier"), "\\", "/");
  print(classifier);
  call("trainableSegmentation.Weka_Segmentation.loadClassifier", classifier);

for (currentFile = 0; currentFile < inputFileList.length; currentFile++) {
  print("Okay let's work on... "+inputFileList[currentFile]);