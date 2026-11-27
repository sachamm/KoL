// smmDaily: the safeguards around today's code. See docs/daily-script.md.
//
//   - Booking: every purchase in today's session log that did not go through
//     smmSpend or diet.ash (the old daily code, garbo, buying by hand) counts
//     as operating spend against the half-of-net rule. diet.ash has a budget
//     of its own (smm.diet.budget). Every mall purchase, the diet's too, is
//     checked against the average sale price afterwards.
//   - MP: restore to a floor from free daily sources, so a day that starts at
//     0 MP does not stall.
//   - Fence: items closeted while garbo runs.
//
// The parsing and arithmetic are plain functions with no game access, tested
// in tests/ash/.

import <smmDailyCore.ash>
import <smmSpend.ash>
import <smmDailyPolicy.ash>
import <smmDailyFence.ash>

boolean smmDGateSettings =
	smmDDeclare("priceCheckLookups", "150", "maximum distinct mall items to quote; unknown or unchecked requests leave price compliance unverified")
	&& smmDDeclare("fullRestoreAt", "2000", "License to Chill (a full restore) is used only when this much MP is missing");

// ---------------------------------------------------------------------------
// Purchases in the session log

record SmmDPurchase {
	string name;
	int quantity;
	int price;     // each
	string source; // "shop #123" or an NPC store's name
	boolean mall;
};

// KoLmafia logs each purchase request as
//   buy 3 drum machine for 3400 each from shop #1733788 on 20261123
//   buy 1 oversized sparkler for 900 each from Clan Underground Fireworks Shop
// The line is the request, so a listing that sold out a moment earlier still
// counts: the total errs on the high side, which is the safe side for a cap.
SmmDPurchase [int] smmDParsePurchases(string log) {
	SmmDPurchase [int] found;
	// create_matcher lets "." match a line break, so the pattern says not to (-s)
	matcher line = create_matcher("(?m-s)^buy ([0-9,]+) (.+) for ([0-9,]+) each from (.+?)(?: on [0-9]{8})?[ \\t\\r]*$", log);
	while (find(line)) {
		SmmDPurchase p;
		p.quantity = group(line, 1).to_int(); // to_int reads "1,250" as 1250
		p.name = group(line, 2);
		p.price = group(line, 3).to_int();
		p.source = group(line, 4);
		p.mall = p.source.starts_with("shop #");
		if (p.quantity > 0 && p.price > 0) found[count(found)] = p;
	}
	return found;
}

int smmDPurchaseTotal(SmmDPurchase [int] purchases) {
	int total = 0;
	foreach i, p in purchases total += p.quantity * p.price;
	return total;
}

// Operating spend: the log's total less what is accounted for elsewhere, which
// is what smmSpend bought itself and what diet.ash bought on its own budget
// (their purchases are in the log too). It never goes down within a day.
int smmDOperatingFrom(int logTotal, int accountedElsewhere, int alreadyBooked) {
	return max(alreadyBooked, max(0, logTotal - max(0, accountedElsewhere)));
}

// Meat diet.ash paid for purchases today. diet.ash keeps the count as it buys.
int smmDDietBought() { return max(0, get_property("_smm.diet.bought").to_int()); }

// The diet's budget for the day. The default is kSmmDietBudget in smmDiet.ash
// (tests/smmdaily-tests.sh checks that the two agree).
int kSmmDDietBudget = 500000;
int smmDDietBudgetFrom(string setting) {
	return setting.is_integer() ? max(0, setting.to_int()) : kSmmDDietBudget;
}

void smmDDietReport() {
	print("Diet: paid " + max(0, get_property("_smm.diet.spent").to_int()) + " Meat today (" + smmDDietBought() + " of it for purchases), of its own budget of "
		+ smmDDietBudgetFrom(get_property("smm.diet.budget")) + " (smm.diet.budget).", "blue");
}

// Meat paid above the average sale price for `quantity` copies that cost
// `paid` together. 0 when the average is unknown.
int smmDOverpaid(int quantity, int paid, float average) {
	if (average <= 0 || quantity <= 0) return 0;
	return max(0, paid - floor(average) * quantity);
}

string smmDTodaysLog() {
	string [int] logs = session_logs(1);
	return count(logs) > 0 ? logs[0] : "";
}

// Books today's purchases as operating spend. Returns the operating total.
int smmDBookPurchases() {
	smmSpendDayStart();
	SmmDPurchase [int] purchases = smmDParsePurchases(smmDTodaysLog());
	int total = smmDPurchaseTotal(purchases);
	int operating = smmDOperatingFrom(total, smmSpendLoggedSpent() + smmDDietBought(), smmSpendOperating());
	set_property(kSmmSpendOperatingKey, operating);
	print("smmDaily: " + count(purchases) + " purchases in today's session log on this machine, " + total + " Meat. Booked as operating spend: "
		+ operating + " (smmSpend's own buys: " + smmSpendSpent() + "; the diet's, on its own budget: " + smmDDietBought() + ").", "blue");
	return operating;
}

record SmmDBought {
	string name;
	int quantity;
	int paid;
};

// The day's mall purchases, one entry per item, biggest spend first.
SmmDBought [int] smmDMallBought(SmmDPurchase [int] purchases) {
	int [string] quantity;
	int [string] paid;
	foreach i, p in purchases {
		if (!p.mall) continue;
		quantity[p.name] += p.quantity;
		paid[p.name] += p.quantity * p.price;
	}
	SmmDBought [int] bought;
	foreach name in paid {
		SmmDBought b;
		b.name = name;
		b.quantity = quantity[name];
		b.paid = paid[name];
		bought[count(bought)] = b;
	}
	sort bought by -value.paid;
	return bought;
}

record SmmDPriceAudit {
 int items;
 int quotedItems;
 int unknownItems;
 int uncheckedItems;
 int requests;
 int flaggedRequests;
 int requestMeat;
 int quotedMeat;
 int potentialExcess;
 string evidenceProblem;
};
string smmDPriceAuditPrefixOverride; // logged-out fixture files only

// Check each request independently: a cheap purchase cannot cancel a later
// above-cap request for the same item. These lines are requests, not fills.
SmmDPriceAudit smmDAuditPrices(SmmDPurchase [int] purchases, float [string] quotes) {
 SmmDPriceAudit audit;
 boolean [string] seen;
 foreach i, p in purchases {
  if (!p.mall) continue;
  if (!seen[p.name]) {
   seen[p.name] = true;
   audit.items += 1;
   if (!(quotes contains p.name)) audit.uncheckedItems += 1;
   else if (quotes[p.name] <= 0) audit.unknownItems += 1;
   else audit.quotedItems += 1;
  }
  audit.requests += 1;
  audit.requestMeat += p.quantity * p.price;
  if (!(quotes contains p.name) || quotes[p.name] <= 0) continue;
  audit.quotedMeat += p.quantity * p.price;
  int excess = smmDOverpaid(p.quantity, p.quantity * p.price, quotes[p.name]);
  if (excess > 0) { audit.flaggedRequests += 1; audit.potentialExcess += excess; }
 }
 return audit;
}

string smmDPriceAuditProblem(SmmDPriceAudit audit) {
 if (audit.potentialExcess > 0) return "potential above-average purchase requests: " + audit.flaggedRequests + "; inspect actual fills and quote timing";
 if (audit.evidenceProblem != "") return audit.evidenceProblem;
 if (audit.unknownItems > 0 || audit.uncheckedItems > 0)
  return "price audit incomplete: " + audit.unknownItems + " unknown averages, " + audit.uncheckedItems + " unchecked items";
 return "";
}

string smmDBudgetProblem(int net, int spent, int operating, int dietPurchases, float fraction) {
 int cap = floor(max(0, net) * min(0.5, max(0.0, fraction)));
 int committed = max(0, spent) + max(0, operating) + max(0, dietPurchases);
 return committed > cap ? "recorded spending exceeds the shared cap by " + (committed - cap) + " Meat, including diet purchases" : "";
}

SmmDPriceAudit smmDPriceCheck() {
 smmDLog("price.audit", "NOTE", "price request audit started");
 int auditSeq = smmDJournalNext() - 1;
 SmmDPurchase [int] purchases = smmDParsePurchases(smmDTodaysLog());
 SmmDBought [int] bought = smmDMallBought(purchases);
 float [string] quotes;
 int lookups = 0;
 foreach i, b in bought {
  item it = b.name.to_item();
  if (it == $item[none]) { quotes[b.name] = 0; continue; }
  if (lookups >= max(0, smmDSettingInt("priceCheckLookups"))) continue;
  if (lookups % 10 == 0) print("smmDaily: quoting mall price audit item " + (lookups + 1) + " of " + count(bought));
  quotes[b.name] = smmSpendAveragePrice(it);
  lookups += 1;
 }
 SmmDPriceAudit audit = smmDAuditPrices(purchases, quotes);
 string [string, string] evidence;
 evidence["meta", "kind"] = "purchase requests, not confirmed fills; quotes from this script's Pricegun cache";
 evidence["meta", "epoch"] = smmDEpoch();
 int details = 0;
 foreach i, p in purchases {
  if (!p.mall) continue;
  string key = i.to_string();
  float average = quotes contains p.name ? quotes[p.name] : 0;
  string coverage = !(quotes contains p.name) ? "unchecked" : average <= 0 ? "unknown" : "quoted";
  int extra = smmDOverpaid(p.quantity, p.quantity * p.price, average);
  evidence[key, "item"] = p.name;
  evidence[key, "quantity"] = p.quantity.to_string();
  evidence[key, "requestedUnitPrice"] = p.price.to_string();
  evidence[key, "average"] = average.to_string();
  evidence[key, "coverage"] = coverage;
  evidence[key, "potentialExcess"] = extra.to_string();
  if ((extra > 0 || coverage != "quoted") && details < 20) {
   details += 1;
   print("&nbsp;&nbsp;request " + p.quantity + " " + p.name + " at " + p.price + " each: "
    + (extra > 0 ? extra + " potentially above the per-copy average cap " + floor(average) : coverage + " average"), "orange");
  }
 }
 string prefix = smmDTestMode && smmDPriceAuditPrefixOverride != "" ? smmDPriceAuditPrefixOverride : "smm-price-audit-" + smmDEpoch().replace_string(":", "-");
 string evidenceFile = prefix + "-" + auditSeq + ".txt";
 if (!map_to_file(evidence, evidenceFile)) {
  audit.evidenceProblem = "could not write the price audit evidence";
  print("smmDaily: " + audit.evidenceProblem, "red");
 }
 string issue = smmDPriceAuditProblem(audit);
 print("smmDaily: mall request audit: " + audit.requests + " requests, " + audit.requestMeat + " Meat; " + audit.quotedItems + "/" + audit.items
  + " items quoted, " + audit.unknownItems + " unknown, " + audit.uncheckedItems + " unchecked; potential excess " + audit.potentialExcess + " Meat", issue == "" ? "blue" : "orange");
 print("SMM_DAILY_PRICE_AUDIT " + (audit.potentialExcess > 0 ? "POTENTIAL_OVERPAYMENT" : issue == "" ? "VERIFIED_REQUEST_CAPS" : "UNVERIFIED"));
 smmDLog("price.audit", "NOTE", "evidence " + evidenceFile + "; quoted " + audit.quotedItems + "/" + audit.items
  + "; potential excess " + audit.potentialExcess + (issue != "" ? "; " + issue : ""));
 return audit;
}

// ---------------------------------------------------------------------------
// MP from free daily sources

boolean [string] smmDMpSourceFailed; // this session: a source that restored nothing is not tried again

int smmDMpTarget() { return min(smmDSettingInt("mpFloor"), my_maxmp()); }

// The next free source worth using with `missing` MP short of full, "" when
// none is left. Cheapest to waste first: bat-wing rests have no other use.
// Free rests are not on the list. Each one refills Cinch on the Cincho de
// Mayo, and 60 Cinch (Fiesta Exit) forces a noncombat, which is worth far more
// than the MP.
string smmDNextFreeMP(int missing) {
	if (!smmDMpSourceFailed["License to Chill"] && missing >= smmDSettingInt("fullRestoreAt")
		&& item_amount($item[License to Chill]) > 0 && get_property("_licenseToChillUsed") != "true")
		return "License to Chill";
	if (!smmDMpSourceFailed["bat wings"] && available_amount($item[bat wings]) > 0 && get_property("_batWingsRestUsed").to_int() < 11)
		return "bat wings";
	if (!smmDMpSourceFailed["nuns"] && get_property("sidequestNunsCompleted") == "fratboy" && get_property("nunsVisits").to_int() < 3)
		return "nuns";
	if (!smmDMpSourceFailed["eternal car battery"] && item_amount($item[eternal car battery]) > 0 && get_property("_eternalCarBatteryUsed") != "true")
		return "eternal car battery";
	return "";
}

// Every return value is captured: an uncaptured failure would abort the day.
void smmDUseFreeMP(string source) {
	boolean ok = true;
	switch (source) {
	case "License to Chill":
		ok = use(1, $item[License to Chill]);
		break;
	case "bat wings":
		item back = equipped_item($slot[back]);
		if (back != $item[bat wings]) ok = equip($slot[back], $item[bat wings]);
		if (ok) ok = use_skill(1, $skill[Rest upside down]);
		if (back != $item[bat wings]) {
			boolean restored = equip($slot[back], back); // $item[none] takes the wings off again
			if (!restored) print("smmDaily: could not put " + back + " back on after resting upside down.", "orange");
		}
		break;
	case "nuns":
		ok = cli_execute("nuns");
		break;
	case "eternal car battery":
		ok = use(1, $item[eternal car battery]);
		break;
	}
	if (!ok) print("smmDaily: " + source + " did not work.", "orange");
}

// Restores MP toward target from free sources only. Never buys a restorer.
// Returns the MP afterwards.
// A free restore gives 1,000 MP or more. With a maximum under the low line it
// would be spent for next to nothing, and again before every task: something
// is holding maximum MP down, and no restore fixes that.
boolean smmDMpWorthRestoring(int maxMp) { return maxMp >= smmDSettingInt("mpLow"); }

int smmDFreeMP(int target) {
	if (!smmDMpWorthRestoring(my_maxmp())) return my_mp();
	int guard = 0;
	while (my_mp() < target && guard < 30) {
		guard += 1;
		string source = smmDNextFreeMP(my_maxmp() - my_mp());
		if (source == "") break;
		int before = my_mp();
		smmDUseFreeMP(source);
		if (my_mp() <= before) smmDMpSourceFailed[source] = true;
	}
	return my_mp();
}

// The old nightcap can reach 12 MP after free restores are exhausted.
// Buy only fresh medicine, at a verified average-price ceiling, within both
// a small daily cap and the remaining spending allowance. Owned stock stays.
void smmDOverdrunkMP(int target) {
 if (!isOverdrunk() || my_mp() >= target) return;
 item medicine = $item[Doc Galaktik's Invigorating Tonic];
 int limit = smmDailyPurchaseLimit(npc_price(medicine), smmSpendAveragePrice(medicine));
 if (limit <= 0) return;
 for attempt from 1 upto 15 {
  if (my_mp() >= target) break;
  int left = smmDSettingInt("combatMpBudget") - get_property("_smm.daily.combatMpSpent").to_int();
  if (left < limit || smmSpendBudget() < limit || my_meat() < limit) break;
  int copiesBefore = item_amount(medicine);
  int meatBefore = my_meat();
  int bought = buy(1, medicine, limit);
  int paid = max(0, meatBefore - my_meat());
  set_property("_smm.daily.combatMpSpent", get_property("_smm.daily.combatMpSpent").to_int() + paid);
  if (bought <= 0 || item_amount(medicine) <= copiesBefore) break;
  int mpBefore = my_mp();
  boolean restored = use(1, medicine); // exactly the freshly acquired copy
  if (!restored || my_mp() <= mpBefore) break;
 }
}

// Called after the final outfit change, immediately before opening a fight.
// Free recovery first; only the bounded overdrunk fallback may buy medicine.
// Campsite rests are never used.
void smmDCombatPrepare() {
	if (get_property("smm.daily.active") == "" || current_round() > 0 || handling_choice()) return;
	string grind = get_property("_smm.grind.active");
 if (grind != "" && smmDailyFundedTurnsLeft(total_turns_played(), get_property("_smm.grind.startTurns").to_int(), get_property("_smm.grind.turnLimit").to_int()) == 0)
  abort("smmDaily: funded paid-turn limit reached for " + grind + "; collection work is held for another day");
 smmDFreeMP(min(my_maxmp(), max(100, smmDSettingInt("mpLow"))));
 smmDOverdrunkMP(min(my_maxmp(), 100));
	int target = smmDailyCombatHpTarget(my_maxhp());
	for attempt from 1 upto 8 {
		if (my_hp() >= target) break;
		int before = my_hp();
		boolean healed = false;
		if (have_skill($skill[Cannelloni Cocoon]) && my_mp() >= mp_cost($skill[Cannelloni Cocoon]))
			healed = use_skill(1, $skill[Cannelloni Cocoon]);
		else if (have_skill($skill[Tongue of the Walrus]) && my_mp() >= mp_cost($skill[Tongue of the Walrus]))
			healed = use_skill(1, $skill[Tongue of the Walrus]);
		if (!healed || my_hp() <= before) break;
	}
 smmDOverdrunkMP(min(my_maxmp(), 100));
	if (my_hp() < target)
		abort("smmDaily: combat preparation needs " + target + " HP after dressing (have " + my_hp() + "); no safe free recovery remains");
}

// Before each task: no task starts nearly out of MP while a free restore is
// left. The line is low on purpose. Today's burnMP spends MP down to about
// base Mysticality after most tasks, and topping up to the breakfast floor
// each time would only feed the free restores to it. When the free sources
// are spent this warns and carries on: the old code decides what it can cast.
void smmDMpHook(string task) {
	// opening and closing the day casts nothing, so it restores nothing
	if (smmDTaskIndex contains task) {
		int phase = smmDTasks[smmDTaskIndex[task]].phase;
		if (phase == 0 || phase == count(smmDPhaseNames) - 1) return;
	}
	if (!smmDMpWorthRestoring(my_maxmp())) return;
	int low = smmDSettingInt("mpLow");
	if (my_mp() >= low) return;
	int before = my_mp();
	int after = smmDFreeMP(low);
	if (after < low)
		smmDLog(task, "NOTE", "MP " + after + " is under " + low + " and the free restores are used up");
	else
		smmDLog(task, "NOTE", "MP restored from " + before + " to " + after + " from free sources");
}

// ---------------------------------------------------------------------------
// Fence: items moved to the closet while garbo runs. garbo does not take from
// the closet while autoSatisfyWithCloset is false. The record is a plain
// preference (no leading underscore) so it survives rollover with the items.

boolean smmDGateHooks() {
	smmDHookBeforeTask = "smmDMpHook";
	return true;
}
boolean smmDGateHooked = smmDGateHooks();
