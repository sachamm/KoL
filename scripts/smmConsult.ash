import <smmUtils.ash>
string __smm_consult_version = "0.1";

/**
To use, place this in the custom combat script:

consult smmConsult.ash

To use any of the functions from the command line, do this:
using smmConsult.ash
*/

// TODO add Army of Toddlers when wearing xp shirt

// -------------------------------------
// GLOBALS, DATA TYPES, CONSTANTS, AND DATA
// -------------------------------------

string kNostalgiaNextCombatKey = "_smm.NostalgiaNextCombat";
string kSpikolodonNextCombatKey = "_smm.kSpikolodonNextCombat";

record AbortRecord {
	int missed;
	int pastround;
	int hpbelow;
	int hppercentbelow;
	int mpbelow;
};


record DebuffMonsterRecord {
	float expectedAttackFraction; // the amount of offence debuff expected by taking actions[] -- absolute value can be calculated with monster's base attack
	float expectedDefenseFraction; // the amount of defense debuff expected by taking actions[] -- absolute value can be calculated with monster's base defense

	float repeatingAttackFraction; // the repeating debuff to offence, applied after roundsTaken
	float repeatingDefenseFraction; // the repeating debuff to defense, applied after roundsTaken
	float repeatingAttackAbsolute; // applied separately from repeatingAttackFraction
	float repeatingDefenseAbsolute; // applied separately from repeatingDefenseFraction

	int roundsTaken;
	ActionRecord [int] actions;
};


record DamageRecord {
	int damage;
	int damageTypes; // pick damageTypes elements from dmgElements and do damage of each type
	element [int] dmgElements; // none = physical
};


// TODO these pickpocket array constants should probably be removed and a more general check done
string [] NoPPMonsters = {
	"beefy bodyguard bat",
	"sabre-toothed lime",
	"dairy ooze"
};
string [] ltaNoPPMonsters = {
	"minion",
	"Number Five",
	"Mr. Huge",
	"May Jones"
};


string gAccumulatedResponse;

int gkMonsterOriginalAttack;
int gkMonsterOriginalDefense;




// -------------------------------------
// UTILITIES
// -------------------------------------

float addPercent(float number, float percent_to_add) {
	return number + (number * (percent_to_add/100));
}



// for physical attacks -- depends on what you're weilding (range vs melee)
stat attackStat() {
	stat rval;

// 	rval = weapon_type(equipped_item($slot[weapon]));
	rval = current_hit_stat();
	if (equipped_item($slot[weapon]) == $item[Fourth of May Cosplay Saber])
		rval = my_primestat();

	return rval;
}



// true if we want to keep the monster alive as long as possible (star starfish trick)
boolean wantToStasis() {
	return my_familiar() == $familiar[star starfish] || my_familiar() == $familiar[Sausage Golem] || my_familiar() == $familiar[Underworld Bonsai];
}



boolean macroAborted(string page) {
	return page.contains_text("Macro Aborted");
}



int _gRealMonsterHP;

// returns the monster's real hp as reported by KoL, not Mafia
// call with the empty string (or other non-matching string) for the cached value
// defaults to monster_hp() if it can't figure out the hp from the string and there is no cached value
int real_monster_hp(string combatResult) {
	int rval;
	string attackResult = combatResult.to_lower_case();
	//print("attack string: " + attackResult, "green");

	matcher damageSectionMatcher = create_matcher("var monsterstats = \\{\"hp\":\"([0-9,]+)\",\"def\":\"([0-9,]+)\",\"off\":\"([0-9,]+)\"\\};", attackResult);
	while (find(damageSectionMatcher))
		rval = min(rval, to_int(group(damageSectionMatcher, 1)));

	if (rval <= 0) {
		matcher statblockMatcher = create_matcher("HP: ([0-9]+), Atk: [0-9]+], Def: [0-9]+, Type:", attackResult);
		while (find(statblockMatcher))
			rval = min(rval, to_int(group(statblockMatcher, 1)));
	}

	if (rval <= 0) {
		if (_gRealMonsterHP != 0)
			rval = _gRealMonsterHP;
		else
			rval = monster_hp();
	}

	_gRealMonsterHP = rval;
	return _gRealMonsterHP;
}

int real_monster_hp() {
	return real_monster_hp(visit_url("/fight.php"));
}



AbortRecord defaultAborts(monster foe) {
	AbortRecord rval;

	// conservative by default
	rval.missed = 2;
	rval.pastround = 25;
	rval.hpbelow = 50;
	rval.hppercentbelow = 50;

	if (my_class() == $class[seal clubber]) {
		rval.missed = 5;
// 		rval.pastround = 20;
		rval.hpbelow = 33;
		rval.hppercentbelow = 33;

	} else if (my_class() == $class[turtle tamer]) {
		rval.missed = 8;
// 		rval.pastround = 25;
		rval.hpbelow = 20;
		rval.hppercentbelow = 20;

	} else if (my_class() == $class[pastamancer] || my_class() == $class[sauceror]) {
		rval.mpbelow = 26;

	} else if (my_class() == $class[disco bandit]) {
		rval.missed = 8;
// 		rval.pastround = 25;
		rval.hpbelow = 25;
		rval.hppercentbelow = 25;

	} else if (my_class() == $class[accordion thief]) {
		rval.missed = 4;
// 		rval.pastround = 20;
		rval.hpbelow = 33;
		rval.hppercentbelow = 33;

	}

	// these monsters run the razor's edge by default
	if (foe == $monster[Slime Tube monster] || foe == $monster[spooky ghost]) {
		rval.hpbelow = 0;
		rval.hppercentbelow = 0;
	}

	return rval;
}



// max number of rounds we should automate -- if we don't kill it in this amount of time, something might be wrong so we'll generally abort
int maxRounds(monster foe) {
	return defaultAborts(foe).pastround;
}



// expected_damage taken by us, with a safety factor
int safeExpectedDamageTaken(monster foe) {
	int damage = max(expected_damage(), 1);

	if (foe == $monster[drippy tree] || foe == $monster[drippy bat] || foe == $monster[drippy reveler])
		damage = my_maxhp() * 0.3;

	else if (foe == $monster[amorphous blob])
		damage += my_maxhp() * 0.25;

	return damage * kExpectedDamageSafetyFactor;
}



string toString(DamageRecord dr) {
	string elementString;
	foreach idx, anElement in dr.dmgElements {
		elementString = elementString.joinString(anElement, ", ");
	}

	return dr.damage + " dmg, picking " + dr.damageTypes + " element from types " + elementString;
}

string toString(DamageRecord [] drs) {
	string rval;
	foreach idx, dr in drs {
		rval += dr + "\n";
	}

	return rval;
}


// returns the base expected damage done by the give skill, i.e. damage without any damage resistance, bonus damage or bonus percent damage
// skill none = attack
DamageRecord [] baseExpectedDamageDone(skill dmgSkill) {
	DamageRecord [int] rval;

	if (dmgSkill == $skill[none]) {
		int damage = max(my_buffedstat(current_hit_stat()) - monster_defense(), 0);
		rval[0] = new DamageRecord(damage, 1, {$element[none]});

	} else if (dmgSkill == $skill[Saucestorm]) {
		rval[0] = new DamageRecord(min(50, 22 + floor(0.2 * my_buffedstat($stat[mysticality]))), 2, {$element[cold], $element[hot]});

	} else if (dmgSkill == $skill[Saucegeyser]) {
		rval[0] = new DamageRecord(65 + floor(0.4 * my_buffedstat($stat[mysticality])), 1, {$element[cold], $element[hot]});

	} else if (dmgSkill == $skill[Weapon of the Pastalord]) {
		rval[0] = new DamageRecord(48 + floor(0.5 * my_buffedstat($stat[mysticality])), 1, {$element[none]});
	}

	return rval;
}



// returns the expected damage done after any bonus damage and the element type of the damage of the given skill
// does NOT consider foe resistance
// skill none = attack
DamageRecord [] expectedDamageDoneAfterBuffs(skill dmgSkill) {
	DamageRecord [int] rval;

	int dmg;
	int weaponBonus = numeric_modifier("Weapon Damage");
	float weaponBonusPercent = numeric_modifier("Weapon Damage Percent") / 100.0;
	int spellBonus = numeric_modifier("Spell Damage");
	float spellBonusPercent = numeric_modifier("Spell Damage Percent") / 100.0;
	print("weapon bonus damage: " + weaponBonus + ", weapon bonus damage %: " + (weaponBonusPercent * 100) + ", spell bonus damage: " + spellBonus + ", spell bonus damage %: " + (spellBonusPercent * 100));

	if (dmgSkill == $skill[none]) {
		int damage = (max(my_buffedstat(current_hit_stat()) - monster_defense(), 0) + weaponBonus) * (1.0 + weaponBonusPercent);
		rval[0] = new DamageRecord(damage, 1, {$element[none]});

	} else if (dmgSkill == $skill[Saucestorm]) {
		dmg = min(50, 22 + floor(0.2 * my_buffedstat($stat[mysticality]) + spellBonus)) * (1.0 + spellBonusPercent);
		rval[0] = new DamageRecord(dmg, 2, {$element[cold], $element[hot]});

	} else if (dmgSkill == $skill[Saucegeyser]) {
		dmg = ((65 + floor(0.4 * my_buffedstat($stat[mysticality]))) * (1.0 + spellBonusPercent)) + spellBonus;
		rval[0] = new DamageRecord(dmg, 1, {$element[cold], $element[hot]});

	} else if (dmgSkill == $skill[Weapon of the Pastalord]) {
		rval[0] = new DamageRecord(48 + floor(0.5 * my_buffedstat($stat[mysticality])), 1, {$element[none]});
	}

	return rval;
}


// chooses which element to use against the given foe from among the options of the damage we're evaluating
// example: Saucegeyser will choose hot or cold depending on the foe's resistances
element [] choseElements(DamageRecord dr, monster foe) {
	element [int] usefulChoices;
	int i = 0;
	foreach idx, anElement in dr.dmgElements {
// 			if (monster_element(foe) == anElement)
		if (i < dr.damageTypes) {
			// first chose all the elements we need
			usefulChoices[i] = anElement;
			i++;
		} else if (anElement == foe.monster_element()) {
			// we have chosen all the elements we need and this extra element isn't useful
			continue;
		} else {
			// we have all the elements we need and have an extra element and it is useful, check if any of the existing choices are not useful
			foreach idx2, choiceElement in usefulChoices {
				if (choiceElement == foe.monster_element() && choiceElement != $element[none])
					usefulChoices[idx2] = anElement;
			}
		}
	}
	return usefulChoices;
}


// DOES consider foe resistance
// skill none = attack
int expectedDamageDoneToMonsterBySkill(monster foe, skill dmgSkill) {
	int [element] damageByElement;
	element [int] sortableElements;
	int i;

	DamageRecord [] damageData = expectedDamageDoneAfterBuffs(dmgSkill);
	assert(count(damageData) == 1, "not expecting more than 1 DamageRecord");
	DamageRecord dr = damageData[0];

	int elementsToChoose = dr.damageTypes;
	int damageDone;
	foreach idx, anElement in dr.dmgElements {
		int damageResisted;
		if (anElement == $element[none]) // physical res
			damageResisted = max(0, dr.damage * (foe.physical_resistance / 100.0));
		else if (monster_element(foe) == anElement) // strong against element
			damageResisted = dr.damage - 1;
		else if (weak_elements(foe.monster_element()) contains anElement) // weak against element
			damageResisted = -dr.damage;

		damageDone = max(0, (dr.damage - damageResisted));
		damageByElement[anElement] += damageDone;
		sortableElements[i++] = anElement;
		print("possible damage done: " + damageDone + " by element " + anElement + " to foe: " + foe);
	}

	sort sortableElements by -damageByElement[value];

	int totalDamage;
	for idx from 0 to elementsToChoose - 1 {
		element anElement = sortableElements[idx];
		damageDone = damageByElement[anElement];
		totalDamage += damageDone;
		print("actual damage done: " + damageDone + " by element " + anElement + " to foe: " + foe);
	}

	print("total damage done: " + totalDamage + " to foe: " + foe);
	return totalDamage;
}



// flat amount of hp we expect to remove from the given monster AFTER considering element defense and susceptibility
int expectedDamageDone(ActionRecord anAction, monster foe) {
	int totalDamage = 0;

	// SKILL / ATTACK
	if (anAction.skillToUse != $skill[none] || anAction.attack) {
		totalDamage = expectedDamageDoneToMonsterBySkill(foe, anAction.skillToUse);

	// COMBAT ITEMS
	} else if (anAction.itemToUse != $item[none]) {
		// have to do this manually????
		if (anAction.itemToUse == $item[Arr, M80]) {
			if (foe.monster_element() == $element[hot])
				return 1;
			foreach weakElement in weak_elements(foe.monster_element()) {
				if (weakElement == $element[hot])
					return 100;
			}
			return 50;
		}
	} else
		assert(false, "expectedDamageDone: should not get here, action: " + anAction.toString());

	print("expectedDamageDone with action: " + anAction.toString() + " vs foe: " + foe + " is: " + totalDamage, "blue");
	return totalDamage;
}



// expected_damage with a safety factor
int safeExpectedDamageTaken() {
	return safeExpectedDamageTaken(last_monster());
}

// TODO some monsters can't be staggered
boolean canStagger(monster foe) {
	if (arrayContains(get_monsters($location[Through the Spacegate]), foe) && get_property("_spacegateCoordinates") > "R")
		return false;
	if (foe == $monster[Normal hobo]) return false;
	if (foe == $monster[drippy tree] || foe == $monster[drippy bat] || foe == $monster[drippy reveler]) return false;

	return monster_level_adjustment() < 100;
}

boolean canInjureWithSpells(monster foe) {
	if ((foe == $monster[Murderbot soldier] || foe == $monster[Murderbot drone]) && get_property("_spacegateCoordinates") > "R")
		return false;

	return true;
}


// does NOT take into consideration any debuffing that might happen
int expectedRoundsToKill(monster foe, int monsterHP, int damageDone) {
	if (damageDone == 0) damageDone++; // make sure we're not dividing by zero
	return ceil(monsterHP / to_float(damageDone)); // int/int = int, which will truncate any fraction instead of rounding up
}

// does NOT take into consideration any debuffing that might happen
int expectedRoundsToKill(monster foe, int monsterHP, ActionRecord anAttack) {
	// if we're going to use an instaKill, we're going to kill it in 1 rd
// 	if (instaKillSkillData().theSkill contains defAction.skillToUse) // TODO could be any insta kill
	if (anAttack.skillToUse == $skill[Free-for-All])
		return 1;

	int expectedDamageDone = expectedDamageDone(anAttack, foe);
	int expectedRoundsToKill = expectedRoundsToKill(foe, monsterHP, expectedDamageDone);

	return expectedRoundsToKill;
}


// does NOT take into consideration any debuffing that might happen
boolean willKillBeforeTimeout(monster foe, int monsterHP, int damageDone) {
	return expectedRoundsToKill(foe, monsterHP, damageDone) <= maxRounds(foe);
}

// uses estimates of future damage done
// does NOT take into consideration any debuffing that might happen
boolean willKillBeforeTimeout(monster foe, int monsterHP, ActionRecord anAttack) {
	int expectedDamageDone = expectedDamageDone(anAttack, foe);
	return willKillBeforeTimeout(foe, monsterHP, expectedDamageDone);
}


// does NOT take into consideration any debuffing that might happen
boolean willKillBeforeDying(monster foe, int monsterHP, int damageDone, int damageTaken) {
	assert(damageDone > 0, "willKillBeforeDying got a zero damageDone");
	assert(damageTaken > 0, "willKillBeforeDying got a zero damageTaken");

	// int/int = int, which will truncate any fraction instead of rounding up -- hence the conversion to float
	int expectedRoundsToKill = ceil(monsterHP / to_float(damageDone));
	int expectedRoundsToDie = floor(my_hp() / to_float(damageTaken));
	return expectedRoundsToKill <= expectedRoundsToDie;
}

// uses estimates of future damage taken and given
// does NOT take into consideration any debuffing that might happen
boolean willKillBeforeDying(monster foe, int monsterHP, ActionRecord anAttack) {
	// ensure neither of these are assigned 0, which will result in a div by zero error
	int expectedDamageDone = max(1, expectedDamageDone(anAttack, foe));
	int expectedDamageTaken = max(1, safeExpectedDamageTaken());
	return willKillBeforeDying(foe, monsterHP, expectedDamageDone, expectedDamageTaken);
}



boolean didWinFight(string pageToTest) {
	return pageToTest.contains_text("You win the fight!");
}

void exitOnWinFight(string pageToTest) {
	if (didWinFight(pageToTest)) {
		print("we won the fight, exiting consult script", "green");
		exit;
	}
}

string executeScriptAndExitOnWinFight(monster foe, string script) {
	string aPage = executeScript(script);

	if (foe == $monster[Normal hobo] && (aPage.contains_text("Okskin.gif") || aPage.contains_text("Okboots.gif") || aPage.contains_text("Okeyes.gif") || aPage.contains_text("Okguts.gif") || aPage.contains_text("Okskull.gif") || aPage.contains_text("Okcrotch.gif")))
		print("************ WARNING: hobo overkilled ************", "red");

	exitOnWinFight(aPage);
	return aPage;
}



// returns true if at least one drop of this given monster is pickpocketable and
// we're not going to take too much damage by pickpocketing (too much = more than 50% our current hp)
// TODO don't steal if no pp-only item and all items are both 100% pp AND 100% drop
boolean pickpocketable(monster foe) {
	// if it is a new monster, default to true since we have no idea
	if (foe.image == "") return true;

	// if pickpocketing puts us in danger, return false (danger means expected damage will kill us in 2 rounds)
	if (my_hp() < safeExpectedDamageTaken() * 2)
		return false;

	// if it has any known pickpocket-able items, return true
	foreach index, rec in item_drops_array(foe)
		if (rec.type == "p" || rec.type == "" || rec.type == "0")
			return true;

	// otherwise, false
	return false;
}




// returns the debuff needed to ensure the current monster attacks won't hit
// as a fraction of the monster's attack stat. will always be between 0 and 1, inclusive
float monsterAttackDebuffNeededFraction() {
	return min(my_buffedstat($stat[moxie]) / (monster_attack() + 10.0), 1.0);
}

// returns the absolute value of the debuff needed to ensure the current monster attacks won't hit
// return value will always be positive
int monsterAttackDebuffNeededAbsolute() {
	return max((monster_attack() + 10.0) - my_buffedstat($stat[moxie]), 0);
}


// returns the debuff needed to ensure our attacks will hit the current monster
// as a fraction of the monster's defense stat. will always be between 0 and 1, inclusive
float monsterDefenseDebuffNeededFraction() {
	return min(my_buffedstat(attackStat()) / (monster_defense() + 5.0), 1.0);
}

// returns the absolute value of the debuff needed to ensure the current monster attacks won't hit
// return value will always be positive
int monsterDefenseDebuffNeededAbsolute() {
	return max((monster_defense() + 5.0) - my_buffedstat(attackStat()), 0);
}


// returns an array of debuff actions we will use to achieve the needed debuffs
// all debuffs will cause staggering with the possible exception of when a non-staggering debuff was the last to bring us over debuffNeeded
// TODO Stealth Mistletoe
DebuffMonsterRecord debuffMonsterRecords(float monsterAttackDebuffNeededFraction, float monsterDefenseDebuffNeededFraction, int wantedStatisRounds) {
	DebuffMonsterRecord rval = new DebuffMonsterRecord(1.0, 1.0, 1.0, 1.0, 0, 0);
  	float debuffNeeded = min(monsterAttackDebuffNeededFraction, monsterDefenseDebuffNeededFraction);

	item [] kDelevelNoStaggerItems = {
		$item[Zombo's empty eye],
		$item[Miniborg hiveminder],
		$item[Miniborg Destroy-O-Bot],
		$item[Miniborg strangler],
		$item[spectre scepter],
		$item[spectre scepter],
		$item[spectre scepter],
		$item[spectre scepter],
		$item[spectre scepter],
		$item[spectre scepter],
		$item[spectre scepter],
		$item[spectre scepter],
		$item[spectre scepter],
		$item[spectre scepter],
		$item[spectre scepter],
		$item[spectre scepter],
	};
	int delevelNoStaggerIndex = 0;

	float fractionDone = 1.00;
	int numberOfTurns = 0;
	int statisRounds = 0;
	item tempItem;
	int i = 1; // index, start at 1 to leave room for weaksauce at index 0
	int tempItemIndex;
	boolean didWeaksauce = false;

	float delevellingMultiplier = 1.0;
	if (have_effect($effect[Ruthlessly Efficient]) > 0)
		delevellingMultiplier += 0.5;
	if (equipped_amount($item[dark porquoise ring]) > 0)
		delevellingMultiplier += 1.0;
	if (last_monster() == $monster[Moleman]) // some monsters seem to get less debuffing (recent change?)
		delevellingMultiplier = delevellingMultiplier / 6.0;

	ActionRecord [int] actions;

	// HOA CITATION PAD
	if (have_item($item[HOA citation pad]) && (fractionDone > debuffNeeded || statisRounds < wantedStatisRounds)
		&& (monster_phylum() == $phylum[dude] || monster_phylum() == $phylum[hippy] || monster_phylum() == $phylum[orc])) {
		if (tempItem == $item[none]) {
			tempItemIndex = i;
			actions[i++] = new ActionRecord(false, false, $skill[none], $item[HOA citation pad]);
			tempItem = actions[tempItemIndex].itemToUse;
			numberOfTurns++;
		} else {
			actions[tempItemIndex] = new ActionRecord(false, false, $skill[none], tempItem, $item[HOA citation pad]);
			tempItem = $item[none];
		}
		fractionDone = fractionDone * (1.0 - (0.3 * delevellingMultiplier));
		statisRounds++;
	}

	// MAYOR GHOST'S SCISSORS
	if (have_item($item[Mayor Ghost's scissors]) && (fractionDone > debuffNeeded || statisRounds < wantedStatisRounds)
		&& monster_phylum() == $phylum[undead]) {
		if (tempItem == $item[none]) {
			tempItemIndex = i;
			actions[i++] = new ActionRecord(false, false, $skill[none], $item[Mayor Ghost's scissors]);
			tempItem = actions[tempItemIndex].itemToUse;
			numberOfTurns++;
		} else {
			actions[tempItemIndex] = new ActionRecord(false, false, $skill[none], tempItem, $item[Mayor Ghost's scissors]);
			tempItem = $item[none];
		}
		fractionDone = fractionDone * (1.0 - (0.3 * delevellingMultiplier));
		statisRounds++;
	}

	// DETECT WEAKNESS
	if (have_skill($skill[Detect Weakness]) && (fractionDone > debuffNeeded || statisRounds < wantedStatisRounds)) {
		actions[i++] = new ActionRecord(false, false, $skill[Detect Weakness], $item[none]);
		numberOfTurns++;
		fractionDone = fractionDone * (1.0 - (0.1 * delevellingMultiplier));
		statisRounds++;
	}

	// TIME-SPINNER
	if (have_item($item[time-spinner]) && (fractionDone > debuffNeeded || statisRounds < wantedStatisRounds)) {
		actions[i++] = new ActionRecord(false, false, $skill[none], $item[time-spinner], kDelevelNoStaggerItems[delevelNoStaggerIndex++]);
		numberOfTurns++;
		fractionDone = fractionDone * (1.0 - (0.05 * delevellingMultiplier));
		statisRounds++;
	}

	// LITTLE RED BOOK
	if (have_item($item[little red book]) && (fractionDone > debuffNeeded || statisRounds < wantedStatisRounds)) {
		actions[i++] = new ActionRecord(false, false, $skill[none], $item[little red book], kDelevelNoStaggerItems[delevelNoStaggerIndex++]);
		numberOfTurns++;
		fractionDone = fractionDone * (1.0 - (0.05 * delevellingMultiplier));
		statisRounds++;
	}

	// BOOMBOX
	if (have_skill($skill[Sing Along]) && get_property("boomBoxSong") == "Remainin' Alive" && (fractionDone > debuffNeeded || statisRounds < wantedStatisRounds)) {
		actions[i++] = new ActionRecord(false, false, $skill[Sing Along], $item[none]);
		numberOfTurns++;
		fractionDone = fractionDone * (1.0 - (0.15 * delevellingMultiplier));
		statisRounds++;
	}

	// MICROMETEORITE
	if (have_skill($skill[micrometeorite]) && (fractionDone > debuffNeeded || statisRounds < wantedStatisRounds)) {
		actions[i++] = new ActionRecord(false, false, $skill[micrometeorite], $item[none]);
		numberOfTurns++;
		fractionDone = fractionDone * (1.0 - (micrometerorite_percent() * delevellingMultiplier));
		statisRounds++;
	}

	// WEAKSAUCE check LAST to see how many combat turns we've used debuffing, then insert the actual debuff at the START of the script so we get all those turns of auto-debuffing
	if (have_skill($skill[curse of weaksauce])) { // use CoW no matter what -- if we debuff at all we will need it either because we're not doing enough damage or we need it to hit in the first place
// 	   && (fractionDone > debuffNeeded || statisRounds < wantedStatisRounds || my_class() == $class[Sauceror] || count(actions) >= 1)) { // use weaksauce if we debuffed at all before??? free debuffing seems like a good idea if we need it
		actions[0] = new ActionRecord(false, false, $skill[curse of weaksauce], $item[none]);
		numberOfTurns++;
		statisRounds++;
		didWeaksauce = true;
		rval.repeatingAttackAbsolute += min(monster_attack() * 0.04, 66); // weaksauce debuffs by 4% and caps out at ~66 stats debuffed / turn (contra the wiki)???????????????????????????????
		rval.repeatingDefenseAbsolute += min(monster_defense() * 0.04, 66);
		float weaksauceFraction = min(rval.repeatingAttackAbsolute / monster_attack(), rval.repeatingDefenseAbsolute / monster_defense());
		fractionDone = fractionDone - (weaksauceFraction * delevellingMultiplier * numberOfTurns); // weaksauce will take the same amount each turn, so use MINUS instead of multiplying

		// NON-DELEVELING but staggering for weaksauce -- assuming no further useful items, so fill up funksling hand with a divine item to do damage
		// NASTY-SMELLING MOSS stagger for debuff with weaksauce -- if there's an item to throw left over from above, use that
		if (have_item($item[nasty-smelling moss]) && (fractionDone > debuffNeeded || statisRounds < wantedStatisRounds)) { // stagger for weaksauce
			actions[i++] = new ActionRecord(false, false, $skill[none], $item[nasty-smelling moss], kDelevelNoStaggerItems[delevelNoStaggerIndex++]);
			numberOfTurns++;
			fractionDone = fractionDone - (weaksauceFraction * delevellingMultiplier); // weaksauce will take the same amount each turn, so use MINUS instead of multiplying
			statisRounds++;
		}
		// ENTANGLING NOODLES
		if (my_class() != $class[pastamancer] && (fractionDone > debuffNeeded || statisRounds < wantedStatisRounds)) { // if we're not going to use it for stunning, use it for debuff with weaksauce due to staggering
			actions[i++] = new ActionRecord(false, false, $skill[Entangling Noodles], $item[none]);
			numberOfTurns++;
			fractionDone = fractionDone - (weaksauceFraction * delevellingMultiplier); // weaksauce will take the same amount each turn, so use MINUS instead of multiplying
			statisRounds++;
		}
		// SILENT knife stagger for debuff with weaksauce
		if (fractionDone > debuffNeeded || statisRounds < wantedStatisRounds) {
			actions[i++] = new ActionRecord(false, false, $skill[Silent Knife], $item[none]);
			numberOfTurns++;
			fractionDone = fractionDone - (weaksauceFraction * delevellingMultiplier); // weaksauce will take the same amount each turn, so use MINUS instead of multiplying
			statisRounds++;
		}
		// SILENT skill stagger for debuff with weaksauce TODO figure best one ----- DOESN'T STAGGER?
		if (fractionDone > debuffNeeded || statisRounds < wantedStatisRounds) {
// 			if (equipped_item($slot[weapon]).type == "knife" || )
			actions[i++] = new ActionRecord(false, false, $skill[Silent Slice], $item[none]);
			numberOfTurns++;
			fractionDone = fractionDone - (weaksauceFraction * delevellingMultiplier); // weaksauce will take the same amount each turn, so use MINUS instead of multiplying
			statisRounds++;
		}

		// CHEAPEST STAGGER ITEM
		if (fractionDone > debuffNeeded || statisRounds < wantedStatisRounds) { // stagger for weaksauce
			item [] kStaggerItems = {
				$item[Battlie Light Saver],
				$item[big boom],
				$item[dwarf bread],
				$item[ear poison],
				$item[extremely confusing manual],
				$item[gob of wet hair],
				$item[gyroscope],
				$item[jar full of wind],
				$item[Junk-Bond],
				$item[hemp net],
				$item[palm-frond net],
				$item[shard of double-ice],
				$item[superamplified boom box],
				$item[tongue depressor],
			};
			sort kStaggerItems by historical_price(value);
			item cheapestStaggerItem = kStaggerItems[0];
			actions[i++] = new ActionRecord(false, false, $skill[none], cheapestStaggerItem, kDelevelNoStaggerItems[delevelNoStaggerIndex++]);
			numberOfTurns++;
			fractionDone = fractionDone - (weaksauceFraction * delevellingMultiplier); // weaksauce will take the same amount each turn, so use MINUS instead of multiplying
			statisRounds++;
		}
	}

	// NO STAGGER things, so we only do it if it will put us over the threshold we need
	float potentialfractionDone = fractionDone * (1.0 - (0.3 * delevellingMultiplier));
	if (have_item($item[Great Wolf's lice]) && monster_phylum() == $phylum[beast] && (fractionDone > debuffNeeded && potentialfractionDone < debuffNeeded)) {
		actions[i++] = new ActionRecord(false, false, $skill[none], $item[Great Wolf's lice]);
		numberOfTurns++;
		fractionDone = potentialfractionDone;
	}
	potentialfractionDone = fractionDone * (1.0 - (0.3 * delevellingMultiplier));
	if (have_item($item[Great Wolf's lice]) && monster_phylum() == $phylum[beast] && (fractionDone > debuffNeeded && potentialfractionDone < debuffNeeded)) {
		actions[i++] = new ActionRecord(false, false, $skill[none], $item[Great Wolf's lice]);
		numberOfTurns++;
		fractionDone = potentialfractionDone;
	}

	// COST ITEMS
// 	if (have_item($item[crayon shavings]) && fractionDone > debuffNeeded) {
// 		if (tempItem == $item[none]) {
// 			tempItemIndex = i;
// 			actions[i++] = new ActionRecord(false, false, $skill[none], $item[crayon shavings]);
// 			tempItem = actions[tempItemIndex].itemToUse;
// 			numberOfTurns++;
// 		} else {
// 			actions[tempItemIndex] = new ActionRecord(false, false, $skill[none], tempItem, $item[crayon shavings]);
// 			tempItem = $item[none];
// 		}
// 		fractionDone = fractionDone * (1.0 - (0.3 * delevellingMultiplier));
// 	}
// 	if (item_amount($item[crayon shavings]) > 1 && fractionDone > debuffNeeded) {
// 		if (tempItem == $item[none]) {
// 			tempItemIndex = i;
// 			actions[i++] = new ActionRecord(false, false, $skill[none], $item[crayon shavings]);
// 			tempItem = actions[tempItemIndex].itemToUse;
// 			numberOfTurns++;
// 		} else {
// 			actions[tempItemIndex] = new ActionRecord(false, false, $skill[none], tempItem, $item[crayon shavings]);
// 			tempItem = $item[none];
// 		}
// 		fractionDone = fractionDone * (1.0 - (0.3 * delevellingMultiplier));
// 	}
// 	if (have_item($item[jam band bootleg]) && fractionDone > debuffNeeded) {
// 		if (tempItem == $item[none]) {
// 			tempItemIndex = i;
// 			actions[i++] = new ActionRecord(false, false, $skill[none], $item[jam band bootleg]);
// 			tempItem = actions[tempItemIndex].itemToUse;
// 			numberOfTurns++;
// 		} else {
// 			actions[tempItemIndex] = new ActionRecord(false, false, $skill[none], tempItem, $item[jam band bootleg]);
// 			tempItem = $item[none];
// 		}
// 		fractionDone = fractionDone * (1.0 - (0.5 * delevellingMultiplier));
// 	}
// 	if (item_amount($item[jam band bootleg]) > 1 && fractionDone > debuffNeeded) {
// 		if (tempItem == $item[none]) {
// 			tempItemIndex = i;
// 			actions[i++] = new ActionRecord(false, false, $skill[none], $item[jam band bootleg]);
// 			tempItem = actions[tempItemIndex].itemToUse;
// 			numberOfTurns++;
// 		} else {
// 			actions[tempItemIndex] = new ActionRecord(false, false, $skill[none], tempItem, $item[jam band bootleg]);
// 			tempItem = $item[none];
// 		}
// 		fractionDone = fractionDone * (1.0 - (0.5 * delevellingMultiplier));
// 	}
// 	if (have_item($item[electronics kit]) && fractionDone > debuffNeeded) {
// 		if (tempItem == $item[none]) {
// 			tempItemIndex = i;
// 			actions[i++] = new ActionRecord(false, false, $skill[none], $item[electronics kit]);
// 			tempItem = actions[tempItemIndex].itemToUse;
// 			numberOfTurns++;
// 		} else {
// 			actions[tempItemIndex] = new ActionRecord(false, false, $skill[none], tempItem, $item[electronics kit]);
// 			tempItem = $item[none];
// 		}
// 		fractionDone = fractionDone * (1.0 - (0.25 * delevellingMultiplier));
// 	}
// 	if (item_amount($item[electronics kit]) > 1 && fractionDone > debuffNeeded) {
// 		if (tempItem == $item[none]) {
// 			tempItemIndex = i;
// 			actions[i++] = new ActionRecord(false, false, $skill[none], $item[electronics kit]);
// 			tempItem = actions[tempItemIndex].itemToUse;
// 			numberOfTurns++;
// 		} else {
// 			actions[tempItemIndex] = new ActionRecord(false, false, $skill[none], tempItem, $item[electronics kit]);
// 			tempItem = $item[none];
// 		}
// 		fractionDone = fractionDone * (1.0 - (0.25 * delevellingMultiplier));
// 	}

	print("expected fraction: " + fractionDone + " for script: '" + macroForActions(actions) + "'", "blue");

	rval.expectedAttackFraction = fractionDone;
	rval.expectedDefenseFraction = fractionDone;
	rval.actions = actions;
	return rval;
// 	return new DebuffMonsterRecord(fractionDone, fractionDone, actions);
}


// TODO add survivable rounds to debuff needed
DebuffMonsterRecord debuffMonsterRecords(int wantedStatisRounds) {
	float monsterAttackDebuffNeededFraction = monsterAttackDebuffNeededFraction();
	float monsterDefenseDebuffNeededFraction = monsterDefenseDebuffNeededFraction();

	print("fraction to always defend: " + monsterAttackDebuffNeededFraction + ", buffed moxie: " + my_buffedstat($stat[moxie]) + ", monster attack + 10: " + (monster_attack() + 10.0), "blue");
	print("fraction to always hit: " + monsterDefenseDebuffNeededFraction + ", buffed attack stat: " + my_buffedstat(attackStat()) + ", monster defense + 5: " + (monster_defense() + 5.0), "blue");

	return debuffMonsterRecords(monsterAttackDebuffNeededFraction, monsterDefenseDebuffNeededFraction, wantedStatisRounds);
}


// returns the debuff to the monster's attack at the given round given dmr
// only returns sensible values if atRound is after dmr.roundsTaken
float attackDebuffAtRoundAsFraction(DebuffMonsterRecord dmr, int atRound) {
	if (atRound <= dmr.roundsTaken)
		return dmr.expectedAttackFraction;

	int extraRounds = atRound - dmr.roundsTaken;
	float absoluteFraction = dmr.repeatingAttackAbsolute / gkMonsterOriginalAttack;

	// not a perfect simulation, but should be close enough
	return max(dmr.expectedAttackFraction - (absoluteFraction * extraRounds), 0) * (dmr.repeatingAttackFraction ** extraRounds);
}

// returns the debuff to the monster's defense at the given round given dmr
// only returns sensible values if atRound is after dmr.roundsTaken
float defenseDebuffAtRoundAsFraction(DebuffMonsterRecord dmr, int atRound) {
	if (atRound <= dmr.roundsTaken)
		return dmr.expectedDefenseFraction;

	int extraRounds = atRound - dmr.roundsTaken;
	float absoluteFraction = dmr.repeatingDefenseAbsolute / gkMonsterOriginalDefense;

	// not a perfect simulation, but should be close enough
	return max(dmr.expectedDefenseFraction - (absoluteFraction * extraRounds), 0) * (dmr.repeatingDefenseFraction ** extraRounds);
}


// returns the simulated number of turns before we are safe from the monster's attacks given the actions taken in dmr
int roundsBeforeDefend(DebuffMonsterRecord dmr, monster foe) {
	float monsterAttackDebuffNeededFraction = monsterAttackDebuffNeededFraction();

	if (monsterAttackDebuffNeededFraction >= dmr.expectedAttackFraction)
		return dmr.roundsTaken;

	for aRound from dmr.roundsTaken to maxRounds(foe) {
		if (attackDebuffAtRoundAsFraction(dmr, aRound) <= monsterAttackDebuffNeededFraction)
			return aRound;
	}

	return maxRounds(foe);
}

// returns the simulated number of turns before we can hit given the actions taken in dmr
int roundsBeforeHit(DebuffMonsterRecord dmr, monster foe) {
	float monsterDefenseDebuffNeededFraction = monsterDefenseDebuffNeededFraction();

	if (monsterDefenseDebuffNeededFraction >= dmr.expectedDefenseFraction)
		return dmr.roundsTaken;

	for aRound from dmr.roundsTaken to maxRounds(foe) {
		if (defenseDebuffAtRoundAsFraction(dmr, aRound) <= monsterDefenseDebuffNeededFraction)
			return aRound;
	}

	return maxRounds(foe);
}

// similar to will_usually_miss() but returns true if we can ALWAYS hit the monster
// uses attackStat() which wraps current_hit_stat() to consider the Cosplay sabre.
boolean willAlwaysHit() {
	return my_buffedstat(attackStat()) >= (monster_defense() + 5.0) || equipped_amount($item[June cleaver]) >= 1;
}


boolean willHitInTime(DebuffMonsterRecord dmr, monster foe) {
	int roundsBeforeHit = roundsBeforeHit(dmr, foe);
	if (roundsBeforeHit >= 15)
		return false;
	return true;
}


// true if we should attack this monster, i.e. if we can hit and do enough damage to kill it while staying alive ourselves
boolean shouldAttack(monster foe, DebuffMonsterRecord dmr, int monsterHP) {
// 	int expectedDmgDone = expectedDamageDone($skill[none]); // none = attack
// 	if (expectedDmgDone > monster_hp() * 1.25)
// 		return true;
// 
	// if debuffing takes too long, don't attack
	if (!willHitInTime(dmr, foe)) {
		print("shouldAttack: false, will take so many rds to debuff to the point we can't attack successfully!", "green");
		return false;
	}

	// if debuffing takes more rounds than we have available, don't attack
	// assumes 5 rounds for attacking
	if (count(dmr.actions) + 5 >= 25) {
		print("shouldAttack: false, debuffing will not leave us enough time to kill!", "green");
		return false;
	}

	// if debuffing takes longer than we can survive, don't attack
	int roundsBeforeDefend = roundsBeforeDefend(dmr, foe);
	int safeExpectedDamageTaken = safeExpectedDamageTaken(foe);
	if (roundsBeforeDefend * safeExpectedDamageTaken > my_hp()) { // if we're debuffing, this amount will go down over rds, so don't include any more safety factor
		print("shouldAttack: false, we'll die while debuffing!", "green");
		return false;
	}

	// if we can't stagger, we can't really debuff safely and we have to be able to kill fast
	if (!canStagger(foe) && safeExpectedDamageTaken * 10 > my_hp()) {
		print("shouldAttack: false, can't stagger and taking too much damage to withstand during debuffing", "green");
		return false;
	}

	// if foe's physical resistance is too high, don't attack
	if ((foe.physical_resistance > 50 && buffed_hit_stat() < 3 * foe.base_defense) // can we overwhelm resistance with 3 times the required stat???????????????????????????????
		|| foe.physical_resistance > 75) {
		print("shouldAttack: false, foe physical resistance " + foe.physical_resistance + ", which is > 50!", "green");
		return false;
	}

	return true;
}


// return the default attack
// the basic idea is that any monster susceptible to attacks should be attacked unless they do
// too much damage or if they don't take physical damage.
// most monsters are susceptible to attack, even if their stats are much higher
ActionRecord defaultAttack(monster foe, int monsterHP) { // #defaultAction
	ActionRecord theAction;
	DebuffMonsterRecord dmr = debuffMonsterRecords(0);
	boolean shouldAttack = shouldAttack(foe, dmr, monsterHP);

	// NORMAL HOBO special override because we don't want too much overdamage to normal hobos
	if (foe == $monster[Normal hobo])
		theAction.skillToUse = $skill[Saucestorm];

	// DRIPPY MONSTER drippy monsters only susceptible to attacks
	else if (foe == $monster[drippy tree] || foe == $monster[drippy bat] || foe == $monster[drippy reveler])
		theAction.attack = true;

	// SAUCEROR saucerors gain MP from overkilling with Curse of Weaksauce
	else if (my_class() == $class[Sauceror] && my_mp() >= mp_cost($skill[Saucegeyser]))
		theAction.skillToUse = $skill[Saucegeyser];

	// PIG SKINNER every 25 turns, use a Free-for-all for a free kill
	else if (my_class() == $class[Pig Skinner] && foe != $monster[sausage goblin]
		&& !foe.boss && have_effect($effect[Everything Looks Red]) == 0 && my_mp() >= mp_cost($skill[Free-for-all])
		&& !(gkNoInstaKillMonsters contains foe)) {
		theAction.skillToUse = $skill[Free-for-all];

	// CANNOT DEBUFF ENOUGH OR PHYSICAL RES TOO HIGH
	} else if (!shouldAttack) {
		print("recommending escalation immediately", "orange");
		theAction.skillToUse = $skill[Saucestorm];

		// will saucestorm take too many rounds, irrespective of the foe's attack/defence -- typically not mana efficient
		if (expectedRoundsToKill(foe, monsterHP, theAction) > 4)
			theAction.skillToUse = $skill[Saucegeyser];

		// these elements will 1/2 our damage, but should be incorporated into other calcs??
// 		if (foe.monster_element() == $element[cold] || foe.monster_element() == $element[hot])
// 			theAction.skillToUse = $skill[Saucegeyser];

		if (!willKillBeforeDying(foe, monsterHP, theAction) || !willKillBeforeTimeout(foe, monsterHP, theAction))
			theAction.skillToUse = $skill[Saucegeyser];

		int expectedRds = expectedRoundsToKill(foe, monsterHP, theAction);
		if (my_mp() < (mp_cost(theAction.skillToUse) * expectedRds))
			abort("we'd like to escalate to " + theAction.skillToUse + " but we don't have enough mp!");

	// WEAPON OF THE PASTALORD ???
// 	} else if (foe.physical_resistance > 80 && my_mp() >= mp_cost($skill[Weapon of the Pastalord])) {
// 		print("recommending escalation to Weapon of the Pastalord immediately", "blue");
// 		theAction.skillToUse = $skill[Weapon of the Pastalord];

	// STAR STARFISH
	} else if (wantToStasis()) { // if everything looks good and we've got a starfish, do minimal dmg to maximize mp regen
		print("star starfish technique!", "blue");
		theAction.itemToUse = $item[seal tooth];

	// if we have a bunch of Arr, M80s, use those up
	} else if (item_amount($item[Arr, M80]) >= 50
		&& foe.monster_element() != $element[hot]
		&& monsterHP <= (50 * 2 * 15)) { // Arr, M80s do ~50 hot dmg avg and drop items worth more than an Arr, M80(?)
		checkIfRunningOut($item[Arr, M80], 10000);
		theAction.itemToUse = $item[Arr, M80];
		theAction.item2ToUse = $item[Arr, M80];

	// if we're a TT, try out the Kneebutt
	} else if (my_class() == $class[turtle tamer]) {
		if (expected_damage() < monsterHP && safeExpectedDamageTaken(foe) > (my_maxhp() / 25) && mp_cost($skill[Kneebutt]) < my_mp()) // TODO if we take more damage than we heal
			theAction.skillToUse = $skill[Kneebutt];
		else
			theAction.attack = true;

	// DEFAULT
	} else {
		theAction.attack = true;
	}

	if (theAction.skillToUse != $skill[none] && mp_cost(theAction.skillToUse) > my_mp())
		abort("not enough mp to use default attack " + macroForAction(theAction));

	return theAction;
}



boolean doingEnoughDamage(monster foe, int currentMonHp, int damageDone) {
	int expectedRounds = ceil(currentMonHp / to_float(damageDone));
	int roundsRemaining = maxRounds(foe) - current_round();
	print("expecting to take " + expected_damage() + " damage (or " + safeExpectedDamageTaken() + " with the safety margin) per round. rounds remaining: " + roundsRemaining, "green");

	// SAFE FIGHT
	if (expectedRounds < roundsRemaining // doing enough damage
		&& (my_hp() / 2) > safeExpectedDamageTaken() * (expectedRounds - 1)) // and not taking too much damage -- never want to take more than 1/2 hp in a fight TODO figure the amount of hp we're regaining?
		return true;

	// ONE HIT KILL
	if (damageDone > currentMonHp)
		return true;

	return false;
}



// true if we should try to debuff this monster for melee/ranged
// false when debuffing would not be profitable, either because we can't debuff enough, 
// we don't need to debuff, 
boolean shouldDebuff(monster foe, DebuffMonsterRecord dmr, int monsterHP) {
	print("willAlwaysHit: " + willAlwaysHit() + ", will_usually_dodge " + will_usually_dodge() + ", safeExpectedDamageTaken: " + safeExpectedDamageTaken(), "blue");
	int expectedDamageDone = expectedDamageDone(new ActionRecord(true), foe);

	// if we're not going to attack, we shouldn't debuff
	// captures a lot of the logic that used to be in this function (via shouldAttack())
	if (!defaultAttack(foe, monsterHP).attack) {
		print("shouldDebuff: false, we're not attacking", "green");
		return false;
	}

	// if we're attacking and we won't do enough damage by default, debuff
	if (!doingEnoughDamage(foe, monsterHP, expectedDamageDone)) {
		print("shouldDebuff: true, we're not doing enough damage", "green");
		return true;
	}

	// if we're already always hitting, no need to debuff
	if (willAlwaysHit()) {
		print("shouldDebuff: false, we're always hitting", "green");
		return false;
	}

	return true;
}

// the fraction of the monster's defense that needs to remain before an attack would be successful
float fractionNeededToSuccessfullyAttack() {
	return my_buffedstat(attackStat()) / (monster_defense() + 5.0);
}

boolean isDebuffEnoughToHit(float defFraction) {
	return defFraction <= fractionNeededToSuccessfullyAttack();
}

boolean isDebuffEnoughToDefend(float offFraction) {
	float fractionNeededToSuccessfullyDefend = my_buffedstat($stat[moxie]) / (monster_attack() + 10.0); // the fraction of the monster's attack that needs to remain before a miss is guaranteed

	return offFraction <= fractionNeededToSuccessfullyDefend;
}

// true if the given debuffs will debuff enough to hit before the combat times out
boolean debuffsEnough(DebuffMonsterRecord dmr, monster foe) {
	int damageTakenBeforeCanHit = roundsBeforeHit(dmr, foe) * safeExpectedDamageTaken();
// 	print("weaksauceTurnsUntilHit: " + weaksauceTurnsUntilHit(dmr.expectedDefenseFraction) + ", damageTakenBeforeCanHit: " + damageTakenBeforeCanHit, "blue");
// 	return isDebuffEnoughToHit(defFraction) && isDebuffEnoughToDefend(offFraction);
	return (isDebuffEnoughToHit(dmr.expectedDefenseFraction) && isDebuffEnoughToDefend(dmr.expectedAttackFraction)) || (damageTakenBeforeCanHit < my_hp() && damageTakenBeforeCanHit < my_maxhp() * 0.4);
}



boolean canLatte() {
	if (!to_boolean(get_property("_latteDrinkUsed")) && equipped_amount($item[latte lovers member's mug]) > 0) {
		return true;
	}
	return false;
}

// use the latte lover's mug whenever we'd get all the MP gain or when we need the HP to avoid dying
boolean checkLatte() {
	if (canLatte() && ((my_hp() <= safeExpectedDamageTaken()) || (my_mp() < my_maxmp() / 2))) {
		use_skill($skill[Gulp Latte]);
		return true;
	}
	return false;
}



// returns a string with a conditional that returns true iff the monster we're fighting is one from the given location
string isMonsterFromLocationScript(location aLocation, string conditionalFunction) {
	string rval;
	float [monster] monsterMap = appearance_rates(aLocation);
	foreach m in monsterMap {
		string monsterName = m;
		string [int] monsterSplit = split_string(monsterName, " \\(");
		monsterName = monsterSplit[0];
		if (count(monsterSplit) != 1)
			monsterName += "*";
// 		print("monster: " + m + ", changed to: " + monsterName, "blue");

		boolean conditional = (conditionalFunction == "") ? true : call boolean conditionalFunction(m);
		if (m != $monster[none] && conditional)
			rval = rval.joinString("monstername " + monsterName, " || ");
	}
	return rval;
}


// returns a string with a conditional that returns true iff the monster we're fighting is one from the given location
string isMonsterFromLocationScript(location aLocation) {
	return isMonsterFromLocationScript(aLocation, "");
}



// return aborts script
string setupAborts(monster foe) {
	string rval;

	AbortRecord ar = defaultAborts(foe);

	if (ar.missed > 0)
		rval += "abort missed " + ar.missed + ";";
	if (ar.pastround > 0)
		rval += "abort pastround " + ar.pastround + ";";
	if (ar.hpbelow > 0 && my_maxhp() > ar.hpbelow) // TODO check if macro language can do this: abort my_maxhp() > ar.hpbelow || hpbelow X;
		rval += "abort hpbelow " + ar.hpbelow + ";";
	if (ar.hppercentbelow > 0)
		rval += "abort hppercentbelow " + ar.hppercentbelow + ";";
	if (ar.mpbelow > 0)
		rval += "abort mpbelow " + ar.mpbelow + ";";

	if (wantToStasis())
		rval += "abort (!mppercentbelow 100);";

	return rval;
}



// mafia may not capture the new monster's stats correctly
// do something to update mafia's knowledge of the stats, which will allow
// the consult script to calculate things properly
string resyncMonsterStats() {
	print("REFRESH!", "orange");
	return visit_url("/fight.php", true, false);

// 	if (scriptString != "" && scriptString != setupAborts(foe)) {
// 		// if we're pickpocketing or something else, that will suffice
// 	} else { // otherwise do some kind of default action
// 		if (inRonin())
// 			scriptString += macroForAction(defaultAttack(foe)); // means we're doing the default action twice -- TODO figure something else to do?
// 		else {
// 			if (my_hp() < 200)
// 				scriptString += "skill Silent Treatment;";
// 			else
// 				scriptString += "skill Blood Bucatini;";
// 		}
// 	}
// 	gAccumulatedResponse += executeScript(scriptString);
// 	scriptString = "";
}



// -------------------------------------
// CONSULT
//
// Each function will execute what it needs to and pass the rest
// back in a string to be executed later. Ideally everything will be passed back and all the
// script can be executed at once, but sometimes the script may need to execute to determine
// the results before it can proceed. All functions can return the empty string if they
// executed everything.
// -------------------------------------


// set up aborts and other defines and check for overriding behaviours like Disintegrate
string startFight(monster foe) {
	print("startFight");
	string scriptString = "";

	if (!inRonin()) {
		// YELLOW RAY swarm of scarab beatles
		if (item_amount($item[Yellow Rocket]) > 0 && have_effect($effect[Everything Looks Yellow]) == 0) {
			if (foe == $monster[swarm of scarab beatles]) {
				// don't need to pickpocket, Disintegrate will get it all
// 				use_skill($skill[Disintegrate]);
				throw_item($item[Yellow Rocket]);
				exit;
			}
		}
	}

	scriptString = setupAborts(foe);

	return scriptString;
}



string doDebuff(monster foe, int monsterHP, string scriptSoFar) {
	print("doDebuff");
	string scriptString = scriptSoFar;

	// water balloon
// 	scriptString += "use water balloon;";
	int statisRounds = 0;

	DebuffMonsterRecord dmr = debuffMonsterRecords(statisRounds);

	if (shouldAttack(foe, dmr, monsterHP) || statisRounds > 0) {
		// might not want to debuff even if we're attacking -- we're always hitting, for example
		if (shouldDebuff(foe, dmr, monsterHP) || statisRounds > 0) {
			print("we want to statis for " + statisRounds, "blue");
			scriptString += macroForActions(dmr.actions);

		// if we don't debuff, Sauceror won't have cast Curse of Weaksauce, which we want
		} else if (my_class() == $class[Sauceror])
			scriptString += "skill Curse of Weaksauce;";
	}

	return scriptString;
}


string doPickpocket(monster foe, int monsterHP, string scriptSoFar) {
	print("doPickpocket, round: " + current_round());
	string scriptString = scriptSoFar;

	// PICKPOCKET
	if (pickpocketable(foe) && current_round() <= 1) {
		if (my_class() == $class[disco bandit] || my_class() == $class[accordion thief]
			|| equipped_amount($item[tiny black hole]) > 0 || equipped_amount($item[mime army infiltration glove]) > 0) {
			scriptString += "pickpocket;";
		}
	}
	if (pickpocketable(foe) && my_class() == $class[disco bandit] && is_wearing_outfit("Bling of the New Wave"))
		scriptString += "pickpocket;";

	return scriptString;
}



// pickpocketing and debuffing are together because we have to pickpocket first but
// we'd like to debuff before trying any potential Disco Combo
string doPickpocketAndDebuff(monster foe, int monsterHP, string scriptSoFar) {
	print("doPickpocketAndDebuff");

	// PICKPOCKET
	string scriptString = scriptSoFar;
	scriptString = doPickpocket(foe, monsterHP, scriptString);

	// WORKAROUND: KoL stats are not consistent with reality until we interact with the monster -- do that here before we get to the main debuff calculations
	string pageString = resyncMonsterStats();

	// DEBUFF
	scriptString = doDebuff(foe, real_monster_hp(pageString), scriptString);

	return scriptString;
}



string doClassStun(monster foe, int monsterHP, string scriptSoFar) {
	print("doClassStun");
	skill stunSkill = stun_skill();
	boolean shouldUseStunSkill = have_skill(stunSkill);

	if (stunSkill == $skill[Accordion Bash] && !atAccordionEquipped())
		shouldUseStunSkill = false;
	if (safeExpectedDamageTaken() < my_maxhp() * 0.05 || expectedDamageDone(defaultAttack(foe, monsterHP), foe) > monsterHP)
		shouldUseStunSkill = false;
	if (my_class() == $class[sauceror] && my_soulsauce() < 5)
		shouldUseStunSkill = false;
// 	if (my_class() == $class[turtle tamer] && !(have_effect($effect[Blessing of the Storm Tortoise]) > 0 || have_effect($effect[Grand Blessing of the Storm Tortoise]) > 0 || have_effect($effect[Glorious Blessing of the Storm Tortoise]) > 0))
// 		shouldUseStunSkill = false;
	if (monster_level_adjustment() >= 100)
		shouldUseStunSkill = false;

	if (shouldUseStunSkill)
		return scriptSoFar + "skill " + stunSkill + ";";
	else
		return scriptSoFar;
}



string doOlfaction(monster foe, string scriptSoFar) {
	print("doOlfaction");
	int manaRequired = 0;
	if (to_monster(get_property("olfactedMonster")) != foe && my_mp() > manaRequired + 40 && have_skill($skill[Transcendent Olfaction])) {
		scriptSoFar += "skill Transcendent Olfaction;";
		manaRequired += 40;
	}
	if (to_monster(get_property("_gallapagosMonster")) != foe && my_mp() > manaRequired + 30 && have_skill($skill[Gallapagosian Mating Call])) {
		scriptSoFar += "skill Gallapagosian Mating Call;";
		manaRequired += 30;
	}
	if (to_monster(get_property("_latteMonster")) != foe && have_skill($skill[Offer Latte to Opponent]))
		scriptSoFar += "skill Offer Latte to Opponent;";
	if (to_monster(get_property("mokeyPointMonster")) != foe && have_skill($skill[Monkey Point]))
		scriptSoFar += "skill Monkey Point;";
	return scriptSoFar;
}



// assumes the class stun is either done or not needed
string doItemsAndBuffs(monster foe, int monsterHP, string scriptSoFar) {
	print("doItemsAndBuffs");
	string scriptString = scriptSoFar;
	boolean canStagger = canStagger(foe);

	if (my_familiar() == $familiar[space jellyfish])
		scriptString += "skill extract jelly;";

	if (get_property("_feelPrideUsed").to_int() < 3 && equipped_amount($item[makeshift garbage shirt]) > 0
		&& monsterHP >= 625) // any high-xp monster will do
		scriptString += "skill Feel Pride;";

	if ("_feelNostalgicUsed".get_property().to_int() < 3) {
		// FEEL NOSTALGIC -- if we set it manually, do it here
		if (kNostalgiaNextCombatKey.get_property().to_boolean()) {
			scriptString += "skill Feel Nostalgic;";
			kNostalgiaNextCombatKey.set_property("false");
		} else {
			// FEEL NOSTALGIC if the current monster is not the same as last monster and last monster is worth it
			monster nosMon = get_property("feelNostalgicMonster").to_monster();
			int nosMonValue = monsterCurrentItemMeatValue(nosMon);
			if (nosMon != $monster[none] && foe != nosMon && nosMonValue > kTurnValue * 10) {
				print("feeling nostagic for " + nosMon + ", valued at " + nosMonValue, "blue");
				scriptString += "skill feel nostalgic;";
			}
		}
	}

	// SPIKOLODON
	if (kSpikolodonNextCombatKey.get_property().to_boolean()) {
		scriptString += "skill Launch spikolodon spikes;";
		kSpikolodonNextCombatKey.set_property("false");
	}

	// SING ALONG
	boolean shouldSingAlongWithBoomboxStats = get_property("boomBoxSong") == "Eye of the Giger" && canStagger;
	boolean shouldSingAlongWithBoomboxSpell = get_property("boomBoxSong") == "Food Vibrations" && defaultAttack(foe, monsterHP).skillToUse != $skill[none] && canStagger;
	boolean shouldSingAlongWithBoomboxMeat = get_property("boomBoxSong") == "Total Eclipse of Your Meat" && foe.min_meat > 0;
	if (have_skill($skill[sing along])
		&& (shouldSingAlongWithBoomboxStats || shouldSingAlongWithBoomboxSpell || shouldSingAlongWithBoomboxMeat))
		scriptString += "skill sing along;";

	// NEW HABIT
	if (have_skill($skill[a new habit]))
		scriptString += "skill a new habit;";

	// BROKEN CHAMPAGNE BOTTLE: maximum item!
	if (equipped_amount($item[broken champagne bottle]) >= 1) {
		if (equipped_amount($item[vampyric cloake]) >= 1 && to_int(get_property("_vampyreCloakeFormUses")) < 10) scriptString += "skill Become a bat;";
		if (equipped_amount($item[Lil' Doctor&trade; bag]) >= 1 && to_int(get_property("_otoscopeUsed")) < 3) scriptString += "skill Otoscope;";
		if (my_familiar() == $familiar[Pocket Professor]) scriptString += "if hasskill Lecture on mass;skill Lecture on mass;endif;";
		if (get_property("_hoboUnderlingSummons").to_int() < 5 && is_wearing_outfit("Hodgman's Regal Frippery")) scriptString += "skill Ask the hobo to dance for you;";

	// things that we only want to do when NOT wearing the champagne bottle
	} else {
		if (my_familiar() == $familiar[Pocket Professor] && monster_hp(foe) >= 625) scriptString += "if hasskill deliver your thesis!;skill deliver your thesis!;endif;";
	}

	if ((have_item($item[cosmic bowling ball]) || have_skill($skill[Bowl Straight Up]))
		&& have_effect($effect[Cosmic Ball in the Air]) < 1000)
		scriptString += "skill Bowl Straight Up;";

	// DRESSUP SELECTOR: item
	if (get_property(kDressupSelectorKey).contains_text("item")) {
	}

	// BIG BOOK OF PIRATE INSULTS for pirates TODO only if we need it
	if (monster_phylum(foe) == $phylum[pirate]) {
		if (have_item($item[The Big Book of Pirate Insults]))
			scriptString += "use big book of pirate insults;";
		else {
			print("wanted to insult a pirate but don't have the book!", "red");
			waitq(10);
		}
	}

	// order is stun, olfaction, items, so do the stagger-able items last to get as many rounds of stun as possible
	if (canStagger) {
		if (have_item($item[beehive]) && have_item($item[rock band flyers])) scriptString += "use rock band flyers, beehive;";
		else if (have_item($item[time-spinner]) && have_item($item[rock band flyers])) scriptString += "use rock band flyers, time-spinner;";
		else if (have_item($item[beehive])) scriptString += "use beehive;";
		else if (have_item($item[rock band flyers])) scriptString += "use rock band flyers;";

		if (my_mp() / my_maxmp() <= 0.6 && equipped_amount($item[latte lovers member's mug]) >= 1 && !to_boolean(get_property("_latteDrinkUsed")))
			scriptString += "skill Gulp Latte;";
	}

	// SIGNAL FRAGMENT PUZZLE https://kol.coldfront.net/thekolwiki/index.php/Signal_fragment_puzzle
	if (!inRonin()) {
		item tempItem;
		switch(my_location()) {
			case $location[Anemone Mine]:
			case $location[The Dive Bar]:
			case $location[The Marinara Trench]:
				tempItem = $item[New Age hurting crystal];
				break;

			case $location[The Hole in the Sky]:
				tempItem = $item[superamplified boom box];
				break;

			case $location[The Valley of Rof L'm Fao]:
				if (foe == $monster[rampaging adding machine])
					tempItem = $item[short calculator];
				break;

			case $location[The Bubblin' Caldera]:
				tempItem = $item[PADL Phone];
				break;

			case $location[The Ice Hotel]:
				tempItem = $item[photoprotoneutron torpedo];
				break;
		}
		if (tempItem != $item[none]) {
			checkIfRunningOut(tempItem, 500);
			int times = min(11, item_amount(tempItem) / 2);
			if (times > 0)
				scriptString += "mark IaB;if !times " + times + ";use " + tempItem + ", " + tempItem + ";goto IaB;endif;";
		}
	}

	// PRO SKATEBOARD -- doubles drops
	if (equipped_amount($item[pro skateboard]) >= 1)
		scriptString += "skill Do an epic McTwist!;";

	// SUBURBS OF DIS
	if (appearance_rates($location[The Glacier of Jerks], false) contains foe)
		scriptString += "skill Tattle;";
	//if (appearance_rates($location[The Clumsiness Grove], false) contains foe)
	//	scriptString += "skill Tormet Plant;";
	//if (appearance_rates($location[The Maelstrom of Lovers], false) contains foe)
	//	scriptString += "skill Pinch Ghost;";

	// MP RESTORE -- BLUE ROCKET
	if (!inRonin() && have_effect($effect[Everything Looks Blue]) <= 0)
		scriptString += "use blue rocket;";

	// SILENT TREATMENT this is strictly a debuff but do here to take advantage of a possible stun
	if (!inRonin() && !foe.boss && (foe.physical_resistance >= 66.0 && bestElementalResistance(foe) >= 66.0)
		&& my_buffedstat(my_primestat()) < monster_defense() * 1.33  // if we have that much stat advantage, we probably don't need to worry about resistance(?)
		&& defaultAttack(foe, monster_hp()).attack) // only do it if we're going to try to debuff and attack
		scriptString += "skill Silent Treatment;";

	// identify POTIONS OF DOOM #potion of doom #dungeon of doom #dungeons of doom #dod #pod
	if (!potionsOfDoomIdentified()) {
		print("*** identifying Potions of Doom ***", "blue");
		item [int] sortedPots;
		int idx;

		foreach it in $items[bubbly potion, cloudy potion, dark potion, effervescent potion, fizzy potion, milky potion, murky potion, smoky potion, swirly potion]
			sortedPots[idx++] = it;
		sort sortedPots by current_price(value);

		// this will (deliberately) not use the most expensive item since it is automatically discovered based on the other ones
		boolean firstHandFull = false;
		item firstHandItem = $item[none];
		foreach i, it in sortedPots {
			// skip this potion if we already have it (could happen with auto-damage that kills a monster before using all the potions)
			if (get_property("lastBangPotion" + it.to_int()) != "")
				continue;

			if (firstHandFull) {
				scriptString += "use " + firstHandItem + ", " + it + ";";
				firstHandFull = false;
			} else {
				firstHandItem = it;
				firstHandFull = true;
			}
		}
	}

	// FRANKEN STEIN
	if (have_skill($skill[Toast your enemy]))
		scriptString += "skill Toast your enemy;";

	return scriptString;
}



string raveComboScript(int comboNumber) {
	string storedValue = get_property("raveCombo" + comboNumber);
	assert(storedValue != "", "we haven't learned the combo " + comboNumber);
	string [] skills = storedValue.split_string(",");
	return "skill " + skills.joinString("; skill ") + ";";
}

string raveConcentrationScript() {
	return raveComboScript(1);
}

string raveNirvanaScript() {
	return raveComboScript(2);
}



string doClassSkills(monster foe, int monsterHP, string scriptSoFar) {
	print("doClassSkills");
	string scriptString = scriptSoFar;

	if (my_class() == $class[seal clubber])
		scriptString += "";
	else if (my_class() == $class[turtle tamer])
		scriptString += "";
	else if (my_class() == $class[pastamancer])
		scriptString += "";
	else if (my_class() == $class[sauceror])
		scriptString += "";
	else if (my_class() == $class[disco bandit]) {
		if (canStagger(foe) || safeExpectedDamageTaken() < my_maxhp() * 0.1) {
			if (have_skill($skill[Disco Dance of Doom])) scriptString += "skill disco dance of doom;";
			if (have_skill($skill[Disco Dance II: Electric Boogaloo])) scriptString += "skill Disco Dance II: Electric Boogaloo;";
			if (have_skill($skill[Disco Dance 3: Back in the Habit])) scriptString += "skill Disco Dance 3: Back in the Habit;";
			if (have_skill($skill[pop and lock it]) && have_skill($skill[break it on down]) && have_skill($skill[run like the wind])) {
				scriptString += raveConcentrationScript();
				scriptString += raveNirvanaScript();
			}
		}
	} else if (my_class() == $class[accordion thief]) {
		scriptString += "if hasskill steal accordion; skill steal accordion; endif;";
		if (have_skill($skill[Cadenza]) && atAccordionEquipped())
			scriptString += "skill Cadenza;";
	}

	return scriptString;
}



string doLocationSpecific(string scriptSoFar) {
	print("doLocationSpecific");
	string scriptString = scriptSoFar;

	if (get_property("lassoTraining") != "expertly" && my_location().environment == "underwater" && equipped_amount($item[sea cowboy hat]) > 0 && equipped_amount($item[sea chaps]) > 0) {
		scriptString += "use sea lasso;";
	}

	if (equipped_amount($item[cozy scimitar]) > 0 && my_location().environment == "underwater") {
		scriptString += "skill harpoon!;skill summon leviatuga;";
	} else if (equipped_amount($item[cozy scimitar]) > 0)
		print("WARNING: cozy scimitar equipped but not underwater!", "red");

	return scriptString;
}



// returns the damage per action averaged over all the damage done in the given combat result string
int parseDamagePerAction(string combatResult, int hpBeforeStart) {
	string attackResult = combatResult.to_lower_case();
	//print("attack string: " + attackResult, "green");

  	int damage = 0;

	print("before macro, hp is now: " + hpBeforeStart + ", def is now: " + monster_defense() + ", off is now: " + monster_attack());
	matcher damageSectionMatcher = create_matcher("var monsterstats = \\{\"hp\":\"([0-9,]+)\",\"def\":\"([0-9,]+)\",\"off\":\"([0-9,]+)\"\\};", attackResult);
	int turnsTaken = 0;
	while (find(damageSectionMatcher)) {
		int hpAfterAction = to_int(group(damageSectionMatcher, 1));
		int defAfterAction = to_int(group(damageSectionMatcher, 2));
		int offAfterAction = to_int(group(damageSectionMatcher, 3));
		print("after the action, hp are now: " + hpAfterAction + ", def is now: " + defAfterAction + ", off is now: " + offAfterAction + ", total damage done: " + damage);
		damage = hpBeforeStart - hpAfterAction;
		turnsTaken++;
	}

// TRY #2
// 	matcher damageSectionMatcher = create_matcher("<script type=\"text/javascript\">var monsterstats = \\{\"hp\":\"([0-9,]+)\",\"def\":\"[0-9,]+\",\"off\":\"[0-9,]+\"\\};(.*?)<center>", attackResult);
// 	while (find(damageSectionMatcher)) {
// 		int currentMonsterHP = to_int(group(damageSectionMatcher, 1));
// 		print("calculated monster HP: " + currentMonsterHP + " vs KoLmafia's calc: " + monster_hp(), "blue");
// 		string damageSection = group(damageSectionMatcher, 2);
// 		print("damage section: " + damageSection, "green");
// 
// 		matcher damageMatcher = create_matcher("([0-9,]+)", damageSection);
// 		while (find(damageMatcher)) {
// 			damage += to_int(group(damageMatcher, 1));
// 		}
// 	}

// TRY #1
//	matcher damageSectionMatcher = create_matcher("var monsterstats = \\{\"hp\":\"[0-9,]+\",\"def\":\"[0-9,]+\",\"off\":\"[0-9,]+\"\\};</script><table><tr><[tT]d>(.*?)</td></tr></table>", attackResult);
// 	while (find(damageSectionMatcher)) {
// 		string damageSection = group(damageSectionMatcher, 1);
// 		print("damage section: " + damageSection, "green");
// 
// 		if (damageSection.contains_text(" damage.") || damageSection.contains_text(" you sing for ")) {
// 			// cut off the elemental damage
// 			string nonElementalDmgSection = damageSection;
// 			int startOfElementalDmg = index_of(damageSection, "(");
// 			if (startOfElementalDmg > 0)
// 				nonElementalDmgSection = substring(nonElementalDmgSection, 0, startOfElementalDmg);
// 
// 			// any numbers left should be basic damage, parse the whole string for any numbers
// 			damage += to_int(nonElementalDmgSection);
// 			print("non-elemental dmg: " + to_int(nonElementalDmgSection), "green");
// 
// 			// extra elemental damage
// 			matcher elementalMatcher = create_matcher("\\(<font.*?<b>\\+([0-9]+)</b></font>\\)", damageSection);
// 			while (find(elementalMatcher)) {
// 				print("elemental damage parse string: " + group(elementalMatcher, 1), "green");
// 				damage += to_int(group(elementalMatcher, 1));
// 			}
// 		}
// 	}

	print("parsed damage: " + damage + " over " + turnsTaken + " turns", "green");
	return damage / turnsTaken;
}



// given an attack we already did and the damage we did with it, return the next attack to do
ActionRecord chooseActionRecord(monster foe, int monsterHP, ActionRecord attackDone, int damageDone) {
	if (attackDone.isEmptyAction())
		return defaultAttack(foe, monsterHP);

	int expectedRounds = ceil(monsterHP / to_float(damageDone));
	print("expecting " + expectedRounds + " rds", "blue");

	// FEEL SUPERIOR
	if (hippy_stone_broken() && monsterHP < monster_hp(foe) * 0.2 && monsterHP > 5 && get_property("_feelSuperiorUsed").to_int() < 3)
		return new ActionRecord(false, false, $skill[Feel Superior]);

	// DOING ENOUGH DAMAGE?
	boolean notDoingEnoughDamage = false;
	if (maxRounds(foe) - current_round() == 0 || damageDone < monsterHP / (maxRounds(foe) - current_round())) {
		print("we're not doing enough damage!", "orange");
		notDoingEnoughDamage = true;
	}

	// TAKING TOO MUCH DAMAGE?
	boolean takingTooMuchDamage = false;
	if (safeExpectedDamageTaken() * expectedRounds > my_hp()) {
		print("we're taking too much damage!", "orange");
		takingTooMuchDamage = true;
	}

	// ESCALATE? if we're taking too much damage, or we're not doing enough damage and we're near our max rounds (within 5), escalate
	if (takingTooMuchDamage
		|| (notDoingEnoughDamage && attackDone.itemToUse != $item[none]) // if we're using items, we have no hope of increasing dmg down the line
		|| ((notDoingEnoughDamage || !wantToStasis()) && (maxRounds(foe) - current_round()) < 5)) { // TODO: figure out how to include increasing debuff from curse of weaksauce? will the current round > maxRounds() work?
		print("not enough damage (" + damageDone + "), and/or taking too much damage (" + safeExpectedDamageTaken() + ") expected rounds: " + expectedRounds + ", recommending escalation", "orange");

		ActionRecord [int] escalationProfile = { // attack, pickpocket, skillToUse, itemToUse, item2Touse
			new ActionRecord(true), // attack
			new ActionRecord(false, false, $skill[Saucestorm]),
			new ActionRecord(false, false, $skill[Saucegeyser]),
			new ActionRecord(false, false, $skill[Weapon of the Pastalord]),
		};

		ActionRecord returnAction;
		int currentEscalation = -1;
		for i from 0 to count(escalationProfile) - 1 {
			if (attackDone.isSameAction(escalationProfile[i]))
				currentEscalation = i;
		}
		int escalateBy = 1; // coming in, we know we have to escalate once
// 		repeat {
			currentEscalation += escalateBy;
			currentEscalation = min(currentEscalation, count(escalationProfile) - 1);
			returnAction = escalationProfile[currentEscalation];
			print("escalating to " + returnAction.toString());
// 		} until (currentEscalation >= count(escalationProfile) - 1 || willKillBeforeDying(foe, returnAction)); // willKillBeforeDying isn't always right, instead of trying to calc dmg, test one attack and use the result as dmg done

		if (!willKillBeforeDying(foe, monsterHP, returnAction))
			print("we aren't doing enough damage with the same action: '" + macroForAction(returnAction) + "' (and/or we don't have the mp to cast that many times)", "red");
		return returnAction;
	}

	if (!willKillBeforeDying(foe, monsterHP, attackDone))
		print("we aren't doing enough damage with the same attack " + macroForAction(attackDone) + " (and/or we don't have the mp to cast that many times)", "red");
	return attackDone; // return the last attack by default
}



int parseDamage(monster foe, int hpBeforeScript, string resultSoFar) {
	int damageDone;

	// DIRECT
// 	damageDone = hpBeforeScript - monster_hp(); // mafia seems braindead on God Lobster's hp AND OTHERS

	// PARSE
	if (damageDone <= 0) { // if that didn't work, try parsing the HTML directly
		damageDone = parseDamagePerAction(resultSoFar, hpBeforeScript);
	}

	// RESYNC
	if (damageDone <= 0) { // that didn't work either, try resync'ing the page
		string pageString = resyncMonsterStats();
		damageDone = hpBeforeScript - real_monster_hp(pageString);
	}

	assert(damageDone > 0, "we should have done damage:\n" + resultSoFar);
	print("damage done: " + damageDone, "blue");

	return damageDone;
}


string attackHelper(monster foe, int hpBeforeScript, string scriptString) {
	print("attackHelper current round: " + current_round(), "blue");
	logMonsterCombatStats();

	string resultPage = executeScript(scriptString);

	boolean didAbortMacro = macroAborted(resultPage);
	if ((inCombat() && !in_multi_fight()) || didAbortMacro)
		abort("stopping automation, in combat: " + inCombat() + ", aborted: " + didAbortMacro);

	return resultPage;
}


ActionRecord reconMonsterDefenses(monster foe, int monHPBeforeScript, ActionRecord lastAttack, int damageDone) {
	int roundsRemaining = maxRounds(foe) - current_round();
	ActionRecord theAttack = chooseActionRecord(foe, monHPBeforeScript, lastAttack, damageDone);

	while (inCombat() && roundsRemaining > 0) {
		print("recon script current round: " + current_round(), "blue");
		string scriptString = setupAborts(foe) + macroForAction(theAttack);
		string resultPage = attackHelper(foe, monHPBeforeScript, scriptString);
		gAccumulatedResponse += resultPage;
		damageDone = parseDamage(foe, monHPBeforeScript, resultPage);
		monHPBeforeScript -= damageDone;
		int expectedRounds = ceil(monHPBeforeScript / to_float(damageDone));

		if (damageDone < 0) return theAttack; // combat's over

		if (doingEnoughDamage(foe, monHPBeforeScript, damageDone)) {
			if (expectedRounds * mp_cost(theAttack.skillToUse) > my_mp()) {
				// escalation will only make mp problems worse
				print("will run out of mp before killing, aborting consult", "red");
				return theAttack;
			} else // everything looks good
				break;
		}

		else { // ESCALATE
			lastAttack = theAttack;
			theAttack = chooseActionRecord(foe, monHPBeforeScript, lastAttack, damageDone);
		}

		roundsRemaining = maxRounds(foe) - current_round();
	}

	return theAttack;
}

boolean reconAndKill(monster foe, int monHPBeforeScript, ActionRecord lastAttack, int damageDone) {
	// ATTACK ONCE repeatedly, escalating skills until we get something that does enough damage
	ActionRecord theAttack = reconMonsterDefenses(foe, monHPBeforeScript, lastAttack, damageDone);

	// SPAM THE CHOSEN ACTION
	int maxRounds = maxRounds(foe) - current_round(); // was: ceil((maxRounds(foe) - current_round()) / 2.0);
	string scriptString = setupAborts(foe) + "mark RAK;if !times " + maxRounds + ";" + macroForAction(theAttack) + ";goto RAK;endif;";
	string resultPage = attackHelper(foe, monHPBeforeScript, scriptString);
	gAccumulatedResponse += resultPage;
	boolean didAbortMacro = macroAborted(resultPage);

	print("exiting main loop, current round: " + current_round(), "red");
	return (!inCombat() || in_multi_fight()) && !didAbortMacro;
}


// Escalation strategy:
// 1. execute everything we have up until this point
// 2. attack once, parsing the damage we've done
// 3. if the attack didn't do enough damage to kill in time, escalate the skill (see chooseActionRecord) and try again
// 4. use the optimal skill to construct a script to kill the monster and execute
boolean escalationStrategy(monster foe, int monHPBeforeScript, string scriptSoFar) {
	print("escalationStrategy, monHPBeforeScript: " + monHPBeforeScript, "green");
	string scriptString = scriptSoFar;

	// FIRST, EXECUTE THE GIVEN SCRIPT, which is presumably a debuff or otherwise non-damaging script
	logMonsterCombatStats();

	string resultSoFar = executeScript(scriptString); // empty script is fine
	gAccumulatedResponse += resultSoFar;

	boolean didAbortMacro = macroAborted(resultSoFar);
	if (!inCombat() || didAbortMacro) {
		print("doMainLoop: stopping automation at the first execution. in combat? " + inCombat() + ", aborted? " + didAbortMacro, "orange");
		return !didAbortMacro;
	}

	return reconAndKill(foe, real_monster_hp(resultSoFar), new ActionRecord(), 0);
}


// Basic strategy: execute everything we have up until this point with the
// default action a number times equal to the numbers of turns remaining minus 5.
// If the monster isn't dead at that point, execute the basic strategy
boolean basicStrategy(monster foe, int monHPBeforeScript, string scriptSoFar) {
	print("basicStrategy, monHPBeforeScript: " + monHPBeforeScript, "green");
	string scriptString = scriptSoFar;

	// FIRST, EXECUTE THE EXISTING SCRIPT
	logMonsterCombatStats();

	string resultSoFar = executeScript(scriptString); // empty script is fine
	gAccumulatedResponse += resultSoFar;

	boolean didAbortMacro = macroAborted(resultSoFar);
	if (!inCombat() || didAbortMacro) {
		print("doMainLoop: stopping automation at the first execution. in combat? " + inCombat() + ", aborted? " + didAbortMacro, "orange");
		return !didAbortMacro;
	}

	// figure out how many rounds we have left and bash the default action that many times (less 5 for emergencies)
	logMonsterCombatStats();
	int maxRounds = maxRounds(foe) - current_round(); // leave 5 rounds for the basic strat
	ActionRecord theAttack = defaultAttack(foe, monHPBeforeScript);
	scriptString = "mark BS;if !times " + maxRounds + ";" + macroForAction(theAttack) + ";goto BS;endif;";

	string resultPage = attackHelper(foe, monHPBeforeScript, scriptString);
	gAccumulatedResponse += resultPage;
	didAbortMacro = macroAborted(resultPage);
	int damageDone = parseDamage(foe, monHPBeforeScript, resultPage);

	// combat's over
	if (damageDone < 0 || !inCombat())
		return !didAbortMacro;

	// we're still in combat
	string pageString = resyncMonsterStats();

	return reconAndKill(foe, real_monster_hp(pageString), theAttack, damageDone);
}


// try to finish the fight. returns the accumulated response after the execution of the given script and the main loop
string doMainLoop(monster foe, int monHPBeforeScript, string scriptSoFar) {
	assert(foe != $monster[Guy Made Of Bees], "do Guy Made Of Bees manually -- try polar vortex!");

	print("doMainLoop");
	string scriptString = scriptSoFar;

	basicStrategy(foe, monHPBeforeScript, scriptSoFar);

	return gAccumulatedResponse;

	// ATTACK WITH OPTIMAL SKILL
// 	roundsRemaining = maxRounds(foe) - current_round();
// 		print("kill script current round: " + current_round(), "blue");
// 		logMonsterCombatStats();
// 
// 		
// 		scriptString = setupAborts() + macroForAction(theAttack);
// 
// 		// if we recommend the same action as last time, use up 1/2 the rounds to the maxRound doing the same action
// 		if (ceil((maxRounds(foe) - current_round()) / 2.0) >= 1)
// 			scriptString = "mark ML;if !times " + ceil((maxRounds(foe) - current_round()) / 2.0) + ";" + scriptString + ";goto ML;endif;";
// 
// 		hpBeforeScript = monster_hp();
// 		resultSoFar = executeScript(scriptString);
// 		gAccumulatedResponse += resultSoFar;
// 
// 		didAbortMacro = macroAborted(resultSoFar);
// 		if (!inCombat() || didAbortMacro) {
// 			print("stopping automation, in combat: " + inCombat() + ", aborted: " + didAbortMacro, "orange");
// 			break;
// 		}
// 
// 		scriptString = setupAborts(foe);
// 
// 		// FIGURE OUT DAMAGE DONE
// 		// start by relying on mafia
// 		damageDone = hpBeforeScript - monster_hp();
// 
// 		// that didn't work, try parsing the HTML directly
// 		if (damageDone < 3)
// 			damageDone = parseDamage(resultSoFar, hpBeforeScript);
// 
// 		// that didn't work either, try resync'ing the page
// 		if (damageDone < 3) { // damage not lining up with what we expected, try refreshing
// 			print("detected too little damage ( " + damageDone + ")... something's wrong -- resyncing", "red");
// 			scriptString = resyncMonsterStats(foe, scriptString);
// 			damageDone = hpBeforeScript - monster_hp();
// 			print("damage done now: " + damageDone, "blue");
// 			if (damageDone < 3) // if we're still screwed, try the same thing again once
// 				continue;
// 		}
// 		assert(damageDone != 0, "we should not have done zero damage");
// 		print("damage done: " + damageDone, "blue");
// 
// 		// DOING ENOUGH DAMAGE?
// 		int expectedRounds = ceil(monster_hp() / to_float(damageDone));
// 		print("expecting to take " + expected_damage() + " damage (or " + safeExpectedDamageTaken() + " with the safety margin) per round", "green");
// 		if (expectedRounds < roundsRemaining && my_hp() > safeExpectedDamageTaken() * (expectedRounds - 1))
// 			return setupAborts(foe) + macroForAction(theAttack) + "repeat;";
// 
// 		// we might be able to kill in one hit, so check the "safely kill" section first (above), then ensure we can survive the next round
// 		if (my_hp() <= safeExpectedDamageTaken() && damageDone < monster_hp()) {
// 			print("we're about to die, aborting consult", "red");
// 			return "abort";
// 		}
// 
// 		// since we can't safely kill, see if we can choose a different attack action and try again
// 		lastAttack = theAttack;
// 		theAttack = chooseActionRecord(foe, lastAttack, damageDone);
// 
// 		if (mp_cost(theAttack.skillToUse) > my_mp()) {
// 			print("will run out of mp before killing, aborting consult", "red");
// 			return "abort";
// 		}
// 
// 		roundsRemaining = maxRounds(foe) - current_round();
// 	}
}



void initConsult(monster foe) {
	gkMonsterOriginalAttack = foe.base_attack;
	gkMonsterOriginalDefense = foe.base_defense;

// 	if (!in_multi_fight())
// 		gAccumulatedResponse = "";
	gAccumulatedResponse = "";

	print("initConsult hit stat: "+ attackStat() + ", canStagger: " + canStagger(foe) + ", wantToStasis: " + wantToStasis() + ", original attack: " + gkMonsterOriginalAttack + ", original defense: " + gkMonsterOriginalDefense, "blue");
}


// returns the script so far
string customScriptWithDefaultKillHelperTop(int initround, monster foe, string aPage) {
	int currentRound = initround;
	initConsult(foe);
	string scriptString = startFight(foe);
	int monsterHP = real_monster_hp("");

	if (currentRound == 1)
		scriptString = doPickpocketAndDebuff(foe, monsterHP, scriptString);
	else {
		// TODO redo this WORKAROUND: KoL stats are not consistent with reality until we interact with the monster -- do that here before we get to the main debuff calculations
		string pageString = resyncMonsterStats();
		monsterHP = real_monster_hp(pageString);
		scriptString = doDebuff(foe, monsterHP, scriptString);
	}
	currentRound = current_round();

	if ((expected_damage() > (my_maxhp() * 0.02)) && canStagger(foe)) // TODO expected_damage() > the amount healed at the end of a fight
		scriptString = doClassStun(foe, monsterHP, scriptString);

	return scriptString;
}

// returns the script so far
string customScriptWithDefaultKillHelperBottom(string scriptString, int initround, monster foe, int monsterHP, string aPage, string customScript) {
	scriptString = doItemsAndBuffs(foe, monsterHP, scriptString);
	scriptString = doClassSkills(foe, monsterHP, scriptString);
	scriptString = doLocationSpecific(scriptString);

	scriptString += customScript;

	return doMainLoop(foe, monsterHP, scriptString);
}

// inserts a custom script at the end of the usual preamble stuff, then kills the monster with
// whatever would have normally done so
// returns the accumulated response pages across all requests to attempt to finish combat
string customScriptWithOlfactAndDefaultKill(int initround, monster foe, string aPage, string customScript) {
	print("customScriptWithOlfactAndDefaultKill: " + foe + ", script: '" + customScript + "'", "green");
	string scriptString = customScriptWithDefaultKillHelperTop(initround, foe, aPage);
	scriptString = doOlfaction(foe, scriptString);
	return customScriptWithDefaultKillHelperBottom(scriptString, initround, foe, real_monster_hp(""), aPage, customScript);
}

// returns the accumulated response pages across all requests to attempt to finish combat
string customScriptWithDefaultKill(int initround, monster foe, string aPage, string customScript) {
	print("customScriptWithDefaultKill: " + foe + ", script: '" + customScript + "'", "green");
	string scriptString = customScriptWithDefaultKillHelperTop(initround, foe, aPage);
	return customScriptWithDefaultKillHelperBottom(scriptString, initround, foe, real_monster_hp(""), aPage, customScript);
}



string instaKillWithOlfact(int initround, monster foe, string aPage) {
	PrioritySkillRecord instaKillSkill = chooseInstaKillSkill();
	if (instaKillSkill.theSkill == $skill[none])
		abort("no insta kill skill!");

	return customScriptWithOlfactAndDefaultKill(initround, foe, aPage, "skill " + instaKillSkill.theSkill + ";");
}


string customScriptWithInstaKill(int initround, monster foe, string aPage, string customScript) {
	PrioritySkillRecord instaKillSkill = chooseInstaKillSkill();
	if (instaKillSkill.theSkill == $skill[none])
		abort("no insta kill skill!");

	return customScriptWithDefaultKill(initround, foe, aPage, customScript + ";skill " + instaKillSkill.theSkill + ";");
}

string instaKill(int initround, monster foe, string aPage) {
	return customScriptWithInstaKill(initround, foe, aPage, "");
}

string instaKill() {
	return instaKill(current_round(), last_monster(), "");
}



string defaultKillWithOlfact(int initround, monster foe, string aPage) {
	return customScriptWithOlfactAndDefaultKill(initround, foe, aPage, "");
}


string defaultKill(int initround, monster foe, string aPage) {
	return customScriptWithDefaultKill(initround, foe, aPage, "");
}

string defaultKill() {
	return defaultKill(current_round(), last_monster(), "");
}



void main(int initround, monster foe, string aPage) {
	string resultPage = defaultKill(initround, foe, aPage);
}



