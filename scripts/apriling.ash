script "apriling";
notify TQuilla;
since r26333;

import <smmUtils.ash>
string __apriling_version = "0.1";

/*
manipulate Apriling band helmet.

@author Sacha Mallais (TQuilla #2771003)
*/

void aprilingOutputHelp() {
	print("apriling help");
	print("apriling -combat|combat|+combat|drop|sax|tom|tuba|staff|piccolo|help");
	print("apriling 1|2|2|3|4|5|6|7|8");
	print("apriling lucky # also gets the sax");
}

// can we do something with these args?
void verify_arguments(string arguments) {
	string [int] argv = split_string(arguments, " ");

	if (argv[0] == "-combat" || argv[0] == "1")
		return;
	if (argv[0] == "combat" || argv[0] == "2" || argv[0] == "+combat")
		return;
	if (argv[0] == "drop" || argv[0] == "3")
		return;
	if (argv[0] == "sax" || argv[0] == "4" || argv[0] == "saxophone")
		return;
	if (argv[0] == "tom" || argv[0] == "5" || argv[0] == "drum")
		return;
	if (argv[0] == "tuba" || argv[0] == "6")
		return;
	if (argv[0] == "staff" || argv[0] == "7")
		return;
	if (argv[0] == "piccolo" || argv[0] == "8")
		return;
	if (argv[0] == "lucky")
		return;
	if (argv[0] == "worm" || argv[0] == "wormride")
		return;
	abort("bad argument");
}

void main(string arguments) {
	//arguments = arguments.to_lower_case(); NO!
	string [int] argv = split_string(arguments, " ");
	print("apriling v" + __apriling_version);

	if (argv[0] == "help" || arguments == "") {
		aprilingOutputHelp();
        return;
	}

	verify_arguments(arguments);

    switch (argv[0]) {
        case "1":
        case "-combat":
            visit_url("/inventory.php?pwd&action=apriling", true, false);
            run_choice(1);
            run_choice(9);
            break;
        case "2":
        case "combat":
        case "+combat":
            visit_url("/inventory.php?pwd&action=apriling", true, false);
            run_choice(2);
            run_choice(9);
            break;
        case "3":
        case "drop":
            visit_url("/inventory.php?pwd&action=apriling", true, false);
            run_choice(3);
            run_choice(9);
            break;
        case "4":
        case "sax":
        case "saxophone":
            visit_url("/inventory.php?pwd&action=apriling", true, false);
            run_choice(4);
            run_choice(9);
            break;
        case "5":
        case "tom":
        case "drum":
            visit_url("/inventory.php?pwd&action=apriling", true, false);
            run_choice(5);
            run_choice(9);
            break;
        case "6":
        case "tuba":
            visit_url("/inventory.php?pwd&action=apriling", true, false);
            run_choice(6);
            run_choice(9);
            break;
        case "7":
        case "staff":
            visit_url("/inventory.php?pwd&action=apriling", true, false);
            run_choice(7);
            run_choice(9);
            break;
        case "8":
        case "piccolo":
            visit_url("/inventory.php?pwd&action=apriling", true, false);
            run_choice(8);
            run_choice(9);
            break;
        case "lucky":
            if ("_aprilBandSaxophoneUses".get_property().to_int() < 3 && have_effect($effect[Lucky!]) == 0) {
                if (!have_item($item[Apriling band saxophone])) {
                    print("Getting sax");
                    cli_execute("apriling sax");
                }
                assert(have_item($item[Apriling band saxophone]), "Failed to get sax");

                string page = visit_url('inventory.php?pwd=' + my_hash() + '&iid=11566&action=aprilplay', false, false);
                if (have_effect($effect[Lucky!]) == 0) {
                    print_html(page);
                    abort("Failed to get lucky");
                }
            } else if (have_effect($effect[Lucky!]) > 0) {
                print("You already have the lucky effect.");
            } else
                print("Already used the Apriling band saxophone 3 times today!");
            break;
        case "worm":
        case "wormride":
            if ("_aprilBandTomUses".get_property().to_int() < 3) {
                if (!have_item($item[Apriling band quad tom])) {
                    print("Getting tom");
                    cli_execute("apriling tom");
                }
                assert(have_item($item[Apriling band quad tom]), "Failed to get Apriling band quad tom");

                string page = visit_url('inventory.php?pwd=' + my_hash() + '&iid=11567&action=aprilplay', false, false);
                visit_url("/main.php", true, false); // get to the combat
                run_combat();
            } else {
                print("Already used the Apriling band tom drum 3 times today!");
            }
            break;
        default:
            abort("bad argument");
    }
}
