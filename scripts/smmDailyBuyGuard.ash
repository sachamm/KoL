// Bridge for cooperative third-party direct buys. Automatic retrieval, crafting,
// direct URLs and delegated scripts still require the closing purchase audit.
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
