// NPC resale planning and form validation. No purchases or account mutations.
record SmmNRVendor {
	item it;
	string shop;
	int row;
	int base;
};

record SmmNRMarket {
	int price;
	int volume;
	int activeDays;
	int largestDay;
	boolean valid;
};

record SmmNRBatch {
	int quantity;
	int unitCost;
	int worstCost;
	int profit;
	boolean jelly;
};

boolean smmNRShopSupported(string shop) {
	return contains_text("|generalstore|gnoll|madeline|knobdisp|hiddentavern|guildstore1|guildstore2|guildstore3|hippy|armory|blackmarket|bartender|jewelers|unclep|chinatown|cyber_hackmarket|dripcafeteria|driparmory|gnomart|whitecitadel|", "|" + shop + "|");
}

SmmNRVendor smmNRVendorLine(string line) {
	SmmNRVendor out;
	string [int] f = split_string(line, "\t");
	if (count(f) < 5 || !smmNRShopSupported(f[1]) || !f[3].is_integer()) return out;
	matcher row = create_matcher("^ROW([0-9]+)$", f[4]);
	if (!find(row)) return out;
	out.it = to_item(f[2]);
	if (out.it == $item[none] || !out.it.tradeable || f[3].to_int() <= 0) { out.it = $item[none]; return out; }
	// A catalog quantity restriction is not a bulk allowance.
	if (count(f) > 5 && f[5] != "") { out.it = $item[none]; return out; }
	out.shop = f[1]; out.row = group(row, 1).to_int(); out.base = f[3].to_int();
	return out;
}

// Pricegun's default window: use the previous fourteen complete UTC dates,
// including zero-sale days. Today's partial bucket never inflates the rate.
SmmNRMarket smmNRMarketFrom(string response, int average, int today) {
	SmmNRMarket out;
	if (average <= 0) return out;
	matcher history = create_matcher('(?s)"history"\\s*:\\s*\\[(.*?)\\]', response);
	if (!find(history)) return out;
	boolean [int] seen;
	foreach i, entry in split_string(group(history, 1), "\\}\\s*,\\s*\\{") {
		matcher date = create_matcher('"date"\\s*:\\s*"([0-9]{4}-[0-9]{2}-[0-9]{2})T', entry);
		matcher volume = create_matcher('"volume"\\s*:\\s*([0-9]+)', entry);
		if (!find(date) || !find(volume)) continue;
		int day = date_to_timestamp("yyyy-MM-ddX", group(date, 1) + "Z") / 86400000;
		if (day < today - 14 || day >= today) continue;
		if (seen[day]) return new SmmNRMarket();
		seen[day] = true;
		int units = group(volume, 1).to_int();
		if (units < 0 || units > 1000000000) return new SmmNRMarket();
		out.volume += units;
		if (units > 0) out.activeDays += 1;
		out.largestDay = max(out.largestDay, units);
	}
	matcher sales = create_matcher('(?s)"sales"\\s*:\\s*\\[(.*?)\\]', response);
	if (!find(sales)) return out;
	matcher prices = create_matcher('"unitPrice"\\s*:\\s*\\{\\s*"__decimal__"\\s*:\\s*"([0-9]+(?:\\.[0-9]+)?)"', group(sales, 1));
	float [int] recent;
	while (find(prices) && count(recent) < 20) recent[count(recent)] = group(prices, 1).to_float();
	if (count(recent) == 0) return out;
	sort recent by value;
	int n = count(recent);
	float median = n % 2 == 1 ? recent[n / 2] : (recent[n / 2 - 1] + recent[n / 2]) / 2.0;
	out.price = floor(min(average, median));
	// At least three selling dates, and no single-date whale dominating demand.
	out.valid = out.price > 0 && out.volume > 0 && out.activeDays >= 3 && out.largestDay <= out.volume * 0.8;
	return out;
}

int smmNRStockGap(int volume, int days, int held) {
	if (volume <= 0 || days <= 0) return 0;
	int ceiling = min(16777215, floor(volume / 14.0 * min(365, days)));
	return max(0, ceiling - max(0, held));
}

int smmNRUnitCost(int base, boolean fiveFinger, boolean jelly) {
	return max(0, floor(base * (95 - (fiveFinger ? 5 : 0) - (jelly ? 10 : 0)) / 100.0));
}

// Reserve the full pants-only charge, even with jelly: a missing discount must
// not break the cash ceiling. Jelly's cash acquisition is part of that ceiling;
// its economic cost also prices owned copies and displaced spleen.
SmmNRBatch smmNRPlan(int wanted, int budget, int base, int resale, boolean fiveFinger,
	boolean canJelly, int jellyCash, int jellyValue) {
	SmmNRBatch best;
	int plain = smmNRUnitCost(base, fiveFinger, false);
	if (wanted <= 0 || budget <= 0 || plain <= 0 || resale <= 0) return best;
	int q = min(wanted, budget / plain);
	int gain = q * (resale - plain);
	if (gain > 0) { best.quantity = q; best.unitCost = plain; best.worstCost = q * plain; best.profit = gain; }
	if (canJelly && jellyCash >= 0 && jellyValue >= jellyCash && budget > jellyCash) {
		q = min(wanted, (budget - jellyCash) / plain);
		int unit = smmNRUnitCost(base, fiveFinger, true);
		gain = q * (resale - unit) - jellyValue;
		if (unit > 0 && gain > best.profit && gain > 0) {
			best.quantity = q; best.unitCost = unit; best.worstCost = q * plain + jellyCash;
			best.profit = gain; best.jelly = true;
		}
	}
	return best;
}

// Validate the precise visible NPC row and its Meat-only price. Requires the
// bulk-buy button; disabled, missing, mismatched and multi-currency rows fail.
int smmNRVisiblePrice(string html, SmmNRVendor vendor) {
	matcher rows = create_matcher("(?is)<tr\\b[^>]*\\brel=[\"']" + vendor.it.to_int() + "[\"'][^>]*>(.*?)</tr>", html);
	while (find(rows)) {
		string row = group(rows, 1);
		if (contains_text(to_lower_case(row), "disabled") || !contains_text(row, "multibuy")) continue;
		if (!contains_text(row, "whichshop=" + vendor.shop + "&") || !contains_text(row, "whichrow=" + vendor.row + "&")) continue;
		// Native shop rows have three product cells, then Meat image and price.
		// Reject currencies on either side of Meat, not just after its price.
		string [int] cells;
		matcher cell = create_matcher('(?is)<td\\b[^>]*>(.*?)</td>', row);
		while (find(cell)) cells[count(cells)] = group(cell, 1);
		if (count(cells) < 6 || !contains_text(cells[3], "meat.gif")) continue;
		boolean otherCurrency;
		foreach i, content in cells if (i >= 3 && (contains_text(content, "descitem(") || contains_text(content, "desc_item.php"))) otherCurrency = true;
		if (otherCurrency) continue;
		matcher price = create_matcher('(?is)^\\s*<b>([0-9,]+)</b>', cells[4]);
		if (!find(price)) continue;
		return group(price, 1).to_int(); // ASH reads grouped numbers (e.g. 1,000)
	}
	return 0;
}

string smmNRPurchaseURL(SmmNRVendor vendor, int quantity) {
	return "shop.php?whichshop=" + vendor.shop + "&action=buyitem&whichrow=" + vendor.row
		+ "&quantity=" + quantity + "&ajax=1";
}

boolean smmNRJellyConfirmed(boolean result, int beforeItems, int afterItems, int beforeSpleen, int afterSpleen) {
	return result && beforeItems - afterItems == 1 && afterSpleen - beforeSpleen == 1;
}

boolean smmNRReceiptOK(int quantity, int received, int paid, int expectedUnit) {
	return quantity > 0 && received == quantity && paid == quantity * expectedUnit;
}

// Direct shop requests can log the pants-only price, omitting the one-shot
// jelly discount. Reconcile exactly what this worker appended to the log.
int smmNRLoggedPurchases(string log) {
	int total;
	matcher m = create_matcher("(?m-s)^buy ([0-9,]+) .+? for ([0-9,]+) each from [^\\r\\n]+", log);
	while (find(m)) total += group(m, 1).to_int() * group(m, 2).to_int();
	return total;
}
