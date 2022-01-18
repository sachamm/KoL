since r26135;

string __smm_utils_version = "0.9";


/*
To use the subroutines from this ASH file in the CLI, do this in the CLI:
using smmUtils.ash;

You can then call any subroutine in this file from the command line. For example:
itemDescription (yellow rocket);
     NOTE this ^ space between the name of the subroutine and the parenthesis is important for some reason

Subroutines without any params can be called without the empty parens (), e.g.:
timeToRollover;

To stop using this on the CLI, do:
get commandLineNamespace
set commandLineNamespace =
(if you have other files that you are "using", the first command will show them -- you'll
have to re-"using" them after resetting the name space)
*/

// -------------------------------------
// DATA TYPES, CONSTANTS, AND DATA
// -------------------------------------

record ItemDropRecord {
   item drop;
   int rate;
   string type;
};

// this uniquely identifies a single action to take in combat
// One and only one field should be filled out, all others should be false/none.
record ActionRecord {
	boolean attack;
	boolean pickpocket;
	skill skillToUse;
	item itemToUse;
	item item2ToUse;
};

// various iterations of the skill record priority scheme
record BanishRecord {
	skill skillUsed;
	int turncount;
	monster monsterBanished;
};

record SkillRecord {
	skill skillToUse;
	item itemToEquip;
};

record PrioritySkillRecord {
	skill theSkill;
	item theItem;        	// item to equip/use(?) to enable/cast(?) the skill
	int mpCost;             // estimated cost of the skill in mp
	int meatCost;           // estimated cost of the skill in meat -- use the default cost of a turn if the skill costs turns (such as Batter Up!)
	float priority;         // whole part is the group, fractional part only affects which is chosen if usesAvailable are equal
	int usesAvailable;      // number available to use assuming all conditions are met (i.e. the item is worn, have enough mana, etc.)
	boolean isAvailableNow; // if we had uses available, could we cast it now?
};



// abstracts the notion of an adventure to include not just a location but also item uses and skill uses.
// this uniquely identifies a single method to start an adventure
// One and only one field should be filled out, all others should be none.
record AdventureRecord {
	location locationToUse;
	skill skillToUse;
	item itemToUse;
};



// represents a single buff, with its buff amount, duration, opportunity cost, and effect. for use with analysis tools such as buffColdRes
record AnalyzeRecord {
	int buffAmount; // amount of the buff, either in percent or absolute terms
	boolean buffIsPercentBased;
	int duration;
	int opportunityCost; // turn cost, spleen cost, etc.
	effect theEffect;
	string activationString; // CLI string where %d is number of activations, e.g. "synthesize %d Synthesis: Cold". default activations are handled automatically (use, chew, eat, drink)
};



int kMaxInt = 2147483647;
int kMinInt = -2147483648;
int kUnlimitedUses = kMaxInt;

int kTurnValue = get_property("smmTurnValue") == "" ? 4000 : get_property("smmTurnValue").to_int(); // the value of a turn

//item kSpleenItem = $item[powdered gold];
//float kTurnsPerSpleen = ??;
item kSpleenItem = $item[coffee pixie stick];
float kTurnsPerSpleen = 1.88;
item kFillerSpleenItem = $item[transdermal smoke patch];

float kExpectedDamageSafetyFactor = 1.10;

float kPersueFamiliarIfOver = 1/3; // if a familiar is this much progress into getting a drop, include it as a default familiar choice (among other things, such as inclusion in mummery)
if (!can_interact()) kPersueFamiliarIfOver = 2/3; // get closer to done before including in default processing if we're in ronin

int gUnrestrictedManaToSave = 150; // save at least this much mana by default

string kDefaultMood = "current";
string kNoMood = "apathetic";

string kFloundrySpotsKey = "_floundryFishingSpots";

string kHadGoalsKey = "smmHadGoals";

string kSavedOutfitKeyPrefix = "_smmSavedOutfit";
string kSavedFamiliarKeyPrefix = "_smmSavedFamiliar";
string kSavedFamiliarEquipKeyPrefix = "_smmSavedFamiliarEquipment";
string kDefaultOutfit = "base";
string kForceDressupKey = "_dressupForce";
string kDressupLocationKey = "_dressupLocation";
string kDressupSelectorKey = "_dressupSelector";
string kDressupFamiliarSelectorKey = "_dressupFamiliarSelector";
string kDressupMaxStringKey = "_dressupMaxString";
string kDressupLastFullMaxStringKey = "_dressupLastFullMaxString";
string kDressupTweakStringKey = "_dressupTweakString";
string kDressupSavedEquipSetKey = "dressupSavedEquipSet";

string kCheckForLastSausageGoblinKey = "smmCheckForLastSausageGoblin";

string kSmutOrcPervertProgressKey = "smmSmutOrcPervertProgress";
string kLastSmutOrcPervertTurnsSpentKey = "smmLastSmutOrcPervertTurnsSpent";

int kCocoonHealing = 1000;

int kSausagesToGet = 15;
int kSausagesToEat = 23;
int kMaxSausagesToEat = 23;


int kDreadsylvaniaCompleteTurns = 3000;
int kHobopolisCompleteTurns = 5000;
int kHobopolisTownCenterCompleteTurns = 2000;
int kHobopolisOutskirtsCompleteTurns = 500;


int [string] kQualityStringToPerAdventureMap = {
	"crappy" : 1,
	"decent" : 2,
	"good" : 3,
	"awesome" : 4,
	"EPIC" : 5,
};



int [string] kQuestM12PirateCompletionMap = {
	"unstarted" : 0,
	"started" : 1,
	"step1" : 2,
	"step2" : 3,
	"step3" : 4,
	"step4" : 5,
	"step5" : 6,
	"step6" : 7,
	"finished" : 8
};



string [int] rave_combo_map = {
	1 : "item", // +30% aka Rave Concentration
	2 : "meat", // +50% aka Rave Nirvana
	3 : "knockout", // 3-rd stun + DOT
	4 : "bleeding",
	5 : "steal",
	6 : "stats"
};



location [] kDreadLocs = {
	$location[Dreadsylvanian Woods],
	$location[Dreadsylvanian Village],
	$location[Dreadsylvanian Castle]
};

location [] kHoboLos = {
	$location[A Maze of Sewer Tunnels],
	$location[Burnbarrel Blvd.],
	$location[Exposure Esplanade],
	$location[Hobopolis Town Square],
	$location[The Ancient Hobo Burial Ground],
	$location[The Heap],
	$location[The Purple Light District]
};

location [string] kEndGameNameToLocationMap = {
	"Sewers" : $location[A Maze of Sewer Tunnels],
	"Town Square" : $location[Hobopolis Town Square],
	"Burnbarrel Blvd." : $location[Burnbarrel Blvd.],
	"Exposure Esplanade" : $location[Exposure Esplanade],
	"The Heap" : $location[The Heap],
	"The Ancient Hobo Burial Ground" : $location[The Ancient Hobo Burial Ground],
	"The Purple Light District" : $location[The Purple Light District]
};



skill [] BloodySkillsArray = {
	$skill[Blood Frenzy],
	$skill[Blood Bond],
	$skill[Blood Bubble]
};



// banish skill to number of turns banished
int [skill] kBanishSkillMap = {
	$skill[Batter Up!] : kMaxInt,
	$skill[KGB tranquilizer dart] : 20,
	$skill[Throw Latte on Opponent] : 30,
	$skill[Reflex Hammer] : 30,
	$skill[Show them your ring] : 60,
	$skill[Asdon Martin: Spring-Loaded Front Bumper] : 30,
	$skill[Snokebomb] : 30,
	$skill[Feel Hatred] : 50,
	$skill[Breathe Out] : 20
};



monster [location] kTargetableMonstersMap = {
	$location[The Goatlet] : $monster[dairy goat],
	$location[The Fungal Nethers] : $monster[angry mushroom guy]
};



effect [] kDrivingStyles = {
	$effect[Driving Obnoxiously],
	$effect[Driving Stealthily],
	$effect[Driving Wastefully],
	$effect[Driving Safely],
	$effect[Driving Recklessly],
	$effect[Driving Intimidatingly],
	$effect[Driving Quickly],
	$effect[Driving Observantly],
	$effect[Driving Waterproofly]
};



string [location] kLatteLocations = {
	$location[The Dire Warren] : "carrot",
	$location[The Black Forest] : "cajun",
	$location[The Bat Hole Entrance] : "guarna",
	$location[The Arid, Extra-Dry Desert] : "lizard",
	$location[The Spooky Forest] : "rawhide",
	$location[The Dark Elbow of the Woods] : "vitamins",
	$location[The Dark Heart of the Woods] : "wing",
	$location[The Haunted Library] : "ink"
};


item [phylum] kRobortenderStrongBooze = {
	$phylum[bug] : $item[eighth plague],
	$phylum[constellation] : $item[single entendre],
	$phylum[demon] : $item[reverse Tantalus],
	$phylum[elemental] : $item[elemental caipiroska],
	$phylum[elf] : $item[Feliz Navidad],
	$phylum[fish] : $item[Bloody Nora],
	$phylum[goblin] : $item[moreltini],
	$phylum[hippy] : $item[hell in a bucket],
	$phylum[hobo] : $item[Newark],
	$phylum[horror] : $item[R'lyeh],
	$phylum[humanoid] : $item[Gnollish sangria],
	$phylum[mer-kin] : $item[vodka barracuda],
	$phylum[orc] : $item[Mysterious Island iced tea],
	$phylum[penguin] : $item[drive-by shooting],
	$phylum[pirate] : $item[gunner's daughter],
	$phylum[plant] : $item[dirt julep],
	$phylum[slime] : $item[Simepore slime],
	$phylum[weird] : $item[Phil Collins],
};



item [stat] kStatToDivineCombatItemMap = {
	$stat[muscle] : $item[divine noisemaker],
	$stat[mysticality] : $item[divine can of silly string],
	$stat[moxie] : $item[divine blowout],
};



boolean kAbortOnCounter = true;
boolean kDontAbort = false;



// -------------------------------------
// PREFERENCE COVER METHODS
// -------------------------------------

boolean freeWanderingMonstersOnly() {
	return to_boolean(get_property("_smmStopNonFreeVoteAdventures"));
}



// -------------------------------------
// CODE UTILITIES
// -------------------------------------

int smm_abs(int val) {
	if (val < 0)
		return -val;
	else
		return val;
}



// returns a new array composed of the given array minus the first item
string [int] cdr(string [int] anArray) {
	string [int] newArray;

	if (count(anArray) == 1) return newArray;

	for i from 1 to count(anArray) - 1 {
		newArray[i-1] = anArray[i];
	}

	return newArray;
}



// strip the given characters off the beginning and end of the given string and return the resulting string
string strip(string stripString, string charsToStrip) {
	if (stripString == "") return "";

	int stripIndexStart = 0;
	for i from 0 to length(stripString) - 1 {
		string aChar = char_at(stripString, i);
		if (charsToStrip.contains_text(aChar))
			stripIndexStart = i + 1;
		else
			break;
	}

	int stripIndexEnd = length(stripString);
	if (stripIndexStart == stripIndexEnd)
		return "";

	for i from length(stripString) - 1 to stripIndexStart {
		string aChar = char_at(stripString, i);
		if (charsToStrip.contains_text(aChar))
			stripIndexEnd = i;
		else
			break;
	}

	return substring(stripString, stripIndexStart, stripIndexEnd);
}

string strip(string stripString) {
	return strip(stripString, " ");
}



// joins the strings in an array
string joinString(string [] anArray, string midString) {
	string rval;
	foreach idx, aString in anArray {
		if (rval != "") rval += midString;
		rval += aString;
	}
	return rval;
}


// appends a string to another, inserting the given string between if both strings are non-empty
string joinString(string baseString, string stringToAppend, string joinString) {
	string rval = baseString;
	if (baseString != "" && stringToAppend != "") rval += joinString;
	return rval += stringToAppend;
}


// appends a string to another, inserting a comma and space between if both strings are non-empty
string maxStringAppend(string maxString, string stringToAppend) {
	return maxString.joinString(stringToAppend, ", ");
}



// this set of functions all return true if the test thing is in the given array
boolean arrayContains(string [] array, string test) {
	foreach aThing in array {
		if (array[aThing] == test)
			return true;
	}
	return false;
}

boolean arrayContains(skill [] array, skill test) {
	foreach aThing in array {
		if (array[aThing] == test)
			return true;
	}
	return false;
}

// returns true if the test monster is in the given array
boolean arrayContains(monster [] array, monster test) {
	foreach aMonster in array {
		if (array[aMonster] == test)
			return true;
	}
	return false;
}

boolean arrayContains(SkillRecord [] array, PrioritySkillRecord test) {
	foreach idx, sr in array {
		if (sr.skillToUse == test.theSkill && sr.itemToEquip == test.theItem)
			return true;
	}
	return false;
}



// aborts with abortString if asserted is not true
void assert(boolean asserted, string abortString) {
	if (!asserted)
		abort("assertion failed: " + abortString);
}



// -------------------------------------
// KOL UTILITIES
// -------------------------------------


boolean restoreAllMP() {
	return restore_mp(my_maxmp() - my_mp());
}



void timeToRollover() {
	print("You have "+(23 - (gametime_to_int() / (86400000 / 24)))+":"+(59 - ((gametime_to_int() / (86400000 / 1440)) % 60))+" left until rollover begins.");
}

int minutesToRollover() {
	int msPerDay = 1000 * 60 * 60 * 24;
	return (msPerDay - gametime_to_int()) / (1000 * 60);
}



boolean inCombat() {
// 	return current_round() != 0 && monster_hp() > 0 && my_hp() > 0;
	return current_round() != 0;
}



boolean [element] weak_elements(element anElement) {
	switch (anElement) {
		case $element[cold]:   return $elements[spooky, hot];
		case $element[spooky]: return $elements[hot, stench];
		case $element[hot]:    return $elements[stench, sleaze];
		case $element[stench]: return $elements[sleaze, cold];
		case $element[sleaze]: return $elements[cold, spooky];
	}
	return $elements[none];
}



// prints useful info for the location we're about to adventure in
// only prints the info once per day per location
void notesForLocation(location aLocation) {
	string doOnceProperty = "_smmDoOnceNotesForLocation" + aLocation;
	boolean doneOnce = to_boolean(get_property(doOnceProperty));

	string [location] notes = {
		$location[The Haunted Laundry Room] : "CAN GET INVISIBLE STRING for use with li'l ghost costume",
		$location[The Haunted Storage Room] : "CAN GET INVISIBLE SEAM RIPPER for use with li'l ghost costume",
		$location[Lair of the Ninja Snowmen] : "CAN GET INVISIBLE SEAM RIPPER for use with li'l ghost costume",
	};

	print("\n\nAdventuring at: " + aLocation, "blue");
	if (notes[aLocation] != "" && !doneOnce) {
		print(notes[aLocation], "blue");
		wait(15);
	}

	set_property(doOnceProperty, "true");
}


boolean isUnlocked(location aLocation) {
	int questM12PirateCompletion = kQuestM12PirateCompletionMap[get_property("questM12Pirate")];

	if (aLocation == $location[Belowdecks])
		return questM12PirateCompletion >= 8;
	if (aLocation == $location[The Poop Deck])
		return questM12PirateCompletion >= 7;
	if (aLocation == $location[The F'c'le])
		return questM12PirateCompletion >= 6;

	return true;
}



void saveAndSetProperty(string property, string value) {
	set_property("_smmBackup_" + property, get_property(property));
	set_property(property, value);
}

void restoreSavedProperty(string property) {
	set_property(property, get_property("_smmBackup_" + property));
}



string itemDescription(item anItem) {
	buffer descriptionPage = visit_url("/desc_item.php?whichitem=" + anItem.descid);

	matcher descMatcher = create_matcher("<body>(.*)</body>", to_string(descriptionPage));
	find(descMatcher);
	return group(descMatcher, 1);
}


void print_description(item anItem) {
	print_html(itemDescription(anItem));
}



string effectDescription(effect anEffect) {
	buffer descriptionPage = visit_url("/desc_effect.php?whicheffect=" + anEffect.descid, false, false);

	matcher descMatcher = create_matcher("<div id=\"description\">(.*)</div>", to_string(descriptionPage));
	find(descMatcher);
	return group(descMatcher, 1);
}


void printEffectDescription(effect anEffect) {
	print_html(effectDescription(anEffect));
	print_html("");
}



string skillDescription(skill aSkill) {
	return effectDescription(to_effect(aSkill));
}


void printSkillDescription(skill aSkill) {
	print_html(skillDescription(aSkill));
}



string statAbbr(stat aStat) {
	if (aStat == $stat[muscle]) return "mus";
	if (aStat == $stat[mysticality]) return "mys";
	if (aStat == $stat[moxie]) return "mox";
	assert(false, "not a valid stat??");
	return "should never get here"; // parser requires this
}



boolean uneffect(effect anEffect) {
	return cli_execute("uneffect " + anEffect);
}

boolean uneffect(skill aSkill) {
	return uneffect(to_effect(aSkill));
}



boolean inRonin() {
	return !can_interact();
}



boolean max_mcd() {
	int maxmcd = 10;
	if (canadia_available())
		maxmcd = 11;
	if (current_mcd() == maxmcd)
		return true;
	return change_mcd(maxmcd);
}

// ease of use alias
boolean mmcd() {
	return max_mcd();
}



float hitPercent(int attack, int defense) {
	// ( (Attack - Defense) / 18 ) * 100 + 50 = Hit%
	float percent = 100.0 * (attack - defense) / 18 + 50.0;
	return max(min(percent, 100), 0);
}



// returns the number of free crafting turns are available
int availableFreeCraftTurns() {
	int inigosFreeCraftTurns = floor(have_effect($effect[Inigo's Incantation of Inspiration]) / 5.0);
	int cutCornersFreeCraftTurns = 5 - to_int(get_property("_expertCornerCutterUsed"));
	return inigosFreeCraftTurns + cutCornersFreeCraftTurns;
}



// attempts to put target amount of anItem in your inventory.
// if target is less than the number of equipped items, will count your equipped items as your inventory
// (differs from retrieve_item in this respect -- useful when acquiring items for equipping)
// if target is more than the number you have equipped, it might end up unequip'ing any items
// you DO have equipped (though other avenues will be pursued first, see Retrieval order in the wiki for more info)
// might pull, create, fold or even buy the item (with a user confirmation for buying over mafia's preference-set limit)
// returns true iff it was able to acquire target items
boolean fullAcquire(int target, item anItem) {
// 	print("fullAcquire: " + target + "X " + anItem, "green");
	if (equipped_amount(anItem) >= target)
		return true;

	if (item_amount(anItem) >= target)
		return true;

	boolean acquired = false; // slightly strange logic allows reordering the attempts without recoding... once the order is finalized, can move to a more traditional structure
	int needed = target - item_amount(anItem);

	if (!acquired)
		acquired = retrieve_item(target, anItem);
	needed = target - item_amount(anItem);

	// retrieve_item doesn't always fold
	boolean success = true;
	if (!acquired && count(get_related(anItem, "fold")) > 0)
		while (success && needed > 0) {
			success = cli_execute("fold " + anItem);
			needed = target - item_amount(anItem);
		}
	needed = target - item_amount(anItem);
	if (needed == 0)
		acquired = true;

	// retrieve_item doesn't always create
	if (!acquired && availableFreeCraftTurns() >= needed)
		acquired = create(needed, anItem);
	needed = target - item_amount(anItem);

	if (!acquired && user_confirm("Could not acquire " + target + "X " + anItem + " any other way, buy the needed " + needed + " more @ " + mall_price(anItem) + ", total cost: " + (needed * mall_price(anItem)) + "?", 60000, true))
		acquired = buy(target, anItem);
	needed = target - item_amount(anItem);

// 	print("target: " + target + " in inv: " + item_amount(anItem) + " acquired: " + acquired);
	return acquired;
}

// attempts to acquire the given item, possibly pulling or buying the item
boolean fullAcquire(item anItem) {
	return fullAcquire(1, anItem);
}



// number of accordion thief buffs / effects currently active
int accordionSongsActive() {
	int rval;
	int [effect] currentEffects = my_effects(); // Array of current active effects
	foreach buff in currentEffects {
		skill currentEffect = to_skill(buff);
		if (currentEffect.class == $class[accordion thief] && currentEffect.buff) { // True if AT buff 
			rval++;
		}
	}
	return rval;
}


boolean isATSong(skill aSkill)  {
	return aSkill.class == $class[accordion thief] && aSkill.buff;
}

boolean isATSong(effect anEffect)  {
	return isATSong(to_skill(anEffect));
}


int maxAccordionSongs()  {
	int maxSongs = boolean_modifier("Four Songs") ? 4 : 3;
	int additionalSongs = numeric_modifier("Additional Song");
	return maxSongs + additionalSongs;
}



// prints out all worn equipment
string logEquipmentString(boolean shortForm) {
	string [] outputStrings = {
		$slot[hat] + ": " + equipped_item($slot[hat]) + ", " + $slot[back] + ": " + equipped_item($slot[back]) + ", " + $slot[shirt] + ": " + equipped_item($slot[shirt]),
		$slot[weapon] + ": " + equipped_item($slot[weapon]) + ", " + $slot[off-hand] + ": " + equipped_item($slot[off-hand]) + ", " + $slot[pants] + ": " + equipped_item($slot[pants]),
		$slot[acc1] + ": " + equipped_item($slot[acc1]) + ", " + $slot[acc2] + ": " + equipped_item($slot[acc2]) + ", " + $slot[acc3] + ": " + equipped_item($slot[acc3]),
		"fam: " + my_familiar() + ", " + $slot[familiar] + ": " + equipped_item($slot[familiar])
	};

	string rval;
	if (shortForm)
		rval = joinString(outputStrings, ", ");
	else
		rval = joinString(outputStrings, "\n");

	return rval;
}

string logEquipmentString() {
	return logEquipmentString(true);
}

void logEquipment(boolean shortForm) {
	print(logEquipmentString(shortForm));
}

void logEquipment() {
	logEquipment(false);
}



void unequipAll(boolean unequipFamiliar) {
// 	visit_url("/inv_equip.php?pwd&action=unequipall", true, false); // doesn't seem to be an actual shortcut
	foreach slt in $slots[] {
		if ((slt != $slot[familiar] || unequipFamiliar) && equipped_item(slt) != $item[none])
			equip(slt, $item[none]);
	}
}



// returns the average number of adventures gained by eating/drinking the given item
int nutrition(item food_booze) {
	matcher aMatcher = create_matcher("([0-9]+)-?([0-9]*)", food_booze.adventures);
	if (!find(aMatcher))
		abort("nutrition: non-food/non-booze: " + food_booze + ", adventures: " + food_booze.adventures);

	string lowString = group(aMatcher, 1);
	string highString = group(aMatcher, 2);
	int low = to_int(lowString);
	int high = to_int(highString);

	if (highString == "" && lowString == 0) // 0 adventures? use a default based on quality
		return kQualityStringToPerAdventureMap[food_booze.quality] * (food_booze.inebriety + food_booze.fullness);
	else if (highString == "")
		return low;
	else
		return (low + high) / 2;
}



// executes the given Custom Combat Script
string executeScript(string script) {
	if (script != "") {
		print("executing script: " + script, "blue");
		return visit_url("fight.php?action=macro&macrotext=" + url_encode(script), true, true);
	}
	else {
		return "";
	}
}



// wraps item_drops_array to return something that can be stored in a variable
ItemDropRecord [] normalized_item_drops_array(monster mob) {
	ItemDropRecord [int] itemDropRecordArray;
	ItemDropRecord tempIDR;
	int counter = 0;

	foreach idx, monsterDropsArray in item_drops_array(mob) {
		tempIDR = new ItemDropRecord();
		tempIDR.drop = monsterDropsArray.drop;
		tempIDR.rate = monsterDropsArray.rate;
		tempIDR.type = monsterDropsArray.type;
		itemDropRecordArray[counter] = tempIDR;
		counter++;
	}

	return itemDropRecordArray;
}


// returns pickpocket-able items dropped by aMonster
ItemDropRecord [int] ppItemDropsArray(monster aMonster) {
	ItemDropRecord [int] itemDropRecordArray;
	ItemDropRecord tempIDR;
	int counter = 0;

	foreach idx, monsterDropsArray in item_drops_array(aMonster) {
		if ((monsterDropsArray.rate > 0 || monsterDropsArray.type == "0") && (monsterDropsArray.type != "n" && monsterDropsArray.type != "b")) {
			tempIDR = new ItemDropRecord();
			tempIDR.drop = monsterDropsArray.drop;
			tempIDR.rate = monsterDropsArray.rate;
			tempIDR.type = monsterDropsArray.type;
			itemDropRecordArray[counter] = tempIDR;
			counter++;
		}
	}

	return itemDropRecordArray;
}


// returns true iff at least one monster at the location has an appearance rate > 0% AND
// has one pickpocket-able item
boolean isPPUseful(location aLocation) {
	float [monster] monsterMap = appearance_rates(aLocation);
	foreach m in monsterMap {
		//print("testing monster: " + m);
		if (m != $monster[none] && monsterMap[m] > 0 && count(ppItemDropsArray(m)) > 1)
			return true;
	}

	return false;
}



boolean isOlfacted(monster aMonster) {
	boolean isOlfacted = false;

	if (have_effect($effect[On the Trail]) > 0) {
		if (aMonster == $monster[none])
			isOlfacted = true;
		else if (to_monster(get_property("olfactedMonster")) == aMonster)
			isOlfacted = true;
	}

	return isOlfacted;
}

boolean isOlfacted(monster [] targetMonsters) {
	foreach idx, aMonster in targetMonsters {
		if (isOlfacted(aMonster))
			return true;
	}

	return false;
}



// is the item in the inventory, or stored, or equipped
boolean have_item(item anItem) {
	//print(anItem + ": " + available_amount(anItem) + ", returning: " + (available_amount(anItem) > 0));
	return available_amount(anItem) > 0;
}



// returns the item for which we have the highest number in inventory
item mostOfItem(item [] itemList) {
	sort itemList by -item_amount(value);
	return itemList[0];
}



int [item] gHatchlings;
int [item] hatchlings() {
	if (count(gHatchlings) > 0)
		return gHatchlings;

	int i = 0;
	foreach fam in $familiars[] {
		gHatchlings[fam.hatchling] = 1;
	}
	return gHatchlings;
}


boolean is_gift(item anItem) {
	return anItem.gift;
}


boolean is_skillbook(item anItem) {
	return anItem == $item[the Crymbich Manuscript];
}


boolean is_hatchling(item anItem) {
	return hatchlings() contains anItem;
}


int familarWeight(familiar fam) {
	return familiar_weight(fam) + weight_adjustment();
}



// -------------------------------------
// MOOD UTILITIES
// -------------------------------------


string moodStringAppend(string moodString, string stringToAppend) {
	return moodString.joinString(stringToAppend, ", ");
}


// TODO different songs depending on situation
skill [] defaultSongs() {
	skill [] rval = {
		$skill[Fat Leon's Phat Loot Lyric],
		$skill[The Polka of Plenty],
		$skill[Aloysius' Antiphon of Aptitude],
		$skill[Stevedave's Shanty of Superiority],
	};
	return rval;
}


skill defaultFacialExpression() {
	return $skill[Patient Smile];
}


// prints all the skills in the current mood
void listMood() {
	foreach idx, moodString in mood_list() {
		print(moodString);
	}
}


skill [int] moodSkills() {
	skill [int] rval;
	int idx = 0;

	foreach idx, moodString in mood_list() {
		string skillString = moodString.split_string(" \\| ")[1];
		rval[idx++] = to_skill(skillString);
	}

	return rval;
}


// the AT song buffs we currently have active
int [skill] activeSongs() {
	int [skill] activeSongs;
	foreach anEffect, duration in my_effects() {
		skill aSkill = anEffect.to_skill();
		if (aSkill.class == $class[accordion thief] && aSkill.buff
			|| anEffect == $effect[Rolando's Rondo of Resisto]) // for some reason this isn't an AT buff
			activeSongs[aSkill] = duration;
	}
	return activeSongs;
}


// the AT song buffs in the current mood
int [skill] moodSongs() {
	int [skill] moodSongs;
	foreach idx, aSkill in moodSkills() {
		if (aSkill.class == $class[accordion thief] && aSkill.buff)
			moodSongs[aSkill] = have_effect(aSkill.to_effect());
	}
	return moodSongs;
}


int countMoodSongs() {
	return count(moodSongs());
}


// the facial expression we currently have active
skill activeFacialExpression() {
	foreach anEffect in my_effects() {
		if (anEffect.to_skill().expression)
			return anEffect.to_skill();
	}
	return $skill[none];
}


// the facial expression in the current mood
skill moodFacialExpression() {
	foreach idx, aSkill in moodSkills() {
		if (aSkill.expression)
			return aSkill;
	}
	return $skill[none];
}


boolean inMood(skill aSkill) {
	return arrayContains(moodSkills(), aSkill);
}

boolean inMood(effect anEffect) {
	return arrayContains(moodSkills(), anEffect.to_skill());
}


string getMoodRaw() {
	return get_property("currentMood");
}

string getMood() {
	return getMoodRaw().replace_string(", defaultfacialexpression", "").replace_string(", default1song", "").replace_string(", default2song", "").replace_string(", default3song", "").replace_string(", default4song", "");
}


void moodExecute() {
	cli_execute("mood execute");

	string currentMood = get_property("currentMood");
	// auto-fill songs and facial expression with something
	if (!inRonin() && currentMood != "apathetic") { // don't auto-fill in ronin
		if (activeFacialExpression() == $skill[none])
			if (!use_skill(1, defaultFacialExpression()))
				abort("could not fill facial expression with " + defaultFacialExpression());

		int songSpace = maxAccordionSongs() - count(activeSongs());
		foreach idx, buffSkill in defaultSongs() {
			if (songSpace == 0) break;
			if (have_effect(buffSkill.to_effect()) == 0) {
				if (use_skill(1, buffSkill))
					songSpace--;
				else
					abort("could not fill song space with " + buffSkill);
			}
		}
	}
}


void setMoodRaw(string moodString) {
// 	print("setMoodRaw: " + moodString, "blue");
	string parsedMoodString = moodString.replace_string("|", ","); // the CLI parser doesn't like commas
	cli_execute("mood " + parsedMoodString);
}


// will replace "[primestat]" in the moodString with the abbreviation of the prime stat
// will attempt to fill out missing songs or facial expressions with something minimally useful (mp regen? or xp?)
void setMood(string moodString) {
	print("setMood: " + moodString, "blue");

	string parsedMoodString = moodString.replace_string("[primestat]", statAbbr(my_primestat()));

	// instead of doing this here, let's try in moodExecute()
// 	setMoodRaw(parsedMoodString); // so we can properly detect the expression
// 	if (activeFacialExpression() == $skill[none] && !moodString == "apathetic")
// 		parsedMoodString = parsedMoodString.moodStringAppend("defaultfacialexpression");
// 
// 	setMoodRaw(parsedMoodString); // so we can properly count the songs in the mood
// 	int songSpace = maxAccordionSongs() - count(activeSongs());
// 	print("song space: " + songSpace);
// 	if (songSpace > 0 && !moodString.contains_text("apathetic"))
// 		parsedMoodString = parsedMoodString.moodStringAppend("default" + songSpace + "song");

	setMoodRaw(parsedMoodString);
	cli_execute("mood execute");
	print("debug: raw mood at the end of setMood: " + getMoodRaw());
}


void setCurrentMoodRaw(string tweakMood) {
	setMoodRaw(moodStringAppend(kDefaultMood, tweakMood));
}


// set the mood to the default (currently "current"), adjusted by tweakMood, which will be appended with a comma
void setCurrentMood(string tweakMood) {
	setMood(moodStringAppend(kDefaultMood, tweakMood));
}


// set the default mood with no extraneous moods
void setDefaultMoodRaw() {
	setMoodRaw(kDefaultMood);
}


// set the mood to the default, adding expressions or songs as necessary to max out expressions (1) and songs (usually 4)
void setDefaultMood() {
	setMood(kDefaultMood);
}


// always raw
void setNoMood() {
	setMoodRaw(kNoMood);
	assert(count(moodSkills()) == 0, "setNoMood: set mood to apathetic, but the apathetic mood has triggers");
}



// make sure the default mood ("current") is set up correctly
void setUpMood() {
	string moodString;
	if (!inRonin()) {
		string className = replace_string(my_class().to_lower_case(), " ", "");
		moodString = "current extends unrestricted, " + className;
	} else {
		moodString = "current extends apathetic";
	}
	print("setUpMood: " + moodString, "blue");
	setMoodRaw(moodString);
	setMoodRaw("current");
	mood_execute(1);
}



// cast ion-mood bloody skills until they are at buffTurns turns
// should be called with a decent amount of mp
boolean burnHP(int buffTurns) {
// 	if (my_maxhp() < kCocoonHealing) {
// 		int tries = 0;
// 		float mp_mod = .1;
// 		repeat {
// 			tries++;
// 			string temp_max_string = "hp, " + mp_mod + " mp";
// 			print("max " + temp_max_string);
// 			maximize(temp_max_string, 1, 2, true, true);
// 			print("max mp " + numeric_modifier("Generated:_spec", "Maximum MP"));
// 			if (numeric_modifier("Generated:_spec", "Maximum MP") < my_mp()) mp_mod *= 10;
// 		} until (tries > 3 || numeric_modifier("Generated:_spec", "Maximum MP") >= my_mp());
// 
// 		if (numeric_modifier("Generated:_spec", "Maximum MP") < my_mp())
// 			abort("unable to get more hp without losing mp");
// 	}

	// calculate mp cost
	int casts = 0;
	foreach idx, aSkill in BloodySkillsArray {
		effect buff = aSkill.to_effect();
		if (have_effect(buff) < buffTurns && have_skill(aSkill) && inMood(buff)) {
			int turnsToGet = buffTurns - have_effect(buff);
			int turnsPerCast = turns_per_cast(aSkill);
			casts += ceil(turnsToGet / to_float(turnsPerCast));
		}
	}
	if (casts == 0) return true;

	if (my_maxhp() < kCocoonHealing) {
		if (!user_confirm("burnHP: proceed with max hp " + my_maxhp() + " less than " + kCocoonHealing + "?\nTry maximize 5 mp, hp 1000 min", 30000, true))
			abort();
// 		maximize("5 mp, hp 1000 min", false); // this ensures we don't lose mp while increasing the max hp as well
	}

	int hpNeeded = casts * 30;
	int maxHP = my_maxhp();
	int cocoonsNeeded = ceil(hpNeeded / to_float(min(maxHP, kCocoonHealing))) + 1;
	if (my_mp() < cocoonsNeeded * 20)
		abort ("burnHP: not enough mana, need: " + (cocoonsNeeded * 20));
	else
		print("have enough mana", "green");

	// buff it up
	boolean success = true;
	foreach idx, aSkill in BloodySkillsArray {
		effect buff = aSkill.to_effect();
		if (have_effect(buff) < buffTurns && have_skill(aSkill) && inMood(buff)) {
			int turnsToGet = buffTurns - have_effect(buff);
			int turnsPerCast = turns_per_cast(aSkill);
			int castAccumulator = ceil(turnsToGet / to_float(turnsPerCast));

			while (castAccumulator > 0) {
				int numberOfCasts = min(castAccumulator, floor(my_hp() / 30.0));
				print("casting " + aSkill + " " + numberOfCasts + " times", "blue");

				success = use_skill(numberOfCasts, aSkill) && success;
				castAccumulator -= numberOfCasts;

				// recover HP only if we have more casting to do
				if (castAccumulator > 0)
					success = success && use_skill(1, $skill[Cannelloni Cocoon]); // won't cast unless the bloody skill cast was successful

				if (!success)
					return false;
			}
		}
	}

	return true;
}

void burnHP() {
	burnHP(1000);
}



void hpMood() {
	int lowestBloodyEffectDuration = 1000;
	skill lowestBloodySkill;
	if (my_hp() == my_maxhp() && my_maxhp() > 300) {
		foreach idx, aSkill in BloodySkillsArray {
			effect buff = aSkill.to_effect();
			if (have_effect(buff) < lowestBloodyEffectDuration && have_skill(aSkill)) {
				lowestBloodyEffectDuration = have_effect(buff);
				lowestBloodySkill = aSkill;
			}
		}

		if (lowestBloodyEffectDuration < 1000)
			use_skill(lowestBloodySkill);
	}
}



// Similar to the CLI command "burn" with these exceptions:
// 1) does a "mood execute" first, which ensures all in-mood effects are active, regardless of burnAmount.
// 2) then resets the mood to the default mood -- this causes spare mp to be spent on the main buffs first
// and then, once those are max'ed out, the rest of the mp amount will be spent on the rest of the actual current mood.
// 3) once all buffs in the mood have been max'ed (more than ~1000 turns), will pick the buff in the default mood with
// the lowest number of turns and blow the rest of the burnAmount on that.
// 4) a negative burnAmount acts like burn in that it saves abs(burnAmount) mp with the above restrictions. A zero burnAmount represents "burn *" i.e. burn all mp
//
// This is most appropriate in aftercore.
void burnMP(int burnAmount) {
	print("burnMP burning " + burnAmount + " mp with current mood: " + getMood() + " (raw: " + getMoodRaw() + ")", "blue");

	string currentMood = getMoodRaw();
	if (currentMood == "" || currentMood == kNoMood)
		return;

	int targetMP = my_mp() - burnAmount;
	if (burnAmount < 0) targetMP = -burnAmount;
	else if (burnAmount == 0) targetMP = 0;

	// first, spend any mp we have (regardless of burnAmount) to ensure all in-mood effects are active
	int mpBefore = my_mp();
	moodExecute();

	// if we already spent all the mp we wanted to, exit now
	if (burnAmount > 0) {
		burnAmount -= (mpBefore - my_mp());
		if (burnAmount <= 0)
			return;
	}

	// then, switch to the default mood and "burn" all mp on that
	skill [int] defaultMoodSkills;
	try {
		setDefaultMoodRaw(); // we don't want any extraneous stuff that setDefaultMood might do
		defaultMoodSkills = moodSkills();

		if (burnAmount == 0)
			cli_execute("burn *");
		else
			cli_execute("burn " + burnAmount);
	} finally {
		setMoodRaw(currentMood); // also does a mood execute, so might burn more mp...
	}

	// if we still have mp to burn here, dump it all on one thing to avoid wasting it
	if (targetMP == 0 || my_mp() > smm_abs(targetMP)) {
		sort defaultMoodSkills by have_effect(value.to_effect());
		foreach i, aSkill in defaultMoodSkills
			if (have_effect(aSkill.to_effect()) > 1000 && mp_cost(aSkill) > 0 && have_skill(aSkill)) {
				use_skill(floor((my_mp() - targetMP) / to_float(mp_cost(aSkill))), aSkill);
				return;
			}
	}
}

void burnMP() {
	int amountToSave = gUnrestrictedManaToSave;
	if (my_basestat($stat[mysticality]) > amountToSave)
		amountToSave = my_basestat($stat[mysticality]);
	burnMP(-amountToSave);
}


void burnExtraMP() {
	burnMP(-get_property("manaBurningThreshold").to_float() * my_maxmp());
}



void ensure_not_beaten_up() {
	if (have_effect($effect[Beaten Up]) > 0) {
		print("AUTOMATICALLY REMOVING BEATEN UP!", "red");
		if (get_property("_hotTubSoaks") < 5)
			cli_execute("hottub");
		else
			use_skill($skill[Tongue of the Walrus]);
	}
}


boolean isPoisoned() {
	return have_effect($effect[Hardly Poisoned at All]) > 0 || have_effect($effect[A Little Bit Poisoned]) > 0 || have_effect($effect[Somewhat Poisoned]) > 0 || have_effect($effect[Really Quite Poisoned]) > 0 || have_effect($effect[Majorly Poisoned]) > 0;
}

boolean ensureNotPoisoned() {
	if (isPoisoned()) {
		fullAcquire($item[anti-anti-antidote]);
		use(1, $item[anti-anti-antidote]);
	}
	return !isPoisoned();
}

boolean ensureNoTeleportitis() {
	if (have_effect($effect[Teleportitis]) > 0) {
		fullAcquire($item[soft green echo eyedrop antidote]);
		use(1, $item[soft green echo eyedrop antidote]);
	}
	return have_effect($effect[Teleportitis]) == 0;
}

// includes poison
boolean ensureNotDebuffed() {
	boolean rval = true;
	rval = ensureNotPoisoned() && rval;
	rval = ensureNoTeleportitis() && rval;
	return rval;
}


// heal up to the given hp or higher
void haveAtLeastHP(int minHP) {
	int cocoCasts = floor(minHP / 1000.0);
	use_skill(cocoCasts, $skill[Cannelloni Cocoon]);

	while (my_hp() < minHP && my_hp() < my_maxhp()) {
		int hp_needed = minHP - my_hp();
		if (hp_needed <= 10 && my_mp() >= 6)
			use_skill($skill[Lasagna Bandages]);
		else if (hp_needed <= 30 && my_mp() >= 10)
			use_skill($skill[Tongue of the Walrus]);
		else if (my_mp() < 20)
			abort("don't have mp to heal");
		else
			// use_skill(ceil(hp_needed/kCocoonHealing)), $skill[Cannelloni Cocoon]); // SHOULD WORK but borks mafia itself!!
			use_skill($skill[Cannelloni Cocoon]);
	}
}

void healIfRequired(float hpFractionMin) {
	ensure_not_beaten_up(); // might use the hottub, which can remove other debuffs, so use first
	ensureNotDebuffed(); //  includes poisoned
	haveAtLeastHP(my_maxhp() * hpFractionMin);
}

// heal if 10% less than max hp
void healIfRequired() {
	healIfRequired(0.9);
}

// restores enough mp to heal to max hp
void healIfRequiredWithMPRestore(float hpFractionMin) {
	int cocoCasts = ceil(my_maxhp() / 1000.0);
	restore_mp(20 * cocoCasts);
	healIfRequired(hpFractionMin);
}

void healIfRequiredWithMPRestore() {
	healIfRequiredWithMPRestore(0.9);
}


void healToMax() {
	healIfRequired(1.0);
}

void healToMaxWithMPRestore() {
	healIfRequiredWithMPRestore(1);
}


void coco() {
	healIfRequiredWithMPRestore();
}

void cocoa() {
	healToMaxWithMPRestore();
}



// returns true if a counter is set to expire between now and max_turns
boolean check_counters(int max_turns, boolean should_abort) {
	string kCounterWarningDoneKey = "_smmCounterWarningDone";

	boolean has_warned = to_boolean(get_property(kCounterWarningDoneKey));
	boolean will_expire = get_counters("", 0, max_turns) != "";

	if (will_expire && has_warned) {
		set_property(kCounterWarningDoneKey, "false");
		return false;
	}

	if (will_expire && should_abort) {
		set_property(kCounterWarningDoneKey, "true");
		abort("A counter is about to expire.");
	}

	if (!will_expire)
		set_property(kCounterWarningDoneKey, "false");

	return will_expire;
}

// returns true if a counter is set to expire next turn
boolean check_counters(boolean should_abort) {
	return check_counters(0, should_abort);
}



// returns true if the given page is an error page
boolean isErrorPage(string checkPage) {
	if (checkPage == "") return true;
	if (checkPage.contains_text("A voice from the terminal says")) return true; // error at ??
	if (checkPage.contains_text("<td>You shouldn't be here.<center>")) return true; // not dressed for Obligatory Pirate's Cove
	if (checkPage.contains_text("<td>You're not currently at sea.<center>")) return true; // adv at PirateRealm sea, but we're at a PR island
	if (checkPage.contains_text("That isn't a place you can get to the way you're dressed.")) return true; // not dressed for Palindome
	if (checkPage.contains_text("Resistance Required]")) return true; // not enough elemental res

	return false;
}



void preAdventureChecks(int checkTurns) {
	print("**RUNNING pre-adventure script** " + checkTurns + " turns in advance", "blue");

	if (my_adventures() == 0) abort("Out of adventures!");

	check_counters(checkTurns, kAbortOnCounter);

	burnExtraMP();

	if (count(get_goals()) > 0)
		set_property(kHadGoalsKey, "true");
	else
		set_property(kHadGoalsKey, "false");
}

void preAdventureChecks() {
	preAdventureChecks(0);
}


// Adventure using visit_url instead of adventure() -- but also attempts to do all the pre-stuff that adventure() does.
// Post-stuff will have to be done elsewhere... Useful when you want the pre-automation of adventure() without the turn
// automation or the post-automation that can kill scripts (such as when you get Beaten Up during an adventure)
// checkTurns is the number of turns to check ahead for counter expiry, default is 0, i.e. next turn
// Returns the text of the page returned by visit_url
// Typically, this will return mid-adventure, so you will need to run_turn() or whatever after this.
string advURL(string aURL, int checkTurns) {
	preAdventureChecks(checkTurns);
	logEquipment(true);
	string rval = visit_url(aURL, true, false);
	return rval;
}

string advURL(string aLocation) {
	return advURL(aLocation, 0);
}

string advURL(location aLocation, int checkTurns) {
	notesForLocation(aLocation);
	return advURL(to_url(aLocation), checkTurns);
}

string advURL(location aLocation) {
	return advURL(aLocation, 0);
}



string toString(AdventureRecord advRecord) {
	if (advRecord.locationToUse != $location[none])
		return advRecord.locationToUse.to_string();
	else if (advRecord.itemToUse != $item[none])
		return advRecord.itemToUse.to_string();
	else
		return advRecord.skillToUse.to_string();
}


// abstracts the notion of an adventure to include not just a location but also item uses and skill uses.
string getToAdventure(AdventureRecord advRecord) {
	if (advRecord.locationToUse != $location[none])
		return advURL(advRecord.locationToUse);
	else if (advRecord.itemToUse != $item[none]) {
		preAdventureChecks(1);
		return use(1, advRecord.itemToUse);
	} else {
		preAdventureChecks(1);
		return use_skill(advRecord.skillToUse);
	}
}



string makeClickableCommand(string commandName, string command, boolean confirm) {
	string confirm_string = "confirm+";
	if (!confirm) confirm_string = "";
	return "<strong style=\"color:blue;\"><a href=\"KoLmafia/sideCommand?cmd=" + commandName + "+" + confirm_string + command + "&pwd=" + my_hash() + "\">" + command + "</a></strong>";
}



boolean isOysterDay() {
	return get_property("_isOysterDay").to_boolean();
}



boolean isChoicePage(string lastPage) {
	return lastPage.contains_text("choice.php");
}

// TODO fix this
boolean isFightPage(string lastPage) {
	return !lastPage.isChoicePage();
}



boolean canPickpocket() {
	return (my_class() == $class[Disco Bandit]
		|| my_class() == $class[Accordion Thief]
		|| equipped_amount($item[tiny black hole]) >= 1
		|| equipped_amount($item[mime army infiltration glove]) >= 1);
}



boolean isPizzaWorkshed() {
	return get_workshed() == $item[diabolic pizza cube];
}

boolean isAsdonWorkshed() {
	return get_workshed() == $item[Asdon Martin keyfob];
}



float pickpocketChance() {
	return numeric_modifier("Pickpocket Chance");
}



string expandOutfits(string maxString) {
	string rval = maxString;
	matcher aMatcher = create_matcher("outfit\\s+([^,]+)", maxString);
	while (find(aMatcher)) {
		string outfitName = strip(group(aMatcher, 1), "' \"");
		foreach key,doodad in outfit_pieces(outfitName) {
			rval = maxStringAppend(rval, "equip " + to_string(doodad));
		}
	}
	return rval;
}



// return the number of weapon or off-hand items explicitly requested in the maxStringToTest
int countHandsUsed(string maxString) {
	int rval = 0;
	string maxStringToTest = expandOutfits(maxString);
	matcher aMatcher = create_matcher("(?<!-)equip\\s+([^,]+)", maxStringToTest);
	while (find(aMatcher)) {
		item anItem = to_item(strip(group(aMatcher, 1), "' \""));
		if (anItem == $item[none]) abort("couldn't convert '" + group(aMatcher, 1) + "' to an item");
		slot aSlot = to_slot(anItem);
		//print("found " + to_item(group(aMatcher, 1)) + ": " + aSlot);
		if (aSlot == $slot[weapon] || aSlot == $slot[off-hand])
			rval++;
	}
	return rval;
}


int count_accessories(string maxString) {
	int rval = 0;
	string maxStringToTest = expandOutfits(maxString);
	matcher aMatcher = create_matcher("(?<!-)equip\\s+([^,]+)", maxStringToTest);
	while (find(aMatcher)) {
		item anItem = to_item(strip(group(aMatcher, 1), "' \""));
		if (anItem == $item[none]) abort("couldn't convert '" + group(aMatcher, 1) + "' to an item");
		slot aSlot = to_slot(anItem);
		if (aSlot == $slot[acc1] || aSlot == $slot[acc2] || aSlot == $slot[acc3])
			rval++;
	}
	return rval;
}



// returns true iff the maxString contains a "-equip" directive for the given item
boolean wantsToNotEquip(string maxString, item anItem) {
	matcher desc_matcher = create_matcher("-equip ([^,]+)", maxString);
	while (find(desc_matcher)) {
		if (to_item(group(desc_matcher, 1)) == anItem)
			return true;
	}
	return false;
}

// returns true iff in the given maxString there is an equip directive for a melee weapon OR
// a "melee" directive
boolean wantsToEquipMelee(string maxString) {
	// melee?
	string [] directives = split_string(maxString, ", ");
	if (arrayContains(directives, "melee"))
		return true;

	// +equip a melee weapon?
	string maxStringToTest = expandOutfits(maxString);
	matcher desc_matcher = create_matcher("(?<!-)equip\\s+([^,]+)", maxStringToTest);
	while (find(desc_matcher)) {
		if (weapon_type(to_item(group(desc_matcher, 1))) == $stat[muscle])
			return true;
	}
	return false;
}


boolean wantsToEquip(string maxString, item anItem) {
	string maxStringToTest = expandOutfits(maxString);
	matcher desc_matcher = create_matcher("(?<!-)equip\\s+([^,]+)", maxStringToTest);
	while (find(desc_matcher)) {
		if (to_item(group(desc_matcher, 1)) == anItem)
			return true;
	}
	return false;
}

// returns true iff all of checkSlot's available room is taken up by "equip" directives in the given maxString
// for most things available room = 1
// weapons = 2, or 1 with an off-hand item, further complicated by 2H items and the left-hand man
// off-hand = 0 with 2H weapon, 1 normally, or 2 with left-hand man
// accessories = 3
boolean wantsToEquip(string maxString, slot checkSlot) {
	string maxStringToTest = maxString.expandOutfits();
	matcher equipMatcher = create_matcher("(?<!-)equip\\s+([^,]+)", maxStringToTest);

	int offHands = 1;
	int totalHands = 2;
	if (my_familiar() == $familiar[left-hand man]) {
		totalHands++;
		offHands++;
	}

	int weaponsEquipped = 0;
	int offhandsEquipped = 0;
	int accessoriesEquipped = 0;
	while (find(equipMatcher)) {
		item equippedItem = to_item(group(equipMatcher, 1));
		assert(equippedItem != $item[none], "could not convert the item in the max string to an item object");
		slot equippedItemSlot = equippedItem.to_slot();

		// if we're looking at a weapon or offhand, check 2H weapons and more than 1 weapon as well
		if (equippedItemSlot == $slot[acc1] || equippedItemSlot == $slot[acc2] || equippedItemSlot == $slot[acc3])
			accessoriesEquipped++;
		else if (equippedItemSlot == $slot[off-hand])
			offhandsEquipped++;
		else if (equippedItemSlot == $slot[weapon] && weapon_type(equippedItem) != $stat[none]) // stat none weapons are weird for some reason
			weaponsEquipped += weapon_hands(equippedItem);

		if ((checkSlot == $slot[off-hand] || checkSlot == $slot[weapon]) && weaponsEquipped + offhandsEquipped >= totalHands)
			return true;
		else if (checkSlot == $slot[off-hand] && offhandsEquipped + max(0, weaponsEquipped - 1) >= offHands)
			return true;
		else if ((checkSlot == $slot[acc1] || checkSlot == $slot[acc2] || checkSlot == $slot[acc3]) && accessoriesEquipped >= 3)
			return true;
		else if (equippedItemSlot == checkSlot && !(checkSlot == $slot[acc1] || checkSlot == $slot[acc2] || checkSlot == $slot[acc3] || checkSlot == $slot[off-hand] || checkSlot == $slot[weapon]))
			return true;
	}

// 	if ((checkSlot == $slot[weapon] || checkSlot == $slot[off-hand]) && weaponsEquipped >= 1)
// 		return maxStringToTest.contains_text("+club") || maxStringToTest.contains_text("type club") || maxStringToTest.contains_text("+accordion") || maxStringToTest.contains_text("type accordion");

	return false;
}


// returns true if the given maximize string allows equipping the given item
// i.e. we're not already equipping an item in the same slot
boolean canEquipWithMaxString(string maxString, item anItem) {
	return ((!maxString.wantsToEquip(to_slot(anItem))) && (!maxString.wantsToNotEquip(anItem)));
}

// returns true if the current automated dressup string allows equipping the given item
boolean canEquipWithExistingAutomatedDressup(item anItem) {
	string maxString = get_property(kDressupMaxStringKey);
	return canEquipWithMaxString(maxString, anItem);
}



string maxStringAppendIfPossibleToEquip(string maxString, item itemToEquip) {
	if (canEquipWithMaxString(maxString, itemToEquip))
		return maxStringAppend(maxString, "equip " + itemToEquip);
	else
		return maxString;
}



string toString(ActionRecord ar) {
	if (ar.attack != false) return "attack!";
	if (ar.pickpocket != false) return "pickpocket!";
	if (ar.skillToUse != $skill[none]) return "use skill: " + ar.skillToUse;
	if (ar.itemToUse != $item[none]) return "use item: " + ar.itemToUse + ", item 2: " + ar.item2ToUse;
	return "empty action!";
}


boolean isEmptyAction(ActionRecord ar) {
	if (ar.attack != false) return false;
	if (ar.pickpocket != false) return false;
	if (ar.skillToUse != $skill[none]) return false;
	if (ar.itemToUse != $item[none]) return false;
	return true;
}


// returns true if the contents of the two ActionRecords are the same, i.e. they reference the same action
boolean isSameAction(ActionRecord one, ActionRecord two) {
	if (one.attack != two.attack) return false;
	if (one.pickpocket != two.pickpocket) return false;
	if (one.skillToUse != two.skillToUse) return false;
	if (one.itemToUse != two.itemToUse) return false;
	if (one.item2ToUse != two.item2ToUse) return false;
	return true;
}


// returns the HTML page that is the result of taking the given action -- must be in combat!
string takeAction(ActionRecord theAction) {
	if (theAction.attack)
		return attack();
	else if (theAction.pickpocket)
		return steal();
	else if (theAction.skillToUse != $skill[none])
		return use_skill(theAction.skillToUse);
	else if (theAction.item2ToUse == $item[none])
		return throw_item(theAction.itemToUse);
	else
		return throw_items(theAction.itemToUse, theAction.item2ToUse);
}


string macroForAction(ActionRecord theAction) {
	if (theAction.attack)
		return "attack;";
	else if (theAction.pickpocket)
		return "pickpocket;";
	else if (theAction.skillToUse != $skill[none])
		return "skill " + theAction.skillToUse + ";";
	else if (theAction.item2ToUse == $item[none])
		return "use " + theAction.itemToUse + ";";
	else
		return "use " + theAction.itemToUse + ", " + theAction.item2ToUse + ";";
}

string macroForActions(ActionRecord [int] actions) {
	string rval;

	// order is important and the records might not have been inserted in order
	for i from 0 to count(actions) {
		ActionRecord action = actions[i];
// 		print("creating macro for action: " + toString(action));
		if (!isEmptyAction(action))
			rval += macroForAction(action);
	}
	return rval;
}


string equipStringForAction(ActionRecord theAction) {
	string rval;
	if (theAction.itemToUse != $item[none] && !theAction.itemToUse.combat) // assumes all non-combat items are equippable and all combat items are not equippable
		rval = "equip " + theAction.itemToUse;
	return rval;
}



// returns the higher of the minPrice or the current market price
int undercutPriceWithMin(item itemToUndercut, int minPrice) {
	int itemPrice = mall_price(itemToUndercut);
	if (itemPrice < 0) {
		print("price is less than 0 for " + itemToUndercut + ", manual intervention required", "red");
		abort(); // ?????
		return minPrice;
	}

	int actualPrice = max(itemPrice, minPrice);
	return actualPrice;
}

// returns the price the item was set to or 0 if repricing was unsuccessful
int undercutWithMinPrice(item itemToUndercut, int limit, int minPrice) {
	int undercutPrice = undercutPriceWithMin(itemToUndercut, minPrice);
	if (reprice_shop(undercutPrice, limit, itemToUndercut))
		return undercutPrice;
	else
		return 0;
}


// stockAmount is the target stock amount, a zero stockAmount means stock all of theItem
boolean stockItem(int minPrice, int limit, int stockAmount, int saveAmount, item theItem) {
	int lowestPrice = mall_price(theItem);
	int price = max(minPrice, lowestPrice);

	int stockedAmount = shop_amount(theItem);
	int availableAmount = available_amount(theItem);
	int targetStockAmount = max(min(stockAmount, availableAmount + stockedAmount - saveAmount), 0);
	int delta = targetStockAmount - stockedAmount;
	if (delta > 0 && delta > availableAmount + stockedAmount - saveAmount) {
		print("don't have enough " + theItem + " to stock " + delta + " more -- inventory amount: " + item_amount(theItem) + ", save amount: " + saveAmount, "red");
		return false;
	}

	print("stocking " + theItem + "@" + price + "(min price: " + minPrice + ") limit: " + limit
		+ ", target amt: " + stockAmount + ", save amt: " + saveAmount + ", actual target stock amt: " + targetStockAmount
		+ " -- lowest mkt price: " + lowestPrice + ", stocked amt: " + stockedAmount
		+ ", avail amt: " + availableAmount + ", delta: " + delta, "green");

	if (price != shop_price(theItem) || limit != shop_limit(theItem)) {
		reprice_shop(price, limit, theItem);
	}

	if (delta < 0) {
		print("removing " + (-delta) + " of " + theItem + "@" + price, "blue");
		return take_shop(-delta, theItem);
	}

	if (delta > 0) {
		print("adding " + delta + " of " + theItem + "@" + price, "blue");
		if (!retrieve_item(delta, theItem))
			abort("could not retrieve " + delta + " of " + theItem + " for store stocking");
		return put_shop(price, limit, delta, theItem);
	}

	return true; // delta == 0
}

// stockAmount is the target stock amount, a zero stockAmount means stock all of theItem
// a negative stockAmount means stock all of theItem except abs(stockAmount)
boolean stockItem(int minPrice, int limit, int stockAmount, item theItem) {
	int lowestPrice = mall_price(theItem);
	int price = max(minPrice, lowestPrice);

	int stockedAmount = shop_amount(theItem);
	int delta = stockAmount - stockedAmount;
	if (stockAmount < 0) {
		delta = available_amount(theItem) + stockAmount;
	}
	if (delta > available_amount(theItem)) {
		print("don't have enough " + theItem + " to stock " + delta + " more -- inventory amount: " + item_amount(theItem), "red");
		return false;
	}

	print("stocking " + theItem + "@" + price + "(min price given: " + minPrice + ") limit " + limit + ", target amount: " + stockAmount + " -- lowest price on market: " + lowestPrice + ", stocked amount: " + stockedAmount + ", delta: " + delta, "green");

	if (price != shop_price(theItem) || limit != shop_limit(theItem)) {
		reprice_shop(price, limit, theItem);
	}

	if (delta < 0) {
		print("removing " + (-delta) + " of " + theItem + "@" + price, "blue");
		return take_shop(-delta, theItem);
	}

	if (delta > 0) {
		print("adding " + delta + " of " + theItem + "@" + price, "blue");
		if (!retrieve_item(delta, theItem))
			abort("could not retrieve " + delta + " of " + theItem + " for store stocking");
		return put_shop(price, limit, delta, theItem);
	}

	return true; // delta == 0
}

// uses stockItem to stock the item with a price set by the higher of the current market price or the given minPrice
boolean undercutItemWithMin(int minPrice, int limit, int stockAmount, item theItem) {
	return stockItem(undercutPriceWithMin(theItem, minPrice), limit, stockAmount, theItem);
}

boolean stockItem(int limit, int stockAmount, item theItem) {
	int price = mall_price(theItem);
	if (price < 0) {
		print("price is less than 0 for " + theItem + ", manual intervention required", "red");
		abort(); // ?????
		return false;
	}
	return stockItem(price, limit, stockAmount, theItem);
}


void printReceipt(int [item] receipt) {
	int items, meat;
	foreach anItem in receipt {
		print(receipt[anItem] + "X " + anItem + " @ " + historical_price(anItem), "green");
		items += receipt[anItem];
		meat += historical_price(anItem) * receipt[anItem];
	}
	print("TOTAL of " + items + " items @ " + meat + " meat (estimated)", "green");
}



void printPSR(PrioritySkillRecord toPrint) {
	print("[" + toPrint.priority + "]" + toPrint.theSkill
		+ " with item " + toPrint.theItem + "@" + toPrint.meatCost
		+ ", " + toPrint.usesAvailable
		+ " uses, available now: " + toPrint.isAvailableNow);
}

void printPSRArray(PrioritySkillRecord [] arrayToPrint) {
	print("");
	foreach psrIndex, psrToPrint in arrayToPrint
		printPSR(psrToPrint);
}



// take the floor of the priority: the lowest of those goes first, ties are broken first by number of uses available, then by the fractional part of the priority
PrioritySkillRecord skillToUse(PrioritySkillRecord [] skillData, location aLocation, int maxPerTurnCost, SkillRecord [] excludedSkills) {
	boolean isInCombat = inCombat();
	print("skillToUse, in combat: " + isInCombat + ", location: " + aLocation + ", maxPerTurnCost: " + maxPerTurnCost);
	printPSRArray(skillData);
	PrioritySkillRecord psr;

	// start by getting the set of skills with the same lowest integer priority and usesAvailable > 0 and isAvailableNow
	PrioritySkillRecord [int] setOfSkillsSamePriority;
	int prioritySetIndex = 0;
	int lowestIntegerPriority = kMaxInt;
	foreach idx in skillData {
		psr = skillData[idx];
		if (arrayContains(excludedSkills, psr)) {
			print("excluding " + psr.theSkill);
			continue;
		}
		if (truncate(psr.priority) == lowestIntegerPriority && psr.usesAvailable > 0 && psr.isAvailableNow) {
			setOfSkillsSamePriority[prioritySetIndex++] = psr;
		} else if (truncate(psr.priority) < lowestIntegerPriority && psr.usesAvailable > 0 && psr.isAvailableNow) {
			prioritySetIndex = 0;
			clear(setOfSkillsSamePriority);
			setOfSkillsSamePriority[prioritySetIndex++] = psr;
			lowestIntegerPriority = truncate(psr.priority);
		}
	}
	// should end up with a set of skills with the lowest integer priority and all available to use now
// 	printPSRArray(setOfSkillsSamePriority);

	// select the set of skills with the highest usesAvailable within the results so far
	PrioritySkillRecord [int] setOfSkillsSameUses;
	prioritySetIndex = 0;
	int highestAvailableUses = 0;
	foreach idx in setOfSkillsSamePriority {
		psr = setOfSkillsSamePriority[idx];
		if (psr.usesAvailable == highestAvailableUses) {
			setOfSkillsSameUses[prioritySetIndex++] = psr;
		} else if (psr.usesAvailable > highestAvailableUses) {
			prioritySetIndex = 0;
			clear(setOfSkillsSameUses);
			setOfSkillsSameUses[prioritySetIndex++] = psr;
			highestAvailableUses = psr.usesAvailable;
		}
	}
	// should end up with a set of banish skills with the lowest integer priority and highest usesAvailable
// 	printPSRArray(setOfSkillsSameUses);

	// select the skill with the highest fractional priority within the results so far
	PrioritySkillRecord [int] setOfSkillsLowestPriority;
	prioritySetIndex = 0;
	float lowestPriority = kMaxInt;
	foreach idx in setOfSkillsSameUses {
		psr = setOfSkillsSameUses[idx];
		if (psr.priority == lowestPriority) {
			setOfSkillsLowestPriority[prioritySetIndex++] = psr;
		} else if (psr.priority < lowestPriority) {
			prioritySetIndex = 0;
			clear(setOfSkillsLowestPriority);
			setOfSkillsLowestPriority[prioritySetIndex++] = psr;
			lowestPriority = psr.priority;
		}
	}

	printPSRArray(setOfSkillsLowestPriority);
	// choose one of the remaining and make sure we can use it
	int i = 0;
	while (i < count(setOfSkillsLowestPriority)) {
		psr = setOfSkillsSameUses[i];
		if (psr.theSkill == $skill[none] // no skill means we're prioritizing items that we don't have to equip, in which case, return the first one
			|| psr.theItem == $item[none] || equipped_amount(psr.theItem) > 0 // otherwise, make sure we can equip the item
			|| (!isInCombat && can_equip(psr.theItem) && canEquipWithExistingAutomatedDressup(psr.theItem)))
			break;
		i++;
	}

	// if all the recommended banishers are invalid (mostly because we can't equip the item for
	// one reason or another -- not enough stats usually), exclude all the banishers we got and try again
	// TODO FIXME merge excluded arrays
// 	if(count(setOfBanishesLowestPriority) > 0) {
// 		print("chosen banisher can't be equipped, trying again", "orange");
// 		return banishToUse(isInCombat, aLocation, ignoreCost, setOfBanishesLowestPriority);
// 	}

	print("choosing number " + i);
	printPSR(setOfSkillsLowestPriority[i]);
	return setOfSkillsLowestPriority[i];
}

PrioritySkillRecord topPriority(PrioritySkillRecord [] priorityData) {
	SkillRecord [] excludedData;
	return skillToUse(priorityData, $location[none], kMaxInt, excludedData);
}



// -------------------------------------
// FINANCIAL UTILITIES ITEM UTILITIES MEAT UTILITIES
// -------------------------------------


// print item details
void printItemDetails(item anItem) {
	print("name: " + anItem.name);
	print("levelreq: " + anItem.levelreq);
	print("quality: " + anItem.quality);
	print("adventures: " + anItem.adventures);
	print("fullness: " + anItem.fullness);
	print("inebriety: " + anItem.inebriety);
	print("combat: " + anItem.combat);
	print("combat_reusable: " + anItem.combat_reusable);
	print("usable: " + anItem.usable);
	print("reusable: " + anItem.reusable);
	print("multi: " + anItem.multi);
	print("fancy: " + anItem.fancy);
	print("seller: " + anItem.seller);
	print("buyer: " + anItem.buyer);
}



// returns the cost of the given item per buff given, including the number used and the opportunity cost of using it
int analyzeItem(item itemToAnalyze, int buff, int useAmount, int opportunityCost) {
	return ((mall_price(itemToAnalyze) * useAmount) + opportunityCost) / buff;
}


// returns the cost of the given item per buffAmount given, including the number used and the opportunity cost of using it
int costPerBuffTurn(item itemToAnalyze, int buffAmount, int duration, int opportunityCost) {
	return round((mall_price(itemToAnalyze).to_float() + opportunityCost) / buffAmount / duration);
}



// returns the meat value of all items (items only NOT MEAT) dropped by the given mob at the given item drop bonus
// if something is not salable at the mall (determined by the mall price being equal to the min price) use the autosell price in the calculation instead
int monsterItemMeatValue(monster mob, float bonusItemDrop) {
	if (mob == $monster[none]) return 0;

	float totalMeatValue = 0;
	foreach index, data in item_drops_array(mob) {
		float dropRate = (data.rate * (1 + bonusItemDrop/100)) / 100;
		if (dropRate > 1.0) dropRate = 1.0;
		if (data.type == "0") dropRate = (0.1 * (1 + bonusItemDrop/100)) / 100; // no info available, set to 0.1% by default
		int mallPrice = mall_price(data.drop);
		if (autosell_price(data.drop) > 0 && mallPrice == autosell_price(data.drop) * 2) {
			//print("unsellable item: " + data.drop);
			mallPrice = autosell_price(data.drop);
		}
		totalMeatValue += mall_price(data.drop) * dropRate;
	}
	return totalMeatValue;
}

int monsterBaseItemMeatValue(monster mob) {
	return monsterItemMeatValue(mob, 0);
}

int monsterCurrentItemMeatValue(monster mob) {
	return monsterItemMeatValue(mob, item_drop_modifier());
}


// returns the meat value dropped by the given mob at the given item and meat drop level
int monsterMeatDropValue(monster mob, float bonusMeatDrop) {
	if (mob == $monster[none]) return 0;
	return meat_drop(mob) * (1 + bonusMeatDrop/100);
}

int monsterBaseMeatDropValue(monster mob) {
	return monsterMeatDropValue(mob, 0.0);
}

int monsterCurrentMeatDropValue(monster mob) {
	return monsterMeatDropValue(mob, meat_drop_modifier());
}



// returns the meat value dropped by the given mob at the given item and meat drop level
int monsterTotalMeatValue(monster mob, float bonusItemDrop, float bonusMeatDrop) {
// 	float meatDrop = meat_drop(mob) * (1 + bonusMeatDrop/100);
// 	meatDrop += monsterItemMeatValue(mob, bonusItemDrop);
	return monsterItemMeatValue(mob, bonusItemDrop) + monsterMeatDropValue(mob, bonusMeatDrop);
}

int monsterBaseTotalMeatValue(monster mob) {
	return monsterTotalMeatValue(mob, 0.0, 0.0);
}

int monsterCurrentTotalMeatValue(monster mob) {
	return monsterTotalMeatValue(mob, item_drop_modifier(), meat_drop_modifier());
}



// prints the given item drops and their base drop rate modified by the bonusItemDrop
void printItemDrops(ItemDropRecord [int] itemDropsArray, float bonusItemDrop) {
	foreach index, data in itemDropsArray {
		float rate = data.rate * (1 + bonusItemDrop/100);
		string rateString = to_string(rate, "%.2f") + "%";
		if (data.type == "0")
			rateString = "0.1%??";
		if (data.type != "b")
			print(rateString + " drop rate for " + data.drop + "@" + mall_price(data.drop) + (data.type=="p" ? " (pickpocket only)" : ""));
	}
}


// prints item drops and their base drop rate modified by the bonusItemDrop for the given monster
void printMonsterItemDrops(monster mob, float bonusItemDrop) {
	printItemDrops(normalized_item_drops_array(mob), bonusItemDrop);
	print("total value at +" + bonusItemDrop + "% item drop: " + monsterItemMeatValue(mob, bonusItemDrop));
}


// prints meat and item drops for the given mob
void printMonsterDropDetails(monster mob, float bonusItemDrop, float bonusMeatDrop) {
	int meatDropValue = monsterMeatDropValue(mob, bonusMeatDrop);
	print(mob + " (with +" + to_string(bonusItemDrop, "%.2f") + "% item and +" + to_string(bonusMeatDrop, "%.2f") + "% meat) drops " + meatDropValue + " meat");
	printMonsterItemDrops(mob, bonusItemDrop);
	print("GRAND TOTAL: " + monsterTotalMeatValue(mob, bonusItemDrop, bonusMeatDrop));
}

void printMonsterBaseDropDetails(monster mob) {
	printMonsterDropDetails(mob, 0, 0);
}

void printMonsterCurrentDropDetails(monster mob) {
	printMonsterDropDetails(mob, item_drop_modifier(), meat_drop_modifier());
}


// prints item drops and their base drop rate modified by the bonusItemDrop for the given monster
void printMonsterPickpocketDrops(monster mob, float bonusPPDrop) {
	printItemDrops(ppItemDropsArray(mob), bonusPPDrop);
	print("total value at +" + bonusPPDrop + "% item drop: " + monsterItemMeatValue(mob, bonusPPDrop));
}

void printMonsterBasePickpocketDrops(monster mob) {
	printMonsterPickpocketDrops(mob, 0);
}

void printMonsterCurrentPickpocketDrops(monster mob) {
	printMonsterPickpocketDrops(mob, pickpocketChance());
}



// returns the meat value dropped by the given location at the given item and meat drop level
int locationMeatValue(location aLocation, float bonusItemDrop, float bonusMeatDrop) {
	float meatDrop = 0;
	int numberOfMonsters = 0;
	foreach i1, mob in get_monsters(aLocation) {
		meatDrop += monsterTotalMeatValue(mob, bonusItemDrop, bonusMeatDrop);
		numberOfMonsters++;
	}
	return meatDrop / numberOfMonsters;
}

int locationBaseMeatValue(location aLocation) {
	return locationMeatValue(aLocation, 0, 0);
}

int locationCurrentMeatValue(location aLocation) {
	return locationMeatValue(aLocation, item_drop_modifier(), meat_drop_modifier());
}



float itemBaseDropChance(item wantedItem, monster fromMonster) {
	foreach index, data in item_drops_array(fromMonster) {
		if (data.drop == wantedItem)
			return data.rate;
	}

	abort(fromMonster + " does not drop " + wantedItem);
	return 0;
}


float itemDropBonusNeededToGuarantee(item wantedItem, monster fromMonster) {
	return ((100.0 / itemBaseDropChance(wantedItem, fromMonster)) - 1) * 100;
}



// TODO double check this and generalize
int perAdventureCost() {
	float perAdventureCost = 0;
	//perAdventureCost += (mall_price($item[Crimbo fudge]) + mall_price($item[Swizzler])) / 50; // Sweet Synthesis Collection (item)
	if (isAsdonWorkshed()) {
		perAdventureCost += (329 + 462) / 30.0; // Spring-loaded Front Bumper (banish)
		perAdventureCost += (329 + 462) / 30.0; // Driving somethingly
	}
	//perAdventureCost += 0 / 50; // Items are Forever (KGB) can't guarantee each time
	return perAdventureCost;
}



void locationMeatDetails(location aLocation, float perAdventureCost, float itemDrop, float meatDrop) {
	record dropdata {
		item drop;
		int rate;
		string type;
	};

	print(aLocation + ", per adv cost: " + perAdventureCost);
	foreach mob, rate in appearance_rates(aLocation) {
		print(mob + " (" + rate + "%) meat drop: " + monsterMeatDropValue(mob, meatDrop) + ", item drop: " + monsterItemMeatValue(mob, itemDrop) + " total: " + (monsterTotalMeatValue(mob, itemDrop, meatDrop) - perAdventureCost));
	}
}

void locationBaseMeatDetails(location aLocation) {
	locationMeatDetails(aLocation, perAdventureCost(), 0, 0);
}

void locationCurrentMeatDetails(location aLocation) {
	locationMeatDetails(aLocation, perAdventureCost(), item_drop_modifier(), meat_drop_modifier());
}



void locationDropDetails(location aLocation) {
	record dropdata {
		item drop;
		int rate;
		string type;
	};

	dropdata [monster][int] all_mon_drops;
	foreach i1, mob in get_monsters(aLocation)
		foreach index, rec in item_drops_array(mob) {
			all_mon_drops [mob][index].drop = rec.drop;
			all_mon_drops [mob][index].rate = rec.rate;
			all_mon_drops [mob][index].type = rec.type;
		}

	foreach mob, index, data in all_mon_drops {
		string rate = data.rate + "%";
		if (data.type == "0")
			rate = "unknown rate";
		if (data.type != "p" && data.type != "b")
			print(mob + ", drops " + data.drop + ": " + rate + " @ " + mall_price(data.drop));
	}
}



// -------------------------------------
// OUTFIT UTILITIES
// -------------------------------------


boolean haveOutfit(string outfitName) {
	print("checking outfit name: " + outfitName, "orange");
	boolean rval = false;
	if (outfitName.starts_with("_"))
		rval = get_property(kSavedOutfitKeyPrefix + outfitName) != "";
	else
		rval = have_outfit(outfitName);
		
	print("haveOutfit: " + rval, "orange");
	return rval;
}



void saveEquippedFamiliar(string outfitName) {
	set_property(kSavedFamiliarKeyPrefix + outfitName, my_familiar());
	set_property(kSavedFamiliarEquipKeyPrefix + outfitName, equipped_item($slot[familiar]));
}

void saveEquippedFamiliar() {
	saveEquippedFamiliar("Backup");
}


void saveOutfit(string outfitName) {
	print("Saving outfit: " + outfitName, "blue");
	if (!outfitName.starts_with("_")) {
		cli_execute("outfit save " + outfitName);
	}

	string outfitString = logEquipmentString(true);
	print(outfitString, "green");
	set_property(kSavedOutfitKeyPrefix + outfitName, outfitString);
	saveEquippedFamiliar(outfitName);
}

void saveOutfit() {
	saveOutfit("Backup");
}


boolean restoreEquippedFamiliar(string outfitName) {
	familiar theFamiliar = to_familiar(get_property(kSavedFamiliarKeyPrefix + outfitName));
	if (my_familiar() != theFamiliar)
		if (!use_familiar(theFamiliar))
			return false;

	item familiarEquipment = to_item(get_property(kSavedFamiliarEquipKeyPrefix + outfitName));
	if (equipped_item($slot[familiar]) != familiarEquipment) {
		fullAcquire(familiarEquipment);
		if (!equip(familiarEquipment))
			return false;
	}
	return true;
}

boolean restoreEquippedFamiliar() {
	return restoreEquippedFamiliar("");
}


// restore an outfit using the built-in outfit system iff the outfit name does not start with "_" underscore
// if it does start with underscore, will use the property database to store the outfit and re-equip one piece at a time.
boolean restoreOutfit(boolean restoreFamiliar, string outfitName) {
	string outfitPiecesString = get_property(kSavedOutfitKeyPrefix + outfitName);
	print("Wearing outfit: " + outfitName + ", restoring familiar: " + restoreFamiliar, "blue");
	print(outfitPiecesString, "green");

	boolean rval = true;

	item [int] outfitPieces;
	int i;
	if (outfitName.starts_with("_")) {
		foreach idx, pieceString in outfitPiecesString.split_string(", ") {
			string [] pieces = pieceString.split_string(": ");
			if (pieces[1] == "none") continue; // some slots will have no item equipped
			if (pieces[0].starts_with("fam")) continue; // ignore saved familiar (fam will be done by restoreEquippedFamiliar)

			slot theSlot = pieces[0].to_slot();
			item theEquipment = pieces[1].to_item();

			assert(theEquipment != $item[none] && theSlot != $slot[none], "restoreOutfit: something wrong with item: " + pieces[1] + " in slot: " + pieces[0]);
			outfitPieces[i] = theEquipment;
			i++;
		}
	} else
		outfitPieces = outfit_pieces(outfitName);

	// count the number of each item we need
	int [item] itemCount;
	foreach key, doodad in outfitPieces
		itemCount[doodad]++;

	// calc the difference between what we are wearing and what we want to wear
	int [item] needed;
	foreach doodad, amt in itemCount {
		if (equipped_amount(doodad) < amt) {
			needed[doodad] = amt - equipped_amount(doodad);
		}
	}

	// acquire each piece
	foreach doodad, amt in needed {
		if (!fullAcquire(amt, doodad)) {
			rval = false;
			print("restoreOutfit: could not acquire " + amt + " X " + doodad + "!!!", "orange");
		}
	}

	if (outfitName.starts_with("_") || !cli_execute("outfit " + outfitName)) {
		// equip one piece at a time
		foreach key, doodad in outfitPieces {
			if (can_equip(doodad) && have_item(doodad) && equipped_amount(doodad) < 1)
				equip(doodad);
			else if (equipped_amount(doodad) < 1)
				rval = false;
		}
	}

	if (restoreFamiliar)
		rval = restoreEquippedFamiliar(outfitName) && rval; // order is important with short-circuiting

	return rval;
}

boolean restoreOutfit(boolean restoreFamiliar) {
	return restoreOutfit(restoreFamiliar, "Backup");
}


void clearSavedFamiliar(string outfitName) {
	set_property("_" + outfitName + "_savedFamiliar", "");
	set_property("_" + outfitName + "_savedFamiliarEquipment", "");
}

void clearSavedFamiliar() {
	clearSavedFamiliar("");
}


void wearDefaultOutfit() {
	cli_execute("outfit " + kDefaultOutfit);
}



int fullnessRoom() {
	return fullness_limit() - my_fullness();
}


int inebrietyRoom() {
	return inebriety_limit() - my_inebriety();
}


int spleenRoom() {
	return spleen_limit() - my_spleen_use();
}


boolean isOverdrunk() {
	return my_inebriety() > inebriety_limit();
}


// returns true if we're max'ed out on food and drink
// if checkSpleen is true, check we have at least 5 spleen to recover from overdrinking fermented pickle juice
boolean readyToOverdrink(boolean checkSpleen) {
	int myLimit = inebriety_limit();
	if (my_familiar() == $familiar[Stooper]) myLimit--;

	if (my_inebriety() != myLimit && my_inebriety() != myLimit + 1) return false;
	if (my_fullness() != fullness_limit()) return false;
	if (checkSpleen && my_spleen_use() < 5) return false;

	return true;
}


// returns true if we have yet to drink 1 drunkenness for the stooper
boolean stooperPending() {
	boolean haveStooper = my_familiar() == $familiar[Stooper];
	return (haveStooper && my_inebriety() < inebriety_limit()) || (!haveStooper && my_inebriety() <= inebriety_limit());
}



// returns true if we're an accordion thief with an accordion equipped
boolean atAccordionEquipped() {
	return my_class() == $class[accordion thief] && item_type(equipped_item($slot[weapon])) == "accordion";
}



// returns the total number of adventures gained at rollover. Includes:
// base 40, gains from outfit, gains from special days, any special items that may affect adv at rollover
// if shouldSimulate is true, will use maximize to figure out a best case scenario for outfit, if false, will use whatever we're wearing now
int adventureGainAtRollover(boolean shouldSimulate) {
	int adv = 40;
	if (shouldSimulate) {
		maximize("adventures, switch tot", true);
		adv += numeric_modifier("Generated:_spec", "Adventures");
	} else {
		adv += numeric_modifier("Adventures");
	}
	if (to_boolean(get_property("_borrowedTimeUsed"))) adv -= 20;
	adv += to_int(get_property("extraRolloverAdventures")); // not sure what this is, seems to be 0
	if (gameday_to_string() == "Carlvember 5") adv += 10;
	return adv;
}  

int adventureGainAtRollover() {
	return adventureGainAtRollover(false);
}

int myAdventuresAtRollover(boolean shouldSimulate) {
	return adventureGainAtRollover() + my_adventures();
}  

// total adventures at rollover based on what you have on now
int myAdventuresAtRollover() {
	return myAdventuresAtRollover(false);
}


void clearGoals() {
	/*int i;
	string g;
	foreach i,g in get_goals();
		remove_item_condition(i, to_item(g)); */
	// above doesn't work for some reason
	cli_execute("goal clear");
}

boolean haveGoals() {
	return count(get_goals()) > 0;
}


// returns the turn on which a semi-rare will be encountered
int fortuneCookie() {
	string counter_string = get_property("relayCounters");
	string [int] counter_split = split_string(counter_string.replace_string("|", ":"), ":");

	//Parse counters:
	for i from 0 to (counter_split.count() - 1) by 3 {
		if (i + 3 > counter_split.count())
			break;
		if (counter_split[i].length() == 0)
			continue;
		int turn_number = to_int(counter_split[i]);
		int turns_until_counter = turn_number - my_turncount();
		string counter_name_raw = counter_split[i + 1];
		string counter_gif = counter_split[i + 2];
		string location_id;
		string type;

		if (counter_name_raw == "Fortune Cookie") {
			return turn_number;
		}
	}
	return -1;
}


boolean semirareKnown() {
	return fortuneCookie() >= my_turncount();
}


int turnsUntilSemiRare() {
	if (!semirareKnown())
		return -1;
	return fortuneCookie() - my_turncount();
}



// returns the largest familiar weight adjustment we could get by dressing in the right clothes
int maxWeightAdjustement() {
	maximize("familiar weight", true);
	return numeric_modifier("Generated:_spec", "Familiar Weight");
}



int smutOrcPervertProgress() {
	//return $location[The Smut Orc Logging Camp].turns_spent % 20;
	return to_int(get_property(kSmutOrcPervertProgressKey));
}

void setSmutOrcPervertProgress(int progress) {
	set_property(kSmutOrcPervertProgressKey, progress);
}


void normalizeSmutOrcPervertProgress() {
	print("smut orc logging camp turns spent: " + $location[The Smut Orc Logging Camp].turns_spent);
}



int turnsSinceSausageGoblin() {
	return total_turns_played() - to_int(get_property("_lastSausageMonsterTurn"));
}


int maxTurnsToNextSausageGoblin() {
	int sausageFights = to_int(get_property("_sausageFights"));
// 	return 1 + (3 * numberOfSausageGoblins) + (max(0, numberOfSausageGoblins - 5) ^ 3);
	return 5 + sausageFights * 3 + max(0, sausageFights - 5) ** 3 - 1;
}


float chanceOfSausageGoblinNextTurn() {
	return (turnsSinceSausageGoblin() + 1.0) / (maxTurnsToNextSausageGoblin() + 1.0);
}


void checkForLastSausageGoblin() {
// 	if (!inRonin() && last_monster() == $monster[sausage goblin] && to_int(get_property("_backUpUses")) < 11)
	if (!inRonin() && get_property(kCheckForLastSausageGoblinKey).to_boolean()) {
		print("turns since last sausage goblin: " + turnsSinceSausageGoblin() + ", chance of encounter: " + chanceOfSausageGoblinNextTurn() + "%");
		if (last_monster() == $monster[sausage goblin] && get_property("_backUpUses").to_int() < 11
			&& get_property("_sausageFights").to_float() >= (kSausagesToGet * (2.0/3.0)))
			abort("sausage goblin!");
	}
}



int breatheWater() {
	int breathWaterFor = max(have_effect($effect[Really Deep Breath]), have_effect($effect[Oxygenated Blood]));
	breathWaterFor = max(breathWaterFor, have_effect($effect[Pneumatic]));
	breathWaterFor = max(breathWaterFor, have_effect($effect[Driving Waterproofly]));
	return max(breathWaterFor, have_effect($effect[Pumped Stomach]));
}

boolean canBreatheWater() {
	return breatheWater() > 0;
}



// hippy camp and orcish frat house locations are weird
location mysterious_island_camp(string camp) {
	location aLocation;
	if (camp == "hippy") {
		aLocation = to_location("The Hippy Camp");
		if (aLocation != to_location("The Hippy Camp"))
			aLocation = to_location("The Hippy Camp (Bombed Back to the Stone Age)");
	} else if (camp == "frat") {
		aLocation = $location[Frat House];
		if (aLocation != $location[Frat House])
			aLocation = $location[The Orcish Frat House (Bombed Back to the Stone Age)];
	}
	return aLocation;
}



// returns the number of UNBANISHED monsters at aLocation.
// if get_all is false, only monsters with a positive appearance rate will be counted
// (which means bosses and monsters in NCs are excluded)
int number_monsters(location aLocation, boolean get_all) {
	float [monster] monster_map = appearance_rates(aLocation);
	int total_monsters = 0;
	foreach m in monster_map {
		if ((m != $monster[none]) && (get_all || (monster_map[m] > 0))) {
			total_monsters++;
		}
	}
	return total_monsters;
}


// does the given location have the given monster?
boolean contains_monster(location aLocation, monster a_monster) {
	monster [int] monster_map = get_monsters(aLocation);
	foreach i in monster_map
		if (monster_map[i] == a_monster) return true;
	return false;
}



string raw_quest_log_string = "";
string get_quest_log() {
	if (raw_quest_log_string == "") {
		raw_quest_log_string = visit_url("/questlog.php?which=7", true, false);
	}
	return raw_quest_log_string;
}

string [string] quest_log_entries;
string [string] parse_quest_log() {
	if (count(quest_log_entries) == 0) {
		string page = get_quest_log();
		matcher aMatcher = create_matcher("<b>([^>]+)</b><br>(.+?)<p>", page);
		while (find(aMatcher)) {
			string quest_name = group(aMatcher, 1);
			string quest_text = group(aMatcher, 2);
			quest_log_entries[quest_name] = quest_text;
		}
	}

	return quest_log_entries;
}

void clear_quest_log_cache() {
	raw_quest_log_string = "";
	clear(quest_log_entries);
}

// returns the quest text for the given quest
string quest(string quest) {
	return parse_quest_log()[quest];
}

boolean is_on_quest(string quest) {
	return parse_quest_log() contains quest;
}

void print_quest(string quest_name) {
	print_html("<b>" + quest_name + ": </b>" + quest(quest_name));
}

void print_quest_log() {
	string [string] quest_log_entries = parse_quest_log();
	foreach quest in quest_log_entries {
		print_html("<b>" + quest + ": </b>" + quest_log_entries[quest]);
	}
}



int get_price(item itm) {
	if (historical_age(itm) < 7) return historical_price(itm);
	return mall_price(itm);
}



boolean is_pvpable(item thing) {
	return thing.tradeable && thing.discardable && !thing.gift && !thing.quest;
}


// closet any items valued greater than expensiveValue
// WARNING: will store items that are potentially useful in combat
void store_pvp() {
	int expensiveValue = 400;

	int [item] inventory = get_inventory();
	batch_open();
	foreach it in inventory {
		if(is_pvpable(it) && get_price(it) > expensiveValue) {
			print_html("storing: " + item_amount(it) + " " + it + "@" + get_price(it));
			put_closet(item_amount(it), it);
		}
	}
	batch_close();
}

void stow_pvpable_items() {
	if (hippy_stone_broken()) {
		store_pvp();
	}
}



// TODO
void getFreeGoofballs() {
	buffer goofballVendorString = visit_url("/tavern.php?place=susguy", true, false);
	matcher freeGoofballMatcher = create_matcher("(for free!)", goofballVendorString);
	if (find(freeGoofballMatcher)) {
		// get those free goofballs
	}
}



int fernswarthy_level() {
	string raw_fernswarthy_string = visit_url("/basement.php", true, false);
	matcher aMatcher = create_matcher("Fernswarthy's Basement, Level ([0-9]+)", raw_fernswarthy_string);
	if (!find(aMatcher)) return 0;
	return to_int(group(aMatcher, 1));
}



void getDefaultPastaThrall() {
	use_skill($skill[bind spice ghost]);
}



// returns true if we detect that we have restarted mafia after running breakfast
// assumes Advanced Cocktail Crafting will be cast during breakfast
boolean haveRestartedMafia() {
	int cocktailCraftingDrops = my_session_items($item[coconut shell]) + my_session_items($item[little paper umbrella]) + my_session_items($item[magical ice cubes]);
	return cocktailCraftingDrops < 5 && get_property("breakfastCompleted").to_boolean();
}



int aerogelAttacheCaseItemDrops() {
	int dropsFromCocktailCrafting = (get_property("cocktailSummons").to_int() > 0 || haveRestartedMafia()) ? 5 : 0;
	return my_session_items($item[coconut shell]) + my_session_items($item[little paper umbrella]) + my_session_items($item[magical ice cubes]) - dropsFromCocktailCrafting;
}



item [] inventoryArray() {
	item [int] invItems;

	int i = 0;
	foreach it in get_inventory() {
		invItems[i] = it;
		i++;
	}
	return invItems;
}



void listHighQuantityItems() {
	item [int] invItems = inventoryArray();
	sort invItems by -available_amount(value);

	foreach x, it in invItems {
		int available = available_amount(it);
		if (available > 2 * my_ascensions()) {
			print(available + "X " + it);
		}
	}
}


void pull_high_quantity_items() {
	item [int] storage_items;

	int i = 0;
	foreach it in get_storage() {
		storage_items[i] = it;
		i++;
	}

	sort storage_items by -storage_amount(value);

	batch_open();
	foreach x, it in storage_items {
		int stored = storage_amount(it);
		if (stored > 2 * my_ascensions()) {
			print("pulling " + stored + " of " + it);
			take_storage(stored, it);
		}
	}
	boolean sexy = batch_close();
	print("pull batch successful: " + sexy);
}



// can the item be ground by the kramco sausage grinder
boolean is_grindable(item grind_test) {
	return item_amount(grind_test) > 2 * my_ascensions() && item_type(grind_test) != "food" && item_type(grind_test) != "booze";
}

void list_grindable_items() {
	int expensiveValue = 200;
	item [int] inv_items = inventoryArray();
	sort inv_items by -item_amount(value);

	foreach x, it in inv_items
		if (is_grindable(it) && get_price(it) < expensiveValue && is_pvpable(it)) {
			print(item_amount(it) + " " + it);
		}
}


boolean setBoombox(string boom) {
	return cli_execute("boombox " + boom);
}

void setDefaultBoombox() {
	setBoombox("food");
}



// TODO
boolean saveState() {
	return true;
}

boolean restoreState() {
	return true;
}



// set us up in the default state: outfit, mood, boombox
void setDefaultKoLState() {
// 	wearDefaultOutfit(); // this really slows things down when doing the same thing over and over
	max_mcd();
	setDefaultMood();
	setDefaultBoombox();
}



void printMonsterDetails(monster aMonster) {
	print(aMonster);
	print("physical_resistance: " + aMonster.physical_resistance);
}



boolean useMoMifNeeded() {
	if (!to_boolean(get_property("_milkOfMagnesiumUsed")))
		return use(1, $item[milk of magnesium]);
	return true;
}



// ensures the given song buff can be cast right now
// returns true if it could make the room (or room already exists)
boolean ensureSongRoom(skill [] songsToPlay) {
	int roomNeeded = 0;
	skill [int] songsThatNeedSpace;
	foreach idx, song in songsToPlay {
		if (have_effect(to_effect(song)) == 0) {
			songsThatNeedSpace[roomNeeded] = song;
			roomNeeded++;
		}
	}
	if (roomNeeded == 0 || accordionSongsActive() + roomNeeded <= maxAccordionSongs())
		return true;

	skill [int] uneffectSongOrder = {
		1: $skill[The Ode to Booze],
		2: $skill[The Power Ballad of the Arrowsmith],
		3: $skill[The Magical Mojomuscular Melody],
		4: $skill[The Moxious Madrigal],
		5: $skill[Stevedave's Shanty of Superiority],
		6: $skill[The Psalm of Pointiness],
		7: $skill[Brawnee's Anthem of Absorption],
		8: $skill[Prelude of Precision],
		9: $skill[Cletus's Canticle of Celerity],
		10: $skill[Jackasses' Symphony of Destruction],
		11: $skill[Dirge of Dreadfulness],
		12: $skill[Benetton's Medley of Diversity],
		13: $skill[Elron's Explosive Etude],
		14: $skill[Aloysius' Antiphon of Aptitude],
		15: $skill[Ur-Kel's Aria of Annoyance],
		16: $skill[The Sonata of Sneakiness],
		17: $skill[Carlweather's Cantata of Confrontation],
		18: $skill[Chorale of Companionship],
		19: $skill[The Polka of Plenty],
		20: $skill[Fat Leon's Phat Loot Lyric],
		// never uneffect these
// 		21: $skill[Inigo's Incantation of Inspiration],
// 		22: $skill[Donho's Bubbly Ballad],
// 		23: $skill[The Ballad of Richie Thingfinder],
	};

	foreach idx, songToPlay in songsThatNeedSpace {
		print("uneffecting a song buff to make room for " + songToPlay, "green");

		// first, go through and uneffect in order a buff that isn't part of our mood
		foreach idx, aSong in uneffectSongOrder {
			if (roomNeeded == 0)
				return true;
			if (have_effect(to_effect(aSong)) > 0 && !inMood(aSong) && !arrayContains(songsToPlay, aSong)) {
				if (uneffect(aSong))
					roomNeeded--;
				else
					abort("failed uneffecting non-mood skill " + aSong + " to make room for " + songToPlay);
			}
		}

		// if we got here, we don't have a song that isn't in the current mood
		// go through in order and uneffect the first song we find
		foreach idx, aSong in uneffectSongOrder {
			if (roomNeeded == 0)
				return true;
			if (have_effect(to_effect(aSong)) > 0 && !arrayContains(songsToPlay, aSong)) {
				if (uneffect(aSong))
					roomNeeded--;
				else
					abort("failed uneffecting mood skill " + aSong + " to make room for " + songToPlay);
			}
		}
	}

	return roomNeeded == 0;
}

boolean ensureSongRoom(skill songToPlay) {
	skill [] songsToPlay = {songToPlay};
	return ensureSongRoom(songsToPlay);
}

boolean ensureSongRoom()  {
	return ensureSongRoom($skill[none]);
}


boolean uneffectIfNeeded(skill buff) {
	if (isATSong(buff))
		return ensureSongRoom(buff);

	return true;
}


void shakeOffNonMoodSongs() {
	int [skill] activeSongs = activeSongs();
	int [skill] moodSongs = moodSongs();

	foreach aSkill in activeSongs {
		print("testing:  " + aSkill);
		if (!(moodSongs contains aSkill))
			uneffect(aSkill.to_effect());
	}
}



boolean use_skill_if_needed(int minimumNumberOfTurns, skill aSkill) {
	assert(aSkill != $skill[none], "use_skill_if_needed: no skill");

	boolean executed = true;
	effect theEffect = to_effect(aSkill);
	while (have_effect(theEffect) < minimumNumberOfTurns && executed) {
		int effectTurns = have_effect(theEffect);
		executed = use_skill(1, aSkill); // this is not returning false under all circumstances where the skill fails
		if (have_effect(theEffect) == effectTurns) // no extra turns_per_cast
			break;
	}

	if (have_effect(theEffect) < minimumNumberOfTurns)
		abort("unable to get enough " + theEffect);

	return executed;
}

boolean use_skill_if_needed(skill aSkill) {
	return use_skill_if_needed(1, aSkill);
}



// ensure we have enough buff space to play songToPlay and then insure we have minimumNumberOfTurns of the associated effect
// will try to avoid uneffecting buffs in the current mood
boolean songBuffIfNeededWithUneffect(skill songToPlay, int minimumNumberOfTurns) {
	uneffectIfNeeded(songToPlay);
	return use_skill_if_needed(minimumNumberOfTurns, songToPlay);
}


boolean useOdeToBoozeIfNeeded(int minTurns) {
	boolean success = songBuffIfNeededWithUneffect($skill[The Ode To Booze], minTurns);
	assert(!success || have_effect($effect[Ode to Booze]) >= minTurns, "didn't get enough ode to booze");
	return success;
}



// will Ode To Booze or milk of magnesium as necessary
// uses "drink", so will give a user-confirm warning when overdrinking
string cliStringToConsume(int quantity, item itemToConsume) {
	string rval;
	if (itemToConsume.fullness > 0) {
		if (!to_boolean(get_property("_milkOfMagnesiumUsed")))
			rval = "use milk of magnesium; ";
		return rval + "eat " + quantity + " " + itemToConsume;

	} else if (itemToConsume.inebriety > 0) {
		return "useOdeToBoozeIfNeeded (" + (itemToConsume.inebriety * quantity) + "); drink " + quantity + " " + itemToConsume;

	} else if (itemToConsume.spleen > 0)
		return "chew " + quantity + " " + itemToConsume;

	else
		return "use " + quantity + " " + itemToConsume;
}


// consume (eat/drink/chew/use) any item.
// will Ode To Booze or milk of magnesium as necessary
// uses "drink", so will give a user-confirm warning when overdrinking
boolean consume(int quantity, item itemToConsume) {
	print("consuming: " + quantity + " X " + itemToConsume, "green");

	if (itemToConsume.fullness > 0) {
		useMoMifNeeded();
		return eat(quantity, itemToConsume);

	} else if (itemToConsume.inebriety > 0) {
		useOdeToBoozeIfNeeded(itemToConsume.inebriety * quantity);
		return drink(quantity, itemToConsume);

	} else if (itemToConsume.spleen > 0)
		return chew(quantity, itemToConsume);

	else
		return use(quantity, itemToConsume);
}



// consume any item, one at a time, to achieve minimumNumberOfTurns of anEffect
// assumes itemToConsume actually gives anEffect
boolean consumeIfNeeded(item itemToConsume, effect anEffect, int minimumNumberOfTurns) {
	boolean executed = true;
	while (have_effect(anEffect) < minimumNumberOfTurns && executed) {
		int beforeEffect = have_effect(anEffect);
		executed = consume(1, itemToConsume);
		int afterEffect = have_effect(anEffect);
		if (beforeEffect == afterEffect) {
			print("consumeIfNeeded: not getting " + anEffect + " from " + itemToConsume + "!", "red");
			executed = false;
		}
	}
	return executed;
}

boolean use_if_needed(item itemToUse, effect anEffect, int minimumNumberOfTurns) {
	return consumeIfNeeded(itemToUse, anEffect, minimumNumberOfTurns);
}


boolean consumeIfNeededWithUneffect(item itemToConsume, effect anEffect, int minimumNumberOfTurns) {
	if (to_skill(anEffect) != $skill[none] && !uneffectIfNeeded(to_skill(anEffect)))
		abort("consumeIfNeededWithUneffect");
	return consumeIfNeeded(itemToConsume, anEffect, minimumNumberOfTurns);
}



// executes the given string in the cli until anEffect has minimumNumberOfTurns
boolean cli_execute_if_needed(string executeString, effect anEffect, int minimumNumberOfTurns) {
	if (to_skill(anEffect) != $skill[none] && !uneffectIfNeeded(to_skill(anEffect)))
		abort("cli_execute_if_needed");

	boolean executed = true;
	int turnsOfEffect = have_effect(anEffect);
	while (turnsOfEffect < minimumNumberOfTurns && executed) {
		executed = cli_execute(executeString);
		int newTurnsOfEffect = have_effect(anEffect);
		if (turnsOfEffect == newTurnsOfEffect)
			return false;
		else
			turnsOfEffect = newTurnsOfEffect;
	}
	return executed;
}

boolean cli_execute_if_needed(string executeString, effect anEffect) {
	return cli_execute_if_needed(executeString, anEffect, 1);
}



// ensures the given buff's effect has minimumNumberOfTurns
// will uneffect anything that interfere's with casting buff
boolean buffIfNeededWithUneffect(skill buff, int minimumNumberOfTurns) {
	return songBuffIfNeededWithUneffect(buff, minimumNumberOfTurns);
}

boolean buffIfNeededWithUneffect(skill buff) {
	return songBuffIfNeededWithUneffect(buff, 1);
}



// gets anEffect from either using anItem or from casting aSkill
// will always use aSkill if it is non-none
boolean getEffectIfNeededWithUneffect(effect anEffect, item anItem, skill aSkill, int minimumNumberOfTurns) {
	if (aSkill != $skill[none])
		return buffIfNeededWithUneffect(aSkill, minimumNumberOfTurns); // anEffect is only needed if we're using an item
	else
		return consumeIfNeededWithUneffect(anItem, anEffect, minimumNumberOfTurns);
}



// TODO make this use the same PrioritySkillRecord as everything else
// might return a blank record if there are no free runaways to be had
ActionRecord chooseFreeRunaway(int maxPerRunawayCost) {
	ActionRecord theAction;

	if (my_class() == $class[Accordion Thief] && have_item($item[fish-oil smoke bomb]))
		theAction.itemToUse = $item[fish-oil smoke bomb];
	else if (have_item($item[peppermint parasol])
		&& maxPerRunawayCost >= (historical_price($item[peppermint parasol]) / 10)
		&& to_int(get_property("parasolUsed")) < 3) // after 3, less than 100% chance
		theAction.itemToUse = $item[peppermint parasol];

	return theAction;
}

boolean canFreeRunaway(int maxPerRunawayCost) {
	ActionRecord theAction = chooseFreeRunaway(maxPerRunawayCost);
	return theAction.skillToUse != $skill[none] || theAction.itemToUse != $item[none];
}



void buffColdRes(AnalyzeRecord [item] itemsToAnalyze, int buffTurnsNeeded, int maxMeatcostPerBuffTurn) {
	item [int] sortArray;
	int ctr = 0;
	foreach it in itemsToAnalyze {
		sortArray[ctr] = it;
		ctr += 1;
	}
	sort sortArray by costPerBuffTurn(value, itemsToAnalyze[value].buffAmount, itemsToAnalyze[value].duration, itemsToAnalyze[value].opportunityCost);

	// CHOOSE BUFFS TO USE
	int totalBuffs;
	int totalCostPerTurn;
	string htmlOutput = "<table><th>Item</th><th>current turns</th><th>buff amount</th><th>duration</th><th>effect</th><th>cost per buff turn</th><th></tr>\n";
	for idx from 0 to count(sortArray) - 1 {
		item anItem = sortArray[idx];
		int costPerBuffTurn = costPerBuffTurn(anItem, itemsToAnalyze[anItem].buffAmount, itemsToAnalyze[anItem].duration, itemsToAnalyze[anItem].opportunityCost);
		string textColour = "blue";
		if (costPerBuffTurn <= maxMeatcostPerBuffTurn) {
			textColour = "green";
			totalBuffs += itemsToAnalyze[anItem].buffAmount;
			totalCostPerTurn += costPerBuffTurn * itemsToAnalyze[anItem].buffAmount;
		}

// 		print(anItem + " (current turns: " + have_effect(itemsToAnalyze[anItem].theEffect) + ", buffs for: " + itemsToAnalyze[anItem].buffAmount + (itemsToAnalyze[anItem].buffIsPercentBased ? "%" : "")
// 			+ ", " + itemsToAnalyze[anItem].duration + " turns, effect: " + itemsToAnalyze[anItem].theEffect + ") @ "
// 			+ costPerBuffTurn + " / buff" + (itemsToAnalyze[anItem].buffIsPercentBased ? " percentage" : "")
// 			+ " / duration", textColour);
		htmlOutput += "<tr><td>" + anItem + "</td><td>" + have_effect(itemsToAnalyze[anItem].theEffect)
			+ "</td><td>" + itemsToAnalyze[anItem].buffAmount + (itemsToAnalyze[anItem].buffIsPercentBased ? "%" : "")
			+ "</td><td>" + itemsToAnalyze[anItem].duration + "</td><td>" + itemsToAnalyze[anItem].theEffect
			+ "</td><td>" + costPerBuffTurn + "</td></tr>\n";
	}

	htmlOutput += "</table>\n";
	print_html(htmlOutput);

	if (totalBuffs == 0)
		abort("no buffs were chosen, try raising maxMeatcostPerBuffTurn");
	print("current Cold Resistance: " + numeric_modifier("Cold Resistance"), "blue");
	print("total cost: " + totalCostPerTurn + "/turn, total buff: " + totalBuffs + ", total cost/buff/turn: " + (totalCostPerTurn / totalBuffs), "blue");

	// BUFF UP
	if (!user_confirm("Proceed under the following circumstances?\nTotal buff cost: " + totalCostPerTurn + ", total buff: "
		+ totalBuffs + "%, total cost per buff percent: " + (totalCostPerTurn / totalBuffs)
		+ " meat\nTurn cost: " + (kTurnValue * 30) + " -- total cost per buff: "
		+ totalCostPerTurn + "\n", 60000, false))
		abort();

	// ACQUIRE AND CONSUME ITEMS
	foreach idx, anItem in sortArray {
		int costPerBuffPercent = costPerBuffTurn(anItem, itemsToAnalyze[anItem].buffAmount, itemsToAnalyze[anItem].duration, itemsToAnalyze[anItem].opportunityCost);
		if (costPerBuffPercent <= maxMeatcostPerBuffTurn) {
			if (!fullAcquire(ceil(buffTurnsNeeded.to_float() / itemsToAnalyze[anItem].duration), anItem)) {
				abort("could not acquire consumable: " + anItem);
			}
			consumeIfNeededWithUneffect(anItem, itemsToAnalyze[anItem].theEffect, buffTurnsNeeded);
		}
	}
}



string coldResBuffMakeClickableCommand(string command, string title) {
	return "<strong style=\"color:blue;\"><a href=\"KoLmafia/sideCommand?cmd=" + command.url_encode() + "&pwd=" + my_hash() + "\">" + title + "</a></strong>";
}

void coldResBuff(AnalyzeRecord [item] coldResItemsToAnalyze, int buffTurnsNeeded) {
	// SPECIAL CASES
	// Frosty Hand -- cargo pocket
	// KGB
	// pillkeeper

	item [int] sortArray;
	item [effect] effectMap;
	int ctr = 0;
	foreach it in coldResItemsToAnalyze {
		sortArray[ctr] = it;
		effectMap[coldResItemsToAnalyze[it].theEffect] = it;
		ctr += 1;
	}
	sort sortArray by costPerBuffTurn(value, coldResItemsToAnalyze[value].buffAmount, coldResItemsToAnalyze[value].duration, coldResItemsToAnalyze[value].opportunityCost);

	// CHOOSE BUFFS TO USE
	int buffCurrentlyOn;
	int newBuffs;
	int totalCost;
	int currentColdRes = numeric_modifier("Cold Resistance");
	string htmlOutput = "<html><head><style>table, td {border:none; border-collapse:collapse; padding:0px;}; th {border:1px}</style></head><body>"
		+ "<table><tr><th>Amount</th><th>Item (click to use 1)</th><th>Price</th><th>current turns</th><th>buff amount</th><th>duration</th><th>effect</th><th>cost per buff turn</th><th># needed</th><th>one less</th></tr>\n";

	// first, get the current state and calculate the items we need to maintain it for buffTurnsNeeded
	int [item] itemsNeeded; // item to number of turns needed
	for idx from 0 to count(sortArray) - 1 {
		item theItem = sortArray[idx];
		int costPerBuffTurn = costPerBuffTurn(theItem, coldResItemsToAnalyze[theItem].buffAmount, coldResItemsToAnalyze[theItem].duration, coldResItemsToAnalyze[theItem].opportunityCost);
		effect theEffect = coldResItemsToAnalyze[theItem].theEffect;
		string textColour = "#ADD8E6";
		if (have_effect(theEffect) > 0) {
			itemsNeeded[theItem] = buffTurnsNeeded - have_effect(theEffect);
			buffCurrentlyOn += coldResItemsToAnalyze[theItem].buffAmount;
			textColour = "#90ee90";
		} else {
			itemsNeeded[theItem] = buffTurnsNeeded;
			newBuffs += coldResItemsToAnalyze[theItem].buffAmount;
		}
		int numberNeeded = max(ceil(itemsNeeded[theItem].to_float() / coldResItemsToAnalyze[theItem].duration), 0);
		totalCost += numberNeeded * mall_price(theItem);

// 		print(theItem + " (current turns: " + have_effect(coldResItemsToAnalyze[theItem].theEffect)
// 			+ ", buffs for: " + coldResItemsToAnalyze[theItem].buffAmount + (coldResItemsToAnalyze[theItem].buffIsPercentBased ? "%" : "")
// 			+ ", " + coldResItemsToAnalyze[theItem].duration + " turns, effect: " + coldResItemsToAnalyze[theItem].theEffect + ") @ "
// 			+ costPerBuffTurn + " / buff" + (coldResItemsToAnalyze[theItem].buffIsPercentBased ? " percentage" : "")
// 			+ " / duration. Planning to consume " + numberNeeded, textColour);
		string activate1String = cliStringToConsume(1, theItem);
		if (coldResItemsToAnalyze[theItem].activationString != "")
			activate1String = to_string(1, coldResItemsToAnalyze[theItem].activationString);
		string activateAllString = coldResItemsToAnalyze[theItem].activationString == "" ? cliStringToConsume(numberNeeded, theItem) : to_string(numberNeeded, coldResItemsToAnalyze[theItem].activationString);
		string activateAllLessOneString = coldResItemsToAnalyze[theItem].activationString == "" ? cliStringToConsume(numberNeeded - 1, theItem) : to_string(numberNeeded - 1, coldResItemsToAnalyze[theItem].activationString);
		htmlOutput += "<tr style='background-color: " + textColour + "'><td>"
			+ available_amount(theItem) + "</td><td>"
			+ coldResBuffMakeClickableCommand(activate1String, coldResItemsToAnalyze[theItem].activationString == "" ? theItem.to_string() : activate1String) + "</td><td>"
			+ mall_price(theItem) + "</td><td>"
			+ have_effect(coldResItemsToAnalyze[theItem].theEffect)+ "</td><td>" 
			+ coldResItemsToAnalyze[theItem].buffAmount + (coldResItemsToAnalyze[theItem].buffIsPercentBased ? "%" : "") + "</td><td>" 
			+ coldResItemsToAnalyze[theItem].duration + "</td><td>" + coldResItemsToAnalyze[theItem].theEffect+ "</td><td>" 
			+ costPerBuffTurn + "</td><td>"
			+ coldResBuffMakeClickableCommand(activateAllString, numberNeeded.to_string()) + "</td><td>"
			+ (numberNeeded > 0 ? coldResBuffMakeClickableCommand(activateAllLessOneString, to_string(numberNeeded - 1)) : "") + "</td></tr>\n";
	}

	htmlOutput += "</table></body></html>\n";
	print_html(htmlOutput);
	print_html("<html></html>"); // clears screen thrash from my seemingly well-formed HTML

	int baseColdRes = currentColdRes - buffCurrentlyOn; // the cold res minus the buffs we're managing

	// BUFF UP
// 	if (!user_confirm("Proceed under the following circumstances?\nTotal buff cost: " + totalCost + ", total buff: "
// 		+ (buffCurrentlyOn + newBuffs) + ", total cost per buff: " + (totalCost / (buffCurrentlyOn + newBuffs))
// 		+ " meat\nTOTAL COST: " + totalCost, 60000, false))
// 		abort("user aborted");
// 
// 	// ACQUIRE AND CONSUME ITEMS
// 	foreach theItem, amount in itemsNeeded {
// 		int numberNeeded = ceil(amount.to_float() / coldResItemsToAnalyze[theItem].duration);
// 		if (!fullAcquire(numberNeeded, theItem)) {
// 			abort("could not acquire consumable: " + theItem);
// 		}
// 		consumeIfNeededWithUneffect(theItem, coldResItemsToAnalyze[theItem].theEffect, amount);
// 	}
}


void autoColdResBuff(AnalyzeRecord [item] coldResItemsToAnalyze) {
	int longestEffect;
	int totalTurnsForAverage, effectsForAverage;
	foreach theItem, ar in coldResItemsToAnalyze {
		int effectDuration = have_effect(ar.theEffect);
		if (effectDuration > 0) {
			totalTurnsForAverage += effectDuration;
			effectsForAverage++;
		}
		if (effectDuration > longestEffect)
			longestEffect = effectDuration;
	}
	if (effectsForAverage == 0)
		abort("no existing cold res buffs, use coldResBuff(int buffTurnsNeeded)");
	int averageEffect = totalTurnsForAverage / effectsForAverage;
	coldResBuff(coldResItemsToAnalyze, averageEffect);
}



// -------------------------------------
// END GAME UTILITIES
// -------------------------------------

// return an array of locations and turns spent for all end game locations
// only hits the server once
int [location] endGameTurnsSpent() {
	int [location] rval;
	string aPage = visit_url("clan_raidlogs.php");

	// dreadsylvania
	matcher m = create_matcher("Your clan has defeated <b>([\\d,]*)</b> monster\\\(s\\\) in the ([\\w]+)", aPage);
	while (m.find()) {
		int killCount = m.group(1).to_int();
		string locString = m.group(2);
		location killLoc = to_location("dreadsylvanian " + (locString == "Forest" ? "Woods" : locString));
		rval[killLoc] = killCount;
	}

	// hobopolis TODO can probably do everything in xpath...
	string [int] hobopolisNames = xpath(aPage, "//div[@id='Hobopolis']//p/b/text()");
	string [int] hobopolisCompletion = xpath(aPage, '//div[@id="Hobopolis"]//blockquote');
	foreach idx, aString in hobopolisCompletion {
		int turnsTaken = 0;
		matcher hoboMatcher = create_matcher("\\(([0-9]+) turns?\\)", aString);
		while (find(hoboMatcher)) {
			turnsTaken += hoboMatcher.group(1).to_int();
		}
		location theLocation = kEndGameNameToLocationMap[substring(hobopolisNames[idx], 0, length(hobopolisNames[idx]) - 1)];
		if (theLocation != $location[none])
			rval[theLocation] = turnsTaken;
	}

	// slimetube
	string [int] slimetubeCompletion = xpath(aPage, '//div[@id="SlimeTube"]//center//center/b/text()');
	if (count(slimetubeCompletion) < 1) {
		rval[$location[The Slime Tube]] = 0;
	} else
		rval[$location[The Slime Tube]] = slimetubeCompletion[0].to_int();

	return rval;
}


int [location] dreadsylvaniaTurnsSpent(int [location] turnsSpent) {
	int [location] dreadLocs;
	foreach idx, dreadLoc in kDreadLocs {
		dreadLocs[dreadLoc] = turnsSpent[dreadLoc];
	}
	return dreadLocs;
}

int dreadsylvaniaTotalTurnsSpent(int [location] turnsSpent) {
	int dreadTurns;
	foreach idx, dreadLoc in kDreadLocs {
		dreadTurns += turnsSpent[dreadLoc];
	}
	return dreadTurns;
}

int [location] hobopolisTurnsSpent(int [location] turnsSpent) {
	int [location] hoboLos;
	foreach idx, hoboLo in kHoboLos {
		hoboLos[hoboLo] = turnsSpent[hoboLo];
	}
	return hoboLos;
}

int hobopolisTotalTurnsSpent(int [location] turnsSpent) {
	int hoboTurns;
	foreach idx, hoboLo in kHoboLos {
		hoboTurns += turnsSpent[hoboLo];
	}
	return hoboTurns;
}



void printTurnsSpent(int [location] turnsSpent) {
	int total;
	foreach aLocation, spent in turnsSpent {
		print(aLocation + ": " + spent, "green");
		total += spent;
	}
	print("TOTAL turns spent: " + total, "green");
}


void printDreadsylvaniaTurnsSpent(int [location] turnsSpent) {
	printTurnsSpent(dreadsylvaniaTurnsSpent(turnsSpent));
}

void printDreadsylvaniaTurnsSpent() {
	printDreadsylvaniaTurnsSpent(endGameTurnsSpent());
}


void printHobopolisTurnsSpent(int [location] turnsSpent) {
	printTurnsSpent(hobopolisTurnsSpent(turnsSpent));
}

void printHobopolisTurnsSpent() {
	printHobopolisTurnsSpent(endGameTurnsSpent());
}


void printSlimetubeTurnsSpent(int [location] turnsSpent) {
	int [location] printTurnsSpent = {$location[The Slime Tube]: turnsSpent[$location[The Slime Tube]]};
	printTurnsSpent(printTurnsSpent);
}

void printSlimetubeTurnsSpent() {
	printSlimetubeTurnsSpent(endGameTurnsSpent());
}


void printEndGameTurnsSpent() {
	int [location] printTurnsSpent = endGameTurnsSpent();
	print("Dreadsylvania:");
	printDreadsylvaniaTurnsSpent(printTurnsSpent);
	print("\nHobopolis:");
	printHobopolisTurnsSpent(printTurnsSpent);
	print("\nSlime Tube:");
	printSlimetubeTurnsSpent(printTurnsSpent);
}


float dreadsylvaniaCompletion(int [location] turnsSpent) {
	return dreadsylvaniaTotalTurnsSpent(turnsSpent).to_float() / kDreadsylvaniaCompleteTurns.to_float();
}

float dreadsylvaniaCompletion() {
	return dreadsylvaniaCompletion(endGameTurnsSpent());
}


float hobopolisCompletion(int [location] turnsSpent) {
	return hobopolisTotalTurnsSpent(turnsSpent).to_float() / kHobopolisCompleteTurns.to_float();
}

float hobopolisCompletion() {
	return hobopolisCompletion(endGameTurnsSpent());
}



// -------------------------------------
// IOTM ITEMS OF THE MONTH
// -------------------------------------

// TODO should probably be in unrestricted.ash? needed by automation.ash
void doseRobortender() {
	if (!get_property("_roboDrinks").contains_text("Newark")) {
		fullAcquire(1, $item[newark]);
		boolean unused = cli_execute("robo newark");
	}
}


item [phylum] kRobortenderWeakBooze() {
	item [phylum] rval;

	foreach phy, strongBooze in kRobortenderStrongBooze {
		foreach ingred, amt in get_ingredients(strongBooze) {
			if (ingred.to_int() > 9300)
				rval[phy] = ingred;
		}
	}

	return rval;
}

item [phylum] kRobortenderDrops() {
	item [phylum] rval;

	foreach phy, weakBooze in kRobortenderWeakBooze() {
		foreach ingred, amt in get_ingredients(weakBooze) {
			if (ingred.to_int() > 9300)
				rval[phy] = ingred;
		}
	}

	return rval;
}

// returns the number of robo items dropped so far today
int roboDrops(boolean doPrint) {
	int rval;
	int [item] receipt;
	foreach roboPhylum, roboDrop in kRobortenderDrops() {
		int drops = my_session_items(roboDrop);
		if (drops > 0) {
			receipt[roboDrop] = drops;
			rval += drops;
		}
	}
	if (doPrint)
		printReceipt(receipt);
	return rval;
}

int roboDrops() {
	return roboDrops(true);
}


void printRoboArray(item [phylum] anArray) {
	int i;
	foreach phy, roboItem in anArray {
		print(i++ + ": " + roboItem + " drops from " + phy);
	}
}

void printRoboArray() {
	printRoboArray(kRobortenderDrops());
}


// chance for the next drop
float roboDropChance() {
	int drops = roboDrops(false);
	switch (drops) {
		case 0: return 1.0;

		case 1: case 2: case 3: return 0.5;

		case 4: case 5: case 6: return 0.4;

		case 7: case 8: case 9: return 0.3;

		default: return 0.2;
	}
}


// chance for the next drop at a given location
// including the chance of a NC
float roboDropChanceForLocation(location roboLo, boolean doPrint) {
	float baseDropChance = roboDropChance();
	float rval;

	if (doPrint)
		print("roboDropChanceForLocation @ " + roboLo + ", with base robo drop chance: " + (baseDropChance * 100) + "%");

	foreach mon, rate in appearance_rates(roboLo) {
		phylum monPhy = monster_phylum(mon);
		float realRate = rate / 100;
		if (kRobortenderDrops() contains monPhy) {
			rval += (realRate * baseDropChance);
		}

		if (doPrint)
			print(mon + " (" + monPhy + ") appears " + rate + "%", "green");
	}

	if (doPrint)
		print("Chance of a robo drop: " + (rval * 100) + "% / turn", "green");

	return rval;
}

float roboDropChanceForLocation(location roboLo) {
	return roboDropChanceForLocation(roboLo, true);
}



int roboEconomicsForMonster(monster roboMo, boolean doPrint) {
	int bestValue = 100;
	float baseDropChance = roboDropChance();
	item [phylum] drops = kRobortenderDrops();
	item [phylum] weak = kRobortenderWeakBooze();
	item [phylum] strong = kRobortenderStrongBooze;

	phylum monPhy = monster_phylum(roboMo);
	if (drops contains monPhy) {
		item bestValueItem = drops[monPhy];
		int bestValuePrice = historical_price(bestValueItem);

		if (historical_price(weak[monPhy]) > bestValuePrice) {
			bestValueItem = weak[monPhy];
			bestValuePrice = historical_price(bestValueItem);
		}
		if (historical_price(strong[monPhy]) > bestValuePrice) {
			bestValueItem = strong[monPhy];
			bestValuePrice = historical_price(bestValueItem);
		}

		bestValue = bestValuePrice * baseDropChance;

		if (doPrint)
			print(roboMo
				+ " drops " + drops[monPhy] + "@" + historical_price(drops[monPhy])
				+ ", weak: " + weak[monPhy] + "@" + historical_price(weak[monPhy])
				+ ", strong: " + strong[monPhy] + "@" + historical_price(strong[monPhy])
				+ " -- best value * robo drop chance: " + bestValue + " meat value per kill"
				, "green");
	}

	return bestValue;
}

int roboEconomicsForMonster(monster roboMo) {
	return roboEconomicsForMonster(roboMo, true);
}



int roboEconomicsForLocation(location roboLo, boolean doPrint) {
	float baseDropChance = roboDropChance();
	item [phylum] drops = kRobortenderDrops();
	item [phylum] weak = kRobortenderWeakBooze();
	item [phylum] strong = kRobortenderStrongBooze;
	int totalValue;

	if (doPrint)
		print("roboEconomicsForLocation @ " + roboLo + ", with base robo drop chance: " + (baseDropChance * 100) + "%", "green");

	foreach mon, rate in appearance_rates(roboLo) {
		if (mon != $monster[none]) {
			float realRate = max(rate, 0) / 100;
			int roboMoValue = roboEconomicsForMonster(mon, doPrint);
			print("-> rate: " + realRate);
			totalValue += roboMoValue * realRate;
		}
	}

	return totalValue;
}

int roboEconomicsForLocation(location roboLo) {
	return roboEconomicsForLocation(roboLo, true);
}


void roboEconomics() {
	item [phylum] drops = kRobortenderDrops();
	item [phylum] weak = kRobortenderWeakBooze();
	item [phylum] strong = kRobortenderStrongBooze;
	string printString = "<table><tr><th>strong</th><th>weak</th><th>drop</th><th>phylum</th></tr>";

	foreach phy in kRobortenderStrongBooze {
		printString += "<tr><td>"
			+ strong[phy] + "@" + historical_price(strong[phy]) + "</td><td>"
			+ weak[phy] + "@" + historical_price(weak[phy]) + "</td><td>"
			+ drops[phy] + "@" + historical_price(drops[phy]) + "</td><td>"
			+ phy
			+ "</td></tr>";
	}

	printString += "</table>";

	print_html(printString);
}



// uses the briefcase to get anEffect until anEffect has minimumNumberOfTurns
boolean briefcase_if_needed(effect anEffect, int minimumNumberOfTurns) {
	string [effect] BriefcaseEffectsMap = {
		$effect[A View to Some Meat]:"meat",
		$effect[Items Are Forever]:"item",
		$effect[Initiative and Let Die]:"init"
	};

	int clicksUsed = to_int(get_property("_kgbClicksUsed"));
	boolean executed = false;
	while (have_effect(anEffect) < minimumNumberOfTurns && clicksUsed < 22) {
		executed = cli_execute("briefcase buff " + BriefcaseEffectsMap[anEffect]);
		clicksUsed = to_int(get_property("_kgbClicksUsed"));
		if (!executed) return false;
	}
	return true;

	return cli_execute_if_needed("briefcase buff " + BriefcaseEffectsMap[anEffect], anEffect, minimumNumberOfTurns);
}



// returns true if any Asdon Martin buff is current on
boolean drivingAsdonMartin() {
	effect [] AsdonMartinEffects = {
		$effect[Driving Obnoxiously],
		$effect[Driving Stealthily],
		$effect[Driving Wastefully],
		$effect[Driving Safely],
		$effect[Driving Recklessly],
		$effect[Driving Intimidatingly],
		$effect[Driving Quickly],
		$effect[Driving Observantly],
		$effect[Driving Waterproofly]
	};
	foreach index in AsdonMartinEffects
		if (have_effect(AsdonMartinEffects[index]) > 0)
			return true;
	return false;
}


// returns true if we have no asdon marten effect or we have the given effect
boolean drivingAsdonMartin(effect asdonEffect) {
	return have_effect(asdonEffect) > 0 || !drivingAsdonMartin();
}



// returns all possible asdon martin fuel sorted by best meat efficiency
item [] asdonFuel() {
	int expensiveValue = 100;
	item [int] inv_items = inventoryArray();

	// filter for fuel items
	item [int] fuelItems;
	int fuelIndex;
	foreach idx, it in inv_items {
		if ((item_type(it) == "food" || item_type(it) == "booze")
			&& (it.fullness > 0 || it.inebriety > 0)
			&& (count(get_ingredients(it)) > 0)
			&& is_pvpable(it))
			fuelItems[fuelIndex++] = it;
	}

	// filter for price
	item [int] filteredItems;
	int filteredIndex;
	foreach idx, it in fuelItems {
		int nutrition = nutrition(it); // number of adventures
		if (historical_price(it) / nutrition < expensiveValue)
			filteredItems[filteredIndex++] = it;
	}

	// sort by cost per adventure gained
	sort filteredItems by historical_price(value) / nutrition(value);

	return filteredItems;
}


void printAsdonMartFuel() {
	item [int] filteredItems = asdonFuel();
	foreach idx, it in filteredItems {
		int nutrition = nutrition(it); // number of adventures
		print(item_amount(it) + "x " + it + " (" + nutrition + " adv @ " + (historical_price(it) / nutrition) + " meat/adv)");
	}
}


item bestAsdonFuel() {
	return asdonFuel()[0];
}


// uses generic food to fuel the asdon martin
void fuelAsdonMartin(int moreFuel) {
	assert(isAsdonWorkshed(), "fuelAsdonMartin: no Asdon Martin in your workshed!");

	int goalFuel = get_fuel() + moreFuel;
	int neededFuel = moreFuel;
	item bestFuel = bestAsdonFuel();
	int amtFuelToAcquire = ceil(neededFuel.to_float() / nutrition(bestFuel).to_float());

	print("fuelAsdonMartin: have " + get_fuel() + " need " + goalFuel + ". Starting with " + amtFuelToAcquire + " x " + bestFuel, "green");

	while (neededFuel > 0) {
// 		fullAcquire(bestFuel, amtFuelToAcquire);
		int amtFuelBought = bestFuel.buy(amtFuelToAcquire, bestFuel.historical_price());
		int amtFuelToUse = min(amtFuelBought, available_amount(bestFuel));
		assert(amtFuelToUse > 0, "we bought the cheapest fuel but didn't get any");
		cli_execute("asdonmartin fuel " + amtFuelToUse + " " + bestFuel);

		neededFuel = goalFuel - get_fuel();
		bestFuel = bestAsdonFuel();
		amtFuelToAcquire = ceil(neededFuel / nutrition(bestFuel));
	}
}


// ensure the Asdon Martin is fueled up to fuelLevel
void ensureAsdonMartinFuel(int fuelLevel) {
	assert(isAsdonWorkshed(), "ensureAsdonMartinFuel: no Asdon Martin in your workshed!");

	int moreFuel = fuelLevel - get_fuel();
	if (moreFuel > 0)
		fuelAsdonMartin(moreFuel);
}


// use the asdonmartin, fueling enough for the buff if we're not in ronin
boolean fueled_asdonmartin(string style, int minimumNumberOfTurns) {
	assert(isAsdonWorkshed(), "fueled_asdonmartin: no Asdon Martin in your workshed!");

	// inv elven hardtack; inv elven squeeze; inv unidentified jerky; inv white lightning; inv handful of nuts and berries;
	// fill up enough to handle the uses we're about to do
	int effect_turns = have_effect(to_effect("Driving " + style));
	int neededTurns = minimumNumberOfTurns - effect_turns;
	if (neededTurns > 0) {
		int toDrive = ceil(neededTurns / 30.0) + 1;
		ensureAsdonMartinFuel(toDrive * 37);
		print("buffing " + toDrive + " times, total fuel required: " + (toDrive * 37) + " to get: " + minimumNumberOfTurns + " turns of style: " + style + " effect turns: " + effect_turns + " needed turns: " + neededTurns);
	}

	return cli_execute_if_needed("asdonmartin drive " + style, to_effect("Driving " + style), minimumNumberOfTurns);
}


// does a fueledAsdonMartin() only if we aren't already driving some other buff
void safeFueledAsdonMartin(effect desiredEffect, int minTurns) {
	assert(isAsdonWorkshed(), "safeFueledAsdonMartin: no Asdon Martin in your workshed!");

	foreach idx, aDriveEffect in kDrivingStyles {
		if (aDriveEffect != desiredEffect && have_effect(aDriveEffect) > 0)
			return;
	}

	// fill up enough to handle the uses we're about to do
	int effect_turns = have_effect(desiredEffect);
	int neededTurns = minTurns - effect_turns;
	if (neededTurns > 0) {
		int toDrive = ceil(neededTurns / 30.0) + 1;
		ensureAsdonMartinFuel(toDrive * 37);
		print("buffing " + toDrive + " times, total fuel required: " + (toDrive * 37) + " to get: " + minTurns + " turns of style: " + desiredEffect + " effect turns: " + effect_turns + " needed turns: " + neededTurns);
	}

	cli_execute_if_needed("asdonmartin drive " + substring(desiredEffect, 8), desiredEffect, minTurns);
}



// return the current debuff that the micrometerorite skill does
float micrometerorite_percent() {
	return max(0.10, 0.25 - (get_property("_micrometeoriteUses").to_float() / 100.0));
}



boolean onGuzzlrQuest() {
	if (get_property("questGuzzlr") == "unstarted")
		return false;
	return true;
}


void printGuzzlrQuest() {
	if (get_property("questGuzzlr") == "unstarted") {
		print("No Guzzlr quest started!", "red");
		return;
	}

	print(get_property("guzzlrQuestTier") + " tier quest: go to " + get_property("guzzlrQuestLocation") + " and give a " + get_property("guzzlrQuestBooze"), "green");
	print("abandoned a quest: " + get_property("_guzzlrQuestAbandoned") + ", today's deliveries plat: " + get_property("_guzzlrPlatinumDeliveries") + ", gold: " + get_property("_guzzlrGoldDeliveries") + ", total deliveries today: " + get_property("_guzzlrDeliveries"), "green");
}


// choiceOption = 2 for bronze, 3 for gold, 4 for platinum
// returns true if we're on the selected tier of quest, whether we had to get a new quest or we're on it already
boolean getGuzzlrQuest(int choiceOption) {
	if (onGuzzlrQuest()) {
		print(get_property("guzzlrQuestTier") + " Guzzlr quest already started!", "red");
		printGuzzlrQuest();
		return choiceOption == 4 ? get_property("guzzlrQuestTier") == "platinum" : choiceOption == 3 ? get_property("guzzlrQuestTier") == "gold" : get_property("guzzlrQuestTier") == "bronze";
	}
	if (choiceOption == 3) { // gold
		if (to_int(get_property("_guzzlrGoldDeliveries")) >= 3) {
			print("Already done 3 gold Guzzlr quests!", "red");
			printGuzzlrQuest();
			return false;
		}
	} else if (choiceOption == 4) { // platinum
		if (to_int(get_property("_guzzlrPlatinumDeliveries")) >= 1) {
			print("Already done a platinum Guzzlr quest!", "red");
			printGuzzlrQuest();
			return false;
		}
	} else if (choiceOption != 2) { // bronze
		abort("incorrect choiceOption passed to getGuzzlrQuest");
	}

	visit_url("/inventory.php?tap=guzzlr", false, false);
	string pageString = run_choice(choiceOption);
	boolean success = pageString.contains_text("You select a ");
	if (success) {
		printGuzzlrQuest();
		set_property("_smmGuzzlrLocationLockedWarningDone", "false");
	}
	return success;
}



// gets the next Guzzlr quest in descending order from platinum
// returns the quest tier (plat = 1, gold = 2, bronze = 3)
int getGuzzlrQuest() {
	int questTier = 3;
	int choiceOption = 2;

	if (onGuzzlrQuest()) {
		string questTier = get_property("guzzlrQuestTier");
		printGuzzlrQuest();
		return questTier == "platinum" ? 1 : questTier == "gold" ? 2 : 3;
	}

	if (get_property("_guzzlrPlatinumDeliveries").to_int() == 0) {
		questTier = 1;
		choiceOption = 4;
	} else if (get_property("_guzzlrGoldDeliveries").to_int() < 3) {
		questTier = 2;
		choiceOption = 3;
	}

	if (!getGuzzlrQuest(choiceOption))
		abort("failed getting a tier " + questTier + " guzzlr quest");
	return questTier;
}


void getAndCancelPlatinumGuzzlrQuest() {
	buffer pageText;
	string tweakOutfit = "";

	if ((get_property("questGuzzlr") == "unstarted") && (to_int(get_property("_guzzlrPlatinumDeliveries")) == 0))
		getGuzzlrQuest(4); // platinum

	if (get_property("guzzlrQuestTier") != "platinum") {
		print("getAndCancelPlatinumGuzzlrQuest: platinum quest already cancelled or a quest of a different tier is already started", "red");
		return;
	}

	// cancel the platinum quest and continue
	visit_url("/inventory.php?tap=guzzlr", false, false);
	run_choice(1);
	run_choice(5);
}



void summon_pants(string element_string, string sacrifice1, string sacrifice2, string sacrifice3) {
	if (have_item($item[pantogram pants])) {
		print("you already have your pants!");
		print_description($item[pantogram pants]);
		return;
	}

	string [stat] alignment_map = {
		$stat[muscle]:"1",
		$stat[mysticality]:"2",
		$stat[moxie]:"3"
	};
	string [string] element_map = {
		"hot":"1",
		"cold":"2",
		"spooky":"3",
		"sleaze":"4",
		"stench":"5"
	};
	string [string] sacrifice1_map = {
		"hp":"-1,0",
		"mp":"-2,0",
		"hp regen 1":to_int($item[red pixel potion]) + ",1",
		"hp regen 2":to_int($item[royal jelly]) + ",1",
		"hp regen 3":to_int($item[scented massage oil]) + ",1",
		"mp regen 1":to_int($item[cherry cloaca cola]) + ",1",
		"mp regen 2":to_int($item[bubblin' crude]) + ",1",
		"mp regen 3":to_int($item[glowing new age crystal]) + ",1",
		"-mp cost":to_int($item[baconstone]) + ",1",
		"red pixel potion":to_int($item[red pixel potion]) + ",1",
		"royal jelly":to_int($item[royal jelly]) + ",1",
		"scented massage oil":to_int($item[scented massage oil]) + ",1",
		"cherry cloaca cola":to_int($item[cherry cloaca cola]) + ",1",
		"bubblin' crude":to_int($item[bubblin' crude]) + ",1",
		"glowing new age crystal":to_int($item[glowing new age crystal]) + ",1",
		"baconstone":to_int($item[baconstone]) + ",1"
	};
	string [string] sacrifice2_map = {
		"weapon dmg":"-1,0",
		"spell dmg":"-2,0",
		"meat drop 1":to_int($item[taco shell]) + ",1",
		"meat drop 2":to_int($item[porquoise]) + ",1",
		"item drop 1":to_int($item[fairy gravy boat]) + ",1",
		"item drop 2":to_int($item[tiny dancer]) + ",1",
		"mus exp 1":to_int($item[knob goblin firecracker]) + ",3",
		"mys exp 1":to_int($item[razor-sharp can lid]) + ",3",
		"mox exp 1":to_int($item[spider web]) + ",3",
		"mus exp 2":to_int($item[synthetic marrow]) + ",5",
		"mys exp 2":to_int($item[haunted battery]) + ",5",
		"mox exp 2":to_int($item[the funk]) + ",5",
		"taco shell":to_int($item[taco shell]) + ",1",
		"porquoise":to_int($item[porquoise]) + ",1",
		"fairy gravy boat":to_int($item[fairy gravy boat]) + ",1",
		"tiny dancer":to_int($item[tiny dancer]) + ",1",
		"knob goblin firecracker":to_int($item[knob goblin firecracker]) + ",3",
		"razor-sharp can lid":to_int($item[razor-sharp can lid]) + ",3",
		"spider web":to_int($item[spider web]) + ",3",
		"synthetic marrow":to_int($item[synthetic marrow]) + ",5",
		"haunted battery":to_int($item[haunted battery]) + ",5",
		"the funk":to_int($item[the funk]) + ",5"
	};
	string [string] sacrifice3_map = {
		"-combat":"-1,0",
		"+combat":"-2,0",
		"init":to_int($item[bar skin]) + ",1",
		"crit":to_int($item[hamethyst]) + ",1",
		"fam":to_int($item[lead necklace]) + ",1",
		"candy":to_int($item[huge bowl of candy]) + ",1",
		"sea":to_int($item[sea salt crystal]) + ",1",
		"fishing":to_int($item[wriggling worm]) + ",1",
		"pool":to_int($item[8-ball]) + ",1",
		"avatar":to_int($item[moxie weed]) + ",1",
		"hilarity":to_int($item[ten-leaf clover]) + ",1",
		"bar skin":to_int($item[bar skin]) + ",1",
		"hamethyst":to_int($item[hamethyst]) + ",1",
		"lead necklace":to_int($item[lead necklace]) + ",1",
		"huge bowl of candy":to_int($item[huge bowl of candy]) + ",1",
		"sea salt crystal":to_int($item[sea salt crystal]) + ",1",
		"wriggling worm":to_int($item[wriggling worm]) + ",1",
		"8-ball":to_int($item[8-ball]) + ",1",
		"moxie weed":to_int($item[moxie weed]) + ",1",
		"ten-leaf clover":to_int($item[ten-leaf clover]) + ",1"
	};

	if (!(element_map contains element_string)) abort ("element_string value '" + element_string + "' unknown");
	if (!(sacrifice1_map contains sacrifice1)) abort ("sacrifice1 value '" + sacrifice1 + "' unknown");
	if (!(sacrifice2_map contains sacrifice2)) abort ("sacrifice2 value '" + sacrifice2 + "' unknown");
	if (!(sacrifice3_map contains sacrifice3)) abort ("sacrifice3 value '" + sacrifice3 + "' unknown");

	// visit the item link to prime the pump
	visit_url("/inv_use.php?which=3&pwd&whichitem=9573", true, false);

	string url_to_visit = "choice.php?whichchoice=1270&pwd&option=1&m=" + alignment_map[my_primestat()] +
																  "&e=" + element_map[element_string] +
																  "&s1=" + sacrifice1_map[sacrifice1] +
																  "&s2=" + sacrifice2_map[sacrifice2] +
																  "&s3=" + sacrifice3_map[sacrifice3];
	print("creating pantogram pants with: " + url_to_visit);
	visit_url(url_to_visit, true, false);

	if (!have_item($item[pantogram pants]))
		print("WARNING: pants not created, missing reagent?", "red");
	else
		print_description($item[pantogram pants]);
}



// prints the summary from the sausage-o-matic
void sausageSummary() {
	buffer grindSummary = visit_url("/inventory.php?action=grind", true, false);
	matcher desc_matcher = create_matcher("(It looks like your grinder needs .*? units\\.)", to_string(grindSummary));
	find(desc_matcher);
	print(group(desc_matcher, 1));
}


// use the Kramco sausage-o-matic to grind the given item and quantity
int sausageGrind(item grindItem, int qty) {
	buffer grind_page = visit_url("/choice.php?pwd&whichchoice=1339&option=1&qty=" + qty + "&iid=" + to_int(grindItem), true, false);
	matcher desc_matcher = create_matcher("filling counter increments by ([0-9,]+)", to_string(grind_page));
	find(desc_matcher);
	return to_int(group(desc_matcher, 1));
}


void grindForSausages() {
	assert(!inRonin(), "grindForSausages: use only in ronin -- grinds lots of things you care about");

	sausageSummary();
	int [item, string] grindMap;
	file_to_map("sausage_grind_map.txt", grindMap);
	foreach grindItem, pathName in grindMap {
		print("");
		int qty = available_amount(grindItem);
		if (qty > 0 && (pathName == "" || pathName == my_path())) {
			print("grinding " + grindItem + " x" + qty + "@" + grindMap[grindItem, pathName]);
			sausageGrind(grindItem, qty);
		}
	}
	sausageSummary();
}



// equip each familiar so that the shorter-order cook benefit happens
// presumably helps with maximize
void cycleFavouriteFamiliars() {
	use_familiar($familiar[Shorter-Order Cook]);
	if (have_item($item[blue plate]))
		equip($item[blue plate]);

	if (equipped_amount($item[blue plate]) == 0 && !user_confirm("The Shorter-Order Cook isn't equipped with a blue plate... continue anyway?", 60000, true))
		abort("cycleFavouriteFamiliars");

	foreach fam in favorite_familiars() {
		use_familiar(fam);
	}
}



void checkIfRunningOut(item anItem, int runningOutThreshold) {
	int availableAmount = available_amount(anItem);
	if (availableAmount < runningOutThreshold)
		print("warning: running out of " + anItem + ", " + availableAmount + " available", "orange");
}



string getFloundrySpots() {
	if (get_property(kFloundrySpotsKey) == "") {
		buffer page = visit_url("/clan_viplounge.php?action=floundry", true, false);
		matcher desc_matcher = create_matcher("(<b>Good fishing spots today:.*?)</td>", to_string(page));

		if (!find(desc_matcher))
			abort("unable to find fishing spots");
		string rval = group(desc_matcher, 1);
		set_property(kFloundrySpotsKey, rval);
	}

	return get_property(kFloundrySpotsKey);
}

void printFloundrySpots() {
	print_html(getFloundrySpots());
}


boolean isFloundryLocation(location testLocation) {
	string page = getFloundrySpots();
	matcher desc_matcher = create_matcher(to_string(testLocation), page);
	if (find(desc_matcher))
		return true;
	return false;
}



void getBeachCombBuff(int effectNumber) {
	visit_url("/main.php?comb=1");
	visit_url("/choice.php?whichchoice=1388&pwd&option=3&buff=" + effectNumber);
	run_choice(5);
}



int spacegateEnergy() {
	string thePage = visit_url("/place.php?whichplace=spacegate&action=sg_Terminal");
	matcher energyMatcher = create_matcher("Spacegate Energy remaining: <b><font size=\\+2>([0-9][0-9]?) </font></b>Adventures", thePage);
	if (!find(energyMatcher))
		return 20;
	int energyLeft = group(energyMatcher, 1).to_int();
	set_property("_spacegateTurnsLeft", energyLeft);
	return energyLeft;
}



int pocketProfessorLectures(int weight) {
	int rval = floor(square_root(weight - 1.0) + 1.0);
	if (familiar_equipped_equipment($familiar[Pocket Professor]) == $item[Pocket Professor memory chip])
		rval += 2;
	return rval;
}

int pocketProfessorLectures() {
	return pocketProfessorLectures(familarWeight($familiar[Pocket Professor]));
}

int pocketProfessorLecturesAvailable() {
	return max(0, pocketProfessorLectures() - to_int(get_property("_pocketProfessorLectures")));
}

// uses the results of a simulated maximize to see the potential 
int pocketProfessorLecturesPossiblyAvailable() {
	int base = familiar_weight($familiar[Pocket Professor]);
	int adj = numeric_modifier("Generated:_spec", "Familiar Weight");
	return pocketProfessorLectures(base + adj) - to_int(get_property("_pocketProfessorLectures"));
}



int combatsToNextCatBurglarHeist() {
	int nextDrop = 10;
	int catBurglarCharge = to_int(get_property("_catBurglarCharge"));

	while (catBurglarCharge >= nextDrop) {
		nextDrop *= 2;
	}

	return nextDrop;
}

int progressToNextCatBurglarHeist() {
	int nextDrop = 10;
	int previousDrop = 0;
	int catBurglarCharge = to_int(get_property("_catBurglarCharge"));
	int leftoverCharge = catBurglarCharge;

	while (catBurglarCharge >= nextDrop) {
		previousDrop = nextDrop;
		nextDrop *= 2;
		leftoverCharge -= previousDrop;
	}

	return leftoverCharge;
}



int backupCameraUses() {
	return to_int(get_property("_backUpUses"));
}

int backupCameraUsesAvailable() {
	return 11 - backupCameraUses();
}



phylum snapperGuideMeToPhylum() {
	string snapperGuideMe = get_property("redSnapperPhylum");
	if (snapperGuideMe == "merkin") snapperGuideMe = "mer-kin";
	return to_phylum(snapperGuideMe);
}


void setRedNosedSnapperGuideMe(string aPhylum) {
	//if (my_familiar() != $familiar[Red-nosed Snapper]) abort("setting snapper's guide me without the snapper equipped"); don't need to be equipped????

	if (aPhylum == "mer-kin") aPhylum = "merkin";

	if (get_property("redSnapperPhylum") != aPhylum) {
		visit_url('familiar.php?action=guideme&pwd');
		visit_url('choice.php?pwd&whichchoice=1396&option=1&cat=' + aPhylum);
	}
}



// fight the given monster, which must be one that we've already fought at least once this ascension
string timespinnerFight(monster toFight) {
// 	use(1, $item[Time-Spinner]); // this doesn't get things started correctly for some reason
	visit_url("/inv_use.php?pwd&which=99&whichitem=9104&ajax=1", true, false);

	string aPage = run_choice(1); // return to a previous fight

	// testString will be present in the page if we've fought the monster before
	string testString = "<option value=\"" + to_int(toFight) + "\">" + toFight + "</option>";
	if (!aPage.contains_text(testString)) {
		run_choice(2); // maybe later
		abort("can't travel back to a monster we haven't already fought at least once this ascension!");
	}

	return visit_url("/choice.php?pwd&whichchoice=1196&option=1&monid=" + to_int(toFight), true, false); // select the monster to fight
}



boolean canConsultColdMedicineCabinet() {
	return false;
// 	int consultsRemaining = 5 - get_property("_coldMedicineConsults").to_int();
// 	int nextColdMedicineConsult = get_property("_nextColdMedicineConsult").to_int();
// 	return consultsRemaining > 0 && nextColdMedicineConsult <= total_turns_played();
}



void coldMedicineCabinet() {
	item [string] kDocNameToItemMap = {
		"Dr. Heelgood, Orthopedist" : $item[ice crown],
		"Dr. Tatestgood, Nutritionist" : $item[frozen tofu pop],
		"Dr. Freeze, Prohibition Doc" : $item[Doc's Smartifying Wine],
		"Dr. Peelgood, Dermatologist" : $item[anti-odor cream],
		"Dr. Iveway, Internist" : $item[Homebodyl&trade;],
	};

	int consultsRemaining = 5 - get_property("_coldMedicineConsults").to_int();
	int nextColdMedicineConsult = get_property("_nextColdMedicineConsult").to_int();
	if (!canConsultColdMedicineCabinet())
		abort("can't consult coldMedicineCabinet, consultsRemaining: " + consultsRemaining + " nextColdMedicineConsult=" + nextColdMedicineConsult + " (current turncount: " + total_turns_played() + ")");

	string cabinetPage = visit_url("/campground.php?action=workshed", false, false); // use post?, encoded?
	string [] choices = available_choice_options();
	item [int] gettableItems;
	int [item] itemToChoiceNumberMap; // maps items to choice number
	int idx;
	foreach num, choice_text in choices {
		item theItem = kDocNameToItemMap[choice_text];
		if (theItem != $item[none]) {
			print(num + ": " + theItem + " @ " + historical_price(theItem));
			itemToChoiceNumberMap[theItem] = num;
			gettableItems[idx++] = theItem;
		} else if (num < 6)
			abort("new doctor name! " + choice_text);
	}

	sort gettableItems by -historical_price(value);
	item bestTarget = gettableItems[0];
	print("coldMedicineCabinet getting: " + bestTarget + " worth " + historical_price(bestTarget), "blue");
	run_choice(itemToChoiceNumberMap[bestTarget]);
}



// -------------------------------------
// BANISH UTILITIES
// -------------------------------------

// returns the turns a given banish skill is in effect for
int banishedTurnsPerCast(skill banish_skill) {
	return kBanishSkillMap[banish_skill];
}


BanishRecord [] parseBanishedMonsters() {
	string [int, int] parser = group_string(get_property("banishedMonsters"), "([^:]+):([^:]+):(\\d+)");
	BanishRecord [int] rval;
	int rvalIndex = 0;
	foreach i in parser {
		rval[rvalIndex].monsterBanished = to_monster(parser[i][1]);
		rval[rvalIndex].skillUsed = to_skill(parser[i][2]);
		rval[rvalIndex].turncount = to_int(parser[i][3]);
		rvalIndex++;
	}
	return rval;
}


// returns the number of turns since the given banish skill was used, or kMaxInt if it has never been used
// based on the property "banishedMonsters"
// if aLocation is not "none", will only consider the banish used if it was used in the given location
int turnsSinceBanishUsed(skill aBanisher, location aLocation) {
	BanishRecord [] banishedMonsters = parseBanishedMonsters();
	foreach i in banishedMonsters {
		BanishRecord br = banishedMonsters[i];
		if (br.skillUsed == aBanisher && (aLocation == $location[none] || contains_monster(aLocation, br.monsterBanished)))
			return my_turncount() - br.turncount;
	}
	return kMaxInt;
}


// returns the number of banishes actually in effect at the given location
// pass in None to count all banishes in effect
int banishesInEffect(location aLocation) {
	BanishRecord [] banishedMonsters = parseBanishedMonsters();
	int total_banishes = 0;
	for i from 0 to count(banishedMonsters) {
		if ((aLocation == $location[none] || contains_monster(aLocation, banishedMonsters[i].monsterBanished)) && (banishedMonsters[i].turncount + banishedTurnsPerCast(banishedMonsters[i].skillUsed) > my_turncount()))
			total_banishes++;
	}
	return total_banishes;
}

int banishesInEffect() {
	return banishesInEffect($location[none]);
}


// true if using the given banisher at the given location (or anywhere if aLocation is None)
boolean using_banish(skill aBanisher, location aLocation) {
	BanishRecord [] banishedMonsters = parseBanishedMonsters();
	for i from 0 to count(banishedMonsters) {
		//print("skill: " + banishedMonsters[i].skillUsed + ", banished: " + banishedMonsters[i].monsterBanished + ", turncount: " + banishedMonsters[i].turncount);
		if ((banishedMonsters[i].skillUsed == aBanisher) && ((aLocation == $location[none] || contains_monster(aLocation, banishedMonsters[i].monsterBanished)) && (banishedMonsters[i].turncount + banishedTurnsPerCast(banishedMonsters[i].skillUsed) > my_turncount())))
			return true;
	}
	return false;
}


// is the banisher being used anywhere?
boolean using_banish(skill aBanisher) {
	return using_banish(aBanisher, $location[none]);
}


int unbanished(location aLocation) {
	print("number of monsters: " + number_monsters(aLocation, false) + ", banishes in effect: " + banishesInEffect(aLocation));
	return number_monsters(aLocation, false);
}


// count monsters who aren't targets and aren't banished
int unbanishedNonTargets(location aLocation, monster [] someTargets) {
	int rval = 0;
	float [monster] monsterMap = appearance_rates(aLocation);
	foreach m in monsterMap {
		//print("testing monster: " + m);
		if (m != $monster[none] && monsterMap[m] > 0) {
			boolean found = false;
			foreach targetIndex in someTargets {
				//print("testing target: " + someTargets[targetIndex]);
				if (someTargets[targetIndex] == m) {
					found = true;
					break;
				}
			}
			if (!found)
				rval++;
		}
	}
	return rval;
}


// returns the status of all banishes in an array
// a banish will be "available" if it is castable/usable, AND either availableWhenInUse is true or the banish is not
// currently being used in the given location (or in any location if location is 'none')
PrioritySkillRecord [int] banishSkillData(boolean availableWhenInUse, location aLocation, int maxPerTurnCost) {
	PrioritySkillRecord tempBSR;
	boolean isInCombat = inCombat();
	int basePriority = 3;
	int costPriority = maxPerTurnCost == kMaxInt ? 1 : 4;
	boolean costIsGood;
	PrioritySkillRecord [int] bsrArray;
	int i = 0;

	// Asdon Martin: Spring-Loaded Front Bumper
	tempBSR = new PrioritySkillRecord($skill[Asdon Martin: Spring-Loaded Front Bumper], $item[none]);
	tempBSR.meatCost = 1400;
	tempBSR.priority = costPriority + 0.1;
	tempBSR.usesAvailable = kUnlimitedUses;
	costIsGood = maxPerTurnCost <= (tempBSR.meatCost / 30);
	tempBSR.isAvailableNow = costIsGood && isAsdonWorkshed() && turnsSinceBanishUsed($skill[Asdon Martin: Spring-Loaded Front Bumper], $location[none]) >= 30 && get_fuel() >= 50;
	bsrArray[i++] = tempBSR;

	// Batter Up!
	tempBSR = new PrioritySkillRecord();
	tempBSR.theSkill = $skill[Batter Up!];
	tempBSR.theItem = $item[none];
	tempBSR.meatCost = kTurnValue;
	tempBSR.priority = costPriority + 0.2;
	tempBSR.usesAvailable = kUnlimitedUses;
	boolean weildingAClub = item_type(equipped_item($slot[weapon])).contains_text("club") || (item_type(equipped_item($slot[weapon])).contains_text("sword") && have_effect($effect[Iron Palms]) > 0);
	costIsGood = maxPerTurnCost <= (tempBSR.meatCost / 100); // banishes for the rest of the day, using 100 as duration
	tempBSR.isAvailableNow = costIsGood && my_class() == $class[seal clubber] && my_fury() >= 5 && (weildingAClub || !isInCombat) && (availableWhenInUse || !using_banish($skill[Batter Up!], aLocation));
	bsrArray[i++] = tempBSR;

	// Show them your ring
	tempBSR = new PrioritySkillRecord();
	tempBSR.theSkill = $skill[Show them your ring];
	tempBSR.theItem = $item[mafia middle finger ring];
	tempBSR.priority = basePriority;
	tempBSR.usesAvailable = to_boolean(get_property("_mafiaMiddleFingerRingUsed")) ? 0 : 1;
	tempBSR.isAvailableNow = equipped_amount($item[mafia middle finger ring]) > 0 || (!isInCombat && canEquipWithExistingAutomatedDressup($item[mafia middle finger ring]));
	bsrArray[i++] = tempBSR;

	// Throw Latte on Opponent
	tempBSR = new PrioritySkillRecord($skill[Throw Latte on Opponent], $item[Latte lovers member's mug]);
	tempBSR.priority = basePriority + 0.1;
	int latteRefillsAvailable = 3 - to_int(get_property("_latteRefillsUsed"));
	boolean latteBanishAvailable = !to_boolean(get_property("_latteBanishUsed"));
	int latteBanishesAvailable = latteRefillsAvailable;
	if (latteBanishAvailable) latteBanishesAvailable++;
	tempBSR.usesAvailable = latteBanishesAvailable;
	tempBSR.isAvailableNow = ((equipped_amount($item[Latte lovers member's mug]) > 0
		 || (!isInCombat && canEquipWithExistingAutomatedDressup($item[Latte lovers member's mug])))
		&& (availableWhenInUse || !using_banish($skill[Throw Latte on Opponent], aLocation)));
	bsrArray[i++] = tempBSR;

	// Show Your Boring Familiar Pictures
	tempBSR = new PrioritySkillRecord($skill[Show Your Boring Familiar Pictures], $item[familiar scrapbook]);
	tempBSR.priority = basePriority + 0.1;
	tempBSR.usesAvailable = to_int(get_property("scrapbookCharges")) / 100;
	tempBSR.isAvailableNow = ((equipped_amount($item[familiar scrapbook]) > 0 && have_skill($skill[Show Your Boring Familiar Pictures]))
		 || (!isInCombat && canEquipWithExistingAutomatedDressup($item[familiar scrapbook])))
		&& (availableWhenInUse || !using_banish($skill[Show Your Boring Familiar Pictures], aLocation));
// 	bsrArray[i++] = tempBSR; // TODO the skill seems to be bugged

	// KGB tranquilizer dart
	tempBSR = new PrioritySkillRecord();
	tempBSR.theSkill = $skill[KGB tranquilizer dart];
	tempBSR.theItem = $item[Kremlin's Greatest Briefcase];
	tempBSR.priority = basePriority + 0.1;
	tempBSR.usesAvailable = 3 - to_int(get_property("_kgbTranquilizerDartUses"));
	tempBSR.isAvailableNow = (equipped_amount($item[Kremlin's Greatest Briefcase]) > 0 || (!isInCombat && canEquipWithExistingAutomatedDressup($item[Kremlin's Greatest Briefcase]))) && (availableWhenInUse || !using_banish($skill[KGB tranquilizer dart], aLocation));
	bsrArray[i++] = tempBSR;

	// Lil' Doctor&trade; bag
	tempBSR = new PrioritySkillRecord();
	tempBSR.theSkill = $skill[Reflex Hammer];
	tempBSR.theItem = $item[Lil' Doctor&trade; bag];
	tempBSR.priority = basePriority + 0.1;
	tempBSR.usesAvailable = 3 - to_int(get_property("_reflexHammerUsed"));
	tempBSR.isAvailableNow = (equipped_amount($item[Lil' Doctor&trade; bag]) > 0 || (!isInCombat && canEquipWithExistingAutomatedDressup($item[Lil' Doctor&trade; bag]))) && (availableWhenInUse || !using_banish($skill[Reflex Hammer], aLocation));
	bsrArray[i++] = tempBSR;

	// Snokebomb
	tempBSR = new PrioritySkillRecord();
	tempBSR.theSkill = $skill[Snokebomb];
	tempBSR.theItem = $item[none];
	tempBSR.priority = basePriority + 0.2;
	tempBSR.usesAvailable = 3 - to_int(get_property("_snokebombUsed"));
	tempBSR.isAvailableNow = availableWhenInUse || !using_banish($skill[Snokebomb], aLocation);
	bsrArray[i++] = tempBSR;

	// Feel Hatred
	tempBSR = new PrioritySkillRecord();
	tempBSR.theSkill = $skill[Feel Hatred];
	tempBSR.theItem = $item[none];
	tempBSR.priority = basePriority + 0.2;
	tempBSR.usesAvailable = 3 - to_int(get_property("_feelHatredUsed"));
	tempBSR.isAvailableNow = availableWhenInUse || !using_banish($skill[Feel Hatred], aLocation);
	bsrArray[i++] = tempBSR;

	// Breathe Out
	tempBSR = new PrioritySkillRecord();
	tempBSR.theSkill = $skill[Breathe Out];
	tempBSR.theItem = $item[none];
	tempBSR.meatCost = mall_price($item[hot jelly]) + (kTurnValue * kTurnsPerSpleen);
	tempBSR.priority = basePriority + 2.3;
	tempBSR.usesAvailable = spleen_limit() - my_spleen_use();
	costIsGood = maxPerTurnCost <= (tempBSR.meatCost / 20); // banishes for the rest of the day, using 100 as duration
	tempBSR.isAvailableNow = costIsGood && have_skill($skill[Breathe Out]) && (availableWhenInUse || !using_banish($skill[Breathe Out], aLocation));
	bsrArray[i++] = tempBSR;

	return bsrArray;
}

PrioritySkillRecord [int] banishSkillData(location aLocation, int maxPerTurnCost) {
	return banishSkillData(false, aLocation, maxPerTurnCost);
}


void printPSRArray(boolean availableWhenInUse, boolean isInCombat, location aLocation, int maxPerTurnCost) {
	printPSRArray(banishSkillData(availableWhenInUse, aLocation, maxPerTurnCost));
}

void printPSRArray() {
	printPSRArray(banishSkillData(false, to_location(get_property("lastAdventure")), kMaxInt));
}


// how many banishes do we have available right now? the fact that a banish is already in use doesn't matter
int banishesAvailable(int maxPerTurnCost) {
	int rval;
	PrioritySkillRecord [int] banishRecords = banishSkillData(true, $location[none], maxPerTurnCost);
	foreach bsrIndex in banishRecords {
		if (banishRecords[bsrIndex].isAvailableNow && (maxPerTurnCost >= banishRecords[bsrIndex].meatCost)) {
			if (banishRecords[bsrIndex].usesAvailable == kUnlimitedUses)
				rval++;
			else
				rval += banishRecords[bsrIndex].usesAvailable;
		}
	}
	return rval;
}


// ease-of-use helper function for refilling latte automatically
void refillLatteIfRequired() {
	int latteRefillsAvailable = 3 - to_int(get_property("_latteRefillsUsed"));
	boolean latteBanishAvailable = !to_boolean(get_property("_latteBanishUsed"));
	if (!latteBanishAvailable && latteRefillsAvailable > 0 && !inRonin()) {
		if (latteRefillsAvailable > 1)
			cli_execute("latte refill cajun carrot rawhide");
		else
			cli_execute("latte refill cajun carrot guarna");
	}
}


// banish selection:
// start by looking at priorities as ints, and select the set of banishes with the same lowest priority, and where usesAvailable > 0 and isAvailableNow is true
// within the set of banishes with the same integer priority, select the banishes with the highest usesAvailable
// within the set of banishes with the same integer priority and the same number of usesAvailable, select the banish with the highest fractional priority
SkillRecord banishToUse(PrioritySkillRecord [] skillData, location aLocation, int maxPerTurnCost, SkillRecord [] excludedBanishes) {
	boolean isInCombat = inCombat();
	if (!isInCombat) refillLatteIfRequired();
	if (maxPerTurnCost > 0 && !isInCombat && isAsdonWorkshed())
		ensureAsdonMartinFuel(50);

	PrioritySkillRecord psr = skillToUse(skillData, aLocation, maxPerTurnCost, excludedBanishes);

	return new SkillRecord(psr.theSkill, psr.theItem);
}

// banish selection:
// start by looking at priorities as ints, and select the set of banishes with the same lowest priority, and where usesAvailable > 0 and isAvailableNow is true
// within the set of banishes with the same integer priority, select the banishes with the highest usesAvailable
// within the set of banishes with the same integer priority and the same number of usesAvailable, select the banish with the highest fractional priority
SkillRecord banishToUse(location aLocation, int maxPerTurnCost, SkillRecord [] excludedBanishes) {
	PrioritySkillRecord [] skillData = banishSkillData(false, aLocation, maxPerTurnCost);
	return banishToUse(skillData, aLocation, maxPerTurnCost, excludedBanishes);
}

SkillRecord banishToUse(PrioritySkillRecord [] skillData, location aLocation, int maxPerTurnCost) {
	SkillRecord [] excludedBanishes;
	return banishToUse(skillData, aLocation, maxPerTurnCost, excludedBanishes);
}

SkillRecord banishToUse(location aLocation, int maxPerTurnCost) {
	PrioritySkillRecord [] skillData = banishSkillData(false, aLocation, maxPerTurnCost);
	SkillRecord [] excludedBanishes;
	return banishToUse(skillData, aLocation, maxPerTurnCost, excludedBanishes);
}

SkillRecord banishToUse(location aLocation) {
	return banishToUse(aLocation, 0);
}



// -------------------------------------
// REPLACE MONSTER UTILITIES
// -------------------------------------

// returns the status of all monster replacers
PrioritySkillRecord [int] replaceMonsterSkillData() {
	boolean isInCombat = inCombat();
	PrioritySkillRecord tempPSR;
	int basePriority = 3;
	PrioritySkillRecord [int] psrArray;
	int i = 0;

	// Macrometeorite
	tempPSR = new PrioritySkillRecord();
	tempPSR.theSkill = $skill[Macrometeorite];
	tempPSR.theItem = $item[none];
	tempPSR.priority = basePriority;
	tempPSR.usesAvailable = 10 - to_int(get_property("_macrometeoriteUses"));
	tempPSR.isAvailableNow = true;
	psrArray[i++] = tempPSR;

	// Macrometeorite
	int batteryPowerUsed = to_int(get_property("_powerfulGloveBatteryPowerUsed"));
	int usesAvailable = (100 - batteryPowerUsed) / 10;
	boolean isAvailableNow = (equipped_amount($item[Powerful Glove]) > 0 || (!isInCombat && canEquipWithExistingAutomatedDressup($item[Powerful Glove])));
	tempPSR = new PrioritySkillRecord($skill[CHEAT CODE: Replace Enemy], $item[Powerful Glove], 0, 0, basePriority, usesAvailable, isAvailableNow);
	psrArray[i++] = tempPSR;

	return psrArray;
}

PrioritySkillRecord chooseReplaceMonsterSkill() {
	SkillRecord [int] excludedSkills;
	return skillToUse(replaceMonsterSkillData(), $location[none], kMaxInt, excludedSkills);
}


boolean canReplaceMonster() {
	PrioritySkillRecord chosenReplaceMonsterSkill = chooseReplaceMonsterSkill();
	boolean rval = ((chosenReplaceMonsterSkill.theSkill != $skill[none]) && (chosenReplaceMonsterSkill.usesAvailable > 0) && chosenReplaceMonsterSkill.isAvailableNow);

	if (rval)
		print("we can replace monsters");
	else
		print("we can't replace monsters");

	return rval;
}



// -------------------------------------
// INSTA KILL UTILITIES
// -------------------------------------
// an insta-kill/instakill/insta kill is an auto-kill that takes no turns, these are all from IotM

// returns the status of all free kill skills in an array
PrioritySkillRecord [int] instaKillSkillData() {
	boolean isInCombat = inCombat();
	PrioritySkillRecord tempPSR;
	int basePriority = 3;
	PrioritySkillRecord [int] psrArray;
	int i = 0;

	// Gingerbread Mob Hit
	tempPSR = new PrioritySkillRecord();
	tempPSR.theSkill = $skill[Gingerbread Mob Hit];
	tempPSR.theItem = $item[none];
	tempPSR.priority = basePriority;
	tempPSR.usesAvailable = to_boolean(get_property("_gingerbreadMobHitUsed")) ? 0 : 1;
	tempPSR.isAvailableNow = true;
	psrArray[i++] = tempPSR;

	// Chest X-Ray
	tempPSR = new PrioritySkillRecord();
	tempPSR.theSkill = $skill[Chest X-Ray];
	tempPSR.theItem = $item[Lil' Doctor&trade; bag];
	tempPSR.priority = basePriority;
	tempPSR.usesAvailable = 3 - to_int(get_property("_chestXRayUsed"));
	tempPSR.isAvailableNow = (equipped_amount($item[Lil' Doctor&trade; bag]) > 0 || (!isInCombat && canEquipWithExistingAutomatedDressup($item[Lil' Doctor&trade; bag])));
	psrArray[i++] = tempPSR;

	// Shattering Punch
	tempPSR = new PrioritySkillRecord();
	tempPSR.theSkill = $skill[Shattering Punch];
	tempPSR.theItem = $item[none];
	tempPSR.priority = basePriority;
	tempPSR.usesAvailable = 3 - to_int(get_property("_shatteringPunchUsed"));
	tempPSR.isAvailableNow = true;
	psrArray[i++] = tempPSR;

	return psrArray;
}


int instaKillsAvailable() {
	int rval;
	PrioritySkillRecord [int] instaKillSkillData = instaKillSkillData();
	foreach idx in instaKillSkillData {
		rval += instaKillSkillData[idx].usesAvailable;
	}
	return rval;
}


PrioritySkillRecord chooseInstaKillSkill() {
	SkillRecord [int] excludedSkills;

	if (!inCombat() && isAsdonWorkshed())
		ensureAsdonMartinFuel(100);
	return skillToUse(instaKillSkillData(), $location[none], kMaxInt, excludedSkills);
}



// -------------------------------------
// YELLOW RAY UTILITIES
// -------------------------------------
// a yellow ray/yellow-ray/yellowray forces all items to drop, or all non-conditional items to drop
// usually it will end combat, and sometimes without a turn spent
// these are all from IotM

// returns the status of all yellow skills in an array
PrioritySkillRecord [int] yellowRaySkillData() {
	boolean isInCombat = inCombat();
	PrioritySkillRecord tempPSR;
	int basePriority = 3;
	PrioritySkillRecord [int] psrArray;
	int i = 0;

	// Asdon Martin: Spring-Loaded Front Bumper
	tempPSR = new PrioritySkillRecord($skill[Asdon Martin: Missile Launcher]);
	tempPSR.theItem = $item[none];
	tempPSR.meatCost = 2800;
	tempPSR.priority = basePriority;
	tempPSR.usesAvailable = to_boolean(get_property("_missileLauncherUsed")) ? 0 : 1;
	tempPSR.isAvailableNow = isAsdonWorkshed() && get_fuel() >= 100;
	psrArray[i++] = tempPSR;

	// Disintegrate
// 	tempPSR = new PrioritySkillRecord($skill[Disintegrate]);
// 	tempPSR.theItem = $item[none];
// 	tempPSR.meatCost = kTurnValue;
// 	tempPSR.mpCost = 150;
// 	tempPSR.priority = basePriority;
// 	tempPSR.usesAvailable = kUnlimitedUses;
// 	tempPSR.isAvailableNow = (have_effect($effect[Everything Looks Yellow]) == 0) && (my_mp() >= 150);
// 	psrArray[i++] = tempPSR;

	// yellow rocket -- cost 250 meat but only 75 turns of Everything Looks Yellow
	tempPSR = new PrioritySkillRecord($skill[none], $item[yellow rocket]);
	tempPSR.meatCost = 250;
	tempPSR.mpCost = 0;
	tempPSR.priority = basePriority;
	tempPSR.usesAvailable = kUnlimitedUses;
	tempPSR.isAvailableNow = (have_effect($effect[Everything Looks Yellow]) == 0);
	psrArray[i++] = tempPSR;

	// Feel Envy
	tempPSR = new PrioritySkillRecord($skill[Feel Envy]);
	tempPSR.theItem = $item[none];
	tempPSR.meatCost = kTurnValue;
	tempPSR.mpCost = 0;
	tempPSR.priority = basePriority;
	tempPSR.usesAvailable = 3 - to_int(get_property("_feelEnvyUsed"));
	tempPSR.isAvailableNow = true;
	psrArray[i++] = tempPSR;

	// Use the Force
	tempPSR = new PrioritySkillRecord($skill[Use the Force]);
	tempPSR.theItem = $item[Fourth of May Cosplay Saber];
	tempPSR.meatCost = 0;
	tempPSR.mpCost = 0;
	tempPSR.priority = basePriority;
	tempPSR.usesAvailable = 5 - to_int(get_property("_saberForceUses"));
	tempPSR.isAvailableNow = !isInCombat || equipped_amount($item[Fourth of May Cosplay Saber]) > 0;
	psrArray[i++] = tempPSR;

	// Shocking Lick
	tempPSR = new PrioritySkillRecord($skill[Shocking Lick]);
	tempPSR.theItem = $item[none];
	tempPSR.meatCost = 0;
	tempPSR.mpCost = 0;
	tempPSR.priority = basePriority;
	tempPSR.usesAvailable = to_int(get_property("shockingLickCharges"));
	tempPSR.isAvailableNow = true;
	psrArray[i++] = tempPSR;

	return psrArray;
}


// get mana and other resources to allow YR
void prepForYellowRay() {
	restore_mp(150);
	if (isAsdonWorkshed() && !to_boolean(get_property("_missileLauncherUsed")))
		ensureAsdonMartinFuel(100);
}


PrioritySkillRecord chooseYellowRaySkill(SkillRecord [] excludedSkills) {
	if (!inCombat())
		prepForYellowRay();
	return skillToUse(yellowRaySkillData(), $location[none], kMaxInt, excludedSkills);
}

PrioritySkillRecord chooseYellowRaySkill() {
	SkillRecord [] excludedSkills;
	return chooseYellowRaySkill(excludedSkills);
}


boolean canYellowRay() {
	PrioritySkillRecord chosenYellowRaySkill = chooseYellowRaySkill();
	return chosenYellowRaySkill.theSkill != $skill[none] && chosenYellowRaySkill.usesAvailable > 0 && chosenYellowRaySkill.isAvailableNow;
}

// returns true if we have any yellow ray skills available that don't give the Everything Looks Yellow debuff
// can be used to ensure all free yellow ray skills are used
boolean canYellowRayWithoutSeeingYellow() {
	SkillRecord [] excludedSkills = {new SkillRecord($skill[Disintegrate], $item[none])};
	PrioritySkillRecord chosenYellowRaySkill = chooseYellowRaySkill(excludedSkills);
	return chosenYellowRaySkill.theSkill != $skill[none] && chosenYellowRaySkill.usesAvailable > 0 && chosenYellowRaySkill.isAvailableNow;
}


boolean canDisintegrate() {
	return have_effect($effect[Everything Looks Yellow]) == 0;
}



// -------------------------------------
// POST ADVENTURE
// -------------------------------------


// TODO: play with the boombox???? can only do 11/day
// TODO: LOVe potion #0 / tainted LOVe potion
// TODO: red rocket/blue rocket
// returns true iff there were goals at the start of the adventure and all goals were satisfied in the last adventure
boolean postAdventure() {
	print("**RUNNING post-adventure script**", "blue");

	assert(!inCombat(), "postAdventure: shouldn't be in combat");
	assert(!handling_choice(), "postAdventure: shouldn't be in a choice");
	print("debug: raw mood: " + getMoodRaw());

	// setSmutOrcPervertProgress  -- MOVED TO advURLWithWanderingMonsterRedirect
// 	if (my_location() == $location[The Smut Orc Logging Camp]) {
// 		setSmutOrcPervertProgress(smutOrcPervertProgress() + 1);
// 		print("setting smutOrcPervertProgress to: " + smutOrcPervertProgress() + ", turns spent in zone: " + $location[The Smut Orc Logging Camp].turns_spent + ", turns in zone for last pervert: " + to_int(get_property(kLastSmutOrcPervertTurnsSpentKey)));
// 	}
	if (last_monster() == $monster[smut orc pervert]) {
		int lastSmutOrcPervertTurnsSpent = to_int(get_property(kLastSmutOrcPervertTurnsSpentKey));
		print("found Smut Orc Pervert, progress was " + smutOrcPervertProgress() + ", resetting progress to 0 -- turns spent in zone: " + $location[The Smut Orc Logging Camp].turns_spent + ", turns in zone for last pervert: " + lastSmutOrcPervertTurnsSpent, "orange");
		set_property(kLastSmutOrcPervertTurnsSpentKey, $location[The Smut Orc Logging Camp].turns_spent - 1);
		setSmutOrcPervertProgress(0);
	}

	if (!inRonin()) {
		cli_execute("dreadstopper");

		// put in storage items that get auto-used and which we don't want to be auto-used
		put_closet(item_amount($item[funky junk key]), $item[funky junk key]);
		put_closet(item_amount($item[bowling ball]), $item[bowling ball]); // in ronin as well??
		put_closet(item_amount($item[twist of lime]), $item[twist of lime]);
		put_closet(item_amount($item[Swizzler]), $item[Swizzler]);

		// having none blocks the lucky gold ring from dropping them
		put_closet(item_amount($item[sand dollar]), $item[sand dollar]);
		put_closet(item_amount($item[hobo nickel]), $item[hobo nickel]);

		// having none allows them to drop from the Boxing Daydream
		put_closet(item_amount($item[bauxite beret]), $item[bauxite beret]);
		put_closet(item_amount($item[bauxite boxers]), $item[bauxite boxers]);
		put_closet(item_amount($item[bauxite bow-tie]), $item[bauxite bow-tie]);
		put_closet(item_amount($item[My First Art of War]), $item[My First Art of War]);
		put_closet(item_amount($item[Boxing Day Pass]), $item[Boxing Day Pass]);

		// GUZZLR -- make sure we have a gold quest open at all times if possible
		// will be grinded by the redirection mechanism for sausage goblins, vote monsters, and maybe others in the future
		// will not get a bronze quest if we have the maple magnet
		if (get_property("questGuzzlr") == "unstarted"
			&& (!have_item($item[maple magnet]) 
				|| get_property("_guzzlrPlatinumDeliveries").to_int() == 0
				|| get_property("_guzzlrGoldDeliveries").to_int() < 3)) {
			if (to_int(get_property("_guzzlrPlatinumDeliveries")) == 0)
				getAndCancelPlatinumGuzzlrQuest();
			getGuzzlrQuest();
		}

		// COLD MEDICINE cabinet
		if (canConsultColdMedicineCabinet())
			coldMedicineCabinet();
	} else {
		// FIREWORKS -- ensure we have one rocket of each colour at all times
		if (my_meat() > 2000) {
			if (item_amount($item[red rocket]) == 0)
				fullAcquire($item[red rocket]);
			if (item_amount($item[blue rocket]) == 0)
				fullAcquire($item[blue rocket]);
			if (item_amount($item[yellow rocket]) == 0)
				fullAcquire($item[yellow rocket]);
		}

		// COLD MEDICINE cabinet
		if (canConsultColdMedicineCabinet())
			print("cold medicine cabinet is ready!", "red");
	}

	checkForLastSausageGoblin();

	if (my_adventures() == 0)
		print("ZERO ADVENTURES! Fight an XO monster?!!!!?", "red");

	// GOALS and return value
	if (to_boolean(get_property(kHadGoalsKey)) && count(get_goals()) == 0) {
		print("conditions have been satisfied!", "green");
		set_property(kHadGoalsKey, "false");
		return true;
	} else
		return false;
}



// -------------------------------------
// THINGS THAT SPEND TURNS AND REQUIRE postAdventure()
// -------------------------------------


// returns money spent
int daycareRecruit() {
	int startingMeat = my_meat();

	preAdventureChecks(0); // takes money, not turns
	visit_url("/place.php?whichplace=town_wrong&action=townwrong_boxingdaycare", true, false);
	visit_url("/choice.php?pwd&whichchoice=1334&option=3", true, false);
	visit_url("/choice.php?pwd&whichchoice=1336&option=1", true, false);
	visit_url("/main.php", true, false);
	postAdventure();

	return startingMeat - my_meat();
}


void daycareScavenge() {
	preAdventureChecks(3);
	advURL("/place.php?whichplace=town_wrong&action=townwrong_boxingdaycare", 1);
	run_choice(3);
	run_choice(2);
	visit_url("/main.php", true, false);
	postAdventure();
	//visit_url("/choice.php?pwd&whichchoice=1334&option=3", true, false);
	//visit_url("/choice.php?pwd&whichchoice=1336&option=2", true, false);
}

void burnScavengeDaycare(int turnsToSpend) {
	print("burnScavengeDaycare: " + turnsToSpend + " turns", "blue");

	int daycareGymScavenges = to_int(get_property("_daycareGymScavenges"));
	int nextScavengeTurnCost = min(daycareGymScavenges, 3);

	while (turnsToSpend >= nextScavengeTurnCost) {
		print("scavenging...");
		daycareScavenge();
		turnsToSpend -= nextScavengeTurnCost;
		daycareGymScavenges = to_int(get_property("_daycareGymScavenges"));
		nextScavengeTurnCost = min(daycareGymScavenges, 3);
	}
}



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
// 		if (joinString == "") joinString = " && ";
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



