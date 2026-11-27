// Synthetic receipt and persistence tests. No shop, login or network calls.
import <smmDailyIncome.ash>
int checks;
int failures;
void check(boolean ok, string why) { checks += 1; if (!ok) { failures += 1; print("FAIL: " + why, "red"); } }
string receipt(int id, string time, string buyer, int quantity, string it, int meat) {
 return id + ": 11/26/26 " + time + " " + buyer + " bought " + quantity + " (" + it + ") for " + meat + " Meat.";
}

void main() {
 SmmIncomeSale sale = smmIncomeSaleFrom(receipt(99, "17:00:00", "Fixture Buyer", 10, "item (with parentheses)", 10000));
 check(sale.valid && sale.quantity == 10 && sale.meat == 10000, "shop amount is total proceeds, not price per copy");
 check(sale.key.contains_text(url_encode("item (with parentheses)")), "nested item parentheses survive normalization");
 check(!sale.key.contains_text("Fixture") && !sale.key.starts_with("99:"), "normalized evidence excludes buyers and unstable row numbers");
 check(sale.key == smmIncomeSaleFrom(receipt(1, "17:00:00", "Renamed Buyer", 10, "item (with parentheses)", 10000)).key, "renumbering or buyer renaming cannot invent a new receipt");
 check(!smmIncomeSaleFrom("not a receipt").valid, "unknown entry is not silently valued as zero");
 check(!smmIncomeSaleFrom("1: 02/30/26 12:00:00 Fixture bought 1 (seal tooth) for 100 Meat.").valid, "impossible calendar date is rejected");
 check(smmIncomeSaleFrom("1: 02/29/24 12:00:00 Fixture bought 1 (seal tooth) for 100 Meat.").valid, "valid leap day is accepted");

 string [int] before;
 before[0] = receipt(50, "16:00:00", "A", 1, "seal tooth", 100);
 before[1] = receipt(49, "15:00:00", "B", 2, "MSG", 2000);
 string [int] after;
 after[0] = receipt(53, "17:00:00", "C", 3, "MSG", 3000);
 after[1] = receipt(52, "16:00:00", "Renamed A", 1, "seal tooth", 100);
 after[2] = receipt(51, "15:00:00", "B", 2, "MSG", 2000);
 SmmIncomeShopBook opening = smmIncomeShopBookFrom(before, true);
 SmmIncomeShopDelta delta = smmIncomeShopDiff(opening, smmIncomeShopBookFrom(after, true));
 check(delta.complete && delta.receipts == 1 && delta.quantity == 3 && delta.proceeds == 3000, "new receipts match an opening multiset independent of sort order and row numbers");
 after[3] = receipt(54, "17:00:00", "Another Buyer", 3, "MSG", 3000);
 delta = smmIncomeShopDiff(opening, smmIncomeShopBookFrom(after, true));
 check(delta.receipts == 2 && delta.proceeds == 6000, "identical same-second purchases retain multiplicity");
 remove after[2];
 check(smmIncomeShopDiff(opening, smmIncomeShopBookFrom(after, true)).complete, "expired older rows do not invalidate a retained newest anchor");
 remove after[1];
 delta = smmIncomeShopDiff(opening, smmIncomeShopBookFrom(after, true));
 check(!delta.complete && delta.problem.contains_text("anchor"), "a lost opening anchor makes coverage partial");
 after[1] = before[0];
 after[4] = receipt(1, "14:00:00", "Old Buyer", 5, "MSG", 5000);
 delta = smmIncomeShopDiff(opening, smmIncomeShopBookFrom(after, true));
 check(!delta.complete && delta.proceeds == 6000, "late older history is not misclassified as income since opening");
 after[4] = "unparsed store entry";
 check(!smmIncomeShopDiff(opening, smmIncomeShopBookFrom(after, true)).complete, "unknown rows leave coverage unverified");
 check(!smmIncomeShopDiff(opening, smmIncomeShopBookFrom(before, false)).complete, "unavailable shop data cannot claim complete coverage");
 string [int] empty;
 delta = smmIncomeShopDiff(smmIncomeShopBookFrom(empty, false), smmIncomeShopBookFrom(after, true));
 check(!delta.available && delta.proceeds == 0, "an unavailable opening cannot classify the whole historical shop log as newly earned proceeds");

 string events = "You gain 100 Meat\nEncounter: fixture\nRound 1: Fixture wins the fight!\nYou gain 1,000 Meat\r\n"
  + "You lose 5 Meat\nuse 1 fat wallet\nYou gain 500 Meat\n> You gain 99999 Meat\nYou spent 20 Meat\nYou gain some Meat\n";
 SmmIncomeCashEvents cash = smmIncomeCashFrom(events);
 check(cash.gains == 1600 && cash.combatGains == 1000 && cash.losses == 25, "combat, other gains and logged outflows remain distinct; quoted output is excluded");
 check(cash.unparsed == 1, "unparsed cash events prevent complete local coverage");
 check(smmIncomeLogCovered("ABCmore", 3, "ABC"), "append-only log preserves the opening boundary");
 check(!smmIncomeLogCovered("abcMORE", 3, "ABC") && !smmIncomeLogCovered("AB", 3, "ABC"), "changed and shortened logs are detected exactly");

 smmDTestMode = true;
 smmIncomePrefixOverride = "smm-daily-test-income";
 string [string] saved = smmIncomeOpeningFrom(10000, 9000, "ABC", opening);
 check(smmIncomeOpeningValid(saved), "opening metadata validates with normalized receipt counts");
 map_to_file(saved, smmIncomePrefix() + ".txt");
 map_to_file(saved, smmIncomePrefix() + "-backup.txt");
 check(smmIncomeSaveOpening(99999, 9000, "later", opening), "resuming an observed window keeps its original baseline");
 check(smmIncomeLoadOpening()["meta:cash"] == "10000", "resuming does not erase already observed cash changes");
 smmDSet("_smm.spend.startMeat", "9000");
 smmDSet("_smm.spend.spent", "123");
 clear(smmDJournal);
 smmDJournalLoaded = true;
 smmDJournalOverride = "smm-daily-test-income-journal.txt";
 // Logged out there is no shop: the report must preserve uncertainty and the
 // funding policy, not try to repair missing receipts by changing cash totals.
 smmIncomeReport(10100, "ABC");
 smmIncomeReport(10100, "ABC");
 check(smmDGet("_smm.spend.startMeat") == "9000" && smmDGet("_smm.spend.spent") == "123", "income reporting does not change the cash funding ledger");
 string [string] evidence1;
 string [string] evidence2;
 file_to_map(smmIncomePrefix() + "-report-1.txt", evidence1);
 file_to_map(smmIncomePrefix() + "-report-3.txt", evidence2);
 check(evidence1["report:resourceProfit"].starts_with("UNVERIFIED") && evidence2["report:resourceProfit"].starts_with("UNVERIFIED"), "independent closing observations retain explicit unverified profit status");
 check(count(smmDJournal) == 4 && evidence1["report:shopCoverage"] == "false", "each report records evidence and does not claim coverage after its anchor is missing");
 smmDJournalOverride = "";
 smmDJournalLoaded = false;
 clear(smmDJournal);
 string [string] cut;
 map_to_file(cut, smmIncomePrefix() + ".txt");
 check(smmIncomeOpeningValid(smmIncomeLoadOpening()), "a valid mirror recovers a truncated opening snapshot");
 saved["meta:cash"] = "10001";
 map_to_file(saved, smmIncomePrefix() + ".txt");
 check(!smmIncomeOpeningValid(smmIncomeLoadOpening()), "conflicting valid opening snapshots are not guessed between");
 check(!smmIncomeSaveOpening(12345, 9000, "new", opening), "a conflict cannot silently reset the observation window");
 saved["zz:seal"] = "";
 check(!smmIncomeOpeningValid(saved), "incomplete serialized metadata is rejected");
 saved["zz:seal"] = "complete-v1";
 saved["meta:shopRows"] = "9999";
 check(!smmIncomeOpeningValid(saved), "receipt count mismatch detects incomplete payloads");
 smmDTestMode = false;
 smmIncomePrefixOverride = "";
 if (failures == 0) print("PASS smmDailyIncomeTest: " + checks + " checks");
 else print("FAILED smmDailyIncomeTest: " + failures + " of " + checks + " checks", "red");
}
