import <smmUtils.ash>
import <smmCCS.ash>
import <smmConsult.ash>

// A yes/no question. During an smmdaily run (smm.daily.active is set) nobody
// is there to answer, so it takes the default answer at once instead of
// waiting a minute for it.
boolean smmConfirm(string prompt, boolean defaultAnswer) {
	if (get_property("smm.daily.active") != "") {
		print(prompt + " -- " + defaultAnswer + " (smmdaily run: the default answer)", "blue");
		return defaultAnswer;
	}
	return user_confirm(prompt, 60000, defaultAnswer);
}
string __smm_automation_version = "0.3";


/*
Automation, with 3 main functions: automated dressing, automated redirection, and monster targeting.

Automated dressing attempts to fill equipment slots with useful items that would not otherwise be equipped
(or, in the case of the broken champagne bottle and possibly others, to ensure items WON'T be equipped unless
explicitly called for). Things that automated dressing might do:
- Equip a pickpocket-enabling item if you're not DB or AT if there's pickpocketable items (TODO: look for pp-only items only??)
- Wear "i voted!" sticker on the turn the vote monster is due (if it's a free turn OR the property smm.FreeWanderingMonstersOnly is false)
- Wear maple magnet in the places where grinding with it is useful
- Wear the Kramco Sausage-o-Matic if there's a high chance of getting a sausage goblin
- Wear all the best item-dropping items when the broken champagne bottle is called for
- Wear oyster basket on oyster day
- Wear fishing equipment in fishing locations
- Wear mafia thumb ring
- Wear latte lovers member's mug if we're in a location with pending unlocks
- Wear a melee weapon for mus classes and ranged for mox classes ??? this is turned off right now
- Wear pantogram pants for hilarity
In all cases, will respect "-equip" directives, e.g. -equip pantogram pants; will not overwrite
existing equip directives (including outfits); and will prioritize better items first. The main
function to use for automating outfits is automate_dressup().

Automated redirection attempts to redirect wandering monsters and copies to useful locations with delay.
Places that redirection might go to (in priority order as of 2022-02-16):
- The few prioritized latte lovers member's mug unlock locations (see nextLatteIngredient(), but default is +item,+meat,+fam,+adv in that order)
- Infernal rackets backstage if we don't have the unicorn (have to get the other 1/2 of the Azazel quest manually i think)
- Pagoda quest unlocks (pandamonium slums, inside the palindome)
- Initial zap wand unlock (Enormous Greater-Than Sign)
- Join guild locations if we haven't joined our guild (haunted pantry, sleazy back alley, outskirts of cobb's knob)
- Guild quest locations when they are needed (currently: the unquiet garves, the "fun" house)
- Guzzlr gold quest locations
- Pirate unlocks (TODO)
- 10 turns in The Valley of Rof L'm Fao for A Quest, LOL
- Guzzlr bronze quest locations
- Smut orc logging camp to get a smut orc keepsake box (last-ditch default if nothing else) TODO figure something better
In all cases, you have to finish the quest manually at this time. The main function to use
for auto redirection is redirectAdventure() or ra () on the gCLI.

Monster targeting attempts to kill the target monsters a set number of times. It's original purpose
was to finish New You quests, which need this kind of facility, but it turns out to be useful
in Bounty quests, meat farming, and many other uses besides.
- Uses direct targetting mechanisms like Map the Monsters
- Also uses automated dressing to equip banishing items (which was actually the original purpose of automated dressing)
- Uses automated redirection (see above) while targeting.
See targetMob() for more details.

You can get auto dressup without the auto redirection by setting the additionalMaxString argument to the empty string.
Put your entire max string in the selector argument instead. You can get auto redirection without the auto dressup by
putting your entire max string into the additionalMaxString and setting selector to the empty string.

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
string kRedirectSavedEquipSetKey = "smm.RedirectSavedEquipSet";
string kTargetMobSavedEquipSetKey = "smm.TargetMobEquipSet";


// TODO make these properties
string [] kDefaultLatteIngredients = {"carrot", "cajun", "rawhide"}; // ingredients must appear in kLatteLocations
string [] kDefaultLatteLastRefillIngredients = {"carrot", "cajun", "guarna"}; // ingredients must appear in kLatteLocations
string [] kExtraLatteIngredients = {}; // extra ingredients to unlock (other than those in the above 2 lists) -- ingredients must appear in kLatteLocations


// returns true iff the given ingredient is a priority ingredient
boolean isPriorityLatteIngredient(string testIngredient) {
	foreach idx, ingred in kDefaultLatteIngredients {
		if (ingred == testIngredient)
			return true;
	}
	foreach idx, ingred in kDefaultLatteLastRefillIngredients {
		if (ingred == testIngredient)
			return true;
	}
	foreach idx, ingred in kExtraLatteIngredients {
		if (ingred == testIngredient)
			return true;
	}

	return false;
}


// returns true iff the given location is for a priority ingredient that we haven't unlocked
boolean isPriorityLatteLocation(location aLocation) {
	string ingred = latteIngredientForLocation(aLocation);
	return ingred != "" && !isLatteIngredientUnlocked(ingred) && isPriorityLatteIngredient(ingred);
}


// returns the next default latte lovers member's mug ingredient to grind or the empty string if there are no more
string nextLatteIngredient() {
	foreach idx, ingredient in kDefaultLatteIngredients {
		if (!isLatteIngredientUnlocked(ingredient))
			return ingredient;
	}
	foreach idx, ingredient in kDefaultLatteLastRefillIngredients {
		if (!isLatteIngredientUnlocked(ingredient))
			return ingredient;
	}
	foreach idx, ingredient in kExtraLatteIngredients {
		if (!isLatteIngredientUnlocked(ingredient))
			return ingredient;
	}

	return "";
}



// -------------------------------------
// DRESSING
// -------------------------------------


// selects a familiar based on the given selector and adds a string appropriate for
// "maximize" to dress the familiar in the best equipment to the existingMaxString and returns that
//
// will read smm.ChooseFamiliarOverride and smm.ChooseFamiliarOverrideEquipString and use those if set
// aLocation: the expected location we will adventure in (might be none, in which case monster should be specified)
// aMonster: the expected monster we will fight (might be none, in which case location should be specified)
string chooseFamiliar(string selector, location aLocation, monster aMonster, string existingMaxString) {
	string rval = existingMaxString;

	// DO NOTHING if we specify -familiar
	if (existingMaxString.contains_text("-familiar"))
		return rval;

	// OVERRIDE from properties
	string overrideString = get_property("smm.ChooseFamiliarOverride");
	if (overrideString != "") {
		use_familiar(to_familiar(overrideString));
		return maxStringAppend(rval, get_property("smm.ChooseFamiliarOverrideEquipString"));
	}

	// TRACKER TODO this will never trigger as we always have On the Trail now
	// [tracker] -- use the red-nosed snapper until we find what we're looking for, then back to our regular choice -- "guide me" MUST be set up by calling function
	matcher selectorMatcher = create_matcher(" \\[.*\\]", selector);
	string famSelector = replace_first(selectorMatcher, "");
	if (contains_text(selector, "[tracker]")) {
		if (have_effect($effect[On the Trail]) == 0) {
			use_familiar($familiar[Red-nosed Snapper]);
			return rval;
		}
		// if we're already On The Trail, fall through and select the familiar based on the other part
	}

	// if the selector is empty, do nothing WRT familiars
	if (famSelector == "") {
		return maxStringAppend(rval, "-familiar");

	// NO familiar
	} else if (contains_text(famSelector, "none")) {
		use_familiar($familiar[none]);
		return rval;
	}

	familiar familiarFromSelector = famSelector.to_familiar();
	boolean hasFamEE = existingMaxString.wantsToEquip($slot[familiar]); // familiar equipped equipment specified in the existingMaxString
	item defaultFamEE = $item[tiny stillsuit];
	item famEEToEquip;

	// ITEM
	if (contains_text(famSelector, "item")) {
		if (!hasFamEE && have_item($item[li'l ninja costume])) {
			use_familiar($familiar[Trick-or-Treating Tot]);
			// rval = maxStringAppend(rval, "switch Trick-or-Treating Tot"); // if we use_familiar we don't need to switch
			famEEToEquip = $item[li'l ninja costume];
		} else {
			use_familiar($familiar[Cat Burglar]);
			// rval = maxStringAppend(rval, "switch Cat Burglar"); // if we use_familiar we don't need to switch
			if (!hasFamEE)
				famEEToEquip = $item[burglar/sleep mask]; // adds a charge 50% of the time
		}

	// MEAT
	} else if (contains_text(famSelector, "meat")) {
		if (!hasFamEE && have_item($item[li'l pirate costume])) {
			use_familiar($familiar[Trick-or-Treating Tot]);
			// rval = maxStringAppend(rval, "switch Trick-or-Treating Tot"); // if we use_familiar we don't need to switch
			famEEToEquip = $item[li'l pirate costume];
		} else {
			use_familiar($familiar[Hobo Monkey]);
			// rval = maxStringAppend(rval, "switch Hobo Monkey"); // if we use_familiar we don't need to switch
			// famEEToEquip = $item[tiny bindle]; // minimal effect and the maximizer will maximize it
		}

	// -COMBAT
	} else if (contains_text(famSelector, "-combat")) {
		// use_familiar($familiar[Disgeist]); don't actually switch, since we might not actually use the fam if the effect is too low (e.g. when -combat is less than -25, further reduction is less effective)
		rval = maxStringAppend(rval, "switch Disgeist");
		// famEEToEquip = $item[smoke ball]; // might not be available (disappaears at the end of day), also might not be effective

	// +COMBAT
	} else if (contains_text(famSelector, "+combat")) {
		// use_familiar($familiar[Jumpsuited Hound Dog]); don't actually switch, since we might not actually use the fam if the effect is too low (e.g. when +combat is over +25, further reduction is less effective)
		rval = maxStringAppend(rval, "switch Jumpsuited Hound Dog");
		// famEEToEquip = $item[blue suede shoes]; // might not be effective

	// NONCOMBAT -- fams that are useful in a non-combat #left hand man
	} else if (contains_text(famSelector, "noncombat")) {
		use_familiar($familiar[Left-Hand Man]);
		assert(equip($slot[familiar], $item[KoL Con 13 snowglobe]), "Failed to equip Left-Hand Man with KoL Con 13 snowglobe");
		rval = maxStringAppend(rval, "-familiar"); // have to do Left-Hand Man manually
		// famEEToEquip = $item[KoL Con 13 snowglobe]; // have to do Left-Hand Man equipment manually

	// FIGHT -- best default combat familiar
	} else if (contains_text(famSelector, "fight")) {
		use_familiar($familiar[Vampire Vintner]);
		rval = maxStringAppend(rval, "switch Vampire Vintner");
		// famEEToEquip = $item[French-Transylvanian Dictionary]; // minimal effect

	// MONSTER LEVEL
	} else if (contains_text(famSelector, "ml")) {
		// use_familiar($familiar[Purse Rat]); // maximizer will maximize it so we don't need to switch manually
		rval = maxStringAppend(rval, "switch Purse Rat");
		// famEEToEquip = $item[tiny cell phone]; // maxmimizer will maximize it

	// INIT
	} else if (contains_text(famSelector, "init")) {
		// use_familiar($familiar[Cute Meteor]); // maximizer will maximize it so we don't need to switch manually
		rval = maxStringAppend(rval, "switch Cute Meteor");
		// famEEToEquip = $item[meteor shower cap]; // maxmimizer will maximize it

	// PREVENT ATTACKS
	} else if (contains_text(famSelector, "prevent")) {
		if (have_item($item[God Lobster's Robe])) {
			use_familiar($familiar[God Lobster]);
			// rval = maxStringAppend(rval, "switch God Lobster"); // if we use_familiar we don't need to switch
			famEEToEquip = $item[God Lobster's Robe];
		} else {
			use_familiar($familiar[Levitating Potato]);
			// rval = maxStringAppend(rval, "switch Levitating Potato"); // if we use_familiar we don't need to switch
			// famEEToEquip = $item[many-eyed glasses]; // minimal effect
		}

	// ROBORTENDER -- custom for robortender because we want to specify the "bartend" switch setting
	} else if (contains_text(famSelector, "robortender")) {
 		use_familiar($familiar[robortender]);
 		doseRobortender();
		// rval = maxStringAppend(rval, "switch Robortender"); // if we use_familiar we don't need to switch
		famEEToEquip = $item[toggle switch (Bartend)];

	// POCKET PROFESSOR -- custom for pocket professor because we want to get the friar's familiar buff
	} else if (contains_text(famSelector, "pocket professor")) {
 		use_familiar($familiar[Pocket Professor]);
		// rval = maxStringAppend(rval, "switch Pocket Professor"); // if we use_familiar we don't need to switch
		famEEToEquip = $item[Pocket Professor memory chip];
		if (friars_available()) // TODO move this to where the pocket professor is used
			cli_execute("friars familiar");

	// SHORTER-ORDER COOK -- make sure our previous familiar can use XP, since shorter-order cook gives the last fam 1 xp #short-order #short order #shortorder
	} else if (contains_text(famSelector, "shorter-order cook")) {
		if (my_familiar() != $familiar[Shorter-Order Cook]) {
			// the familiar before the shorter-order cook needs to be able to use XP in some way
			print("Shorter-order Cook selected, ensuring previous familiar is set to Pocket Professor for the free fam XP", "green");
			if (my_familiar() != $familiar[Pocket Professor])
		 		use_familiar($familiar[Pocket Professor]);
	 		use_familiar($familiar[Shorter-Order Cook]);
		}
		// rval = maxStringAppend(rval, "switch Shorter-order Cook"); // if we use_familiar we don't need to switch
		famEEToEquip = $item[blue plate]; // reduces the frequency of Shorter-Order Cook item drops from every 11 adv to every 9 adv

	// ANY FAMILIAR NAME
	} else if (familiarFromSelector != $familiar[none]) {
		use_familiar(familiarFromSelector);
		// rval = maxStringAppend(rval, "switch " + familiarFromSelector); // if we use_familiar we don't need to switch
		item famItem = familiar_equipment(familiarFromSelector);

	// DEFAULT, will match anything else but expected to use selector = "default" by convention
	} else {
		float roboChance = roboDropChanceForLocation(aLocation, false);

		// make sure screech is available
		if ("screechCombats".get_property().to_int() > 0) {
			use_familiar($familiar[Patriotic Eagle]);

		// Robortender if we haven't exhausted the RoboDrops (lowest drop chance after 10 drops) and the location gives good drops
		} else if (roboChance > 0.25
		  && (aLocation != $location[none] && roboEconomicsForLocation(aLocation, false) > kTurnValue * roboChance)) {
			use_familiar($familiar[robortender]);
			doseRobortender();
			famEEToEquip = $item[toggle switch (Bartend)];

		// Cat Burglar if we're close enough to a heist
		} else if (!hasFamEE && (baseCombatsToNextCatBurglarHeist() <= 20.0 || progressToNextCatBurglarHeist() / baseCombatsToNextCatBurglarHeist() > kPersueFamiliarIfOver)) {
			use_familiar($familiar[Cat Burglar]);
			print("selecting default familiar Cat Burglar", "green");
			famEEToEquip = $item[burglar/sleep mask]; // adds a charge 50% of the time

		// Garbage Fire if we're close enough to a drop
		} else if (get_property("garbageFireProgress").to_float() / 30.0 > kPersueFamiliarIfOver) {
			use_familiar($familiar[Garbage Fire]);

		// Optimistic Candle if we're close enough to a drop
		} else if (to_float(get_property("optimisticCandleProgress")) / 30.0 > kPersueFamiliarIfOver) {
			use_familiar($familiar[Optimistic Candle]);

		// Cookbootbat if we haven't dropped the recipe
		} else if (!"_cookbookbatRecipeDrops".get_property().to_boolean()) {
			use_familiar($familiar[cookbookbat]);

		} else if ("_mapToACandyRichBlockDrops".get_property().to_int() < 1) {
			use_familiar($familiar[Jill-of-All-Trades]);

		} else if ("_grubbyWoolDrops".get_property().to_int() < 1) {
			use_familiar($familiar[Hobo in Sheep's Clothing]);

		} else {
			use_familiar($familiar[cookbookbat]);
			//use_familiar($familiar[Melodramedary]);
			//use_familiar($familiar[Pocket Professor]);
		}

		// default familiar equipment for default familiars
		if (!wantsToEquip(existingMaxString, $slot[familiar]) && !wantsToEquip(rval, $slot[familiar]) && (!isUnderwaterLocation(aLocation) || canMyFamiliarBreatheWater()))
			famEEToEquip = defaultFamEE;
	}

	if (!hasFamEE && isUnderwaterLocation(aLocation) && !canMyFamiliarBreatheWater()) {
		hasFamEE = true;
		if (have_item($item[das boot]))
			rval = maxStringAppend(rval, "equip das boot");
		else
			rval = maxStringAppend(rval, "equip little bitty bathysphere");
	}

	assert(! (hasFamEE && famEEToEquip != $item[none]), "we want to equip famEE " + famEEToEquip + " but the calling function already specified something to equip!");
	if (famEEToEquip != $item[none] && have_item(famEEToEquip))
		rval = maxStringAppend(rval, "equip " + famEEToEquip);

	return rval;
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



// returns true if getting a wandering monster would be bad (currently because the wandering
// monster would consume a use of the broken champagne bottle)
boolean wanderingMonstersBad(string maxString) {
	return wantsToEquip(maxString, $item[broken champagne bottle]);
}


boolean voteMonsterNext() {
	return (total_turns_played() % 11 == 1 && to_int(get_property("lastVoteMonsterTurn")) != total_turns_played() && !inRonin());
}


// returns true if the current vote monster is useful to get (i.e. has non-tradable items OR is worth more than the turn value)
// AND our outfit allows wandering monsters AND the dressup max string isn't -equip'ing the i voted sticker
boolean wantVoteMonster() {
	monster voteMonster = get_property("_voteMonster").to_monster();
	int freeVoteFightsDone = get_property("_voteFreeFights").to_int();
	string dressupMaxString = get_property(kDressupMaxStringKey);

	return (freeVoteFightsDone < 3 || !freeWanderingMonstersOnly())
			&& (freeVoteFightsDone < 3
				|| voteMonster == $monster[terrible mutant] || voteMonster == $monster[annoyed snake] || voteMonster == $monster[slime blob]
				|| monsterTotalMeatValue(voteMonster, true, max(400, item_drop_modifier()), max(400, meat_drop_modifier())) > kTurnValue) // TODO only guessing at the redirection outfit... can we calculate it?
			&& (!wanderingMonstersBad(dressupMaxString))
	;
}



void setDefaultMoodForLocation(location advLocation) {
	switch (advLocation) {
		case $location[Infernal Rackets Backstage]:
		case $location[Lair of the Ninja Snowmen]:
			if (!inRonin())
				setCurrentMood("-combat");
			break;

		case $location[The Overgrown Lot]:
		case $location[The Sleazy Back Alley]:
		case $location[The Black Forest]:
		case $location[The eXtreme Slope]:
		case $location[The Haunted Gallery]:
		case $location[The Hidden Temple]:
		case $location[Whitey's Grove]:
			if (!inRonin())
				setCurrentMood("+combat");
			break;

		case $location[The Enormous Greater-Than Sign]:
			if (get_property("lastPlusSignUnlock").to_int() < my_ascensions() && !have_item($item[plus sign]))
				setCurrentMood("-combat");
			else
				setCurrentMood("+combat");
			break;

		case $location[Madness Bakery]:
			if (questStage("questM25Armorer") == 1 || questStage("questM25Armorer") == 2)
				setCurrentMood("-combat");
			else
				setCurrentMood("+combat");
			break;

		case $location[The Obligatory Pirate's Cove]:
		case $location[Barrrney's Barrr]:
		case $location[The F'c'le]:
			if (!have_outfit("Swashbuckling Getup") && available_amount($item[pirate fledges]) == 0)
				setCurrentMood("-combat"); // get outfit -- Obligatory Pirate's Cove only
			else
				setCurrentMood("+combat");
			break;

		case $location[The Haunted Bathroom]:
			if (!inRonin() && !get_property("guyMadeOfBeesDefeated").to_boolean())
				setCurrentMood("-combat");
			else
				setCurrentMood("+combat");
			break;

		case $location[The Skeleton Store]:
			if (!inRonin() && !get_property("skeletonStoreAvailable").to_boolean())
				setCurrentMood("-combat");
			else
				setCurrentMood("+combat");
			break;

		case $location[The "Fun" House]:
			// this is actually a superlikely, NOT a NC
// 			if (get_property("questG04Nemesis") == "step5" && $location[The "Fun" House].turns_spent >= 10)
// 				setCurrentMood("-combat");
			break;
	}
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


string storedDressupMaxString() {
	return get_property(kDressupMaxStringKey);
}



// Appends to given maxString a maximizer string that will enable adventuring in the given location and returns it.
// Most locations will require nothing. Prototypical example is the pirate fledges required for adventuring in the Obligatory Pirate Cove.
// TODO Since these are required items only, will not check if the existing maxString allows dressing with the returned item(s)????
string maxStringForLocation(location advLocation, string maxString) { // #dressForLocation
	switch (advLocation) {
		// PIRATES
		case $location[The Obligatory Pirate's Cove]:
			maxString = maxStringAppend(maxString, "+10 combat");
			break;
		case $location[Barrrney's Barrr]:
		case $location[The F'c'le]:
			maxString = maxStringAppend(maxString, "+10 combat");
			// we need the outfit/accessory so drop through to the next block
		case $location[The Poop Deck]: // has O Cap'm, My Cap'm so no +combat
		case $location[Belowdecks]: // 100% combat
			if (have_item($item[pirate fledges]))
				maxString = maxStringAppend(maxString, "equip pirate fledges");
			else if (have_outfit("Swashbuckling Getup"))
				maxString = maxStringAppend(maxString, "outfit Swashbuckling Getup");
			else
				abort("can't dress for location: " + advLocation);
			break;


		case $location[The Overgrown Lot]:
		case $location[The eXtreme Slope]:
			if (!inRonin())
				maxString = maxStringAppend(maxString, "+combat");
			break;

		case $location[The Black Forest]:
		case $location[The Hidden Temple]:
			if (!inRonin())
				maxString = maxStringAppend(maxString, "+10 combat");
			break;

		case $location[Madness Bakery]:
			if (!inRonin())
				maxString = maxStringAppend(maxString, "+20 combat");
			break;

		// PALINDOME
		case $location[Inside the Palindome]:
			if (have_item($item[Talisman o' Namsilat]))
				maxString = maxStringAppend(maxString, "equip Talisman o' Namsilat");
			else
				abort("can't dress for location: " + advLocation);
			break;

		// AZAZEL
		case $location[Infernal Rackets Backstage]:
			if ( !(get_property("questM10Azazel") == "finished" || have_item($item[Azazel's unicorn])))
				maxString = maxStringAppend(maxString, "-10 combat");
			break;

		// GUY MADE OF BEES
		case $location[The Haunted Bathroom]:
			if (!inRonin() && !get_property("guyMadeOfBeesDefeated").to_boolean())
				maxString = maxStringAppend(maxString, "-10 combat, equip industrial fire extinguisher");
			else
				maxString = maxStringAppend(maxString, "+50 combat 20 min");
			break;

		// SKELETON STORE
		case $location[The Skeleton Store]:
			if (!inRonin() && !get_property("skeletonStoreAvailable").to_boolean())
				maxString = maxStringAppend(maxString, "-10 combat");
			else
				maxString = maxStringAppend(maxString, "+50 combat 20 min");
			break;

		// THE SLEAZY BACK ALLEY
		case $location[The Sleazy Back Alley]:
			if (!inRonin())
				maxString = maxStringAppend(maxString, "+50 combat 20 min");
			break;

		// GUILD -- fun house funhouse
		case $location[The "Fun" House]:
			if (get_property("questG04Nemesis") == "step5" && $location[The "Fun" House].turns_spent >= 6)
				// this assumes clown wig and clown whip are possible
				maxString = maxStringAppend(maxString, "4 clownosity, -50 combat"); // careful: too much -combat might overwhelm clownosity -- NEED the "4" in "4 clownosity" see https://wiki.kolmafia.us/index.php/Modifier_Maximizer
			break;

		// LAIR OF THE NINJA SNOWMEN
		case $location[Lair of the Ninja Snowmen]:
			if (!inRonin())
				maxString = maxStringAppend(maxString, "-10 combat");
			break;

		// 8-BIT REALM
		case $location[8-Bit Realm]:
		case $location[The Fungus Plains]:
		case $location[Vanya's Castle]:
		case $location[Megalo-City]:
		case $location[Hero's Field]:
		case $location[Shadow Rift (The 8-Bit Realm)]:
			if (have_item($item[continuum transfunctioner]))
				maxString = maxStringAppend(maxString, "equip continuum transfunctioner");
			else
				abort("can't dress for location: " + advLocation);
			break;

		case $location[The Briny Deeps]:
		case $location[The Brinier Deepers]:
		case $location[The Briniest Deepests]:
		case $location[The Wreck of the Edgar Fitzsimmons]:
		case $location[An Octopus's Garden]:
		case $location[Anemone Mine]:
		case $location[The Coral Corral]:
		case $location[The Mer-kin Outpost]:
		case $location[Mer-kin Gymnasium]:
		case $location[Mer-kin Elementary School]:
		case $location[Mer-kin Colosseum]:
		case $location[Mer-kin Library]:
			if (!canBreatheWater()) {
				if (have_item($item[old SCUBA tank]))
					maxString = maxStringAppend(maxString, "equip old SCUBA tank");
				else
					maxString = maxStringAppend(maxString, "equip aerated diving helmet");
			}
			break;
	}

	return maxString;
}


// returns a maximizer string that will enable olfacting
string dressForOlfaction(location advLocation, monster target) {
	string rval;
	string maxString = storedDressupMaxString();

	if (!hasBeenOfferedLatte(target) && !get_property("_latteCopyUsed").to_boolean()
		&& !wantsToNotEquip(maxString, $item[latte lovers member's mug])
		&& !wantsToEquip(maxString, $slot[off-hand])) {
		print("EQUIPPING latte lovers member's mug for olfaction");
		rval = rval.maxStringAppend("equip latte lovers member's mug");
	}

	return rval;
}



// the core of the automated dressup facility, this returns a maximizer string so we can
// dress up in the most appropriate outfit.
// an empty selector represents an automated outfit without any actual automated equipping -- therefore this function cannot be called with an empty selector
// an empty additionalMaxString represents an automated outfit based on selector but with no automated redirecting
string maximizerStringForDressup(location advLocation, string selector, string additionalMaxString) {
	assert(selector != "", "maximizerStringForDressup: blank selector");

	// TRACKER SELECTOR
	// remove the "[tracker]" bit if it is present
	matcher selectorMatcher = create_matcher(" \\[.*\\]", selector);
	selector = replace_first(selectorMatcher, "");
	string maxString = maxStringAppend(selector, additionalMaxString);

	// LOCATION-SPECIFIC items that we need to adventure at the location (e.g. pirate fledges)
	maxString = maxStringForLocation(advLocation, maxString);

	// IN RONIN
	if (inRonin()) {
	}

	// CLASS-SPECIFIC
	if (my_class() == $class[Turtle Tamer])
		maxString = maxStringAppend(maxString, "-equip fiberglass foil"); // has a bad habit of killing things before we get into combat, which means we can't do things like yellow ray -- TODO might be useful against scaling foes???

	boolean highChanceOfSausageGoblin = (chanceOfSausageGoblinNextTurn() > 0.20 && to_int(get_property("_sausageFights")) < kSausagesToGet) || chanceOfSausageGoblinNextTurn() > 0.50;
	boolean lowChanceOfSausageGoblin = (chanceOfSausageGoblinNextTurn() > 0.10 && to_int(get_property("_sausageFights")) < kSausagesToGet) || chanceOfSausageGoblinNextTurn() > 0.25;

	// PRIORITY LATTE LOVERS MEMBER'S MUG unlocks -- we're probably getting redirected for a wandering monster to a priority latte unlock location, so better make sure we equip it!
	if (isPriorityLatteLocation(advLocation) && countHandsUsed(maxString) < 2
		&& !wantsToEquip(maxString, $slot[off-hand])
		&& !wantsToNotEquip(maxString, $item[latte lovers member's mug])) {
		maxString = maxStringAppend(maxString, "equip latte lovers member's mug");
	}

	// FRANKEN STEIN -- not useful
// 	if (countHandsUsed(maxString) < 2 && !wantsToEquip(maxString, $slot[off-hand]) && !wantsToNotEquip(maxString, $item[Franken Stein ])) {
// 		maxString = maxStringAppend(maxString, "equip Franken Stein");
// 	}

	// SAUSAGE GOBLINS (HIGH CHANCE), the kramco gets priority in the off-hand when we're likely to get a sausage goblin
	if (!inRonin() && highChanceOfSausageGoblin && countHandsUsed(maxString) < 2 && !wanderingMonstersBad(maxString)
		&& !wantsToEquip(maxString, $slot[off-hand]) && !wantsToEquip(maxString, $item[backup camera]) // if we're backing up to another monster, we don't want any chance of a sausage goblin
		&& !wantsToNotEquip(maxString, $item[Kramco Sausage-o-Matic&trade;])) {
		print("wants to equip offhand: " + wantsToEquip(maxString, $slot[off-hand]));
		maxString = maxStringAppend(maxString, "equip Kramco Sausage-o-Matic&trade;");
	}

	// LATHE MAPLE MAGNET
	if (have_item($item[maple magnet]) && countHandsUsed(maxString) < 2
		&& (advLocation == $location[Dreadsylvanian Woods] || advLocation == $location[The Smut Orc Logging Camp] || advLocation == $location[The Purple Light District] || advLocation == $location[The Mouldering Mansion] || advLocation == $location[The Stately Pleasure Dome] || advLocation == $location[The Rogue Windmill] || advLocation == $location[The Jungles of Ancient Loathing] || advLocation == $location[The Dripping Trees])
		&& !wantsToEquip(maxString, $slot[off-hand]) && !wantsToNotEquip(maxString, $item[maple magnet]))
		maxString = maxStringAppend(maxString, "equip maple magnet");

	// CURSED MAGNIFYING GLASS
	if (get_property("cursedMagnifyingGlassCount").to_int() < 13 && get_property("_voidFreeFights").to_int() < 5
		&& countHandsUsed(maxString) < 2 && !wantsToEquip(maxString, $slot[off-hand])
		&& !wantsToNotEquip(maxString, $item[cursed magnifying glass]))
		maxString = maxStringAppend(maxString, "equip cursed magnifying glass");

	// JUNE CLEAVER -- if we can skip the Cleaver-dreams, we should go for them and get high-value ones
	if (!inRonin() && (get_property("_juneCleaverEncounters").to_int() < 5 || "_juneCleaverSkips".get_property().to_int() < 5)
		&& !maxString.contains_text("clownosity") // we need the weapon slot for clownosity
		&& !wantsToEquip(maxString, $slot[weapon]) && !wantsToNotEquip(maxString, $item[June cleaver]))
		maxString = maxStringAppend(maxString, "equip June cleaver");

	// DESIGNER SWEATPANTS
	item guzItem = to_item(get_property("guzzlrQuestBooze"));
	location guzLoc = to_location(get_property("guzzlrQuestLocation"));
	if ((advLocation != guzLoc || !have_item(guzItem)) // don't equip sweatpants if we're about to do a Guzzlr quest location (in which case we want Guzzlr pants)
		&& (get_property("sweat").to_int() < 75 && get_property("_sweatOutSomeBoozeUsed").to_int() < 3)
		&& !wantsToEquip(maxString, $slot[pants]) && !wantsToNotEquip(maxString, $item[designer sweatpants]))
		maxString = maxStringAppend(maxString, "equip designer sweatpants");

	// PICKPOCKET-ENDABLING ITEM
	maxString = dressForPickpocket(advLocation, maxString);

	// JURASSIC PARKA if we're casting Launch spikolodon spikes
	if (kSpikolodonNextCombatKey.get_property().to_boolean())
		maxString = maxStringAppend(maxString, "equip Jurassic Parka");
	// McHUGELARGE LEFT SKI if we're casting McHugeLarge Avalanche
	if (kAvalancheNextCombatKey.get_property().to_boolean())
		maxString = maxStringAppend(maxString, "equip McHugeLarge left ski");

	// VOTE MONSTER
	// equip the i voted sticker if we can get a free fight, or if we are in aftercore
	// if we're not in aftercore and we don't have any more free fights, ensure we aren't
	// wearing the sticker if it might trigger a wandering monster
	int freeVoteFightsDone = get_property("_voteFreeFights").to_int();
	if (voteMonsterNext() && wantVoteMonster()
		&& count_accessories(maxString) < 3 && !wantsToNotEquip(maxString, $item[&quot;I Voted!&quot; sticker])) {
		maxString = maxStringAppend(maxString, "equip \"i voted!\" sticker");
		// no point in the thumb ring if it is a free fight
		if (to_int(get_property("_voteFreeFights")) < 3 && !wantsToEquip(maxString, $item[mafia thumb ring]))
			maxString = maxStringAppend(maxString, "-equip mafia thumb ring");
	}

	// GARBAGE TOTE ITEMS: BROKEN CHAMPAGNE BOTTLE will try to equip all sorts of +item things when we equip the broken champagne bottle
	if (!wantsToEquip(maxString, $item[broken champagne bottle]) && !wantsToNotEquip(maxString, $item[broken champagne bottle])) // do not switch to another tote item! we have champagne charges leftover from yesterday
		maxString = maxStringAppend(maxString, "-equip broken champagne bottle");
	if (!isToteSwitchSafe() && !wantsToEquip(maxString, $item[wad of used tape]) && !wantsToNotEquip(maxString, $item[wad of used tape])) // do not switch to another tote item! we have champagne charges leftover from yesterday
		maxString = maxStringAppend(maxString, "-equip wad of used tape");
	if (!isToteSwitchSafe() && !wantsToEquip(maxString, $item[makeshift garbage shirt]) && !wantsToNotEquip(maxString, $item[makeshift garbage shirt])) // do not switch to another tote item! we have champagne charges leftover from yesterday
		maxString = maxStringAppend(maxString, "-equip makeshift garbage shirt");

	if (wantsToEquip(maxString, $item[broken champagne bottle])) { // if we're equipping the champagne bottle, equip all the +item stuff
		int champagneChargesAvailable = to_int(get_property("garbageChampagneCharge"));
		int otoscopeChargesAvailable = 3 - to_int(get_property("_otoscopeUsed"));
		int cloakChargesAvailable = 10 - to_int(get_property("_vampyreCloakeFormUses"));

		if (available_amount($item[broken champagne bottle]) == 0 || (champagneChargesAvailable == 0 && !to_boolean(get_property("_garbageItemChanged")))) {
			cli_execute("tote 2");
			champagneChargesAvailable = to_int(get_property("garbageChampagneCharge"));
		}
		if (otoscopeChargesAvailable > 0 && count_accessories(maxString) < 3) {
			maxString += ", equip Lil' Doctor&trade; bag";
		}
		if (cloakChargesAvailable > 0 && !wantsToEquip(maxString, $slot[back])) {
			maxString += ", equip vampyric cloake";
		}
	}

	// OYSTER DAY
	if (!inRonin() && isOysterDay()) {
		if (!wantsToEquip(maxString, $slot[off-hand]) && !wantsToNotEquip(maxString, $item[oyster basket]) && countHandsUsed(maxString) < 2)
			maxString = maxStringAppend(maxString, "equip oyster basket");
	}

	// GUZZLR items if we're in a Guzzlr quest location
	if (!inRonin()) {
		if (advLocation == guzLoc && have_item(guzItem)) {
			if (count_accessories(maxString) < 3 && !wantsToNotEquip(maxString, $item[Guzzlr shoes]))
				maxString = maxStringAppend(maxString, "equip Guzzlr shoes");
			if (!wantsToEquip(maxString, $slot[pants]) && !wantsToNotEquip(maxString, $item[Guzzlr pants]))
				maxString = maxStringAppend(maxString, "equip Guzzlr pants");
			// gives extra stats
// 			if (guzzlrQuestTurns(true) <= 1 + pocketProfessorLecturesAvailable() && !wantsToEquip(maxString, $slot[hat]) && !wantsToNotEquip(maxString, $item[Guzzlr hat]))
// 				maxString = maxStringAppend(maxString, "equip Guzzlr hat");
		} else if (onGuzzlrQuest() && advLocation == guzLoc && !have_item(guzItem)) {
			print("******** WARNING: wanted to dress for Guzzlr delivery but we don't have the delivery item ***************", "red");
			printGuzzlrQuest();
		}
	}

	// MAFIA THUMB RING if we have room and the item, equip the thumb ring when +item is at least +900% (since the item it replaces is at least +50% item vs +5% adv)
	// this assumes we're grinding and not adventuring in PirateRealm, for example
	if (count_accessories(maxString) < 3 && have_item($item[mafia thumb ring])
		&& !wantsToNotEquip(maxString, $item[mafia thumb ring]) && can_equip($item[mafia thumb ring])
		&& ((selector.contains_text("item") && item_drop_modifier() >= 900)
			|| (selector.contains_text("meat") && meat_drop_modifier() >= 900)
			|| (!selector.contains_text("item") && !selector.contains_text("meat"))))
		maxString = maxStringAppend(maxString, "equip mafia thumb ring");

	// TODO lucky golden ring -- wear whenever we have access to spring break beach, conspiracy island, dinseylandfill, etc., not sure how to figure out if we have access

	// DOLPHINS -- NB: doesn't have to be underwater
	if (get_property("dolphinItem") != "" && get_property("dolphinItem").to_item().cheapest_price() >= kTurnValue / 2
		&& !maxString.contains_text("clownosity") // we need the hat slot for clownosity
		&& !wantsToEquip(maxString, $slot[hat])
		&& !wantsToNotEquip(maxString, $item[Dolph Bossin's Crimbo hat]))
		maxString = maxStringAppend(maxString, "equip Dolph Bossin's Crimbo hat");

	// COMBAT LOVERS LOCKET -- at this point, anything without reminiscences is more likely to be uncopyable
// 	if (!inRonin() && count_accessories(maxString) < 3 && !wanderingMonstersBad(maxString)
// 			&& !wantsToEquip(maxString, $slot[off-hand])
// 			&& !wantsToNotEquip(maxString, $item[combat lover's locket])
// 			&& count(cllLocalNoReminiscence(advLocation)) > 0) {
// 		maxString = maxStringAppend(maxString, "equip combat lover's locket");
// 	}

	// EVERFULL DART HOLSTER
	if (count_accessories(maxString) < 3 && have_item($item[Everfull Dart Holster])
		&& !wantsToNotEquip(maxString, $item[Everfull Dart Holster]) && can_equip($item[Everfull Dart Holster])
		&& (have_effect($effect[Everything Looks Red]) == 0
		  || ("_dartsUsed".get_property().to_int() >= 3 && (selector.contains_text("meat") || selector.contains_text("item")))))
		maxString = maxStringAppend(maxString, "equip Everfull Dart Holster");

	// AEROGEL ATTACHE CASE if we restarted mafia, the aerogelAttacheCaseItemDrops count will be off so just don't equip if we've restarted
	if (!inRonin() && !haveRestartedMafia() && aerogelAttacheCaseItemDrops() < 4
		&& !wantsToEquip(maxString, $slot[off-hand]) && !wantsToNotEquip(maxString, $item[aerogel attache case])
		&& countHandsUsed(maxString) < 2 && have_effect($effect[Fishy]) == 0)
		maxString = maxStringAppend(maxString, "equip aerogel attache case");

	// PANTOGRAM PANTS equip for occasional hilarity
	if (!wantsToEquip(maxString, $slot[pants]) && !wantsToNotEquip(maxString, $item[pantogram pants])
		&& !maxString.contains_text("clownosity") // we need the pants slot for clownosity
		&& get_property("_pantogramModifier").contains_text("Drops Items"))
		maxString = maxStringAppend(maxString, "equip pantogram pants");

	// JUNE CLEAVER -- still get 3 gains per adv on the 6th dream (2 gains on the 7th and beyond), but low value
	if (!inRonin() && get_property("_juneCleaverEncounters").to_int() < 7
		&& get_property("_juneCleaverSkips").to_int() >= 5 // if we have skips, would be caught above and already equipped
		&& !maxString.contains_text("clownosity") // we need the weapon slot for clownosity
		&& !wantsToEquip(maxString, $slot[weapon]) && !wantsToNotEquip(maxString, $item[June cleaver]))
		maxString = maxStringAppend(maxString, "equip June cleaver");

	// LIL' DOCTOR™ BAG -- if we don't have the LDB quest, wear the LDB
	if (count_accessories(maxString) < 3
			&& !wantsToNotEquip(maxString, $item[Lil' Doctor&trade; bag])
			&& questStage("questDoctorBag") <= -1) {
		maxString = maxStringAppend(maxString, "equip Lil' Doctor&trade; bag");
	}

	// FISHING
	if (!inRonin() && vipLoungeAvailable() && isFloundryLocation(advLocation)) {
		if (!wantsToEquip(maxString, $slot[pants]) && !wantsToNotEquip(maxString, $item[government-issued slacks]))
			maxString = maxStringAppend(maxString, "equip government-issued slacks");
		if (!wantsToEquip(maxString, $slot[hat]) && !wantsToNotEquip(maxString, $item[fishin' hat]))
			maxString = maxStringAppend(maxString, "equip fishin' hat");
	}

	// KoL Con 13 snowglobe
	if (!inRonin()
		&& !wantsToEquip(maxString, $slot[off-hand]) && !wantsToNotEquip(maxString, $item[KoL Con 13 snowglobe]) && countHandsUsed(maxString) < 2)
		maxString = maxStringAppend(maxString, "equip KoL Con snowglobe");

	// RANDOM LATTE LOVERS MEMBER'S MUG unlocks
	if (!isLatteLocationUnlocked(advLocation) && countHandsUsed(maxString) < 2
		&& !wantsToEquip(maxString, $slot[off-hand])
		&& !wantsToNotEquip(maxString, $item[latte lovers member's mug])) {
		maxString = maxStringAppend(maxString, "equip latte lovers member's mug");
	}

    // CANDY CANE SWORD CANE adds options to many NCs -- mostly low value crap drops, but if we don't have anything in the weapon slot, equip in some locations
    // TODO most of these only drop once per day
    if (!inRonin() && !wantsToEquip(maxString, $slot[weapon]) && !wantsToNotEquip(maxString, $item[Candy cane sword cane])
        && (advLocation == $location[Madness Bakery] || advLocation == $location[The Sleazy Back Alley] || advLocation == $location[The Overgrown Lot]
            || advLocation == $location[The Haunted Bedroom] || advLocation == $location[The Haunted Library] || advLocation == $location[The Spooky Forest]
            || advLocation == $location[The Daily Dungeon] || advLocation == $location[South of the Border] || advLocation == $location[The Penultimate Fantasy Airship]
            || advLocation == $location[The Castle in the Clouds in the Sky (Basement)] || advLocation == $location[A Mob of Zeppelin Protesters] || advLocation == $location[Inside the Palindome]
            || advLocation == $location[The eXtreme Slope]))
        maxString = maxStringAppend(maxString, "equip Candy cane sword cane");

	// SAUSAGE GOBLINS (LOW CHANCE) if we don't have anything in the off-hand, equip the kramco if we have a 20% chance of a sausage goblin
	if (!inRonin() && lowChanceOfSausageGoblin && countHandsUsed(maxString) < 2 && !wanderingMonstersBad(maxString)
		&& !wantsToEquip(maxString, $slot[off-hand]) && !wantsToEquip(maxString, $item[backup camera]) // if we're backing up to another monster, we don't want any chance of a sausage goblin
		&& !wantsToNotEquip(maxString, $item[Kramco Sausage-o-Matic&trade;])) {
		maxString = maxStringAppend(maxString, "equip Kramco Sausage-o-Matic&trade;");
	}

	// FAMILIAR SCRAPBOOK -- default off-hand item???? -- right now just if the familiar needs xp
	if (!inRonin()
		&& (my_familiar() == $familiar[Pocket Professor]
			|| my_familiar() == $familiar[Grey Goose]
			|| (my_familiar() != $familiar[Trick-or-Treating Tot]
				&& my_familiar() != $familiar[XO Skeleton]
				&& my_familiar() != $familiar[Robortender])
			&& my_familiar_weight() < 20)
		&& !wantsToEquip(maxString, $slot[off-hand]) && !wantsToNotEquip(maxString, $item[familiar scrapbook]) && countHandsUsed(maxString) < 2)
		maxString = maxStringAppend(maxString, "equip familiar scrapbook");

	// LATTE LOVER'S MEMBER'S MUG -- Gulp Latte: free mp regen, low value
	if (!"_latteDrinkUsed".get_property().to_boolean() && my_mp() / my_maxmp() <= 0.5 && countHandsUsed(maxString) < 2
	    && !wantsToEquip(maxString, $slot[off-hand]) && !wantsToNotEquip(maxString, $item[latte lovers member's mug])) {
		maxString = maxStringAppend(maxString, "equip latte lovers member's mug");
	}


	// melee vs ranged -- need to be careful with vote monsters as they scale, done last in case we equip any weapons during auto dressup
	// TODO not sure if we actually want to do this
	if (!wantsToEquip(maxString, $slot[weapon])) {
		if (my_primestat() == $stat[muscle]) {
// 			if (my_class() == $class[seal clubber] && have_effect($effect[Fishy]) == 0) {
// 				if (have_effect($effect[Iron Palms]) > 0)
// 					maxString = maxStringAppend(maxString, "type club, type sword");
// 				else
// 				maxString = maxStringAppend(maxString, "type club");
// 			} else
// 				maxString = maxStringAppend(maxString, "melee");
		} else if (my_primestat() == $stat[moxie] && !wantsToEquipMelee(maxString)) {
// 			if (my_class() == $class[accordion thief])
// 				maxString = maxStringAppend(maxString, "type accordion");
// 			else
// 				maxString = maxStringAppend(maxString, "-melee");
		}
	}

	return maxString;
}


string kDressupOutfitPrefixKey = "_smm.DressupTmp: ";

// What dressup() does with the familiar when it finds a cached outfit for its max string.
// The cache is keyed on the max string alone, and the same max string can go with different
// familiars: the "default" selector picks by drop progress, "item" and "meat" pick by what we
// own, and an empty selector or "-familiar" leaves whichever familiar is out. So the familiar
// saved with the cache is only right when it is still the one chooseFamiliar() wants.
// Restoring it blindly put the old familiar back on every other dressup(), and chooseFamiliar()
// swapped it out again on the next one.
string kDressupCacheLeaveFamiliar = "leave";     // restore the gear, don't touch the familiar or its equipment
string kDressupCacheRestoreFamiliar = "restore"; // restore the gear, the familiar and its equipment
string kDressupCacheStale = "stale";             // cached with another familiar: maximize again

// maxString: the full max string, after chooseFamiliar()
// cachedFamiliar: the familiar saved with the cached outfit
// currentFamiliar: the familiar out now, i.e. after chooseFamiliar()
string dressupCacheFamiliarAction(string maxString, familiar cachedFamiliar, familiar currentFamiliar) {
	// the maximizer was told to keep its hands off the familiar, so we do too
	if (maxString.contains_text("-familiar"))
		return kDressupCacheLeaveFamiliar;
	// chooseFamiliar() left the choice to the maximizer ("switch Disgeist"), so the familiar it chose last time stands
	if (maxString.contains_text("switch "))
		return kDressupCacheRestoreFamiliar;
	// chooseFamiliar() chose: the cache is good only if it was made with that familiar
	if (cachedFamiliar == currentFamiliar)
		return kDressupCacheRestoreFamiliar;
	return kDressupCacheStale;
}

// if selector is empty, doesn't make any changes to the max string (other than the tweak string when dressup(string tweak) calls this)
void dressup(location advLocation, string selector, string familiarSelector, string additionalMaxString) {
    print("dressup: at location: " + advLocation + ", selector: " + selector + ", familiarSelector: " + familiarSelector + ", additionalMaxString: " + additionalMaxString, "blue");

	if (advLocation != $location[none])
		set_location(advLocation);

	string maxString;
	if (selector != "")
		maxString = maximizerStringForDressup(advLocation, selector, additionalMaxString);
	else
		maxString = additionalMaxString;

	maxString = chooseFamiliar(familiarSelector, advLocation, $monster[none], maxString);

	print("after: at location: " + advLocation + ", max string: " + maxString, "blue");

	// we're not forcing re-maximization and we have the exact maximize string already cached
	string cachedOutfit = kDressupOutfitPrefixKey + maxString;
	string cacheFamiliarAction = kDressupCacheStale;
	if (!get_property(kForceDressupKey).to_boolean() && maxString == get_property(kDressupLastFullMaxStringKey) && haveOutfit(cachedOutfit)) {
		cacheFamiliarAction = dressupCacheFamiliarAction(maxString, get_property(kSavedFamiliarKeyPrefix + cachedOutfit).to_familiar(), my_familiar());
		if (cacheFamiliarAction == kDressupCacheStale)
			print("the cached dressup was made with another familiar, maximizing again", "blue");
	}

	if (cacheFamiliarAction != kDressupCacheStale) {
		print("skipping maximize for same max string, restoring existing dressup instead", "blue");
		restoreOutfit(cacheFamiliarAction == kDressupCacheRestoreFamiliar, cachedOutfit);

	} else {
		saveAndSetProperty("logPreferenceChange", "false"); // try to avoid log spam
		try {
print("here111");
			if (!maximize(maxString, false)) {
print("here11");
				unequipAll(false); // don't need to unequip familiar
				maximize(maxString, false);
			}
print("here1");

			// finally, do a maximize with a close-to-right outfit and see if there's a tweak
			if (!maximize(maxString, false))
				abort("dressup: maximizer failed");

print("here2");
			if (kSpikolodonNextCombatKey.get_property().to_boolean()) {
				assert(equipped_amount($item[Jurassic Parka]) >= 1, "we're not wearing the Jurassic Parka after dressing, but we want to cast Spikes next combat!");
				cli_execute("parka spikolodon");
			}

print("here3");
			// short term cache: if kDressupLastFullMaxStringKey is equal to our current max string, we don't maximize at all
			// could theoretically be bad if we don't change up the outfit in a long time
			set_property(kDressupLastFullMaxStringKey, maxString);
			saveOutfit(kDressupSavedEquipSetKey);

print("here4");
			// long-term cache: if we have the outfit stored here, we dress into the cached outfit as our first maximize
			// (which is then followed up by a maximize to ensure we catch any changes since last time we dressed in this outfit)
			saveOutfit(kDressupOutfitPrefixKey + maxString);

			set_property(kForceDressupKey, "false");
		} finally {
			restoreSavedProperty("logPreferenceChange");
		}
	}

	// ensure any valuable items we took off are stowed safely
	// stow_pvpable_items(); // not useful if we have anything we want to use in combat

    print("dressup: done", "blue");
}

// tweak the automated dressup string and wear it
void dressup(string tweak, boolean replaceExistingTweak) {
	string existingTweak = get_property(kDressupTweakStringKey);
	if (existingTweak != "" && !replaceExistingTweak && (!existingTweak.contains_text(tweak) || tweak == "")) {
		tweak = maxStringAppend(existingTweak, tweak);
	}

	set_property(kDressupTweakStringKey, tweak);
	string locationString = get_property(kDressupLocationKey);
	location theLocation = to_location(locationString);
	string dressupMaxString = get_property(kDressupMaxStringKey);

	if ((locationString == "" || locationString == "none" || theLocation == my_location()) && dressupMaxString != "") {
		dressup(theLocation, get_property(kDressupSelectorKey), get_property(kDressupFamiliarSelectorKey), maxStringAppend(dressupMaxString, tweak));
	} else
		print("wrong location (stored loc: \"" + locationString + "\", my loc: \"" + my_location() + "\") OR no max string, SKIPPING maximize", "orange");
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

void clearAutomateDressup() {
	remove_property(kDressupLocationKey);
	remove_property(kDressupSelectorKey);
	remove_property(kDressupFamiliarSelectorKey);
	remove_property(kDressupMaxStringKey);
	remove_property(kDressupLastFullMaxStringKey);
	remove_property(kDressupTweakStringKey);
}

void clearAllDressupCaches() {
	clearAutomateDressup();

	foreach aProp in get_all_properties("_smm.SavedFamiliar_smm.DressupTmp", false)
		remove_property(aProp);
	foreach aProp in get_all_properties("_smm.SavedFamiliarEquipment_smm.DressupTmp", false)
		remove_property(aProp);
	foreach aProp in get_all_properties("_smm.SavedOutfit_smm.DressupTmp", false)
		remove_property(aProp);
	foreach aProp in get_all_properties(kDressupOutfitPrefixKey, false)
		remove_property(aProp);
}

void backupAutomatedDressup(string backupKey) {
	string backupKeyToUse = backupKey;
	if (!backupKey.starts_with("_"))
		backupKeyToUse = "_" + backupKeyToUse;

	set_property(backupKeyToUse + kDressupLocationKey, get_property(kDressupLocationKey));
	set_property(backupKeyToUse + kDressupSelectorKey, get_property(kDressupSelectorKey));
	set_property(backupKeyToUse + kDressupFamiliarSelectorKey, get_property(kDressupFamiliarSelectorKey));
	set_property(backupKeyToUse + kDressupMaxStringKey, get_property(kDressupMaxStringKey));
	set_property(backupKeyToUse + kDressupTweakStringKey, get_property(kDressupTweakStringKey));
	set_property(backupKeyToUse + kDressupLastFullMaxStringKey, get_property(kDressupLastFullMaxStringKey));

	set_property(backupKeyToUse + kSavedFamiliarKeyPrefix, get_property(kSavedFamiliarKeyPrefix));
	set_property(backupKeyToUse + kSavedFamiliarEquipKeyPrefix, get_property(kSavedFamiliarEquipKeyPrefix));

// 	saveOutfit(backupKeyToUse + "_outfit");
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

	set_property(kSavedFamiliarKeyPrefix, get_property(backupKeyToUse + kSavedFamiliarKeyPrefix));
	set_property(kSavedFamiliarEquipKeyPrefix, get_property(backupKeyToUse + kSavedFamiliarEquipKeyPrefix));

	// we definitely DO NOT want to restoreOutfit here!!!
// 	if (haveOutfit(backupKeyToUse + "_outfit")) {
// 	}
}


string fixupCLArtifacts(string maximizerString) {
	return maximizerString.replace_string("|", ",");
}


// sets up automation for dressing:
// 1. will equip various useful and/or fun items like the pantogram pants
//    will respect any "-equip <item>" that shows up in additionalMaxString, so you can tweak the automation, won't detect categories of items or outfits
//    will not equip any useful/fun items automatically if item_selector is blank, useful to get redirect automation without the fun items taking up valuable slots
// 2. will automatically equip the "i voted!" sticker every 11 turns unless -equip "i voted!" sticker is specified in additionalMaxString
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
void automate_dressup(location aLocation, string selector, string familiar_selector, string additionalMaxString) {
	clearAutomateDressup(); // clear any previous automated dressup, but don't clear caches
	//if (aLocation != $location[none])
	//	set_location(aLocation);

	string parsed_additionalMaxString = fixupCLArtifacts(additionalMaxString);
	parsed_additionalMaxString = maxStringAppend(parsed_additionalMaxString, get_property("dressupGlobalTweakString"));
	dressup(aLocation, selector, familiar_selector, parsed_additionalMaxString);

	set_property(kDressupLocationKey, to_string(aLocation));
	set_property(kDressupSelectorKey, selector);
	set_property(kDressupFamiliarSelectorKey, familiar_selector);
	set_property(kDressupMaxStringKey, parsed_additionalMaxString);
}



// -------------------------------------
// REDIRECTION
// -------------------------------------

int [location] gLockedLocationWaitWarningTime;

// returns the location we should go when we do a wandering-monster redirect
// this should be the most important place to burn delay
location redirectionDelayLocation() { // #locationfordelay #redirect delay location #redirectdelaylocation
	location rval;
	string reason;
	string ingredient = nextLatteIngredient();
	item guzItem = to_item(get_property("guzzlrQuestBooze"));
	location guzLoc = to_location(get_property("guzzlrQuestLocation"));
	string guzTier = get_property("guzzlrQuestTier");
	location sotsQuestLocation = "_sotParcelReturned".get_property().to_boolean() ? $location[none] : sotsQuestLocation();


    // LUCKY! -- should always be checked first
    if (have_effect($effect[Lucky!]) > 0) {
		reason = "lucky";
		rval = $location[The Oasis];


	// LATTE LOVERS MEMBER'S MUG unlocks -- high priority so we can get the +4 rollover adventures
	} else if (ingredient != "") {
		assert(!isLatteIngredientUnlocked(ingredient), "nextLatteIngredient returned an unlocked ingredient");
		reason = "latte ingredient: " + ingredient;
		rval = kLatteLocations[ingredient];


	// AZAZEL we need non-combats, don't do if we finished, have the unicorn or we have all 4 items -- WE WANT NC HERE, SO ONLY BACKUP CAMERA WORKS, NOT JUST DELAY FROM WANDERING MONSTERS
// 	} else if (!(get_property("questM10Azazel") == "finished" || have_item($item[Azazel's unicorn])
// 		|| (have_item($item[comfy pillow]) && have_item($item[giant marshmallow]) && have_item($item[beer-scented teddy bear]) && have_item($item[booze-soaked cherry])) )) {
// 		reason = "Azazel";
// 		rval = $location[infernal rackets backstage];


	// PAGODA -- hey deze map is a superlikely, which is checked for BEFORE wandering monsters, so this makes sense
	} else if (!(have_item($item[Hey Deze map]) || (get_campground() contains $item[pagoda plans]))) {
		reason = "pagoda (Hey Deze map)";
		rval = $location[pandamonium slums];

	// elf farm raffle ticket superlikely
	} else if (have_item($item[Talisman o' Namsilat])
		&& item_amount($item[elf farm raffle ticket]) == 0 && !(get_campground() contains $item[pagoda plans])) {
		reason = "pagoda (elf farm raffle ticket)";
		rval = $location[inside the palindome];


	// TODO zap wand
	} else if (get_property("lastPlusSignUnlock").to_int() < my_ascensions() && !have_item($item[plus sign])) {
		reason = "zap wand: looking for plus sign";
		rval = $location[The Enormous Greater-Than Sign];


	// GUILD
	} else if (get_property("questG07Myst") == "started") {
		reason = "guild quest";
		rval = $location[The Haunted Pantry];

	} else if (get_property("questG08Moxie") == "started") {
		reason = "guild quest";
		rval = $location[The Sleazy Back Alley];

	} else if (get_property("questG09Muscle") == "started") {
		reason = "guild quest";
		rval = $location[The Outskirts of Cobb's Knob];


	// TODO hmm, wiki says it is a NC with a 5-7 turn delay, but i'm not so sure -- pretty sure this is a superlikely
	} else if (get_property("questG04Nemesis") == "started" && $location[The Unquiet Garves].turns_spent < 5) {
		reason = "guild quest";
		rval = $location[The Unquiet Garves];
	} else if (get_property("questG04Nemesis") == "started" && $location[The Unquiet Garves].turns_spent >= 5) {
		print("*** Guild Quest is ready! ***", "red");
		rval = $location[The Unquiet Garves];

	} else if (questStage("questG04Nemesis") == 5) {
		reason = "guild quest";
		rval = $location[The "Fun" House]; // looking for Adventurer, $1.99 -- a superlikely, so we DO NOT need -combat


	// TODO poop deck

	// GUZZLR gold or platinum quest -- gold and platinum get precedence, see below for bronze
	} else if (guzItem != $item[none] && guzLoc != $location[none] && (guzTier == "gold" || guzTier == "platinum")) {
		if (isUnlocked(guzLoc)) {
			fullAcquire(guzItem);
			reason = "quzzlr gold or platinum quest";
			rval = guzLoc;
		} else {
			print(guzLoc + " is not yet unlocked, skipping Guzzlr quest!!!!!!!!!!!!!!!!!!", "red");
			waitq(max(0, 10 - gLockedLocationWaitWarningTime[guzLoc]++));
// 			abort(guzLoc + " is not yet unlocked");
		}


	// OLIVER's PLACE
	} else if (sotsQuestLocation != $location[none]
        // these locations are not available in ronin
		&& sotsQuestLocation != $location[A Massive Ziggurat]
		&& sotsQuestLocation != $location[An Overgrown Shrine (Northwest)]
		&& sotsQuestLocation != $location[An Overgrown Shrine (Northeast)]
		&& sotsQuestLocation != $location[An Overgrown Shrine (Southwest)]
		&& sotsQuestLocation != $location[An Overgrown Shrine (Southeast)]
		// these locations will get done automatically elsewhere
		&& (sotsQuestLocation != $location[The Neverending Party] || ("_neverendingPartyFreeTurns".get_property().to_int() >= 9 && !"_neverendingPartyToday".get_property().to_boolean()))
		&& !sotsQuestLocation.to_string().contains_text("Shadow Rift") // and in this case we don't want to redirect into the shadow rift as these turns are free anyway
	) {
		reason = "Milky-Eyed Sot's quest";
		rval = sotsQuestLocation;


	// for the A Quest, LOL quest
	} else if ($location[The Valley of Rof L'm Fao].turns_spent < 10) {
		reason = "A Quest, LOL quest";
		rval = $location[The Valley of Rof L'm Fao];


	// UNTINKER
	} else if (get_property("questM01Untinker") == "started") {
		reason = "untinker";
		rval = $location[The Degrassi Knoll Garage];


	// GUY MADE OF BEES #guy made of bee pollen -- NEEDS BACKUP CAMERA ONLY!!
// 	} else if (rval == $location[none] && !get_property("guyMadeOfBeesDefeated").to_boolean()) {
// 		reason = "Guy Made of Bee Pollen";
// 		rval = $location[The Haunted Bathroom];


	// GUZZLR bronze quest
	} else if (guzItem != $item[none] && guzLoc != $location[none]) {
		if (isUnlocked(guzLoc)) {
			fullAcquire(guzItem);
			reason = "quzzlr bronze quest";
			rval = guzLoc;
		} else {
			if (!get_property("_smm.GuzzlrLocationLockedWarningDone").to_boolean()) {
				set_property("_smm.GuzzlrLocationLockedWarningDone", "true");
				abort(guzLoc + " is not yet unlocked");
			}
		}


	// LIL' DOCTOR™ BAG
	} else if (questStage("questDoctorBag") >= 0) {
		item docQuestItem = get_property("doctorBagQuestItem").to_item();
		string docQuestNumberString = get_property("doctorQuestNumber");
		int docQuestNumber = docQuestNumberString == "" ? 1 : docQuestNumberString.to_int();
		int acquired = fullAcquire(docQuestItem, docQuestNumber);

		reason = "Lil' Doctor bag quest";
		rval = get_property("doctorBagQuestLocation").to_location();

		assert(item_amount(docQuestItem) >= docQuestNumber, "couldn't get " + docQuestNumber + "X " + docQuestItem + " for a Lil' Doctor bag quest, only got " + docQuestNumber);
		assert(rval != $location[none], "didn't get Lil' Doctor bag quest location");


	// DEFAULT go to the smut orc logging camp to get smut orc pervert
	} else {
		int turnsToPervert = 19 - smutOrcPervertProgress();
		if (turnsToPervert == 0)
			if (!smmConfirm(turnsToPervert + " turns to Smut Orc Pervert, " + $location[The Smut Orc Logging Camp].turns_spent + " turns spent -- adventuring here will overwrite it. Continue?", false))
				abort();
		reason = "smut orc keepsake box. Progress to pervert BEFORE adventure: " + smutOrcPervertProgress();
		rval = $location[The Smut Orc Logging Camp];
	}

	print("redirectionDelayLocation: redirecting to " + rval + " for reason: " + reason, "orange");
	return rval;
}



string burnNextGodLobster() {
	string rval;

	int glFightsAvailable = 3 - to_int(get_property("_godLobsterFights"));
	if (glFightsAvailable == 0) return "";

	print("burnNextGodLobster, " + glFightsAvailable + " fights available", "green");

	if(!have_item($item[God Lobster's Crown]))
		rval = cli_execute_output("GodLobster regalia");
	else
		rval = cli_execute_output("GodLobster xp");

	return rval;
}



string toString(AdventureRecord advRecord) {
	if (advRecord.locationToUse != $location[none])
		return advRecord.locationToUse.to_string();
	else if (advRecord.itemToUse != $item[none])
		return advRecord.itemToUse.to_string();
	else if (advRecord.skillToUse != $skill[none])
		return advRecord.skillToUse.to_string();
	else
		return advRecord.funcString;
}


// adventures at advRecord (a location, item or skill) including all pre-adventure checks but NOT finishing the turn
string getToAdventure(AdventureRecord advRecord) {
    // if we have a function string, call it first, as it might do things like dress up for the adventure
    if (advRecord.funcString != "") {
        string callString = advRecord.funcString;
        print("calling " + callString, "green");
        return call string callString ();

    } else if (advRecord.locationToUse != $location[none])
		return advURL(advRecord.locationToUse);

	else if (advRecord.itemToUse != $item[none]) {
		preAdventureChecks();
		return museumSafeUse(1, advRecord.itemToUse);

	} else if (advRecord.skillToUse != $skill[none]) {
		preAdventureChecks();
		return use_skill(advRecord.skillToUse);
	}

    abort("getToAdventure: invalid AdventureRecord. No function, location, item or skill to use");
    return ""; // unreachable
}



// adventures at advRecord (a location, item or skill) including all pre- and post-adventure stuff
boolean anyAdventure(AdventureRecord advRecord) {
    print("anyAdventure: going to " + toString(advRecord), "green");
	string result = getToAdventure(advRecord);
	result += run_turn();
	assert(!postAdventure(), "anyAdventure: goals were satisfied, aborting");
	return true;
}



// fix for shadow locations not working
string [location] bugfixMap = {
	$location[Shadow Rift (The 8-Bit Realm)] : "/place.php?whichplace=8bit&action=8rift_free",
};



// prep for real location we're going to adventure at
// if we aren't going to redirect, this means doing essentially nothing
// if we ARE going to redirect, dressup and set the state for the redirect
// the redirection location is generally determined by redirectionDelayLocation()
location realAdvLocation(location aLocation, boolean shouldPrep) {
	location actualLocation = aLocation;
	string redirectOutfitSelector = "combat"; // we never want a NC when redirecting, more +combat will be added by maxStringForLocation
	string redirectionMaxString = isToteSwitchSafe() ? "" : "-equip makeshift garbage shirt";
	string redirectFamiliarSelector = "default"; // WE PROBABLY DO NOT WANT DEFAULT FAMILIAR -- the robortender might get equipped due to high value in the redirected-to zone


	// REDIRECT
	if (!inRonin()) { // no redirect in ronin, ever
		location sotLoc = "_sotParcelLocation".get_property().to_location();

        // LUCKY!
        if (have_effect($effect[Lucky!]) > 0) {
            // get Ultrahydrated -- TODO figure out better things to do with lucky
            // it's a guaranteed NC
			actualLocation = redirectionDelayLocation();
			redirectOutfitSelector = "mp regen";
			redirectionMaxString = maxStringAppend(redirectionMaxString, "-equip \"I Voted!\" sticker, -equip Kramco Sausage-o-Matic&trade;, -equip cursed magnifying glass, -equip broken champagne bottle, -equip mafia thumb ring, -equip aerogel attache case, -equip pantogram pants");
			print("advURLWithWanderingMonsterRedirect: redirecting to " + actualLocation + " for a Lucky! adventure at The Oasis", "orange");


		// JUNE CLEAVER -- these NC's generally don't advance delay() but they do for the Sot's quest
		} else if (!"_sotParcelReturned".get_property().to_boolean() && "_juneCleaverFightsLeft".get_property().to_int() <= 0
			&& sotLoc != $location[none] && sotLoc != $location[A Massive Ziggurat]
			&& sotLoc != $location[An Overgrown Shrine (Northwest)] && sotLoc != $location[An Overgrown Shrine (Northeast)]
			&& sotLoc != $location[An Overgrown Shrine (Southwest)] && sotLoc != $location[An Overgrown Shrine (Southeast)]
			&& (sotLoc != $location[The Neverending Party] || "_neverendingPartyFreeTurns".get_property().to_int() >= 9 || "_neverendingPartyToday".get_property().to_boolean())
			&& !sotLoc.to_string().contains_text("Shadow Rift")) {
			actualLocation = sotLoc;
			redirectOutfitSelector = "equip June Cleaver"; // cleaver adventures never risk a NC (???????????????)
			redirectionMaxString = maxStringAppend(redirectionMaxString, "-equip \"I Voted!\" sticker, -equip Kramco Sausage-o-Matic&trade;, -equip cursed magnifying glass, -equip broken champagne bottle, -equip mafia thumb ring, -equip aerogel attache case, -equip pantogram pants"); // we don't need exp for cleaver adventures, so overwrite this instead of adding to it
			print("advURLWithWanderingMonsterRedirect: redirecting to " + actualLocation + " for a June Cleaver adventure at the Sot's quest", "orange");


		// SAUSAGE GOBLIN guaranteed
		} else if (chanceOfSausageGoblinNextTurn() >= 1.0) {
			actualLocation = redirectionDelayLocation();

			redirectOutfitSelector = "5 item";
			redirectionMaxString = maxStringAppend(redirectionMaxString, "equip Kramco Sausage-o-Matic&trade;, -equip \"I Voted!\" sticker, -equip June Cleaver, -equip cursed magnifying glass, -equip Everfull Dart Holster, -equip broken champagne bottle, -equip mafia thumb ring, -equip aerogel attache case, -equip pantogram pants");

            // don't waste the early (higher-chance) space jellyfish uses on a sausage goblin
			if ("_spaceJellyfishDrops".get_property().to_int() >= 2)
				redirectFamiliarSelector = "space jellyfish";
			else
                redirectFamiliarSelector = "default";
			print("advURLWithWanderingMonsterRedirect: redirecting to " + actualLocation + " for a sausage goblin", "orange");


		// VOTE MONSTER -- if it's free or valued at more than the turn value
		} else if (voteMonsterNext()) {
			monster voteMonster = get_property("_voteMonster").to_monster();
			if (wantVoteMonster()) {
				actualLocation = redirectionDelayLocation();

				redirectionMaxString = maxStringAppend(redirectionMaxString, "-equip broken champagne bottle, -equip mafia thumb ring, -equip aerogel attache case, -equip pantogram pants, equip \"I Voted!\" sticker, -equip Kramco Sausage-o-Matic&trade;, -equip cursed magnifying glass, -equip June Cleaver");

				if (voteMonster == $monster[terrible mutant]
					|| voteMonster == $monster[angry ghost]
					|| voteMonster == $monster[government bureaucrat]
					|| voteMonster == $monster[slime blob]) {
					redirectOutfitSelector = "10 item";
					redirectFamiliarSelector = "item";
				} else if (nonCombatChance(actualLocation) == 0.0) {
					redirectOutfitSelector = "exp";
				}

				// VOTE MONSTER OUTFIT -- uncomment one of these 3 options
				if (voteMonster == $monster[terrible mutant])
					redirectionMaxString = maxStringAppend(redirectionMaxString, ""); // equip nothing = get mutant arm
// 				if (voteMonster == $monster[terrible mutant] && available_amount($item[mutant arm]) > 0 && countHandsUsed(redirectionMaxString) < 2) // equip the mutant arm to get the mutant legs
// 					redirectionMaxString = maxStringAppend(redirectionMaxString, "+equip mutant arm"); // equip mutant arm = get mutant leg
// 				if (voteMonster == $monster[terrible mutant] && available_amount($item[mutant legs]) > 0 && !wantsToEquip(redirectionMaxString, $slot[pants])) // equip the mutant legs to get the mutant crown
// 					redirectionMaxString = maxStringAppend(redirectionMaxString, "+equip mutant legs"); // equip mutant leg = get mutant crown

				print("advURLWithWanderingMonsterRedirect: redirecting to " + actualLocation + " for a vote monster: " + voteMonster, "orange");
			} else
				print("advURLWithWanderingMonsterRedirect: SKIPPING redirecting to " + actualLocation + " for a vote monster: " + voteMonster + " -- we don't want it", "red");


		// CURSED MAGNIFYING GLASS -- VOID MONSTER
		} else if (get_property("cursedMagnifyingGlassCount").to_int() >= 13 && get_property("_voidFreeFights").to_int() <= 5) {
			actualLocation = redirectionDelayLocation();
			redirectionMaxString = maxStringAppend(redirectionMaxString, "equip cursed magnifying glass, 0.1 exp, -equip Kramco Sausage-o-Matic&trade;, -equip \"I Voted!\" sticker, -equip June Cleaver, -equip Everfull Dart Holster, -equip broken champagne bottle, -equip mafia thumb ring");

			if (nonCombatChance(actualLocation) > 0.0)
				redirectionMaxString = maxStringAppend(redirectionMaxString, "-equip aerogel attache case, -equip pantogram pants");
			else
				redirectOutfitSelector = "exp";

			print("advURLWithWanderingMonsterRedirect: redirecting to " + actualLocation + " for a VOID monster", "orange");


		// PERVERT -- takes a turn, do last
		} else if (smutOrcPervertProgress() >= 19) {
			actualLocation = $location[The Smut Orc Logging Camp];
			redirectOutfitSelector = "exp";
			redirectionMaxString = maxStringAppend(redirectionMaxString, "-equip cursed magnifying glass, -equip Kramco Sausage-o-Matic&trade;, -equip \"I Voted!\" sticker, -equip June Cleaver, -equip broken champagne bottle");
			print("advURLWithWanderingMonsterRedirect: getting smut orc pervert instead", "orange");
		}
	}

	// DRESSUP -- change outfit if redirecting, but make sure the "current" outfit stays the same
	if (shouldPrep && actualLocation != aLocation) {
		saveMood();
		setDefaultMoodForLocation(actualLocation);

		// save and restore the automated dressup settings that got us to our current outfit
		backupAutomatedDressup(kRedirectSavedEquipSetKey);

		automate_dressup(actualLocation, redirectOutfitSelector, redirectFamiliarSelector, redirectionMaxString);

		restoreAutomatedDressup(kRedirectSavedEquipSetKey);

		healIfRequiredWithMPRestore(); // outfit change might have changed maxhp, so need to manually heal here

	} else { // if we redirected last adv, this should dress us in the proper attire
		if (haveSavedMood()) {
			restoreSavedMood();
			deleteSavedMood();
		}

		set_location(aLocation);
		dressup("", false);
	}

	return actualLocation;
}


// true iff the next time we adventure with advURLWithWanderingMonsterRedirect we will redirect
boolean willRedirect(location aLocation) {
	return realAdvLocation(aLocation, false) != aLocation;
}



// Adventure with advURL() (which means doing the same pre-automation that adventure() does, but without the turn automation or post-automation)
// but automatically redirects known wandering monsters to areas with delay
// Useful for when adventuring in an area where burning delay is not useful
// first try: will redirect vote monsters to the smut orc chasm so that we can get smut orc perverts essentially for free
// the adventure itself and post-adv checks have to be done by the caller
// if we redirected, the caller may also have to re-dress -- recommend saving the outfit after dressup() and then restoring after calling this
string advURLWithWanderingMonsterRedirect(location aLocation) {
	preAdventureChecks(); // need this here so any potential maximize before an adv (esp. combat freq) gets the benefit of our mood -- also useful to stop before redressing if there's a trigger

	// REDIRECT LOCATION AND DRESSUP
	location actualLocation = realAdvLocation(aLocation, true);

	// ADVENTURE
	setDefaultMoodForLocation(actualLocation);
	string aPage;
	if (bugfixMap contains actualLocation && have_effect($effect[Shadow Affinity]) > 0) // shadow rift locations are not standard locations
		aPage = advUrl(bugfixMap[actualLocation]);
	else
		aPage = advURL(actualLocation);

	// moved back to postAdventure()
// 	if (actualLocation == $location[The Smut Orc Logging Camp] && aPage.contains_text("fight.php")) {
// 		setSmutOrcPervertProgress(smutOrcPervertProgress() + 1);
// 		print("setting smutOrcPervertProgress to: " + smutOrcPervertProgress() + ", turns spent in zone: " + $location[The Smut Orc Logging Camp].turns_spent + ", turns in zone for last pervert: " + to_int(get_property(kLastSmutOrcPervertTurnsSpentKey)));
// 	}

	return aPage;

	// the adventure itself and post-adv checks have to be done by the caller
	// if we redirected, the caller will also have to re-dress, which it can do with restoreOutfit(kRedirectSavedEquipSetKey, true);
}



// runs a turn given the page string returned from visit_url or advURLWithWanderingMonsterRedirect
// differs from run_turn in that it handles choices that follow the fight, and prints the page when there's an error
string runTurn(string pageString, string scriptString) {
	string rval;

	// ERROR?
	if (isErrorPage(pageString)) {
		abort(pageString);

	// CHOICE
	} else if (handling_choice() || choice_follows_fight()) {
		rval += run_choice(-1);
		assert(!handling_choice(), "still handling a choice"); // TODO choice follow fight

	// "NO ACTION" ADVENTURE (?)
	} else if (!contains_text(pageString, "fight.php")) {
		print("********* DETECTED 'no action' ADVENTURE page output follows **********", "red");
		print(pageString);

	// FIGHT
	} else {
        assert(inCombat(), "not in combat");

		print("executing script: " + scriptString, "green");
		rval += run_combat(scriptString); // we want to run combat this way so that any relevant CCS will override the default kill script in smmConsult
        // rval += customScriptWithDefaultKill(1, last_monster(), pageString, scriptString); DO NOT DO THIS

        if (inCombat()) {
            abort("still in combat after running script: " + scriptString);
        } else if ("_lastCombatLost".get_property().to_boolean()) {
            abort("lost combat after running script: " + scriptString);
        } else if (choice_follows_fight())
			rval += run_choice(-1);
	}

	return rval;
}

// replicates the full automation of adventure() but with automatic redirect of known wandering monsters to areas with delay
// the redirect is handled by advURLWithWanderingMonsterRedirect(), see that above for specifics of what is getting redirected
// returns true if we adventured in the specified location, false otherwise (redirect or failed adv or incomplete adventure/still in a choice/still in a fight)
// calls runTurnCallback with with page and the given script, with a default of runTurn() above.
string redirectAdventureHelper(location aLocation, string scriptString, string runTurnCallback) {
	assert(aLocation != $location[none], "redirectAdventure(location, string): can't adventure at location none");
	if (runTurnCallback == "") runTurnCallback = "runTurn";
	boolean hadGoals = haveGoals(); // if have goals now and not later, presumably they're completed

	moodExecute(); // need this here so any potential maximize before an adv (esp. combat freq) gets the benefit of our mood

	// we need this for automated dressing (even though we are going to dressup
	// for redirect explicitly)... so this may equip something (e.g. i voted sticker, Kramco sausage grinder, etc.)
	// that we might later remove before adventuring
	dressup("", false);
	saveOutfit(kRedirectSavedEquipSetKey); // the outfit we had on before redirecting

	string pageString, turnResults;
	try {
		string pageString = advURLWithWanderingMonsterRedirect(aLocation);

		if (aLocation == my_location())
			turnResults = call string runTurnCallback(pageString, scriptString);
		else
			turnResults = call string runTurnCallback(pageString, ""); // if we redirected, use the default script

	} finally {
		postAdventure();
		if (hadGoals && !haveGoals())
			abort("redirectAdventureHelper: goals completed!");
		restoreOutfit(kRedirectSavedEquipSetKey); // will usually be the same outfit, unless we redirected
		if (my_location() != aLocation)
			set_location(aLocation); // required because after a redirection, the location setting will be incorrect
	}

	return pageString + turnResults;
}

// replicates the full automation of adventure() but with automatic redirect of known wandering monsters to areas with delay
// the redirect is handled by advURLWithWanderingMonsterRedirect(), see that above for specifics of what is getting redirected
// returns true if we adventured in the specified location at least once, false otherwise
// all adventures count against the number of adventures done, even if they take no turns
boolean redirectAdventure(location aLocation, int turnCount, string scriptString, string runTurnCallback) {
	print("redirectAdventure: base location: " + aLocation + ", turns to adventure: " + turnCount + ", script: " + scriptString, "green");

	assert(aLocation != $location[none], "redirectAdventure(location, string, int): can't adventure at location none");

	if (inRonin()) { // no redirect in ronin, ever
		boolean adventureWasSuccessful = adventure(turnCount, aLocation);
		assert(adventureWasSuccessful, "redirectAdventure (in ronin!): failed adventuring in " + aLocation);
		return true;
	}

	int turnsDone = 0;
	while (turnsDone < turnCount && my_adventures() > 0) {
		print("adventure #" + (turnsDone + 1) + " at " + aLocation, "green");
		string adventureResult = redirectAdventureHelper(aLocation, scriptString, runTurnCallback);
		if (isErrorPage(adventureResult)) {
			print(adventureResult, "red");
			return false;
		}
		turnsDone++;
	}

	return true;
}

boolean redirectAdventure(location aLocation, int adventures, string scriptString) {
	return redirectAdventure(aLocation, adventures, scriptString, "");
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
// TARGET MOB
// -------------------------------------

// returns a script for olfacting the given monster
string olfactionScript(monster aMonster) {
	string rval = "";

	if (olfactsAvailable() <= 0)
		print("******* we wanted to olfact " + aMonster + ", but we don't have any more uses of Transcendent Olfaction *******", "red");
	else if (combat_skill_available($skill[Transcendent Olfaction])
		&& to_monster(get_property("olfactedMonster")) != aMonster)
		rval += "skill " + to_int($skill[Transcendent Olfaction]) + ";";

	if (my_mp() < mp_cost($skill[Gallapagosian Mating Call]))
		print("******* we wanted to Gallapagosian Mating Call " + aMonster + ", but we don't have enough MP *******", "red");
	else if (have_skill($skill[Gallapagosian Mating Call])
		&& to_monster(get_property("_gallapagosMonster")) != aMonster)
		rval += "skill " + to_int($skill[Gallapagosian Mating Call]) + ";";

	if ("_latteCopyUsed".get_property().to_boolean())
		print("******* we wanted to Offer Latte to Opponent " + aMonster + ", but today's use is already spent *******", "orange");
	else if (equipped_amount($item[latte lovers member's mug]) < 1
		|| !combat_skill_available($skill[Offer Latte to Opponent]))
		print("******* we wanted to Offer Latte to Opponent " + aMonster + ", but we don't have the skill (we are "
			+ (equipped_amount($item[latte lovers member's mug]) >= 1 ? "" : "NOT")
			+ " wielding the latte lover's mug) *******", "orange");
	else if (to_monster(get_property("_latteMonster")) != aMonster)
		rval += "skill " + to_int($skill[Offer Latte to Opponent]) + ";";

	if (!have_skill($skill[Get a Good Whiff of This Guy]))
		print("******* we wanted to Get a Good Whiff of This Guy " + aMonster + ", but we don't have the skill (familiar is "
			+ (my_familiar() == $familiar[Nosy Nose] ? "" : "NOT")
			+ " Nosy Nose) *******", "yellow");
	else if ((to_monster(get_property("nosyNoseMonster")) != aMonster))
		rval += "skill " + to_int($skill[Get a Good Whiff of This Guy]) + ";";

	return rval;
}


// returns true if we fought the main target and won, false otherwise
string targetMobFightHelper(location aLocation, monster [] target_monsters, string scriptToUse, int maxPerTurnCost, boolean optimal, boolean shouldOlfact) {
	string rval;
	string prefightScript;

	// COMBAT at this point we should be in combat
	assert(inCombat(), "targetMobFightHelper: should be in combat, but we aren't");

	 // the max number of non-targets we want unbanished, 1 if we can replace or 0 otherwise
	int maxNonTargetsUnbanished = 0;
// 	if (have_skill($skill[Macrometeorite]) || item_amount($item[fish-oil smoke bomb]) > 0) maxNonTargetsUnbanished = 1;
	if (have_skill($skill[Macrometeorite])) maxNonTargetsUnbanished = 1;
	int unbanishedNonTargets = unbanishedNonTargets(aLocation, target_monsters);

	// REPLACE/BANISH
	// don't replace a wandering monster, drop through to combat processing, remembering that banish / replace may not result in actually getting a target monster
	if (!contains_monster(aLocation, last_monster())) {
		print("looks like we're in combat with a wandering monster", "orange");

	// A forced encounter (for example, a crystal-ball prediction) can still
	// present a monster Mafia considers banished. Rebanishing cannot improve
	// the normal encounter pool; finish it with the default CCS instead.
	} else if (!arrayContains(target_monsters, last_monster()) && is_banished(last_monster())) {
		print("Encountered an already-banished non-target: " + last_monster() + "; using the default CCS.", "orange");

	// we can usefully replace or banish the monster we're in combat with
	} else if (!arrayContains(target_monsters, last_monster())) {

		// REPLACE: if there is exactly 1 unbanished, non-target monster and we get the wrong monster
		print("unbanished non-targets during combat: " + unbanishedNonTargets, "blue");
		if (canReplaceMonster() && unbanishedNonTargets == 1) { // if you replace when there is more than 1 unbanished target (even if olfacted), you have a high chance of not getting the target (due to KoL adventure queue)
			rval += visit_url("/fight.php?action=steal", true, false); // pickpocket if able
			use_skill($skill[Macrometeorite]);
			// drop to FIGHT

		// FREE-RUNAWAY
// 		} else if (unbanishedNonTargets > maxNonTargetsUnbanished && item_amount($item[fish-oil smoke bomb]) > 0) {
// 			visit_url("/fight.php?action=steal", true, false); // pickpocket if able
// 			throw_item($item[fish-oil smoke bomb]);
// 			return false;

		// BANISH
		} else {
			PrioritySkillRecord banisher = banishToUse(aLocation, maxPerTurnCost);

			if (banisher.theSkill != $skill[none]) {
				print("RECOMMENDING BANISHER: " + banisher.theSkill, "green");
				rval += visit_url("/fight.php?action=steal", true, false); // pickpocket if able
				use_skill(banisher.theSkill);
				if (banisher.theSkill == $skill[Spring Kick]) // doesn't end combat
				    run_combat(); // or use defaultKill()???
				assert(!inCombat(), "targetMobFightHelper: tried to banish, but we're still in combat");
				return rval;

			// can't replace and can't banish
			} else {
				if (optimal)
					abort("Can't banish OR macro!");
				else
					print("WARNING: Can't banish OR macro!", "orange");
			}
		}

	} else
		print("We should be in combat with a target monster", "green");

	// TARGET MONSTER ONLY: olfact and run custom script
	if (arrayContains(target_monsters, last_monster())) {
		if (target_monsters[0] == last_monster()) {
			// OLFACT
			if (shouldOlfact)
				prefightScript += olfactionScript(last_monster());

			// SKILL TO USE
			if (scriptToUse != "") {
				prefightScript += scriptToUse;
				if (!scriptToUse.ends_with(";"))
					prefightScript += ";";
			}
		}
		// Preserve a setup failure before the default CCS can kill the monster.
		set_property("lastMacroError", "");
		executeScript(prefightScript);
		assert(get_property("lastMacroError") == "",
			"targetMobFightHelper: combat setup failed: " + get_property("lastMacroError"));
		
		// special case if the skill is Use the Force, which drops us into a choice adventure
		if (scriptToUse.contains_text("Use the Force")) {
			rval += visit_url("/main.php", false, false);
			return rval + run_choice(3);
		} else if (choice_follows_fight())
			print("WARNING: choice follows, script used: " + scriptToUse + "!", "red");


	// NON-TARGET MONSTER -- despite possible redirection/banishment, we're in combat with the wrong monster
	} else
		print("WARNING: combat with non-target monster!!!", "orange");

	// FIGHT
	rval += run_combat();
	assert(!inCombat(), "targetMobFightHelper: still in combat after run_combat");

	return rval;
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
	assert(count(target_monsters) > 0, "targeting nobody?? target_monsters has no elements");
	if (!isAutomatingDressup()
		&& !smmConfirm("We're targetting a mob but we have no automated dressup set up, therefore we can't auto-banish... continue?", true))
		abort("targetMob: targetting mob but not automated dressup (user aborted)");

	print("targetMob: going to " + aLocation + " and targeting mob: " + target_monsters[0] + " (" + count(target_monsters) + " total targets) " + kills + " times, optimal: " + optimal + ", maxPerTurnCost: " + maxPerTurnCost, "green");

	string aPage;
	int kStartingKills = kills;
	if (kills == 0) kills = 1; // need 1 to get into the loop, we'll detect kStartingKills and break out below

	// TRACKER FAMILIAR AUTOMATION -- TODO not sure this works as intended -- should be in dressup()???
	// the familiar is set by chooseFamiliar(), called by dressup() below, but we have to set the phylum in targetMob because chooseFamiliar doesn't know anything about the target
	boolean tracking = get_property(kDressupFamiliarSelectorKey).contains_text("[tracker]"); // true if we're tracking with Red-nosed Snapper... or Nosy Nose???
	if (tracking && monsterQueueCopies(target_monsters[0]) < 4) { // we only want to track until we have olfacted the target
		use_familiar($familiar[Red-nosed Snapper]);
		if (snapperGuideMeToPhylum() != target_monsters[0].phylum) {
			print("setting tracker phylum: " + target_monsters[0].phylum, "blue");
			setRedNosedSnapperGuideMe(target_monsters[0].phylum);
		}
	}

	boolean hadGoals = haveGoals(); // if we have goals now and not later, presumably they're completed
	int noActionInARow = 0; // number of "no action" adv in a row we've had -- more than 3 in a row means we're probably on a new type of error page instead

	while (kills > 0) {
		preAdventureChecks(); // need this here so any potential maximize before an adv (esp. combat freq) gets the benefit of our mood -- also useful to stop before redressing if there's a trigger

		 // the max number of non-targets we want unbanished, 1 if we can replace or 0 otherwise
		int maxNonTargetsUnbanished = 0;
		if (canReplaceMonster() || (canFreeRunaway(maxPerTurnCost) && monsterQueueCopies(target_monsters[0]) >= 4))
			maxNonTargetsUnbanished = 1;

		// BANISH equip a banishing item if we're going to banish
		string tweakItem = "";
		if (unbanishedNonTargets(aLocation, target_monsters) > maxNonTargetsUnbanished) {
			PrioritySkillRecord equip_banish = banishToUse(aLocation, maxPerTurnCost);
			if (equip_banish.theSkill == $skill[none])
				print("NO RECOMMENDED BANISHER!!", "orange");
			else
				print("RECOMMENDING BANISHER: " + equip_banish.theSkill, "green");
			if (equip_banish.theItem != $item[none]) {
				print("EQUIPPING: " + equip_banish.theItem, "blue");
				tweakItem = "+equip " + equip_banish.theItem;
			}
		} else if (monsterQueueCopies(target_monsters[0]) < 4) { // if the queue is full of the monster we're after, don't bother with olfacting
			// if we're not going to banish, maybe equip to olfact?
			tweakItem = dressForOlfaction(aLocation, target_monsters[0]);
		}
		dressup(tweakItem, false);
		saveOutfit(kTargetMobSavedEquipSetKey);

		restore_mp(mp_cost($skill[Gallapagosian Mating Call]) + mp_cost(skillToUse));

		int unbanishedNonTargets = unbanishedNonTargets(aLocation, target_monsters);
		print("targetMob: unbanished non-targets before combat: " + unbanishedNonTargets, "blue");
		try {
			boolean chainedFight = false;

			// DIRECT TARGET map the monsters, time-spinner
			if (!tracking
				&& monsterQueueCopies(target_monsters[0]) == 1 //  no extra copies in the queue
				&& unbanishedNonTargets >= 1) {

				if (to_int(get_property("_monstersMapped")) < 3) {
					print("targetMob: mapping (map the monsters) target monster: " + target_monsters[0], "green");
					if (!to_boolean(get_property("mappingMonsters")))
						if (!use_skill(1, $skill[Map the Monsters]))
							abort("tried to cast map the monsters but it didn't work!");
					aPage = advURL(aLocation);
					while (!handling_choice()) { // we didn't get to the map choice
						// probably a wandering monster
						run_combat();
						aPage = advURL(aLocation);
					}
					runMapChoice(aPage, target_monsters[0]);
					chainedFight = true;

				// save time-spinners for hitting high-value Recent Fight
				// } else if (to_int(get_property("_timeSpinnerMinutesUsed")) <= 7) {
				// 	print("targetMob: traveling back in time (time-spinner) to fight target monster: " + target_monsters[0], "green");
				// 	string spinResult = timespinnerFight(target_monsters[0]);
				// 	if (spinResult != "")
				// 		chainedFight = true;

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
				print(aPage, "red");
				abort("error page at adventure location: " + aLocation);
			}

			// DID WE GET TO A CHOICE OR CHAINED CHOICE?
			if (handling_choice() || choice_follows_fight()) {
				run_choice(-1);
				if (kStartingKills == 0)
					return false;
				continue;
			}

			// "NO ACTION" ADVENTURE (?)
			if (!contains_text(aPage, "fight.php")) {
				print("---------------- detected 'no action' adventure -------------------", "orange");
				noActionInARow++;
				if (kStartingKills == 0 || noActionInARow >= 3)
					return false;
				continue;
			} else
				noActionInARow = 0;

			// FIGHT
			boolean shouldOlfact = kStartingKills > 1;
			boolean targetKilled = true;
			if (inCombat()) {
				aPage += targetMobFightHelper(aLocation, target_monsters, skillToUse, maxPerTurnCost, optimal, shouldOlfact);
				targetKilled = isWinPage(aPage);
			} else if (aPage.contains_text("fight.php") && !isBeatenUp()) // presumably we were in combat and killed it or were killed by it already
				targetKilled = arrayContains(target_monsters, last_monster());

			assert(!inCombat(), "targetMob: we should have killed/been killed by the encountered monster at this point");

			// CHOICE FOLLOWS FIGHT
			if (choice_follows_fight()) {
				print("targetMob: choice follows fight!", "blue");
				run_choice(-1);
			}

			if (isWinPage(aPage)) {
				if (kStartingKills == 0)
					return true;
				if (targetKilled)
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

			restoreOutfit(kTargetMobSavedEquipSetKey); // will usually be the same outfit, unless we redirected
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
// Also does not olfact or direct target as targetMob does and requires a script that kills the monster (or an empty script to run the default CCS)
// DOES follow chained non-combats but DOES NOT follow chained combats.
// Uses banishers according to banishToUse().
// scriptToUse is the script to use against monsters in the targetMonsters array -- wandering monsters use the script in the CCS
// Returns the page returned by adventuring.
// if the script passed in doesn't kill the monster, will return true while still in combat (since we know it is a target monster)
// TODO: refactor to amalgamate this with targetMob??: only thing that needs to be done is to allow targetMob take a script to pass to run_combat??????
string adv1TargetingMobs(location aLocation, monster [] targetMonsters, int maxPerTurnCost, boolean shouldOlfact, string scriptToUse) {
	string page;
	print("adv1TargetingMobs: going to " + aLocation + " and targeting mob: " + targetMonsters[0] + " (" + count(targetMonsters) + " total targets), maxPerTurnCost: " + maxPerTurnCost + ", olfact: " + shouldOlfact + ", script: " + scriptToUse, "green");

	assert(my_adventures() > 0, "adv1TargetingMobs: Out of adventures");
	assert(!in_multi_fight(), "adv1TargetingMobs: we're trying to adventure but we're still in combat (multi-fight)");
	assert(!inCombat(), "adv1TargetingMobs: trying to adventure while already in combat");
	assert(!handling_choice(), "adv1TargetingMobs: trying to adventure while in a choice");
	assert(!choice_follows_fight(), "adv1TargetingMobs: trying to adventure while about to be in a choice (choice follows fight)");

	check_counters(kAbortOnCounter);

	int maxNonTargetsUnbanished = 0;
// 	if (have_skill($skill[Macrometeorite]) || item_amount($item[fish-oil smoke bomb]) > 0) maxNonTargetsUnbanished = 1;
	// TODO use the replace skill data
	if (have_skill($skill[Macrometeorite])) maxNonTargetsUnbanished = 1;
	boolean banishingPhylum = (my_familiar() == $familiar[Patriotic Eagle] && "screechCombats".get_property().to_int() == 0 && !"banishedPhyla".get_property().contains_text("Patriotic Screech"));

	// EQUIP BANISH ITEM if we're going to banish
	string tweakItem = "";
	if (unbanishedNonTargets(aLocation, targetMonsters) > maxNonTargetsUnbanished) {
		PrioritySkillRecord equip_banish = banishToUse(aLocation, maxPerTurnCost);
		if (equip_banish.theSkill == $skill[none])
			print("NO RECOMMENDED BANISHER!!", "orange");
		else
			print("RECOMMENDING BANISHER: " + equip_banish.theSkill, "green");
		if (equip_banish.theItem != $item[none]) {
			print("EQUIPPING: " + equip_banish.theItem, "blue");
			tweakItem = "+equip " + equip_banish.theItem;
		}
	} else // if we're not going to banish, maybe equip to olfact?
		tweakItem = dressForOlfaction(aLocation, targetMonsters[0]);

	dressup(tweakItem, false);
	saveOutfit(kRedirectSavedEquipSetKey);

	try {
		page = advURLWithWanderingMonsterRedirect(aLocation);

		// list of "if"s to cover all the different kinds of things that could have happened
		if (isChoicePage(page)) { // choice
			return page  + run_choice(-1);

		// "NO ACTION" adventure -- things like exposition pages -- generally take no adventures, but there will be no chain after it either way(???)
		} else if (!contains_text(page, "fight.php")) {
			return page;

		// WANDERING MONSTER
		} else if (!contains_monster(aLocation, last_monster())) {
			print("wandering monster", "blue");
			page += run_combat(); // uses the DEFAULT CCS

		} else { // COMBAT
			if (inCombat()) {
                page += targetMobFightHelper(aLocation, targetMonsters,  scriptToUse, maxPerTurnCost, true, shouldOlfact);
			} // else: presumably we were in combat and killed it already? it may have killed us
			assert(!inCombat(), "targetMob: we should have killed/been killed by the encountered monster at this point");

			// CHOICE FOLLOWS FIGHT
			if (choice_follows_fight()) {
				run_choice(-1);
			}
		}

        return page;

	} finally {
		// A failed combat must retain its original error. Post-adventure
		// bookkeeping and outfit restoration require combat to be over.
		if (!inCombat()) {
			postAdventure(); // have to run manually, since we're using visit_url

			restoreOutfit(kRedirectSavedEquipSetKey);
			if (my_location() != aLocation) { // restore location after redirection
				set_location(aLocation);
			}
		}
	}
}

void adv1TargetingMob(location aLocation, monster targetMonster, int maxPerTurnCost, boolean shouldOlfact, string scriptToUse) {
	monster [] monsterArray = {targetMonster};
	adv1TargetingMobs(aLocation, monsterArray, maxPerTurnCost, shouldOlfact, scriptToUse);
}



// burn all buffs to maximize meat drop
// TODO: use a cost threshold instead of "useSweetSynthesis"
void buffForMeatDrop(int turnsToBuffFor, boolean useSweetSynthesis) {
	setCurrentMood("meat");

	boolean unused = setBoombox("meat");
	unused = cli_execute("hatter Daylight Shavings Helmet"); // +40 meat
	unused = cli_execute("concert winklered"); // +40 meat
	briefcase_if_needed($effect[A View to Some Meat], turnsToBuffFor);

	newAcquire($item[thin black candle], 3, 288);
	unused = cli_execute("summon meat"); // +100% Meat

	if (my_class() == $class[Pastamancer] && my_thrall() != $thrall[Lasagmbie])
		use_skill($skill[Bind Lasagmbie]);

	if (isAsdonWorkshed())
		fueled_asdonmartin("observantly", turnsToBuffFor);

	if (have_item($item[lodestone]) && !"_lodestoneUsed".get_property().to_boolean())
		use($item[lodestone]);

	if ("_monkeyPawWishesUsed".get_property().to_int() < 4) // save the Monkey Point for olfacting
		cli_execute_if_needed("monkeypaw effect Frosty", $effect[Frosty], turnsToBuffFor);

	// Aug 7
	if (!"_aug7Cast".get_property().to_boolean())
		use_skill($skill[Aug. 7th: Lighthouse Day!]);

	// SPLEEN -- Sweet Synthesis
	if (useSweetSynthesis) {
		int availableSpleen = spleen_limit() - my_spleen_use();
		if (availableSpleen < ceil(turnsToBuffFor / 30.0))
			print("WARNING: wanted to use Sweet Synthesis, but we didn't have enough spleen, will fill as much as we can.", "orange");
		sweetSynthesis($effect[Synthesis: Greed], min(turnsToBuffFor, availableSpleen * 30));
	}
}

void buffForMeatDrop(int turnsToBuffFor) {
	buffForMeatDrop(turnsToBuffFor, false);
}


// TODO: add item-specific equips
string maximizeStringForMeatDrop() {
	string maxString = "meat";
	return maxString;
}


// burn everything to maximize item drop
void maximizeForMeatDrop(int turnsToBuffFor, location aLocation) {
	buffForMeatDrop(turnsToBuffFor);

	string maxString = maximizeStringForMeatDrop();
	maxString = chooseFamiliar("meat", aLocation, $monster[none], maxString);

	clearAutomateDressup();
	maximize(maxString, false);
}



void buffForItemDrop(int turnsToBuffFor, location aLocation, boolean useSweetSynthesis) {
	print("buffForItemDrop: " + turnsToBuffFor + ", use sweet Synthesis: " + useSweetSynthesis, "green");
	if (turnsToBuffFor <= 0) return;

	boolean unused;
	if (vipLoungeAvailable() && !to_boolean(get_property("_clanFortuneBuffUsed"))) cli_execute("fortune buff hagnk"); // +50%
	if (!to_boolean(get_property("_daycareSpa"))) cli_execute("daycare mysticality"); // +25%
	if (to_int(get_property("_poolGames")) < 3) cli_execute("pool 3"); // +10%
	briefcase_if_needed($effect[Items Are Forever], turnsToBuffFor);
	//boolean unused = use_skill(1, $skill[Visit your Favorite Bird]);
	if (!to_boolean(get_property("_favoriteBirdVisited"))) {
		buffIfNeededWithUneffect($skill[Visit your Favorite Bird]);
		buffIfNeededWithUneffect($skill[Seek Out a Bird], turnsToBuffFor);
	}
	if (have_skill($skill[incredible self-esteem]))
		cli_execute("cast incredible self-esteem");

	if ("_monkeyPawWishesUsed".get_property().to_int() < 5)
		cli_execute_if_needed("monkeypaw effect Frosty", $effect[Frosty], min(turnsToBuffFor, (5 - "_monkeyPawWishesUsed".get_property().to_int()) * 30)); // TODO this underestimates the possible if we already have turns of the effect

	if (!"_portableSteamUnitUsed".get_property().to_boolean())
		use($item[portable steam unit]);

	if (my_class() == $class[Pastamancer] && my_thrall() != $thrall[Spice Ghost])
		use_skill($skill[Bind Spice Ghost]);

	int thingfinderCastsAvailable = 10 - to_int(get_property("_thingfinderCasts"));
	if (my_class() == $class[Accordion Thief] && thingfinderCastsAvailable > 0 && my_level() >= 15)
		buffIfNeededWithUneffect($skill[The Ballad of Richie Thingfinder], min(turnsToBuffFor, thingfinderCastsAvailable * 20));

	// FOOD: roasted vegetable of Jarlsberg
	consumeIfNeeded($item[roasted vegetable of Jarlsberg], $effect[Wizard Sight], turnsToBuffFor);

	// Aug 7
	if (!"_aug7Cast".get_property().to_boolean())
		use_skill($skill[Aug. 7th: Lighthouse Day!]);

	// these ones have a cost associated
	if (!to_boolean(get_property("_madTeaParty"))) cli_execute("hatter 28"); // +20%
	if (isAsdonWorkshed())
		safeFueledAsdonMartin($effect[Driving Observantly], turnsToBuffFor);

	// SPLEEN -- Sweet Synthesis
	if (useSweetSynthesis) {
		int availableSpleen = spleen_limit() - my_spleen_use();
		if (availableSpleen < ceil(turnsToBuffFor / 30.0))
			print("WARNING: wanted to use Sweet Synthesis, but we didn't have enough spleen, will fill as much as we can.", "orange");
		sweetSynthesis($effect[Synthesis: Collection], min(turnsToBuffFor, availableSpleen * 30));
	}
}

// wears all the stuff that could help us with drops, not necessarily stuff that just maximizes item drop chance
string maximizeStringForItemDrop() {
	int champagneChargesAvailable = to_int(get_property("garbageChampagneCharge"));
	int otoscopeChargesAvailable = 3 - to_int(get_property("_otoscopeUsed"));
	int cloakChargesAvailable = 10 - to_int(get_property("_vampyreCloakeFormUses"));

	string maxString = "item";
	if (champagneChargesAvailable > 0 || !to_boolean(get_property("_garbageItemChanged"))) {
		maxString += ", +equip broken champagne bottle";
		if (available_amount($item[broken champagne bottle]) == 0 || champagneChargesAvailable == 0)
			cli_execute("tote 2");
	}
	if (otoscopeChargesAvailable > 0) {
		maxString += ", +equip Lil' Doctor&trade; bag";
	}
	if (cloakChargesAvailable > 0) {
		maxString += ", +equip vampyric cloake";
	}

	return maxString;
}


// burn everything to maximize item drop
void maximizeForItemDrop(int turns, location aLocation) {
	buffForItemDrop(turns, aLocation, false);

	string maxString = maximizeStringForItemDrop();
	maxString = chooseFamiliar("item", aLocation, $monster[none], maxString);

	// 	int professorLecturesAvailable = pocketProfessorLecturesAvailable();
	// 	if (professorLecturesAvailable > 0) {
	// 		use_familiar($familiar[Pocket Professor]);
	// 		if (friars_available())
	// 			cli_execute("friars familiar"); // we want this for the pocket professor all the time... professor gives adv for exp
	// 		equip($item[Pocket Professor memory chip]);
	// 		familiarString = "-familiar";
	// 	}

	clearAutomateDressup();
	maximize(maxString, false);
}



string startFreeCombat() {
	assert(freeCombatsAvailable() > 0, "startFreeCombat: no free combats available");
 
	AdventureRecord freeCombat = chooseFreeCombat();
	return getToAdventure(freeCombat);
}

string freeCombatAdventure(string script) {
	string rval = startFreeCombat();
	rval += customScriptWithDefaultKill(script);
	return rval;
}



// might do a free combat, as some sneak skills are only castable in combat
void sneakNextTurn(int maxCost) {
	assert(canSneak(), "sneakNextTurn: no more sneaks available");

	PriorityRecord sneakSkill = chooseSneakSkill(maxCost);

	if (sneakSkill.maximizeString != "")
		maximize(sneakSkill.maximizeString, false);

	if (sneakSkill.customCombatString != "") { // we need to be in combat to cast the skill
		freeCombatAdventure(sneakSkill.customCombatString);
	} else
		cli_execute(sneakSkill.cliExecuteString);
}



void setDefaultAutomationState() {
	clearAutomateDressup();
}
