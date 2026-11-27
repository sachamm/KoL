import <smmDailyBuyGuard.ash>
int checks;
int failures;
void check(boolean ok, string why) { checks += 1; if (!ok) { failures += 1; print("FAIL guarded buy observation: " + why); } }
void offer(int quantity, int requested, float average, int budget, int wantQty, int wantLimit) {
 SmmGuardOffer got = smmGuardOfferFor(quantity, requested, average, budget);
 checks += 1;
 if (got.quantity != wantQty || got.limit != wantLimit) {
  failures += 1;
  print("FAIL guarded offer " + quantity + "/" + requested + "/" + average + "/" + budget);
 }
}
void main() {
 offer(10, 0, 100.9, 1000, 10, 100);
 offer(10, 200, 100.9, 1000, 10, 100);
 offer(10, 80, 100.9, 1000, 10, 80);
 offer(10, 100, 100.9, 250, 2, 100);
 offer(10, 100, 100.9, 99, 0, 100);
 offer(10, 100, 100.9, -1, 0, 100);
 offer(10, 100, 0, 1000, 0, 0);
 offer(10, 100, -2, 1000, 0, 0);
 offer(10, 100, 0.9, 1000, 0, 0);
 offer(0, 100, 100, 1000, 0, 100);
 offer(-1, 100, 100, 1000, 0, 100);
 offer(1, -1, 100, 1000, 1, 100);
 item it = $item[seal tooth];
 clear(smmGuardDeniedBuys);
 check(smmGuardMayTryBuy(it, 100), "a new worker can assess its first offer");
 smmGuardBuyObserved(it, 0, 100);
 check(!smmGuardMayTryBuy(it, 100) && !smmGuardMayTryBuy(it, 50), "a confirmed no-fill excludes the same or lower ceiling");
 check(smmGuardMayTryBuy(it, 101), "a different higher guarded ceiling can be assessed");
 check(smmGuardMayTryBuy($item[seal-clubbing club], 100), "a denial is item-specific");
 smmGuardBuyObserved(it, 0, 200);
 check(!smmGuardMayTryBuy(it, 150) && smmGuardMayTryBuy(it, 201), "the strongest observed denied ceiling is retained");
 smmGuardBuyObserved(it, 1, 150);
 check(smmGuardMayTryBuy(it, 100), "a real later fill replaces stale denial evidence");
 smmGuardBuyObserved(it, 0, 0);
 check(!(smmGuardDeniedBuys contains it) && !smmGuardMayTryBuy(it, 0), "no positive proposal is invented from a zero ceiling");
 smmGuardBuyObserved(it, 0, 200); clear(smmGuardDeniedBuys);
 check(smmGuardMayTryBuy(it, 100), "worker-local reset leaves game counters out of this state");
 if (failures == 0) print("PASS smmDailyBuyGuardTest: " + checks + " checks");
 else print("FAILED smmDailyBuyGuardTest: " + failures + " of " + checks);
}
