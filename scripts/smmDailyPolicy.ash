// Pure policy seams shared by the runner, accounting and combat scripts.
boolean smmDailyRocketAllowed(boolean ronin, int copies, int effectTurns) {
	return !ronin && copies > 0 && effectTurns <= 0;
}

int smmDailyCombatHpTarget(int maximum) { return max(1, ceil(maximum * 0.6)); }

boolean smmDailyCollectionEligible(boolean unbuyable, boolean displayable, boolean known, int missing) {
 return unbuyable && displayable && known && missing > 0;
}
boolean smmDailyCollectionCanFund(int committed, int existingReservation, int turns, int turnValue, int budget) {
 return turns > 0 && turnValue > 0 && max(0, committed - max(0, existingReservation)) + turns * turnValue <= max(0, budget);
}

int smmDailyFundedTurnsLeft(int current, int started, int limit) {
 return max(0, limit - max(0, current - started));
}

int smmDailySignedItemDelta(int before, int after) { return after - before; }

// Reusable equipment returning from a fight is not newly produced loot.
boolean smmDailyReturnItem(item it) {
	return it.reusable || it == $item[cosmic bowling ball];
}

int smmDailyPurchaseLimit(int requested, float average) {
	return average > 0 ? max(0, min(requested, floor(average))) : 0;
}

string smmDailyResourceState(int used, int limit, string blocked, string reserved, string owner, boolean failed) {
	if (used >= limit) return "used";
	if (failed) return "missed: owner failed";
	if (blocked != "") return "blocked: " + blocked;
	if (reserved != "") return "reserved: " + reserved;
	return "unspent: " + owner + " has no confirmed profitable use recorded";
}
