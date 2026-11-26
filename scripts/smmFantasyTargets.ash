// Shared read-only FantasyRealm target selection.
import <smmMuseumPolicy.ash>

item [] gkFRItems = {$item[Rubee&trade;],
	$item[sachet of strange powder], $item[druidic s'more], $item[mourning wine], $item[denastified haunch], $item[bad rum and good cola], $item[Potion of Heroism],
	$item[the Archwizard's briefs], $item[Duke Vampire's regal cloak], $item[The Ghoul King's ghoulottes], $item[the Ley Incursion's waist], $item[Master Thief's utility belt], $item[belt of Ogrekind],
	$item[nozzle of the Phoenix], $item[Dragonscale breastplate], $item[leggings of the Spider Queen],
	$item[shield of the Skeleton Lord], $item[ring of the Skeleton Lord], $item[scepter of the Skeleton Lord],
};


// Routes whose final choices were never confirmed (they stop on an assert).
boolean [item] gkFRUnverifiedRoutes = $items[bad rum and good cola, Potion of Heroism];
item gkFRFallbackItem = $item[scepter of the Skeleton Lord];
int kFRTurnsPerRun = 30;


// A run gives one reward, except the Rubee route (40-60 + 40-60 + 90-110).
int frRunYield(item it) {
	return it == $item[Rubee&trade;] ? 200 : 1;
}

// Runs still needed to hold Museum #1 (strongest other collection plus the usual buffer),
// counting copies owned outside the Display Case. -1 when no ranking is stored.
// Reads the stored ranking only; never asks the Museum.
int frRunsToFirst(item it) {
	int target = smmMuseumFirstTarget(smmMuseumCachedCollection(it));
	if (target < 0) return -1;
	int stillShort = target - display_amount(it) - smmMuseumOwnedCopies(it);
	if (stillShort <= 0) return 0;
	return ceil(stillShort.to_float() / frRunYield(it));
}

// Why a reward is not a candidate for the daily run; "" when it is.
string frSkipReason(item it) {
	if (gkFRUnverifiedRoutes contains it) return "route not verified";
	int runs = frRunsToFirst(it);
	if (runs < 0) return "no stored Museum ranking";
	if (runs == 0) return "already enough for #1";
	int price = it.tradeable ? historical_price(it) : 0;
	if (price > 0 && price < kFRTurnsPerRun * kTurnValue) return "cheaper to buy (" + price + " Meat)";
	return "";
}

// The reward to grind today: the one that reaches Museum #1 in the fewest runs.
// smm.frTarget names a reward to use instead. Falls back to the scepter when no
// reward is short. Makes no game requests.
item frChooseTarget(boolean verbose) {
	item forced = get_property("smm.frTarget").to_item();
	foreach i, it in gkFRItems if (it == forced && forced != $item[none]) {
		if (verbose) print("fr: smm.frTarget asks for " + forced, "blue");
		return forced;
	}
	item best = $item[none];
	int bestRuns = 0;
	foreach i, it in gkFRItems {
		string skip = frSkipReason(it);
		int runs = frRunsToFirst(it);
		if (verbose)
			print("fr: " + it + ": case " + display_amount(it) + ", other " + smmMuseumOwnedCopies(it)
				+ (skip == "" ? ", " + runs + " runs to #1" : ", skipped: " + skip), skip == "" ? "blue" : "gray");
		if (skip != "") continue;
		if (best == $item[none] || runs < bestRuns) {
			best = it;
			bestRuns = runs;
		}
	}
	if (best == $item[none]) {
		if (verbose) print("fr: no reward is short of #1, using " + gkFRFallbackItem, "orange");
		return gkFRFallbackItem;
	}
	if (verbose) print("fr: target " + best + ", " + bestRuns + " runs to #1", "green");
	return best;
}

// Today's target: chosen once a day and remembered in _smm.frTarget so a resumed run keeps it.
item frTodaysTarget() {
	item remembered = get_property("_smm.frTarget").to_item();
	foreach i, it in gkFRItems if (it == remembered && remembered != $item[none]) return remembered;
	item chosen = frChooseTarget(true);
	set_property("_smm.frTarget", chosen.to_string());
	return chosen;
}
