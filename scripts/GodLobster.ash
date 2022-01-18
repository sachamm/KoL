import <smmUtils.ash>
string __godlobster_version = "0.9";


string GodLobsterHelpOutputMakeClickableCommand(string command, boolean confirm) {
	string confirm_string = "confirm+";
	if (!confirm) confirm_string = "";
	return "<strong style=\"color:blue;\"><a href=\"KoLmafia/sideCommand?cmd=GodLobster+" + confirm_string + command + "&pwd=" + my_hash() + "\">" + command + "</a></strong>";
}


void GodLobsterOutputHelp() {
	print_html("");
	print_html("<span style=\"font-size:1.5em;font-weight:bold;\">God Lobster</span>");
	print_html("<span style=\"font-family:Monospace;\">&gt; godlobster  &#91;<i>times</i>&#93; <i>command</i></span>");
	print_html("<span>where <i>times</i> is an optional number from 1-3 or '*' and <i>command</i> is one of: (click to execute)</span>");
    print_html(GodLobsterHelpOutputMakeClickableCommand("outfit", false) + ": wear default outfit for fighting the God Lobster.");
    print_html(GodLobsterHelpOutputMakeClickableCommand("combats", false) + ": combats used (of 3/day).");
    print_html(GodLobsterHelpOutputMakeClickableCommand("mp", true) + ": mp regen buff.");
    print_html(GodLobsterHelpOutputMakeClickableCommand("-combat", true) + ": get -combat buff.");
    print_html(GodLobsterHelpOutputMakeClickableCommand("+combat", true) + ": get +combat buff.");
    print_html(GodLobsterHelpOutputMakeClickableCommand("regalia", true) + ": get next regalia piece.");
    print_html(GodLobsterHelpOutputMakeClickableCommand("xp", true) + ": biggest xp possible (based on regalia).");
}



item best_regalia() {
	if (available_amount($item[God Lobster's Crown]) > 0)
		return $item[God Lobster's Crown];
	else if (available_amount($item[God Lobster's Robe]) > 0)
		return $item[God Lobster's Robe];
	else if (available_amount($item[God Lobster's Rod]) > 0)
		return $item[God Lobster's Rod];
	else if (available_amount($item[God Lobster's Ring]) > 0)
		return $item[God Lobster's Ring];
	else if (available_amount($item[God Lobster's Scepter]) > 0)
		return $item[God Lobster's Scepter];
	else
		return $item[none];
}



void dressupForGodLobster() {
	use_familiar($familiar[God Lobster]);
	maximize("exp, mainstat, effective, equip " + best_regalia(), false);
}


// can we do something with these args?
void verify_arguments(string [] argv) {
	string arguments = argv[0];
	if (arguments == "*" || arguments == "1" || arguments == "2" || arguments == "3")
		arguments = argv[1];

	if (arguments == "help" || arguments == "combats" || arguments == "outfit") {
		return;
    } else if (arguments == "mp" || arguments == "mp regen") {
		return;
	} else if (arguments == "regalia" || arguments == "equipment") {
		if (best_regalia() == $item[God Lobster's Crown])
			abort("Already have all regalia!");
		return;
    } else if (arguments == "xp" || arguments == "exp") {
		if (best_regalia() != $item[God Lobster's Crown])
			abort("Don't have all regalia!");
		return;
	} else if (arguments == "-combat") {
		if (!have_item($item[God Lobster's Ring]))
			abort("Don't have God Lobster's Ring -- run 'regalia' first");
		return;
	} else if (arguments == "+combat") {
		if (!have_item($item[God Lobster's Rod]))
			abort("Don't have God Lobster's Rod -- run 'regalia' first");
		return;
	}

	print("Bad arguments \"" + arguments + "\".");
	GodLobsterOutputHelp();
	exit;
}



void main(string arguments) {
	arguments = arguments.to_lower_case();
	string [] argv = split_string(arguments, " ");
	verify_arguments(argv);

	int combats_used = to_int(get_property("_godLobsterFights"));
	int times = 1;
	if (argv[0] == "*") {
		times = 3 - combats_used;
		arguments = argv[1];
	} else if (argv[0].is_integer()) {
		times = argv[0].to_int();
		arguments = argv[1];
	}

	print("GodLobster v" + __godlobster_version + " - command " + arguments + " " + times + " time(s)");

	if (arguments == "help" || arguments == "") {
		GodLobsterOutputHelp();
        return;
	}

	if (arguments.contains_text("confirm")) {
		if (!user_confirm(arguments + "?")) {
			print_html("Stopping.");
			return;
		}
	}

	// report available fights and return
	if (arguments.contains_text("combats")) {
		print_html("God Lobster combats used: " + combats_used);
		return;

	// dress for god lobster and return
	} else if (arguments.contains_text("outfit")) {
		dressupForGodLobster();
		return;
	}

	saveOutfit();
	try {
		dressupForGodLobster();

		while (times > 0) {
			healIfRequiredWithMPRestore();
			restore_mp(5 * mp_cost($skill[Saucegeyser]) + mp_cost($skill[Cannelloni Cocoon]) + mp_cost($skill[Tongue of the Walrus]));

			if (arguments == "regalia" || arguments == "equipment") {
				equip($slot[familiar], best_regalia());
				visit_url("/main.php?fightgodlobster=1", true, false);
	// 			run_combat("consult smmKoL_consult.ash");
				run_combat();
				visit_url("/main.php?fightgodlobster=1", true, false);
				run_choice(1);

			} else if (arguments == "mp" || arguments == "mp regen") {
				equip($slot[familiar], $item[none]);
				visit_url("/main.php?fightgodlobster=1", true, false);
	// 			run_combat("consult smmKoL_consult.ash");
				run_combat();
				visit_url("/main.php?fightgodlobster=1", true, false);
				run_choice(2);

			} else if (arguments == "-combat") {
				equip($slot[familiar], $item[God Lobster's Ring]);
				visit_url("/main.php?fightgodlobster=1", true, false);
	// 			run_combat("consult smmKoL_consult.ash");
				run_combat();
				visit_url("/main.php?fightgodlobster=1", true, false);
				run_choice(2);

			} else if (arguments == "+combat") {
				equip($slot[familiar], $item[God Lobster's Rod]);
				visit_url("/main.php?fightgodlobster=1", true, false);
	// 			run_combat("consult smmKoL_consult.ash");
				run_combat();
				visit_url("/main.php?fightgodlobster=1", true, false);
				run_choice(2);

			} else if (arguments == "xp" || arguments == "exp") {
				equip($slot[familiar], best_regalia());
				visit_url("/main.php?fightgodlobster=1", true, false);
	// 			run_combat("consult smmKoL_consult.ash");
				run_combat();
				visit_url("/main.php?fightgodlobster=1", true, false);
				run_choice(2);
			}

			assert(!inCombat(), "should be done combat at this point");
			assert(!handling_choice(), "should be done with the choice at this point");
			times--;
		}

	} finally {
		restoreOutfit(true);
	}
}


