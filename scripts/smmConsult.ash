import <smmUtils.ash>
string __smm_consult_version = "0.1";

/**
To use, place this in the custom combat script:

consult smmConsult.ash

To use any of the functions from the command line, do this:
using smmConsult.ash
*/

// TODO add Meteor Showered for Gingerbread Alligators
// TODO add Army of Toddlers when wearing xp shirt

// -------------------------------------
// GLOBALS, DATA TYPES, CONSTANTS, AND DATA
// -------------------------------------

record AbortRecord {
	int missed;
	int pastround;
	int hpbelow;
	int hppercentbelow;
	int mpbelow;
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


boolean gCannotDebuffEnough; // true if we should consider throwing out the idea of attacking physically




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



AbortRecord defaultAborts(monster foe) {
	AbortRecord rval;

	// conservative by default
	rval.missed = 2;
	rval.pastround = 20;
	rval.hpbelow = 50;
	rval.hppercentbelow = 50;

	if (my_class() == $class[seal clubber]) {
		rval.missed = 5;
		rval.pastround = 20;
		rval.hpbelow = 33;
		rval.hppercentbelow = 33;

	} else if (my_class() == $class[turtle tamer]) {
		rval.missed = 8;
		rval.pastround = 25;
		rval.hpbelow = 20;
		rval.hppercentbelow = 20;

	} else if (my_class() == $class[pastamancer] || my_class() == $class[sauceror]) {
		rval.mpbelow = 26;

	} else if (my_class() == $class[disco bandit]) {
		rval.missed = 8;
		rval.pastround = 25;
		rval.hpbelow = 25;
		rval.hppercentbelow = 25;

	} else if (my_class() == $class[accordion thief]) {
		rval.missed = 4;
		rval.pastround = 20;
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



record DamageRecord {
	int damage;
	int damageTypes; // pick damageTypes elements from dmgElements and do damage of each type
	element [int] dmgElements; // none = physical
};


string toString(DamageRecord dr) {
	string elementString;
	foreach idx, anElement in dr.dmgElements {
		elementString = elementString.joinString(anElement, ", ");
	}

	return dr.damage + " dmg, picking " + dr.damageTypes + "X from types " + elementString;
}

string toString(DamageRecord [] drs) {
	string rval;
	foreach idx, dr in drs {
		rval += dr + "\n";
	}

	return rval;
}


// returns the base expected damage done by the give skill, i.e. damage without any bonus damage or bonus percent damage
// skill none = attack
DamageRecord [] baseExpectedDamageDone(skill dmgSkill) {
	DamageRecord [int] rval;

	if (dmgSkill == $skill[none]) {
		int damage = max(my_buffedstat($stat[muscle]) - monster_defense(), 0);
		rval[0] = new DamageRecord(my_buffedstat(current_hit_stat()), damage, {$element[none]});

	} else if (dmgSkill == $skill[Saucestorm]) {
		rval[0] = new DamageRecord(min(50, 22 + floor(0.2 * my_buffedstat($stat[mysticality]))), 2, {$element[cold], $element[hot]});

	} else if (dmgSkill == $skill[Saucegeyser]) {
		rval[0] = new DamageRecord(65 + floor(0.4 * my_buffedstat($stat[mysticality])), 1, {$element[cold], $element[hot]});

	} else if (dmgSkill == $skill[Weapon of the Pastalord]) {
		rval[0] = new DamageRecord(48 + floor(0.5 * my_buffedstat($stat[mysticality])), 1, {$element[none]});
	}

	return rval;
}



// returns the expected damage done by the give skill
// skill none = attack
DamageRecord [] expectedDamageDone(skill dmgSkill) {
	DamageRecord [int] rval;

	int dmg;
	int weaponBonus = numeric_modifier("Weapon Damage");
	float weaponBonusPercent = numeric_modifier("Weapon Damage Percent") / 100.0;
	int spellBonus = numeric_modifier("Spell Damage");
	float spellBonusPercent = numeric_modifier("Spell Damage Percent") / 100.0;
	print("weapon damage: " + weaponBonus + ", weapon damage %: " + weaponBonusPercent + ", spell damage: " + spellBonus + ", spell damage %: " + spellBonusPercent);

	if (dmgSkill == $skill[none]) {
		int damage = (max(my_buffedstat($stat[muscle]) - monster_defense(), 0) + weaponBonus) * (1.0 + weaponBonusPercent);
		rval[0] = new DamageRecord(my_buffedstat(current_hit_stat()), damage, {$element[none]});

	} else if (dmgSkill == $skill[Saucestorm]) {
		dmg = (min(50, 22 + floor(0.2 * my_buffedstat($stat[mysticality]))) * (1.0 + spellBonusPercent)) + spellBonus;
		rval[0] = new DamageRecord(dmg, 2, {$element[cold], $element[hot]});

	} else if (dmgSkill == $skill[Saucegeyser]) {
		dmg = ((65 + floor(0.4 * my_buffedstat($stat[mysticality]))) * (1.0 + spellBonusPercent)) + spellBonus;
		rval[0] = new DamageRecord(dmg, 1, {$element[cold], $element[hot]});

	} else if (dmgSkill == $skill[Weapon of the Pastalord]) {
		rval[0] = new DamageRecord(48 + floor(0.5 * my_buffedstat($stat[mysticality])), 1, {$element[none]});
	}

	return rval;
}



// chooses which element to use against the given foe
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



// flat amount of hp we expect to remove from the given monster AFTER considering element defense and susceptibility
int expectedDamageDone(ActionRecord anAction, monster foe) {
	int totalDamage = 0;

	if (anAction.skillToUse != $skill[none] || anAction.attack) {
		foreach idx, dr in baseExpectedDamageDone(anAction.skillToUse) { // we're assuming here that we're getting a skill or we're attacking (in which case skillToUse will be none as expected by baseExpectedDamage)
			print(dr.toString(), "green");
			foreach idx, anElement in choseElements(dr, foe) {
				print("evaluating: " + anElement, "green");
				int actualAmount = dr.damage;
				if (anElement != $element[none] && monster_element(foe) == anElement)
					actualAmount = 1;
				else {
					foreach weakElement in weak_elements(foe.monster_element()) {
						if (anElement == weakElement) {
							actualAmount *= 2;
							break;
						}
					}
				}

				totalDamage += actualAmount;
			}
		}

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



boolean willKillBeforeTimeout(monster foe, int damageDone) {
	int expectedRoundsToKill = ceil(monster_hp() / to_float(damageDone)); // int/int = int, which will truncate any fraction instead of rounding up
	return expectedRoundsToKill <= maxRounds(foe);
}

// uses estimates of future damage done
boolean willKillBeforeTimeout(monster foe, ActionRecord anAttack) {
	print("willKillBeforeTimeout");
	int expectedDamageDone = expectedDamageDone(anAttack, foe);
	return willKillBeforeTimeout(foe, expectedDamageDone);
}


boolean willKillBeforeDying(monster foe, int damageDone, int damageTaken) {
	assert(damageDone > 0, "willKillBeforeDying got a zero damageDone");
	assert(damageTaken > 0, "willKillBeforeDying got a zero damageTaken");
	print("willKillBeforeDying(foe, int, int)");

	// int/int = int, which will truncate any fraction instead of rounding up -- hence the conversion to float
	int expectedRoundsToKill = ceil(monster_hp() / to_float(damageDone));
	int expectedRoundsToDie = floor(my_hp() / to_float(damageTaken));
	return expectedRoundsToKill <= expectedRoundsToDie;
}

// uses estimates of future damage taken and given
boolean willKillBeforeDying(monster foe, ActionRecord anAttack) {
	print("willKillBeforeDying(foe, ActionRecord)");
	// ensure neither of these are assigned 0, which will result in a div by zero error
	int expectedDamageDone = max(1, expectedDamageDone(anAttack, foe));
	int expectedDamageTaken = max(1, safeExpectedDamageTaken());
	return willKillBeforeDying(foe, expectedDamageDone, expectedDamageTaken);
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




// similar to will_usually_miss() but returns true if we can ALWAYS hit the monster
// uses attackStat() which wraps current_hit_stat() to consider the Cosplay sabre.
boolean willAlwaysHit() {
	return my_buffedstat(attackStat()) >= (monster_defense() + 5.0);
}

boolean shouldDebuff() {
	print("willAlwaysHit: " + willAlwaysHit() + ", gCannotDebuffEnough: " + gCannotDebuffEnough + ", will_usually_dodge " + will_usually_dodge() + ", safeExpectedDamageTaken: " + safeExpectedDamageTaken(), "blue");
	return (!willAlwaysHit() && !gCannotDebuffEnough) || (!will_usually_dodge() && safeExpectedDamageTaken() * 20 > my_hp());
// 	return true;
}

// the fraction of the monster's defense that needs to remain before an attack would be successful
float fractionNeededToSuccessfullyAttack() {
	return my_buffedstat(attackStat()) / (monster_defense() + 5.0);
}

boolean isDebuffEnoughToHit(float defFraction) {
	return defFraction <= fractionNeededToSuccessfullyAttack();
}

// given defFraction, the fraction that we will debuff the monster's defense, how many turns before we can hit it if we have casted weaksauce
int weaksauceTurnsUntilHit(float defFraction) {
	return -(log_n(fractionNeededToSuccessfullyAttack() / defFraction) / log_n(100.0/97.0));
}

boolean isDebuffEnoughToDefend(float offFraction) {
	float fractionNeededToSuccessfullyDefend = my_buffedstat($stat[moxie]) / (monster_attack() + 10.0); // the fraction of the monster's attack that needs to remain before a miss is guaranteed

	return offFraction <= fractionNeededToSuccessfullyDefend;
}

boolean canDebuffEnough(float offFraction, float defFraction) {
	int damageTakenBeforeCanHit = weaksauceTurnsUntilHit(defFraction) * safeExpectedDamageTaken();
	print("weaksauceTurnsUntilHit: " + weaksauceTurnsUntilHit(defFraction) + ", damageTakenBeforeCanHit: " + damageTakenBeforeCanHit, "blue");
// 	return isDebuffEnoughToHit(defFraction) && isDebuffEnoughToDefend(offFraction);
	return (isDebuffEnoughToHit(defFraction) && isDebuffEnoughToDefend(offFraction)) || (damageTakenBeforeCanHit < my_hp() && damageTakenBeforeCanHit < my_maxhp() * 0.4);
}

boolean canDebuffEnough() {
	return canDebuffEnough(0.7, 0.7);
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
		if (m != $monster[none] && monsterMap[m] > 0 && conditional)
			rval = rval.joinString("monstername " + monsterName, " || ");
	}
	return rval;
}


// returns a string with a conditional that returns true iff the monster we're fighting is one from the given location
string isMonsterFromLocationScript(location aLocation) {
	return isMonsterFromLocationScript(aLocation, "");
}



// return the default attack action
ActionRecord defaultAction(monster foe) {
	ActionRecord theAction;

	// NORMAL HOBO override
	if (foe == $monster[Normal hobo]) // special override because we don't want too much overdamage to normal hobos
		theAction.skillToUse = $skill[Saucestorm];

	// DRIPPY MONSTER override
	else if (foe == $monster[drippy tree] || foe == $monster[drippy bat] || foe == $monster[drippy reveler]) // drippy monsters only susceptible to attacks
		theAction.attack = true;

	// SAUCEROR override
	else if (my_class() == $class[Sauceror] && my_mp() >= mp_cost($skill[Saucegeyser])) // saucerors gain MP from overkilling with Curse of Weaksauce
		theAction.skillToUse = $skill[Saucegeyser];

	// CANNOT DEBUFF ENOUGH OR PHYSICAL RES TOO HIGH
	else if ((gCannotDebuffEnough || foe.physical_resistance > 80)
			&& canInjureWithSpells(foe) && my_mp() >= mp_cost($skill[Saucestorm])) {
		print("recommending escalation immediately, cannot debuff enough: " + gCannotDebuffEnough + ", physical res: " + foe.physical_resistance + "%", "blue");
		if (item_amount($item[Arr, M80]) > 0
			&& foe.monster_element() != $element[hot]
			&& foe.monster_hp() <= (50 * 2 * 15)) { // Arr, M80s do ~50 hot dmg avg and drop items worth more than an Arr, M80(?)
			checkIfRunningOut($item[Arr, M80], 10000);
			theAction.itemToUse = $item[Arr, M80];
			theAction.item2ToUse = $item[Arr, M80];
		} else
			theAction.skillToUse = $skill[Saucestorm];

		if ((!willKillBeforeDying(foe, theAction) || foe.monster_element() == $element[cold] || foe.monster_element() == $element[hot]) && my_mp() >= mp_cost($skill[Saucegeyser]))
			theAction.skillToUse = $skill[Saucegeyser];
		else if (!willKillBeforeDying(foe, theAction) || foe.monster_element() == $element[cold] || foe.monster_element() == $element[hot])
			abort("we'd like to escalate to saucegeyser but we don't have enough mp");

	// WEAPON OF THE PASTALORD ???
	} else if ((gCannotDebuffEnough || foe.physical_resistance > 80) && my_mp() >= mp_cost($skill[Weapon of the Pastalord])) {
		print("recommending escalation to Weapon of the Pastalord immediately", "blue");
		theAction.skillToUse = $skill[Weapon of the Pastalord];

	// STAR STARFISH
	} else if (wantToStasis()) { // if everything looks good and we've got a starfish, do minimal dmg to maximize mp regen
		theAction.itemToUse = $item[seal tooth];

	// DEFAULT
	} else {
// 		if (my_class() == $class[turtle tamer]) {
// 			if (expected_damage() < monster_hp() && safeExpectedDamageTaken(foe) > my_maxhp() * 0.02) // TODO if we take more damage than we heal
// 				theAction.skillToUse = $skill[Kneebutt];
// 			else
// 				theAction.attack = true;
// 		} else
		if (item_amount($item[Arr, M80]) > 0
			&& foe.monster_element() != $element[hot]
			&& foe.monster_hp() <= (50 * 2 * 15)) { // Arr, M80s do ~50 hot dmg avg and drop items worth more than an Arr, M80(?)
			checkIfRunningOut($item[Arr, M80], 10000);
			theAction.itemToUse = $item[Arr, M80];
			theAction.item2ToUse = $item[Arr, M80];
		} else
			theAction.attack = true;
	}

	if (theAction.skillToUse != $skill[none] && mp_cost(theAction.skillToUse) > my_mp())
		abort("not enough mp to use default attack " + macroForAction(theAction));

	return theAction;
}



// return aborts script
string setupAborts(monster foe) {
	string rval;

	AbortRecord ar = defaultAborts(foe);

	if (ar.missed > 0)
		rval += "abort missed " + ar.missed + ";";
	if (ar.pastround > 0)
		rval += "abort pastround " + ar.pastround + ";";
	if (ar.hpbelow > 0)
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
// returns the unexecuted part of the script, same as the rest
string resyncMonsterStats(monster foe, string scriptSoFar) {
	print("REFRESH!", "orange");
	string scriptString = scriptSoFar;

	visit_url("/fight.php", false, false);

// 	if (scriptString != "" && scriptString != setupAborts(foe)) {
// 		// if we're pickpocketing or something else, that will suffice
// 	} else { // otherwise do some kind of default action
// 		if (inRonin())
// 			scriptString += macroForAction(defaultAction(foe)); // means we're doing the default action twice -- TODO figure something else to do?
// 		else {
// 			if (my_hp() < 200)
// 				scriptString += "skill Silent Treatment;";
// 			else
// 				scriptString += "skill Blood Bucatini;";
// 		}
// 	}
// 	executeScript(scriptString);
// 	scriptString = "";

	return scriptString;
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
		// YELLOW RAY
		if (item_amount($item[Yellow Rocket]) > 0 && have_effect($effect[Everything Looks Yellow]) == 0) {
			if (foe == $monster[swarm of scarab beatles]
				|| foe == $monster[slime blob]) {
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



record DebuffMonsterRecord {
	float expectedOffFraction;
	float expectedDefFraction;
	ActionRecord [int] actions;
};


// returns the fraction of the current monster's base stats we would need to debuff to
// successfully attack (in expectedOffFraction) and defend (in expectedDefFraction)
// actions will always be empty
DebuffMonsterRecord monsterDebuffNeeded() {
	float fractionNeededToSuccessfullyAttack = my_buffedstat(attackStat()) / (monster_defense() + 5.0); // the fraction of the monster's defense that needs to remain before an attack would be successful
	float fractionNeededToSuccessfullyDefend = my_buffedstat($stat[moxie]) / (monster_attack() + 10.0); // the fraction of the monster's attack that needs to remain before a miss is guaranteed
	return new DebuffMonsterRecord(fractionNeededToSuccessfullyAttack, fractionNeededToSuccessfullyDefend);
}


// returns the status of all debuff skills in an array
// all debuffs will cause staggering with the possible exception of when a non-staggering debuff was the last to bring us over debuffNeeded
DebuffMonsterRecord debuffMonsterRecords(float debuffNeeded) {
	item [] kDelevelNoStaggerItems = {
		$item[Miniborg hiveminder],
		$item[Miniborg Destroy-O-Bot],
		$item[Miniborg strangler],
		$item[spectre scepter],
		$item[Zombo's empty eye],
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
	item tempItem;
	int i = 1; // start at 1 to leave room for weaksauce at the start
	int tempItemIndex;
	boolean didWeaksauce = false;

	float delevellingMultiplier = 1.0;
	if (have_effect($effect[Ruthlessly Efficient]) > 0)
		delevellingMultiplier += 0.5;
	if (equipped_amount($item[dark porquoise ring]) > 0)
		delevellingMultiplier += 1.0;

	ActionRecord [int] actions;

	if (have_item($item[HOA citation pad]) && fractionDone > debuffNeeded && (monster_phylum() == $phylum[dude] || monster_phylum() == $phylum[hippy] || monster_phylum() == $phylum[orc])) {
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
	}
	if (have_item($item[Mayor Ghost's scissors]) && fractionDone > debuffNeeded && monster_phylum() == $phylum[undead]) {
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
	}
	if (have_skill($skill[Detect Weakness]) && fractionDone > debuffNeeded) {
		actions[i++] = new ActionRecord(false, false, $skill[Detect Weakness], $item[none]);
		numberOfTurns++;
		fractionDone = fractionDone * (1.0 - (0.1 * delevellingMultiplier));
	}
	if (have_item($item[time-spinner]) && fractionDone > debuffNeeded) {
		actions[i++] = new ActionRecord(false, false, $skill[none], $item[time-spinner], kDelevelNoStaggerItems[delevelNoStaggerIndex++]);
		numberOfTurns++;
		fractionDone = fractionDone * (1.0 - (0.05 * delevellingMultiplier));
	}
	if (have_item($item[little red book]) && fractionDone > debuffNeeded) {
		actions[i++] = new ActionRecord(false, false, $skill[none], $item[little red book], kDelevelNoStaggerItems[delevelNoStaggerIndex++]);
		numberOfTurns++;
		fractionDone = fractionDone * (1.0 - (0.05 * delevellingMultiplier));
	}
	if (have_skill($skill[Sing Along]) && get_property("boomBoxSong") == "Remainin' Alive" && fractionDone > debuffNeeded) {
		actions[i++] = new ActionRecord(false, false, $skill[Sing Along], $item[none]);
		numberOfTurns++;
		fractionDone = fractionDone * (1.0 - (0.15 * delevellingMultiplier));
	}
	if (have_skill($skill[micrometeorite]) && fractionDone > debuffNeeded) {
		actions[i++] = new ActionRecord(false, false, $skill[micrometeorite], $item[none]);
		numberOfTurns++;
		fractionDone = fractionDone * (1.0 - (micrometerorite_percent() * delevellingMultiplier));
	}

	// check LAST to see how many combat turns we've used debuffing, then insert the actual debuff at the START of the script so we get all those turns of auto-debuffing
	if (have_skill($skill[curse of weaksauce]) && (fractionDone > debuffNeeded || my_class() == $class[sauceror])) {
		actions[0] = new ActionRecord(false, false, $skill[curse of weaksauce], $item[none]);
		numberOfTurns++;
		didWeaksauce = true;
		fractionDone = fractionDone - (0.03 * delevellingMultiplier * numberOfTurns); // weaksauce will take 3% of the initial stats each turn, so use MINUS instead of multiplying

		// NON-DELEVELING but staggering for weaksauce -- assuming no further useful items, so fill up funksling hand with a divine item to do damage
		// NASTY-SMELLING MOSS stagger for debuff with weaksauce -- if there's an item to throw left over from above, use that
		if (have_item($item[nasty-smelling moss]) && fractionDone > debuffNeeded) { // stagger for weaksauce
			actions[i++] = new ActionRecord(false, false, $skill[none], $item[nasty-smelling moss], kDelevelNoStaggerItems[delevelNoStaggerIndex++]);
			numberOfTurns++;
			fractionDone = fractionDone - (0.03 * delevellingMultiplier); // weaksauce will take 3% of the initial stats each turn, so use MINUS instead of multiplying
		}
		// ENTANGLING NOODLES
		if (my_class() != $class[pastamancer] && fractionDone > debuffNeeded) { // if we're not going to use it for stunning, use it for debuff with weaksauce due to staggering
			actions[i++] = new ActionRecord(false, false, $skill[Entangling Noodles], $item[none]);
			numberOfTurns++;
			fractionDone = fractionDone - (0.03 * delevellingMultiplier); // weaksauce will take 3% of the initial stats each turn, so use MINUS instead of multiplying
		}
		// SILENT knife stagger for debuff with weaksauce
		if (fractionDone > debuffNeeded) {
			actions[i++] = new ActionRecord(false, false, $skill[Silent Knife], $item[none]);
			numberOfTurns++;
			fractionDone = fractionDone - (0.03 * delevellingMultiplier); // weaksauce will take 3% of the initial stats each turn, so use MINUS instead of multiplying
		}
		// SILENT skill stagger for debuff with weaksauce TODO figure best one ----- DOESN'T STAGGER?
		if (fractionDone > debuffNeeded) {
// 			if (equipped_item($slot[weapon]).type == "knife" || )
			actions[i++] = new ActionRecord(false, false, $skill[Silent Slice], $item[none]);
			numberOfTurns++;
			fractionDone = fractionDone - (0.03 * delevellingMultiplier); // weaksauce will take 3% of the initial stats each turn, so use MINUS instead of multiplying
		}

		// CHEAPEST STAGGER ITEM
		if (fractionDone > debuffNeeded) { // stagger for weaksauce
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
			fractionDone = fractionDone - (0.03 * delevellingMultiplier); // weaksauce will take 3% of the initial stats each turn, so use MINUS instead of multiplying
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
	return new DebuffMonsterRecord(fractionDone, fractionDone, actions);
}


// TODO add survivable rounds to debuff needed
DebuffMonsterRecord debuffMonsterRecords() {
	DebuffMonsterRecord dmr = monsterDebuffNeeded();
  	float debuffNeeded = min(dmr.expectedOffFraction, dmr.expectedDefFraction);

	print("fraction to always hit: " + dmr.expectedOffFraction + ", buffed attack stat: " + my_buffedstat(attackStat()) + ", monster_defense() + 5.0: " + (monster_defense() + 5.0));
	print("fraction to always defend: " + dmr.expectedDefFraction + ", buffed moxie: " + my_buffedstat($stat[moxie]) + ", monster_attack() + 10.0: " + (monster_attack() + 10.0));

	return debuffMonsterRecords(debuffNeeded);
// 	return debuffMonsterRecords(0.5); // TODO do all the debuffs for now: a bug in KoLmafia doesn't update the attack/defense/hp values after using the backup camera
}


string doDebuff(monster foe, string scriptSoFar) {
	print("doDebuff");
	string scriptString;

	if (shouldDebuff()) {
		print("safeExpectedDamageTaken: " + safeExpectedDamageTaken(), "blue");
		if (canStagger(foe) || safeExpectedDamageTaken() * 20 < my_hp()) { // if we can't stagger we should just abort if we can't handle the damage output
			DebuffMonsterRecord dmr = debuffMonsterRecords();
// 			if (canDebuffEnough(dmr.expectedOffFraction, dmr.expectedDefFraction)) {
				scriptString = scriptSoFar + macroForActions(dmr.actions);
				print("debuffing: " + scriptString, "blue");
// 			} else {
// 				print("recommending escalation to spells: we can't debuff enough: " + dmr.expectedOffFraction + " offense fraction, " + dmr.expectedDefFraction + " def fraction", "blue");
// 				gCannotDebuffEnough = true; // if we can't debuff enough, cast spells instead
// 			}
		} else { // if we need to debuff and can't stagger, cast spells TODO: see if a single debuff will cross the threshold to safe (in which case staggering isn't necessary)
			print("recommending escalation to spells: we can't stagger and monster is doing too much damage (" + safeExpectedDamageTaken() + ") to absorb it while debuffing!", "blue");
			gCannotDebuffEnough = true;
		}
	}

	return scriptString;
}


string doPickpocket(monster foe, string scriptSoFar) {
	print("doPickpocket");
	string scriptString = scriptSoFar;

	// PICKPOCKET
	if (pickpocketable(foe) && current_round() == 1) {
		if (my_class() == $class[disco bandit] || my_class() == $class[accordion thief]
			|| equipped_amount($item[tiny black hole]) > 0 || equipped_amount($item[mime army infiltration glove]) > 0) {
			scriptString += "pickpocket;";
		}
	}
	if (pickpocketable(foe) && my_class() == $class[disco bandit] && is_wearing_outfit("Bling of the New Wave"))
		scriptString += "pickpocket;";

	return scriptString;
}



// TODO
string doDiscoPickpocket(monster foe, string scriptSoFar) {
	return scriptSoFar;
}



// pickpocketing and debuffing are together because we have to pickpocket first but
// we'd like to debuff before trying any potential Disco Combo
string doPickpocketAndDebuff(monster foe, string scriptSoFar) {
	print("doPickpocketAndDebuff");

	// PICKPOCKET
	string scriptString = scriptSoFar;
	scriptString = doPickpocket(foe, scriptString);

	// WORKAROUND: KoL stats are not consistent with reality until we interact with the monster -- do that here before we get to the main debuff calculations
	scriptString = resyncMonsterStats(foe, scriptString);

	// DEBUFF
	scriptString = doDebuff(foe, scriptString);

	boolean tryDiscoCombo = my_class() == $class[Disco Bandit];
	if (tryDiscoCombo) {
		scriptString = doDiscoPickpocket(foe, scriptString);
	}

	return scriptString;
}



string doClassStun(monster foe, string scriptSoFar) {
	print("doClassStun");
	skill stunSkill = stun_skill();
	boolean shouldUseStunSkill = have_skill(stunSkill);

	if (stunSkill == $skill[Accordion Bash] && !atAccordionEquipped())
		shouldUseStunSkill = false;
	if (safeExpectedDamageTaken() < my_maxhp() * 0.05 || expectedDamageDone(defaultAction(foe), foe) > monster_hp())
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
	return scriptSoFar;
}



// assumes the class stun is either done or not needed
string doItemsAndBuffs(monster foe, string scriptSoFar) {
	print("doItemsAndBuffs");
	string scriptString = scriptSoFar;
	boolean canStagger = canStagger(foe);

	if (my_familiar() == $familiar[space jellyfish])
		scriptString += "skill extract jelly;";

	// SING ALONG
	boolean shouldSingAlongWithBoomboxStats = get_property("boomBoxSong") == "Eye of the Giger" && canStagger;
	boolean shouldSingAlongWithBoomboxSpell = get_property("boomBoxSong") == "Food Vibrations" && my_primestat() == $stat[mysticality] && canStagger;
	boolean shouldSingAlongWithBoomboxMeat = get_property("boomBoxSong") == "Total Eclipse of Your Meat" && foe.min_meat > 0;
	if (have_skill($skill[sing along])
		&& (shouldSingAlongWithBoomboxStats || shouldSingAlongWithBoomboxSpell || shouldSingAlongWithBoomboxMeat))
		scriptString += "skill sing along;";

	// NEW HABIT
	if (have_skill($skill[a new habit]))
		scriptString += "skill a new habit;";

	// +ITEM things
	if (equipped_amount($item[broken champagne bottle]) >= 1) {
		if (equipped_amount($item[vampyric cloake]) >= 1 && to_int(get_property("_vampyreCloakeFormUses")) < 10) scriptString += "skill Become a bat;";
		if (equipped_amount($item[Lil' Doctor&trade; bag]) >= 1 && to_int(get_property("_otoscopeUsed")) < 3) scriptString += "skill Otoscope;";
		if (my_familiar() == $familiar[Pocket Professor]) scriptString += "if hasskill Lecture on mass;skill Lecture on mass;endif;";
		if (have_skill($skill[Bowl Straight Up])) scriptString += "skill Bowl Straight Up;";
	} else {
		if (my_familiar() == $familiar[Pocket Professor] && monster_hp() >= 1296) scriptString += "if hasskill deliver your thesis!;skill deliver your thesis!;endif;";
	}

	// BIG BOOK OF PIRATE INSULTS for pirates TODO only if we need it
	if (monster_phylum(foe) == $phylum[pirate] && have_item($item[The Big Book of Pirate Insults]))
		scriptString += "use big book of pirate insults;";

	// FEEL NOSTALGIC if the current monster is not the same as last monster and last monster is worth it
	if (foe != last_monster() && monsterCurrentItemMeatValue(foe) > kTurnValue / 2) {
		print("feeling nostagic!", "blue");
		scriptString += "cast feel nostalgic;";
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

	return scriptString;
}


string doClassSkills(monster foe, string scriptSoFar) {
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
				//scriptString = default_rave_combo_set_sub() + rval;
				//scriptString += " call rave_steal; call rave_item; call rave_meat; call rave_stats;";
			}
		}
	}
	else if (my_class() == $class[accordion thief]) {
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



int parseDamage(string combatResult, int hpBeforeStart) {
	string attackResult = combatResult.to_lower_case();
	//print("attack string: " + attackResult, "green");

  	int damage = 0;

	print("before macro, hp is now: " + hpBeforeStart + ", def is now: " + monster_defense() + ", off is now: " + monster_attack());
	matcher damageSectionMatcher = create_matcher("<!-- macroaction: (.+?) -->.+?var monsterstats = \\{\"hp\":\"([0-9,]+)\",\"def\":\"([0-9,]+)\",\"off\":\"([0-9,]+)\"\\};", attackResult);
	int turnsTaken = 0;
	while (find(damageSectionMatcher)) {
		string macroAction = group(damageSectionMatcher, 1);
		int hpAfterMacro = to_int(group(damageSectionMatcher, 2));
		int defAfterMacro = to_int(group(damageSectionMatcher, 3));
		int offAfterMacro = to_int(group(damageSectionMatcher, 4));
		print("after macro action '" + macroAction + "', hp are now: " + hpAfterMacro + ", def is now: " + defAfterMacro + ", off is now: " + offAfterMacro);
		damage += hpBeforeStart - hpAfterMacro;
		turnsTaken++;
	}

	if (turnsTaken == 1 && damage == 0) { // the above method didn't work
		print("DAMAGE 0??", "red");
		damage = 172; // saucestorm
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

	// fumble?
	if (damage == 0 && !attackResult.contains_text("fumble")) {
		//print("mis-parsed damage", "orange");
		abort("mis-parsed damage");
		return 0;
	}
	print("parsed damage: " + damage, "green");
	return damage;
}



// given an attack we already did and the damage we did with it, return the next attack to do
ActionRecord chooseActionRecord(monster foe, ActionRecord attackDone, int damageDone) {
	int expectedRounds = ceil(monster_hp() / to_float(damageDone));
	print("with monster hp: " + monster_hp() + " and damage done: " + damageDone + ", expecting " + expectedRounds + " rds", "blue");

	// DOING ENOUGH DAMAGE?
	boolean notDoingEnoughDamage = false;
	if (maxRounds(foe) - current_round() == 0 || damageDone < monster_hp() / maxRounds(foe) - current_round()) {
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
		print("not enough damage (" + damageDone + "), and/or taking too much damage (" + safeExpectedDamageTaken() + ") expected rounds: " + expectedRounds + ", recommending escalation", "blue");
		ActionRecord [] escalationProfile = { // attack, pickpocket, skillToUse, itemToUse, item2Touse
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
		repeat {
			currentEscalation += escalateBy;
			currentEscalation = min(currentEscalation, count(escalationProfile) - 1);
			returnAction = escalationProfile[currentEscalation];
		} until (currentEscalation >= count(escalationProfile) - 1 || willKillBeforeDying(foe, returnAction));

		if (!willKillBeforeDying(foe, returnAction))
			abort("we aren't doing enough damage with escalated skill " + macroForAction(returnAction) + " (and/or we don't have the mp to cast that many times)");

		return returnAction;
	}

	if (!willKillBeforeDying(foe, attackDone))
		print("we aren't doing enough damage with the same attack " + macroForAction(attackDone) + " (and/or we don't have the mp to cast that many times)", "red");
	return attackDone; // return the last attack by default
}


string doMainLoop(monster foe, string scriptSoFar) {
	print("doMainLoop");
	string scriptString = scriptSoFar;

	ActionRecord theAttack = defaultAction(foe);

	int roundsRemaining = maxRounds(foe) - current_round();
	while (inCombat() && roundsRemaining > 0) {
		ActionRecord lastAttack;
		int damageDone = 0;

		print("TOP, current round: " + current_round(), "red");
		logMonsterCombatStats();

		scriptString += macroForAction(theAttack);

		// if we recommend the same action as last time, use up 1/2 the rounds to the maxRound doing the same action
		if (damageDone != 0 && isSameAction(lastAttack, theAttack) && ceil((maxRounds(foe) - current_round()) / 2.0) >= 1)
			scriptString = "mark a1;if !times " + ceil((maxRounds(foe) - current_round()) / 2.0) + ";" + scriptString + ";goto a1;endif;";

		int hpBeforeScript = monster_hp();
		string resultSoFar = executeScript(scriptString);

		boolean didAbortMacro = macroAborted(resultSoFar);
		if (!inCombat() || didAbortMacro) {
			print("stopping automation, in combat: " + inCombat() + ", aborted: " + didAbortMacro, "orange");
			break;
		}

		scriptString = setupAborts(foe);

		// if we will safely kill the monster within roundsRemaining rounds, return the attack macro
// 		int damageDone = parseDamage(resultSoFar, hpBeforeScript);
		damageDone = hpBeforeScript - monster_hp();
		if (damageDone < 3) { // damage not lining up with what we expected, clearly, try refreshing
			print("detected ZERO damage: resyncing", "red");
			scriptString = resyncMonsterStats(foe, scriptString);
			damageDone = hpBeforeScript - monster_hp();
			continue;

			// FUMBLE??
// 			if (theAttack.attack && damageDone == 0) {
// 				print("looks like a fumble?? trying same action again", "orange");
// 				continue;
// 			}
		}
		assert(damageDone != 0, "we should not have done zero damage");

		// DOING ENOUGH DAMAGE
		int expectedRounds = ceil(monster_hp() / to_float(damageDone));
		print("expecting to take " + expected_damage() + " damage (or " + safeExpectedDamageTaken() + " with the safety margin) per round", "green");
		if (expectedRounds < roundsRemaining && my_hp() > safeExpectedDamageTaken() * (expectedRounds - 1))
			return setupAborts(foe) + macroForAction(theAttack) + "repeat;";

		// we might be able to kill in one hit, so check the "safely kill" section first (above), then ensure we can survive the next round
		if (my_hp() <= safeExpectedDamageTaken() && damageDone < monster_hp()) {
			print("we're about to die, aborting consult", "red");
			return "abort";
		}
		if (isSameAction(lastAttack, theAttack) && expectedRounds > roundsRemaining) {
			print("expecting too many turns in combat (expected rounds: " + expectedRounds + ", rounds remaining: " + roundsRemaining + ") will run until one of the aborts trips", "red");
// 			return "abort";
		}
		if (isSameAction(lastAttack, theAttack) && expectedRounds * mp_cost(theAttack.skillToUse) > my_mp()) {
			print("will run out of mp before killing, aborting consult", "red");
			return "abort";
		}

		// since we can't safely kill, see if we can choose a different attack action and try again
		lastAttack = theAttack;
		theAttack = chooseActionRecord(foe, lastAttack, damageDone);

		if (mp_cost(theAttack.skillToUse) > my_mp()) {
			print("will run out of mp before killing, aborting consult", "red");
			return "abort";
		}

		roundsRemaining = maxRounds(foe) - current_round();

		print("BOTTOM, current round: " + current_round(), "red");
	}

	print("EXITING, current round: " + current_round(), "red");
	return "";
}



void init(monster foe) {
	gCannotDebuffEnough = false;

	print("init: attackStat: "+ attackStat() + ", canStagger: " + canStagger(foe) + ", shouldDebuff: " + shouldDebuff() + ", wantToStasis: " + wantToStasis(), "green");
}


string customScriptWithDefaultKillHelperTop(int initround, monster foe, string aPage) {
	int currentRound = initround;
	init(foe);
	string scriptString = startFight(foe);

	if (currentRound == 1)
		scriptString = doPickpocketAndDebuff(foe, scriptString);
	else {
		// WORKAROUND: KoL stats are not consistent with reality until we interact with the monster -- do that here before we get to the main debuff calculations
		scriptString = resyncMonsterStats(foe, scriptString);

		scriptString = doDebuff(foe, scriptString);
	}
	currentRound = current_round();

	if ((expected_damage() > (my_maxhp() * 0.02)) && canStagger(foe)) // TODO expected_damage() > the amount healed at the end of a fight
		scriptString = doClassStun(foe, scriptString);

	return scriptString;
}

string customScriptWithDefaultKillHelperBottom(string scriptString, int initround, monster foe, string aPage, string customScript) {
	scriptString = doItemsAndBuffs(foe, scriptString);
	scriptString = doClassSkills(foe, scriptString);
	scriptString = doLocationSpecific(scriptString);

	scriptString += customScript + ";";

	scriptString = doMainLoop(foe, scriptString);
	return scriptString;
}

// inserts a custom script at the end of the usual preamble stuff, then kills the monster with
// whatever would have normally done so
string customScriptWithOlfactAndDefaultKill(int initround, monster foe, string aPage, string customScript) {
	print("customScriptWithOlfactAndDefaultKill: " + foe + ", script: '" + customScript + "'", "green");
	string scriptString = customScriptWithDefaultKillHelperTop(initround, foe, aPage);
	scriptString = doOlfaction(foe, scriptString);
	scriptString = customScriptWithDefaultKillHelperBottom(scriptString, initround, foe, aPage, customScript);
	if (scriptString != "")
		executeScript(scriptString);
	return "abort";
}

string customScriptWithDefaultKill(int initround, monster foe, string aPage, string customScript) {
	print("customScriptWithDefaultKill: " + foe + ", script: '" + customScript + "'", "green");
	string scriptString = customScriptWithDefaultKillHelperTop(initround, foe, aPage);
	scriptString = customScriptWithDefaultKillHelperBottom(scriptString, initround, foe, aPage, customScript);
	if (scriptString != "")
		executeScript(scriptString);
	return "abort";
}



string instaKillWithOlfact(int initround, monster foe, string aPage) {
	PrioritySkillRecord instaKillSkill = chooseInstaKillSkill();
	if (instaKillSkill.theSkill == $skill[none])
		abort("no insta kill skill!");

	return customScriptWithOlfactAndDefaultKill(initround, foe, aPage, "skill " + instaKillSkill.theSkill + ";");
}


string instaKill(int initround, monster foe, string aPage) {
	PrioritySkillRecord instaKillSkill = chooseInstaKillSkill();
	if (instaKillSkill.theSkill == $skill[none])
		abort("no insta kill skill!");

	return customScriptWithDefaultKill(initround, foe, aPage, "skill " + instaKillSkill.theSkill + ";");
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
	string scriptString = defaultKill(initround, foe, aPage);
}



