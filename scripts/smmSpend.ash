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

string kSmmSpendStartKey = "_smm.spend.startMeat";   // cleared at rollover
string kSmmSpendSpentKey = "_smm.spend.spent";       // cleared at rollover
string kSmmSpendBuyMapFile = "unrestricted_buy_map.txt";

record SmmSpendOffer {
	item it;
	int quantity;    // copies wanted
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
// first call of the day (the property is cleared at rollover) takes the snapshot.
void smmSpendDayStart() {
	if (get_property(kSmmSpendStartKey) == "")
		set_property(kSmmSpendStartKey, smmSpendLiquidMeat());
}

boolean smmSpendStarted() { return get_property(kSmmSpendStartKey) != ""; }

int smmSpendSpent() { return get_property(kSmmSpendSpentKey).to_int(); }

// Meat netted today by everything except this script's own purchases.
int smmSpendNet() {
	if (!smmSpendStarted()) return 0;
	return smmSpendLiquidMeat() + smmSpendSpent() - get_property(kSmmSpendStartKey).to_int();
}

// Meat still allowed to be spent today: half the day's net, less what is spent.
// Never more than the Meat on hand, and nothing on a losing day.
int smmSpendBudget() {
	int allowed = floor(max(0, smmSpendNet()) * smmSpendFraction());
	return max(0, min(allowed - smmSpendSpent(), my_meat()));
}

void smmSpendReport() {
	if (!smmSpendStarted()) {
		print("Spending: no opening Meat recorded today, so the budget is 0.", "orange");
		return;
	}
	print("Spending: opened at " + get_property(kSmmSpendStartKey) + " Meat, netted " + smmSpendNet()
		+ ", spent " + smmSpendSpent() + ", still allowed " + smmSpendBudget(), "blue");
}

// ---------------------------------------------------------------------------
// Market price: the recent average sale price.

float [item] smmSpendAverages;
int smmSpendLookups;

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
		smmSpendAverages[it] = smmSpendParseAverage(it, response);
	}
	return smmSpendAverages[it];
}

// ---------------------------------------------------------------------------
// Buying

// Buys up to offer.quantity at no more than offer.limit each, within the
// remaining budget. Returns the Meat actually spent, measured, not estimated.
int smmSpendBuy(SmmSpendOffer offer, string reason) {
	int budget = smmSpendBudget();
	if (offer.price <= 0 || offer.limit < offer.price) return 0;
	int quantity = min(offer.quantity, budget / offer.price);
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

		// rule 3: never above the average sale price. With no sales on record,
		// pay no more than the current listing.
		float average = smmSpendAveragePrice(it);
		int limit = average > 0 ? min(worth, floor(average)) : min(worth, price);
		if (limit < price) continue;

		SmmSpendOffer offer;
		offer.it = it;
		offer.quantity = wanted;
		offer.price = price;
		offer.limit = limit;
		offer.score = (worth - price) / to_float(price);
		offers[count(offers)] = offer;
	}

	sort offers by -value.score;
	foreach i, offer in offers {
		if (smmSpendBudget() < offer.price) continue;
		smmSpendBuy(offer, "worth " + round(offer.score * 100) + "% more than its price");
	}
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

// Pass 2: Display Case items on sale. Only items with a stored Museum ranking
// are considered (no Museum requests are made here), top-ten gaps before
// first-place gaps. An item qualifies when its mall price is 20% or more under
// its average sale price. Biggest discount first.
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
		if (lookups >= smmSpendMaxLookups()) break;
		item it = to_item(id);
		lookups += 1;
		set_property(i < tenCount ? "smm.spend.cursorTen" : "smm.spend.cursorFirst", id);

		float average = smmSpendAveragePrice(it);
		if (average <= 0) continue; // no sales on record: the discount is unknown
		int price = mall_price(it);
		if (price <= 0) continue;
		float discount = 1.0 - price / average;
		if (discount < smmSpendMinDiscount()) continue;

		SmmSpendOffer offer;
		offer.it = it;
		offer.quantity = smmMuseumMissing(it, smmMuseumGoal(it));
		offer.price = price;
		offer.limit = floor(average * (1.0 - smmSpendMinDiscount())); // only listings that are themselves 20% under
		offer.score = discount;
		offers[count(offers)] = offer;
	}

	sort offers by -value.score;
	foreach i, offer in offers {
		if (smmSpendBudget() < offer.price) continue;
		if (smmSpendBuy(offer, round(offer.score * 100) + "% under its average sale price") < 1) continue;
		int deposit = smmMuseumDepositAmount(offer.it);
		if (deposit > 0 && !smmMuseumDeposit(offer.it, deposit))
			print("Spending: could not add " + offer.it + " to the Display Case, the copies stay in inventory", "orange");
	}
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
	smmSpendReport();
	if (smmSpendBudget() < 1) return;
	smmSpendPositiveReturn();
	if (smmSpendBudget() > 0)
		smmSpendMuseumSales();
	smmSpendReport();
}
