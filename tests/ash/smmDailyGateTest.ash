// Offline tests for smmDaily's spending arithmetic, session-log booking,
// fence record, garbo arguments and audit table. Run by
// tests/smmdaily-tests.sh in a logged-out KoLmafia.

import <smmDailyTasks.ash>

int checks;
int failures;

void check(boolean ok, string what) {
	checks += 1;
	if (!ok) {
		failures += 1;
		print("FAIL: " + what, "red");
	}
}

void same(string got, string want, string what) {
	check(length(got) == length(want) && got.index_of(want) == 0, what + ": got '" + got + "', want '" + want + "'");
}

void testAllowance() {
	check(smmSpendAllowance(1000000, 0, 0, 0.5) == 500000, "half of the day's net");
	check(smmSpendAllowance(1000000, 0, 300000, 0.5) == 200000, "operating spend comes out of the allowance");
	check(smmSpendAllowance(1000000, 150000, 300000, 0.5) == 50000, "and so do smmSpend's own buys");
	check(smmSpendAllowance(1000000, 200000, 300000, 0.5) == 0, "exactly used up");
	check(smmSpendAllowance(1000000, 400000, 300000, 0.5) == 0, "over the cap is 0, not negative");
	check(smmSpendAllowance(-50000, 0, 0, 0.5) == 0, "nothing on a losing day");
	check(smmSpendAllowance(0, 0, 250000, 0.5) == 0, "operating spend with no net leaves nothing");
	check(smmSpendAllowance(999, 0, 0, 0.5) == 499, "rounds down");
	check(smmSpendAllowance(1000000, 0, 0, 0.25) == 250000, "a smaller fraction");
	check(smmSpendAllowance(1000000, -5, -5, 0.5) == 500000, "negative inputs cannot add allowance");
}

string kLog =
	"mallsearch \"drum machine\"\n"
	+ "\n"
	+ "buy 1 drum machine for 3400 each from shop #1733788 on 20261123\n"
	+ "Preference _concoctionDatabaseRefreshes changed from 109 to 110\n"
	+ "> newly acquired 1 drum machine @ 3400\n"
	+ "buy 3 drum machine for 3500 each from shop #22 on 20261123\r\n"
	+ "buy 1 oversized sparkler for 900 each from Clan Underground Fireworks Shop\n"
	+ "You spent 900 Meat\n"
	+ "buy 7 turtle pheromones for 500 each from Smacketeria\n"
	+ "buy 2 recipe for disaster for 1,250 each from shop #5 on 20261123\n"
	+ "Trade 1 flimsy hardwood scraps for 1 maple magnet\n"
	+ "> buy 5 would-be command for 100 each from shop #1 on 20261123\n"
	+ "buy 0 nothing for 100 each from shop #9 on 20261123\n"
	+ "buy 1 free thing for 0 each from shop #9 on 20261123\n"
	+ "[182] Cook 1 Vegetable of Jarlsberg + 1 Vegetable of Jarlsberg\n"
	+ "buy 1 bubblin' crude for 120 each from shop #3888700 on 20261123";

void testPurchases() {
	SmmDPurchase [int] p = smmDParsePurchases(kLog);
	check(count(p) == 6, "six purchases found, got " + count(p));
	same(p[0].name, "drum machine", "item name");
	check(p[0].quantity == 1 && p[0].price == 3400 && p[0].mall, "mall purchase fields");
	same(p[0].source, "shop #1733788", "the date is not part of the shop");
	check(p[1].quantity == 3 && p[1].price == 3500 && p[1].mall, "a line ending in CRLF");
	same(p[2].source, "Clan Underground Fireworks Shop", "NPC store name");
	check(!p[2].mall && !p[3].mall, "NPC purchases are not mall purchases");
	same(p[4].name, "recipe for disaster", "an item with ' for ' in its name");
	check(p[4].price == 1250, "a price with a comma");
	same(p[5].name, "bubblin' crude", "the last line, with no newline after it");
	check(smmDPurchaseTotal(p) == 3400 + 3 * 3500 + 900 + 7 * 500 + 2 * 1250 + 120, "total Meat");
	check(count(smmDParsePurchases("")) == 0, "an empty log has no purchases");

	SmmDBought [int] bought = smmDMallBought(p);
	check(count(bought) == 3, "three items bought in the mall");
	same(bought[0].name, "drum machine", "biggest spend first");
	check(bought[0].quantity == 4 && bought[0].paid == 13900, "copies of one item are added up");
	same(bought[2].name, "bubblin' crude", "smallest spend last");
}

void testBooking() {
	check(smmDOperatingFrom(10000, 4000, 0) == 6000, "the log's total less smmSpend's own buys");
	check(smmDOperatingFrom(10000, 0, 0) == 10000, "all of it when smmSpend bought nothing");
	check(smmDOperatingFrom(10000, 4000 + 3500, 0) == 2500, "the diet's purchases are on its own budget, so they come off too");
	check(smmDDietBudgetFrom("") == 500000, "the diet's budget has a default");
	check(smmDDietBudgetFrom("250000") == 250000, "smm.diet.budget sets the diet's budget");
	check(smmDDietBudgetFrom("0") == 0, "a budget of 0 buys nothing");
	check(smmDDietBudgetFrom("-5") == 0, "a negative budget is 0");
	check(smmDDietBudgetFrom("lots") == 500000, "a budget that is not a number is the default");
	check(smmDOperatingFrom(3000, 4000, 0) == 0, "never negative");
	check(smmDOperatingFrom(10000, 4000, 9000) == 9000, "never goes down within a day");
	check(smmDOperatingFrom(0, 0, 0) == 0, "an empty log books nothing");

	check(smmDOverpaid(3, 3300, 1000.0) == 300, "Meat above the average sale price");
	check(smmDOverpaid(3, 2700, 1000.0) == 0, "under the average is not overpaying");
	check(smmDOverpaid(3, 3300, 0.0) == 0, "an unknown average claims nothing");
	check(smmDOverpaid(2, 2001, 1000.4) == 0, "the average is rounded up before comparing");
}

void testFence() {
	int drum = $item[drum machine].to_int();
	int leaf = $item[inflammable leaf].to_int();
	check(drum > 0 && leaf > 0, "the fence test items exist");
	string stored = drum + ":5|" + leaf + ":12";
	int [item] fenced = smmDParseFenced(stored);
	check(count(fenced) == 2 && fenced[$item[drum machine]] == 5 && fenced[$item[inflammable leaf]] == 12, "fence record parses");
	check(count(smmDParseFenced(smmDFencedToString(fenced))) == 2, "fence record round trip");
	check(smmDParseFenced(smmDFencedToString(fenced))[$item[inflammable leaf]] == 12, "fence record round trip keeps counts");
	check(count(smmDParseFenced("")) == 0, "an empty record is empty");
	check(count(smmDParseFenced("garbage|0:3|" + drum + ":0|" + drum + ":x:1")) == 0, "malformed parts are ignored");
	fenced[$item[drum machine]] = 0;
	same(smmDFencedToString(fenced), leaf + ":12", "an item taken back drops out of the record");
	check(smmDParseFenced(drum + ":2|" + drum + ":3")[$item[drum machine]] == 5, "repeated items add up");

	boolean [item] items = smmDFenceItems();
	check(count(items) == 4, "the default fence list names four real items, got " + count(items));
	check(items[$item[drum machine]] && items[$item[Special Seasoning]] && items[$item[inflammable leaf]], "the default fence list");
	check(items[$item[Cincho de Mayo]], "the Cincho de Mayo is fenced, so garbo cannot spend the free rests and Cinch kept for Fiesta Exits");
}

void testGarbo() {
	same(smmDTGarboCommand(10, ""), "garbo -10", "garbo leaves N turns");
	same(smmDTGarboCommand(0, ""), "garbo -1", "never 'garbo 0' or a bare 'garbo': those mean no limit");
	same(smmDTGarboCommand(-5, ""), "garbo -1", "a negative setting cannot become a positive turn count");
	same(smmDTGarboCommand(25, "nobarf"), "garbo -25 nobarf", "extra arguments follow the turn count");
	same(smmDTGarboArgsProblem(""), "", "no extra arguments is fine");
	same(smmDTGarboArgsProblem("nobarf"), "", "a harmless argument is allowed");
	check(smmDTGarboArgsProblem("ascend") != "", "ascend is refused");
	check(smmDTGarboArgsProblem("nobarf ASCEND") != "", "ascend is refused in any case and position");
	check(smmDTGarboArgsProblem("workshed=cmc") != "", "workshed= is refused");
	check(smmDTGarboArgsProblem("quick") != "", "quick is refused");
	check(smmDTGarboArgsProblem("100") != "", "a turn count is refused");
	check(smmDTGarboArgsProblem("-5") != "", "a negative turn count is refused");
	check(smmDTGarboArgsProblem("turns=3") != "", "turns= is refused");
	// logged out valueOfAdventure reads 0, which is outside the allowed range
	check(smmDTGarboReady() != "", "garbo is not ready with valueOfAdventure outside 3,500 to 10,000");

	// the second garbo run stops at the diet's stop point
	check(smmDTStopPoint("") == 0 && smmDTStopPoint("x") == 0 && smmDTStopPoint("-3") == 0, "no usable stop point holds nothing back");
	check(smmDTStopPoint("17") == 17, "the stop point diet.js recorded");
	same(smmDTGarboFinalCommand(0, ""), "garbo", "with nothing to hold, the last garbo run spends every adventure");
	same(smmDTGarboFinalCommand(17, ""), "garbo -17", "otherwise it leaves the stop point");
	same(smmDTGarboFinalCommand(17, "nobarf"), "garbo -17 nobarf", "extra arguments follow");
	same(smmDTDietCommand("execute"), "call diet.js execute yes", "diet.js is told yes: smmdaily never waits on a question");
}

void testForcedNoncombats() {
	// Cinch: 100 to start, a rest refills 30 for each of the first five, then 25, 20, 15, 10, then 5
	check(smmDTCinchRestore(0) == 30 && smmDTCinchRestore(4) == 30, "the first five rests refill 30");
	check(smmDTCinchRestore(5) == 25 && smmDTCinchRestore(8) == 10 && smmDTCinchRestore(9) == 5 && smmDTCinchRestore(30) == 5, "then 25, 20, 15, 10, then 5");
	check(smmDTFiestaExitsLeft(0, 0, 0) == 1, "1 Fiesta Exit with no rests");
	check(smmDTFiestaExitsLeft(0, 0, 1) == 2, "2 with 1 rest");
	check(smmDTFiestaExitsLeft(0, 0, 3) == 3 && smmDTFiestaExitsLeft(0, 0, 5) == 4 && smmDTFiestaExitsLeft(0, 0, 8) == 5, "3 with 3, 4 with 5, 5 with 8");
	check(smmDTFiestaExitsLeft(0, 0, 17) == 6, "6 with 17");
	check(smmDTFiestaExitsLeft(0, 0, 31) == 7, "Tquilla's 31 free rests pay for 7 (430 Cinch)");
	check(smmDTFiestaExitsLeft(100, 31, 0) == 0, "none once garbo has rested 31 times and spent the Cinch");
	check(smmDTFiestaExitsLeft(60, 0, 0) == 0, "40 Cinch and no rests is not an exit");
	check(smmDTaskIndex["forced.nc"] < smmDTaskIndex["garbo"], "the forced noncombats are spent before garbo can take the rests and Cinch");
	same(smmDTasks[smmDTaskIndex["forced.nc"]].mode_legacy, "legacy", "and they run in the legacy profile");
}

void testHold() {
	same(smmDLHoldReason("true", "true", true), "", "both answers yes: carry on");
	same(smmDLHoldReason("", "", true), "", "unset answers never stop the run");
	check(smmDLHoldReason("false", "true", false) != "", "useBanishers=false stops the run");
	check(smmDLHoldReason("false", "", true) != "", "useBanishers=false stops whatever the bottle holds");
	check(smmDLHoldReason("true", "false", true) != "", "highItem=false stops while the champagne bottle is usable");
	same(smmDLHoldReason("true", "false", false), "", "highItem=false does not stop once the bottle is spent, as in dailyGrind");
	check(smmDTaskIndex["bounty"] < smmDTaskIndex["hold"] && smmDTaskIndex["hold"] < smmDTaskIndex["champagne"], "the hold sits between the bounty and the champagne bottle");
	check(smmDTasks[smmDTaskIndex["hold"]].repeatable, "the hold applies on every run, not once a day");
	same(smmDTasks[smmDTaskIndex["route"]].done_fn, "smmDLRouteDone", "the route is done only when it came back clean");
	same(smmDTasks[smmDTaskIndex["route.paid"]].done_fn, "smmDLRoutePaidDone", "and so is its paid pass");
}

void testGrindValue() {
	// tradeable, listed at, average sale price, autosell
	check(dailyGrindItemValueFrom(true, 4969, 4700.0, 20) == 4700, "a grind's loot is valued at what it sells for");
	check(dailyGrindItemValueFrom(true, 3000, 3234.0, 20) == 3000, "never above the lowest listing");
	check(dailyGrindItemValueFrom(true, 999999, 0.0, 15) == 15, "an item with no recent sales is worth its autosell price, not its asking price");
	check(dailyGrindItemValueFrom(true, 0, 812.0, 15) == 812, "an item with no listing is worth its sale price");
	check(dailyGrindItemValueFrom(false, 0, 0.0, 40) == 40, "an untradeable item is worth its autosell price");
}

void testGrindSkip() {
	// runs, return per turn, minDays, earlyDays, turn value, Museum item still short
	same(dailyGrindSkipReason(0, -1, 5, 2, 4500, false), "", "a grind with no history runs");
	same(dailyGrindSkipReason(1, 100, 5, 2, 4500, false), "", "one day is not enough to drop a grind");
	check(dailyGrindSkipReason(2, 2000, 5, 2, 4500, false) != "", "after 2 days a grind under half the turn value is dropped");
	same(dailyGrindSkipReason(2, 3000, 5, 2, 4500, false), "", "after 2 days a grind over half the turn value still runs");
	check(dailyGrindSkipReason(5, 3000, 5, 2, 4500, false) != "", "after 5 days a grind under the turn value is dropped");
	same(dailyGrindSkipReason(5, 4500, 5, 2, 4500, false), "", "a grind at the turn value runs");
	same(dailyGrindSkipReason(9, 100, 5, 2, 4500, true), "", "a grind whose Museum item is still short runs");
}

void testFeelEnvy() {
	// rate, type, item drop %, value
	check(feelEnvyMissingValue(10.0, "", 0.0, 10000) == 9000, "a 10% drop: Feel Envy adds 90% of its value");
	check(feelEnvyMissingValue(10.0, "", 900.0, 10000) == 0, "item drop that already makes it certain: nothing added");
	check(feelEnvyMissingValue(10.0, "n", 900.0, 10000) == 9000, "a drop item drop does not touch: still 90%");
	check(feelEnvyMissingValue(10.0, "p", 0.0, 10000) == 0, "a pickpocket-only drop is left out");
	check(feelEnvyMissingValue(10.0, "c", 0.0, 10000) == 0, "a conditional drop is left out");
	check(feelEnvyMissingValue(0.0, "", 0.0, 10000) == 0, "a drop of unknown rate is left out");
	check(feelEnvyMinGain() > 0, "Feel Envy needs a gain worth something");
}

void testForcedNcTargets() {
	ForcedNcTarget t = parseForcedNcTarget("The Haunted Billiards Room; choice 875 = 1 ; 2");
	check(t.where == $location[The Haunted Billiards Room], "a target's location is read");
	check(t.choice == 875 && t.option == 1, "a target's choice and option are read");
	check(t.perDay == 2, "a target's times a day are read");
	same(forcedNcTargetProblem(t), "", "a complete target is usable");
	check(forcedNcTargetProblem(parseForcedNcTarget("Nowhere Special;choice 1=1;1")) != "", "an unknown location is refused");
	check(forcedNcTargetProblem(parseForcedNcTarget("The Haunted Billiards Room;875;1")) != "", "a target without a choice is refused");
	check(forcedNcTargetProblem(parseForcedNcTarget("The Haunted Billiards Room;choice 875=1")) != "", "a target without a count is refused");
}

void testMpSources() {
	// Logged out nothing is owned, so no source is offered. What matters here
	// is the one that must never be offered whatever is owned.
	same(smmDNextFreeMP(5000), "", "no free MP source is offered with nothing owned");
	boolean restsListed = false;
	foreach i, line in smmDTPools if (smmDTParsePool(line).pref == "timesRested") restsListed = true;
	check(restsListed, "free rests are still reported in the audit");
	check(!smmDMpWorthRestoring(100), "no free restore is spent while maximum MP is 100");
	check(smmDMpWorthRestoring(20122), "free restores are used at a normal maximum");
}

void testAuditTable() {
	check(count(smmDTPools) >= 30, "the audit table is there");
	boolean [string] labels;
	foreach i, line in smmDTPools {
		SmmDPool pool = smmDTParsePool(line);
		string problem = smmDTPoolProblem(pool);
		check(problem == "", "audit line '" + line + "': " + problem);
		check(pool.limit >= 0, "audit line '" + line + "' has a use limit");
		check(!(labels contains pool.label), "audit label '" + pool.label + "' appears once");
		labels[pool.label] = true;
		smmDTPoolOwned(pool); // must not abort logged out
	}
	SmmDPool bad = smmDTParsePool("x|_x|1|item:no such item at all zzz");
	check(smmDTPoolProblem(bad) != "", "an unknown item is reported");
	check(smmDTPoolProblem(smmDTParsePool("x|_x|1|pref:noEquals")) != "", "a pref requirement needs name=value");
	check(smmDTPoolProblem(smmDTParsePool("x|_x|1|wand:thing")) != "", "an unknown kind of requirement is reported");
	check(smmDTPoolProblem(smmDTParsePool("only a label")) != "", "a short line is reported");
	check(smmDTPoolUsed("true") == 1 && smmDTPoolUsed("false") == 0 && smmDTPoolUsed("") == 0 && smmDTPoolUsed("7") == 7, "use counts from number and true/false preferences");
}

void testRegistry() {
	check(count(smmDTasks) >= 30, "the day's tasks are registered");
	int phase = 0;
	foreach i, t in smmDTasks {
		check(t.phase >= phase, t.id + " is in phase order");
		phase = t.phase;
		check(smmDPhaseNames contains t.phase, t.id + " is in a known phase");
		check(t.about != "", t.id + " has a description");
		check(smmDValidMode(t.mode_legacy) && smmDValidMode(t.mode_plan), t.id + " has valid default modes");
		check(t.do_fn != "" || t.legacy_fn != "", t.id + " has something to run");
		check(!t.museum || t.spends_turns, t.id + ": a Museum grind spends turns");
		boolean phaseName = false;
		foreach p, name in smmDPhaseNames if (name == t.id && t.id != "garbo") phaseName = true; // the garbo task is its phase
		check(!phaseName, t.id + " does not share a name with a phase");
	}
	// since 2026-11-24 the legacy profile runs the whole day: garbo and the nightcap too
	same(smmDTasks[smmDTaskIndex["garbo"]].mode_legacy, "on", "garbo runs in the legacy profile");
	foreach id in $strings[diet, forced.nc, nightcap.before, diet.turngen, garbo.final, diet.finish, goodnight.adv, goodnight]
		check(smmDTaskWanted(id), id + " runs in the legacy profile");
	check(smmDTaskIndex["drip.prep"] < smmDTaskIndex["diet"], "the drippy nugget and wine go in before the diet fills the organs");
	check(smmDTaskIndex["garbo"] < smmDTaskIndex["nightcap.before"] && smmDTaskIndex["nightcap.before"] < smmDTaskIndex["diet.turngen"]
		&& smmDTaskIndex["diet.turngen"] < smmDTaskIndex["garbo.final"] && smmDTaskIndex["garbo.final"] < smmDTaskIndex["diet.finish"]
		&& smmDTaskIndex["diet.finish"] < smmDTaskIndex["goodnight.adv"] && smmDTaskIndex["goodnight.adv"] < smmDTaskIndex["goodnight"],
		"the nightcap runs in the order it was run by hand");
	check(smmDTaskIndex["goodnight"] < smmDTaskIndex["close.report"], "the report comes after good_night, so its unused list is the day's real one");
	check(smmDTasks[smmDTaskIndex["garbo.final"]].spends_turns && !smmDTasks[smmDTaskIndex["goodnight.adv"]].spends_turns,
		"the last garbo run spends turns; the overdrunk turns are not blocked as turns");
	same(smmDTasks[smmDTaskIndex["route.paid"]].mode_legacy, "off", "the route runs once in the legacy profile");
	same(smmDTasks[smmDTaskIndex["oasis"]].mode_plan, "off", "the plan profile leaves the Oasis turns to garbo");
	check(smmDPhaseNames[smmDTasks[smmDTaskIndex["close.book"]].phase] == "close" && smmDTaskIndex["close.book"] < smmDTaskIndex["close.spend"], "purchases are booked before the spending step");
	check(smmDTaskIndex["mp.bootstrap"] < smmDTaskIndex["breakfast.second"], "MP is restored before second breakfast");
	check(smmDTaskIndex["day.open"] == 0, "the day opens first");
	same(smmDHookBeforeTask, "smmDMpHook", "the MP check runs before each task");
	same(smmDHookRunStart, "smmDLRunStart", "the prompt answers are set for the run");

	check(count(smmDTSettingWarnings()) >= 1, "setting warnings can be computed logged out");
}

void main() {
	testAllowance();
	testPurchases();
	testBooking();
	testFence();
	testGarbo();
	testHold();
	testForcedNoncombats();
	testGrindValue();
	testGrindSkip();
	testFeelEnvy();
	testForcedNcTargets();
	testMpSources();
	testAuditTable();
	testRegistry();
	if (failures == 0) print("PASS smmDailyGateTest: " + checks + " checks");
	else print("FAILED smmDailyGateTest: " + failures + " of " + checks + " checks", "red");
}
