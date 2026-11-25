// smmDietOptimizer.ash -- the diet optimizer behind diet.ash.
//
// This is an ASH port of the diet calculator by tehtmi at
// https://www.lethe.xyz/kol/diets.php (diet-code-1.0.0.js), which credits
// Eleron and houeland for earlier work. scripts/diet.js carried it as a
// JavaScript port from 2023 to 2026; this file replaces that one. The search,
// the variations it tries and its tie-breaking are the original's. Changes
// from it (marked "smm:") replace the page's static price table and settings
// form with live KoLmafia data. The ones carried over from diet.js are daily
// counters, effect values, overdrink candidates and the Affirmation Cookie.
// One is new here: Ode to Booze adventures count only when you have the
// skill.
//
// ASH has no closures or objects, so the structure differs: the page's
// per-call state lives in dto* globals, specs and result nodes live in pools
// indexed by number, and maps that the page iterated in insertion order keep
// that order in a key list. diet.ash plans with "include nightcap" "no" and
// leaves the overdrink to its own phase 4, so the page's limited-nightcap
// code is not ported. It is also unreachable from diet.ash's settings, as is
// the tiny plastic sword pricing. LICENSING.md records the source and the
// open question about permission to redistribute it.

// ---------------------------------------------------------------------------
// Data the KoLmafia layer (smmDiet.ash) fills in.

record DietItem {
	string name;
	float advmin;
	float advmax;
	string type;         // food, booze, spleen, extender, simple, or "" for helpers and chocolates
	boolean hasSize;
	int [int] size;      // fullness, drunkenness, spleen; negative = cleaning
	float price;         // 0: none
	int limit;           // 0: none
	string itemClass;    // saucy food, pizza, taco, salad, lasagna, beer, wine
	boolean tuxedo;      // a martini the tuxedo shirt boosts
	int pvpfights;
	float bonusadv;      // smm: flat extras, not scaled by helpers
	float bonusvalue;
	float effectvalue;
	string effectName;
	int effectTurns;
	int effectValue;
	int speakeasy;       // the speakeasy's price, 0 when not a speakeasy drink
	boolean owned;       // limited to copies already owned
	boolean eat;         // magical sausage: eaten, though it uses no stomach
	int free;            // sausages that cost no Meat; -1 when not counted
	boolean internalLimit;
	string specialprice;
};

record DietGear {
	string name;
	string slot;
	int [int] size;
	boolean worn;
};

record DietSettings {
	float advValue;
	float pvpValue;
	int classid;
	boolean overdrinkCandidates;
	int rolloverGain;
	int overdrunkTurns;
	boolean hasSink;
	string sinkName;
	int sinkValue;
	boolean saucemaven;
	boolean pizzaLover;
	boolean recall;
	boolean breakfast;
	boolean coldOne;
	boolean fieldGar;
	boolean tuxedo;
	boolean ring;
	boolean mime;
	boolean speakeasy;
	boolean ode;             // smm: Ode to Booze adventures count only with the skill
	int semirares;
	int luckyWanted;
	float [string] effectRates;
	string workshed;
	boolean [string] excluded;
	int [int] organs;
	int [int] base;
	DietGear [int] gear;
	boolean stooper;
	boolean sweatHave;
	int sweatAmount;
	int sweatLeft;
	int sweatReady;
	int sweatCasts;
	float affirmationBonus;
	int speakeasyLeft;
	int recallLeft;
	int chocFancy;
	int chocVita;
	int chocCigar;
	int chocSculpture;
};

DietItem [int] dietConsumables;
float dietSemirareValue;

// ---------------------------------------------------------------------------
// Specs (one way to consume one item) and result nodes (a linked list of specs).

record DietSpec {
	DietItem item;
	boolean [string] opts;
	float value;
	boolean hasSize;
	int [int] size;
	float adv;
	boolean hasAdvmax;
	float advmax;
	int pvp;
	float price;
	int limit;
	string limitKey;
	float fortuneValue;
	int helper;          // spec number, -1 for none
	boolean tuxedoBoosted;
	int offset;
	int skip;
	int realOffset;
};

record DietNode {
	int first;           // spec number
	int rest;            // node number, -1 for the empty diet
	float value;
	boolean mime;
	boolean hasAdvOverride;
	float advOverride;
	boolean isNightcap;
};

record DietNote {
	string type;         // text, effect, item
	string verb;
	string text;
	string effect;
	string itemName;
	boolean exclude;     // a helper bought and used up with the row
};

record DietRow {
	int spec;
	int amount;
	string name;
	float turns;
	int fights;
	float price;         // for all of the row's units
	float value;
	boolean isNightcap;
	boolean mime;
	int fortune;
	float fortuneValue;
	DietNote [int] notes;
	string specialprice;
	int sortkey;
};

record DietResult {
	DietRow [int] rows;
	float value;
	DietRow [int] overdrinks;
};

DietSpec [int] dtoSpecs;
int dtoSpecCount;
DietNode [int] dtoNodes;
int dtoNodeCount;

float kDietEpsilon = 0.000001;

int [int] dtoSize(int a, int b, int c) {
	int [int] s;
	s[0] = a;
	s[1] = b;
	s[2] = c;
	return s;
}

int [int] dtoCopySize(int [int] s) {
	return dtoSize(s[0], s[1], s[2]);
}

string dtoSizeKey(int [int] s) {
	return s[0] + "," + s[1] + "," + s[2];
}

boolean [string] dtoCopyOpts(boolean [string] o) {
	boolean [string] c;
	foreach k, v in o if (v) c[k] = true;
	return c;
}

int dtoNewSpec(DietItem it) {
	DietSpec s = new DietSpec();
	s.item = it;
	s.helper = -1;
	dtoSpecs[dtoSpecCount] = s;
	dtoSpecCount += 1;
	return dtoSpecCount - 1;
}

DietSpec dtoSpec(int id) { return dtoSpecs[id]; }

int dtoNode(int first, int rest, float value) {
	DietNode n = new DietNode();
	n.first = first;
	n.rest = rest;
	n.value = value;
	dtoNodes[dtoNodeCount] = n;
	dtoNodeCount += 1;
	return dtoNodeCount - 1;
}

float dtoValue(int node) { return node < 0 ? 0.0 : dtoNodes[node].value; }

void dtoPush(int [int] list, int x) { list[count(list)] = x; }

void dtoUnshift(int [int] list, int x) {
	for (int i = count(list) - 1; i >= 0; i--) list[i + 1] = list[i];
	list[0] = x;
}

// A map of specs by key that remembers the order keys were first added, as
// the page's object did.
record DietSpecMap {
	int [string] byKey;
	string [int] order;
};

void dtoMapSet(DietSpecMap m, string key, int spec) {
	if (!(m.byKey contains key)) m.order[count(m.order)] = key;
	m.byKey[key] = spec;
}

// The page's create_list: specs, with the limited ones grouped by what limits them.
record DietSpecList {
	int [int] plain;
	int [string, int] limited;
	string [int] keys;
};

// ---------------------------------------------------------------------------
// The optimizer's per-run state (the page's closure variables).

DietSettings dtoS;
float dtoAdvValue;
float dtoFightValue;
int dtoStomach;
int dtoLiver;
int dtoSpleen;
float dtoFortuneValue;
int dtoAffirmationBonus;

DietItem dtoFork;
DietItem dtoSpork;
DietItem dtoMunchies;
DietItem dtoMug;
DietItem dtoShotglass;
DietItem dtoFieldGar;
DietItem dtoBeerNuts;
DietItem dtoBrie;
DietItem dtoWish;
DietItem dtoBlueMana;
DietItem dtoXTattoo;
DietItem dtoTacoSauce;
DietItem dtoSeasoning;
DietItem dtoMayoflex;
DietItem dtoMayodiol;
boolean [string] dtoHave;    // which of the items above are on offer

DietSpecMap dtoBest;
DietSpecMap dtoBestGar;
DietSpecMap dtoBestBrie;
int [int] dtoOverdrinks;
boolean dtoOverdrinkList;

record DietFlag {
	string flag;
	boolean complicated;
	string itemClass;
	int minFullness;
	boolean garList;
};
DietFlag [int, int] dtoFoodFlags;
int dtoFoodFlagFamilies;

int [int] dtoNormal;         // for quick_fill
float [string] dtoQuickCache;
int [int] dtoFood;
int [int] dtoBoozeItems;
int [int] dtoSpleenItems;
int dtoLastSpork;
int dtoLastFortune;
int [string] dtoSpleenIterCache;
int [string] dtoSpleenCache;
int [string] dtoFoodCache;
int [string] dtoBoozeCache;

boolean dtoHas(string what) { return dtoHave contains what; }

int dtoCalculateMunchies(float adv) {
	if (adv <= 3) return 3;
	if (adv <= 6) return 2;
	return 1;
}

string dtoChocolateStartingWeapon(int classid) {
	switch (classid) {
	case 1: return "chocolate seal-clubbing club";
	case 2: return "chocolate turtle totem";
	case 3: return "chocolate pasta spoon";
	case 4: return "chocolate saucepan";
	case 5: return "chocolate disco ball";
	case 6: return "chocolate stolen accordion";
	}
	return "";
}

// The page's calculate_adventures: the average over the base adventure range,
// or the highest with maximum.
float dtoCalculateAdventures(DietItem it, boolean [string] opts, boolean maximum) {
	float total = 0.0;
	float n = 0.0;
	float highest = 0.0;
	if (it.advmax == 0) return 0.0;
	for (float base_adv = it.advmin; base_adv <= it.advmax; base_adv += 1) {
		float adv = base_adv;
		if (opts["munchies pill"]) adv += dtoCalculateMunchies(adv);
		float wine_bonus = 0;
		if (dtoS.ring && it.itemClass == "wine") wine_bonus += floor(0.5 + 0.5 * floor(adv * 0.25));
		if (opts["brie"] && it.itemClass == "wine") wine_bonus += floor(adv * 0.25);
		adv = adv + wine_bonus;
		if (opts["salad fork"]) {
			if (it.itemClass == "salad") adv = ceil(adv * 1.5);
			else adv = ceil(adv * 1.3);
		} else if (opts["fudge spork"]) {
			adv += 3;
		} else if (opts["frosty mug"]) {
			if (it.itemClass == "beer") adv = floor(adv * 1.5);
			else adv = floor(adv * 1.3);
		} else if (opts["shotglass"]) {
			adv += 3;
		}
		if ((opts["beer nuts"] || opts["beer nuts (wish)"]) && it.itemClass == "beer") adv += 5;
		if (opts["taco sauce"] && it.itemClass == "taco") adv += 1;
		if (it.type == "booze" && adv > 0 && dtoS.ode) adv += it.size[1];  // Ode to Booze (smm: only with the skill)
		if (opts["gar-ish"] && it.itemClass == "lasagna") adv += 5;
		if (dtoS.pizzaLover && it.itemClass == "pizza") adv += it.size[0];
		if (dtoS.saucemaven && it.itemClass == "saucy food") {
			adv += 3;
			if (dtoS.classid == 3 || dtoS.classid == 4) adv += 2;
		}
		if (dtoS.tuxedo && it.tuxedo) adv += 2;
		if (opts["mayoflex"]) adv += 1;
		if (opts["special seasoning"]) adv += 1;
		// item-specific bonuses counted separately AFTER bonuses from munchies/fork/etc
		if (it.name == "Affirmation Cookie") adv += dtoAffirmationBonus;  // smm: 0 under KoLmafia, whose data includes it
		// smm: KoLmafia's data already lists spaghetti breakfast and Cold One at
		// 6 adventures, so the page's +5 bonus for them is not added.
		highest = max(highest, adv);
		total += adv;
		n += 1.0;
	}
	if (maximum) return highest;
	return total / n;
}

float dtoCalculatePrice(DietItem it) {
	if (it.name == "spaghetti breakfast" && dtoS.breakfast) return 5;
	if (it.name == "Cold One" && dtoS.coldOne) return 5;
	if (dtoS.speakeasy && it.speakeasy > 0) return it.speakeasy;
	return it.price;
}

int dtoOptimizeFood(DietItem it);

// The page's create_spec. Returns -1 where the page returned nothing.
int dtoCreateSpec(DietItem it, boolean [string] given) {
	boolean [string] opts = dtoCopyOpts(given);
	if (it.itemClass == "taco" && dtoHas("taco sauce") && dtoTacoSauce.price + kDietEpsilon < dtoAdvValue) opts["taco sauce"] = true;
	if (it.type == "food" && dtoHas("special seasoning") && dtoSeasoning.price + kDietEpsilon < dtoAdvValue) opts["special seasoning"] = true;

	float adv = dtoCalculateAdventures(it, opts, false);
	float price = dtoCalculatePrice(it);
	if (price == 0) return -1;

	if (opts["munchies pill"]) price += dtoMunchies.price;
	if (opts["taco sauce"]) price += dtoTacoSauce.price;
	if (opts["salad fork"]) price += dtoFork.price;
	if (opts["fudge spork"]) price += dtoSpork.price;
	if (opts["frosty mug"]) price += dtoMug.price;
	if (opts["shotglass"]) price += dtoShotglass.price;
	if (opts["mayoflex"]) price += 1000;
	if (opts["mayodiol"]) price += 1000;
	if (opts["special seasoning"]) price += dtoSeasoning.price;
	float value = adv * dtoAdvValue - price;
	float fvalue = 0;
	if (opts["fortune"]) {
		float penalty = 0;
		if (it.name == "fortune cookie") penalty = 1.25;
		else if (it.name == "Lucky Lindy") penalty = 1;
		else abort("smmDietOptimizer: fortune option on " + it.name);
		fvalue = dtoFortuneValue - penalty * dtoAdvValue;
		value += fvalue;
	}
	int pvp = 0;
	if (it.pvpfights != 0) {
		pvp = it.pvpfights;
		value += pvp * dtoFightValue;
	}
	// smm: flat extras the item gives once, not scaled by fork/mug/Ode
	if (it.bonusadv != 0) {
		adv += it.bonusadv;
		value += it.bonusadv * dtoAdvValue;
	}
	value += it.bonusvalue;
	value += it.effectvalue;  // smm: the effect it gives (see smmDietEffectOf)

	int id = dtoNewSpec(it);
	DietSpec spec = dtoSpecs[id];
	spec.opts = dtoCopyOpts(opts);
	spec.value = value;
	spec.hasSize = true;
	spec.size = dtoCopySize(it.size);
	spec.adv = adv;
	spec.hasAdvmax = true;
	spec.advmax = dtoCalculateAdventures(it, opts, true) + it.bonusadv;
	spec.pvp = pvp;
	spec.price = price;
	spec.limit = it.limit;
	if (opts["fortune"]) spec.fortuneValue = fvalue;
	if (it.speakeasy > 0) {
		spec.limit = dtoS.speakeasyLeft;  // smm: was 3
		spec.limitKey = "speakeasy";
	}
	if (opts["mayodiol"]) spec.size = dtoSize(spec.size[0] - 1, spec.size[1] + 1, spec.size[2]);
	if (opts["beer nuts"]) {
		spec.size = dtoSize(spec.size[0] + 1, spec.size[1], spec.size[2]);
		int helper = dtoOptimizeFood(dtoBeerNuts);
		if (helper < 0) return -1;  // (the page fails here)
		spec.helper = helper;
		spec.value += dtoSpecs[helper].value;
		dtoSpecs[helper].value = 0;
	}
	if (opts["beer nuts (wish)"]) {
		int wish = dtoNewSpec(dtoWish);
		DietSpec w = dtoSpecs[wish];
		w.value = 0;
		w.hasSize = true;
		w.size = dtoSize(0, 0, 0);
		w.price = dtoWish.price;
		w.adv = 0;
		w.opts["wish_salty_mouth"] = true;
		spec.helper = wish;
		spec.value -= dtoWish.price;
	}
	if (dtoS.tuxedo && it.tuxedo) spec.tuxedoBoosted = true;
	return id;
}

float dtoOdCost(DietSpec s) { return s.adv * dtoAdvValue - s.value; }

// a limited drink may be used up by the rest of the plan, so it never rules others out
boolean dtoOdDominates(DietSpec a, DietSpec b) {
	return a.item.limit == 0 && a.adv >= b.adv && dtoOdCost(a) <= dtoOdCost(b) + kDietEpsilon;
}

void dtoCreateSpecAndTest(DietItem it, boolean [string] opts, DietSpecMap list) {
	int id = dtoCreateSpec(it, opts);
	if (id < 0) return;
	DietSpec spec = dtoSpecs[id];
	if (spec.value == 0) return;
	string key = dtoSizeKey(spec.size);
	if (it.limit != 0) key += it.name;
	else if (it.speakeasy > 0) key += "speakeasy";
	if (spec.opts["fortune"]) key += "fortune";
	if (spec.opts["fudge spork"]) key += "spork";
	if (spec.opts["mayodiol"]) key += "mayodiol";

	if (!(list.byKey contains key) || spec.value > dtoSpecs[list.byKey[key]].value + kDietEpsilon) dtoMapSet(list, key, id);

	// smm: single-drink overdrink candidates, chosen outside the optimizer:
	// booze needing no stomach or spleen. Kept only if no other is at least as
	// many adventures for no more cost, so any adventure cap still finds the best.
	if (dtoOverdrinkList && it.type == "booze" && spec.size[1] > 0 && spec.size[0] <= 0 && spec.size[2] <= 0
		&& it.speakeasy == 0 && spec.value > kDietEpsilon
		&& !(spec.opts["mayodiol"] || spec.opts["brie"] || spec.opts["fortune"])) {
		foreach i, other in dtoOverdrinks
			if (dtoOdDominates(dtoSpecs[other], spec)) return;
		int [int] kept;
		foreach i, other in dtoOverdrinks
			if (!dtoOdDominates(spec, dtoSpecs[other])) dtoPush(kept, other);
		dtoPush(kept, id);
		dtoOverdrinks = kept;
	}
}

void dtoCreateSpecAndTest(DietItem it, boolean [string] opts) {
	dtoCreateSpecAndTest(it, opts, dtoBest);
}

void dtoFoodVariationsHelper(DietItem it, boolean complicated, DietSpecMap list, boolean [string] flags, int idx) {
	if (idx < dtoFoodFlagFamilies) {
		dtoFoodVariationsHelper(it, complicated, list, flags, idx + 1);
		foreach j, fi in dtoFoodFlags[idx] {
			if (complicated && fi.complicated) continue;
			if (fi.itemClass != "" && fi.itemClass != it.itemClass) continue;
			if (fi.minFullness != 0 && it.size[0] < fi.minFullness) continue;
			DietSpecMap rlist = fi.garList ? dtoBestGar : list;
			flags[fi.flag] = true;
			dtoFoodVariationsHelper(it, complicated || fi.complicated, rlist, flags, idx + 1);
			flags[fi.flag] = false;
		}
	} else {
		dtoCreateSpecAndTest(it, dtoCopyOpts(flags), list);
	}
}

// The best simple way to eat one food (no spork, no Gar-ish).
int dtoOptimizeFood(DietItem it) {
	DietSpecMap temp;
	boolean [string] flags;
	dtoFoodVariationsHelper(it, true, temp, flags, 0);
	string key = dtoSizeKey(it.size);
	return temp.byKey contains key ? temp.byKey[key] : -1;
}

// The page's quick_fill: the most the normal (unlimited) consumables can get
// from this much space. Its memo is the page's own: keyed by the space only,
// written at the first index and read at every index.
float dtoQuickFill(int fullness, int drunkenness, int spleen, int idx) {
	string key = fullness + "," + drunkenness + "," + spleen;
	if (dtoQuickCache contains key && dtoQuickCache[key] != 0) return dtoQuickCache[key];
	float best_value = 0;
	if (idx < count(dtoNormal)) {
		DietSpec spec = dtoSpecs[dtoNormal[idx]];
		best_value = dtoQuickFill(fullness, drunkenness, spleen, idx + 1);
		int [int] sz = spec.size;
		if (sz[0] <= fullness && sz[1] <= drunkenness && sz[2] <= spleen && (sz[0] > 0 || sz[1] > 0 || sz[2] > 0)) {
			float value = spec.value + dtoQuickFill(fullness - sz[0], drunkenness - sz[1], spleen - sz[2], idx);
			if (value > best_value + kDietEpsilon) best_value = value;
		}
	}
	if (idx == 0) dtoQuickCache[key] = best_value;
	return best_value;
}

void dtoAddToList(DietSpecList list, int id) {
	DietSpec spec = dtoSpecs[id];
	if (spec.limit != 0 || spec.opts["fudge spork"] || spec.opts["fortune"]) {
		string key;
		if (spec.limit != 0) key = spec.limitKey != "" ? spec.limitKey : spec.item.name;
		else if (spec.opts["fudge spork"]) key = spec.opts["fortune"] ? "hybrid" : "fudge spork";
		else key = "fortune";
		if (!(list.limited contains key)) list.keys[count(list.keys)] = key;
		list.limited[key, count(list.limited[key])] = id;
	} else {
		dtoPush(list.plain, id);
	}
}

int [int] dtoResolveList(DietSpecList list) {
	int [int] final_list;
	int [int] fudge;
	int [int] hybrid;
	int [int] fortune;
	int [int] speakeasy;
	foreach k, key in list.keys {
		int offset = count(list.limited[key]);
		for (int j = 0; j < count(list.limited[key]); j++) {
			int id = list.limited[key, j];
			dtoSpecs[id].offset = offset;
			if (key == "fudge spork") dtoPush(fudge, id);
			else if (key == "hybrid") dtoPush(hybrid, id);
			else if (key == "fortune") dtoPush(fortune, id);
			else if (key == "speakeasy") dtoPush(speakeasy, id);
			else dtoPush(final_list, id);
			offset -= 1;
		}
	}
	foreach i, id in fudge dtoPush(final_list, id);
	foreach i, id in hybrid dtoPush(final_list, id);
	foreach i, id in fortune dtoPush(final_list, id);
	foreach i, id in speakeasy dtoPush(final_list, id);
	foreach i, id in list.plain dtoPush(final_list, id);
	return final_list;
}

float dtoFindMaxValue(int [int] items, int size_idx, boolean [string] exclude, float [int] min_values, float [int] feedback_values) {
	float max_value = 0;
	foreach i, id in items {
		DietSpec spec = dtoSpecs[id];
		if (exclude[spec.item.name] || spec.size[size_idx] <= 0) continue;
		float value = spec.value;
		for (int si = 0; si < 3; si++) {
			if (size_idx != si && spec.size[si] != 0) {
				if (spec.size[si] > 0) value -= min_values[si] * spec.size[si];
				else value += feedback_values[si] * -spec.size[si];
			} else if (size_idx == si) {
				value -= min_values[si] * (spec.size[si] - 1);
			}
		}
		if (value > max_value + kDietEpsilon) max_value = value;
	}
	return max_value;
}

float [int] dtoFloats(float a, float b, float c) {
	float [int] f;
	f[0] = a;
	f[1] = b;
	f[2] = c;
	return f;
}

float dtoFullnessMax;
float dtoDrunkennessMax;
float dtoSpleenMax;

boolean dtoSizeReducerHelpful(DietSpec spec) {
	float value = spec.value;
	if (spec.size[0] < 0) value += dtoFullnessMax * -spec.size[0];
	if (spec.size[1] < 0) value += dtoDrunkennessMax * -spec.size[1];
	if (spec.size[2] < 0) value += dtoSpleenMax * -spec.size[2];
	return value > kDietEpsilon;
}

int dtoBestSpleenIter(int capacity, int idx) {
	string key = capacity + "," + idx;
	if (dtoSpleenIterCache contains key) return dtoSpleenIterCache[key];
	int best = -1;
	if (idx < count(dtoSpleenItems)) {
		int sid = dtoSpleenItems[idx];
		DietSpec spec = dtoSpecs[sid];
		int sz = spec.size[2];
		int best_i = -1;
		int best_rest = -1;
		float best_value = 0;
		int lim = spec.limit != 0 ? spec.limit : 1000;
		for (int i = 0; i <= lim; i++) {
			int new_capacity = capacity - sz * i;
			int rest = dtoBestSpleenIter(new_capacity, idx + 1);
			float value = dtoValue(rest) + i * spec.value;
			if (value > best_value + kDietEpsilon) {
				best_i = i;
				best_rest = rest;
				best_value = value;
			}
			if (new_capacity < sz) break;
		}
		if (best_i >= 0) {
			best = best_rest;
			for (int i = 1; i <= best_i; i++) best = dtoNode(sid, best, dtoValue(best) + spec.value);
			if (best >= 0) dtoNodes[best].value = best_value;
		}
	}
	dtoSpleenIterCache[key] = best;
	return best;
}

int dtoBestSpleen(int capacity) {
	string key = capacity.to_string();
	if (dtoSpleenCache contains key) return dtoSpleenCache[key];
	int best = dtoBestSpleenIter(capacity, 0);
	dtoSpleenCache[key] = best;
	return best;
}

int dtoBestFoodIter(int fullness, int spleen, int idx) {
	string key = fullness + "," + spleen + "," + idx;
	if (dtoFoodCache contains key) return dtoFoodCache[key];
	int best;
	if (idx >= count(dtoFood)) {
		best = dtoBestSpleen(spleen);
	} else {
		int sid = dtoFood[idx];
		DietSpec spec = dtoSpecs[sid];
		int lim = spec.limit != 0 ? spec.limit : 1000;
		int [int] sz = spec.size;
		int best_i = -1;
		int best_rest = -1;
		float best_value = 0;
		for (int i = 0; i <= lim; i++) {
			int nf = fullness - i * sz[0];
			int ns = spleen - i * sz[2];
			int offset = 1;
			if (i > 0 && spec.offset != 0) offset = spec.offset;
			if (i == 0 && spec.skip != 0) offset += spec.skip;
			int rest = dtoBestFoodIter(nf, ns, idx + offset);
			float value = dtoValue(rest) + i * spec.value;
			if (best_i < 0 || value > best_value + kDietEpsilon) {
				best_i = i;
				best_rest = rest;
				best_value = value;
			}
			if (nf < sz[0]) break;
		}
		best = best_rest;
		for (int i = 1; i <= best_i; i++) best = dtoNode(sid, best, dtoValue(best) + spec.value);
		if (best >= 0) dtoNodes[best].value = best_value;
	}
	dtoFoodCache[key] = best;
	return best;
}

int dtoBestFood(int fullness, int spleen) { return dtoBestFoodIter(fullness, spleen, 0); }

int dtoBestBooze(int c0, int c1, int c2, int idx, boolean spork, int semirare, int limit_count, int free_one_drunk) {
	int drunkenness = c1 < 0 ? -1000 : c1;
	if (idx > dtoLastSpork) spork = false;
	if (idx > dtoLastFortune) semirare = 0;
	string key = c0 + "," + c1 + "," + c2 + "," + idx + "," + spork + "," + semirare + "," + limit_count + "," + free_one_drunk;
	if (dtoBoozeCache contains key) return dtoBoozeCache[key];
	int best = -1;
	if (idx >= count(dtoBoozeItems)) {
		best = dtoBestFood(c0, c2);
		if (dtoHas("x tattoo") && drunkenness >= 0) {
			int adv = ceil((drunkenness + 1) * 4.5);
			float price = dtoXTattoo.price;
			float value = adv * dtoAdvValue - price;
			if (value > kDietEpsilon) {
				int x = dtoNewSpec(dtoXTattoo);
				dtoSpecs[x].value = value;
				dtoSpecs[x].adv = adv;
				dtoSpecs[x].price = price;
				best = dtoNode(x, best, value + dtoValue(best));
			}
		}
	} else {
		int sid = dtoBoozeItems[idx];
		DietSpec spec = dtoSpecs[sid];
		int lim = 1000;
		if (spec.limit != 0) lim = spec.limit - limit_count;
		int [int] sz = spec.size;
		boolean using_spork = spec.opts["fudge spork"];
		boolean fortune = spec.opts["fortune"];
		if (using_spork) lim = min(1, lim);
		if (using_spork && !spork) lim = 0;
		if (fortune) lim = min(semirare, lim);
		int fullness_offset = spec.opts["mayodiol"] ? 1 : 0;
		int best_i = -1;
		int best_rest = -1;
		float best_value = 0;
		int best_free = 0;
		for (int i = 0; i <= lim; i++) {
			int n0 = c0 - i * sz[0];
			int n1 = c1 - i * sz[1];
			int n2 = c2 - i * sz[2];
			int free_drunk_used = 0;
			if (i > 0 && free_one_drunk > 0 && sz[1] == 1 && spec.item.type == "booze") {
				free_drunk_used = min(i, free_one_drunk);
				n1 += free_drunk_used;
			}
			int offset = 1;
			if (i > 0 && spec.realOffset != 0) offset = spec.realOffset;
			int new_limit_count = 0;
			if (spec.limit != 0 && spec.offset > 1) new_limit_count = i + limit_count;
			if (i == 0 && spec.skip != 0) offset += spec.skip;
			int rest = dtoBestBooze(n0, n1, n2, idx + offset, (i > 0 && using_spork) ? false : spork,
				fortune ? semirare - i : semirare, new_limit_count, free_one_drunk - free_drunk_used);
			float value = dtoValue(rest) + i * spec.value - free_drunk_used * dtoAdvValue;
			if (best_i < 0 || value > best_value + kDietEpsilon) {
				best_i = i;
				best_rest = rest;
				best_value = value;
				best_free = free_drunk_used;
			}
			if ((n0 - fullness_offset) < sz[0] || n1 < sz[1]) break;
		}
		best = best_rest;
		for (int i = 1; i <= best_i; i++) {
			float value = dtoValue(best) + spec.value;
			best = dtoNode(sid, best, value);
			if (i <= best_free) {
				dtoNodes[best].mime = true;
				dtoNodes[best].hasAdvOverride = true;
				dtoNodes[best].advOverride = spec.adv - 1;
				dtoNodes[best].value -= dtoAdvValue;
			}
			if (spec.helper >= 0) best = dtoNode(spec.helper, best, dtoValue(best));
		}
	}
	dtoBoozeCache[key] = best;
	return best;
}

// ---------------------------------------------------------------------------
// Rows: the page's conversion to Eleron's format.

int dtoSortkey(DietRow row) {
	DietItem c = dtoSpecs[row.spec].item;
	if (c.type == "extender") return 1;
	if (c.type == "simple") return 2;
	if (c.type == "") return 3;
	if (c.name == "fortune cookie") return 1000;
	if (c.type == "food") return 1010;
	if (c.type == "booze" && !row.isNightcap) return 2000;
	if (c.type == "booze" && row.isNightcap) return 3000;
	if (c.type == "spleen") return 4000;
	return -1000;
}

void dtoNote(DietRow row, string type, string verb, string what, boolean exclude) {
	DietNote n = new DietNote();
	n.type = type;
	n.verb = verb;
	if (type == "text") n.text = what;
	else if (type == "effect") n.effect = what;
	else n.itemName = what;
	n.exclude = exclude;
	row.notes[count(row.notes)] = n;
}

DietRow [int] dtoRows(int head, boolean nightcapHead) {
	DietRow [string] byKey;
	string [int] order;
	int node = head;
	boolean first = true;
	while (node >= 0) {
		DietNode nd = dtoNodes[node];
		DietSpec spec = dtoSpecs[nd.first];
		boolean is_nightcap = nd.isNightcap || (first && nightcapHead);
		first = false;
		string key = spec.item.name;
		if (is_nightcap) key += " (nightcap)";
		if (spec.opts["fortune"]) key += " (fortune)";
		if (spec.opts["mayodiol"]) key += " (mayodiol)";
		if (spec.opts["fudge spork"]) key += " (fudge spork)";
		if (spec.opts["beer nuts"] || spec.opts["beer nuts (wish)"]) key += " (with beer nuts)";
		if (spec.opts["brie"]) key += " (with brie)";
		if (spec.opts["wish_refined_palate"]) key += " (wish refined)";
		if (spec.opts["wish_salty_mouth"]) key += " (wish salty)";
		if (nd.mime) key += " (with mime shotglass)";
		if (spec.opts["special seasoning"]) key += " (with special seasoning)";
		float turns = nd.hasAdvOverride && nd.advOverride != 0 ? nd.advOverride : spec.adv;
		if (!(byKey contains key)) {
			DietRow r = new DietRow();
			r.spec = nd.first;
			r.amount = 1;
			r.name = spec.item.name;
			r.turns = turns;
			r.fights = spec.pvp;
			r.price = spec.price;
			r.value = spec.value;
			r.isNightcap = is_nightcap;
			r.mime = nd.mime;
			r.fortuneValue = spec.fortuneValue;
			byKey[key] = r;
			order[count(order)] = key;
		} else {
			DietRow r = byKey[key];
			r.amount += 1;
			r.turns += turns;
			r.fights += spec.pvp;
			r.value += spec.value;
		}
		node = nd.rest;
	}
	DietRow [int] rows;
	foreach k, key in order {
		DietRow r = byKey[key];
		DietSpec spec = dtoSpecs[r.spec];
		r.specialprice = spec.item.specialprice;
		r.price *= r.amount;
		if (r.isNightcap) dtoNote(r, "text", "", "nightcap", false);
		if (spec.opts["fortune"]) {
			r.fortune = r.amount;
			r.fortuneValue *= r.amount;
			dtoNote(r, "text", "", "semi-rare", false);
		}
		if (spec.opts["wish_refined_palate"]) dtoNote(r, "effect", "wish for", "Refined Palate", false);
		if (spec.opts["wish_salty_mouth"]) dtoNote(r, "effect", "wish for", "Salty Mouth", false);
		if (spec.opts["salad fork"]) dtoNote(r, "item", "using", dtoFork.name, true);
		if (spec.opts["fudge spork"]) dtoNote(r, "item", "using", dtoSpork.name, true);
		if (spec.opts["taco sauce"]) dtoNote(r, "item", "with", dtoTacoSauce.name, true);
		if (spec.opts["frosty mug"]) dtoNote(r, "item", "using", dtoMug.name, true);
		if (spec.opts["shotglass"]) dtoNote(r, "item", "using", dtoShotglass.name, true);
		if (spec.opts["gar-ish"]) dtoNote(r, "effect", "with", "Gar-ish", false);
		if (spec.opts["beer nuts"] || spec.opts["beer nuts (wish)"]) dtoNote(r, "effect", "with", "Salty Mouth", false);
		if (spec.item.itemClass == "wine" && dtoS.ring) dtoNote(r, "item", "wearing", "mafia pinky ring", false);
		if (spec.opts["brie"]) dtoNote(r, "effect", "with", "Refined Palate", false);
		if (spec.opts["munchies pill"]) dtoNote(r, "item", "with", dtoMunchies.name, true);
		if (spec.opts["special seasoning"]) dtoNote(r, "item", "with", dtoSeasoning.name, true);
		if (spec.opts["mayoflex"]) dtoNote(r, "item", "with", dtoMayoflex.name, true);
		if (spec.opts["mayodiol"]) dtoNote(r, "item", "with", dtoMayodiol.name, true);
		if (spec.tuxedoBoosted) dtoNote(r, "item", "wearing", "tuxedo shirt", false);
		if (r.mime) dtoNote(r, "item", "using", "mime army shotglass", false);
		r.sortkey = dtoSortkey(r);
		rows[count(rows)] = r;
	}
	// sort by sortkey, then name (stable)
	string [int] sortKey;
	foreach i, r in rows sortKey[i] = to_string(r.sortkey + 2000, "%06d") + to_lower_case(r.name) + to_string(i, "%06d");
	sort rows by sortKey[index];
	DietRow [int] sorted;
	foreach i, r in rows sorted[count(sorted)] = r;
	return sorted;
}

// ---------------------------------------------------------------------------
// The optimizer.

void dtoFlagFamily(int family, string flag, boolean complicated, string itemClass, int minFullness, boolean garList) {
	DietFlag f = new DietFlag();
	f.flag = flag;
	f.complicated = complicated;
	f.itemClass = itemClass;
	f.minFullness = minFullness;
	f.garList = garList;
	dtoFoodFlags[family, count(dtoFoodFlags[family])] = f;
}

boolean dtoIsChocolate(string name) {
	switch (name) {
	case "fancy chocolate":
	case "fancy but probably evil chocolate":
	case "fancy chocolate car":
	case "beet-flavored Mr. Mediocrebar":
	case "cabbage-flavored Mr. Mediocrebar":
	case "sweet-corn-flavored Mr. Mediocrebar":
	case "choco-Crimbot":
		return true;
	}
	return false;
}

boolean dtoIsClassChocolate(string name) {
	switch (name) {
	case "chocolate seal-clubbing club":
	case "chocolate turtle totem":
	case "chocolate pasta spoon":
	case "chocolate saucepan":
	case "chocolate disco ball":
	case "chocolate stolen accordion":
		return true;
	}
	return false;
}

record DietChocolate {
	DietItem item;
	int [int] adv;
};

int dtoDiet;  // the result being built (a node)

void dtoTryChocolate(DietChocolate [int] list, int already_used) {
	for (int i = already_used; i < 3; i++) {
		int best = -1;
		boolean found = false;
		foreach j, entry in list {
			int adv = entry.adv[i];
			if (adv <= 0) continue;
			float value = adv * dtoAdvValue - entry.item.price;
			if (value <= kDietEpsilon) continue;
			float total = dtoValue(dtoDiet) + value;
			if (!found || total > dtoValue(best) + kDietEpsilon) {
				int sid = dtoNewSpec(entry.item);
				dtoSpecs[sid].value = value;
				dtoSpecs[sid].adv = adv;
				dtoSpecs[sid].price = entry.item.price;
				best = dtoNode(sid, dtoDiet, total);
				found = true;
			}
		}
		if (!found) break;
		dtoDiet = best;
	}
}

void dtoAddChocolate(DietChocolate [int] list, DietItem it, int a, int b, int c) {
	DietChocolate ch = new DietChocolate();
	ch.item = it;
	ch.adv[0] = a;
	ch.adv[1] = b;
	ch.adv[2] = c;
	list[count(list)] = ch;
}

DietResult smmDietOptimize(DietSettings s) {
	dtoS = s;
	dtoAdvValue = s.advValue;
	dtoFightValue = s.pvpValue;
	dtoStomach = s.organs[0];
	dtoLiver = s.organs[1];
	dtoSpleen = s.organs[2];
	dtoFortuneValue = dietSemirareValue;
	dtoAffirmationBonus = s.affirmationBonus;
	dtoOverdrinkList = s.overdrinkCandidates;
	boolean try_field_gar = s.fieldGar;
	boolean [string] excluded = s.excluded;
	string chocolate_weapon = dtoChocolateStartingWeapon(s.classid);

	// fresh state for this run (the spec pool is kept: older plan rows point into it)
	clear(dtoNodes);
	dtoNodeCount = 0;
	clear(dtoHave);
	DietSpecMap freshBest;
	DietSpecMap freshGar;
	DietSpecMap freshBrie;
	dtoBest = freshBest;
	dtoBestGar = freshGar;
	dtoBestBrie = freshBrie;
	clear(dtoOverdrinks);
	clear(dtoFoodFlags);
	clear(dtoNormal);
	clear(dtoSpleenItems);
	clear(dtoFood);
	clear(dtoBoozeItems);
	clear(dtoQuickCache);
	clear(dtoSpleenIterCache);
	clear(dtoSpleenCache);
	clear(dtoFoodCache);
	clear(dtoBoozeCache);

	foreach idx, it in dietConsumables {
		if (excluded[it.name]) continue;
		switch (it.name) {
		case "Ol' Scratch's salad fork": dtoFork = it; dtoHave["fork"] = true; break;
		case "fudge spork": dtoSpork = it; dtoHave["spork"] = true; break;
		case "munchies pill": dtoMunchies = it; dtoHave["munchies"] = true; break;
		case "Frosty's frosty mug": dtoMug = it; dtoHave["mug"] = true; break;
		case "BGE shotglass": dtoShotglass = it; dtoHave["shotglass"] = true; break;
		case "potion of the field gar": dtoFieldGar = it; dtoHave["field gar"] = true; break;
		case "packet of beer nuts": dtoBeerNuts = it; dtoHave["beer nuts"] = true; break;
		case "toasted brie": dtoBrie = it; dtoHave["brie"] = true; break;
		case "pocket wish": dtoWish = it; dtoHave["wish"] = true; break;
		case "blue mana": dtoBlueMana = it; dtoHave["blue mana"] = true; break;
		case "temporary X tattoos": dtoXTattoo = it; dtoHave["x tattoo"] = true; break;
		case "Taco Dan's Super Taco-Riffic Taco Sauce!": dtoTacoSauce = it; dtoHave["taco sauce"] = true; break;
		case "Special Seasoning": dtoSeasoning = it; dtoHave["special seasoning"] = true; break;
		case "Mayoflex": dtoMayoflex = it; dtoHave["mayoflex"] = true; break;
		case "Mayodiol": dtoMayodiol = it; dtoHave["mayodiol"] = true; break;
		}
	}

	// food variations: one family of options at a time
	int fam = 0;
	if (dtoHas("fork")) dtoFlagFamily(fam, "salad fork", false, "", 0, false);
	if (dtoHas("spork")) dtoFlagFamily(fam, "fudge spork", true, "", 0, false);
	fam += 1;  // (the fork family is there even when empty)
	if (dtoHas("munchies")) {
		dtoFlagFamily(fam, "munchies pill", false, "", 0, false);
		fam += 1;
	}
	// smm: fortune cookies stopped giving semi-rares in the 2021 luck update,
	// so only Lucky Lindy (booze, below) still gets the "fortune" option.
	if (s.workshed == "mayo" && (dtoHas("mayoflex") || dtoHas("mayodiol"))) {
		if (dtoHas("mayoflex")) dtoFlagFamily(fam, "mayoflex", false, "", 0, false);
		if (dtoHas("mayodiol")) dtoFlagFamily(fam, "mayodiol", false, "", 2, false);
		fam += 1;
	}
	if (try_field_gar && dtoHas("field gar")) {
		dtoFlagFamily(fam, "gar-ish", true, "lasagna", 0, true);
		fam += 1;
	}
	dtoFoodFlagFamilies = fam;

	int field_gar_spec = -1;
	int [int] extenders;
	int [int] simple;
	DietChocolate [int] chocolate;
	DietChocolate [int] nano_chocolate;
	DietChocolate [int] tobacco_chocolate;
	DietChocolate [int] sculpture_chocolate;

	foreach idx, it in dietConsumables {
		if (it.name == "Cold One" || it.name == "spaghetti breakfast") {
			it.limit = 1;
			it.internalLimit = true;
		}
		if (excluded[it.name]) continue;
		if (it.type == "food" || it.type == "booze" || it.type == "spleen") {
			if (it.size[0] <= dtoStomach && it.size[2] <= dtoSpleen) {
				boolean [string] none;
				if (it.type == "food") {
					boolean [string] flags;
					dtoFoodVariationsHelper(it, false, dtoBest, flags, 0);
				} else if (it.type == "booze") {
					dtoCreateSpecAndTest(it, none);
					if (it.speakeasy > 0) {
						if (it.name == "Lucky Lindy") dtoCreateSpecAndTest(it, $strings[fortune]);
					} else {
						if (dtoHas("mug")) dtoCreateSpecAndTest(it, $strings[frosty mug]);
						if (dtoHas("shotglass")) dtoCreateSpecAndTest(it, $strings[shotglass]);
						if (dtoHas("beer nuts") && it.itemClass == "beer") {
							dtoCreateSpecAndTest(it, $strings[beer nuts]);
							if (dtoHas("mug")) dtoCreateSpecAndTest(it, $strings[beer nuts, frosty mug]);
							if (dtoHas("shotglass")) dtoCreateSpecAndTest(it, $strings[beer nuts, shotglass]);
						}
						if (dtoHas("wish") && it.itemClass == "beer") {
							dtoCreateSpecAndTest(it, $strings[beer nuts (wish)]);
							if (dtoHas("mug")) dtoCreateSpecAndTest(it, $strings[beer nuts (wish), frosty mug]);
							if (dtoHas("shotglass")) dtoCreateSpecAndTest(it, $strings[beer nuts (wish), shotglass]);
						}
						if ((dtoHas("brie") || dtoHas("wish")) && it.itemClass == "wine") {
							dtoCreateSpecAndTest(it, $strings[brie], dtoBestBrie);
							if (dtoHas("mug")) dtoCreateSpecAndTest(it, $strings[frosty mug, brie], dtoBestBrie);
							if (dtoHas("shotglass")) dtoCreateSpecAndTest(it, $strings[shotglass, brie], dtoBestBrie);
						}
					}
				} else {
					dtoCreateSpecAndTest(it, none);
				}
			}
		} else if (it.type == "extender") {
			int sid = dtoNewSpec(it);
			DietSpec spec = dtoSpecs[sid];
			spec.value = -it.price;
			spec.hasSize = true;
			spec.size = dtoCopySize(it.size);
			spec.limit = it.limit;
			spec.price = it.price;
			spec.adv = 0;
			dtoPush(extenders, sid);
		} else if (it.type == "simple") {
			float adv = (it.advmin + it.advmax) / 2;
			int pvp = it.pvpfights;
			int sid = dtoNewSpec(it);
			DietSpec spec = dtoSpecs[sid];
			spec.value = adv * dtoAdvValue + pvp * dtoFightValue - it.price;
			spec.adv = adv;
			spec.hasAdvmax = true;
			spec.advmax = it.advmax;
			spec.pvp = pvp;
			spec.price = it.price;
			spec.limit = it.limit;
			dtoPush(simple, sid);
		}
		if (it.name == "potion of the field gar") {
			field_gar_spec = dtoNewSpec(it);
			DietSpec spec = dtoSpecs[field_gar_spec];
			spec.value = -it.price;
			spec.hasSize = true;
			spec.size = dtoSize(0, 0, 0);
			spec.price = it.price;
			spec.adv = 0;
		}
		if (dtoIsChocolate(it.name)) dtoAddChocolate(chocolate, it, 5, 3, 1);
		if (it.name == chocolate_weapon) dtoAddChocolate(chocolate, it, 3, 2, 1);
		else if (dtoIsClassChocolate(it.name)) dtoAddChocolate(chocolate, it, 2, 1, 0);
		if (it.name == "vitachoconutriment capsule") dtoAddChocolate(nano_chocolate, it, 5, 3, 1);
		if (it.name == "chocolate cigar") dtoAddChocolate(tobacco_chocolate, it, 5, 3, 1);
		if (it.name == "fancy chocolate sculpture") dtoAddChocolate(sculpture_chocolate, it, 5, 3, 1);
	}

	if (try_field_gar) {
		boolean useful = false;
		foreach k, key in dtoBestGar.order {
			int gar = dtoBestGar.byKey[key];
			if (!(dtoBest.byKey contains key) || dtoSpecs[gar].value > dtoSpecs[dtoBest.byKey[key]].value + kDietEpsilon) {
				useful = true;
				break;
			}
		}
		if (!useful) try_field_gar = false;
	}

	foreach k, key in dtoBest.order {
		DietSpec spec = dtoSpecs[dtoBest.byKey[key]];
		if (spec.limit == 0 && !spec.opts["fudge spork"] && !spec.opts["fortune"]) dtoPush(dtoNormal, dtoBest.byKey[key]);
	}

	DietSpecList food_items;
	DietSpecList booze_helpers;
	DietSpecList booze_real_items;
	foreach k, key in dtoBest.order {
		int sid = dtoBest.byKey[key];
		DietSpec spec = dtoSpecs[sid];
		int [int] sz = spec.size;
		DietItem it = spec.item;
		boolean has_mayodiol = spec.opts["mayodiol"];
		boolean has_spork = spec.opts["fudge spork"];
		string plain = dtoSizeKey(sz);
		string named = plain + it.name;
		if (sz[0] >= 0 && sz[1] >= 0 && sz[2] >= 0 && dtoQuickFill(sz[0], sz[1], sz[2], 0) > spec.value) {
			// useless: the normal consumables do better in the same space
		} else if ((dtoBest.byKey contains plain) && dtoBest.byKey[plain] != sid && dtoSpecs[dtoBest.byKey[plain]].value > spec.value + kDietEpsilon) {
			// useless
		} else if (has_spork && (dtoBest.byKey contains named) && dtoSpecs[dtoBest.byKey[named]].value > spec.value + kDietEpsilon) {
			// useless
		} else {
			if (sz[0] == 0 && sz[1] == 0 && sz[2] > 0 && it.type == "spleen") dtoPush(dtoSpleenItems, sid);
			else if (sz[1] > 0 && sz[2] <= 0 && it.type == "booze") dtoAddToList(booze_real_items, sid);
			else if (sz[1] < 0) dtoAddToList(booze_helpers, sid);
			else if (sz[1] > 0 || has_mayodiol || (dtoHas("mayodiol") && it.type == "food" && it.limit != 0 && s.workshed == "mayo")) dtoAddToList(booze_helpers, sid);
			else if (spec.opts["fudge spork"] || spec.opts["fortune"] || spec.limit != 0) dtoAddToList(booze_helpers, sid);
			else if (sz[0] > 0 && it.type == "food") dtoAddToList(food_items, sid);
			else print("unhandled item: " + it.name, "orange");
		}
	}

	// (the page meant to copy the food list here, but copied only the Gar-ish lasagna)
	int [int] field_gar_food_items;
	if (try_field_gar) foreach k, key in dtoBestGar.order dtoPush(field_gar_food_items, dtoBestGar.byKey[key]);

	dtoFood = dtoResolveList(food_items);
	int [int] booze_real = dtoResolveList(booze_real_items);
	int [int] helpers = dtoResolveList(booze_helpers);

	if (try_field_gar && field_gar_spec >= 0) {
		dtoSpecs[field_gar_spec].limit = 1;
		dtoSpecs[field_gar_spec].skip = count(field_gar_food_items);
		if (s.workshed == "mayo" && dtoHas("mayodiol")) {
			foreach i, id in field_gar_food_items dtoUnshift(helpers, id);
			dtoUnshift(helpers, field_gar_spec);
		} else {
			dtoPush(dtoFood, field_gar_spec);
			foreach i, id in field_gar_food_items dtoPush(dtoFood, id);
		}
	}

	if (dtoHas("brie") || dtoHas("wish")) {
		int brie_spec = -1;
		int wish_spec = -1;
		if (dtoHas("brie")) brie_spec = dtoOptimizeFood(dtoBrie);
		if (dtoHas("wish")) {
			wish_spec = dtoNewSpec(dtoWish);
			DietSpec w = dtoSpecs[wish_spec];
			w.value = -dtoWish.price;
			w.hasSize = true;
			w.size = dtoSize(0, 0, 0);
			w.price = dtoWish.price;
			w.adv = 0;
			w.opts["wish_refined_palate"] = true;
		}
		int [int] brie_list;
		foreach k, key in dtoBestBrie.order {
			int sid = dtoBestBrie.byKey[key];
			DietSpec spec = dtoSpecs[sid];
			if (spec.value > dtoQuickFill(spec.size[0], spec.size[1], spec.size[2], 0) + kDietEpsilon) dtoPush(brie_list, sid);
		}
		if (count(brie_list) > 0) {
			if (brie_spec >= 0) {
				dtoSpecs[brie_spec].limit = 1;
				if (wish_spec >= 0) dtoSpecs[brie_spec].realOffset = 2;
				else dtoSpecs[brie_spec].skip = count(brie_list);
				dtoPush(helpers, brie_spec);
			}
			if (wish_spec >= 0) {
				dtoSpecs[wish_spec].limit = 1;
				dtoSpecs[wish_spec].skip = count(brie_list);
				dtoPush(helpers, wish_spec);
			}
			foreach i, id in brie_list dtoPush(helpers, id);
		}
	}

	// Intervals for the possible value of each kind of capacity, to leave out
	// capacity helpers that are far too expensive.
	float fullness_min = dtoQuickFill(1, 0, 0, 0);
	float drunk_min = dtoQuickFill(0, 1, 0, 0);
	float spleen_min = dtoQuickFill(0, 0, 1, 0);
	int [int] all_food_booze;
	foreach i, id in dtoFood dtoPush(all_food_booze, id);
	foreach i, id in booze_real dtoPush(all_food_booze, id);
	foreach i, id in helpers dtoPush(all_food_booze, id);
	float [int] mins = dtoFloats(fullness_min, drunk_min, spleen_min);
	boolean [string] noExclude;
	float spleen_max = dtoFindMaxValue(dtoSpleenItems, 2, noExclude, mins, dtoFloats(0, 0, 0));
	float full_nf = dtoFindMaxValue(all_food_booze, 0, $strings[Mr. Burnsger, The Plumber's mushroom stew], mins, dtoFloats(0, 0, spleen_max));
	float drunk_nf = dtoFindMaxValue(all_food_booze, 1, $strings[Doc Clock's thyme cocktail, The Mad Liquor], mins, dtoFloats(0, 0, spleen_max));
	// two feedback items can be used for each of fullness and drunkenness, so do two steps of feedback
	float full_f0 = dtoFindMaxValue(all_food_booze, 0, noExclude, mins, dtoFloats(0, drunk_nf, spleen_max));
	float drunk_f0 = dtoFindMaxValue(all_food_booze, 1, noExclude, mins, dtoFloats(full_nf, 0, spleen_max));
	float full_f1 = dtoFindMaxValue(all_food_booze, 0, noExclude, mins, dtoFloats(0, drunk_f0, spleen_max));
	float drunk_f1 = dtoFindMaxValue(all_food_booze, 1, noExclude, mins, dtoFloats(full_f0, 0, spleen_max));
	float full_f2 = dtoFindMaxValue(all_food_booze, 0, noExclude, mins, dtoFloats(0, drunk_f1, spleen_max));
	float drunk_f2 = dtoFindMaxValue(all_food_booze, 1, noExclude, mins, dtoFloats(full_f1, 0, spleen_max));
	dtoFullnessMax = dtoFindMaxValue(all_food_booze, 0, noExclude, mins, dtoFloats(0, drunk_f2, spleen_max));
	dtoDrunkennessMax = dtoFindMaxValue(all_food_booze, 1, noExclude, mins, dtoFloats(full_f2, 0, spleen_max));
	dtoSpleenMax = spleen_max;

	foreach i, sid in extenders {
		DietSpec spec = dtoSpecs[sid];
		if (!dtoSizeReducerHelpful(spec)) continue;
		if (spec.size[1] < 0) dtoUnshift(helpers, sid);
		else if (spec.size[0] < 0) dtoUnshift(dtoFood, sid);
		else dtoUnshift(dtoSpleenItems, sid);
	}

	clear(dtoBoozeItems);
	foreach i, id in helpers dtoPush(dtoBoozeItems, id);
	foreach i, id in booze_real dtoPush(dtoBoozeItems, id);

	dtoLastSpork = -1;
	dtoLastFortune = -1;
	foreach i, id in dtoBoozeItems {
		if (dtoSpecs[id].opts["fudge spork"]) dtoLastSpork = i;
		if (dtoSpecs[id].opts["fortune"]) dtoLastFortune = i;
	}

	int free_one_drunk = s.mime ? 1 : 0;
	dtoDiet = dtoBestBooze(dtoStomach, dtoLiver, dtoSpleen, 0, true, s.semirares, 0, free_one_drunk);

	// chocolate time!
	dtoTryChocolate(chocolate, s.chocFancy);  // smm: skip chocolates already eaten today
	dtoTryChocolate(nano_chocolate, s.chocVita);
	dtoTryChocolate(tobacco_chocolate, s.chocCigar);
	dtoTryChocolate(sculpture_chocolate, s.chocSculpture);

	if (dtoHas("blue mana") && s.recall && s.recallLeft > 0) {
		DietItem recall = new DietItem();
		recall.name = "Ancestral Recall";
		recall.advmin = 3;
		recall.advmax = 3;
		recall.price = dtoBlueMana.price;
		recall.specialprice = "1 blue mana";
		recall.free = -1;
		int sid = dtoNewSpec(recall);
		DietSpec spec = dtoSpecs[sid];
		spec.value = 3 * dtoAdvValue - dtoBlueMana.price;
		spec.adv = 3;
		spec.price = dtoBlueMana.price;
		spec.limit = s.recallLeft;  // smm: was 10
		dtoPush(simple, sid);
	}

	foreach i, sid in simple {
		DietSpec spec = dtoSpecs[sid];
		if (spec.value <= kDietEpsilon) continue;
		for (int n = 0; n < spec.limit; n++) dtoDiet = dtoNode(sid, dtoDiet, dtoValue(dtoDiet) + spec.value);
	}

	DietResult result = new DietResult();
	result.rows = dtoRows(dtoDiet, false);
	result.value = dtoValue(dtoDiet);
	if (dtoOverdrinkList) {
		foreach i, sid in dtoOverdrinks {
			int head = dtoNode(sid, -1, dtoSpecs[sid].value);
			DietRow [int] one = dtoRows(head, true);
			result.overdrinks[count(result.overdrinks)] = one[0];
		}
	}
	return result;
}
