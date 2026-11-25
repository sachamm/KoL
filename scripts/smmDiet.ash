// smmDiet.ash -- the daily diet: plans the whole day's food, booze, spleen and
// other turn generation from live KoLmafia data, then buys and consumes it in
// phases. diet.ash is its command; smmdaily runs it. The optimizer itself is
// in smmDietOptimizer.ash, a port of tehtmi's diet calculator.
//
// Every plan covers the whole day: all organs full, cleaners used, organ-size
// gear (and the Stooper) worn for extra space, and an overdrink at the end.
// It is carried out in four phases:
//   1. now: food, booze and spleen in the organs' normal space, with the
//      cleaners; then adventure until those adventures are spent;
//   2. other turn generation that uses no organ (chocolates, tofu and other
//      simple items, magical sausages, Ancestral Recall); then adventure
//      until those are spent;
//   3. end of day: Sweat Out Some Booze, wear the organ-size gear / Stooper
//      and fill every organ to that capacity, never past it;
//   4. overdrink exactly one drink: the one worth most whose adventures fit
//      under the cap; then the gear comes off. Nothing is eaten after it.
// Phases 3 and 4 end useful adventuring (the gear costs you, and overdrunk you
// can only fight from items and skills), so their adventures roll over to
// tomorrow. Rollover keeps at most 200 adventures, so the plan gives a stop
// point: stop adventuring with that many adventures left, then finish. It is
// 200 - what rollover adds - what phases 3-4 add + the turns good_night_adv
// (smmUnrestricted.ash) will spend overdrunk afterwards (fax, Time-Spinner,
// locket, Daycare: smmUtils' goodNightAdvTurns). Holding those turns back
// for after the overdrink is what lets the day end close to 200. When the
// whole nightcap passes 200 even with no adventures held, the stop point is 0
// and the adventures past 200 are spent overdrunk on the best sink (trick-or-
// treating on Hallowe'en, garbo with Drunkula's wineglass, the Beach Comb:
// smmUtils' overdrunkSinks; good_night_adv does it). The nightcap is trimmed
// only where a consumable isn't worth its price at the sink's value per
// adventure, or when there is no sink.
// Organ-reducing items (mojo filter, spice melange, ...) the plan buys are
// phase 1: they are used during execute, as soon as the organ they clear is
// full, since adventuring after them costs nothing.
//
// Usage (gCLI):  call diet.ash [options]     (prints the whole-day plan)
//   execute        buy and consume phase 1 (asks to confirm)
//   turngen        once phase 1's adventures are spent: re-plan, then buy and
//                  consume phases 1-2 (asks to confirm)
//   finish         at the stop point: re-plan, then buy and consume everything
//   (or nightcap)  left, phases 1 to 4 (asks to confirm). It does nothing if
//                  you hold more adventures than the stop point, or if the
//                  plan would lose any adventure at rollover. The organ gear
//                  and Stooper stay on until the overdrink is in. Then run
//                  good_night_adv for the overdrunk fights.
//                  With designer sweatpants, it first casts Sweat Out Some
//                  Booze as often as your sweat allows (25 each, 3 a day) and
//                  plans the drunkenness that frees; other runs only flag it
//   value=N        meat per adventure (default: smm.TurnValue, else 5000)
//   rollover=N     adventures rollover will add (default: smmUtils'
//                  adventureGainAtRollover with the best adventure gear)
//   overdrunk=N    adventures good_night_adv will spend after the overdrink
//                  (default: smmUtils' goodNightAdvTurns)
//   sinkvalue=N    meat per adventure spent overdrunk past the cap (default:
//                  the best of smmUtils' overdrunkSinks; 0: none, trim instead)
//   organs=F,D,S   override remaining fullness,drunkenness,spleen (no gear counted)
//   lucky=N        Lucky! adventures wanted from Lucky Lindy (default 3)
//   pvp=N          meat per PvP fight (default 0)
//   itemdrop=N     meat one adventure with +1% Item Drop is worth, for the
//                  effects consumables give (default: smm.ItemDropValue, else
//                  0.2% of the adventure value: +100% is worth a fifth of an
//                  adventure). Every modifier in smmDietEffectModifiers has such
//                  an option and preference, named after it without spaces
//                  (meatdrop=N / smm.MeatDropValue, familiarweight=N / ...);
//                  0 ignores that modifier
//   noRefresh      don't re-check live mall prices of the chosen items (and
//                  don't look up their average sale prices: buying is still
//                  capped at the average, so an overpriced item stops the run)
//   budget=N       meat the diet may pay today (default: smm.diet.budget,
//                  else 500,000). What earlier runs paid today counts
//                  (_smm.diet.spent). A plan that would pass it is re-planned
//                  at a lower value per adventure until it fits, and no
//                  purchase is made that the Meat left does not cover
//   exclude=a|b|c  item names to leave out
//   yes            answer "yes" to the question before buying (for smmdaily,
//                  which runs unattended); budgets and price caps still apply
//   (execute, turngen and finish handle helpers, effects, Ode to Booze and gear, then
//   restore your outfit and familiar)
//
// Replaces scripts/diet.js (2023-2026), which this is a port of; the
// KoLmafia layer below is Sacha Mallais's (TQuilla #2771003).

import <smmDietOptimizer.ash>
import <smmMuseumPolicy.ash>

string smmDietTrim(string s) {
	matcher m = create_matcher("^\\s*(.*?)\\s*$", s);
	return m.find() ? m.group(1) : s;
}

float smmDietAbs(float x) { return x < 0 ? -x : x; }

// ---------------------------------------------------------------------------
// Options

string [string] smmDietParseArgs(string args) {
	string [string] opts;
	foreach i, part in split_string(args, "\\s+(?=\\w+=|noRefresh\\b|execute\\b|turngen\\b|finish\\b|nightcap\\b|yes\\b)") {
		string p = smmDietTrim(part);
		if (p == "") continue;
		int eq = index_of(p, "=");
		if (eq < 0) opts[p] = "true";
		else opts[substring(p, 0, eq)] = substring(p, eq + 1);
	}
	if (opts contains "nightcap") opts["finish"] = "true";  // same thing
	return opts;
}

boolean smmDietOpt(string [string] opts, string name) { return opts contains name; }

// JavaScript's parseFloat: the number at the start of the text, or none.
boolean smmDietIsNumber(string s) {
	return create_matcher("^\\s*[-+]?(\\d+\\.?\\d*|\\.\\d+)", s).find();
}

float smmDietNumber(string s) {
	matcher m = create_matcher("^\\s*([-+]?(\\d+\\.?\\d*|\\.\\d+))", s);
	return m.find() ? m.group(1).to_float() : 0.0;
}

// JavaScript's parseInt: the integer at the start of the text, else 0.
int smmDietInt(string s) {
	matcher m = create_matcher("^\\s*([-+]?\\d+)", s);
	return m.find() ? m.group(1).to_int() : 0;
}

string smmDietPref(string name) { return get_property(name); }
int smmDietPrefInt(string name) { return smmDietInt(get_property(name)); }
boolean smmDietPrefBool(string name) { return get_property(name) == "true"; }

string smmDietFmt(float n) { return to_string(round(n), "%,d"); }

// ---------------------------------------------------------------------------
// Constants

int kSmmDietBudget = 500000;    // the diet's own daily budget (smmDailyGate.ash has the same default)
float kSmmDietBudgetStep = 0.85; // each re-plan values an adventure this much lower
int kSmmDietPlanPasses = 16;     // re-plans for changed prices and for the budget
float kSmmDietPriceSlack = 1.3;  // pay at most 30% over the planned price
int kSmmDietCap = 200;           // most adventures rollover keeps (only enforced at rollover)
int kSmmDietLastPhase = 4;
int kSmmDietSweatPerCast = 25;
int kSmmDietSweatCastsPerDay = 3;
float kSmmDietHuge = 1000000000000000.0;  // "no limit"

// Organ cleaning that KoLmafia lists only as a note tag ("-2 Drunkenness").
int smmDietOrganIndex(string organ) {
	switch (to_lower_case(organ)) {
	case "fullness": return 0;
	case "drunkenness": return 1;
	case "spleen": return 2;
	}
	return -1;
}

// Limited organ items: name -> KoLmafia counter, uses allowed. From
// KoLmafia's dailylimits.txt; the counter is a "true"/"false" flag or a count.
// Prefs without a leading underscore persist for the whole ascension.
record SmmDietLimit {
	string pref;
	int uses;
};

SmmDietLimit [string] smmDietOrganLimits = {
	"Kudzu salad": new SmmDietLimit("_kudzuSaladEaten", 1),
	"Miss Graves' vermouth": new SmmDietLimit("_missGravesVermouthDrunk", 1),
	"Mr. Burnsger": new SmmDietLimit("_mrBurnsgerEaten", 1),
	"The Plumber's mushroom stew": new SmmDietLimit("_plumbersMushroomStewEaten", 1),
	"The Mad Liquor": new SmmDietLimit("_madLiquorDrunk", 1),
	"Doc Clock's thyme cocktail": new SmmDietLimit("_docClocksThymeCocktailDrunk", 1),
	"Affirmation Cookie": new SmmDietLimit("_affirmationCookieEaten", 1),
	"Hodgman's blanket": new SmmDietLimit("_hodgmansBlanketDrunk", 1),
	"jar of fermented pickle juice": new SmmDietLimit("_pickleJuiceDrunk", 1),
	"extra-greasy slider": new SmmDietLimit("_extraGreasySliderEaten", 1),
	"tin cup of mulligan stew": new SmmDietLimit("_mulliganStewEaten", 1),
	"drippy caviar": new SmmDietLimit("_drippyCaviarUsed", 1),
	"drippy nugget": new SmmDietLimit("_drippyNuggetUsed", 1),
	"drippy plum(?)": new SmmDietLimit("_drippyPlumUsed", 1),
	"drippy pilsner": new SmmDietLimit("_drippyPilsnerUsed", 1),
	"glass of drippy wine": new SmmDietLimit("_drippyWineUsed", 1),
	"Pizza of Legend": new SmmDietLimit("pizzaOfLegendEaten", 1),
	"Calzone of Legend": new SmmDietLimit("calzoneOfLegendEaten", 1),
	"Deep Dish of Legend": new SmmDietLimit("deepDishOfLegendEaten", 1),
	"The Author's ink": new SmmDietLimit("_authorsInkUsed", 1),
	"The Inquisitor's unidentifiable object": new SmmDietLimit("_inquisitorsUnidentifiableObjectUsed", 1),
	"mansquito serum": new SmmDietLimit("_mansquitoSerumUsed", 1),
	"voodoo snuff": new SmmDietLimit("_voodooSnuffUsed", 1),
	"turkey blaster": new SmmDietLimit("_turkeyBlastersUsed", 3),
};

// Uses of a limited item left (today, or this ascension).
int smmDietLimitLeft(SmmDietLimit limit) {
	string v = smmDietPref(limit.pref);
	int used = v == "true" ? 1 : (v == "false" ? 0 : smmDietInt(v));
	return max(0, limit.uses - used);
}

// Spleen items whose value isn't adventures: name -> PvP fights.
int [string] smmDietSpleenPvp = {"Purple Beast energy drink": 3, "sweat-ade": 5};

// Equipment that adds organ capacity: slot and [stomach, liver, spleen].
// Accessories share the three accessory slots.
record SmmDietCapacity {
	string slot;
	int f;
	int d;
	int s;
};

SmmDietCapacity [string] smmDietCapacityGear = {
	"angelbone chopsticks": new SmmDietCapacity("acc", 1, 0, 0),
	"angelbone dice": new SmmDietCapacity("acc", 0, 1, 0),
	"devilbone rosary": new SmmDietCapacity("acc", 0, 1, 0),
	"devilbone corset": new SmmDietCapacity("shirt", 1, 0, 0),
	"angelbone totem": new SmmDietCapacity("weapon", 0, 0, 1),
	"devilbone greaves": new SmmDietCapacity("pants", 0, 0, 1),
};
string [int] smmDietCapacityOrder = {"angelbone chopsticks", "angelbone dice", "devilbone rosary", "devilbone corset", "angelbone totem", "devilbone greaves"};

// Clan speakeasy drinks, keyed by item id (names contain quotes / entities).
int [int] smmDietSpeakeasy = {
	7589: 250, 7590: 250, 7591: 250, 7592: 500, 7593: 500, 7594: 500,
	7595: 500, 7596: 5000, 7597: 10000, 7598: 20000, 7599: 100000,
};

// KoLmafia note tags -> the optimizer's "item class".
string [string] smmDietClassTags = {
	"SAUCY": "saucy food", "PIZZA": "pizza", "TACO": "taco", "SALAD": "salad",
	"LASAGNA": "lasagna", "BEER": "beer", "WINE": "wine",
};

// Non-organ items the optimizer uses as helpers or chocolates. From index
// kSmmDietFirstChocolate on, they are chocolates.
string [int] smmDietHelpers = {
	"Ol' Scratch's salad fork", "fudge spork", "munchies pill", "Frosty's frosty mug",
	"BGE shotglass", "potion of the field gar", "pocket wish", "blue mana",
	"temporary X tattoos", "Taco Dan's Super Taco-Riffic Taco Sauce!", "Special Seasoning",
	"fancy chocolate", "fancy but probably evil chocolate", "fancy chocolate car",
	"beet-flavored Mr. Mediocrebar", "cabbage-flavored Mr. Mediocrebar",
	"sweet-corn-flavored Mr. Mediocrebar", "choco-Crimbot",
	"chocolate seal-clubbing club", "chocolate turtle totem", "chocolate pasta spoon",
	"chocolate saucepan", "chocolate disco ball", "chocolate stolen accordion",
	"vitachoconutriment capsule", "chocolate cigar", "fancy chocolate sculpture",
};
int kSmmDietFirstChocolate = 11;

boolean smmDietIsChocolate(string name) {
	foreach i, h in smmDietHelpers if (i >= kSmmDietFirstChocolate && h == name) return true;
	return false;
}

record SmmDietListed {
	string name;
	int [int] size;  // extenders
	float adv;       // simple items
	int pvp;
	int left;        // uses left today
};

SmmDietListed smmDietListed(string name, int f, int d, int s, float adv, int pvp, int left) {
	SmmDietListed x = new SmmDietListed();
	x.name = name;
	x.size = dtoSize(f, d, s);
	x.adv = adv;
	x.pvp = pvp;
	x.left = max(0, left);
	return x;
}

int smmDietUnusedFlag(string pref) { return smmDietPrefBool(pref) ? 0 : 1; }

// Organ-space extenders, with the uses left today.
SmmDietListed [int] smmDietExtenders() {
	SmmDietListed [int] l;
	l[0] = smmDietListed("mojo filter", 0, 0, -1, 0, 0, 3 - smmDietPrefInt("currentMojoFilters"));
	l[1] = smmDietListed("spice melange", -3, -3, 0, 0, 0, smmDietUnusedFlag("spiceMelangeUsed"));
	l[2] = smmDietListed("Ultra Mega Sour Ball", -3, -3, 0, 0, 0, smmDietUnusedFlag("_ultraMegaSourBallUsed"));
	l[3] = smmDietListed("lupine appetite hormones", -3, 0, 0, 0, 0, smmDietUnusedFlag("_lupineHormonesUsed"));
	l[4] = smmDietListed("sweet tooth", -1, 0, 0, 0, 0, smmDietUnusedFlag("_sweetToothUsed"));
	l[5] = smmDietListed("distention pill", -1, 0, 0, 0, 0, smmDietUnusedFlag("_distentionPillUsed"));
	l[6] = smmDietListed("cuppa Voraci tea", -1, 0, 0, 0, 0, smmDietUnusedFlag("_voraciTeaUsed"));
	l[7] = smmDietListed("cuppa Sobrie tea", 0, -1, 0, 0, 0, smmDietUnusedFlag("_sobrieTeaUsed"));
	l[8] = smmDietListed("synthetic dog hair pill", 0, -1, 0, 0, 0, smmDietUnusedFlag("_syntheticDogHairPillUsed"));
	l[9] = smmDietListed("alien plant pod", 0, -3, 0, 0, 0, smmDietUnusedFlag("_alienPlantPodUsed"));
	l[10] = smmDietListed("alien animal milk", -3, 0, 0, 0, 0, smmDietUnusedFlag("_alienAnimalMilkUsed"));
	return l;
}

// Items that give adventures or fights without using an organ, with the uses left.
SmmDietListed [int] smmDietSimple() {
	SmmDietListed [int] l;
	l[0] = smmDietListed("milk of magnesium", 0, 0, 0, 5, 0, smmDietUnusedFlag("_milkOfMagnesiumUsed"));
	l[1] = smmDietListed("essential tofu", 0, 0, 0, 5, 0, smmDietUnusedFlag("_essentialTofuUsed"));
	l[2] = smmDietListed("resolution: be more adventurous", 0, 0, 0, 2, 0, 5 - smmDietPrefInt("_resolutionAdv"));
	l[3] = smmDietListed("Hunger&trade; Sauce", 0, 0, 0, 3, 0, smmDietUnusedFlag("_hungerSauceUsed"));
	l[4] = smmDietListed("brain preservation fluid", 0, 0, 0, 5, 0, smmDietUnusedFlag("_brainPreservationFluidUsed"));
	l[5] = smmDietListed("Twelve Night Energy", 0, 0, 0, 12, 0, smmDietUnusedFlag("_twelveNightEnergyUsed"));
	l[6] = smmDietListed("confusing LED clock", 0, 0, 0, -5, 5, smmDietUnusedFlag("_confusingLEDClockUsed"));
	l[7] = smmDietListed("Jerks' Health&trade; Magazine", 0, 0, 0, 0, 1, 5 - smmDietPrefInt("_jerksHealthMagazinesUsed"));
	l[8] = smmDietListed("Meteorite-Ade", 0, 0, 0, 0, 5, 3 - smmDietPrefInt("_meteoriteAdesUsed"));
	return l;
}

// ---------------------------------------------------------------------------
// Museum collection. Until you are #1 for an item, every copy you own is
// collection stock, not free food. smmMuseumPolicy.ash decides how many owned
// copies are spare (beyond the #1 target); only those may be eaten, and a
// bought item is bought fresh rather than taken from the reserved copies.

record SmmDietSpare {
	int spare;
	int liquid;
};
SmmDietSpare [item] smmDietMuseumSpare;
boolean smmDietMuseumKnown;  // false when the Museum data is unavailable

void smmDietLoadMuseumSpare(boolean [item] candidates) {
	clear(smmDietMuseumSpare);
	smmDietMuseumKnown = true;
	foreach it in candidates {
		if (available_amount(it) <= 0 || !is_displayable(it)) continue;
		SmmDietSpare e = new SmmDietSpare();
		e.spare = smmMuseumSpareCopies(it);
		e.liquid = round(smmItemLiquidValue(it));
		smmDietMuseumSpare[it] = e;
	}
}

// Owned copies the diet may use up.
int smmDietSpareCopies(item it) {
	int have = available_amount(it);
	if (have <= 0 || !is_displayable(it)) return have;
	if (!smmDietMuseumKnown || !(smmDietMuseumSpare contains it)) return 0;
	return min(have, smmDietMuseumSpare[it].spare);
}

// Owned copies the Museum still needs: never consumed.
int smmDietReservedCopies(item it) { return max(0, available_amount(it) - smmDietSpareCopies(it)); }

// ---------------------------------------------------------------------------
// Prices

record SmmDietPrice {
	boolean ok;      // false when the item can't be had
	float price;
	int limit;       // 0: none
	boolean owned;
};

SmmDietPrice [item] smmDietPriceCache;

// Meat cost of one of an item: mall (or NPC store if cheaper). Untradeable
// items cost what a spare owned copy could otherwise be turned into (at least
// 1 meat) and are capped at the number of spare copies.
SmmDietPrice smmDietPriceOf(item it, boolean fresh) {
	if (!fresh && (smmDietPriceCache contains it) && smmDietPriceCache[it].ok) return smmDietPriceCache[it];
	float p = 0;
	if (is_tradeable(it)) {
		p = fresh ? mall_price(it) : historical_price(it);
		if (p <= 0 && !fresh) p = 0;
	}
	int npc = npc_price(it);
	if (npc > 0 && (p <= 0 || npc < p)) p = npc;
	SmmDietPrice result = new SmmDietPrice();
	if (p > 0) {
		result.ok = true;
		result.price = p;
	} else {
		int spare = smmDietSpareCopies(it);
		int liquid = smmDietMuseumSpare contains it ? smmDietMuseumSpare[it].liquid : autosell_price(it);
		if (spare > 0) {
			result.ok = true;
			result.price = max(1, liquid);
			result.limit = spare;
			result.owned = true;
		}
	}
	smmDietPriceCache[it] = result;
	return result;
}

SmmDietPrice smmDietPriceOf(item it) { return smmDietPriceOf(it, false); }

// The spending rules (docs/aftercore-goals.md): nothing is bought above its
// average sale price. The average comes from Pricegun: an answer for this
// item with at least one sale and one history entry. Anything else is
// "unknown" (0).
float smmDietParseAverage(string text, int id) {
	matcher ident = create_matcher("\"itemId\"\\s*:\\s*([0-9]+)", text);
	if (!ident.find() || ident.group(1).to_int() != id) return 0;
	if (!create_matcher("\"sales\"\\s*:\\s*\\[\\s*\\{", text).find()) return 0;
	if (!create_matcher("\"history\"\\s*:\\s*\\[\\s*\\{", text).find()) return 0;
	matcher dec = create_matcher("\"value\"\\s*:\\s*\\{\\s*\"__decimal__\"\\s*:\\s*\"(-?[0-9]+(?:\\.[0-9]+)?)\"", text);
	if (dec.find()) return max(0.0, dec.group(1).to_float());
	matcher num = create_matcher("\"value\"\\s*:\\s*(-?[0-9]+(?:\\.[0-9]+)?)\\s*[,}]", text);
	if (num.find()) return max(0.0, num.group(1).to_float());
	return 0;
}

float [item] smmDietAverageCache;  // 0 when unknown

float smmDietAverageSalePrice(item it) {
	if (!(smmDietAverageCache contains it))
		smmDietAverageCache[it] = smmDietParseAverage(visit_url("https://pricegun.loathers.net/api/" + to_int(it), false, false), to_int(it));
	return smmDietAverageCache[it];
}

// What to do with a planned item the mall sells at price:
//   "buy"   at or under the average, or the average is unknown (no sales on
//           record: the current listing is the only price there is);
//   "owned" above the average, but spare copies are owned: use only those;
//   "drop"  above the average and none to spare: leave it out of the diet.
string smmDietAverageRule(float price, float average, int spare) {
	if (!(average > 0) || price <= average) return "buy";
	return spare > 0 ? "owned" : "drop";
}

// The most the diet may pay for one copy: the planned price with its slack,
// never more than the average sale price when that is known, and never more
// than an equal share of the Meat left in the budget (left, for n copies;
// kSmmDietHuge for no budget to mind). Prices can rise between plan and purchase.
int smmDietBuyCap(float planned, float average, float left, int n) {
	int cap = ceil(planned * kSmmDietPriceSlack);
	if (average > 0) cap = min(cap, floor(average));
	if (n > 0 && left < kSmmDietHuge) cap = min(cap, floor(left / n));
	return max(0, cap);
}

// Whether the budget still has cost Meat in it. What costs nothing is always
// allowed, even on a budget already passed.
boolean smmDietCanAfford(float cost, float left) { return cost <= 0 || left >= cost; }

int smmDietBudget(string [string] opts) {
	string explicit = opts contains "budget" ? opts["budget"] : smmDietPref("smm.diet.budget");
	matcher m = create_matcher("^\\s*[-+]?\\d+", explicit);
	return m.find() ? max(0, smmDietInt(explicit)) : kSmmDietBudget;
}

// ---------------------------------------------------------------------------
// Magical sausages: no fullness, 1 adventure each, 23 a day. Owned spare ones
// are free; more are ground from casings with a Kramco Sausage-o-Matic for
// 111 meat times the number made today (meat already in the grinder counts).
// Priced at the average cost of all of them, since at any sensible adventure
// value every one is worth eating.

// Meat the grinder asks for n more sausages, when made were made today and
// it already holds units Meat.
int smmDietSausageCost(int n, int made, int units) {
	int cost = 0;
	for (int j = 1; j <= n; j++) cost += 111 * (made + j);
	return max(0, cost - units);
}

// How many of n more sausages that Meat already covers.
int smmDietFreeSausages(int n, int made, int units) {
	int free = 0;
	while (free < n && smmDietSausageCost(free + 1, made, units) == 0) free += 1;
	return free;
}

DietItem smmDietNewItem(string name) {
	DietItem e = new DietItem();
	e.name = name;
	e.free = -1;
	return e;
}

boolean smmDietSausageEntry(DietItem e) {
	item it = $item[magical sausage];
	int left = 23 - smmDietPrefInt("_sausagesEaten");
	if (left <= 0) return false;
	int owned = min(left, smmDietSpareCopies(it));
	int make = 0;
	int makeCost = 0;
	int free = 0;
	if (available_amount($item[Kramco Sausage-o-Matic&trade;]) > 0 || available_amount($item[replica Kramco Sausage-o-Matic&trade;]) > 0) {
		make = min(left - owned, available_amount($item[magical sausage casing]));
		makeCost = smmDietSausageCost(make, smmDietPrefInt("_sausagesMade"), smmDietPrefInt("sausageGrinderUnits"));
		free = smmDietFreeSausages(make, smmDietPrefInt("_sausagesMade"), smmDietPrefInt("sausageGrinderUnits"));
	}
	int n = owned + make;
	if (n <= 0) return false;
	e.name = it.name;
	e.advmin = 1;
	e.advmax = 1;
	e.type = "simple";
	e.hasSize = true;
	e.size = dtoSize(0, 0, 0);
	e.limit = n;
	e.price = max(1, round(to_float(makeCost) / n));
	e.owned = true;
	e.eat = true;
	e.free = owned + free;  // the ones that cost no Meat
	return true;
}

// ---------------------------------------------------------------------------
// Effects. A consumable that gives an effect (Sacramento wine: 50 adventures
// of +50% Item Drop) is worth more than its adventures. Effects only wear off
// as you adventure, so every turn of one counts, whenever it is consumed.
// Each modifier below is worth a set amount of meat per adventure per point,
// given as a fraction of the adventure value and anchored at +100% Item Drop
// = a fifth of an adventure. The rest are rough estimates relative to that
// for aftercore farming; override any of them with its option or preference
// (see smmDietEffectRates). Left out: modifiers whose worth has no fixed sign
// or size (Combat Rate, Fumble, zone- and path-specific ones).
float [string] smmDietEffectModifiers = {
	// drops
	"Item Drop": 0.002, "Item Drop Penalty": 0.002, "Sporadic Item Drop": 0.0005,
	"Meat Drop": 0.001, "Meat Drop Penalty": 0.001, "Sporadic Meat Drop": 0.00025,
	"Food Drop": 0.0005, "Booze Drop": 0.0005, "Candy Drop": 0.0005, "Gear Drop": 0.0005,
	"Hat Drop": 0.0005, "Weapon Drop": 0.0005, "Offhand Drop": 0.0005, "Shirt Drop": 0.0005,
	"Pants Drop": 0.0005, "Accessory Drop": 0.0005, "Spleen Drop": 0.0005, "Potion Drop": 0.0005,
	"Pickpocket Chance": 0.0005,
	// familiar
	"Familiar Weight": 0.005, "Hidden Familiar Weight": 0.005, "Familiar Weight Percent": 0.001,
	"Familiar Experience": 0.005, "Familiar Action Bonus": 0.0005, "Familiar Damage": 0.00002,
	// stats and experience
	"Experience": 0.0005, "Monster Level": 0.0002, "Monster Level Percent": 0.0002,
	"Muscle Experience": 0.0002, "Mysticality Experience": 0.0002, "Moxie Experience": 0.0002,
	"Muscle Experience Percent": 0.00005, "Mysticality Experience Percent": 0.00005,
	"Moxie Experience Percent": 0.00005,
	"Muscle": 0.00002, "Mysticality": 0.00002, "Moxie": 0.00002,
	"Muscle Percent": 0.00002, "Mysticality Percent": 0.00002, "Moxie Percent": 0.00002,
	// HP and MP (a cheaper skill is a negative Mana Cost)
	"Maximum HP": 0.000005, "Maximum MP": 0.000005, "Maximum HP Percent": 0.00001, "Maximum MP Percent": 0.00001,
	"HP Regen Min": 0.00002, "HP Regen Max": 0.00002, "MP Regen Min": 0.0002, "MP Regen Max": 0.0002,
	"Mana Cost": -0.001, "Stackable Mana Cost": -0.001, "Combat Mana Cost": -0.0005,
	// combat
	"Initiative": 0.00005, "Initiative Penalty": 0.00005,
	"Damage Absorption": 0.00001, "Damage Reduction": 0.0001,
	"Cold Resistance": 0.0002, "Hot Resistance": 0.0002, "Sleaze Resistance": 0.0002,
	"Spooky Resistance": 0.0002, "Stench Resistance": 0.0002,
	"Weapon Damage": 0.00002, "Weapon Damage Percent": 0.00002, "Ranged Damage": 0.00002,
	"Ranged Damage Percent": 0.00002, "Spell Damage": 0.00002, "Spell Damage Percent": 0.00002,
	"Cold Damage": 0.00002, "Hot Damage": 0.00002, "Sleaze Damage": 0.00002,
	"Spooky Damage": 0.00002, "Stench Damage": 0.00002,
	"Cold Spell Damage": 0.00002, "Hot Spell Damage": 0.00002, "Sleaze Spell Damage": 0.00002,
	"Spooky Spell Damage": 0.00002, "Stench Spell Damage": 0.00002,
	"Critical Hit Percent": 0.00005, "Spell Critical Percent": 0.00005,
	"Damage Aura": 0.00002, "Thorns": 0.00002,
};

// Meat per adventure per point of each valued modifier. "Item Drop" is set by
// option itemdrop=N, else preference smm.ItemDropValue, else its fraction
// above; the others likewise.
float [string] smmDietEffectRates(string [string] opts, float advValue) {
	float [string] rates;
	foreach name, fraction in smmDietEffectModifiers {
		string key = replace_all(create_matcher("[^A-Za-z]", name), "");
		string o = opts[to_lower_case(key)];
		float v;
		if (smmDietIsNumber(o)) v = smmDietNumber(o);
		else if (smmDietIsNumber(smmDietPref("smm." + key + "Value"))) v = smmDietNumber(smmDietPref("smm." + key + "Value"));
		else v = fraction * advValue;
		if (v != 0) rates[name] = v;
	}
	return rates;
}

// The effect one of an item gives and what it is worth; false when it gives
// none or none of its modifiers is valued.
boolean smmDietEffectOf(item it, float [string] rates, DietItem e) {
	effect eff = effect_modifier(it, "Effect");
	if (eff == $effect[none]) return false;
	float turns = numeric_modifier(it, "Effect Duration");
	if (!(turns > 0)) return false;
	float perTurn = 0;
	foreach name, rate in rates perTurn += numeric_modifier(eff, name) * rate;
	if (perTurn == 0) return false;
	e.effectName = eff.to_string();
	e.effectTurns = round(turns);
	e.effectValue = round(turns * perTurn);
	e.effectvalue = e.effectValue;
	return true;
}

void smmDietParseAdventures(string s, DietItem e) {
	matcher m = create_matcher("^\\s*(-?\\d+(?:\\.\\d+)?)(?:\\s*-\\s*(-?\\d+(?:\\.\\d+)?))?\\s*$", s);
	if (!m.find()) return;
	e.advmin = m.group(1).to_float();
	e.advmax = m.group(2) != "" ? m.group(2).to_float() : e.advmin;
}

// Everything buildConsumables might price: organ items plus helpers, extenders and simple items.
boolean [item] smmDietCandidates() {
	boolean [item] list;
	foreach it in $items[] if (it.fullness > 0 || it.inebriety > 0 || it.spleen > 0) list[it] = true;
	foreach i, name in smmDietHelpers list[to_item(name)] = true;
	foreach i, x in smmDietExtenders() list[to_item(x.name)] = true;
	foreach i, x in smmDietSimple() list[to_item(x.name)] = true;
	list[$item[magical sausage]] = true;
	remove list[$item[none]];
	return list;
}

void smmDietAdd(DietItem e) { dietConsumables[count(dietConsumables)] = e; }

// lucky: Lucky! effects wanted; rates: smmDietEffectRates
void smmDietBuildConsumables(boolean [string] excluded, int lucky, float [string] rates) {
	clear(dietConsumables);
	int myLevel = my_level();
	foreach it in $items[] {
		int f = it.fullness;
		int d = it.inebriety;
		int s = it.spleen;
		if (f <= 0 && d <= 0 && s <= 0) continue;
		if (excluded[it.name]) continue;
		if (it.levelreq > myLevel) continue;
		if (it.quality == "pseudoitem") continue;
		string [int] tags = split_string(it.notes, "\\s*,\\s*");
		boolean skip = false;
		foreach i, t in tags if (t == "Vampyre" || t == "KOLHS") skip = true;
		if (skip) continue;

		DietItem e = smmDietNewItem(it.name);
		smmDietParseAdventures(it.adventures, e);
		e.type = f > 0 ? "food" : (d > 0 ? "booze" : "spleen");
		e.hasSize = true;
		e.size = dtoSize(f, d, s);
		foreach i, raw in tags {
			string tag = smmDietTrim(raw);
			matcher clean = create_matcher("(?i)^-(\\d+) (fullness|drunkenness|spleen)$", tag);
			if (clean.find()) e.size[smmDietOrganIndex(clean.group(2))] -= clean.group(1).to_int();
			if (smmDietClassTags contains tag) e.itemClass = smmDietClassTags[tag];
			if (tag == "MARTINI") e.tuxedo = true;
		}
		if (smmDietOrganLimits contains it.name) {
			e.limit = smmDietLimitLeft(smmDietOrganLimits[it.name]);
			if (e.limit <= 0) continue;
		}
		if (smmDietSpleenPvp contains it.name) e.pvpfights = smmDietSpleenPvp[it.name];
		if (it == $item[clovermint]) {
			// Lucky! doesn't stack, so one is worth a clover; skip it if no Lucky! is wanted
			if (lucky <= 0 || have_effect($effect[Lucky!]) > 0) continue;
			e.bonusvalue = dietSemirareValue;
			e.limit = 1;
		}
		if (it == $item[Three Sheets to the Wind]) {
			// Wetted Whistle: +10 adventures at rollover, if nothing is adventured
			// after it -- so it is always drunk in phase 3 (see smmDietSplitPhases)
			e.bonusadv = 10;
			e.limit = 1;
		}
		if (count(rates) > 0) smmDietEffectOf(it, rates, e);

		if (smmDietSpeakeasy contains to_int(it)) {
			e.speakeasy = smmDietSpeakeasy[to_int(it)];
		} else if (it == $item[Cold One] || it == $item[spaghetti breakfast]) {
			// priced by the optimizer (5 meat) when the skill is available;
			// otherwise only if you already have some
			SmmDietPrice cp = smmDietPriceOf(it);
			if (cp.ok) {
				e.price = cp.price;
				e.owned = true;
			}
		} else {
			SmmDietPrice pr = smmDietPriceOf(it);
			if (!pr.ok) continue;
			e.price = pr.price;
			if (pr.limit > 0) {
				e.limit = e.limit != 0 ? min(e.limit, pr.limit) : pr.limit;
				e.owned = true;
			}
		}
		smmDietAdd(e);
	}

	foreach i, name in smmDietHelpers {
		item hi = to_item(name);
		if (excluded[hi.name]) continue;
		SmmDietPrice hp = smmDietPriceOf(hi);
		if (hp.ok && !hp.owned) {
			DietItem e = smmDietNewItem(hi.name);
			e.price = hp.price;
			smmDietAdd(e);
		}
	}
	DietItem sausage = smmDietNewItem("magical sausage");
	if (smmDietSausageEntry(sausage) && !excluded[sausage.name]) smmDietAdd(sausage);
	if (get_workshed() == $item[portable Mayo Clinic]) {
		DietItem flex = smmDietNewItem("Mayoflex");
		flex.price = 1000;
		smmDietAdd(flex);
		DietItem diol = smmDietNewItem("Mayodiol");
		diol.price = 1000;
		smmDietAdd(diol);
	}

	foreach i, x in smmDietExtenders() {
		if (x.left <= 0 || excluded[x.name]) continue;
		SmmDietPrice ep = smmDietPriceOf(to_item(x.name));
		if (!ep.ok) continue;
		DietItem e = smmDietNewItem(x.name);
		e.price = ep.price;
		e.type = "extender";
		e.hasSize = true;
		e.size = dtoCopySize(x.size);
		e.limit = min(x.left, ep.limit > 0 ? ep.limit : 99);
		smmDietAdd(e);
	}
	foreach i, x in smmDietSimple() {
		if (x.left <= 0 || excluded[x.name]) continue;
		item si = to_item(x.name);
		SmmDietPrice sp = smmDietPriceOf(si);
		if (!sp.ok) continue;
		DietItem e = smmDietNewItem(si.name);
		e.advmin = x.adv;
		e.advmax = x.adv;
		e.pvpfights = x.pvp;
		e.price = sp.price;
		e.type = "simple";
		e.hasSize = true;
		e.size = dtoSize(0, 0, 0);
		e.limit = min(x.left, sp.limit > 0 ? sp.limit : 99);
		smmDietAdd(e);
	}
}

// ---------------------------------------------------------------------------
// Settings

int smmDietClassId() {
	switch (my_class()) {
	case $class[Seal Clubber]: return 1;
	case $class[Turtle Tamer]: return 2;
	case $class[Pastamancer]: return 3;
	case $class[Sauceror]: return 4;
	case $class[Disco Bandit]: return 5;
	case $class[Accordion Thief]: return 6;
	}
	return 0;
}

// Gar-ish does nothing on Mondays (KoL server time, Arizona = UTC-7).
boolean smmDietIsGarishDay() {
	int days = (now_to_int() - 7 * 3600 * 1000) / (86400 * 1000);
	return (days + 3) % 7 != 0;  // 1970-01-01 was a Thursday
}

string [int] smmDietGearSlots = {"acc1", "acc2", "acc3", "shirt", "weapon", "pants"};
string [int] smmDietAccSlots = {"acc1", "acc2", "acc3"};

boolean smmDietIsCapacityGearIn(string slotName) {
	return smmDietCapacityGear contains equipped_item(to_slot(slotName)).name;
}

DietGear smmDietGear(string name, string slotName, SmmDietCapacity g, boolean worn) {
	DietGear x = new DietGear();
	x.name = name;
	x.slot = slotName;
	x.size = dtoSize(g.f, g.d, g.s);
	x.worn = worn;
	return x;
}

// Organ-capacity gear for phase 3. Gear you are wearing now counts too, but
// not toward phase 1, since you'd take it off to adventure. The corset is
// skipped when a tuxedo shirt can boost martinis, and one accessory slot is
// left for the pinky ring.
DietGear [int] smmDietCapacityGearList(boolean tuxedo, boolean ring) {
	DietGear [int] gear;
	boolean [string] taken;
	foreach i, slotName in smmDietGearSlots {
		string worn = equipped_item(to_slot(slotName)).name;
		if ((smmDietCapacityGear contains worn) && !(taken contains worn)) {
			gear[count(gear)] = smmDietGear(worn, slotName, smmDietCapacityGear[worn], true);
			taken[worn] = true;
		}
	}
	string [int] accSlots;
	foreach i, slotName in smmDietAccSlots if (!smmDietIsCapacityGearIn(slotName)) accSlots[count(accSlots)] = slotName;
	if (ring && count(accSlots) > 0) remove accSlots[count(accSlots) - 1];
	int nextAcc = 0;
	foreach i, name in smmDietCapacityOrder {
		if (taken contains name) continue;
		SmmDietCapacity g = smmDietCapacityGear[name];
		item it = to_item(name);
		if (available_amount(it) <= 0 || !can_equip(it)) continue;
		if (g.slot == "shirt" && (tuxedo || !(have_skill($skill[Torso Awareness]) || have_skill($skill[Best Dressed])))) continue;
		string slotName = g.slot;
		if (slotName == "acc") {
			if (nextAcc >= count(accSlots)) continue;
			slotName = accSlots[nextAcc];
			nextAcc += 1;
		}
		gear[count(gear)] = smmDietGear(name, slotName, g, false);
	}
	return gear;
}

// Accessory slot for the pinky ring: one not holding capacity gear.
slot smmDietRingSlot() {
	for (int i = 2; i >= 0; i--) {
		if (!smmDietIsCapacityGearIn(smmDietAccSlots[i])) return to_slot(smmDietAccSlots[i]);
	}
	return $slot[acc3];
}

boolean smmDietHaveUsable(item it) { return available_amount(it) > 0 && can_equip(it); }

// Sweat Out Some Booze (designer sweatpants, held or worn): 25 sweat for -1
// drunkenness, 3 casts a day. Sweat builds while you adventure in the pants.
void smmDietSweat(DietSettings s) {
	s.sweatHave = available_amount($item[designer sweatpants]) > 0;
	s.sweatAmount = smmDietPrefInt("sweat");
	s.sweatLeft = s.sweatHave ? max(0, kSmmDietSweatCastsPerDay - smmDietPrefInt("_sweatOutSomeBoozeUsed")) : 0;
	s.sweatReady = min(s.sweatLeft, s.sweatAmount / kSmmDietSweatPerCast);
}

// Casts worth making now: each needs drunkenness to remove, and casting is
// pointless if you'd still be over your liver limit afterwards.
int smmDietSweatCastsNow(DietSettings s) {
	int n = min(s.sweatReady, my_inebriety());
	if (my_inebriety() - n > inebriety_limit()) return 0;
	return max(0, n);
}

// One cast at a time (multicasting it has been unreliable).
int smmDietCastSweatOutBooze(int n, string [int] log) {
	int done = 0;
	for (int i = 0; i < n; i++) {
		int used = smmDietPrefInt("_sweatOutSomeBoozeUsed");
		int drunk = my_inebriety();
		boolean ok = use_skill(1, $skill[Sweat Out Some Booze]);
		if (!ok || (smmDietPrefInt("_sweatOutSomeBoozeUsed") == used && my_inebriety() == drunk)) break;
		done += 1;
	}
	if (done < n) log[count(log)] = "warning: cast Sweat Out Some Booze " + done + " of " + n + " times; plan may not fit";
	return done;
}

DietSettings smmDietBuildSettings(string [string] opts) {
	DietSettings s = new DietSettings();
	float advValue = smmDietNumber(opts["value"]);
	if (advValue == 0) advValue = smmDietNumber(smmDietPref("smm.TurnValue"));
	if (advValue == 0) advValue = 5000;
	s.advValue = advValue;
	// Sweat Out Some Booze is cast only by finish (the day's last run), so
	// only finish counts the drunkenness it frees.
	smmDietSweat(s);
	s.sweatCasts = smmDietOpt(opts, "finish") && !smmDietOpt(opts, "organs") ? smmDietSweatCastsNow(s) : 0;
	int inebriety = my_inebriety() - s.sweatCasts;
	boolean overdrunk = inebriety > inebriety_limit();
	int [int] organs = dtoSize(fullness_limit() - my_fullness(), max(0, inebriety_limit() - inebriety), spleen_limit() - my_spleen_use());
	// The optimizer plans no nightcap: phase 4 is one overdrink, picked by
	// smmDietPlanDay from the optimizer's single-drink candidates.

	// organs: space for the whole day. base: what phase 1 may use -- without
	// organ gear or the Stooper, even if they're on now.
	DietGear [int] gear;
	boolean stooper = false;
	if (smmDietOpt(opts, "organs")) {
		string [int] o = split_string(opts["organs"], ",");
		organs = dtoSize(smmDietInt(o[0]), count(o) > 1 ? smmDietInt(o[1]) : 0, count(o) > 2 ? smmDietInt(o[2]) : 0);
	} else {
		gear = smmDietCapacityGearList(smmDietHaveUsable($item[tuxedo shirt]), smmDietHaveUsable($item[mafia pinky ring]));
		if (overdrunk) {
			DietGear [int] kept;
			foreach i, g in gear if (g.size[1] == 0) kept[count(kept)] = g;
			gear = kept;
		}
		boolean stooperOut = my_familiar() == $familiar[Stooper];
		stooper = !overdrunk && have_familiar($familiar[Stooper]);
		if (stooper && !stooperOut) organs[1] += 1;
		foreach i, g in gear {
			if (g.worn) continue;
			for (int o = 0; o < 3; o++) organs[o] += g.size[o];
		}
	}
	int [int] base = dtoCopySize(organs);
	foreach i, g in gear for (int o = 0; o < 3; o++) base[o] -= g.size[o];
	if (stooper) base[1] -= 1;

	int speakeasyLeft = max(0, 3 - smmDietPrefInt("_speakeasyDrinksDrunk"));
	boolean hasSpeakeasy = (get_clan_lounge() contains $item[Clan speakeasy]) && speakeasyLeft > 0;

	boolean [string] excluded;
	if (opts contains "exclude") foreach i, name in split_string(opts["exclude"], "\\|") excluded[smmDietTrim(name)] = true;
	if (smmDietPrefBool("_fudgeSporkUsed")) excluded["fudge spork"] = true;
	if (smmDietPrefBool("_affirmationCookieEaten")) excluded["Affirmation Cookie"] = true;
	if (smmDietPrefBool("_spaghettiBreakfastEaten") || my_fullness() > 0) excluded["spaghetti breakfast"] = true;
	if (smmDietPrefBool("_coldOne") && available_amount($item[Cold One]) == 0) excluded["Cold One"] = true;

	int lucky = opts contains "lucky" ? smmDietInt(opts["lucky"]) : 3;

	s.pvpValue = smmDietNumber(opts["pvp"]);
	s.classid = smmDietClassId();
	s.overdrinkCandidates = !overdrunk;
	s.saucemaven = have_skill($skill[Saucemaven]);
	s.pizzaLover = have_skill($skill[Pizza Lover]);
	s.recall = have_skill($skill[Ancestral Recall]);
	s.breakfast = have_skill($skill[Spaghetti Breakfast]) && !excluded["spaghetti breakfast"];
	s.coldOne = have_skill($skill[Grab a Cold One]) && !smmDietPrefBool("_coldOne");
	s.fieldGar = smmDietIsGarishDay();
	s.tuxedo = smmDietHaveUsable($item[tuxedo shirt]);
	s.ring = smmDietHaveUsable($item[mafia pinky ring]);
	s.mime = available_amount($item[mime army shotglass]) > 0 && !smmDietPrefBool("_mimeArmyShotglassUsed");
	s.speakeasy = hasSpeakeasy;
	s.ode = have_skill($skill[The Ode to Booze]);
	s.semirares = hasSpeakeasy ? min(lucky, speakeasyLeft) : 0;
	s.luckyWanted = lucky;
	s.effectRates = smmDietEffectRates(opts, advValue);
	s.workshed = get_workshed() == $item[portable Mayo Clinic] ? "mayo" : "none";
	s.excluded = excluded;
	s.organs = organs;
	s.base = base;
	s.gear = gear;
	s.stooper = stooper;
	// KoLmafia already rewrites the cookie's adventures from affirmationCookiesEaten
	// (3, 5, 7, then 9), so no bonus is added on top.
	s.affirmationBonus = 0;
	s.speakeasyLeft = speakeasyLeft;
	s.recallLeft = max(0, 10 - smmDietPrefInt("_ancestralRecallCasts"));
	s.chocFancy = smmDietPrefInt("_chocolatesUsed");
	s.chocVita = smmDietPrefInt("_vitachocCapsulesUsed");
	s.chocCigar = smmDietPrefInt("_chocolateCigarsUsed");
	s.chocSculpture = smmDietPrefInt("_chocolateSculpturesUsed");
	return s;
}

// ---------------------------------------------------------------------------
// Phases. The optimizer plans the whole day; smmDietSplitPhases decides which
// units are consumed in each phase:
//   1 now: food, booze and spleen that fit the organs' normal space, with all
//     cleaners
//   2 once phase 1's adventures are spent: other turn generation that uses no
//     organ (chocolates, simple items such as tofu, magical sausages,
//     Ancestral Recall) -- by then you have ground more sausages and built
//     more sweat
//   3 end of day, wearing organ gear / Stooper (and after Sweat Out Some
//     Booze): the units that need the extra space, plus Three Sheets to the
//     Wind (its rollover bonus is lost if you adventure after it)
//   4 overdrink: one drink, picked by smmDietChooseLate (the optimizer plans none)
// Phases 1-2 are adventured today; phases 3-4 roll over.

record DietPlan {
	DietRow [int] rows;
	DietRow [int] overdrinks;
	int [int, int] parts;    // parts[row, phase]: units of the row in each phase 1-4
	float [int] adv;         // adventures of each phase 1-4
	boolean roomUnlimited;
	float room;
	int roll;                // the first phase that rolls over (3, or 1 at finish)
	float value;
	int [string] dropped;
	boolean hasOverdrink;
	DietRow overdrink;
	int overflow;
	float late;
	float spread;
	int stopAt;
	boolean trimmed;
	float base;
	int held;
};

DietSpec smmDietRowSpec(DietRow row) { return dtoSpecs[row.spec]; }

// Organ use of one unit of a plan row.
int [int] smmDietUnitSize(DietRow row) {
	DietSpec spec = smmDietRowSpec(row);
	if (!spec.hasSize) return dtoSize(0, 0, 0);
	int [int] s = dtoCopySize(spec.size);
	if (row.mime) s[1] = max(0, s[1] - 1);
	return s;
}

boolean smmDietAnyNegative(int [int] s) { return s[0] < 0 || s[1] < 0 || s[2] < 0; }
boolean smmDietAnyPositive(int [int] s) { return s[0] > 0 || s[1] > 0 || s[2] > 0; }

// Turn generation that uses no organ: phase 2. Milk of magnesium boosts the
// food eaten after it, so it stays with the food.
boolean smmDietIsTurngen(DietRow row) {
	int [int] s = smmDietUnitSize(row);
	DietItem it = smmDietRowSpec(row).item;
	if (s[0] != 0 || s[1] != 0 || s[2] != 0 || row.isNightcap || row.name == "milk of magnesium") return false;
	return it.type == "simple" || smmDietIsChocolate(row.name) || row.name == "Ancestral Recall";
}

record SmmDietUnit {
	int row;
	int [int] size;
};

// Smallest subset of units whose organ-o sizes add up to at least need
// (fewest units on a tie); all of them if no subset reaches it.
int [int] smmDietSmallestCover(SmmDietUnit [int] units, int o, int need) {
	int [int, int] best;        // sum -> unit numbers
	boolean [int] reached;
	int [int] sums;             // reached sums in the order first reached
	reached[0] = true;
	sums[0] = 0;
	foreach u, unit in units {
		int sz = unit.size[o];
		int [int] before;  // ascending, as the reached sums were listed
		foreach i, x in sums before[i] = x;
		sort before by value;
		foreach i, x in before {
			if (x >= need) continue;
			int t = x + sz;
			int pickLen = count(best[x]) + 1;
			if (!(reached contains t) || count(best[t]) > pickLen) {
				int [int] pick;
				foreach k, v in best[x] pick[k] = v;
				pick[count(pick)] = u;
				remove best[t];
				foreach k, v in pick best[t, k] = v;
				if (!(reached contains t)) sums[count(sums)] = t;
				reached[t] = true;
			}
		}
	}
	int found = -1;
	foreach i, x in sums if (x >= need && (found < 0 || x < found)) found = x;
	int [int] result;
	if (found < 0) {
		foreach u in units result[count(result)] = u;
		return result;
	}
	foreach k, v in best[found] result[count(result)] = v;
	return result;
}

// Units of each plan row per phase: parts[i, ph] for phases 1-4.
int [int, int] smmDietSplitPhases(DietRow [int] rows, DietSettings settings) {
	int [int] room = dtoCopySize(settings.base);
	int [int] used = dtoSize(0, 0, 0);
	SmmDietUnit [int] movable;
	int [int, int] parts;
	foreach i, r in rows {
		int [int] s = smmDietUnitSize(r);
		DietSpec spec = smmDietRowSpec(r);
		for (int ph = 1; ph <= kSmmDietLastPhase; ph++) parts[i, ph] = 0;
		if (r.isNightcap) { parts[i, 4] = r.amount; continue; }
		if (spec.item.bonusadv != 0) { parts[i, 3] = r.amount; continue; }
		if (smmDietIsTurngen(r)) { parts[i, 2] = r.amount; continue; }
		parts[i, 1] = r.amount;
		for (int o = 0; o < 3; o++) {
			if (s[o] > 0) used[o] += s[o] * r.amount;
			else room[o] -= s[o] * r.amount;  // cleaning frees space for phase 1
		}
		// Lucky! (fortune drinks, clovermint) is only worth something while
		// you can still adventure, and cleaners belong to phase 1.
		boolean canMove = smmDietAnyPositive(s) && !smmDietAnyNegative(s) && !spec.opts["fortune"] && spec.item.bonusvalue == 0;
		if (canMove) for (int k = 0; k < r.amount; k++) {
			SmmDietUnit u = new SmmDietUnit();
			u.row = i;
			u.size = s;
			movable[count(movable)] = u;
		}
	}
	for (int org = 0; org < 3; org++) {
		int need = used[org] - room[org];
		if (need <= 0) continue;
		SmmDietUnit [int] candidates;
		int [int] candidateIndex;  // candidate -> movable key
		foreach m, u in movable if (u.size[org] > 0) {
			candidateIndex[count(candidates)] = m;
			candidates[count(candidates)] = u;
		}
		foreach p, c in smmDietSmallestCover(candidates, org, need) {
			SmmDietUnit u = candidates[c];
			parts[u.row, 1] -= 1;
			parts[u.row, 3] += 1;
			for (int q = 0; q < 3; q++) used[q] -= u.size[q];
			remove movable[candidateIndex[c]];
		}
	}
	return parts;
}

// Adventures rollover will add, with the best adventure gear on (smmUtils).
int smmDietRolloverGain(string [string] opts) {
	if (opts contains "rollover") return smmDietInt(opts["rollover"]);
	return adventureGainAtRollover(true);
}

// Adventures good_night_adv will spend after the overdrink, while overdrunk (smmUtils).
int smmDietOverdrunkTurns(string [string] opts) {
	if (opts contains "overdrunk") return max(0, smmDietInt(opts["overdrunk"]));
	return max(0, goodNightAdvTurns(false));
}

// The best way to spend any number of adventures while overdrunk (smmUtils'
// overdrunkSinks: trick-or-treating on Hallowe'en, garbo with Drunkula's
// wineglass, the Beach Comb). With one, the nightcap is only trimmed where
// its adventures are worth less spent that way than the consumable costs.
// Option sinkvalue=N overrides the value (0: plan with no sink).
void smmDietOverdrunkSink(string [string] opts, DietSettings s) {
	s.hasSink = false;
	foreach i, sink in overdrunkSinks() {
		if (sink.value <= 0) continue;
		s.hasSink = true;
		s.sinkName = sink.name;
		s.sinkValue = sink.value;
		break;
	}
	if (opts contains "sinkvalue") {
		int v = smmDietInt(opts["sinkvalue"]);
		if (v > 0) {
			if (!s.hasSink) s.sinkName = "overdrunk adventures";
			s.hasSink = true;
			s.sinkValue = v;
		} else {
			s.hasSink = false;
		}
	}
}

// Adventures each phase actually gives (the nightcap's uncapped).
float [int] smmDietPhaseAdventures(DietRow [int] rows, int [int, int] parts) {
	float [int] adv;
	for (int ph = 1; ph <= kSmmDietLastPhase; ph++) adv[ph] = 0;
	foreach i, r in rows {
		float per = r.isNightcap ? smmDietRowSpec(r).adv : r.turns / r.amount;
		for (int ph = 1; ph <= kSmmDietLastPhase; ph++) adv[ph] += per * parts[i, ph];
	}
	return adv;
}

// Adventures of phases from..4.
float smmDietAdvFrom(float [int] adv, int first) {
	float total = 0;
	for (int ph = first; ph <= kSmmDietLastPhase; ph++) total += adv[ph];
	return total;
}

// How far one unit's adventures can roll above the plan's (average) figure.
float smmDietHalfRange(DietRow row) {
	DietSpec spec = smmDietRowSpec(row);
	// the same helper, skill and equipment transformations as the average
	if (spec.hasAdvmax) return max(0.0, spec.advmax - spec.adv);
	return spec.item.advmax > spec.item.advmin ? (spec.item.advmax - spec.item.advmin) / 2 : 0.0;
}

int smmDietUnits(DietPlan plan, int r, int first) {
	int n = 0;
	for (int ph = first; ph <= kSmmDietLastPhase; ph++) n += plan.parts[r, ph];
	return n;
}

// After trimming, an organ-space extender (mojo filter, spice melange, ...)
// may free space nothing uses any more: don't buy it.
void smmDietDropIdleExtenders(DietPlan plan, DietSettings settings) {
	int [int] sizeNow = settings.organs;
	int [int] used = dtoSize(0, 0, 0);
	int [int] freed = dtoSize(0, 0, 0);
	int [int] ext;
	foreach i, r in plan.rows {
		int [int] s = r.isNightcap ? dtoSize(0, 0, 0) : smmDietUnitSize(r);
		int n = smmDietUnits(plan, i, 1);
		for (int o = 0; o < 3; o++) {
			if (s[o] > 0) used[o] += s[o] * n;
			else freed[o] -= s[o] * n;
		}
		if (smmDietRowSpec(r).item.type == "extender") ext[count(ext)] = i;
	}
	foreach e, r in ext {
		int [int] es = smmDietUnitSize(plan.rows[r]);
		for (int ph = plan.roll; ph <= kSmmDietLastPhase; ph++) {
			while (plan.parts[r, ph] > 0) {
				boolean idle = true;
				for (int o = 0; o < 3; o++) if (es[o] < 0 && used[o] > sizeNow[o] + freed[o] + es[o]) idle = false;
				if (!idle) break;
				plan.parts[r, ph] -= 1;
				for (int o = 0; o < 3; o++) if (es[o] < 0) freed[o] += es[o];
				plan.value -= plan.rows[r].value / plan.rows[r].amount;
				plan.dropped[plan.rows[r].name] += 1;
			}
		}
	}
}

record SmmDietLateUnit {
	int row;
	int phase;
	int adv;
	float value;
	float score;
};

record SmmDietKnap {
	float score;
	int [int] take;
};

// Phase 4 is a single overdrink, chosen together with the units finish
// consumes (phases 3-4; at finish also phase 1-2 leftovers) so that their
// adventures fit in plan.room: a small knapsack over those units, tried with
// each overdrink. Without an overdrunk sink nothing may pass the room. With
// one, adventures past it are allowed, each worth the sink's value instead of
// an adventure's (plan.overflow: how many good_night_adv must spend that
// way). Every unit is fitted at the top of its adventure range. Units that
// clean an organ are always kept (others rely on the space they free). Ties
// go to more adventures, to end the day closer to the cap. With unlimited
// room nothing is dropped and the overdrink worth most is picked.
void smmDietChooseLate(DietPlan plan, DietSettings settings) {
	clear(plan.dropped);
	plan.hasOverdrink = false;
	float eps = kDietEpsilon;
	SmmDietLateUnit [int] units;
	float fixed = 0;
	boolean unlimited = plan.roomUnlimited;
	foreach i, r in plan.rows {
		if (r.isNightcap) continue;  // the optimizer plans none; never trim one
		float a = r.turns / r.amount;
		float top = a + smmDietHalfRange(r);
		boolean cleans = smmDietAnyNegative(smmDietUnitSize(r));
		for (int ph = plan.roll; ph <= kSmmDietLastPhase; ph++) {
			for (int k = 0; k < plan.parts[i, ph]; k++) {
				if (unlimited || cleans) { fixed += top; continue; }
				SmmDietLateUnit u = new SmmDietLateUnit();
				u.row = i;
				u.phase = ph;
				u.adv = ceil(top - eps);
				u.value = r.value / r.amount;
				u.score = max(u.value, 0.0) + (a + 1) * eps;  // keep 0-value units when they fit
				units[count(units)] = u;
			}
		}
	}

	int [string] used;  // copies of each item the plan already uses
	foreach r, row in plan.rows used[row.name] += smmDietUnits(plan, r, 1);
	DietRow [int] drinks;
	foreach i, od in plan.overdrinks {
		int lim = smmDietRowSpec(od).item.limit;
		if (lim != 0 && used[od.name] >= lim) continue;
		if (od.value <= eps) continue;
		drinks[count(drinks)] = od;
	}

	float pickScore = 0;
	int [int] pickTake;
	boolean pickHasDrink = false;
	DietRow pickDrink;
	int pickOver = 0;
	plan.overflow = 0;  // adventures past the room, spent overdrunk on the sink
	if (unlimited) {
		foreach d, od in drinks {
			float sc = od.value + od.turns * eps;
			if (sc > pickScore + eps * eps) {
				pickScore = sc;
				pickHasDrink = true;
				pickDrink = od;
			}
		}
	} else {
		int avail = max(0, floor(plan.room - fixed + eps));
		// Adventures past the room: spent overdrunk on the best sink (each then
		// worth its value instead of an adventure), or not allowed without one.
		boolean sink = settings.hasSink;
		float penalty = sink ? max(0.0, settings.advValue - settings.sinkValue) : 0;
		int capacity = avail;
		if (sink) foreach u, unit in units capacity += unit.adv;
		// best[c]: the units worth most using at most c adventures
		float [int] bestScore;
		int [int, int] bestTake;
		for (int c = 0; c <= capacity; c++) bestScore[c] = 0;
		foreach u, unit in units {
			for (int c = capacity; c >= unit.adv; c--) {
				float cand = bestScore[c - unit.adv] + unit.score;
				if (cand > bestScore[c] + eps * eps) {
					int [int] take;
					foreach k, v in bestTake[c - unit.adv] take[k] = v;
					take[count(take)] = u;
					bestScore[c] = cand;
					remove bestTake[c];
					foreach k, v in take bestTake[c, k] = v;
				}
			}
		}
		pickScore = -kSmmDietHuge;
		for (int c = 0; c <= capacity; c++) {
			for (int op = -1; op < count(drinks); op++) {
				int need = 0;
				float value = 0;
				if (op >= 0) {
					need = ceil(drinks[op].turns + smmDietHalfRange(drinks[op]) - eps);
					value = drinks[op].value + drinks[op].turns * eps;
				}
				int over = max(0, c + need - avail);
				if (over > 0 && !sink) continue;  // its adventures would pass the cap
				float score = bestScore[c] + value - (over > 0 ? over * penalty : 0);
				if (score > pickScore + eps * eps) {
					pickScore = score;
					clear(pickTake);
					foreach k, v in bestTake[c] pickTake[k] = v;
					pickHasDrink = op >= 0;
					if (op >= 0) pickDrink = drinks[op];
					pickOver = over;
				}
			}
		}
		plan.overflow = pickOver;
	}

	boolean [int] keep;
	foreach k, u in pickTake keep[u] = true;
	foreach x, un in units {
		if (keep contains x) continue;
		DietRow row = plan.rows[un.row];
		plan.parts[un.row, un.phase] -= 1;
		plan.adv[un.phase] -= row.turns / row.amount;
		plan.value -= un.value;
		plan.dropped[row.name] += 1;
	}
	if (pickHasDrink) {
		int n = count(plan.rows);
		plan.rows[n] = pickDrink;
		for (int ph = 1; ph <= kSmmDietLastPhase; ph++) plan.parts[n, ph] = 0;
		plan.parts[n, 4] = 1;
		plan.adv[kSmmDietLastPhase] += pickDrink.turns;
		plan.value += pickDrink.value;
		plan.hasOverdrink = true;
		plan.overdrink = pickDrink;
	}
	if (!unlimited) smmDietDropIdleExtenders(plan, settings);
}

// Phases split and nightcap chosen for room adventures at finish
// (unlimited: nothing trimmed). plan.late: the adventures finish adds.
DietPlan smmDietLatePlan(DietResult result, DietSettings settings, boolean finish, boolean unlimited, float room) {
	DietPlan plan = new DietPlan();
	foreach i, r in result.rows plan.rows[i] = r;
	foreach i, r in result.overdrinks plan.overdrinks[i] = r;
	plan.parts = smmDietSplitPhases(plan.rows, settings);
	plan.adv = smmDietPhaseAdventures(plan.rows, plan.parts);
	plan.roomUnlimited = unlimited;
	plan.room = room;
	plan.roll = finish ? 1 : 3;
	plan.value = 0;
	foreach i, r in plan.rows plan.value += r.value;
	smmDietChooseLate(plan, settings);
	plan.late = smmDietAdvFrom(plan.adv, plan.roll);
	// how far above the average (the plan's figure) finish's adventures can roll
	plan.spread = 0;
	foreach r, row in plan.rows plan.spread += smmDietUnits(plan, r, plan.roll) * smmDietHalfRange(row);
	return plan;
}

// Plan the day around the rollover cap. Everything consumed at finish (phases
// 3-4, plus at finish any phase 1-2 leftovers) rolls over with the adventures
// you still hold, less what good_night_adv spends overdrunk, plus what
// rollover adds. Nothing of that may pass the cap, so:
//   stop point = cap - rollover gain + overdrunk turns - finish's adventures
// for the full nightcap (organs filled to the gear's capacity, the best
// overdrink). Finish runs only with at most that many adventures held. When
// the stop point is below 0 -- the nightcap alone passes the cap even with no
// adventures held -- it is 0 and smmDietChooseLate trims the nightcap to what
// fits. No plan loses an adventure at rollover.
DietPlan smmDietPlanDay(DietSettings settings, boolean finish) {
	DietResult result = smmDietOptimize(settings);
	float base = kSmmDietCap - settings.rolloverGain + settings.overdrunkTurns;
	DietPlan plan = smmDietLatePlan(result, settings, finish, true, 0);
	// plan for every consumable rolling the top of its adventure range
	plan.stopAt = floor(base - plan.late - plan.spread + kDietEpsilon);
	plan.trimmed = plan.stopAt < 0;
	if (plan.trimmed) {
		plan = smmDietLatePlan(result, settings, finish, false, base);  // as if you hold no adventures
		plan.stopAt = 0;
		plan.trimmed = true;
	}
	plan.base = base;
	plan.held = finish ? my_adventures() : 0;
	return plan;
}

// ---------------------------------------------------------------------------
// The budget

// The item a plan row uses up, when that is not the row's own name.
string smmDietRowItem(string name) { return name == "Ancestral Recall" ? "blue mana" : name; }  // one per cast

// How many of each item a plan uses over the whole day: consumables, the
// helpers consumed with them, the mana behind Ancestral Recall, and one
// pocket wish for each effect the plan wishes for (a wish lasts for all the
// drinks it helps).
int [string] smmDietPlanUnits(DietPlan plan) {
	int [string] units;
	boolean [string] wished;
	int wishes = 0;
	foreach i, row in plan.rows {
		int n = smmDietUnits(plan, i, 1);
		if (n == 0) continue;
		units[smmDietRowItem(row.name)] += n;
		foreach j, note in row.notes {
			if (note.type == "item" && note.exclude) units[note.itemName] += n;
			if (note.type == "effect" && note.verb == "wish for" && !(wished contains note.effect)) {
				wished[note.effect] = true;
				wishes += 1;
			}
		}
	}
	if (wishes > units["pocket wish"]) units["pocket wish"] = wishes;
	return units;
}

// Meat one unit of an entry costs in cash even though nothing is bought in a
// store: a speakeasy drink, or a sausage ground from casings (the entry's
// price is the grinder's cost averaged over the day's sausages).
float smmDietCashPrice(DietItem e) {
	if (e.speakeasy > 0) return e.speakeasy;
	if (e.name == "magical sausage") return e.price > 1 ? e.price : 0;
	return 0;
}

// Spare owned copies the diet may use, by item name: smmDietSpareLive in a
// game, or a test's own function (called by name).
int smmDietSpareLive(string name) { return max(0, smmDietSpareCopies(to_item(name))); }

int smmDietSpareOf(string spareFn, string name) { return call int spareFn(name); }

// Meat a plan still has to pay: the copies beyond the spare ones already
// owned, at the planned price, plus what speakeasy drinks and sausage
// grinding cost. Other owned-only entries cost nothing.
float smmDietPlanPurchaseCost(int [string] units, DietItem [int] consumables, string spareFn) {
	float cost = 0;
	foreach c, e in consumables {
		int n = units[e.name];
		if (n == 0) continue;
		if (smmDietCashPrice(e) > 0) cost += n * smmDietCashPrice(e);
		else if (!e.owned && e.price > 0) cost += max(0, n - smmDietSpareOf(spareFn, e.name)) * e.price;
	}
	return cost;
}

// Takes everything that costs Meat off the list: an entry with spare owned
// copies is limited to them, and any other priced entry is removed, as are
// speakeasy drinks and sausages that would have to be ground.
void smmDietRestrictToOwned(DietItem [int] consumables, string spareFn) {
	int [int] keys;
	foreach c in consumables keys[count(keys)] = c;
	for (int k = count(keys) - 1; k >= 0; k--) {
		int c = keys[k];
		DietItem e = consumables[c];
		boolean cash = smmDietCashPrice(e) > 0;
		if (!cash && (e.owned || !(e.price > 0))) continue;
		int spare = e.type != "" && e.speakeasy == 0 ? smmDietSpareOf(spareFn, e.name) : 0;  // helpers are bought or left out
		if (e.free >= 0) spare = e.free;  // sausages: made already, or covered by the grinder's Meat
		if (spare > 0) {
			e.limit = e.limit != 0 ? min(e.limit, spare) : spare;
			e.owned = true;
			if (cash) e.price = 1;
		} else {
			remove consumables[c];
		}
	}
}

// Every purchasable item a plan relies on: the consumables and their helpers,
// the mana behind Ancestral Recall, and the potion or wish behind an effect.
boolean [string] smmDietPlanItemNames(DietPlan plan) {
	boolean [string] names;
	foreach i, row in plan.rows {
		names[smmDietRowItem(row.name)] = true;
		foreach j, note in row.notes {
			if (note.type == "item" && note.exclude) names[note.itemName] = true;
			if (note.type == "effect" && note.effect == "Gar-ish") names["potion of the field gar"] = true;
			if (note.type == "effect" && note.verb == "wish for") names["pocket wish"] = true;
			if (note.type == "effect" && note.effect == "Salty Mouth" && dtoSpecs[row.spec].opts["beer nuts (wish)"]) names["pocket wish"] = true;
		}
	}
	return names;
}

// Re-checks the live mall price of everything the plan buys and applies the
// average-sale-price rule to it. True when anything changed, so that the day
// must be planned again.
boolean smmDietRefreshPlanPrices(DietPlan plan) {
	boolean [string] names = smmDietPlanItemNames(plan);
	boolean changed = false;
	int [int] keys;
	foreach c in dietConsumables keys[count(keys)] = c;
	foreach k, c in keys {
		DietItem e = dietConsumables[c];
		if (!(names contains e.name) || e.speakeasy > 0 || e.owned) continue;
		item it = to_item(e.name);
		SmmDietPrice live = smmDietPriceOf(it, true);
		if (!live.ok) continue;
		if (smmDietAbs(live.price - e.price) > 0.02 * e.price) {
			print("Price of " + e.name + ": " + smmDietFmt(e.price) + " -> " + smmDietFmt(live.price), "gray");
			e.price = live.price;
			changed = true;
		}
		int npc = npc_price(it);
		if (!is_tradeable(it) || live.owned || (npc > 0 && npc <= live.price)) continue;  // not a mall purchase
		float average = smmDietAverageSalePrice(it);
		int spare = e.type != "" ? max(0, smmDietSpareCopies(it)) : 0;  // helpers are bought or left out
		string rule = smmDietAverageRule(live.price, average, spare);
		if (rule == "buy") continue;
		print("Not buying " + e.name + ": the mall's " + smmDietFmt(live.price) + " is above its average sale price of " + smmDietFmt(floor(average))
			+ (rule == "owned" ? "; only the " + spare + " spare owned are used" : ""), "orange");
		if (rule == "owned") {
			e.limit = e.limit != 0 ? min(e.limit, spare) : spare;
			e.price = floor(average);  // what a spare copy could be sold for
			e.owned = true;
		} else {
			remove dietConsumables[c];
		}
		changed = true;
	}
	return changed;
}

boolean smmDietRefresh(string refreshFn, DietPlan plan) { return call boolean refreshFn(plan); }

record SmmDietFit {
	DietPlan plan;
	float toBuy;
	boolean over;
	boolean ownedOnly;
};

// Settles a plan: re-plans while the refresh reports changed prices (refreshFn
// "" for none), and while the plan's purchases cost more than room (the Meat
// left in the diet's budget; kSmmDietHuge for no limit). Over budget, each
// re-plan values an adventure kSmmDietBudgetStep lower, so the purchases that
// return least per Meat go first; settings.advValue is left at the value the
// final plan was made with. When there is no room at all, or the passes run
// out, the plan is made from owned copies only.
SmmDietFit smmDietFitPlan(DietPlan plan, DietSettings settings, boolean finish, float room, string refreshFn, string spareFn) {
	float fullValue = settings.advValue;
	float toBuy = 0;
	boolean ownedOnly = false;
	room = max(0.0, room);
	for (int pass = 0; ; pass++) {
		boolean changed = refreshFn != "" && !ownedOnly ? smmDietRefresh(refreshFn, plan) : false;
		toBuy = smmDietPlanPurchaseCost(smmDietPlanUnits(plan), dietConsumables, spareFn);
		if (!changed && toBuy <= room) break;
		if (pass >= kSmmDietPlanPasses) {
			if (changed) {
				plan = smmDietPlanDay(settings, finish);
				toBuy = smmDietPlanPurchaseCost(smmDietPlanUnits(plan), dietConsumables, spareFn);
			}
			break;
		}
		if (!changed) {
			if (room > 0 && pass < kSmmDietPlanPasses - 1) {
				settings.advValue *= kSmmDietBudgetStep;
			} else {
				smmDietRestrictToOwned(dietConsumables, spareFn);
				settings.advValue = fullValue;
				ownedOnly = true;
			}
		}
		plan = smmDietPlanDay(settings, finish);
	}
	SmmDietFit fit = new SmmDietFit();
	fit.plan = plan;
	fit.toBuy = toBuy;
	fit.over = toBuy > room;
	fit.ownedOnly = ownedOnly;
	return fit;
}

// ---------------------------------------------------------------------------
// Printing

string smmDietNoteText(DietNote n) {
	if (n.type == "text") return n.text;
	if (n.type == "effect") return n.verb + " " + n.effect;
	return n.verb + " " + n.itemName;
}

string smmDietGearDescription(DietSettings settings) {
	string names = "";
	foreach i, g in settings.gear names += (names == "" ? "" : ", ") + g.name;
	if (settings.stooper) names += (names == "" ? "" : ", ") + "Stooper (familiar)";
	return names;
}

string smmDietPhaseTitle(int ph, DietSettings settings) {
	switch (ph) {
	case 1: return "Phase 1 -- now (execute): food, booze and spleen, with the cleaners; then adventure until these are spent";
	case 2: return "Phase 2 -- then (turngen): other turn generation; then adventure until these are spent";
	case 3:
		string gear = smmDietGearDescription(settings);
		return "Phase 3 -- end of day (finish): " + (gear != "" ? "wear " + gear + ", fill every organ to the new capacity (never over)" : "fill every organ (never over)");
	}
	return "Phase 4 -- overdrink one drink, the one worth most that fits under the cap; then take the organ gear off";
}

// The rollover budget and the stop point: how many adventures to stop at.
void smmDietPrintStopPoint(DietPlan plan, DietSettings settings, boolean finish) {
	int late = round(plan.late);
	int over = settings.overdrunkTurns;
	int top = floor(plan.late + plan.spread + kDietEpsilon);
	print("Rollover: about " + settings.rolloverGain + " (best adventure gear) + " + late + (top > late ? " (at most " + top + ")" : "")
		+ (finish ? " from the rest of the diet" : " from phases 3-4") + " + the adventures you hold at finish - "
		+ over + " good_night_adv spends overdrunk; at most " + kSmmDietCap + ".", "gray");
	string at = finish ? " You hold " + plan.held + "." : "";
	if (plan.trimmed && plan.overflow > 0)
		print("Stop point: 0 adventures -- the whole nightcap passes " + kSmmDietCap + " even with none held, so spend them all; about "
			+ plan.overflow + " adventures past it go to " + settings.sinkName + " overdrunk (" + smmDietFmt(settings.sinkValue)
			+ " meat each; good_night_adv)." + at, "blue");
	else if (plan.trimmed)
		print("Stop point: 0 adventures -- the whole nightcap passes " + kSmmDietCap + " even with none held, so spend them all and finish with what fits (above)"
			+ (settings.hasSink ? "; spending more on " + settings.sinkName + " overdrunk (" + smmDietFmt(settings.sinkValue) + " meat each) isn't worth the rest."
				: "; nothing to spend more on overdrunk.") + at, "blue");
	else
		print("Stop point: stop adventuring with " + plan.stopAt + " adventures left, then " + (finish ? "finish" : "run: call diet.ash finish")
			+ "; good_night_adv then spends " + over + " of them overdrunk." + at, "blue");
}

// Flag Sweat Out Some Booze: what finish will cast, or why it isn't counted.
void smmDietPrintSweatFlag(DietSettings s, boolean finish) {
	if (!s.sweatHave || s.sweatLeft == 0) return;
	int casts = s.sweatCasts;
	if (casts > 0) {
		print("Sweat Out Some Booze: casting it " + casts + "x first (" + (casts * kSmmDietSweatPerCast) + " of " + s.sweatAmount
			+ " sweat) for " + casts + " more drunkenness (counted above).", "blue");
		if (s.sweatLeft > casts) print("  " + (s.sweatLeft - casts) + " more casts left today.", "gray");
		return;
	}
	string why;
	if (!finish) why = "not counted; it is cast by the last run of the day (call diet.ash finish)";
	else if (s.sweatReady == 0) why = "not enough sweat (" + s.sweatAmount + " of " + kSmmDietSweatPerCast + " per cast)";
	else if (my_inebriety() == 0) why = "no drunkenness to sweat out yet";
	else why = "you would still be over your liver limit";
	print("Sweat Out Some Booze: " + s.sweatLeft + " casts left today, " + s.sweatAmount + " sweat (" + kSmmDietSweatPerCast + " per cast) -- " + why + ".", "orange");
}

void smmDietPrintPlan(DietPlan plan, DietSettings settings, boolean finish) {
	int [int] o = settings.organs;
	int [int] base = settings.base;
	print("Whole-day diet for " + o[0] + " fullness, " + o[1] + " drunkenness, " + o[2] + " spleen (" + base[0] + "/" + base[1] + "/" + base[2]
		+ " without organ gear) at " + smmDietFmt(settings.advValue) + " meat/adventure", "blue");
	float totalTurns = 0;
	float cost = 0;
	float pvp = 0;
	float effects = 0;
	float [int] phaseTurns;
	for (int ph = 1; ph <= kSmmDietLastPhase; ph++) {
		string [int] lines;
		phaseTurns[ph] = 0;
		foreach i, r in plan.rows {
			int n = plan.parts[i, ph];
			if (n == 0) continue;
			string notes = "";
			foreach j, note in r.notes notes += (notes == "" ? "" : "; ") + smmDietNoteText(note);
			if (r.specialprice != "") notes += (notes == "" ? "" : "; ") + r.specialprice;
			DietItem it = smmDietRowSpec(r).item;
			if (it.effectName != "") {
				notes += (notes == "" ? "" : "; ") + smmDietFmt(it.effectTurns * n) + " adv of " + it.effectName + " worth " + smmDietFmt(it.effectValue * n) + " meat";
				effects += it.effectValue * n;
			}
			float turns = r.turns * n / r.amount;
			lines[count(lines)] = n + "x " + r.name + " -- " + smmDietFmt(turns) + " adv, " + smmDietFmt(r.price * n / r.amount) + " meat" + (notes != "" ? " (" + notes + ")" : "");
			phaseTurns[ph] += turns;
		}
		if (count(lines) == 0) continue;
		print(smmDietPhaseTitle(ph, settings) + " (" + smmDietFmt(phaseTurns[ph]) + " adv):", "blue");
		foreach l, line in lines print("  " + line);
	}
	foreach j, r in plan.rows {
		int units = smmDietUnits(plan, j, 1);
		totalTurns += r.turns * units / r.amount;
		cost += r.price * units / r.amount;
		pvp += to_float(r.fights) * units / r.amount;
	}
	foreach name, n in plan.dropped
		if (n > 0) print("Leaving out " + n + "x " + name + ": the nightcap is trimmed to fit under " + kSmmDietCap + " at rollover.", "gray");
	if (!plan.hasOverdrink && settings.overdrinkCandidates)
		print("No overdrink: no single drink worth its price fits under " + kSmmDietCap + " at rollover.", "orange");
	print("Total: " + smmDietFmt(totalTurns) + " adventures" + (pvp != 0 ? " + " + smmDietFmt(pvp) + " PvP fights" : "") + " for " + smmDietFmt(cost)
		+ " meat; net value " + smmDietFmt(plan.value) + " meat" + (effects != 0 ? " (" + smmDietFmt(effects) + " of it from effects)" : ""), "green");
	if (finish) print("Everything left is consumed now, so all " + smmDietFmt(totalTurns) + " roll over to tomorrow.", "green");
	else print(smmDietFmt(phaseTurns[1] + phaseTurns[2]) + " adventures from phases 1-2 to use today; " + smmDietFmt(phaseTurns[3] + phaseTurns[4])
		+ " from phases 3-4 roll over to tomorrow.", "green");
	smmDietPrintStopPoint(plan, settings, finish);
	if (o[1] > 0) print(settings.ode ? "Booze adventures assume Ode to Booze is active." : "Booze adventures leave out Ode to Booze: you don't have the skill.", "gray");
	smmDietPrintSweatFlag(settings, finish);
}

// ---------------------------------------------------------------------------
// Execution: buys and consumes a plan in a safe order.

float smmDietBudgetRoom = kSmmDietHuge;  // set by smmDietMain before a plan is carried out
int smmDietMeatAtStart;
boolean smmDietAutoYes;

// The Meat an execution may still pay: what was left of the budget when it
// started, less what it has paid since.
float smmDietBudgetLeftNow() {
	return smmDietBudgetRoom >= kSmmDietHuge ? kSmmDietHuge : smmDietBudgetRoom - (smmDietMeatAtStart - my_meat());
}

void smmDietNoteSpend(string key, int paid) {
	if (paid > 0) set_property(key, to_string(smmDietPrefInt(key) + paid));
}

// helpers used right before the item they boost
boolean [string] smmDietUseBefore = $strings[Ol' Scratch's salad fork, fudge spork, Frosty's frosty mug, BGE shotglass, munchies pill, dieting pill, Mayoflex, Mayodiol];

float smmDietPlannedPrice(string name) {
	foreach c, e in dietConsumables if (e.name == name) return e.price;
	return 0;
}

// Meat that fetching missing more copies outside the mall will cost, where it
// can be known: a store's price, the sausage grinder's, the Mayo Clinic's.
// Anything else there is made from what is owned, which costs nothing.
float smmDietFallbackCost(string name, int missing, int npc) {
	if (npc > 0) return npc * missing;
	if (name == "magical sausage") return smmDietSausageCost(missing, smmDietPrefInt("_sausagesMade"), smmDietPrefInt("sausageGrinderUnits"));
	if (name == "Mayoflex" || name == "Mayodiol") return smmDietPlannedPrice(name) * missing;
	return 0;
}

// Make sure n of an item are in inventory, buying at most the slack over plan.
boolean smmDietAcquire(string name, int n) {
	item it = to_item(name);
	n += smmDietReservedCopies(it);  // Museum copies stay; eat spare or freshly bought ones
	int have = available_amount(it);
	if (have >= n) {
		boolean got = retrieve_item(n, it);
		return got;
	}
	if (it == $item[Cold One] || it == $item[spaghetti breakfast]) {
		boolean cast = use_skill(1, it == $item[Cold One] ? $skill[Grab a Cold One] : $skill[Spaghetti Breakfast]);
		return available_amount(it) >= n;
	}
	int npc = npc_price(it);
	if (is_tradeable(it) && can_interact()) {
		// never above the average sale price, whatever the plan says
		float planned = smmDietPlannedPrice(name);
		int cap = smmDietBuyCap(planned, npc > 0 && npc <= planned ? 0 : smmDietAverageSalePrice(it), smmDietBudgetLeftNow(), n - have);
		int meatBefore = my_meat();
		if (cap > 0) {
			int bought = buy(n - have, it, cap);
		} else if (planned > 0) {
			print("Not buying " + name + ": the diet's budget for today has " + smmDietFmt(max(0.0, smmDietBudgetLeftNow())) + " meat left.", "orange");
		}
		smmDietNoteSpend("_smm.diet.bought", meatBefore - my_meat());
	}
	int missing = n - available_amount(it);
	if (missing > 0 && smmDietCanAfford(smmDietFallbackCost(name, missing, npc), smmDietBudgetLeftNow())) {
		// NPC stores, Mayo Clinic, crafting. Not the mall: KoLmafia's own mall
		// buying (autoSatisfyWithMall) knows neither cap.
		boolean mallOn = smmDietPrefBool("autoSatisfyWithMall");
		int meatThen = my_meat();
		if (mallOn) set_property("autoSatisfyWithMall", "false");
		try {
			boolean got = retrieve_item(n, it);
		} finally {
			if (mallOn) set_property("autoSatisfyWithMall", "true");
		}
		if (npc > 0) smmDietNoteSpend("_smm.diet.bought", meatThen - my_meat());  // a store purchase is in the session log too
	}
	return available_amount(it) >= n;
}

// The order units are consumed in, by kind.
float smmDietOrderOf(DietRow row) {
	DietSpec spec = smmDietRowSpec(row);
	string type = spec.item.type;
	if (row.name == "milk of magnesium") return 0;
	if (type == "extender") return -1;                                            // used on demand
	if (spec.opts["wish_refined_palate"] || spec.opts["wish_salty_mouth"]) return -1;  // wished on demand
	if (row.name == "potion of the field gar") return -1;                         // used on demand
	if (type == "simple" || smmDietIsChocolate(row.name) || row.name == "Ancestral Recall") return 1;
	if (row.name == "spaghetti breakfast") return 2;
	if (type == "food") return 3;
	if (type == "spleen") return 4;
	if (type == "booze" && !row.isNightcap) return row.mime ? 4.5 : 5;  // the shotglass takes the first 1-drunkenness drink
	if (row.name == "temporary X tattoos") return 6;
	if (row.isNightcap) return 7;
	return 1;
}

int [int] smmDietOrganState() { return dtoSize(my_fullness(), my_inebriety(), my_spleen_use()); }
int [int] smmDietOrganLimitsNow() { return dtoSize(fullness_limit(), inebriety_limit(), spleen_limit()); }

record SmmDietStep {
	DietRow row;
	float order;
	int stage;
	int seq;
};

// Which organ (0-2) this unit would overflow right now, or -1 if it fits.
int smmDietBlockingOrgan(SmmDietStep step) {
	DietSpec spec = smmDietRowSpec(step.row);
	if (!spec.hasSize || step.row.isNightcap) return -1;
	int [int] cur = smmDietOrganState();
	int [int] lim = smmDietOrganLimitsNow();
	int [int] add = smmDietUnitSize(step.row);
	for (int o = 0; o < 3; o++) if (add[o] > 0 && cur[o] + add[o] > lim[o]) return o;
	return -1;
}

// Pocket wishes the plan budgeted, per effect. The optimizer prices one wish
// per drink, but one wish lasts for all of them, so most of these go unused.
int [string] smmDietWishBudget;

boolean smmDietEnsureEffect(string effectName) {
	effect eff = to_effect(effectName);
	if (have_effect(eff) > 0) return true;
	if (effectName == "Gar-ish") {
		if (!smmDietAcquire("potion of the field gar", 1)) return false;
		boolean used = use(1, $item[potion of the field gar]);
	} else if (smmDietWishBudget[effectName] > 0) {
		if (!smmDietAcquire("pocket wish", 1)) return false;
		boolean wished = cli_execute("genie effect " + effectName);
		smmDietWishBudget[effectName] -= 1;
	}
	return have_effect(eff) > 0;
}

string smmDietConsumeUnit(SmmDietStep step, string [int] log) {
	DietRow row = step.row;
	DietSpec spec = smmDietRowSpec(row);
	string name = row.name;
	foreach i, n in row.notes {
		if (n.type == "effect") {
			if (!smmDietEnsureEffect(n.effect)) log[count(log)] = "warning: no " + n.effect + " for " + name + " (fewer adventures)";
		} else if (n.type == "item" && n.verb == "wearing") {
			item gear = to_item(n.itemName);
			if (!have_equipped(gear)) {
				// the pinky ring goes in the accessory slot the capacity gear left free
				boolean worn = gear == $item[mafia pinky ring] ? equip(smmDietRingSlot(), gear) : equip(gear);
			}
		} else if (n.type == "item" && n.exclude) {
			if (!smmDietAcquire(n.itemName, 1)) return "cannot get " + n.itemName;
			if (smmDietUseBefore contains n.itemName) {
				boolean used = use(1, to_item(n.itemName));
				if (!used) return "helper failed: " + n.itemName;
			}
		}
	}

	if (name == "Ancestral Recall") {
		if (!smmDietAcquire("blue mana", 1)) return "cannot get blue mana";
		boolean cast = use_skill(1, $skill[Ancestral Recall]);
		return cast ? "" : "Ancestral Recall failed";
	}
	item it = to_item(name);
	if (spec.item.speakeasy > 0) {
		if (!smmDietCanAfford(spec.item.speakeasy, smmDietBudgetLeftNow())) return "no Meat left in the diet's budget for " + name;
		boolean drunk = cli_execute("drinksilent 1 [" + to_int(it) + "]");
		return drunk ? "" : "speakeasy drink failed";
	}
	if (!smmDietAcquire(name, 1)) return "cannot get " + name;
	string type = spec.item.type;
	boolean ok;
	if (row.isNightcap) ok = overdrink(1, it);
	else if (type == "food") ok = eatsilent(1, it);
	else if (type == "booze") ok = drinksilent(1, it);
	else if (type == "spleen") ok = chew(1, it);
	else if (spec.item.eat) ok = eatsilent(1, it);  // magical sausage: food with no fullness
	else ok = use(1, it);
	return ok ? "" : "consuming " + name + " failed";
}

// True if cleaning by size now would be partly wasted (organ not used enough).
boolean smmDietWastesCleaning(int [int] size, int skipOrgan) {
	int [int] cur = smmDietOrganState();
	for (int o = 0; o < 3; o++) if (o != skipOrgan && size[o] < 0 && cur[o] < -size[o]) return true;
	return false;
}

record SmmDietExtender {
	DietRow row;
	int left;
};

int smmDietOrgansTouched(int [int] s) {
	int n = 0;
	for (int o = 0; o < 3; o++) if (s[o] < 0) n += 1;
	return n;
}

// Use one extender that frees space in the given organ. Single-organ ones go
// first, so two-organ ones (spice melange) aren't spent while the other organ
// is still empty.
boolean smmDietUseExtenderFor(int organ, SmmDietExtender [int] extenders, boolean allowWaste) {
	for (int touched = 1; touched <= 3; touched++) {
		foreach i, e in extenders {
			int [int] s = smmDietRowSpec(e.row).size;
			if (e.left <= 0 || s[organ] >= 0 || smmDietOrgansTouched(s) != touched) continue;
			if (!allowWaste && smmDietWastesCleaning(s, organ)) continue;
			if (!smmDietAcquire(e.row.name, 1)) return false;
			boolean used = use(1, to_item(e.row.name));
			if (!used) return false;
			e.left -= 1;
			return true;
		}
	}
	return false;
}

// Cast enough Ode to Booze for the booze among these steps.
void smmDietCastOde(SmmDietStep [int] steps) {
	int drunk = 0;
	foreach i, st in steps {
		DietSpec spec = smmDietRowSpec(st.row);
		if (spec.item.type == "booze" && spec.hasSize) drunk += max(0, spec.size[1]);
	}
	if (drunk == 0) return;
	if (!have_skill($skill[The Ode to Booze])) {
		print("You don't have The Ode to Booze; booze will give about " + drunk + " fewer adventures.", "orange");
		return;
	}
	for (int tries = 0; tries < 6 && have_effect($effect[Ode to Booze]) < drunk; tries++) {
		boolean cast = use_skill(1, $skill[The Ode to Booze]);
		if (!cast) break;
	}
	if (have_effect($effect[Ode to Booze]) < drunk)
		print("Only " + have_effect($effect[Ode to Booze]) + " turns of Ode to Booze for " + drunk + " drunkenness (song slots full?).", "orange");
}

record SmmDietRun {
	string error;
	SmmDietStep [int] left;
};

void smmDietSortSteps(SmmDietStep [int] steps) {
	sort steps by value.order * 1000000 + value.seq;
}

// Consume steps in a safe order. Multiple passes: units that don't fit yet
// (food waiting on a cleaning booze), and cleaning items whose organ isn't
// full enough yet, are retried later. The overdrink waits until everything
// else is in, so organs are filled to capacity first and only that one drink
// goes over. Waste is allowed only when a pass makes no other progress.
// Units that never fit are an error only when strict.
SmmDietRun smmDietRunSteps(SmmDietStep [int] steps, SmmDietExtender [int] extenders, string [int] log, boolean strict) {
	SmmDietStep [int] pending;
	foreach i, st in steps pending[count(pending)] = st;
	boolean allowWaste = false;
	string error = "";
	boolean odeDone = false;
	while (count(pending) > 0 && error == "") {
		SmmDietStep [int] next;
		boolean progress = false;
		int n = count(pending);
		for (int s = 0; s < n && error == ""; s++) {
			SmmDietStep step = pending[s];
			if (step.row.isNightcap) {
				boolean othersLeft = count(next) > 0;
				for (int t = s + 1; t < n; t++) if (!pending[t].row.isNightcap) othersLeft = true;
				if (othersLeft) { next[count(next)] = step; continue; }
				if (my_inebriety() < inebriety_limit())
					log[count(log)] = "note: overdrinking at " + my_inebriety() + " of " + inebriety_limit() + " drunkenness (liver not full)";
			}
			if ((smmDietRowSpec(step.row).item.type == "booze" || step.order >= 5) && !odeDone) {
				smmDietCastOde(steps);
				odeDone = true;
			}
			int organ = smmDietBlockingOrgan(step);
			while (organ >= 0 && smmDietUseExtenderFor(organ, extenders, allowWaste)) organ = smmDietBlockingOrgan(step);
			if (organ >= 0) { next[count(next)] = step; continue; }
			DietSpec spec = smmDietRowSpec(step.row);
			if (spec.hasSize && !allowWaste && smmDietWastesCleaning(spec.size, -1) && (count(next) > 0 || s < n - 1)) {
				next[count(next)] = step;
				continue;
			}
			string err = smmDietConsumeUnit(step, log);
			if (err != "") error = err;
			else progress = true;
		}
		if (progress) allowWaste = false;
		else if (!allowWaste && count(next) > 0) allowWaste = true;
		else if (count(next) > 0 && error == "") {
			if (!strict) {
				SmmDietRun r = new SmmDietRun();
				r.left = next;
				return r;
			}
			int [int] st = smmDietOrganState();
			int [int] lim = smmDietOrganLimitsNow();
			error = "can't fit " + next[0].row.name + " (organs " + st[0] + "/" + st[1] + "/" + st[2] + " of " + lim[0] + "/" + lim[1] + "/" + lim[2] + ")";
		}
		pending = next;
	}
	SmmDietRun r = new SmmDietRun();
	r.error = error;
	r.left = pending;
	return r;
}

// Phase 3 setup: put on the organ-capacity gear and take out the Stooper.
void smmDietWearLateGear(DietSettings settings, string [int] log) {
	foreach g, gear in settings.gear {
		slot sl = to_slot(gear.slot);
		if (equipped_item(sl).name == gear.name) continue;
		boolean worn = equip(sl, to_item(gear.name));
		if (!worn) log[count(log)] = "warning: couldn't wear " + gear.name + "; plan may not fit";
	}
	if (settings.stooper && my_familiar() != $familiar[Stooper]) {
		boolean out = use_familiar($familiar[Stooper]);
		if (!out) log[count(log)] = "warning: couldn't take out the Stooper; plan may not fit";
	}
}

// Carry out phases 1 to lastPhase (1 execute, 2 turngen, 4 finish), with anything earlier left over.
void smmDietExecute(DietPlan plan, DietSettings settings, int lastPhase) {
	boolean finish = lastPhase == kSmmDietLastPhase;
	SmmDietStep [int] steps;
	SmmDietExtender [int] extenders;
	float cost = 0;
	clear(smmDietWishBudget);
	int seq = 0;
	foreach r, row in plan.rows {
		int n = 0;
		for (int ph = 1; ph <= lastPhase; ph++) n += plan.parts[r, ph];
		if (n == 0) continue;
		cost += row.price * n / row.amount;
		DietSpec spec = smmDietRowSpec(row);
		if (spec.opts["wish_salty_mouth"]) smmDietWishBudget["Salty Mouth"] += n;
		if (spec.opts["wish_refined_palate"]) smmDietWishBudget["Refined Palate"] += n;
		float order = smmDietOrderOf(row);
		if (order < 0) {
			if (spec.item.type == "extender") {
				SmmDietExtender e = new SmmDietExtender();
				e.row = row;
				e.left = n;
				extenders[count(extenders)] = e;
			}
			continue;
		}
		for (int ph = 1; ph <= lastPhase; ph++) {
			for (int k = 0; k < plan.parts[r, ph]; k++) {
				SmmDietStep st = new SmmDietStep();
				st.row = row;
				st.order = order;
				st.stage = ph;
				st.seq = seq;
				seq += 1;
				steps[count(steps)] = st;
			}
		}
	}
	smmDietSortSteps(steps);
	// early: phases 1-2 (organs' normal space, no gear); late: phases 3-4
	SmmDietStep [int] early;
	SmmDietStep [int] late;
	foreach i, st in steps {
		if (st.stage <= 2) early[count(early)] = st;
		else late[count(late)] = st;
	}
	string nextRun = lastPhase == 1 ? "call diet.ash turngen" : "call diet.ash finish";
	if (count(steps) == 0 && count(extenders) == 0) {
		if (finish) print("Nothing worth consuming.", "blue");
		else print("Nothing to consume in phase" + (lastPhase == 1 ? " 1" : "s 1-2") + ". Once your adventures are spent, run: " + nextRun, "blue");
		return;
	}
	string what = finish ? "the rest of today's diet" : (lastPhase == 1 ? "phase 1 of the diet" : "phases 1-2 of the diet");
	int sweatCasts = finish ? settings.sweatCasts : 0;
	if (sweatCasts > 0) what = "Cast Sweat Out Some Booze " + sweatCasts + "x, then buy and consume " + what;
	else what = "Buy and consume " + what;
	string question = what + " (about " + smmDietFmt(cost) + " meat)?";
	if (smmDietAutoYes) print(question + " Yes (the yes option).", "blue");
	else if (!user_confirm(question, 60000, false)) {
		print("Diet not executed.", "blue");
		return;
	}

	int startMeat = my_meat();
	int startAdv = my_adventures();
	smmDietMeatAtStart = startMeat;
	string [int] log;
	string error = "";
	SmmDietStep [int] left;
	boolean wore = false;
	boolean lateDone = false;
	familiar fam = my_familiar();
	boolean checkpoint = cli_execute("checkpoint");
	try {
		if (sweatCasts > 0) smmDietCastSweatOutBooze(sweatCasts, log);
		SmmDietRun run = smmDietRunSteps(early, extenders, log, false);
		error = run.error;
		left = run.left;
		if (finish && error == "") {
			// Organs are filled to the gear's capacity (never over), then the
			// overdrink; only then does the gear come off.
			smmDietWearLateGear(settings, log);
			wore = true;
			SmmDietStep [int] rest;
			foreach i, st in left rest[count(rest)] = st;
			foreach i, st in late rest[count(rest)] = st;
			smmDietSortSteps(rest);
			run = smmDietRunSteps(rest, extenders, log, true);
			error = run.error;
			left = run.left;
			lateDone = error == "";
		}
	} finally {
		smmDietNoteSpend("_smm.diet.spent", startMeat - my_meat());  // against the day's diet budget
		// Stopped before the overdrink: taking the gear or Stooper off now
		// could leave you over your liver limit without the nightcap.
		boolean keepGear = wore && !lateDone && my_inebriety() <= inebriety_limit();
		if (keepGear) {
			log[count(log)] = "warning: stopped before the overdrink: the organ gear and Stooper stay on; "
				+ "fix the problem and run finish again (or overdrink by hand) before taking them off";
		} else {
			boolean restored = cli_execute("outfit checkpoint");
			if (my_familiar() != fam) {
				boolean back = use_familiar(fam);
			}
		}
	}

	foreach l, line in log print(line, "orange");
	foreach e, ext in extenders if (ext.left > 0) print("Didn't need " + ext.left + "x " + ext.row.name, "gray");
	string summary = "Gained " + (my_adventures() - startAdv) + " adventures for " + smmDietFmt(startMeat - my_meat()) + " meat.";
	if (error != "") {
		print("Diet stopped: " + error + ". " + summary, "red");
	} else if (!finish) {
		if (count(left) > 0) {
			string names = "";
			foreach i, st in left names += (names == "" ? "" : ", ") + st.row.name;
			print("Didn't fit yet, left for the end of the day: " + names, "gray");
		}
		print((lastPhase == 1 ? "Phase 1" : "Phases 1-2") + " done. " + summary + " Adventure until these are spent, then run: " + nextRun, "green");
	} else {
		print("Diet done. " + summary, "green");
		int over = settings.overdrunkTurns;
		string sinkNote = settings.hasSink ? ", then whatever would pass " + kSmmDietCap + " on " + settings.sinkName : "";
		if (over > 0 || sinkNote != "")
			print("Now run good_night_adv (" + over + " overdrunk adventures of fights" + sinkNote + "): ash import <smmUnrestricted.ash>; good_night_adv()", "blue");
	}
}

// ---------------------------------------------------------------------------
// The command

void smmDietMain(string args) {
	string [string] opts = smmDietParseArgs(args);
	boolean finish = smmDietOpt(opts, "finish");
	smmDietAutoYes = smmDietOpt(opts, "yes");
	DietSettings settings = smmDietBuildSettings(opts);
	dietSemirareValue = mall_price($item[11-leaf clover]);
	clear(smmDietPriceCache);
	smmDietLoadMuseumSpare(smmDietCandidates());
	smmDietBuildConsumables(settings.excluded, settings.luckyWanted, settings.effectRates);

	settings.rolloverGain = smmDietRolloverGain(opts);
	boolean overdrunkNow = my_inebriety() > inebriety_limit();
	settings.overdrunkTurns = overdrunkNow ? 0 : smmDietOverdrunkTurns(opts);
	if (overdrunkNow) settings.hasSink = false;
	else smmDietOverdrunkSink(opts, settings);
	DietPlan plan = smmDietPlanDay(settings, finish);

	// Historical prices can be stale: re-check live mall prices for everything
	// the plan uses, and re-plan until those prices stop changing. The same
	// pass holds each planned purchase to its average sale price, and the whole
	// plan to the diet's budget for the day.
	int budget = smmDietBudget(opts);
	int spentToday = smmDietPrefInt("_smm.diet.spent");
	float fullValue = settings.advValue;
	SmmDietFit fit = smmDietFitPlan(plan, settings, finish, budget - spentToday, smmDietOpt(opts, "noRefresh") ? "" : "smmDietRefreshPlanPrices", "smmDietSpareLive");
	plan = fit.plan;
	string budgetNote = "Diet budget: " + smmDietFmt(max(0, budget - spentToday)) + " of " + smmDietFmt(budget) + " meat left today (smm.diet.budget, or budget=N), so this plan ";
	if (fit.ownedOnly) print(budgetNote + "buys nothing and uses only what is owned.", "orange");
	else if (settings.advValue < fullValue) print(budgetNote + "values an adventure at " + smmDietFmt(settings.advValue) + " meat instead of " + smmDietFmt(fullValue) + ".", "orange");

	smmDietPrintPlan(plan, settings, finish);
	// smmdaily's garbo.final stops at this many adventures before the nightcap
	set_property("_smm.diet.stopAt", to_string(max(0, plan.stopAt)));
	if (finish) {
		int excess = plan.held - plan.stopAt;
		if (excess > 0) {
			print("Not finishing: you hold " + plan.held + " adventures, " + excess + " more than the stop point (" + plan.stopAt
				+ "), so the nightcap would lose " + excess + " at rollover. Spend " + excess + " more (call diet.ash turngen first if phase 2 is left), then run finish again.", "red");
			return;
		}
		// what is left after good_night_adv, plus rollover: never past the cap (by construction)
		float spend = min(to_float(settings.overdrunkTurns), plan.held + plan.late);
		float sunk = settings.hasSink ? kSmmDietHuge : 0;  // a sink takes whatever is left over
		int lost = floor(plan.held + plan.late + plan.spread - spend - sunk + settings.rolloverGain - kSmmDietCap + kDietEpsilon);
		if (lost > 0) {
			print("Not finishing: this plan would lose " + lost + " adventures at rollover.", "red");
			return;
		}
	}
	if (fit.over) {
		print("Diet budget: this plan buys about " + smmDietFmt(fit.toBuy) + " meat of items, with " + smmDietFmt(spentToday) + " already spent today and a budget of "
			+ smmDietFmt(budget) + " (smm.diet.budget, or budget=N)."
			+ (finish || smmDietOpt(opts, "turngen") || smmDietOpt(opts, "execute") ? " Nothing is bought or consumed." : ""), "red");
		return;
	}
	smmDietBudgetRoom = max(0, budget - spentToday);
	if (finish) smmDietExecute(plan, settings, kSmmDietLastPhase);
	else if (smmDietOpt(opts, "turngen")) smmDietExecute(plan, settings, 2);
	else if (smmDietOpt(opts, "execute")) smmDietExecute(plan, settings, 1);
}
