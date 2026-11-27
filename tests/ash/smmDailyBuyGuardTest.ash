import <smmDailyBuyGuard.ash>
int checks;
int failures;
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
 if (failures == 0) print("PASS smmDailyBuyGuardTest: " + checks + " checks");
 else print("FAILED smmDailyBuyGuardTest: " + failures + " of " + checks);
}
