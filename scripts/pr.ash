script "pr";
notify TQuilla;
since r26718;

import <smmAutomation.ash>;

/**
Grind PirateRealm

"pr help" in the CLI for help

@author Sacha Mallais (TQuilla #2771003)
*/


item goalItem = $item[Red Roger's reliquary];
string __pr_version = "0.1";
string gkPirateRealmDoneKey = "_smm.PirateRealmDone";


void printHelp() {
	print_html("<h2>pr</h2>");
	print_html("<br>Grind PirateRealm (PR).</br>");
}



// return true if stats are ok for PR adventures
boolean prVerifyStats() {
	assert(equipped_amount($item[Red Roger's red left foot]) == 0 || equipped_amount($item[Red Roger's red right foot]) == 0, "prVerifyStats: should never wear both of Red Roger's red feet");

	if (equipped_amount($item[PirateRealm eyepatch]) == 0 || (equipped_amount($item[Red Roger's red left foot]) == 0 && equipped_amount($item[Red Roger's red right foot]) == 0)) return false;

	if (my_buffedstat($stat[muscle]) > 100) return false;
	if (my_buffedstat($stat[mysticality]) > 100) return false;
	if (my_buffedstat($stat[moxie]) > 100) return false;

	boolean dressedForLand = equipped_amount($item[Red Roger's red left foot]) > 0;
	if (my_maxhp() < 150 && dressedForLand) return false;
	return true;
}


// finagle things so that all buffed stats are below 101
// PR party hat gives more fun points; Red Roger's red left hand gives +100% item in PR;
// Red Roger's red right hand gives +50 dmg in PR (island-only???);
// Red Roger's red right foot for sailing and Red Roger's red left foot for island
void prDressup(boolean isSea, int numAdventures) {
    print("dressing up for PR, isSea=" + isSea + ", numAdventures=" + numAdventures + "...", "green");
    assert(have_item($item[PirateRealm eyepatch]), "You need a PirateRealm eyepatch to grind PirateRealm.");

    // if we're already dressed up and everything works, don't change anything
    // if we're switching from land to sea or vice versa, make sure to re-maximize
    if (equipped_amount($item[PirateRealm eyepatch]) >= 1 && prVerifyStats()) {
        if (isSea && equipped_amount($item[Red Roger's red left foot]) >= 1) {
            unequip($item[Red Roger's red left foot]);
            equip($item[Red Roger's red right foot]);
        } else if (!isSea && equipped_amount($item[Red Roger's red right foot]) >= 1) {
            unequip($item[Red Roger's red right foot]);
            equip($item[Red Roger's red left foot]);
        } else // we didn't change anything
	        if (prVerifyStats())
    	        return;
    }

    // we don't want more than 100 mp because our stats are going to be very constrained
	burnMP(-100);

	location prLoc = isSea ? $location[PirateRealm Island] : $location[Sailing the PirateRealm Seas];

    // start by equipping the eyepatch and seeing how much we need to adjust our stats
    if (equipped_amount($item[PirateRealm eyepatch]) < 1)
        equip($item[PirateRealm eyepatch]);
	int musOverage = my_buffedstat($stat[muscle]) - 100;
    int mysOverage = my_buffedstat($stat[mysticality]) - 100;
    int moxOverage = my_buffedstat($stat[moxie]) - 100;
    float mus_mod = (musOverage > 0) ? min(-musOverage, 20) : -1;
    float mys_mod = (mysOverage > 0) ? min(-mysOverage * 2, 20) : -1; // mys is uniquely difficult to lower
    float mox_mod = (moxOverage > 0) ? min(-moxOverage, 20) : -1;
    float hp_mod = 10;

    int tries = 5;
	string maxString;
	repeat {
		string selector = "mp regen";
		string famSelector = "default";
		if (isSea) {
			// 10 mp stops the wristwatch bug from happening
			maxString = (have_item($item[PirateRealm eyepatch]) ? "equip PirateRealm eyepatch, " : "") + "10 mp, equip PirateRealm party hat, equip Red Roger's red left hand, "
			    + "equip Red Roger's red right foot, -equip pantogram pants, -equip Everfull Dart Holster, -equip Kramco Sausage-o-Matic&trade;, "
				+ mys_mod + " mys, " + mus_mod + " mus, " + mox_mod + " mox";
			famSelector = "noncombat";
		} else {
			string lastIsland = get_property("_lastPirateRealmIsland");
			maxString = hp_mod + " hp, -ml, equip PirateRealm eyepatch, equip PirateRealm party hat, equip Red Roger's red left hand, equip Red Roger's red left foot, -equip pantogram pants, -equip Everfull Dart Holster, -equip Kramco Sausage-o-Matic&trade;, "
				+ mys_mod + " mys, " + mus_mod + " mus, " + mox_mod + " mox";
			switch (lastIsland) {
				case "Battle Island":
				case "Dessert Island":
				case "Signal Island":
				case "Storm Island":
				case "Temple Island":
					selector = "20 item";
					famSelector = "item";
					break;

				case "Trash Island":
					selector = "20 meat";
					famSelector = "meat";
					break;
			}
		}
		automate_dressup(isSea ? $location[Sailing the PirateRealm Seas] : $location[PirateRealm Island], selector, famSelector, maxString);

		if (my_buffedstat($stat[muscle]) > 100) mus_mod *= 5;
		if (my_buffedstat($stat[mysticality]) > 100) mys_mod *= 5;
		if (my_buffedstat($stat[moxie]) > 100) mox_mod *= 5;
		if (my_maxhp() < 200) hp_mod *= 5;

		// DEBUFF gets more and more dramatic as tries counts down
		// uneffect generally costing 1000 meat these days
		switch (tries) {
		    case 5: // only the cheapest or most extreme cases
    			if (!prVerifyStats()) // Apathy, always 100meat for 10 adv of -10 stats
    				use_if_needed($item[Mr. Mediocrebar], $effect[Apathy], numAdventures);
    			if (my_buffedstat($stat[muscle]) > 100) // Bloody Hand, free -5 mus
    				use_if_needed($item[seal tooth], $effect[Bloody Hand], numAdventures);

    			if (!prVerifyStats() && have_effect($effect[Cheerled]) > 0)
    				uneffect($effect[Cheerled]); // Pig Skinner class only, free -50% stats
                break;

		    case 4: // first cheap try didn't work so this time more expensive debuffs and/or less extreme cases
          		if (my_buffedstat($stat[muscle]) >= 130 && have_effect($effect[Angering Pizza Purists]) > 0)
         			uneffect($effect[Angering Pizza Purists]);

          		if (my_buffedstat($stat[muscle]) >= 130 && have_effect($effect[Gummiheart]) > 0)
         			uneffect($effect[Gummiheart]);
          		if (my_buffedstat($stat[mysticality]) >= 130 && have_effect($effect[Gummibrain]) > 0)
         			uneffect($effect[Gummibrain]);
          		if (my_buffedstat($stat[moxie]) >= 130 && have_effect($effect[Gummiskin]) > 0)
         			uneffect($effect[Gummiskin]);
                break;

		    case 3: // starting to get serious
    			if (my_buffedstat($stat[muscle]) >= 115 && have_effect($effect[Angering Pizza Purists]) > 0)
    				uneffect($effect[Angering Pizza Purists]);

          		if (my_buffedstat($stat[muscle]) >= 115 && have_effect($effect[Gummiheart]) > 0)
         			uneffect($effect[Gummiheart]);
          		if (my_buffedstat($stat[mysticality]) >= 115 && have_effect($effect[Gummibrain]) > 0)
         			uneffect($effect[Gummibrain]);
          		if (my_buffedstat($stat[moxie]) >= 115 && have_effect($effect[Gummiskin]) > 0)
         			uneffect($effect[Gummiskin]);

                // looks like no moxie debuff bang potion available
    			if (my_buffedstat($stat[muscle]) > 100 && potionsOfDoomIdentified())
    				use_if_needed(potionOfDoom("sleepiness"), $effect[Sleepy], numAdventures); // Sleepy, 120 meat for 20 adv of -30% mus
    			if (my_buffedstat($stat[mysticality]) > 100 && potionsOfDoomIdentified())
    				use_if_needed(potionOfDoom("confusion"), $effect[Confused], numAdventures); // Confused, 120 meat for 20 adv of -30% mys

    			if (!prVerifyStats())
    				use_if_needed($item[marzipan skull], $effect[Hardly Poisoned At All], numAdventures); // Sugar Rush and Hardly Poisoned At All, 100 meat for 5 adv of net -5% mus, -20% mys, -5% mox
    			if (!prVerifyStats() && have_effect($effect[Beaten Up]) < numAdventures) { // if we have less than we need, get all that we need in one shot so we don't have to re-buy Rock Pops
    				use_if_needed($item[Rock Pops], $effect[Popping Stomach], 1);
       				use_if_needed($item[Dyspepsi-Cola], $effect[Beaten Up], 40); // total 500 meat for 40 adv of -50% stats
    			}

				if (my_maxhp() < 200 && !maxString.contains_text("equip sea salt scrubs"))
					maxString = maxStringAppend(maxString, "equip sea salt scrubs");
                break;

		    case 2: // getting desperate, least extreme cases and most expensive debuffs
    			if (my_buffedstat($stat[muscle]) > 100 && have_effect($effect[Angering Pizza Purists]) > 0)
    				uneffect($effect[Angering Pizza Purists]);

          		if (my_buffedstat($stat[muscle]) >= 100 && have_effect($effect[Gummiheart]) > 0)
         			uneffect($effect[Gummiheart]);
          		if (my_buffedstat($stat[mysticality]) >= 100 && have_effect($effect[Gummibrain]) > 0)
         			uneffect($effect[Gummibrain]);
          		if (my_buffedstat($stat[moxie]) >= 100 && have_effect($effect[Gummiskin]) > 0)
         			uneffect($effect[Gummiskin]);

                // fine tuning (these debuffs also buff)
    			if (my_buffedstat($stat[muscle]) > 100 && my_buffedstat($stat[mysticality]) <= 95)
    				use_if_needed($item[pickle-flavored chewing gum], $effect[Mystic Pickleness], numAdventures); // Mystic Pickleness, 100 meat for 5 adv of mys +5, mus -5
    			if (my_buffedstat($stat[muscle]) > 100 && my_buffedstat($stat[moxie]) <= 95)
    				use_if_needed($item[lime-and-chile-flavored chewing gum], $effect[Spicy Limeness], numAdventures); // Spicy Limeness, 100 meat for 5 adv of mus -5, mox +5
    			if (my_buffedstat($stat[moxie]) > 100 && my_buffedstat($stat[mysticality]) <= 95)
    				use_if_needed($item[jaba&ntilde;ero-flavored chewing gum], $effect[Spicy Mouth], numAdventures); // Spicy Mouth, 100 meat for 5 adv of mox -5, mys +5
    			if (my_buffedstat($stat[moxie]) > 100 && my_buffedstat($stat[muscle]) <= 95)
    				use_if_needed($item[tamarind-flavored chewing gum], $effect[Tamarind Torment], numAdventures); // Tamarind Torment, 100 meat for 5 adv of mox -5, mus +5

                // tiny debuffs with few advs
    			if (my_buffedstat($stat[muscle]) > 100) // Wussiness potion, 100 meat for 3 adv of -3 mus
    				use_if_needed($item[wussiness potion], $effect[Wussiness], numAdventures);
    			if (my_buffedstat($stat[muscle]) > 100) // Missing Fingers, 100 meat for 3 adv of -3 mus
    				use_if_needed($item[Knob Goblin firecracker], $effect[Missing Fingers], numAdventures);

				if (my_maxhp() < 200 && !maxString.contains_text("equip sea salt scrubs"))
					maxString = maxStringAppend(maxString, "equip sea salt scrubs");
                break;

		    default:
	    }

	} until (tries-- <= 0 || prVerifyStats());

	assert(prVerifyStats(), "prDressup: wasn't able to get all stats <= 100 and max hp >= 150 (hp needed for land only), max string: " + maxString);
}



void getPirateRealmQuest() {
    // get the PirateRealm eyepatch if we don't have it
	if (available_amount($item[PirateRealm eyepatch]) == 0) {
		print("getting PirateRealm eyepatch", "blue");
		visit_url("/place.php?whichplace=realm_pirate&action=pr_port", true, false);
	}
    assert(available_amount($item[PirateRealm eyepatch]) > 0, "getPirateRealmQuest: we didn't get the PirateRealm eyepatch!");

	if (available_amount($item[curious anemometer]) == 0) {
        if (equipped_amount($item[PirateRealm eyepatch]) == 0)
            equip($item[PirateRealm eyepatch]);

		visit_url("/place.php?whichplace=realm_pirate&action=pr_port", true, false);
		run_choice(1); // Head to Groggy's

		// cuisinier for the Dessert Island
		// Wide-Eyed or Harquebusier crewmate for Skull Island
		int choiceNumber = 0;
		foreach i, name in available_choice_options(false) {
			// first choice
			if (name.contains_text("Harquebusier")) {
				choiceNumber = i;
				break;
			}
			// second choice
			if (name.contains_text("Wide-Eyed")) {
				choiceNumber = i;
			}
			// third choice
			if (name.contains_text("Cuisinier") && choiceNumber == 0) {
				choiceNumber = i;
			}
		}
		if (choiceNumber == 0) {
            choiceNumber = random(3) + 1; // random if we didn't choose something specifically
		    print("didn't find a crewmate to choose, RANDOM CHOICE: " + choiceNumber, "red");
		}
		run_choice(choiceNumber);

		run_choice(4); // curious anemometer to unlock Trash Island
		run_choice(4); // Swift Clipper = fastest
		run_choice(1); // head to the sea
	}

    assert(available_amount($item[curious anemometer]) > 0, "getPirateRealmQuest: we didn't get the curious anemometer!");
}



record PRStatusRecord {
	int guns;
	int grub;
	int grog;
	int glue;
	int gold;
	int fun;
};
int gkExpectedSeaAdventures = 10;


string prStatusRecordToString(PRStatusRecord prRecord) {
    return "Guns: " + prRecord.guns + ", Grub: " + prRecord.grub + ", Grog: " + prRecord.grog + ", Glue: " + prRecord.glue + ", Gold: " + prRecord.gold + ", Fun: " + prRecord.fun;
}

void printPRStatusRecord(PRStatusRecord prRecord) {
    print(prStatusRecordToString(prRecord), "blue");
}



PRStatusRecord getPirateRealmStatus() {
	PRStatusRecord result;

	if ("_lastPirateRealmIsland".get_property().to_location() == $location[none])
		return result;

	set_location($location[Sailing the PirateRealm Seas]);
	buffer page = visit_url("/charpane.php", true, false);
	matcher parse = create_matcher('<b>Guns:</b></td><td class=small>(\\d+)</td></tr><tr><td class=small align=right><b>Grub:</b></td><td class=small>(\\d+)</td></tr><tr><td class=small align=right><b>Grog:</b></td><td class=small>(\\d+)</td></tr><tr><td class=small align=right><b>Glue:</b></td><td class=small>(\\d+)</td></tr><tr><td class=small align=right><b>Gold:</b></td><td class=small>(\\d+)</td></tr><tr><td class=small align=right><b>Fun:</b></td><td class=small>(\\d+)</td>', page);
	if(find(parse)) {
		result.guns = to_int(parse.group(1));
		result.grub = to_int(parse.group(2));
		result.grog = to_int(parse.group(3));
		result.glue = to_int(parse.group(4));
		result.gold = to_int(parse.group(5));
		result.fun = to_int(parse.group(6));
	} else
		abort("couldn't find PR status -- too large stats (need 100 or less), or not enough turns (need 40)?");
	return result;
}

buffer runPRIslandChoice(string[3] islandPriority) {
	assert(handling_choice(), "runPRIslandChoice: we're not handling a choice!");
	int choiceNumber = 0;
	foreach i, name in available_choice_options(false) {
		// the preferred choice, only available sometimes
		if (name.contains_text(islandPriority[0])) {
			choiceNumber = i;
			break;
		}

		// second choice, only available sometimes
		if (islandPriority[1] != "" && name.contains_text(islandPriority[1]))
			choiceNumber = i;

		// the default choice, always available
		if (choiceNumber == 0 && name.contains_text(islandPriority[2]))
			choiceNumber = i;
	}

	return run_choice(choiceNumber);
}

// return true if we successfully completed a high-seas adventure AND it wasn't the last adventure
boolean runPRSeasChoice(PRStatusRecord status, string choicePage) {
	assert(handling_choice(), "runPRSeasChoice: not handling a choice");
// 	int lastChoice = last_choice();
// 	assert(lastChoice == something, "not in a PR choice");

	boolean rval = true;
	string resultPage;
	int theChoice = 0;

	if (choicePage.contains_text("<td>You're not currently at sea.<center>")) {
		rval = false;
		print("we're not at sea!", "red");

	} else if (choicePage.contains_text("Smooth Sailing")) {
		if (status.grub < 10 && status.grog < 10)
			resultPage = run_choice(3);
		else if (status.grub > status.grog)
			resultPage = run_choice(1); // feast
		else
			resultPage = run_choice(2); // party
	} else if (choicePage.contains_text("High Tide, Low Morale")) {
		if (status.grub > status.grog && status.grub > 5)
			resultPage = run_choice(1); // feast
		else if (status.grog > 5)
			resultPage = run_choice(2); // party
		else if (status.gold >= 30)
			resultPage = run_choice(3);
		else
			resultPage = run_choice(4);
	} else if (choicePage.contains_text("Like Shops in the Night")) {
		while (status.gold >= 10 && (status.grub < 50 || status.grog < 50 || status.glue < 2)) {
			if (status.grub < status.grog && status.grub < 50)
				theChoice = 1; // buy grub
			else if (status.grog < 50)
				theChoice = 2; // buy grog
			else if (status.glue < 2)
				theChoice = 3; // buy glue
			if (status.glue == 0 && status.grub >20 && status.grog > 20)
				theChoice = 3;
			assert(theChoice != 0, "runPRSeasChoice: should always have a choice");

			resultPage = run_choice(theChoice);
			status = getPirateRealmStatus();
		}

		while (status.gold > 200) {
			resultPage = run_choice(4); // buy gun
			status = getPirateRealmStatus();
		}

		run_choice(6); // exit
	} else if (choicePage.contains_text("The Ship is Wrecked")) {
		if (available_choice_options()[1] == "")
			resultPage = run_choice(2); // wait for assistance
		else
			resultPage = run_choice(1); // fix it with glue
	}

	else if (choicePage.contains_text("Land Ho!")) {
		resultPage = run_choice(-1); // head inland
		rval = false;

	} else {
		print("default choice", "blue");
		resultPage = run_choice(-1);
	}

	assert(!handling_choice(), "still handling a choice at the end of runPRSeasChoice");

	postAdventure();
	return rval;
}

// one adventure on the seas
boolean sailThePirateRealmSeas(PRStatusRecord status) {
    prDressup(true, gkExpectedSeaAdventures);
	assert(prVerifyStats(), "invalid stats");
	string aPage = advURL(to_url($location[Sailing the PirateRealm Seas]));
	return runPRSeasChoice(status, aPage);
}

// get through an entire sea
boolean grindPirateRealmSea() {
	PRStatusRecord status = getPirateRealmStatus();
	while (sailThePirateRealmSeas(status)) {
		healToMaxWithMPRestore();
		status = getPirateRealmStatus();
    	prDressup(true, gkExpectedSeaAdventures);
	}

	return true;
}

// return true if we successfully completed an island combat AND it wasn't the last adventure
string runPRIslandTurn(string aPage) {
	string resultPage;

	if (isErrorPage(aPage)) {
		print("GOT ERROR PAGE: " + aPage, "red");
	} else if (inCombat()) {
		resultPage = run_combat();
	} else if (aPage.contains_text("fight.php")) {
		// monster killed before we got into combat
	} else {
		assert(handling_choice(), "runPRIslandTurn: we should be handling a choice at this point");
		resultPage = run_choice(-1);
	}

	if (!isErrorPage(resultPage))
		postAdventure();
	return resultPage;
}

// grind through an entire island
boolean grindPirateRealmIsland() {
	boolean [location] thirdIslands = {$location[Signal Island] : true, $location[Tiki Island] : true, $location[Storm Island] : true, $location[Red Roger's Fortress] : true, $location[Jack's Hideout] : true, $location[The Temple] : true};
	location island = to_location(get_property("_lastPirateRealmIsland"));
	int turns = (thirdIslands contains island) ? 10 : 5;
	prDressup(false, turns);

	while (turns > 0) {
		assert(prVerifyStats(), "invalid stats");
		healIfRequiredWithMPRestore();
		restore_mp(50);

		string aPage = advURL(island);
		string resultPage = runPRIslandTurn(aPage);
		turns--;

		if (last_monster() == $monster[Red Roger] && !inCombat() && "_lastCombatWon".get_property().to_boolean()) {
			set_property("_smm.PirateRealmDone", "true");
			break;
		}
	}
	return prVerifyStats();
}


// using the Swift Clipper
int gkPRBoatSpeed = 4; // number of turns to the next island
int gkPRStartingGuns = 0;

// onSeas -- are we sailing the seas
// islandNeeded -- need to finish island?
boolean grindSeaAndIsland(boolean onSeas, boolean islandNeeded) {
	assert(!handling_choice() && !inCombat(), "grindSeaAndIsland: we're not in a good starting state (in combat or in a choice)");

	string [3][] islandPriority = {
		0: {"Skull", "Dessert", "Battle"},
		1: {(have_item($item[tomb-opener]) ? "Cemetery" : "Trash"), "", "Trash"},
		2: {"Red Roger's Fortress", "Temple", "Signal"},
	};
	boolean everythingLooksGood = true;
	PRStatusRecord status = getPirateRealmStatus(); // get the status after dressing up in case there's a problem: then we're dressed and can manually adventure

	// no way to know for sure if we're on the seas, so very defensive programming
	if (onSeas) {
		prDressup(true, 1); // true = dressing for the sea
		assert(prVerifyStats(), "grindSeaAndIsland: invalid stats");

		string resultPage = advURL($location[Sailing the PirateRealm Seas]);
		int lastChoice = last_choice();
		int section = lastChoice - 1352;
		if (isErrorPage(resultPage))
			onSeas = false;
		else if (handling_choice() && (lastChoice == 1352 || lastChoice == 1353 || lastChoice == 1354)) {
			runPRIslandChoice(islandPriority[section]);
		} else if (handling_choice()) {
			onSeas = runPRSeasChoice(status, resultPage);
		} else {
			onSeas = false;
			string islandTurnResult = runPRIslandTurn(resultPage);
			islandNeeded = ! isErrorPage(islandTurnResult);
		}
	}

	string lastIsland = get_property("_lastPirateRealmIsland");

	// SEA
	if (everythingLooksGood && onSeas) {
		print("adventuring at sea " + lastIsland, "green");
		everythingLooksGood = grindPirateRealmSea();
	}

	// ISLAND
	if (everythingLooksGood && islandNeeded) {
		print("adventuring at island " + lastIsland, "green");
		everythingLooksGood = grindPirateRealmIsland();
	}

	return everythingLooksGood;
}


// goLong = get a slow ship to do as many turns as possible in PR (TODO)
void grindPirateRealm(PRStatusRecord status, boolean goLong) {
	setNoMood(); // we might need to remove buffs

	saveAndSetProperty("choiceAdventure1357", "2"); // The Starboard is Bare, Dive for bigger bounty
	saveAndSetProperty("choiceAdventure1358", "2"); // The Starboard is Bare, Dive for bigger bounty
	saveAndSetProperty("choiceAdventure1359", "2"); // Grog for the Grogless, Dive for sunken casks
	saveAndSetProperty("choiceAdventure1362", "2"); // Stormy Weather, Try to gain some extra distance
	saveAndSetProperty("choiceAdventure1363", "1"); // Who Pirates the Pirates?, Attempt to flee
	saveAndSetProperty("choiceAdventure1364", "1"); // An Opportunity for Dastardly Do, Attack them (best option in terms of FunPoints, win or lose, though you do have to have and spend a glue, otherwise only gain 1 FP next adv)
	saveAndSetProperty("choiceAdventure1365", "2"); // A Sea Monster!, Flee it!

	try {
    	string lastIsland = "_lastPirateRealmIsland".get_property();
		if (lastIsland == "Red Roger's Fortress" || lastIsland == "Temple Island" || lastIsland == "Signal Island"
			|| (lastIsland == "Cemetery Island" && have_item($item[Red Roger's map]))
			|| (lastIsland == "Trash Island" && false)) { // can't sniff this condition :(
			grindSeaAndIsland(true, true);
		} else if (lastIsland == "Cemetery Island" || lastIsland == "Trash Island"
			|| (lastIsland == "Skull Island" && have_item($item[tomb-opener]))
			|| (lastIsland == "Dessert Island" && my_session_items($item[cocoa of youth]) >= 1)
			|| (lastIsland == "Battle Island" && status.guns >= gkPRStartingGuns + 3)) {
			grindSeaAndIsland(true, true);
			grindSeaAndIsland(true, true);
		} else if (lastIsland == "" || lastIsland == "Skull Island" || lastIsland == "Dessert Island" || lastIsland == "Battle Island") {
			grindSeaAndIsland(true, true);
			grindSeaAndIsland(true, true);
			grindSeaAndIsland(true, true);
		} else
			abort("grindPirateRealm: inconsistent state, not sure how to proceed");

		int lastChoice = last_choice();
		if (lastChoice == 1378 || lastChoice == 1379 || lastChoice == 1384 || lastChoice == 1381 || lastChoice == 1382 || lastChoice == 1380)
			set_property("_smm.PirateRealmDone", "true");
		else
			abort("something went wrong, we're expecting to have done the last choice at this point");

	} finally {
		restoreSavedProperty("choiceAdventure1357");
		restoreSavedProperty("choiceAdventure1358");
		restoreSavedProperty("choiceAdventure1359");
		restoreSavedProperty("choiceAdventure1362");
		restoreSavedProperty("choiceAdventure1363");
		restoreSavedProperty("choiceAdventure1364");
		restoreSavedProperty("choiceAdventure1365");
	}
}



// can we do something with these args?
void verifyArguments(string arguments) {
	string [int] argv = split_string(arguments, " ");

    if (count(argv) > 2)
        abort("pr: too many arguments");
    if (count(argv) == 1 && argv[0] != "quest" && argv[0] != "dressup" && argv[0] != "long" && argv[0] != "short" && argv[0] != "version" && argv[0] != "help")
        abort("pr: invalid argument");
}


void main(string arguments) {
	print("pr args: " + arguments, "green");

    // really hard to tell if we've done this quest, so we'll just set a property when done
	if (gkPirateRealmDoneKey.get_property().to_boolean()
		|| my_session_items(goalItem) >= 1)
		return;

	verifyArguments(arguments);

	string [int] argv = split_string(arguments, " ");
    PRStatusRecord status = getPirateRealmStatus();
    switch (argv[0]) {
        case "quest":
            getPirateRealmQuest();
            return;

        case "dressup":
            boolean isSea = count(argv) == 2 && argv[1] == "sea";
            prDressup(isSea, 1);
            assert(prVerifyStats(), "not dressed up for PirateRealm");
            return;

        case "version":
            print("pr v" + __pr_version);
            return;

        case "help":
            printHelp();
            return;
    }

    // DEFAULT CASE
    getPirateRealmQuest(); // includes dressup

	int startingFP = "availableFunPoints".get_property().to_int();
	int startingTC = my_turncount();
	string lastIsland = "_lastPirateRealmIsland".get_property();
	print("grindPirateRealm with starting FP: " + startingFP + " and starting turncount: " + startingTC + ", last island: " + lastIsland, "green");
    print("status: " + prStatusRecordToString(status), "green");

	grindPirateRealm(status, count(argv) == 1 && argv[0] == "long");

    int gainedFP = "availableFunPoints".get_property().to_int() - startingFP;
    int turnsUsed = startingTC - my_turncount();
	print("exiting PirateRealm gained " + gainedFP + " fun points in " + turnsUsed + " turns for a gain of " + (gainedFP / turnsUsed) + " fp/turn");
}
