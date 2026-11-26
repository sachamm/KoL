// Offline only: deterministic market, form, cash and receipt checks.
import <smmDailyGate.ash>

int checks;
int failures;
void check(boolean ok, string what) {
	checks += 1;
	if (!ok) { failures += 1; print("FAIL: " + what, "red"); }
}

string bucket(int date, int volume) {
	return '{"date":"2026-11-' + date + 'T00:00:00.000Z","volume":' + volume + ',"price":{"__decimal__":"463"}}';
}

string market(string history) {
	return '{"sales":[{"unitPrice":{"__decimal__":"463"}},{"unitPrice":{"__decimal__":"465"}}],"history":[' + history + ']}';
}

void testMarket() {
	int today = date_to_timestamp("yyyy-MM-ddX", "2026-11-26Z") / 86400000;
	string history;
	for day from 12 to 25 history += (history == "" ? "" : ",") + bucket(day, 1);
	SmmNRMarket result = smmNRMarketFrom(market(history), 470, today);
	check(result.valid && result.volume == 14 && result.activeDays == 14, "fourteen complete dates at one sale a day");
	check(result.price == 464, "conservative recent sale median");
	check(smmNRMarketFrom(market(history), 460, today).price == 460, "never above time-weighted sale average");
	check(smmNRStockGap(result.volume, 365, 0) == 365, "one per day permits exactly 365");
	check(smmNRStockGap(result.volume, 365, 65) == 300, "subtract existing inventory, closet, storage and shop copies");
	check(smmNRStockGap(result.volume, 999, 0) == 365, "buffer cannot exceed a year");
	check(smmNRStockGap(result.volume, 30, 0) == 30, "shorter configurable horizon");
	check(smmNRStockGap(1, 365, 0) == 26, "missing dates count as zero and quantities round down");
	check(smmNRStockGap(14, 365, 366) == 0 && smmNRStockGap(14, 0, 0) == 0, "no restock above ceiling or with zero horizon");
	check(smmNRMarketFrom(market(history + "," + bucket(26, 100000)), 470, today).volume == 14, "exclude today's partial whale bucket");
	check(!smmNRMarketFrom(market(history + "," + bucket(25, 1)), 470, today).valid, "duplicate date is rejected");
	check(!smmNRMarketFrom(market(bucket(23, 1) + "," + bucket(24, 1) + "," + bucket(25, 100)), 470, today).valid, "single-day volume spike is rejected");
	check(!smmNRMarketFrom(market(bucket(24, 1) + "," + bucket(25, 1)), 470, today).valid, "require three selling dates");
	check(!smmNRMarketFrom(market(history), 0, today).valid, "unknown average is rejected");
	check(!smmNRMarketFrom(market(history), 470, today + 30).valid, "stale window is rejected");
	check(!smmNRMarketFrom('{"sales":[],"history":[]}', 470, today).valid, "empty sales are rejected");
}

void testPlans() {
	check(smmNRUnitCost(150, false, true) == 127, "combined discount rounds down");
	check(smmNRUnitCost(1000, false, false) == 950, "pants remain worn without jelly");
	check(smmNRUnitCost(1000, true, true) == 800, "Five Finger Discount stacks once");
	SmmNRBatch bowls = smmNRPlan(365, 1000000, 500, 463, false, true, 2500, 11000);
	check(bowls.jelly && bowls.quantity == 365 && bowls.unitCost == 425 && bowls.profit == 2870, "Bowls can profit with a year-sized batch after jelly and spleen");
	check(bowls.worstCost == 365 * 475 + 2500, "cash reserves pants-only full cost plus jelly");
	check(smmNRPlan(365, 100000, 500, 463, false, true, 2500, 11000).quantity == 0, "insufficient batch margin skips Bowls");
	SmmNRBatch msg = smmNRPlan(10000, 97500, 1000, 1000, false, true, 2500, 2500);
	check(msg.jelly && msg.quantity == 100 && msg.worstCost == 97500 && msg.profit == 12500, "MSG batch sized by remaining cash including jelly");
	check(smmNRPlan(10, 100000, 1000, 1000, false, true, 2500, 11000).jelly == false, "small profitable pants-only batch does not waste jelly");
	check(smmNRPlan(10, 950, 1000, 1000, false, false, 0, 0).quantity == 1, "budget shrinks quantity at execution");
	check(smmNRPlan(10, 949, 1000, 1000, false, false, 0, 0).quantity == 0, "not even one copy fits");
	check(smmNRPlan(10, 100000, 1000, 800, false, true, 0, 0).quantity == 0, "unprofitable items skipped");
	check(smmNRPlan(0, 100000, 1000, 1000, false, true, 0, 0).quantity == 0, "no annual stock gap");
	check(smmNRPlan(10, 0, 1000, 1000, false, true, 0, 0).quantity == 0, "zero daily budget");
	check(!smmNRPlan(100, 100000, 1000, 1000, false, false, 2500, 2500).jelly, "full spleen or unavailable jelly leaves pants-only plan");
}

void testVendor() {
	SmmNRVendor vendor = smmNRVendorLine("Madeline's Baking Supply\tmadeline\tGnollish pie tin\t25\tROW736");
	check(vendor.it == $item[Gnollish pie tin] && vendor.row == 736 && vendor.base == 25, "parse current Mafia NPC catalog row");
	check(smmNRVendorLine("closed\tcrimbo23\tMSG\t1\tROW532").it == $item[none], "closed/unsupported shop excluded");
	check(smmNRVendorLine("limited\tgeneralstore\tMSG\t1000\tROW532\t1").it == $item[none], "quantity-limited offer excluded");
	string html = '<tr rel="158"><td></td><td><img onclick="descitem(1)"></td><td><a onclick="descitem(1)">pie tin</a></td><td><img src="itemimages/meat.gif" title="Meat"></td><td><b>23</b></td><td><input class="button doit multibuy" rel="shop.php?whichshop=madeline&action=buyitem&quantity=1&whichrow=736&pwd=TEST" value="Buy"></td></tr>';
	check(smmNRVisiblePrice(html, vendor) == 23, "visible Meat-only bulk row validated");
	check(smmNRVisiblePrice(replace_string(html, "rel=\"158\"", "rel=\"1580\""), vendor) == 0, "item ID prefix is not the item");
	check(smmNRVisiblePrice(replace_string(html, "whichrow=736&", "whichrow=7360&"), vendor) == 0, "wrong row rejected");
	check(smmNRVisiblePrice(replace_string(html, "whichshop=madeline&", "whichshop=gnoll&"), vendor) == 0, "wrong vendor rejected");
	check(smmNRVisiblePrice(replace_string(html, "multibuy", "disabled multibuy"), vendor) == 0, "disabled vendor row rejected");
	check(smmNRVisiblePrice(replace_string(html, "multibuy", "single"), vendor) == 0, "must support one bulk request");
	check(smmNRVisiblePrice(replace_string(html, "</b></td><td><input", "</b></td><td><a onclick='descitem(2)'>currency</a><input"), vendor) == 0, "additional currency rejected");
	check(smmNRVisiblePrice(replace_string(html, '<td><img src="itemimages/meat.gif"', '<td><a onclick="descitem(2)">currency</a></td><td><img src="itemimages/meat.gif"'), vendor) == 0, "currency before Meat rejected too");
	check(smmNRVisiblePrice("", vendor) == 0, "unavailable vendor fails closed");
	check(smmNRPurchaseURL(vendor, 365) == "shop.php?whichshop=madeline&action=buyitem&whichrow=736&quantity=365&ajax=1", "one direct bulk NPC POST without mall fallback");
}

void testReceiptsAndLedger() {
	check(smmNRJellyConfirmed(true, 2, 1, 5, 6), "jelly confirmed by both item and spleen changes");
	check(!smmNRJellyConfirmed(false, 2, 1, 5, 6), "failed chew cannot trigger purchase");
	check(!smmNRJellyConfirmed(true, 2, 2, 5, 6) && !smmNRJellyConfirmed(true, 2, 1, 5, 5), "ambiguous chew cannot trigger purchase");
	check(smmNRReceiptOK(100, 100, 85000, 850), "exact discounted receipt accepted");
	check(!smmNRReceiptOK(100, 99, 84150, 850), "partial purchase stops further spending");
	check(!smmNRReceiptOK(100, 100, 95000, 850), "missing jelly discount stops further spending");
	string log = "noise\nbuy 100 MSG for 950 each from Gouda's Grimoire and Grocery\nYou spent 85000 Meat\nbuy 1 sleaze jelly for 2,500 each from shop #1 on 20261126\n";
	check(smmNRLoggedPurchases(log) == 97500, "logged price sum includes NPC pants-only quote and jelly");
	check(smmNRLoggedPurchases(log) == smmDPurchaseTotal(smmDParsePurchases(log)), "same log arithmetic as the daily gate");
	int accounted = smmSpendLoggedSpentFrom(87500, 10000);
	check(accounted == 97500, "actual paid is kept separate from log charge");
	check(smmDOperatingFrom(97500 + 5000, accounted, 0) == 5000, "jelly log discrepancy is not phantom operating spend");
	check(smmSpendAllowance(1000000, 87500, 5000, 0.5) == 407500, "daily allowance charges actual cash exactly once");
	check(smmSpendLoggedSpentFrom(87500, -5000) == 82500, "signed adjustment also supports unlogged charges");
}

void main() {
	testMarket(); testPlans(); testVendor(); testReceiptsAndLedger();
	if (failures > 0) abort("FAIL smmNpcResaleTest: " + failures + " / " + checks);
	print("PASS smmNpcResaleTest: " + checks + " checks", "green");
}
