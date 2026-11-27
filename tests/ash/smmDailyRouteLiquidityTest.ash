import <smmIotmRoute.ash>
int checks;
int failures;
void check(boolean ok, string why) { checks += 1; if (!ok) { failures += 1; print("FAIL: " + why); } }
void equal(float got, float want, string why) { check(smmIRSame(got,want),why+": got "+got+", expected "+want); }
void seed(item it, int stock) {
 smmIRPrices[it]=1000; smmIRReplacementPrices[it]=1500;
 SmmNRMarket market; market.valid=true; market.price=800; market.volume=1400; market.activeDays=10;
 smmIRMarkets[it]=market; smmIRTestStock[it]=stock;
 SmmMuseumGoal goal; goal.known=true;
 smmMuseumGoals[it]=goal; smmMuseumKeeps[it]=0;
}
void main() {
 smmIRMarketTestMode=true;
 item it=$item[seal tooth]; int floorValue=max(0,autosell_price(it));
 seed(it,68);
 equal(smmIRSaleCapacity(it),70,"same seven-day, ten-percent completed-sale capacity as grind accounting");
 equal(smmIRSurplusValue(it,3),1600+floorValue,"only two new copies get the market premium");
 equal(smmIRRewardValue(it,3),1600+floorValue,"met Museum goal does not add retained value");
 check(smmIRGainRun(it,10)==2,"production batch stops at the market tier boundary");
 equal(smmIRSurplusValue(it,0),0,"zero quantity has no sale value");
 equal(smmIRRewardValue(it,-2),0,"negative reward quantity is not income");
 float input=smmIRInputValue(it,1);
 smmIRTestStock[it]=70000;
 equal(smmIRSurplusValue(it,10),10*floorValue,"large existing stock removes the premium");
 equal(smmIRInputValue(it,1),input,"illiquid outputs never cheapen consumed input opportunity cost");
 equal(smmIRSaleValue(it),1000,"the input quote remains separate from marginal output value");
 SmmMuseumGoal need; need.known=true; need.first=3; need.first_minimum=1; need.tenth=1;
 smmMuseumGoals[it]=need;
 equal(smmIRRewardValue(it,5),4500+2*floorValue,"three retained copies and two surplus copies are not double credited");
 check(smmIRGainRun(it,10)==1,"an earlier rank milestone still bounds batching before the price tier");
 need.first_minimum=3; need.tenth=3; smmMuseumGoals[it]=need;
 check(smmIRGainRun(it,10)==3,"retained-copy tier bounds batching when the milestone matches it");
 SmmMuseumGoal unknown; smmMuseumGoals[it]=unknown;
 equal(smmIRRewardValue(it,5),5*floorValue,"unknown rank gets no invented avoided-purchase credit");
 seed(it,0); smmIRMarkets[it].valid=false;
 equal(smmIRSurplusValue(it,2),2*floorValue,"invalid demand evidence falls back to autosell");
 seed(it,0); smmIRMarkets[it].volume=0;
 equal(smmIRSurplusValue(it,2),2*floorValue,"zero demand has no premium capacity");
 item token=$item[fat loot token];
 seed(token,0); smmIRPrices[token]=2000; smmIRReplacementPrices[token]=3000;
 check(!token.tradeable,"fixture currency is untradeable");
 equal(smmIRSurplusValue(token,2),2*max(0,autosell_price(token)),"unexecuted currency conversion is not sale proceeds");
 smmMuseumGoals[token]=need;
 equal(smmIRRewardValue(token,2),6000,"explicit replacement value can still fund retained untradeable copies");
 equal(smmIRSaleValue(token),2000,"conversion opportunity quote remains available for input costs");
 seed(it,0); smmIRPrices[it]=10000; smmIRReplacementPrices[it]=0; smmIRMarkets[it].price=8000;
 SmmRPResource [string] pools; pools["route.paid"]=new SmmRPResource("one paid turn",1,true,"");
 SmmRPAction [string] candidates;
 candidates["loot"]=smmRPNewAction("produce one copy",1,smmIRRewardValue(it));
 candidates["loot"].adventure_delta=-1; candidates["loot"].costs["route.paid"]=1;
 candidates["cash"]=smmRPNewAction("earn cash",1,6000);
 candidates["cash"].adventure_delta=-1; candidates["cash"].costs["route.paid"]=1;
 SmmRPReservation [int] reservations;
 SmmRPContext context=new SmmRPContext("liquidity.fixture",5000,false,0,20000);
 SmmRPPlan plan=smmRPSolve(candidates,pools,reservations,context);
 check(plan.valid && plan.quantity["loot"]==1 && plan.quantity["cash"]==0,"solver can select profitable liquid production");
 smmIRTestStock[it]=70000;
 candidates["loot"].direct_meat=smmIRRewardValue(it);
 plan=smmRPSolve(candidates,pools,reservations,context);
 check(plan.valid && plan.quantity["loot"]==0 && plan.quantity["cash"]==1,"saturated output changes the actual paid-turn choice");
 string before=smmIRStateSignature(); smmIRTestStock[it]+=1; string after=smmIRStateSignature();
 SmmIRResult result; result.success=true; int [string] queued;
 check(before!=after && smmIRMaterialChange("fixture",1,result,before,after,queued).contains_text("stock"),"valued stock changes invalidate the queued plan");
 smmIRMarketTestMode=false; clear(smmIRMarkets); smmIRQuotes=1000000;
 SmmNRMarket capped=smmIRMarket($item[disco ball]);
 check(!capped.valid && smmIRQuotes==1000000,"exhausted quote budget authorizes no HTTP lookup or market premium");
 if (failures==0) print("PASS smmDailyRouteLiquidityTest: "+checks+" checks");
 else print("FAILED smmDailyRouteLiquidityTest: "+failures+" of "+checks);
}
