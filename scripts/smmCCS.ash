


// -------------------------------------
// CUSTOM COMBAT MACROS / CUSTOM COMBAT SCRIPTS / CCS
// -------------------------------------

// pickpocket if able, do it twice in case we fail the first time and have a 2nd attempt
// not having a second attempt won't mess anything up
void pickpocket() {
	visit_url("/fight.php?action=steal", true, false);
	visit_url("/fight.php?action=steal", true, false);
}

string setup_aborts_sub() {
	string rval = " ";

	if (my_class() == $class[seal clubber])
		rval += "abort missed 3;abort pastround 15;abort hppercentbelow 33;";
	else if (my_class() == $class[turtle tamer])
		rval += "abort missed 7;abort pastround 20;abort hppercentbelow 20;";
	else if (my_class() == $class[pastamancer])
		rval += "abort mpbelow 26;abort missed 2;abort pastround 15;abort hppercentbelow 50;";
	else if (my_class() == $class[sauceror])
		rval += "abort mpbelow 26;abort missed 2;abort pastround 15;abort hppercentbelow 50;";
	else if (my_class() == $class[disco bandit])
		rval += "abort missed 2;abort pastround 25;abort hppercentbelow 25;";
	else if (my_class() == $class[accordion thief])
		rval += "abort missed 3;abort pastround 15;abort hppercentbelow 33;";

	return rval;
}

string pickpocket_sub() {
	string [] no_pp_monsters = { // this doesn't make a lot of sense in this context, would work better as part of a consult script
		"beefy bodyguard bat",
		"sabre-toothed lime",
		"dairy ooze"
	};
	string [] lta_no_pp_monsters = {
		"minion",
		"Number Five",
		"Mr. Huge",
		"May Jones"
	};
	string rval;

// 	rval = "if ";
// 	string joinString = "";
// 	foreach mon in no_pp_monsters {
// 		rval += joinString + "!monstername \"" + no_pp_monsters[mon] + "\"";
// 		if (joinString == "") joinString = " || ";
// 	}

	rval += "pickpocket;";
	if (my_class() == $class[disco bandit] && is_wearing_outfit("Bling of the New Wave"))
		rval += "pickpocket;"; // second try
// 	rval += "endif;";
	return rval;
}

string items_sub() {
	string rval = "sub doItems;use Time-Spinner;skill micrometeorite;";
	if (have_item($item[beehive]) && have_item($item[rock band flyers])) rval += "use rock band flyers, beehive;";
	else if (have_item($item[beehive])) rval += "use beehive;";
	else if (have_item($item[rock band flyers])) rval += "use rock band flyers;";
	rval += "endsub;\n";
	return rval;
}

string rave_combo_sub(int combo_number) {
	string rval = "sub rave_" + rave_combo_map[combo_number] + ";";
	string combo_string = get_property("raveCombo" + combo_number);
	buffer combo_buffer = replace_string(combo_string, ",", "; skill ");
	rval += "skill " + combo_buffer + ";endsub;";
	return rval;
}

string default_rave_combo_set_sub() {
	// steal, item, meat, stats
	return rave_combo_sub(5) + rave_combo_sub(1) + rave_combo_sub(2) + rave_combo_sub(6);
}

string class_stun_sub() {
	string rval = "sub doClassStun;";

	if (my_class() == $class[seal clubber])
		rval += "";
	else if (my_class() == $class[turtle tamer])
		rval += "";
	else if (my_class() == $class[pastamancer])
		rval += "";
	else if (my_class() == $class[sauceror])
		rval += "";
	else if (my_class() == $class[disco bandit]) {
	}
	else if (my_class() == $class[accordion thief]) {
		rval += "if hasskill Accordion Bash;skill Accordion Bash;endif;";
	}

	rval += "endsub;";
	return rval;
}

string class_skills_sub() {
	string rval = "sub doClassSkills;";

	if (my_class() == $class[seal clubber])
		rval += "";
	else if (my_class() == $class[turtle tamer])
		rval += "";
	else if (my_class() == $class[pastamancer])
		rval += "";
	else if (my_class() == $class[sauceror])
		rval += "";
	else if (my_class() == $class[disco bandit]) {
		if (have_skill($skill[Disco Dance of Doom])) rval += "skill disco dance of doom;";
		if (have_skill($skill[Disco Dance II: Electric Boogaloo])) rval += "skill Disco Dance II: Electric Boogaloo;";
		if (have_skill($skill[Disco Dance 3: Back in the Habit])) rval += "skill Disco Dance 3: Back in the Habit;";
		if (have_skill($skill[pop and lock it]) && have_skill($skill[break it on down]) && have_skill($skill[run like the wind])) {
			rval = default_rave_combo_set_sub() + rval;
			//rval += "combo Rave Steal;combo Rave Concentration;combo Rave Nirvana;combo Rave Stats;";
			rval += "call rave_steal;call rave_item;call rave_meat;call rave_stats;";
		}
	}
	else if (my_class() == $class[accordion thief]) {
		rval += "if hasskill steal accordion;skill steal accordion;endif;if hasskill Cadenza;skill Cadenza;endif;";
	}

	rval += "endsub;";
	return rval;
}

string init_sub() {
	string rval = pickpocket_sub() + items_sub() + class_stun_sub() + class_skills_sub() + "sub init;call doItems;call doClassStun;";
	if (my_familiar() == $familiar[space jellyfish]) rval += "skill extract jelly;";
	if (have_skill($skill[sing along])) rval += "skill sing along;";
	if (have_skill($skill[a new habit])) rval += "skill a new habit;";
	rval += "call doClassSkills; endsub;";
	return rval;
}

string hit_sub() {
	string rval = "sub hit;";
	if (my_primestat() == $stat[muscle])
		rval += "attack;";
	else if (my_primestat() == $stat[mysticality])
		rval += "skill saucestorm;";
	else if (my_primestat() == $stat[moxie])
		rval += "attack;";
	rval += "endsub;";
	return rval;
}

string big_hit_sub() {
	string rval = "sub big_hit;";
	if (my_primestat() == $stat[muscle])
		rval += "skill lunging thrust-smack;";
	else if (my_primestat() == $stat[mysticality])
		rval += "skill saucegeyser;";
	else if (my_primestat() == $stat[moxie])
		rval += "skill saucegeyser;";
	rval += "endsub;";
	return rval;
}

string heal_sub() {
	return "sub heal;if hppercentbelow 80 && !muscleclass && hasskill saucy salve;if !times 2;skill saucy salve;call heal;endif;endif;if hascombatitem anti-anti-antidote;if haseffect Hardly Poisoned at All || haseffect A Little Bit Poisoned || haseffect Somewhat Poisoned || haseffect Really Quite Poisoned || haseffect Majorly Poisoned;use anti-anti-antidote;endif;endif;endsub;";
}

string main_sub() {
	return hit_sub() + heal_sub() + "sub main;call heal;call hit;endsub;";
}

string big_main_sub() {
	return big_hit_sub() + heal_sub() + "sub big_main;call heal;call big_hit;endsub;";
}

string default_sub() {
	return main_sub() + init_sub() + setup_aborts_sub() + "call init;call main;repeat;";
}

string big_default_sub() {
	return big_main_sub() + init_sub() + setup_aborts_sub() + "call init;call big_main;repeat;";
}



