// Observed cash sources. Shop proceeds are realized receipts, not profit or
// proof that the sold items were produced today. This does not change budgets.
import <smmDailyCore.ash>

record SmmIncomeSale {
 boolean valid;
 int stamp; // printed two-digit year, month, day and time; ordering only
 int quantity;
 int meat;
 string key; // no buyer name or unstable shop-log row number
};

SmmIncomeSale smmIncomeSaleFrom(string entry) {
 SmmIncomeSale sale;
 matcher m = create_matcher("^(?:[0-9]+: )?([0-9]{2})/([0-9]{2})/([0-9]{2}) ([0-9]{2}):([0-9]{2}):([0-9]{2}) .+ bought ([0-9,]+) \\((.+)\\) for ([0-9,]+) Meat\\.[ \\r]*$", entry);
 if (!m.find()) return sale;
 if (m.group(1).to_int() < 1 || m.group(1).to_int() > 12 || m.group(2).to_int() < 1 || m.group(2).to_int() > 31
  || m.group(4).to_int() > 23 || m.group(5).to_int() > 59 || m.group(6).to_int() > 59) return sale;
 int [int] monthDays = {1:31, 2:(m.group(3).to_int() % 4 == 0 ? 29 : 28), 3:31, 4:30, 5:31, 6:30, 7:31, 8:31, 9:30, 10:31, 11:30, 12:31};
 if (m.group(2).to_int() > monthDays[m.group(1).to_int()]) return sale;
 sale.quantity = m.group(7).to_int();
 sale.meat = m.group(9).to_int();
 if (sale.quantity <= 0 || sale.meat <= 0) return sale;
 sale.stamp = (m.group(3) + m.group(1) + m.group(2) + m.group(4) + m.group(5) + m.group(6)).to_int();
 sale.key = sale.stamp + "|" + sale.quantity + "|" + url_encode(m.group(8)) + "|" + sale.meat;
 sale.valid = true;
 return sale;
}

record SmmIncomeShopBook {
 int [string] copies;
 int rows;
 int unknown;
 string newest;
 int newestStamp;
 boolean reliable;
};

SmmIncomeShopBook smmIncomeShopBookFrom(string [int] entries, boolean reliable) {
 SmmIncomeShopBook book;
 book.reliable = reliable;
 foreach i, entry in entries {
  book.rows += 1;
  SmmIncomeSale sale = smmIncomeSaleFrom(entry);
  if (!sale.valid) { book.unknown += 1; continue; }
  book.copies[sale.key] += 1;
  if (sale.stamp > book.newestStamp) { book.newestStamp = sale.stamp; book.newest = sale.key; }
 }
 return book;
}

record SmmIncomeShopDelta {
 int receipts;
 int quantity;
 int proceeds;
 boolean available; // a comparable opening exists; partial current data may still omit receipts
 boolean complete;
 string problem;
};

SmmIncomeShopDelta smmIncomeShopDiff(SmmIncomeShopBook before, SmmIncomeShopBook after) {
 SmmIncomeShopDelta delta;
 delta.available = before.reliable && before.unknown == 0;
 if (!delta.available) { delta.problem = "opening shop receipts unavailable or unparsed; new proceeds cannot be attributed"; return delta; }
 if (!before.reliable || !after.reliable) delta.problem = "shop log availability is unverified";
 else if (before.unknown > 0 || after.unknown > 0) delta.problem = "unparsed shop receipts";
 else if (before.rows > 0 && (before.newest == "" || after.copies[before.newest] < before.copies[before.newest]))
  delta.problem = "opening shop-log anchor disappeared; receipts may be missing";
 foreach key, copies in after.copies {
  int fresh = max(0, copies - before.copies[key]);
  if (fresh == 0) continue;
  string [int] fields = key.split_string("\\|");
  int boundary = before.newest == "" ? 0 : before.newest.split_string("\\|")[0].to_int();
  if (fields[0].to_int() < boundary) {
   delta.problem = "older receipts appeared outside the observed opening boundary";
   continue;
  }
  delta.receipts += fresh;
  delta.quantity += fresh * fields[1].to_int();
  delta.proceeds += fresh * fields[3].to_int();
 }
 delta.complete = delta.problem == "";
 return delta;
}

record SmmIncomeCashEvents {
 int gains;
 int combatGains;
 int losses;
 int unparsed;
};

SmmIncomeCashEvents smmIncomeCashFrom(string log) {
 SmmIncomeCashEvents cash;
 boolean won = false;
 foreach i, raw in log.split_string("\n") {
  string line = raw.replace_string("\r", "");
  if (line.starts_with("Encounter: ") || line.starts_with("[")
   || create_matcher("^(?:buy|use|cast|equip|put|send|trade|eat|drink|chew|autosell|sell|create|cook|mix|smith|pull) ", line).find()) won = false;
  if (line.starts_with("Round ") && !line.contains_text(" wins the fight!")) won = false;
  if (create_matcher("^Round [0-9]+: .+ wins the fight!$", line).find()) won = true;
  matcher event = create_matcher("^You (gain|lose|spent) ([0-9,]+) Meat\\.?$", line);
  if (!event.find()) {
   if (create_matcher("^You (?:gain|lose|spent) .*Meat", line).find()) cash.unparsed += 1;
   continue;
  }
  int amount = event.group(2).to_int();
  if (event.group(1) == "gain") { cash.gains += amount; if (won) cash.combatGains += amount; }
  else cash.losses += amount;
 }
 return cash;
}

string smmIncomePrefixOverride; // offline fixtures only
boolean smmIncomeSame(string a, string b) { return a.length() == b.length() && a.index_of(b) == 0; }
boolean smmIncomeLogCovered(string log, int offset, string anchor) {
 return offset >= 0 && log.length() >= offset && anchor.length() == min(256, offset)
  && smmIncomeSame(log.substring(max(0, offset - 256), offset), anchor);
}
string smmIncomeEncodedAnchor(string log, int offset) {
 return url_encode(log.substring(max(0, offset - 256), offset));
}
boolean smmIncomeLogCovered(string log, int offset, string anchor, string format) {
 if (format == "") return smmIncomeLogCovered(log, offset, anchor); // legacy single-line snapshots
 return format == "url-tail256" && offset >= 0 && log.length() >= offset
  && smmIncomeSame(smmIncomeEncodedAnchor(log, offset), anchor);
}
string smmIncomePrefix() {
 return smmDTestMode && smmIncomePrefixOverride != "" ? smmIncomePrefixOverride : "smm-income-opening-" + smmDEpoch().replace_string(":", "-");
}

string [string] smmIncomeOpeningFrom(int cash, int fundingBase, string log, SmmIncomeShopBook book) {
 string [string] saved;
 saved["meta:epoch"] = smmDEpoch();
 saved["meta:capturedAt"] = now_to_string("yyyy-MM-dd HH:mm:ss");
 saved["meta:cash"] = cash.to_string();
 saved["meta:fundingBase"] = fundingBase.to_string();
 saved["meta:logOffset"] = log.length().to_string();
 saved["meta:logAnchorFormat"] = "url-tail256";
 saved["meta:logAnchor"] = smmIncomeEncodedAnchor(log, log.length());
 saved["meta:shopRows"] = book.rows.to_string();
 saved["meta:shopUnknown"] = book.unknown.to_string();
 saved["meta:shopReliable"] = book.reliable.to_string();
 saved["meta:newest"] = book.newest;
 foreach key, copies in book.copies saved["sale:" + key] = copies.to_string();
 saved["zz:seal"] = "complete-v1";
 return saved;
}

boolean smmIncomeOpeningValid(string [string] saved) {
 if (saved["zz:seal"] != "complete-v1" || saved["meta:epoch"] != smmDEpoch()) return false;
 foreach key in $strings[cash, fundingBase, logOffset, shopRows, shopUnknown]
  if (!saved["meta:" + key].is_integer() || saved["meta:" + key].to_int() < 0) return false;
 if (saved["meta:shopReliable"] != "true" && saved["meta:shopReliable"] != "false") return false;
 int anchorUnits = min(256, saved["meta:logOffset"].to_int());
 if (saved["meta:logAnchorFormat"] == "url-tail256") {
  // Encoded ASCII avoids tabs/newlines being interpreted as map delimiters.
  if (saved["meta:logAnchor"].length() < anchorUnits || saved["meta:logAnchor"].length() > anchorUnits * 9
   || !create_matcher("^(?:[A-Za-z0-9.*_+~\\-]|%[0-9A-Fa-f]{2})*$", saved["meta:logAnchor"]).find()) return false;
 } else if (saved["meta:logAnchorFormat"] != "" || saved["meta:logAnchor"].length() != anchorUnits) return false;
 int rows = saved["meta:shopUnknown"].to_int();
 foreach key, copies in saved {
  if (!key.starts_with("sale:")) continue;
  if (!copies.is_integer() || copies.to_int() <= 0 || !create_matcher("^[0-9]+\\|[1-9][0-9]*\\|[^|]+\\|[1-9][0-9]*$", key.substring(5)).find()) return false;
  rows += copies.to_int();
 }
 if (rows != saved["meta:shopRows"].to_int()) return false;
 if (rows > saved["meta:shopUnknown"].to_int() && saved["sale:" + saved["meta:newest"]].to_int() <= 0) return false;
 return true;
}

string [string] smmIncomeLoadOpening() {
 string [string] a;
 string [string] b;
 file_to_map(smmIncomePrefix() + ".txt", a);
 file_to_map(smmIncomePrefix() + "-backup.txt", b);
 boolean validA = smmIncomeOpeningValid(a);
 boolean validB = smmIncomeOpeningValid(b);
 if (validA && validB) {
  if (count(a) != count(b)) { clear(a); return a; }
  foreach key, value in a if (!(b contains key) || !smmIncomeSame(b[key], value)) { clear(a); return a; }
 }
 if (validA) return a;
 if (validB) return b;
 clear(a);
 return a;
}

boolean smmIncomeSaveOpening(int cash, int fundingBase, string log, SmmIncomeShopBook book) {
 if (smmIncomeOpeningValid(smmIncomeLoadOpening())) return true; // resume never re-baselines
 if (file_to_buffer(smmIncomePrefix() + ".txt").length() > 0 || file_to_buffer(smmIncomePrefix() + "-backup.txt").length() > 0) return false;
 string [string] saved = smmIncomeOpeningFrom(cash, fundingBase, log, book);
 return map_to_file(saved, smmIncomePrefix() + "-backup.txt") && map_to_file(saved, smmIncomePrefix() + ".txt");
}

void smmIncomeOpen(int cash, int fundingBase, string log) {
 if (smmIncomeOpeningValid(smmIncomeLoadOpening())) return;
 string [int] sales;
 boolean shop = have_shop();
 if (shop) sales = get_shop_log();
 SmmIncomeShopBook book = smmIncomeShopBookFrom(sales, !shop || count(sales) > 0);
 if (!smmIncomeSaveOpening(cash, fundingBase, log, book))
  print("smmDaily: income opening snapshot unavailable; source attribution will remain unverified", "orange");
}

void smmIncomeReport(int cash, string log) {
 string [string] saved = smmIncomeLoadOpening();
 if (!smmIncomeOpeningValid(saved)) {
  print("SMM_DAILY_INCOME_COVERAGE UNVERIFIED: opening snapshot missing, corrupt or conflicting");
  return;
 }
 smmDLog("income.report", "NOTE", "income observation report started");
 int reportSeq = smmDJournalNext() - 1;
 SmmIncomeShopBook before;
 before.rows = saved["meta:shopRows"].to_int();
 before.unknown = saved["meta:shopUnknown"].to_int();
 before.reliable = saved["meta:shopReliable"] == "true";
 before.newest = saved["meta:newest"];
 foreach key, copies in saved if (key.starts_with("sale:")) before.copies[key.substring(5)] = copies.to_int();
 string [int] sales;
 boolean shop = have_shop();
 if (shop) sales = get_shop_log();
 SmmIncomeShopBook after = smmIncomeShopBookFrom(sales, !shop || count(sales) > 0);
 SmmIncomeShopDelta delta = smmIncomeShopDiff(before, after);
 int offset = saved["meta:logOffset"].to_int();
 boolean logComplete = smmIncomeLogCovered(log, offset, saved["meta:logAnchor"], saved["meta:logAnchorFormat"]);
 SmmIncomeCashEvents events = smmIncomeCashFrom(logComplete ? log.substring(offset) : "");
 if (events.unparsed > 0) logComplete = false;
 int change = cash - saved["meta:cash"].to_int();
 string [string] evidence = smmIncomeOpeningFrom(cash, saved["meta:fundingBase"].to_int(), log, after);
 evidence["report:openingFile"] = smmIncomePrefix() + ".txt";
 evidence["report:openingBackupFile"] = smmIncomePrefix() + "-backup.txt";
 evidence["report:openingCash"] = saved["meta:cash"];
 evidence["report:shopCoverage"] = delta.complete.to_string();
 evidence["report:shopProceeds"] = delta.proceeds.to_string();
 evidence["report:shopProceedsAvailable"] = delta.available.to_string();
 evidence["report:localLogCoverage"] = logComplete.to_string();
 evidence["report:loggedGains"] = events.gains.to_string();
 evidence["report:combatGains"] = events.combatGains.to_string();
 evidence["report:loggedLosses"] = events.losses.to_string();
 evidence["report:unparsedCashEvents"] = events.unparsed.to_string();
 evidence["report:resourceProfit"] = "UNVERIFIED: old/new stock origins and complete cost attribution unavailable";
 string reportPrefix = smmDTestMode && smmIncomePrefixOverride != "" ? smmIncomePrefixOverride + "-report" : "smm-income-report-" + smmDEpoch().replace_string(":", "-");
 string evidenceFile = reportPrefix + "-" + reportSeq + ".txt";
 boolean persisted = map_to_file(evidence, evidenceFile);
 if (!persisted) print("smmDaily: could not save income observation evidence", "orange");
 print("Income observation window begins at day.open, after login: cash change " + change
  + "; shop receipts " + delta.receipts + ", copies " + delta.quantity + ", gross proceeds " + (delta.available ? delta.proceeds.to_string() : "unavailable")
  + (delta.complete ? " (opening anchor retained)" : " (partial: " + delta.problem + ")"));
 print("Income: local logged gains " + events.gains + " (" + events.combatGains + " after an observed combat win), losses " + events.losses
  + (logComplete ? "" : "; log shortened or boundary changed, totals unavailable"));
 print("Income: observed opening cash minus the funding baseline " + (saved["meta:cash"].to_int() - saved["meta:fundingBase"].to_int())
  + "; remaining window cash movement " + (delta.complete && logComplete ? (change - delta.proceeds - events.gains + events.losses).to_string() : "unavailable (partial coverage)")
  + ". Proceeds are not profit; old/new stock origins, purchase costs and other transfers are not fully reconciled.");
 print("SMM_DAILY_INCOME_COVERAGE " + (delta.complete && logComplete && persisted ? "OBSERVED_WINDOW" : "PARTIAL") + "; RESOURCE_PROFIT UNVERIFIED; budget remains cash-based");
 smmDLog("income.report", "NOTE", "cash change " + change + "; observed shop gross " + delta.proceeds + "; shop coverage " + delta.complete
  + "; local log coverage " + logComplete + "; evidence " + (persisted ? evidenceFile : "missing") + "; resource profit unverified");
}
