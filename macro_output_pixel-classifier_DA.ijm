// --------------------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
// Script for the following operation: formatting the 4x3 channels from the PxClass. into readable images -------
// tested with Fiji ImageJ 2.1.0/1.53c; Java 1.8.0_172 [64-bit] -------------------------------------------------
// 1.0 - 20201111 > initial version, Alex C [Hodia] -------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------

macro "macro_output_pixel-classifier_DA" {

	// Precautionary measure

	requires("1.53c");

	// Initialise variables

	current_version_script = "v1.0";
	save_array = newArray("In the source folder","Somewhere else");
	analysed_stuff = false;
	decision = 1;
	class_names_array = newArray("Raw data","Tumor","Parenchyma","Normal Bronchi");

	// Input folder

	datapaths = getDirectory("Choose the folder containing the output from the pixel classifier");

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

	number_of_tif = 0;
	for (n=0; n<fileextensionlist.length; n++) {
		if (fileextensionlist[n] == ".tif") {
			number_of_tif = number_of_tif + 1;
		}
	}

	if (number_of_tif == 0) {
		exit("Duh! This folder doesn't contain a single valid tif file!");
	}

	// Main GUI

	Dialog.create("Preparation of output files from Aivia's pixel classifier");
	Dialog.addMessage("Script " + current_version_script);
	Dialog.addMessage("");
	Dialog.addMessage("Source: " + datapaths);
	Dialog.addMessage("Number of tif files: " + number_of_tif);
	Dialog.addMessage("");
	Dialog.addString("             Frame 1 label (ignored)", class_names_array[0], "Raw data");
	Dialog.addString("             Frame 2 class label", class_names_array[1], "Tumor");
	Dialog.addString("             Frame 3 class label", class_names_array[2], "Parenchyma");
	Dialog.addString("             Frame 4 class label", class_names_array[3], "Normal Bronchi");
	Dialog.addMessage("");
	Dialog.addChoice("Save output", save_array, "Somewhere else");
	Dialog.addString("Extension for filtered outputs:", "pc", 25);
	Dialog.addMessage("");
	Dialog.show();
	gui_saving_location_choice = Dialog.getChoice();
	class_names_array[0] = Dialog.getString();
	class_names_array[1] = Dialog.getString();
	class_names_array[2] = Dialog.getString();
	class_names_array[3] = Dialog.getString();
	gui_extension_output = Dialog.getString();


	// Enabling batch mode (no display)

	setBatchMode(false);

	// Localise or create the output folder

	if(gui_saving_location_choice == "In the source folder") {
		output_dir=datapaths;
	}
	
	if(gui_saving_location_choice == "Somewhere else") {
		if (decision ==1) {
			output_dir=getDirectory("Choose the save folder");
			decision++;
		}
	}

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

			run("Bio-Formats Importer", "open=["+ file_path + "] view=[Hyperstack] stack_order=Default");

			// Resize the stack to a more manageable preview size (1/16th of the size of the original)

			rename("original_stack");
			run("Scale...", "x=0.25 y=0.25 interpolation=Bilinear average create title=new_stack");
			close("original_stack");

			// Data handling
			
			run("Stack to Images");
			run("Merge Channels...", "c1=new_stack-0001 c2=new_stack-0002 c3=new_stack-0003 ignore");
			selectWindow("RGB");
			rename(class_names_array[0]);
			run("Merge Channels...", "c1=new_stack-0004 c2=new_stack-0005 c3=new_stack-0006 ignore");
			selectWindow("RGB");
			rename(class_names_array[1]);
			run("Merge Channels...", "c1=new_stack-0007 c2=new_stack-0008 c3=new_stack-0009 ignore");
			selectWindow("RGB");
			rename(class_names_array[2]);
			run("Merge Channels...", "c1=new_stack-0010 c2=new_stack-0011 c3=new_stack-0012 ignore");
			selectWindow("RGB");
			rename(class_names_array[3]);
			
			selectWindow(class_names_array[1]);
			run("Duplicate...", " ");
			run("8-bit");
			selectWindow(class_names_array[1]+"-1");
			run("Blue");
			rename("Blue");
			
			selectWindow(class_names_array[2]);
			run("Duplicate...", " ");
			run("8-bit");
			selectWindow(class_names_array[2]+"-1");
			run("Green");
			rename("Green");
			
			selectWindow(class_names_array[3]);
			run("Duplicate...", " ");
			run("8-bit");
			selectWindow(class_names_array[3]+"-1");
			run("Red");
			rename("Red");
			
			run("Merge Channels...", "c1=Red c2=Green c3=Blue create ignore");
			selectWindow("Composite");
			run("RGB Color");
			selectWindow("Composite");
			close();
			run("Images to Stack", "name=Stack-Output-Classifier title=[] use keep");
			new_window_name=file_shortname + "_"  + gui_extension_output;
			selectWindow("Stack-Output-Classifier"); rename(new_window_name);

			// Create output file path and save the output image

			output_path=output_dir+new_window_name+".tif";
			save(output_path);
			close("*");

			}

	}

}