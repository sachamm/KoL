// Persistent transfers with fake game quantities; no server requests.
import <smmDailyTasks.ash>
int checks;
int failures;
void check(boolean ok, string reason) { checks += 1; if (!ok) { failures += 1; print("FAIL: " + reason, "red"); } }

void freshFence() {
 clear(smmDTestProps);
 clear(smmDFenceTestInventory);
 clear(smmDFenceTestCloset);
 smmDTestMode = true;
 smmDFenceTestMode = true;
 smmDFenceTestFill = -1;
 smmDFenceTestMoves = 0;
 smmDFenceTestRejectWrite = false;
 smmDFenceFileOverride = "smm-daily-test-fence.txt";
 SmmDFenceState empty;
 empty.player = my_id().to_int();
 smmDFenceSave(empty);
 smmDFenceLoaded = false;
 smmDSet("smm.daily.fenceItems", "drum machine");
}

void forgetFenceCache() {
 smmDFenceLoaded = false;
 SmmDFenceState empty;
 smmDFenceCurrent = empty;
 smmDSet(kSmmDFencedKey, "");
}

void main() {
 item it = $item[drum machine];
 check(smmDFenceObserved(1, 10, 10, 4, 0, 14) == 10, "confirmed incoming copies conserve inventory plus closet");
 check(smmDFenceObserved(-1, 10, 4, 10, 14, 0) == 10, "confirmed returns conserve inventory plus closet");
 check(smmDFenceObserved(1, 10, 10, 4, 7, 7) == 3, "partial transfer counts only moved copies");
 check(smmDFenceObserved(1, 10, 10, 4, 10, 4) == 0, "no movement is distinguishable from success");
 check(smmDFenceObserved(1, 10, 10, 4, 0, 15) == -1, "unrelated closet gains are ambiguous");
 check(smmDFenceObserved(-1, 10, 4, 10, 15, 0) == -1, "unrelated inventory gains are ambiguous");
 check(!smmDFenceRecordValid("garbage") && !smmDFenceRecordValid(it.to_int()+":0"), "corrupt ledger records cannot migrate silently");

 freshFence();
 smmDFenceTestInventory[it] = 10;
 smmDFenceTestCloset[it] = 4;
 smmDFence();
 check(smmDFenceTestInventory[it] == 0 && smmDFenceTestCloset[it] == 14, "fencing transfers all copies using fake game state");
 check(smmDParseFenced(smmDFenceCurrent.fenced)[it] == 10, "fence owns only moved copies, not original closet stock");
 forgetFenceCache();
 smmDUnfence();
 check(smmDFenceTestInventory[it] == 10 && smmDFenceTestCloset[it] == 4, "lost preference cache does not lose fenced copies or take original stock");
 check(smmDFenceCurrent.fenced == "", "confirmed return settles the persistent ledger");

 // Crash after server movement, before its local settlement.
 freshFence();
 smmDFenceTestInventory[it] = 10;
 smmDFenceTestCloset[it] = 4;
 smmDFenceIntent(1, it, 10);
 boolean moved = smmDFenceMove(1, it, 10);
 forgetFenceCache();
 smmDFenceLoad();
 check(smmDFenceCurrent.direction == 1 && smmDFenceCurrent.requested == 10, "pending intent survives a crash and lost preferences");
 smmDUnfence();
 check(smmDFenceTestInventory[it] == 10 && smmDFenceTestCloset[it] == 4 && smmDFenceCurrent.fenced == "", "explicit recovery reconciles the pending put, then returns exactly its copies");

 // Crash after a return, before recording it. Do not return a second batch.
 freshFence();
 smmDFenceTestInventory[it] = 10;
 smmDFenceTestCloset[it] = 4;
 smmDFence();
 smmDFenceIntent(-1, it, 10);
 moved = smmDFenceMove(-1, it, 10);
 forgetFenceCache();
 int movesBefore = smmDFenceTestMoves;
 smmDUnfence();
 check(smmDFenceTestMoves == movesBefore && smmDFenceTestCloset[it] == 4, "recovering an already completed return never takes original closet stock");

 freshFence();
 smmDFenceTestInventory[it] = 10;
 smmDFenceIntent(1, it, 10);
 smmDFenceTestFill = 3;
 moved = smmDFenceMove(1, it, 10);
 forgetFenceCache();
 smmDFenceLoad();
 check(smmDFenceSettle() == 3 && smmDParseFenced(smmDFenceCurrent.fenced)[it] == 3, "a partial put after a crash owns only the conserved observed copies");
 smmDFenceTestFill = -1;
 smmDFenceTestCloset[it] = 2; // one recorded copy is missing
 smmDUnfence();
 check(smmDParseFenced(smmDFenceCurrent.fenced)[it] == 1, "missing fenced stock remains recorded after available copies return");

 // A truncated mirror cannot erase a newer valid checkpoint.
 SmmDFenceState [int] cut;
 map_to_file(cut, smmDFenceFile());
 forgetFenceCache();
 smmDFenceLoad();
 check(smmDParseFenced(smmDFenceCurrent.fenced)[it] == 1, "complete backup recovers a truncated primary fence record");
 SmmDFenceState corrupt = smmDFenceCopy(smmDFenceCurrent);
 corrupt.seal = "";
 check(!smmDFenceStateValid(corrupt), "missing final seal detects a partial record");
 corrupt = smmDFenceCopy(smmDFenceCurrent);
 corrupt.player += 1;
 check(!smmDFenceStateValid(corrupt), "another player's fence file cannot authorize a move");

 freshFence();
 smmDFenceTestInventory[it] = 10;
 smmDFenceIntent(1, it, 10); // crash before server request
 forgetFenceCache();
 smmDUnfence();
 check(smmDFenceTestInventory[it] == 10 && smmDFenceTestMoves == 0 && smmDFenceCurrent.fenced == "", "pending no-op does not manufacture or move copies on recovery");

 freshFence();
 SmmDFenceState [int] missing;
 map_to_file(missing, smmDFenceFile());
 map_to_file(missing, smmDFenceBackupFile());
 smmDSet(kSmmDFencedKey, it.to_int() + ":2");
 smmDFenceLoaded = false;
 smmDFenceTestCloset[it] = 7;
 smmDUnfence();
 check(smmDFenceTestInventory[it] == 2 && smmDFenceTestCloset[it] == 5, "legacy preferences migrate without claiming original closet copies");

 freshFence();
 smmDFenceTestInventory[it] = 10;
 smmDFenceTestCloset[it] = 4;
 smmDFence();
 smmDFenceIntent(-1, it, 10);
 SmmDFenceState [int] pendingCopy;
 pendingCopy[1] = smmDFenceCopy(smmDFenceCurrent);
 moved = smmDFenceMove(-1, it, 10);
 smmDFenceSettle();
 map_to_file(pendingCopy, smmDFenceFile()); // crash before replacing the older primary
 forgetFenceCache();
 movesBefore = smmDFenceTestMoves;
 smmDUnfence();
 check(smmDFenceTestMoves == movesBefore && smmDFenceTestCloset[it] == 4, "newer settled backup wins over an older pending primary without a duplicate return");

 freshFence();
 smmDFenceLoad();
 SmmDFenceState missingReturn = smmDFenceCopy(smmDFenceCurrent);
 missingReturn.fenced = it.to_int() + ":2";
 smmDFenceSave(missingReturn);
 smmDSet(kSmmDFencedKey, ""); // a lost/edited compatibility cache is not proof
 check(!smmDTUnfenceDone(), "unfence completion reads persistent ownership rather than the preference cache");
 smmDJournalOverride = "smm-daily-test-fence-worker.txt";
 smmDJournalLoaded = true;
 smmDHookBeforeTask = "";
 smmDSet("smm.daily.runner", "true");
 smmDRunTask(smmDTasks[smmDTaskIndex["close.unfence"]]);
 check(smmDStopRun != "" && smmDGet("_smm.daily.error.close.unfence") != "", "missing stock stops the close worker before any collection-spending task");
 check(smmDFenceTestMoves == 0, "missing stock cannot manufacture a return request");

 freshFence();
 if (failures == 0) print("PASS smmDailyFenceTest: " + checks + " checks");
 else print("FAILED smmDailyFenceTest: " + failures + " of " + checks + " checks", "red");
}
