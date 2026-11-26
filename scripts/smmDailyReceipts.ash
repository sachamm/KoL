// Session transactions supplement physical holdings; requests are not receipts.
import <smmDailyPolicy.ash>

record SmmDailyItemReceipt {
 int acquired;
 int nativeDrops;
 int requestedBuys;
 int requestedMeat;
};

SmmDailyItemReceipt [item] smmDailyItemReceipts(string log) {
 SmmDailyItemReceipt [item] receipts;
 monster foe = $monster[none];
 boolean won = false;
 foreach i, line in log.split_string("\n") {
  if (line.starts_with("Encounter: ")) { foe = line.substring(11).to_monster(); won = false; }
  if (line.starts_with("Round ") && line.contains_text(" wins the fight!")) won = true;
  matcher purchase = create_matcher("^buy ([0-9,]+) (.+) for ([0-9,]+) each from ", line);
  if (purchase.find()) {
   item it = purchase.group(2).to_item();
   if (it != $item[none]) {
    int quantity = purchase.group(1).to_int();
    receipts[it].requestedBuys += quantity;
    receipts[it].requestedMeat += quantity * purchase.group(3).to_int();
   }
  }
  if (line.starts_with("buy ") || line.starts_with("use ") || line.starts_with("cast ")
   || line.starts_with("equip ") || line.starts_with("put ") || line.starts_with("[")) won = false;
  matcher gain = create_matcher("^You acquire (?:an item: )?(.+?)(?: \\(([0-9,]+)\\))?\\r?$", line);
  if (!gain.find()) continue;
  item it = gain.group(1).to_item();
  if (it == $item[none]) continue;
  int quantity = gain.group(2) == "" ? 1 : gain.group(2).to_int();
  receipts[it].acquired += quantity;
  if (!won || foe == $monster[none]) continue;
  foreach j, drop in item_drops_array(foe)
   if (drop.drop == it) { receipts[it].nativeDrops += quantity; break; }
 }
 return receipts;
}

// A moving asset has no value delta. Consumed owned inputs have a negative
// delta; buying then consuming an input is already charged in the Meat delta.
int smmDailyValuedDelta(item it, int before, int after, int nativeDrops) {
 if (smmDailyReturnItem(it) && nativeDrops == 0) return 0;
 return smmDailySignedItemDelta(before, after);
}
