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
	check(count(items) == 3, "the default fence list names three real items, got " + count(items));
	check(items[$item[drum machine]] && items[$item[Special Seasoning]] && items[$item[inflammable leaf]], "the default fence list");
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
		check(!(smmDPhaseNames[0] == t.id || smmDPhaseNames[1] == t.id || smmDPhaseNames[2] == t.id || smmDPhaseNames[3] == t.id || smmDPhaseNames[5] == t.id),
			t.id + " does not share a name with a phase");
	}
	// in the legacy profile nothing the old dailyGrind did not do runs by itself
	same(smmDTasks[smmDTaskIndex["garbo"]].mode_legacy, "dry", "garbo is announced, not run, in the legacy profile");
	same(smmDTasks[smmDTaskIndex["route.paid"]].mode_legacy, "off", "the route runs once in the legacy profile");
	same(smmDTasks[smmDTaskIndex["oasis"]].mode_plan, "off", "the plan profile leaves the Oasis turns to garbo");
	check(smmDTasks[smmDTaskIndex["close.book"]].phase == 5 && smmDTaskIndex["close.book"] < smmDTaskIndex["close.spend"], "purchases are booked before the spending step");
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
	testAuditTable();
	testRegistry();
	if (failures == 0) print("PASS smmDailyGateTest: " + checks + " checks");
	else print("FAILED smmDailyGateTest: " + failures + " of " + checks + " checks", "red");
}
