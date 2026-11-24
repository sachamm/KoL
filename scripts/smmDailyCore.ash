// smmDaily: the engine. See docs/daily-script.md and docs/daily-script-plan.md.
//
// This file has no imports and touches no game state beyond reading the
// character's status, so it can be tested in a logged-out KoLmafia
// (tests/ash/). Everything that spends, casts or adventures lives in the task
// files, which the engine calls by name.
//
// A day is a list of tasks in a fixed order. Each task has a mode:
//   off     never runs
//   dry     prints what it would do
//   legacy  runs today's code (the block lifted from dailyGrind)
//   on      runs the new implementation, where there is one
// A task's mode is smm.daily.task.<id> when that is set, else the default of
// the active profile (smm.daily.profile = legacy | plan).

// ---------------------------------------------------------------------------
// Property seam: tests read and write a map instead of real preferences.

boolean smmDTestMode;
string [string] smmDTestProps;

string smmDGet(string name) {
	if (smmDTestMode) return (smmDTestProps contains name) ? smmDTestProps[name] : "";
	return get_property(name);
}

void smmDSet(string name, string value) {
	if (smmDTestMode) smmDTestProps[name] = value;
	else set_property(name, value);
}

// ---------------------------------------------------------------------------
// Settings: each one declared once, read as smm.daily.<name>.

record SmmDSetting {
	string fallback;
	string about;
};
SmmDSetting [string] smmDSettings;

boolean smmDDeclare(string name, string fallback, string about) {
	SmmDSetting s;
	s.fallback = fallback;
	s.about = about;
	smmDSettings[name] = s;
	return true;
}

string smmDSetting(string name) {
	string explicit = smmDGet("smm.daily." + name);
	if (explicit != "") return explicit;
	return (smmDSettings contains name) ? smmDSettings[name].fallback : "";
}

int smmDSettingInt(string name) { return smmDSetting(name).to_int(); }
boolean smmDSettingBool(string name) { return smmDSetting(name) == "true"; }

boolean smmDCoreSettings =
	smmDDeclare("profile", "legacy", "legacy = today's code in the new order; plan = the plan's target (garbo as the Meat engine, Oasis and sandworms off)")
	&& smmDDeclare("runner", "false", "true on the one machine that runs the day; anywhere else 'run' is a dry run. Never put this in smm-prefs.txt")
	&& smmDDeclare("dryRun", "false", "true makes every 'run' a dry run")
	&& smmDDeclare("museumTurns", "100", "most paid turns a day for the Museum grinds (beer lens, ghost costume, Spacegate, FantasyRealm, PirateRealm, Daily Dungeon, Drip, Gingerbread)")
	&& smmDDeclare("garboLeaveTurns", "10", "adventures garbo leaves unspent (garbo -N); also what a paid task must leave")
	&& smmDDeclare("garboArgs", "", "extra garbo arguments; ascend, workshed= and quick are refused")
	&& smmDDeclare("garboReserveTurns", "30", "adventures a Museum grind must leave for garbo, on top of garboLeaveTurns, while the garbo task is on")
	&& smmDDeclare("mpFloor", "2000", "MP to restore to after breakfast, from free sources only")
	&& smmDDeclare("mpLow", "400", "no task starts under this much MP while a free restore is left")
	&& smmDDeclare("rolloverBufferMin", "10", "no turn-spending task starts this close to rollover")
	&& smmDDeclare("fenceItems", "drum machine|Special Seasoning|inflammable leaf", "items closeted while garbo runs, separated by |")
	&& smmDDeclare("maxAttempts", "2", "times a task may start in one day before it is marked failed")
	&& smmDDeclare("halt", "", "set before a run: stop after this task, then clear this setting");

// ---------------------------------------------------------------------------
// Day key. The game date is pinned to rollover, and it is the key the resource
// planner and the spending ledger already use, so nothing has to migrate.

string smmDEpoch() {
	return today_to_string() + ":" + my_ascensions() + ":" + my_id();
}

// ---------------------------------------------------------------------------
// Journal: one line per event, appended and written at once. The intent
// (BEGIN) is on disk before the task runs, so an interrupted task shows as a
// BEGIN with no END. The spending totals do not live here: they are in the
// _smm.spend.* preferences, so a lost journal never reads as "nothing spent".

record SmmDLine {
	string epoch;
	string at;
	string task;
	string event;   // BEGIN END SKIP DRY DONE FAIL STOP NOTE GAP
	int turns;      // total_turns_played()
	int adventures; // my_adventures()
	int meat;       // Meat on hand, in the closet and in storage
	int mp;
	string note;
};
SmmDLine [int] smmDJournal;
boolean smmDJournalLoaded;
string smmDJournalOverride; // tests

string smmDJournalFile() {
	if (smmDJournalOverride != "") return smmDJournalOverride;
	return "smm-daily-" + my_id() + ".txt";
}

int smmDJournalNext() {
	int last = 0;
	foreach seq in smmDJournal if (seq > last) last = seq;
	return last + 1;
}

void smmDJournalWrite() {
	if (!map_to_file(smmDJournal, smmDJournalFile()))
		print("smmDaily: could not write the journal " + smmDJournalFile(), "red");
}

SmmDLine smmDLineNow(string task, string event, string note) {
	SmmDLine line;
	line.epoch = smmDEpoch();
	line.at = now_to_string("HH:mm:ss");
	line.task = task;
	line.event = event;
	line.turns = total_turns_played();
	line.adventures = my_adventures();
	line.meat = my_meat() + my_closet_meat() + my_storage_meat();
	line.mp = my_mp();
	line.note = note;
	return line;
}

// Loads today's lines. Lines from an earlier day move to a "-prev" file. If
// fewer lines come back than this day has written (the file was lost, or cut
// short), a GAP line records it instead of the day silently starting again.
void smmDJournalLoad() {
	if (smmDJournalLoaded) return;
	smmDJournalLoaded = true;
	SmmDLine [int] stored;
	file_to_map(smmDJournalFile(), stored);
	SmmDLine [int] earlier;
	string epoch = smmDEpoch();
	clear(smmDJournal);
	foreach seq, line in stored {
		if (line.epoch == epoch) smmDJournal[seq] = line;
		else earlier[seq] = line;
	}
	if (count(earlier) > 0)
		map_to_file(earlier, smmDJournalFile().replace_string(".txt", "-prev.txt").to_string());
	int written = smmDGet("_smm.daily.journalLines").to_int();
	if (count(smmDJournal) < written) {
		smmDJournal[max(written, smmDJournalNext())] = smmDLineNow("journal", "GAP",
			"expected " + written + " lines for today, found " + count(smmDJournal) + "; spending totals are kept in preferences and are unaffected");
		print("smmDaily: today's journal is missing lines (found " + count(smmDJournal) + " of " + written + ").", "orange");
	}
	if (count(earlier) > 0 || count(smmDJournal) != count(stored)) smmDJournalWrite();
}

SmmDLine smmDLog(string task, string event, string note) {
	smmDJournalLoad();
	SmmDLine line = smmDLineNow(task, event, note);
	smmDJournal[smmDJournalNext()] = line;
	smmDJournalWrite();
	smmDSet("_smm.daily.journalLines", count(smmDJournal));
	return line;
}

// The journal line of the last BEGIN that has no END after it, 0 when every
// task that began also ended.
int smmDJournalOpenSeq() {
	smmDJournalLoad();
	int open = 0;
	foreach seq, line in smmDJournal {
		if (line.event == "BEGIN") open = seq;
		else if (line.event == "END" && open > 0 && line.task == smmDJournal[open].task) open = 0;
	}
	return open;
}

string smmDJournalOpenTask() {
	int open = smmDJournalOpenSeq();
	return open > 0 ? smmDJournal[open].task : "";
}

// ---------------------------------------------------------------------------
// Tasks

record SmmDTask {
	string id;
	int phase;
	string about;
	string ready_fn;    // string fn(): "" when it can run now, else why not
	string done_fn;     // boolean fn(): the game says it is done. "" = the engine's own flag only
	string do_fn;       // void fn(): the new implementation. "" = none yet
	string legacy_fn;   // void fn(): today's code. "" = none
	boolean spends_turns;
	boolean on_is_free; // the new implementation spends no turns, though the legacy one does
	boolean museum;     // counts against smm.daily.museumTurns
	boolean repeatable; // runs on every 'run' (bookkeeping), never marked done
	string mode_legacy; // default mode in the legacy profile
	string mode_plan;   // default mode in the plan profile
};
SmmDTask [int] smmDTasks;
int [string] smmDTaskIndex;

string [int] smmDPhaseNames = {0: "preflight", 1: "breakfast", 2: "free", 3: "grinds", 4: "garbo", 5: "close"};

SmmDTask smmDNewTask(string id, int phase, string about) {
	SmmDTask t;
	t.id = id;
	t.phase = phase;
	t.about = about;
	t.mode_legacy = "legacy";
	t.mode_plan = "legacy";
	return t;
}

void smmDRegister(SmmDTask t) {
	if (smmDTaskIndex contains t.id) abort("smmDaily: task " + t.id + " is registered twice");
	int at = count(smmDTasks);
	if (at > 0 && smmDTasks[at - 1].phase > t.phase) abort("smmDaily: task " + t.id + " is registered out of phase order");
	smmDTasks[at] = t;
	smmDTaskIndex[t.id] = at;
}

boolean smmDValidMode(string mode) {
	return mode == "off" || mode == "dry" || mode == "legacy" || mode == "on";
}

boolean smmDForceDry; // the 'dry' command

// The task's own mode, before a dry run is applied.
string smmDConfiguredMode(SmmDTask t) {
	string explicit = smmDGet("smm.daily.task." + t.id);
	if (smmDValidMode(explicit)) return explicit;
	return smmDSetting("profile") == "plan" ? t.mode_plan : t.mode_legacy;
}

boolean smmDIsDryRun() {
	return smmDForceDry || smmDSettingBool("dryRun") || !smmDSettingBool("runner");
}

string smmDMode(SmmDTask t) {
	string mode = smmDConfiguredMode(t);
	if (mode != "off" && smmDIsDryRun()) return "dry";
	return mode;
}

// The function a mode runs. "on" with no new implementation falls back to the
// legacy one, and the reverse, so a mode never silently does nothing.
string smmDFunctionFor(SmmDTask t, string mode) {
	if (mode == "on") return t.do_fn != "" ? t.do_fn : t.legacy_fn;
	if (mode == "legacy") return t.legacy_fn != "" ? t.legacy_fn : t.do_fn;
	return "";
}

boolean smmDTaskDone(SmmDTask t) {
	if (t.repeatable) return false;
	return smmDGet("_smm.daily.done." + t.id) == smmDEpoch();
}

// The task is switched on and has not finished or failed today.
boolean smmDTaskWanted(string id) {
	if (!(smmDTaskIndex contains id)) return false;
	SmmDTask t = smmDTasks[smmDTaskIndex[id]];
	return smmDConfiguredMode(t) != "off" && !smmDTaskDone(t) && smmDGet("_smm.daily.failed." + id) != smmDEpoch();
}

// garbo will really run later today: its task is set to run, not to dry or off.
boolean smmDGarboPending() {
	if (!smmDTaskWanted("garbo")) return false;
	string mode = smmDConfiguredMode(smmDTasks[smmDTaskIndex["garbo"]]);
	return mode == "on" || mode == "legacy";
}

int smmDMuseumTurnsUsed() { return smmDGet("_smm.daily.museumTurnsUsed").to_int(); }

int smmDSecondsToRollover() {
	int at = rollover();
	if (at <= 0) return 86400; // unknown (logged out): don't block on it
	return at - (now_to_int() / 1000);
}

// Whether the implementation this task is set to run spends turns.
boolean smmDSpendsTurns(SmmDTask t) {
	if (!t.spends_turns) return false;
	return !(t.on_is_free && t.do_fn != "" && smmDConfiguredMode(t) == "on");
}

// Why the engine itself won't start this task now, "" when it may.
string smmDEngineBlock(SmmDTask t) {
	if (!smmDSpendsTurns(t)) return "";
	if (my_inebriety() > inebriety_limit()) return "overdrunk";
	if (smmDSecondsToRollover() < smmDSettingInt("rolloverBufferMin") * 60) return "too close to rollover";
	if (t.phase != 4 && my_adventures() <= smmDSettingInt("garboLeaveTurns"))
		return "only " + my_adventures() + " adventures left (" + smmDSettingInt("garboLeaveTurns") + " are held back)";
	if (t.museum && smmDMuseumTurnsUsed() >= smmDSettingInt("museumTurns"))
		return "the Museum grinds have used " + smmDMuseumTurnsUsed() + " of " + smmDSettingInt("museumTurns") + " paid turns";
	int reserve = smmDSettingInt("garboReserveTurns") + smmDSettingInt("garboLeaveTurns");
	if (t.museum && smmDGarboPending() && my_adventures() <= reserve)
		return my_adventures() + " adventures left, and " + reserve + " are kept for garbo and the end of the day";
	return "";
}

// A grind with no done-test of its own that used turns and came back with no
// adventures left stopped because the turns ran out, not because the work was
// finished. It stays open, so a later run with more adventures carries on.
boolean smmDRanOutOfAdventures(SmmDTask t, int turnsUsed, int adventuresLeft) {
	return t.done_fn == "" && !t.repeatable && smmDSpendsTurns(t) && turnsUsed > 0 && adventuresLeft <= 0;
}

// 'call' takes a plain variable, not a record field, hence these.
boolean smmDCallBool(string fn) { return call boolean fn(); }
string smmDCallString(string fn) { return call string fn(); }

// One line on where a task stands, for 'plan' and 'status'.
string smmDTaskStatus(SmmDTask t) {
	string mode = smmDConfiguredMode(t);
	if (mode == "off") return "off";
	if (smmDTaskDone(t)) return "done";
	if (t.done_fn != "" && smmDCallBool(t.done_fn)) return "done (game state)";
	if (smmDGet("_smm.daily.failed." + t.id) == smmDEpoch()) return "FAILED today (smmdaily retry " + t.id + ")";
	string why = t.ready_fn == "" ? "" : smmDCallString(t.ready_fn);
	if (why != "") return "not now: " + why;
	why = smmDEngineBlock(t);
	if (why != "") return "not now: " + why;
	return mode == "dry" ? "would run (dry)" : "will run (" + mode + ")";
}

// ---------------------------------------------------------------------------
// The run

string smmDStopRun;           // a task sets this to end the run after itself
string smmDHookBeforeTask;    // void fn(string id): set by the gate (MP floor)
string smmDHookRunStart;      // void fn(): set by the task files (prompt presets)
string smmDHookRunEnd;        // void fn()

string smmDPreflight() {
	if (smmDTestMode) return "";
	if (current_round() > 0 || handling_choice()) return "finish the current fight or choice first";
	if (!can_interact() || my_path() != $path[none]) return "smmDaily is for unrestricted aftercore, out of Ronin";
	return "";
}

// selector: "" for everything, a phase name, or a task id.
boolean smmDSelected(SmmDTask t, string selector) {
	return selector == "" || selector == t.id || selector == smmDPhaseNames[t.phase];
}

boolean smmDKnownSelector(string selector) {
	if (selector == "" || (smmDTaskIndex contains selector)) return true;
	foreach i, name in smmDPhaseNames if (name == selector) return true;
	return false;
}

void smmDRunTask(SmmDTask t) {
	string mode = smmDMode(t);
	if (mode == "off") return;
	if (smmDTaskDone(t)) return;
	if (t.done_fn != "" && smmDCallBool(t.done_fn)) {
		if (mode != "dry") {
			smmDSet("_smm.daily.done." + t.id, smmDEpoch());
			smmDLog(t.id, "DONE", "already done (game state)");
		}
		return;
	}
	if (smmDGet("_smm.daily.failed." + t.id) == smmDEpoch()) {
		print("smmDaily: " + t.id + " failed earlier today, skipping (smmdaily retry " + t.id + " to try again)", "orange");
		return;
	}
	string why = t.ready_fn == "" ? "" : smmDCallString(t.ready_fn);
	if (why == "") why = smmDEngineBlock(t);
	if (why != "") {
		print("smmDaily: skipping " + t.id + ": " + why, "gray");
		if (mode != "dry") smmDLog(t.id, "SKIP", why);
		return;
	}
	if (mode == "dry") {
		if (smmDIsDryRun() && smmDConfiguredMode(t) == "dry")
			print("smmDaily (dry run): " + t.id + " is set to dry, so a real run would not run it either - " + t.about + ". To have it run: set smm.daily.task." + t.id + " = on", "blue");
		else if (smmDIsDryRun())
			print("smmDaily (dry run): would run " + t.id + " [" + smmDConfiguredMode(t) + "] - " + t.about, "blue");
		else
			print("smmDaily: " + t.id + " is set to dry, so it was not run - " + t.about + ". To run it here: set smm.daily.task." + t.id + " = on", "orange");
		return;
	}
	string fn = smmDFunctionFor(t, mode);
	if (fn == "") {
		smmDLog(t.id, "SKIP", "no implementation for mode " + mode);
		return;
	}
	int tries = smmDGet("_smm.daily.tries." + t.id).to_int();
	if (!t.repeatable && tries >= smmDSettingInt("maxAttempts")) {
		smmDSet("_smm.daily.failed." + t.id, smmDEpoch());
		smmDLog(t.id, "FAIL", "started " + tries + " times without finishing");
		print("smmDaily: " + t.id + " started " + tries + " times without finishing; marked failed for today.", "red");
		return;
	}
	smmDSet("_smm.daily.tries." + t.id, tries + 1);
	if (smmDHookBeforeTask != "") call void smmDHookBeforeTask(t.id);

	print("smmDaily: " + t.id + " [" + mode + "] - " + t.about, "blue");
	SmmDLine before = smmDLog(t.id, "BEGIN", mode + (tries > 0 ? ", attempt " + (tries + 1) : ""));
	call void fn();
	int turns = total_turns_played() - before.turns;
	int meat = my_meat() + my_closet_meat() + my_storage_meat() - before.meat;
	string note = "turns " + turns + ", Meat " + (meat >= 0 ? "+" : "") + meat;
	boolean finished = t.done_fn == "" || smmDCallBool(t.done_fn);
	if (!finished) note += "; done-test still false";
	boolean ranOut = smmDRanOutOfAdventures(t, turns, my_adventures());
	if (ranOut) note += "; out of adventures, so it stays open";
	smmDLog(t.id, "END", note);
	if (t.museum && turns > 0) smmDSet("_smm.daily.museumTurnsUsed", smmDMuseumTurnsUsed() + turns);
	if (finished && !ranOut && !t.repeatable) smmDSet("_smm.daily.done." + t.id, smmDEpoch());
	if (t.repeatable) smmDSet("_smm.daily.tries." + t.id, 0);
	// running out of turns is not a failed attempt
	if (ranOut) smmDSet("_smm.daily.tries." + t.id, tries);
}

// A task that began and never ended (an abort, a crash, a closed window) is
// closed here, at the start of the next run. Its turns are still charged: the
// turns played since it began are the most it can have used.
void smmDCloseInterrupted() {
	int open = smmDJournalOpenSeq();
	if (open == 0) return;
	SmmDLine begin = smmDJournal[open];
	int turns = max(0, total_turns_played() - begin.turns);
	boolean museum = (smmDTaskIndex contains begin.task) && smmDTasks[smmDTaskIndex[begin.task]].museum;
	if (museum && turns > 0) smmDSet("_smm.daily.museumTurnsUsed", smmDMuseumTurnsUsed() + turns);
	smmDLog(begin.task, "END", "interrupted; closed by the next run, " + turns + " turns played since it began");
	print("smmDaily: the last run stopped inside " + begin.task + " (" + turns + " turns played since it began).", "orange");
}

void smmDRun(string selector) {
	if (!smmDKnownSelector(selector)) {
		print("smmDaily: no phase or task is called '" + selector + "'. Try smmdaily plan.", "red");
		return;
	}
	string problem = smmDPreflight();
	if (problem != "") {
		print("smmDaily: " + problem + ".", "red");
		return;
	}
	boolean dry = smmDIsDryRun();
	if (dry && !smmDForceDry && !smmDSettingBool("dryRun"))
		print("smmDaily: this machine is not the runner, so this is a dry run. To run for real here: set smm.daily.runner = true", "orange");

	string epoch = smmDEpoch();
	if (!dry) {
		smmDCloseInterrupted();
		if (smmDGet("smm.daily.active") == epoch) print("smmDaily: the last run did not end cleanly.", "orange");
		smmDSet("smm.daily.active", epoch);
	}
	smmDStopRun = "";
	try {
		if (!dry && smmDHookRunStart != "") call void smmDHookRunStart();
		foreach i, t in smmDTasks {
			if (!smmDSelected(t, selector)) continue;
			smmDRunTask(t);
			if (dry) continue;
			if (current_round() > 0 || handling_choice()) {
				smmDLog(t.id, "STOP", "left in a fight or a choice");
				print("smmDaily: stopped after " + t.id + ": still in a fight or a choice. Resolve it, then smmdaily run.", "red");
				break;
			}
			if (smmDStopRun != "") {
				smmDLog(t.id, "STOP", smmDStopRun);
				print("smmDaily: stopped after " + t.id + ": " + smmDStopRun, "orange");
				break;
			}
			if (smmDSetting("halt") == t.id) {
				smmDSet("smm.daily.halt", ""); // one stop, not one every day
				smmDLog(t.id, "STOP", "smm.daily.halt");
				print("smmDaily: stopped after " + t.id + " (smm.daily.halt).", "orange");
				break;
			}
			if (epoch != smmDEpoch()) {
				print("smmDaily: rollover passed during the run; stopping.", "orange");
				break;
			}
		}
	} finally {
		if (!dry) {
			if (smmDHookRunEnd != "") call void smmDHookRunEnd();
			smmDSet("smm.daily.active", "");
		}
	}
}

// ---------------------------------------------------------------------------
// Reports

void smmDPrintTasks(string selector) {
	int phase = -1;
	foreach i, t in smmDTasks {
		if (!smmDSelected(t, selector)) continue;
		if (t.phase != phase) {
			phase = t.phase;
			print("Phase " + phase + ": " + smmDPhaseNames[phase], "blue");
		}
		string status = smmDTaskStatus(t);
		string color = status.starts_with("will run") ? "green" : status.starts_with("would run") ? "olive" : status.starts_with("FAILED") ? "red" : "gray";
		print("&nbsp;&nbsp;" + t.id + " [" + smmDConfiguredMode(t) + "] " + status + " - " + t.about, color);
	}
}

void smmDPrintJournal(int last) {
	smmDJournalLoad();
	int skip = last > 0 ? max(0, count(smmDJournal) - last) : 0;
	int at = 0;
	foreach seq, line in smmDJournal {
		at += 1;
		if (at <= skip) continue;
		print(line.at + " " + line.event + " " + line.task + " | turns " + line.turns + ", adv " + line.adventures
			+ ", Meat " + line.meat + ", MP " + line.mp + (line.note != "" ? " | " + line.note : ""));
	}
	if (count(smmDJournal) == 0) print("smmDaily: nothing in today's journal yet.");
}

void smmDPrintSettings() {
	foreach name, s in smmDSettings
		print("smm.daily." + name + " = " + smmDSetting(name) + (smmDGet("smm.daily." + name) == "" ? " (default)" : "") + " - " + s.about);
}
