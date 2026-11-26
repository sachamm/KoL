script "smmdaily";

// The daily run. See docs/daily-script.md.
//
//   smmdaily plan [phase|task]   what would run now, and why not for the rest
//   smmdaily dry [phase|task]    walk the day without doing anything
//   smmdaily run [phase|task]    run the day, or one phase or task of it
//   smmdaily status              tasks, spending, MP, turns, fence
//   smmdaily journal [n]         today's journal (the last n lines)
//   smmdaily retry <task>        let a failed or finished task run again
//   smmdaily book                book today's purchases as operating spend
//   smmdaily audit               price check and unused daily resources
//   smmdaily unfence             take fenced items back out of the closet
//   smmdaily settings            every smm.daily.* setting and its value
//   smmdaily reset               clear the run lock left by a crashed run

import <smmDailyTasks.ash>

void smmDailyHeader() {
	print("smmDaily " + smmDEpoch() + ": profile " + smmDSetting("profile") + ", "
		+ (smmDIsDryRun() ? "DRY RUN (" + (smmDSettingBool("runner") ? "smm.daily.dryRun" : "this machine is not the runner") + ")" : "runner")
		+ ", " + my_adventures() + " adventures, MP " + my_mp() + "/" + my_maxmp()
		+ ", Museum grind turns " + smmDMuseumTurnsUsed() + "/" + smmDSettingInt("museumTurns"), "blue");
	foreach i, warning in smmDTSettingWarnings()
		print("&nbsp;&nbsp;warning: " + warning, "orange");
	string problem = smmDPreflight();
	if (problem != "") print("&nbsp;&nbsp;cannot run now: " + problem, "red");
}

void main(string command) {
	command = replace_all(create_matcher("^\\s+|\\s+$", command), "");
	string verb = command;
	string rest = "";
	int space = command.index_of(" ");
	if (space > 0) {
		verb = command.substring(0, space);
		rest = replace_all(create_matcher("^\\s+", command.substring(space + 1)), "");
	}
	switch (verb.to_lower_case()) {
	case "":
	case "plan":
		smmDailyHeader();
		if (!smmDKnownSelector(rest)) abort("No phase or task is called '" + rest + "'.");
		smmDPrintTasks(rest);
		break;
	case "dry":
		smmDForceDry = true;
		smmDailyHeader();
		smmDRun(rest);
		break;
	case "run":
		smmDailyHeader();
		smmDRun(rest);
		break;
	case "status":
		smmDailyHeader();
		smmDPrintTasks("");
		smmSpendReport();
		smmDFenceStatus();
		if (smmDGet("smm.daily.active") != "") print("A run is marked active (" + smmDGet("smm.daily.active") + "). If none is running: smmdaily reset", "orange");
		break;
	case "journal":
		smmDPrintJournal(rest.to_int());
		break;
	case "retry":
		if (!(smmDTaskIndex contains rest)) abort("No task is called '" + rest + "'. Try smmdaily plan.");
		smmDRetry(rest);
		print("smmDaily: " + rest + " may run again. Daily counters and spending were kept.");
		break;
	case "book":
		smmDBookPurchases();
		smmSpendReport();
		smmDDietReport();
		break;
	case "audit":
		smmDBookPurchases();
		smmSpendReport();
		smmDDietReport();
		smmDPriceCheck();
		smmDTAudit();
		break;
	case "unfence":
		smmDUnfence();
		break;
	case "fence-status":
		smmDFenceStatus();
		break;
	case "settings":
		smmDPrintSettings();
		break;
	case "reset":
		if (handling_choice() || current_round() > 0) abort("Resolve the current encounter first.");
		smmDSet("smm.daily.active", "");
		smmDLRunEnd();
		print("smmDaily: cleared the run lock. Finished tasks, daily counters and spending were kept.");
		break;
	default:
		abort("Use smmdaily plan | dry | run [phase|task] | status | journal [n] | retry <task> | book | audit | fence-status | unfence | settings | reset");
	}
}
