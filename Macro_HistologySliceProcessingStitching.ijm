// ----------------------------------------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------------------------------------
// ------ Script for the following operations: illumination correction, name change, resize and stitching ---------------
// ------ tested with Fiji ImageJ 2.1.0/1.53c; Java 1.8.0_172 [64-bit] --------------------------------------------------
// ------ 1.0 - 20201021 > initial version, Alex C [Hodia] --------------------------------------------------------------
// ------ 1.1 - 20210207 > coefficient illumination correction are now automatically calculated, Alex C [Hodia] ---------
// ------ 1.2 - 20210426 > recursive data processing, Alex C [Hodia] ----------------------------------------------------
// ------ 1.3 - 20210429 > bug fix: memory leak specific to RGB outputs, Alex C [Hodia] ---------------------------------
// ------ 1.4 - 20210530 > automatic stiching, self correction, Alex C [Hodia] ------------------------------------------
// ------ 1.5 - 20210611 > new folder structure for processing, automatic white balance correction, Alex C [Hodia] ------
// ------ 1.6 - 20210809 > minor bug fixes, Alex C [Hodia] --------------------------------------------------------------
// ----------------------------------------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------------------------------------


// Precautionary measure

requires("1.53c");

// Warning

Dialog.create("New version - Warning");
Dialog.addMessage("-------------------------------------------------------------------");
Dialog.addMessage("WARNING");
Dialog.addMessage("This new version of the script requires the data");
Dialog.addMessage("to be stored in subfolders (one per slide).");
Dialog.addMessage("-------------------------------------------------------------------");
Dialog.show();

// Initialise variables and going dark

var current_version_script = "1.6";
var save_array = newArray("Next to each source folder","Somewhere else");
var scalevalue = 0.5;
var gui_extension_output = "-processed";
var gui_extension_stitched = "-stitched";
var gui_extension_corrected = "-corrected";
var gui_extension_snapshot = "-snapshot";
var extension_trim = 8; // 8 characters is suitable for .ome.tif extensions
var characters_trim = 0;
var filename = "";
var nb_files_for_backgroundidentification = 21;
var k1_c1 = "";
var k1_c2 = "";
var k1_c3 = "";
var nb_folders = 0;
var inputparentdir = "";
var inputdir = "";
var outputdir = "";
var folder_count = 0;
var file_count = 0;
var foldername_list = newArray(999); // Maximum number of folders to analyze at once

setBatchMode(false);

// Main GUI

Dialog.create("Data processing script for tissue imaging");
Dialog.addMessage("Tissue slide processing script v" + current_version_script);
Dialog.addMessage("-----------------------------------------------------------------------------------------------");
Dialog.addMessage("IMAGE CORRECTION");
Dialog.addCheckbox("Perform illumination correction", true);
Dialog.addNumber("Number of tiles to use to infer background", nb_files_for_backgroundidentification);
Dialog.addCheckbox("Perform white balance correction", true);
Dialog.addCheckbox("Resize every tile", true);
Dialog.addNumber("Scaling factor", scalevalue);
Dialog.addMessage("-----------------------------------------------------------------------------------------------");
Dialog.addMessage("TILE STITCHING");
Dialog.addCheckbox("Stitch the tiles together", true);
Dialog.addCheckbox("Create an RGB image", true);
Dialog.addCheckbox("Create a small snapshot image of the final image", true);
Dialog.addCheckbox("Keep the intermediate files", false);
Dialog.addMessage("-----------------------------------------------------------------------------------------------");
Dialog.addMessage("OPTIONS");
Dialog.addCheckbox("Filename trimming for output files?", true);
Dialog.addNumber("Extension length to remove", extension_trim);
Dialog.addNumber("Characters to trim from end", characters_trim);
Dialog.addCheckbox("Add sequential order at the end of filename", false);
Dialog.addMessage("-----------------------------------------------------------------------------------------------");
Dialog.addChoice("Save output", save_array, "Next to each source folder");
Dialog.addString("Extension for processed images:", gui_extension_output, 20);
Dialog.addString("Extension for stitched image:", gui_extension_stitched, 20);
Dialog.addString("Extension for white balance corrected:", gui_extension_corrected, 20);
Dialog.addString("Extension for snapshot:", gui_extension_snapshot, 20);
Dialog.addMessage("");
Dialog.show();

// Storing variables from the GUI

choice_illuminationcorrection = Dialog.getCheckbox();
nb_files_for_backgroundidentification = Dialog.getNumber();
choice_whitebalance = Dialog.getCheckbox();
choice_resize = Dialog.getCheckbox();
scalevalue = Dialog.getNumber();

choice_stitching = Dialog.getCheckbox();
choice_rgboutput = Dialog.getCheckbox();
choice_smallsnapshot = Dialog.getCheckbox();
choice_keepintermediates = Dialog.getCheckbox();

choice_trimming = Dialog.getCheckbox();
extension_trim = Dialog.getNumber();
characters_trim = Dialog.getNumber();
choice_sequentialorder = Dialog.getCheckbox();

gui_saving_location_choice = Dialog.getChoice();
gui_extension_output = Dialog.getString();
gui_extension_stitched = Dialog.getString();
gui_extension_corrected = Dialog.getString();
gui_extension_snapshot = Dialog.getString();

// Input folder selection

Dialog.create("Input folder");
Dialog.addMessage("Choose the directory containing the folders (1 for each slide).");
Dialog.show();
inputdir = getDirectory("Choose the directory containing the folders");

// Output folder selection

if(gui_saving_location_choice == "Somewhere else") {
	Dialog.create("Output folder");
	Dialog.addMessage("Choose where to save the data in the next dialog box.");
	Dialog.show();
	outputdir=getDirectory("Choose the save folder");
}

if (gui_saving_location_choice == "Next to each source folder") {
	outputdir = inputdir;
}

// Print feedback for the log and list/store all the folders contained in the main directory

print("Tissue slide processing script v" + current_version_script);
print("--------------------------------------------------");
print("");
print("Input directory: "+inputdir);
print("Output directory: "+outputdir);
print("");
print("--------------------------------------------------");
print("");
print("List of folders detected:");
countFolders(inputdir,file_count,folder_count);
print("---> "+file_count+" files to process for "+folder_count+" slide(s).");
print("");
print("--------------------------------------------------");
print("");

// User warning

Dialog.create("File count");
Dialog.addMessage("Everything is ready: " + file_count + " files will be processed.");
Dialog.addMessage("Make sure you have enough available space on the destination drive.");
Dialog.show();

// Main processing sequence

for (i=0; i<foldername_list.length; i++) {
	path = inputdir+foldername_list[i];
	fileHandler(path);
	
		
	//close("stack_in_progress");
	//close("stack_in_progress (RGB)");
	
	
	
	print(foldername_list[i]+" has been processed - Correction coefficients: " + k1_c1 + ", "  + k1_c2 + ", "  + k1_c3 + "."); // Log entry at the end of every slide/folder

	clear path;
		
}



// Final log entry

print(count+" files have been processed.");
print("Script over.");

// --------------------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
// ---- Functions in use in this document -----------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------

// Progress bar implementation


// This function counts the number of folders (aka slides) contained in the main source directory, and the total number of files to process
function countFolders(inputdir,file_count,folder_count) {
	list = getFileList(inputdir);
	for (i=0; i<list.length; i++) {
		if (endsWith(list[i], "/")) {
			countFolders(""+inputdir+list[i]);
			folder_count++;
			foldername_list[i] = replace(list[i],"/","");
			print(" ~ "+foldername_list[i]);
			}
		else
			file_count++;
	}
	return foldername_list;
	return file_count;
	return folder_count;
}

// I need to implement a step to create a temporary folder for every single raw data folder/slide. Something like that should work and I could delete it later on:
function createTemporaryFolder(filename,i,gui_extension_output) {
	temporary_folder_name = filename[i]+gui_extension_output+'-temp'+File.separator;
	File.makeDirectory(temporary_folder_name);
	if (!File.exists(temporary_folder_name))
		exit("Unable to create directory");
	print(temporary_folder_name);
}

// This function creates 'file_path' as path+file_list[j] to load individual tif files and starts processFile() function on each
function fileHandler(path) {
	file_list = getFileList(path);
	for (j=0; j<file_list.length; j++) {
		//showProgress(n++, count);
		file_path = path+file_list[j];
		processFile(file_path,file_list,gui_extension_output);
		close("stack_in_progress");
		close("stack_in_progress (RGB)");
	}
}

// This function is the core of the script for each tif file, subcalling all the others tile-specific functions depending on GUI user inputs
function processFile(file_path,file_list,gui_extension_output) {
	if (choice_illuminationcorrection) {
		generateIlluminationCorrectionBackground();						// This function is implemented.
	}
	if (endsWith(file_path, ".tif")) {
		filename = file_list[i];
		open(file_path);
		selectWindow(filename);
		rename("stack_in_progress");
		if (choice_illuminationcorrection) {							// This function is implemented.
			illuminationCorrection();
		}
		if (choice_resize) {											// This function is implemented.
			resizeTile();
		}
		if (choice_trimming) {											// This function is implemented.
			filenameTrimming();
		}
		if (choice_sequentialorder) {									// This function is implemented.
			changeFilenameSequential();
		}
		if (choice_rgboutput) {											// This function is implemented.
			transformToRGB();
		}
		savepathprocessedtile=outputdir+foldername_list+gui_extension_output+"/"+filename+gui_extension_output+".tif";
 		saveAs("Tiff", savepathprocessedtile);
		close("stack_in_progress");
	}
}

// This function is the core of the script for each slide folder, subcalling all the others slide-specific functions depending on GUI user inputs
function processFileBatch(file_path) {
		if (choice_stitching) {											//
			stitchingSlide(gui_extension_stitched);
		}
		if (choice_whitebalance) {										// This function has been implemented.
			whiteBalance(gui_extension_corrected);
		}
		if (choice_smallsnapshot) {										// This function has been implemented.
			makeSnapshot(gui_extension_snapshot);
		}
		if (choice_keepintermediates) {									// This function has been implemented.
			deleteInterimFiles();
		}
		savepathprocessedslide=outputdir+foldername_list+gui_extension_output+"/"+filename+gui_extension_output+".tif";
 		saveAs("Tiff", savepathprocessedslide);
		close("slide_in_progress");
}

// New function to convert the RGB multi channel image into an RGB merged output for ICE
function transformToRGB() {
	run("RGB Color");
}

// This function generates a background template for illumination correction
function generateIlluminationCorrectionBackground(inputdir,file_list,i) {
	for (l=0; l<nb_files_for_backgroundidentification; l++) {
	open(inputdir+File.separator+file_list[l])
	}
	run("Images to Stack", "name=BackgroundStack title=[] use");
	run("Z Project...", "projection=Median");
	selectWindow("BackgroundStack"); close();
	selectWindow("MED_BackgroundStack");
	run("RGB Stack"); 
	savepathbackgroundimage = inputdir+file_list[i]+"_background.tif";
	saveAs("Tiff", savepathbackgroundimage);
	selectWindow("MED_BackgroundStack");
	run("Stack to Images");
	selectWindow("Red"); rename("red_illumination_correction"); k1_c1 = getValue("Mode");
	selectWindow("Green"); rename("green_illumination_correction"); k1_c2 = getValue("Mode");
	selectWindow("Blue"); rename("blue_illumination_correction"); k1_c3 = getValue("Mode");
	print("Correction coefficients calculated for this image are:");
	print("Coefficient RED", k1_c1);
	print("Coefficient GREEN", k1_c2);
	print("Coefficient BLUE", k1_c3);
}

// This function performs the calculation for illumination correction, it requires openBackgroundIllumination to be done before
function illuminationCorrection() {
	selectWindow("stack_in_progress");
	run("Make Composite"); // This is necessary to prevent the first image from splitting into "stack_in_progress (green)" instead of C1-stack_in_progress
	run("Split Channels");
	run("Calculator Plus", "i1=C1-stack_in_progress i2=red_illumination_correction operation=[Divide: i2 = (i1/i2) x k1 + k2] k1="+k1_c1+" k2=0 create");
	selectWindow("Result");
	ic_c1="Red-corrected";
	rename(ic_c1);
	close("C1-stack_in_progress");
	run("Calculator Plus", "i1=C2-stack_in_progress i2=green_illumination_correction operation=[Divide: i2 = (i1/i2) x k1 + k2] k1="+k1_c2+" k2=0 create");
	selectWindow("Result");
	ic_c2="Green-corrected";
	rename(ic_c2);
	close("C2-stack_in_progress");
	run("Calculator Plus", "i1=C3-stack_in_progress i2=blue_illumination_correction operation=[Divide: i2 = (i1/i2) x k1 + k2] k1="+k1_c3+" k2=0 create");
	selectWindow("Result");
	ic_c3="Blue-corrected";
	rename(ic_c3);
	close("C3-stack_in_progress");
	run("Merge Channels...", "c1=Red-corrected c2=Green-corrected c3=Blue-corrected create ignore");
	selectWindow("Composite");
	rename("stack_in_progress");
}

// This function trimms the filename in order the remove long extension or meaningless characters or number sequence
function filenameTrimming() {
	filename = list[i];
	filename_length = lengthOf(filename);
	filename_short = substring(filename,0,filename_length-extension_trim);
	filename_short_length = lengthOf(filename_short);
	filename = substring(filename_short,0,filename_short_length-characters_trim);
}

// This function adds at the end of the filename a series of sequential digits
function changeFilenameSequential() {
	padding_value="";
	if (i <= 9) { padding_value = "0000"; }
	if (i >= 10 && i <= 99) { padding_value="000"; }
	if (i >= 100 && i <= 999) { padding_value="00"; }
	if (i >= 1000 && i <= 9999) { padding_value="0"; }
	if (i >= 10000 && i <= 99999) { padding_value=""; }
	filename = filename + "_" + padding_value + i;
}

// This function resizes each image
function resizeTile() {
	selectWindow("stack_in_progress");
	run("Scale...", "x=0.5 y=0.5 width=1376 height=1096 interpolation=Bilinear average create title=stack_resized.tif");
	close("stack_in_progress");
	selectWindow("stack_resized.tif");
	rename("stack_in_progress");
}

// This function performs the stitching following the defaults settings from the LeicaHisto scope (hard code your settings below if necessary)
function stitchingSlide(gui_extension_stitched) {
/* Steps to implement:
	- Stitching
		- identify the file name with {xxx} and {yyy} indices (prob using string=replace(string,"\\[_Pos000-000_\\]","_Pos{xxx}-{yyy}_"))
		- make it an RGB if needed
		- save the final image
 */
}

// This function performs a white balance on the stitched tile (and uses the illumination correction blank to work)
function whiteBalance(gui_extension_corrected) {
	val = newArray(3);
	selectWindow("Red"); run("Measure"); val[0] = getResult("Mean");
	selectWindow("Green"); run("Measure"); val[1] = getResult("Mean");
	selectWindow("Blue"); run("Measure"); val[2] = getResult("Mean");
	selectWindow("slide_in_progress");
	run("Make Composite");
	run("Select None"); run("16-bit"); run("32-bit");
	Array.getStatistics(val, min, max, mean);
	for (s=1; s<=3; s++) {
		setSlice(s);
		dR = val[s-1] - mean;
		if (dR < 0) {
			run("Add...", "slice value="+ abs(dR));
		} else if (dR > 0) {
			run("Subtract...", "slice value="+ abs(dR));
		}
	}
	run("16-bit");
	run("RGB Color");
}

// This function creates a small (very small) snapshot of the full slide for easy browsing purpose
function makeSnapshot(gui_extension_snapshot) {
	run("Scale...", "x=0.05 y=0.05 interpolation=Bilinear average create");
	savepathsnapshot=outputdir+foldername_list+gui_extension_output+"/"+filename+gui_extension_output+".tif";
 	saveAs("Tiff", savepathsnapshot);
	close();
}

// This function allows the user to delete the intermediate files created during processing (huge space saver!)
function deleteInterimFiles() {
	templist = getFileList(temporary_folder_name);
	for (y=0; y<templist.length; y++) {
		File.delete(temp+templist[y]);
	}
	File.delete(temporary_folder_name);
	if (File.exists(temporary_folder_name))
		exit("Unable to delete directory");
	else
		print("Directory and files successfully deleted");
}

// Final message within the status bar
showStatus("The macro has finished to process your files.");

// --------------------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
// ---- Functions not currently in use in this document ---------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------

// This function lists the name of every file
function listFiles(inputdir) {
	list = getFileList(inputdir);
	for (i=0; i<list.length; i++) {
		if (endsWith(list[i], "/"))
		listFiles(""+inputdir+list[i]);
		else
		print((count++) + ": " + inputdir + list[i]);
	}
}