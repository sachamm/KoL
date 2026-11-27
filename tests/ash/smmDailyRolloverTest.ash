// Expected aborts; all workers are synthetic and never contact the game.
import <smmDailyCore.ash>
string scenario;
int workers;
void changeDay() { smmDTestEpoch = "20000102:0:0"; }
void rolloverStart() { if (scenario == "start") changeDay(); }
void rolloverBefore(string task) { if (scenario == "before") changeDay(); }
void rolloverBody() { workers += 1; if (scenario == "body") changeDay(); }
void unsafeNext() { print("UNSAFE_NEXT_EXECUTED"); }
void main(string arg) {
 scenario = arg;
 smmDTestMode = true;
 smmDTestEpoch = "20000101:0:0";
 smmDJournalLoaded = true;
 smmDJournalOverride = "smm-test-rollover-" + scenario + ".txt";
 smmDSet("smm.daily.runner", "true");
 // A previous day's crashed marker must not block a deliberate fresh run.
 smmDSet("smm.daily.active", "19991231:0:0");
 smmDHookRunStart = "rolloverStart";
 smmDHookBeforeTask = "rolloverBefore";
 SmmDTask t = smmDNewTask("rollover.fixture", 0, "rollover fixture");
 t.do_fn = "rolloverBody";
 t.mode_plan = "on";
 t.museum = true;
 smmDRegister(t);
 t = smmDNewTask("rollover.next", 0, "must not run after rollover");
 t.do_fn = "unsafeNext";
 t.mode_plan = "on";
 smmDRegister(t);
 try {
  if (scenario == "active") smmDRequireActiveDay();
  if (scenario == "journal") {
   smmDJournalLoad();
   changeDay();
   smmDLog("rollover.fixture", "END", "must not persist in new day");
  }
  if (scenario == "checkpoint") {
   SmmDLine line = smmDLineNow("rollover.fixture", "END", smmDCheckpointNote("old day", 1, true, false, 42, ""));
   changeDay();
   smmDApplyCheckpoint(line);
  }
  smmDRun("");
  print("UNSAFE_NEXT_EXECUTED");
 } finally {
  int ended;
  int wrongDay;
  foreach seq, line in smmDJournal {
   if (line.event == "END") ended += 1;
   if (line.epoch != "20000101:0:0") wrongDay += 1;
  }
  print("ROLLOVER_STATE workers=" + workers + " ended=" + ended + " wrongDay=" + wrongDay
   + " done=" + smmDGet("_smm.daily.done.rollover.fixture") + " museum=" + smmDMuseumTurnsUsed());
 }
}
