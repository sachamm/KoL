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

int smmGuardConsumptionMissing(int quantity, int owned, int reserved) {
 return max(0, max(0, quantity) - max(0, owned - max(0, reserved)));
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
