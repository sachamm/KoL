import <smmDailyTasks.ash>
int checks;
int failures;
int casts;
boolean result;
boolean completed;
void check(boolean ok, string why) { checks += 1; if (!ok) { failures += 1; print("FAIL: " + why); } }
boolean breakfastFixture() { casts += 1; smmDSet("breakfastCompleted", completed); return result; }
void fresh() {
 clear(smmDTestProps);
 smmDSet("smm.daily.active", smmDEpoch());
 smmDTTestBreakfast = "breakfastFixture";
 smmDTaskProblem = ""; casts = 0; result = true; completed = true;
}
void main() {
 smmDTestMode = true;
 fresh(); smmDSet("breakfastCompleted", "true"); smmDTBreakfast();
 check(casts == 0, "ordinary already-completed breakfast is not repeated");
 fresh(); smmDSet("breakfastCompleted", "true"); smmDSet("_smm.daily.breakfastDeferred", "true"); smmDTBreakfast();
 check(casts == 1, "deferred login breakfast runs despite yesterday's complete marker");
 check(smmDGet("_smm.daily.breakfastDeferred") == "false" && smmDTaskProblem == "", "successful native confirmation clears the deferral");
 smmDTBreakfast(); check(casts == 1, "confirmed deferred breakfast does not dispatch twice");
 fresh(); smmDSet("breakfastCompleted", "false"); smmDTBreakfast();
 check(casts == 1 && smmDTaskProblem == "", "unfinished ordinary breakfast is repaired");
 fresh(); result = false; smmDSet("_smm.daily.breakfastDeferred", "true"); smmDTBreakfast();
 check(casts == 1 && smmDTaskProblem != "" && smmDGet("_smm.daily.breakfastDeferred") == "true", "false command result retains deferral and unfinished outcome");
 fresh(); completed = false; smmDSet("_smm.daily.breakfastDeferred", "true"); smmDTBreakfast();
 check(casts == 1 && smmDTaskProblem != "" && smmDGet("_smm.daily.breakfastDeferred") == "true", "incomplete summons cannot clear deferral after a true command result");
 result = true; completed = true; smmDTaskProblem = ""; smmDTBreakfast();
 check(casts == 2 && smmDTaskProblem == "" && smmDGet("_smm.daily.breakfastDeferred") == "false", "explicit retry can confirm and settle breakfast");
 if (failures == 0) print("PASS smmDailyBreakfastTest: " + checks + " checks");
 else print("FAILED smmDailyBreakfastTest: " + failures + " of " + checks);
}
