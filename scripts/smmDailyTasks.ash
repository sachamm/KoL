// smmDaily: the day's task list, and the tasks that are new code.
// See docs/daily-script.md.

import <smmDailyLegacy.ash>

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

void smmDTOpen() {
	smmSpendDayStart(); // opening Meat for the day's spending budget, before anything is earned or bought
	foreach i, warning in smmDTSettingWarnings() {
		print("smmDaily: " + warning + ".", "orange");
		smmDLog("day.open", "NOTE", warning);
	}
	boolean unused = cli_execute("smmPrefs check");
	smmDLog("day.open", "NOTE", "opening Meat " + get_property(kSmmSpendStartKey) + ", " + my_adventures() + " adventures, profile " + smmDSetting("profile"));
}

// ---------------------------------------------------------------------------
// Phase 1: MP before anything casts

// Gear is left as it is: the floor is capped at the MP the current outfit
// holds, and second breakfast dresses for the day straight afterwards.
void smmDTBootstrap() {
	boolean unused;
	int before = my_mp();
	int target = smmDMpTarget();
	smmDFreeMP(target);
	// Breakfast summons that failed for lack of MP: KoLmafia's breakfast casts
	// only what still has casts left, so running it again is the repair.
	if (get_property("breakfastCompleted") != "true") {
		unused = cli_execute("breakfast");
		smmDFreeMP(target);
	}
	string note = "MP " + before + " to " + my_mp() + " (floor " + target + ", maximum " + my_maxmp() + "), breakfastCompleted=" + get_property("breakfastCompleted");
	smmDLog("mp.bootstrap", "NOTE", note);
	if (my_mp() < target) print("smmDaily: MP is " + my_mp() + ", under the floor of " + target + ", and the free restores are used up.", "orange");
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
	return "garbo -" + max(1, leaveTurns) + (args != "" ? " " + args : "");
}

string smmDTGarboReady() {
	int voa = get_property("valueOfAdventure").to_int();
	if (voa < 3500 || voa > 10000) return "valueOfAdventure is " + voa + ", outside 3,500 to 10,000";
	string problem = smmDTGarboArgsProblem(smmDSetting("garboArgs"));
	if (problem != "") return "smm.daily.garboArgs: " + problem;
	return "";
}

boolean smmDTGarboDone() {
	return get_property("_garboCompleted") != "" || my_adventures() <= smmDSettingInt("garboLeaveTurns");
}

void smmDTGarbo() {
	string command = smmDTGarboCommand(smmDSettingInt("garboLeaveTurns"), smmDSetting("garboArgs"));
	int operatingBefore = smmDBookPurchases();
	boolean finished = false;
	try {
		smmDFence();
		smmDLog("garbo", "NOTE", command + "; fenced " + get_property(kSmmDFencedKey));
		finished = cli_execute(command);
	} finally {
		smmDUnfence();
	}
	int bought = smmDBookPurchases() - operatingBefore;
	smmDLog("garbo", "NOTE", "garbo bought " + bought + " Meat of items; its own count: Meat " + get_property("garboResultsMeat")
		+ ", items " + get_property("garboResultsItems") + ", turns " + get_property("garboResultsTurns"));
	if (!finished) smmDStopRun = "garbo did not finish; smmdaily run starts it again";
}

// ---------------------------------------------------------------------------
// Phase 5: close

boolean smmDTUnfenceDone() {
	return get_property(kSmmDFencedKey) == "";
}

void smmDTUnfence() {
	smmDUnfence();
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
	"free rests|timesRested|0|",
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

void smmDTAudit() {
	int open = 0;
	print("smmDaily: daily resources with uses left:", "blue");
	foreach i, line in smmDTPools {
		SmmDPool pool = smmDTParsePool(line);
		if (smmDTPoolProblem(pool) != "" || !smmDTPoolOwned(pool)) continue;
		int limit = pool.limit > 0 ? pool.limit : total_free_rests();
		int used = smmDTPoolUsed(get_property(pool.pref));
		if (used >= limit) continue;
		open += 1;
		print("&nbsp;&nbsp;" + pool.label + ": " + used + " of " + limit + " used");
	}
	if (open == 0) print("&nbsp;&nbsp;none");
	smmDLog("close.report", "NOTE", open + " daily resources still have uses left; Museum grinds used " + smmDMuseumTurnsUsed() + " of "
		+ smmDSettingInt("museumTurns") + " paid turns; operating spend " + smmSpendOperating() + ", smmSpend " + smmSpendSpent()
		+ ", net " + smmSpendNet());
}

void smmDTReport() {
	smmDLLedger();
	smmDBookPurchases();
	smmSpendReport();
	smmDPriceCheck();
	smmDTAudit();
	timeToRollover();
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
	t.museum = flags.contains_text("museum");
	t.repeatable = flags.contains_text("repeat");
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
	// 2 free
	smmDTAdd(2, "route", "the IoTM route (legacy: all of it; on: free actions only)", "", "", "smmDLRouteFree", "smmDLRouteAll", "turns", "legacy", "on");
	smmDTAdd(2, "deeds", "daily deeds that cost no adventures", "", "", "", "smmDLDeeds", "", "legacy", "legacy");
	// 3 grinds
	smmDTAdd(3, "fishing", "sea grind on yesterday's Fishy", "smmDLFishingReady", "", "", "smmDLFishing", "turns", "legacy", "legacy");
	smmDTAdd(3, "bounty", "bounty hunting", "", "", "", "smmDLBounty", "turns", "legacy", "legacy");
	smmDTAdd(3, "champagne", "burn the champagne bottle's charge", "smmDLChampagneReady", "", "", "smmDLChampagne", "turns", "legacy", "off");
	smmDTAdd(3, "science", "science grind", "", "", "", "smmDLScience", "turns", "legacy", "legacy");
	smmDTAdd(3, "nep", "Neverending Party quest and free turns", "smmDLNepReady", "", "", "smmDLNep", "turns", "legacy", "legacy");
	smmDTAdd(3, "pregrind", "seek birds and dress for item drop", "", "smmDLPregrindDone", "", "smmDLPregrind", "", "legacy", "legacy");
	smmDTAdd(3, "oasis", "Oasis farming: scarab beatles or drum machines", "", "smmDLOasisDone", "", "smmDLOasis", "turns", "legacy", "off");
	smmDTAdd(3, "beerLens", "beer lenses", "smmDLBeerLensReady", "", "", "smmDLBeerLens", "turns museum", "legacy", "legacy");
	smmDTAdd(3, "ghostCostume", "li'l ghost costume", "smmDLGhostCostumeReady", "", "", "smmDLGhostCostume", "turns museum", "legacy", "legacy");
	smmDTAdd(3, "spacegate", "Spacegate", "smmDLSpacegateReady", "", "", "smmDLSpacegate", "turns museum", "legacy", "legacy");
	smmDTAdd(3, "fantasyRealm", "FantasyRealm, reward closest to Museum #1", "smmDLFantasyRealmReady", "", "", "smmDLFantasyRealm", "turns museum", "legacy", "legacy");
	smmDTAdd(3, "pirateRealm", "PirateRealm", "smmDLPirateRealmReady", "", "", "smmDLPirateRealm", "turns museum", "legacy", "legacy");
	smmDTAdd(3, "dailyDungeon", "Daily Dungeon", "smmDLDailyDungeonReady", "", "", "smmDLDailyDungeon", "turns museum", "legacy", "legacy");
	smmDTAdd(3, "drip", "the Drip", "smmDLDripReady", "", "", "smmDLDrip", "turns museum", "legacy", "legacy");
	smmDTAdd(3, "dolphin", "dolphin whistle for the waiting item", "smmDLDolphinReady", "", "", "smmDLDolphin", "turns", "legacy", "legacy");
	smmDTAdd(3, "workshed", "fuel Driving Observantly, then swap the Asdon for the model train set", "smmDLWorkshedReady", "", "", "smmDLWorkshed", "", "legacy", "legacy");
	smmDTAdd(3, "gingerbread", "Gingerbread City items", "", "", "", "smmDLGingerbread", "turns museum", "legacy", "legacy");
	smmDTAdd(3, "route.paid", "the IoTM route's paid-turn actions, after the grinds", "", "", "", "smmDLRouteAll", "turns museum", "off", "legacy");
	// 4 garbo
	smmDTAdd(4, "garbo", "fence, garbo -N, unfence", "smmDTGarboReady", "smmDTGarboDone", "smmDTGarbo", "", "turns", "dry", "on");
	// 5 close
	smmDTAdd(5, "close.unfence", "take back anything still closeted from a garbo run", "", "smmDTUnfenceDone", "smmDTUnfence", "", "repeat", "on", "on");
	smmDTAdd(5, "close.book", "book the day's purchases from the session log as operating spend", "", "", "smmDTBook", "", "repeat", "on", "on");
	smmDTAdd(5, "close.store", "restock the store", "", "", "", "smmDLStore", "repeat", "legacy", "legacy");
	smmDTAdd(5, "close.spend", "budgeted buying: positive-return items, then Display Case items on sale", "", "", "", "smmDLSpend", "repeat", "legacy", "legacy");
	smmDTAdd(5, "close.report", "ledgers, price check and the daily resources still unused", "", "", "smmDTReport", "", "repeat", "on", "on");

	smmDHookRunStart = "smmDLRunStart";
	smmDHookRunEnd = "smmDLRunEnd";
	return true;
}
boolean smmDTRegistered = smmDTRegisterAll();
