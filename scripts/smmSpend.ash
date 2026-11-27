// Daily Meat ledger and budgeted buying. See docs/daily-spending.md.
//
// The spending rules (docs/aftercore-goals.md):
//   1. Meat goes first to purchases with a positive return, then to items on
//      sale, biggest discount first.
//   2. Spend at most half of the Meat netted that day.
//   3. Never pay above the market price.
//   4. "Cheap" means 20% or more under the market price.
// The market price is the item's recent average sale price (Pricegun), not the
// current lowest mall listing.

import <smmUtils.ash>
import <smmMuseumPolicy.ash>
import <smmDailyReceipts.ash>
import <smmNpcResale.ash>


string kSmmSpendStartKey = "_smm.spend.startMeat";   // cleared at rollover
string kSmmSpendCloseKey = "smm.spend.lastClose";    // kept across days: Meat held when the spending step last finished
string kSmmSpendSpentKey = "_smm.spend.spent";       // cleared at rollover
string kSmmSpendOperatingKey = "_smm.spend.operating"; // cleared at rollover: Meat everything else paid for purchases today, booked by smmDaily
string kSmmSpendLogAdjustmentKey = "_smm.spend.logAdjustment"; // NPC log charge minus measured charge
string kSmmSpendNPCPendingKey = "smm.spend.npcPending"; // survives rollover: interrupted/ambiguous batch needs reconciliation
string kSmmSpendBuyMapFile = "unrestricted_buy_map.txt";

record SmmSpendOffer {
	item it;
	int quantity;    // copies wanted
	int average;     // average sale price of one copy, 0 when unknown
	int price;       // current mall price of one copy
	int limit;       // the most to pay for one copy
	float score;     // higher is bought first
};

// ---------------------------------------------------------------------------
// Settings

boolean smmSpendEnabled() { return get_property("smm.spend.enabled") != "false"; }
boolean smmSpendDryRun() { return get_property("smm.spend.dryRun") == "true"; }

float smmSpendFraction() {
	string explicit = get_property("smm.spend.fraction");
	if (explicit == "") return 0.5;
	return min(0.5, max(0.0, explicit.to_float())); // rule 2 is a ceiling: never above half
}

float smmSpendMinDiscount() {
	string explicit = get_property("smm.spend.minDiscount");
	if (explicit == "") return 0.2;
	return min(0.95, max(0.2, explicit.to_float())); // rule 4 is a floor: never under 20%
}

// Pass 2 trusts an average sale price only when at least this many copies sold
// in Pricegun's history (about two weeks).
int smmSpendMinSales() {
	string explicit = get_property("smm.spend.minSales");
	return explicit == "" ? 5 : max(1, explicit.to_int());
}

int smmSpendMaxLookups() {
	string explicit = get_property("smm.spend.maxLookups");
	return explicit == "" ? 60 : max(0, explicit.to_int());
}

// ---------------------------------------------------------------------------
// Ledger: what the day netted, and what this script has spent of it.

int smmSpendLiquidMeat() {
	return my_meat() + my_closet_meat() + my_storage_meat();
}

// Record the day's opening Meat. Safe to call any number of times: only the
// first call of the day (the property is cleared at rollover) sets it.
// The day opens at the Meat held when the spending step last finished, so that
// shop sales made since then (overnight, while logged out) count as net. With
// no earlier close on record it opens at the Meat held now.
void smmSpendDayStart() {
	if (get_property(kSmmSpendStartKey) != "") return;
	string lastClose = get_property(kSmmSpendCloseKey);
	set_property(kSmmSpendStartKey, lastClose != "" ? lastClose.to_int() : smmSpendLiquidMeat());
}

// Record the Meat held now as the point the next day opens from.
void smmSpendDayClose() {
	set_property(kSmmSpendCloseKey, smmSpendLiquidMeat());
}

boolean smmSpendStarted() { return get_property(kSmmSpendStartKey) != ""; }

int smmSpendSpent() { return get_property(kSmmSpendSpentKey).to_int(); }

int smmSpendLoggedSpentFrom(int spent, int adjustment) { return max(0, spent + adjustment); }
int smmSpendLoggedSpent() { return smmSpendLoggedSpentFrom(smmSpendSpent(), get_property(kSmmSpendLogAdjustmentKey).to_int()); }

// Meat netted today by everything except this script's own purchases.
int smmSpendNet() {
	if (!smmSpendStarted()) return 0;
	return smmSpendLiquidMeat() + smmSpendSpent() - get_property(kSmmSpendStartKey).to_int();
}

// Meat that every other purchase of the day cost: the old daily code, garbo,
// buying by hand. smmDaily books it from the session log (smmDailyGate.ash).
// It is 0 until then, which is how this script behaved before.
int smmSpendOperating() { return get_property(kSmmSpendOperatingKey).to_int(); }

// Rule 2 as arithmetic: this script's purchases and the day's other purchases
// together stay within the fraction of the day's net. Nothing on a losing day.
int smmSpendAllowance(int net, int spent, int operating, float fraction) {
	int allowed = floor(max(0, net) * min(0.5, max(0.0, fraction)));
	return max(0, allowed - max(0, spent) - max(0, operating));
}

int smmSpendAllowance(int net, int spent, int operating, int dietPurchases, float fraction) {
 return smmSpendAllowance(net, spent, max(0, operating) + max(0, dietPurchases), fraction);
}

int smmSpendDietPurchases() { return max(0, get_property("_smm.diet.bought").to_int()); }

// Meat still allowed to be spent today. Never more than the Meat on hand.
// Refresh immediately before every allowance decision, including the buying
// inside good_night. Purchase requests conservatively overbook partial fills.
int smmSpendLogOffset;
int smmSpendLogPurchases;
void smmSpendRefreshOperating() {
 if (get_property("smm.daily.active") == "") return;
 string [int] logs = session_logs(1);
 if (count(logs) == 0) return;
 if (logs[0].length() < smmSpendLogOffset) { smmSpendLogOffset = 0; smmSpendLogPurchases = 0; }
 matcher buys = create_matcher("(?m-s)^buy ([0-9,]+) .+ for ([0-9,]+) each from .+$", logs[0].substring(smmSpendLogOffset));
 while (buys.find()) smmSpendLogPurchases += buys.group(1).to_int() * buys.group(2).to_int();
 smmSpendLogOffset = logs[0].length();
 int elsewhere = smmSpendLoggedSpent() + max(0, get_property("_smm.diet.bought").to_int());
 set_property(kSmmSpendOperatingKey, max(smmSpendOperating(), max(0, smmSpendLogPurchases - elsewhere)));
}

int smmSpendBudget() {
 smmSpendRefreshOperating();
	return min(smmSpendAllowance(smmSpendNet(), smmSpendSpent(), smmSpendOperating(), smmSpendDietPurchases(), smmSpendFraction()), my_meat());
}

void smmSpendReport() {
	if (!smmSpendStarted()) {
		print("Spending: no opening Meat recorded today, so the budget is 0.", "orange");
		return;
	}
 int remaining = smmSpendBudget(); // refresh before printing the booked totals
	print("Spending: opened at " + get_property(kSmmSpendStartKey) + " Meat, netted " + smmSpendNet()
		+ ", spent " + smmSpendSpent() + (smmSpendOperating() > 0 ? ", other purchases " + smmSpendOperating() : "")
		+ ", diet purchases " + smmSpendDietPurchases() + ", still allowed " + remaining, "blue");
}

// ---------------------------------------------------------------------------
// Market price: the recent average sale price.

float [item] smmSpendAverages;
int [item] smmSpendVolumes;
string [item] smmSpendMarketResponses;
int smmSpendLookups;

// Copies sold over Pricegun's history. 0 when there is none.
int smmSpendParseVolume(string response) {
	int units = 0;
	matcher history = create_matcher("(?s)\"history\"\\s*:\\s*\\[(.*?)\\]", response);
	if (!find(history)) return 0;
	matcher volumes = create_matcher("\"volume\"\\s*:\\s*([0-9]+)", group(history, 1));
	while (find(volumes))
		units += to_int(group(volumes, 1));
	return units;
}

// Pricegun's value is a time-weighted completed-sale estimate. Require both a
// sale and a history entry; anything missing or malformed is "unknown" (0).
float smmSpendParseAverage(item it, string response) {
	matcher identity = create_matcher("\"itemId\"\\s*:\\s*([0-9]+)", response);
	if (!find(identity) || to_int(group(identity, 1)) != to_int(it)) return 0;
	matcher sales = create_matcher("\"sales\"\\s*:\\s*\\[\\s*\\{", response);
	matcher history = create_matcher("\"history\"\\s*:\\s*\\[\\s*\\{", response);
	if (!find(sales) || !find(history)) return 0;
	matcher value = create_matcher("\"value\"\\s*:\\s*\\{\\s*\"__decimal__\"\\s*:\\s*\"([0-9]+(?:\\.[0-9]+)?)\"\\s*\\}", response);
	if (!find(value)) return 0;
	return max(0.0, to_float(group(value, 1)));
}

// 0 when unknown. One request per item per session.
float smmSpendAveragePrice(item it) {
	if (!(smmSpendAverages contains it)) {
		smmSpendLookups += 1;
		string response = visit_url("https://pricegun.loathers.net/api/" + to_int(it), false, false);
		smmSpendMarketResponses[it] = response;
		smmSpendAverages[it] = smmSpendParseAverage(it, response);
		smmSpendVolumes[it] = smmSpendAverages[it] > 0 ? smmSpendParseVolume(response) : 0;
	}
	return smmSpendAverages[it];
}

// Copies sold recently, from the same request as the average.
int smmSpendSalesVolume(item it) {
	smmSpendAveragePrice(it);
	return smmSpendVolumes[it];
}

// ---------------------------------------------------------------------------
// Buying

// Buys up to offer.quantity at no more than offer.limit each, within the
// remaining budget. Returns the Meat actually spent, measured, not estimated.
int smmSpendBuy(SmmSpendOffer offer, string reason) {
	int budget = smmSpendBudget();
 offer.limit = smmDailyPurchaseLimit(offer.limit, smmSpendAveragePrice(offer.it));
 if (offer.limit <= 0) {
  print("Spending: no verified average-price allowance for " + offer.it + "; skipped", "orange");
  return 0;
 }
	// buy() may pay up to the limit for each copy, so the limit sizes the purchase:
	// the budget can't be exceeded whatever the listings turn out to cost
	int quantity = min(offer.quantity, budget / offer.limit);
	if (quantity < 1) return 0;
	if (smmSpendDryRun()) {
		print("Spending (dry run): would buy " + quantity + " " + offer.it + " at up to " + offer.limit + " each (" + reason + ")", "blue");
		return 0;
	}
	int before = my_meat();
	int bought = buy(quantity, offer.it, offer.limit);
	int spent = max(0, before - my_meat());
	if (spent > 0)
		set_property(kSmmSpendSpentKey, smmSpendSpent() + spent);
	print("Spending: bought " + bought + " " + offer.it + " for " + spent + " Meat (" + reason + ")", "blue");
	return spent;
}

// Pass 1: positive return. The buy map lists items with what one copy is worth
// to us and how many to keep on hand. A copy priced under that worth returns
// more than it costs. Best return per Meat first.
void smmSpendPositiveReturn() {
	int [item, int] buy_map;
	if (!file_to_map(kSmmSpendBuyMapFile, buy_map)) {
		print("Spending: could not read " + kSmmSpendBuyMapFile, "orange");
		return;
	}

	SmmSpendOffer [int] offers;
	int lookups = 0;
	foreach it, worth, keep in buy_map {
		if (it == $item[none] || !it.tradeable || worth <= 0) continue;
		int wanted = keep - available_amount(it);
		if (wanted < 1) continue;
		// a fresh stored price well above the item's worth needs no request
		if (historical_price(it) > worth && historical_age(it) < 2.0) continue;
		if (lookups >= smmSpendMaxLookups()) break;
		lookups += 1;
		int price = mall_price(it);
		if (price <= 0 || price >= worth) continue;

		// Rule 3: a verified average is required before buying.
		float average = smmSpendAveragePrice(it);
		int limit = smmDailyPurchaseLimit(worth, average);
		if (limit < price) continue;

		SmmSpendOffer offer;
		offer.it = it;
		offer.quantity = wanted;
		offer.price = price;
		offer.average = floor(average);
		offer.limit = limit;
		offer.score = (worth - price) / to_float(price);
		offers[count(offers)] = offer;
	}

	sort offers by -value.score;
	foreach i, offer in offers
		smmSpendBuy(offer, "worth " + round(offer.score * 100) + "% more than its price");
}

// Candidates in id order, starting after the item examined last time, so that
// a capped number of lookups a day still works through the whole list.
int [int] smmSpendRotate(int [int] ids, string cursorKey) {
	int [int] ordered;
	int cursor = get_property(cursorKey).to_int();
	sort ids by value;
	foreach i, id in ids if (id > cursor) ordered[count(ordered)] = id;
	foreach i, id in ids if (id <= cursor) ordered[count(ordered)] = id;
	return ordered;
}

// ---------------------------------------------------------------------------
// NPC resale: a positive-return pass before collection purchases.

int smmSpendNPCDays() {
	string setting = get_property("smm.spend.npcBufferDays");
	return setting == "" ? 365 : min(365, max(0, setting.to_int()));
}

int smmSpendNPCSpleenValue() {
	string setting = get_property("smm.spend.npcSpleenValue");
	return setting == "" ? ceil(1.88 * max(0, kTurnValue)) : max(0, setting.to_int());
}

int smmSpendNPCHeld(item it) {
	return item_amount(it) + closet_amount(it) + storage_amount(it) + shop_amount(it) + equipped_amount(it);
}

item smmSpendNPCPants() {
	foreach pants in $items[Travoltan trousers, designer sweatpants, replica designer sweatpants]
		if ((item_amount(pants) > 0 || equipped_amount(pants) > 0) && can_equip(pants)) return pants;
	return $item[none]; // never buy equipment as an unbudgeted side effect
}

string smmSpendNPCLog() {
	string [int] logs = session_logs(1);
	return count(logs) > 0 ? logs[0] : "";
}

record SmmSpendNPCOffer {
	SmmNRVendor vendor;
	SmmNRMarket market;
	float score;
};

record SmmSpendNPCJelly {
	boolean usable;
	int cash;
	int value;
};

SmmSpendNPCJelly smmSpendNPCQuote() {
	SmmSpendNPCJelly quote;
	if (my_spleen_use() >= spleen_limit()) return quote;
	item jelly = $item[sleaze jelly];
	boolean spare = item_amount(jelly) > 0 && smmMuseumSpareCopies(jelly) > 0;
	int average = floor(smmSpendAveragePrice(jelly));
	int price = mall_price(jelly);
	quote.usable = average > 0 && price > 0 && (spare || price <= average);
	if (quote.usable) {
		quote.cash = spare ? 0 : average;
		quote.value = max(quote.cash, ceil(spare ? smmMuseumOwnedValue(jelly, 1) : average)) + smmSpendNPCSpleenValue();
	}
	return quote;
}

// Final preparation may visit pages and buy one fresh jelly. Everything must
// finish BEFORE chewing: the only following game request is the single POST.
boolean smmSpendNPCBuy(SmmSpendNPCOffer offer, item pants, boolean fiveFinger,
	boolean canJelly, int jellyCash, int jellyValue) {
	item it = offer.vendor.it;
	item jelly = $item[sleaze jelly];
	int resale = offer.market.price;
	if (shop_amount(it) > 0) resale = min(resale, shop_price(it));
	int wanted = smmNRStockGap(offer.market.volume, smmSpendNPCDays(), smmSpendNPCHeld(it));
	SmmNRBatch batch = smmNRPlan(wanted, smmSpendBudget(), offer.vendor.base, resale, fiveFinger,
		canJelly && my_spleen_use() < spleen_limit(), jellyCash, jellyValue);
	if (batch.quantity < 1) return true;
	if (smmSpendDryRun()) {
		print("Spending (dry run): NPC resale " + batch.quantity + " " + it + " at " + batch.unitCost
			+ ", list at " + resale + "; projected profit " + batch.profit + ", " + offer.market.volume
			+ " sales / 14 complete days; " + (batch.jelly ? "one jelly immediately before one bulk purchase" : "pants only")
			+ ", conditional on the vendor price with " + pants + " equipped.", "blue");
		return true;
	}
	if (equipped_item($slot[pants]) != pants) return false;
	int plain = smmNRUnitCost(offer.vendor.base, fiveFinger, false);
	string page = visit_url("shop.php?whichshop=" + offer.vendor.shop);
	if (smmNRVisiblePrice(page, offer.vendor) != plain) return true; // locked store, outfit conflict, or changed price
	if (batch.jelly && jellyCash > 0) {
		int before = item_amount(jelly);
		SmmSpendOffer acquisition;
		acquisition.it = jelly; acquisition.quantity = 1; acquisition.limit = jellyCash;
		smmSpendBuy(acquisition, "one fresh jelly for NPC resale");
		if (item_amount(jelly) != before + 1) return true;
		// The cash is now booked. Charge its economic value, but do not reserve it twice.
		batch = smmNRPlan(wanted, smmSpendBudget(), offer.vendor.base, resale, fiveFinger, true, 0, jellyValue);
	}
	if (batch.quantity < 1) return true;
	if (batch.jelly && item_amount(jelly) < 1) return true;
	// Recheck the row after acquiring jelly; no fallback, split buy, or retrieval
	// is allowed once the one-purchase discount has been consumed.
	page = visit_url("shop.php?whichshop=" + offer.vendor.shop);
	if (equipped_item($slot[pants]) != pants || smmNRVisiblePrice(page, offer.vendor) != plain) return true;
	if (batch.worstCost > smmSpendBudget()) return true;
	string url = smmNRPurchaseURL(offer.vendor, batch.quantity) + "&pwd=" + my_hash();
	int beforeItems = item_amount(it);
	int beforeJelly = item_amount(jelly);
	int beforeSpleen = my_spleen_use();
	int beforeLogged = smmNRLoggedPurchases(smmSpendNPCLog());
	int beforeMeat = my_meat();
	int received; int paid;
	set_property(kSmmSpendNPCPendingKey, it.to_int() + ":" + batch.quantity + ":" + batch.unitCost + ":" + beforeMeat);
	try {
		if (batch.jelly) {
			boolean chewed = chew(1, jelly);
			if (!smmNRJellyConfirmed(chewed, beforeJelly, item_amount(jelly), beforeSpleen, my_spleen_use())) {
				print("Spending: jelly consumption was not confirmed; no NPC purchase sent. Reconcile " + kSmmSpendNPCPendingKey + ".", "red");
				return false;
			}
		}
		visit_url(url, true, false); // immediately after confirmed chew: exactly one item, one bulk request
	} finally {
		paid = max(0, beforeMeat - my_meat());
		received = item_amount(it) - beforeItems;
		set_property(kSmmSpendSpentKey, smmSpendSpent() + paid);
		int logged = smmNRLoggedPurchases(smmSpendNPCLog()) - beforeLogged;
		set_property(kSmmSpendLogAdjustmentKey, get_property(kSmmSpendLogAdjustmentKey).to_int() + logged - paid);
	}
	if (!smmNRReceiptOK(batch.quantity, received, paid, batch.unitCost)) {
		print("Spending: unexpected NPC receipt for " + it + ": received " + received + ", paid " + paid
			+ ". Spending stopped; reconcile " + kSmmSpendNPCPendingKey + " before clearing it.", "red");
		return false;
	}
	set_property(kSmmSpendNPCPendingKey, "");
	// Only the newly purchased copies are listed. Retain an existing lower shop
	// price and its per-buyer limit rather than repricing unrelated stock upward.
	if (!put_shop(resale, shop_limit(it), received, it))
		print("Spending: listing failed for " + received + " " + it + "; stock retained and counts against the next batch.", "orange");
	print("Spending: NPC resale bought " + received + " " + it + " for " + paid + ", listing at " + resale
		+ " each; projected profit " + batch.profit + (batch.jelly ? " after jelly and spleen value" : " with pants only"), "blue");
	return true;
}

boolean smmSpendNPCResale() {
	if (get_property("smm.spend.npcResale") == "false" || smmSpendNPCDays() < 1) return true;
	item pants = smmSpendNPCPants();
	if (pants == $item[none]) { print("Spending: NPC resale needs owned discount pants in inventory or equipped.", "orange"); return true; }
	if (!refresh_shop()) { print("Spending: cannot refresh shop stock; skipping NPC resale.", "orange"); return true; }
	boolean fiveFinger = have_skill($skill[Five Finger Discount]);
	SmmSpendNPCJelly quote = smmSpendNPCQuote();
	SmmNRVendor [int] vendors;
	boolean [int] seen;
	int [int] ids;
	foreach n, line in file_to_array("data/npcstores.txt") {
		SmmNRVendor vendor = smmNRVendorLine(line);
		if (vendor.it == $item[none] || npc_price(vendor.it) <= 0) continue;
		vendors[count(vendors)] = vendor;
		int id = vendor.it.to_int();
		if (!seen[id]) { seen[id] = true; ids[count(ids)] = id; }
	}
	item previous = equipped_item($slot[pants]);
	string [string] saved;
	foreach pref in $strings[autoSatisfyWithMall, autoSatisfyWithNPCs, autoSatisfyWithCoinmasters, autoSatisfyWithCloset, autoSatisfyWithStorage, autoSatisfyWithStash]
		saved[pref] = get_property(pref);
	try {
		if (!smmSpendDryRun()) {
			foreach pref in saved set_property(pref, "false");
			if (!equip($slot[pants], pants) || equipped_item($slot[pants]) != pants) return true;
		}
		SmmSpendNPCOffer [int] offers;
		string [string] pages;
		int lookups;
		foreach n, id in smmSpendRotate(ids, "smm.spend.npcCursor") {
			if (lookups >= smmSpendMaxLookups()) break;
			lookups += 1;
			if (!smmSpendDryRun()) set_property("smm.spend.npcCursor", id);
			item it = id.to_item();
			int average = floor(smmSpendAveragePrice(it));
			SmmNRMarket market = smmNRMarketFrom(smmSpendMarketResponses[it], average, now_to_int() / 86400000);
			if (!market.valid || market.volume < smmSpendMinSales()) continue;
			int resale = shop_amount(it) > 0 ? min(market.price, shop_price(it)) : market.price;
			int wanted = smmNRStockGap(market.volume, smmSpendNPCDays(), smmSpendNPCHeld(it));
			SmmSpendNPCOffer best;
			foreach v, vendor in vendors {
				if (vendor.it != it) continue;
				SmmNRBatch plan = smmNRPlan(wanted, smmSpendBudget(), vendor.base, resale, fiveFinger, quote.usable, quote.cash, quote.value);
				if (plan.quantity < 1) continue;
				if (!(pages contains vendor.shop)) pages[vendor.shop] = visit_url("shop.php?whichshop=" + vendor.shop);
				int visible = smmNRVisiblePrice(pages[vendor.shop], vendor);
				if (visible <= 0 || (!smmSpendDryRun() && visible != smmNRUnitCost(vendor.base, fiveFinger, false))) continue;
				float score = plan.profit / to_float(max(1, plan.worstCost));
				if (score > best.score) { best.vendor = vendor; best.market = market; best.score = score; }
			}
			if (best.score > 0) offers[count(offers)] = best;
		}
		sort offers by -value.score;
		foreach n, offer in offers {
			if (smmSpendBudget() < 1) break;
			// Re-evaluate spare copies and remaining spleen before every batch.
			quote = smmSpendNPCQuote();
			if (!smmSpendNPCBuy(offer, pants, fiveFinger, quote.usable, quote.cash, quote.value)) return false;
		}
	} finally {
		if (!smmSpendDryRun()) {
			if (equipped_item($slot[pants]) != previous && !equip($slot[pants], previous)) print("Spending: could not restore previous pants.", "orange");
			foreach pref, setting in saved set_property(pref, setting);
		}
	}
	return true;
}

// Copies of an item still to acquire to reach the Museum top ten.
int smmSpendTenGap(item it) {
	SmmMuseumGoal goal = smmMuseumGoal(it);
	if (!goal.known) return 0;
	return max(0, goal.tenth - smmMuseumDisplay(it) - smmMuseumStock(it));
}

void smmSpendDeposit(item it) {
 int deposit = smmMuseumDepositAmount(it);
 int before = display_amount(it);
 if (deposit <= 0) return;
 boolean moved = smmMuseumDeposit(it, deposit);
 int confirmed = max(0, display_amount(it) - before);
 if (!moved || confirmed != deposit)
  print("Spending: Display Case transfer for " + it + " confirmed " + confirmed + " of " + deposit, "orange");
 if (confirmed > 0) {
  set_property("_smm.spend.deposited", get_property("_smm.spend.deposited").to_int() + confirmed);
  print("Museum deposit confirmed: " + confirmed + " " + it + ", case now " + display_amount(it), "blue");
 }
}

// Pass 2: Display Case items on sale. Only items with a stored Museum ranking
// are considered (no Museum requests are made here), top-ten gaps before
// first-place gaps.
//
// A sale is often only a few cheap listings, which mall_price() (the fifth
// cheapest) does not show. So each candidate is probed with a real purchase of
// one copy at no more than 80% of its average sale price: the mall fills it
// from the cheapest listing, and what was paid is the true sale price. Items
// with a probe that filled are then bought biggest discount first, to the top
// ten for every item before any is bought toward first place.
void smmSpendMuseumSales() {
	if (!smmMuseumEnabled() || !have_display()) return;

	int [int] shortOfTen;
	int [int] shortOfFirst;
	foreach it in $items[] {
		if (!it.tradeable || !is_displayable(it) || !smmMuseumStored(it)) continue;
		SmmMuseumGoal goal = smmMuseumGoal(it);
		if (!goal.known || smmMuseumMissing(it, goal) < 1) continue;
		if (smmMuseumDisplay(it) + smmMuseumStock(it) < goal.tenth)
			shortOfTen[count(shortOfTen)] = to_int(it);
		else
			shortOfFirst[count(shortOfFirst)] = to_int(it);
	}

	int [int] candidates;
	foreach i, id in smmSpendRotate(shortOfTen, "smm.spend.cursorTen") candidates[count(candidates)] = id;
	int tenCount = count(candidates);
	foreach i, id in smmSpendRotate(shortOfFirst, "smm.spend.cursorFirst") candidates[count(candidates)] = id;
	print("Spending: " + tenCount + " tradeable items short of the top ten, " + (count(candidates) - tenCount) + " short of first place", "blue");

	SmmSpendOffer [int] offers;
	int lookups = 0;
	foreach i, id in candidates {
		if (lookups >= smmSpendMaxLookups() || smmSpendBudget() < 1) break;
		item it = to_item(id);
		lookups += 1;
		set_property(i < tenCount ? "smm.spend.cursorTen" : "smm.spend.cursorFirst", id);

		float average = smmSpendAveragePrice(it);
		if (average <= 0) continue; // no sales on record: the discount is unknown
		if (smmSpendSalesVolume(it) < smmSpendMinSales()) continue; // too few sales to trust the average

		SmmSpendOffer offer;
		offer.it = it;
		offer.average = floor(average);
		offer.limit = floor(average * (1.0 - smmSpendMinDiscount())); // only listings that are themselves 20% under
		if (offer.limit < 1) continue;

		int paid;
		if (smmSpendDryRun()) {
			// nothing is bought in a dry run, so the fifth-cheapest listing stands in for the probe
			paid = mall_price(it);
			if (paid <= 0 || paid > offer.limit) continue;
		} else {
			offer.quantity = 1;
			paid = smmSpendBuy(offer, "probe at 20% or more under its average sale price");
			if (paid < 1) continue; // nothing listed that cheaply
			smmSpendDeposit(it);
		}
		offer.price = paid;
		offer.score = 1.0 - paid / average;
		offers[count(offers)] = offer;
	}

	sort offers by -value.score;
	// round 1: to the top ten
	foreach i, offer in offers {
		offer.quantity = smmSpendTenGap(offer.it);
		if (offer.quantity < 1) continue;
		if (smmSpendBuy(offer, "to the top ten, first copy was " + round(offer.score * 100) + "% under its average sale price") > 0)
			smmSpendDeposit(offer.it);
	}
	// round 2: toward first place
	foreach i, offer in offers {
		offer.quantity = smmMuseumMissing(offer.it, smmMuseumGoal(offer.it));
		if (offer.quantity < 1) continue;
		if (smmSpendBuy(offer, "toward first place, first copy was " + round(offer.score * 100) + "% under its average sale price") > 0)
			smmSpendDeposit(offer.it);
	}
}

// Pass 3: Museum places at no more than the average sale price. What the
// budget still allows after the first two passes goes to the cheapest whole
// gaps: to the top ten for every item before any toward first place, the
// cheapest verified quote first within the bounded lookup pool. Historical
// prices only seed discovery order, never purchase order or affordability.
// Rule 3 holds: nothing is paid above the average sale
// price. Only gaps whose full ceiling cost fits are attempted; limited
// listings can still cause partial fills, which do not establish a place.
// On 2026-11-24 nine such gaps (about 2.5M Meat for nine #1 places) were
// bought by hand after the day was over.
boolean smmSpendRankPassOn() { return get_property("smm.spend.rankPass") != "false"; }

record SmmSpendGap {
	item it;
	int quantity;
	int estimate;
	boolean toTen;
	int limit;
};

// Separate tiers avoid a fixed numeric offset putting a very large top-ten
// gap behind a first-place gap. Quoted costs replace discovery estimates.
SmmSpendGap [int] smmSpendRankOrder(SmmSpendGap [int] gaps, boolean quoted) {
	SmmSpendGap [int] ten;
	SmmSpendGap [int] first;
	foreach i, gap in gaps {
		if (gap.quantity <= 0 || (quoted && gap.limit <= 0)) continue;
		SmmSpendGap ranked; // ASH record assignment aliases the original record
		ranked.it = gap.it;
		ranked.quantity = gap.quantity;
		ranked.estimate = quoted ? gap.quantity * gap.limit : gap.estimate;
		ranked.limit = gap.limit;
		ranked.toTen = gap.toTen;
		if (ranked.toTen) ten[count(ten)] = ranked;
		else first[count(first)] = ranked;
	}
	sort ten by value.estimate;
	sort first by value.estimate;
	SmmSpendGap [int] ordered;
	foreach i, gap in ten ordered[count(ordered)] = gap;
	foreach i, gap in first ordered[count(ordered)] = gap;
	return ordered;
}

// Discovery continues after the last examined item; a bounded quote pool
// cannot silently starve later candidates behind stale or unaffordable ones.
SmmSpendGap [int] smmSpendRankScan(SmmSpendGap [int] gaps, int cursor) {
	int start = 0;
	foreach i, gap in gaps if (gap.it.to_int() == cursor) start = i + 1;
	SmmSpendGap [int] ordered;
	foreach i, gap in gaps if (i >= start) ordered[count(ordered)] = gap;
	foreach i, gap in gaps if (i < start) ordered[count(ordered)] = gap;
	return ordered;
}

boolean smmSpendRankAffordable(SmmSpendGap gap, int budget) {
	return gap.quantity > 0 && gap.limit > 0 && gap.quantity <= max(0, budget) / gap.limit;
}

// A gap whose lookup came to nothing (no sales history, too few sales, nothing
// listed at or under the average) is left for smm.spend.rankRetryDays days
// (default 3), so the same cheap gaps cannot use up every lookup each day
// and keep the rest from ever being looked at. Kept in smm.spend.rankMiss as
// id:day pairs, day counted from the epoch.
string kSmmSpendRankMissKey = "smm.spend.rankMiss";

int smmSpendToday() { return now_to_int() / 86400000; }

int smmSpendRankRetryDays() {
	string explicit = get_property("smm.spend.rankRetryDays");
	return explicit == "" ? 3 : max(1, explicit.to_int());
}

boolean smmSpendRankDue(int missDay, int today, int retryDays) {
	return missDay <= 0 || today - missDay >= retryDays;
}

int [int] smmSpendRankMisses(string stored) {
	int [int] misses;
	foreach i, pair in stored.split_string(",") {
		string [int] parts = pair.split_string(":");
		if (count(parts) == 2 && parts[0].is_integer() && parts[1].is_integer())
			misses[parts[0].to_int()] = parts[1].to_int();
	}
	return misses;
}

// Only misses still inside the retry window are kept.
string smmSpendRankMissString(int [int] misses, int today, int retryDays) {
	string out = "";
	foreach id, day in misses {
		if (smmSpendRankDue(day, today, retryDays)) continue;
		out += (out == "" ? "" : ",") + id + ":" + day;
	}
	return out;
}

void smmSpendMuseumRanks() {
	if (!smmSpendRankPassOn() || !smmMuseumEnabled() || !have_display()) return;
	SmmSpendGap [int] gaps;
	foreach it in $items[] {
		if (!it.tradeable || !is_displayable(it) || !smmMuseumStored(it)) continue;
		SmmMuseumGoal goal = smmMuseumGoal(it);
		if (!goal.known) continue;
		int missing = smmMuseumMissing(it, goal);
		if (missing < 1) continue;
		int price = historical_price(it);
		int toTen = smmSpendTenGap(it);
		SmmSpendGap gap;
		gap.it = it;
		gap.toTen = toTen > 0;
		gap.quantity = toTen > 0 ? toTen : missing;
		gap.estimate = gap.quantity * max(0, price);
		gaps[count(gaps)] = gap;
	}
	gaps = smmSpendRankOrder(gaps, false);
	gaps = smmSpendRankScan(gaps, get_property("smm.spend.rankCursor").to_int());
	print("Spending: " + count(gaps) + " Display Case gaps; quoting at most " + smmSpendMaxLookups() + " before ordering purchases by verified cost", "blue");

	int today = smmSpendToday();
	int retryDays = smmSpendRankRetryDays();
	int [int] misses = smmSpendRankMisses(get_property(kSmmSpendRankMissKey));
	int lookups = 0;
	SmmSpendGap [int] quoted;
	foreach i, gap in gaps {
		int budget = smmSpendBudget();
		if (budget < 1 || lookups >= smmSpendMaxLookups()) break;
		int id = gap.it.to_int();
		if (!smmSpendRankDue(misses[id], today, retryDays)) continue; // looked at lately, came to nothing
		lookups += 1;
		if (!smmSpendDryRun()) set_property("smm.spend.rankCursor", id);
		misses[id] = today; // cleared below when it buys
		float average = smmSpendAveragePrice(gap.it);
		if (average <= 0 || smmSpendSalesVolume(gap.it) < smmSpendMinSales()) continue;
		gap.limit = floor(average);
		quoted[count(quoted)] = gap;
	}
	quoted = smmSpendRankOrder(quoted, true);
	print("Spending: " + count(quoted) + " verified gaps from " + lookups + " quotes; cheapest within each quoted rank tier, not a global optimum", "blue");
	foreach i, gap in quoted {
		int id = gap.it.to_int();
		// Earlier purchases and transfers may have changed both stock and cash.
		gap.quantity = gap.toTen ? smmSpendTenGap(gap.it) : smmMuseumMissing(gap.it, smmMuseumGoal(gap.it));
		if (!smmSpendRankAffordable(gap, smmSpendBudget())) {
			remove misses[id]; // retry when this whole gap becomes affordable
			continue;
		}
		SmmSpendOffer offer;
		offer.it = gap.it;
		offer.average = gap.limit;
		offer.limit = gap.limit; // rule 3: never above the verified average sale price
		offer.quantity = gap.quantity;
		// KoLmafia has no ASH call for how many copies are listed under a price, so
		// a gap can be bought only in part. Those copies still go in the case and
		// shrink the gap; the rest waits the retry window, so it cannot take the
		// budget day after day.
		int held = item_amount(gap.it);
		if (smmSpendBuy(offer, (gap.toTen ? "to the top ten" : "to first place") + " at no more than its average sale price") > 0) {
			if (item_amount(gap.it) - held >= gap.quantity) remove misses[id];
			else print("Spending: only " + (item_amount(gap.it) - held) + " of " + gap.quantity + " " + gap.it + " were listed at or under " + offer.limit + "; the rest waits " + retryDays + " days", "orange");
			smmSpendDeposit(gap.it);
		}
	}
	// a dry run buys nothing, so what it looked at is not a miss
	if (!smmSpendDryRun()) set_property(kSmmSpendRankMissKey, smmSpendRankMissString(misses, today, retryDays));
}

// The whole step. Can run any number of times a day: each run spends only what
// the budget still allows, so a later run picks up Meat netted since the last.
void smmSpendRun() {
	if (!smmSpendEnabled()) {
		print("Spending is off (smm.spend.enabled=false).", "blue");
		return;
	}
	if (!can_interact()) {
		print("Spending: the mall is not available.", "orange");
		return;
	}
	smmSpendDayStart();
	smmSpendReport();
	if (get_property(kSmmSpendNPCPendingKey) != "") {
		print("Spending: interrupted/ambiguous NPC batch; reconcile " + kSmmSpendNPCPendingKey + " before clearing it.", "red");
		return;
	}
	if (smmSpendBudget() > 0) {
		smmSpendPositiveReturn();
		if (smmSpendBudget() > 0 && !smmSpendNPCResale()) {
			smmSpendReport(); smmSpendDayClose(); return;
		}
		if (smmSpendBudget() > 0)
			smmSpendMuseumSales();
		if (smmSpendBudget() > 0)
			smmSpendMuseumRanks();
		smmSpendReport();
	}
	smmSpendDayClose(); // the next day opens from here, so later sales count as its net
}
