script "nep";
notify TQuilla;
since r26718;

import <smmAutomation.ash>;

string __nep_version = "0.1";

/**
Grind Neverending Party

"nep help" in the CLI for help

@author Sacha Mallais (TQuilla #2771003)
*/

int kTurnsPerNC = 8;
string kNEPQuestString = "Party Fair";
string kNEPAmpUp = "woots";
string kNEPClearGuests = "partiers";
string kNEPSnack = "food";
string kNEPBooze = "booze";
string kNEPPayTheDJ = "dj";
string kNEPCleanUp = "trash";



void printHelp() {
	print_html("<h2>nep</h2>");
	print_html("<br>Grind Neverending Party (NEP).</br>");
	print_html("<h3>Commands:</h3>");
	print_html("<br/><strong style=\"color:blue;\">party</strong>: get the quest (if needed) and do it");
	print_html("<br/><span style=\"color:blue;\">prep</span>: dress and buff for normal NEP");
	print_html("<br/><span style=\"color:blue;\">prephard</span>: dress and buff for hardcore NEP");
}



// returns the quest we're on, getting the quest if we're not on it already
// returns the empty string iff we've already finished the quest
// NOTE we're locked into normal vs hard the first time we go to the zone
string nepGetQuest(boolean partyHard) {
	string questString = "_questPartyFairQuest".get_property();

	while (questString == "" && "_questPartyFair".get_property() != "finished") {
		if (partyHard)
			equip($item[PARTY HARD T-shirt], $slot[shirt]);
		else
			equip($item[none], $slot[shirt]);

		string pageString = advURLWithWanderingMonsterRedirect($location[The Neverending Party]);
// 		string pageString = advURL($location[The Neverending Party]);
		if (handling_choice()) {
			run_choice(1);

			clear_quest_log_cache();
			print_quest(kNEPQuestString);
			questString = "_questPartyFairQuest".get_property();
		} else // we redirected
			run_turn();
	}

	print_quest(kNEPQuestString);
	return questString;
}



void nepDressup(boolean partyHard) {
	string partyQuest = "_questPartyFairQuest".get_property();

	// BASE OUTFIT
	string selectorString = "item";
	string famSelectorString = "item";
	string additionalString = "-equip pantogram pants, -equip mafia thumb ring, -equip Kramco Sausage-o-Matic&trade;, -equip June Cleaver, -equip Everfull Dart Holster"; // we're assuming we never need more than then 10 free quests to complete the quest (needs the Jurassic Parka)
	if (partyHard)
		additionalString += ", equip PARTY HARD T-shirt";

	// quest-specific tweaks to outfit and choices
	switch (partyQuest) {
	    case "":
		    print("no quest");
			break;

		case kNEPClearGuests:
			if (have_item($item[intimidating chainsaw])) {
				additionalString = maxStringAppend(additionalString, "equip intimidating chainsaw");
			}
			break;

		case kNEPCleanUp:
			// only need 450-500% +item to max out gains
			if (partyHard) {
				selectorString = "meat";
				famSelectorString = "default";
			} else {
				// in normal mode, we will finish early, so lower +item so we get more free turns
				selectorString = "50 meat";
				famSelectorString = "meat";
			}
			break;

		case kNEPSnack:
		case kNEPBooze:
			break;

		case kNEPAmpUp:
			additionalString = maxStringAppend(additionalString, "equip cosmetic football");
			break;

		case kNEPPayTheDJ:
			selectorString = "meat";
			additionalString = maxStringAppend(additionalString, "mox 300 min");
			break;

		default:
			abort("unknown NEP quest");
	}

	automate_dressup($location[The Neverending Party], selectorString, famSelectorString, additionalString);
}


void nepPrep(boolean partyHard) {
	nepGetQuest(partyHard);
	string partyQuest = "_questPartyFairQuest".get_property();

	buffForItemDrop(1, $location[The Neverending Party], true); // do this first for the Hatter buff
	buffForMeatDrop(1, true);

	nepDressup(partyHard);

	// quest-specific tweaks to choices
	switch (partyQuest) {
		case kNEPClearGuests:
// 			set_property("choiceAdventure1324", "4"); // basement
// 			set_property("choiceAdventure1328", "3"); // intimidating chainsaw
			set_property("choiceAdventure1324", "5"); // fight
			break;

		case kNEPCleanUp:
			if (partyHard && last_choice() != 1326) {
				fullAcquire($item[gas can]);
				set_property("choiceAdventure1324", "2"); // kitchen
				set_property("choiceAdventure1326", "5"); // Burn some trash
			} else {
				set_property("choiceAdventure1324", "5"); // fight
			}
			break;

		case kNEPSnack:
			set_property("choiceAdventure1324", "2"); // kitchen
			set_property("choiceAdventure1326", "3"); // talk to geraldine
			break;

		case kNEPBooze:
			set_property("choiceAdventure1324", "3"); // back yard
			set_property("choiceAdventure1327", "3"); // talk to gerald
			break;

		case kNEPAmpUp:
			fullAcquire($item[very small red dress]);
			set_property("choiceAdventure1324", "1"); // upstairs
			set_property("choiceAdventure1325", "5"); // toss red dress on the lamp
			break;

		case kNEPPayTheDJ:
			set_property("choiceAdventure1324", "1"); // upstairs
			set_property("choiceAdventure1325", "4"); // crack the safe
			break;

		default:
			abort("unknown NEP quest");
	}
}



void nepQuestAutomation() {
	boolean partyHard = "_partyHard".get_property().to_boolean();
	string partyQuest = "_questPartyFairQuest".get_property();
	int partyTurn = "_neverendingPartyFreeTurns".get_property().to_int();
	int partyProgress = "_questPartyFairProgress".get_property().to_int();
	string tweakString;

	int neededNEPChoices; // number of choices we need to complete the quest

	switch (partyQuest) {
		case kNEPClearGuests:
			// even with all this crap, it takes many turns
// 			if (have_item($item[intimidating chainsaw]))
// 				tweakString = maxStringAppend(tweakString, "equip intimidating chainsaw");
//
// 			neededNEPChoices = 2;
// 			if (partyTurn >= 2 && partyTurn <= 3) {
// 				fullAcquire($item[jam band bootleg]);
// 				set_property("choiceAdventure1324", "1"); // upstairs
// 				set_property("choiceAdventure1325", "3"); // jam band bootleg
// 				neededNEPChoices = 1;
// 			} else if (partyTurn >= 4 && partyTurn <= 6) {
// 				fullAcquire($item[Purple Beast energy drink]);
// 				set_property("choiceAdventure1324", "3"); // back yard
// 				set_property("choiceAdventure1327", "5"); // Purple Beast energy drink
// 				neededNEPChoices = 0;
// 			} else {
// 				neededNEPChoices = 0;
// 				set_property("choiceAdventure1324", "5"); // fight
// 			}

			break;

		case kNEPCleanUp:
			if (partyHard) { // we want to get the choice ASAP to clear as much as possible
				neededNEPChoices = 2;
			}
			break;

		case kNEPSnack:
		case kNEPBooze:
			// figure out which booze/food
			if (questStage("_questPartyFair") >= 1) {
				int [int] progress_split;
				foreach key, v in get_property("_questPartyFairProgress").split_string(" ") {
					if (v == "") continue;
					progress_split.arrayAppend(v.to_int());
				}
				int amountNeeded = progress_split[0];
				item itemNeeded = progress_split[1].to_item();
				assert(itemNeeded != $item[none], "didn't get the snack/drink to acquire!");

				print("acquiring " + amountNeeded + " " + itemNeeded + "@ " + mall_price(itemNeeded) + " for the Neverending Party");
				assert(fullAcquire(itemNeeded, amountNeeded) >= amountNeeded, "could not acquire " + amountNeeded + " of " + itemNeeded);

				set_property("choiceAdventure1326", "4"); // return the food to Geraldine
				set_property("choiceAdventure1327", "4"); // return the booze to Gerald
			}
			break;

		case kNEPAmpUp:
			neededNEPChoices = 0;
			if (partyTurn >= 2) {
				fullAcquire($item[electronics kit]);
				set_property("choiceAdventure1324", "4"); // basement
				set_property("choiceAdventure1328", "4"); // modify living room lights
			}
			break;

		case kNEPPayTheDJ:
			neededNEPChoices = 0;
			if (partyTurn >= 1) {
				set_property("choiceAdventure1324", "5"); // fight
			}
			break;

		default:
			abort("unknown NEP quest");
	}

	print("want " + neededNEPChoices + " more choices", "green");
	boolean canGetFreeChoice = ((partyTurn + (2 * max(0, neededNEPChoices - 1))) + ("encountersUntilNEPChoice".get_property().to_int())) < 10;
	int futureChoices = neededNEPChoices - (canGetFreeChoice ? 1 : 0);
	if (futureChoices > 0) {
		tweakString = maxStringAppend(tweakString, "equip Jurassic Parka");
		set_property(kSpikolodonNextCombatKey, "true");
	}

	dressup(tweakString);
	setParkaMode("spikolodon"); // dressup is changing the parka mode
}



void grindNeverendingParty() {
	boolean unused;
	string tweakString;
	boolean partyHard = "_partyHard".get_property().to_boolean();
	string partyQuest = "_questPartyFairQuest".get_property();
	string partyQuestStep = "_questPartyFair".get_property();
	int partyTurn = "_neverendingPartyFreeTurns".get_property().to_int();
	int partyProgress = "_questPartyFairProgress".get_property().to_int();

	try {
		while (partyQuestStep != "finished") {
			nepQuestAutomation();

			healIfRequiredWithMPRestore();
// 			unused = adv1($location[The Neverending Party], to_int(get_property("_neverendingPartyFreeTurns")) < 10 ? 0 : 1, "");
			redirectAdventure($location[The Neverending Party], 1);

			partyTurn = "_neverendingPartyFreeTurns".get_property().to_int();
			partyQuestStep = get_property("_questPartyFair");

			if (partyQuest == kNEPClearGuests && partyTurn >= 10)
				break;
		}

	} finally {
		remove_property("choiceAdventure1324");
		remove_property("choiceAdventure1325");
		remove_property("choiceAdventure1326");
		remove_property("choiceAdventure1327");
	}
}



// can we do something with these args?
void verifyArguments(string arguments) {
}


void main(string arguments) {
	print("nep args: " + arguments, "green");
	string [int] argv = split_string(arguments, " ");

	// HELP AND VERSION
	if (count(argv) == 1 && argv[0] == "version") {
		print("nep v" + __nep_version);
		return;
	} else if (count(argv) == 1 && argv[0] == "help") {
		printHelp();
		return;
	}

	verifyArguments(arguments);

	// ALREADY DONE
	string partyQuest = "_questPartyFair".get_property();
	if (get_property("_questPartyFair") == "finished") {
		print("Neverending Party is over! Exiting...", "green");
		return;
	}

	// PREP COMMANDS
	if (count(argv) == 1 && argv[0] == "dressup") {
		nepDressup(false);
		return;
	} else if (count(argv) == 1 && argv[0] == "dressuphard") {
		nepDressup(true);
		return;
	} else if (count(argv) == 1 && argv[0] == "quest") {
		nepGetQuest(false);
		return;
	} else if (count(argv) == 1 && argv[0] == "questhard") {
		nepGetQuest(true);
		return;
	} else if (count(argv) == 1 && argv[0] == "prep") {
		nepPrep(false);
		return;
	} else if (count(argv) == 1 && argv[0] == "prephard") {
		nepPrep(true);
		return;
	}

	// PARTY DOWN -- will accept the normal quest if we haven't already gotten the hard version with "nep prephard"
	if (count(argv) == 1 && argv[0] == "party") {
		cli_execute("prefref party");

		nepPrep("_partyHard".get_property().to_boolean()); // defaults to false if we haven't gotten the quest
		grindNeverendingParty();
	}
}
