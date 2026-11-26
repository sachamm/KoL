// Offline regressions for the November 25-26 live failures and accounting.
import <smmDailyTasks.ash>
int checks;
int failures;
void check(boolean ok, string message) {
 checks += 1;
 if (!ok) { failures += 1; print("FAIL: " + message, "red"); }
}
void testCombatPolicy() {
 check(!smmDailyRocketAllowed(false, 0, 0), "a missing blue rocket cannot enter the macro");
 check(smmDailyRocketAllowed(false, 1, 0), "an owned usable blue rocket is allowed");
 check(!smmDailyRocketAllowed(false, 1, 10), "no redundant rocket with its effect active");
 check(!smmDailyRocketAllowed(true, 1, 0), "no aftercore rocket policy in Ronin");
 check(smmDailyCombatHpTarget(100000) == 60000, "HP readiness follows the final outfit's maximum");
 check(smmDailyCombatHpTarget(1) == 1, "tiny HP maximum cannot round readiness to zero");
 check(smmDailyFundedTurnsLeft(103, 100, 5) == 2, "a resumed grind retains only its unspent funded turns");
 check(smmDailyFundedTurnsLeft(107, 100, 5) == 0, "overrun cannot create negative or additional capacity");
 check(smmDailyFundedTurnsLeft(100, 100, 0) == 0, "zero budget authorizes no turn");
}
void testReceipts() {
 item input = $item[seal tooth];
 check(smmDailyValuedDelta(input, 5, 0, 0) == -5, "fully consumed owned inputs are charged");
 check(smmDailyValuedDelta(input, 20, 20, 0) == 0, "moving owned copies between storage, case, shop and equipment has no income");
 check(smmDailyValuedDelta($item[cosmic bowling ball], 0, 1, 0) == 0, "returning bowling ball is not produced dungeon loot");
 check(smmDailyValuedDelta($item[cosmic bowling ball], 1, 0, 0) == 0, "throwing the reusable bowling ball is not a consumption expense");
 check(smmDailyValuedDelta(input, 0, 3, 3) == 3, "real new loot remains counted");
 string log = "buy 2 seal tooth for 100 each from shop #42 on 20261126\nYou acquire seal tooth (2)\n"
  + "equip weapon seal tooth\n> You acquire an item: seal tooth\nYou acquire an effect: Shamed (10)\n";
 SmmDailyItemReceipt [item] receipt = smmDailyItemReceipts(log);
 check(receipt[input].requestedBuys == 2 && receipt[input].requestedMeat == 200, "purchase requests remain separate from observed gains");
 check(receipt[input].acquired == 2 && receipt[input].nativeDrops == 0, "quoted diagnostics and effects cannot become loot");
 monster foe = $monster[spooky vampire];
 item drop = $item[none];
 foreach i, d in item_drops_array(foe) { drop = d.drop; break; }
 check(drop != $item[none], "native-loot fixture has a known monster drop");
 receipt = smmDailyItemReceipts("Encounter: spooky vampire\nRound 1: Test wins the fight!\nYou acquire an item: " + drop + "\n");
 check(receipt[drop].nativeDrops == 1, "a native drop follows an observed win");
 receipt = smmDailyItemReceipts("Encounter: spooky vampire\nYou acquire an item: " + drop + "\n");
 check(receipt[drop].nativeDrops == 0, "an encounter without victory cannot claim native loot");
 receipt = smmDailyItemReceipts("Encounter: spooky vampire\nRound 1: Test wins the fight!\nYou acquire an item: cosmic bowling ball\n");
 check(receipt[$item[cosmic bowling ball]].nativeDrops == 0, "returned equipment is not a monster's native drop");
}
void testPrices() {
 check(smmDailyPurchaseLimit(500, 300.9) == 300, "purchase boundary enforces the average");
 check(smmDailyPurchaseLimit(200, 300.9) == 200, "a tighter caller limit survives");
 check(smmDailyPurchaseLimit(500, 0) == 0, "unknown average cannot authorize a purchase");
 check(smmDailyPurchaseLimit(500, -1) == 0, "bad average fails closed");
 check(smmDailyPurchaseLimit(0, 300) == 0, "zero allowance cannot buy");
}
void testCompletion() {
 smmDTestMode = true;
 clear(smmDTestProps);
 check(smmDSetting("profile") == "plan", "an unset profile defaults to plan");
 check(smmDCompletionProblem() != "", "having a nightcap alone cannot complete unfinished tasks");
 foreach i, t in smmDTasks if (t.id.starts_with("goodnight")) smmDSet("_smm.daily.done." + t.id, smmDEpoch());
 check(smmDCompletionProblem() == "", "finished end-of-day tasks pass the task completion gate");
 smmDSet("_smm.daily.failed.goodnight.adv.fax", smmDEpoch());
 check(smmDCompletionProblem().contains_text("goodnight.adv.fax"), "a failed child is visible even after goodnight finishes");
 smmDSet("_smm.daily.failed.goodnight.adv.fax", "");
 smmDSet("smm.daily.task.goodnight.adv.locket", "dry");
 check(smmDCompletionProblem().contains_text("disabled"), "a dry required task is not a completed day");
 check(smmDSelected(smmDTasks[smmDTaskIndex["goodnight.adv.fax"]], "goodnight.adv"), "old group command selects its new resumable children");
 check(!smmDSelected(smmDTasks[smmDTaskIndex["goodnight.adv.fax"]], "goodnight.adv.locket"), "retrying one child does not select another");
 smmDTestMode = false;
 clear(smmDTestProps);
}
void testCollectionBudget() {
 check(smmDailyCollectionEligible(true, true, true, 10), "named unbuyable target with a known gap qualifies");
 check(!smmDailyCollectionEligible(true, true, false, 10), "unknown rankings invent no collection entitlement");
 check(!smmDailyCollectionEligible(true, true, true, 0), "closed gap stops the collection exemption");
 check(!smmDailyCollectionEligible(false, true, true, 10), "buyable output does not bypass the profit test");
 check(!smmDailyCollectionEligible(true, false, true, 10), "nondisplayable output cannot fund Museum losses");
 check(smmDailyCollectionCanFund(0, 0, 2, 4500, 9000), "two-turn target fits its funded loss");
 check(!smmDailyCollectionCanFund(1, 0, 2, 4500, 9000), "cannot overcommit even one Meat");
 check(smmDailyCollectionCanFund(9000, 9000, 2, 4500, 9000), "resuming a reservation does not charge it twice");
 check(!smmDailyCollectionCanFund(9000, 9000, 3, 4500, 9000), "resuming cannot expand the reservation beyond the budget");
 check(!smmDailyCollectionCanFund(0, 0, 0, 4500, 9000), "zero-turn target cannot bypass a budget");
 check(!smmDailyCollectionCanFund(0, 0, 2, 0, 9000), "unknown turn value cannot authorize a loss");
 check(dailyGrindCollectionTarget("oasis") == $item[none], "incidental untradeable drops do not exempt Oasis");
}
void testResourceOutcomes() {
 check(smmDailyResourceState(10, 10, "", "", "nep", false) == "used", "exhausted counter is used");
 check(smmDailyResourceState(6, 10, "server returned Party's Over", "", "nep", false).starts_with("blocked"), "closed Party is blocked, not four missed fights");
 check(smmDailyResourceState(0, 3, "", "collection tomorrow", "grinds", false).starts_with("reserved"), "declared retention has a reason");
 check(smmDailyResourceState(0, 3, "", "", "goodnight", true).starts_with("missed"), "owner failure is actionable");
 check(smmDailyResourceState(4, 5, "", "", "grinds", false).starts_with("unspent"), "a spare saber use is not automatically waste");
}
void main() {
 testCombatPolicy(); testReceipts(); testPrices(); testCompletion(); testCollectionBudget(); testResourceOutcomes();
 if (failures == 0) print("PASS smmDailyReviewTest: " + checks + " checks");
 else print("FAILED smmDailyReviewTest: " + failures + " of " + checks + " checks", "red");
}
