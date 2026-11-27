script "fr";
notify TQuilla;
since r26718;

import <smmAutomation.ash>;
import <smmFantasyTargets.ash>

string __fr_version = "0.1";

/**
Grind FantasyRealms.

"fr help" in the CLI for help

@author Sacha Mallais (TQuilla #2771003)
*/


item gTargetItem;

void printHelp() {
	print_html("<h2>fr</h2>");
	print_html("<br>Grind FantasyRealms.</br>");
	print_html("<br>quest -- start the FantasyRealm and get the G.E.M. and one of the Warrior/Mage/Rogue hat</br>");
	print_html("<br>dressup -- wear the FantasyRealm G.E.M. and stow the familiar</br>");
	print_html("<br><i>item</i></br> -- grind FR until we get the item");
	print_html("<br>items -- list available items</br>");
	print_html("<br>choose -- show which reward is closest to Museum #1; does nothing in the game</br>");
	print_html("<br>best -- grind that reward (set smm.frTarget to name one yourself)</br>");
}



// return true if stats are ok for FR adventures
boolean frVerifyStats() {
	if (my_buffedstat($stat[muscle]) > 100) return false;
	if (my_buffedstat($stat[mysticality]) > 100) return false;
	if (my_buffedstat($stat[moxie]) > 100) return false;
	return true;
}



void getFantasyrealmQuest() {
	int warriorHelm = available_amount($item[FantasyRealm Warrior's Helm]);
	int mageHat = available_amount($item[FantasyRealm Mage's Hat]);
	int rogueMask = available_amount($item[FantasyRealm Rogue's Mask]);
	int choiceWithTheLeast = 0;
	if (warriorHelm < mageHat) {
		if (rogueMask < warriorHelm)
			choiceWithTheLeast = 3;
		else
			choiceWithTheLeast = 1;
	} else {
		if (mageHat < rogueMask)
			choiceWithTheLeast = 2;
		else
			choiceWithTheLeast = 3;
	}
	buffer page = visit_url("/place.php?whichplace=realm_fantasy&action=fr_initcenter", true, false);
	run_choice(choiceWithTheLeast);
}



void dressForFRZone(location frloc) {
	string maxString;

// 		if (monstersKilled[$monster[Cursed Villager]] >= 5) return; // TODO figure out how to detect if we've done the monsters AND the choice at the end

	switch (frloc) {
		case $location[The Cursed Village]: // cursed villager
		case $location[The Cursed Village Thieves' Guild]:
			assert(fullAcquire($item[spectre scepter], 2) >= 2, "didn't get 2 spectre scepters"); // required for strat
			maxString = "-ml, equip double-ice box, equip fantasyrealm g. e. m., equip LyleCo premium monocle, equip LyleCo premium magnifying glass, -equip Kramco Sausage-o-Matic&trade;";
			automate_dressup(frloc, "mainstat", "none", maxString);
			break;

		case $location[The Sprawling Cemetery]: // spooky ghost
			maxString = "-ml, equip fantasyrealm g. e. m., equip LyleCo premium monocle, equip LyleCo premium magnifying glass, -equip Kramco Sausage-o-Matic&trade;";
			automate_dressup(frloc, "50 spooky res", "none", maxString);
			break;

		case $location[The Mystic Wood]: // fantasy forest faerie
		case $location[The Towering Mountains]: // fantasy ourk
		case $location[The Bandit Crossroads]: // fantasy bandit
			maxString = "-ml, equip fantasyrealm g. e. m., equip LyleCo premium monocle, equip LyleCo premium magnifying glass, -equip Kramco Sausage-o-Matic&trade;";
			automate_dressup(frloc, "mainstat", "none", maxString);
			restore_mp(min(my_maxmp(), mp_cost($skill[Saucestorm]) * 10 + mp_cost($skill[Cannelloni Cocoon]) * 5));
			break;

		case $location[The Putrid Swamp]: // swamp monster
			maxString = "-ml, stench res, equip fantasyrealm g. e. m., equip LyleCo premium monocle, equip LyleCo premium magnifying glass, -equip Kramco Sausage-o-Matic&trade;";
			automate_dressup(frloc, "mainstat", "none", maxString);
			restore_mp(min(my_maxmp(), mp_cost($skill[Saucestorm]) * 10 + mp_cost($skill[Cannelloni Cocoon]) * 5));
			break;

		case $location[The Troll Fortress]: // swamp troll
			automate_dressup($location[the troll fortress], "hp regen", "none", "-ml, +equip fantasyrealm g. e. m., +equip LyleCo premium monocle, +equip LyleCo premium magnifying glass, -equip Kramco Sausage-o-Matic&trade;");
			break;

		case $location[The Faerie Cyrkle]: // quadfaerie
			maxString = "-ml, 10 all res, equip LyleCo premium magnifying glass, equip fantasyrealm g. e. m., equip LyleCo premium monocle, -equip Kramco Sausage-o-Matic&trade;";
			if (my_basestat($stat[muscle]) >= 175)
				maxString += ", equip cup of infinite pencils, equip mafia thumb ring";
			else if (my_basestat($stat[muscle]) >= 27)
				maxString += ", equip hippy protest button, equip ancient stone head";
			else
				maxString += ", equip hippy protest button";
			automate_dressup (frloc, "mus", "none", maxString);
			break;

		case $location[The Foreboding Cave]: // rubber bat
			automate_dressup($location[The Foreboding Cave], "mainstat", "none", "-ml, equip fantasyrealm g. e. m., equip LyleCo premium monocle, equip LyleCo premium magnifying glass, -equip Kramco Sausage-o-Matic&trade;");
			break;

		case $location[The Druidic Campsite]: // druid plants
			automate_dressup($location[The Druidic Campsite], "mainstat", "none", "-ml, equip bezoar ring, equip fantasyrealm g. e. m., equip LyleCo premium monocle, equip LyleCo premium magnifying glass, -equip Kramco Sausage-o-Matic&trade;");
			break;

		case $location[The Barrow Mounds]: // barrow wraith? [sic]
			automate_dressup($location[The Barrow Mounds], "init", "none", "-ml, equip fantasyrealm g. e. m., equip LyleCo premium monocle, equip LyleCo premium magnifying glass, -equip Kramco Sausage-o-Matic&trade;, equip combat lover's locket");
			break;

		case $location[Near the Witch's House]: // flock of every birds
			automate_dressup($location[Near the Witch's House], "spell dmg", "", "-ml, mys, spell dmg percent, +equip fantasyrealm g. e. m., +equip LyleCo premium monocle, +equip LyleCo premium magnifying glass, -equip Kramco Sausage-o-Matic&trade;");
			break;

		case $location[The Old Rubee Mine]:
			automate_dressup($location[The Old Rubee Mine], "dr", "none", "-ml, +equip fantasyrealm g. e. m., +equip LyleCo premium monocle, +equip LyleCo premium magnifying glass, +equip lucky gold ring, -equip Kramco Sausage-o-Matic&trade;");
			break;

		case $location[The Evil Cathedral]:
			string maxString = "+equip fantasyrealm g. e. m., +equip LyleCo premium monocle, +equip LyleCo premium magnifying glass";
			if (my_basestat($stat[muscle]) >= 175) maxString += ", +equip cup of infinite pencils";
			else if (my_basestat($stat[mysticality]) >= 20) maxString += ", +equip double-ice box";
			if (my_basestat($stat[mysticality]) >= 65) maxString += ", +equip hippy protest button";
			automate_dressup($location[The Evil Cathedral], "mainstat", "none", maxString);
			break;

		case $location[The Labyrinthine Crypt]:
			automate_dressup($location[The Labyrinthine Crypt], "", "none", "-ml, -10 hp, -mus, mp regen, +equip fantasyrealm g. e. m., +equip LyleCo premium monocle, +equip LyleCo premium magnifying glass");
			break;

		case $location[The Ley Nexus]:
			use_skill($skill[Quiet Judgement]);
			use_skill($skill[The Magical Mojomuscular Melody]);
			use_skill($skill[Stevedave's Shanty of Superiority]);
			clearAutomateDressup();
			maximize("10 mys, elemental dmg, effective, +equip fantasyrealm g. e. m.", false);
			if (my_buffedstat($stat[mysticality]) < 500) cli_execute("telescope look high");
			if (my_buffedstat($stat[mysticality]) < 500) cli_execute("monorail buff");
			if (!maximize("-ml, mys 500 min, elemental dmg, effective, +equip fantasyrealm g. e. m.", false)) abort("unable to get 500 mys");
			healIfRequiredWithMPRestore();
			burnMP(0);
			break;

		case $location[The Master Thief's Chalet]:
			automate_dressup($location[The Master Thief's Chalet], "sleaze res 5 min", "none", "-ml, +equip fantasyrealm g. e. m., +equip LyleCo premium monocle, +equip LyleCo premium magnifying glass, -equip Kramco Sausage-o-Matic&trade;");
			healIfRequiredWithMPRestore();
			restore_mp(50);
			break;

		case $location[The Ogre Chieftain's Keep]:
			use_skill($skill[Quiet Determination]);
			use_skill($skill[The Power Ballad of the Arrowsmith]);
			use_skill($skill[Stevedave's Shanty of Superiority]);
			clearAutomateDressup();
			maximize("100 mus, effective, +equip fantasyrealm g. e. m.", false);
			maximize("100 mus, effective, +equip fantasyrealm g. e. m.", false); // first run doesn't get everything for some reason
			if (my_buffedstat($stat[muscle]) < 500) cli_execute("telescope look high");
			if (my_buffedstat($stat[muscle]) < 500) cli_execute("monorail buff");
			if (my_buffedstat($stat[muscle]) < 500) abort("unable to get 500 mus");
			healIfRequiredWithMPRestore();
			break;

		case $location[The Lair of the Phoenix]:
			clearAutomateDressup();
			maximize("100 mox, effective, +equip fantasyrealm g. e. m.", false);
			maximize("100 mox, effective, +equip fantasyrealm g. e. m.", false);
			if (my_buffedstat($stat[moxie]) < 500) buffIfNeededWithUneffect($skill[The Moxious Madrigal]);
			if (my_buffedstat($stat[moxie]) < 500) buffIfNeededWithUneffect($skill[Stevedave's Shanty of Superiority]);
			if (my_buffedstat($stat[moxie]) < 500) cli_execute("telescope look high");
			if (my_buffedstat($stat[moxie]) < 500) cli_execute("monorail buff");
			if (my_buffedstat($stat[moxie]) < 500) abort("unable to get 500 mox");
			healIfRequiredWithMPRestore();
			break;

		case $location[The Dragon's Moor]:
			automate_dressup($location[The Dragon's Moor], "mainstat", "none", "-ml, +equip dragon slaying sword, +equip fantasyrealm g. e. m., +equip lucky gold ring, -equip Kramco Sausage-o-Matic&trade;");
			break;

		case $location[The Spider Queen's Lair]:
			setCurrentMood("mox");
			clearAutomateDressup();
			maximize("100 mox, effective, +equip fantasyrealm g. e. m.", false);
			maximize("100 mox, effective, +equip fantasyrealm g. e. m.", false);
			// 		if (my_buffedstat($stat[moxie]) < 500) buffIfNeededWithUneffect($skill[The Moxious Madrigal]);
			// 		if (my_buffedstat($stat[moxie]) < 500) buffIfNeededWithUneffect($skill[Quiet Desperation]);
			// 		if (my_buffedstat($stat[moxie]) < 500) buffIfNeededWithUneffect($skill[Stevedave's Shanty of Superiority]);
			if (my_buffedstat($stat[moxie]) < 500) cli_execute("telescope look high");
			if (my_buffedstat($stat[moxie]) < 500) cli_execute("monorail buff");
			if (my_buffedstat($stat[moxie]) < 500) abort("unable to get 500 mox");
			healIfRequiredWithMPRestore();
			break;

		default:
			abort("unknown zone: " + frloc);
	}
}



// grind all of the given Fantasy Realm zone with the current outfit and state
// also dresses for and selects the final choice of the zone if endChoice is > 0
void grindFRZone(location frloc, int endChoice, string wearForChoice) {
	int [monster] monstersKilled = parseFantasyRealmMonstersKilled();
	monster zonemon = zoneMonster(frloc);
	boolean bossZone = zonemon == $monster[none];
	int advToDo = 5 - monstersKilled[zonemon];

	if (bossZone) {
		print("going to " + frloc + " to kill a boss", "green");
		advToDo = 1;
	} else
		print("going to " + frloc + " to kill " + advToDo + " " + zonemon, "green");

	// ADVENTURE
	int tries = advToDo + 3;
	while (advToDo > 0 && tries > 0) {
		healToMaxWithMPRestore();
		restore_mp(20);
		advURL(frloc);

		if (handling_choice()) // might get a choice sooner than we expect if we're in a boss zone
			break;
		assert(inCombat(), "grindFRZone: " + frloc + ", expecting " + advToDo + " more combats but we didn't get into combat, something's wrong");
		run_combat();
		postAdventure();

		monstersKilled = parseFantasyRealmMonstersKilled();
		advToDo = 5 - monstersKilled[zonemon];
		tries--;
	}
	assert(bossZone || monstersKilled[zonemon] >= 5, "wasn't able to kill all 5 " + zonemon + " in " + frloc);
	assert(!inCombat(), "we finished grinding in " + frloc + " but we're in combat");

	// FINAL CHOICE
	if (endChoice > 0) {
		print("going to " + frloc + " to submit choice " + endChoice + " with " + wearForChoice, "blue");

		if (wearForChoice != "") {
			// we might be already handling a choice if we're in a boss zone
			if (handling_choice()) {
				run_last_choice_option(); // get out of the choice so we can dressup
				postAdventure();
			}
			maximize("-tiebreaker, equip FantasyRealm G.E.M., " + wearForChoice, false);
		}

		assert(my_adventures() >= 1, "not enough adventures to finish " + frloc);
		if (!handling_choice()) // we might handling a choice if we're in a boss zone and we didn't need to dressup
			advURL(frloc);

		if (handling_choice()) { // we might have already done the final choice, which i have no way to detect
			run_choice(endChoice);
			postAdventure();
		} else
			print("WARNING: wanted to do the end choice at " + frloc + " but we didn't get to a choice adventure! Note that we could have already done it.", "orange");
	}

	assert(!handling_choice() && !inCombat(), "something wrong while adventuring in " + frloc);
}


void grindFRZone(location frloc, int endChoice) {
	grindFRZone(frloc, endChoice, "");
}



// dresses for and then adventures in the given location
// NOTE: we're not wearing the kramco because wandering monsters don't appear -- also, can't copy into these zones
void grindFRZoneWithDressup(location frloc, int endChoice, string wearForChoice) {
	dressForFRZone(frloc);
	grindFRZone(frloc, endChoice, wearForChoice);
}

void grindFRZoneWithDressup(location frloc, int endChoice) {
	grindFRZoneWithDressup(frloc, endChoice, "");
}



// DEPRECATED: old way of starting FR
void fantasyrealmBaseGrind() {
	print("fantasyrealmBaseGrind", "green");
	int advToDo;
	int tries;
	int [monster] monstersKilled = parseFantasyRealmMonstersKilled();

	// if the last one's done, we're done
	if (monstersKilled[$monster[Swamp monster]] >= 5)
		return;

	getFantasyrealmQuest();

	clearGoals();
	change_mcd(0);
	if (my_mp() > 200) {
		setDefaultMood();
		burnMP(-200);
	}
	setNoMood(); // don't spend mana, need it all

	// NOTE: we're not wearing the kramco because wandering monsters don't appear -- also, can't copy into these zones

	if (monstersKilled[$monster[Cursed villager]] < 5) {
		assert(fullAcquire($item[spectre scepter], 2) >= 2, "didn't get 2 spectre scepters"); // required for strat
		string maxString = "-ml, equip double-ice box, equip fantasyrealm g. e. m., equip LyleCo premium monocle, equip LyleCo premium magnifying glass, -equip Kramco Sausage-o-Matic&trade;";
		automate_dressup($location[the cursed village], "mainstat", "none", maxString);
		grindFRZone($location[the cursed village], 0);
	}

	if (monstersKilled[$monster[Spooky ghost]] < 5) {
		automate_dressup($location[The Sprawling Cemetery], "50 spooky res", "none", "-ml, equip fantasyrealm g. e. m., equip LyleCo premium monocle, equip LyleCo premium magnifying glass, -equip Kramco Sausage-o-Matic&trade;");
		grindFRZone($location[The Sprawling Cemetery], 0);
	}

	if (monstersKilled[$monster[Fantasy forest faerie]] < 5 || monstersKilled[$monster[Fantasy ourk]] < 5
	    || monstersKilled[$monster[Fantasy bandit]] < 5 || monstersKilled[$monster[Swamp monster]] < 5) {
		automate_dressup($location[none], "mainstat", "none", "-ml, equip fantasyrealm g. e. m., equip LyleCo premium monocle, equip LyleCo premium magnifying glass, -equip Kramco Sausage-o-Matic&trade;");

		restore_mp(min(my_maxmp(), mp_cost($skill[Saucestorm]) * 10 + mp_cost($skill[Cannelloni Cocoon]) * 5));
		grindFRZone($location[The Mystic Wood], 0);
		grindFRZone($location[The Towering Mountains], 0);
		grindFRZone($location[The Bandit Crossroads], 0);
		grindFRZone($location[The Putrid Swamp], 0);
	}
}



// given a target item from FantasyRealm, grinds the necessary adventures to get it
// note that wandering monsters cannot appear in these zones
// #grindFantasyRealm #fantasy realm #fr
void fantasyrealmGrind(item targetItem) {
	print("fantasyrealmGrind, target item: " + targetItem, "green");

	if (my_session_items(targetItem) > 0 || get_property("_fantasyRealmDone").to_boolean()) {
		print("Already got it!", "green");
		return;
	}

	string pageText;
	int advToDo;
	int [monster] monstersKilled = parseFantasyRealmMonstersKilled();

	getFantasyrealmQuest();
	clearGoals();
	change_mcd(0);
	if (my_mp() > 200) {
		setDefaultMood();
		burnMP(-200);
	}
	setNoMood(); // don't spend mana, need it all

	if (my_adventures() < 30 && !user_confirm("adventure in FantasyRealm with less than 30 adv?", 60000, true))
		abort("user aborted");

	string maxString;

	switch (targetItem) {
		case $item[sachet of strange powder]: // 2 hours
			frEnsureHoursNeeded(string [] {"The Towering Mountains", "The Foreboding Cave"});
			frEnsureTurnsNeeded(string [] {"The Towering Mountains", "The Foreboding Cave"});

			grindFRZoneWithDressup($location[The Towering Mountains], 2);
			grindFRZoneWithDressup($location[The Foreboding Cave], 2);
			break;

		case $item[druidic s'more]: // 2 hours
			frEnsureHoursNeeded(string [] {"The Mystic Wood", "The Druidic Campsite"});
			frEnsureTurnsNeeded(string [] {"The Mystic Wood", "The Druidic Campsite"});

			grindFRZoneWithDressup($location[The Mystic Wood], 2);
			grindFRZoneWithDressup($location[The Druidic Campsite], 1);
			break;

		case $item[mourning wine]: // 2 hours
			frEnsureHoursNeeded(string [] {"The Sprawling Cemetery", "The Barrow Mounds"});
			frEnsureTurnsNeeded(string [] {"The Sprawling Cemetery", "The Barrow Mounds"});

			grindFRZoneWithDressup($location[The Sprawling Cemetery], 2);
			grindFRZoneWithDressup($location[The Barrow Mounds], 2);
			break;

		case $item[denastified haunch]: // 4 hours
			frEnsureHoursNeeded(string [] {"The Troll Fortress", "The Mystic Wood", "The Faerie Cyrkle", "The Putrid Swamp"});
			frEnsureTurnsNeeded(string [] {"The Troll Fortress", "The Mystic Wood", "The Faerie Cyrkle", "The Putrid Swamp"});

			fullAcquire($item[FantasyRealm Key]);
			grindFRZoneWithDressup($location[The Putrid Swamp], 2);
			grindFRZone($location[The Troll Fortress], 2); // don't need to redress for this
			grindFRZoneWithDressup($location[The Mystic Wood], 1);
			grindFRZoneWithDressup($location[The Faerie Cyrkle], 2);

			museumSafeCreate(1, $item[denastified haunch]);
			set_property("_fantasyRealmDone", "true");
			break;

		case $item[bad rum and good cola]: // 4 hours
			frEnsureHoursNeeded(string [] {"The Towering Mountains", "The Old Rubee Mine", "The Cursed Village", "The Evil Cathedral"});
			frEnsureTurnsNeeded(string [] {"The Towering Mountains", "The Old Rubee Mine", "The Cursed Village", "The Evil Cathedral"});

			assert(false, "double check the choice selections");
			fullAcquire($item[FantasyRealm Key]);
			grindFRZoneWithDressup($location[The Towering Mountains], 1);
			grindFRZoneWithDressup($location[The Old Rubee Mine], 3);
			grindFRZoneWithDressup($location[The Cursed Village], 1); // The Evil Cathedral
			grindFRZoneWithDressup($location[The Evil Cathedral], 3);

			museumSafeCreate(1, $item[bad rum and good cola]);
			set_property("_fantasyRealmDone", "true");
			break;

		case $item[Potion of Heroism]: // 4 hours
			frEnsureHoursNeeded(string [] {"The Sprawling Cemetery", "The Labyrinthine Crypt", "Putrid Swamp", "Near the Witch's House"});
			frEnsureTurnsNeeded(string [] {"The Sprawling Cemetery", "The Labyrinthine Crypt", "Putrid Swamp", "Near the Witch's House"});

			assert(false, "double check the choice selections");
			fullAcquire($item[FantasyRealm Key]);
			grindFRZoneWithDressup($location[The Sprawling Cemetery], 1); // Labyrinthine Crypt
			grindFRZoneWithDressup($location[The Labyrinthine Crypt], 1); // hero's skull
			grindFRZoneWithDressup($location[The Putrid Swamp], 1); // Near the Witch's House
			grindFRZoneWithDressup($location[Near the Witch's House], 3); // to-go brew

			museumSafeCreate(1, $item[Potion of Heroism]);
			set_property("_fantasyRealmDone", "true");
			break;

		case $item[Rubee&trade;]: // 4 hours
			frEnsureHoursNeeded(string [] {"The Sprawling Cemetery", "The Cursed Village", "The Towering Mountains", "The Foreboding Cave"});
			frEnsureTurnsNeeded(string [] {"The Sprawling Cemetery", "The Cursed Village", "The Towering Mountains", "The Foreboding Cave"});

			fullAcquire($item[FantasyRealm Key]);
			grindFRZoneWithDressup($location[The Sprawling Cemetery], 4); // 40-60 Rubees
			grindFRZoneWithDressup($location[The Cursed Village], 5); // 40-60 Rubees
			grindFRZoneWithDressup($location[The Towering Mountains], 2); // The Foreboding Cave
			grindFRZoneWithDressup($location[The Foreboding Cave], 2); // 90-110 Rubees

			set_property("_fantasyRealmDone", "true");
			break;

		case $item[the Archwizard's briefs]: // 5 hours
			frEnsureHoursNeeded(string [] {"The Mystic Wood", "The Druidic Campsite", "The Towering Mountains", "The Cursed Village", "The Archwizard's Tower"});
			frEnsureTurnsNeeded(string [] {"The Mystic Wood", "The Druidic Campsite", "The Towering Mountains", "The Cursed Village", "The Archwizard's Tower"});

			grindFRZoneWithDressup($location[The Mystic Wood], 2);
			grindFRZoneWithDressup($location[The Druidic Campsite], 3);
			grindFRZoneWithDressup($location[The Towering Mountains], 4);
			grindFRZoneWithDressup($location[The Cursed Village], 3);

			automate_dressup($location[The Archwizard's Tower], "cold res 5 min", "none", "-ml, equip charged druidic orb, equip fantasyrealm g. e. m., -equip Kramco Sausage-o-Matic&trade;");
			grindFRZone($location[The Archwizard's Tower], 1);

			set_property("_fantasyRealmDone", "true");
			break;

		case $item[Duke Vampire's regal cloak]: // 5 hours
			frEnsureHoursNeeded(string [] {"The Mystic Wood", "The Putrid Swamp", "Near the Witch's House", "The Sprawling Cemetery", "Duke Vampire's Chateau"});
			frEnsureTurnsNeeded(string [] {"The Mystic Wood", "The Putrid Swamp", "Near the Witch's House", "The Sprawling Cemetery", "Duke Vampire's Chateau"});

			grindFRZoneWithDressup($location[The Mystic Wood], 5);
			grindFRZoneWithDressup($location[The Putrid Swamp], 1);
			grindFRZoneWithDressup($location[Near the Witch's House], 2);
			grindFRZoneWithDressup($location[The Sprawling Cemetery], 3, "equip FantasyRealm Rogue's Mask");

			automate_dressup($location[Duke Vampire's Chateau], "10 init", "none", "-ml, +equip fantasyrealm g. e. m., +equip LyleCo premium monocle, +equip LyleCo premium magnifying glass, -equip Kramco Sausage-o-Matic&trade;");
			grindFRZone($location[Duke Vampire's Chateau], 1);

			set_property("_fantasyRealmDone", "true");
			break;

		case $item[The Ghoul King's ghoulottes]: // 5 hours
			grindFRZoneWithDressup($location[The Mystic Wood], 1);
			grindFRZoneWithDressup($location[The Faerie Cyrkle], 1);
			grindFRZoneWithDressup($location[The Sprawling Cemetery], 2);
			grindFRZoneWithDressup($location[The Barrow Mounds], 3, "equip FantasyRealm Warrior's Helm");

			automate_dressup($location[The Ghoul King's Catacomb], "-ml, spooky res 5 min", "none", "hot dmg, +equip fantasyrealm g. e. m., +equip LyleCo premium monocle, +equip LyleCo premium magnifying glass, -equip Kramco Sausage-o-Matic&trade;");
			grindFRZone($location[The Ghoul King's Catacomb], 1);

			set_property("_fantasyRealmDone", "true");
			break;

		case $item[the Ley Incursion's waist]: // 5 hours
			fullAcquire($item[FantasyRealm key]);
			grindFRZoneWithDressup($location[The Sprawling Cemetery], 5, "equip FantasyRealm Mage's Hat");
			grindFRZoneWithDressup($location[The Putrid Swamp], 2);
			grindFRZoneWithDressup($location[The Troll Fortress], 3);
			grindFRZoneWithDressup($location[The Mystic Wood], 3);
			grindFRZoneWithDressup($location[The Ley Nexus], 1);

			set_property("_fantasyRealmDone", "true");
			break;

		case $item[Master Thief's utility belt]: // 5 hours
			grindFRZoneWithDressup($location[The Sprawling Cemetery], 1); // Labyrinthine Crypt
			grindFRZoneWithDressup($location[The Labyrinthine Crypt], 3, "equip FantasyRealm Rogue's Mask"); // arrest warrant
			grindFRZoneWithDressup($location[The Cursed Village], 7); // notarized arrest warrant
			grindFRZoneWithDressup($location[The Towering Mountains], 3); // The Master Thief's Chalet
			grindFRZoneWithDressup($location[The Master Thief's Chalet], 1);

			set_property("_fantasyRealmDone", "true");
			break;

		case $item[belt of Ogrekind]: // 5 hours
			grindFRZoneWithDressup($location[The Putrid Swamp], 5); // nasty marshmallow
			grindFRZoneWithDressup($location[The Mystic Wood], 2); // The Druidic Campsite
			grindFRZoneWithDressup($location[The Druidic Campsite], 2); // poisoned s'more
			grindFRZoneWithDressup($location[The Towering Mountains], 5, "equip FantasyRealm Warrior's Helm"); // The Ogre Chieftain's Keep
			grindFRZoneWithDressup($location[The Ogre Chieftain's Keep], 1);
// 			executeScript("use divine noisemaker, divine noisemaker");

			set_property("_fantasyRealmDone", "true");
			break;

		case $item[nozzle of the Phoenix]: // 5 hours
			grindFRZoneWithDressup($location[The Cursed Village], 1); // The Evil Cathedral
			grindFRZoneWithDressup($location[The Evil Cathedral], 4, "equip FantasyRealm Mage's Hat"); // holy water
			grindFRZoneWithDressup($location[The Towering Mountains], 2); // The Foreboding Cave
			grindFRZoneWithDressup($location[The Foreboding Cave], 3, "equip FantasyRealm Mage's Hat"); // 90-110 Rubees
			grindFRZoneWithDressup($location[The Lair of the Phoenix], 1);

			set_property("_fantasyRealmDone", "true");
			break;

		case $item[Dragonscale breastplate]: // 5 hours
			fullAcquire($item[FantasyRealm Key]);
			grindFRZoneWithDressup($location[The Towering Mountains], 1); // The Old Rubee Mine
			grindFRZoneWithDressup($location[The Old Rubee Mine], 2);
			grindFRZoneWithDressup($location[The Cursed Village], 6);
			grindFRZoneWithDressup($location[The Putrid Swamp], 3, "equip FantasyRealm Warrior's Helm");
			grindFRZoneWithDressup($location[The Dragon's Moor], 1);

			set_property("_fantasyRealmDone", "true");
			break;

		case $item[leggings of the Spider Queen]: // 5 hours
			grindFRZoneWithDressup($location[The Cursed Village], 2, "equip FantasyRealm Rogue's Mask");
			grindFRZoneWithDressup($location[The Cursed Village Thieves' Guild], 2);
			grindFRZoneWithDressup($location[The Mystic Wood], 1);
			grindFRZoneWithDressup($location[The Faerie Cyrkle], 3, "equip FantasyRealm Rogue's Mask");

			museumSafeUse(1, $item[universal antivenin]);
			assert(have_effect($effect[Fantastic Immunity]) > 0, "didn't get the universal antivenin");
			grindFRZoneWithDressup($location[The Spider Queen's Lair], 1);

			set_property("_fantasyRealmDone", "true");
			break;

		case $item[shield of the Skeleton Lord]: // 5 hours
		case $item[ring of the Skeleton Lord]: // 5 hours
		case $item[scepter of the Skeleton Lord]: // 5 hours
			string dressupString;
			if (targetItem == $item[shield of the Skeleton Lord]) dressupString = "outfit FantasyRealm Warrior's Outfit";
			if (targetItem == $item[ring of the Skeleton Lord]) dressupString = "outfit FantasyRealm Wizard's Outfit";
			if (targetItem == $item[scepter of the Skeleton Lord]) dressupString = "outfit FantasyRealm Thief's Outfit";
			automate_dressup($location[none], "", "none", dressupString);

			grindFRZoneWithDressup($location[The Towering Mountains], 10, dressupString);
			grindFRZoneWithDressup($location[The Mystic Wood], 10, dressupString);
			grindFRZoneWithDressup($location[The Putrid Swamp], 10, dressupString);
			grindFRZoneWithDressup($location[The Cursed Village], 10, dressupString);
			grindFRZone($location[The Sprawling Cemetery], 10, dressupString);

			set_property("_fantasyRealmDone", "true");
			break;

		default:
			abort("unknown item");
	}

	setDefaultMood();
}



// can we do something with these args?
void verifyArguments(string arguments) {
	string [int] argv = split_string(arguments, " ");
	gTargetItem = arguments.to_item();

    if (count(argv) == 1 && argv[0] != "version" && argv[0] != "help"
        && argv[0] != "items"
        && argv[0] != "choose"
        && argv[0] != "best"
        && argv[0] != "quest"
        && gTargetItem == $item[none])
        abort("fr: invalid argument");
}


void main(string arguments) {
	print("fr args: " + arguments, "green");

	verifyArguments(arguments);

	string [int] argv = split_string(arguments, " ");
    switch (argv[0]) {
        case "quest":
            getFantasyrealmQuest();
            break;
        case "dressup":
       		automate_dressup($location[PirateRealm Island], "item", "none", "equip FantasyRealm G.E.M.");
            break;
        case "version":
            print("fr v" + __fr_version);
            break;
        case "help":
            printHelp();
            break;
        case "choose":
            frChooseTarget(true);
            break;
        case "best":
            fantasyrealmGrind(frTodaysTarget());
            break;

        default:
        	if (gTargetItem != $item[none])
				fantasyrealmGrind(gTargetItem);
			else
				abort("fr: should never get here");
    }
}
