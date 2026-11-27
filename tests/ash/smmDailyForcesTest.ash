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
 if (failures == 0) print("PASS smmDailyForcesTest: " + checks + " checks");
 else print("FAILED smmDailyForcesTest: " + failures + " of " + checks);
}
