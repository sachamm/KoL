// A gap prevents spending even if a task would otherwise be ready.
import <smmDailyCore.ash>
void unsafeGapTask() { print("UNSAFE_TASK_EXECUTED"); }
void unsafeGapHook(string task) { print("UNSAFE_HOOK_EXECUTED"); }
void main() {
 smmDTestMode = true;
 smmDJournalLoaded = true;
 smmDJournalOverride = "smm-daily-test-gap.txt";
 smmDJournal[1] = smmDLineNow("journal", "GAP", "fixture: unrecoverable lines");
 smmDHookBeforeTask = "unsafeGapHook";
 smmDSet("smm.daily.runner", "true");
 SmmDTask t = smmDNewTask("gap.failure", 0, "journal gap fixture");
 t.do_fn = "unsafeGapTask";
 t.mode_plan = "on";
 smmDRegister(t);
 smmDRun("");
 print("UNSAFE_TASK_EXECUTED");
}
