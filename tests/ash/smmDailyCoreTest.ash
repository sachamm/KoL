// Offline tests for the smmDaily engine. Run by tests/smmdaily-tests.sh in a
// logged-out KoLmafia: nothing here needs the game.

import <smmDailyCore.ash>

int checks;
int failures;

void check(boolean ok, string what) {
	checks += 1;
	if (!ok) {
		failures += 1;
		print("FAIL: " + what, "red");
	}
}

void same(string got, string want, string what) {
	// ASH's == ignores case; compare exactly
	check(length(got) == length(want) && got.index_of(want) == 0, what + ": got '" + got + "', want '" + want + "'");
}

// --- stub tasks ------------------------------------------------------------

int [string] ran;
boolean neverDone;
string notReady;
string stopAfter;

void stubA() { ran["a"] += 1; }
void stubB() { ran["b"] += 1; }
void stubC() { ran["c"] += 1; }
boolean stubCDone() { return !neverDone && ran["c"] > 0; }
void stubD() { ran["d"] += 1; }
string stubDReady() { return notReady; }
void stubE() { ran["e"] += 1; if (stopAfter != "") smmDStopRun = stopAfter; }
void stubM() { ran["m"] += 1; }
void stubGarbo() { ran["garbo"] += 1; }
void stubR() { ran["r"] += 1; }
boolean stubAlready() { return true; }
void stubF() { ran["f"] += 1; }
void stubFreeNew() { ran["g.new"] += 1; }
void stubPaidOld() { ran["g.old"] += 1; }

void addStub(int phase, string id, string ready_fn, string done_fn, string do_fn, string legacy_fn, string flags, string mode_legacy, string mode_plan) {
	SmmDTask t = smmDNewTask(id, phase, "stub " + id);
	t.ready_fn = ready_fn;
	t.done_fn = done_fn;
	t.do_fn = do_fn;
	t.legacy_fn = legacy_fn;
	t.spends_turns = flags.contains_text("turns");
	t.on_is_free = flags.contains_text("on-free");
	t.museum = flags.contains_text("museum");
	t.repeatable = flags.contains_text("repeat");
	t.mode_legacy = mode_legacy;
	t.mode_plan = mode_plan;
	smmDRegister(t);
}

// A new day on the runner machine, nothing done, empty journal.
void fresh() {
	clear(smmDTestProps);
	clear(ran);
	clear(smmDJournal);
	smmDJournalLoaded = true;
	smmDJournalWrite();
	smmDForceDry = false;
	neverDone = false;
	notReady = "";
	stopAfter = "";
	smmDSet("smm.daily.runner", "true");
	smmDSet("smm.daily.garboLeaveTurns", "-1"); // logged out there are 0 adventures; don't let that block turn tasks
}

int journalCount(string task, string event) {
	int n = 0;
	foreach seq, line in smmDJournal if (line.task == task && line.event == event) n += 1;
	return n;
}

void testSettings() {
	fresh();
	same(smmDSetting("museumTurns"), "100", "default setting");
	smmDSet("smm.daily.museumTurns", "40");
	check(smmDSettingInt("museumTurns") == 40, "explicit setting wins");
	check(!smmDSettingBool("dryRun"), "boolean default");
	same(smmDSetting("noSuchSetting"), "", "unknown setting is empty");
	foreach name, s in smmDSettings check(s.about != "", "setting " + name + " has a description");
}

void testModes() {
	fresh();
	SmmDTask b = smmDTasks[smmDTaskIndex["t.b"]];
	same(smmDConfiguredMode(b), "legacy", "legacy profile default");
	smmDSet("smm.daily.profile", "plan");
	same(smmDConfiguredMode(b), "off", "plan profile default");
	smmDSet("smm.daily.task.t.b", "on");
	same(smmDConfiguredMode(b), "on", "explicit task mode wins");
	smmDSet("smm.daily.task.t.b", "sometimes");
	same(smmDConfiguredMode(b), "off", "an invalid task mode is ignored");
	smmDSet("smm.daily.profile", "legacy");
	smmDSet("smm.daily.task.t.b", "");

	same(smmDMode(b), "legacy", "runner runs for real");
	smmDSet("smm.daily.runner", "false");
	same(smmDMode(b), "dry", "not the runner: dry");
	smmDSet("smm.daily.runner", "true");
	smmDSet("smm.daily.dryRun", "true");
	same(smmDMode(b), "dry", "smm.daily.dryRun: dry");
	smmDSet("smm.daily.task.t.b", "off");
	same(smmDMode(b), "off", "off stays off in a dry run");

	SmmDTask a = smmDTasks[smmDTaskIndex["t.a"]];
	same(smmDFunctionFor(a, "on"), "stubA", "on runs the new function");
	same(smmDFunctionFor(a, "legacy"), "stubA", "legacy falls back to the new function when there is no old one");
	same(smmDFunctionFor(b, "on"), "stubB", "on falls back to the old function when there is no new one");
	same(smmDFunctionFor(b, "dry"), "", "dry runs nothing");
}

void testRunOnceAndResume() {
	fresh();
	smmDRun("");
	check(ran["a"] == 1, "a ran");
	check(ran["b"] == 1, "b ran (legacy)");
	check(ran["c"] == 1, "c ran");
	check(ran["d"] == 1, "d ran");
	check(ran["e"] == 1, "e ran");
	check(ran["r"] == 1, "repeatable ran");
	check(ran["f"] == 0, "a task the game says is done does not run");
	check(journalCount("t.f", "DONE") == 1, "and is journaled as DONE");
	check(journalCount("t.a", "BEGIN") == 1 && journalCount("t.a", "END") == 1, "a has BEGIN and END");
	same(smmDJournalOpenTask(), "", "no task left open");
	same(smmDGet("smm.daily.active"), "", "run lock released");

	smmDRun("");
	check(ran["a"] == 1 && ran["b"] == 1 && ran["c"] == 1 && ran["e"] == 1, "finished tasks do not run again");
	check(ran["r"] == 2, "a repeatable task runs on every run");
	check(journalCount("t.f", "DONE") == 1, "DONE is journaled once");
}

void testNotReadyAndOff() {
	fresh();
	notReady = "not today";
	smmDSet("smm.daily.task.t.b", "off");
	smmDRun("");
	check(ran["d"] == 0, "a task that is not ready does not run");
	check(journalCount("t.d", "SKIP") == 1, "and is journaled as SKIP");
	check(ran["b"] == 0 && journalCount("t.b", "BEGIN") == 0, "an off task leaves no trace");
	notReady = "";
	smmDRun("");
	check(ran["d"] == 1, "it runs once it is ready");
}

void testAttempts() {
	fresh();
	neverDone = true;
	smmDRun("t.c");
	smmDRun("t.c");
	check(ran["c"] == 2, "a task whose done-test stays false is tried twice");
	smmDRun("t.c");
	check(ran["c"] == 2, "and not a third time");
	check(journalCount("t.c", "FAIL") == 1, "it is journaled as FAIL");
	same(smmDGet("_smm.daily.failed.t.c"), smmDEpoch(), "and marked failed for today");
	smmDRun("");
	check(ran["c"] == 2 && ran["a"] == 1 && ran["e"] == 1, "a failed task blocks only itself");
	check(smmDTaskStatus(smmDTasks[smmDTaskIndex["t.c"]]).starts_with("FAILED"), "status says FAILED");
	// what 'smmdaily retry' does
	smmDSet("_smm.daily.failed.t.c", "");
	smmDSet("_smm.daily.tries.t.c", "0");
	neverDone = false;
	ran["c"] = 0;
	smmDRun("t.c");
	check(ran["c"] == 1, "retry lets it run again");
	check(smmDTaskDone(smmDTasks[smmDTaskIndex["t.c"]]), "and finish");
}

void testStops() {
	fresh();
	smmDSet("smm.daily.halt", "t.a");
	smmDRun("");
	check(ran["a"] == 1 && ran["b"] == 0, "smm.daily.halt stops after the named task");
	same(smmDGet("smm.daily.halt"), "", "and clears itself");
	check(journalCount("t.a", "STOP") == 1, "the halt is journaled");

	stopAfter = "stub asked to stop";
	smmDRun("");
	check(ran["e"] == 1 && ran["r"] == 0, "a task can stop the run after itself");
	check(journalCount("t.e", "STOP") == 1, "the stop is journaled");
	same(smmDGet("smm.daily.active"), "", "run lock released after a stop");
}

void testDryRun() {
	fresh();
	smmDSet("smm.daily.runner", "false");
	smmDRun("");
	check(count(ran) == 0, "a dry run runs nothing");
	check(count(smmDJournal) == 0, "and writes nothing to the journal");
	same(smmDGet("_smm.daily.done.t.a"), "", "and marks nothing done");
	same(smmDGet("_smm.daily.tries.t.a"), "", "and counts no attempt");

	fresh();
	smmDForceDry = true;
	smmDRun("");
	check(count(ran) == 0, "'dry' on the runner machine runs nothing");
	smmDForceDry = false;

	fresh();
	smmDSet("smm.daily.task.t.a", "dry");
	smmDRun("");
	check(ran["a"] == 0 && ran["b"] == 1, "a task set to dry is skipped in a real run");
	check(!smmDTaskDone(smmDTasks[smmDTaskIndex["t.a"]]), "and is not marked done");
}

void testSelectors() {
	fresh();
	smmDRun("t.d");
	check(ran["d"] == 1 && count(ran) == 1, "a task id runs that task only");
	fresh();
	smmDRun("breakfast");
	check(ran["b"] == 1 && ran["c"] == 1 && count(ran) == 2, "a phase name runs that phase only");
	fresh();
	smmDRun("no.such.thing");
	check(count(ran) == 0, "an unknown selector runs nothing");
	check(smmDKnownSelector("") && smmDKnownSelector("close") && smmDKnownSelector("t.a") && !smmDKnownSelector("clos"), "selector lookup");
}

void testTurnLimits() {
	fresh();
	smmDSet("smm.daily.museumTurns", "50");
	smmDSet("_smm.daily.museumTurnsUsed", "50");
	smmDRun("");
	check(ran["m"] == 0, "a Museum grind does not start once the cap is used");
	check(ran["e"] == 1, "other turn tasks still run");

	fresh();
	smmDSet("smm.daily.task.garbo", "on");
	check(smmDGarboPending(), "garbo is pending when its task is on");
	smmDRun("grinds");
	check(ran["m"] == 0, "a Museum grind leaves the garbo reserve alone");
	check(ran["e"] == 1, "the reserve binds Museum grinds only");
	smmDSet("smm.daily.garboReserveTurns", "-1");
	smmDRun("grinds");
	check(ran["m"] == 1, "with no reserve the grind runs");

	fresh();
	check(!smmDGarboPending(), "garbo set to dry is not pending");
	smmDRun("grinds");
	check(ran["m"] == 1, "no reserve is held while garbo is not going to run");

	fresh();
	smmDSet("smm.daily.garboLeaveTurns", "10");
	smmDRun("");
	check(ran["e"] == 0 && ran["m"] == 0, "turn tasks do not start with too few adventures");
	check(ran["a"] == 1 && ran["r"] == 1, "tasks that spend no turns still run");
	check(ran["g.old"] == 0 && ran["g.new"] == 0, "a task whose legacy code spends turns is held back too");
	check(smmDSpendsTurns(smmDTasks[smmDTaskIndex["t.g"]]), "it spends turns in legacy mode");

	fresh();
	smmDSet("smm.daily.garboLeaveTurns", "10");
	smmDSet("smm.daily.profile", "plan");
	check(!smmDSpendsTurns(smmDTasks[smmDTaskIndex["t.g"]]), "its new implementation spends none");
	smmDRun("free");
	check(ran["g.new"] == 1 && ran["g.old"] == 0, "so that one still runs with too few adventures");
}

void testJournal() {
	fresh();
	smmDLog("x", "BEGIN", "one\twith a tab");
	smmDLog("x", "END", "two");
	smmDLog("y", "BEGIN", "three");
	same(smmDJournalOpenTask(), "y", "a BEGIN with no END is the open task");
	same(smmDGet("_smm.daily.journalLines"), "3", "the line count is kept in a preference");

	// read back from disk
	clear(smmDJournal);
	smmDJournalLoaded = false;
	smmDJournalLoad();
	check(count(smmDJournal) == 3, "the journal reads back");
	same(smmDJournal[1].note, "one\twith a tab", "notes survive the round trip");
	same(smmDJournalOpenTask(), "y", "the open task survives the round trip");

	// lines lost: the count in preferences is ahead of the file
	SmmDLine [int] cut;
	cut[1] = smmDJournal[1];
	map_to_file(cut, smmDJournalFile());
	clear(smmDJournal);
	smmDJournalLoaded = false;
	smmDJournalLoad();
	check(journalCount("journal", "GAP") == 1, "missing lines are recorded as a GAP");
	check(count(smmDJournal) == 2, "the surviving line is kept");

	// an earlier day's lines move out of today's journal
	SmmDLine [int] mixed;
	SmmDLine old = smmDLineNow("z", "END", "yesterday");
	old.epoch = "20000101:0:0";
	mixed[1] = old;
	mixed[2] = smmDLineNow("x", "BEGIN", "today");
	map_to_file(mixed, smmDJournalFile());
	smmDSet("_smm.daily.journalLines", "1");
	clear(smmDJournal);
	smmDJournalLoaded = false;
	smmDJournalLoad();
	check(count(smmDJournal) == 1 && smmDJournal[2].task == "x", "only today's lines are loaded");
	SmmDLine [int] previous;
	file_to_map("smm-daily-test-prev.txt", previous);
	check(count(previous) == 1 && previous[1].task == "z", "earlier lines are kept in the -prev file");

	// an interrupted task is closed by the next run, then runs again
	fresh();
	smmDLog("t.a", "BEGIN", "on");
	smmDSet("_smm.daily.tries.t.a", "1");
	smmDRun("t.a");
	check(ran["a"] == 1 && smmDTaskDone(smmDTasks[smmDTaskIndex["t.a"]]), "a task interrupted once runs again and finishes");
	check(journalCount("t.a", "BEGIN") == 2 && journalCount("t.a", "END") == 2, "the interrupted BEGIN gets its END");
	same(smmDJournalOpenTask(), "", "nothing is left open");
	check(smmDJournalOpenSeq() == 0, "no open line");
}

void main() {
	smmDTestMode = true;
	smmDJournalOverride = "smm-daily-test.txt";

	addStub(0, "t.a", "", "", "stubA", "", "", "on", "on");
	addStub(1, "t.b", "", "", "", "stubB", "", "legacy", "off");
	addStub(1, "t.c", "", "stubCDone", "stubC", "", "", "on", "on");
	addStub(2, "t.d", "stubDReady", "", "stubD", "", "", "on", "on");
	addStub(2, "t.f", "", "stubAlready", "stubF", "", "", "on", "on");
	addStub(2, "t.g", "", "", "stubFreeNew", "stubPaidOld", "turns on-free", "legacy", "on");
	addStub(3, "t.m", "", "", "stubM", "", "turns museum", "on", "on");
	addStub(3, "t.e", "", "", "stubE", "", "turns", "on", "on");
	addStub(4, "garbo", "", "", "stubGarbo", "", "turns", "dry", "on");
	addStub(5, "t.r", "", "", "stubR", "", "repeat", "on", "on");

	testSettings();
	testModes();
	testRunOnceAndResume();
	testNotReadyAndOff();
	testAttempts();
	testStops();
	testDryRun();
	testSelectors();
	testTurnLimits();
	testJournal();

	fresh(); // leave an empty test journal behind
	if (failures == 0) print("PASS smmDailyCoreTest: " + checks + " checks");
	else print("FAILED smmDailyCoreTest: " + failures + " of " + checks + " checks", "red");
}
