// Bridge for cooperative third-party buys, including finished-item deficits in
// explicit retrieval calls. Implicit sourcing, crafting, direct URLs and
// delegated scripts still require the closing purchase audit.
import <smmDailyCore.ash>
import <smmSpend.ash>
import <smmDailyPolicy.ash>

record SmmGuardOffer { int quantity; int limit; };
SmmGuardOffer smmGuardOfferFor(int quantity, int requested, float average, int budget) {
 SmmGuardOffer offer;
 offer.limit = smmDailyPurchaseLimit(requested > 0 ? requested : floor(average), average);
 if (offer.limit > 0) offer.quantity = min(max(0, quantity), max(0, budget) / offer.limit);
 return offer;
}

string smmGuardEpoch;
void smmGuardReady() {
 if (smmGuardEpoch == "") smmGuardEpoch = smmDEpoch();
 smmDRequireEpoch(smmGuardEpoch);
 smmDRequireActiveDay();
 if (smmDGet("smm.daily.active") == "" || my_id().to_int() <= 0)
  abort("smmDaily: guarded garbo requires a logged-in active daily run");
 if (!smmSpendStarted()) abort("smmDaily: guarded garbo requires today's opening ledger");
 if (count(session_logs(1)) == 0) abort("smmDaily: guarded garbo requires the purchase log before buying");
}

int smmGuardBuy(int quantity, item it, int requested) {
 smmGuardReady();
 float average = smmSpendAveragePrice(it);
 SmmGuardOffer offer = smmGuardOfferFor(quantity, requested, average, smmSpendBudget());
 if (offer.quantity <= 0) {
  print("smmDaily: direct garbo buy held for " + it + "; no verified price or shared allowance", "orange");
  return 0;
 }
 smmGuardReady(); // quote and ledger refresh may have made requests
 int operating = smmSpendOperating();
 int cash = my_meat();
 int bought = buy(offer.quantity, it, offer.limit);
 smmDRequireEpoch(smmGuardEpoch);
 // Charge observed cash immediately; the later log refresh takes max(), so it
 // does not charge these direct buys twice. Native request logs remain evidence.
 set_property(kSmmSpendOperatingKey, max(smmSpendOperating(), operating + max(0, cash - my_meat())));
 return bought;
}

// A paid access refusal must not prevent garbo's separate daily work. This
// forecast never authorizes a purchase: actual retrieval keeps the same guard.
string smmGuardBarfHold(boolean access, int owned, float average, int quote, int budget) {
 if (access || owned > 0) return "";
 SmmGuardOffer offer = smmGuardOfferFor(1, 500000, average, budget);
 if (offer.quantity < 1) return "Dinsey ticket has no verified price or shared allowance";
 if (quote <= 0) return "Dinsey ticket has no current mall quote";
 if (quote > offer.limit) return "Dinsey ticket quote " + quote + " exceeds the existing ceiling " + offer.limit;
 return "";
}

string smmGuardBarfHold() {
 smmGuardReady();
 if (get_property("stenchAirportAlways") == "true" || get_property("_stenchAirportToday") == "true") return "";
 item ticket = $item[one-day ticket to Dinseylandfill];
 if (available_amount(ticket) > 0) return "";
 float average = smmSpendAveragePrice(ticket);
 int quote = mall_price(ticket);
 string reason = smmGuardBarfHold(false, 0, average, quote, smmSpendBudget());
 smmGuardReady();
 return reason;
}

int smmGuardConsumptionMissing(int quantity, int owned, int reserved) {
 return max(0, max(0, quantity) - max(0, owned - max(0, reserved)));
}

boolean smmGuardInputAvailable(int quantity, int accessible, int owned, int reserved, int requested, float average, int quote, int budget, boolean buying) {
 int missing = max(max(0, quantity - max(0, accessible)), smmGuardConsumptionMissing(quantity, owned, reserved));
 if (missing == 0) return true;
 if (!buying || quote <= 0) return false;
 SmmGuardOffer offer = smmGuardOfferFor(missing, requested, average, budget);
 return offer.quantity == missing && quote <= offer.limit;
}

boolean smmGuardStealHoldReported;
boolean smmGuardItemStealEligible(location where) {
 smmGuardReady();
 if (where != $location[The Stately Pleasure Dome] || have_effect($effect[Absinthe-Minded]) > 0) return true;
 item input = $item[tiny bottle of absinthe];
 int accessible = available_amount(input);
 int owned = smmMuseumOwnedCopies(input);
 int reserved = smmMuseumReservedCopies(input);
 smmGuardReady();
 if (smmGuardInputAvailable(1, accessible, owned, reserved, 0, 0, 0, 0, false)) return true;
 float average = smmSpendAveragePrice(input);
 int quote = mall_price(input);
 // The inspected upstream prerequisite requests at most twice the current
 // quote; the real buy still enforces both that ceiling and the average.
 int requested = min(2000000000.0, max(0.0, quote * 2.0)).to_int();
 boolean eligible = smmGuardInputAvailable(1, accessible, owned, reserved, requested, average, quote, smmSpendBudget(),
  get_property("autoSatisfyWithMall") == "true" && get_property("autoSatisfyWithNPCs") == "true");
 smmGuardReady();
 if (!eligible && !smmGuardStealHoldReported) {
  print("smmDaily: item-steal route held at " + where + "; absinthe cannot be supplied within the price/shared cap while preserving Museum copies; selecting another eligible route", "orange");
  smmGuardStealHoldReported = true;
 }
 return eligible;
}

boolean smmGuardGardenHoldReported;
boolean smmGuardBlackRoseEligible() {
 smmGuardReady();
 item seed = $item[black garden rose];
 int [item] camp = get_campground();
 if ((camp contains seed) || get_property("_garbo_blackRoseFightsDone") == "true") return true;
 int accessible = available_amount(seed);
 int owned = smmMuseumOwnedCopies(seed);
 int reserved = smmMuseumReservedCopies(seed);
 smmGuardReady();
 if (seed.reusable) reserved = 0;
 boolean eligible = smmGuardInputAvailable(1, accessible, owned, reserved, 0, 0, 0, 0, false);
 int configured = get_property("autoBuyPriceLimit").to_int();
 boolean buying = seed.tradeable && configured >= 0 && get_property("autoSatisfyWithMall") == "true" && get_property("autoSatisfyWithNPCs") == "true";
 if (!eligible && buying) {
  float average = smmSpendAveragePrice(seed);
  int quote = mall_price(seed);
  eligible = smmGuardInputAvailable(1, accessible, owned, reserved, configured == 0 ? 20000 : configured, average, quote, smmSpendBudget(), true);
 }
 smmGuardReady();
 if (!eligible && !smmGuardGardenHoldReported) {
  print("smmDaily: Black Rose Garden fights held: no usable seed within Museum, price and allowance rules; other daily work can continue", "orange");
  smmGuardGardenHoldReported = true;
 }
 return eligible;
}

int smmGuardConsumptionQuantity(int quantity, item it, boolean usingItem) {
 return usingItem && it.reusable ? min(1, max(0, quantity)) : max(0, quantity);
}

// Freeze the reserve before acquiring replacement copies. Recomputing an
// unknown-rank reserve after buying would reserve the replacements as well.
boolean smmGuardConsume(int quantity, item it, boolean usingItem) {
 smmGuardReady();
 if (quantity <= 0 || it == $item[none] || (usingItem && it.reusable)) return true;
 int reserved = smmMuseumReservedCopies(it);
 smmGuardReady();
 if (reserved <= 0) return true; // ordinary finished-item retrieval handles acquisition
 int missing = smmGuardConsumptionMissing(quantity, smmMuseumOwnedCopies(it), reserved);
 if (missing > 0 && it.tradeable && get_property("autoSatisfyWithMall") == "true" && get_property("autoSatisfyWithNPCs") == "true") {
  int limit = get_property("autoBuyPriceLimit").to_int();
  if (limit >= 0) smmGuardBuy(missing, it, limit == 0 ? 20000 : limit);
 }
 smmGuardReady();
 if (smmGuardConsumptionMissing(quantity, smmMuseumOwnedCopies(it), reserved) == 0) return true;
 print("smmDaily: garbo consumption held for " + it + "; preserving " + reserved + " Museum copies", "orange");
 return false;
}
