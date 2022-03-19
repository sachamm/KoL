import <smmUtils.ash>
import <smmAutomation.ash>
import "VotingBooth.ash";
string __unrestricted_version = "0.9";

/*
A collection of functions for use in aftercore or in an unrestricted run.

To use the functions in this ASH script in another ASH script, add this to your script:
import "smmUnrestricted.ash";

To use the functions in this ASH script from your command line, do this in the gCLI:
using smmUnrestricted.ash;

This will add all the functions in smmUnrestricted.ash AND all it's imports to your command line name space.
You can then call any function in this file from the command line. For example:

tm (The Haunted Bathroom, claw-foot bathtub, cannelloni cannon, 14, true, true);
  ^
NOTE the space between the name of the subroutine and the parenthesis is important for some reason

Subroutines without any params must be called without the empty parens (), e.g.:
LOVprep;

To stop using this and get rid of all traces, do:
get commandLineNamespace
set commandLineNamespace =
(i.e. set the commandLineNamespace to empty. If you have other files that you are "using", the first command
will show them -- you'll have to re-"using" them after resetting the name space)


Notes to myself:
you can always find any particular link you are looking for by using the cli 'debug trace on/off' commands.
Turn it on, click the link you want to capture, turn it off...then look in the TRACE log in your mafia folder for the link

KoLmafia SVN connection string
https://svn.code.sf.net/p/kolmafia/code
*/


string gkSpacegateCoordinates = "RATFINK";
item gkJellyToGet = $item[sleaze jelly];
item gkFishyGearToGet = $item[tunac];
# item gkFishyGearToGet = $item[troutsers];


item gkPreeatItem = $item[none];
item gkFoodItem = $item[extra-greasy slider];
int gkEatSpleenReduction = 5;
float gkFoodAdvGains = 6.5 + (gkEatSpleenReduction * kTurnsPerSpleen / gkFoodItem.fullness); // per-fullness adv gain

item gkPredrinkItem = $item[none];
item gkDrinkItem = $item[perfect dark and stormy];
int gkDrinkItemSpleenReduction = 0;
float gkDrinkAdvGains = 6.17 + (gkDrinkItemSpleenReduction * kTurnsPerSpleen / gkDrinkItem.inebriety); // per-inebriety adv gain

item gkPreoverdrinkItem = $item[none];
item gkOverdrinkDrinkItem = $item[sangria del diablo]; // nightcap night cap -- OR sangria del diablo, probably with no pre-drink?
item gkStooperDrink = $item[elemental caipiroska]; // or Lucky Lindy if we need SR and luckyIfNeeded is true
int gkOverdrinkSpleenReduction = 0;

item gkSpleenItem = kSpleenItem;
float gkSpleenAdvGains = kTurnsPerSpleen;

int gkBastilleBuffAmount = 11;


string MallSpecialsPurchasedKey = "_smm.MallSpecialsPurchased";
string ShelfSpecialsPurchasedKey = "_smm.ShelfSpecialsPurchased";

int gStoreSaveAmount = get_property("smm.StoreSaveAmount") == "" ? 11 : get_property("smm.StoreSaveAmount").to_int(); // amount to save from going on sale default 11


// COLD RES BUFFS TODO KGB, pillkeeper, frosty hand (cargo pocket)
AnalyzeRecord [item] gkColdResistanceItems = { // buff amt, is % based?, duration, opportunity cost, effect
	$item[Dreadsylvanian grimlet]: new AnalyzeRecord(5, false, 200, (gkDrinkAdvGains - 9.5) * kTurnValue, $effect[Dreadful Fear]),
	$item[Dreadsylvanian spooky pocket]: new AnalyzeRecord(5, false, 200, (gkFoodAdvGains - 9.5) * kTurnValue, $effect[Dreadful Fear]),
	$item[Dreadsylvanian hot toddy]: new AnalyzeRecord(5, false, 200, (gkDrinkAdvGains - 9.5) * kTurnValue, $effect[Dreadful Heat]),
	$item[Dreadsylvanian hot pocket]: new AnalyzeRecord(5, false, 200, (gkFoodAdvGains - 9.5) * kTurnValue, $effect[Dreadful Heat]),
	$item[bottle of antifreeze]: new AnalyzeRecord(9, false, 10, 0, $effect[Fever From the Flavor]),
	$item[red-hot boilermaker]: new AnalyzeRecord(5, false, 50,  (gkDrinkAdvGains - 3.25) * kTurnValue, $effect[Boilermade]),
	$item[patch of extra-warm fur]: new AnalyzeRecord(5, false, 20, 0, $effect[Furrier Than Thou]),
	$item[oversized ice molecule]: new AnalyzeRecord(5, false, 50, (gkSpleenAdvGains - 0) * kTurnValue, $effect[Icy Composition]),
	$item[Asbestos thermos]: new AnalyzeRecord(5, false, 100, (gkDrinkAdvGains - 3.75) * kTurnValue, $effect[Inner Warmth]),
	$item[Very hot lunch]: new AnalyzeRecord(5, false, 100, (gkFoodAdvGains - 3.75) * kTurnValue, $effect[Inner Warmth]),
	$item[moosemeat pie]: new AnalyzeRecord(5, false, 50, (gkFoodAdvGains - 3.0) * kTurnValue, $effect[Moose-Warmed Belly]),
	$item[warm war shawarma]: new AnalyzeRecord(3, false, 30, (gkFoodAdvGains - 5.5) * kTurnValue, $effect[Shawarma Warm War]),
	$item[cold wad]: new AnalyzeRecord(2, false, 20, (gkSpleenAdvGains - 0) * kTurnValue, $effect[Cold Blooded]),
	$item[lotion of hotness]: new AnalyzeRecord(2, false, 15, 0, $effect[Hot Hands]), // TODO More duration for saucerors
	$item[lotion of spookiness]: new AnalyzeRecord(2, false, 15, 0, $effect[Spooky Hands]), // TODO More duration for saucerors
	$item[penguin paste]: new AnalyzeRecord(2, false, 15, (gkSpleenAdvGains - 1.88) * kTurnValue, $effect[Penguinny Flavor]),
	$item[cold powder]: new AnalyzeRecord(1, false, 5, 0, $effect[Insulated Trousers]),
	$item[cyan seashell]: new AnalyzeRecord(1, false, 20, 0, $effect[Shells of the Damned]),
	$item[recording of Rolando's Rondo of Resisto]: new AnalyzeRecord(5, false, 20, 0, $effect[Rolando's Rondo of Resisto]),
	$item[murderbot shield unit]: new AnalyzeRecord(5, false, 20, 0, $effect[Shielded Unit]),
	$item[vodka barracuda]: new AnalyzeRecord(4, false, 40, (gkDrinkAdvGains - 5.0) * kTurnValue, $effect[Mer-kinkiness]),
	$item[scintillating oyster egg]: new AnalyzeRecord(3, false, 20, (gkSpleenAdvGains - 0) * kTurnValue, $effect[Eggscitingly Colorful]),
	$item[Ish Kabibble]: new AnalyzeRecord(3, false, 25, (gkDrinkAdvGains - 3.5) * kTurnValue, $effect[Feeling No Pain]),
	$item[Party-in-a-Can&trade;]: new AnalyzeRecord(3, false, 50, (gkSpleenAdvGains - 0) * kTurnValue, $effect[Party on Your Skin]),
	$item[rainbow glitter candle]: new AnalyzeRecord(2, false, 80, 0, $effect[Covered in the Rainbow]),
	$item[vodka stinger]: new AnalyzeRecord(2, false, 40, (gkDrinkAdvGains - 4.0) * kTurnValue, $effect[Mer-kindliness]),
	$item[pec oil]: new AnalyzeRecord(2, false, 20, 0, $effect[Oiled-Up]),
	$item[scroll of Protection from Bad Stuff]: new AnalyzeRecord(2, false, 20, 0, $effect[Protection from Bad Stuff]),
	$item[can of black paint]: new AnalyzeRecord(2, false, 10, 0, $effect[Red Door Syndrome]),
	$item[programmable turtle]: new AnalyzeRecord(2, false, 15, 0, $effect[Spiro Gyro]),
	$item[beefy pill]: new AnalyzeRecord(1, false, 30, (gkSpleenAdvGains - 0) * kTurnValue, $effect[Beefy]),
	$item[Tapioc berry]: new AnalyzeRecord(1, false, 20, 0, $effect[Berry Elemental]),
	$item[sticky lava globs]: new AnalyzeRecord(3, false, 20, 0, $effect[Burning Hands]),
	$item[marzipan skull]: new AnalyzeRecord(9, false, 30, 100 + (kTurnValue * kTurnsPerSpleen), $effect[Synthesis: Cold], "synthesize %d Synthesis: Cold"),
	$item[jagged tooth]: new AnalyzeRecord(7, false, 50, -100, $effect[Cold Sweat], "mom cold"),
	$item[grisly shell fragment]: new AnalyzeRecord(3, false, 30, -100, $effect[Rainbow Vaccine], "spacegate vaccine 1"),
	$item[kelp]: new AnalyzeRecord(3, false, 50, -100, $effect[Cold as Nice], "beach head Cold as Nice"),
};



void setDefaultState() {
	setDefaultKoLState();
	setDefaultAutomationState();
}



string sweetSynthesisHelper(item candyA, item candyB) {
	if (candyA == candyB)
		checkIfRunningOut(candyA, 200);
 	else {
		checkIfRunningOut(candyA, 100);
		checkIfRunningOut(candyB, 100);
 	}
	return "synthesize " + candyA + ", " + candyB;
}

void sweetSynthesis(effect buff, int minimumNumberOfTurns) {
 	if (my_spleen_use() >= spleen_limit()) abort("no spleen available to synth!");

	if (buff == $effect[Synthesis: Collection])
		cli_execute_if_needed(sweetSynthesisHelper($item[Crimbo peppermint bark], $item[Crimbo peppermint bark]), buff, minimumNumberOfTurns);
	else if (buff == $effect[Synthesis: Greed])
		cli_execute_if_needed(sweetSynthesisHelper($item[Tallowcreme Halloween Pumpkin], $item[Crimbo fudge]), buff, minimumNumberOfTurns);
	else if (buff == $effect[Synthesis: Smart])
		cli_execute_if_needed(sweetSynthesisHelper($item[marzipan skull], $item[ribbon candy]), buff, minimumNumberOfTurns);
}



// -------------------------------------
// FINANCES
// -------------------------------------


// target stock amount is the available amount times the stockFraction minus gStoreSaveAmount
// will save and NOT sell a number of theItem equal to the #1 rank in the top 10 list
boolean stockTop10Item(int minPrice, int limit, float stockFraction, item theItem) {
	return stockItem(minPrice, limit,
		max(0, (available_amount(theItem) + shop_amount(theItem)) * stockFraction - gStoreSaveAmount),
		rank1Amount(lookupCollection(theItem)),
		theItem);
}


void stockStore() {
	// min price, limit, amount to stock, amount to save, item
 	stockItem(9500, 0, 163, rank1Amount(lookupCollection($item[mojo filter])) + 111, $item[mojo filter]); // save top 1 spot amount and an extra 111 to use
	stockItem(6100, 0, 120, rank1Amount(lookupCollection($item[drum machine])), $item[drum machine]); // save more later for top 10 spot
	stockItem(20000, 0, 22, rank1Amount(lookupCollection($item[sleaze jelly])) + 100, $item[sleaze jelly]); // save top 1 spot amount and an extra 100 to use

	// min price, limit, amount to stock, item
	stockItem(20000, 0, 11, $item[bottle of antifreeze]);

	// Arr, M80 items
	// min price, limit, fraction to stock, item
	stockTop10Item(100, 0, 0.5, $item[bottle of rum]);
	stockTop10Item(200, 0, 0.5, $item[crowbarrr]);
	stockTop10Item(100, 0, 0.5, $item[eyepatch]);
	stockTop10Item(1000, 66, 0.5, $item[flaregun]);
	stockTop10Item(100, 0, 0.5, $item[grogpagne]);
	stockTop10Item(990, 66, 0.5, $item[grungy bandana]);
	stockTop10Item(200, 0, 0.5, $item[leotarrrd]);
	stockTop10Item(180, 0, 0.5, $item[stuffed shoulder parrot]);
	stockTop10Item(3450, 22, 0.5, $item[sunken chest]);
	stockTop10Item(180, 0, 0.5, $item[swashbuckling pants]);

	// price, limit, amount to stock, item
	put_shop(83000, 0, 3 - shop_amount($item[low tide martini]), $item[low tide martini]);

	// arbitrage
	doArbitrage($item[scimitar cozy], 5);
	doArbitrage($item[fish stick cozy], 5);
	doArbitrage($item[bazooka cozy], 5);
	doArbitrage($item[great old fashioned], 5);
	doArrbitrage($item[4-d camera], 11);

// 	put_shop(0, 0, available_amount($item[rocky raccoon]) - 250, $item[rocky raccoon]);
// 	put_shop(0, 0, available_amount($item[savoy truffle]) - 250, $item[savoy truffle]);
// 	put_shop(0, 0, available_amount($item[hot date]) - 250, $item[hot date]);
// 	put_shop(0, 0, available_amount($item[palm frond]) - 500, $item[palm frond]);
// 	put_shop(0, 0, available_amount($item[happiness]) - 1, $item[happiness]);
// 	put_shop(0, 0, available_amount($item[Maxwell's Silver Hammer]) - 1, $item[Maxwell's Silver Hammer]);
// 	put_shop(0, 0, available_amount($item[Colonel Mustard's Lonely Spades Club Jacket]) - 1, $item[Colonel Mustard's Lonely Spades Club Jacket]);
// 	put_shop(0, 0, available_amount($item[Corporal Fennel's Lonely Clubs Club Jacket]) - 1, $item[Corporal Fennel's Lonely Clubs Club Jacket]);
// 	put_shop(0, 0, available_amount($item[General Sage's Lonely Diamonds Club Jacket]) - 1, $item[General Sage's Lonely Diamonds Club Jacket]);
// 	put_shop(0, 0, available_amount($item[Private Pepper's Lonely Hearts Club Jacket]) - 1, $item[Private Pepper's Lonely Hearts Club Jacket]);
}



// current income for sea locations
void currentIncomeSea(int perAdventureCost, float itemDrop, float meatDrop) {
	print("octopus's garden", "blue");
	print("neptune flytrap: " + (monsterTotalMeatValue($monster[neptune flytrap], itemDrop, meatDrop) - perAdventureCost));
	print("octopus gardener: " + (monsterTotalMeatValue($monster[octopus gardener], itemDrop, meatDrop) - perAdventureCost));
	print("sponge: " + (monsterTotalMeatValue($monster[sponge], itemDrop, meatDrop) - perAdventureCost));
	print("stranglin' algae: " + (monsterTotalMeatValue($monster[stranglin' algae], itemDrop, meatDrop) - perAdventureCost));

	print("wreck of the edgar fitzsimmons", "blue");
	print("mer-kin scavenger: " + (monsterTotalMeatValue($monster[mer-kin scavenger], itemDrop, meatDrop) - perAdventureCost));
	print("cargo crab: " + (monsterTotalMeatValue($monster[cargo crab], itemDrop, meatDrop) - perAdventureCost));
	print("drowned sailor: " + (monsterTotalMeatValue($monster[drowned sailor], itemDrop, meatDrop) - perAdventureCost));
	print("mine crab: " + (monsterTotalMeatValue($monster[mine crab], itemDrop, meatDrop) - perAdventureCost));
	print("unholy diver: " + (monsterTotalMeatValue($monster[unholy diver], itemDrop, meatDrop) - perAdventureCost));

	print("coral corral", "blue");
	print("sea cowboy: " + (monsterTotalMeatValue($monster[sea cowboy], itemDrop, meatDrop) - perAdventureCost));
	print("sea cow: " + (monsterTotalMeatValue($monster[sea cow], itemDrop, meatDrop) - perAdventureCost));
	print("mer-kin rustler: " + (monsterTotalMeatValue($monster[mer-kin rustler], itemDrop, meatDrop) - perAdventureCost));

	print("dive bar", "blue");
	print("mer-kin tippler: " + (monsterTotalMeatValue($monster[mer-kin tippler], itemDrop, meatDrop) - perAdventureCost));
	print("lounge lizardfish: " + (monsterTotalMeatValue($monster[lounge lizardfish], itemDrop, meatDrop) - perAdventureCost));
	print("nurse shark: " + (monsterTotalMeatValue($monster[nurse shark], itemDrop, meatDrop) - perAdventureCost));

	print("anemone mine", "blue");
	print("anemone combatant: " + (monsterTotalMeatValue($monster[anemone combatant], itemDrop, meatDrop) - perAdventureCost));
	print("killer clownfish: " + (monsterTotalMeatValue($monster[killer clownfish], itemDrop, meatDrop) - perAdventureCost));
	print("mer-kin miner: " + (monsterTotalMeatValue($monster[mer-kin miner], itemDrop, meatDrop) - perAdventureCost));

	print("marinara trench", "blue");
	print("diving belle: " + (monsterTotalMeatValue($monster[diving belle], itemDrop, meatDrop) - perAdventureCost));
	print("fisherfish: " + (monsterTotalMeatValue($monster[fisherfish], itemDrop, meatDrop) - perAdventureCost));
	print("giant squid: " + (monsterTotalMeatValue($monster[giant squid], itemDrop, meatDrop) - perAdventureCost));
	print("mer-kin diver: " + (monsterTotalMeatValue($monster[mer-kin diver], itemDrop, meatDrop) - perAdventureCost));

	print("mer-kin outpost", "blue");
	print("mer-kin burglar: " + (monsterTotalMeatValue($monster[mer-kin burglar], itemDrop, meatDrop) - perAdventureCost));
	print("mer-kin raider: " + (monsterTotalMeatValue($monster[mer-kin raider], itemDrop, meatDrop) - perAdventureCost));
	print("mer-kin healer: " + (monsterTotalMeatValue($monster[mer-kin healer], itemDrop, meatDrop) - perAdventureCost));

	print("caliginous abyss", "blue");
	print("eye in the darkness: " + (monsterTotalMeatValue($monster[eye in the darkness], itemDrop, meatDrop) - perAdventureCost));
	print("peanut: " + (monsterTotalMeatValue($monster[peanut], itemDrop, meatDrop) - perAdventureCost));
	print("school of many: " + (monsterTotalMeatValue($monster[school of many], itemDrop, meatDrop) - perAdventureCost));
	print("slithering thing: " + (monsterTotalMeatValue($monster[slithering thing], itemDrop, meatDrop) - perAdventureCost));

	print("madness reef", "blue");
	print("jamfish: " + (monsterTotalMeatValue($monster[jamfish], itemDrop, meatDrop) - perAdventureCost));
	print("magic dragonfish: " + (monsterTotalMeatValue($monster[magic dragonfish], itemDrop, meatDrop) - perAdventureCost));
	print("pufferfish: " + (monsterTotalMeatValue($monster[pufferfish], itemDrop, meatDrop) - perAdventureCost));
}

void currentIncomeSea() {
	currentIncomeSea(perAdventureCost(), item_drop_modifier(), meat_drop_modifier());
}



void currentIncome(int perAdventureCost, float itemDrop, float meatDrop) {
	print("****INCOME WITH: " + perAdventureCost + " meat spent/adv, +" + itemDrop + "% item, +" + meatDrop + "% meat");

	int bikerGain = monsterTotalMeatValue($monster[biker], itemDrop, meatDrop) - perAdventureCost;
	int burnoutGain = monsterTotalMeatValue($monster[burnout], itemDrop, meatDrop) - perAdventureCost;
	int jockGain = monsterTotalMeatValue($monster[jock], itemDrop, meatDrop) - perAdventureCost;
	int partyGirlGain = monsterTotalMeatValue($monster[party girl], itemDrop, meatDrop) - perAdventureCost;
	int plainGirlGain = monsterTotalMeatValue($monster["plain" girl], itemDrop, meatDrop) - perAdventureCost;
	print("biker: " + bikerGain);
	print("burnout: " + burnoutGain);
	print("jock: " + jockGain);
	print("party girl: " + partyGirlGain);
	print("'plain' girl: " + plainGirlGain);
	print("neverending party average: " + ((bikerGain + burnoutGain + jockGain + partyGirlGain + plainGirlGain) / 5));
	print("");

	print("angry ghost: " + (monsterTotalMeatValue($monster[angry ghost], itemDrop, meatDrop) - perAdventureCost));
	print("slime blob: " + (monsterTotalMeatValue($monster[slime blob], itemDrop, meatDrop) - perAdventureCost));
	print("terrible mutant: " + (monsterTotalMeatValue($monster[terrible mutant], itemDrop, meatDrop) - perAdventureCost));
	print("government bureaucrat: " + (monsterTotalMeatValue($monster[government bureaucrat], itemDrop, meatDrop) - perAdventureCost));
	print("annoyed snake: " + (monsterTotalMeatValue($monster[annoyed snake], itemDrop, meatDrop) - perAdventureCost));
	print("");

	print("bookbat: " + (mall_price($item[tattered scrap of paper]) * ((10 * (1 + itemDrop/100)) / 100) - perAdventureCost)); // mafia's drop rate for tattered scrap of paper is wrong

	print("gnarly/gnasty gnome: " + (mall_price($item[clockwork key]) * ((1.6 * (1 + itemDrop/100)) / 100) - perAdventureCost)); // mafia's drop rate for clockwork keys is horribly wrong

	print("blur: " + ((monsterTotalMeatValue($monster[blur], itemDrop, meatDrop) * 0.95) - perAdventureCost - mall_price($item[ten-leaf clover])/20));
	print("swarm of scarab beatles: " + (monsterTotalMeatValue($monster[swarm of scarab beatles], itemDrop, meatDrop) * 0.8)); // include cost of the ten-leaf clover and the 1 turn in 20 to get Ultrahydrated
}

void currentIncome() {
	currentIncome(perAdventureCost(), item_drop_modifier(), meat_drop_modifier());
}


void printIncomeDetails(monster aMonster) {
	print(aMonster);
	int [item] itemDrops = item_drops(aMonster);
	foreach anItem in itemDrops {
		print(anItem + ": " + itemDrops[anItem] + "% drop @" + mall_price(anItem) + " meat");
	}
}



void luckyIncome() {
	int [location] luckyAdventuresByMeatGainMap = luckyAdventuresByMeatGainMap();
	location [] sortedLuckyAdventuresByMeatGain = sortedLuckyAdventuresByMeatGain(false);
	print("turn value: " + kTurnValue + " -- cost to get lucky! with:");
	print("pillkeeper (first): 0, subsequent: " + (3 * gkSpleenAdvGains * kTurnValue));
	print("Lucky Lindy: " + (kTurnValue * 3 + 500));
	print("11-leaf clover: " + historical_price($item[11-leaf clover]));
	foreach ind, aloc in sortedLuckyAdventuresByMeatGain {
		print(aloc + ": " + luckyAdventuresByMeatGainMap[aloc]);
	}
}


void luckyCurrentIncome() {
	int [location] luckyAdventuresByMeatGainMap = luckyAdventuresByMeatGainMap();
	location [] sortedLuckyAdventuresByMeatGain = sortedLuckyAdventuresByMeatGain(false);
	foreach ind, aloc in sortedLuckyAdventuresByMeatGain {
		print(aloc + ": " + (luckyAdventuresByMeatGainMap[aloc] - kTurnValue));
	}
}



item [] kCimboItems = {
	$item[gooified animal matter],
	$item[gooified vegetable matter],
	$item[gooified mineral matter],

	$item[fleshy putty],
	$item[third ear],
	$item[festive egg sac],

	$item[poisonsettia],
	$item[peppermint-scented socks],
	$item[the Crymbich Manuscript],

	$item[projectile chemistry set],
	$item[depleted Crimbonium football helmet],
	$item[synthetic rock],

	$item[&quot;caramel&quot; orange],
	$item[self-repairing earmuffs],
	$item[carnivorous potted plant],

	$item[universal biscuit],
	$item[yule hatchet],
	$item[potato alarm clock],

	$item[lab-grown meat],
	$item[golden fleece],
	$item[boxed gumball machine],

	$item[cloning kit],
	$item[electric pants],
	$item[can of mixed everything],
};

void crimcome() {
	string printString = "<table><tr><th>item</th><th>mall value</th></tr>";

	foreach idx, critem in kCimboItems {
		printString += "<tr><td>"
			+ critem + "</td><td>"
			+ mall_price(critem)
			+ "</td></tr>";
	}

	printString += "</table>";

	print_html(printString);
}



// calculates income from some monsters. Dresses up in all item (and then all meat) gear
// use bonusItemDrop and bonusMeatDrop to simulate other item or meat drop buffs that aren't
// currently in effect
void incomeCalculator(int bonusItemDrop, int bonusMeatDrop) {
	clear_automate_dressup();
	use_familiar($familiar[Trick-or-Treating Tot]);

	print("TESTING WITH +ITEM", "blue");
	if (isAsdonWorkshed())
		fueled_asdonmartin("observantly", 1);
// 	foreach i, rec in maximize("item, 0.1 meat, +switch tot, +switch cat burglar", 1, 2, true, true) {
// 		if (rec.score >= 1.0) {
// 			print_html("item #" + i + " score: " + to_string(rec.score, "%.2f") + ", '" + rec.command + "'");
// 			print("effect: " + rec.effect + ", item: " + rec.item + " skill: " + rec.skill);
// 			if (rec.effect != $effect[none] && rec.item != $item[none])
// 				print("cost: " + mall_price(rec.item));
// 			print("");
// 		}
// 	}
// 	currentIncome(perAdventureCost(), numeric_modifier("Generated:_spec", "Item Drop"), numeric_modifier("Generated:_spec", "Meat Drop"));
	automate_dressup($location[none], "item", "item", "");
	currentIncome(perAdventureCost(), item_drop_modifier() + bonusItemDrop, meat_drop_modifier() + bonusMeatDrop);


	print("TESTING WITH +MEAT", "blue");
// 	foreach i, rec in maximize("meat, 0.1 item, +switch tot, +switch cat burglar, +switch hobo monkey", 1, 2, true, true) {
// 		if (rec.score >= 1.0) {
// 			print_html("item #" + i + " score: " + to_string(rec.score, "%.2f") + ", '" + rec.command + "'");
// 			print("effect: " + rec.effect + ", item: " + rec.item + " skill: " + rec.skill);
// 			if (rec.effect != $effect[none] && rec.item != $item[none])
// 				print("cost: " + mall_price(rec.item));
// 			print("");
// 		}
// 	}
// 	currentIncome(perAdventureCost(), numeric_modifier("Generated:_spec", "Item Drop"), numeric_modifier("Generated:_spec", "Meat Drop"));
	automate_dressup($location[none], "meat", "meat", "");
	currentIncome(perAdventureCost(), item_drop_modifier() + bonusItemDrop, meat_drop_modifier() + bonusMeatDrop);
}



// calculates income from some monsters. Dresses up in all item (and then all meat) gear
// use bonusItemDrop and bonusMeatDrop to simulate other item or meat drop buffs that aren't
// currently in effect
void incomeCalculator() {
	incomeCalculator(0, 0);
}



// -------------------------------------
// AUTOMATION -- DAILY
// -------------------------------------

void useNashCrosbyStill() {
	print("useNashCrosbyStill", "green");
	item[int] distilledLiquour;
	for i from 0 to 11 {
		distilledLiquour[i] = to_item(i + 1551);
	}
	distilledLiquour[12] = $item[bottle of Pete's Sake];
	distilledLiquour[13] = $item[bottle of Ooze-O];
	
	sort distilledLiquour by available_amount(value);
	int i = 0;
	while (stills_available() > 0) {
		create(min(stills_available(), creatable_amount(distilledLiquour[i])), distilledLiquour[i]);
		i++;
	}
}



int effectiveGingerbreadCityTurns() {
	int base = to_int(get_property("_gingerbreadCityTurns"));
	int clockAdvance = 0;
	if (to_boolean(get_property("_gingerbreadClockAdvanced"))) clockAdvance = 5;
	return base + clockAdvance;
}


void printGingerbreadLeaderboard() {
	string page = visit_url("/place.php?whichplace=gingerbreadcity&action=gc_leaderboard", false);
	matcher leaderboardMatcher = create_matcher("<tr><td><b><a class=nounder href=showplayer.php\\?who=[0-9]+>(.+?)</a></b></td><td></td><td>([0-9,]+) sprinkles</td></tr>", page);
	while (find(leaderboardMatcher)) {
		string leaderName = group(leaderboardMatcher, 1);
		int leaderAmount = to_int(group(leaderboardMatcher, 2));
		print(leaderName + ": " + leaderAmount);
	}
}



string maxStringForSausageGoblin() {
	return "exp, 0.1 meat";
}



void dressupForBackupCamera(location aLocation, int copiesToMake) {
	monster cameraMonster = last_monster();
	string kDefaultFamiliar = "default";

	// DRESS UP
	equip_all_familiars(); // important for Pocket Professor
	string familiarSelector = kDefaultFamiliar;
	string selector = "item";
	string maxString = "+equip backup camera, pickpocket chance, item";

	if (cameraMonster == $monster[sausage goblin]) {
		selector = "exp";
		maxString = maxStringAppend(maxString + ", -equip mafia thumb ring", maxStringForSausageGoblin());
	}

	// simulate a maximize with "familiar weight", which will be used by pocketProfessorLecturesPossiblyAvailable
	maximize(maxString + ", familiar weight", true);
	// buff up if we need it
	if (copiesToMake >= 2 && pocketProfessorLecturesPossiblyAvailable() < copiesToMake - 1) { // -1 for the original one back'ed up to
		cli_execute_if_needed("beach head Do I Know You From Somewhere?", $effect[Do I Know You From Somewhere?]);
	}
	if (copiesToMake >= 2 && pocketProfessorLecturesPossiblyAvailable() > 0) {
		familiarSelector = "Pocket Professor";
		maxString += ", familiar weight";
		maxString += ", equip Pocket Professor memory chip";
	}

	maxString = maxStringForLocation(aLocation, maxString);

	automate_dressup(aLocation, selector, familiarSelector, maxString); // item and pp chance in case we are backing up to something that might drop something
}


// handles the chained combat if we decide to use the pocket professor's relativity
int grindBackupCameraFightHelper(int copiesToMake, monster cameraMonster, string aPage) {
	assert(inCombat(), "grindBackupCameraFightHelper: we're not in combat");

	if (copiesToMake >= 2 && my_familiar() == $familiar[Pocket Professor] && pocketProfessorLecturesAvailable() > 0 && my_hp() >= my_maxhp() / 4) {
		aPage = customScriptWithDefaultKill(1, cameraMonster, aPage, "skill lecture on relativity;");
		copiesToMake--;
		boolean conditionsSatisfied = postAdventure();

		visit_url("/main.php", false, false); // get to the new fight
		if (current_round() != 1) abort("We didn't get to a new Pocket Professor fight! current round = " + current_round());

		if (conditionsSatisfied) {
			print("conditions satisfied, exiting after chained fight", "orange");
			run_combat(); postAdventure();
			return 0;
		} else
			copiesToMake = grindBackupCameraFightHelper(copiesToMake, cameraMonster, aPage);

	} else {
		run_combat(); postAdventure();
		copiesToMake--;
	}

	return copiesToMake;
}

// backs up to the last monster, adventuring at aLocation
// will kill the target "times" times, which may not exactly correspond to number of backups used
// as other copiers might be used
// if aLocation == none, will use redirectionDelayLocation() to determine the location to grind
// if stopMonster != none, will stop automation and return if we meet stopMonster
// returns the number of backups actually done
int grindBackupCamera(location aLocation, int times, monster stopMonster) {
	assert(equipped_amount($item[backup camera]) >= 1, "grindBackupCamera: no backup camera equipped");

	boolean hadGoals = haveGoals();
	string aPage;
	location advLocation = aLocation;
	monster cameraMonster = last_monster();
	int copiesToMake = min(times, backupCameraUsesAvailable() + pocketProfessorLecturesAvailable());
	int kStartingCopies = copiesToMake;
	print("grindBackupCamera: " + cameraMonster + " at "
		+ (aLocation == $location[none] ? " delay locations " : aLocation.to_string()) + " -- " + copiesToMake + " times (wanted " + times + ")", "green");

	// GRIND
	try {
		saveAndSetProperty(kCheckForLastSausageGoblinKey, "false");

		while ((haveGoals() || !hadGoals) && copiesToMake > 0 && last_monster() == cameraMonster && backupCameraUsesAvailable() > 0) {
			boolean conditionsSatisfied;

			if (aLocation == $location[none])
				advLocation = redirectionDelayLocation();

			if (!in_multi_fight()) {
				healIfRequiredWithMPRestore();
				aPage = advURL(advLocation);
			}

			if (isErrorPage(aPage)) {
				print("got an error page:\n" + aPage, "red");
				abort("grindBackupCamera: didn't get to the adventure location: " + advLocation);
			}

			if (handling_choice()) {
				run_choice(-1);
				if (postAdventure()) break;

			// no action adventure(?)
			} else if (!contains_text(aPage, "fight.php")) {
				if (postAdventure()) break;
				continue;

			} else if (last_monster() == stopMonster) { // stop monster
				break;

			} else if (last_monster() == cameraMonster) { // we're already fighting the right monster
				copiesToMake = grindBackupCameraFightHelper(copiesToMake, cameraMonster, aPage);

			} else { // fighting a different monster: backup to the target
				string script = "pickpocket;pickpocket;if !monstername \"" + cameraMonster + "\";skill back-up to your last enemy;endif;";
				aPage = executeScript(script);
				visit_url("/fight.php", true, false); // get to the new fight
				copiesToMake = grindBackupCameraFightHelper(copiesToMake, cameraMonster, aPage);
			}

			if ((my_familiar() == $familiar[Pocket Professor]) && (copiesToMake == 1 || pocketProfessorLecturesAvailable() == 0) && !in_multi_fight())
				break; // return with only partial done if we can't use the pocket professor any more??
		}
	} finally {
		restoreSavedProperty(kCheckForLastSausageGoblinKey);
	}

	if (kStartingCopies - copiesToMake > 0)
		print("WARNING: still have copies to make!", "red");
	return kStartingCopies - copiesToMake;
}

// dresses appropriately and then calls grindBackupCamera
int grindBackupCameraWithDressup(location aLocation, int times, monster stopMonster) {
	dressupForBackupCamera(aLocation, times);
	setDefaultMoodForLocation(aLocation);
	return grindBackupCamera(aLocation, times, stopMonster);
}

void grindBackupCamerasWithDressup(int times) {
	int turnsToPervert = 19 - smutOrcPervertProgress();
	int copiesToMakeAvailable = min(times, backupCameraUsesAvailable() + pocketProfessorLecturesAvailable());

	location advLocation = redirectionDelayLocation();
	if (advLocation == $location[The Smut Orc Logging Camp]) {
		if (copiesToMakeAvailable > turnsToPervert)
			if (!user_confirm(turnsToPervert + " turns to Smut Orc Pervert, " + $location[The Smut Orc Logging Camp].turns_spent + " turns spent -- " + copiesToMakeAvailable + " backups will overwrite it. Continue?", 60000, false))
				abort();
	}

	grindBackupCameraWithDressup(advLocation, copiesToMakeAvailable, $monster[none]);
}

void grindBackupCamerasWithDressup() {
	grindBackupCamerasWithDressup(backupCameraUsesAvailable() + pocketProfessorLecturesAvailable());
}

// backup at the current location
void delayBackupCameraWithDressup(int times, monster stopMonster) {
	grindBackupCameraWithDressup(my_location(), times, stopMonster);
}



float turnGenValueOfSpleen() { // spleenValue spleen value value of spleen
	return (kTurnsPerSpleen * kTurnValue);
}

float synthGreedValueOfSpleen(int baseMeatDrop) {
	float kSweetSynthGreedMultiplier = 3.0;
	int costOfSweetSynth = 2000;
	int sweetSynthTurns = 30;
	return (baseMeatDrop * kSweetSynthGreedMultiplier * sweetSynthTurns) - costOfSweetSynth;
}

void spleenBreakpoints(monster testMonster) {
	print("spleen is worth " + kTurnsPerSpleen + " advs and an adv is worth " + kTurnValue + " meat, therefore a spleen is worth " + (turnGenValueOfSpleen()) + " meat if used for turngen");

	int baseMeatDrop = monsterBaseMeatDropValue(testMonster);
	int currentMeatDrop = monsterCurrentMeatDropValue(testMonster);
	float greedValue = monsterMeatDropValue(testMonster, meat_drop_modifier() + 300) - currentMeatDrop;
	print("when used to target " + testMonster + ", with " + baseMeatDrop + " base and " + currentMeatDrop + " current meat drop, Synth: Greed will give " + greedValue + " extra meat per turn, " + greedValue * 30 + " meat over 30 turns");

	print("");

	int baseItemDrop = monsterBaseItemMeatValue(testMonster);
	int currentItemDrop = monsterCurrentItemMeatValue(testMonster);
	float collectValue = monsterItemMeatValue(testMonster, item_drop_modifier() + 150) - monsterCurrentItemMeatValue(testMonster);
	print("when used to target " + testMonster + ", with items worth " + baseItemDrop + " base and " + currentItemDrop + " current, Synth: Collection will give " + collectValue + " extra meat per turn, " + collectValue * 30 + " meat over 30 turns");
}



void printMPCost(item anItem) {
	int mallPrice = mall_price(anItem);
	effect anEffect = effect_modifier(anItem, "Effect");
	if (anEffect != $effect[none]) {
		float mpPerTurn = (numeric_modifier(anEffect, "MP Regen Min") + numeric_modifier(anEffect, "MP Regen Max")) / 2;
		int effectTurns = numeric_modifier(anItem, "Effect Duration");
		print(anItem + ": " + to_string(mpPerTurn, "%.1f") + "mp/turn for " + effectTurns + " turns @" + mallPrice + ", " + to_string(mallPrice/(mpPerTurn * effectTurns), "%.3f") + "meat/mp");
	} else {
		float avgMP = (anItem.minmp + anItem.maxmp) / 2;
		print(anItem + ": " + to_string(avgMP, "%.1f") + "mp @" + mallPrice + ", " + to_string(mallPrice/avgMP, "%.3f") + "meat/mp");
	}
}

void cheapestMPRegen() {
	print("gulp latte: 'free'");
	print("april shower: 1000mp @" + (3.5 * mall_price($item[shard of double-ice])) + " meat, " + ((3.5 * mall_price($item[shard of double-ice])) / min(1000, my_maxmp())) + " meat/mp");
	print("magical mystery juice: " + ((my_level() * 1.5) + 5) + "mp @45 meat, " + to_string(45 / ((my_level() * 1.5) + 5), "%.3f") + " meat/mp");
	printMPCost($item[mangled finger]);
	printMPCost($item[neurostim pill]);
	printMPCost($item[irradiated turtle]);
	printMPCost($item[orcish hand lotion]);
	printMPCost($item[carbonated water lily]);
	printMPCost($item[honey-dipped locust]);
	printMPCost($item[Monstar energy beverage]);
	printMPCost($item[ancient magi-wipes]);
	printMPCost($item[Doc Galaktik's Invigorating Tonic]);
	printMPCost($item[Dyspepsi-Cola]);
	printMPCost($item[Cloaca-Cola]);
	printMPCost($item[phonics down]);
	printMPCost($item[carbonated soy milk]);
	printMPCost($item[tiny house]);
	printMPCost($item[knob goblin seltzer]);
	printMPCost($item[Notes from the Elfpocalypse, Chapter I]);
	printMPCost($item[Mountain Stream soda]);
	printMPCost($item[dueling turtle]);
	printMPCost($item[elven magi-pack]);
	print("Egnaro berry: " + floor(my_maxmp() / 2.0) + " @" + mall_price($item[Egnaro berry]) + " meat, " + (1.0 * mall_price($item[Egnaro berry]) / (my_maxmp() / 2)) + " meat/mp");
}


string mpCostHTML(item anItem) {
	string rval = "";

	int mallPrice = mall_price(anItem);
	effect anEffect = effect_modifier(anItem, "Effect");
	if (anEffect != $effect[none]) {
		float mpPerTurn = (numeric_modifier(anEffect, "MP Regen Min") + numeric_modifier(anEffect, "MP Regen Max")) / 2;
		int effectTurns = numeric_modifier(anItem, "Effect Duration");
		rval = "<tr><td>" + anItem + "</td><td>" + to_string(mpPerTurn, "%.1f") + "mp/turn for " + effectTurns + " turns</td><td>" + mallPrice + "</td><td>" + to_string(mallPrice/(mpPerTurn * effectTurns), "%.3f") + "</td></tr>";
	} else {
		float avgMP = (anItem.minmp + anItem.maxmp) / 2;
		rval = "<tr><td>" + anItem + "</td><td>" + to_string(avgMP, "%.1f") + "mp</td><td>" + mallPrice + "</td><td>" + to_string(mallPrice/avgMP, "%.3f") + "</td><tr>";
	}

	return rval;
}

void cheapestMPRegenHTML() {
	string mpTable = "<table><thead><tr><td>name</td><td>mp restored</td><td>mall price</td><td>meat/mp</td></tr></thead><tbody>";
	mpTable += "<tr><td>magical mystery juice</td><td>" + ((my_level() * 1.5) + 5) + "mp</td><td>45</td><td>" + to_string(45 / ((my_level() * 1.5) + 5), "%.3f") + "</td></tr>";
	mpTable += mpCostHTML($item[mangled finger]);
	mpTable += mpCostHTML($item[neurostim pill]);
	mpTable += mpCostHTML($item[irradiated turtle]);
	mpTable += mpCostHTML($item[orcish hand lotion]);
	mpTable += mpCostHTML($item[carbonated water lily]);
	mpTable += mpCostHTML($item[Monstar energy beverage]);
	mpTable += "<tr></tr>";
	mpTable += "<tr><td>Egnaro berry</td><td>" + floor(my_maxmp() / 2.0) + "</td><td>" + mall_price($item[Egnaro berry]) + " meat</td><td>" + to_string(1.0 * mall_price($item[Egnaro berry]) / (my_maxmp() / 2), "%.3f") + "</td></tr>";
	mpTable += "<tr><td>april shower</td><td>1000mp</td><td>" + (3.5 * mall_price($item[shard of double-ice])) + " meat</td><td>" + to_string((3.5 * mall_price($item[shard of double-ice])) / 1000, "%.3f") + "</td></tr>";
	mpTable += "<tr><td>gulp latte</td><td>" + floor(my_maxmp() / 2.0) + "</td><td>n/a</td><td>n/a</td></tr>";
	mpTable += "</tbody></table>";

	print_html(mpTable);
	print("");
}



void getDocGalaktikQuest() {
	if (!is_on_quest("What's Up, Doc?")) {
		visit_url("/shop.php?whichshop=doc&action=talk", false, false);
		run_choice(1);
	}
}

void getMeatsmithQuest() {
	if (!is_on_quest("Helping Make Ends Meat")) {
		visit_url("/shop.php?whichshop=meatsmith&action=talk", false, false);
		run_choice(1);
	}
}

void getArmoryQuest() {
	if (!is_on_quest("Lending a Hand (and a Foot)")) {
		visit_url("/shop.php?whichshop=armory&action=talk", false, false);
		run_choice(1);
	}
}

void getOldLandfillQuest() {
	if (!is_on_quest("Give a Hippy a Boat...")) {
		visit_url("/place.php?whichplace=woods&action=woods_smokesignals", false, false);
		run_choice(1);
		run_choice(2);
	}
}



record MaximizerRecord {
	string display; //What would be shown in the Modifier Maximizer tab
	string command; //The CLI command the Maximizer would execute
	float score;    //The score added from equipping the item or gaining 1 turn of the effect
	effect anEffect;  //The effect you would gain
	item anItem;      //The item being used or equipped
	skill aSkill;    //The skill you need to cast
};


void grindGlitchSeasonReward() {
	print("grindGlitchSeasonReward", "green");
	advURL("/inv_eat.php?pwd&which=3&whichitem=10207", true, false);
	run_combat(); postAdventure();
// 	assert(get_property("_glitchMonsterFights").to_boolean(), "did not flight the glitch monster");
}



void grindDrip(location dripLoc, string dressupTweak) {
	print("grindDrip at " + dripLoc + " with dressupTweak: " + dressupTweak, "green");

	setDefaultState();
	change_mcd(0);

	// CONSUME
	if (!to_boolean(get_property("_drippyNuggetUsed")) && my_fullness() <= fullness_limit() - 5) {
		useMoMifNeeded();
		eat(1, $item[drippy nugget]);
	}
	if (!to_boolean(get_property("_drippyWineUsed")) && my_inebriety() <= inebriety_limit() - 5) {
		useOdeToBoozeIfNeeded(5);
		drink(1, $item[glass of drippy wine]);
	}
	int turnsToGrind = to_int(get_property("drippyJuice"));

	if (turnsToGrind > 0) {
		// DRESSUP
		if (item_amount($item[drippy stake]) > 1) put_closet(item_amount($item[drippy stake]) - 1, $item[drippy stake]);

		string maxString = "0.2 mus, +equip drippy stake, +equip drippy khakis, +equip Drip harness, +equip lustrous drippy orb";
		maxString = maxStringAppend(maxString, fixupCLArtifacts(dressupTweak));
		if (!wantsToEquip(maxString, $slot[off-hand]) && !wantsToNotEquip(maxString, $item[drippy truncheon]) && countHandsUsed(maxString) < 2)
			maxString = maxStringAppend(maxString, "equip drippy truncheon");
		if (!wantsToEquip(maxString, $slot[off-hand]) && !wantsToNotEquip(maxString, $item[drippy shield]) && countHandsUsed(maxString) < 2)
			maxString = maxStringAppend(maxString, "equip drippy shield");
		if (can_equip($item[sea salt scrubs]))
			maxString += ", +equip sea salt scrubs";
		automate_dressup(dripLoc, "item", "item", maxString);

		use_if_needed($item[handful of hand chalk], $effect[Chalky Hand], turnsToGrind);
		if (my_buffedstat($stat[muscle]) < 200)
			use_if_needed($item[Ferrigno's Elixir of Power], $effect[Incredibly Hulking], turnsToGrind);
		if (my_buffedstat($stat[muscle]) < 200)
			abort("not enough muscle!");

		// ADVENTURE
		while (turnsToGrind > 0) {
			healIfRequiredWithMPRestore();
			adventure(1, dripLoc);
			turnsToGrind = to_int(get_property("drippyJuice"));
		}
	}

}

void grindDrip() {

	if (have_item($item[maple magnet])) {
		saveAndSetProperty("choiceAdventure1406", "5");

		grindDrip($location[the dripping trees], "equip maple magnet");

		restoreSavedProperty("choiceAdventure1406");
	} else {
	// 	set_property("choiceAdventure1411", "1"); // door 1: staff and maybe drippy orb
	// 	set_property("choiceAdventure1411", "2"); // door 2: candy bar or driplets
		set_property("choiceAdventure1411", "3"); // door 3: drippy grub
	// 	set_property("choiceAdventure1411", "4"); // door 4: trade drippy stein for drippy pilsner
	// 	set_property("choiceAdventure1411", "5"); // door 5: driplets
		set_property("choiceAdventure1415", "1"); // buy drippy candy bar

		grindDrip($location[the dripping hall], "");

		remove_property("choiceAdventure1411");
		remove_property("choiceAdventure1415");
	}
}



void grindScience(boolean useSweetSynthesis) {
	print("grindScience", "green");
	if (to_boolean(get_property("_eldritchTentacleFought")) && to_boolean(get_property("_eldritchHorrorEvoked")))
		return;

	if (isAsdonWorkshed() && !drivingAsdonMartin())
		fueled_asdonmartin("observantly", 1);
	if (useSweetSynthesis && my_spleen_use() < spleen_limit())
		sweetSynthesis($effect[Synthesis: Collection], 1);

	burnMP();
	string maxString = "spell dmg";
	if (my_primestat() != $stat[moxie] && my_basestat($stat[moxie]) >= 200)
		maxString = maxString + ", +equip mime army infiltration glove, +equip meteorb";
	else if (my_primestat() != $stat[moxie])
		maxString = maxString + ", +equip Tiny black hole";
	else
		maxString = maxString + ", +equip meteorb";
	dressup($location[none], "spell damage percent", "magic dragonfish", maxString);

	restore_mp(100);

	// fight the tentacle at the science tent
	if (!to_boolean(get_property("_eldritchTentacleFought"))) {
		healIfRequiredWithMPRestore();
		buffer page = visit_url("/place.php?whichplace=forestvillage&action=fv_scientist", true, false);
		run_choice(1);
		//visit_url("/choice.php?whichchoice=1201&option=1&pwd", true, false); // fight tentacle
		//visit_url("/fight.php?action=steal", true, false); // pickpocket if able
		//run_combat();
	}

	// fight the tentacle from the skill
	if (!to_boolean(get_property("_eldritchHorrorEvoked"))) {
		healIfRequiredWithMPRestore();
		use_if_needed($item[crappy waiter disguise], $effect[Crappily Disguised as a Waiter], 1);
		use_skill($skill[Evoke Eldritch Horror]);
		//visit_url("/skills.php?whichskill=168&quantity=1&ajax=1&action=Skillz&ref=1&targetplayer=2771003&pwd");
		//visit_url("/fight.php?action=steal", true, false); // pickpocket if able
		//run_combat();
		if (have_effect($effect[Crappily Disguised as a Waiter]) > 0) {
			string savedProperty = get_property("choiceAdventure855");
			set_property("choiceAdventure855", "4");
			adv1($location[The Copperhead Club], 0);
			set_property("choiceAdventure855", savedProperty);
		}
	}
}



void grindMushroomGarden(int choiceNumber) {
	int cropLevel = to_int(get_property("mushroomGardenCropLevel"));
	print("grindMushroomGarden, crop level: " + cropLevel, "green");

	if (cropLevel >= 11) {
		print("auto-picking mushroom", "blue");
		set_property("choiceAdventure1410", "2");
	} else {
		print(choiceNumber == 1 ? "fertilizing mushroom" : "picking mushroom", "blue");
		set_property("choiceAdventure1410", choiceNumber);
	}

	try {
		if (to_int(get_property("_mushroomGardenFights")) >= 1) {
			// we've done the fight but maybe not the choice
			adv1($location[your mushroom garden], 0);
			return;
		}

		automate_dressup($location[your mushroom garden], "10 exp", "default", "mainstat, effective, -equip Kramco Sausage-o-Matic&trade;, -equip \"i voted\" sticker, -equip mafia thumb ring");

		healIfRequiredWithMPRestore();
		adventure(1, $location[your mushroom garden]); // 0 turns, so will auto-follow to the choice and auto-pick the choice
	} finally {
		remove_property("choiceAdventure1410");
	}
}



// get the +10 level goodness
void grind_poke_familiar_items() {
	if (have_item($item[amulet coin]) || have_item($item[luck incense]) || have_item($item[muscle band]) || have_item($item[razor fang]) || have_item($item[shell bell]) || have_item($item[smoke ball]))
		return;

	cli_execute("garden pick");
	while (!have_item($item[amulet coin]) && !have_item($item[luck incense]) && !have_item($item[muscle band]) && !have_item($item[razor fang]) && !have_item($item[shell bell]) && !have_item($item[smoke ball])) {
		use(1, $item[Pok&eacute;-Gro fertilizer]);
		cli_execute("garden pick");
	}
}



// find an existing guzzlr quest and do it, doesn't do special dressup or using items like the platinum- and gold-specific scripts below
void grindGuzzlr(string tweakOutfit) {
	assert(onGuzzlrQuest(), "grindGuzzlr: we're not on a guzzlr quest");

	// GET QUEST LOCATION AND BOOZE
	string boozeString = get_property("guzzlrQuestBooze");
	item boozeToTake;
	if (boozeString == "special personalized cocktail")
		boozeToTake = $item[buttery boy];
	else
		boozeToTake = boozeString.to_item();
	location locationToGoTo = get_property("guzzlrQuestLocation").to_location();
	assert(locationToGoTo != $location[none], "grindGuzzlr: didn't get the location to go to");
	assert(boozeToTake != $item[none], "grindGuzzlr: didn't get the booze to take");

	print("going to " + locationToGoTo + " to give a " + boozeToTake, "green");

	if (item_amount(boozeToTake) == 0)
		if (!fullAcquire(boozeToTake))
			abort("don't have the booze " + boozeToTake + " and couldn't acquire it!");
	assert(item_amount(boozeToTake) > 0, "grindGuzzlr: still don't have booze:" + boozeToTake);

	// DRESSUP
	string selector = "0.1 item";
	string familiarSelector = "default";
	string maxString = fixupCLArtifacts(tweakOutfit);
	if (last_monster() == $monster[sausage goblin]) { // if the last monster is the sausage goblin, use that to get free turns at the guzzlr location
		setCurrentMood("meat");
		if (pocketProfessorLecturesAvailable() > 0)
			familiarSelector = "pocket professor";
		if (pocketProfessorLecturesPossiblyAvailable() > 0)
			selector = "familiar weight";
		maxString = maxStringAppend(maxStringForSausageGoblin() + ", equip backup camera", maxString);
	} else {
		setCurrentMood("+combat");
		maxString = maxStringAppend("0.01 mp regen, +combat 25 max", maxString);
	}

	string testString = maxStringAppend(maxString, maxStringForLocation(locationToGoTo, maxString));
	// guzzlr equipment shoes = less adv, pants = more bucks, hat = more stats
	maxString = maxStringAppendIfPossibleToEquip(testString, $item[Guzzlr shoes]);
	maxString = maxStringAppendIfPossibleToEquip(testString, $item[Guzzlr pants]);
	maxString = maxStringAppendIfPossibleToEquip(testString, $item[Guzzlr hat]);

	automate_dressup(locationToGoTo, selector, familiarSelector, maxString);

	// DO IT
	clearGoals();
	add_item_condition(1, $item[Guzzlrbuck]);
	healIfRequiredWithMPRestore();

	// if last monster is a sausage goblin, grind the backup camera at this location
	if (last_monster() == $monster[sausage goblin]) {
		while (haveGoals() && backupCameraUsesAvailable() > 0) {
			grindBackupCamera(locationToGoTo, 25, $monster[none]);
			selector = "0.1 item";
			familiarSelector = "default";
			automate_dressup(locationToGoTo, selector, familiarSelector, maxString);
		}

	} else if (kTargetableMonstersMap[locationToGoTo] != $monster[none]) {
		monster [] bestTarget = {kTargetableMonstersMap[locationToGoTo]};
		targetMob(locationToGoTo, bestTarget, $skill[none], 25, false, kMaxInt);
	} else {
		healIfRequiredWithMPRestore();
		adventure(25, locationToGoTo); // do not need to redirect as all wandering monsters adv advance the goal
	}
}

void grindGuzzlr() {
	grindGuzzlr("");
}


void grindGuzzlrWithSausageGoblin() {
	if (last_monster() != $monster[sausage goblin])
		abort("sausage goblin was not the last monster!");
	grindGuzzlr("");
}


// check the platinum guzzlr quest, possibly doing it, and then do the 3 gold quests
void grindGoldGuzzlr() {
	string tweakOutfit = "";
	getGuzzlrQuest(3); // gold

	location questLocation = to_location(get_property("guzzlrQuestLocation"));

	if (questLocation == $location[Barrrney's Barrr] || questLocation == $location[The F'c'le] || questLocation == $location[The Poop Deck] || questLocation == $location[Belowdecks]) {
		if (have_item($item[pirate fledges]))
			tweakOutfit = "equip pirate fledges";
		else
			tweakOutfit = "outfit swashbuckling getup";

	} else if (questLocation == $location[8-bit Realm]) {
		tweakOutfit = "equip continuum transfunctioner";

	} else if (questLocation == $location[The Haunted Laboratory]) {
		saveAndSetProperty("choiceAdventure884", "6");

	} else if (questLocation == $location[The Haunted Nursery]) {
		saveAndSetProperty("choiceAdventure885", "6");

	} else if (questLocation == $location[The Spooky Forest]) {
		saveAndSetProperty("choiceAdventure502", "2");
		saveAndSetProperty("choiceAdventure505", "2");

	} else if (questLocation == $location[The Penultimate Fantasy Airship]) {
		saveAndSetProperty("choiceAdventure178", "2");

	} else if (questLocation == $location[The Castle in the Clouds in the Sky (Ground Floor)]) {
		saveAndSetProperty("choiceAdventure647", "3");

	} else if (questLocation == $location[The Castle in the Clouds in the Sky (Top Floor)]) {
		saveAndSetProperty("choiceAdventure677", "2");
		saveAndSetProperty("choiceAdventure678", "3");

	} else if (questLocation == $location[The Haunted Bedroom]) {
		saveAndSetProperty("choiceAdventure876", "1");
		saveAndSetProperty("choiceAdventure878", "4");
		saveAndSetProperty("choiceAdventure879", "2");
		saveAndSetProperty("choiceAdventure880", "2");

	} else if (questLocation == $location[Guano Junction]) {
		saveAndSetProperty("choiceAdventure1427", "2");
	}


	try {
		grindGuzzlr(tweakOutfit);

	} finally {
		if (questLocation == $location[The Haunted Laboratory]) {
			restoreSavedProperty("choiceAdventure884");

		} else if (questLocation == $location[The Haunted Nursery]) {
			restoreSavedProperty("choiceAdventure885");

		} else if (questLocation == $location[The Spooky Forest]) {
			restoreSavedProperty("choiceAdventure502");
			restoreSavedProperty("choiceAdventure505");

		} else if (questLocation == $location[The Penultimate Fantasy Airship]) {
			restoreSavedProperty("choiceAdventure178");

		} else if (questLocation == $location[The Castle in the Clouds in the Sky (Ground Floor)]) {
			restoreSavedProperty("choiceAdventure647");

		} else if (questLocation == $location[The Castle in the Clouds in the Sky (Top Floor)]) {
			restoreSavedProperty("choiceAdventure677");
			restoreSavedProperty("choiceAdventure678");

		} else if (questLocation == $location[The Haunted Bedroom]) {
			restoreSavedProperty("choiceAdventure876");
			restoreSavedProperty("choiceAdventure878");
			restoreSavedProperty("choiceAdventure879");
			restoreSavedProperty("choiceAdventure880");

		} else if (questLocation == $location[Guano Junction]) {
			restoreSavedProperty("choiceAdventure1427");
		}
	}
}


// check the platinum guzzlr quest, possibly doing it
void grindPlatinumGuzzlr() {
	buffer pageText;
	string tweakOutfit = "";

	if ((get_property("questGuzzlr") == "unstarted") && (to_int(get_property("_guzzlrPlatinumDeliveries")) == 0)) {
		getGuzzlrQuest(4); // platinum
	} else {
		if (get_property("guzzlrQuestTier") != "platinum") {
			print("we're in grindPlatinumGuzzlr, but a quest of a different tier is already started! returning", "red");
			return;
		}
	}

	location questLocation = to_location(get_property("guzzlrQuestLocation"));

	cli_execute("prefref guzzlr");
	if (!user_confirm("Cancel platinum location and continue?", 60000, true)) {
		abort("manual platinum location: " + questLocation);
	} else { // cancel the platinum quest and continue
		visit_url("/inventory.php?tap=guzzlr", false, false);
		run_choice(1);
		run_choice(5);
		return;
	}


	// customizations DON'T DO ANY MORE, KEEP THE DAILY ITEM INSTEAD
// 	if (questLocation == $location[Hamburglaris Shield Generator]) {
// 		if (get_property("questF04Elves") != "finished") abort("about to adventure in spaaaace, but we haven't done the quest yet!");
// 		use_if_needed($item[transporter transponder], $effect[Transpondent], max(1, 10 - to_int(get_property("guzzlrDeliveryProgress"))));
// 
// 	} else if (questLocation == $location[The Red Queen's Garden]) {
// 		use_if_needed($item[&quot;DRINK ME&quot; potion], $effect[Down the Rabbit Hole], max(1, 10 - to_int(get_property("guzzlrDeliveryProgress"))));
// 
// 	} else { // default action: cancel the platinum quest and continue, but check with user first
// 		cli_execute("prefref guzzlr");
// 		if (!user_confirm("Cancel platinum location and continue?", 60000, true)) {
// 			abort("manual platinum location: " + questLocation);
// 		} else { // cancel the platinum quest and continue
// 			visit_url("/inventory.php?tap=guzzlr", false, false);
// 			run_choice(1);
// 			return;
// 		}
// 	}
// 
// 	item someBooze = $item[Buttery Boy];
// 	if (!have_item(someBooze) && !fullAcquire(someBooze))
// 		abort("don't have a Buttery Boy and couldn't acquire it!");
// 	print("going to " + questLocation + " to give a " + someBooze, "green");
// 	grindGuzzlr(questLocation, someBooze, tweakOutfit);
// 
// 	if (questLocation == $location[Hamburglaris Shield Generator]) {
// 		print("leaving spaaaaace with " + have_effect($effect[Transpondent]) + " turns of Transpondent remaining. Cancel within 3 seconds...", "blue");
// 		wait(3);
// 	}
}


void grindGoldAndPlatinumGuzzlr() {
	int tries = 3 - to_int(get_property("_guzzlrGoldDeliveries")) + 2;
	while (((to_int(get_property("_guzzlrGoldDeliveries")) < 3 && get_property("questGuzzlr") == "unstarted") || get_property("guzzlrQuestTier") == "gold") && tries > 0) {
		grindGoldGuzzlr();
		tries--;
	}
	if (to_int(get_property("_guzzlrGoldDeliveries")) < 3)
		print("WARNING: " + (3 - to_int(get_property("_guzzlrGoldDeliveries"))) + " gold quest(s) remain undone", "red");

	if (get_property("guzzlrQuestTier") == "platinum" || (to_int(get_property("_guzzlrPlatinumDeliveries")) < 1 && get_property("questGuzzlr") == "unstarted")) {
		grindPlatinumGuzzlr();
	}
	if (to_int(get_property("_guzzlrPlatinumDeliveries")) < 1)
		print("WARNING: platinum quest remains undone", "red");
}



// TODO: complete this...
// CAN ONLY GRIND BEFORE BEATING THE GHOST, i.e. before completing the Spookyraven quests
void grindPoolSkill() {
	setDefaultState();
	setCurrentMood("-combat, meat");
	automate_dressup($location[The Haunted Billiards Room], "-combat", "default", "equip staff of fats");
	if (combat_rate_modifier() > -25) abort("not enough -combat");
}



// use the PSR mechanism. mpCost is actually the turn cost.
PrioritySkillRecord [int] freeCraftingData(item nightcap) {
	PrioritySkillRecord [int] psrArray;
	PrioritySkillRecord tempPSR;
	int kBaseUsesAvailable = 33; // use this to balance between 2 or more items with kBaseUsesAvailable - my_session_items(<my item>);
	int availableFreeCraftTurns = availableFreeCraftTurns();
	int i = 0;

	// nightcap -- skill, item, mpCost, meatCost, priority -- mp cost is the turn cost to create
	tempPSR = new PrioritySkillRecord($skill[none], nightcap, 1, 0, 1);
	tempPSR.usesAvailable = 1 - available_amount(nightcap); // only ever need 1
	tempPSR.isAvailableNow = availableFreeCraftTurns >= tempPSR.mpCost && have_mats(nightcap);
	psrArray[i++] = tempPSR;

	// tempura air -- skill, item, mpCost, meatCost, priority -- mp cost is the turn cost to create
	tempPSR = new PrioritySkillRecord($skill[none], $item[tempura air], 1, 0, 5);
	tempPSR.usesAvailable = 1 - my_session_items($item[tempura air]);
	tempPSR.isAvailableNow = availableFreeCraftTurns >= tempPSR.mpCost && have_mats($item[tempura air]);
	psrArray[i++] = tempPSR;

	// haunted gimlet -- skill, item, mpCost, meatCost, priority -- mp cost is the turn cost to create
	tempPSR = new PrioritySkillRecord($skill[none], $item[haunted gimlet], 3, 0, 11);
	tempPSR.usesAvailable = kBaseUsesAvailable - 11 - my_session_items($item[haunted gimlet]); // will only craft if we have 11 free crafting turns
	tempPSR.isAvailableNow = availableFreeCraftTurns >= tempPSR.mpCost && have_mats($item[haunted gimlet]);
	psrArray[i++] = tempPSR;

	// for use with haunted hell ramen -- skill, item, mpCost, meatCost, priority -- mp cost is the turn cost to create
	tempPSR = new PrioritySkillRecord($skill[none], $item[Hell ramen], 2, 0, 11);
	tempPSR.usesAvailable = kBaseUsesAvailable - my_session_items($item[Hell ramen]);
	tempPSR.isAvailableNow = availableFreeCraftTurns >= tempPSR.mpCost && have_mats($item[Hell ramen]);
	psrArray[i++] = tempPSR;

	// backstop item: create these if nothing else is available, should be 1 turn to create
	tempPSR = new PrioritySkillRecord($skill[none], $item[savory dry noodles], 1, 0, 99);
	tempPSR.usesAvailable = kMaxInt;
	tempPSR.isAvailableNow = availableFreeCraftTurns >= tempPSR.mpCost && have_mats($item[savory dry noodles]);
	psrArray[i++] = tempPSR;

	return psrArray;
}

// use the PSR mechanism. mpCost is actually the turn cost.
PrioritySkillRecord [int] freeCraftingData() {
	return freeCraftingData($item[sangria del diablo]);
}



// spend free crafting turns: milk of magnesium; gloomy mushroom wine; oily mushroom wine;
int [item] burnInigoCrafting() {
	int [item] receipt;
	int inigosCasts = 5 - to_int(get_property("_inigosCasts"));
	int inigosFreeCraftTurns = floor(have_effect($effect[Inigo's Incantation of Inspiration]) / 5.0);
	if (inigosCasts == 0 && inigosFreeCraftTurns == 0) return receipt;
	print("burnInigoCrafting: " + inigosCasts + " casts available, free crafts: " + inigosFreeCraftTurns, "green");

	restore_mp(100 * inigosCasts);
	ensureSongRoom($skill[Inigo's Incantation of Inspiration]);
	if (!use_skill(inigosCasts, $skill[Inigo's Incantation of Inspiration]))
		abort("failed casting inigo's");

	inigosFreeCraftTurns = floor(have_effect($effect[Inigo's Incantation of Inspiration]) / 5.0);
	int tries = inigosFreeCraftTurns + 3;
	while (inigosFreeCraftTurns > 0 && tries > 0) {
		PrioritySkillRecord topPriority = topPriority(freeCraftingData());
		assert(topPriority.theItem != $item[none], "burnInigoCrafting: topPriority returned no item to craft");
		if (create(1, topPriority.theItem))
			receipt[topPriority.theItem]++;
		else
			abort("failed creating " + topPriority.theItem);

		inigosFreeCraftTurns = floor(have_effect($effect[Inigo's Incantation of Inspiration]) / 5.0);
	}

	if (have_effect($effect[Inigo's Incantation of Inspiration]) >= 5)
		abort("exiting burnInigoCrafting with inigo turns to spare!");

	print("items created using Inigos:", "green");
	printReceipt(receipt);
	return receipt;
}


// spend free crafting turns: make milk of magnesium; make gloomy mushroom wine; make oily mushroom wine;
int [item] cutCorners() {
	int [item] receipt;
	int cornersToCut = 5 - to_int(get_property("_expertCornerCutterUsed"));
	if (cornersToCut == 0) return receipt;
	print("cutCorners: " + cornersToCut + " corners to cut", "green");

	int tries = cornersToCut + 3;
	while (cornersToCut > 0 && tries > 0) {
		PrioritySkillRecord topPriority = topPriority(freeCraftingData());
		if (create(1, topPriority.theItem))
			receipt[topPriority.theItem]++;
		else
			abort("failed creating " + topPriority.theItem);
		cornersToCut = 5 - to_int(get_property("_expertCornerCutterUsed"));
	}

	cornersToCut = 5 - to_int(get_property("_expertCornerCutterUsed"));
	if (cornersToCut > 0)
		abort("exiting cutCorners with corners left to cut");

	print("items created using cut corners:", "green");
	printReceipt(receipt);
	return receipt;
}


// spend free crafting turns: make milk of magnesium; make gloomy mushroom wine; make oily mushroom wine;
void burnFreeCrafting() {
	burnInigoCrafting();
	cutCorners();
}



void burn_fortune_teller(string buffString, boolean compatible1, boolean compatible2, boolean compatible3) {
	print("burn_fortune_teller", "green");
	cli_execute("zatara"); // auto-reply to requested consults

	if (!to_boolean(get_property("_clanFortuneBuffUsed"))) {
		print("getting fortune buff: " + buffString);
		cli_execute("fortune buff " + buffString);
	}

	boolean [] compatibleArray = {compatible1, compatible2, compatible3};

	// names with spaces will mess up incompatible fortune-telling
	string [] consults = {
		"CWBot",
		"PeKaJe",
		"infopowerbroker",
		"djve",
		"Weakling",
		"busstop82",
		"bombzar",
		"TheBarracuda",
		"unusualscar",
		"Mhoraigh",
		"nixon66",
		"footrest",
		"Thaz",
		"Aaro",
	};

	int i = 0;
	int consultNumber = 1 + to_int(get_property("_clanFortuneConsultUses"));
	while (consultNumber <= 3 && i <= count(consults)) {
		boolean worked = cli_execute("fortune " + consults[i] + (compatibleArray[consultNumber - 1] ? "" : " unmatchable gibberish blerrrrg")); // COMPATIBLE = "" vs INCOMPATIBLE = something random that won't match anything
		consultNumber = 1 + to_int(get_property("_clanFortuneConsultUses"));
		i++;
	}

	if (to_int(get_property("_clanFortuneConsultUses")) < 3)
		print("WARNING: unused fortune teller consultations", "red");
}



void grindTotCostume(item costume) {
	print("grindTotCostume: " + costume, "green");
	if (have_item(costume)) return;

	setDefaultState();
	ensureSongRoom($skill[Carlweather's Cantata of Confrontation]); 

	// we're going to do a free kill
	string maxString = "-equip mafia thumb ring";

	location advLocation;
	string selector;
	if (costume == $item[li'l ninja costume]) {
		setDefaultMood();
		advLocation = $location[Lair of the Ninja Snowmen];
		selector = "item";
	} else if (costume == $item[li'l pirate costume]) {
		// need to handle non-combats
		setCurrentMood("+combat");
		advLocation = $location[Barrrney's Barrr];
		selector = "+combat";
		if (have_item($item[pirate fledges]))
			maxString += ", equip pirate fledges";
		else
			maxString += ", outfit swashbuckling getup";
	} else
		abort("unknown tot costume");
	maxString = dressForPickpocket(advLocation, maxString);

	string scriptString = "pickpocket; pickpocket; ";
	PrioritySkillRecord instaKillSkill = chooseInstaKillSkill();
	if (instaKillSkill.theSkill != $skill[none]) {
		scriptString += "if " + isMonsterFromLocationScript(advLocation) + "; skill " + instaKillSkill.theSkill + "; endif; abort;";
		if (instaKillSkill.theItem != $item[none])
			maxString += ", equip " + instaKillSkill.theItem;
	} else
		scriptString = "";

	automate_dressup(advLocation, selector, "item", maxString);

	int tries = 3;
	while (tries > 0 && !have_item(costume)) { // in case of wandering monsters
		healIfRequiredWithMPRestore();
		dressup();
		redirectAdventure(advLocation, scriptString);
		run_turn();
		tries--;
	}

	if (available_amount(costume) == 0)
		abort("didn't get tot costume!");
}



void safe_mumming(familiar a_familiar, string mum_buff) {
	if (get_property("_mummeryMods").contains_text(a_familiar))
		print("familiar already has a mumming trunk buff", "red");
	else {
		if (!use_familiar(a_familiar)) abort("unable to switch to familiar");
		boolean unused = cli_execute("mummery " + mum_buff);
	}
}

void applyMummingBuffs() {
	print("applyMummingBuffs", "green");
	familiar old_familiar = my_familiar();
	visit_url("/inv_use.php?which=3&pwd&whichitem=9592", true, false); // prime the pump

	if (my_daycount() == 1) {
		safe_mumming($familiar[Gelatinous Cubeling], "myst"); // extra mys gain
	}

	if (inRonin()) {
		safe_mumming($familiar[Cat Burglar], "item"); // extra mus (and stagger), mys, mox gain, bleed (item)
		safe_mumming($familiar[Hobo Monkey], "meat"); // 1.25x leprechaun; extra mus, mys gain, extra item, meat drop
		safe_mumming($familiar[Garbage Fire], "mp"); // hot dmg (mp)
		safe_mumming($familiar[Robortender], "hp"); // extra mys gain, extra meat drop, extra hp
		if (my_daycount() != 1)
			safe_mumming($familiar[Optimistic Candle], "myst"); // hot dmg (mp), extra mys gain
	} else {
		safe_mumming($familiar[Trick-or-Treating Tot], "item"); // extra meat, item drop, extra mys gain
		safe_mumming($familiar[Robortender], "hp"); // extra mys gain, extra meat drop, extra hp
		safe_mumming($familiar[Hobo Monkey], "meat"); // extra meat drop (and delevel), extra mus gain, extra item, extra mys gain
		safe_mumming($familiar[Space Jellyfish], "mus"); // extra mus gain
		safe_mumming($familiar[Chocolate Lab], "mox"); // extra mus, mys gain

		if(to_int(get_property("garbageFireProgress")) / 30 > kPersueFamiliarIfOver)
			safe_mumming($familiar[Garbage Fire], "mp"); // hot dmg (mp)
		else
			safe_mumming($familiar[Cat Burglar], "mp");

		if(to_int(get_property("optimisticCandleProgress")) / 30 > kPersueFamiliarIfOver)
			safe_mumming($familiar[Optimistic Candle], "myst"); // hot dmg (mp), extra mys gain
	}

	if (!use_familiar(old_familiar)) abort("unable to switch back to original familiar");
}



void buyShelfSpecials() {
	print("buyShelfSpecials", "green");
	if (to_boolean(get_property(ShelfSpecialsPurchasedKey)))
		return;

	int startingMeat = my_meat();
	int [item, int] buy_map;
	

	buySpecials(buy_map);
	set_property(ShelfSpecialsPurchasedKey, "true");
}


void buyMallSpecials() {
	print("buyMallSpecials", "green");
	if (to_boolean(get_property(MallSpecialsPurchasedKey)))
		return;

	int [item, int] buy_map;
	file_to_map("unrestricted_buy_map.txt", buy_map);

	buySpecials(buy_map);
	set_property(MallSpecialsPurchasedKey, "true");
}



void timespinner_prank(string playerName) {
	if (to_int(get_property("_timeSpinnerMinutesUsed")) >= 10) return;
	cli_execute("timespinner prank " + playerName + " msg=Tequila!");
}

void burn_timespinner_pranks() {
	print("burn_timespinner_pranks", "green");
	string [int] pranks = {
		1:"cyberdyne",
		2:"PeKaJe",
		3:"djve",
		4:"infopowerbroker",
		5:"busstop82",
		6:"Weakling",
		7:"TheBarracuda",
		8:"llubgnuoy",
		9:"beljeferon",
		10:"bombzar",
		11:"dragonfrog",
		12:"nixon66"
	};

	for i from 1 to count(pranks) {
		if (to_int(get_property("_timeSpinnerMinutesUsed")) >= 10) return;
		timespinner_prank(pranks[i]);
	}
}

void burn_timespinner_fights() {
	print("burn_timespinner_fights", "green");
	setDefaultMood();

	if (to_int(get_property("_timeSpinnerMinutesUsed")) >= 10) return;

	// lower stats for Krakrox!!
	cli_execute("mcd 0");
	cli_execute("uneffect ode");
	buffIfNeededWithUneffect($skill[Jackasses' Symphony of Destruction], 11);
	burnMP();

	clear_automate_dressup();
	dressup($location[none], "0.1 hp", "default", "-mys, -mus, -mox, -ml, 0.1 mp, -equip wristwatch of the white knight");

	for i from 1 to 11 - to_int(get_property("_timeSpinnerMinutesUsed")) {
		healIfRequiredWithMPRestore();
		visit_url("/inv_use.php?which=3&pwd&whichitem=9104&ajax=1", true, false);
		run_choice(3);
	}
}

void burn_timespinner() {
	if (to_int(get_property("_timeSpinnerMinutesUsed")) >= 10) return;
	burn_timespinner_pranks();
	burn_timespinner_fights();
}


// fight a photocopied monster. 
// first, if putFax is true, will send our current fax
// if we have one in our inv already, will fight that, otherwise will get a fax first and then fight it
// finally, will get a fax and leave it in our inv for tomorrow
void burnFax(boolean putFax) {
	assert(!get_property("_photocopyUsed").to_boolean(), "fax already burned");
	print("burnFax: current photocopy: " + get_property("photocopyMonster") + ", put fax first: " + putFax, "green");
	assert(!putFax || have_item($item[photocopied monster]), "we don't have a fax to put");

	if (putFax)
		cli_execute("fax put");

	if (item_amount($item[photocopied monster]) == 0)
		cli_execute("fax get");

	monster monsterToFight = get_property("photocopyMonster").to_monster();

	// dress up
	string selector = "item";
	string familiarSelector = "item";
	string maxString;
	if (!cllHasReminiscence(monsterToFight))
		maxString = "equip combat lover's locket";

	if (roboEconomicsForMonster(monsterToFight) >= 3333) { // TODO figure out benefit from other fams
		familiarSelector = "robortender";
	}
	automate_dressup($location[none], selector, familiarSelector, maxString);

	healIfRequiredWithMPRestore();
	anyAdventure(new AdventureRecord($location[none], $skill[none], $item[photocopied monster]));

	cli_execute("fax get");
}



// burn all remaining genie wishes using wish, stopping if we encounter the goal item
void burnGenieWishes(item goalItem, string wish) {
	int genieWishesPossible = 3 - to_int(get_property("_genieWishesUsed"));

	// figure the meat gain per wish
	boolean willCombat = !wish.contains_text("pony");
	monster fightMon = wish.to_monster();
	int monsterMeatValue = monsterCurrentTotalMeatValue(fightMon);
	int meatWishValue = min(50000, my_level() * 500);

	print("burnGenieWishes, wishes to make: " + genieWishesPossible + ", wish: '" + wish + "', stopping on goal item: " + goalItem, "green");
	if (genieWishesPossible == 0) return;

	int startingGoalAmount = 0;
	if (willCombat) {
		assert(fightMon != $monster[none], "wish should resolve to a monster");
		if (monsterMeatValue < meatWishValue && !user_confirm("About to wish a monster worth " + monsterMeatValue + ", but we can just wish meat worth " + meatWishValue + ". Continue?", 60000, true))
			abort("user aborted");

		if (goalItem != $item[none]) {
			startingGoalAmount = my_session_items(goalItem);
			if (startingGoalAmount > 0 && !user_confirm("We already got at least one " + goalItem + ". Continue to wish for another " + fightMon + "?", 60000, true))
				abort("user aborted");
		}
	}

	// compose wish string
	string genie_string = "monster " + wish;
	if (!willCombat)
		genie_string = "item pony";

	while (genieWishesPossible > 0 && (goalItem == $item[none] || my_session_items(goalItem) <= startingGoalAmount)) {
		print("wishing for: " + genie_string);
		cli_execute("genie " + genie_string);
		if (willCombat) {
			visit_url("/main.php", true, false); // get to the fight
			run_combat();
		}

		genieWishesPossible--;
	}

	if (to_int(get_property("_genieWishesUsed")) < 3)
		print("WARNING: unused genie wishes", "red");
}



// costs min 200 meat for the bricks and ~1600 meat for the eye -- doesn't seem worth it
void burn_bricko_fights(item bricko_monster) {
	print("burn_bricko_fights", "green");
	int brickoFightsPossible = 10 - to_int(get_property("_brickoFights"));

	fullAcquire(bricko_monster);
	while (brickoFightsPossible > 0 && have_item(bricko_monster)) {
		print("fighting: " + bricko_monster);
		cli_execute("use " + bricko_monster);
		visit_url("/main.php", true, false); // get to the fight
		visit_url("/fight.php?action=steal", true, false); // pickpocket if able
		run_combat();

		brickoFightsPossible--;
	}
}

void burn_bricko_fights() {
	burn_bricko_fights($item[BRICKO ooze]);
}


void burn_kgb(string buff_to_get) {
	print("burn_kgb", "green");
	effect [string] buff_map = {
		"meat":$effect[A View to Some Meat],
		"item":$effect[Items Are Forever]
	};

	int kgbClicksUsed = to_int(get_property("_kgbClicksUsed"));
	int kgb_buffs_possible = (27 - kgbClicksUsed) / 3;

	string buff_string = "briefcase buff " + buff_to_get;
	string alt_buff_string = "briefcase buff ";
	if (buff_to_get == "item")
		alt_buff_string += "meat";
	else
		alt_buff_string += "item";

	for i from 1 to kgb_buffs_possible {
		if (have_effect(buff_map[buff_to_get]) < 500)
			cli_execute(buff_string);
		else
			cli_execute(alt_buff_string);
	}
}



// where "free" = no turns
void burnFreeDaycare() {
	print("burnFreeDaycare", "blue");

	burnScavengeDaycare(0); // spend 0 turns scavenging

	int toddlerRecruits = to_int(get_property("_daycareRecruits"));
	print("recruiting toddlers... " + get_property("daycareToddlers") + " toddlers before recruiting", "blue");
	while (toddlerRecruits < 2) {
		daycareRecruit();
		toddlerRecruits = to_int(get_property("_daycareRecruits"));
	}
	print(get_property("daycareToddlers") + " toddlers after recruiting");
}


// burn mana, maximize mp, use license to chill, then burnHP and burnMP
// burnAmount is any value accepted by burnMP/burn, use kMinInt to save all mana
void burnLicenseToChill(int burnAmount) {
	if (!to_boolean(get_property("_licenseToChillUsed"))) {
		burnMP(0);
		maximize("mp", false);

		use(1, $item[license to chill]);

		burnInigoCrafting();
		burnHP();
		burnMP(burnAmount);
	}
}

void burnLicenseToChill() {
	burnLicenseToChill(gUnrestrictedManaToSave);
}



// where "free" means less than the current value of kTurnValue
void burnFreeTurnGen() {
	print("burnFreeTurnGen", "green");
	if (!to_boolean(get_property(MallSpecialsPurchasedKey))) {
		item [class] classItemMap = {
			$class[seal clubber]:$item[chocolate seal-clubbing club],
			$class[turtle tamer]:$item[chocolate turtle totem],
			$class[pastamancer]:$item[chocolate pasta spoon],
			$class[sauceror]:$item[chocolate saucepan],
			$class[disco bandit]:$item[chocolate disco ball],
			$class[accordion thief]:$item[chocolate stolen accordion]
		};

		int kChocolatesToEat = 2;
		if (available_amount(classItemMap[my_class()]) < kChocolatesToEat)
			buy(kChocolatesToEat, classItemMap[my_class()]);
		int chocolateToEat = kChocolatesToEat - to_int(get_property("_chocolatesUsed"));
		use(chocolateToEat, classItemMap[my_class()]);

		//use(1, $item[etched hourglass]); // looks like it is being done as part of breakfast

		// burn mana, maximize mp, and use license to chill only if we aren't doing fernswarthy
		// in which case, save for later use in fernswarthy
		if (fernswarthy_level() <= 1) {
			burnLicenseToChill();
		}
	}
}


void printPottedPowerPlant() {
	visit_url("/inv_use.php?pwd&which=3&whichitem=10738", true, false);
	string plantStatus = get_property("_pottedPowerPlant");
	print("\npotted power plant: " + plantStatus, "red");
	if (plantStatus.contains_text("6")) {
		print("************* WARNING: potted power plant ready for harvest ****************\n", "red");
		print("************* WARNING: potted power plant ready for harvest ****************\n", "red");
		print("************* WARNING: potted power plant ready for harvest ****************\n", "red");
		wait(15);
	}
}



// sets up for and then prints basic daily info that might be relevant to the current daily run
void printDailyInfo(int [location] endGameTurnsSpent) {
	cli_execute("inv baconstone; inv hamethyst");
	print("today's daily special: " + daily_special());

	printEffectDescription($effect[Blessing of the bird]);
	printEffectDescription($effect[Blessing of your favorite Bird]);

	// display bounties in case we want one
	cli_execute("bounty");
	printFloundrySpots();
	cli_execute("cheapest affirmation cookie");
	if (have_item($item[Love Potion #0]))
		print_description($item[Love Potion #0]);
	else
		print("drank love potion");

	float dreadsylvaniaCompletion = endGameTurnsSpent[$location[Dreadsylvanian Woods]] / 10;
	float hobopolisCompletion = hobopolisCompletion(endGameTurnsSpent);
	if (dreadsylvaniaCompletion < 75 || hobopolisCompletion < 75) {
		if (!have_item($item[maple magnet]) && !get_property("_smm.BuyMapleMagnetWarningDone").to_boolean()
			&& user_confirm("Dreadsylvanian Woods " + dreadsylvaniaCompletion
				+ "% complete, Hobopolis " + hobopolisCompletion + "% complete -- buy maple magnet?", 60000, false)) {
			fullAcquire($item[maple magnet]);
		}
		set_property("_smm.BuyMapleMagnetWarningDone", true);
	}

	printPottedPowerPlant();
}



void defaultZap() {
	if (to_int(get_property("_zapCount")) > 0) {
		print("skipping zap, already zapped", "blue");
		return;
	}

	item zapItem = $item[baconstone];
	if (available_amount($item[hamethyst]) > available_amount($item[baconstone]))
		zapItem = $item[hamethyst];

	checkIfRunningOut(zapItem, 50);
	boolean unused = cli_execute("zap " + zapItem);
}



// all the setup for items
void setupItems() {
	print("setupItems", "green");
	boolean unused;

	if (!to_boolean(get_property("_timeSpinnerReplicatorUsed"))) {
		equip($slot[weapon], $item[none]); // ensure we aren't wearing anything that would mess with FarFuture
		cli_execute("FarFuture memory");
	}

	if (!have_item($item[pantogram pants])) {
		fullAcquire($item[bubblin' crude]);
		fullAcquire($item[porquoise]);
		fullAcquire($item[ten-leaf clover]);
		summon_pants("sleaze", "mp regen 2", "meat drop 2", "hilarity"); // bubblin' crude, porquoise, ten-leaf clover
	}

	// mod the Cosplay sabre 
	if (get_property("_saberMod") == "0") {
		visit_url("main.php?action=may4");
		visit_url("choice.php?pwd&whichchoice=1386&option=4"); // +10 fam weight
// 		visit_url("choice.php?pwd&whichchoice=1386&option=3"); // +3 all res
	}

	if (item_amount($item[runed taper candle]) == 0)
		buy($item[oversized sparkler]);
	fullAcquire(1, gkFishyGearToGet);

	if (item_amount($item[soap knife]) > 0)
		put_closet(item_amount($item[soap knife]), $item[soap knife]);
	use_skill($skill[That's Not a Knife]);

	if (!inRonin())
		voteInVotingBooth();

	cli_execute("briefcase collect");

	//buy(1, $item[game grid token]);
	visit_url("/place.php?whichplace=arcade&action=arcade_plumber", false, false); // can get a random game token?

	// use quest items
	use(available_amount($item[fisherman's sack]), $item[fisherman's sack]);

	// do this after license to chill in case we get free buff turns
	if (!get_property("_bastilleGamesLockedIn").to_boolean()
		&& (have_effect($effect[Shark-Tooth Grin]) > gkBastilleBuffAmount - 3
		|| have_effect($effect[Boiling Determination]) > gkBastilleBuffAmount - 3
		|| have_effect($effect[Enhanced Interrogation]) > gkBastilleBuffAmount - 3)) {
		use_if_needed($item[sharkfin gumbo], $effect[Shark-Tooth Grin], gkBastilleBuffAmount);
		use_if_needed($item[boiling broth], $effect[Boiling Determination], gkBastilleBuffAmount);
		use_if_needed($item[interrogative elixir], $effect[Enhanced Interrogation], gkBastilleBuffAmount);
		unused = cli_execute("basty win");
	} else if (to_boolean(get_property("_bastilleGamesLockedIn")) == false && to_int(get_property("_bastilleGames")) < 5 && (have_effect($effect[Shark-Tooth Grin]) > 0 || have_effect($effect[boiling determination]) > 0 || have_effect($effect[enhanced interrogation]) > 0))
		print("have bastille buffs but not enough", "red");

	use(1, $item[Bird-a-Day calendar]);

	defaultZap();
}



// TODO Jingle Bells TT buff bot buff
void secondBreakfast(int [location] endGameTurnsSpent) {
	boolean unused;

	cli_execute("breakfast");

	setUpMood();
	setDefaultBoombox();
	setupItems();
	if (!inRonin()) { // setup the default outfit
		dressup($location[none], "item", "item", "");
		saveOutfit(kDefaultOutfit);
	}

	if (have_mushroom_plot())
		cli_execute("planting/auto_mushroom.ash");

	burnFreeDaycare();
	applyMummingBuffs();

	burnFreeTurnGen();

	// STUFF THAT COSTS MANA AFTER THIS -- these first ones cost lots of mana
	if (my_basestat($stat[moxie]) >= 133) { // 150 minus some to allow for stat gains and wearing later in the day
		use_skill(1, $skill[Ceci N'Est Pas Un Chapeau]);
		assert(have_item($item[no hat]), "didn't get no hat!");
	}
	burnInigoCrafting();

	if (have_skill($skill[canticle of carboloading])) {
		use_skill(1, $skill[canticle of carboloading]);
	}

	healIfRequiredWithMPRestore();
	use_skill(1, $skill[blood blade]);
	use_skill(1, $skill[blood blade]);

	// free combats that have no stat to max or other considerations
	burnMP();

	buyMallSpecials();

	set_property("_smm.SecondBreakfastDone", "true");

	printDailyInfo(endGameTurnsSpent);
}

void secondBreakfast() {
	secondBreakfast(endGameTurnsSpent());
}



void dailyDeedsAdv() {
	restore_mp(20);
	grindTotCostume($item[li'l pirate costume]);
	grindTotCostume($item[li'l ninja costume]);

	if (my_garden_type() == "grass") // means we're using the tall grass garden
		grind_poke_familiar_items();
}



int totalSausagesToMake() {
// 	int sausagesToMake = kSausagesToEat + 2;
// 	sausagesToMake = min(sausagesToMake, get_property("_sausageFights").to_int() + 11); // right now we have a lot of spare sausages, save casings
// 	fullAcquire(sausagesToMake, $item[magical sausage casing]);
// 	return min(sausagesToMake, available_amount($item[magical sausage casing]));
	return 25;
}

int sausagesToMake() {
	// want to make (collected casings - 2) sausages each day
	// int sausagesToMake = (kSausagesToGet - 2) - to_int(get_property("_sausagesMade"));
	// sausagesToMake = min(sausagesToMake, to_int(get_property("_sausageFights")) - 2);

	// we're now getting more than 23 (which is the max eatable/day), make all 23 plus some extra for the display case
	return totalSausagesToMake() - to_int(get_property("_sausagesMade"));
}

// return the number of sausages we can theoretically eat if we had the sausages
// if doNotOvereat is true, will limit the number returned to a number that won't make us overeat
int sausagesToEat(boolean doNotOvereat) {
	int sausagesToEat = 23 - to_int(get_property("_sausagesEaten"));
	if (doNotOvereat) { // make sure we don't eat so much that we lose adv at rollover
		int adventuresAtRollover = myAdventuresAtRollover();
		return min(sausagesToEat, 200 - adventuresAtRollover);
	} else
		return sausagesToEat;
}

int sausagesToEat() {
	return sausagesToEat(false);
}



// Pending Turns Record
record PendingTurnsRecord {
	int turns;
	string desc;
};

// potential number of turns that could be spent while drunk
int drunkTurnsPending(boolean shouldPrint) {
	int kTimespinnerTricks = 3; // TODO better guesstimate
	PendingTurnsRecord [int] pts;
	int idx = 0;
	pts[idx++] = new PendingTurnsRecord(3 - to_int(get_property("_genieWishesUsed")), "genie bottle");
	pts[idx++] = new PendingTurnsRecord(to_boolean(get_property("_photocopyUsed")) ? 0 : 1, "fax");
	pts[idx++] = new PendingTurnsRecord(max(10 - kTimespinnerTricks - to_int(get_property("_timeSpinnerMinutesUsed")), 0), "timespinner fights"); // guesstimate of the number of turns that will be used tricking people TODO better guesstimate
	pts[idx++] = new PendingTurnsRecord(to_int(get_property("_daycareGymScavenges")) > 2 ? 0 : to_int(get_property("_daycareGymScavenges")) > 1 ? 2 : 3, "boxing daycare scavenging");
	pts[idx++] = new PendingTurnsRecord(3 - cllNumMonstersFought(), "combat lover's locket reminiscences");

	int totalPendingTurns;
	string outputString;
	foreach idx, pt in pts {
		outputString += pt.turns + " turns for " + pt.desc + ", ";
		totalPendingTurns += pt.turns;
	}

	if (shouldPrint)
		print(outputString + " TOTAL PENDING TURNS: " + totalPendingTurns);
	return totalPendingTurns;
}

int drunkTurnsPending() {
	return drunkTurnsPending(true);
}


// if fillToMax is false, will only use (presumably larger sized) spleen items that are optimal in terms of cost per adv_turns, which may result in unused spleen.
// if fillToMax is true, will also use enough smaller-sized spleen items to fill spleen to max.
void tquillaFillSpleen(boolean fillToMax) {
	chew(floor((spleen_limit() - my_spleen_use()) / kSpleenItem.spleen), kSpleenItem);
	if (spleen_limit() - my_spleen_use() >= kSpleenItem.spleen) abort("something wrong with spleen");
	if (fillToMax) {
		chew(spleen_limit() - my_spleen_use(), kFillerSpleenItem);
	}
}


// TODO Affirmation Cookie??
void tquillaEat(int numberToEat, boolean refillSpleen) {
	// sanity checks
	assert(gkFoodItem != $item[none], "no food item");
	assert(numberToEat >= 1, "not eating " + numberToEat + "X " + gkFoodItem);
	assert(fullness_limit() - my_fullness() >= gkFoodItem.fullness, "we're too full, you're going to have to eat manually");
	assert(my_spleen_use() >= gkEatSpleenReduction, "not enough spleen use!");

	abort("do manually");

	numberToEat = min(numberToEat, floor((fullness_limit() - my_fullness()) / to_float(gkFoodItem.fullness)));
	numberToEat = min(numberToEat, floor(my_spleen_use() / to_float(gkEatSpleenReduction)));

	assert(retrieve_item(numberToEat, $item[Special Seasoning]), "couldn't retrieve enough Special Seasoning");
	assert(numberToEat > 0, "tquillaEat: we should never get here -- should be caught be previous assertions");

	useMoMifNeeded();
	if (gkPreeatItem != $item[none])
		eat(numberToEat, gkPreeatItem);
	eat(numberToEat, gkFoodItem);

	if (refillSpleen)
		tquillaFillSpleen(false);
}

void tquillaEat(boolean refillSpleen) {
	tquillaEat(1, refillSpleen);
}


// TODO less than 5 drunkenness free
void tquillaDrink(int numberToDrink, boolean refillSpleen) {
	// sanity checks
	int myLimit = inebriety_limit();
	if (my_familiar() == $familiar[Stooper]) myLimit--;
	assert(gkDrinkItem != $item[none], "no drink item");
	assert(myLimit - my_inebriety() >= gkDrinkItem.inebriety, "we're too drunk, you're going to have to drink manually");
	assert(my_spleen_use() >= gkDrinkItemSpleenReduction, "not enough spleen use!");
	assert(gkDrinkItem != $item[Sacramento wine] || have_effect($effect[Refined Palate]) > 0, "need Refined Palate");

	numberToDrink = min(numberToDrink, floor((inebriety_limit() - my_inebriety()) / to_float(gkDrinkItem.inebriety)));
	numberToDrink = min(numberToDrink, floor(my_spleen_use() / to_float(gkDrinkItemSpleenReduction)));

	if (numberToDrink == 0) abort("we should never get here");

	restore_mp(mp_cost($skill[The Ode to Booze]));
	useOdeToBoozeIfNeeded(gkDrinkItem.inebriety);
	if (gkPredrinkItem != $item[none])
		drink(numberToDrink, gkPredrinkItem);
	drink(numberToDrink, gkDrinkItem);

	if (refillSpleen)
		tquillaFillSpleen(false);
}

void tquillaDrink(boolean refillSpleen) {
	tquillaDrink(1, refillSpleen);
}



void tquillaOverdrink(boolean refillSpleen, boolean luckyIfNeeded) {
	// sanity checks
	int myLimit = inebriety_limit();
	if (my_familiar() == $familiar[Stooper]) myLimit--;
	assert(gkOverdrinkDrinkItem != $item[none], "no overdrink item");
	assert(gkStooperDrink != $item[none], "no stooper drink item");
	assert(my_inebriety() == myLimit, "we should be at our inebriety limit or 1 away from it if we are using Stooper");
	assert(my_fullness() == fullness_limit(), "we should be full before overdrinking, but we only have " + my_fullness() + " used of " + fullness_limit());
	assert(my_spleen_use() >= 5, "overdrinking will get rid of 5 spleen, but we only have " + my_spleen_use() + " spleen used");

	int kDrinkItemSize = gkOverdrinkDrinkItem.inebriety + gkStooperDrink.inebriety;

	int drunkTurnsPending = drunkTurnsPending(false);

	saveOutfit();
	try {
		if (to_int(get_property("_gingerbreadCityTurns")) == 0) {
			printGingerbreadLeaderboard();
			if (!user_confirm("Gingerbread city not done... continue to overdrink?", 60000, true))
				abort("user aborted");
		}

		restore_mp(mp_cost($skill[The Ode to Booze]));
		if (!useOdeToBoozeIfNeeded(kDrinkItemSize))
			abort("didn't get enough ode to booze");

		// STOOPER DRINK
		use_familiar($familiar[stooper]);
		while (my_inebriety() == inebriety_limit() - 1) {// haven't done stooper yet -- use a "while" in case there are free 1-sized drinks available
// 			if (luckyIfNeeded && to_int(get_property("_speakeasyDrinksDrunk")) < 3 && !semirareKnown() && !hippy_stone_broken())
// 				cli_execute("drink lucky lindy"); // drink() doesn't work
// 			else
				drink(1, gkStooperDrink);
		}

		// OVERDRINK
		assert(my_familiar() == $familiar[Stooper] && my_inebriety() == inebriety_limit(), "tquillaOverdrink: we should have the Stooper familiar and be at our inebriety limit");

		if (gkPreoverdrinkItem != $item[none])
			drink(1, gkPreoverdrinkItem); // stuff like frosty's frosty mug
		overdrink(1, gkOverdrinkDrinkItem);

		// ST. SNEAKY PETE'S DAY
		if (isSneakyPeteDay()) {
			assert(my_inebriety() == inebriety_limit() + 1 + gkOverdrinkDrinkItem.inebriety, "tquillaOverdrink: we're not at the right inebriety for St. Sneaky Pete's Day");
			int extraBeer = 10 - (inebriety_limit() - my_inebriety());
			fullAcquire(extraBeer, $item[green beer]);
			overdrink(extraBeer, $item[green beer]);
		}

		if (refillSpleen)
			tquillaFillSpleen(true);
	} finally {
		restoreOutfit(true);
	}
}



// given the current state of consumption (fullness, drunkenness, spleen), return the ideal
// number of adv to start end-of-day consumption so as to end near but not over 200 adv at rollover
// target is 5-10 advs shy of 200 to allow for variations in end-of-day consumption gain
// ideally the difference will be made up with magical sausages to reach exactly 200 adv tomorrow
int idealAdvToOverdrink() {
	if (!readyToOverdrink(true)) abort("we're not ready to overdrink");

	int drunkTurnsSpent = drunkTurnsPending(true);

	int pixieStickGains = round(1.88 * (gkOverdrinkSpleenReduction + spleen_limit() - my_spleen_use()));

	int foodGains = 0; // TODO
	int drinkGains = 0; // TODO
	int stooperGains = (stooperPending() ? 7 : 0);
	int overdrinkGains = gkOverdrinkDrinkItem.inebriety * 6 * 1;
	int sneakyPeteGains = isSneakyPeteDay() ? (2 * (10 - 1 - gkOverdrinkDrinkItem.inebriety)) : 0;
	int spleenGains = pixieStickGains;
	int licenseToChillGains = to_boolean(get_property("_licenseToChillUsed")) ? 0 : 5;
	int rolloverGains = adventureGainAtRollover(true);

	int totalGains = stooperGains + overdrinkGains + sneakyPeteGains + spleenGains + licenseToChillGains + rolloverGains;

	int sausageGains = sausagesToEat(true);

	print("stooper gains: " + stooperGains
		+ ", overdrink gains: " + overdrinkGains
		+ (isSneakyPeteDay() ? ", Sneaky Pete gains: " + sneakyPeteGains : "")
		+ ", spleen gains: " + spleenGains
		+ ", license to chill gains: " + licenseToChillGains
		+ ", rollover gains: " + rolloverGains
		);
	print("TOTAL GAINS (not including sausage): " + totalGains);
	print("GAINS - PENDING = " + (totalGains - drunkTurnsSpent) + ", sausage gains: " + sausageGains);

	int rval = 200 - totalGains + drunkTurnsSpent;
	print("IDEAL ADV TO OVERDRINK AT: " + rval + " with " + sausageGains + " extra turns available from sausages -- ideal is " + (rval - sausageGains) + " if all sausages are eaten after overdrinking");

	return rval;
}



// -------------------------------------
// AUTOMATION -- GRINDING -- CLASS
// -------------------------------------

void grindSeal(item sealFigurine) {
	healIfRequiredWithMPRestore();
	visit_url("/inv_use.php?checked=1&pwd&whichitem=" + to_int(sealFigurine), true, false);
	run_combat("skill Lunging Thrust-Smack;");
}

void grindSeals(item sealFigurine) {
	int [item] FigurineToCandlesMap = {
		$item[figurine of an ancient seal]:3,
		$item[figurine of a sleek seal]:3
	};

	burnMP();
	setDefaultMood();
	automate_dressup($location[none], "item", "default", "+club, -equip Kramco Sausage-o-Matic&trade;, -equip \"i voted\" sticker");

	// sanity checks
	if (sealFigurine == $item[figurine of a sleek seal] || item_drop_modifier() < 186) abort("not enough item drop to guarantee 35% drop");

	int baseSealSummons = 5;
	if (have_item($item[Claw of the Infernal Seal])) baseSealSummons += 5;
	int sealsToSummon = baseSealSummons - to_int(get_property("_sealsSummoned"));

	int candlesToBuy = FigurineToCandlesMap[sealFigurine] * sealsToSummon;
	fullAcquire(candlesToBuy, $item[seal-blubber candle]);

	while (sealsToSummon > 0 && sealFigurine != $item[none]) {
		grindSeal(sealFigurine);
		sealsToSummon--;
	}
}



// -------------------------------------
// AUTOMATION -- GRINDING -- IOTM
// -------------------------------------

void burnGodLobster() {
	int glFightsAvailable = 3 - to_int(get_property("_godLobsterFights"));
	if (glFightsAvailable == 0) return;
	print("burnGodLobster, " + glFightsAvailable + " fights available", "green");

	cli_execute("GodLobster outfit");

	while (glFightsAvailable > 0 && !have_item($item[God Lobster's Crown])) {
		cli_execute("GodLobster regalia");
		glFightsAvailable = 3 - to_int(get_property("_godLobsterFights"));
	}

	if (glFightsAvailable > 0)
		cli_execute("GodLobster " + glFightsAvailable + " xp");

// 	if (glFightsAvailable > 0)
// 		cli_execute("GodLobster outfit");
// 
// 	while (glFightsAvailable > 0) {
// 		restore_mp(5 * mp_cost($skill[Saucegeyser]) + mp_cost($skill[Cannelloni Cocoon]) + mp_cost($skill[Tongue of the Walrus]));
// 		healIfRequiredWithMPRestore();
// 
// 		if (have_item($item[God Lobster's Crown]))
// 			cli_execute("GodLobster xp");
// 		else
// 			cli_execute("GodLobster regalia");
// 
// 		glFightsAvailable = 3 - to_int(get_property("_godLobsterFights"));
// 	}
}



void getCampAwayBuff() {
	visit_url("/place.php?whichplace=campaway&action=campaway_sky", true, false);
}

void burnCampAwayBuffs() {
	print("burnCampAwayBuffs", "green");
	int numberToDo = 4 - to_int(get_property("_campAwayCloudBuffs")) - to_int(get_property("_campAwaySmileBuffs"));
	if (numberToDo > 0)
		for i from 1 to numberToDo {
			getCampAwayBuff();
		}
}



// TODO conditional-ize this to make it faster
void burnBuffs() {
	burn_kgb("item");
	burn_fortune_teller("item", true, true, false);
	burnCampAwayBuffs();

	boolean unused = cli_execute("friars familiar");
	unused = cli_execute("telescope high");
	unused = cli_execute("use fishy pipe");
	unused = cli_execute("monorail"); // favoured by Lyle
	unused = cli_execute("mom stats");
	unused = cli_execute("swim laps");
	unused = cli_execute("ballpit");
	unused = cli_execute("pool aggressive, strategic, stylish");
	unused = cli_execute("shower cold");
	unused = cli_execute("spacegate vaccine 3");
	unused = cli_execute("cast incredible self-esteem");
	unused = cli_execute("daycare mysticality");
	unused = cli_execute("use circle drum");

	use_skill(3, $skill[Feel Disappointed]);
	use_skill(3, $skill[Feel Excitement]);
	use_skill(3, $skill[Feel Nervous]);
	use_skill(3, $skill[Feel Peaceful]);
}



void burnNuns() {
	print("burnNuns", "green");
	int do_it = 3 - to_int(get_property("nunsVisits"));
	maximize("mp", false);
	while (do_it > 0) {
		do_it--;
		burnMP(0);
		boolean unused = cli_execute("nuns");
	}
	burnMP();
}



void burnFreeRests() {
	print("burnFreeRests", "green");
	int do_it = total_free_rests() - to_int(get_property("timesRested"));
	burnMP();
	while (do_it > 0) {
		do_it--;
		cli_execute("camp rest");
	}
}



void burnFreeMP() {
	print("burnFreeMP", "green");

	maximize("mp", false);

	boolean eternalCarBatteryUsed = to_boolean(get_property("_eternalCarBatteryUsed"));
	int nunsVisitsAvailable = 3 - to_int(get_property("nunsVisits"));
	if (!to_boolean(get_property("sidequestNunsCompleted"))) nunsVisitsAvailable = 0;
	int campRestsAvailable = total_free_rests() - to_int(get_property("timesRested"));

	int tries = 3;
	while ((nunsVisitsAvailable > 0 || campRestsAvailable > 0 || !eternalCarBatteryUsed) && tries > 0) {
		while (nunsVisitsAvailable > 0 && my_maxmp() - my_mp() >= 1000) {
			nunsVisitsAvailable--;
			cli_execute("nuns");
			tries = 3;
		}

		while (campRestsAvailable > 0 && my_maxmp() - my_mp() >= 160) {
			campRestsAvailable--;
			cli_execute("camp rest");
			tries = 3;
		}

		if (!eternalCarBatteryUsed && my_maxmp() - my_mp() >= 55) {
			eternalCarBatteryUsed = use(1, $item[eternal car battery]);
			tries = 3;
		}

		burnMP(gUnrestrictedManaToSave);
		tries--;
	}
}



void burnSpleen() {
	print("burnSpleen", "green");
	// if i'm both overdrunk and the hippy stone is broken, don't burn spleen items: we're about to ascend
	if (!isOverdrunk() || !hippy_stone_broken()) {
		int spleenAvailable = spleen_limit() - my_spleen_use();
		//chew(spleenAvailable, $item[Knob Goblin pet-buffing spray]);
		chew(floor(spleenAvailable / 4.0), $item[agua de vida]);
		spleenAvailable = spleen_limit() - my_spleen_use();
		if (spleenAvailable > 0) print("WARNING: spleen available!!!!!!!!!!!!!!!!!!!!", "red");
	}
}



// should be called while overdrunk after dressing for rollover
// handles making up to 46 sausages
void burn_sausages(boolean doNotOvereat) {
	saveOutfit();
	int sausagesToMake = sausagesToMake();
	int sausagesToEat = sausagesToEat(true);
	int startingSausagesToEat = sausagesToEat;
	print("burn_sausages: doNotOvereat: " + doNotOvereat + ", making: " + sausagesToMake + ", eating: " + sausagesToEat, "green");

	try {
		// FIRST MAKE SAUSAGES
		if (sausagesToMake > 0)
			if (!cli_execute("make " + sausagesToMake + " magical sausage"))
				abort("failed while MAKING sausages");

		// try to work around the user confirmation
// 		set_property("_sausagesMade", "0");
// 
// 		int sausagesMade = 0;
// 		int tries = 0;
// 		while (sausagesToMake > 0 || tries < 10) {
// 			if (sausagesToMake > kMaxSausagesToEat)
// 				sausagesToMake = kMaxSausagesToEat;
// 
// 			if (!cli_execute("make " + sausagesToMake + " magical sausage"))
// 				abort("failed while MAKING sausages");
// 			sausagesMade += to_int(get_property("_sausagesMade"));
// 			sausagesToMake = kSausagesToMake - sausagesMade;
// 
// 			set_property("_sausagesMade", "0");
// 			tries++;
// 		}
// 		set_property("_sausagesMade", sausagesMade + kSausagesPreviouslyMade);

		// THEN EAT SAUSAGES
		int adventuresAtRollover = myAdventuresAtRollover();
		if (sausagesToEat > 0 && !(isOverdrunk() && hippy_stone_broken())) { // if i'm both overdrunk and the hippy stone is broken, don't burn sausages: we're about to ascend
			maximize("mp", false);
			while (sausagesToEat > 0) {
				if (my_mp() + 999 > my_maxmp())
					burnMP(0);
				if (cli_execute("eat magical sausage"))
					sausagesToEat--;
				else
					abort("failed while EATING sausages");
			}

		} else if (sausagesToEat > 0) {
			print("NOT EATING sausages due to being overdrunk AND in PVP (which usually means we're about to ascend, so no reason for extra turns)", "orange");
		}

	} finally {
		burnMP();
		if (!restoreOutfit(true))
			print("burn_sausages: COULD NOT RESTORE EQUIPPED SET!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!", "red");
		print((startingSausagesToEat - sausagesToEat) + " sausages eaten, total eaten: " + get_property("_sausagesEaten") + " of 23", "green");
	}
}

void burn_sausages() {
	burn_sausages(true);
}



// fightMons is an ordered list of monsters we want to fight with the combat lover's locket
// TODO
void burnCombatLoversLocket(monster fightMon) {
	if (3 - cllNumMonstersFought() <= 0) return;

	advURL("/inventory.php?reminisce=1");
	visit_url("/choice.php?whichchoice=1463&pwd&option=1&mid=" + fightMon.to_int(), true, false);
	run_combat();
	postAdventure();
}

// fight the default monsters
void burnCombatLoversLocket() {
	setCurrentMood("meat");

	// mer-kin baker for mer-kin rolling pin
	automate_dressup($location[none], "item", "robortender", "0.5 meat");
	burnCombatLoversLocket($monster[mer-kin baker]);

	// crimbylow
	automate_dressup($location[none], "item", "robortender", "0.5 meat");
	burnCombatLoversLocket($monster[crimbylow]);

	// gingerbread maw
	automate_dressup($location[none], "item", "robortender", "0.5 meat");
	burnCombatLoversLocket($monster[gingerbread maw]);

	// Knob Goblin Embezzler meat
// 	automate_dressup($location[none], "meat", "meat", "0.1 item");
// 	burnCombatLoversLocket($monster[Knob Goblin Embezzler]);

	// ice conceirge for bag of foreign bribes
// 	automate_dressup($location[none], "item", "item", "0.1 meat");
// 	burnCombatLoversLocket($monster[ice concierge]);

	// swarm of scarab beatles for mojo filter
// 	automate_dressup($location[none], "item", "item", "0.1 meat");
// 	burnCombatLoversLocket($monster[swarm of scarab beatles]);
}



void beforeOverdrunkGoodNight() {
	print("dolphinItem: " + get_property("dolphinItem"), "green");
	if (get_property("dolphinItem") != "" && !to_boolean(get_property("_smm.ShouldUseDolphinWhistleQueryDone")) && user_confirm("Use dolphin whistle for dolphinItem: " + get_property("dolphinItem") + ", price: " + mall_price(to_item(get_property("dolphinItem"))), 60000, false)) {
		cli_execute("use dolphin whistle");
	}
	set_property("_smm.ShouldUseDolphinWhistleQueryDone", "true");

	grindMushroomGarden(1); // 1=fertilize (will auto-pick on max growth)
}


// can be and should generally be done when overdrunk, but not required
void good_night_adv() {
	burn_timespinner();

	healIfRequiredWithMPRestore();
	//burnGenieWishes($item[bag of foreign bribes], "ice concierge"); // get ponies for now if we don't otherwise use it
	burnScavengeDaycare(3);
	burnCombatLoversLocket();

	//burnBrokenChampagneBottle(); // may want to save until tomorrow so we can use +item from LOV tunnel, etc?

	if (my_class() == $class[seal clubber])
		grindSeals($item[figurine of an ancient seal]);
}


// burn free turns granted from items/skills
// can be used overdrunk if we're able to get into a combat while overdrunk (such as with drum machines)
void burnInstaKills() {
	print("burnInstaKills", "green");
	PrioritySkillRecord instaKillSkill = chooseInstaKillSkill();

	if (instaKillSkill.theSkill == $skill[none]) {
		print("no insta-kill skills left", "blue");
		return;
	}
	if (my_adventures() == 0)
		abort("we have insta-kills but we can't insta-kill without any turns!");

	if (instaKillSkill.theSkill != $skill[none])
		automate_dressup($location[none], "item", "item", "-equip \"i voted\" sticker");
	int tries = 3;
	while (instaKillSkill.theSkill != $skill[none] && tries > 0) {
		if (instaKillSkill.theItem != $item[none]) {
			fullAcquire(instaKillSkill.theItem);
			dressup("equip " + instaKillSkill.theItem);
		}
		fullAcquire($item[drum machine]);
		advURL("/inv_use.php?pwd&which=3&whichitem=2328", true, false);
		run_combat("pickpocket; pickpocket; skill " + instaKillSkill.theSkill); postAdventure();
		instaKillSkill = chooseInstaKillSkill();
	}
}



// burn all 0-turn combats: science, tentacle, god lobster, glitch season reward, mushroom garden
void burnFreeCombats() {
	print("burnFreeCombats", "green");

	grindGlitchSeasonReward();
	burnGodLobster();
	grindScience(false); // use synthesis?
// 	grindMushroomGarden(1); // this must be run when not overdrunk, but we don't know if we're ascending yet, so don't normally run it here
}



void burnFreeUseItems() {
	boolean unused;

	burnGenieWishes($item[none], "pony");
	burnGenieWishes($item[none], "pony");
	burnGenieWishes($item[none], "pony");

	int combs = 11 - get_property("_freeBeachWalksUsed").to_int();
	unused = cli_execute("combo " + combs);
	burnLicenseToChill();
}



// returns a string that can be passed to maximize to dressup for most boss fights
// currently maximizes xp by equipping the makeshift garbage shirt if it's available
// and excludes pickpocket-enabling items from being equipped (as bosses don't need to be pickpocketed usually)
string defaultDressupStringForBossFight(string maxString) {
	string rval = "";

	// bosses give lots of xp
// 	if (!wantsToNotEquip(maxString, $item[makeshift garbage shirt]) && to_int(get_property("garbageShirtCharge")) > 0)
	rval = maxStringAppend(rval, "exp");

	// bosses almost never have pickpocketable items
	if (!wantsToEquip(maxString, $item[mime army infiltration glove]))
		rval = maxStringAppend(rval, "-equip mime army infiltration glove");
	if (!wantsToEquip(maxString, $item[tiny black hole]))
		rval = maxStringAppend(rval, "-equip tiny black hole");

	// don't redirect to vote monster
	if (!wantsToEquip(maxString, $item[&quot;I Voted!&quot; sticker]))
		rval = maxStringAppend(rval, "-equip \"i voted\" sticker");

	// don't get sausage goblins
	if (!wantsToEquip(maxString, $item[Kramco Sausage-o-Matic&trade;]))
		rval = maxStringAppend(rval, "-equip Kramco Sausage-o-Matic&trade;");

	// don't use aerogel attache case
	if (!wantsToEquip(maxString, $item[aerogel attache case]))
		rval = maxStringAppend(rval, "-equip aerogel attache case");

	// don't use pantogram pants
	if (!wantsToEquip(maxString, $item[pantogram pants]))
		rval = maxStringAppend(rval, "-equip pantogram pants");

	return maxStringAppend(maxString, rval);
}


void bossFight(location aLocation, string additionalEquipment, string familiarSelector) {
	string maxString = additionalEquipment.replace_string("|", ",");

// 	clear_automate_dressup();
// 	chooseFamiliar(familiarSelector);
// 	maxString = maxStringAppend(maxString, defaultDressupStringForBossFight(additionalEquipment));
// 	maximize(maxStringAppend("mainstat", maxString), false);
	automate_dressup(aLocation, "mainstat", familiarSelector, defaultDressupStringForBossFight(maxString));

	healToMaxWithMPRestore();
}

void bossFight() {
	bossFight($location[none], "", "fight");
}


void bossMonster(monster whichBoss) {
	if (whichBoss == $monster[The Big Wisniewski]) {
		bossFight(mysterious_island_camp("hippy"), "outfit frat warrior fatigues, hp, dr", "default");

	// Beelzebozo
	} else if (whichBoss == $monster[The Clownlord Beelzebozo]) {
		setCurrentMood("-combat");
		burnMP();
		bossFight($location[The "Fun" House], "clownosity 4 min, -500 combat", "default");
		if (numeric_modifier("Clowniness") < 4) abort("clowniness is not at 4!");
		if (combat_rate_modifier() > -25) abort("combat is not at -25%!");

	// amorphous blob -- low stats and hp and kill with spells
	} else if (whichBoss == $monster[amorphous blob]) {
		setDefaultMood();
		bossFight($location[none], "-ml, -hp", "mosquito");
		print("strat: low stats and hp and kill with spells", "blue");

	// default
	} else
		bossFight($location[none], "", "fight");

	healToMaxWithMPRestore();
}



// -------------------------------------
// AUTOMATION -- GRINDING -- IOTM
// -------------------------------------

// TODO do first before grinding scarab beatles, use red-nosed snapper to track undead (sheet ghost), check others for tracking possibility
void grindGhostCostume() {
	if (to_boolean(get_property("_smm.GotGhostCostume")) || banishesAvailable(kMaxInt) == 0) {
		print("grindGhostCostume: already got it or not enough banishers", "green");
		return;
	}
	print("grindGhostCostume", "green");

	monster [] target;
	cli_execute("refresh inv");

	// STEP 3
	if (have_effect($effect[Invisibly Ripped]) > 0 || have_item($item[invisible seam ripper])) {
		print("STEP 3: getting li'l ghost costume from sheet ghost @ The Haunted Storage Room", "green");
		clearGoals();
		setDefaultState();
		if (have_item($item[invisible seam ripper]))
			use(1, $item[invisible seam ripper]);

		automate_dressup($location[The Haunted Storage Room], "item", "default", "item");

		try {
			target = {$monster[sheet ghost]};
			add_item_condition(1, $item[li'l ghost costume]);
			while (have_effect($effect[Invisibly Ripped]) > 0) {
				targetMob($location[The Haunted Storage Room], target, $skill[none], 1, true, kMaxInt); // optimal, max banisher cost
			}
		} finally {
			if (my_session_items($item[li'l ghost costume]) == 0)
				abort("didn't get ghost costume!");
			else
				set_property("_smm.GotGhostCostume", "true");
			return;
		}

	// STEP 2 -- DO NOT WANT +combat!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	} else if (have_effect($effect[Invisible Ties]) > 0 || have_item($item[invisible string])) {
		print("STEP 2: getting invisible seam ripper from Ninja Snowman Weaponmaster @ Lair of the Ninja Snowmen", "green");
		setDefaultState();
		setCurrentMood("-combat");
		if (have_item($item[invisible string]))
			use(1, $item[invisible string]);

		automate_dressup($location[Lair of the Ninja Snowmen], "-combat", "default", "item");
// 		assert(-combat < -25, "");
		target = {$monster[Ninja Snowman Weaponmaster]};
		while (!have_item($item[invisible seam ripper]) && have_effect($effect[Invisible Ties]) > 0) {
			targetMob($location[Lair of the Ninja Snowmen], target, $skill[none], 1, true, kMaxInt); // optimal, max banisher cost
			cli_execute("refresh inv");
		}
		if (!have_item($item[invisible seam ripper]))
			abort("don't have invisible seam ripper");
		use(1, $item[invisible seam ripper]);
		grindGhostCostume();
		return;

	// STEP 1
	} else {
		print("STEP 1: getting invisible string from plaid ghost @ The Haunted Laundry Room", "green");
		setDefaultState();
		automate_dressup($location[The Haunted Laundry Room], "item", "default", "item");

		target = {$monster[plaid ghost]};
		int tries = 6 + 3; // highest number of turns i've seen, plus an extra 3
		while (!have_item($item[invisible string]) && tries > 0) {
			targetMob($location[The Haunted Laundry Room], target, $skill[none], 1, true, kMaxInt); // optimal, max banisher cost
			cli_execute("refresh inv");
			tries--;
		}
		if (!have_item($item[invisible string]))
			abort("don't have invisible string");
		grindGhostCostume();
		return;
	}
}



void grindJelly(item jellyType, int numberToGet) {
	int maxTurnsToBurn = 30;

	clearGoals();
	add_item_condition(numberToGet, jellyType);

	// burn the LOV potion if we haven't already
	if (have_item($item[Love Potion #0])) use(1, $item[Love Potion #0]); // TODO: make this more general, look for specific buffs

	if (jellyType == $item[stench jelly]) {
		set_location(mysterious_island_camp("hippy"));
		cli_execute("mood current, meat");
		automate_dressup(my_location(), "item", "space jellyfish", "");
	} else if (jellyType == $item[sleaze jelly]) {
		set_location(mysterious_island_camp("frat"));
		cli_execute("mood current, +combat, meat");
		automate_dressup(my_location(), "+combat", "space jellyfish", "0.1 item");
	}

	healIfRequiredWithMPRestore();
	adventure(maxTurnsToBurn, my_location(), default_sub());
}


void grindJelly(item jellyType) {
	int numberToGet = 5;
	numberToGet = numberToGet - to_int(get_property("_spaceJellyfishDrops"));
	print("getting " + numberToGet + " " + jellyType);
	if (numberToGet > 0)
		grindJelly(jellyType, numberToGet);
}



void grindJellyWithEnemyReplacement(boolean usePowerglove, boolean useMacro, item jellyType, boolean zeroTurns) {
	print("grindJellyWithEnemyReplacement", "green");
	int kMinimumGoalJellies = 3;
	int jelliesDropped = to_int(get_property("_spaceJellyfishDrops"));
	if (jelliesDropped >= kMinimumGoalJellies) return;

	string maxString = ", equip familiar scrapbook, -equip Kramco Sausage-o-Matic&trade;, -equip \"i voted\" sticker, -equip mafia thumb ring";
	if (usePowerglove) maxString += ", +equip Powerful Glove";
	if (!zeroTurns) maxString += ", -equip mafia thumb ring"; // only wear if we DON'T banish

	if (jellyType == $item[stench jelly]) {
		set_location(mysterious_island_camp("hippy"));
		setCurrentMood("meat");
		automate_dressup(my_location(), "item", "space jellyfish", "+combat" + maxString);
	} else if (jellyType == $item[sleaze jelly]) {
		set_location(mysterious_island_camp("frat"));
		setCurrentMood("+combat, meat");
		automate_dressup(my_location(), "+combat", "space jellyfish", "0.1 item" + maxString);
	}

	PrioritySkillRecord instaKillSkill = chooseInstaKillSkill();
	if (instaKillSkill.theSkill != $skill[none]) {
		if (instaKillSkill.theItem != $item[none])
			dressup("equip " + instaKillSkill.theItem);
	}

	healIfRequiredWithMPRestore();

	int macroUsesAvailable = 10 - to_int(get_property("_macrometeoriteUses"));
	int gloveUsesAvailable = 10 - ceil(to_int(get_property("_powerfulGloveBatteryPowerUsed")) / 10.0);
	int tries = 3;
	while (jelliesDropped < kMinimumGoalJellies && (macroUsesAvailable > 0 || gloveUsesAvailable > 0) && tries > 0) {
		string page = advURLWithWanderingMonsterRedirect(my_location());
		if (handling_choice())
			run_choice(-1);
		else if (!contains_monster(my_location(), last_monster())) // wandering monster
			run_combat();
		else {
			string theScript = pickpocket_sub();
			if (usePowerglove && gloveUsesAvailable > 0)
				theScript += "sub pgMain;if !times " + gloveUsesAvailable + ";skill extract jelly;skill CHEAT CODE: Replace Enemy;call pgMain;endif;endsub;call pgMain;";
			executeScript(theScript);

			if (useMacro && macroUsesAvailable > 0)
				theScript = "sub macroMain;if !times " + min(macroUsesAvailable, 13 - gloveUsesAvailable) + ";skill extract jelly;skill Macrometeorite;call macroMain;endif;endsub;call macroMain;";
			theScript += "skill extract jelly;";

			if (zeroTurns && instaKillSkill.theSkill != $skill[none])
				theScript += "skill " + instaKillSkill.theSkill;
			else
				theScript += "attack;repeat;"; // attack until dead

			executeScript(theScript);
		}

		tries--;
		jelliesDropped = to_int(get_property("_spaceJellyfishDrops"));
		macroUsesAvailable = 10 - to_int(get_property("_macrometeoriteUses"));
		gloveUsesAvailable = 10 - ceil(to_int(get_property("_powerfulGloveBatteryPowerUsed")) / 10.0);
	}
}




// NOT suitable for leaderboarding
// will overwrite applicable choiceAdventure settings and then reset them to empty
void grindGingerbread(boolean takeShortcut, boolean adventureAfterMidnight, boolean progressBlackmail) {
	set_property("choiceAdventure1209", "2"); // IF we go to upscale at midnight:
	set_property("choiceAdventure1214", "2"); // chocolate sculpture (+3 adventures)

	try {
		// these increase stats, and therefore xp
		boolean unused = cli_execute("mom stats");
		unused = cli_execute("spacegate vaccine 2");
		unused = cli_execute("ballpit");

		setDefaultMood(); setDefaultBoombox();
		string familiarString = "";
		if (familiar_weight($familiar[chocolate lab]) < 20) {
			use_familiar($familiar[chocolate lab]);
			unused = cli_execute("friars familiar");
		}
		else
			familiarString = "default";
		automate_dressup($location[Gingerbread Industrial Zone], "10 mainstat", familiarString, "5 item, sprinkles, +equip makeshift garbage shirt");
		healIfRequiredWithMPRestore();

		// SHORTCUT
		int turnsUsed = effectiveGingerbreadCityTurns();
		if (turnsUsed == 0 && takeShortcut) {
			set_property("choiceAdventure1215", "1"); // set the clock forward
			adv1($location[Gingerbread Civic Center], 0, "");
		}

		// MORNING
		turnsUsed = effectiveGingerbreadCityTurns();
		while (turnsUsed < 9) {
			redirectAdventure($location[Gingerbread Industrial Zone], 9 - turnsUsed);
			turnsUsed = effectiveGingerbreadCityTurns();
		}

		// NOON
		turnsUsed = effectiveGingerbreadCityTurns();
		if (turnsUsed == 9) {
			if (progressBlackmail && to_int(get_property("gingerLawChoice")) >= 3 && !have_item($item[teethpick])) {
				set_property("choiceAdventure1206", "4"); // buy teethpick
				adv1($location[Gingerbread Industrial Zone], -1, "");
			} else if (progressBlackmail && have_item($item[fruit-leather negatives])) {
				set_property("choiceAdventure1208", "8"); // retail district: drop off negatives -- gingerPhotoTaken=true???
				adv1($location[Gingerbread Upscale Retail District], -1, "");
			} else if (progressBlackmail && to_boolean(get_property("gingerNegativesDropped")) && !to_boolean(get_property("gingerBlackmailAccomplished")) && !have_item($item[gingerbread blackmail photos])) {
			//} else if (progressBlackmail && to_boolean(get_property("gingerNegativesGiven")) && !to_boolean(get_property("gingerBlackmailAccomplished")) && !have_item($item[gingerbread blackmail photos])) {
				set_property("choiceAdventure1208", "8"); // retail district: pick up photos
				adv1($location[Gingerbread Upscale Retail District], -1, "");
			} else if (progressBlackmail && have_item($item[gingerbread blackmail photos])) {
				set_property("choiceAdventure1202", "4"); // civic center: blackmail
				adv1($location[Gingerbread Civic Center], -1, "");
			} else if (progressBlackmail) {
				set_property("choiceAdventure1208", "1"); // retail district: gingerbread dog treat
				adv1($location[Gingerbread Upscale Retail District], -1, "");
			} else { // default
				// retail district: pumpkin spice candle which allows getting broken chocolate pocketwatch
				//set_property("choiceAdventure1208", "2");
				//adv1($location[Gingerbread Upscale Retail District], -1, "");

				// retail district: gingerbread dog treat (139k meat)
				set_property("choiceAdventure1208", "1");
				adv1($location[Gingerbread Upscale Retail District], -1, "");
			}
		}

		// AFTERNOON/EVENING
		turnsUsed = effectiveGingerbreadCityTurns();
		while (turnsUsed >= 10 && turnsUsed < 19) {
			redirectAdventure($location[Gingerbread Industrial Zone], 19 - turnsUsed);
			turnsUsed = effectiveGingerbreadCityTurns();
		}

		// MIDNIGHT
		turnsUsed = effectiveGingerbreadCityTurns();
		if (turnsUsed == 19) {
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
					set_property("choiceAdventure1207", "2");
					set_property("choiceAdventure1213", "1");
					adv1($location[Gingerbread Industrial Zone], -1, "");
				}
			}
		}

		// AFTER MIDNIGHT
		turnsUsed = effectiveGingerbreadCityTurns();
		if (turnsUsed >= 20 && adventureAfterMidnight)
			redirectAdventure($location[Gingerbread Industrial Zone], 15);
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
		automate_dressup($location[Gingerbread Upscale Retail District], "", "chocolate lab", "sprinkles, +equip candy dog collar");

		useMoMifNeeded();
		cli_execute("beach head Do I Know You From Somewhere?");
		if (fullness_limit() - my_fullness() >= 4 && have_effect($effect[Sprinkle in Your Eye]) == 0 && have_effect($effect[Sprinkle Sense]) == 0) {
			eat(1, $item[animal part cracker]);
			buy(1, $item[green-iced sweet roll]);
			eat(1, $item[green-iced sweet roll]);
		}
		fullAcquire($item[gingerbread restraining order]);
		buy(3, $item[tainted icing]);
		use_if_needed($item[tainted icing], $effect[Iced and Tainted], 30 - turnsUsed);

		// MORNING
		healIfRequiredWithMPRestore();
		while (turnsUsed < 9) {
			adventure(9 - turnsUsed, $location[Gingerbread Upscale Retail District]);
			turnsUsed = effectiveGingerbreadCityTurns();
		}

		// NOON
		turnsUsed = effectiveGingerbreadCityTurns();
		healIfRequiredWithMPRestore();
		if (turnsUsed == 9) {
			adv1($location[Gingerbread Train Station], 0);
		}

		// AFTERNOON/EVENING
		turnsUsed = effectiveGingerbreadCityTurns();
		healIfRequiredWithMPRestore();
		while (turnsUsed >= 10 && turnsUsed < 19) {
			adventure(19 - turnsUsed, $location[Gingerbread Sewers]);
			turnsUsed = effectiveGingerbreadCityTurns();
		}

		// MIDNIGHT
		turnsUsed = effectiveGingerbreadCityTurns();
		healIfRequiredWithMPRestore();
		if (turnsUsed == 19) {
			adventure(1, $location[Gingerbread Upscale Retail District]);
		}

		// AFTER MIDNIGHT
		turnsUsed = effectiveGingerbreadCityTurns();
		healIfRequiredWithMPRestore();
		if (turnsUsed >= 20)
			adventure(15, $location[Gingerbread Sewers]);
	} finally {
		remove_property("choiceAdventure1204");
		remove_property("choiceAdventure1209");
	}
}


// NOTE: copying doesn't work!
void winSprinkles(int maxMeatCostPerBuffPercent) {
	boolean unused;
	printGingerbreadLeaderboard();
	int turnsUsed = effectiveGingerbreadCityTurns();
	int buffTurnsNeeded = 30 - effectiveGingerbreadCityTurns();

	// DRESS UP
	if (turnsUsed == 0) {
		setDefaultState();
		maximize("sprinkles, switch chocolate lab", false);
	}
	maximize("sprinkles, switch chocolate lab", false); // first maximize might set up a different environment in which a second maximize might make different choices

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
	print("Sprinkle in Your Eye: 1x animal part cracker@" + mall_price($item[animal part cracker]) + " OR 1x gingerbread wine@" + mall_price($item[gingerbread wine]) + ", CHOOSING: " + sprinkleInYourEyeItem + "@" + sprinkleInYourEyeCost + "/buff percent", "green");

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
	int sprinkleSenseAmount = sprinkleSenseItem == $item[green-iced sweet roll] ? 1 : 3;
	int sprinkleSenseCost = ((mall_price(sprinkleSenseItem) * sprinkleSenseAmount) + sprinkleSenseOpportunityCost) / 30;
	print("Sprinkle Sense: 1x green-iced sweet roll@" + mall_price($item[green-iced sweet roll]) + " OR 3x green rock candy@" + (3 * mall_price($item[green rock candy])) + ", CHOOSING: " + sprinkleSenseItem + "@" + sprinkleSenseCost + "/buff percent", "green");

	analyzeItem($item[gingerbread restraining order], 10, 1, 0);

	// FAMILIAR WEIGHT BUFFS
	AnalyzeRecord [item] itemsToAnalyze = {
		sprinkleInYourEyeItem: new AnalyzeRecord(50, true, 1, sprinkleInYourEyeOpportunityCost, $effect[Sprinkle in Your Eye]),
		sprinkleSenseItem: new AnalyzeRecord(50, true, sprinkleSenseAmount, sprinkleSenseOpportunityCost, $effect[Sprinkle Sense]),
		$item[recording of chorale of companionship]: new AnalyzeRecord(10, true, 2, 0, $effect[Chorale of Companionship]),
		$item[gene tonic: fish]: new AnalyzeRecord(10, true, 1, 0, $effect[Human-Fish Hybrid]),
		$item[resolution: be kinder]: new AnalyzeRecord(5, true, 2, 0, $effect[Kindly Resolve]),
		$item[green snowcone]: new AnalyzeRecord(5, true, 2, 0, $effect[Green Tongue]),
		$item[abstraction: joy]: new AnalyzeRecord(10, true, 1, 1 * kTurnsPerSpleen * kTurnValue, $effect[Joy]),
		$item[gingerbread spice latte]: new AnalyzeRecord(10, true, 1, 0, $effect[Whole Latte Love]),
		$item[daily affirmation: work for hours a week]: new AnalyzeRecord(5, true, 1, 0, $effect[Work For Hours a Week]),
		$item[Gene Tonic: Construct]: new AnalyzeRecord(5, true, 1, 0, $effect[Human-Machine Hybrid]),
		$item[shrimp cocktail]: new AnalyzeRecord(5, true, 2, 0, $effect[Shrimpin' Ain't Easy]),
		$item[gleaming oyster egg]: new AnalyzeRecord(5, true, 1, 1 * kTurnsPerSpleen * kTurnValue, $effect[Gleam-Inducing]),
		$item[stephen's secret formula]: new AnalyzeRecord(10, true, 2, 0, $effect[Spookyravin']),
		$item[dog ointment]: new AnalyzeRecord(10, true, 2, 0, $effect[Unbarking Dogs]),
		$item[Party-in-a-Can&trade;]: new AnalyzeRecord(5, true, 1, 1 * kTurnsPerSpleen * kTurnValue, $effect[Party on Your Skin]),
		$item[Amnesiac Ale]: new AnalyzeRecord(10, true, 1, 2 * 3 * kTurnValue, $effect[All Is Forgiven]),
		$item[cuppa Loyal tea]: new AnalyzeRecord(5, true, 1, 0, $effect[Loyal Tea]),
		$item[Hot Socks]: new AnalyzeRecord(10, true, 1, (3 * 3 * kTurnValue) + 5000, $effect[[1701]Hip to the Jive]),
		$item[disintegrating spiky collar]: new AnalyzeRecord(5, true, 3, 0, $effect[Man's Worst Enemy]),
	};

	item [int] sortArray;
	int ctr = 0;
	foreach it in itemsToAnalyze {
		sortArray[ctr] = it;
		ctr += 1;
	}
	sort sortArray by analyzeItem(value, itemsToAnalyze[value].buffAmount, ceil(buffTurnsNeeded.to_float() / itemsToAnalyze[value].duration), itemsToAnalyze[value].opportunityCost);

	// CHOOSE BUFFS TO USE
	int totalBuffs;
	int totalCost;
	foreach idx, anItem in sortArray {
		int costPerBuffPercent = analyzeItem(anItem, itemsToAnalyze[anItem].buffAmount, itemsToAnalyze[anItem].duration, itemsToAnalyze[anItem].opportunityCost);
		string colour;
		if (costPerBuffPercent <= maxMeatCostPerBuffPercent) {
			colour = "green";
			totalBuffs += itemsToAnalyze[anItem].buffAmount;
			totalCost += costPerBuffPercent * itemsToAnalyze[anItem].buffAmount;
		} else {
			colour = "blue";
		}
		print(anItem + "@" + costPerBuffPercent + "/buff percentage", colour);
	}

	if (totalBuffs == 0)
		abort("no buffs were chosen, try raising maxMeatCostPerBuffPercent");
	print("Sprinkle Drop bonus: " + numeric_modifier("Sprinkle Drop") + "%", "blue");
	print("total cost: " + totalCost + ", total buff: " + totalBuffs + "%, total cost per buff percent: " + (totalCost / totalBuffs), "blue");
	print("VS gain from winning: " + mall_price($item[my life of crime, a memoir]), "blue");

	// BUFF UP
	if (buffTurnsNeeded == 30) { // only do this the first time through
		if (!user_confirm("Proceed under the following circumstances?\ntotal buff cost: " + totalCost + ", total buff: " + totalBuffs + "%, total cost per buff percent: " + (totalCost / totalBuffs) + " meat\nturn cost: " + (kTurnValue * 30) + " -- TOTAL COST: " + (totalCost + (kTurnValue * 30)) + "\nVS gain from winning: " + mall_price($item[my life of crime, a memoir]), 60000, false))
			abort();

		// ONE-OFF BUFFS
		unused = cli_execute_if_needed("beach head Do I Know You From Somewhere?", $effect[Do I Know You From Somewhere?], buffTurnsNeeded);
		unused = cli_execute_if_needed("pool aggressive", $effect[Billiards Belligerence], buffTurnsNeeded);
		unused = cli_execute_if_needed("fortune buff familiar", $effect[A Girl named Sue], buffTurnsNeeded);
		if (!to_boolean(get_property("_madTeaParty")))
			unused = cli_execute_if_needed("hatter 24", $effect[You Can Really Taste the Dormouse], buffTurnsNeeded);

		// ACQUIRE AND CONSUME ITEMS
		foreach idx, anItem in sortArray {
			int costPerBuffPercent = analyzeItem(anItem, itemsToAnalyze[anItem].buffAmount, itemsToAnalyze[anItem].duration, itemsToAnalyze[anItem].opportunityCost);
			if (costPerBuffPercent <= maxMeatCostPerBuffPercent) {
				if (!fullAcquire(ceil(buffTurnsNeeded.to_float() / itemsToAnalyze[anItem].duration), anItem)) {
					abort("could not acquire consumable: " + anItem);
				}
				consumeIfNeededWithUneffect(anItem, itemsToAnalyze[anItem].theEffect, buffTurnsNeeded);
			}
		}
	}

	print("Total Sprinkle Drop bonus: " + numeric_modifier("Sprinkle Drop") + "%", "blue");

	// ADVENTURE!
	// MORNING
	while (turnsUsed < 9) {
		healIfRequiredWithMPRestore();
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
		healIfRequiredWithMPRestore();
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
		healIfRequiredWithMPRestore();
		adventure(1, $location[Gingerbread Sewers]);
		turnsUsed = effectiveGingerbreadCityTurns();
		if (last_monster() == $monster[gingerbread alligator])
			abort("try copying alligator!");
	}

	printGingerbreadLeaderboard();
}



boolean checkLOVprepStats(boolean shouldAbort) {
	boolean isError = false;
	string errorString = "";

	if (my_buffedstat($stat[moxie]) - monster_level_adjustment() < my_buffedstat($stat[muscle]) * 1.1) {
		isError = true;
		errorString += "check monster level (muscle * 1.1 &gt; mox - ml). ";
	}
	if (my_buffedstat($stat[mysticality]) < my_buffedstat($stat[moxie]) * 0.8) {
		isError = true;
		errorString += "mysticality &lt; moxie * 0.8. ";
	}
	if (equipped_item($slot[weapon]) == $item[none]) {
		isError = true;
		errorString += "no weapon! ";
	}

	if (isError && shouldAbort)
		abort("aborting due to incorrect LOV stats: " + errorString);

	return !isError;
}

// preps for the lov tunnel, returns true if it successfully burnt all mana, false otherwise
boolean LOVprep() {
	boolean unused;
	float ml_mod = -5;
	float mus_mod = -1;
	float mys_mod;
	float mox_mod;

	change_mcd(0);
	setDefaultMood();
	cli_execute("uneffect arrowsmith, sonata, cantata, ur-kel");
	buffIfNeededWithUneffect($skill[The Magical Mojomuscular Melody]);
	if (my_class() == $class[pastamancer] && have_skill($skill[Dismiss Pasta Thrall])) // TODO detect specific thrall that causes a problem
		use_skill($skill[Dismiss Pasta Thrall]);

	string maxString = "-familiar, -melee, pickpocket chance, init";
	if (!have_item($item[broken champagne bottle]) || to_int(get_property("garbageChampagneCharge")) == 0) {
		maxString += ", +equip makeshift garbage shirt";
		if (to_int(get_property("garbageShirtCharge")) < 3)
			cli_execute("tote 5");
	}

	burnMP();
	use_familiar($familiar[space jellyfish]);
	cli_execute("equip space jellybicycle");

	if (my_primestat() == $stat[moxie]) {
		mys_mod = 2;
		mox_mod = 1;
		if (my_class() == $class[accordion thief]) {
			//maxString += ", +outfit Master Squeezeboxer";
		} else {
			maxString += ", +equip aerogel attache case"; // gives +pickpocket and cocktail mat drops
		}
	} else if (my_primestat() == $stat[muscle]) {
		buffIfNeededWithUneffect($skill[Disco Smirk]);
		mus_mod = -5;
		mys_mod = 3;
		mox_mod = 6;
		if (my_basestat($stat[moxie]) >= 200)
			maxString += ", +equip mime army infiltration glove, +equip aerogel attache case";
		else
			maxString += ", +equip tiny black hole";
	} else {
		buffIfNeededWithUneffect($skill[Disco Smirk]);
		mys_mod = 1;
		mox_mod = 3;
		if (my_basestat($stat[moxie]) >= 200)
			maxString += ", +equip mime army infiltration glove, +equip aerogel attache case";
		else
			maxString += ", +equip tiny black hole";
	}

	int tries = 0;
	clear_automate_dressup();
	repeat {
		tries++;
		string temp_maxString = maxString + ", " + mys_mod + " mys, " + mus_mod + " mus, " + mox_mod + " mox, " + ml_mod + " ml";
		maximize(temp_maxString, false);

		if (my_buffedstat($stat[mysticality]) < my_buffedstat($stat[moxie]) * 0.8)
			mys_mod += 4;
		if (my_buffedstat($stat[moxie]) - monster_level_adjustment() < my_buffedstat($stat[muscle]) * 1.1) {
			mox_mod += 4;
			mus_mod -= 4;
		}

		if (my_buffedstat($stat[moxie]) - monster_level_adjustment() < my_buffedstat($stat[muscle]) * 1.1)
			buffIfNeededWithUneffect($skill[The Moxious Madrigal]);
		if (my_buffedstat($stat[moxie]) - monster_level_adjustment() < my_buffedstat($stat[muscle]) * 1.1)
			buffIfNeededWithUneffect($skill[Blubber Up]);
		if (my_buffedstat($stat[moxie]) - monster_level_adjustment() < my_buffedstat($stat[muscle]) * 1.1) {
			if (my_basestat($stat[moxie]) > 40)
				buffIfNeededWithUneffect($skill[Quiet Desperation]);
			else
				buffIfNeededWithUneffect($skill[Disco Smirk]);
		}
		if (my_buffedstat($stat[moxie]) - monster_level_adjustment() < my_buffedstat($stat[muscle]) * 1.1)
			cli_execute_if_needed("beach head Pomp & Circumsands", $effect[Pomp & Circumsands]);
	} until (tries > 3 || checkLOVprepStats(false));

	// sanity checks
	checkLOVprepStats(true);

	if (my_daycount() == 1) {
		if (my_hp() < my_maxhp() * 0.9)
			cli_execute("hottub");
	} else {
		healIfRequiredWithMPRestore(); // heal up after changing equipment
		burnMP(0);
	}

	if (my_mp() > 10) {
		print("warning: unburnt mana", "blue");
		return false;
	}
	return true;
}


void LOVadv(item clothes, effect buff, item emporium) {
	print("LOVadv", "green");
	if (to_boolean(get_property("_loveTunnelUsed")))
		return;

	LOVprep();

	int [item] clothes_map = {
		$item[LOV Eardigan]:1,
		$item[LOV Epaulettes]:2,
		$item[LOV Earrings]:3,
		$item[none]:4
	};
	int [effect] buff_map = {
		$effect[Lovebotamy]:1,
		$effect[Open Heart Surgery]:2,
		$effect[Wandering Eye Surgery]:3,
		$effect[none]:4
	};
	int [item] emporium_map = {
		$item[LOV Enamorang]:1,
		$item[LOV Emotionizer]:2,
		$item[LOV Extraterrestrial Chocolate]:3,
		$item[LOV Echinacea Bouquet]:4,
		$item[LOV Elephant]:5,
		$item[toast]:6,
		$item[none]:7
	};

	if (!(clothes_map contains clothes)) abort ("clothes value '" + clothes + "' unknown");
	if (!(buff_map contains buff)) abort ("buff value '" + buff + "' unknown");
	if (!(emporium_map contains emporium)) abort ("emporium value '" + emporium + "' unknown");

	visit_url("/place.php?whichplace=town_wrong&action=townwrong_tunnel", true, false);

	run_choice(1); // visit LOV tunnel
	run_choice(1); // fight enforcer
	run_combat();
	visit_url("/place.php?whichplace=town_wrong&action=townwrong_tunnel", true, false);

	run_choice(clothes_map[clothes]);
	run_choice(1); // fight engineer
	run_combat();
	visit_url("/place.php?whichplace=town_wrong&action=townwrong_tunnel", true, false);

	run_choice(buff_map[buff]);
	visit_url("/choice.php?whichchoice=1227&option=1&pwd", true, false); // fight equivocator
	visit_url("/fight.php?action=steal", true, false); // pickpocket if able
	run_combat();

	visit_url("/place.php?whichplace=town_wrong&action=townwrong_tunnel", true, false);
	run_choice(emporium_map[emporium]); // boomerang, etc.

	if (my_class() == $class[pastamancer])
		getDefaultPastaThrall();
	max_mcd();
}



// burn all buffs to maximize meat drop
// TODO: use a cost threshold instead of "useSweetSynthesis"
void buffForMeatDrop(int turns, boolean useSweetSynthesis) {
	setCurrentMood("meat");

	setBoombox("meat");

	if (isAsdonWorkshed())
		fueled_asdonmartin("observantly", turns);
	briefcase_if_needed($effect[A View to Some Meat], turns);

	int availableSpleen = spleen_limit() - my_spleen_use();
	if (useSweetSynthesis && (availableSpleen > ceil(turns / 30.0)))
		sweetSynthesis($effect[Synthesis: Greed], turns);
}

void buffForMeatDrop(int turns) {
	buffForMeatDrop(turns, false);
}


// TODO: add item-specific equips
string maximizeStringForMeatDrop() {
	string maxString = "meat";
	return maxString;
}


// burn everything to maximize item drop
void maximizeForMeatDrop(int turns) {
	buffForMeatDrop(turns);

	string familiarString = chooseFamiliar("meat", $location[none]);

	clear_automate_dressup();
	maximize(maxStringAppend(maximizeStringForMeatDrop(), familiarString), false);
}



void buffForItemDrop(int turnsToBuffFor, boolean useSweetSynthesis) {
	print("buffForItemDrop: " + turnsToBuffFor + ", use sweet Synthesis: " + useSweetSynthesis, "green");
	if (turnsToBuffFor <= 0) return;

	boolean unused;
	if (!to_boolean(get_property("_clanFortuneBuffUsed"))) cli_execute("fortune buff hagnk"); // +50%
	if (!to_boolean(get_property("_daycareSpa"))) cli_execute("daycare mysticality"); // +25%
	if (to_int(get_property("_poolGames")) < 3) cli_execute("pool 3"); // +10%
	briefcase_if_needed($effect[Items Are Forever], turnsToBuffFor);
	//boolean unused = use_skill(1, $skill[Visit your Favorite Bird]);
	if (!to_boolean(get_property("_favoriteBirdVisited"))) buffIfNeededWithUneffect($skill[Visit your Favorite Bird]);
	if (have_skill($skill[incredible self-esteem]))
		cli_execute("cast incredible self-esteem");

	if (my_class() == $class[Accordion Thief] && to_int(get_property("_thingfinderCasts")) < 10 && my_level() >= 15)
		buffIfNeededWithUneffect($skill[The Ballad of Richie Thingfinder], turnsToBuffFor);

	// these ones have a cost associated
	if (!to_boolean(get_property("_madTeaParty"))) cli_execute("hatter 28"); // +20%
	if (isAsdonWorkshed())
		safeFueledAsdonMartin($effect[Driving Observantly], turnsToBuffFor);

	int availableSpleen = spleen_limit() - my_spleen_use();
	if (useSweetSynthesis && (availableSpleen > ceil(turnsToBuffFor / 30.0)))
		sweetSynthesis($effect[Synthesis: Collection], turnsToBuffFor);
}

void buffForItemDrop(int turnsToBuffFor) {
	buffForItemDrop(turnsToBuffFor, false);
}


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
void maximizeForItemDrop(int turns) {
	buffForItemDrop(turns);

	string familiarString = chooseFamiliar("item", $location[none]);

// 	int professorLecturesAvailable = pocketProfessorLecturesAvailable();
// 	if (professorLecturesAvailable > 0) {
// 		use_familiar($familiar[Pocket Professor]);
// 		if (friars_available())
// 			cli_execute("friars familiar"); // we want this for the pocket professor all the time... professor gives adv for exp
// 		equip($item[Pocket Professor memory chip]);
// 		familiarString = "-familiar";
// 	}

	clear_automate_dressup();
	maximize(maxStringAppend(maximizeStringForItemDrop(), familiarString), false);
}



void burnBrokenChampagneBottle(AdventureRecord advRecord) {
	print("burnBrokenChampagneBottle: " + advRecord.toString(), "green");
	int chargesAvailable = to_int(get_property("garbageChampagneCharge"));
	if (chargesAvailable == 0 && !to_boolean(get_property("_garbageItemChanged"))) {
		cli_execute("tote 2");
		chargesAvailable = to_int(get_property("garbageChampagneCharge"));
	}

	int tries = 30;
	while (chargesAvailable > 0 && tries > 0) {
		int turnsToBurn = chargesAvailable;
		int otoscopeChargesAvailable = 3 - to_int(get_property("_otoscopeUsed"));
		int cloakChargesAvailable = 10 - to_int(get_property("_vampyreCloakeFormUses"));
		int professorLecturesAvailable = pocketProfessorLectures() - to_int(get_property("_pocketProfessorLectures"));

		if (otoscopeChargesAvailable > 0) {
			turnsToBurn = min(turnsToBurn, otoscopeChargesAvailable);
		}
		if (cloakChargesAvailable > 0) {
			turnsToBurn = min(turnsToBurn, cloakChargesAvailable);
		}
		if (professorLecturesAvailable > 0) {
			turnsToBurn = min(turnsToBurn, professorLecturesAvailable);
		}

		maximizeForItemDrop(turnsToBurn);
		if (have_item($item[maple magnet]))
			equip($item[maple magnet]);

		healIfRequiredWithMPRestore();
		getToAdventure(advRecord);
		run_turn();

		chargesAvailable = to_int(get_property("garbageChampagneCharge"));
		if (available_amount($item[broken champagne bottle]) == 0 || chargesAvailable == 0) {
			cli_execute("tote 2");
			chargesAvailable = to_int(get_property("garbageChampagneCharge"));
		}
		tries--;
	}
}

// for the CLI
void burnChampagneBottle(boolean drumMachine) {
	AdventureRecord ar;
	if (drumMachine)
		ar = new AdventureRecord($location[none], $skill[none], $item[drum machine]);
	else {
		if (have_item($item[maple magnet]))
			ar = new AdventureRecord($location[Dreadsylvanian Woods], $skill[none], $item[none]);
		else
			ar = new AdventureRecord($location[Dreadsylvanian Village], $skill[none], $item[none]);
	}
	burnBrokenChampagneBottle(ar);
}



// does a run through the spacegate at the given coordinates
// if gateString is empty, will use random coordinates
void grindSpacegate(string gateString) {
	int turnsLeft = spacegateEnergy();
	if (turnsLeft <= 0) return;
	print("grindSpacegate '" + gateString + "' for " + turnsLeft + " turns", "green");

	item [] spacegateEquipment = {
		$item[filter helmet],
		$item[exo-servo leg braces],
		$item[high-friction boots],
		$item[gate transceiver],
		$item[rad cloak]
	};

	clearGoals();
	setDefaultMood();

	if (get_property("_spacegateCoordinates") == "") {
		cli_execute("spacegate destination " + gateString);
		adv1($location[Through the Spacegate], 0, ""); // zero-turn adventure, will acquire the equipment needed
	}

	string familiarSelector = "item";
	string offhandString = "";
	string maxString = "0.1 mp regen, equip combat lover's locket"; // , -equip \"i voted\" sticker ??
	string plantLife = get_property("_spacegatePlantLife");
	string animalLife = get_property("_spacegateAnimalLife");

	set_property("choiceAdventure1243", "1"); // Interstellar Trade: buy anything

	// prefer plant life sample kit for no reason TODO use the one we need the most
	if (plantLife.contains_text("primitive") || plantLife.contains_text("advanced") || plantLife.contains_text("anomalous")) {
		if (!plantLife.contains_text("hostile") && offhandString == "") {
			fullAcquire($item[botanical sample kit]);
			offhandString = "equip botanical sample kit";
			set_property("choiceAdventure1237", "3"); // A Simple Plant: alien plant sample
			set_property("choiceAdventure1238", "3"); // A Complicated Plant: complex alien plant sample
			set_property("choiceAdventure1239", "3"); // What a Plant!: fascinating alien plant sample
		} else {
			familiarSelector = "robortender"; // TODO sniff value and switch based on that???
			set_property("choiceAdventure1237", "1"); // A Simple Plant: edible alien plant bit
			set_property("choiceAdventure1238", "1"); // A Complicated Plant: edible alien plant bit
			set_property("choiceAdventure1239", "1"); // What a Plant!: edible alien plant bit
		}
	}

	if (animalLife.contains_text("primitive") || animalLife.contains_text("advanced") || animalLife.contains_text("anomalous")) {
		if (!animalLife.contains_text("hostile") && offhandString == "") {
			fullAcquire($item[zoological sample kit]);
			offhandString = "equip zoological sample kit";
			set_property("choiceAdventure1240", "3"); // The Animals, The Animals: alien zoological sample
			set_property("choiceAdventure1241", "3"); // buffalo-like animal: complex alien zoological sample
			set_property("choiceAdventure1242", "3"); // house-sized animal: fascinating alien zoological sample
		} else {
			set_property("choiceAdventure1240", "2"); // The Animals, The Animals: alien toenails
			set_property("choiceAdventure1241", "2"); // buffalo-like animal: alien toenails
			set_property("choiceAdventure1242", "2"); // house-sized animal: alien toenails
		}
	}

	if (offhandString == "") {
		fullAcquire($item[geological sample kit]);
		offhandString = "equip geological sample kit";
		set_property("choiceAdventure1236", "2"); // Space Cave: just core sample
		set_property("choiceAdventure1255", "2"); // cool space rocks: core sample
		set_property("choiceAdventure1256", "2"); // wide open spaces: core sample
	} else {
		set_property("choiceAdventure1236", "6"); // Space Cave: just leave
		set_property("choiceAdventure1255", "1"); // cool space rocks: rocks
		set_property("choiceAdventure1256", "1"); // wide open spaces: rocks
	}

	maxString = maxString.maxStringAppend(offhandString);
	foreach sgEquipmentIndex in spacegateEquipment {
		if (have_item(spacegateEquipment[sgEquipmentIndex]))
			maxString = maxString.maxStringAppend("equip " + spacegateEquipment[sgEquipmentIndex]);
	}

	automate_dressup($location[Through the Spacegate], "item", familiarSelector, maxString);

	boolean unused;
	if (get_property("_spacegateCoordinates") > "DAAAAAA")
		unused = cli_execute("ballpit");

	// intro adventure, 0 turns -- might already be done, but won't harm anything?? TODO: might miss a redirect if this is an actual adventure
	healIfRequiredWithMPRestore();
	adv1($location[Through the Spacegate], -1, "");

	while (turnsLeft > 0) {
		healIfRequiredWithMPRestore();
		restore_mp(3 * mp_cost($skill[Weapon of the Pastalord]));
		redirectAdventure($location[Through the Spacegate], 1);

		turnsLeft--;
		set_property("_spacegateTurnsLeft", turnsLeft);
	}

	if (spacegateEnergy() > 0)
		grindSpacegate(gateString);
	else {
		// put into the closet if they can be accidentally used
		put_closet(item_amount($item[alien rock sample]), $item[alien rock sample]);
		put_closet(item_amount($item[alien rock sample]), $item[alien rock sample]);
		put_closet(item_amount($item[alien toenails]), $item[alien toenails]);
		put_closet(item_amount($item[alien zoological sample]), $item[alien zoological sample]);
		put_closet(item_amount($item[complex alien zoological sample]), $item[complex alien zoological sample]);
		put_closet(item_amount($item[fascinating alien zoological sample]), $item[fascinating alien zoological sample]);
		put_closet(item_amount($item[alien plant fibers]), $item[alien plant fibers]);
		put_closet(item_amount($item[alien plant sample]), $item[alien plant sample]);
		put_closet(item_amount($item[complex alien plant sample]), $item[complex alien plant sample]);
		put_closet(item_amount($item[fascinating alien plant sample]), $item[fascinating alien plant sample]);
		put_closet(item_amount($item[spant egg casing]), $item[spant egg casing]);
		put_closet(item_amount($item[murderbot memory chip]), $item[murderbot memory chip]);
	}
}

void grindSpacegate() {
	grindSpacegate(gkSpacegateCoordinates);
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

void resetFantasyrealmChoices() {
}

int [monster] parseFantasyRealmMonstersKilled() {
	int [monster] rval;
	string [int, int] parser = group_string(get_property("_frMonstersKilled"), ",?([^:]+):(\\d+)");
	foreach i in parser {
		monster aMonster = to_monster(parser[i][1]);
		int aKillCount = to_int(parser[i][2]);
		rval[aMonster] = aKillCount;
		//print("found monster: " + aMonster + ", killed: " + aKillCount);
	}
	return rval;
}

void fantasyrealmBaseGrind() {
	print("fantasyrealmBaseGrind", "green");
	int advToDo;
	int tries;
	int [monster] monstersKilled = parseFantasyRealmMonstersKilled();

	// if the last one's done, we're done
	if (monstersKilled[$monster[Swamp monster]] >= 5)
		return;

	getFantasyrealmQuest();
	resetFantasyrealmChoices();

	clearGoals();
	change_mcd(0);
	setDefaultMood();
	burnMP();

	// we're not wearing the kramco because wandering monsters don't appear -- also, can't copy into these zones
	advToDo = 5 - monstersKilled[$monster[Cursed villager]];
	if (advToDo > 0) {
		fullAcquire(2, $item[spectre scepter]);
		string maxString = "-ml, equip double-ice box, equip fantasyrealm g. e. m., equip LyleCo premium monocle, equip LyleCo premium magnifying glass";
		automate_dressup($location[the cursed village], "mainstat", "none", maxString);
		healIfRequiredWithMPRestore();
		adventure(advToDo, $location[The Cursed Village]);
	}

	automate_dressup($location[none], "50 spooky res", "none", "-ml, equip fantasyrealm g. e. m., equip LyleCo premium monocle, equip LyleCo premium magnifying glass");
	healIfRequired();
	advToDo = 5 - monstersKilled[$monster[Spooky ghost]];
	tries = 3 + advToDo;
	while (advToDo > 0 && tries > 0) {
		healIfRequiredWithMPRestore();
		adventure(1, $location[The Sprawling Cemetery]);
		advToDo = 5 - parseFantasyRealmMonstersKilled()[$monster[Spooky ghost]];
		tries--;
	}

	automate_dressup($location[none], "mainstat", "none", "-ml, equip fantasyrealm g. e. m., equip LyleCo premium monocle, equip LyleCo premium magnifying glass");

	healIfRequiredWithMPRestore();
	advToDo = 5 - monstersKilled[$monster[Fantasy forest faerie]];
	restore_mp(min(my_maxmp(), mp_cost($skill[Saucestorm]) * 10 + mp_cost($skill[Cannelloni Cocoon]) * 5));
	adventure(advToDo, $location[The Mystic Wood]);

	healIfRequiredWithMPRestore();
	advToDo = 5 - monstersKilled[$monster[Fantasy ourk]];
	adventure(advToDo, $location[The Towering Mountains]);

	healIfRequiredWithMPRestore();
	advToDo = 5 - monstersKilled[$monster[Fantasy bandit]];
	adventure(advToDo, $location[The Bandit Crossroads]);

	advToDo = 5 - monstersKilled[$monster[Swamp monster]];
	if (advToDo > 0)
		for i from 1 to advToDo {
			healIfRequiredWithMPRestore();
			adventure(1, $location[The Putrid Swamp]);
		}
}


// assumes base grind has been done
void fantasyrealmGrind(item targetItem) { // grindFantasyRealm
	print("fantasyrealmGrind, target item: " + targetItem, "green");

	if (my_session_items(targetItem) > 0) {
		print("Already got it!");
		return;
	}

	string pageText;
	int advToDo;
	int [monster] monstersKilled = parseFantasyRealmMonstersKilled();

	setNoMood(); // don't spend mana, need it all

	if (targetItem == $item[sachet of strange powder]) {
		pageText = advURL($location[The Towering Mountains]);
		run_choice(2); postAdventure();
		automate_dressup($location[the foreboding cave], "mainstat", "", "-ml, +equip fantasyrealm g. e. m., +equip LyleCo premium monocle, +equip LyleCo premium magnifying glass, -equip Kramco Sausage-o-Matic&trade;");
		healIfRequiredWithMPRestore();
		adventure(5, $location[the foreboding cave], "");
		pageText = advURL($location[the foreboding cave]);
		run_choice(2); postAdventure();
	}
	if (targetItem == $item[druidic s'more]) {
		pageText = advURL($location[The Mystic Wood]);
		run_choice(2); postAdventure();
		automate_dressup($location[The Druidic Campsite], "mainstat", "", "-ml, +equip bezoar ring, +equip fantasyrealm g. e. m., +equip LyleCo premium monocle, +equip LyleCo premium magnifying glass, -equip Kramco Sausage-o-Matic&trade;");
		healIfRequiredWithMPRestore();
		adventure(5, $location[The Druidic Campsite], "");
		pageText = advURL($location[The Druidic Campsite]);
		run_choice(1); postAdventure();
	}
	if (targetItem == $item[mourning wine]) {
		pageText = advURL($location[The Sprawling Cemetery]);
		run_choice(2); postAdventure();
		automate_dressup($location[the barrow mounds], "init", "", "-ml, +equip fantasyrealm g. e. m., +equip LyleCo premium monocle, +equip LyleCo premium magnifying glass, -equip Kramco Sausage-o-Matic&trade;");
		healIfRequiredWithMPRestore();
		adventure(5, $location[the barrow mounds], "");
		pageText = advURL($location[the barrow mounds]);
		run_choice(2); postAdventure();
	}
	if (targetItem == $item[denastified haunch]) {
		pageText = advURL($location[The Putrid Swamp]);
		run_choice(2); postAdventure();
		adventure(5, $location[The Troll Fortress], "");
		pageText = advURL($location[The Troll Fortress]);
		run_choice(2); postAdventure();
		pageText = advURL($location[The Mystic Wood]);
		run_choice(1); postAdventure();
		if (my_basestat($stat[muscle]) >= 175)
			automate_dressup ($location[The Faerie Cyrkle], "mus", "none", "-ml, 10 all res, +equip fantasyrealm g. e. m., +equip LyleCo premium monocle, +equip LyleCo premium magnifying glass, +equip cup of infinite pencils, +equip mafia thumb ring, +equip pantogram pants");
		else
			automate_dressup ($location[The Faerie Cyrkle], "mus", "none", "-ml, 10 all res, +equip fantasyrealm g. e. m., +equip LyleCo premium monocle, +equip LyleCo premium magnifying glass, +equip hippy protest button, +equip pantogram pants");
		healIfRequiredWithMPRestore(); adventure(1, $location[The Faerie Cyrkle], "");
		healIfRequiredWithMPRestore(); adventure(1, $location[The Faerie Cyrkle], "");
		healIfRequiredWithMPRestore(); adventure(1, $location[The Faerie Cyrkle], "");
		healIfRequiredWithMPRestore(); adventure(1, $location[The Faerie Cyrkle], "");
		healIfRequiredWithMPRestore(); adventure(1, $location[The Faerie Cyrkle], "");
		pageText = advURL($location[The Faerie Cyrkle]);
		run_choice(2); postAdventure();
		cli_execute("make denastified haunch");
	}

	if (targetItem == $item[Rubee&trade;]) {
		pageText = advURL($location[the cursed village]);
		run_choice(5); postAdventure();
	}

	if (targetItem == $item[the Archwizard's briefs]) {
		pageText = advURL($location[The Mystic Wood]);
		run_choice(2); postAdventure();
		automate_dressup($location[The Druidic Campsite], "mainstat", "", "-ml, +equip bezoar ring, +equip fantasyrealm g. e. m., +equip LyleCo premium monocle, +equip LyleCo premium magnifying glass, -equip Kramco Sausage-o-Matic&trade;");
		healIfRequiredWithMPRestore();
		adventure(5, $location[The Druidic Campsite], "");
		equip($item[FantasyRealm Mage's Hat]);
		pageText = advURL($location[The Druidic Campsite]);
		run_choice(3); postAdventure();
		pageText = advURL($location[The Towering Mountains]);
		run_choice(4); postAdventure();
		pageText = advURL($location[The Cursed Village]);
		run_choice(3); postAdventure();
		automate_dressup($location[The Archwizard's Tower], "cold res 5 min", "none", "-ml, +equip charged druidic orb, +equip fantasyrealm g. e. m.");
		healIfRequiredWithMPRestore();
		pageText = advURL($location[The Archwizard's Tower]);
		run_choice(1); postAdventure();
		cli_execute("dc auto the Archwizard's briefs");
		cli_execute("dc list the Archwizard's briefs");
	}
	if (targetItem == $item[Duke Vampire's regal cloak]) {
		pageText = advURL($location[The Mystic Wood]);
		run_choice(5); postAdventure();
		pageText = advURL($location[The Putrid Swamp]);
		run_choice(1); postAdventure();
		automate_dressup($location[Near the Witch's House], "spell dmg", "", "-ml, mys, spell dmg percent, +equip fantasyrealm g. e. m., +equip LyleCo premium monocle, +equip LyleCo premium magnifying glass, -equip Kramco Sausage-o-Matic&trade;");
		while (monstersKilled[$monster[flock of every birds]] < 5) {
			healToMax();
			adventure(1, $location[Near the Witch's House], "");
			monstersKilled = parseFantasyRealmMonstersKilled();
		}
		pageText = advURL($location[Near the Witch's House]);
		run_choice(2); postAdventure();
		equip($item[FantasyRealm Rogue's Mask]);
		pageText = advURL($location[The Sprawling Cemetery]);
		run_choice(3); postAdventure();
		automate_dressup($location[Duke Vampire's Chateau], "init", "", "-ml, +equip fantasyrealm g. e. m., +equip LyleCo premium monocle, +equip LyleCo premium magnifying glass, -equip Kramco Sausage-o-Matic&trade;");
		pageText = advURL($location[Duke Vampire's Chateau]);
		run_choice(1); postAdventure();
		cli_execute("dc auto Duke Vampire's regal cloak");
		cli_execute("dc list Duke Vampire's regal cloak");
	}
	if (targetItem == $item[The Ghoul King's ghoulottes]) {
		pageText = advURL($location[The Mystic Wood]);
		run_choice(1); postAdventure();
		if (my_basestat($stat[muscle]) >= 175)
			automate_dressup($location[The Faerie Cyrkle], "mus", "none", "-ml, 10 all res, +equip fantasyrealm g. e. m., +equip LyleCo premium monocle, +equip LyleCo premium magnifying glass, +equip cup of infinite pencils, +equip mafia thumb ring, +equip pantogram pants");
		else
			automate_dressup($location[The Faerie Cyrkle], "mus", "none", "-ml, 10 all res, +equip fantasyrealm g. e. m., +equip LyleCo premium monocle, +equip LyleCo premium magnifying glass, +equip hippy protest button, +equip pantogram pants");
		for i from 1 to 10 { // might fail a few times
			healIfRequiredWithMPRestore();
			pageText = advURL($location[The Faerie Cyrkle]);
			if (isChoicePage(pageText))
				break;
			run_combat(); postAdventure();
		}
 		run_choice(1); postAdventure();
		pageText = advURL($location[The Sprawling Cemetery]);
		run_choice(2); postAdventure();
		automate_dressup($location[the barrow mounds], "init", "", "-ml, +equip fantasyrealm g. e. m., +equip LyleCo premium monocle, +equip LyleCo premium magnifying glass, -equip Kramco Sausage-o-Matic&trade;");
		healIfRequiredWithMPRestore();
		adventure(5, $location[the barrow mounds], "");
		equip($item[FantasyRealm Warrior's Helm]);
		pageText = advURL($location[the barrow mounds]);
		run_choice(3); postAdventure();
		automate_dressup($location[The Ghoul King's Catacomb], "-ml, spooky res 5 min", "none", "hot dmg, +equip fantasyrealm g. e. m., +equip LyleCo premium monocle, +equip LyleCo premium magnifying glass");
		healIfRequiredWithMPRestore();
		pageText = advURL($location[The Ghoul King's Catacomb]);
		run_choice(1); postAdventure();
		cli_execute("dc auto The Ghoul King's ghoulottes");
		cli_execute("dc list The Ghoul King's ghoulottes");
	}
	if (targetItem == $item[the Ley Incursion's waist]) {
		equip($item[FantasyRealm Mage's Hat]);
		pageText = advURL($location[The Sprawling Cemetery]);
		run_choice(5); postAdventure();
		if (item_amount($item[FantasyRealm key]) == 0) buy($coinmaster[FantasyRealm Rubee&trade; Store], 1, $item[FantasyRealm key]);
		pageText = advURL($location[The Putrid Swamp]);
		run_choice(2); postAdventure();
		automate_dressup($location[the troll fortress], "hp regen", "none", "-ml, +equip fantasyrealm g. e. m., +equip LyleCo premium monocle, +equip LyleCo premium magnifying glass, -equip Kramco Sausage-o-Matic&trade;");
		healIfRequiredWithMPRestore();
		adventure(5, $location[the troll fortress], "");
		pageText = advURL($location[the troll fortress]);
		run_choice(3); postAdventure();
		pageText = advURL($location[The Mystic Wood]);
		run_choice(3); postAdventure();
		use_skill($skill[Quiet Judgement]);
		use_skill($skill[The Magical Mojomuscular Melody]);
		use_skill($skill[Stevedave's Shanty of Superiority]);
		clear_automate_dressup();
		maximize("10 mys, elemental dmg, effective, +equip fantasyrealm g. e. m.", false);
		if (my_buffedstat($stat[mysticality]) < 500) cli_execute("telescope look high");
		if (my_buffedstat($stat[mysticality]) < 500) cli_execute("monorail buff");
		if (!maximize("-ml, mys 500 min, elemental dmg, effective, +equip fantasyrealm g. e. m.", false)) abort("unable to get 500 mys");
		healIfRequiredWithMPRestore();
		burnMP(0);
		pageText = advURL($location[The Ley Nexus]);
		run_choice(1); postAdventure();
		run_combat();
		cli_execute("dc auto the Ley Incursion's waist");
		cli_execute("dc list the Ley Incursion's waist");
	}
	if (targetItem == $item[Master Thief's utility belt]) {
		uneffect($effect[Reptilian Fortitude]);
		pageText = advURL($location[The Sprawling Cemetery]);
		run_choice(1); postAdventure();
		automate_dressup($location[The Labyrinthine Crypt], "", "none", "-ml, -10 hp, -mus, mp regen, +equip fantasyrealm g. e. m., +equip LyleCo premium monocle, +equip LyleCo premium magnifying glass");
		advToDo = 5 - parseFantasyRealmMonstersKilled()[$monster[crypt creeper]];
		while (advToDo > 0) {
			checkIfRunningOut($item[gauze garter], 100);
			healToMaxWithMPRestore();
			restoreAllMP();
			adv1($location[The Labyrinthine Crypt], 1, "sub MasterThief; if hppercentbelow 40; use gauze garter; endif;if hppercentbelow 80; skill saucy salve; endif;if !hppercentbelow 80; attack; endif; endsub; call MasterThief; repeat;");
			advToDo = 5 - parseFantasyRealmMonstersKilled()[$monster[crypt creeper]];
		}
		equip($item[FantasyRealm Rogue's Mask]);
		pageText = advURL($location[The Labyrinthine Crypt]);
		run_choice(3); // arrest warrant
		postAdventure();
		pageText = advURL($location[The Cursed Village]);
		run_choice(7); // notarized arrest warrant
		postAdventure();
		pageText = advURL($location[The Towering Mountains]);
		run_choice(3); postAdventure();
		automate_dressup($location[The Master Thief's Chalet], "sleaze res 5 min", "none", "-ml, +equip fantasyrealm g. e. m., +equip LyleCo premium monocle, +equip LyleCo premium magnifying glass");
		healIfRequiredWithMPRestore();
		restore_mp(50);
		pageText = advURL($location[The Master Thief's Chalet]);
		run_choice(1); postAdventure();
		cli_execute("dc auto Master Thief's utility belt");
		cli_execute("dc list Master Thief's utility belt");
	}
	if (targetItem == $item[belt of Ogrekind]) {
		pageText = advURL($location[The Putrid Swamp]);
		run_choice(5); // nasty marshmallow
		postAdventure();
		pageText = advURL($location[The Mystic Wood]);
		run_choice(2); // druidic campsite
		postAdventure();
		automate_dressup($location[The Druidic Campsite], "mainstat", "none", "-ml, +equip bezoar ring, +equip fantasyrealm g. e. m., +equip LyleCo premium monocle, +equip LyleCo premium magnifying glass, -equip Kramco Sausage-o-Matic&trade;");
		adventure(5, $location[The Druidic Campsite], "");
		pageText = advURL($location[The Druidic Campsite]);
		run_choice(2); postAdventure();
		equip($item[FantasyRealm Warrior's Helm]);
		pageText = advURL($location[The Towering Mountains]);
		run_choice(5); // ogre chieftain's keep
		postAdventure();
		use_skill($skill[Quiet Determination]);
		use_skill($skill[The Power Ballad of the Arrowsmith]);
		use_skill($skill[Stevedave's Shanty of Superiority]);
		clear_automate_dressup();
		maximize("100 mus, effective, +equip fantasyrealm g. e. m.", false);
		maximize("100 mus, effective, +equip fantasyrealm g. e. m.", false); // first run doesn't get everything for some reason
		if (my_buffedstat($stat[muscle]) < 500) cli_execute("telescope look high");
		if (my_buffedstat($stat[muscle]) < 500) cli_execute("monorail buff");
		if (my_buffedstat($stat[muscle]) < 500) abort("unable to get 500 mus");
		healIfRequiredWithMPRestore();
		pageText = advURL($location[the ogre chieftain's keep]);
		run_choice(1); postAdventure();
		executeScript("use divine noisemaker, divine noisemaker");
		cli_execute("dc auto belt of Ogrekind");
		cli_execute("dc list belt of Ogrekind");
	}
	if (targetItem == $item[nozzle of the Phoenix]) {
		pageText = advURL($location[The Cursed Village]);
		run_choice(1); // the evil cathedral
		postAdventure();
		string maxString = "+equip fantasyrealm g. e. m., +equip LyleCo premium monocle, +equip LyleCo premium magnifying glass";
		if (my_basestat($stat[muscle]) >= 175) maxString += ", +equip cup of infinite pencils";
		else if (my_basestat($stat[mysticality]) >= 20) maxString += ", +equip double-ice box";
		if (my_basestat($stat[mysticality]) >= 65) maxString += ", +equip hippy protest button";
		automate_dressup($location[The Evil Cathedral], "mainstat", "none", maxString);
		// use wind-up Whatsian robot; // optional
		adventure(5, $location[The Evil Cathedral], "");
		equip($item[FantasyRealm Mage's Hat]);
		pageText = advURL($location[The Evil Cathedral]);
		run_choice(4); postAdventure();
		pageText = advURL($location[The Towering Mountains]);
		run_choice(2); postAdventure();
		automate_dressup($location[the foreboding cave], "mainstat", "none", "-ml, +equip fantasyrealm g. e. m., +equip LyleCo premium monocle, +equip LyleCo premium magnifying glass, +equip lucky gold ring, -equip Kramco Sausage-o-Matic&trade;");
		adventure(5, $location[the foreboding cave], "");
		equip($item[FantasyRealm Mage's Hat]);
		pageText = advURL($location[the foreboding cave]);
		run_choice(3); postAdventure();
		clear_automate_dressup();
		maximize("100 mox, effective, +equip fantasyrealm g. e. m.", false);
		maximize("100 mox, effective, +equip fantasyrealm g. e. m.", false);
		if (my_buffedstat($stat[moxie]) < 500) buffIfNeededWithUneffect($skill[The Moxious Madrigal]);
		if (my_buffedstat($stat[moxie]) < 500) buffIfNeededWithUneffect($skill[Stevedave's Shanty of Superiority]);
		if (my_buffedstat($stat[moxie]) < 500) cli_execute("telescope look high");
		if (my_buffedstat($stat[moxie]) < 500) cli_execute("monorail buff");
		if (my_buffedstat($stat[moxie]) < 500) abort("unable to get 500 mox");
		healIfRequiredWithMPRestore();
		pageText = advURL($location[the lair of the phoenix]);
		run_choice(1); postAdventure();
		run_combat();
		cli_execute("dc auto nozzle of the Phoenix");
		cli_execute("dc list nozzle of the Phoenix");
	}
	if (targetItem == $item[Dragonscale breastplate]) {
		if (item_amount($item[FantasyRealm key]) == 0) buy($coinmaster[FantasyRealm Rubee&trade; Store], 1, $item[FantasyRealm key]);
		pageText = advURL($location[The Towering Mountains]);
		run_choice(1); postAdventure();
		automate_dressup($location[The Old Rubee Mine], "dr", "none", "-ml, +equip fantasyrealm g. e. m., +equip LyleCo premium monocle, +equip LyleCo premium magnifying glass, +equip lucky gold ring, -equip Kramco Sausage-o-Matic&trade;");
		for i from 1 to 5 {
			healIfRequiredWithMPRestore();
			//adventure(1, $location[The Old Rubee Mine], "");
			pageText = advURL($location[The Old Rubee Mine]);
			run_combat(); postAdventure();
		}
		healIfRequiredWithMPRestore();
		pageText = advURL($location[The Old Rubee Mine]);
		run_choice(2); postAdventure();
		pageText = advURL($location[The Cursed Village]);
		run_choice(6); postAdventure();
		equip($item[FantasyRealm Warrior's Helm]);
		pageText = advURL($location[The Putrid Swamp]);
		run_choice(3); postAdventure();
		automate_dressup($location[The Dragon's Moor], "mainstat", "none", "-ml, +equip dragon slaying sword, +equip fantasyrealm g. e. m., +equip lucky gold ring, -equip Kramco Sausage-o-Matic&trade;");
		pageText = advURL($location[The Dragon's Moor]);
		run_choice(1); postAdventure();
		run_combat();
		cli_execute("dc auto Dragonscale breastplate");
		cli_execute("dc list Dragonscale breastplate");
	}
	if (targetItem == $item[leggings of the Spider Queen]) {
		equip($item[FantasyRealm Rogue's Mask]);
		pageText = advURL($location[The Cursed Village]);
		run_choice(2); postAdventure();
		for i from 1 to 10 {
			healIfRequiredWithMPRestore();
			pageText = advURL($location[The Cursed Village Thieves' Guild]);
			if (isChoicePage(pageText))
				break;
			run_combat(); postAdventure();
		}
		run_choice(2);
		pageText = advURL($location[The Mystic Wood]);
		run_choice(1); postAdventure();
		if (my_basestat($stat[muscle]) >= 175)
			automate_dressup($location[The Faerie Cyrkle], "mus", "none", "-ml, 10 all res, +equip fantasyrealm g. e. m., +equip LyleCo premium monocle, +equip LyleCo premium magnifying glass, +equip cup of infinite pencils, +equip mafia thumb ring, +equip pantogram pants");
		else
			automate_dressup($location[The Faerie Cyrkle], "mus", "none", "-ml, 10 all res, +equip fantasyrealm g. e. m., +equip LyleCo premium monocle, +equip LyleCo premium magnifying glass, +equip hippy protest button, +equip pantogram pants");
		for i from 1 to 10 {
			healIfRequiredWithMPRestore();
			pageText = advURL($location[The Faerie Cyrkle]);
			if (isChoicePage(pageText))
				break;
			run_combat(); postAdventure();
		}
		run_choice(6); postAdventure();
		equip($item[FantasyRealm Rogue's Mask]);
		pageText = advURL($location[The Faerie Cyrkle]);
		run_choice(3); postAdventure();
		use(1, $item[universal antivenin]);
		setCurrentMood("mox");
		clear_automate_dressup();
		maximize("100 mox, effective, +equip fantasyrealm g. e. m.", false);
		maximize("100 mox, effective, +equip fantasyrealm g. e. m.", false);
// 		if (my_buffedstat($stat[moxie]) < 500) buffIfNeededWithUneffect($skill[The Moxious Madrigal]);
// 		if (my_buffedstat($stat[moxie]) < 500) buffIfNeededWithUneffect($skill[Quiet Desperation]);
// 		if (my_buffedstat($stat[moxie]) < 500) buffIfNeededWithUneffect($skill[Stevedave's Shanty of Superiority]);
		if (my_buffedstat($stat[moxie]) < 500) cli_execute("telescope look high");
		if (my_buffedstat($stat[moxie]) < 500) cli_execute("monorail buff");
		if (my_buffedstat($stat[moxie]) < 500) abort("unable to get 500 mox");
		healIfRequiredWithMPRestore();
		pageText = advURL($location[The Spider Queen's Lair]);
		run_choice(1); postAdventure();
		run_combat();

		cli_execute("dc auto leggings of the Spider Queen");
		cli_execute("dc list leggings of the Spider Queen");
	}

	if (targetItem == $item[shield of the Skeleton Lord] || targetItem == $item[ring of the Skeleton Lord] || targetItem == $item[scepter of the Skeleton Lord]) {
		string dressupString = "mainstat, +equip fantasyrealm g. e. m., ";
		if (targetItem == $item[shield of the Skeleton Lord]) dressupString += "outfit FantasyRealm Warrior's Outfit";
		if (targetItem == $item[ring of the Skeleton Lord]) dressupString += "outfit FantasyRealm Wizard's Outfit";
		if (targetItem == $item[scepter of the Skeleton Lord]) dressupString += "outfit FantasyRealm Thief's Outfit";
		automate_dressup($location[The Towering Mountains], "", "none", dressupString);

		healIfRequiredWithMPRestore();
		pageText = advURL($location[The Towering Mountains]);
		run_choice(10); postAdventure();
		healIfRequiredWithMPRestore();
		pageText = advURL($location[The Mystic Wood]);
		run_choice(10); postAdventure();
		healIfRequiredWithMPRestore();
		pageText = advURL($location[The Putrid Swamp]);
		run_choice(10); postAdventure();
		healIfRequiredWithMPRestore();
		pageText = advURL($location[The Cursed Village]);
		run_choice(10); postAdventure();
		healIfRequiredWithMPRestore();
		pageText = advURL($location[The Sprawling Cemetery]);
		run_choice(10); postAdventure();

		run_combat();

		cli_execute("dc auto shield of the Skeleton Lord");
		cli_execute("dc list shield of the Skeleton Lord");
		cli_execute("dc auto ring of the Skeleton Lord");
		cli_execute("dc list ring of the Skeleton Lord");
		cli_execute("dc auto scepter of the Skeleton Lord");
		cli_execute("dc list scepter of the Skeleton Lord");
	}

	setDefaultMood();
}



void fantasyrealmDisplayCase() {
	cli_execute("dc auto Rubee");
	cli_execute("dc auto sachet of strange powder");
	cli_execute("dc auto druidic s'more");
	cli_execute("dc auto mourning wine");
	cli_execute("dc auto denastified haunch");
	cli_execute("dc auto the Archwizard's briefs");
	cli_execute("dc auto Duke Vampire's regal cloak");
	cli_execute("dc auto The Ghoul King's ghoulottes");
	cli_execute("dc auto the Ley Incursion's waist");
	cli_execute("dc auto Master Thief's utility belt");
	cli_execute("dc auto belt of Ogrekind");
	cli_execute("dc auto nozzle of the Phoenix");
	cli_execute("dc auto Dragonscale breastplate");
	cli_execute("dc auto leggings of the Spider Queen");
	cli_execute("dc auto shield of the Skeleton Lord");
	cli_execute("dc auto ring of the Skeleton Lord");
	cli_execute("dc auto scepter of the Skeleton Lord");
}



// TODO: do some quests in easy mode, others in hard mode (everything in hard mode right now)
void grindNeverendingParty(boolean useSweetSynthesis) {
	print("grindNeverendingParty", "green");
	string kPartyQuestString = "Party Fair";
	clear_quest_log_cache();
	string partyQuest = quest(kPartyQuestString);

	if (get_property("_questPartyFair") == "finished"
		|| (partyQuest.contains_text("Clear all of the guests") && to_int(get_property("_neverendingPartyFreeTurns")) >= 10))
		return;

	cli_execute("prefref party");
	try {
		int kTurnsPerNC = 8;
		boolean unused;

		// get the quest -- TODO will fail on the day you leave ronin/hardcore if you don't accept the party quest
		if (!is_on_quest(kPartyQuestString)) {
			equip($item[PARTY HARD T-shirt]);
			adv1($location[The Neverending Party], -1, "");
			run_choice(1);
			clear_quest_log_cache();
			print_quest(kPartyQuestString);
		}
		if (!is_on_quest(kPartyQuestString)) abort("can't find quest");

		// buffs
		setCurrentMood("meat");
		unused = setBoombox("meat");
		unused = cli_execute("hatter 22");
		unused = cli_execute("summon 2");
		unused = cli_execute("concert winklered");
		if (to_int(get_property("_kgbClicksUsed")) <= 23)
			briefcase_if_needed($effect[A View to Some Meat], kTurnsPerNC);
		if (useSweetSynthesis && my_spleen_use() < spleen_limit())
			sweetSynthesis($effect[Synthesis: Greed], kTurnsPerNC);
		if (useSweetSynthesis && my_spleen_use() < spleen_limit())
			sweetSynthesis($effect[Synthesis: Collection], kTurnsPerNC);
		if (isAsdonWorkshed())
			fueled_asdonmartin("observantly", kTurnsPerNC);

		// base outfit
		string additionalString = "+equip PARTY HARD T-shirt, -equip Kramco Sausage-o-Matic&trade;, -equip \"i voted\" sticker, -equip wad of used tape"; // don't waste these free turns here

		// quest-specific tweaks to outfit and choices
		string selectorString = "meat";
		partyQuest = quest(kPartyQuestString);

		if (partyQuest.contains_text("Clear all of the guests")) {
			if (have_item($item[intimidating chainsaw]))
				additionalString = maxStringAppend(additionalString, "+equip intimidating chainsaw");
			set_property("choiceAdventure1324", "5"); // fight

		} else if (partyQuest.contains_text("megawoots") && have_item($item[cosmetic football])) {
			additionalString = maxStringAppend(additionalString, "+equip cosmetic football");
			set_property("choiceAdventure1324", "1");
			set_property("choiceAdventure1325", "5");

		} else if (partyQuest.contains_text("Geraldine")) {
			set_property("choiceAdventure1324", "2"); // kitchen
			set_property("choiceAdventure1326", "3"); // talk to geraldine

		} else if (partyQuest.contains_text("Gerald") || partyQuest.contains_text("backyard")) {
			set_property("choiceAdventure1324", "3"); // back yard
			set_property("choiceAdventure1327", "3"); // talk to gerald

		} else if (partyQuest.contains_text("Meat for the DJ")) {
			selectorString = "meat";
			additionalString = maxStringAppend(additionalString, "mox 300 min");
			set_property("choiceAdventure1324", "5"); // fight

		} else if (partyQuest.contains_text("Clean up the trash")) {
			selectorString = "item";
			set_property("choiceAdventure1324", "2"); // kitchen
			set_property("choiceAdventure1326", "5"); // Burn some trash
		}

		automate_dressup($location[The Neverending Party], selectorString, selectorString, additionalString);

		// party time
		while (is_on_quest(kPartyQuestString) && get_property("_questPartyFair") != "finished") {
			partyQuest = quest(kPartyQuestString);

			// QUEST AUTOMATION
			if (partyQuest.contains_text("Clear all of the guests")) {
				if (to_int(get_property("_neverendingPartyFreeTurns")) >= 10)
					break;

			} else if ((partyQuest.contains_text("Gerald") || partyQuest.contains_text("backyard")) && get_property("_questPartyFair") == "step1") { // also matches "Geraldine"
        		int [int] progress_split;
				foreach key, v in get_property("_questPartyFairProgress").split_string(" ") {
					if (v == "") continue;
					progress_split.arrayAppend(v.to_int());
				}
                int amountNeeded = progress_split[0];
                item itemNeeded = progress_split[1].to_item();
                if (itemNeeded != $item[none]) {
	                print("acquiring " + amountNeeded + " " + itemNeeded + "@ " + mall_price(itemNeeded) + " for the Neverending Party");
					if (!fullAcquire(amountNeeded, itemNeeded))
						abort("could not acquire " + amountNeeded + " of " + itemNeeded);
					else {
               			set_property("choiceAdventure1326", "4"); // return the food to Geraldine
               			set_property("choiceAdventure1327", "4"); // return the booze to Gerald
					}
				} else {
					abort("shouldn't get here!");
				}

			} else if (partyQuest.contains_text("Meat for the DJ")) {
				if (my_basestat($stat[moxie]) >= 300) {
					set_property("choiceAdventure1324", "1"); // head upstairs
					set_property("choiceAdventure1325", "4"); // meat from the safe
				} else {
					set_property("choiceAdventure1324", "5"); // fight
				}
			}

			string tweakString;
			if (to_int(get_property("_neverendingPartyFreeTurns")) < 10)
				tweakString = "-equip mafia thumb ring";
			else
				tweakString = "";
			dressup(tweakString);
			healIfRequiredWithMPRestore();

			unused = adv1($location[The Neverending Party], to_int(get_property("_neverendingPartyFreeTurns")) < 10 ? 0 : 1, "");

			clear_quest_log_cache();
		}

		// might need one last adventure to turn in quest
		unused = adv1($location[The Neverending Party], 0, "");
		//use(1, $item[deluxe Neverending Party favor]); // save it
		setDefaultBoombox();
	} finally {
		remove_property("choiceAdventure1324");
		remove_property("choiceAdventure1325");
		remove_property("choiceAdventure1326");
		remove_property("choiceAdventure1327");
	}
}



// finagle things so that all buffed stats are below 101
// PR party hat gives more fun points; Red Roger's red left hand gives +100% item in PR;
// Red Roger's red right hand gives +50 dmg in PR;
// Red Roger's red right foot for sailing and Red Roger's red left foot for island
boolean prDressup(string selectorString, string familiarString, string baseString) {
	int tries = 3;
	float mus_mod = 1;
	float mys_mod = 1;
	float mox_mod = 1;

	repeat {
		string temp_maxString = baseString + ", equip PirateRealm eyepatch, equip PirateRealm party hat, equip Red Roger's red left hand, equip Red Roger's red right hand, "
			+ mys_mod + " mys 100 max, " + mus_mod + " mus 100 max, " + mox_mod + " mox 100 max, equip combat lover's locket";
		automate_dressup($location[PirateRealm Island], selectorString, familiarString, temp_maxString);
		if (my_buffedstat($stat[muscle]) > 100) mus_mod -= 1;
		if (my_buffedstat($stat[mysticality]) > 100) mys_mod -= 1;
		if (my_buffedstat($stat[moxie]) > 100) mox_mod -= 1;
		tries--;
	} until (tries <= 0 || (my_buffedstat($stat[muscle]) <= 100 && my_buffedstat($stat[mysticality]) <= 100 && my_buffedstat($stat[moxie]) <= 100));

	if (my_buffedstat($stat[muscle]) <= 100 && my_buffedstat($stat[mysticality]) <= 100 && my_buffedstat($stat[moxie]) <= 100)
		return true;
	else
		return false;
}

void getPirateRealmQuest() {
	if (available_amount($item[PirateRealm eyepatch]) == 0)
		visit_url("/place.php?whichplace=realm_pirate&action=pr_port", true, false);

	boolean success = prDressup("item", "Plastic Pirate Skull", "0.5 meat");
	assert(success, "can't dressup -- buffed stat higher than 100??");

	if (available_amount($item[curious anemometer]) == 0) {
		visit_url("/place.php?whichplace=realm_pirate&action=pr_port", true, false);
		run_choice(1); // Head to Groggy's

		// cuisinier for the Dessert Island
		int choiceNumber = 0;
		foreach i, name in available_choice_options(false) {
			if (name.contains_text("Cuisinier")) {
				choiceNumber = i;
				break;
			}
		}
		if (choiceNumber == 0) choiceNumber = random(3) + 1; // random of we can't get the cuisinier
		run_choice(choiceNumber);

		run_choice(4); // curious anemometer to unlock Trash Island
		run_choice(4); // Swift Clipper
		run_choice(1); // head to the sea
	}
}

record PRStatusRecord {
	int guns;
	int grub;
	int grog;
	int glue;
	int gold;
	int fun;
};

PRStatusRecord getPirateRealmStatus() {
	PRStatusRecord result;
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

// one adventure on the seas
boolean sailThePirateRealmSeas() {
	boolean rval = true;
	PRStatusRecord status = getPirateRealmStatus();

	string aPage = advURL(to_url($location[Sailing the PirateRealm Seas]));

	if (aPage.contains_text("Smooth Sailing")) {
		if (status.grub > status.grog)
			run_choice(1); // feast
		else if (status.grub > 0)
			run_choice(2); // party
		else
			run_choice(1); // party but no food, so the option is missing
	} else if (aPage.contains_text("High Tide, Low Morale")) {
		if (status.grub > status.grog && status.grub > 5)
			run_choice(1); // feast
		else if (status.grog > 5)
			run_choice(2); // party
		else if (status.gold >= 30)
			run_choice(3);
		else
			run_choice(4);
	} else if (aPage.contains_text("Like Shops in the Night")) {
		while (status.gold >= 10 && (status.grub < 50 || status.grog < 50 || status.glue < 2)) {
			int theChoice = 0;
			if (status.grub < status.grog && status.grub < 50)
				theChoice = 1; // buy grub
			else if (status.grog < 50)
				theChoice = 2; // buy grog
			else if (status.glue < 2)
				theChoice = 3; // buy glue
			if (status.glue == 0 && status.grub >20 && status.grog > 20)
				theChoice = 3;
			assert(theChoice != 0, "sailThePirateRealmSeas: should always have a choice");

			run_choice(theChoice);
			status = getPirateRealmStatus();
		}

		while (status.gold > 200) {
			run_choice(4); // buy gun
			status = getPirateRealmStatus();
		}

		run_choice(6); // exit
	} else if (aPage.contains_text("The Ship is Wrecked")) {
		if (available_choice_options()[1] == "")
			run_choice(2); // wait for assistance
		else
			run_choice(1); // fix it with glue
	}

	else if (aPage.contains_text("Land Ho!")) {
		run_choice(-1); // head inland
		rval = false;

	} else if (aPage.contains_text("<td>You're not currently at sea.<center>")) 
		rval = false;

	else
		run_choice(-1);

	assert(!handling_choice(), "still handling a choice at the end of sailThePirateRealmSeas");

	postAdventure();
	return rval;
}

// get through an entire sea
boolean grindPirateRealmSea() {
	prDressup("mp regen", "Plastic Pirate Skull", "equip Red Roger's red right foot");

	while (sailThePirateRealmSeas()) {
		healIfRequiredWithMPRestore();
	}

	return true;
}

// grind through an entire island
boolean grindPirateRealmIsland(int turns) {
	location island = to_location(get_property("_LastPirateRealmIsland"));

	while (turns > 0)
		try {
			healIfRequiredWithMPRestore();
			restore_mp(30);
			string aPage = advURL(island);
			if (isErrorPage(aPage))
				return false;
			else if (inCombat())
				run_combat();
			else if (aPage.contains_text("fight.php"))
				// monster killed before we got into combat, continue
				continue;
			else {
				assert(handling_choice(), "grindPirateRealmIsland: we should be handling a choice at this point");
				run_choice(-1);
				return true;
			}
		} finally {
			postAdventure();
			turns--;
		}

	return false;
}

void grindPirateRealm() {
	print("grindPirateRealm", "green");

	if (to_boolean(get_property("_smm.PRIslandThreeDone")))
		return;

	saveAndSetProperty("choiceAdventure1358", "2"); // The Starboard is Bare, Dive for bigger bounty
	saveAndSetProperty("choiceAdventure1359", "2"); // Grog for the Grogless, Dive for sunken casks
	saveAndSetProperty("choiceAdventure1362", "2"); // Stormy Weather, Try to gain some extra distance
	saveAndSetProperty("choiceAdventure1363", "1"); // Who Pirates the Pirates?, Attempt to flee
	saveAndSetProperty("choiceAdventure1364", "1"); // An Opportunity for Dastardly Do, Attack them
	saveAndSetProperty("choiceAdventure1365", "2"); // A Sea Monster!, Flee it!
	try {
		setDefaultState();
		clearGoals();
		burnMP(-100);

		location island;

		// choose island 1 -- Dessert if available, Battle otherwise
		if (get_property("_LastPirateRealmIsland") == "") {
			assert(my_adventures() >= 40, "grindPirateRealm: not enough adv to visit the PirateRealm");
			getPirateRealmQuest();

			visit_url(to_url($location[Sailing the PirateRealm Seas]), true, false);
			int choiceNumber = 0;
			foreach i, name in available_choice_options(false) {
				if (name.contains_text("Dessert")) {
					choiceNumber = i;
					break;
				}
				if (name.contains_text("Battle"))
					choiceNumber = i;
			}
			run_choice(choiceNumber);
		}

		// sea 1
		if (!to_boolean(get_property("_smm.PRSeaOneDone"))) {
			print("adventuring at sea #1", "green");
			if (grindPirateRealmSea())
				set_property("_smm.PRSeaOneDone", "true");
			else
				abort("grindPirateRealm: failed while adventuring at sea");
		}
		// island 1
		if (!to_boolean(get_property("_smm.PRIslandOneDone"))) {
			print("adventuring at island #1", "green");
			prDressup("mp regen", "default", "equip Red Roger's red left foot");
			if (grindPirateRealmIsland(5))
				set_property("_smm.PRIslandOneDone", "true");
			else
				abort("grindPirateRealm: failed while adventuring on island");
		}

		// sea 2
		if (!to_boolean(get_property("_smm.PRSeaTwoDone"))) {
			// choose island 2
			if (get_property("_LastPirateRealmIsland") != "Trash Island") {
				equip($item[PirateRealm eyepatch]);
				visit_url(to_url($location[Sailing the PirateRealm Seas]), true, false);
				run_choice(-1); // trash island
			}

			print("adventuring at sea #2", "green");
			if (grindPirateRealmSea())
				set_property("_smm.PRSeaTwoDone", "true");
			else
				abort("grindPirateRealm: failed while adventuring at sea");
		}
		// island 2
		if (!to_boolean(get_property("_smm.PRIslandTwoDone"))) {
			buffForMeatDrop(5, false); // don't use sweet synthesis: doesn't repay cost unless we burn the rest of the buff turns somewhere useful
			prDressup("meat", "meat", "equip Red Roger's red left foot");

			print("adventuring at island #2", "green");
			if (grindPirateRealmIsland(5))
				set_property("_smm.PRIslandTwoDone", "true");
			else
				abort("grindPirateRealm: failed while adventuring on island");
			setDefaultState(); // reset the mood
		}

		// sea 3
		if (!to_boolean(get_property("_smm.PRSeaThreeDone"))) {
			// choose island 3
			if (get_property("_LastPirateRealmIsland") != "Tiki Island") {
				equip($item[PirateRealm eyepatch]);
				visit_url(to_url($location[Sailing the PirateRealm Seas]), true, false);
				// run_choice(1); // signal island
				run_choice(2); // tiki island
			}

			print("adventuring at sea #3", "green");
			if (grindPirateRealmSea())
				set_property("_smm.PRSeaThreeDone", "true");
			else
				abort("grindPirateRealm: failed while adventuring at sea");
		}
		// island 3
		if (!to_boolean(get_property("_smm.PRIslandThreeDone"))) {
			prDressup("mp regen", "default", "equip Red Roger's red left foot");

			print("adventuring at island #3", "green");
			if (grindPirateRealmIsland(10))
				set_property("_smm.PRIslandThreeDone", "true");
			else
				abort("grindPirateRealm: failed while adventuring on island");
		}

	} finally {
		restoreSavedProperty("choiceAdventure1358");
		restoreSavedProperty("choiceAdventure1359");
		restoreSavedProperty("choiceAdventure1362");
		restoreSavedProperty("choiceAdventure1363");
		restoreSavedProperty("choiceAdventure1364");
		restoreSavedProperty("choiceAdventure1365");
	}
}



void grindGlaciest(boolean banishesAvailable) {
	int kTurnsToAdventure = 20;
	string kWalfordQuestString = "Filled to the Brim";
	monster [] bestTarget = {$monster[ice bartender]};
	monster [] noBanishesRemainingTargets = {$monster[ice bartender], $monster[ice clerk]}; // clerk = ice bell (banish); housekeeper = minibar key (fancy chocolate)
	monster [] noBagTargets = {$monster[ice bartender], $monster[ice concierge]};
	boolean unused;

	// set choiceAdventure1116=4
	setCurrentMood("-combat");

	string additionalString = "-combat";
	if (to_int(get_property("_voteFreeFights")) > 2) // only equip vote sticker for free fights
		additionalString = "-equip \"i voted\" sticker";
	clear_quest_log_cache();
	if (to_int(get_property("walfordBucketProgress")) < 100 && is_on_quest(kWalfordQuestString)) {
		additionalString = "+equip Walford's bucket";
		if (quest(kWalfordQuestString).contains_text("blood"))
			additionalString += ", +equip remorseless knife";
	}
	automate_dressup($location[The Ice Hotel], "item", "default", additionalString);

	monster [] targets = bestTarget;
	if (!banishesAvailable) targets = noBanishesRemainingTargets;
	if (item_amount($item[bag of foreign bribes]) == 0) targets = noBagTargets;

	targetMob($location[The Ice Hotel], targets, $skill[none], kTurnsToAdventure, banishesAvailable, kMaxInt);
	// set choiceAdventure1116=
}


// -------------------------------------
// AUTOMATION -- GRINDING -- ASCENSION PREP
// -------------------------------------

// gets 1 smut orc keepsake box, ensures won't dressup in a free-combat generating item
// (which will overwrite the pervert and thus the keepsake box)
// turns_until_box should INCLUDE the turn to get the box
void grind_smut_orc_keepsake_box(int turns_until_box) {
	setMood("current, meat");
	automate_dressup($location[The Smut Orc Logging Camp], "meat", "", "+equip Kramco Sausage-o-Matic&trade;");

	if (turns_until_box > 1) {
		//print("MACRO: " + default_sub());
		for i from 1 to (turns_until_box - 1) {
			check_counters(kAbortOnCounter);
			healIfRequiredWithMPRestore();
			print("doing adv #" + i);
			if (!adv1($location[The Smut Orc Logging Camp], 1, default_sub()))
				abort("adv1 failed");
			if (last_monster() == $monster[smut orc pervert])
				abort("unexpected pervert. Stopping.");
		}
	}

	clear_automate_dressup();
	dressup($location[none], "meat", "default", "-equip Kramco Sausage-o-Matic&trade;, -equip \"i voted\" sticker");
	if (!adv1($location[The Smut Orc Logging Camp], 1, default_sub()))
		abort("final adv1 failed");

	if (last_monster() == $monster[smut orc pervert])
		print("success", "green");
	else
		print("failed -- you might not have specified enough turns OR you overwrote it with a wandering monster", "red");
}

void grind_smut_orc_keepsake_box() {
	grind_smut_orc_keepsake_box(20);
}



void grindSpace(int turnsToGrind, int maxPerTurnCost) {
	int kBuffTurns = ceil(turnsToGrind * 1.2);
	setMood("current, meat");
	if (isAsdonWorkshed() && (!drivingAsdonMartin() || have_effect($effect[Driving Observantly]) > 0))
		fueled_asdonmartin("observantly", kBuffTurns);
	//sweetSynthesis($effect[Synthesis: Collection], kBuffTurns); // not needed to finish in 30 turns?
	briefcase_if_needed($effect[Items Are Forever], kBuffTurns);

	automate_dressup($location[Domed City of Grimacia], "item", "item", "-equip \"i voted\" sticker");

	monster [] monsterArray = {$monster[grizzled survivor], $monster[unhinged survivor], $monster[whiny survivor]};
	targetMob($location[Domed City of Grimacia], monsterArray, $skill[none], turnsToGrind, true, maxPerTurnCost);
}



void grindReflections(int reflectionsToGet, int maxPerTurnCost) {
	int kBuffTurns = ceil(reflectionsToGet * 1.2);
	setMood("current, meat");
	if (isAsdonWorkshed() && (!drivingAsdonMartin() || have_effect($effect[Driving Observantly]) > 0))
		fueled_asdonmartin("observantly", kBuffTurns);
	//sweetSynthesis($effect[Synthesis: Collection], kBuffTurns);
	briefcase_if_needed($effect[Items Are Forever], kBuffTurns);

	automate_dressup($location[The Red Queen's Garden], "item", "item", "");

	monster [] monsterArray = {$monster[grizzled survivor], $monster[unhinged survivor], $monster[whiny survivor]};
	targetMob($location[The Red Queen's Garden], monsterArray, $skill[none], reflectionsToGet, true, maxPerTurnCost);
}



void grindScarabBeatles(int numberToGet, int maxPerTurnCost, boolean doBlur) {
	int kBuffTurns = ceil(numberToGet * 1);
	print("grindScarabBeatles, " + numberToGet + " to get, maxPerTurnCost: " + maxPerTurnCost + ", do blur: " + doBlur, "green");

	// first time through: get Ultrahydrated first to save a turn of our buffs
	if (have_effect($effect[Ultrahydrated]) == 0) {
		if (!get_property("_freePillKeeperUsed").to_boolean())
			cli_execute("pillkeeper free semirare");
		adv1($location[The Oasis], 1);
	}

	if (isFloundryLocation($location[The Oasis]) && have_item($item[wriggling worm]))
		use_if_needed($item[wriggling worm], $effect[Baited Hook], kBuffTurns);

	// buffs
	setMood("current, meat");
	setBoombox("meat");
	boolean useSweetSynthesis = spleen_limit() - my_spleen_use() >= kBuffTurns / 15;
	buffForItemDrop(kBuffTurns, useSweetSynthesis); // use sweet synthesis if we have the spleen
	int availableSpleen = spleen_limit() - my_spleen_use();
	if (useSweetSynthesis && (availableSpleen > ceil(kBuffTurns / 30.0)))
		sweetSynthesis($effect[Synthesis: Greed], kBuffTurns);

	// dress up
	int chargesAvailable = to_int(get_property("garbageChampagneCharge"));
	if (chargesAvailable == 0 && !to_boolean(get_property("_garbageItemChanged"))) {
		cli_execute("tote 2");
		chargesAvailable = to_int(get_property("garbageChampagneCharge"));
	}
	string champagneString = chargesAvailable > 0 ? ", equip broken champagne bottle" : "";
	string sabreString = (to_int(get_property("_saberForceUses")) < 5 && champagneString == "") ? ", equip Fourth of May Cosplay Saber" : "";
	automate_dressup($location[The Oasis], "item", "item", "0.25 meat, -equip aerogel attache case, -equip fishin' hat, -equip government-issued slacks, -equip pantogram pants" + champagneString + sabreString);
	healIfRequiredWithMPRestore();

	monster [] monsterArray = {$monster[swarm of scarab beatles]};
	if (doBlur) monsterArray = {$monster[swarm of scarab beatles], $monster[blur]};
	int misses = 3;
	while (numberToGet > 0 && misses > 0) {
		skill skillToUse = $skill[none];
		if (get_property("olfactedMonster").to_monster() != $monster[swarm of scarab beatles]
			&& user_confirm("overwrite Olfact?"))
			skillToUse = $skill[Transcendent Olfaction];
		else if (canYellowRay() && (item_drop_modifier() < 600 || meat_drop_modifier() < 800) && equipped_amount($item[broken champagne bottle]) == 0) {
			prepForYellowRay();
			skillToUse = chooseYellowRaySkill().theSkill; // not in combat
		}

		if (have_effect($effect[Ultrahydrated]) == 0) {
			if (!get_property("_freePillKeeperUsed").to_boolean())
				cli_execute("pillkeeper free semirare");
		}

		if (targetMob($location[The Oasis], monsterArray, skillToUse, 1, true, maxPerTurnCost))
			numberToGet--;
		else
			misses--;

		print("swarm of scarab beatles: " + ((monsterTotalMeatValue($monster[swarm of scarab beatles], item_drop_modifier(), meat_drop_modifier()) - perAdventureCost() - mall_price($item[ten-leaf clover])/20) * 0.95)); // include cost of the ten-leaf clover and the 1 turn in 20 to get Ultrahydrated
		if (doBlur)
			print("blur: " + ((monsterTotalMeatValue($monster[blur], item_drop_modifier(), meat_drop_modifier()) - perAdventureCost() - mall_price($item[ten-leaf clover])/20) * 0.95)); // include cost of the ten-leaf clover and the 1 turn in 20 to get Ultrahydrated
	}

	if (misses == 0)
		print("exiting as a result of too many misses!", "red");
}

// attempts to grind while saving banishesToSave banishes
void grindScarabBeatles(int maxPerTurnCost, boolean doBlur, int banishesToSave) {
	clear_automate_dressup();
	printPSRArray(true, false, $location[The Oasis], maxPerTurnCost);
	int banishesAvailable = max(0, banishesAvailable(maxPerTurnCost) - banishesToSave);
	if (banishesAvailable > 0)
		grindScarabBeatles(min(banishesAvailable * 10, my_adventures() - 10), maxPerTurnCost, doBlur);
}

// tries to grind until all banishes are done
void grindScarabBeatles(int maxPerTurnCost, boolean doBlur) {
	clear_automate_dressup();
	int banishesAvailable = banishesAvailable(maxPerTurnCost);
	while (banishesAvailable > 0) {
		grindScarabBeatles(min((banishesAvailable + 1) * 10, my_adventures() - 10), maxPerTurnCost, doBlur);
		banishesAvailable = banishesAvailable(maxPerTurnCost);
	}
}


// only need +234% item to get drum machines
// will yellow ray beatles if getBeatlesOnYellowRay is true
void grindDrumMachine(int numberToGet, int maxPerTurnCost, boolean getBeatlesOnYellowRay) {
	int kTargetItemDrop = 234;
	int kBuffTurns = ceil(numberToGet * 1.2);

	if (!drivingAsdonMartin($effect[Driving Observantly]))
		print("WARNING: overwriting existing Asdon buff!", "red");
	buffForMeatDrop(kBuffTurns, false); // use sweet Synthesis

	if (isFloundryLocation($location[The Oasis]) && have_item($item[wriggling worm]))
		use_if_needed($item[wriggling worm], $effect[Baited Hook], kBuffTurns);

	string familiarSelector = "meat";
	string maxString = "item";
	float meatBonus = 1;
	int tries = 4;
	repeat {
		automate_dressup($location[The Oasis], meatBonus + " meat", familiarSelector, maxString);

		if (item_drop_modifier() < kTargetItemDrop * 1.1 && tries == 4)
			familiarSelector = "item";
		if (item_drop_modifier() < kTargetItemDrop * 1.1)
			meatBonus = meatBonus / 4;
		if (item_drop_modifier() > kTargetItemDrop * 2)
			meatBonus = meatBonus * 3;

		tries--;
	} until (tries <= 0 || (item_drop_modifier() >= kTargetItemDrop && item_drop_modifier() <= kTargetItemDrop * 2));

	try {
		tries = 1.5 * numberToGet;
		while (numberToGet > 0 && tries > 0) {
			monster [] monsterArray = {$monster[blur]};
			if (getBeatlesOnYellowRay && canYellowRay()) monsterArray = {$monster[blur], $monster[swarm of scarab beatles]};

			skill skillToUse = $skill[none];
			string dressupTweak = "";

			// only do YR processing if we have already olfacted the blur -- otherwise the beatles will be olfacted and then we'll be sad
			if (canYellowRay() && getBeatlesOnYellowRay && isOlfacted($monster[blur])) {
				monsterArray = {$monster[swarm of scarab beatles], $monster[blur]}; // beatles need to be first or the yellow ray won't fire

				PrioritySkillRecord psr = chooseYellowRaySkill();
				skillToUse = psr.theSkill;
				if (psr.theItem != $item[none])
					dressupTweak = "equip " + psr.theItem;
			}
			if (skillToUse == $skill[none] &&  !isOlfacted($monster[blur])) {
				skillToUse = $skill[Transcendent Olfaction];
			}

			// if the vote monster comes up, we might be in targetMob for 2 turns
			// if we're looking for more than 1 mob, we might be in targetMob for an unspecified number of turns
			// if another wandering mob (event mobs for example) comes up, we might be in targetMob for an unspecified number of turns
			// if we're not targeting optimally, we might be targetMob for more than 1 turn -- we are currently only targeting optimally
			if (have_effect($effect[Ultrahydrated]) == 0) {
				if (!get_property("_freePillKeeperUsed").to_boolean())
					cli_execute("pillkeeper free semirare");
			}

			// target that mob
			assert(item_drop_modifier() >= kTargetItemDrop, "grindDrumMachine: not enough +item"); // TODO: this might get triggered when we redirect
			dressup(dressupTweak);
			if (targetMob($location[The Oasis], monsterArray, skillToUse, 0, true, maxPerTurnCost))
				numberToGet--;
			print("blur: " + ((monsterTotalMeatValue($monster[blur], item_drop_modifier(), meat_drop_modifier()) - perAdventureCost() - mall_price($item[ten-leaf clover])/20) * 0.95)); // include cost of the ten-leaf clover and the 1 turn in 20 to get Ultrahydrated

			tries--;
		}
	} finally {
		if (have_item($item[ten-leaf clover]))
			use(item_amount($item[ten-leaf clover]), $item[ten-leaf clover]);
	}
}


void grindDrumMachine(int maxPerTurnCost, boolean getBeatlesOnYellowRay, int banishesToSave) {
	printPSRArray(true, false, $location[The Oasis], maxPerTurnCost);
	int banishesAvailable = max(0, banishesAvailable(maxPerTurnCost) - banishesToSave);
	if (banishesAvailable > 0)
		grindDrumMachine(min(banishesAvailable * 10, my_adventures() - 10), maxPerTurnCost, getBeatlesOnYellowRay);
}


void grindDrumMachine(int maxPerTurnCost, boolean getBeatlesOnYellowRay) {
	printPSRArray(true, false, $location[The Oasis], maxPerTurnCost);
	int banishesAvailable = banishesAvailable(maxPerTurnCost);
	if (banishesAvailable > 0)
		grindDrumMachine(min((banishesAvailable + 1) * 10, my_adventures() - 10), maxPerTurnCost, getBeatlesOnYellowRay);
}



void useDrumMachine(int turnsToGrind) {
	automate_dressup($location[none], "item", "item", "-equip \"i voted\" sticker");
	if (isAsdonWorkshed())
		fueled_asdonmartin("observantly", turnsToGrind);
	//sweetSynthesis($effect[Synthesis: Collection], turnsToGrind);
	briefcase_if_needed($effect[Items Are Forever], turnsToGrind);
	use(turnsToGrind, $item[drum machine]);
}


void grindThugnderdome(int turnsToGrind, int maxPerTurnCost) {
	setDefaultMood();
	if (isFloundryLocation($location[Thugnderdome]) && have_item($item[wriggling worm]))
		use_if_needed($item[wriggling worm], $effect[Baited Hook], turnsToGrind);
	if (isAsdonWorkshed() && (!drivingAsdonMartin() || have_effect($effect[Driving Observantly]) < turnsToGrind))
		fueled_asdonmartin("observantly", turnsToGrind);
	//sweetSynthesis($effect[Synthesis: Collection], turnsToGrind);
	briefcase_if_needed($effect[Items Are Forever], turnsToGrind);
	automate_dressup($location[Thugnderdome], "item", "item", "0.1 meat");

	monster [] monsterArray = {$monster[gnarly gnome], $monster[gnasty gnome]};
	targetMob($location[Thugnderdome], monsterArray, $skill[none], turnsToGrind, false, maxPerTurnCost);
}


void burnYellowRays(int maxPerTurnCost, boolean useClover) {
	try {
		setMood("current, meat");
		set_property("choiceAdventure1387", "3");

		automate_dressup($location[The Oasis], "meat", "default", "-equip Kramco Sausage-o-Matic&trade;");

		int tries = 30; // random guess
		while (canYellowRay() && tries > 0) {
			prepForYellowRay();
			skill skillToUse = chooseYellowRaySkill().theSkill;

			if (have_effect($effect[Ultrahydrated]) == 0 && useClover) {
				if (!get_property("_freePillKeeperUsed").to_boolean())
					cli_execute("pillkeeper free semirare");
			}
			if (isFloundryLocation($location[The Oasis]) && have_item($item[wriggling worm]))
				use_if_needed($item[wriggling worm], $effect[Baited Hook], 2);

			tm($location[The Oasis], $monster[swarm of scarab beatles], skillToUse, 1, true, maxPerTurnCost);

			tries--;
		}
	} finally {
		remove_property("choiceAdventure1387");
	}
}


void grindBeerLens(int maxPerTurnCost) {
	print("grindBeerLens", "green");
	int banishesAvailable = banishesAvailable(maxPerTurnCost);
	if (banishesAvailable < 3) {
		print("not enough banishes available, skipping", "blue");
		return;
	}

	int beerLensToGet = 3 - to_int(get_property("_beerLensDrops"));
	if (beerLensToGet > 0) {
		setCurrentMood("meat");
		string maxString = "meat";
		automate_dressup($location[A Barroom Brawl], "item 300 min", "item [tracker]", maxString);
		healIfRequiredWithMPRestore();

		monster [] bestTarget = {$monster[unemployed knob goblin]};
		while (beerLensToGet > 0) {
			targetMob($location[A Barroom Brawl], bestTarget, $skill[none], beerLensToGet, true, maxPerTurnCost); // optimal, ignore cost
			beerLensToGet = 3 - to_int(get_property("_beerLensDrops"));
		}
	}
}


void grindDailyDungeon() {
	print("grindDailyDungeon", "green");
	if (!to_boolean(get_property("dailyDungeonDone"))) {
		setDefaultState();
		automate_dressup($location[The Daily Dungeon], "mp regen", "default", "+equip ring of detect boring doors");
		int roomsToDo = 15 - to_int(get_property("_lastDailyDungeonRoom"));
		while (roomsToDo > 0) {
			healIfRequiredWithMPRestore();
			redirectAdventure($location[The Daily Dungeon], 1);
			roomsToDo = 15 - to_int(get_property("_lastDailyDungeonRoom"));
		}
	}
}



void remove_properties(string filter) {
	foreach prop in get_all_properties(filter, false) { // false = not global properties file
		if (user_confirm("Should we delete property '" + prop + "'?\nValue = '" + get_property(prop) + "'"))
			remove_property(prop, false); // false = not global properties file
	}
}



// -------------------------------------
// AUTOMATION -- GRINDING -- SEA QUEST
// -------------------------------------

boolean getFishy(int minTurns) {
	int neededFishy = minTurns - have_effect($effect[Fishy]);
	if (neededFishy <= 0) return true;

	int skateParkFishy = get_property("skateParkStatus") == "ice" ? 30 : 0;
	int pipeFishy = get_property("_fishyPipeUsed").to_boolean() ? 0 : 10;

	if (pipeFishy >= neededFishy) {
		use(1, $item[fishy pipe]);
		neededFishy = minTurns - have_effect($effect[Fishy]);
	}

	if (skateParkFishy >= neededFishy) {
		cli_execute("skate lutz");
		neededFishy = minTurns - have_effect($effect[Fishy]);
	}

	return have_effect($effect[Fishy]) >= minTurns;
}


boolean getBreathWater(int minTurns) {
	assert(breatheWater() == 0, "getBreathWater: we're already breathing water");
	assert(minTurns <= 20, "getBreathWater: can't get more than 20 turns of breathing water at a time");

	item [] breatheWaterItems = {$item[hyperinflated seal lung], $item[ballast turtle], $item[tempura air], $item[pressurized potion of pneumaticity]};
	sort breatheWaterItems by -historical_price(value);
	int idx = 0;
	while (breatheWater() == 0) {
		item breatheWaterItem = breatheWaterItems[idx++];
		if (have_item(breatheWaterItem))
			use(1, breatheWaterItem);
	}

	if (breatheWater() == 0 && isAsdonWorkshed())
		safeFueledAsdonMartin($effect[Driving Observantly], minTurns);

	return breatheWater() >= minTurns;
}


// prep for success in the sea
// gets fishy, underwater breathing and reduces pressure penalties as possible
void prepForSea(location seaLocation, boolean isGrinding, int seaTurns) {
	print("prepForSea: lasso training: " + get_property("lassoTraining"));

	if (have_effect($effect[Fishy]) < seaTurns)
		getFishy(seaTurns);
	assert(have_effect($effect[Fishy]) >= seaTurns, "wasn't able to get " + seaTurns + " turns of Fishy");

	if (breatheWater() == 0) // water-breathing buffs overlap, so only get a new one when we run out of the last
		getBreathWater(seaTurns);
	assert(breatheWater() >= seaTurns, "wasn't able to get " + seaTurns + " turns of water breathing");

	// REDUCE PRESSURE
	ensureSongRoom($skill[Donho's Bubbly Ballad]);
	if (have_skill($skill[Donho's Bubbly Ballad]))
		buffIfNeededWithUneffect($skill[Donho's Bubbly Ballad], seaTurns);
	else
		use_if_needed($item[recording of Donho's Bubbly Ballad], $effect[Donho's Bubbly Ballad], seaTurns);
	assert(have_effect($effect[Donho's Bubbly Ballad]) >= seaTurns, "did not get Donho effect");
	//use shavin' razor; use mer-kin fastjuice; use shark cartilage;

	if (isGrinding)
		buffForItemDrop(seaTurns);

	setDefaultMood(); // fill up mood
}


// dress for success in the sea
void dressForSea(location seaLocation, boolean isGrinding) { // sea_quest sea quest
	boolean unused;
	fullAcquire($item[cozy scimitar]);

	string selectorString = "";
	string familiarString = "robortender [tracker]";
	//string maxString = "+equip lucky gold ring, -equip \"i voted\" sticker, -equip Kramco Sausage-o-Matic&trade;, -equip pantogram pants, -equip aerogel attache case, -equip mafia thumb ring"; // needed to stop some automation
	string maxString = "-equip \"i voted\" sticker, -equip Kramco Sausage-o-Matic&trade;, -equip mafia thumb ring";
// 	if (my_class() == $class[accordion thief]) // causes problems in octopus' garden
// 		maxString += ", +four songs";

	if (seaLocation == $location[An Octopus's Garden]) {
		setCurrentMood("-combat");
		selectorString = "-5 combat";
		familiarString = "";
		use_familiar($familiar[Robortender]); equip($item[toggle switch (Bartend)]);
		maxString += ", 0.1 item, 0.01 hp, +equip straw hat";
		if (can_equip($item[octopus's spade]))
			maxString += ", +equip octopus's spade";

	} else if ((seaLocation == $location[The Wreck of the Edgar Fitzsimmons] || seaLocation == $location[The Mer-Kin Outpost]) && !isGrinding) {
		setCurrentMood("-combat");
		selectorString = "-combat";
		familiarString = "robortender";
		use_familiar($familiar[Robortender]); equip($item[toggle switch (Bartend)]);
		if (can_equip($item[sea salt scrubs]))
			maxString += ", +equip sea salt scrubs";
		if (can_equip($item[cozy scimitar]))
			maxString += ", +equip cozy scimitar";

	} else if (seaLocation == $location[The Wreck of the Edgar Fitzsimmons] && isGrinding) {
		// option 1: drowned sailor
// 		setCurrentMood("+combat");
// 		selectorString = "item";
// 		maxString += ", +10 combat, -equip pantogram pants, -equip aerogel attache case";
// 		setRedNosedSnapperGuideMe("undead");

		// option 2: unholy diver
		setCurrentMood("-combat");
		selectorString = "item";
		maxString += ", -50 combat, -equip pantogram pants, -equip aerogel attache case";
		setRedNosedSnapperGuideMe("horror");

		if (to_int(get_property("garbageChampagneCharge")) > 0)
			maxString += ", +equip broken champagne bottle";
		else if (can_equip($item[cozy scimitar]))
			maxString += ", +equip cozy scimitar";
		if ((to_int(get_property("_chestXRayUsed")) < 3) || (to_int(get_property("_otoscopeUsed")) < 3))
			maxString += ", +equip Lil' Doctor&trade; bag";
		if (to_int(get_property("_vampyreCloakeFormUses")) < 10)
			maxString += ", +equip vampyric cloake";

	} else if (seaLocation == $location[The Mer-Kin Outpost] && isGrinding) {
		setCurrentMood("+combat");
		selectorString = "item";
		maxString += ", +combat, -equip pantogram pants, -equip aerogel attache case";
		if (to_int(get_property("garbageChampagneCharge")) > 0)
			maxString += ", +equip broken champagne bottle";
		else if (can_equip($item[cozy scimitar]))
			maxString += ", +equip cozy scimitar";
		if ((to_int(get_property("_chestXRayUsed")) < 3) || (to_int(get_property("_otoscopeUsed")) < 3))
			maxString += ", +equip Lil' Doctor&trade; bag";
		if (to_int(get_property("_vampyreCloakeFormUses")) < 10)
			maxString += ", +equip vampyric cloake";

	} else if (seaLocation == $location[Anemone Mine] && !isGrinding) {
		setCurrentMood("-combat");
		selectorString = "-5 combat";
		familiarString = "red-nosed snapper";
		if (can_equip($item[sea salt scrubs]))
			maxString += ", +equip sea salt scrubs";
		if (can_equip($item[cozy scimitar]))
			maxString += ", +equip cozy scimitar";
		if (get_property("redSnapperPhylum") != "horror")
			setRedNosedSnapperGuideMe("horror");

	} else if (seaLocation == $location[The Marinara Trench]) {
		setCurrentMood("-combat");
		if (isGrinding)
			maxString += ", 5 item";
		else
			maxString += ", item";
		if (get_property("redSnapperPhylum") != "merkin")
			setRedNosedSnapperGuideMe("merkin");
		maxString += ", -50 combat";
		if (can_equip($item[cozy scimitar]))
			maxString += ", +equip cozy scimitar";
		if ((to_int(get_property("_chestXRayUsed")) < 3))
			maxString += ", +equip Lil' Doctor&trade; bag";

	} else if (seaLocation == $location[The Dive Bar]) {
		if (isGrinding) {
			setDefaultMood();
			selectorString = "item";
		} else {
			setCurrentMood("-combat");
			selectorString = "-combat";
		}
		maxString += ", -equip pantogram pants, -equip aerogel attache case";
		if (to_int(get_property("garbageChampagneCharge")) > 0)
			maxString += ", +equip broken champagne bottle";
		else if (can_equip($item[cozy scimitar]))
			maxString += ", +equip cozy scimitar";
		if ((to_int(get_property("_chestXRayUsed")) < 3) || (to_int(get_property("_otoscopeUsed")) < 3))
			maxString += ", +equip Lil' Doctor&trade; bag";
		if (to_int(get_property("_vampyreCloakeFormUses")) < 10)
			maxString += ", +equip vampyric cloake";
		familiarString = "";
		use_familiar($familiar[Robortender]); equip($item[toggle switch (Bartend)]);

	} else if (seaLocation == $location[Madness Reef]) {
		if (isGrinding) {
			setCurrentMood("+combat");
			maxString += ", +combat";
		}
		else {
			setCurrentMood("-combat");
			maxString += ", -combat";
		}
		maxString += ", 10 item";
		if (to_int(get_property("garbageChampagneCharge")) > 0)
			maxString += ", +equip broken champagne bottle";
		else if (can_equip($item[cozy scimitar]))
			maxString += ", +equip cozy scimitar";
		if ((to_int(get_property("_chestXRayUsed")) < 3) || (to_int(get_property("_otoscopeUsed")) < 3))
			maxString += ", +equip Lil' Doctor&trade; bag";
		if (to_int(get_property("_vampyreCloakeFormUses")) < 10)
			maxString += ", +equip vampyric cloake";

	} else if (seaLocation == $location[The Coral Corral] && !isGrinding) {
		setCurrentMood("meat");
		selectorString = "item";
		maxString += ", +equip aquamariner's necklace, +equip aquamariner's ring";
		if (can_equip($item[sea salt scrubs]))
			maxString += ", +equip sea salt scrubs";
		if (can_equip($item[cozy scimitar]))
			maxString += ", +equip cozy scimitar";
		familiarString = "";
		use_familiar($familiar[Robortender]); equip($item[toggle switch (Bartend)]);

	} else if ((seaLocation == $location[The Coral Corral] || seaLocation == $location[Anemone Mine]) && isGrinding) {
		setCurrentMood("meat");
		selectorString = "item";
		maxString += ", +equip aquamariner's necklace, +equip aquamariner's ring";
		if (can_equip($item[sea salt scrubs]))
			maxString += ", +equip sea salt scrubs";
		if (can_equip($item[cozy scimitar]))
			maxString += ", +equip cozy scimitar";

	} else if (seaLocation == $location[The Skate Park]) {
		setCurrentMood("-combat");
		selectorString = "-combat";

	} else if (seaLocation == $location[The Caliginous Abyss]) {
		setCurrentMood("-combat");
		selectorString = "-combat";
		maxString += ", +equip black glass, +equip shark jumper, +equip scale-mail underwear";
		if (can_equip($item[cozy scimitar]))
			maxString += ", +equip cozy scimitar";
		use_if_needed($item[comb jelly], $effect[Jelly Combed], 20);

	} else if (seaLocation == $location[Mer-kin Elementary School]) {
		setCurrentMood("-combat");
		maxString += ", -combat, item, outfit Mer-kin Scholar's Vestments";
		if (can_equip($item[cozy scimitar]))
			maxString += ", +equip cozy scimitar";

	} else if (seaLocation == $location[Mer-kin Library]) {
		setDefaultMood();
		maxString += ", item, outfit Mer-kin Scholar's Vestments";
		if (can_equip($item[cozy scimitar]))
			maxString += ", +equip cozy scimitar";

	} else if (seaLocation == $location[Mer-kin Gymnasium] || seaLocation == $location[Mer-kin Colosseum]) {
		setDefaultMood();
		maxString += ", item, outfit Mer-kin Gladiatorial Gear";
		if (can_equip($item[cozy scimitar]))
			maxString += ", +equip cozy scimitar";

	} else {
		setDefaultMood();
		selectorString = "item";
		if (can_equip($item[cozy scimitar]))
			maxString += ", +equip cozy scimitar";
		familiarString = "";
	}

	if (get_property("lassoTraining") != "expertly" && seaLocation != $location[An Octopus's Garden] && !isGrinding) {
		maxString += ", +equip sea cowboy hat, +equip sea chaps";
	}

	if (familiarString.contains_text("robortender")) {
		use_familiar($familiar[robortender]);
		unused = cli_execute("robo bloody nora");
	}

	//use_familiar($familiar[Space Jellyfish]); equip($item[Li'l Businessman Kit]); // kit = more sand dollars
	//use_familiar($familiar[Robortender]); equip($item[toggle switch (Bartend)]); doseRobortender();
	//unused = cli_execute("robo bloody nora");
	automate_dressup(seaLocation, selectorString, familiarString, maxString);

	string currentMood = getMood();
	if (currentMood.contains_text("-combat") && combat_rate_modifier() > -25)
		abort("didn't get enough -combat!");
	if (currentMood.contains_text("+combat") && combat_rate_modifier() < 25)
		abort("didn't get enough +combat!");
}


// prep for and dress for success in the sea
// gets fishy, underwater breathing and reduces pressure penalties as possible
void seaQuest(location seaLocation, boolean isGrinding) { // sea_quest sea quest
	int turns = breatheWater() > 0 ? breatheWater() : 20;
	prepForSea(seaLocation, isGrinding, turns);
	dressForSea(seaLocation, isGrinding);
}


// favour stranglin' algae if we don't favourGardener
void grindOctopusesGarden(int turnsToGrind, int maxPerTurnCost, boolean favourGardener) {
	setCurrentMood("-combat");
	seaQuest($location[An Octopus's Garden], true);
	if (isAsdonWorkshed() && (!drivingAsdonMartin() || have_effect($effect[Driving Observantly]) < turnsToGrind))
		safeFueledAsdonMartin($effect[Driving Observantly], turnsToGrind);
	//sweetSynthesis($effect[Synthesis: Collection], turnsToGrind);

	monster [] monsterArray = {$monster[octopus gardener], $monster[stranglin' algae]};
	if (!favourGardener) monsterArray = {$monster[stranglin' algae], $monster[octopus gardener]};
	targetMob($location[An Octopus's Garden], monsterArray, $skill[none], turnsToGrind, true, maxPerTurnCost);
}


void grindSeaLocation(location seaLocation, monster [] targetArray, boolean maximizeItemDrop, int turnsToGrind, int maxPerTurnCost) {
	print("grinding sea location: " + seaLocation + ", targetting: " + targetArray[0] + " (total targets: " + count(targetArray) + ") turns to grind: " + turnsToGrind + ", ignore cost: " + maxPerTurnCost, "green");

	seaQuest(seaLocation, true);

	// do all this for the results of Harpoon! and Summon Leviatuga OR just wield the broken champagne bottle and the rest of the items and let the consult script do the rest
	int tries = min(turnsToGrind, have_effect($effect[fishy])) + instaKillsAvailable() + 5; // some extra tries for turtle finding
	while (have_effect($effect[fishy]) > 0 && have_effect($effect[Donho's Bubbly Ballad]) > 0 && canBreatheWater() && tries > 0) {
		string itemScript = main_sub() + init_sub() + setup_aborts_sub() + "call init;";

		if (equipped_amount($item[cozy scimitar]) == 1)
			itemScript += "skill Summon Leviatuga; skill Harpoon!; ";

		//itemScript += "if monstername \"*" + targetArray[0] + "*\";  skill Transcendent Olfaction; skill Gallapagosian Mating Call; skill Offer Latte to Opponent; "; // this stuff happens above?????
		itemScript += "if monstername \"*" + targetArray[0] + "*\"; ";

		if (maximizeItemDrop && equipped_amount($item[vampyric cloake]) >= 1 && to_int(get_property("_vampyreCloakeFormUses")) < 10)
			itemScript += "skill become a bat;";

		if (maximizeItemDrop && equipped_amount($item[Lil' Doctor&trade; bag]) >= 1 && to_int(get_property("_otoscopeUsed")) < 3)
			itemScript += "skill otoscope;";

		PrioritySkillRecord instaKillSkill = chooseInstaKillSkill();
		if (instaKillSkill.theSkill != $skill[none]) {
			itemScript += "skill " + instaKillSkill.theSkill + ";";
			if (instaKillSkill.theItem != $item[none])
				dressup("equip " + instaKillSkill.theItem);
		}

		itemScript += "endif;";
		itemScript += "call main;repeat;";

		healIfRequiredWithMPRestore();
		if (!adv1TargetingMobs(seaLocation, targetArray, maxPerTurnCost, itemScript) && !arrayContains(targetArray, last_monster())) {
			// wrong target or failed adventuring in the sea
			//print("failed adventuring in the sea!", "red");
		}
		if (available_amount($item[cozy scimitar]) == 0)
			fullAcquire($item[cozy scimitar]);

		seaQuest(seaLocation, true);
		tries--;
	}
}


void grindMerkinOutpost(int turnsToGrind, int maxPerTurnCost) {
	set_property("choiceAdventure312", "4");
	monster [] monsterArray = {$monster[mer-kin raider]};

	grindSeaLocation($location[The Mer-Kin Outpost], monsterArray, true, turnsToGrind, maxPerTurnCost);

	set_property("choiceAdventur312", "");
	put_shop(0, 0, available_amount($item[Mer-kin breastplate]) - 1, $item[Mer-kin breastplate]);
}


void grindEdgarFitzsimmons(int turnsToGrind, int maxPerTurnCost) {
	// drowned sailor
// 	set_property("choiceAdventure299", "2");
// 	monster mainTarget = $monster[drowned sailor];
// 	monster [] monsterArray = {$monster[drowned sailor]};
	// unholy diver
	set_property("choiceAdventure299", "1");
	monster mainTarget = $monster[unholy diver];
	monster [] monsterArray = {$monster[unholy diver]};

	grindSeaLocation($location[The Wreck of the Edgar Fitzsimmons], monsterArray, true, turnsToGrind, maxPerTurnCost);

	set_property("choiceAdventure299", "");
}


// champagne bottle is overkill (mer-kin diver's biggest drop is 10%), but other +item is not
void grindMarinaraTrench(int turnsToGrind, int maxPerTurnCost) {
	monster [] monsterArray = {$monster[mer-kin diver]};
	grindSeaLocation($location[The Marinara Trench], monsterArray, true, turnsToGrind, maxPerTurnCost);
}


void grindCoralCorral(int turnsToGrind, int maxPerTurnCost) {
	monster [] monsterArray = {$monster[sea cow], $monster[sea cowboy]};
	grindSeaLocation($location[The Coral Corral], monsterArray, true, turnsToGrind, maxPerTurnCost);
}


// target mer-kin tippler if we don't targetNurseShark
void grindDiveBar(int turnsToGrind, int maxPerTurnCost, boolean targetNurseShark) {
	seaQuest($location[The Dive Bar], true);

	monster [] monsterArray = {$monster[nurse shark]};
	if (!targetNurseShark) {
		monsterArray = {$monster[mer-kin tippler]};
	}

	grindSeaLocation($location[The Dive Bar], monsterArray, true, turnsToGrind, maxPerTurnCost);

// shop put -1 nurse's hat;
// shop put -1 sea salt scrubs;
// shop put -250 slug of rum;
// shop put -250 alewife ale;
// shop put -250 mer-kin pinkslip;
// shop put * blank prescription sheet;
// print dolphinItem
}


void grindMadnessReef(int turnsToGrind, int maxPerTurnCost) {
	monster [] monsterArray = {$monster[jamfish], $monster[magic dragonfish]};
	grindSeaLocation($location[Madness Reef], monsterArray, true, turnsToGrind, maxPerTurnCost);
}



// -------------------------------------
// AUTOMATION -- GRINDING -- END GAME
// -------------------------------------


void grindHobopolisSewers(int maxPerTurnCost) {
	setDefaultState();
	setCurrentMood("-combat");
	int neededDropBonus = itemDropBonusNeededToGuarantee($item[bottle of sewage schnapps], $monster[C. H. U. M.]);

	// don't equip the pants so we can get more +item, don't equip the mafia thumb ring so we can get more -combat
	automate_dressup($location[A Maze of Sewer Tunnels], "-20 combat", "item", "0.2 item, 0.1 pickpocket chance, 0.01 init, equip Li'l Businessman Kit, equip hobo code binder, equip gatorskin umbrella, -equip pantogram pants, -equip mafia thumb ring");
	if (item_drop_modifier() < neededDropBonus && isAsdonWorkshed())
		safeFueledAsdonMartin($effect[Driving Observantly], 1);

	monster [] targets = {$monster[C. H. U. M.]};
	while (true) {
		healIfRequiredWithMPRestore();

		dressup();
		assert(combat_rate_modifier() <= -25.0 || equipped_amount($item[&quot;I Voted!&quot; sticker]) > 0, "not enough -combat");
		targetMob($location[A Maze of Sewer Tunnels], targets, $skill[none], 1, false, maxPerTurnCost); // not optimal, ignore cost
	}
}



int expectedCoatedInSlimeDmg(int coatedTurns) {
	int effective_turns = max(0, 11 - coatedTurns);
	float res_percent = 100.0 - elemental_resistance($element[slime]);
	return expression_eval("ceil(" + effective_turns + "^2.727*" + res_percent + "*" + my_maxhp() + "/10000)");
}

int expectedCoatedInSlimeDmg() {
	int coatedTurns = have_effect($effect[Coated in Slime]);
	if (coatedTurns == 0) coatedTurns = max(1, 11 - ceil(monster_level_adjustment() / 100.0));
	return expectedCoatedInSlimeDmg(coatedTurns);
}

int safeExpectedCoatedInSlimeDmg() {
	return expectedCoatedInSlimeDmg() * kExpectedDamageSafetyFactor;
}


// adventure in the slime tube with the current outfit until adventuring would cause us to be beaten up
// then clear the Coated in Slime debuff with either a hottub soak or a chamois
// buffs with free/cheap monster-level adjustment skills
void slimetube(boolean wantEngulfed, boolean burnSpleen) {
	int coatedTurns = have_effect($effect[Coated in Slime]);
	print("slimetube with " + coatedTurns + " turns of Coated in Slime, Slime res: " + numeric_modifier("Slime Resistance"), "blue");

	int turnsToSpend = coatedTurns;
	if (coatedTurns == 0)
		turnsToSpend = max(1, 11 - ceil(monster_level_adjustment() / 100.0));

	if (wantEngulfed)
		setCurrentMood("ml, -combat");
	else
		setCurrentMood("ml, +combat");
	if (my_spleen_use() < spleen_limit() && burnSpleen)
		cli_execute_if_needed("synthesize crimbo fudge, senior mints", $effect[Synthesis: Strong], turnsToSpend); 
	if (isAsdonWorkshed())
		safeFueledAsdonMartin($effect[Driving Recklessly], turnsToSpend);
	max_mcd();

	int expectedDmg = safeExpectedCoatedInSlimeDmg();
	int tries = 15;
	while (expectedDmg < my_maxhp() && tries > 0) {
		haveAtLeastHP(expectedDmg);
		restore_mp(mp_cost($skill[saucestorm]) * 6);
		print("entering combat with " + my_hp() + " hp, expecting " + expectedDmg + " dmg.");
		adv1($location[The Slime Tube], -1, "");
		if (have_effect($effect[Beaten Up]) > 0) abort("unexpectedly beaten up! expected dmg: " + expectedDmg);
		//if (!contains_monster($location[The Slime Tube], last_monster())) abort("wandering monster? " + last_monster());

		expectedDmg = safeExpectedCoatedInSlimeDmg();
		tries--;
	}

	print("exiting The Slime Tube with " + have_effect($effect[Coated in Slime]) + " turns of Coated in Slime", "green");

	if (get_property("_hotTubSoaks") < 5)
		cli_execute("hottub");
	else
		cli_execute("chamois");
	assert(have_effect($effect[Coated in Slime]) == 0, "still have Coated in Slime!!!");
}


// for low-ml, casual grinding
// dresses in low-ml outfit for first adventure (i.e. without Coated in Slime)
// otherwise, dresses in high-ml outfit
void slimetubeWithDressup(boolean wantEngulfed, boolean burnSpleen, int runawayMaxCost) {
	// getting the Coated in Slime debuff with the least ML means we can last longer
	int coatedTurns = have_effect($effect[Coated in Slime]);
	if (coatedTurns == 0) {
		uneffect($effect[Ur-Kel's Aria of Annoyance]);
		setCurrentMood("+combat");

		boolean canRunaway = canFreeRunaway(runawayMaxCost);
		string maxString = "-equip pantogram pants, -familiar";
		if (canRunaway)
			maxString += ", -equip mafia thumb ring";

		automate_dressup($location[The Slime Tube], "-ml", "robortender", maxString);

		int tries = 3;
		while (coatedTurns == 0 && tries > 0) {
			ActionRecord freeRunaway;
			string tweakString = "";
			if (canRunaway) {
				freeRunaway = chooseFreeRunaway(runawayMaxCost);
				tweakString = equipStringForAction(freeRunaway);
			}
			dressup(tweakString);

			restore_mp(mp_cost($skill[saucestorm]) * 6);
			string aPage = advURLWithWanderingMonsterRedirect($location[The Slime Tube]);

			if (isErrorPage(aPage)) {
				print("got an error page:\n" + aPage, "red");
				abort("slimetubeWithDressup: didn't get to the slime tube");
			}
			if (handling_choice()) {
				run_choice(-1);
				continue;
			}

			steal();
			if (canRunaway && contains_monster($location[The Slime Tube], last_monster()))
				takeAction(freeRunaway);
			else
				run_combat();
			postAdventure();

			coatedTurns = have_effect($effect[Coated in Slime]);
			tries--;
		}

// 		assert(last_monster() == $monster[slime tube monster], "wandering monster? " + last_monster());
		assert(coatedTurns > 0, "didn't get Coated in Slime??");
	}

	clear_automate_dressup();
	use_familiar($familiar[robortender]); equip($item[toggle switch (Bartend)]);
	maximize("0.1 ml, 10 slime res, -familiar", false);
	maximize("0.1 ml, 10 slime res, -familiar", false);
	assert(numeric_modifier("Slime Resistance") >= 3.0, "not enough slime resistance to proceed!");

	slimetube(wantEngulfed, burnSpleen);
}



void grindDreadsylvania(location dreadLoc, int grindTurns) {
	setDefaultState();
	setCurrentMood("+combat, [primestat]gains");
	string maxString = "+combat, 0.01 mp regen, -equip pantogram pants"; // not sure if we should equip the pantogram pants or not

	if (my_basestat($stat[muscle]) < 200) {
		if (!user_confirm("Can't equip the dreadful glove (need 200 base mus). Continue without the glove?", 60000, false))
			abort();
	} else
		maxString += ", equip dreadful glove";

	if (my_basestat($stat[moxie]) < 200) {
		if (!user_confirm("Can't equip the dreadful fedora (need 200 base mox). Continue without the fedora?", 60000, false))
			abort();
	} else
		maxString += ", equip dreadful fedora";

	if (my_basestat($stat[mysticality]) < 200) {
		if (!user_confirm("Can't equip the dreadful sweater (need 200 base mys). Continue without the sweater?", 60000, false))
			abort();
	} else
		maxString += ", equip dreadful sweater";

	if (isAsdonWorkshed())
		fueled_asdonmartin("observantly", grindTurns);
	automate_dressup(dreadLoc, "item", "item", maxString);

	healIfRequiredWithMPRestore();
	redirectAdventure(dreadLoc, grindTurns);
}



void grindTatteredScrapOfPaper(int kills, int maxPerTurnCost) {
	setDefaultMood();
	automate_dressup($location[The Haunted Library], "item", "item", "+switch cat burglar");

	if (isAsdonWorkshed())
		fueled_asdonmartin("observantly", kills);
	briefcase_if_needed($effect[Items Are Forever], kills);
	// sweetSynthesis($effect[Synthesis: Collection], kills); // analysis indicates better meat/turn with coffee pixie sticks

	tm($location[The Haunted Library], $monster[bookbat], $skill[none], kills, true, maxPerTurnCost);
}



// -------------------------------------
// AUTOMATION -- GRINDING -- ULTRARARE
// -------------------------------------

// PYEC
void grindPlatinumYendoranExpressCard(int times) {
	try {
		setDefaultState();
		skill [] songsToPlay = {$skill[Carlweather's Cantata of Confrontation], $skill[Ur-Kel's Aria of Annoyance], $skill[Aloysius' Antiphon of Aptitude]};
		ensureSongRoom(songsToPlay);
		setCurrentMood("+combat, ml, [primestat]gains");

		saveAndSetProperty("choiceAdventure25", "1"); // 1 for magic lamp, 2 for mimic, 3 for skip

		automate_dressup($location[The Dungeons of Doom], "item", "default", "+20 combat 25 min 25 max");

		healIfRequiredWithMPRestore();
		redirectAdventure($location[The Dungeons of Doom], times);

	} finally {
		restoreSavedProperty("choiceAdventure25");
	}
}

void grindPlatinumYendoranExpressCard() {
	grindPlatinumYendoranExpressCard(min(my_adventures(), 20));
}



// -------------------------------------
// AUTOMATION -- GRINDING -- EVENTS
// -------------------------------------

void donateResourcesCrimbo2020(boolean allResources, string player) {
	string pageResult;

	if (allResources) {
		pageResult = visit_url("/inv_use.php?pwd&which=3&whichitem=10685", true, false);
		pageResult = visit_url("/choice.php?whichchoice=1442&option=1&pwd&who=" + player, true, false);
		if (pageResult.contains_text("You fill out all the appropriate forms"))
			print("sent food to " + player);
		else
			print("send failed!", "red");

		pageResult = visit_url("/inv_use.php?pwd&which=3&whichitem=10686", true, false);
		pageResult = visit_url("/choice.php?whichchoice=1443&option=1&pwd&who=" + player, true, false);
		if (pageResult.contains_text("You fill out all the appropriate forms"))
			print("sent booze to " + player);
		else
			print("send failed!", "red");
	}

	pageResult = visit_url("/inv_use.php?pwd&which=3&whichitem=10687", true, false);
 	pageResult = visit_url("/choice.php?whichchoice=1444&option=1&pwd&who=" + player, true, false);
 	if (pageResult.contains_text("You fill out all the appropriate forms"))
	 	print("sent candy to " + player);
	else
		print("send failed!", "red");
}



void grindCrimbo2019(location seaLoc, monster sideCritter, int kills) {
	if (available_amount($item[cozy scimitar]) == 0)
		fullAcquire($item[cozy scimitar]);

	if (seaLoc == $location[gingerbread reef] || seaLoc == $location[The Wreck of the H. M. S. Kringle] || seaLoc == $location[The Impenetrable Kelp-Holly Forest]) {
		prepForSea(seaLoc, true, kills);
		automate_dressup(seaLoc, "", $familiar[red-nosed snapper], "item, +equip cozy scimitar, +equip mime army infiltration glove, +equip thumb ring");
	} else {
		seaQuest(seaLoc, true);
	}

	healIfRequired();

	// stop when the cozy wears out
	clearGoals();
	add_item_condition(1, $item[fish scimitar]);
	
	monster [] monsterArray = {sideCritter, $monster[dolphin "orphan"]};
	targetMob(seaLoc, monsterArray, $skill[none], kills, false, kMaxInt); // not optimal, max cost per turn
}


void grindDolphinOrphans(location seaLoc, monster sideCritter, int kills) {
	fullAcquire($item[cozy scimitar]);
	if (seaLoc == $location[gingerbread reef] || seaLoc == $location[The Wreck of the H. M. S. Kringle] || seaLoc == $location[The Impenetrable Kelp-Holly Forest]) {
		prepForSea(seaLoc, true, kills);
		clear_automate_dressup();
		use_familiar($familiar[red-nosed snapper]);
		maximize("item, +equip cozy scimitar, +equip mime army infiltration glove, +equip thumb ring", false);
	} else {
		seaQuest(seaLoc, true);
	}

	healIfRequired();

	monster [] monsterArray = {$monster[dolphin "orphan"]};
	if (sideCritter != $monster[none])
		monsterArray = {sideCritter, $monster[dolphin "orphan"]};
	targetMob(seaLoc, monsterArray, $skill[none], kills, false, kMaxInt); // not optimal, max cost per turn
}



void semiRare() {
	location [] semiRareLocations = {$location[The Limerick Dungeon], $location[The Castle in the Clouds in the Sky (Top Floor)]};

	// ADV AT A SEMI-RARE LOCATION
	if (fortuneCookie() == my_turncount()) {
		if (have_effect($effect[Teleportitis]) > 0) abort("you have Teleportitis!!!");

		location lastSemiRareLocation = to_location(get_property("semirareLocation"));
		location semiRareLocation = semiRareLocations[0];
		if (semiRareLocation == lastSemiRareLocation)
			semiRareLocation = semiRareLocations[1];
		print("next semi-rare location: " + semiRareLocation);
		adventure(1, semiRareLocation);

	// LEARN NEXT SEMI-RARE
	} else if (fortuneCookie() < my_turncount()) {
		restore_mp(mp_cost($skill[The Ode to Booze]));
		useOdeToBoozeIfNeeded(1);
		cli_execute("drink lucky lindy"); // drink() doesn't work

	} else
		print("fortuneCookie (" + fortuneCookie() + ") does not match turn count (" + my_turncount() + ") -- doing nothing", "red");
}



void doBounty() {
	if (!to_boolean(get_property("_smm.BountyCheckDone"))) {
		cli_execute("bounty");
		if (user_confirm("stop for bounty?", 60000, false))
			abort("bounty");
		else
			set_property("_smm.BountyCheckDone", "true");
	}
}



void dailyNoAdventureGrind() {
	secondBreakfast();
	burnMP(-500);

	grindJellyWithEnemyReplacement(true, true, $item[stench jelly], true); 

	LOVadv($item[LOV Earrings], $effect[Wandering Eye Surgery], $item[LOV Enamorang]);
	burnInigoCrafting();
	burnHP();
	burnMP();

	grindScience(true);
	grindNeverendingParty(true);
}


void dailyDefaultGrind(int [location] endGameTurnsSpent) {
	burnHP();
	burnMP();
}


void dailyFishingGrind(int [location] endGameTurnsSpent, int maxPerTurnCost) {
	print("dailyFishingGrind", "green");

	// SEA QUESTING/GRINDING
	if (have_effect($effect[Fishy]) > 1) { //  && breatheWater() >= 1 won't have breathe water the first time through
		if (!to_boolean(get_property("_smm.PreGrindDone"))) {
			seaQuest($location[the coral corral], true);
			currentIncomeSea();
			currentIncomeSea();
		}
		set_property("_smm.PreGrindDone", "true");

		if (get_property("seahorseName") == "")
			abort("sea quest isn't complete!");
		else if (!to_boolean(get_property("_smm.SeaQuestConfirmDone")) && !user_confirm("grindEdgarFitzsimmons?", 60000, true))
			abort();

// 		grindMarinaraTrench(20, maxPerTurnCost); // mer-kin diver
// 		grindMadnessReef(20, maxPerTurnCost); // jamfish, magic dragonfish
		grindEdgarFitzsimmons(20, maxPerTurnCost); // unholy diver

		assert(have_effect($effect[Fishy]) == 0 || breatheWater() == 0, "we should have used all the Fishy OR all the breathing buff by now!");
		set_property("_smm.SeaQuestConfirmDone", "true");
	}
}


void dailyGrind() {
	int maxPerTurnCost = 0;

	if (have_effect($effect[Fishy]) >= 8)
		set_property("_smm.DailyFishingGrind", "true");

	stockStore();
	int [location] endGameTurnsSpent = endGameTurnsSpent();

	if (!to_boolean(get_property("_smm.secondBreakfastDone"))) {
		secondBreakfast(endGameTurnsSpent);
		burnHP();
		burnMP();
	}

	dailyDeedsAdv(); // 0 adv
	grindJellyWithEnemyReplacement(true, true, $item[sleaze jelly], true); // 0 adv

	if (!to_boolean(get_property("_loveTunnelUsed"))) {
		LOVadv($item[LOV Earrings], $effect[Wandering Eye Surgery], $item[LOV Enamorang]);
		burnInigoCrafting();
	}

	// if we have the Fishy buff from the pipe from yesterday
	if (get_property("_smm.DailyFishingGrind").to_boolean())
		dailyFishingGrind(endGameTurnsSpent, maxPerTurnCost); // 20 turns, burns item buffs
	else
		dailyDefaultGrind(endGameTurnsSpent);

	// stuff that needs BANISHERS
	doBounty(); // 20 adv, 5 banishers?
	if (!to_boolean(get_property("_smm.UseBanishersConfirmDone")) && !user_confirm("We're about to use up the banishers. Continue?", 60000, true))
		abort("user aborted");
	set_property("_smm.UseBanishersConfirmDone", "true");

	// stuff that needs ITEM DROP -- buffs AFTER this point in case we want to stop and burn the 50 Dreadsylvania turns before boss
	if (!get_property("_smm.HighItemConfirmDone").to_boolean() && get_property("garbageChampagneCharge").to_int() > 0
		&& !user_confirm("Continue to high item drop section? Dread woods: "
			+ endGameTurnsSpent[$location[Dreadsylvanian Woods]] + ", village: "
			+ endGameTurnsSpent[$location[Dreadsylvanian Village]] + ", castle: "
			+ endGameTurnsSpent[$location[Dreadsylvanian Castle]], 60000, true))
		abort();
	set_property("_smm.HighItemConfirmDone", "true");

	// stuff that needs ITEM DROP
	if (get_property("garbageChampagneCharge").to_int() > 0) {
		AdventureRecord ar;
		if (endGameTurnsSpent[$location[Dreadsylvanian Woods]] < 930 && (my_basestat($stat[muscle]) >= 200 && my_basestat($stat[mysticality]) >= 200 && my_basestat($stat[moxie]) >= 200)) {
			if (have_item($item[maple magnet]))
				ar = new AdventureRecord($location[Dreadsylvanian Woods], $skill[none], $item[none]);
			else
				ar = new AdventureRecord($location[Dreadsylvanian Village], $skill[none], $item[none]);
		} else
			ar = new AdventureRecord($location[none], $skill[none], $item[drum machine]);

		burnBrokenChampagneBottle(ar);
	}

	grindScience(true); // useSweetSynthesis?
	grindNeverendingParty(true); // useSweetSynthesis?

	if (!to_boolean(get_property("_smm.PreGrindDone"))) {
		use_skill(6 - to_int(get_property("_birdsSoughtToday")), $skill[seek out a bird]);
		maximizeForItemDrop(1);
		currentIncome();
		incomeCalculator();
		set_property("_smm.PreGrindDone", "true");
	}

	if (banishesAvailable(maxPerTurnCost) > 0 && !to_boolean(get_property("_smm.GrindDone"))) {
		grindScarabBeatles(maxPerTurnCost, true, 10); // ignoreCost, doBlur, banishes to save
		stockStore();
		assert(!canYellowRay(), "should have spent all the yellow rays by now");
		set_property("_smm.GrindDone", "true");
	}

	// stuff that needs BANISHERS total 13 right now
	grindBeerLens(0); // 3-5 adv, 4 banishers
	grindGhostCostume(); // 5-11 adv, 9 banishers

	// stuff that doesn't need item drop or banishes
	set_property("choiceAdventure1251", "6");
	grindSpacegate(gkSpacegateCoordinates);
	set_property("choiceAdventure1251", "");

// 	abort("do fantasyrealm, piraterealm, the drip manually with combat lover's locket");
	fantasyrealmBaseGrind();
	fantasyrealmGrind($item[Master Thief's utility belt]);
	grindPirateRealm();
	grindDailyDungeon();
	grindDrip(); // TODO: don't run on the day of breaking the prism

	if (get_property("dolphinItem") != "" && !to_boolean(get_property("_smm.ShouldUseDolphinWhistleQueryDone"))) {
		print("dolphinItem: " + get_property("dolphinItem"), "green");
		if (user_confirm("Use dolphin whistle for dolphinItem: " + get_property("dolphinItem") + ", price: "
			+ mall_price(to_item(get_property("dolphinItem"))), 60000, false))
			cli_execute("use dolphin whistle");
	}
	set_property("_smm.ShouldUseDolphinWhistleQueryDone", "true");

	if (!get_property("_workshedItemUsed").to_boolean() && isAsdonWorkshed()) {
		fueled_asdonmartin("observantly", 600);
		assert(have_effect($effect[Driving Observantly]) >= 600, "didn't get 600 turns of Driving Observantly");
		use(1, $item[cold medicine cabinet]);
	}

	timeToRollover();
}



// burn all remaining buffs and 0-adv stuff like free combats
void good_night() {
	boolean unused;
	if (!isOverdrunk()) abort("should be overdrunk before running good_night");

	if (!get_property("_bastilleGamesLockedIn").to_boolean()) {
		use_if_needed($item[sharkfin gumbo], $effect[Shark-Tooth Grin], gkBastilleBuffAmount);
		use_if_needed($item[boiling broth], $effect[Boiling Determination], gkBastilleBuffAmount);
		use_if_needed($item[interrogative elixir], $effect[Enhanced Interrogation], gkBastilleBuffAmount);
		unused = cli_execute("basty win");
	}
	assert(get_property("_bastilleGames").to_int() > 0, "didn't play Bastille Battalion but should have!");

	stockStore();

	useNashCrosbyStill();
	burnBuffs();
	burnSpleen();
	burnFreeUseItems();

	burnFreeCombats();
	burnInstaKills();

	burnFreeMP();
	burnFreeCrafting();

	unused = cli_execute("latte refill cajun carrot guarna"); // meat, item, adv
	maximize("adventures, switch tot", false);

	print("burn sausages!!!!!!!!!!!!!!!", "red");
	burn_sausages(true); // called after maximizing adv, will ensure we don't overeat

	if (to_int(get_property("garbageChampagneCharge")) > 0)
		cli_execute("tote 2"); // broken champagne bottle
	else
		cli_execute("tote 5"); // makeshift garbage shirt
}



// -------------------------------------
// OUT OF RONIN/HARDCORE
// -------------------------------------

void setupCrafting() {
	if (!get_property("hasRange").to_boolean())
		use(1, $item[Dramatic&trade; range]);
	if (!get_property("hasCocktailKit").to_boolean())
		use(1, $item[Queue Du Coq cocktailcrafting kit]);
}



void pullEverythingAfterRonin() {
	batch_open();
	int [item] pull_map;
	file_to_map("unrestricted_pull_map.txt", pull_map);
	foreach pull_item, amt in pull_map {
		print("pulling " + (amt == 0 ? "all" : amt.to_string() + " " + pull_item));
		take_storage(amt == 0 ? storage_amount(pull_item) : amt, pull_item);
	}
	print("pull batch successful: " + batch_close());
	cli_execute("pull * meat");
}



void useSkillbooksAfterRonin() {
	boolean unused;
	int [item] use_map;
	file_to_map("unrestricted_use_map.txt", use_map);
	foreach use_item in use_map {
		print("using: " + use_item, "blue");
		if (have_item(use_item))
			unused = use(use_map[use_item], use_item);
	}
}



void outOfRonin() {
	print("outOfRonin", "green");

	cli_execute("ccs unrestricted");
	set_property("choiceAdventure786", "6"); // skip pygmy office building NC
	set_property("gingerPhotoTaken", "false"); // for the sprinkle briefcase quest
	set_property("trackVoteMonster", "false"); // don't stop for the vote monster, we'll detect it ourselves
	max_mcd();
	cli_execute("briefcase unlock");

	getDocGalaktikQuest();
	getMeatsmithQuest();
	getArmoryQuest();
	getOldLandfillQuest();

	setupCrafting();

	pullEverythingAfterRonin();
	pull_high_quantity_items(); // for use with the asdon martin
	fullAcquire(1, gkFishyGearToGet); // use(1, gkFishyGearToGet);
	equip_all_familiars();
	cycleFavouriteFamiliars();

	// use a bunch of skillbooks to gain skills in aftercore
	useSkillbooksAfterRonin();
	use_skill(1, $skill[spirit of cayenne]);

	if (my_class() == $class[seal clubber]) {
		use_skill(1, $skill[Iron Palm Technique]);
		use_skill(1, $skill[blood sugar sauce magic]);
	}

	if (my_class() == $class[turtle tamer]) {
		use_skill(1, $skill[Blessing of the Storm Tortoise]);
		use_skill(1, $skill[blood sugar sauce magic]);
	}

	if (my_class() == $class[pastamancer]) {
		use_skill(1, $skill[bind spice ghost]);
		print("GET canticle of carboloading from guild!!!!", "blue");
	}

	if (my_class() == $class[sauceror]) {
		use(1, $item[Zu Mannk&auml;se Dienen (used)]);
	}

	if (my_class() == $class[disco bandit]) {
		use(1, $item[Autobiography Of Dynamite Superman Jones (used)]);
	}

	if (my_class() == $class[accordion thief]) {
		print("CHECK FOR Ballad of Richie Thingfinder!!!!", "blue");
	}

	cli_execute("ballpit; spacegate vaccine 2"); // extra stats for extra MP
	setupMood();
	burnMP();

	// visit the old man near the sea, then do breakfast
	visit_url("/place.php?whichplace=sea_oldman&action=oldman_oldman", false, false);
	cli_execute("breakfast");

	secondBreakfast();
	burnMP();
	dailyDeedsAdv();
	burnMP();

	print("remember to twiddle the skill bar in the web UI to the generic skill selection (#1)", "blue");
}



void latteAdventure(location place, string ingredient, int maxTurns) {
	print("latteAdventure looking for '" + ingredient + "' at: " + place + " within " + maxTurns + " turns", "green");

	clearGoals();
	setDefaultMoodForLocation(place);
	automate_dressup($location[none], "meat", "default", maxStringForLocation(place, "equip latte lovers member's mug"));

	if (check_counters(maxTurns, kDontAbort) && !isLatteIngredientUnlocked(ingredient))
		print("WARNING: counter possible before finishing latteAdventure (will abort script at counter) while looking for " + ingredient + " at " + place, "orange");

	int tries = maxTurns;
	while (!isLatteIngredientUnlocked(ingredient) && tries > 0) {
		assert(equipped_amount($item[latte lovers member's mug]) >= 1, "we aren\'t equipping the latte lovers member\'s mug");
		if (!adv1(place))
			abort("latteAdventure: did not successfully adventure at " + place);
		tries--;
	}

	assert(isLatteIngredientUnlocked(ingredient), "latteAdventure: did not unlock " + ingredient + " at " + place + " within " + maxTurns + " turns");
	print("ingredient '" + ingredient + "' UNLOCKED!", "green");
}


void latteAdventure(location place, string ingredient) {
	latteAdventure(place, ingredient, 5);
}


// grind default latte lovers member's mug locations until we get their ingredient
void grindLatteIngredients() {
	string ingredient = nextLatteIngredient();
	while (ingredient != "") {
		assert(!isLatteIngredientUnlocked(ingredient), "nextLatteIngredient returned an unlocked ingredient");
		latteAdventure(kLatteLocations[ingredient], ingredient);
		ingredient = nextLatteIngredient();
	}
}



// -------------------------------------
// GUILD
// -------------------------------------

// set the currently worn pants as a goal for the DB/AT guild starter quest
void setPantsGoal() {
	cli_execute("goal clear; goal add " + equipped_item($slot[pants]));
}

string check_gothy_sub() {
	return "sub checkGothy; if (match \"You watch him go, and soon realize he isn't actually running anywhere\" && !hasskill run like the wind) || (match \"The raver's movements suddenly become spastic and jerky\" && !hasskill pop and lock it) || (match \"The raver drops to the ground and starts spinning his legs wildly\" && !hasskill break it on down); skill gothy; attack; endif; endsub;";
}

string otc_main_sub() {
	fullAcquire($item[seal tooth]);
	return "sub otcMain; if (monstername \"*pop-and-lock*\" && hasskill pop and lock it) || (monstername \"*breakdancing*\" && hasskill break it on down) || (monstername \"*running man*\" && hasskill run like the wind); attack; attack; endif; use seal tooth; call checkGothy; endsub;";
}

void outside_the_club() {
	automate_dressup($location[outside the club], "raveosity", "", "-equip Kramco Sausage-o-Matic&trade;, -equip \"i voted\" sticker");

	string combat_macro;
	if (have_skill($skill[pop and lock it]) && have_skill($skill[break it on down]) && have_skill($skill[run like the wind])) {
		combat_macro = default_sub();
	} else {
		combat_macro = init_sub() + check_gothy_sub() + otc_main_sub() + "sub outside_the_club; if !gotjump; call checkGothy; endif; call init; call otcMain; repeat; endsub; abort pastround 25; call outside_the_club;";
	}

	print("MACRO: " + combat_macro);
	adv1($location[outside the club], -1, combat_macro);
}

void db_nemesis() {
	//automate_dressup($location[The Nemesis' Lair], "mp regen", "", "+equip Shagadelic Disco Banjo, -equip \"i voted\" sticker");
	dressup($location[none], "mp regen", "default", "+equip Shagadelic Disco Banjo, -equip \"i voted\" sticker");
	adv1($location[The Nemesis' Lair], -1, default_sub());
}



// -------------------------------------
// ASCENSION
// -------------------------------------

void dehaunt_aboo_peak() {
	if (item_amount($item[a-boo clue]) * 30 < to_int(get_property("booPeakProgress"))) abort("not enough clues!");
	set_property("choiceAdventure611", 1);

	automate_dressup($location[a-boo peak], "", "", "spooky res, cold res, hp");
	while (to_int(get_property("booPeakProgress")) > 0) {
		healIfRequired();
		use(1, $item[a-boo clue]);
		adventure(1, $location[a-boo peak], "");
	}
}



void junkyard_quest() {
	use_familiar($familiar[Robortender]);
	automate_dressup($location[Next to that Barrel with Something Burning in it], "", "", "outfit frat warrior fatigues, dr, da, hp, mox");
	fullAcquire($item[seal tooth]);
	healIfRequired();
}



void scavenger_hunt() {
	automate_dressup($location[The Haunted Wine Cellar], "item", "", "+equip broken champagne bottle");
	healIfRequired();
}

void scavenger_hunt_charge() {
	automate_dressup($location[The Haunted Wine Cellar], "ml 82 min", "", "+equip unstable fulminate");
	healIfRequired();
}



// returns the percent done of the desert, taking into account all the Gnasir items
int desert_completion() {
	int rval = to_int(get_property("desertExploration"));
	if (item_amount($item[can of black paint]) > 0) rval += 15;
	if (item_amount($item[stone rose]) > 0) rval += 15;
	if (item_amount($item[worm-riding manual page]) >= 15 && item_amount($item[drum machine]) > 0) rval += 30;
	return rval;
}

void desert_quest() {
	use_familiar($familiar[Garbage Fire]);
	automate_dressup($location[The Arid, Extra-Dry Desert], "", "", "+equip uv-resistant compass");

	healIfRequired();
	while ((to_int(get_property("desertExploration")) < 70 && item_amount($item[worm-riding manual page]) < 15) || (to_int(get_property("desertExploration")) < 40)) {
		if (have_effect($effect[Ultrahydrated]) < 1) {
			check_counters(kAbortOnCounter);
			fullAcquire($item[11-leaf clover]);
			adventure(1, $location[The Oasis], "");
		}
		check_counters(kAbortOnCounter);
		adventure(1, $location[The Arid, Extra-Dry Desert], "");
	}
}



void pyramid_quest_top() {
	automate_dressup($location[The Upper Chamber], "-combat", "default", "");
	healIfRequired();
}


void pyramid_quest_mid() {
	automate_dressup($location[The Middle Chamber], "item", "item", "");
	healIfRequired();
}



void lighthouse_quest() {
	automate_dressup($location[Sonofa Beach], "+combat", "default", "");
	healIfRequired();
}



void orchard_quest() {
	use_familiar($familiar[XO Skeleton]);
	automate_dressup($location[The Hatching Chamber], "", "", "");
	healIfRequired();
}



void nuns_quest() {
	use_familiar($familiar[Hobo Monkey]);
	automate_dressup($location[The Themthar Hills], "meat", "", "outfit frat warrior fatigues");
	healIfRequired();
}



void island_war_frat() {
	use_familiar($familiar[Cat Burglar]);
	automate_dressup($location[the battlefield (frat uniform)], "item", "", "outfit frat warrior fatigues");
	healIfRequired();
}



