import <smmDailyTasks.ash>
int checks;
int failures;
int casts;
int gain;
boolean skillOk;
skill lastHealer;
void check(boolean ok, string why) { checks += 1; if (!ok) { failures += 1; print("FAIL: " + why); } }
boolean healFixture(skill healer) {
 casts += 1; lastHealer = healer;
 if (!skillOk) return false;
 smmDTestHealingState.mp -= healer == $skill[Cannelloni Cocoon] ? smmDTestHealingState.cocoonCost : smmDTestHealingState.walrusCost;
 smmDTestHealingState.hp += gain;
 return true;
}
void fresh(int hp, int mp) {
 clear(smmDTestProps); smmDSet("smm.daily.active", smmDEpoch());
 smmDTestHealAction = "healFixture";
 smmDTestHealingState.hp = hp; smmDTestHealingState.mp = mp;
 smmDTestHealingState.cocoon = true; smmDTestHealingState.cocoonCost = 20;
 smmDTestHealingState.walrus = true; smmDTestHealingState.walrusCost = 10;
 casts = 0; gain = 1000; skillOk = true; lastHealer = $skill[none];
}
void main() {
 smmDTestMode = true;
 fresh(500, 1000);
 check(smmDHealToTarget(25000) && casts == 25 && smmDTestHealingState.hp == 25500, "high-HP outfit can require more than eight successful Cocoons");
 check(smmDTestHealingState.mp == 500, "only the confirmed healing casts consume the available MP");
 fresh(8000, 500);
 check(smmDHealToTarget(24000) && casts == 16, "retry finishes the remaining healing without lowering the 60 percent target");
 fresh(0, 240);
 smmDTestHealingState.walrus = false;
 check(!smmDHealToTarget(20000) && casts == 12 && smmDTestHealingState.mp == 0, "MP bounds healing without an arbitrary cast limit or sourcing more MP");
 fresh(1000, 0);
 check(smmDHealToTarget(1000) && casts == 0, "already-ready HP does not require MP or another cast");
 fresh(0, 100); gain = 0;
 check(!smmDHealToTarget(1000) && casts == 1, "successful command with no HP gain stops immediately");
 fresh(0, 100); skillOk = false;
 check(!smmDHealToTarget(1000) && casts == 1, "failed cast is not retried automatically");
 fresh(0, 100); smmDTestHealingState.cocoon = false; gain = 40;
 check(smmDHealToTarget(150) && casts == 4 && lastHealer == $skill[Tongue of the Walrus], "known affordable Walrus heals can reach the target");
 fresh(0, 10); gain = 40;
 check(smmDHealToTarget(40) && casts == 1 && lastHealer == $skill[Tongue of the Walrus], "unaffordable Cocoon permits an affordable known healer");
 fresh(0, 100); smmDTestHealingState.cocoon = false; smmDTestHealingState.walrus = false;
 check(!smmDHealToTarget(1000) && casts == 0, "unknown healing skills cannot be cast");
 fresh(0, 0); smmDTestHealingState.cocoonCost = 0;
 check(smmDHealToTarget(9000) && casts == 9, "zero-cost healing remains bounded by strict HP progress");
 fresh(0, 0); smmDTestHealingState.cocoonCost = 0; gain = 0;
 check(!smmDHealToTarget(9000) && casts == 1, "zero-cost no-progress casts cannot loop forever");
 fresh(0, 100); smmDTestHealingState.cocoonCost = -1; smmDTestHealingState.walrus = false;
 check(!smmDHealToTarget(1000) && casts == 0, "invalid healing cost does not authorize a cast");
 if (failures == 0) print("PASS smmDailyHealingTest: " + checks + " checks");
 else print("FAILED smmDailyHealingTest: " + failures + " of " + checks);
}
