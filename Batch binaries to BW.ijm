
// Get the Directory
toTransformDir = getDirectory("Choose a Directory");
// For some reason the open() fxn only works with the \ instead of /
toTransformDir = replace(toTransformDir,"\\","\\");
// Get the list of images
toTransformList = getFileList(toTransformDir);

// Create sister directory of the transformed images// at the parent level
outTransformDir = File.getParent(toTransformDir)+"\\"+File.getName(toTransformDir)+"-bw";
File.makeDirectory(outTransformDir);
print("*** Made this directory... "+outTransformDir);

setBatchMode(true);
// Run the macro for each images
// output the images to the subdirectory defined earlier
for (currentCaterpillar = 0; currentCaterpillar < toTransformList.length; currentCaterpillar++) {
  print("*** Opening file "+toTransformDir+toTransformList[currentCaterpillar]);
  open(toTransformDir+toTransformList[currentCaterpillar]+"");
  //run("Invert", "stack");
  run("8-bit");
  //run("Brightness/Contrast...");
  run("Enhance Contrast", "saturated=0.35");
  run("Apply LUT", "stack");
  selectWindow(toTransformList[currentCaterpillar]);
  print("*** Saving to... "+outTransformDir+"\\"+toTransformList[currentCaterpillar]);
  saveAs("tif", outTransformDir+"\\"+toTransformList[currentCaterpillar]);
  close();
}
