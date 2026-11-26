// Expected aborts, with fake quantities and no game requests.
import <smmDailyTasks.ash>
void main(string mode) {
 smmDTestMode = true;
 smmDFenceTestMode = true;
 smmDFenceFileOverride = "smm-daily-test-fence-" + mode + ".txt";
 smmDSet("smm.daily.fenceItems", "drum machine");
 item it = $item[drum machine];
 SmmDFenceState initial;
 initial.player = my_id().to_int();
 smmDFenceSave(initial);
 smmDFenceTestInventory[it] = 10;
 try {
  if (mode == "write" || mode == "garbo") {
   smmDFenceTestRejectWrite = true;
   if (mode == "garbo") {
    smmDSet("autoSatisfyWithCloset", "true");
    smmDSet("garbo_autoUserConfirm", "fixture-original");
    smmDSet("smm.daily.garboAutoConfirm", "true");
    smmDTGarboRun("garbo", "ash print(\"UNSAFE_GARBO_EXECUTED\");");
   } else smmDFence();
  } else if (mode == "pending") {
   smmDFenceIntent(1, it, 10);
   smmDFenceLoaded = false;
   smmDSet(kSmmDFencedKey, "");
   smmDFenceEnsureReady();
  } else if (mode == "ambiguous") {
   smmDFenceIntent(1, it, 10);
   boolean moved = smmDFenceMove(1, it, 10);
   smmDFenceTestCloset[it] += 1;
   smmDFenceLoaded = false;
   smmDUnfence();
  } else if (mode == "corrupt" || mode == "conflict") {
   SmmDFenceState broken = smmDFenceCopy(smmDFenceCurrent);
   broken.fenced = it.to_int() + ":1";
   if (mode == "corrupt") broken.seal = "";
   SmmDFenceState [int] saved;
   saved[1] = broken;
   map_to_file(saved, smmDFenceFile());
   if (mode == "corrupt") map_to_file(saved, smmDFenceBackupFile());
   smmDFenceLoaded = false;
   smmDFenceEnsureReady();
  }
  print("UNSAFE_TASK_EXECUTED");
 } finally {
  print("FENCE_TEST_MOVES " + smmDFenceTestMoves);
  if (mode == "garbo") print("FENCE_TEST_RESTORED " + smmDGet("autoSatisfyWithCloset") + " " + smmDGet("garbo_autoUserConfirm"));
 }
}
