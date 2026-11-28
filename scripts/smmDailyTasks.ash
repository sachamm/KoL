// smmDaily: the day's task list, and the tasks that are new code.
// See docs/daily-script.md.

import <smmDailyLegacy.ash>
import <smmDailyIncome.ash>

// ---------------------------------------------------------------------------
// Phase 0: open the day

// Problems with the settings the day depends on, one per entry.
string [int] smmDTSettingWarnings() {
	string [int] warnings;
	int voa = get_property("valueOfAdventure").to_int();
	if (get_property("smm.TurnValue") == "")
		warnings[count(warnings)] = "smm.TurnValue is not set, so today's code values a turn at 5000 while valueOfAdventure is " + voa;
	else if (get_property("smm.TurnValue").to_int() != voa)
		warnings[count(warnings)] = "smm.TurnValue is " + get_property("smm.TurnValue") + " but valueOfAdventure is " + voa;
	if (get_property("autoSatisfyWithCloset") == "true")
		warnings[count(warnings)] = "autoSatisfyWithCloset is true, so closeting does not keep items from garbo";
	if (get_property("libramSkillsSoftcore") != "none")
		warnings[count(warnings)] = "libramSkillsSoftcore is not none, so breakfast spends the day's first MP on libram summons";
	if (get_property(kSmmDFencedKey) != "")
		warnings[count(warnings)] = "items are still closeted from an earlier garbo run (smmdaily unfence)";
	return warnings;
}

string smmDTCaseFile() { return "smm-daily-case-" + my_id() + ".txt"; }
void smmDTCaseOpen() {
 if (get_property("_smm.daily.caseEpoch") == smmDEpoch()) return;
 int [item] opening = get_display();
 if (!map_to_file(opening, smmDTCaseFile())) abort("smmDaily: could not save opening Display Case counts");
 set_property("_smm.daily.caseEpoch", smmDEpoch());
}
void smmDTMuseumReport() {
 if (get_property("_smm.daily.caseEpoch") != smmDEpoch()) {
  print("Museum: opening case snapshot missing; no daily rank gains claimed", "orange"); return;
 }
 int [item] opening;
 if (!file_to_map(smmDTCaseFile(), opening)) {
  print("Museum: opening case snapshot unreadable; no daily rank gains claimed", "orange"); return;
 }
 int copies = 0;
 int items = 0;
 int topTen = 0;
 int first = 0;
 int verified = 0; int verifiedTen = 0; int verifiedFirst = 0; int queried = 0;
 int started = smmMuseumNow();
 int limit = min(20, max(0, smmDSettingInt("museumVerifyLookups")));
 string epoch = smmDEpoch();
 string [item,string] evidence;
 foreach it, now in get_display() {
  int gained = now - opening[it];
  if (gained <= 0) continue;
  copies += gained; items += 1;
  SmmMuseumGoal goal = smmMuseumBounds(smmMuseumCachedCollection(it), my_name(), 11);
  if (goal.known && opening[it] < goal.tenth && now >= goal.tenth) topTen += 1;
  if (goal.known && opening[it] < goal.first_minimum && now >= goal.first_minimum) first += 1;
  boolean fetched = false;
  if (queried < limit) {
   smmDRequireEpoch(epoch);
   fetched = smmMuseumFetch(it);
   queried += 1;
   smmDRequireEpoch(epoch);
  }
  SmmMuseumEntry entry = smmMuseumEntry(it);
  int rank = smmDailyVerifiedRank(fetched, entry.checked, started, now, entry.mine, entry.my_rank);
  if (rank > 0) { verified += 1; if (rank <= 10) verifiedTen += 1; if (rank == 1) verifiedFirst += 1; }
  evidence[it,"opening"] = opening[it]; evidence[it,"closing"] = now;
  evidence[it,"queried"] = fetched; evidence[it,"checked"] = entry.checked;
  evidence[it,"pageCount"] = entry.mine; evidence[it,"verifiedRank"] = rank;
  evidence[it,"coverage"] = rank > 0 ? "fresh matching Museum row" : "unverified: request failed, budget exhausted or Museum count differs";
  print("Museum: confirmed case +" + gained + " " + it + " (" + opening[it] + " -> " + now + ")"
   + (rank > 0 ? ", current Museum rank " + rank : ", current Museum rank UNVERIFIED")
   + (goal.known ? ", short of cached top ten " + max(0, goal.tenth - now) + ", #1 " + max(0, goal.first_minimum - now) : ", ranking unknown"));
 }
 print("Museum: confirmed " + copies + " added copies across " + items + " items; crossed " + topTen + " top-ten and " + first
  + " #1 thresholds against cached competitors. Refresh ranks to confirm current standings.", "blue");
 print("Museum: fresh matching rows " + verified + "/" + items + "; current top ten " + verifiedTen + ", #1 " + verifiedFirst
  + "; " + queried + " requests. These current positions do not establish a daily rank gain.", "blue");
 if (!map_to_file(evidence, "smm-daily-museum-" + my_id() + "-" + today_to_string() + ".txt"))
  abort("smmDaily: could not write the Museum standing evidence");
 print("Collection loss: committed " + get_property("_smm.grind.collectionCommitted") + " / " + dailyGrindCollectionBudget()
  + "; observed opportunity loss " + get_property("_smm.grind.collectionLoss"), "blue");
}

void smmDTOpen() {
 smmDTCaseOpen();
	smmSpendDayStart(); // opening Meat for the day's spending budget, before anything is earned or bought
 smmIncomeOpen(smmSpendLiquidMeat(), get_property(kSmmSpendStartKey).to_int(), smmDTodaysLog());
	foreach i, warning in smmDTSettingWarnings() {
		print("smmDaily: " + warning + ".", "orange");
		smmDLog("day.open", "NOTE", warning);
	}
	// git update can bring new shared settings after they were last applied
	boolean unused = cli_execute(smmDSettingBool("applyPrefs") ? "smmPrefs apply" : "smmPrefs check");
	smmDLog("day.open", "NOTE", "opening Meat " + get_property(kSmmSpendStartKey) + ", " + my_adventures() + " adventures, profile " + smmDSetting("profile"));
}

boolean smmDTSettings =
	smmDDeclare("applyPrefs", "true", "day.open runs smmPrefs apply (true) or only smmPrefs check (false)");

// ---------------------------------------------------------------------------
// Phase 1: MP before anything casts

string smmDTTestBreakfast; // only used by the engine's offline test mode
void smmDTBreakfast() {
 if (smmDGet("breakfastCompleted") == "true" && smmDGet("_smm.daily.breakfastDeferred") != "true") return;
 smmDRequireActiveDay();
 boolean ok;
 if (smmDTestMode) {
  if (smmDTTestBreakfast == "") abort("breakfast test callback is required");
  ok = smmDCallBool(smmDTTestBreakfast);
 } else ok = smmDCommand("breakfast");
 smmDRequireActiveDay();
 if (ok && smmDGet("breakfastCompleted") == "true") smmDSet("_smm.daily.breakfastDeferred", "false");
 else if (smmDTaskProblem == "") smmDTaskProblem = "breakfast did not confirm its configured summons; retry after checking MP and settings";
}

// Gear is left as it is: the floor is capped at the MP the current outfit
// holds, and second breakfast dresses for the day straight afterwards.
void smmDTBootstrap() {
	boolean unused;
	int before = my_mp();
	int target = smmDMpTarget();
	smmDFreeMP(target);
	// Breakfast summons that failed for lack of MP: KoLmafia's breakfast casts
	// only what still has casts left, so running it again is the repair.
	if (smmDGet("breakfastCompleted") != "true" || smmDGet("_smm.daily.breakfastDeferred") == "true") {
		smmDTBreakfast();
		smmDFreeMP(target);
	}
	string note = "MP " + before + " to " + my_mp() + " (floor " + target + ", maximum " + my_maxmp() + "), breakfastCompleted=" + get_property("breakfastCompleted");
	smmDLog("mp.bootstrap", "NOTE", note);
	if (!smmDMpWorthRestoring(my_maxmp()))
		print("smmDaily: maximum MP is only " + my_maxmp() + ", so no free restore was spent. Something is holding it down: check the outfit and effects.", "orange");
	else if (my_mp() < target)
		print("smmDaily: MP is " + my_mp() + ", under the floor of " + target + ", and the free restores are used up.", "orange");
}

// ---------------------------------------------------------------------------
// Phase 1: the diet. diet.ash plans the whole day; each run buys and consumes
// one part of it. "yes" answers its question (it asks before buying).

string smmDTDietCommand(string part) {
	return "call diet.ash " + part + " yes";
}

boolean smmDTOrgansFull() {
	return my_fullness() >= fullness_limit() && my_inebriety() >= inebriety_limit() && my_spleen_use() >= spleen_limit();
}

string smmDTDietReady() {
	if (my_inebriety() > inebriety_limit()) return "overdrunk";
	return smmDTOrgansFull() ? "the organs are full" : "";
}

void smmDTDiet() {
	boolean unused = smmDCommand(smmDTDietCommand("execute"));
}

// ---------------------------------------------------------------------------
// Phase 4: forced noncombats, before garbo

// Fiesta Exits the Cincho de Mayo can still pay for: what is left of today's
// Cinch, plus what the free rests left would refill (30 for each of the first
// five rests, 5 less for each one after, never under 5). 60 Cinch an exit.
int smmDTCinchRestore(int restNumber) {
	return max(5, min(30, 50 - restNumber * 5));
}

int smmDTFiestaExitsLeft(int cinchUsed, int cinchoRests, int restsLeft) {
	int cinch = max(0, 100 - cinchUsed);
	for i from 0 upto restsLeft - 1
		cinch += smmDTCinchRestore(cinchoRests + i);
	return cinch / 60;
}

int smmDTForcedNoncombatsLeft() {
	int left = 0;
	if (available_amount($item[Jurassic Parka]) > 0) left += max(0, 5 - get_property("_spikolodonSpikeUses").to_int());
	if (available_amount($item[McHugeLarge left ski]) > 0) left += max(0, 3 - get_property("_mcHugeLargeAvalancheUses").to_int());
	if (available_amount($item[Cincho de Mayo]) > 0)
		left += smmDTFiestaExitsLeft(get_property("_cinchUsed").to_int(), get_property("_cinchoRests").to_int(),
			max(0, total_free_rests() - get_property("timesRested").to_int()));
	return left;
}

string smmDTForcedReady() {
	if (smmDTForcedNoncombatsLeft() <= 0) return "no spikes, Avalanches or Fiesta Exits left";
	if (available_amount($item[closed-circuit pay phone]) <= 0) return "no closed-circuit pay phone for Rufus's quest";
	return "";
}

// ---------------------------------------------------------------------------
// Phase 4: garbo

// Why these extra garbo arguments are refused, "" when they are fine.
string smmDTGarboArgsProblem(string args) {
	foreach i, word in args.to_lower_case().split_string("\\s+") {
		if (word == "") continue;
		if (word == "ascend") return "'ascend' spends every ember and coin";
		if (word.starts_with("workshed")) return "'workshed=' drains TakerSpace";
		if (word == "quick") return "'quick' skips garbo's setup";
		if (create_matcher("^-?[0-9]+$", word).find()) return "the turn count is set by smm.daily.garboLeaveTurns";
		if (word.starts_with("turns=")) return "the turn count is set by smm.daily.garboLeaveTurns";
	}
	return "";
}

// Always an explicit negative number: "garbo 0" and a bare "garbo" mean no limit.
string smmDTGarboCommand(int leaveTurns, string args) {
	return "smmDailyGarbo -" + max(1, leaveTurns) + (args != "" ? " " + args : "");
}

string smmDTGarboReady() {
	int voa = get_property("valueOfAdventure").to_int();
	if (voa < 3500 || voa > 10000) return "valueOfAdventure is " + voa + ", outside 3,500 to 10,000";
	string problem = smmDTGarboArgsProblem(smmDSetting("garboArgs"));
	if (problem != "") return "smm.daily.garboArgs: " + problem;
	return "";
}

// garbo clears _garboCompleted when it starts and sets it when it finishes.
// Few adventures left is not a sign that it ran: garbo eats and drinks the
// day's diet first, which is where its adventures come from.
boolean smmDTGarboCompletion(string completed, string paidHold) {
	return completed != "" && paidHold == "";
}

boolean smmDTGarboDone() {
	return smmDTGarboCompletion(get_property("_garboCompleted"), get_property("_smm.daily.garboPaidHold"));
}

void smmDTRunStart() {
 smmDLRunStart();
 string completed = get_property("_garboCompleted");
 string hold = get_property("_smm.daily.garboPaidHold");
 boolean access = get_property("stenchAirportAlways") == "true" || get_property("_stenchAirportToday") == "true";
 if (!smmDailyCanReconcileGarbo(completed, hold, access, smmDSettingInt("garboLeaveTurns"))) return;
 // Current native completion plus actual access supersedes an earlier paid
 // access hold. Never clear native counters or call manual work unattended.
 smmDLog("garbo", "NOTE", "recognized standard native completion '" + completed + "' with paid access; prior/manual work is not unattended evidence");
 set_property("_smm.daily.garboPaidHold", "");
 print("smmDaily: recognized completed standard garbo with paid access; cleared the stale access hold. Prior/manual work is not unattended evidence.", "blue");
}

void smmDTGarboRun(string task, string command) {
	int operatingBefore = smmDBookPurchases();
	boolean finished = false;
	boolean autoConfirm = smmDSettingBool("garboAutoConfirm");
	string confirmBefore = smmDGet("garbo_autoUserConfirm");
 string closetBefore = smmDGet("autoSatisfyWithCloset");
	try {
		if (autoConfirm) smmDSet("garbo_autoUserConfirm", "true");
  smmDSet("autoSatisfyWithCloset", "false");
		smmDFence();
		smmDLog(task, "NOTE", command + "; fenced " + get_property(kSmmDFencedKey));
		finished = smmDCommand(command);
	} finally {
  try { smmDUnfence(); }
  finally {
   if (autoConfirm) smmDSet("garbo_autoUserConfirm", confirmBefore);
   smmDSet("autoSatisfyWithCloset", closetBefore);
  }
	}
	int bought = smmDBookPurchases() - operatingBefore;
	smmDLog(task, "NOTE", "garbo bought " + bought + " Meat of items; its own count: Meat " + get_property("garboResultsMeat")
		+ ", items " + get_property("garboResultsItems") + ", turns " + get_property("garboResultsTurns"));
	if (!finished) smmDStopRun = "garbo did not finish; smmdaily run starts it again";
 if (finished && get_property("_smm.daily.garboPaidHold") != "")
  smmDTaskProblem = "garbo's daily worker returned, but paid farming remains held: " + get_property("_smm.daily.garboPaidHold");
 if (get_property(kSmmDFencedKey) != "") smmDStopRun = "fenced items remain unreconciled; resolve them before continuing";
}

void smmDTGarbo() {
	smmDTGarboRun("garbo", smmDTGarboCommand(smmDSettingInt("garboLeaveTurns"), smmDSetting("garboArgs")));
}

// ---------------------------------------------------------------------------
// Phase 5: the nightcap, in the order it was run by hand: the free work held
// for the end of the day, the diet's turn generation, garbo down to the
// diet's stop point, the nightcap drink, the overdrunk turns, good_night.

string smmDTAfterGarboReady() {
	return smmDTGarboDone() ? "" : "garbo has not finished today (run it, or set smm.daily.task.garbo = on)";
}

string smmDTSoberAfterGarboReady() {
	if (my_inebriety() > inebriety_limit()) return "overdrunk: the nightcap is in";
	return smmDTAfterGarboReady();
}

void smmDTDietTurngen() {
	boolean unused = smmDCommand(smmDTDietCommand("turngen"));
}

// diet.ash records the stop point of its last plan in _smm.diet.stopAt: the
// adventures to hold for after the nightcap. With none to hold, garbo spends
// them all ("garbo" with no number).
int smmDTStopPoint(string stored) {
	return stored.is_integer() ? max(0, stored.to_int()) : 0;
}

string smmDTGarboFinalCommand(int stopAt, string args) {
	return (stopAt > 0 ? "smmDailyGarbo -" + stopAt : "smmDailyGarbo") + (args != "" ? " " + args : "");
}

string smmDTGarboFinalReady() {
	string why = smmDTSoberAfterGarboReady();
	if (why != "") return why;
	why = smmDTGarboReady();
	if (why != "") return why;
	int stopAt = smmDTStopPoint(get_property("_smm.diet.stopAt"));
	if (my_adventures() <= stopAt) return my_adventures() + " adventures, at or under the diet's stop point of " + stopAt;
	return "";
}

void smmDTGarboFinal() {
	smmDTGarboRun("garbo.final", smmDTGarboFinalCommand(smmDTStopPoint(get_property("_smm.diet.stopAt")), smmDSetting("garboArgs")));
}

boolean smmDTOverdrunk() {
	return my_inebriety() > inebriety_limit();
}

// diet.ash finish plans again with the drunkenness Sweat Out Some Booze frees,
// which turngen leaves out, so its stop point can be lower than the one
// garbo.final stopped at (sweat also builds while garbo runs). It then
// refuses, having recorded the new stop point: spend down to it and finish
// again.
void smmDTDietFinish() {
	int spendDowns = 0;
	while (true) {
		boolean unused = smmDCommand(smmDTDietCommand("finish"));
  if (smmDTaskProblem != "") return;
		if (smmDTOverdrunk() || smmDStopRun != "") return;
		int stopAt = smmDTStopPoint(get_property("_smm.diet.stopAt"));
		if (my_adventures() <= stopAt || spendDowns >= 2) return; // refused for another reason, or not settling
		// the engine's turn gate, which garbo.final passed and this task does not go through
		if (smmDSecondsToRollover() < smmDSettingInt("rolloverBufferMin") * 60) {
			smmDLog("diet.finish", "NOTE", "finish wants garbo down to " + stopAt + ", but rollover is too close: left for the next run");
			return;
		}
		// and garbo.final's own checks (garbo's arguments, valueOfAdventure)
		string garboWhy = smmDTGarboReady();
		if (garboWhy != "") {
			smmDLog("diet.finish", "NOTE", "finish wants garbo down to " + stopAt + ", but garbo is not ready: " + garboWhy);
			return;
		}
		spendDowns += 1;
		smmDLog("diet.finish", "NOTE", "finish's stop point is " + stopAt + " with " + my_adventures() + " adventures held: garbo down to it");
		smmDTGarboRun("diet.finish", smmDTGarboFinalCommand(stopAt, smmDSetting("garboArgs")));
		if (smmDStopRun != "") return;
	}
}

string smmDTOverdrunkReady() {
	return smmDTOverdrunk() ? "" : "the nightcap is not in yet";
}

// The engine's rollover gate is for sober turn-spending tasks (it refuses
// any overdrunk). good_night_adv spends overdrunk turns, so it checks the
// rollover buffer itself and waits for the next run.
string smmDTOverdrunkTurnsReady() {
	string why = smmDTOverdrunkReady();
	if (why != "") return why;
	if (smmDSecondsToRollover() < smmDSettingInt("rolloverBufferMin") * 60) return "too close to rollover to spend turns";
	return "";
}

boolean smmDTSpinnerDone() {
 return smmDailySourceUnavailable(available_amount($item[Time-Spinner]) > 0, get_property("_timeSpinnerMinutesUsed").to_int(), 10);
}
boolean smmDTLocketDone() {
 return smmDailySourceUnavailable(available_amount($item[Combat Lover's Locket]) > 0, cllNumMonstersFought(), 3);
}

// ---------------------------------------------------------------------------
// Phase 5: close

boolean smmDTUnfenceDone() {
 SmmDFenceState fence = smmDFenceRead();
 return fence.direction == 0 && fence.fenced == "";
}

void smmDTUnfence() {
	smmDUnfence();
 SmmDFenceState fence = smmDFenceRead();
 if (fence.direction != 0 || fence.fenced != "") smmDTaskProblem = "fenced items remain unreconciled";
}

void smmDTBook() {
	smmDBookPurchases();
}

// Daily resources that still have uses left. Each line is
//   label | preference that counts uses | uses a day | what must be owned
// where the last field is empty, item:<name>, skill:<name>, familiar:<name>,
// camp:<name> (an item in the campground) or pref:<name>=<value>.
// A use limit of 0 means "the number of free rests".
string [int] smmDTPools = {
	"bat-wing rests|_batWingsRestUsed|11|item:bat wings",
	"nuns visits|nunsVisits|3|pref:sidequestNunsCompleted=fratboy",
	"free rests (each refills Cinch: keep them for Fiesta Exit)|timesRested|0|",
	"Cinch (Fiesta Exit costs 60 and forces a noncombat)|_cinchUsed|100|item:Cincho de Mayo",
	"spikolodon spikes (force a noncombat)|_spikolodonSpikeUses|5|item:Jurassic Parka",
	"McHugeLarge Avalanche (forces a noncombat)|_mcHugeLargeAvalancheUses|3|item:McHugeLarge duffel bag",
	"Apriling band tuba (forces a noncombat)|_aprilBandTubaUses|3|item:Apriling band tuba",
	"Allied Radio drops (sniper support forces a noncombat)|_alliedRadioDropsUsed|3|item:Allied Radio Backpack",
	"Clara's bell (forces a noncombat)|_claraBellUsed|1|item:Clara's bell",
	"free Sneakisol (forces a noncombat)|_freePillKeeperUsed|1|item:Eight Days a Week Pill Keeper",
	"License to Chill|_licenseToChillUsed|1|item:License to Chill",
	"eternal car battery|_eternalCarBatteryUsed|1|item:eternal car battery",
	"Hermit clovers|_cloversPurchased|3|",
	"Neverending Party free fights|_neverendingPartyFreeTurns|10|pref:neverendingPartyAlways=true",
	"God Lobster fights|_godLobsterFights|3|familiar:God Lobster",
	"Witchess fights|_witchessFights|5|camp:Witchess Set",
	"voting booth free fights|_voteFreeFights|3|pref:voteAlways=true",
	"Speakeasy free fights|_speakeasyFreeFights|3|pref:ownsSpeakeasy=true",
	"Snojo free fights|_snojoFreeFights|10|pref:snojoAvailable=true",
	"Tunnel of L.O.V.E.|_loveTunnelUsed|1|pref:loveTunnelAvailable=true",
	"science tent tentacle|_eldritchTentacleFought|1|",
	"Evoke Eldritch Horror|_eldritchHorrorEvoked|1|skill:Evoke Eldritch Horror",
	"Sword of S Words kills|_swordOfSWordsKills|100|familiar:Sword of S Words",
	"backup camera|_backUpUses|11|item:backup camera",
	"fax machine|_photocopyUsed|1|item:Clan VIP Lounge key",
	"Chest X-Ray|_chestXRayUsed|3|item:Lil' Doctor&trade; bag",
	"Reflex Hammer|_reflexHammerUsed|3|item:Lil' Doctor&trade; bag",
	"Shattering Punch|_shatteringPunchUsed|3|skill:Shattering Punch",
	"Gingerbread Mob Hit|_gingerbreadMobHitUsed|1|skill:Gingerbread Mob Hit",
	"Feel Hatred|_feelHatredUsed|3|skill:Feel Hatred",
	"Snokebomb|_snokebombUsed|3|skill:Snokebomb",
	"KGB tranquilizer darts|_kgbTranquilizerDartUses|3|item:Kremlin's Greatest Briefcase",
	"saber Force|_saberForceUses|5|item:Fourth of May Cosplay Saber",
	"Macrometeorite|_macrometeoriteUses|10|skill:Macrometeorite",
	"Powerful Glove battery|_powerfulGloveBatteryPowerUsed|100|item:Powerful Glove",
	"latte refills|_latteRefillsUsed|3|item:latte lovers member's mug",
	"genie wishes|_genieWishesUsed|3|item:genie bottle",
	"monkey paw wishes|_monkeyPawWishesUsed|5|item:cursed monkey's paw",
	"Deck of Every Card draws|_deckCardsDrawn|15|item:Deck of Every Card",
	"Time-Spinner minutes|_timeSpinnerMinutesUsed|10|item:Time-Spinner",
	"free beach walks|_freeBeachWalksUsed|11|item:Beach Comb",
	"Sweat Out Some Booze|_sweatOutSomeBoozeUsed|3|item:designer sweatpants",
	"Bastille Battalion|_bastilleGames|1|item:Bastille Battalion control rig",
	"molehill mountain|_molehillMountainUsed|1|item:molehill mountain",
	"pool table|_poolGames|3|item:Clan VIP Lounge key",
};

record SmmDPool {
	string label;
	string pref;
	int limit;
	string kind; // "", item, skill, familiar, camp, pref
	string need;
};

SmmDPool smmDTParsePool(string line) {
	SmmDPool pool;
	string [int] fields = line.split_string("\\|");
	if (count(fields) < 3) return pool;
	pool.label = fields[0];
	pool.pref = fields[1];
	pool.limit = fields[2].to_int();
	string owned = count(fields) > 3 ? fields[3] : "";
	int colon = owned.index_of(":");
	if (colon > 0) {
		pool.kind = owned.substring(0, colon);
		pool.need = owned.substring(colon + 1);
	}
	return pool;
}

// "" when the pool's requirement is written correctly and names something real.
string smmDTPoolProblem(SmmDPool pool) {
	if (pool.label == "" || pool.pref == "") return "needs a label and a preference";
	switch (pool.kind) {
	case "": return "";
	case "item": return pool.need.to_item() != $item[none] ? "" : "no item called " + pool.need;
	case "camp": return pool.need.to_item() != $item[none] ? "" : "no item called " + pool.need;
	case "skill": return pool.need.to_skill() != $skill[none] ? "" : "no skill called " + pool.need;
	case "familiar": return pool.need.to_familiar() != $familiar[none] ? "" : "no familiar called " + pool.need;
	case "pref": return pool.need.index_of("=") > 0 ? "" : "pref: needs name=value";
	}
	return "unknown requirement " + pool.kind;
}

boolean smmDTPoolOwned(SmmDPool pool) {
	switch (pool.kind) {
	case "": return true;
	case "item": return available_amount(pool.need.to_item()) > 0;
	case "camp": return get_campground() contains pool.need.to_item();
	case "skill": return have_skill(pool.need.to_skill());
	case "familiar": return have_familiar(pool.need.to_familiar());
	case "pref":
		int equals = pool.need.index_of("=");
		return equals > 0 && get_property(pool.need.substring(0, equals)) == pool.need.substring(equals + 1);
	}
	return false;
}

// Uses counted by a preference that is either a number or true/false.
int smmDTPoolUsed(string value) {
	if (value == "true") return 1;
	if (value == "false" || value == "") return 0;
	return value.to_int();
}

string smmDTPoolOwner(SmmDPool pool) {
 string pref = pool.pref.to_lower_case();
 if (pref == "timesrested" || pref.contains_text("cinch") || pref.contains_text("spikolodon") || pref.contains_text("avalanche")) return "forced.nc";
 if (pref.contains_text("restused") || pref == "nunsvisits" || pref == "_eternalcarbatteryused" || pref.contains_text("licensetochill")) return "mp.bootstrap / goodnight";
 if (pref == "_powerfulglovebatterypowerused") return "route / garbo";
 if (pref.contains_text("hatred") || pref.contains_text("snoke") || pref.contains_text("tranquilizer") || pref.contains_text("saberforce")) return "grinds / garbo";
 if (pref.contains_text("neverendingparty")) return "nep";
 if (pref.contains_text("sweatout")) return "diet.finish";
 if (pref.contains_text("timespinner")) return "goodnight.adv.spinner";
 if (pref.contains_text("photocopy")) return "goodnight.adv.fax";
 return "route / garbo / goodnight";
}
string smmDTPoolBlocked(SmmDPool pool) {
 if (pool.pref == "_neverendingPartyFreeTurns") return get_property("_smm.nep.blocked");
 if ((pool.pref == "_cinchUsed" || pool.pref == "timesRested") && smmDTFiestaExitsLeft(get_property("_cinchUsed").to_int(),
  get_property("_cinchoRests").to_int(), max(0, total_free_rests() - get_property("timesRested").to_int())) == 0)
  return "remaining Cinch and free rests cannot fund another Fiesta Exit";
 return "";
}

void smmDTAudit() {
	int open = 0;
	print("smmDaily: daily resource outcomes (unspent does not by itself mean wasted):", "blue");
	// the nightcap and good_night spend much of this list
	if (my_inebriety() <= inebriety_limit())
		print("&nbsp;&nbsp;(before the nightcap: the nightcap steps and good_night still spend the free fights, free kills and the rest of the Cinch. The close phase after them shows what really went unused.)", "gray");
	if (available_amount($item[Cincho de Mayo]) > 0)
		print("&nbsp;&nbsp;Fiesta Exits the Cinch and free rests still pay for: " + smmDTFiestaExitsLeft(get_property("_cinchUsed").to_int(),
			get_property("_cinchoRests").to_int(), max(0, total_free_rests() - get_property("timesRested").to_int())));
	foreach i, line in smmDTPools {
		SmmDPool pool = smmDTParsePool(line);
		if (smmDTPoolProblem(pool) != "" || !smmDTPoolOwned(pool)) continue;
		int limit = pool.limit > 0 ? pool.limit : total_free_rests();
		int used = smmDTPoolUsed(get_property(pool.pref));
  string owner = smmDTPoolOwner(pool);
  boolean failed = false;
  foreach j, task in owner.split_string(" / ")
   if (get_property("_smm.daily.failed." + task) == smmDEpoch()) failed = true;
  string state = smmDailyResourceState(used, limit, smmDTPoolBlocked(pool), get_property("smm.daily.resourceReason." + pool.pref), owner, failed);
  if (used < limit) open += 1;
  print("&nbsp;&nbsp;" + pool.label + ": " + used + " of " + limit + "; owner " + owner + "; " + state);
	}
	if (open == 0) print("&nbsp;&nbsp;none");
 SmmRPResource [string] shared = smmRPLiveResources();
 SmmRPReservation [int] reservations = smmRPReservations();
 print("Shared planner pools: remaining capacity and reservations; availability is not proof of a profitable action.", "blue");
 foreach id, pool in shared {
  if (pool.known && pool.remaining <= 0) continue;
  string owners = "";
  foreach j, entry in reservations if (entry.resource == id && entry.units > 0) owners += entry.owner + ":" + entry.units + " ";
  print("&nbsp;&nbsp;" + id + ": " + (pool.known ? pool.remaining.to_string() : "unknown")
   + (owners != "" ? "; reserved " + owners : "; no planner reservation") + (pool.reason != "" ? "; " + pool.reason : ""));
 }
	smmDLog("close.report", "NOTE", open + " daily resources still have uses left; Museum grinds used " + smmDMuseumTurnsUsed() + " of "
		+ smmDSettingInt("museumTurns") + " paid turns; operating spend " + smmSpendOperating() + ", smmSpend " + smmSpendSpent() + ", diet " + get_property("_smm.diet.spent")
		+ ", net " + smmSpendNet());
}

// The day is over only when the nightcap is in. A diet.ash finish that refused
// (more adventures held than its stop point) leaves the day open: say so.
string smmDTDayEndProblem() {
 SmmDFenceState fence = smmDFenceRead();
 if (fence.direction != 0) return "pending fence transfer requires reconciliation";
 if (fence.fenced != "") return "fenced items remain unreconciled";
 if (get_property(kSmmDFencedKey) != "") return "fenced items remain unreconciled";
 string taskProblem = smmDCompletionProblem();
 if (taskProblem != "") return taskProblem;
	if (!smmDTGarboDone()) return "garbo has not finished today";
	if (!smmDTOverdrunk()) return "the nightcap is not in: spend down to the diet's stop point (_smm.diet.stopAt = " + get_property("_smm.diet.stopAt") + "), then smmdaily run nightcap";
	return "";
}

void smmDTReport() {
	string open = smmDTDayEndProblem();
 if (open != "") print("smmDaily: the day is not finished: " + open + ".", "orange");

 smmDTMuseumReport();
	smmDLLedger();
	smmDBookPurchases();
	smmSpendReport();
	smmDDietReport();
	SmmDPriceAudit prices = smmDPriceCheck();
 string finance = smmDPriceAuditProblem(prices);
 string budget = smmDBudgetProblem(smmSpendNet(), smmSpendSpent(), smmSpendOperating(), smmSpendDietPurchases(), smmSpendFraction());
 if (budget != "") {
  print("smmDaily: " + budget, "orange");
  if (finance == "") finance = budget;
 }
 if (finance != "") {
  print("smmDaily: financial review required: " + finance, "orange");
  smmDTaskProblem = finance;
  if (open == "") open = finance;
 }
	smmDTAudit();
 smmIncomeReport(smmSpendLiquidMeat(), smmDTodaysLog());
	timeToRollover();
 set_property("_smm.daily.complete", open == "" ? smmDEpoch() : "");
 print("SMM_DAILY_RESULT " + (open == "" ? "COMPLETE" : "INCOMPLETE: " + open), open == "" ? "green" : "red");
}

// ---------------------------------------------------------------------------
// The day, in order. A task's two modes are its defaults in the legacy
// profile (today's behaviour) and the plan profile.

void smmDTAdd(int phase, string id, string about, string ready_fn, string done_fn, string do_fn, string legacy_fn,
		string flags, string mode_legacy, string mode_plan) {
	SmmDTask t = smmDNewTask(id, phase, about);
	t.ready_fn = ready_fn;
	t.done_fn = done_fn;
	t.do_fn = do_fn;
	t.legacy_fn = legacy_fn;
	t.spends_turns = flags.contains_text("turns");
	t.on_is_free = flags.contains_text("on-free");
	t.museum = flags.contains_text("museum");
	t.repeatable = flags.contains_text("repeat");
	matcher need = create_matcher("need=([A-Za-z0-9_]+)", flags);
	if (need.find()) {
		if (need.group(1).is_integer()) t.need = need.group(1).to_int();
		else t.need_fn = need.group(1);
	}
	t.mode_legacy = mode_legacy;
	t.mode_plan = mode_plan;
	smmDRegister(t);
}

boolean smmDTRegisterAll() {
	// 0 preflight
	smmDTAdd(0, "day.open", "record the opening Meat and check the shared settings", "", "", "smmDTOpen", "", "", "on", "on");
	smmDTAdd(0, "store.open", "restock the store", "", "", "", "smmDLStore", "", "legacy", "legacy");
	// 1 breakfast
	smmDTAdd(1, "mp.bootstrap", "restore MP from free sources, then repeat any breakfast summon that failed", "", "", "smmDTBootstrap", "", "", "on", "on");
	smmDTAdd(1, "breakfast.second", "second breakfast: collections, mood, outfit, daily buffs", "", "smmDLSecondBreakfastDone", "", "smmDLSecondBreakfast", "", "legacy", "legacy");
	smmDTAdd(1, "drip.prep", "drippy nugget and drippy wine, before the diet fills the organs", "smmDLDripPrepReady", "", "", "smmDLDripPrep", "", "legacy", "legacy");
	smmDTAdd(1, "diet", "diet.ash: buy and consume the first part of the day's diet", "smmDTDietReady", "", "smmDTDiet", "", "", "on", "on");
	// 2 free
	smmDTAdd(2, "route", "the IoTM route (legacy: all of it; on: free actions only)", "", "smmDLRouteDone", "smmDLRouteFree", "smmDLRouteAll", "turns on-free", "legacy", "on");
	smmDTAdd(2, "deeds", "daily deeds that cost no adventures", "", "", "", "smmDLDeeds", "", "legacy", "legacy");
	// 3 grinds. need=N (or need=<function>) is how many adventures the grind
	// takes to finish, from dailyGrind's own notes and the turns each took on
	// 2026-11-23. A grind is
	// not started with fewer, because today's code stops with an error when the
	// adventures run out halfway (FantasyRealm did on the first live run).
	smmDTAdd(3, "fishing", "sea grind on yesterday's Fishy", "smmDLFishingReady", "", "", "smmDLFishing", "turns need=20", "legacy", "legacy");
	smmDTAdd(3, "bounty", "bounty hunting", "", "", "", "smmDLBounty", "turns need=20", "legacy", "legacy");
	smmDTAdd(3, "hold", "stop here when smm.dailyGrind.useBanishers or highItem is false", "smmDLHoldReady", "", "", "smmDLHold", "repeat", "legacy", "legacy");
	smmDTAdd(3, "champagne", "burn the champagne bottle's charge", "smmDLChampagneReady", "", "", "smmDLChampagne", "turns need=11", "legacy", "off");
	smmDTAdd(3, "science", "science grind", "", "", "", "smmDLScience", "turns", "legacy", "legacy");
	smmDTAdd(3, "nep", "Neverending Party quest and free turns", "smmDLNepReady", "", "", "smmDLNep", "turns", "legacy", "legacy");
	smmDTAdd(3, "pregrind", "seek birds and dress for item drop", "", "smmDLPregrindDone", "", "smmDLPregrind", "", "legacy", "legacy");
	smmDTAdd(3, "oasis", "Oasis farming: scarab beatles or drum machines", "", "smmDLOasisDone", "", "smmDLOasis", "turns", "legacy", "off");
	smmDTAdd(3, "beerLens", "beer lenses", "smmDLBeerLensReady", "", "", "smmDLBeerLens", "turns museum need=9", "legacy", "legacy");
	smmDTAdd(3, "ghostCostume", "li'l ghost costume", "smmDLGhostCostumeReady", "", "", "smmDLGhostCostume", "turns museum need=11", "legacy", "legacy");
	smmDTAdd(3, "spacegate", "Spacegate", "smmDLSpacegateReady", "", "", "smmDLSpacegate", "turns museum need=20", "legacy", "legacy");
	smmDTAdd(3, "fantasyRealm", "FantasyRealm, reward closest to Museum #1", "smmDLFantasyRealmReady", "", "", "smmDLFantasyRealm", "turns museum need=smmDLFantasyRealmNeed", "legacy", "legacy");
	smmDTAdd(3, "pirateRealm", "PirateRealm", "smmDLPirateRealmReady", "", "", "smmDLPirateRealm", "turns museum need=35", "legacy", "legacy");
	smmDTAdd(3, "dailyDungeon", "Daily Dungeon", "smmDLDailyDungeonReady", "", "", "smmDLDailyDungeon", "turns museum need=15", "legacy", "legacy");
	smmDTAdd(3, "drip", "the Drip", "smmDLDripReady", "", "", "smmDLDrip", "turns museum need=15", "legacy", "legacy");
	smmDTAdd(3, "dolphin", "dolphin whistle for the waiting item", "smmDLDolphinReady", "", "", "smmDLDolphin", "turns", "legacy", "legacy");
	smmDTAdd(3, "workshed", "fuel Driving Observantly, then swap the Asdon for the model train set", "smmDLWorkshedReady", "", "", "smmDLWorkshed", "", "legacy", "legacy");
	smmDTAdd(3, "gingerbread", "Gingerbread City items", "", "", "", "smmDLGingerbread", "turns museum need=20", "legacy", "legacy");
	smmDTAdd(3, "route.paid", "the IoTM route's paid-turn actions, after the grinds", "", "smmDLRoutePaidDone", "", "smmDLRouteAll", "turns museum", "off", "legacy");
	// 4 garbo. The forced noncombats go first: garbo spends free rests and Cinch otherwise.
	smmDTAdd(4, "forced.nc", "spikes, Avalanches and Fiesta Exits at the Shadow Rift, before garbo (a paid Rift fight when no free fight is left)", "smmDTForcedReady", "", "", "smmDLForcedNoncombats", "turns", "legacy", "legacy");
	smmDTAdd(4, "garbo", "fence, garbo -N, unfence", "smmDTGarboReady", "smmDTGarboDone", "smmDTGarbo", "", "turns", "on", "on");
	// 5 nightcap
	smmDTAdd(5, "nightcap.before", "beforeOverdrunkGoodNight: store, route, Oliver's Place, Shadow Rifts", "smmDTSoberAfterGarboReady", "", "", "smmDLBeforeOverdrunk", "turns", "legacy", "legacy");
	smmDTAdd(5, "diet.turngen", "diet.ash: chocolates, sausages and other turn generation", "smmDTSoberAfterGarboReady", "", "smmDTDietTurngen", "", "", "on", "on");
	smmDTAdd(5, "garbo.final", "fence, garbo down to the diet's stop point, unfence", "smmDTGarboFinalReady", "", "smmDTGarboFinal", "", "turns", "on", "on");
	smmDTAdd(5, "diet.finish", "diet.ash: the rest of the diet and the nightcap drink", "smmDTSoberAfterGarboReady", "smmDTOverdrunk", "smmDTDietFinish", "", "", "on", "on");
	smmDTAdd(5, "goodnight.adv", "good_night_adv: the overdrunk turns", "smmDTOverdrunkTurnsReady", "", "", "smmDLGoodNightAdv", "", "legacy", "legacy");
 smmDTAdd(5, "goodnight.adv.fax", "overdrunk fax fight", "smmDTOverdrunkTurnsReady", "", "", "smmDLGoodNightFax", "", "legacy", "legacy");
 smmDTAdd(5, "goodnight.adv.spinner", "overdrunk Time-Spinner fights", "smmDTOverdrunkTurnsReady", "smmDTSpinnerDone", "", "smmDLGoodNightSpinner", "", "legacy", "legacy");
 smmDTAdd(5, "goodnight.adv.locket", "overdrunk locket fights", "smmDTOverdrunkTurnsReady", "smmDTLocketDone", "", "smmDLGoodNightLocket", "", "legacy", "legacy");
 smmDTAdd(5, "goodnight.adv.daycare", "Boxing Daycare scavenging", "smmDTOverdrunkTurnsReady", "", "", "smmDLGoodNightDaycare", "", "legacy", "legacy");
 smmDTAdd(5, "goodnight.adv.excess", "spend adventures above the rollover cap", "smmDTOverdrunkTurnsReady", "", "", "smmDLGoodNightExcess", "", "legacy", "legacy");
 smmDTAdd(5, "goodnight", "good_night: rollover gear, free uses, budgeted buying", "smmDTOverdrunkReady", "", "", "smmDLGoodNight", "", "legacy", "legacy");
	// 6 close
	smmDTAdd(6, "close.unfence", "take back anything still closeted from a garbo run", "", "smmDTUnfenceDone", "smmDTUnfence", "", "repeat", "on", "on");
	smmDTAdd(6, "close.book", "book the day's purchases from the session log as operating spend", "", "", "smmDTBook", "", "repeat", "on", "on");
	smmDTAdd(6, "close.store", "restock the store", "", "", "", "smmDLStore", "repeat", "legacy", "legacy");
	smmDTAdd(6, "close.spend", "budgeted buying: positive-return items, then Display Case items on sale", "", "", "", "smmDLSpend", "repeat", "legacy", "legacy");
	smmDTAdd(6, "close.report", "ledgers, price check and the daily resources still unused", "", "", "smmDTReport", "", "repeat", "on", "on");

	smmDHookRunStart = "smmDTRunStart";
	smmDHookRunEnd = "smmDLRunEnd";
	return true;
}
boolean smmDTRegistered = smmDTRegisterAll();
