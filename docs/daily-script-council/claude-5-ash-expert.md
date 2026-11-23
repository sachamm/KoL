# Memo 5: ASH expert, architecture, state, quality, testing and migration

Author: ASH expert seat. Scope: how to build the new daily script so that it serves [aftercore-goals.md](../aftercore-goals.md) (spend free and expiring resources for items and Meat, spending rules 1 to 4, Museum #1). It also covers how to keep it testable and how to move off `dailyGrind()` without losing a day. Citations are `path:line` against this repo, KoLUtils and Tquilla's live prefs.

## Positions in one paragraph

Write the orchestrator in **ASH**. Keep `diet.js` as a JS phase called through a non-interactive flag. Do not start a libram/TypeScript rewrite. The new script, `smmDaily`, is a **thin task engine**: a registry of small tasks, each with `ready`/`completed`/`estimate`/`do`. It plans per phase with `smmResourcePlanner` and calls the existing `smm*` worker functions. It owns three cross-cutting gates that the old code lacks: a **spend gate** that every Meat outflow goes through, a **reserve gate** for MP, banishes, turns and organs, and a **journal** that makes any interruption resumable. Every task has a per-task flag `off | dry | legacy | on`. "legacy" calls today's code path, so migration happens one phase at a time with `dailyGrind()` as the fallback. A final **audit/sweep** task means an unfinished migration can never strand a day's resources.

---

## 1. Architecture

### 1.1 ASH, not JS/TS (for now)

| Factor | Evidence | Consequence |
|---|---|---|
| Everything the script must reuse is ASH | `smmUtils.ash` (10,637 lines), `smmResourcePlanner.ash` (649), `smmValue.ash`, `smmMuseumPolicy.ash`, `smmSpend.ash`, the IoTM route (`smmIotmRoute*.ash`, ~2,300 lines), `smmUnrestricted.ash` (7,178) | A JS/TS orchestrator could not call any of it directly |
| JS cannot import ASH | `diet.js:1937-1955` reaches Museum policy by `cliExecuteOutput('ash import <smmMuseumPolicy.ash>; smmMuseumSpareList(...)')` and regex-parses `Returned:` | Every crossing is stringly-typed and silently degrades ("Museum data unavailable") |
| A garbo-style TS build needs node, yarn and a bundler on both machines | garbo `packages/garbo/package.json` depends on `grimoire-kolmafia`, `libram`, `kolmafia` typings | Sacha's two-machine symlink workflow (README "Local development") would need a build step and a dist folder |
| What we want from garbo is the *pattern*, not the runtime | grimoire `Task {name, ready, completed, do, spendsTurn, limit}` (`garbo/src/tasks/dailyItems.ts:216-220`) and engine checks (`tasks/engine.ts:177-200`) | Easy to copy into ASH records plus `call` dispatch |

**Rule:** one language per process. ASH orchestrates. JS (`diet.js`) and other scripts (`fr`, `pr`, `nep`, `gbc`, garbo itself if the council decides to run it for part of the day) are **phases invoked by CLI**. Success is checked by observable state (organ fullness, `_` counters, turns), not by parsing output. Revisit TS only if Sacha decides to port smmUtils and the planner as well.

### 1.2 Entry point and file layout

```
scripts/smmDaily.ash            ~150 lines  main(string args): plan | run [phase|task] | dry | status | journal | resume | reset | audit
scripts/smmDailyCore.ash        ~500        records, settings registry, task registry, engine loop, journal, lock, settings save/restore
scripts/smmDailyGate.ash        ~300        smmDBuy / smmDUse / smmDCast / smmDCli / smmDAdventure gates; reserve checks; dry-run
scripts/smmDailyPools.ash       ~200        extra planner pools (MP, banishes, paid turns, organs, spend budget) layered on smmRPLiveResources()
scripts/smmDailyTasks<Phase>.ash  <= 600 each  Breakfast, Restore, FreeFights, Banish, Route, Grinds, Diet, Spend, Nightcap, Audit
```

- **No new code goes into `smmUnrestricted.ash`.** At first the task files `import <smmUnrestricted.ash>` (whole) so their `do()` can call `grindSpacegate`, `doBounty`, `grindBeerLens` and the rest unchanged. Over time, each extracted grind moves into `smmGrind<Name>.ash`, and a one-line forwarder stays behind for the CLI namespace (`data/smm-prefs.txt:8` sets `commandLineNamespace smmUnrestricted,smmEcon`).
- ASH has a single global function namespace across imports. Prefix every new symbol `smmD`. Declare `script "smmDaily"; since r29462;` so an old mafia fails loudly.
- Generalise, don't duplicate, the IoTM route's run harness. `smmIRDailyRoute` already has: a stale-lock recovery keyed on epoch (`smmIotmRoute.ash:421-431`), save/restore of 19 mafia settings including turning off `autoSatisfyWithMall` (`:440-458`), a receipt file written before each worker (`:483`), and restore in `finally` (`:507-511`). Move that harness into `smmDailyCore` as `smmDBeginRun()/smmDEndRun()` and have the route call it. One implementation then covers both.

### 1.3 Task model

ASH has no first-class functions. TourGuide solves this with **self-registration at import plus `call` dispatch by name**. Each module runs `RegisterResourceGenerationFunction("Name")` at top level (`TourGuide/.../Items of the Month/2024/Apriling Band Helmet.ash:2`, registry in `Sections/Globals.ash:59-65`), and the engine calls `call function_name(...)` (`Sections/Checklists.ash:202-217`). We copy that:

```ash
record SmmDTask {
    string id;          // "grind.spacegate"; also the journal key and flag name
    string phase;       // "breakfast" | "restore" | "free" | "banish" | "route" | "grind" | "diet" | "spend" | "nightcap" | "audit"
    string ready_fn;    // boolean f()   prerequisites: owned, unlocked, sober/drunk state
    string done_fn;     // boolean f()   keyed on MAFIA's daily counters wherever they exist
    string estimate_fn; // SmmRPAction f()  value and pool costs for the planner
    string do_fn;       // boolean f(int units)  performs, returns observed success
    string legacy_fn;   // void f()      today's code path, used when the flag says "legacy"
    boolean spends_turns;
    int max_attempts;   // default 2: after that it is FAILED for the day and skipped (garbo limit.skip)
};
SmmDTask [string] smmDTasks;

void smmDRegister(string id, string phase, string prefix, boolean turns, string legacy) {
    smmDTasks[id] = new SmmDTask(id, phase, prefix+"Ready", prefix+"Done", prefix+"Estimate",
                                  prefix+"Do", legacy, turns, 2);
}

// smmDailyTasksGrinds.ash, top level: runs at import, like TourGuide
smmDRegister("grind.spacegate", "grind", "smmDSpacegate", true, "smmDLegacySpacegate");
boolean smmDSpacegateReady() { return get_property("spacegateAlways").to_boolean() || get_property("_spacegateToday").to_boolean(); }
boolean smmDSpacegateDone()  { return get_property("_spacegateTurnsLeft").to_int() == 0 && get_property("_spacegateCoordinates") != ""; }
SmmRPAction smmDSpacegateEstimate() {
    SmmRPAction a = smmRPNewAction("Spacegate samples", 20, 0);
    a.loot_value = smmDGrindHistoryValue("spacegate") * 20;    // from the existing smm.grind.hist* ledger
    a.adventure_delta = -20;                                   // 20 paid turns
    a.costs["turns.paid"] = 20;
    return a;
}
boolean smmDSpacegateDo(int units) { grindSpacegate(gkSpacegateCoordinates); return smmDSpacegateDone(); }
void smmDLegacySpacegate() { dailyGrindBegin(); grindSpacegate(gkSpacegateCoordinates); dailyGrindEnd("spacegate"); }
```

(The exact mafia property names in the example must be checked against r29462's `defaults.txt` when the task is written. The test suite in section 4 enforces that.)

`call` resolves names at runtime, so a typo in a registered name only fails when that task runs. The test suite therefore resolves every registered name; see section 4.

### 1.4 Engine and planner

Per phase, in the order the efficiency lead sets:

1. Collect tasks whose flag is not `off`, whose `ready()` is true and whose `completed()` is false.
2. Call each `estimate()` to get an `SmmRPAction`. Solve the phase block with `smmRPSolve(actions, smmDPools(), smmRPReservations(), ctx)`. Blocks are capped at 64 candidates (`docs/resource-planner.md`), which fits a phase. Across phases, **reservations** carry the allocation forward: at run start the engine reserves `turns.paid`, `banish.*` and `mp.reserve` for later daily-limited phases (`smmRPReserve`, `smmResourcePlanner.ash:462`). The IoTM route then cannot eat them, which fixes the review's "uncapped route starves Spacegate/FR/PR/DD/Drip" finding. Feeding the route `smm.IR.maxPaidTurns = allocation` for that run also works with no route change.
3. For each selected task, run the step below. Replan when a pool differs from expectation, which is the route's `smmIRMaterialChange` idea (`smmIotmRoute.ash:346`).

```ash
boolean smmDStep(SmmDTask t, int units) {
    smmDInterruptCheck();                         // smm.daily.interrupt=true or < smm.daily.rolloverBufferMin to rollover -> clean stop
    if (handling_choice() || current_round() > 0) abort("smmDaily: unresolved encounter before " + t.id);
    SmmDSnap before = smmDSnapshot();             // turns, adv, meat (liquid), mp, organs, banishes, valued holdings
    smmDJournal("BEGIN", t.id, before, "");
    SmmRPLease lease = smmRPBegin("smmDaily." + t.phase);
    boolean ok;
    try {
        if (smmDFlag(t.id) == "legacy") { call void t.legacy_fn(); ok = true; }
        else ok = call boolean t.do_fn(units);
    } finally {
        smmRPFinish(lease);                       // commits only observed consumption
    }
    SmmDSnap after = smmDSnapshot();
    boolean done = call boolean t.done_fn();
    if (!t.spends_turns && after.turns > before.turns) smmDWarn(t.id + " spent turns but is marked free");  // garbo engine.ts:192-199
    smmDJournal(ok && done ? "END" : "FAIL", t.id, after, smmDDelta(before, after));
    return ok && done;
}
```

`do()` returns *observed* success. The engine believes `completed()`, not `do()`'s own claim.

---

## 2. State, preferences, journal, dry run

### 2.1 Naming

| Kind | Name | Lifetime | Example |
|---|---|---|---|
| User setting | `smm.daily.<name>` | permanent, shareable via `data/smm-prefs.txt` | `smm.daily.dryRun`, `smm.daily.mpReserve=2000`, `smm.daily.rolloverBufferMin=10` |
| Per-task flag | `smm.daily.task.<id>` | permanent | `smm.daily.task.grind.spacegate = on\|dry\|legacy\|off` |
| Run lock / restore | `smm.daily.active`, `smm.daily.savedSettings` | until the run ends; stale if the epoch differs | `20261123:231` |
| Today's counters we must own | `_smm.daily.<id>.<field>` | mafia clears `_` at rollover | `_smm.daily.grind.spacegate.attempts=1` |
| Journal and receipts | **file** `data/smm-daily-<playerid>.txt` | append, rotate by epoch | see 2.3 |

Rules:

- **Use mafia's own daily properties for `completed()` wherever they exist** (`_spacegateToday`, `_frToday`, `_beerLensDrops`, `_birdsSoughtToday`, ...). Only write our own `_smm.daily.*` flag when mafia does not track the thing. Never write into a name that looks like mafia's: `smmUnrestricted.ash:6743` sets `_fantasyRealmDone`, which shadows the real `_frToday`.
- **Declare every setting once** with type, default and a one-line doc, the way ChIT does (`chit_global.ash:583-589`, `chit_setvar(name,type,def)`). `smmdaily status` can then print every knob and its current value, and the docs table can be generated from it. Today, defaults are scattered inline (`smmUnrestricted.ash:750-753`, `smmSpend.ash:32-57`).
- **Keep bulk state out of prefs.** Tquilla's prefs already hold **1,777 `smm*` properties, 1,695 of them `smm.IR.museumHold.*`** (`tquilla_prefs.txt`), and mafia rewrites that file on changes. The journal, histories and per-item holds belong in `data/*.txt` via `map_to_file`/`buffer_to_file`, like the Museum rank store (`docs/collection-objective.md`, "Museum ranking store").
- **One turn value.** Mafia has `valueOfAdventure=4500` (`data/smm-prefs.txt:11`) while the scripts read `smm.TurnValue` (default 5000) at *import time* (`KoLUtils/scripts/smmUtils.ash:150`). `smmDaily` should read one value per run, print it in the journal header, and warn when `valueOfAdventure` differs by more than 10%, because the maximizer, garbo and mafia's own buying use the latter.

### 2.2 Daily reset

Use the planner's epoch, `smmRPEpoch() = today_to_string() + ":" + my_ascensions()` (`smmResourcePlanner.ash:106-108`). The KoLmafia wiki says `today_to_string()` is pinned to rollover, not local midnight ([Today_to_string](https://wiki.kolmafia.us/index.php/Today_to_string)), so a run crossing Sacha's local midnight stays one day. On start:

1. If `smm.daily.active` holds a different epoch, clear it the way the route does (`smmIotmRoute.ash:421-431`): restore saved settings and gear, then continue.
2. If it holds today's epoch and there is no encounter, treat it as an interrupted run and **resume**. If there is an encounter, abort with instructions.
3. Read the rollover deadline with `rollover()`. Refuse to start a paid-turn task within `smm.daily.rolloverBufferMin` minutes, as garbo's `safeInterrupt` does (`garbo/src/lib.ts:196-212`).

### 2.3 Journal and resume

Append-only TSV, one line per event, flushed **before** `do()` starts:

```
epoch      seq ts        task              event  turns adv  meat       mp    note
20261123:231 41 21:14:03 grind.spacegate   BEGIN  31204 312  150814833  2410
20261123:231 41 21:19:47 grind.spacegate   END    31224 292  150851020  1980  +36187 Meat, samples x3 (closet)
20261123:231 42 21:19:48 grind.pirateRealm SKIP   -     -    -          -     flag=off
```

Resume semantics:

- A `BEGIN` with no matching `END/FAIL` means the task was interrupted. On restart, check `completed()`. If true, write `END(recovered)`. Otherwise increment `_smm.daily.<id>.attempts`. At `max_attempts`, write `FAIL` and move on. One broken task can then no longer stop the day, which is the old `abort()` problem, and cannot loop either.
- Daily-limited tasks are naturally idempotent because `completed()` reads mafia counters. Multi-step tasks (diet phases, nightcap) store a step cursor in `_smm.daily.<id>.step`.
- `smmdaily journal` prints today's lines plus a reconciliation: turns, Meat, MP and banishes per task and in total, against the session log totals.
- Keep `smm-iotm-route-last.txt` as is. The route task copies its `SUMMARY` line into the journal.

### 2.4 Dry run, and gates for every irreversible action

`smm.daily.dryRun=true` (global), or a task flag of `dry`, means:

- The engine runs `ready`, `completed` and `estimate`, solves, and prints the plan with `why` lines, like `iotmroute plan`.
- It **does not call `do()`**. Dry-running real adventure code is impractical, because the outcome of the first fight decides the second.
- Every effectful call made anywhere under the engine (buy, use/eat/drink/chew, cast, adventure, workshed swap, `cli_execute` of another script) goes through a gate in `smmDailyGate.ash`. The gate prints and journals `DRY would ...` and returns false when dry. A task left in `legacy` mode cannot be dry-run safely because it calls old code directly, so a `dry` flag on a legacy task only prints the plan.

The **spend gate** is the important one:

```ash
// The only way smmDaily code buys anything.
int smmDBuy(item it, int qty, string kind /* "operating" | "discretionary" */, float value_each, string why) {
    int avg = to_int(smmSpendAveragePrice(it));                     // rule 3 ceiling: average sale price (smmSpend.ash:140)
    int cap = avg > 0 ? min(avg, floor(value_each)) : min(mall_price(it), floor(value_each));
    if (cap <= 0 || mall_price(it) > cap) { smmDJournal("SKIP", "buy", it + " @" + mall_price(it) + " > cap " + cap); return 0; }
    int budget = kind == "discretionary" ? smmSpendBudget() : smmDOperatingBudget();  // rule 2 for discretionary
    qty = min(qty, budget / cap);
    if (qty < 1) return 0;
    if (smmDDry()) { smmDJournal("DRY", "buy", qty + " " + it + " <= " + cap + " (" + why + ")"); return 0; }
    int before = smmSpendLiquidMeat();
    int got = buy(qty, it, cap);
    smmDBook(kind, max(0, before - smmSpendLiquidMeat()));   // booked into _smm.spend.* so smmSpendNet() stays honest
    return got;
}
```

For the whole run, `smmDBeginRun()` sets `autoSatisfyWithMall/NPCs/Coinmasters=false`, as the route already does (`smmIotmRoute.ash:454`). Mafia then cannot buy implicitly inside `retrieve_item`, `use`, `fueled_asdonmartin` or recovery, and any shortfall shows up as a failed task instead of an unbudgeted purchase. "Operating" spend (diet, Asdon fuel, buff inputs) is limited to the task's own planner `input_cost`, so it only happens when the task's expected return is positive (rule 1). The efficiency lead should rule on whether operating spend also counts against the half-of-net cap. The gate supports either answer.

The **reserve gate** gives MP, banishes and organs explicit floors (`smm.daily.mpReserve`, default 2000 per the ledger). `smmDCast` refuses to go below the floor. The `burnMP` replacement passes the floor through rather than calling `moodExecute()` first (see 3.6).

---

## 3. Problems in the existing code the new script must not inherit

1. **Monolith, no entry point.** `smmUnrestricted.ash` is 7,178 lines and 299 KB with no `main`. It runs through `commandLineNamespace` (`data/smm-prefs.txt:8`), so every top-level function is an entry point, with no argument parsing and no lock. `dailyGrind()` (`smmUnrestricted.ash:6612-6810`) mixes sequencing, policy (banish reserves at `:6683-6685`), value tests and reporting. *New rule:* orchestration in `smmDailyCore`; files of 600 lines or fewer; one task per concern.
2. **Prompts in an unattended run.** `dailyGrindConfirm` falls through to `user_confirm` (`smmUnrestricted.ash:715-723`). More prompts sit at `:1833`, `:2618`, `:2623`, `:4576`, `:4581` and `:6326-6338`, in `fullAcquire` (`KoLUtils/scripts/smmUtils.ash:1316-1318`) and in `smmRecovery.ash:20`. Worst case: **`diet.js:3272` defaults to *false* after 60 s**, so an unattended run skips the whole diet (about 230 adventures) and only prints "Diet not executed." *New rule:* no `user_confirm` under the engine. Decisions are settings or planner outputs, and `diet.js` gets a `yes` argument (a one-line change) that the diet task always passes.
3. **`abort` as control flow.** `abort("user aborted")` at `smmUnrestricted.ash:6640` (banisher prompt) and `:2619/:2624/:4577/:4582`, plus `assert()` on the Asdon swap (`:6777-6778`), end the *whole day*. Everything after them is lost. ASH's `try/finally` runs cleanup but does not stop the abort, so the defence is architectural: tasks return false, the engine journals `FAIL` and moves on, and `abort` is reserved for unsafe states (an unresolved encounter, Beaten Up, a broken lock).
4. **Silent failures.** `unused = cli_execute("dc top10 " + ...)` (`:6741`), `unused = cli_execute("basty win")` (`:2949`, `:6822`), unchecked `use_skill(1, $skill[blood blade])` twice (`:3025-3026`), and `cli_execute("nep prep; nep party;")` (`:6546`, `:6664`) with the result dropped. *New rule:* every gate returns a result, every task checks `completed()` afterwards, and nothing is assigned to `unused`.
5. **Buying paths that bypass the cap and the price ceiling.**
   - `fullAcquire` buys through `newAcquire`→`buy(..., priceLimit*1.05)` (`smmUtils.ash:1236`). When it falls short it calls `retrieve_item` (`:1330`), which with `autoSatisfyWithMall=true` and `autoBuyPriceLimit=20000` (`data/smm-prefs.txt:13,19`) buys from the mall silently.
   - `fuelAsdonMartin` buys at `historical_price * 1.05` (`smmUtils.ash:7417`), above the rule-3 ceiling.
   - The builtin `fueled_asdonmartin` is called at nine sites (`smmUnrestricted.ash:669, 1444, 1487, 5118, 5134, 5416, 5427, 6357, 6776`) with mafia choosing and buying the fuel.
   - `secondBreakfast` calls `fullAcquire($item[maple magnet])` (`:3028`), and `buySpecials` loops over `buy` (`smmUtils.ash:4830-4841`).
   - `smmSpendBuy` (`smmSpend.ash:161-182`) is the only path that books spend. All the others only lower `smmSpendNet()`.
6. **Reserves that are not honoured.** `burnMP` runs `moodExecute()` "regardless of burnAmount" before applying the reserve (`smmUtils.ash:2461-2463`). The default reserve is `max(150, base Myst)` (`:2511-2515`). That is how 17,797 MP went on songs and the 2026-11-21 run stalled (resource ledger, "Bottlenecks").
7. **Global mutable state.** `gGrindTurnMark/gGrindMeatMark/gGrindInventoryMark` (`smmUnrestricted.ash:747-749`) are overwritten by any nested `dailyGrindBegin`. `kTurnValue` is computed at import (`smmUtils.ash:150`). *New rule:* pass a `SmmDSnap` record. No script-level variables except the registry and the run context.
8. **Completion flags that lie.** `_smm.GrindDone` is set whether or not the Oasis ran (`:6702`), and `_fantasyRealmDone` is set after any attempt (`:6743`). Gate flags such as `_smm.UseBanishersConfirmDone` and `_smm.LandPreGrindDone` encode "prompt answered", not "work done". *New rule:* `completed()` describes the world; skip reasons go to the journal, not into flags.
9. **Measurement gaps.** `dailyGrindEnd` measures `my_meat()` only (`:803`, `:815`), so purchases from closet or storage Meat are invisible. It values items at `historical_price`, not realizable value. *New rule:* snapshots use `smmSpendLiquidMeat()` and `smmItemLiquidValue`/`smmMuseumOwnedValue`.

---

## 4. Testing without a live game

**State today:** the repo has one test, `tests/nightcap-adventure-bounds.cjs` (node `vm` against `diet.js`). The planner and route docs reference harnesses in a separate "KoL Automation workspace": `fixes/resource-planner/run-tests.sh` and `fixes/iotm-route/run-tests.sh`. They run the installed KoLmafia JAR in an isolated runtime with test preferences and a fake HTTP client that rejects unexpected requests (`docs/resource-planner.md` "Validation"; `docs/iotm-route.md` "Validation"). **Neither harness is in the KoL or KoLUtils repo.** First action: commit it as `tests/run-tests.sh` so both machines and future PRs can run it.

### Layers

1. **Compile.** Run headless mafia (`java -jar KoLmafia.jar --CLI` with a scratch `settings/`) and call `verify smmDaily.ash` (`verify`/`validate` = "check/run script", [CLI Reference](https://wiki.kolmafia.us/index.php/CLI_Reference)) for every entry point. Also run `ash import <smmDailyTasksGrinds.ash>` per task file, so every import graph compiles on r29462.
2. **Registry integrity.** Load all task files and, for each registered task, `call` its `ready/done/estimate` functions in test mode. This catches misspelled `call` targets. Also check each property named in a `completed()` against mafia's `defaults.txt` or the planner's registry check, which "resolves every source and property against Mafia".
3. **Functional core, imperative shell.** Put decisions (`ready`, `completed`, `estimate`, phase ordering, reservations, spend gate arithmetic, journal parse/resume) in functions that read a `SmmDSnap`/property map, not built-ins. ASH cannot monkeypatch `my_mp()`. The seam is a reader: `smmDProp(name)` returns `smmDTestProps[name]` when `smmDTestMode` is set, otherwise `get_property(name)`. Tests build snapshots in plain ASH.
4. **Fixtures.** Parsing (Spacegate, PirateRealm, garden pages) uses saved HTML, as the route tests already do with real rose-garden, campground and Cup HTML. The fake HTTP client guarantees no live request.
5. **JS.** Keep node `vm` tests for `diet.js`. Add one for the new non-interactive flag: no `userConfirm` call when `yes` is passed.

### Minimum suite

- The journal round-trip covers: BEGIN without END leads to recovery; attempts reach `max_attempts` leads to FAIL and the run continues; a stale epoch lock is cleared and settings are restored.
- **Spend gate:**
  - it never exceeds `smmSpendBudget()`;
  - it never pays above the average sale price;
  - it never buys at less than a 20% discount for "cheap";
  - dry run buys nothing;
  - operating vs discretionary booking keeps `smmSpendNet()` correct.
- **Auto-satisfy:** after `smmDBeginRun` every `autoSatisfyWith*` buy flag is false, and `smmDEndRun` restores it even when the body aborts.
- **Reserve gate:** a cast below `mpReserve` is refused. Banish reservations for later phases are honoured by the route (planner lease regression).
- **Allocation:** with 40 paid turns and the route plus four daily-limited grinds eligible, the daily-limited grinds keep their reservation. This is the regression for the "route starves grinds" finding.
- **Flags:** `off/dry/legacy/on` dispatch to the right function; `legacy` calls exactly the old function.
- **No prompts:** a grep test fails the build if `user_confirm`/`userConfirm` appears in any file imported by `smmDaily` outside an allow-list (`dc.ash` interactive commands).
- **Resolvability:** every registered `call` name resolves, and every property in a `completed()` is known to mafia.

### Staging the first live run

1. **Day 0, read-only:** `smmdaily plan` before the normal `dailyGrind`. Compare its plan with what `dailyGrind` then does (journal vs session log).
2. **Day 1, global dry run:** `smm.daily.dryRun=true`, `smmdaily run`. It prints every intended buy, cast and adventure block and changes nothing, then Sacha runs `dailyGrind` as usual.
3. **Days 2 onwards, one phase at a time:** flip one phase from `legacy` to `on` per day, safest first (order in section 5). Use `smm.daily.halt=<task id>` to stop right after a named task (as garbo's `halt`, `garbo/src/tasks/engine.ts:220-233`), and `smm.daily.interrupt=true` for a clean stop between tasks (garbo `lib.ts:207-211`).
4. **Acceptance per phase:** the journal reconciles with the session log within 1% on turns and Meat; no Meat outflow outside `smmDBuy`; the end-of-day audit shows no daily pool left unused that `dailyGrind` would have spent.

---

## 5. Migration from `dailyGrind()` without losing a day

**Principle:** every new task starts with `legacy_fn` pointing at the exact code `dailyGrind()` runs today. With all flags at `legacy`, `smmdaily run` reproduces `dailyGrind()` in its current order. The only differences are the journal, the gates (where legacy code calls them), the run lock and no prompts, since legacy prompts are answered from `smm.dailyGrind.*` presets, which the new script sets for its run. Flipping a task to `on` swaps in the new implementation for that task only.

### Safety net: the audit/sweep task (runs last in every mode)

`audit` reads `smmRPLiveResources()` plus `smmDPools()` (MP, banishes, organ space, free fights such as CyberRealm/Snojo, `_spacegateToday`, `_frToday`, ...). It lists every pool with capacity left and no owner. For each one that has a legacy runner, it runs it (`sweep`), or with `smm.daily.audit=report` it only reports. Then if a new task fails, is flagged off, or the run is interrupted, the old code still uses the resource that day. Run `smmdaily audit` before `good_night()` in every mode.

### Order (lowest risk and no-legacy gains first)

| Step | Phase | Why this order |
|---|---|---|
| 1 | `audit` (report only) and journal | Zero risk; measures what is being lost today |
| 2 | `free`: CyberRealm and Snojo (20 unused free fights, ledger) | New value, no legacy to break, no turns |
| 3 | `restore` + reserve gate (bat-wing rests, nuns, car battery before songs; `mpReserve=2000`) | Fixes the 11-21 stall before anything else depends on MP |
| 4 | `spend` (wrap `smmSpendRun`; switch `fullAcquire`/Asdon fuel callers to `smmDBuy`) | Already gated and dry-runnable (`smm.spend.dryRun`) |
| 5 | `diet` (`call diet.js execute yes` / `finish yes`, verified by organ fullness) | Biggest single value line; currently can silently not run |
| 6 | `banish` grinds (Oasis, beer lens, ghost, bounty) with planner banish pools | Needs the reserve gate from step 3 |
| 7 | `route`: reservations for daily-limited grinds before `smmIRDailyRoute` | Fixes starvation; route code unchanged |
| 8 | `grind`: Spacegate, FR, PR (Museum-led reliquary choice), DD, Drip, Gingerbread | Each flips separately; the legacy ledger keeps measuring |
| 9 | `nightcap` (`good_night` contents) | Last: depends on overdrink state and diet step 5 |

**Cutover.** Once every phase has been `on` for seven consecutive days with clean journal reconciliation and empty audits, make `dailyGrind()` a two-line forwarder (`cli_execute("smmdaily run")`) so muscle memory and aliases still work. Keep the old body as `dailyGrindLegacy()` for 30 days, then delete it. **Rollback** at any point: set the task flag to `legacy`; no code change, no redeploy.

**Never run the two side by side unmanaged.** During migration `dailyGrind()` is not run separately. `smmdaily run` with `legacy` flags *is* `dailyGrind()`. Running both would let `dailyGrind`'s uncapped route take the turns the new script had reserved. If Sacha does run `dailyGrind()` by hand, the next `smmdaily` start finds those tasks completed through mafia's counters and skips them. That is the idempotency requirement in 2.3.

---

## Open items for other seats

- **Efficiency lead:** phase order, whether operating spend counts against the half-of-net cap, and per-pool reserve sizes.
- **KoLmafia expert:** confirm property names for each `completed()` on r29462, the exact `call <type> name(args)` syntax, and whether the developer `test` command can feed fixture HTML to parsers on this build.
- **garbo expert:** if garbo runs for part of the day, it is one task (`do = cli_execute("garbo ...")`, `completed = adventures spent`) whose turns come from the planner's `turns.paid` reservation, with `valueOfAdventure` set from the run's single turn value.
