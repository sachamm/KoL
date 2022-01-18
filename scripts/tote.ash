import <smmUtils.ash>
string __tote_version = "1.0";

/*
manipulate January's Garbage Tote.

Notes to myself:
you can always find any particular link you are looking for by using the cli 'debug trace on/off' commands.
Turn it on, click the link you want to capture, turn it off...then look in the TRACE log in your mafia folder for the link
tote => /use january's garbage tote;ashq visit_url("choice.php?whichchoice=1275&option=%%");
*/

void toteOutputHelp() {
	print("tote tree|bottle|tights|tape|shirt");
	print("tote offhand|item|ml|hat|stats");
	print("tote 1|2|3|4|5");
}

// can we do something with these args?
void verify_arguments(string arguments) {
	string [int] argv = split_string(arguments, " ");

	if (argv[0] == "tree" || argv[0] == "1" || argv[0] == "shield" || argv[0] == "offhand")
		return;
	if (argv[0] == "bottle" || argv[0] == "2" || argv[0] == "item")
		return;
	if (argv[0] == "tights" || argv[0] == "pants" || argv[0] == "3" || argv[0] == "ml")
		return;
	if (argv[0] == "tape" || argv[0] == "4" || argv[0] == "hat")
		return;
	if (argv[0] == "shirt" || argv[0] == "5" || argv[0] == "stats")
		return;
	abort("bad argument");
}

void main(string arguments) {
	//arguments = arguments.to_lower_case(); NO!
	string [int] argv = split_string(arguments, " ");
	print("tote v" + __tote_version);

	if (argv[0] == "help" || arguments == "") {
		toteOutputHelp();
        return;
	}

	verify_arguments(arguments);

	visit_url("/inv_use.php?pwd&which=3&whichitem=9690", true, false);

	if (argv[0] == "tree" || argv[0] == "1" || argv[0] == "shield" || argv[0] == "offhand") {
		run_choice(1);
		if (!isOverdrunk()) equip($item[deceased crimbo tree]);
	} else if (argv[0] == "bottle" || argv[0] == "2" || argv[0] == "item") {
		run_choice(2);
		if (!isOverdrunk()) equip($item[broken champagne bottle]);
	} else if (argv[0] == "tights" || argv[0] == "3" || argv[0] == "pants" || argv[0] == "ml") {
		run_choice(3);
		if (!isOverdrunk()) equip($item[tinsel tights]);
	} else if (argv[0] == "tape" || argv[0] == "4" || argv[0] == "hat") {
		run_choice(4);
		if (!isOverdrunk()) equip($item[wad of used tape]);
	} else if (argv[0] == "shirt" || argv[0] == "5" || argv[0] == "stats") {
		run_choice(5);
		if (!isOverdrunk()) equip($item[makeshift garbage shirt]);
	}
}


