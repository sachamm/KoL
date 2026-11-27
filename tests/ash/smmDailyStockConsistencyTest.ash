// Optional information-login regression. Reads containers and equipment only;
// never moves an item, buys, casts or adventures. No credentials are needed here.
import <smmDailyTasks.ash>
void main() {
 if (my_id().to_int()<=0) abort("Stock consistency check requires an authorized information login");
 int [item] held=dailyGrindHoldings();
 int checks;
 int mismatches;
 foreach it in $items[] {
  if (it==$item[none]) continue;
  int expected=max(0,held[it]-display_amount(it));
  int actual=smmIRResaleStock(it);
  checks+=1;
  if (expected==actual) continue;
  mismatches+=1;
  if (mismatches<=20) print("SMM_STOCK_MISMATCH item="+it.to_int()+" snapshot="+expected+" native="+actual);
 }
 print("SMM_STOCK_CONSISTENCY checks="+checks+" mismatches="+mismatches);
 if (checks<1 || mismatches>0) abort("Stock consistency check did not reconcile physical ownership");
 print("PASS smmDailyStockConsistencyTest: "+checks+" item rows; no game worker or item transfer");
}
