// This script intentionally aborts before its stub action can run.
import <smmDailyCore.ash>
void unsafeFixture() { print("UNSAFE_TASK_EXECUTED"); }
void unsafeHook(string task) { print("UNSAFE_HOOK_EXECUTED"); }
void main() {
 smmDTestMode = true;
 smmDJournalLoaded = true;
 smmDTestRejectJournalWrite = true;
 smmDHookBeforeTask = "unsafeHook";
 smmDSet("smm.daily.runner", "true");
 SmmDTask t = smmDNewTask("intent.failure", 0, "journal failure fixture");
 t.do_fn = "unsafeFixture";
 t.mode_plan = "on";
 smmDRegister(t);
 smmDRun("");
 print("UNSAFE_TASK_EXECUTED");
}
