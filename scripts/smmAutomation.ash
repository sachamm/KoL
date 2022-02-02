import <smmUtils.ash>
import <smmConsult.ash>
string __smm_automation_version = "0.3";


/*
To use the subroutines from this ASH file in the CLI, do this in the CLI:
using smmAutomation.ash;

You can then call any subroutine in this file from the command line. For example:
targetMob (The Haunted Bathroom, claw-foot bathtub, cannelloni cannon, 14, true, true);
NOTE this^ space between the name of the subroutine and the parenthesis is important for some reason

Subroutines without any params can be called without the empty parens (), e.g.:
voteMonsterNext;

To stop using this, do:
get commandLineNamespace
set commandLineNamespace =
(if you have other files that you are "using", the first command will show them -- you'll
have to re-"using" them after resetting the name space)
*/


// -------------------------------------
// DEFINES
// -------------------------------------

boolean kDoIgnoreCost = true;
boolean kDontIgnoreCost = false;
string kRedirectSavedEquipSetKey = "redirectSavedEquipSet";
string kTargetMobSavedEquipSetKey = "targetMobEquipSet";


// -------------------------------------
// AUTOMATION -- DRESSING
// -------------------------------------


// selects a familiar based on the given selector and returns a string appropriate for
// "maximize" to dress the familiar in the best equipment
//
// will read dressupFamiliarOverrideString and use that if set
string chooseFamiliar(string selector, location aLocation) {
	string rval;
	string overrideString = get_property("dressupFamiliarOverrideString");
	if (overrideString != "") {
		use_familiar(to_familiar(overrideString));
		return "";
	}

	matcher selectorMatcher = create_matcher(" \\[.*\\]", selector);
	string famSelector = replace_first(selectorMatcher, "");
	if (contains_text(selector, "[tracker]")) {
		if (have_effect($effect[On the Trail]) == 0) {
			use_familiar($familiar[Red-nosed Snapper]);
			return "";
		}
		// if we're already On The Trail, fall through and select the familiar based on the other part
	}

	// if the selector is empty, do nothing WRT familiars
	if (famSelector == "") {
		return "-familiar";

	// NO familiar
	} else if (contains_text(famSelector, "none")) {
		use_familiar($familiar[none]);
		return "";

	// [tracker] -- use the red-nosed snapper until we find what we're looking for, then back to our regular choice -- "guide me" MUST be set up by calling function
	}

	familiar familiarFromSelector = famSelector.to_familiar();

	// ITEM
	if (contains_text(famSelector, "item")) {
		rval = "switch Cat Burglar, switch Pocket Professor";
		if (have_item($item[li'l ninja costume])) {
			rval += ", switch Trick-or-Treating Tot";
			use_familiar($familiar[Trick-or-Treating Tot]);
		} else
			use_familiar($familiar[Cat Burglar]);
		return rval;

	// MEAT
	} else if (contains_text(famSelector, "meat")) {
		return "switch Trick-or-Treating Tot, switch Cat Burglar, switch Hobo Monkey";

	// -COMBAT
	} else if (contains_text(famSelector, "-combat")) {
		use_familiar($familiar[Disgeist]);
		return "switch Disgeist";

	// +COMBAT
	} else if (contains_text(famSelector, "+combat")) {
		use_familiar($familiar[Jumpsuited Hound Dog]);
		return "switch Jumpsuited Hound Dog";

	// FIGHT -- best default combat familiar
	} else if (contains_text(famSelector, "fight")) {
		use_familiar($familiar[Angry Goat]);
		return "switch Angry Goat";

	// MONSTER LEVEL
	} else if (contains_text(famSelector, "ml")) {
		use_familiar($familiar[Purse Rat]);
		return "switch purse rat";

	// INIT
	} else if (contains_text(famSelector, "init")) {
		use_familiar($familiar[Cute Meteor]);
		return "switch cute meteor";

	// PREVENT ATTACKS
	} else if (contains_text(famSelector, "prevent")) {
		if (have_item($item[God Lobster's Robe])) {
			use_familiar($familiar[God Lobster]);
			return "equip God Lobster's Robe";
		} else {
			use_familiar($familiar[Levitating Potato]);
			return "";
		}

	// ROBORTENDER -- custom for robortender because we want to specify the "bartend" switch setting
	} else if (contains_text(famSelector, "robortender")) {
 		use_familiar($familiar[robortender]);
 		doseRobortender();
		if (have_item($item[toggle switch (Bartend)]))
			return "equip toggle switch (Bartend)";

	// POCKET PROFESSOR -- custom for pocket professor because we want to get the friar's familiar buff
	} else if (contains_text(famSelector, "pocket professor")) {
 		use_familiar($familiar[Pocket Professor]);
		if (friars_available())
			cli_execute("friars familiar");
		if (have_item($item[Pocket Professor memory chip]))
			return "equip Pocket Professor memory chip";

	// ANY FAMILIAR NAME
	} else if (familiarFromSelector != $familiar[none]) {
		use_familiar(familiarFromSelector);
		item famItem = familiar_equipment(familiarFromSelector);
		if (have_item(famItem)) { // not sure if we really want to do this
			return "equip " + famItem;
		}

	// DEFAULT, will match anything else but expected to use selector = "default" by convention
	} else {
		// Garbage Fire if we're close enough to a drop
		if (to_float(get_property("garbageFireProgress")) / 30.0 > kPersueFamiliarIfOver) {
			use_familiar($familiar[Garbage Fire]);

		// Optimistic Candle if we're close enough to a drop
		} else if (to_float(get_property("optimisticCandleProgress")) / 30.0 > kPersueFamiliarIfOver) {
			use_familiar($familiar[Optimistic Candle]);

		// Cat Burglar if we're close enough to a heist
		} else if (combatsToNextCatBurglarHeist() <= 20.0 || progressToNextCatBurglarHeist() / combatsToNextCatBurglarHeist() > kPersueFamiliarIfOver) {
			use_familiar($familiar[Cat Burglar]);
			if (have_item($item[burglar/sleep mask]))
				return "equip burglar/sleep mask"; // adds a charge 50% of the time

		// Robortender if we haven't exhausted the RoboDrops (lowest drop chance after 10 drops)
		} else if (roboDropChanceForLocation(aLocation, false) > 0.25) {
			use_familiar($familiar[robortender]);
			doseRobortender();
			if (have_item($item[toggle switch (Bartend)]))
				return "equip toggle switch (Bartend)";

		} else {
			use_familiar($familiar[XO Skeleton]);
			//use_familiar($familiar[Melodramedary]);
			//use_familiar($familiar[Pocket Professor]);
		}

		return "equip ittah bittah hookah"; // default familiar equipment
	}

	return "";
}



string runMapChoice(string aPage, monster aMonster) {
	assert(aPage.contains_text("Leading Yourself Right to Them"), "runMapChoice: we aren't in the map choice adventure");

	aPage = visit_url("/choice.php?forceoption=0&option=1&pwd&whichchoice=1435&heyscriptswhatsupwinkwink=" + to_int(aMonster), true, false); // use post, not encoded

	aPage = visit_url("/main.php"); // get to the fight
	assert(aPage.contains_text("fight.php"), "runMapChoice: didn't get to a fight after the map choice");

	return aPage;
}



string weapon_maximizer_string() {
	if (my_class().primestat == $stat[moxie])
		return "-melee";
	else if (my_class().primestat == $stat[muscle])
		return "+melee";
	else
		return "";
}



// returns true if getting a wandering monster would be bad (because the wandering
// monster would consume a use of the broken champagne bottle)
boolean wanderingMonstersBad(string maxString) {
	return wantsToEquip(maxString, $item[broken champagne bottle]);
}


boolean voteMonsterNext() {
	return (total_turns_played() % 11 == 1 && to_int(get_property("lastVoteMonsterTurn")) != total_turns_played() && !inRonin());
}



// appends to existingMaxString a maximizer string that will equip an item that enables pickpocketing on non-moxie classes
// returns existingMaxString for moxie classes
string dressForPickpocket(location advLocation, string existingMaxString) {
	string maxString = existingMaxString;

	if (my_primestat() != $stat[moxie] && (advLocation == $location[none] || isPPUseful(advLocation))) {
		matcher minusCombatMatcher = create_matcher("-[0-9.]*? ?combat", existingMaxString);
		 // all the -combat gear are accessories(?) so if we want -combat, use the offhand item
		if (my_basestat($stat[moxie]) >= 200 && count_accessories(maxString) < 3
			&& !wantsToNotEquip(maxString, $item[mime army infiltration glove])
			&& (!find(minusCombatMatcher) || wantsToEquip(maxString, $slot[off-hand])))
			maxString = maxStringAppend(maxString, "equip mime army infiltration glove");
		else if (!wantsToEquip(maxString, $slot[off-hand]) && !wantsToNotEquip(maxString, $item[tiny black hole]))
			maxString = maxStringAppend(maxString, "equip tiny black hole");
	}

	return maxString;
}


void setDefaultMoodForLocation(location advLocation) {
	if (advLocation == $location[Infernal Rackets Backstage]) {
		setCurrentMood("-combat");
	}
}



// appends to existingMaxString a maximizer string that will enable adventuring in the given location and returns it.
// most locations will require nothing. Prototypical example is the pirate fledges required for adventuring in the Obligatory Pirate Cove
// since these are required items only, will not check if the existing maxString allows dressing with the returned item(s)
string maxStringForLocation(location advLocation, string maxString) { // #dressForLocation
	if (advLocation == $location[Barrrney's Barrr] || advLocation == $location[The F'c'le] || advLocation == $location[The Poop Deck] || advLocation == $location[Belowdecks]) {
		if (have_item($item[pirate fledges]))
			maxString = maxStringAppend(maxString, "equip pirate fledges");
		else if (have_outfit("Swashbuckling Getup"))
			maxString = maxStringAppend(maxString, "outfit Swashbuckling Getup");
		else
			abort("can't dress for location: " + advLocation);

	} else if (advLocation == $location[Inside the Palindome]) {
		if (have_item($item[Talisman o' Namsilat]))
			maxString = maxStringAppend(maxString, "equip Talisman o' Namsilat");
		else
			abort("can't dress for location: " + advLocation);

	} else if (advLocation == $location[infernal Rackets Backstage]) {
		if ( !(get_property("questM10Azazel") == "finished" || have_item($item[Azazel's unicorn])))
			maxString = maxStringAppend(maxString, "-10 combat");

	} else if (advLocation == $location[8-Bit Realm]) {
		if (have_item($item[continuum transfunctioner]))
			maxString = maxStringAppend(maxString, "equip continuum transfunctioner");
		else
			abort("can't dress for location: " + advLocation);
	}

	return maxString;
}


// appends to existingMaxString a maximizer string that will enable olfacting and returns it.
string dressForOlfaction(location advLocation, string existingMaxString) {
	return "";
}


string maximizerStringForDressup(location advLocation, string selector, string additionalMaxString) {
	assert(selector != "", "maximizerStringForDressup: blank selector");

	// TRACKER SELECTOR
	// remove the "[tracker]" bit if it is present
	matcher selectorMatcher = create_matcher(" \\[.*\\]", selector);
	selector = replace_first(selectorMatcher, "");
	string maxString = maxStringAppend(selector, additionalMaxString);

	// LOCATION-SPECIFIC items
	maxString = maxStringForLocation(advLocation, maxString);

	// IN RONIN
	if (inRonin()) {
	}

	boolean highChanceOfSausageGoblin = (chanceOfSausageGoblinNextTurn() > 0.20 && to_int(get_property("_sausageFights")) < kSausagesToGet) || chanceOfSausageGoblinNextTurn() > 0.50;
	boolean lowChanceOfSausageGoblin = (chanceOfSausageGoblinNextTurn() > 0.10 && to_int(get_property("_sausageFights")) < kSausagesToGet) || chanceOfSausageGoblinNextTurn() > 0.25;
	// HIGH CHANCE OF SAUSAGE GOBLINS, the kramco gets priority in the off-hand
	if (!inRonin() && highChanceOfSausageGoblin && countHandsUsed(maxString) < 2 && !wanderingMonstersBad(maxString)
			&& !wantsToEquip(maxString, $slot[off-hand]) && !wantsToNotEquip(maxString, $item[Kramco Sausage-o-Matic&trade;])) {
		maxString = maxStringAppend(maxString, "equip Kramco Sausage-o-Matic&trade;");
	}

	// LATHE MAPLE MAGNET
	if (have_item($item[maple magnet]) && countHandsUsed(maxString) < 2
			&& (advLocation == $location[Dreadsylvanian Woods] || advLocation == $location[The Smut Orc Logging Camp] || advLocation == $location[The Purple Light District] || advLocation == $location[The Mouldering Mansion] || advLocation == $location[The Stately Pleasure Dome] || advLocation == $location[The Rogue Windmill] || advLocation == $location[The Jungles of Ancient Loathing] || advLocation == $location[The Dripping Trees])
			&& !wantsToEquip(maxString, $slot[off-hand]) && !wantsToNotEquip(maxString, $item[maple magnet]))
		maxString = maxStringAppend(maxString, "equip maple magnet");

	// PICKPOCKET-ENDABLING ITEM
	maxString = dressForPickpocket(advLocation, maxString);

	// VOTE MONSTER
	// equip the i voted sticker if we can get a free fight, or if we are in aftercore
	// if we're not in aftercore and we don't have any more free fights, ensure we aren't
	// wearing the sticker if it might trigger a wandering monster
	if (voteMonsterNext() && !wanderingMonstersBad(maxString) && !wantsToNotEquip(maxString, $item[&quot;I Voted!&quot; sticker])
		&& (!freeWanderingMonstersOnly() || to_int(get_property("_voteFreeFights")) < 3)
		&& count_accessories(maxString) < 3) {
		maxString = maxStringAppend(maxString, "equip \"i voted\" sticker");
		// no point in the thumb ring if it is a free fight
		if (to_int(get_property("_voteFreeFights")) < 3 && !wantsToEquip(maxString, $item[mafia thumb ring]))
			maxString = maxStringAppend(maxString, "-equip mafia thumb ring");
	}

	// GARBAGE TOTE ITEMS: BROKEN CHAMPAGNE BOTTLE
	if (!wantsToEquip(maxString, $item[broken champagne bottle]) && !wantsToNotEquip(maxString, $item[broken champagne bottle])) // unless explicitly asked for, don't equip broken champagne bottle
		maxString = maxStringAppend(maxString, "-equip broken champagne bottle");
	else if (wantsToEquip(maxString, $item[broken champagne bottle])) { // if we're equipping the champagne bottle, equip all the +item stuff
		int champagneChargesAvailable = to_int(get_property("garbageChampagneCharge"));
		int otoscopeChargesAvailable = 3 - to_int(get_property("_otoscopeUsed"));
		int cloakChargesAvailable = 10 - to_int(get_property("_vampyreCloakeFormUses"));

		if (available_amount($item[broken champagne bottle]) == 0 || (champagneChargesAvailable == 0 && !to_boolean(get_property("_garbageItemChanged")))) {
			cli_execute("tote 2");
			champagneChargesAvailable = to_int(get_property("garbageChampagneCharge"));
		}
		if (otoscopeChargesAvailable > 0 && count_accessories(maxString) < 3) {
			maxString += ", +equip Lil' Doctor&trade; bag";
		}
		if (cloakChargesAvailable > 0 && !wantsToEquip(maxString, $slot[back])) {
			maxString += ", +equip vampyric cloake";
		}
	} else if (have_item($item[broken champagne bottle]) && !to_boolean(get_property("_garbageItemChanged")) && to_int(get_property("garbageChampagneCharge")) > 0) // do not switch to another tote item! we have champagne charges leftover from yesterday
		maxString = maxStringAppend(maxString, "-equip wad of used tape, -equip makeshift garbage shirt");

	// MISC
	// if we're in aftercore, get hilarity drops, free fights, fishing, and doctor bag quests
	if (!inRonin()) {
		if (isOysterDay()) {
			if (!wantsToEquip(maxString, $slot[off-hand]) && !wantsToNotEquip(maxString, $item[oyster basket]) && countHandsUsed(maxString) < 2)
				maxString = maxStringAppend(maxString, "equip oyster basket");
		}
		// if we restarted mafia, the aerogelAttacheCaseItemDrops count will be off so just don't equip if we've restarted
		if (!haveRestartedMafia() && aerogelAttacheCaseItemDrops() < 5 && !wantsToEquip(maxString, $slot[off-hand]) && !wantsToNotEquip(maxString, $item[aerogel attache case]) && countHandsUsed(maxString) < 2 && have_effect($effect[Fishy]) == 0)
			maxString = maxStringAppend(maxString, "equip aerogel attache case");

		// only need to wear the bag on the one turn that the quest comes up but not sure how to calc that
		if (to_boolean(get_property("_wantLilDoctorBagQuest")) && get_property("questDoctorBag") == "unstarted" && count_accessories(maxString) < 3 && !wantsToNotEquip(maxString, $item[Lil' Doctor&trade; bag]))
			maxString = maxStringAppend(maxString, "equip Lil' Doctor&trade; bag");

		// FISHING
		if (isFloundryLocation(advLocation)) {
			if (!wantsToEquip(maxString, $slot[pants]) && !wantsToNotEquip(maxString, $item[government-issued slacks]))
				maxString = maxStringAppend(maxString, "equip government-issued slacks");
			if (!wantsToEquip(maxString, $slot[hat]) && !wantsToNotEquip(maxString, $item[fishin' hat]))
				maxString = maxStringAppend(maxString, "equip fishin' hat");
		}

		if (!wantsToEquip(maxString, $slot[pants]) && !wantsToNotEquip(maxString, $item[pantogram pants]))
			maxString = maxStringAppend(maxString, "equip pantogram pants");
	}

	// MAFIA THUMB RING
	// if we have room and the item, equip the thumb ring
	if (count_accessories(maxString) < 3 && have_item($item[mafia thumb ring]) && !wantsToNotEquip(maxString, $item[mafia thumb ring]) && can_equip($item[mafia thumb ring]))
		maxString = maxStringAppend(maxString, "equip mafia thumb ring");

	// if we don't have anything in the off-hand, equip the kramco if we have a 20% chance of a sausage goblin
	if (!inRonin() && lowChanceOfSausageGoblin && countHandsUsed(maxString) < 2 && !wanderingMonstersBad(maxString)
			&& !wantsToEquip(maxString, $slot[off-hand])
			&& !wantsToNotEquip(maxString, $item[Kramco Sausage-o-Matic&trade;])) {
		maxString = maxStringAppend(maxString, "equip Kramco Sausage-o-Matic&trade;");
	}

	// melee vs ranged -- need to be careful with vote monsters as they scale, done last in case we equip any weapons during auto dressup
	if (!wantsToEquip(maxString, $slot[weapon])) {
		if (my_primestat() == $stat[muscle]) {
			if (my_class() == $class[seal clubber] && have_effect($effect[Fishy]) == 0) {
// 				if (have_effect($effect[Iron Palms]) > 0)
// 					maxString = maxStringAppend(maxString, "type club, type sword");
// 				else					
// 				maxString = maxStringAppend(maxString, "type club");
			} else
				maxString = maxStringAppend(maxString, "melee");
		} else if (my_primestat() == $stat[moxie] && !wantsToEquipMelee(maxString)) {
			if (my_class() == $class[accordion thief])
				maxString = maxStringAppend(maxString, "type accordion");
			else
				maxString = maxStringAppend(maxString, "-melee");
		}
	}

	return maxString;
}

// if selector is empty, doesn't make any changes to the max string (other than the tweak string when dressup(string tweak) calls this)
void dressup(location advLocation, string selector, string familiarSelector, string additionalMaxString) {
	string kDressupOutfitPrefixKey = "_smm.DressupTmp: ";
	if (advLocation != $location[none])
		set_location(advLocation);

	string maxString;
	if (selector != "")
		maxString = maximizerStringForDressup(advLocation, selector, additionalMaxString);
	else
		maxString = additionalMaxString;

	string familiarMaxString;
	if (!additionalMaxString.contains_text("-familiar"))
		familiarMaxString = chooseFamiliar(familiarSelector, advLocation);
	if (!wantsToEquip(familiarMaxString, $slot[familiar]) || !wantsToEquip(maxString, $slot[familiar])) {
		maxString = maxStringAppend(maxString, familiarMaxString);
	}

	print("dressup: max string: " + maxString, "blue");

	if (maxString == get_property(kDressupLastFullMaxStringKey) && !get_property(kForceDressupKey).to_boolean()) {
		print("skipping maximize for same max string, restoring existing dressup instead", "blue");
		restoreOutfit(true, kDressupOutfitPrefixKey + maxString);
	} else {
		set_property(kDressupLastFullMaxStringKey, maxString);
		saveAndSetProperty("maximizerMRUSize", 0); // TODO try to avoid log spam with this shit
		try {
			// first see if have an outfit saved for this maxString, and switch to it if we do.
			// if not, do an initial maximize and unequip and retry if that fails.
			if (haveOutfit(kDressupOutfitPrefixKey + maxString)) {
				restoreOutfit(true, kDressupOutfitPrefixKey + maxString);
			} else if (!maximize(maxString, false)) {
				unequipAll(false); // don't need to unequip familiar
				maximize(maxString, false);
			}
			// finally, do a maximize with a close-to-right outfit and see if there's a tweak
			if (!maximize(maxString, false))
				abort("dressup: maximizer failed");
			saveOutfit(kDressupSavedEquipSetKey);
			saveOutfit(kDressupOutfitPrefixKey + maxString);
			set_property(kForceDressupKey, "false");
		} finally {
			restoreSavedProperty("maximizerMRUSize");
		}
	}

	// ensure any valuable items we took off are stowed safely
	// stow_pvpable_items(); // not useful if we have anything we want to use in combat
}

// add tweak to the automated dressup string and wear it
void dressup(string tweak, boolean replaceExistingTweak) {
	string tempTweak = get_property(kDressupTweakStringKey);
	if (tempTweak != "" && !replaceExistingTweak) {
		tweak = maxStringAppend(tempTweak, tweak);
	}

	set_property(kDressupTweakStringKey, tweak);
	string locationString = get_property(kDressupLocationKey);
	location theLocation = to_location(locationString);
	string dressupMaxString = get_property(kDressupMaxStringKey);

	if ((locationString == "" || locationString == "none" || theLocation == my_location()) && dressupMaxString != "") {
		dressup(theLocation, get_property(kDressupSelectorKey), get_property(kDressupFamiliarSelectorKey), maxStringAppend(dressupMaxString, tweak));
	} else
		print("wrong location (stored loc: \"" + locationString + "\", my loc: \"" + my_location() + "\") OR no max string, skipping dressup", "orange");
}

void dressup(string tweak) {
	dressup(tweak, true);
}

void dressup() {
	dressup("");
}

// never skip the actual maximize
void forceDressup() {
	set_property(kForceDressupKey, "true");
}


boolean isAutomatingDressup() {
	return get_property(kDressupLocationKey) != "" || get_property(kDressupSelectorKey) != "" || get_property(kDressupFamiliarSelectorKey) != "" || get_property(kDressupMaxStringKey) != "";
}

boolean sameAutomatedDressup(location advLocation, string selector, string familiarSelector, string additionalMaxString) {
	return to_location(get_property(kDressupLocationKey)) == advLocation && get_property(kDressupSelectorKey) == selector && get_property(kDressupFamiliarSelectorKey) == familiarSelector || get_property(kDressupMaxStringKey) == additionalMaxString;
}

void clear_automate_dressup() {
	set_property(kDressupLocationKey, "");
	set_property(kDressupSelectorKey, "");
	set_property(kDressupFamiliarSelectorKey, "");
	set_property(kDressupMaxStringKey, "");
	set_property(kDressupLastFullMaxStringKey, "");
	set_property(kDressupTweakStringKey, "");
}

void clearAutomateDressup() {
	clear_automate_dressup();
}

void backupAutomatedDressup(string backupKey) {
	string backupKeyToUse = backupKey;
	if (!backupKey.starts_with("_"))
		backupKeyToUse = "_" + backupKeyToUse;
	set_property(backupKeyToUse + kDressupLocationKey, get_property(kDressupLocationKey));
	set_property(backupKeyToUse + kDressupSelectorKey, get_property(kDressupSelectorKey));
	set_property(backupKeyToUse + kDressupFamiliarSelectorKey, get_property(kDressupFamiliarSelectorKey));
	set_property(backupKeyToUse + kDressupMaxStringKey, get_property(kDressupMaxStringKey));
	set_property(backupKeyToUse + kDressupLastFullMaxStringKey, get_property(kDressupLastFullMaxStringKey));
	set_property(backupKeyToUse + kDressupTweakStringKey, get_property(kDressupTweakStringKey));

	saveOutfit(backupKeyToUse + "_outfit");
}

void restoreAutomatedDressup(string backupKey) {
	string backupKeyToUse = backupKey;
	if (!backupKey.starts_with("_"))
		backupKeyToUse = "_" + backupKeyToUse;
	set_property(kDressupLocationKey, get_property(backupKeyToUse + kDressupLocationKey));
	set_property(kDressupSelectorKey, get_property(backupKeyToUse + kDressupSelectorKey));
	set_property(kDressupFamiliarSelectorKey, get_property(backupKeyToUse + kDressupFamiliarSelectorKey));
	set_property(kDressupMaxStringKey, get_property(backupKeyToUse + kDressupMaxStringKey));
	set_property(kDressupTweakStringKey, get_property(backupKeyToUse + kDressupTweakStringKey));
	set_property(kDressupLastFullMaxStringKey, get_property(backupKeyToUse + kDressupLastFullMaxStringKey));

	saveOutfit(backupKeyToUse, get_property(backupKeyToUse + "_outfit"));
}


string fixupCLArtifacts(string maximizerString) {
	return maximizerString.replace_string("|", ",");
}


// 
void overrideAutomateDressup() {
}



// sets up automation for dressing:
// 1. will equip various useful and/or fun items like the pantogram pants
//    will respect any "-equip <item>" that shows up in additionalMaxString, so you can tweak the automation, won't detect categories of items or outfits
//    will not equip any useful/fun items automatically if item_selector is blank, useful to get redirect automation without the fun items taking up valuable slots
// 2. will automatically equip the "i voted" sticker every 11 turns unless -equip "i voted" sticker is specified in additionalMaxString
// 3. can be tweaked on the fly using the dressup(string tweak) function, which will add the tweak string as a maximizer string to the original automation
//
// the cli doesn't play well with string params if they have commas in them so use
// pipe "|" instead of commas in additionalMaxString
//
// aLocation is the location to trigger the automation, or none or blank to trigger always -- note that the current location is set to this before the maximize function is called, which may optimize the behaviour of maximize
// item_selector determines the mode that dressup will use, usually corresponds to a maximizer string, such as "item" or "item 234 max"
//     leave blank for no automation in dressup (redirect automation will still occur)
// familiar_selector determines the familiar and will modify the maximizer string to ensure the chosen familiar is either equipped properly or isn't touched, see chooseFamiliar for more info
// additionalMaxString is the catch-all for the rest of the maximizer string -- this will be parsed so that automation will respect not equipping specific items
//
// will append any string in the dressupGlobalTweakString preference/property to the max string
void automate_dressup(location aLocation, string item_selector, string familiar_selector, string additionalMaxString) {
	clear_automate_dressup();
	//if (aLocation != $location[none])
	//	set_location(aLocation);

	string parsed_additionalMaxString = fixupCLArtifacts(additionalMaxString);
	parsed_additionalMaxString = maxStringAppend(parsed_additionalMaxString, get_property("dressupGlobalTweakString"));
	dressup(aLocation, item_selector, familiar_selector, parsed_additionalMaxString);

	set_property(kDressupLocationKey, to_string(aLocation));
	set_property(kDressupSelectorKey, item_selector);
	set_property(kDressupFamiliarSelectorKey, familiar_selector);
	set_property(kDressupMaxStringKey, parsed_additionalMaxString);
}



// returns the location we should go when we do a wandering-monster redirect
// this should be the most important place to burn delay
location redirectionDelayLocation() { // locationfordelay
	// AZAZEL we need non-combats, don't do if we finished, have the unicorn or we have all 4 items
	if ( !(get_property("questM10Azazel") == "finished" || have_item($item[Azazel's unicorn])
		|| (have_item($item[comfy pillow]) && have_item($item[giant marshmallow]) && have_item($item[beer-scented teddy bear]) && have_item($item[booze-soaked cherry])) )) {
		return $location[infernal rackets backstage];
	}

	// GUILD
	if (get_property("questG07Myst") == "started")
		return $location[The Haunted Pantry];
	if (get_property("questG08Moxie") == "started")
		return $location[The Sleazy Back Alley];
	if (get_property("questG09Muscle") == "started")
		return $location[The Outskirts of Cobb's Knob];

	if (get_property("questG04Nemesis") == "started")
		return $location[The Unquiet Garves];

	if (get_property("questG04Nemesis") == "step5" && $location[The "Fun" House].turns_spent < 10)
		return $location[The "Fun" House];

	// TODO add latte unlock locs

	// PAGODA -- hey deze map is a superlikely, so adventure there until we get it
	if ( !(have_item($item[hey deze map]) || (get_campground() contains $item[pagoda plans])))
		return $location[pandamonium slums];
	// Pagoda -- elf farm raffle ticket, want -combat
	if ( !(have_item($item[elf farm raffle ticket]) || (get_campground() contains $item[pagoda plans])) && have_item($item[Talisman o' Namsilat]))
		return $location[inside the palindome];

	// TODO poop deck

	// TODO zap wand

	// GUZZLR gold or platinum quest -- gold and platinum get precedence, see below for bronze
	item guzItem = to_item(get_property("guzzlrQuestBooze"));
	location guzLoc = to_location(get_property("guzzlrQuestLocation"));
	string guzTier = get_property("guzzlrQuestTier");
	if (guzItem != $item[none] && guzLoc != $location[none] && (guzTier == "gold" || guzTier == "platinum")) {
		if (isUnlocked(guzLoc)) {
			fullAcquire(guzItem);
			return guzLoc;
		} else {
			if (!get_property("_smm.GuzzlrLocationLockedWarningDone").to_boolean()) {
				set_property("_smm.GuzzlrLocationLockedWarningDone", "true");
				abort(guzLoc + " is not yet unlocked");
			}
		}
	}

	// for the A Quest, LOL quest
	if ($location[The Valley of Rof L'm Fao].turns_spent < 10)
		return $location[The Valley of Rof L'm Fao];

	// GUZZLR bronze quest
	if (guzItem != $item[none] && guzLoc != $location[none]) {
		if (isUnlocked(guzLoc)) {
			fullAcquire(guzItem);
			return guzLoc;
		} else {
			if (!get_property("_smm.GuzzlrLocationLockedWarningDone").to_boolean()) {
				set_property("_smm.GuzzlrLocationLockedWarningDone", "true");
				abort(guzLoc + " is not yet unlocked");
			}
		}
	}

	// default is to go to the smut orc logging camp to get smut orc pervert
	int turnsToPervert = 19 - smutOrcPervertProgress();
	if (turnsToPervert == 0)
		if (!user_confirm(turnsToPervert + " turns to Smut Orc Pervert, " + $location[The Smut Orc Logging Camp].turns_spent + " turns spent -- adventuring here will overwrite it. Continue?", 60000, false))
			abort();
	print("vote monster next, adventuring in Smut Orc Logging Camp instead. Progress to pervert BEFORE adventure: " + smutOrcPervertProgress(), "orange");
	return $location[The Smut Orc Logging Camp];
}


// Adventure with advURL() (which means doing the same pre-automation that adventure() does, but without the turn automation or post-automation)
// but automatically redirects known wandering monsters to areas with delay
// Useful for when adventuring in an area where burning delay is not useful
// first try: will redirect vote monsters to the smut orc chasm so that we can get smut orc perverts essentially for free
// the adventure itself and post-adv checks have to be done by the caller
// if we redirected, the caller may also have to re-dress -- recommend saving the outfit after dressup() and then restoring after calling this
string advURLWithWanderingMonsterRedirect(location aLocation) {
	location actualLocation = aLocation;
	string dressupMaxString = get_property(kDressupMaxStringKey);
	preAdventureChecks(); // need this here so any potential maximize before an adv (esp. combat freq) gets the benefit of our mood -- also useful to stop before redressing if there's a trigger

	string maxString;
	string redirectOutfitSelector = "exp";
	string redirectFamiliarSelector = "default";

	// REDIRECT
	if (!inRonin()) { // no redirect in ronin, ever

		// SAUSAGE GOBLIN
		if (chanceOfSausageGoblinNextTurn() >= 1.0) {
			actualLocation = redirectionDelayLocation();
			redirectOutfitSelector = "5 item";
			redirectFamiliarSelector = "space jellyfish";
			maxString = "exp, equip Kramco Sausage-o-Matic&trade;, -equip mafia thumb ring";
			print("advURLWithWanderingMonsterRedirect: redirecting to " + actualLocation + " for a sausage goblin", "red");

		// VOTE MONSTER -- might take a turn
		} else if (voteMonsterNext() && (!freeWanderingMonstersOnly() || to_int(get_property("_voteFreeFights")) < 3)) {
			monster voteMonster = get_property("_voteMonster").to_monster();
			// equip the i voted sticker if we can get a free fight, or if we are in aftercore
			if (voteMonsterNext() && !wanderingMonstersBad(dressupMaxString) && !wantsToNotEquip(dressupMaxString, $item[&quot;I Voted!&quot; sticker]) && (!freeWanderingMonstersOnly() || to_int(get_property("_voteFreeFights")) < 3) && count_accessories(dressupMaxString) < 3) {
				maxString = "equip \"i voted\" sticker";

				// VOTE MONSTER REDIRECTION LOCATION
				actualLocation = redirectionDelayLocation();

				// VOTE MONSTER OUTFIT
				if (voteMonster == $monster[terrible mutant])
					maxString = maxStringAppend(maxString, ""); // equip nothing = get mutant arm
// 				if (voteMonster == $monster[terrible mutant] && available_amount($item[mutant arm]) > 0 && countHandsUsed(maxString) < 2) // equip the mutant arm to get the mutant legs
// 					maxString = maxStringAppend(maxString, "+equip mutant arm"); // equip mutant arm = get mutant leg
// 				if (voteMonster == $monster[terrible mutant] && available_amount($item[mutant legs]) > 0 && !wantsToEquip(maxString, $slot[pants])) // equip the mutant legs to get the mutant crown
// 					maxString = maxStringAppend(maxString, "+equip mutant legs"); // equip mutant leg = get mutant crown

				if (voteMonster == $monster[terrible mutant]
					|| voteMonster == $monster[angry ghost]
					|| voteMonster == $monster[government bureaucrat]
					|| voteMonster == $monster[slime blob]) {
					redirectOutfitSelector = "100 item";
					redirectFamiliarSelector = "item";
				}
			}
			print("advURLWithWanderingMonsterRedirect: redirecting to " + actualLocation + " for a vote monster: " + voteMonster, "red");

		// PERVERT -- takes a turn, do last
		} else if (smutOrcPervertProgress() >= 19) {
			maxString = "5 exp, -ml";
			if (have_item($item[broken champagne bottle]))
				maxString += ", -equip makeshift garbage shirt";
			actualLocation = $location[The Smut Orc Logging Camp];
			print("advURLWithWanderingMonsterRedirect: getting smut orc pervert instead", "red");
		}
	}

	// CHANGE OUTFIT IF REDIRECTING
	if (actualLocation != aLocation) {
// 		maximize(maxString, false);
		// save and restore the automated dressup settings that got us to our current outfit
		backupAutomatedDressup(kRedirectSavedEquipSetKey);
		maxString = maxStringAppend(maxString, "-equip broken champagne bottle");
		automate_dressup(actualLocation, redirectOutfitSelector, redirectFamiliarSelector, maxString);
		restoreAutomatedDressup(kRedirectSavedEquipSetKey);
	}

	// ADVENTURE
	string aPage = advURL(actualLocation);

	if (actualLocation == $location[The Smut Orc Logging Camp] && aPage.contains_text("fight.php")) {
		setSmutOrcPervertProgress(smutOrcPervertProgress() + 1);
		print("setting smutOrcPervertProgress to: " + smutOrcPervertProgress() + ", turns spent in zone: " + $location[The Smut Orc Logging Camp].turns_spent + ", turns in zone for last pervert: " + to_int(get_property(kLastSmutOrcPervertTurnsSpentKey)));
	}

	return aPage;

	// the adventure itself and post-adv checks have to be done by the caller
	// if we redirected, the caller will also have to re-dress, which it can do with restoreOutfit(kRedirectSavedEquipSetKey, true);
}



// replicates the full automation of adventure() but with automatic redirect of known wandering monsters to areas with delay
// the redirect is handled by advURLWithWanderingMonsterRedirect(), see that above for specifics of what is getting redirected
// returns true if we adventured in the specified location, false otherwise (redirect or failed adv or incomplete adventure/still in a choice/still in a fight)
boolean redirectAdventureHelper(location aLocation, string scriptString) {
	assert(aLocation != $location[none], "redirectAdventure(location, string): can't adventure at location none");

	print("redirectAdventure: base location: " + aLocation + ", script: " + scriptString, "green");
	boolean hadGoals = haveGoals(); // if have goals now and not later, presumably they're completed

	boolean rval = false;

	preAdventureChecks(); // need this here so any potential maximize before an adv (esp. combat freq) gets the benefit of our mood
	dressup(); // may equip something (e.g. i voted sticker)
	saveOutfit(kRedirectSavedEquipSetKey);

	try {
		string pageString = advURLWithWanderingMonsterRedirect(aLocation);
		rval = my_location() == aLocation;

		// ERROR?
		if (isErrorPage(pageString)) {
// 			print("got an error page:\n" + aPage, "red"); // debugging new types of error pages
			abort("error page at adventure location: " + aLocation);

		// CHOICE
		} else if (handling_choice() || choice_follows_fight()) {
			run_choice(-1);
			assert(!handling_choice(), "still handling a choice"); // TODO choice follow fight

		// "NO ACTION" ADVENTURE (?)
		} else if (!contains_text(pageString, "fight.php")) {
			print("detected 'no action' adventure", "orange");

		// FIGHT
		} else {
			if (my_location() == aLocation) {
				print("executing script: " + scriptString, "green");
				run_combat(scriptString);
			} else // if we redirect, don't use the passed-in script
				run_combat();
			rval = rval && !inCombat();

			if (choice_follows_fight()) {
				run_choice(-1);
				rval = rval && !handling_choice();
			}
		}

	} finally {
		postAdventure();
		if (hadGoals && !haveGoals())
			abort("redirectAdventureHelper: goals completed!");
		restoreOutfit(true, kRedirectSavedEquipSetKey); // will usually be the same outfit, unless we redirected
		if (my_location() != aLocation)
			set_location(aLocation); // required because after a redirection, the location setting will be incorrect
	}

	return rval;
}

// replicates the full automation of adventure() but with automatic redirect of known wandering monsters to areas with delay
// the redirect is handled by advURLWithWanderingMonsterRedirect(), see that above for specifics of what is getting redirected
// returns true if we adventured in the specified location at least once, false otherwise
// all adventures count against the number of adventures done, even if they take no turns
boolean redirectAdventure(location aLocation, int adventures, string scriptString) {
	assert(aLocation != $location[none], "redirectAdventure(location, string, int): can't adventure at location none");
	boolean rval = false;

	if (inRonin()) { // no redirect in ronin, ever
		boolean adventureWasSuccessful = adventure(adventures, aLocation);
		assert(adventureWasSuccessful, "redirectAdventure (in ronin!): failed adventuring in " + aLocation);
		return true;
	}

	int adventuresDone = 1;
	int failCounter = 3;
	while (adventuresDone < (adventures + 1) && failCounter > 0) {
		print("adventure #" + adventuresDone + " at " + aLocation, "green");
		if (redirectAdventureHelper(aLocation, scriptString)) {
			rval = true; // if we adventured even once in aLocation, return true
		} else
			failCounter--;
		adventuresDone++;
	}

	return rval;
}

// replicates the full automation of adventure() but with automatic redirect of known wandering monsters to areas with delay
// the redirect is handled by advURLWithWanderingMonsterRedirect(), see that above for specifics of what is getting redirected
boolean redirectAdventure(location aLocation, string scriptString) {
	assert(aLocation != $location[none], "redirectAdventure(location, int): can't adventure at location none");
	return redirectAdventure(aLocation, 1, scriptString);
}

boolean redirectAdventure(location aLocation, int adventures) {
	assert(aLocation != $location[none], "redirectAdventure(location, int): can't adventure at location none");
	return redirectAdventure(aLocation, adventures, "");
}

void ra(location aLocation, int adventures) {
	redirectAdventure(aLocation, adventures);
}



// -------------------------------------
// AUTOMATION -- target mob
// -------------------------------------

// returns a script for olfacting the given monster
string olfactionScript(monster aMonster) {
	string rval = "";
	if (to_monster(get_property("olfactedMonster")) != aMonster
		&& user_confirm("We'd like to olfact " + aMonster + ", previous olfact target: " + get_property("olfactedMonster") + ". Proceed?", 60000, true))
		rval += "skill Transcendent Olfaction;";
	if (to_monster(get_property("_gallapagosMonster")) != aMonster)
		rval += "skill Gallapagosian Mating Call;";
	if ((to_monster(get_property("_latteMonster")) != aMonster) && (have_skill($skill[Offer Latte to Opponent])))
		rval += "skill Offer Latte to Opponent;";
	if ((to_monster(get_property("nosyNoseMonster")) != aMonster) && (have_skill($skill[Get a Good Whiff of This Guy])))
		rval += "skill Get a Good Whiff of This Guy;";
	return rval;
}

void olfaction(monster a_monster) {
	if (to_monster(get_property("olfactedMonster")) != a_monster
		&& user_confirm("We'd like to olfact " + a_monster + ", previous olfact target: " + get_property("olfactedMonster") + ". Proceed?", 60000, true))
		use_skill($skill[Transcendent Olfaction]);
	if (to_monster(get_property("_gallapagosMonster")) != a_monster) {
		use_skill($skill[Gallapagosian Mating Call]);
		//set_property("gallapagosMonster", a_monster); // something broke?
	}
	if ((to_monster(get_property("_latteMonster")) != a_monster) && (have_skill($skill[Offer Latte to Opponent]))) {
		use_skill($skill[Offer Latte to Opponent]);
		//set_property("_latteMonster", a_monster); // something broke?
	}
	if ((to_monster(get_property("nosyNoseMonster")) != a_monster) && (have_skill($skill[Get a Good Whiff of This Guy])))
		use_skill($skill[Get a Good Whiff of This Guy]);
}


// returns true if we fought the main target and won, false otherwise
boolean targetMobFightHelper(location aLocation, monster [] target_monsters, skill skillToUse, int maxPerTurnCost, boolean optimal, boolean shouldOlfact) {
	// COMBAT at this point we should be in combat
	assert(inCombat(), "targetMobFightHelper: should be in combat, but we aren't");

	 // the max number of non-targets we want unbanished, 1 if we can replace or 0 otherwise
	int maxNonTargetsUnbanished = 0;
	if (have_skill($skill[Macrometeorite]) || item_amount($item[fish-oil smoke bomb]) > 0) maxNonTargetsUnbanished = 1;
	int unbanishedNonTargets = unbanishedNonTargets(aLocation, target_monsters);

	// REPLACE/BANISH
	// don't replace a wandering monster, drop through to combat processing, remembering that banish / replace may not result in actually getting a target monster
	if (!contains_monster(aLocation, last_monster())) {
		print("looks like we're in combat with a wandering monster", "blue");

	// we can usefully replace or banish the monster we're in combat with
	} else if (!arrayContains(target_monsters, last_monster())) {

		// REPLACE: if there is exactly 1 unbanished, non-target monster and we get the wrong monster
		print("unbanished non-targets during combat: " + unbanishedNonTargets, "blue");
		if (canReplaceMonster() && unbanishedNonTargets == 1) { // if you replace when there is more than 1 unbanished target (even if olfacted), you have a high chance of not getting the target (due to KoL adventure queue)
			visit_url("/fight.php?action=steal", true, false); // pickpocket if able
			use_skill($skill[Macrometeorite]);
			// should be caught below and kill the target (optionally with the skillToUse)

		// FREE-RUNAWAY
		} else if (unbanishedNonTargets > maxNonTargetsUnbanished && item_amount($item[fish-oil smoke bomb]) > 0) {
			visit_url("/fight.php?action=steal", true, false); // pickpocket if able
			throw_item($item[fish-oil smoke bomb]);
			return false;

		// BANISH
		} else {
			SkillRecord banisher = banishToUse(aLocation, maxPerTurnCost);

			if (banisher.skillToUse != $skill[none]) {
				print("RECOMMENDING BANISHER: " + banisher.skillToUse, "green");
				visit_url("/fight.php?action=steal", true, false); // pickpocket if able
				use_skill(banisher.skillToUse);
				assert(!inCombat(), "targetMobFightHelper: tried to banish, but we're still in combat");
				return false;

			// can't replace and can't banish
			} else {
				if (optimal)
					abort("Can't banish OR macro!");
				else
					print("WARNING: Can't banish OR macro!", "orange");
			}
		}

	} else {
		print("We should be in combat with a target monster", "green");
	}

	// TARGET MONSTER
	if (arrayContains(target_monsters, last_monster())) {
		if (target_monsters[0] == last_monster()) {

			// OLFACT
			if (shouldOlfact)
				olfaction(last_monster());

			// SKILL TO USE
			if (skillToUse != $skill[none]) {
				use_skill(skillToUse);
				// special case if the skill is Use the Force, which drops us into a choice adventure
				if (choice_follows_fight())
					print("WARNING: choice follows skill used: " + skillToUse + "!", "red");
				if (skillToUse == $skill[Use the Force]) {
					visit_url("/main.php", true, false);
					run_choice(3);
				}
			}
		}

		// FIGHT
		run_combat();
		assert(!inCombat(), "targetMobFightHelper: still in combat after run_combat");

		if (have_effect($effect[Beaten Up]) == 0 && target_monsters[0] == last_monster())
			return true; // we won a fight vs the main target
		else
			return false;

	// NON-TARGET MONSTER -- despite possible redirection/banishment, we're in combat with the wrong monster
	} else {
		print("WARNING: combat with non-target monster!!!", "orange");
		run_combat();
		return false;
	}
}

// Adventure multiple times in aLocation, banishing monsters that aren't in the given array. Uses the automate_dressup mechanism to equip the banishing equipment (which won't work if we're not using the outfit automator)
// Will use Macrometeorite iff all unbanished normal (non-wandering) mobs we could get are in the target array (in other words, iff using macro will "guarantee" a target mob, assuming we don't get a wandering mob)
// Will olfact the first monster in the array (index #0) iff "kills" > 1
// Will kill "kills" monsters. This may take more than "kills" adventures if wandering monsters appear (or if "optimal" is false).
// If "kills" is 0, will only do a single turn not matter what (i.e. will not follow choices or anything else) and will return false if the combat wasn't with the target mob.
// Returns true otherwise.
// Will follow choice adventures if a default is available (even if "kills" is 0). Will abort if we get a choice adventure and no default is available.
// Will abort if optimal is true and can't banish or macro the wrong monster
// Otherwise will continue and do the best it can with olfactions.
// If maxPerTurnCost is less than the cost of fueling, will fuel up and use the Asdon Martin banish first -- see banishToUse() for details.
boolean targetMob(location aLocation, monster [] target_monsters, skill skillToUse, int kills, boolean optimal, int maxPerTurnCost) {
// 	if (have_effect($effect[On the Trail]) > 0 && !isOlfacted(target_monsters)) {
// 		if (user_confirm("We're about to target mob: " + target_monsters[0] + " while we're olfacting " + get_property("olfactedMonster") + ". Uneffect On the Trail and continue?", 60000, true))
// 			uneffect($effect[On the Trail]);
// 		else
// 			abort("targetMob: user aborted");
// 	}
	if (!isAutomatingDressup()
		&& !user_confirm("We're targetting a mob but we have no automated dressup set up, therefore we can't auto-banish... continue?", 60000, true))
		abort("targetMob: targetting mob but not automated dressup (user aborted)");

	print("targetMob: going to " + aLocation + " and targeting mob: " + target_monsters[0] + " (" + count(target_monsters) + " total targets) " + kills + " times, optimal: " + optimal + ", maxPerTurnCost: " + maxPerTurnCost, "green");

	string aPage;
	int kStartingKills = kills;
	if (kills == 0) kills = 1; // need 1 to get into the loop, we'll detect kStartingKills and break out below

	// TRACKER FAMILIAR AUTOMATION -- needs fixing, should be in dressup()???
	// the familiar is set by chooseFamiliar(), called by dressup() below, but we have to set the phylum in targetMob because chooseFamiliar doesn't know anything about the target
	print("FIXME [tracker]: " + get_property(kDressupFamiliarSelectorKey), "red");
	boolean tracking = get_property(kDressupFamiliarSelectorKey).contains_text("[tracker]"); // true if we're tracking with Red-nosed Snapper... or Nosy Nose???
	if (tracking && have_effect($effect[On the Trail]) == 0) { // we only want to track until we have olfacted
		use_familiar($familiar[Red-nosed Snapper]);
		if (snapperGuideMeToPhylum() != target_monsters[0].phylum) {
			print("setting tracker phylum: " + target_monsters[0].phylum, "blue");
			setRedNosedSnapperGuideMe(target_monsters[0].phylum);
		}
		tracking = true;
	}

	boolean hadGoals = haveGoals(); // if we have goals now and not later, presumably they're completed
	int noActionInARow = 0; // number of "no action" adv in a row we've had -- more than 3 in a row means we're probably on a new type of error page instead

	while (kills > 0) {
		preAdventureChecks(); // need this here so any potential maximize before an adv (esp. combat freq) gets the benefit of our mood -- also useful to stop before redressing if there's a trigger

		 // the max number of non-targets we want unbanished, 1 if we can replace or 0 otherwise
		int maxNonTargetsUnbanished = 0;
		if (canReplaceMonster() || (canFreeRunaway(maxPerTurnCost) && isOlfacted(target_monsters[0])))
			maxNonTargetsUnbanished = 1;

		// BANISH equip a banishing item if we're going to banish
		string tweakItem = "";
		if (unbanishedNonTargets(aLocation, target_monsters) > maxNonTargetsUnbanished) {
			SkillRecord equip_banish = banishToUse(aLocation, maxPerTurnCost);
			if (equip_banish.skillToUse == $skill[none])
				print("NO RECOMMENDED BANISHER!!", "orange");
			else
				print("RECOMMENDING BANISHER: " + equip_banish.skillToUse, "green");
			if (equip_banish.itemToEquip != $item[none]) {
				print("EQUIPPING: " + equip_banish.itemToEquip, "blue");
				tweakItem = "+equip " + equip_banish.itemToEquip;
			}
		} else if (!isOlfacted(target_monsters[0])) {
			// if we're not going to banish, maybe equip to olfact?
			tweakItem = dressForOlfaction(aLocation, tweakItem);
		}
		dressup(tweakItem);
		saveOutfit(kTargetMobSavedEquipSetKey);

		restore_mp(mp_cost($skill[Gallapagosian Mating Call]) + mp_cost(skillToUse));

		int unbanishedNonTargets = unbanishedNonTargets(aLocation, target_monsters);
		print("targetMob: unbanished non-targets before combat: " + unbanishedNonTargets, "blue");
		try {
			boolean chainedFight = false;

			// DIRECT TARGET map the monsters, time-spinner
			if (!tracking && have_effect($effect[On the Trail]) == 0 && unbanishedNonTargets >= 1) {

				if (to_int(get_property("_monstersMapped")) < 3) {
					print("targetMob: mapping (map the monsters) target monster: " + target_monsters[0], "green");
					if (!to_boolean(get_property("mappingMonsters")))
						if (!use_skill(1, $skill[Map the Monsters]))
							abort("tried to cast map the monsters but it didn't work!");
					aPage = advURL(aLocation);
					while (!handling_choice()) {
						// probably a wandering monster???
						run_combat();
						aPage = advURL(aLocation);
					}
					runMapChoice(aPage, target_monsters[0]);
						
					chainedFight = true;

				} else if (to_int(get_property("_timeSpinnerMinutesUsed")) <= 7) {
					print("targetMob: traveling back in time (time-spinner) to fight target monster: " + target_monsters[0], "green");
					timespinnerFight(target_monsters[0]);
					chainedFight = true;
				} else
					print("targetMob: would like to direct target: " + target_monsters[0] + " but no direct mapper available", "orange");
			}

			// DO THE ADVENTURE
			if (!chainedFight && !choice_follows_fight()) {
				aPage = advURLWithWanderingMonsterRedirect(aLocation);
			} else
				aPage = visit_url("/main.php", false, false); // get to the chained fight or the choice that follows the last fight

			// ERROR?
			if (isErrorPage(aPage)) {
// 				print("got an error page:\n" + aPage, "red"); // debugging new types of error pages
				abort("error page at adventure location: " + aLocation);
			}

			// CHOICE
			if (handling_choice() || choice_follows_fight()) {
				run_choice(-1);
				if (kStartingKills == 0)
					return false;
				continue;
			}

			// "NO ACTION" ADVENTURE (?)
			if (!contains_text(aPage, "fight.php")) {
				print("detected 'no action' adventure", "blue");
				noActionInARow++;
				if (kStartingKills == 0 || noActionInARow >= 3)
					return false;
				continue;
			} else
				noActionInARow = 0;

			// FIGHT
			boolean shouldOlfact = kStartingKills > 1;
			boolean targetKilled;
			if (inCombat())
				targetKilled = targetMobFightHelper(aLocation, target_monsters, skillToUse, maxPerTurnCost, optimal, shouldOlfact);
			else if (aPage.contains_text("fight.php")) // presumably we were in combat and killed it already
				targetKilled = arrayContains(target_monsters, last_monster());

			assert(!inCombat(), "targetMob: we should have killed the encountered monster at this point");

			// CHOICE FOLLOWS FIGHT
			if (choice_follows_fight()) {
				print("targetMob: choice follows fight!", "blue");
				run_choice(-1);
			}

			if (targetKilled) {
				if (kStartingKills == 0)
					return true;
				kills--;
			} else {
				if (kStartingKills == 0)
					return false;
			}

		} finally {
			postAdventure(); // have to run manually, since we're ultimately using visit_url
			if (hadGoals && !haveGoals())
				abort("targetMob: Goals completed!");

			print("");
			if (kStartingKills < 2 && kills == 0)
				print("targetMob: got 'em", "blue");
			else if (kStartingKills < 2)
				print("targetMob: that wasn't the target", "blue");
			else
				print("targetMob: kills remaining: " + kills, "blue");
			print("");

			restoreOutfit(true, kTargetMobSavedEquipSetKey); // will usually be the same outfit, unless we redirected
			ensure_not_beaten_up();
			// if we redirected, want to make sure we end up in the right location so dressup will trigger
			if (my_location() != aLocation)
				set_location(aLocation); 
		}
	}

	return kills == 0;
}

// shorthand for use in the CLI
boolean tm(location aLocation, monster target_monster, skill skillToUse, int kills, boolean optimal, int maxPerTurnCost) {
	monster [] monsterArray = {target_monster};
	return targetMob(aLocation, monsterArray, skillToUse, kills, optimal, maxPerTurnCost);
}



// Adventures at aLocation exactly once with advURLWithWanderingMonsterRedirect, banishing non-wandering monsters encountered
// if they don't appear in the given array of target monsters.
// Differs from targetMob in that it only adventures once no matter what happens. (targetMob will follow choice adv even when "kills" is 0)
// TODO: refactor to amalgamate this with targetMob: only thing that needs to be done is to allow targetMob take a script to pass to run_combat
// If maxPerTurnCost is less than fuel cost, will fuel up and use the Asdon Martin banish first, will otherwise balance
// among all banishers according to banishToUse(), using the Asdon Martin only if it has to (and only if it is already fueled up).
// scriptToUse is the script to use against monsters in the targetMonsters array -- wandering monsters use the script in the CSS
// Returns true if one of the targetMonsters was killed, false otherwise
// if the script passed in doesn't kill the monster, will return true while still in combat (since we know it is a target monster)
boolean adv1TargetingMobs(location aLocation, monster [] targetMonsters, int maxPerTurnCost, string scriptToUse) {
	assert(my_adventures() > 0, "adv1TargetingMobs: Out of adventures");
	check_counters(kAbortOnCounter);

	int maxNonTargetsUnbanished = 0;
	if (have_skill($skill[Macrometeorite]) || item_amount($item[fish-oil smoke bomb]) > 0) maxNonTargetsUnbanished = 1;

	// equip a banishing item if we're going to banish
	string tweakItem = "";
	if (unbanishedNonTargets(aLocation, targetMonsters) > maxNonTargetsUnbanished) {
		SkillRecord equip_banish = banishToUse(aLocation, maxPerTurnCost);
		if (equip_banish.skillToUse == $skill[none])
			print("NO RECOMMENDED BANISHER!!", "orange");
		else
			print("RECOMMENDING BANISHER: " + equip_banish.skillToUse, "green");
		if (equip_banish.itemToEquip != $item[none]) {
			print("EQUIPPING: " + equip_banish.itemToEquip, "blue");
			tweakItem = "+equip " + equip_banish.itemToEquip;
		}
	} else {
		// if we're not going to banish, maybe equip to olfact?
		tweakItem = dressForOlfaction(aLocation, tweakItem);
	}

	dressup(tweakItem);
	saveOutfit(kRedirectSavedEquipSetKey);

	try {
		string page = advURLWithWanderingMonsterRedirect(aLocation);

		// list of "if"s to cover all the different kinds of pages we could have gone to
		if (contains_text(page, "A choice follows this fight immediately")) { // post-adventure stuff like the lil doctor bag
			abort("A choice follows this fight immediately");
		} else if (isChoicePage(page)) { // choice
			run_choice(-1);
			return false;
		} else if (!contains_text(page, "fight.php")) { // "no action" adventure -- things like exposition pages -- i believe these take no adventures
			return false;
		} else if (!contains_monster(aLocation, last_monster())) { // wandering monster
			print("wandering monster", "blue");
			run_combat();
			return false;
		} else if (!arrayContains(targetMonsters, last_monster())) { // the meat of the matter
			// special processing if there is exactly 1 unbanished (and non-target) monster and we get the wrong monster
			// first, try to Macrometeorite, if not, try free runaway
			if ((unbanishedNonTargets(aLocation, targetMonsters) == maxNonTargetsUnbanished || have_effect($effect[On the Trail]) > 0 && contains_monster(aLocation, to_monster(get_property("olfactedMonster")))) && have_skill($skill[Macrometeorite])) {
				executeScript(pickpocket_sub() + "skill Macrometeorite");
				// should be caught below and kill the target
			} else if (unbanishedNonTargets(aLocation, targetMonsters) > maxNonTargetsUnbanished && item_amount($item[fish-oil smoke bomb]) > 0) {
				executeScript(pickpocket_sub() + "use fish-oil smoke bomb");
				return false;
			} else { // banish
				SkillRecord banisher = banishToUse(aLocation, maxPerTurnCost);
				if (banisher.skillToUse == $skill[none])
					print("NO RECOMMENDED BANISHER!!", "orange");
				else
					print("RECOMMENDING BANISHER: " + banisher.skillToUse, "green");
				if (banisher.skillToUse != $skill[none]) {
					executeScript(pickpocket_sub() + "skill " + banisher.skillToUse);
					return false;
				} else { // no banisher, use Macrometeorite but only if olfacted, otherwise we're just stabbing in the dark
					if (have_effect($effect[On The Trail]) > 0) {
						if (have_skill($skill[Macrometeorite]))
							executeScript(pickpocket_sub() + "skill Macrometeorite");
						else if (have_item($item[fish-oil smoke bomb])) {
							executeScript(pickpocket_sub() + "use fish-oil smoke bomb");
							return false;
						}
					} else
						print("WARNING: Can't banish OR macro!", "blue");
				}
			}
		}

		// separated out from normal fight processing because we might get here via Macrometeorite
		buffer page2;
		if (arrayContains(targetMonsters, last_monster())) {
			string preScript = pickpocket_sub();
			if (targetMonsters[0] == last_monster())
				preScript += olfactionScript(last_monster());
			run_combat(preScript + scriptToUse);
			if (have_effect($effect[Beaten Up]) == 0)
				return false;
		} else {
			print("WARNING: combat with non-target monster!!!", "blue");
			run_combat();
		}
	} finally {
		postAdventure(); // have to run manually, since we're using visit_url
		
		restoreOutfit(true, kRedirectSavedEquipSetKey);
		if (my_location() != aLocation) { // if we redirected, want to make sure we end up in the right location so dressup will trigger
			set_location(aLocation);
		}
	}
	return true;
}

void adv1TargetingMob(location aLocation, monster targetMonster, int maxPerTurnCost, string scriptToUse) {
	monster [] monsterArray = {targetMonster};
	adv1TargetingMobs(aLocation, monsterArray, maxPerTurnCost, scriptToUse);
}



void setDefaultAutomationState() {
	clear_automate_dressup();
}



void main() {
	print("**RUNNING pre-adventure script**");
	dressup();
	hpMood();
	burnExtraMP();
}


