import <smmDailyGarboEvidence.ash>
int checks; int failures;
void check(boolean ok, string why) { checks += 1; if (!ok) { failures += 1; print("FAIL outcomes: " + why); } }
void main() {
 check(smmDailyVerifiedRank(true,100,100,25,25,1)==1,"fresh matching first place");
 check(smmDailyVerifiedRank(true,101,100,25,25,10)==10,"fresh matching top ten");
 check(smmDailyVerifiedRank(false,101,100,25,25,1)==0,"failed refresh cannot use old row");
 check(smmDailyVerifiedRank(true,99,100,25,25,1)==0,"old timestamp cannot verify current place");
 check(smmDailyVerifiedRank(true,101,100,25,24,1)==0,"fresh page with delayed case count is unverified");
 check(smmDailyVerifiedRank(true,101,100,25,25,0)==0,"absent player row is unverified");
 check(smmDailyVerifiedRank(true,101,100,0,0,1)==0,"empty case does not establish a place");
 check(smmDailyCraftMethod("Cooking",3,0,0),"ordinary cooking needs no paid turn");
 check(smmDailyCraftMethod("Mixing",3,0,0),"ordinary mixing needs no paid turn");
 check(smmDailyCraftMethod("Cooking (fancy)",2,2,0),"free cooking covers the requested batch");
 check(!smmDailyCraftMethod("Cooking (fancy)",3,2,100),"mixes cannot fund cooking");
 check(smmDailyCraftMethod("Mixing (fancy)",2,0,2),"free mixing covers the requested batch");
 check(!smmDailyCraftMethod("Mixing (fancy)",3,100,2),"cooks cannot fund mixing");
 check(!smmDailyCraftMethod("Coin Master purchase",1,100,100),"unpriced currency conversion held");
 check(!smmDailyCraftMethod("Meatpasting",1,100,100),"unmodeled paste fee held");
 check(!smmDailyCraftMethod("Cooking, unknown requirement",1,100,100),"changed method metadata held");
 check(!smmDailyCraftMethod("Cooking",0,100,100),"invalid batch held");
 check(smmDailyCraftPurchaseLimit(2,200.9,1000)==100,"finished substitute cannot exceed ingredient opportunity cost per copy");
 check(smmDailyCraftPurchaseLimit(2,2000,50)==50,"configured buy ceiling stays tighter");
 check(smmDailyCraftPurchaseLimit(1,0,100)==0 && smmDailyCraftPurchaseLimit(0,200,100)==0,"unknown ingredient value and invalid quantity cannot buy");
 check(smmDailyCraftPurchaseLimit(1,200,0)==0,"normalized zero never becomes a default allowance");
 item worthless=$item[worthless trinket];
 check(!worthless.tradeable && dailyGrindItemValueFrom(false,999999999999,999999999999,autosell_price(worthless))==autosell_price(worthless),"untradeable sentinel cannot become proceeds");
 check(smmDailyLiquidValue(5,1000,2,999999999999,0)==0,"saturated backlog has no nominal quote premium");
 check(kDailyGrindNames contains "garbo.paid" && kDailyGrindNames contains "garbo.free" && kDailyGrindNames contains "garbo.copy","phase histories stay separate");
 check(smmGuardUsePreservesItem($item[seal tooth]),"native combat-reusable flag also preserves permanent tools");
 print((failures==0 ? "PASS" : "FAILED") + " smmDailyOutcomesTest: " + checks + " checks");
}
