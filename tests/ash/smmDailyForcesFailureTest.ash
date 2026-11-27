import <smmDailyTasks.ash>
string scenario;
int launches;
void launchFailureFixture() {
 launches += 1;
 smmDSet("_spikolodonSpikeUses", "1");
 if (scenario == "abort") abort("FORCED_LAUNCH_FIXTURE_ABORT");
 smmDTestEpoch = "20000102:0:0";
}
void main(string arg) {
 scenario = arg; smmDTestMode = true; smmDTestEpoch = "20000101:0:0";
 smmDSet("smm.daily.active", smmDEpoch());
 forcedNcTestLaunch = "launchFailureFixture";
 AdventureRecord ar;
 try {
  boolean ok = forcedNcTryLaunch(kSpikolodonNextCombatKey, "fixture spike", "_spikolodonSpikeUses", "free", ar);
  print("UNSAFE_FORCE_TARGET_EXECUTED");
 } finally { print("FORCED_LAUNCH_CLEANUP flag=" + smmDGet(kSpikolodonNextCombatKey) + " launches=" + launches); }
}
