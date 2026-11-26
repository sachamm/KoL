// Persistent closet-transfer ownership, independent of the daily epoch.
import <smmDailyCore.ash>

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
		else if (name != "") abort("smmDaily: smm.daily.fenceItems names an unknown item: " + name);
	}
	return items;
}

// Takes an item off wherever it is worn, so it can go into the closet.
void smmDTakeOff(item it) {
	if (equipped_amount(it) <= 0) return;
	foreach sl in $slots[hat, back, shirt, weapon, off-hand, pants, acc1, acc2, acc3, familiar] {
		if (equipped_item(sl) != it) continue;
		boolean off = equip(sl, $item[none]);
		if (!off) abort("smmDaily: could not take " + it + " off before fencing");
	}
}

record SmmDFenceState {
 int generation;
 int player;
 string fenced;
 int direction; // 1 to closet, -1 from closet, 0 settled
 int itemId;
 int requested;
 int inventoryBefore;
 int closetBefore;
 string seal; // last column detects incomplete record writes
};
SmmDFenceState smmDFenceCurrent;
boolean smmDFenceLoaded;
string smmDFenceFileOverride;
boolean smmDFenceTestMode;
boolean smmDFenceTestRejectWrite;
int [item] smmDFenceTestInventory;
int [item] smmDFenceTestCloset;
int smmDFenceTestFill = -1;
int smmDFenceTestMoves;

SmmDFenceState smmDFenceCopy(SmmDFenceState state) {
 SmmDFenceState copy;
 copy.generation = state.generation;
 copy.player = state.player;
 copy.fenced = state.fenced;
 copy.direction = state.direction;
 copy.itemId = state.itemId;
 copy.requested = state.requested;
 copy.inventoryBefore = state.inventoryBefore;
 copy.closetBefore = state.closetBefore;
 copy.seal = state.seal;
 return copy;
}

boolean smmDFenceSame(SmmDFenceState a, SmmDFenceState b) {
 return a.generation == b.generation && a.player == b.player && a.fenced == b.fenced && a.direction == b.direction
  && a.itemId == b.itemId && a.requested == b.requested && a.inventoryBefore == b.inventoryBefore && a.closetBefore == b.closetBefore && a.seal == b.seal;
}

string smmDFenceFile() { return smmDFenceFileOverride != "" ? smmDFenceFileOverride : "smm-daily-fence-" + my_id() + ".txt"; }
string smmDFenceBackupFile() { return smmDFenceFile().replace_string(".txt", "-backup.txt"); }
int smmDFenceInventory(item it) { return smmDFenceTestMode ? smmDFenceTestInventory[it] : item_amount(it); }
int smmDFenceCloset(item it) { return smmDFenceTestMode ? smmDFenceTestCloset[it] : closet_amount(it); }

boolean smmDFenceRecordValid(string text) {
 if (text == "") return true;
 if (!create_matcher("^[0-9]+:[1-9][0-9]*(\\|[0-9]+:[1-9][0-9]*)*$", text).find()) return false;
 foreach i, part in text.split_string("\\|") if (part.split_string(":")[0].to_int().to_item() == $item[none]) return false;
 return true;
}

boolean smmDFenceStateValid(SmmDFenceState state) {
 if (state.seal != "complete-v1" || state.generation <= 0 || state.player != my_id().to_int() || !smmDFenceRecordValid(state.fenced)) return false;
 if (state.direction == 0) return state.itemId == 0 && state.requested == 0 && state.inventoryBefore == 0 && state.closetBefore == 0;
 if (state.direction != 1 && state.direction != -1) return false;
 if (state.itemId.to_item() == $item[none] || state.requested <= 0 || state.inventoryBefore < 0 || state.closetBefore < 0) return false;
 if (state.direction == 1) return state.requested <= state.inventoryBefore;
 return state.requested <= state.closetBefore && state.requested <= smmDParseFenced(state.fenced)[state.itemId.to_item()];
}

SmmDFenceState smmDFenceRead() {
 SmmDFenceState [int] primary;
 SmmDFenceState [int] backup;
 file_to_map(smmDFenceFile(), primary);
 file_to_map(smmDFenceBackupFile(), backup);
 boolean p = count(primary) == 1 && smmDFenceStateValid(primary[1]);
 boolean b = count(backup) == 1 && smmDFenceStateValid(backup[1]);
 if (p && b && primary[1].generation == backup[1].generation && !smmDFenceSame(primary[1], backup[1]))
  abort("smmDaily: conflicting fence records require reconciliation; no closet move was authorized");
 if (p && (!b || primary[1].generation >= backup[1].generation)) return primary[1];
 if (b) return backup[1];
 if (count(primary) > 0 || count(backup) > 0 || file_to_buffer(smmDFenceFile()).length() > 0 || file_to_buffer(smmDFenceBackupFile()).length() > 0)
  abort("smmDaily: unreadable fence records require reconciliation; no closet move was authorized");
 SmmDFenceState initial;
 initial.player = my_id().to_int();
 initial.fenced = smmDGet(kSmmDFencedKey); // migrate an older preference record
 if (!smmDFenceRecordValid(initial.fenced)) abort("smmDaily: invalid legacy fence record requires reconciliation");
 return initial;
}

void smmDFenceLoad() {
 if (!smmDFenceLoaded) {
  smmDFenceCurrent = smmDFenceRead();
  smmDFenceLoaded = true;
 }
}

void smmDFenceSave(SmmDFenceState state) {
 state = smmDFenceCopy(state);
 state.generation += 1;
 state.seal = "complete-v1";
 SmmDFenceState [int] saved;
 saved[1] = state;
 // Write intent to both copies before sending a game request. A crash during
 // a later settlement leaves at least one complete pending/settled record.
 if (smmDFenceTestRejectWrite || !map_to_file(saved, smmDFenceBackupFile()) || !map_to_file(saved, smmDFenceFile()))
  abort("smmDaily: could not write the fence record; no further closet move is authorized");
 smmDFenceCurrent = state;
 smmDFenceLoaded = true;
 smmDSet(kSmmDFencedKey, state.fenced); // compatibility cache, never the only record
}

// -1 means unrelated changes make the transfer ambiguous. Zero is a verified
// no-op, not a successful transfer of the requested amount.
int smmDFenceObserved(int direction, int requested, int inventoryBefore, int closetBefore, int inventoryAfter, int closetAfter) {
 int inventoryDelta = (inventoryBefore - inventoryAfter) * direction;
 int closetDelta = (closetAfter - closetBefore) * direction;
 if (inventoryDelta != closetDelta || inventoryDelta < 0 || inventoryDelta > requested) return -1;
 return inventoryDelta;
}

void smmDFenceIntent(int direction, item it, int requested) {
 smmDFenceLoad();
 if (smmDFenceCurrent.direction != 0) abort("smmDaily: a pending fence transfer must be reconciled before another move");
 SmmDFenceState pending = smmDFenceCopy(smmDFenceCurrent);
 pending.direction = direction;
 pending.itemId = it.to_int();
 pending.requested = requested;
 pending.inventoryBefore = smmDFenceInventory(it);
 pending.closetBefore = smmDFenceCloset(it);
 pending.seal = "complete-v1";
 // New records have no generation until their first persisted intent.
 pending.generation = max(1, pending.generation);
 if (!smmDFenceStateValid(pending)) abort("smmDaily: invalid fence transfer intent; no closet move was authorized");
 smmDFenceSave(pending);
}

int smmDFenceSettle() {
 smmDFenceLoad();
 if (smmDFenceCurrent.direction == 0) return 0;
 SmmDFenceState settled = smmDFenceCopy(smmDFenceCurrent);
 item it = settled.itemId.to_item();
 int moved = smmDFenceObserved(settled.direction, settled.requested, settled.inventoryBefore, settled.closetBefore, smmDFenceInventory(it), smmDFenceCloset(it));
 if (moved < 0) abort("smmDaily: ambiguous pending fence transfer for " + it + "; inspect inventory and closet against smmdaily fence-status before reconciling");
 int [item] fenced = smmDParseFenced(settled.fenced);
 fenced[it] += settled.direction * moved;
 settled.fenced = smmDFencedToString(fenced);
 settled.direction = 0;
 settled.itemId = 0;
 settled.requested = 0;
 settled.inventoryBefore = 0;
 settled.closetBefore = 0;
 smmDFenceSave(settled);
 return moved;
}

boolean smmDFenceMove(int direction, item it, int requested) {
 // Intent must already be durable before this function is reached.
 if (smmDFenceCurrent.direction != direction || smmDFenceCurrent.itemId != it.to_int() || smmDFenceCurrent.requested != requested)
  abort("smmDaily: closet move has no matching durable fence intent");
 if (!smmDFenceTestMode) return direction == 1 ? put_closet(requested, it) : take_closet(requested, it);
 smmDFenceTestMoves += 1;
 int available = direction == 1 ? smmDFenceTestInventory[it] : smmDFenceTestCloset[it];
 int moved = min(requested, min(available, smmDFenceTestFill < 0 ? requested : smmDFenceTestFill));
 smmDFenceTestInventory[it] -= direction * moved;
 smmDFenceTestCloset[it] += direction * moved;
 return moved == requested;
}

void smmDFenceEnsureReady() {
 smmDFenceLoad();
 if (smmDFenceCurrent.direction != 0) abort("smmDaily: pending fence transfer; inspect smmdaily fence-status, then smmdaily unfence to reconcile before running tasks");
 smmDSet(kSmmDFencedKey, smmDFenceCurrent.fenced);
 if (smmDFenceCurrent.fenced != "") abort("smmDaily: fenced items remain from an earlier run; smmdaily unfence before running tasks");
}

void smmDFenceStatus() {
 SmmDFenceState state = smmDFenceRead();
 print("smmDaily: fence generation " + state.generation + "; recorded items " + (state.fenced == "" ? "none" : state.fenced));
 if (state.direction == 0) return;
 item it = state.itemId.to_item();
 print("smmDaily: pending " + (state.direction == 1 ? "closet " : "return ") + state.requested + " " + it
  + "; inventory before/now " + state.inventoryBefore + "/" + smmDFenceInventory(it)
  + "; closet before/now " + state.closetBefore + "/" + smmDFenceCloset(it), "orange");
}

void smmDFence() {
 if (smmDGet("autoSatisfyWithCloset") == "true") abort("smmDaily: closet sourcing must be disabled before garbo can be fenced");
 smmDFenceLoad();
 if (smmDFenceCurrent.direction != 0) abort("smmDaily: pending fence transfer must be reconciled before garbo can start");
 foreach it in smmDFenceItems() {
  if (!smmDFenceTestMode) smmDTakeOff(it);
  int amount = smmDFenceInventory(it);
  if (amount <= 0) continue;
  smmDFenceIntent(1, it, amount);
  boolean ok = smmDFenceMove(1, it, amount);
  int confirmed = smmDFenceSettle();
  if (!ok || confirmed != amount || smmDFenceInventory(it) > 0 || (!smmDFenceTestMode && equipped_amount(it) > 0))
   abort("smmDaily: could not closet all " + amount + " " + it + "; garbo was not started");
  print("smmDaily: closeted " + confirmed + " " + it + " for the garbo run.", "blue");
 }
}

int smmDFenceRemaining(int owed, int requested, int inventoryBefore, int inventoryAfter) {
 return max(0, owed - max(0, min(requested, inventoryAfter - inventoryBefore)));
}

void smmDUnfence() {
 if (!smmDFenceTestMode && (handling_choice() || current_round() > 0)) abort("smmDaily: resolve the encounter before unfencing");
 smmDFenceLoad();
 // The same-process finally block or an explicit unfence request may reconcile
 // conserved counts. A restarted daily run itself never infers the outcome.
 if (smmDFenceCurrent.direction != 0) smmDFenceSettle();
 int [item] fenced = smmDParseFenced(smmDFenceCurrent.fenced);
 foreach it, amount in fenced {
  int take = min(amount, smmDFenceCloset(it));
  if (take <= 0) { print("smmDaily: fenced items remain unreconciled: closet is missing " + amount + " " + it, "red"); continue; }
  smmDFenceIntent(-1, it, take);
  boolean ok = smmDFenceMove(-1, it, take);
  int confirmed = smmDFenceSettle();
  if (!ok || confirmed < amount) print("smmDaily: fenced items remain unreconciled for " + it + "; missing copies stay recorded", "red");
  if (confirmed > 0) print("smmDaily: took " + confirmed + " " + it + " back out of the closet.", "blue");
 }
}

