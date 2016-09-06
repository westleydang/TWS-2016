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
  print("		Okay let's work on... " + inputFileList[currentFile]);  selectWindow("Trainable Weka Segmentation v3.1.0");  call("trainableSegmentation.Weka_Segmentation.applyClassifier", inputDirectory,    inputFileList[currentFile], "showResults=false", "storeResults=true",    "probabilityMaps=false", outputDirectory);  print("***    done classifying  "+ inputFileList[currentFile]);/*  selectWindow("Classification result");  rename("result of "+inputFileList[currentFile]);  selectWindow("\\"+inputFileList[currentFile]);  close();*/}
