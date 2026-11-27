import <smmDailyTasks.ash>
int checks;
int failures;
int launches;
int targets;
int delta;
boolean skillOk;
boolean sawFlag;
string fixtureKey;
string fixturePref;
string declineMode;
string refreshMode;
int rejectedLaunches;
string declinedAdventureFixture() { smmAdventureUnavailableReason = "fixture summon declined"; return ""; }
void declineFixture() {
 launches += 1;
 if (forcedNcTestCarrier.funcString == "accepted") { smmDSet(fixturePref, smmDGet(fixturePref).to_int() + 1); return; }
 rejectedLaunches += 1;
 smmAdventureUnavailableReason = "fixture summon declined";
 if (declineMode == "claimed") smmDSet(fixtureKey, "false");
 if (declineMode == "encounter") smmDSet("lastEncounter", "new fight");
 if (declineMode == "pending") smmDSet("noncombatForcers", "ski avalanche");
 if (declineMode == "delta") smmDSet(fixturePref, smmDGet(fixturePref).to_int() + delta);
}
boolean refreshFixture() {
 if (refreshMode == "counter") smmDSet(fixturePref, "9");
 if (refreshMode == "encounter") smmDSet("lastEncounter", "changed during refresh");
 if (refreshMode == "pending") smmDSet("noncombatForcers", "ski avalanche");
 return refreshMode != "failed";
}
void check(boolean ok, string why) { checks += 1; if (!ok) { failures += 1; print("FAIL: " + why); } }
void launchFixture() {
 launches += 1;
 sawFlag = smmDGet(fixtureKey) == "true";
 smmDSet(fixturePref, smmDGet(fixturePref).to_int() + delta);
}
boolean fiestaFixture() { launches += 1; smmDSet("_cinchUsed", smmDGet("_cinchUsed").to_int() + delta); return skillOk; }
void fresh() {
 clear(smmDTestProps); clear(smmDJournal);
 smmDJournalLoaded = true; smmDJournalOverride = "smm-test-forced-launch.txt";
 smmDHookBeforeTask = "";
 smmDSet("smm.daily.active", smmDEpoch()); smmDSet("smm.daily.runner", "true");
 fixtureKey = kSpikolodonNextCombatKey; fixturePref = "_spikolodonSpikeUses";
 forcedNcTestLaunch = "launchFixture"; forcedNcTestFiesta = "fiestaFixture";
 forcedNcFailure = ""; launches = 0; targets = 0; sawFlag = false; delta = 1; skillOk = true;
 clear(forcedNcRejectedFree); clear(forcedNcTestFreeData);
 forcedNcTestRefresh = ""; declineMode = ""; refreshMode = ""; rejectedLaunches = 0;
}
void selectFixture() {
 while (forcedNcFreeCount() > 0) {
  AdventureRecord ar = forcedNcChooseFree();
  if (!forcedNcTryLaunch(fixtureKey, "fixture spike", fixturePref, "free", ar)) {
   if (forcedNcCarrierUnavailable) continue;
   return;
  }
  targets += 1;
  return;
 }
}
void workerFixture() {
 AdventureRecord ar;
 if (!forcedNcTryLaunch(fixtureKey, "fixture spike", fixturePref, "free", ar)) { smmDTaskProblem = forcedNcFailure; return; }
 targets += 1;
}
void main() {
 smmDTestMode = true;
 string [int] carriers = { "free", "kill", "paid" };
 foreach i, kind in carriers {
  foreach source in $strings[spike,avalanche] {
   fresh();
   if (source == "avalanche") { fixtureKey = kAvalancheNextCombatKey; fixturePref = "_mcHugeLargeAvalancheUses"; }
   smmDSet(fixturePref, "2");
   AdventureRecord ar;
   check(forcedNcTryLaunch(fixtureKey, source, fixturePref, kind, ar), kind + " " + source + " confirms one actual use");
   check(launches == 1 && sawFlag && smmDGet(fixtureKey) == "false", kind + " owns and clears its consult flag");
   check(smmDGet(fixturePref) == "3" && forcedNcFailure == "", kind + " keeps observed usage and no failure");
  }
 }
 foreach amount in $ints[-1,0,2] {
  fresh(); delta = amount; smmDSet(fixturePref, "2"); AdventureRecord ar;
  check(!forcedNcTryLaunch(fixtureKey, "fixture spike", fixturePref, "free", ar), "unconfirmed or unexpected counter delta " + amount + " stops");
  check(launches == 1 && smmDGet(fixtureKey) == "false" && forcedNcFailure != "", "failure retains observed count and clears flag without another carrier");
 }
 fresh(); delta = 60; smmDSet("_cinchUsed", "40");
 check(forcedNcFiesta() && launches == 1 && smmDGet("_cinchUsed") == "100", "Fiesta needs a confirmed 60 Cinch use");
 foreach amount in $ints[0,59,61] {
  fresh(); delta = amount;
  check(!forcedNcFiesta() && forcedNcFailure != "", "Fiesta rejects unexpected Cinch delta " + amount);
 }
 fresh(); delta = 60; skillOk = false;
 check(!forcedNcFiesta() && forcedNcFailure != "", "false skill result remains unconfirmed even when state changed");
 fresh(); delta = 0;
 SmmDTask t = smmDNewTask("force.fixture", 4, "synthetic launch then target");
 t.do_fn = "workerFixture"; t.mode_plan = "on";
 smmDRunTask(t);
 check(targets == 0 && launches == 1, "failed launch never dispatches its target adventure");
 check(smmDGet("_smm.daily.done.force.fixture") == "" && smmDGet("_smm.daily.error.force.fixture") != "", "failed launch leaves the daily task unfinished");
 check(smmDStopRun != "", "failure stops dependent daily work");
 fresh(); smmDRunTask(t);
 check(targets == 1 && launches == 1 && smmDGet("_smm.daily.done.force.fixture") == smmDEpoch(), "confirmed cast can dispatch one target and complete");
 check(smmAdventureLimitReply("Summon limit exceeded.") && smmAdventureLimitReply("Summon limit exceeded"), "known native summon-limit replies are explicit declines");
 check(!smmAdventureLimitReply("") && !smmAdventureLimitReply("network failure") && !smmAdventureLimitReply("User abort"), "unknown failures do not authorize reselection");
 fresh(); AdventureRecord declined; declined.funcString = "declinedAdventureFixture";
 check(!anyAdventure(declined), "declined provider returns before native combat runner or postAdventure");
 fresh(); forcedNcTestLaunch = "declineFixture";
 AdventureRecord bad; bad.funcString = "declined"; AdventureRecord good; good.funcString = "accepted";
 forcedNcTestFreeData[0] = bad; forcedNcTestFreeData[1] = good;
 selectFixture();
 check(launches == 2 && rejectedLaunches == 1 && targets == 1, "one rejected source is skipped before exactly one confirmed target");
 check(forcedNcFreeCount() == 1 && forcedNcChooseFree().funcString == "accepted" && forcedNcFailure == "", "rejected carrier remains excluded for this run");
 check(smmDGet(fixturePref) == "1" && smmDGet(fixtureKey) == "false", "reselection keeps observed usage and clears its queue");
 fresh(); forcedNcTestLaunch = "declineFixture"; forcedNcTestFreeData[0] = bad; selectFixture();
 check(launches == 1 && targets == 0 && forcedNcFreeCount() == 0 && forcedNcFailure == "", "exhausted rejected pool does not repeat or dispatch a target");
 foreach mode in $strings[claimed,encounter,pending] {
  fresh(); forcedNcTestLaunch = "declineFixture"; declineMode = mode;
  check(!forcedNcTryLaunch(fixtureKey, "fixture spike", fixturePref, "free", bad) && !forcedNcCarrierUnavailable && forcedNcFailure != "", mode + " prevents no-fight reselection");
 }
 fresh(); forcedNcTestLaunch = "declineFixture"; smmDSet("noncombatForcers", "ski avalanche");
 check(!forcedNcTryLaunch(fixtureKey, "fixture spike", fixturePref, "free", bad) && !forcedNcCarrierUnavailable, "a preexisting pending force is not classified as unavailable");
 fresh(); forcedNcTestLaunch = "declineFixture";
 check(!forcedNcTryLaunch(fixtureKey, "fixture spike", fixturePref, "paid", bad) && !forcedNcCarrierUnavailable, "paid carriers cannot use the free-carrier exception");
 foreach amount in $ints[-1,2] {
  fresh(); forcedNcTestLaunch = "declineFixture"; declineMode = "delta"; delta = amount;
  check(!forcedNcTryLaunch(fixtureKey, "fixture spike", fixturePref, "free", bad) && !forcedNcCarrierUnavailable && forcedNcFailure != "", "unexpected counter change still holds: " + amount);
 }
 fresh(); forcedNcTestLaunch = "declineFixture"; declineMode = "delta";
 check(forcedNcTryLaunch(fixtureKey, "fixture spike", fixturePref, "free", bad) && !forcedNcCarrierUnavailable && count(forcedNcRejectedFree) == 0, "confirmed one-use delta is never discarded as unavailable");
 foreach mode in $strings[failed,counter,encounter,pending] {
  fresh(); forcedNcTestLaunch = "declineFixture"; forcedNcTestRefresh = "refreshFixture"; refreshMode = mode;
  check(!forcedNcTryLaunch(fixtureKey, "fixture spike", fixturePref, "free", bad) && !forcedNcCarrierUnavailable && forcedNcFailure != "", "refresh " + mode + " holds instead of reselecting");
 }
 if (failures == 0) print("PASS smmDailyForcesTest: " + checks + " checks");
 else print("FAILED smmDailyForcesTest: " + failures + " of " + checks);
}
