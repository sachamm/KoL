script "diet-data";
notify TQuilla;
since r27065;

import <smmUtils.ash>
string __diet-data_version = "0.1";

/**

@author Sacha Mallais (TQuilla #2771003)
*/



void printHelp() {
}



void main(string arguments) {
	string [] argv = split_string(arguments, " ");

	// PROCESS ARGS: help and version
	if (count(argv) == 1 && argv[0] == "version") {
		print("diet-data v" + __diet-data_version);
		return;
	} else if (argv[0] == "" || argv[0] == "help") {
		printHelp();
		return;
	}

	buffer daData = "diet_consumables = [\n";

	foreach it in consumables() {
		daData.append("   { \"name\": \"" + it + "\", \"advmin\": 0, \"advmax\": 0, \"price\": 200, \"type\": \"spleen\", \"size\": [0, 0, 1] }\n");
	}

	daData.append("]\nvar semirare_value=" + luckyValue() + "\n");
}


