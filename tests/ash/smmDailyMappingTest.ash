import <smmDailyTasks.ash>
int checks;
int failures;
int actions;
int mode;
string trace;
string mapPage = "Leading Yourself Right to Them";
void check(boolean ok, string why) { checks += 1; if (!ok) { failures += 1; print("FAIL: " + why); } }
string mapFixture(string action, int decision, location where) {
 actions += 1; trace += action + ":" + decision + "|";
 if (action == "choice") {
  if (mode != 1) smmMapTestState.choice = 0;
  if (mode == 5) smmMapTestState.mapping = false;
 } else if (action == "combat") {
  if (mode != 3) smmMapTestState.fight = false;
 } else if (action == "adventure" && mode != 2 && (mode != 4 || actions == 8)) {
  smmMapTestState.choice = 1435;
  return mapPage;
 }
 return "interruption processed";
}
void fresh() {
 clear(smmDTestProps); smmDSet("smm.daily.active", smmDEpoch());
 smmMapTestAction = "mapFixture"; smmMapFailure = "";
 smmMapTestState.choice = 0; smmMapTestState.decision = 4; smmMapTestState.decisionAvailable = true;
 smmMapTestState.fight = false; smmMapTestState.mapping = true; smmMapTestState.canAdventure = true; smmMapTestState.beaten = false;
 actions = 0; mode = 0; trace = "";
}
string waitMap() { return smmAwaitMapChoice($location[The Haunted Storage Room], "interruption"); }
void main() {
 smmDTestMode = true;
 check(smmMapAvailable(true, 3), "the third cast remains usable while its map is active");
 check(!smmMapAvailable(false, 3), "three consumed casts cannot authorize a new one");
 check(smmMapAvailable(false, 2) && !smmMapAvailable(false, -1), "new mapping needs a valid remaining cast");
 fresh(); smmMapTestState.choice = 1435;
 check(smmAwaitMapChoice($location[The Haunted Storage Room], mapPage) == mapPage && actions == 0, "an actual mapping choice needs no extra adventure");
 fresh(); smmMapTestState.choice = 1468;
 check(waitMap() == mapPage && trace == "choice:4|adventure:0|", "configured June Cleaver interruption resolves before continuing the existing map");
 check(smmMapTestState.mapping && actions == 2, "interruption handling does not cast another map");
 fresh(); smmMapTestState.fight = true;
 check(waitMap() == mapPage && trace == "combat:0|adventure:0|", "wandering fight finishes before seeking the mapping choice");
 fresh(); smmMapTestState.choice = 9999;
 check(waitMap() == "" && actions == 0 && smmMapFailure != "", "unknown choices remain open without blind decisions");
 fresh(); smmMapTestState.choice = 1468; smmMapTestState.decision = 0;
 check(waitMap() == "" && actions == 0, "unconfigured June Cleaver choice is not guessed");
 fresh(); smmMapTestState.choice = 1468; smmMapTestState.decisionAvailable = false;
 check(waitMap() == "" && actions == 0, "an unavailable configured skip is not submitted");
 fresh(); smmMapTestState.choice = 1468; mode = 1;
 check(waitMap() == "" && actions == 1, "a rejected choice is not repeated or followed by an adventure");
 fresh(); smmMapTestState.mapping = false;
 check(waitMap() == "" && actions == 0, "a lost map stops instead of recasting or spending turns");
 fresh(); smmMapTestState.beaten = true;
 check(waitMap() == "" && actions == 0, "Beaten Up stops before another action");
 fresh(); smmMapTestState.canAdventure = false;
 check(waitMap() == "" && actions == 0, "no adventures stops before requesting the location");
 fresh(); mode = 2;
 check(waitMap() == "" && actions == 8, "an endless interrupt stream is bounded to eight transitions");
 fresh(); mode = 4;
 check(waitMap() == mapPage && actions == 8, "a mapping choice reached on the final allowed transition is accepted");
 fresh(); smmMapTestState.fight = true; mode = 3;
 check(waitMap() == "" && actions == 1, "unfinished combat is not attacked again or followed by an adventure");
 fresh(); smmMapTestState.choice = 1435;
 check(waitMap() == "" && actions == 0, "mapping choice id without its actual page is not submitted");
 fresh(); smmMapTestState.choice = 1468; mode = 5;
 check(waitMap() == "" && actions == 1, "lost mapping after a choice stops without another request");
 fresh(); smmMapTestState.choice = 1468;
 check(smmMapRecoverInterrupt() && actions == 1 && smmMapTestState.choice == 0 && smmMapTestState.mapping, "explicit recovery can settle a pending known interruption without adventuring");
 fresh(); smmMapTestState.choice = 1435; smmMapTestState.beaten = true;
 check(smmAwaitMapChoice($location[The Haunted Storage Room], mapPage) == "" && actions == 0, "an open map does not bypass Beaten Up readiness");
 if (failures == 0) print("PASS smmDailyMappingTest: " + checks + " checks");
 else print("FAILED smmDailyMappingTest: " + failures + " of " + checks);
}
