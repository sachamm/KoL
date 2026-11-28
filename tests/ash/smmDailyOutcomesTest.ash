import <smmDailyGarboEvidence.ash>
int checks; int failures;
void check(boolean ok, string why) { checks += 1; if (!ok) { failures += 1; print("FAIL outcomes: " + why); } }
void manualBooking() {
 int oldOffset=smmSpendLogOffset; int oldPurchases=smmSpendLogPurchases;
 boolean oldVerified=smmSpendOperatingVerified;
 try {
  smmSpendOperatingTestMode=true; smmSpendOperatingTestPlayer=123; smmSpendOperatingTestHasLog=true;
  clear(smmSpendOperatingTestProperties);
  smmSpendOperatingTestProperties[kSmmSpendStartKey]="1000";
  smmSpendOperatingTestProperties[kSmmSpendSpentKey]="20";
  smmSpendOperatingTestProperties[kSmmSpendOperatingKey]="0";
  smmSpendOperatingTestProperties[kSmmSpendLogAdjustmentKey]="0";
  smmSpendOperatingTestProperties["_smm.diet.bought"]="30";
  smmSpendOperatingTestProperties["smm.daily.active"]="";
  smmSpendLogOffset=0; smmSpendLogPurchases=0;
  smmSpendOperatingTestLog="buy 2 seal tooth for 100 each from shop #42 on 20261127\n";
  smmSpendRefreshOperating();
  check(smmSpendOperatingProperty(kSmmSpendOperatingKey).to_int()==150 && smmSpendOperatingVerified,"standalone manual context books other purchases after own/diet charges");
  smmSpendRefreshOperating();
  check(smmSpendOperatingProperty(kSmmSpendOperatingKey).to_int()==150,"unchanged log cannot charge the purchases twice");
  smmSpendOperatingTestLog+="buy 1 spices for 50 each from shop #43 on 20261127\n";
  smmSpendRefreshOperating();
  check(smmSpendOperatingProperty(kSmmSpendOperatingKey).to_int()==200,"later manual purchases reduce the next standalone allowance");
  check(smmSpendAllowance(1000,20,smmSpendOperatingProperty(kSmmSpendOperatingKey).to_int(),30,0.5)==250,"updated operating spend enters the actual shared-cap arithmetic");
  smmSpendOperatingTestLog=""; smmSpendRefreshOperating();
  check(smmSpendOperatingProperty(kSmmSpendOperatingKey).to_int()==200,"truncated log cannot release already booked commitments");
  smmSpendOperatingTestPlayer=0; smmSpendOperatingTestLog="buy 9 spices for 100 each from shop #43 on 20261127\n";
  smmSpendRefreshOperating();
  check(smmSpendOperatingProperty(kSmmSpendOperatingKey).to_int()==200 && !smmSpendOperatingVerified,"logged-out context cannot book or authorize allowance");
  smmSpendOperatingTestPlayer=123; smmSpendOperatingTestProperties[kSmmSpendStartKey]=""; smmSpendRefreshOperating();
  check(smmSpendOperatingProperty(kSmmSpendOperatingKey).to_int()==200 && !smmSpendOperatingVerified,"missing opening ledger cannot authorize allowance");
  smmSpendOperatingTestProperties[kSmmSpendStartKey]="1000"; smmSpendOperatingTestHasLog=false; smmSpendRefreshOperating();
  check(smmSpendOperatingProperty(kSmmSpendOperatingKey).to_int()==200 && !smmSpendOperatingVerified,"missing session log preserves commitments but withholds allowance");
 } finally {
  clear(smmSpendOperatingTestProperties);
  smmSpendOperatingTestMode=false; smmSpendOperatingTestPlayer=0; smmSpendOperatingTestHasLog=true; smmSpendOperatingTestLog="";
  smmSpendLogOffset=oldOffset; smmSpendLogPurchases=oldPurchases; smmSpendOperatingVerified=oldVerified;
 }
}
void main() {
 manualBooking();
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
 check(smmDailySourceUnavailable(false,0,10),"absent source needs no preparation");
 check(smmDailySourceUnavailable(true,10,10),"exhausted spinner needs no preparation");
 check(smmDailySourceUnavailable(true,11,10),"over-limit spinner cannot become available");
 check(!smmDailySourceUnavailable(true,9,10),"remaining spinner minute can still fund a historical fight");
 check(smmDailySourceUnavailable(true,3,3),"exhausted locket needs no preparation");
 check(!smmDailySourceUnavailable(true,2,3),"remaining locket charge retains preparation");
 check(!smmDailySourceUnavailable(true,0,0),"unknown limit is not claimed exhausted");
 check(!smmDailySourceUnavailable(true,-1,10),"negative counter is not claimed exhausted");
 check(smmDailyCanReconcileGarbo("garbo","old access hold",true,10),"completed standard native run and real access supersede an old access hold");
 check(smmDailyCanReconcileGarbo("garbo -10","hold",true,10),"matching standard stop point can reconcile");
 check(smmDailyCanReconcileGarbo("garbo -0","hold",true,10),"stricter completed stop point can reconcile");
 check(!smmDailyCanReconcileGarbo("garbo -11","hold",true,10),"leaving more turns cannot satisfy the configured stop point");
 check(!smmDailyCanReconcileGarbo("garbo -10 nobarf","hold",true,10),"partial daily-only completion cannot reconcile");
 check(!smmDailyCanReconcileGarbo("garbo farmingmethod=copperhead","hold",true,10),"custom strategy cannot silently clear automatic hold");
 check(!smmDailyCanReconcileGarbo("garbo","hold",false,10),"native completion without actual access is insufficient");
 check(!smmDailyCanReconcileGarbo("garbo","",true,10),"an absent hold needs no reconciliation");
 check(!smmDailyCanReconcileGarbo("unknown","hold",true,10),"unknown completion signature cannot reconcile");
 check(!smmDailyCanReconcileGarbo("garbo","hold",true,-1),"invalid configured stop point cannot reconcile");
 check(smmDailyDaycareBudget(0,0,20)==0,"unpriced paid Daycare investment is opt-in");
 check(smmDailyDaycareBudget(-1,0,20)==0,"negative Daycare allocation cannot spend turns");
 check(smmDailyDaycareBudget(100,0,20)==3,"explicit Daycare investment retains the original three-turn ceiling");
 check(smmDailyDaycareBudget(3,2,20)==1,"earlier observed paid use reduces the day's remaining allocation");
 check(smmDailyDaycareBudget(3,0,2)==2,"allocation cannot exceed available adventures");
 check(smmDailyDaycareBudget(3,4,20)==0,"already-exceeded allocation cannot authorize another use");
 print((failures==0 ? "PASS" : "FAILED") + " smmDailyOutcomesTest: " + checks + " checks");
}
