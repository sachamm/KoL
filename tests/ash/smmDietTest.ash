// Offline tests for diet.ash (smmDiet.ash and smmDietOptimizer.ash): its
// spending rules (nothing bought above its average sale price, and the diet's
// own daily budget), planning under a budget, and the adventure bounds the
// stop point is built on. Run by tests/smmdaily-tests.sh in a logged-out
// KoLmafia. (They were tests/diet-spending.cjs and
// tests/nightcap-adventure-bounds.cjs for diet.js.)

import <smmDiet.ash>

int checks;
int failures;

void check(boolean ok, string what) {
	checks += 1;
	if (!ok) {
		failures += 1;
		print("FAIL: " + what, "red");
	}
}

void near(float got, float want, string what) {
	check(got - want < 0.0001 && want - got < 0.0001, what + ": got " + got + ", want " + want);
}

// --- the average sale price, as Pricegun gives it ---------------------------

string melange(string value, string sales, string history, int id) {
	return "{\"itemId\":" + id + ",\"sales\":" + sales + ",\"history\":" + history + ",\"value\":" + value + "}";
}

void testAverage() {
	string sales = "[{\"unitPrice\":215000}]";
	string history = "[{\"volume\":12}]";
	string dec = "{\"__decimal__\":\"216771.5\"}";
	near(smmDietParseAverage(melange(dec, sales, history, 1633), 1633), 216771.5, "a decimal value");
	near(smmDietParseAverage(melange("216771.5", sales, history, 1633), 1633), 216771.5, "a plain number");
	near(smmDietParseAverage(melange(dec, sales, history, 1633), 1634), 0, "another item's answer is unknown");
	near(smmDietParseAverage(melange(dec, "[]", history, 1633), 1633), 0, "no sales on record is unknown");
	near(smmDietParseAverage(melange(dec, sales, "[]", 1633), 1633), 0, "no history is unknown");
	near(smmDietParseAverage(melange("{\"__decimal__\":\"0\"}", sales, history, 1633), 1633), 0, "a zero value is unknown");
	near(smmDietParseAverage(melange("null", sales, history, 1633), 1633), 0, "a missing value is unknown");
	near(smmDietParseAverage("", 1633), 0, "no answer is unknown");
	near(smmDietParseAverage("<html>502 Bad Gateway</html>", 1633), 0, "an error page is unknown");
	near(smmDietParseAverage("null", 1633), 0, "null is unknown");
}

// --- the rule: the purchase of 2026-11-24 (326,000 against 216,771) ----------

void testRule() {
	check(smmDietAverageRule(326000, 216771.5, 0) == "drop", "above the average and none owned: left out");
	check(smmDietAverageRule(326000, 216771.5, 2) == "owned", "above the average with spare copies: only those");
	check(smmDietAverageRule(216771, 216771.5, 0) == "buy", "at the average: bought");
	check(smmDietAverageRule(150000, 216771.5, 0) == "buy", "under the average: bought");
	check(smmDietAverageRule(326000, 0, 0) == "drop", "unknown average: no unverified mall purchase");
}

// --- the most acquire may pay per copy ---------------------------------------

void testBuyCap() {
	float none = kSmmDietHuge;
	check(smmDietBuyCap(200000, 216771.5, none, 0) == 216771, "the slack on the plan never passes the average");
	check(smmDietBuyCap(100000, 216771.5, none, 0) == 130000, "under the average the plan and its slack decide");
	check(smmDietBuyCap(326000, 216771.5, none, 0) == 216771, "a plan above the average is still capped");
	check(smmDietBuyCap(1000, 0, none, 0) == 0, "unknown average: no purchase allowance");
	check(smmDietBuyCap(0, 216771.5, none, 0) == 0, "an unplanned item is not bought");
	check(smmDietBuyCap(100000, 216771.5, none, 2) == 130000, "no budget to mind: unchanged");
	check(smmDietBuyCap(100000, 216771.5, 150000, 2) == 75000, "two copies share the Meat left in the budget");
	check(smmDietBuyCap(100000, 216771.5, 500000, 2) == 130000, "plenty left: the plan and its slack decide");
	check(smmDietBuyCap(100000, 200000, 99, 1) == 99, "a price that rose past the budget is not paid");
	check(smmDietBuyCap(100000, 216771.5, 0, 1) == 0, "nothing left: nothing bought");
	check(smmDietBuyCap(100000, 216771.5, -500, 1) == 0, "an overspent budget buys nothing");
	check(smmDietCanAfford(500, 500) && !smmDietCanAfford(500, 499) && !smmDietCanAfford(1, 0) && smmDietCanAfford(1, kSmmDietHuge),
		"a store purchase or a speakeasy drink needs its price left in the budget");
	check(smmDietCanAfford(0, 0) && smmDietCanAfford(0, -100), "what costs nothing is allowed on a spent budget");
	check(smmDietSausageCost(3, 0, 0) == 666, "three sausages: 111 + 222 + 333");
	check(smmDietSausageCost(3, 5, 0) == 2331, "later sausages cost more");
	check(smmDietSausageCost(3, 0, 1000) == 0, "Meat already in the grinder pays for them");
	check(smmDietSausageCost(3, 0, 600) == 66, "or for part of them");
	check(smmDietSausageCost(0, 7, 0) == 0, "none to make costs nothing");
	check(smmDietFreeSausages(23, 0, 111) == 1, "the grinder's Meat covers the first sausage");
	check(smmDietFreeSausages(23, 0, 333) == 2, "or the first two");
	check(smmDietFreeSausages(23, 0, 0) == 0, "an empty grinder covers none");
	check(smmDietFreeSausages(2, 0, 100000) == 2, "never more than can be made");
}

// --- spare copies, as a test's own functions (called by name) ----------------

int spareNone(string name) { return 0; }
int spareTwoPlainFood(string name) { return name == "plain food" ? 2 : 0; }
int spareTwoFineFood(string name) { return name == "fine food" ? 2 : 0; }
int spareFourEach(string name) { return 4; }
int spareAll(string name) { return 23; }

// with nothing left in the budget, sausages are limited to the free ones
string grind(int free) {
	DietItem [int] list;
	DietItem e = smmDietNewItem("magical sausage");
	e.type = "simple";
	e.price = 1332;
	e.owned = true;
	e.limit = 23;
	e.free = free;
	list[0] = e;
	smmDietRestrictToOwned(list, "spareNone");
	string out = "";
	foreach i, x in list out += x.limit + "@" + to_int(x.price) + " ";
	return out;
}

void testRestrict() {
	check(grind(1) == "1@1 ", "one the grinder already paid for stays in a zero-budget plan");
	check(grind(5) == "5@1 ", "as do sausages already made");
	check(grind(0) == "", "with none free, sausages leave the plan");
}

// --- planning under a budget -------------------------------------------------

DietSettings toySettings(float value) {
	DietSettings s = new DietSettings();
	s.advValue = value;
	s.classid = 1;
	s.overdrinkCandidates = true;
	s.rolloverGain = 40;
	s.workshed = "none";
	s.organs = dtoSize(15, 14, 15);
	s.base = dtoSize(15, 14, 15);
	s.ode = true;
	return s;
}

DietItem toy(string name, float adv, string type, int f, int d, int sp, float price) {
	DietItem e = smmDietNewItem(name);
	e.advmin = adv;
	e.advmax = adv;
	e.type = type;
	if (type != "") {
		e.hasSize = true;
		e.size = dtoSize(f, d, sp);
	}
	e.price = price;
	return e;
}

void market() {
	clear(dietConsumables);
	smmDietAdd(toy("fine food", 30, "food", 5, 0, 0, 60000));
	smmDietAdd(toy("plain food", 20, "food", 5, 0, 0, 10000));
	smmDietAdd(toy("fine drink", 12, "booze", 0, 2, 0, 20000));
	smmDietAdd(toy("plain drink", 8, "booze", 0, 2, 0, 3000));
	smmDietAdd(toy("spleen thing", 5, "spleen", 0, 0, 3, 4000));
	DietItem melange = toy("spice melange", 0, "extender", -3, -3, 0, 200000);
	melange.limit = 1;
	smmDietAdd(melange);
}

record ToyFit {
	float value;
	float toBuy;
	boolean over;
	boolean ownedOnly;
	int [string] units;
};

ToyFit toyFit(DietSettings s, float room, string refreshFn, string spareFn) {
	SmmDietFit fit = smmDietFitPlan(smmDietPlanDay(s, false), s, false, room, refreshFn, spareFn);
	ToyFit t = new ToyFit();
	t.value = s.advValue;
	t.toBuy = fit.toBuy;
	t.over = fit.over;
	t.ownedOnly = fit.ownedOnly;
	t.units = smmDietPlanUnits(fit.plan);
	return t;
}

ToyFit fitMarket(float room, string refreshFn, string spareFn) {
	market();
	dietSemirareValue = 30000;
	return toyFit(toySettings(5000), room, refreshFn, spareFn);
}

string unitList(int [string] units) {
	string out = "";
	foreach name, n in units if (n != 0) out += name + "=" + n + " ";
	return out;
}

boolean meltdown;
boolean dropMelange(DietPlan plan) {
	if (meltdown) return false;
	foreach c, e in dietConsumables if (e.name == "spice melange") remove dietConsumables[c];
	meltdown = true;
	return true;
}

void testBudget() {
	ToyFit free = fitMarket(kSmmDietHuge, "", "spareNone");
	check(free.value == 5000, "with room to spare an adventure keeps its value");
	check(!free.over, "and the plan is within budget");
	check(free.units["fine food"] > 0 && free.toBuy > 100000, "the unconstrained toy day buys the fine food: " + unitList(free.units));
	market();
	near(smmDietPlanPurchaseCost(free.units, dietConsumables, "spareNone"), free.toBuy, "the cost is the units at their prices");

	ToyFit tight = fitMarket(free.toBuy - 1, "", "spareNone");
	check(tight.value < 5000, "over budget, the plan values an adventure lower");
	check(tight.toBuy <= free.toBuy - 1 && !tight.over, "and then fits the budget");
	check(tight.toBuy > 0 && !tight.ownedOnly, "a tight budget still buys the cheap adventures");

	// no room at all: only what is owned, at the full value of an adventure
	foreach room in $floats[0, -50000] {
		ToyFit broke = fitMarket(room, "", "spareTwoPlainFood");
		check(broke.toBuy == 0, "no budget left: nothing is bought");
		check(!broke.over, "and that plan is allowed");
		check(broke.ownedOnly, "it is made from owned copies only");
		check(broke.value == 5000, "at the full value of an adventure");
		check(unitList(broke.units) == "plain food=2 ", "it uses the spare copies and nothing else: " + unitList(broke.units));
	}
	// a budget too small for any purchase worth making ends the same way
	ToyFit crumbs = fitMarket(100, "", "spareTwoPlainFood");
	check(crumbs.toBuy == 0 && !crumbs.over && crumbs.ownedOnly && crumbs.value == 5000, "a budget nothing fits in buys nothing");

	// spare copies owned are not purchases
	ToyFit owned = fitMarket(kSmmDietHuge, "", "spareTwoFineFood");
	near(owned.toBuy, free.toBuy - 2 * 60000, "copies already owned cost nothing");
	DietItem [int] mixed;
	mixed[0] = toy("a", 0, "", 0, 0, 0, 100);
	mixed[1] = toy("b", 0, "", 0, 0, 0, 100);
	mixed[1].owned = true;
	mixed[2] = toy("c", 0, "", 0, 0, 0, 100);
	mixed[2].speakeasy = 1;
	mixed[3] = toy("d", 0, "", 0, 0, 0, 100);
	int [string] abc = {"a": 3, "b": 3, "c": 3};
	near(smmDietPlanPurchaseCost(abc, mixed, "spareNone"), 303, "owned-only entries cost nothing, nor unplanned ones; a speakeasy drink costs its own price");
}

// every paid resource is in the estimate, not only store purchases
DietRow toyRow(string name) {
	DietRow r = new DietRow();
	r.name = name;
	r.amount = 1;
	return r;
}

void testPaidUnits() {
	DietPlan paid = new DietPlan();
	paid.rows[0] = toyRow("Ancestral Recall");
	paid.rows[1] = toyRow("wine");
	dtoNote(paid.rows[1], "effect", "wish for", "Refined Palate", false);
	paid.rows[2] = toyRow("other wine");
	dtoNote(paid.rows[2], "effect", "wish for", "Refined Palate", false);
	paid.rows[3] = toyRow("salad");
	dtoNote(paid.rows[3], "item", "using", "fork", true);
	paid.parts[0, 2] = 10;
	paid.parts[1, 1] = 2;
	paid.parts[2, 3] = 3;
	paid.parts[3, 1] = 1;
	paid.parts[3, 3] = 1;
	int [string] u = smmDietPlanUnits(paid);
	check(unitList(u) == "blue mana=10 fork=2 other wine=3 pocket wish=1 salad=2 wine=2 ",
		"Ancestral Recall uses blue mana, and one wish serves every drink it helps: " + unitList(u));

	DietItem [int] paidFor;
	paidFor[0] = toy("blue mana", 0, "", 0, 0, 0, 10000);
	paidFor[1] = toy("Lucky Lindy", 0, "booze", 0, 1, 0, 0);
	paidFor[1].speakeasy = 500;
	paidFor[2] = toy("magical sausage", 1, "simple", 0, 0, 0, 1332);
	paidFor[2].owned = true;
	paidFor[3] = toy("pocket wish", 0, "", 0, 0, 0, 50000);
	int [string] mana = {"blue mana": 10};
	near(smmDietPlanPurchaseCost(mana, paidFor, "spareNone"), 100000, "the mana behind Ancestral Recall is a purchase");
	near(smmDietPlanPurchaseCost(mana, paidFor, "spareFourEach"), 60000, "less the mana already owned");
	int [string] lindy = {"Lucky Lindy": 3};
	near(smmDietPlanPurchaseCost(lindy, paidFor, "spareNone"), 1500, "speakeasy drinks cost Meat");
	int [string] sausages = {"magical sausage": 23};
	near(smmDietPlanPurchaseCost(sausages, paidFor, "spareAll"), 23 * 1332, "so does grinding sausages");
	int [string] wish = {"pocket wish": 1};
	near(smmDietPlanPurchaseCost(wish, paidFor, "spareNone"), 50000, "and a wish");
}

// with nothing left, the optimizer is not offered them either
ToyFit fitPaid(float room) {
	market();
	smmDietAdd(toy("blue mana", 0, "", 0, 0, 0, 10000));
	DietItem lindy = toy("Lucky Lindy", 6, "booze", 0, 1, 0, 0);
	lindy.speakeasy = 500;
	smmDietAdd(lindy);
	dietSemirareValue = 30000;
	DietSettings s = toySettings(5000);
	s.speakeasy = true;
	s.speakeasyLeft = 3;
	s.recall = true;
	s.recallLeft = 10;
	return toyFit(s, room, "", "spareNone");
}

void testPaidPlans() {
	ToyFit rich = fitPaid(kSmmDietHuge);
	check(rich.units["blue mana"] == 10 && rich.units["Lucky Lindy"] > 0, "with room, the toy day casts Ancestral Recall and drinks at the speakeasy: " + unitList(rich.units));
	foreach room in $floats[0, 1] {
		ToyFit poor = fitPaid(room);
		check(poor.toBuy == 0 && poor.units["blue mana"] == 0 && poor.units["Lucky Lindy"] == 0,
			"a budget of " + room + " pays for no mana and no speakeasy drink: " + unitList(poor.units));
	}

	// a refresh that takes an overpriced item off the list re-plans without
	// it, and that alone does not lower the value of an adventure
	meltdown = false;
	ToyFit capped = fitMarket(kSmmDietHuge, "dropMelange", "spareNone");
	check(capped.value == 5000, "a price change is not a budget squeeze");
	check(capped.units["spice melange"] == 0, "the dropped item is out of the plan");
}

// --- adventure bounds and the rollover cap -------------------------------------
// (the stop point is planned on the top of each adventure range)

void bounds(DietItem it, boolean [string] opts, float average, float maximum, string what) {
	float mean = dtoCalculateAdventures(it, opts, false);
	float top = dtoCalculateAdventures(it, opts, true);
	near(mean, average, what + ": average");
	near(top, maximum, what + ": maximum");
	int spec = dtoNewSpec(it);
	dtoSpecs[spec].adv = mean;
	dtoSpecs[spec].hasAdvmax = true;
	dtoSpecs[spec].advmax = top;
	DietRow row = toyRow(it.name);
	row.spec = spec;
	float spread = smmDietHalfRange(row);
	int stop = floor(200 - 40 - mean - spread + kDietEpsilon);
	check(stop + top + 40 <= 200, what + ": the maximum roll fits under the rollover cap");
}

DietItem ranged(string name, string type, string itemClass, int f, int d) {
	DietItem e = toy(name, 10, type, f, d, 0, 1);
	e.advmax = 14;
	e.itemClass = itemClass;
	return e;
}

void testBounds() {
	dtoS = toySettings(5000);
	dtoS.classid = 1;
	bounds(ranged("beer", "booze", "beer", 0, 1), $strings[frosty mug], 18.8, 22, "a beer in a frosty mug");
	bounds(ranged("salad", "food", "salad", 1, 0), $strings[salad fork], 18.2, 21, "a salad with the fork");
	bounds(ranged("wine", "booze", "wine", 0, 1), $strings[brie, frosty mug], 19.4, 23, "a wine with brie in a frosty mug");
	dtoS.ring = true;
	bounds(ranged("wine", "booze", "wine", 0, 1), $strings[brie, frosty mug], 21.6, 25, "and with the pinky ring");
	dtoS.ring = false;
	dtoS.ode = false;
	bounds(ranged("beer", "booze", "beer", 0, 1), $strings[frosty mug], 17.8, 21, "without Ode to Booze, a drink gives its drunkenness less");
}

// --- the phases ----------------------------------------------------------------

void testPhases() {
	// The toy day: what is planned for the base organs is phase 1, and a
	// drink is picked for phase 4.
	market();
	dietSemirareValue = 30000;
	DietSettings s = toySettings(5000);
	s.base = dtoSize(10, 14, 15);  // 5 fullness only with the organ gear
	DietPlan plan = smmDietPlanDay(s, false);
	int early = 0;
	int late = 0;
	foreach i, r in plan.rows {
		if (r.isNightcap) continue;
		int [int] sz = smmDietUnitSize(r);
		early += sz[0] * plan.parts[i, 1];
		late += sz[0] * plan.parts[i, 3];
	}
	check(early <= 10 + 3, "phase 1 fits the base stomach (with the melange's 3): " + early);
	check(late > 0, "the food that needs the gear's space waits for phase 3: " + late);
	check(plan.hasOverdrink && plan.parts[count(plan.rows) - 1, 4] == 1, "one overdrink in phase 4");
	check(plan.stopAt >= 0, "a stop point: " + plan.stopAt);
}

// --- options -------------------------------------------------------------------

void testArgs() {
	string [string] o = smmDietParseArgs("finish yes value=4500 exclude=a b|c noRefresh");
	check(o["finish"] == "true" && o["yes"] == "true" && o["value"] == "4500" && o["noRefresh"] == "true", "the options");
	check(o["exclude"] == "a b|c", "an item name can hold spaces: " + o["exclude"]);
	check(smmDietParseArgs("nightcap") contains "finish", "nightcap is finish");
	check(smmDietBudget(smmDietParseArgs("budget=1234")) == 1234, "budget=N");
}

void main() {
	testAverage();
	testRule();
	testBuyCap();
	testRestrict();
	testBudget();
	testPaidUnits();
	testPaidPlans();
	testBounds();
	testPhases();
	testArgs();
	if (failures == 0) print("PASS smmDietTest: " + checks + " checks");
	else print("FAILED smmDietTest: " + failures + " of " + checks + " checks", "red");
}
