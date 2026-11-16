script "gbc";
notify TQuilla;
since r26718;

import <smmAutomation.ash>;

string __gbc_version = "0.1";

/**
Grind Gingerbread City.

"gbc help" in the CLI for help

@author Sacha Mallais (TQuilla #2771003)
*/


int costPerPercentIncrease = 3333;
item goalItem = $item[counterfeit city];
location gkGrindLocation = $location[Gingerbread Upscale Retail District];



void printHelp() {
	print_html("<h2>gbc</h2>");
	print_html("<br>Grind Gingerbread.</br>");
	print_html("<br>leaderboard|lb</br>");
	print_html("<br>sprinkes</br>");
	print_html("<br>items</br>");
	print_html("<br>quest</br>");
	print_html("<br>win</br>");
}



// default outfit, could theoretically be changed
void gbcDressup(location grindLocation) {
	automate_dressup(grindLocation, "sprinkle", "chocolate lab", "equip candy dog collar");
}


void gbcPrep(location grindLocation) {
    gbcDressup(grindLocation);
}



// morningLoc and eveningLoc are more relevant for the choices than what locations are actually adventured at
void grindGingerbread(boolean takeShortcut, location noonLoc, int noonChoice, location midnightLoc, int midnightChoice) {

	int turnsUsed = effectiveGingerbreadCityTurns();
	print("grindGingerbread, turns used: " + turnsUsed + ", take shortcut: " + takeShortcut + ", noon loc: " + noonLoc + " choice: " + noonChoice + ", midnight loc: " + midnightLoc + " choice: " + midnightChoice, "green");

	newAcquire($item[gingerbread restraining order], 1, kTurnValue);
	newAcquire($item[gingerbread cigarette], 13, kTurnValue);

	// SHORTCUT
	while (turnsUsed == 0 && takeShortcut) {
		print("grindGingerbread: TAKING SHORTCUT", "blue");
		set_property("choiceAdventure1215", "1"); // set the clock forward
		adv1($location[Gingerbread Civic Center], 0, "");
		turnsUsed = effectiveGingerbreadCityTurns();
	}

	// MORNING
	turnsUsed = effectiveGingerbreadCityTurns();
	while (turnsUsed < 9) {
		print("grindGingerbread: MORNING", "blue");
		redirectAdventure(gkGrindLocation, 9 - turnsUsed, "if monstername gingerbread convict || monstername gingerbread finance bro || monstername gingerbread gentrifier || monstername gingerbread lawyer || monstername gingerbread tech bro || monstername Judge Fudge;use gingerbread cigarette;endif;");
		turnsUsed = effectiveGingerbreadCityTurns();
	}

	// NOON
	turnsUsed = effectiveGingerbreadCityTurns();
	while (turnsUsed == 9) {
		print("grindGingerbread: NOON", "blue");
		advURL(noonLoc);
		assert(handling_choice(), "didn't get to noon choice");
		run_choice(noonChoice);
		postAdventure();
		turnsUsed = effectiveGingerbreadCityTurns();
	}

	// AFTERNOON/EVENING
	turnsUsed = effectiveGingerbreadCityTurns();
	while (turnsUsed >= 10 && turnsUsed < 19) {
		print("grindGingerbread: AFTERNOON/EVENING", "blue");
		redirectAdventure(gkGrindLocation, 19 - turnsUsed, "if monstername gingerbread convict || monstername gingerbread finance bro || monstername gingerbread gentrifier || monstername gingerbread lawyer || monstername gingerbread tech bro || monstername Judge Fudge;use gingerbread cigarette;endif;");
		turnsUsed = effectiveGingerbreadCityTurns();
	}

	// MIDNIGHT
	turnsUsed = effectiveGingerbreadCityTurns();
	while (turnsUsed == 19) {
		print("grindGingerbread: MIDNIGHT", "blue");
		advURL(midnightLoc);
		assert(handling_choice(), "didn't get to midnight choice");
		run_choice(midnightChoice);
		postAdventure();
		turnsUsed = effectiveGingerbreadCityTurns();
	}

	// AFTER MIDNIGHT
	turnsUsed = effectiveGingerbreadCityTurns();
	while (turnsUsed >= 20 && !takeShortcut) {
		redirectAdventure(gkGrindLocation, 15, "if monstername gingerbread convict || monstername gingerbread finance bro || monstername gingerbread gentrifier || monstername gingerbread lawyer || monstername gingerbread tech bro || monstername Judge Fudge;use gingerbread cigarette;endif;");
		turnsUsed = effectiveGingerbreadCityTurns();
	}
}


// NOT suitable for leaderboarding
// will overwrite applicable choiceAdventure settings and then reset them to empty
void grindGingerbreadDEPRECATED(boolean takeShortcut, boolean adventureAfterMidnight, boolean progressBlackmail) {
	location kGrindLocation = $location[Gingerbread Upscale Retail District];
	int turnsUsed = effectiveGingerbreadCityTurns();
	print("grindGingerbread, turns used: " + turnsUsed + ", take shortcut: " + takeShortcut + ", after midnight?: " + adventureAfterMidnight + ", progress blackmail?: " + progressBlackmail, "green");

	set_property("choiceAdventure1209", "2"); // IF we go to upscale at midnight:
	set_property("choiceAdventure1214", "2"); // chocolate sculpture (+3 adventures)

	if (turnsUsed == 0) {
		newAcquire($item[gingerbread restraining order], 1, kTurnValue);
		newAcquire($item[gingerbread cigarette], 13, kTurnValue);
	}

	try {
		setDefaultKoLState();

		// these increase stats, and therefore xp
		boolean unused;

		string familiarString = "";
		// level up the chocolate lab for winning runs
		if (familiar_weight($familiar[chocolate lab]) < 20) {
			familiarString = "chocolate lab";
			unused = cli_execute("friars familiar");
		} else
			familiarString = "item";
		// we want the redirection, but we don't want any of the auto dressup stuff
		automate_dressup(kGrindLocation, "", "chocolate lab", "sprinkle");
		healAndRemoveDebuffsWithMPRestore();

		// SHORTCUT
		while (turnsUsed == 0 && takeShortcut) {
			print("TAKING SHORTCUT", "blue");
			set_property("choiceAdventure1215", "1"); // set the clock forward
			adv1($location[Gingerbread Civic Center], 0, "");
			turnsUsed = effectiveGingerbreadCityTurns();
		}

		// MORNING
		turnsUsed = effectiveGingerbreadCityTurns();
		while (turnsUsed < 9) {
			print("MORNING", "blue");
			redirectAdventure(kGrindLocation, 9 - turnsUsed, "if monstername gingerbread convict || monstername gingerbread finance bro || monstername gingerbread gentrifier || monstername gingerbread lawyer || monstername gingerbread tech bro || monstername Judge Fudge;use gingerbread cigarette;endif;");
			turnsUsed = effectiveGingerbreadCityTurns();
		}

		// NOON
		turnsUsed = effectiveGingerbreadCityTurns();
		while (turnsUsed == 9) {
			print("NOON", "blue");

			if (progressBlackmail && get_property("gingerLawChoice").to_int() >= 3 && !have_item($item[teethpick]) && !"gingerBlackmailAccomplished".get_property().to_boolean()) {
				set_property("choiceAdventure1206", "4"); // buy teethpick
				adv1($location[Gingerbread Industrial Zone], 1, "");
			} else if (progressBlackmail && have_item($item[fruit-leather negatives])) {
				set_property("choiceAdventure1208", "8"); // retail district: drop off negatives -- gingerPhotoTaken=true???
				adv1($location[Gingerbread Upscale Retail District], 1, "");
			} else if (progressBlackmail && to_boolean(get_property("gingerNegativesDropped")) && !to_boolean(get_property("gingerBlackmailAccomplished")) && !have_item($item[gingerbread blackmail photos])) {
				//} else if (progressBlackmail && to_boolean(get_property("gingerNegativesGiven")) && !to_boolean(get_property("gingerBlackmailAccomplished")) && !have_item($item[gingerbread blackmail photos])) {
				set_property("choiceAdventure1208", "8"); // retail district: pick up photos
				adv1($location[Gingerbread Upscale Retail District], 1, "");
			} else if (progressBlackmail && have_item($item[gingerbread blackmail photos])) {
				set_property("choiceAdventure1202", "4"); // civic center: blackmail
				adv1($location[Gingerbread Civic Center], 1, "");

			// DEFAULT
			} else {
				// retail district: pumpkin spice candle which allows getting broken chocolate pocketwatch
				//set_property("choiceAdventure1208", "2");
				//adv1($location[Gingerbread Upscale Retail District], 1, "");

				// retail district: gingerbread dog treat
				set_property("choiceAdventure1208", "1");
				adv1($location[Gingerbread Upscale Retail District], 1, "");

				// retail district: outfit pieces gingerbread tophat, waistcoat,trousers
// 				set_property("choiceAdventure1208", "4"); // 4 or 5 or 6
// 				adv1($location[Gingerbread Upscale Retail District], 1, "");
			}
			turnsUsed = effectiveGingerbreadCityTurns();
		}

		// AFTERNOON/EVENING
		turnsUsed = effectiveGingerbreadCityTurns();
		while (turnsUsed >= 10 && turnsUsed < 19) {
			print("AFTERNOON/EVENING", "blue");
			redirectAdventure(kGrindLocation, 19 - turnsUsed, "if monstername gingerbread convict || monstername gingerbread finance bro || monstername gingerbread gentrifier || monstername gingerbread lawyer || monstername gingerbread tech bro || monstername Judge Fudge;use gingerbread cigarette;endif;");
			turnsUsed = effectiveGingerbreadCityTurns();
		}

		// MIDNIGHT
		turnsUsed = effectiveGingerbreadCityTurns();
		while (turnsUsed == 19) {
			print("MIDNIGHT", "blue");
			if (progressBlackmail && to_boolean(get_property("gingerSubwayLineUnlocked")) && !to_boolean(get_property("gingerPhotoTaken"))) {
				set_property("choiceAdventure1205", "4");
				adv1($location[Gingerbread Train Station], -1, ""); // ride new line
				set_property("gingerPhotoTaken", "true");
			} else if (progressBlackmail && !to_boolean(get_property("gingerSubwayLineUnlocked"))) {
				set_property("choiceAdventure1205", "1");
				adv1($location[Gingerbread Train Station], -1, ""); // lay track
			} else if (progressBlackmail && to_int(get_property("gingerLawChoice")) < 3) {
				set_property("choiceAdventure1203", "1");
				adv1($location[Gingerbread Civic Center], -1, ""); // study law
			} else if (progressBlackmail && have_item($item[teethpick]) && to_int(get_property("gingerDigCount")) < 7) {
				set_property("choiceAdventure1205", "5");
				adv1($location[Gingerbread Train Station], -1, ""); // dig
			} else {
				if (have_item($item[pumpkin spice candle])) {
					set_property("choiceAdventure1205", "2");
					adv1($location[Gingerbread Train Station], -1, ""); // broken chocolate pocketwatch
				} else {
					// high-end ginger wine
					// 					saveOutfit(false);
					// 					cli_execute("outfit gingerbread best");
					// 					set_property("choiceAdventure1209", "2");
					// 					set_property("choiceAdventure1214", "1");
					// 					adv1($location[Gingerbread Upscale Retail District], -1, "");
					// 					restoreOutfit(false);

					// spare chocolate parts
// 					set_property("choiceAdventure1207", "2");
// 					set_property("choiceAdventure1213", "1");
// 					adv1($location[Gingerbread Industrial Zone], -1, "");

					// chocolate puppy
// 					fullAcquire($item[gingerbread dog treat]);
// 					set_property("choiceAdventure1203", "5");
// 					adv1($location[Gingerbread Civic Center], -1, "");

					// counterfeit city
					set_property("choiceAdventure1203", "2");
					adv1($location[Gingerbread Civic Center], -1, "");
				}
			}
			turnsUsed = effectiveGingerbreadCityTurns();
		}

		// AFTER MIDNIGHT
		turnsUsed = effectiveGingerbreadCityTurns();
		while (turnsUsed >= 20 && adventureAfterMidnight) {
			redirectAdventure(kGrindLocation, 15, "if monstername gingerbread convict || monstername gingerbread finance bro || monstername gingerbread gentrifier || monstername gingerbread lawyer || monstername gingerbread tech bro || monstername Judge Fudge;use gingerbread cigarette;endif;");
			turnsUsed = effectiveGingerbreadCityTurns();
		}
	} finally {
		remove_property("choiceAdventure1202");
		remove_property("choiceAdventure1203");
		remove_property("choiceAdventure1205");
		remove_property("choiceAdventure1206");
		remove_property("choiceAdventure1208");
		remove_property("choiceAdventure1209");
		remove_property("choiceAdventure1214");
		remove_property("choiceAdventure1215");
	}
}


void grindSprinkles() {
	set_property("choiceAdventure1204", "2"); // sewers??
	set_property("choiceAdventure1209", "1"); // fake cocktail

	try {
		int turnsUsed = effectiveGingerbreadCityTurns();

		setDefaultMood(); setDefaultBoombox();
		automate_dressup($location[Gingerbread Upscale Retail District], "", "chocolate lab", "sprinkle, +equip candy dog collar");

		useMoMifNeeded();
		cli_execute("beach head Do I Know You From Somewhere?");
		if (fullness_limit() - my_fullness() >= 4 && have_effect($effect[Sprinkle in Your Eye]) == 0 && have_effect($effect[Sprinkle Sense]) == 0) {
			museumSafeEat(1, $item[animal part cracker]);
			museumSafeEat(1, $item[green-iced sweet roll]); // buys a fresh one if the owned ones are kept
		}
		fullAcquire($item[gingerbread restraining order]);
		use_if_needed($item[tainted icing], $effect[Iced and Tainted], 30 - turnsUsed);

		// MORNING
		healAndRemoveDebuffsWithMPRestore();
		while (turnsUsed < 9) {
			adventure(9 - turnsUsed, $location[Gingerbread Upscale Retail District]);
			turnsUsed = effectiveGingerbreadCityTurns();
		}

		// NOON
		turnsUsed = effectiveGingerbreadCityTurns();
		healAndRemoveDebuffsWithMPRestore();
		if (turnsUsed == 9) {
			adv1($location[Gingerbread Train Station], 0);
		}

		// AFTERNOON/EVENING
		turnsUsed = effectiveGingerbreadCityTurns();
		healAndRemoveDebuffsWithMPRestore();
		while (turnsUsed >= 10 && turnsUsed < 19) {
			adventure(19 - turnsUsed, $location[Gingerbread Sewers]);
			turnsUsed = effectiveGingerbreadCityTurns();
		}

		// MIDNIGHT
		turnsUsed = effectiveGingerbreadCityTurns();
		healAndRemoveDebuffsWithMPRestore();
		if (turnsUsed == 19) {
			adventure(1, $location[Gingerbread Upscale Retail District]);
		}

		// AFTER MIDNIGHT
		turnsUsed = effectiveGingerbreadCityTurns();
		healAndRemoveDebuffsWithMPRestore();
		if (turnsUsed >= 20)
			adventure(15, $location[Gingerbread Sewers]);
	} finally {
		remove_property("choiceAdventure1204");
		remove_property("choiceAdventure1209");
	}
}



// NOTE: monster copying doesn't work!
void winSprinkles(int maxMeatCostPerBuffPercentage) {
	boolean unused;
	printGingerbreadLeaderboard();
	int turnsUsed = effectiveGingerbreadCityTurns();
	int buffTurnsNeeded = 30 - effectiveGingerbreadCityTurns();

	// DRESS UP
	if (turnsUsed == 0) {
		setDefaultKoLState();
		maximize("sprinkle, switch chocolate lab", false);
	}
	maximize("sprinkle, switch chocolate lab", false); // first maximize might set up a different environment in which a second maximize might make different choices

	// BUFF: Sprinkle in Your Eye
	item sprinkleInYourEyeItem;
	if (fullnessRoom() >= 3 && inebrietyRoom() >= 3) { // choose based on price
		if (mall_price($item[animal part cracker]) < mall_price($item[gingerbread wine]))
			sprinkleInYourEyeItem = $item[animal part cracker];
		else
			sprinkleInYourEyeItem = $item[gingerbread wine];
	} else if (fullnessRoom() >= 3)
		sprinkleInYourEyeItem = $item[animal part cracker];
	else if (inebrietyRoom() >= 3)
		sprinkleInYourEyeItem = $item[gingerbread wine];
	else //default
		sprinkleInYourEyeItem = $item[animal part cracker];

	int sprinkleInYourEyeOpportunityCost = sprinkleInYourEyeItem == $item[gingerbread wine] ? (3 * 4 * kTurnValue) : (3 * 3.5 * kTurnValue); // fill * turns lost per fill * turn value
	int sprinkleInYourEyeCost = (mall_price(sprinkleInYourEyeItem) + sprinkleInYourEyeOpportunityCost) / 30;
	print("Sprinkle in Your Eye: 1x animal part cracker@" + mall_price($item[animal part cracker]) + " OR 1x gingerbread wine@" + mall_price($item[gingerbread wine]) + ", ANALYZING: " + sprinkleInYourEyeItem + "@" + sprinkleInYourEyeCost + "/buff percent");

	// BUFF: Sprinkle Sense
	item sprinkleSenseItem;
	if (fullnessRoom() >= 1) { // choose based on price
		if (mall_price($item[green-iced sweet roll]) < (mall_price($item[green rock candy]) * 3))
			sprinkleSenseItem = $item[green-iced sweet roll];
		else
			sprinkleSenseItem = $item[green rock candy];
	} else
		sprinkleSenseItem = $item[green rock candy];
	int sprinkleSenseOpportunityCost = sprinkleSenseItem == $item[green-iced sweet roll] ? (1 * 4 * kTurnValue) : 0; // fill * turns lost per fill * turn value
	int sprinkleSenseAmount = sprinkleSenseItem == $item[green-iced sweet roll] ? 40 : 10;
	int sprinkleSenseCost = ((mall_price(sprinkleSenseItem) * sprinkleSenseAmount) + sprinkleSenseOpportunityCost) / 30;
	print("Sprinkle Sense: 1x green-iced sweet roll@" + mall_price($item[green-iced sweet roll]) + " OR 3x green rock candy@" + (3 * mall_price($item[green rock candy])) + ", ANALYZING: " + sprinkleSenseItem + "@" + sprinkleSenseCost + "/buff percent");

	costPerBuffPercentage($item[gingerbread restraining order], 10, 1, 0);

	// FAMILIAR WEIGHT BUFFS
	AnalyzeRecord [item] itemsToAnalyze = consumablesToAnalyze("Familiar Weight", false);  // false = don't print

	item [int] sortArray;
	int ctr = 0;
	// marshal the data
	foreach it in itemsToAnalyze
		sortArray[ctr++] = it;
	sort sortArray by costPerBuffPercentage(value, itemsToAnalyze[value].buffAmount,
		ceil(buffTurnsNeeded.to_float() / itemsToAnalyze[value].duration.to_float()), itemsToAnalyze[value].opportunityCost);

	// CHOOSE BUFFS TO USE
	int totalBuffs;
	int totalCost;
	foreach idx, anItem in sortArray {
		int costPerBuffPercent = costPerBuffPercentage(anItem, itemsToAnalyze[anItem].buffAmount,
			ceil(buffTurnsNeeded.to_float() / itemsToAnalyze[anItem].duration.to_float()), itemsToAnalyze[anItem].opportunityCost);
		string colour;
		if (!haveRoom(anItem) && costPerBuffPercent <= maxMeatCostPerBuffPercentage) {
			colour = "orange";
		} else if (!haveRoom(anItem)) {
			colour = "red";
		} else if (costPerBuffPercent <= maxMeatCostPerBuffPercentage) {
			colour = "green";
			totalBuffs += itemsToAnalyze[anItem].buffAmount;
			totalCost += costPerBuffPercent * itemsToAnalyze[anItem].buffAmount;
		} else {
			colour = "blue";
		}
		print(anItem + "@" + costPerBuffPercent + "/buff percentage", colour);
	}

	if (totalBuffs == 0) {
		print("WARNING: no buffs were chosen, try raising maxMeatCostPerBuffPercentage", "red");
		totalBuffs = 1; // just to avoid a div by zero
	} else
		print("total cost: " + totalCost + ", total buff: " + totalBuffs + "%, total cost per buff percent: " + (totalCost / totalBuffs));
	print("gain from winning: " + mall_price($item[my life of crime, a memoir]));
	print("Sprinkle Drop bonus: " + numeric_modifier("Sprinkle Drop") + "%");

	// BUFF UP
	if (buffTurnsNeeded == 30) { // only do this the first time through
		if (!user_confirm("proceed under the following circumstances?\ntotal buff cost: " + totalCost + ", total buff: " + totalBuffs + "%, total cost per buff percent: " + (totalCost / totalBuffs) + " meat\nturn cost: " + (kTurnValue * 30) + " -- TOTAL COST: " + (totalCost + (kTurnValue * 30)) + "\nVS gain from winning: " + mall_price($item[my life of crime, a memoir]), 60000, false))
			abort();

		// ONE-OFF BUFFS
		unused = cli_execute_if_needed("beach head Do I Know You From Somewhere?", $effect[Do I Know You From Somewhere?], buffTurnsNeeded);
		if (vipLoungeAvailable()) {
			unused = cli_execute_if_needed("pool aggressive", $effect[Billiards Belligerence], buffTurnsNeeded);
			unused = cli_execute_if_needed("fortune buff familiar", $effect[A Girl named Sue], buffTurnsNeeded);
		}
		if (!to_boolean(get_property("_madTeaParty")))
			unused = cli_execute_if_needed("hatter 24", $effect[You Can Really Taste the Dormouse], buffTurnsNeeded);

		// ACQUIRE AND CONSUME ITEMS -- TODO only acquire if we need to use it to buff
		foreach idx, anItem in sortArray {
			int amt = ceil(buffTurnsNeeded.to_float() / itemsToAnalyze[anItem].duration.to_float());
			int costPerBuffPercent = costPerBuffPercentage(anItem, itemsToAnalyze[anItem].buffAmount, amt, itemsToAnalyze[anItem].opportunityCost);
			if (costPerBuffPercent <= maxMeatCostPerBuffPercentage && haveRoom(anItem)) {
				if (fullAcquire(anItem, amt) < amt)
					abort("could not acquire consumable: " + anItem);
				consumeIfNeededWithUneffect(anItem, itemsToAnalyze[anItem].theEffect, buffTurnsNeeded);
			}
		}
	}

	print("Total Sprinkle Drop bonus: " + numeric_modifier("Sprinkle Drop") + "%", "blue");

	// ADVENTURE!
	// MORNING
	while (turnsUsed < 9) {
		healAndRemoveDebuffsWithMPRestore();
		adventure(9 - turnsUsed, $location[Gingerbread Industrial Zone]);
		turnsUsed = effectiveGingerbreadCityTurns();
	}

	// NOON
	if (effectiveGingerbreadCityTurns() == 9) {
		advURL($location[Gingerbread Train Station]);
		run_choice(2); postAdventure();
	}

	// AFTERNOON
	turnsUsed = effectiveGingerbreadCityTurns();
	while (turnsUsed >= 10 && turnsUsed < 19) {
		healAndRemoveDebuffsWithMPRestore();
		adventure(1, $location[Gingerbread Sewers]);
		turnsUsed = effectiveGingerbreadCityTurns();
	}

	// MIDNIGHT
	if (effectiveGingerbreadCityTurns() == 19) {
		advURL($location[Gingerbread Upscale Retail District]);
		run_choice(1); postAdventure();
	}

	// AFTER MIDNIGHT
	turnsUsed = effectiveGingerbreadCityTurns();
	while (turnsUsed >= 20 && turnsUsed <= 31) {
		healAndRemoveDebuffsWithMPRestore();
		adventure(1, $location[Gingerbread Sewers]);
		turnsUsed = effectiveGingerbreadCityTurns();
		if (last_monster() == $monster[gingerbread alligator])
			abort("try copying alligator!");
	}

	printGingerbreadLeaderboard();
}


// mode is -1 for quest completion, 0 for sprinkles, 1 for items
void gingerGrind(int gingerMode) {
	assert(gingerMode == -1 || gingerMode == 0 || gingerMode == 1, "gingerGrind: incorrect mode");
	print("gingerGrind mode: " + gingerMode, "green");

	boolean progressBlackmail;
	switch (gingerMode) {
		case 0:
			grindSprinkles(); // TODO integrate this into the main function
			return;

		case -1:
			progressBlackmail = true;
			break;

		case 1:
			progressBlackmail = false;
			break;
	}

	// default outfit, could theoretically be changed in the code below
	automate_dressup(gkGrindLocation, "sprinkle", "chocolate lab", "equip candy dog collar");

	location noonLoc, midnightLoc;
	int noonChoice, midnightChoice;

	// NOON
	// get the teethpick
	if (progressBlackmail && get_property("gingerLawChoice").to_int() >= 3 && !have_item($item[teethpick]) && !to_boolean(get_property("gotSugarRaygun"))) {
		noonChoice = 4;
		noonLoc = $location[Gingerbread Industrial Zone];

	// drop off the negatives
	} else if (progressBlackmail && have_item($item[fruit-leather negatives])) {
		noonChoice = 8;
		noonLoc = $location[Gingerbread Upscale Retail District];

	// pick up the negatives
	} else if (progressBlackmail && to_boolean(get_property("gingerNegativesDropped")) && !to_boolean(get_property("gingerBlackmailAccomplished")) && !have_item($item[gingerbread blackmail photos])) {
	//} else if (progressBlackmail && to_boolean(get_property("gingerNegativesGiven")) && !to_boolean(get_property("gingerBlackmailAccomplished")) && !have_item($item[gingerbread blackmail photos])) {
		noonChoice = 8;
		noonLoc = $location[Gingerbread Upscale Retail District];

	// complete the quest, get the briefcase full of sprinkles
	} else if (progressBlackmail && have_item($item[gingerbread blackmail photos])) {
		noonChoice = 4;
		noonLoc = $location[Gingerbread Civic Center];

	} else {
		// gingerbread dog treat
		noonLoc = $location[Gingerbread Upscale Retail District];
		noonChoice = 1;

		// outfit pieces gingerbread tophat, waistcoat, trousers (choice 4 or 5 or 6)
// 		fullAcquire($item[gingerbread dog treat]);
// 		noonLoc = $location[Gingerbread Upscale Retail District];
// 		noonChoice = 4;

		// pumpkin spice candle which allows getting broken chocolate pocketwatch
// 		fullAcquire($item[gingerbread dog treat]);
// 		noonLoc = $location[Gingerbread Upscale Retail District];
// 		noonChoice = 2;
	}


	// MIDNIGHT
	// get negatives
	if (progressBlackmail && to_boolean(get_property("gingerSubwayLineUnlocked")) && !to_boolean(get_property("gingerPhotoTaken"))) {
		midnightChoice = 4;
		midnightLoc = $location[Gingerbread Train Station];

	// lay track
	} else if (progressBlackmail && !to_boolean(get_property("gingerSubwayLineUnlocked"))) {
		midnightChoice = 1;
		midnightLoc = $location[Gingerbread Train Station];

	// study law
	} else if (progressBlackmail && to_int(get_property("gingerLawChoice")) < 3) {
		midnightChoice = 1;
		midnightLoc = $location[Gingerbread Civic Center];

	// dig
	} else if (progressBlackmail && have_item($item[teethpick]) && to_int(get_property("gingerDigCount")) < 7) {
		midnightChoice = 5;
		midnightLoc = $location[Gingerbread Train Station];

	} else {
		// counterfeit city
		midnightLoc = $location[Gingerbread Civic Center];
		midnightChoice = 2;

		// chocolate puppy (need dog treat)
// 		fullAcquire($item[gingerbread dog treat]);
// 		midnightLoc = $location[Gingerbread Civic Center];
// 		midnightChoice = 5;

		// high-end ginger wine
// 		cli_execute("outfit gingerbread best");
// 		set_property("choiceAdventure1209", "2");
// 		midnightLoc = $location[Gingerbread Upscale Retail District];
// 		midnightChoice = 1;

		// spare chocolate parts
// 		set_property("choiceAdventure1207", "2");
// 		midnightLoc = $location[Gingerbread Industrial Zone];
// 		midnightChoice = 1;
	}


	if (have_item($item[pumpkin spice candle])) {
		midnightLoc = $location[Gingerbread Train Station];
		midnightChoice = 2;
	}

// 	grindGingerbread(boolean takeShortcut, location morningLoc, int noonChoice, location eveningLoc, int midnightChoice);
	grindGingerbread(true, noonLoc, noonChoice, midnightLoc, midnightChoice);

	if (my_session_items($item[fruit-leather negatives]) > 0)
		set_property("gingerPhotoTaken", "true");
	if (daycount() > 7 && my_session_items($item[sugar raygun]) > 0) // pulling sugar raygun from storage increases session items, so ensure we are well out of ronin before setting the property
		set_property("gotSugarRaygun", "true");
}



// can we do something with these args?
void verifyArguments(string arguments) {
	string [int] argv = split_string(arguments, " ");

    if (count(argv) > 1)
        abort("gbc: too many arguments");
    if (count(argv) == 1 && argv[0] != "version" && argv[0] != "help"
        && argv[0] != "leaderboard" && argv[0] != "lb"
        && argv[0] != "prep" && argv[0] != "dressup"
        && argv[0] != "sprinkes" && argv[0] != "items" && argv[0] != "quest"
        && argv[0] != "win")
        abort("gbc: invalid argument");
}


void main(string arguments) {
	print("gbc args: " + arguments, "green");

	verifyArguments(arguments);

	string [int] argv = split_string(arguments, " ");
    switch (argv[0]) {
        case "dressup":
            gbcDressup(gkGrindLocation);
            break;
        case "prep": // includes dressup
            gbcPrep(gkGrindLocation);
            break;
        case "version":
            print("gbc v" + __gbc_version);
            break;
        case "help":
            printHelp();
            break;
        case "win":
            winSprinkles(costPerPercentIncrease);
            break;
        case "items":
            gingerGrind(1);
            break;
        case "quest":
            gingerGrind(-1);
            break;
        case "sprinkles":
            gingerGrind(0);
            break;
        case "leaderboard":
        case "lb":
            printGingerbreadLeaderboard();
            break;

        default:
            abort("gbc: should never get here");
    }
}
