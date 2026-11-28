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

// A fresh HTTP response can still contain an old character count. Only a
// matching Museum row proves the current position; cached thresholds do not.
int smmDailyVerifiedRank(boolean fetched, int checked, int started, int displayed, int pageCount, int pageRank) {
 return fetched && checked >= started && displayed > 0 && pageCount == displayed && pageRank > 0 ? pageRank : 0;
}

boolean smmDailyCraftMethod(string method, int quantity, int cooks, int mixes) {
 if (quantity < 1) return false;
 if (method == "Cooking" || method == "Mixing") return true;
 if (method == "Cooking (fancy)") return cooks >= quantity;
 if (method == "Mixing (fancy)") return mixes >= quantity;
 return false; // fees, paid turns, currencies and unknown methods need a model
}

int smmDailyCraftPurchaseLimit(int quantity, float inputValue, int configured) {
 return quantity > 0 && inputValue > 0 && configured > 0 ? max(0, min(configured, floor(inputValue / quantity))) : 0;
}

boolean smmDailyCombatItemReady(boolean reusable, int physical, int spare) {
 return physical > 0 && (reusable || spare > 0);
}

boolean smmDailySourceUnavailable(boolean owned, int used, int limit) {
 return !owned || (limit > 0 && used >= limit);
}

int smmDailyDaycareBudget(int configured, int spent, int adventures) {
 return min(max(0, adventures), max(0, min(3, max(0, configured)) - max(0, spent)));
}

boolean smmDailyCanReconcileGarbo(string completed, string hold, boolean access, int stopAt) {
 if (hold == "" || !access || stopAt < 0) return false;
 matcher standard = create_matcher("^garbo(?: -([0-9]+))?$", completed);
 if (!standard.find()) return false;
 return standard.group(1) == "" || standard.group(1).to_int() <= stopAt;
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

// Marginal sale capacity after existing stock, not the value of an unlimited
// number of copies at one observed sale price. Never assumes market monopoly.
int smmDailyLiquidCapacity(int marketVolume14Days, int horizonDays, float share) {
 return max(0, floor(min(1000000000.0, max(0, marketVolume14Days) / 14.0 * min(30, max(0, horizonDays)) * min(0.25, max(0.0, share)))));
}

int smmDailyLiquidValue(int quantity, int existingStock, int capacity, int salePrice, int autosell) {
 int q = max(0, quantity);
 int liquid = min(q, max(0, capacity - max(0, existingStock)));
 return floor(min(1000000000.0, q * max(0.0, autosell) + liquid * max(0.0, salePrice - max(0, autosell))));
}
