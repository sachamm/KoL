// smmDaily: today's code, one task at a time. See docs/daily-script.md.
//
// Each function here is a block lifted from dailyGrind() in
// smmUnrestricted.ash, unchanged in what it does, so that the engine can
// order, skip, time and journal the pieces. Nothing new is decided here. When
// a piece gets a new implementation it moves out of this file.
//
// A "Ready" function answers "" when the task can run now, else the reason.

import <smmUnrestricted.ash>
import <smmDailyGate.ash>

int smmDLMaxPerTurnCost() {
	return my_class() == $class[seal clubber] ? 0 : 100; // Batter Up! is a beast
}

// dailyGrindMayRun prints its own reason (switched off, over the paid-turn
// budget, or under the turn value on its logged history).
string smmDLControls(string grind) {
	return dailyGrindMayRun(grind) ? "" : "held back by the dailyGrind controls (smm.dailyGrind." + grind + ", see the line above)";
}

// ---------------------------------------------------------------------------
// Breakfast and the free work

void smmDLStore() {
	stockStore(gkStoreHeartbeat);
}

boolean smmDLSecondBreakfastDone() {
	return get_property(gkSecondBreakfastDoneKey).to_boolean();
}

void smmDLSecondBreakfast() {
	secondBreakfast(endGameTurnsSpent());
	burnHP();
	burnMP();
}

// The route returns early, with work left, when a worker ends in a fight, a
// choice or Beaten Up, or when smm.IR.maxActions is reached. dailyGrind()
// simply called it again on the next run. Here the route counts as done only
// when it came back clean, so an interrupted one is picked up again.
boolean smmDLRouteCameBackClean() {
	if (handling_choice() || current_round() > 0 || have_effect($effect[Beaten Up]) > 0) return false;
	string cap = get_property("smm.IR.maxActions");
	if (cap == "") return true;
	matcher summary = create_matcher("SUMMARY\\tactions=([0-9]+)", file_to_buffer("smm-iotm-route-last.txt").to_string());
	return find(summary) && group(summary, 1).to_int() < max(1, cap.to_int());
}

void smmDLRoute(boolean free_only, string key) {
	set_property(key, "");
	smmIRDailyRoute(free_only, true);
	if (smmDLRouteCameBackClean()) set_property(key, "true");
	else print("smmDaily: the IoTM route stopped with work left; the next smmdaily run picks it up.", "orange");
}

void smmDLRouteAll() {
	smmDLRoute(false, "_smm.daily.routeClean.all");
}

void smmDLRouteFree() {
	smmDLRoute(true, "_smm.daily.routeClean.free");
}

// A whole-route pass covers the free actions too.
boolean smmDLRouteDone() {
	return get_property("_smm.daily.routeClean.all") == "true" || get_property("_smm.daily.routeClean.free") == "true";
}

boolean smmDLRoutePaidDone() {
	return get_property("_smm.daily.routeClean.all") == "true";
}

void smmDLDeeds() {
	dailyDeedsAdv(); // 0 adv
}

// ---------------------------------------------------------------------------
// The grinds, in dailyGrind's order

// dailyGrind() decides this first thing, before breakfast and the route can
// spend turns of the Fishy left from yesterday's pipe. The start of every run
// does the same here (smmDLRunStart), so the test below sees the answer.
void smmDLNoteFishy() {
	if (have_effect($effect[Fishy]) >= 8)
		set_property(gDailyFishingGrindKey, "true");
}

string smmDLFishingReady() {
	if (have_effect($effect[Fishy]) >= 8 || get_property(gDailyFishingGrindKey).to_boolean()) return "";
	return "no Fishy left over from yesterday";
}

void smmDLFishing() {
	smmDLNoteFishy();
	dailyFishingGrind(endGameTurnsSpent(), smmDLMaxPerTurnCost()); // 20 turns, burns item buffs
}

void smmDLBounty() {
	doBounty(); // 20 adv, 5 banishers?
}

// garbageChampagneCharge() can fold the garbage tote, so the readiness test
// reads the same two preferences without calling it.
// dailyGrind() stops after the bounty when smm.dailyGrind.useBanishers is
// false, or when smm.dailyGrind.highItem is false and the champagne bottle
// could still be used, so that the banishers and item-drop buffs are kept for
// work done by hand. An unset answer never stops: the engine does not ask.
// Returns why the run should stop here, "" when it should carry on.
string smmDLHoldReason(string useBanishers, string highItem, boolean champagneUsable) {
	if (useBanishers == "false") return "smm.dailyGrind.useBanishers is false: stopped before the banishers are used";
	if (highItem == "false" && champagneUsable) return "smm.dailyGrind.highItem is false: stopped before the high item drop section";
	return "";
}

string smmDLHoldNow() {
	boolean champagneUsable = get_property("garbageChampagneCharge").to_int() > 0 || !get_property("_garbageItemChanged").to_boolean();
	return smmDLHoldReason(get_property("smm.dailyGrind.useBanishers"), get_property("smm.dailyGrind.highItem"), champagneUsable);
}

string smmDLHoldReady() {
	return smmDLHoldNow() != "" ? "" : "neither smm.dailyGrind.useBanishers nor smm.dailyGrind.highItem asks for a stop";
}

void smmDLHold() {
	smmDStopRun = smmDLHoldNow();
}

string smmDLChampagneReady() {
	if (get_property("garbageChampagneCharge").to_int() > 0 || !get_property("_garbageItemChanged").to_boolean()) return "";
	return "the champagne bottle has no charge and the tote was already folded today";
}

void smmDLChampagne() {
	if (garbageChampagneCharge() <= 0) return;
	int [location] endGameTurnsSpent = endGameTurnsSpent();
	burnChampagneBottle( !isRegularClass()
						|| ! (endGameTurnsSpent[$location[Dreadsylvanian Woods]] < 930
							&& endGameTurnsSpent[$location[Dreadsylvanian Village]] < 930
							&& (my_basestat($stat[muscle]) >= 200
								&& my_basestat($stat[mysticality]) >= 200
								&& my_basestat($stat[moxie]) >= 200)) );
}

void smmDLScience() {
	grindScience(true); // useSweetSynthesis?
}

// The quest can finish before the 10 free turns are used; nep party then
// fights the rest.
string smmDLNepReady() {
	if (get_property("_neverendingPartyFreeTurns").to_int() >= 10) return "the 10 free party turns are used";
	return "";
}

void smmDLNep() {
	boolean unused = cli_execute("nep prep; nep party;"); // Neverending Party -- prep or prephard
}

boolean smmDLPregrindDone() {
	return get_property("_smm.LandPreGrindDone").to_boolean();
}

void smmDLPregrind() {
	int birdsToSeek = 6 - to_int(get_property("_birdsSoughtToday"));
	if (have_skill($skill[seek out a bird]) && birdsToSeek > 0) {
		if (!use_skill($skill[seek out a bird], birdsToSeek)) // optional buff, don't stop the run over it
			print("couldn't seek out all " + birdsToSeek + " birds, continuing", "orange");
	}
	maximizeForItemDrop(1, $location[none]);
	// print-only reports that cost a turn of Asdon fuel and two outfit changes: opt in
	if (get_property("smm.dailyGrind.incomeReport") == "true") {
		currentIncome();
		incomeCalculator();
	}
	set_property("_smm.LandPreGrindDone", "true");
}

boolean smmDLBeerLensPending() {
	return smmDTaskWanted("beerLens") && get_property("_beerLensDrops").to_int() < 3 && dailyGrindMayRun("beerLens");
}

boolean smmDLGhostCostumePending() {
	return smmDTaskWanted("ghostCostume") && !to_boolean(get_property("_smm.GotGhostCostume"))
		&& my_session_items($item[li'l ghost costume]) < 1 && dailyGrindMayRun("ghostCostume");
}

boolean smmDLOasisDone() {
	return get_property("_smm.GrindDone").to_boolean();
}

void smmDLOasis() {
	int maxPerTurnCost = smmDLMaxPerTurnCost();
	// keep banishes back only for the banisher grinds still to do today
	int kSaveBanishes = (smmDLBeerLensPending() ? 4 : 0) + (smmDLGhostCostumePending() ? 8 : 0);
	if (banishesAvailable(maxPerTurnCost) > kSaveBanishes && my_adventures() > 10 && dailyGrindMayRun("oasis")) {
		dailyGrindBegin("oasis");
		int perAdventureCost = perAdventureCost($location[The Oasis]);
		int beatleValue = scarabBeatleValue(perAdventureCost);
		int blurValue = monsterCurrentTotalMeatValue($monster[blur], false) - perAdventureCost;
		print("swarm of scarab beatles: " + beatleValue + ", blurs: " + blurValue, "blue");

		if (beatleValue > kTurnValue && beatleValue > blurValue)
			grindScarabBeatles(maxPerTurnCost, true, kSaveBanishes); // maxPerTurnCost, getBlur, banishes to save
		else if (blurValue > kTurnValue)
			grindDrumMachine(maxPerTurnCost, true, kSaveBanishes); // maxPerTurnCost, getBeatlesOnYellowRay, banishesToSave

		dailyGrindEnd("oasis");
	}
	// Set even when no farming happened: this phase saves banishers and may skip
	// farming (or have no banishes available) or leave yellow rays unused.
	set_property("_smm.GrindDone", "true");
}

string smmDLBeerLensReady() {
	if (get_property("_beerLensDrops").to_int() >= 3) return "all 3 beer lenses have dropped";
	return smmDLControls("beerLens");
}

void smmDLBeerLens() {
	dailyGrindBegin("beerLens");
	grindBeerLens(smmDLMaxPerTurnCost()); // 3-5 adv, 4 banishers
	dailyGrindEnd("beerLens");
}

string smmDLGhostCostumeReady() {
	if (to_boolean(get_property("_smm.GotGhostCostume")) || my_session_items($item[li'l ghost costume]) >= 1)
		return "today's li'l ghost costume is in hand";
	return smmDLControls("ghostCostume");
}

void smmDLGhostCostume() {
	dailyGrindBegin("ghostCostume");
	grindGhostCostume(); // 5-11 adv, 9 banishers
	dailyGrindEnd("ghostCostume");
}

string smmDLSpacegateReady() { return smmDLControls("spacegate"); }

void smmDLSpacegate() {
	dailyGrindBegin("spacegate");
	try {
		saveAndSetProperty("choiceAdventure1251", "6");
		grindSpacegate(gkSpacegateCoordinates);
	} finally {
		restoreSavedProperty("choiceAdventure1251");
	}
	dailyGrindEnd("spacegate");
}

// fr.ash picks the reward closest to Museum #1 (smm.frTarget names one instead)
string smmDLFantasyRealmReady() {
	if (get_property("_fantasyRealmDone").to_boolean()) return ""; // still deposits the reward
	return smmDLControls("fantasyRealm");
}

// About 6 adventures for each hour left on the G. E. M.: 30 for a fresh visit
// (fr.ash asks before starting one with fewer). None once it is done, when
// all that is left is depositing the reward.
int smmDLFantasyRealmNeed() {
	if (get_property("_fantasyRealmDone").to_boolean()) return 0;
	int hours = get_property("_frHoursLeft").to_int();
	return hours > 0 ? 6 * hours : 30;
}

void smmDLFantasyRealm() {
	boolean unused;
	boolean frAlreadyDone = get_property("_fantasyRealmDone").to_boolean();
	dailyGrindBegin("fantasyRealm");
	if (!frAlreadyDone)
		unused = cli_execute("fr best");
	item frTargetItem = get_property("_smm.frTarget").to_item();
	// warn instead of stopping: the grinds below still have daily resources to use
	if (frTargetItem == $item[none] && !frAlreadyDone)
		print("fr best didn't record its target in _smm.frTarget, continuing", "red");
	if (frTargetItem != $item[none]) {
		if (my_session_items(frTargetItem) <= 0 && !get_property("_fantasyRealmDone").to_boolean())
			print("didn't get " + frTargetItem + ", continuing", "red");
		unused = cli_execute("dc top10 " + frTargetItem);
	}
	set_property("_fantasyRealmDone", "true");
	dailyGrindEnd("fantasyRealm");
}

string smmDLPirateRealmReady() {
	if (my_session_items($item[Red Roger's reliquary]) > 0) return "Red Roger's reliquary is in hand";
	if (get_property("_smm.PirateRealmDone").to_boolean()) return "PirateRealm is done";
	return smmDLControls("pirateRealm");
}

void smmDLPirateRealm() {
	dailyGrindBegin("pirateRealm");
	boolean unused = cli_execute("pr short"); // grind PirateRealm
	dailyGrindEnd("pirateRealm");
}

string smmDLDailyDungeonReady() {
	if (get_property("dailyDungeonDone").to_boolean()) return "the Daily Dungeon is done";
	return smmDLControls("dailyDungeon");
}

void smmDLDailyDungeon() {
	dailyGrindBegin("dailyDungeon");
	grindDailyDungeon();
	dailyGrindEnd("dailyDungeon");
}

string smmDLDripReady() { return smmDLControls("drip"); }

void smmDLDrip() {
	dailyGrindBegin("drip");
	grindDrip(); // TODO: don't run on the day of breaking the prism
	dailyGrindEnd("drip");
}

// The Drip's turns come from the drippy nugget and glass of drippy wine, which
// need organ space, so they go in before the diet fills the organs.
string smmDLDripPrepReady() {
	if (!dripConsumePending()) return "no drippy nugget or glass of drippy wine to use today";
	return smmDLControls("drip");
}

void smmDLDripPrep() {
	dripConsume();
}

string smmDLDolphinReady() {
	return get_property("dolphinItem") != "" ? "" : "no dolphin item is waiting";
}

void smmDLDolphin() {
	grindDolphinItem();
}

string smmDLWorkshedReady() {
	if (get_property("_workshedItemUsed").to_boolean()) return "the workshed was already changed today";
	if (!isAsdonWorkshed()) return "the Asdon Martin is not in the workshed";
	if (!have_item($item[model train set])) return "no model train set to swap to";
	return "";
}

void smmDLWorkshed() {
	// Driving Observantly outlasts the day; smm.dailyGrind.asdonTurns sets how much fuel to commit before the swap
	int goalDuration = get_property("smm.dailyGrind.asdonTurns") == "" ? 600 : max(1, get_property("smm.dailyGrind.asdonTurns").to_int());
	boolean unused = fueled_asdonmartin("observantly", goalDuration); // the assert below reports a failure more clearly
	assert(have_effect($effect[Driving Observantly]) >= goalDuration, "didn't get " + goalDuration + " turns of Driving Observantly");
	assert(use(1, $item[model train set]), "couldn't swap the workshed to the model train set");
}

void smmDLGingerbread() {
	int [int, string] leaderboard = gingerbreadLeaderboard();
	boolean winSprinkles = leaderboard.rank1Amount() <= 3000; // we can get to 3000 in 30 turns
	int gbcTurns = effectiveGingerbreadCityTurns();

	if (winSprinkles && gbcTurns == 0) {
		print("We can win the Gingerbread City sprinkles leaderboard, but this should be done manually with 'gbc win'");
		printTop10List(leaderboard);
	} else if (winSprinkles && gbcTurns < 20) {
		print("Gingerbread City is part done (" + gbcTurns + " turns) and the sprinkles leaderboard looked winnable, finish it manually", "orange");
		printTop10List(leaderboard);
	} else if (!winSprinkles && gbcTurns < 20 && dailyGrindMayRun("gingerbread")) {
		if (gbcTurns > 0 || dailyGrindConfirm("gingerbreadItems", "We can't win the Gingerbread City sprinkles leaderboard, should we grind items?", true)) {
			dailyGrindBegin("gingerbread");
			if (!cli_execute("gbc items")) // last grind of the day, report instead of stopping
				print("'gbc items' failed, finish Gingerbread City manually", "red");
			dailyGrindEnd("gingerbread");
		}
	}
}

// ---------------------------------------------------------------------------
// Forced noncombats: spikolodon spikes, McHugeLarge Avalanche and Fiesta
// Exits (with the free rests that refill Cinch), aimed at the Shadow Rift
// choice that finishes a Rufus quest. They run before garbo, which otherwise
// spends the rests and Cinch on Projectile Pinatas (2026-11-24: 31 rests and
// 430 Cinch, no Fiesta Exit).

void smmDLForcedNoncombats() {
	grindRufusAndTheShadowRiftsForFree();
}

// ---------------------------------------------------------------------------
// The nightcap, as run by hand until 2026-11-24

void smmDLBeforeOverdrunk() {
	beforeOverdrunkGoodNight();
}

// Each overdrunk activity has its own journal entry in smmdaily.
void smmDLOverdrunkPrep() {
 automate_dressup($location[none], "item", "item", "0.1 mp, -equip \"i voted!\" sticker, -equip Kramco Sausage-o-Matic&trade;");
 smmDCombatPrepare();
}
void smmDLGoodNightRoute() {
 if (my_adventures() > 0 && smmIREnabled() && !inRonin() && my_path() == $path[none]) smmIRDailyRoute(true, true);
}
void smmDLGoodNightFax() {
 if (my_adventures() <= 0 || get_property("_photocopyUsed").to_boolean()) return;
 if (item_amount($item[photocopied monster]) <= 0 && !(get_clan_lounge() contains $item[deluxe fax machine])) return;
 smmDLOverdrunkPrep();
 burnFax(false);
}
void smmDLGoodNightSpinner() {
 if (my_adventures() <= 0) return;
 smmDLOverdrunkPrep();
 burn_timespinner();
}
void smmDLGoodNightLocket() {
 if (my_adventures() <= 0) return;
 smmDLOverdrunkPrep();
 burnCombatLoversLocket();
}
void smmDLGoodNightDaycare() { burnScavengeDaycare(min(3, my_adventures())); }
void smmDLGoodNightExcess() { burnOverdrunkExcess(); }

void smmDLGoodNightAdv() { smmDLGoodNightRoute(); }

// good_night's burnFreeTurnGen (chocolates, essential tofu, the Mayam
// calendar, the latte refill) can add adventures after good_night_adv's
// rollover check, so check again.
void smmDLGoodNight() {
	good_night();
	// spending the excess takes turns: not inside the rollover buffer
	if (smmDSecondsToRollover() < smmDSettingInt("rolloverBufferMin") * 60)
		print("goodnight: too close to rollover to spend the adventures that would pass the cap", "orange");
	else
		burnOverdrunkExcess();
}

// ---------------------------------------------------------------------------
// Close

void smmDLSpend() {
	// up to half of what the day has netted so far: positive-return buys, then Display Case items on sale
	smmSpendRun();
}

void smmDLLedger() {
	printEndGameTurnsSpent();
	printDailyGrindLedger();
}

// ---------------------------------------------------------------------------
// The yes/no questions today's code asks are answered ahead of time for the
// length of a run, with the answer each one defaults to. A preference that is
// already set is left alone.

string [string] smmDLPromptAnswers = {
	"sea": "true",
	"stopForBounty": "false",
	"useBanishers": "true",
	"highItem": "true",
	"dolphin": "true",
	"gingerbreadItems": "true",
};
boolean [string] smmDLPromptsSet;

void smmDLRunStart() {
	smmDLNoteFishy();
	foreach name, answer in smmDLPromptAnswers {
		if (get_property("smm.dailyGrind." + name) != "") continue;
		set_property("smm.dailyGrind." + name, answer);
		smmDLPromptsSet[name] = true;
	}
}

void smmDLRunEnd() {
 set_property("_smm.grind.active", "");
	foreach name in smmDLPromptsSet
		set_property("smm.dailyGrind." + name, "");
	clear(smmDLPromptsSet);
}
