// smmDaily: the safeguards around today's code. See docs/daily-script.md.
//
//   - Booking: every purchase in today's session log that did not go through
//     smmSpend (the old daily code, garbo, buying by hand) counts as operating
//     spend against the half-of-net rule, and is checked against the average
//     sale price afterwards.
//   - MP: restore to a floor from free daily sources, so a day that starts at
//     0 MP does not stall.
//   - Fence: items closeted while garbo runs.
//
// The parsing and arithmetic are plain functions with no game access, tested
// in tests/ash/.

import <smmDailyCore.ash>
import <smmSpend.ash>

boolean smmDGateSettings =
	smmDDeclare("priceCheckLookups", "15", "how many of the day's biggest mall purchases the audit checks against the average sale price")
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

// Operating spend: the log's total less what smmSpend bought itself (its
// purchases are in the log too). It never goes down within a day.
int smmDOperatingFrom(int logTotal, int discretionary, int alreadyBooked) {
	return max(alreadyBooked, max(0, logTotal - max(0, discretionary)));
}

// Meat paid above the average sale price for `quantity` copies that cost
// `paid` together. 0 when the average is unknown.
int smmDOverpaid(int quantity, int paid, float average) {
	if (average <= 0 || quantity <= 0) return 0;
	return max(0, paid - ceil(average * quantity));
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
	int operating = smmDOperatingFrom(total, smmSpendSpent(), smmSpendOperating());
	set_property(kSmmSpendOperatingKey, operating);
	print("smmDaily: " + count(purchases) + " purchases in today's session log on this machine, " + total + " Meat. Booked as operating spend: "
		+ operating + " (smmSpend's own buys: " + smmSpendSpent() + ").", "blue");
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

// Rule 3 after the fact: the old code and garbo buy at the mall price, which
// can be above the average sale price. This reports where that happened.
void smmDPriceCheck() {
	SmmDBought [int] bought = smmDMallBought(smmDParsePurchases(smmDTodaysLog()));
	int lookups = smmDSettingInt("priceCheckLookups");
	int checked = 0;
	int checkedMeat = 0;
	int allMeat = 0;
	int over = 0;
	foreach i, b in bought {
		allMeat += b.paid;
		if (checked >= lookups) continue;
		item it = b.name.to_item();
		if (it == $item[none]) continue;
		checked += 1;
		checkedMeat += b.paid;
		float average = smmSpendAveragePrice(it);
		if (average <= 0) {
			print("&nbsp;&nbsp;" + b.quantity + " " + b.name + " for " + b.paid + ": no average sale price on record", "gray");
			continue;
		}
		int extra = smmDOverpaid(b.quantity, b.paid, average);
		if (extra <= 0) continue;
		over += extra;
		print("&nbsp;&nbsp;" + b.quantity + " " + b.name + " for " + b.paid + " Meat: " + extra + " above the average sale price of " + floor(average) + " each", "orange");
	}
	print("smmDaily: mall purchases today " + allMeat + " Meat over " + count(bought) + " items; checked the " + checked + " biggest (" + checkedMeat
		+ " Meat), " + over + " Meat of it above the average sale price.", over > 0 ? "orange" : "blue");
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
int smmDFreeMP(int target) {
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

// Before each task: no task starts nearly out of MP while a free restore is
// left. The line is low on purpose. Today's burnMP spends MP down to about
// base Mysticality after most tasks, and topping up to the breakfast floor
// each time would only feed the free restores to it. When the free sources
// are spent this warns and carries on: the old code decides what it can cast.
void smmDMpHook(string task) {
	// opening and closing the day casts nothing, so it restores nothing
	if (smmDTaskIndex contains task) {
		int phase = smmDTasks[smmDTaskIndex[task]].phase;
		if (phase == 0 || phase == 5) return;
	}
	int low = min(smmDSettingInt("mpLow"), my_maxmp());
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

string kSmmDFencedKey = "smm.daily.fenced"; // "itemId:count|itemId:count"

int [item] smmDParseFenced(string stored) {
	int [item] fenced;
	foreach i, part in stored.split_string("\\|") {
		string [int] fields = part.split_string(":");
		if (count(fields) != 2) continue;
		item it = fields[0].to_int().to_item();
		int amount = fields[1].to_int();
		if (it != $item[none] && amount > 0) fenced[it] += amount;
	}
	return fenced;
}

string smmDFencedToString(int [item] fenced) {
	buffer out;
	foreach it, amount in fenced {
		if (amount <= 0) continue;
		if (out.length() > 0) out.append("|");
		out.append(it.to_int() + ":" + amount);
	}
	return out.to_string();
}

boolean [item] smmDFenceItems() {
	boolean [item] items;
	foreach i, name in smmDSetting("fenceItems").split_string("\\|") {
		item it = name.to_item();
		if (it != $item[none]) items[it] = true;
		else if (name != "") print("smmDaily: smm.daily.fenceItems names '" + name + "', which is not an item.", "orange");
	}
	return items;
}

// Closets every copy in inventory of the fenced items. The record is written
// after each move, so an interruption never loses track of a closeted copy.
void smmDFence() {
	if (get_property("autoSatisfyWithCloset") == "true")
		print("smmDaily: autoSatisfyWithCloset is true, so the closet does not protect anything from garbo.", "red");
	int [item] fenced = smmDParseFenced(get_property(kSmmDFencedKey));
	foreach it in smmDFenceItems() {
		int amount = item_amount(it);
		if (amount <= 0) continue;
		if (put_closet(amount, it)) {
			fenced[it] += amount;
			set_property(kSmmDFencedKey, smmDFencedToString(fenced));
			print("smmDaily: closeted " + amount + " " + it + " for the garbo run.", "blue");
		} else
			print("smmDaily: could not closet " + amount + " " + it + ".", "red");
	}
}

void smmDUnfence() {
	int [item] fenced = smmDParseFenced(get_property(kSmmDFencedKey));
	foreach it, amount in fenced {
		int take = min(amount, closet_amount(it));
		if (take < amount)
			print("smmDaily: " + amount + " " + it + " were fenced but the closet holds " + closet_amount(it) + ".", "orange");
		if (take > 0 && !take_closet(take, it)) {
			print("smmDaily: could not take " + take + " " + it + " back out of the closet.", "red");
			continue; // stays on record for the next try
		}
		fenced[it] = 0;
		set_property(kSmmDFencedKey, smmDFencedToString(fenced));
		if (take > 0) print("smmDaily: took " + take + " " + it + " back out of the closet.", "blue");
	}
}

boolean smmDGateHooks() {
	smmDHookBeforeTask = "smmDMpHook";
	return true;
}
boolean smmDGateHooked = smmDGateHooks();
