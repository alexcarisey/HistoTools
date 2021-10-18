// --------------------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
// Script for the measurement of the segmented tissues from the pixel classifier --------------------------------
// tested with Fiji ImageJ 2.1.0/1.53c; Java 1.8.0_172 [64-bit] -------------------------------------------------
// 1.0 - 20201113 > initial version, Alex C [Hodia] -------------------------------------------------------------
// 2.0 - 2021015 > works in tandem with other script to create the human readable images from the classifier ----
// --------------- output files: class naming is now carried over to the analysis tables, measurement now -------
// --------------- performed on the segmented tissues instead of the RGB highlight frame, Alex C [Hodia] --------
// --------------------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------


macro "macro_measurement_classes" {

	// Precautionary measure

	requires("1.53c");

	// Initialise variables

	current_version_script = "v1.0";
	analysed_stuff = false;
	number_of_tif = 0;

	// User warning

	Dialog.create("Warning");
	Dialog.addMessage("Make sure your image files have a Region of Interest (ROI) drawn for measurement.");
	Dialog.show();

	// Input folder

	datapaths = getDirectory("Choose the folder containing the output files from the pixel classifier");

	// Create an array with the name of the files to convert

	filelist = getFileList(datapaths);
	number_of_files = lengthOf(filelist);
	fileextensionlist=newArray(filelist.length);

	// Create an array for the extensions of the files

	for (i=0; i<filelist.length; i++) {
		length_stack=lengthOf(filelist[i]);
		fileextensionlist[i]=substring(filelist[i],length_stack-4,length_stack); // 4 characters for .tif
	}

	// Count the number of files

	for (n=0; n<fileextensionlist.length; n++) {
		if (fileextensionlist[n] == ".tif") {
			number_of_tif = number_of_tif + 1;
		}
	}

	if (number_of_tif == 0) {
		exit("Duh! This folder doesn't contain a single valid tif file!");
	}

	// User GUI

	Dialog.create("Settings");
	Dialog.addMessage("Script for the measurement of the segmented tissues from the pixel classifier")
	Dialog.addMessage("Script " + current_version_script);
	Dialog.addMessage("Source: " + datapaths);
	Dialog.addMessage("Number of tif files detected: " + number_of_tif);
	Dialog.addMessage("The result spreadsheet will be saved in the same folder as the input data.");
	Dialog.show();

	// Enabling batch mode

	setBatchMode(false);
	
	// Enabling the full measurements panel options

	run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction stack limit display redirect=None decimal=3");

	// Loop on all tif files

	for (i=0; i<fileextensionlist.length; i++) {

		if (fileextensionlist[i] == ".tif") {

			// Update a variable to define a proper exit for of the macro in case no tif files are found

			analysed_stuff = true;

			// Paths and components of the file name

			file_path=datapaths+filelist[i];
			file_name=File.getName(file_path);
			file_path_length=lengthOf(file_path);
			file_name_length=lengthOf(file_name);
			file_dir=substring(file_path,0,file_path_length-file_name_length);
			file_shortname=substring(file_name,0,file_name_length-4); 	// 4 characters to get rid of the .tif

			// Import the file and rename window

			open(file_path);
			rename(file_shortname + "-class");
			setSlice("1");
			run("Duplicate...", "duplicate range=2");
			resetMinAndMax();
			run("8-bit");
			setThreshold(1, 255);
			run("Measure");
			close();
			selectWindow(file_shortname + "-class");
			setSlice("2");
			run("Duplicate...", "duplicate range=3");
			resetMinAndMax();
			run("8-bit");
			setThreshold(1, 255);
			run("Measure");
			close();
			setSlice("3");
			run("Duplicate...", "duplicate range=4");
			resetMinAndMax();
			run("8-bit");
			setThreshold(1, 255);
			run("Measure");
			close();
			
		}
	}

		
	// Create output file path and save the output image

		selectWindow("Results");
		output_path=datapaths+"Results.csv";
		saveAs("Results", output_path);
		close("*");

}