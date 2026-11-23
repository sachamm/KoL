# Daily script plan

This is the plan for `smmDaily`, a new daily script for Tquilla that will replace `dailyGrind()` over a few weeks. **Nothing in it has been run in KoLmafia yet.**

## How this plan was made

Two councils worked on the same brief in parallel. Each had five members: an efficiency lead, a KoL strategist, a KoLmafia expert, a garbo expert and an ASH expert. One council was Claude, the other ChatGPT, and each wrote its own plan. This document merges the two.

The sources were the repo docs and scripts, KoLUtils, garbo's source (main at `eaa1455`, release `6bc8b68`), Tour Guide and ChIT, the KoL and KoLmafia wikis, the session logs for Nov 19, Nov 21 and Nov 23 (`Tquilla_20261121.txt`, `Tquilla_20261123.txt`), and the current preferences file.

Where the councils disagreed and the evidence settled it, this document says so. Where it didn't, the question is in **Decisions for Sacha**, with a recommendation.

Every claim taken from either plan was re-checked against the repo, garbo's source or the logs before it was kept. Claims that could not be checked are marked **(unverified)**.

## 1. Summary

**What the script is.** `smmDaily` is an ASH task engine. It runs the day as a short sequence of phases.

- Each phase owns certain resources and has a done-test made of Mafia properties.
- Every phase can be restarted after an interruption.
- One shared gate controls every Meat outflow, and another holds back reserves: MP, banishes, turns and organ space.
- A journal records each action before and after it runs.
- It reuses the existing code (the IoTM route, the resource planner, `dc.ash`, `smmSpend.ash`, the grind functions, `diet.js`) and adds no new farming logic of its own.

**Strategy.** Sacha's scripts are good at the Museum: rank-aware values, the unbuyable grinds, the newest IoTMs, upward-only deposits and the spending rules. garbo is good at Meat: Barf Mountain, the diet, free fights and copy chains. Sacha already runs the two back to back: on Nov 23, `dailyGrind` was followed by `garbo -10` (`Tquilla_20261123.txt:53693`). The plan makes that hybrid deliberate and safe, in this order:

1. A **fence** and a plan.
2. **Museum and rate-limited work**, with a cap on the turns it may take.
3. **`garbo -N`** as the Meat engine.
4. **Deposits, selling, the spending step and the nightcap.**

The Oasis stops being the default farm and runs only when the Museum needs what it drops. garbo does not follow Sacha's spending rules on its own, so the plan fences it, pre-buys its predictable purchases, and books everything it buys against the day's budget. A stricter alternative is offered as decision 1: a bounded Oasis first, and garbo only later through an audited bridge.

**Expected gain.** About **+0.4M to +1.2M Meat-equivalent a day** in recurring gains over current practice. Of that, about **+0.2M a day of cash** rests directly on the logs: moving about 120 Oasis turns to Barf. The rest depends on how often days are lost and on prices that haven't been measured yet. One-off gains are counted separately:

- nine cheap #1s (about 2.5M);
- free top-ten deposits;
- selling surplus stock: the ledger values it at about 700M at the shop's own asking prices, but what will actually sell has not been measured.

The two councils' first estimates differed by an order of magnitude; §6 explains how they were reconciled.

**Decisions for Sacha:**

1. **garbo now or later?** Recommended: keep garbo as the Meat engine now, fenced, capped with `garbo -N` and with its purchases booked against the day's budget. The alternative is a bounded Oasis until an audited garbo bridge exists.
2. **What counts against the half-of-net cap?** Recommended: the stricter reading, operating spend + discretionary spend ≤ 0.5 × net. It rarely binds, because operating spend is about 0.3M a day against a net of several million.
3. **Do sales of old stock count as today's net?** Recommended: yes for true surplus (it is a resource being spent, and that is how `smmSpend` already counts it), reported on its own line.
4. **How much may the unbuyable grinds take?** Recommended: up to 100 paid turns a day, with each grind passing the Museum value test in §3. ChatGPT proposed 40 turns and 200k of loss.
5. **Museum rules.**
   - Do visible ties count as top ten?
   - Should the 11-copy buffer be optional for expensive items?
   - Is a top-ten place worth 0.5 of a #1 when scoring?
   - Recommended shopping order: biggest discount first, with milestones only breaking ties, as in your literal rule.
6. **Deposit the glut?** Recommended: put everything beyond 180 days of measured sales into the Display Case. With `smm.dcAllowRemoval=false` this is effectively permanent.
7. **Buy the Dinseylandfill charter** if it pays back within 60 days? garbo has been buying one-day tickets for 143k to 153k.
8. **One runner, and what to leave alone.** Recommended: Windows runs the day, and switching machines mid-day needs an explicit handoff. Also confirm what must be left for manual play, the clan and the nightcap.

## 2. What the councils found

These facts correct the resource ledger and the brief.

| Topic | What is true | Evidence |
|---|---|---|
| **`valueOfAdventure`** | It is **4,500**, not 500. The scripts still use 5,000 because `smm.TurnValue` is unset. | `data/smm-prefs.txt:11`; garbo printed `Using adventure value 4500.` (`Tquilla_20261123.txt:53694`) |
| **MP stall** | `burnMP` did not spend 17,797 MP: a negative argument means "keep this much" (`smmUtils.ash:2450-2457`). What actually happens: <br>• Rollover leaves MP near 0 (2,089 on Nov 21, 82 on Nov 23). <br>• Breakfast spent the rest on Nov 21: 22 libram summons cost about 1,793 MP, since the n-th summon costs `1+n(n-1)/2` ([wiki](https://wiki.kingdomofloathing.com/Mystical_bookshelf)). <br>• Recovery is off (`mpAutoRecovery=-0.05`, no `recoveryScript`). <br>• `burnMP` runs the mood **before** it honours its reserve (`smmUtils.ash:2461-2463`), and again in `finally` (`:2488`). <br>• A failed mood cast aborts the day. <br>In short, steps that spend MP run before steps that gain it. | `Tquilla_20261121.txt:542,1424,1501`; `Tquilla_20261123.txt:178,1112` |
| **MP supply** | Plenty once it is collected first: 11 bat-wing rests of 1,000, 3 nuns visits of 1,000, License to Chill, Gulp Latte (one gulp gave 39,200), free rests and the car battery. Bought MP costs about 1 Meat per MP. Separately, `burnMP` cast Fat Leon's for 662 turns with about 400 turns left. | `Tquilla_20261123.txt:23293` |
| **Sword of S Words** | Its 100 daily kills are the largest single value line. On Nov 19 garbo used all 100 and got 72 LED blocks (2.92M) and 72 synthetic stuffing (2.40M) at listing prices; the LED blocks went into the case. On Nov 23 `dailyGrind` used 1 kill in 220 turns and left the rest to garbo. So the Sword is wasted only on days garbo doesn't run, like Nov 21. The Sword's value must also be charged for the familiar it displaces and the native item drops it replaces. | Nov 19 log (garbo summary, `put in display case: 72 LED block`); `Tquilla_20261123.txt:7498-7523` |
| **Oasis or Barf** | Barf under garbo made **4,329 raw Meat a turn** on Nov 19 (211 turns) and **3,723** on Nov 22 (350 turns, `garboResults*` prefs). The Oasis on Nov 23 made **2,367 raw Meat a turn**, plus 65 mojo filters, 66 hammers and 70 happiness. Tquilla already holds 42k, 77k and 43k of those and is #1 in all three, so the extra copies are worth almost nothing on the market. | Nov 19 log; Oasis block ending `Tquilla_20261123.txt:39205`; ledger |
| **Grind ledger** | Its figures can't be used: the Oasis at 325k a turn, the ghost costume at 3.3M a turn, Gingerbread at 45.9M in 0 turns, and every grind exempt from the turn-value test. Three causes: <br>• gains are diffs of holdings, so stock moves show up as income; <br>• items consumed are ignored ("Only gains count", `smmUnrestricted.ash:818`); <br>• any untradeable drop counts as a Museum gain. | `Tquilla_20261123.txt:53460-53469`; `smmUnrestricted.ash:808-852` |
| **Banishes** | Not a bottleneck once the script knows all its sources. Spring Kick, Monodent lightning, Saber Force and 474 gingerbread restraining orders are missing from the selector. Batter Up! is listed but is Seal Clubber only. Monodent lightning kills, keeps the drops and banishes for the rest of the day ([wiki](https://wiki.kingdomofloathing.com/Sea_*dent:_Throw_a_Lightning_Bolt); Tour Guide `2025/Seadent.ash:21,61`). ChatGPT reports that Mafia tracks **only one active Monodent banish**, so 11 casts are reusable control, not 11 banishes at once (unverified; check in game). | Tour Guide; KoL wiki Banish page |
| **"20 unused free fights"** | Snojo isn't unlocked (`snojoAvailable=false`). CyberRealm free fights need OVERCLOCK(10), Torso Awareness and a zero-trust tanktop. Its halfway noncombat may use up a fight, and the constructs block normal skills. garbo already runs both once they're available (`tasks/freeFight/index.ts`). Treat them as one-time unlock projects. | prefs |
| **Sandworms** | 32 drum-machine sandworm fights on Nov 19 and Nov 23 dropped **0 spice melange**. Today `burnChampagneBottle(true)` spent 11 paid turns and 11 drum machines at 3,400 for about 35k Meat. garbo also buys drum machines, priced only at mall price (`tasks/freeGiantSandworm.ts:395`). Drum machines are a Museum item (#4). | `Tquilla_20261123.txt:10404` |
| **garbo uses up Museum stock** | On Nov 19 garbo burned 410 inflammable leaves into lassos and a day shortener (`tasks/dailyItems.ts:614-633`), ate 7 Special Seasoning (`diet.ts:1485`) and used 7 drum machines. Its `acquire` takes from Hagnk's and Sacha's own store before buying. | Nov 19 log; `acquire.ts` |
| **garbo against the spending rules** | Verified in the source: <br>• it turns mall, NPC and coinmaster auto-buying on (`index.ts:270-272, 348-350`) and clears the adventure hooks (`:360-363`); <br>• its only size guard is 3M per `acquire` call (`acquire.ts:60`); <br>• `nodiet` still eats chocolates and other non-organ adventure items (`index.ts:531-534`); <br>• its MP recovery eats magical sausages (`restore.ts:73`) and aims for 200 MP; <br>• `garbo 0` or no number means **no limit** (`index.ts:153`); <br>• there is no reserve or protected-stock option (`config.ts`). | garbo source |
| **Museum threshold mismatch** | `smmTargets.ash:257-258` counts a tie with the tenth-largest other collection as top ten. `smmMuseumPolicy.ash:33` requires one more copy. The two must agree. | repo |
| **Drip eats organ space** | `grindDrip` eats a drippy nugget and drinks drippy wine whenever there's room (`smmUnrestricted.ash:1392-1399`), even when the saved `drippyJuice` already covers the run. At 4,500 a turn, 5 fullness of the regular diet is worth about 130k. | repo |
| **Prompts and aborts** | The six `dailyGrindConfirm` prompts have no presets. `diet.js:3272` defaults to *no* after 60 seconds, so an unattended run skips the diet. Several `abort()` calls end the whole day (`smmUnrestricted.ash:6640, 6777-6778`). | repo |
| **Request load** | About 3,000 logged requests and about 250 maximizer runs for 350 adventures today. That is 2.3 equips per adventure, and `burnMP`/`preAdventureChecks` ran about 600 times. | `Tquilla_20261123.txt` |
| **Test harnesses** | The docs mention `fixes/resource-planner/run-tests.sh` and `fixes/iotm-route/run-tests.sh`, but neither is in the repo. The only test is `tests/nightcap-adventure-bounds.cjs`. | repo |

## 3. Where the councils disagreed

| Topic | Claude council | ChatGPT council | Resolution |
|---|---|---|---|
| Meat engine | garbo hybrid now | Bounded Oasis first; garbo later through an audited JS bridge | **Decision 1.** Recommended: hybrid, because garbo is already part of the day and the logs favour Barf. Its rule violations are made visible and booked |
| Operating spend in the cap | Outside the cap | Inside: C + D ≤ 0.5N | **Decision 2.** Recommended: ChatGPT's stricter reading. It rarely binds, and `smmSpend` already counts positive-return buys inside the budget (`docs/daily-spending.md`) |
| Stock sales count toward net | Yes | No; report separately | **Decision 3.** Recommended: yes for surplus, on its own line |
| Starting turn value | 4,500 (the live value) | 5,000 (the ledger) | **Settled: 4,500.** It is the live `valueOfAdventure`, garbo's value, and closer to measured Barf. Calibrate after 5 days |
| Unbuyable budget | 100 turns, each grind value-tested | 40 turns + 200k loss | **Decision 4.** FantasyRealm and PirateRealm alone took 62 turns on Nov 23, so 40 would drop one of them every day |
| Size of the gains | +1.5M to +3M a day | Tens to 150k per row | **Reconciled in §6:** +0.4M to +1.2M recurring, separating log-based cash from estimates and one-offs |
| Banishes | Plentiful once the list is fixed | Model each source: uses, active slots, duration, scope, turn cost | **Both.** The per-source model is adopted, with Monodent conservatively treated as one active banish |
| IoTM priority | Newest first (route doc) | By payoff | **By payoff.** The 2025 gaps (Peridot, Monodent, shrunken head, Möbius) come before more 2026 work |
| Fallback during migration | Each task's `legacy` mode calls today's code | Legacy code still has uncontrolled buyers, so it is not a safe fallback | **Both.** `legacy` keeps the day running. Its purchases are booked from the session log and flagged until each task moves to `on` |

## 4. Objective and valuation

### 4.1 One score and four kinds of value

The goal is #1 in the Museum for every item, with the top ten accepted (`docs/aftercore-goals.md`). The script keeps one score:

> **S = N₁ + 0.5 · N₁₀**, where N₁ counts items at #1 and N₁₀ items in the top ten but not #1 (decision 5). A lost place lowers S. Only copies actually in the Display Case count, with a usable ranking snapshot behind them.

Four kinds of value are kept separate. A copy that is kept for the case is never also counted as sold.

| Value | Used for | Can it unlock spending? |
|---|---|---|
| Realized cash, net of operating costs | The half-of-net cap | Yes |
| Liquid value of surplus | Comparing farms, sales and conversions | No, not until sold |
| Avoided purchase cost of a needed copy | Earn-and-buy against farm-and-keep | No |
| Museum value of a gap closed | Admitting unbuyable work | No |

**The Museum's Meat price, c\*.** The spending step keeps a queue of buyable milestones, sorted by Meat per point. c\* is the Meat per point of the last milestone the day's budget buys. That price values the rest:

- An unbuyable copy that closes a gap is worth `Δpoints × c* ÷ copies still needed`.
- A grind may run only if `Δpoints × c* + liquid value ≥ turns × turn value`. Rare drops count at their expected value.

This replaces two things:

- `smm.IR.museumRankValue`, which defaults to one turn's value (`docs/collection-objective.md:12`). That is far too low: the ledger's cheapest #1s cost 93k to 946k each.
- The grind test's blanket exemption for any untradeable item.

c\* needs a full set of rankings first, so run `dc refresh` and `targets refresh`.

### 4.2 Liquid value

```
liquid value = 0.9 × average sale price × L
L = 1 if surplus ≤ 180 × q, otherwise 180 × q ÷ surplus
q = copies the market takes per day, about 20% of the average daily volume
```

This follows garbo's rule: 0.9 × a historical price no more than 7 days old, or autosell for a listing at the mall minimum (`garbo-lib/src/value.ts:237-246`), with a liquidity factor added. Store the price evidence with each estimate: units sold, number of separate sales, age, and how concentrated the sales were. Five units sold may be one buyer. ChatGPT reports that Pricegun weights sales with a 3-day half-life and damps large trades by square-root volume (unverified).

Never pass a price below 1 to `buy()`, because that means *no limit* ([wiki](https://wiki.kolmafia.us/index.php/Buy)). Reject unknown prices before any purchase call. Anything beyond 180 days of sales has almost no liquid value, so if the Museum can use it, it goes into the case (decision 6). The same values feed garbo's price overrides each morning.

### 4.3 The value of a turn

The value of a turn is the liquid value of the day's **last** farm turns, not an average over all the grinds. garbo measures it on the last 75 to 25 Barf turns (`session.ts:41-160`). It also refuses a `valueOfAdventure` of 3,500 or less, or 10,000 or more (`index.ts:227-240`).

- **Now:** `smm.TurnValue=4500`, the same as `valueOfAdventure`. Every script reads that one value.
- **After 5 garbo days:** set both to a 7-day weighted average of the measured value: raw Meat plus liquid item value, without the Sword's loot, clamped to 3,500–10,000.
- **Free fights** are worth what they drop and what they charge, not one turn each.
- **The farm** is chosen by its own net return per turn.

## 5. Phases of the day

Each phase is a set of tasks. A task records `ready / done / estimate / do / observe`. Done-tests read Mafia's own counters wherever those exist.

These rules hold in every phase:

- each capability has exactly one owner;
- limits are checked before each action, not once at the start of a grind;
- a failed action that consumed resources is still charged;
- a failure blocks only that task and the tasks that depend on it;
- an unknown fight or choice state, or an ambiguous purchase, stops all further actions until it is reconciled;
- nothing is ever taken out of the Display Case;
- adventures from food or drink not yet consumed are never reserved as if they existed.

### Phase 0: Preflight, fence and plan

**What it does:**

- Resolve any open fight or choice.
- Take the run lock (keyed on player, ascension and the `rollover()` timestamp) and run `smmPrefs check`.
- Refuse to start:
  - if `valueOfAdventure` is outside 3,500–10,000;
  - within 10 minutes of rollover;
  - when another machine holds today's journal.
- Snapshot the state and compute R (the MP floor), c\* and the day's turn plan.
- **Fence garbo:**
  - closet drum machines, Special Seasoning and the inflammable leaves the route holds, plus any Museum reserve sitting in Hagnk's or the store;
  - write `data/garbo_item_values.json` from §4.2;
  - set `garbo_copyTarget` when a free monster that can be copied drops a register item.
- Set `autoSatisfyWithMall/NPCs/Coinmasters=false` for Sacha's own phases.

**Done-test:** `_smm.daily.fence` equals today's epoch. The fenced counts are in the journal.

### Phase 1: Breakfast and MP bootstrap

**What it does:**

- Mafia breakfast with `libramSkillsSoftcore=none`.
- Then refill MP, in this order:
  1. maximize MP;
  2. License to Chill;
  3. bat-wing rests (`_batWingsRestUsed < 11`);
  4. nuns visits (`nunsVisits < 3`);
  5. free rests (`timesRested < total_free_rests()`);
  6. the car battery.
- Re-cast any breakfast summon whose own counter shows it failed (`noodleSummons`, `reagentSummons`, `_candySummons`, ...).
- Then `secondBreakfast`'s collections and buffs.

**Done-test:** `breakfastCompleted=true`, every summon counter is set, and `_smm.daily.bootstrap` equals the epoch.

**Invariants:**

- MP stays at or above R, where R = remaining scheduled casts + a combat margin (about 2,000 at breakfast, lower once the casts are done).
- The `burnMP` replacement checks R *before* running the mood.
- `moodExecute` warns instead of aborting.
- Buffs are extended only for the turns actually left.

### Phase 2: Museum and free work (paid turns only for seeds and Lucky!)

**What it does:**

- `iotmroute free`, prioritised by payoff.
- Seed the Sword with the monster worth the most: Museum need first, then liquid loot minus displaced native items.
- Spend Lucky!: on a Museum target first, else the Treasury Embezzler (about 16k), else sell the clovers.
- Aim copies, Peridot and the locket at register targets.
- Deposit owned copies that close a gap, starting with impure gasoline (157 held) and Z-Bone steak (150 held).
- Collect the no-turn dailies: coins, embers, TakerSpace, garden and workshed.
- Once they are unlocked, run Snojo and CyberRealm in small observed batches, stopping before the first fight that would cost a turn.

**Done-test:** the route's receipt (`data/smm-iotm-route-last.txt`) selects no free action, `_cloversPurchased=3`, and no Lucky! is active.

**Invariant:** the only paid turns are the Sword seed and the Lucky! adventures, one turn each. The route already treats a locket or Sword seed as a one-turn action (`scripts/smmIotmRouteCore.ash:562-576`) and gives Heartstone Lucky! `allowed_turns=1` (`:849-855`), so `iotmroute free` alone would skip them. Phase 2 therefore gets an explicit budget of at most 1 + the Lucky! count turns (about 5), taken from `smm.daily.museumTurns` before phase 3 starts, and each use must beat the turn value. Copies without a register target are left for garbo.

### Phase 3: Rate-limited paid work, capped

**What it does:** the grinds that produce unbuyable or gap items, in order of value per turn:

- the Drip;
- FantasyRealm (remove the scepter fallback when no reward qualifies, `fr.ash:29,61`);
- PirateRealm (choose the reward by Museum need instead of always Red Roger's reliquary);
- Spacegate;
- the Daily Dungeon;
- Gingerbread City;
- the ghost costume, until its target is met, and protecting a linked chain once it starts;
- bounty lucre, only when it closes a gap.

Beer lens and the Oasis are only admitted by the value test.

**Owns:**

- paid turns up to `smm.daily.museumTurns` (decision 4);
- short-duration banishes, chosen per source;
- the Drip's organ reservation: 5 fullness or 5 liver **only** when `drippyJuice` won't cover the route, charged at the displaced diet value;
- the Sword as familiar, only if garbo won't run today.

**Done-test:** Mafia's counters (`_spacegateTurnsLeft`, `_frHoursLeft`, `_questPirateRealm`, `dailyDungeonDone`, `_gingerbreadCityTurns`). Where Mafia has none, a script-owned `_smm.daily.grind.<id>`.

**Invariants:**

- `smm.IR.maxPaidTurns` and the planner's `turns.paid` reservation are set before the route runs, so the route can't take these turns.
- At least 30 turns are left for garbo.

### Phase 4: garbo (the Meat engine)

**What it does:** `garbo -N`, where N is the turns phase 5 needs.

- N is always written as an explicit negative number, because `garbo 0` means no limit.
- Never pass `ascend` (it spends every ember and coin, `tasks/dailyItems.ts:286,313`), `workshed=` (it drains TakerSpace, `tasks/post/worksheds.ts:160`) or `quick`.

garbo eats the daytime diet, runs its free fights and copy chain, spends the remaining Sword kills and farms Barf with its own mood and recovery.

**Before it starts:** buy the Dinseylandfill ticket (or charter) through the spend gate, so garbo finds it done.

**Owns:**

- the organs and the 3 mojo filters;
- the remaining paid turns;
- free kills;
- free fights not already used;
- copies without a register target;
- Sword kills.

**Done-test:** `garboResultsDate` is today, `my_adventures() ≤ N` and `_swordOfSWordsKills=100`.

**Invariants:** the fenced counts don't change. Sacha's `betweenBattleScript` and `burnMP` stay off while garbo runs.

**Known gaps, accepted under decision 1:**

- garbo can buy with no daily cap, which phase 5 books afterwards;
- garbo can pay above the average sale price;
- garbo can eat magical sausages for MP.

### Phase 5: Deposits, selling, spending, nightcap, audit

**What it does:**

1. Re-dress and restore the familiar and BoomBox. garbo restores preferences but not gear.
2. Book every `buy N X for P each` line from today's session log that didn't go through the gate, as operating spend, and flag any purchase above the average sale price.
3. Make upward-only `dc` deposits inside `batch_open`/`batch_close`.
4. List surplus in the store at no more than q a day per item, once a day, with `reprice_shop`.
5. Run `smmSpendRun`: positive-return buys, then discount buys (biggest discount first), with milestones only breaking ties.
6. Nightcap: overdrink, then `garbo nodiet turns=X` with the wineglass, as `good_night_adv` already does.
7. Put on rollover gear chosen at the turn value, spend leftover MP on buffs that persist, and unfence.
8. Run the **audit**. Every daily pool that still has capacity and no owner is either run through its legacy routine or reported with its value and the reason it went unused.

**Done-test:** `smm.spend.lastClose` was updated today, Tquilla is overdrunk, and `_smm.daily.audit` equals the epoch.

**Invariants:**

- Spending stays under the cap from decision 2.
- No discretionary purchase is above the average sale price.
- MP at rollover covers tomorrow's breakfast.
- The journal is closed.

## 6. Resource owners

| Resource | Owner | Rule |
|---|---|---|
| Paid turns (about 430: 169 after breakfast plus about 250 from diet and turn generation) | Phase 3 up to `museumTurns`, then phase 4 | A turn goes to phase 3 only if it passes the value test. Everything else goes to Barf |
| Organs, mojo filters | Phase 4 (garbo's diet) | Special Seasoning fenced. The Drip reserves organ space only when it needs to. `diet.js` (called with `yes`) only on days without garbo. Cooler Yeti next-drink boosts are ordered before the diet if the Yeti is owned (unverified) |
| Sword of S Words | Seeded in phase 2 (one paid turn from the Museum turn budget), spent in phase 4 | Charge the displaced familiar and native loot. If garbo doesn't run, the Sword is the familiar for the first 100 fights. The audit checks for 100 kills |
| Copies (about 40) | Phase 2 with a register target, otherwise phase 4 | Never on scarab beatles for stock. Copies are not free fights: each needs a host fight |
| Free kills (7+) | Phase 4 | Only on paid fights. Subtract the loot destroyed by kills that destroy it. No night-time drum-machine fights (`smmUnrestricted.ash:6835`) |
| Free fights (about 45) | Route free workers in phase 2, then garbo | Snojo and CyberRealm after their unlocks, counting only fights that turn out to be free |
| Banishes | Per source | Track uses, active slots, duration, scope, turn cost and drop handling for each source. Short banishes go to short grinds. Rollover banishes go to all-day zones once the short grinds release them. Restraining orders may pass the 100-Meat-per-turn cap. No Batter Up! |
| MP | Phase 1, then floor R | Free sources first, then mall magical mystery juice (about 1 Meat per MP). No libram summons |
| Lucky! | Phase 2, one paid turn each from the Museum turn budget | Museum target, then the Embezzler, then sell the clovers |
| Drum machines, leaves, Special Seasoning | Fenced | Museum stock. No sandworms. Leaves are crafted only within `leafCraftCap` once their rank is known |
| Workshed | Phase 2 (route) | Pick by daily value. An anchor bomb needs 1 rum, 3 anchors, 1 mast and 1 gold, so the 1,826 anchors are limited by gold and worth about 0 at the margin. Never `garbo workshed=` |
| Garden | Phase 2 (route) | After a rose visit, garbo replants the starting garden (`resources/garden.ts:105-115`). Check whether that resets the mushroom plot |
| Shrunken head, Möbius ring, Monodent wave, Peridot | Phase 2 adapters (new) | Ordered by payoff. Zombie state is in `shrunkenHeadZombieMonster/HP/Abilities`. Möbius time cops are a cap, not a promise |
| Surplus stock | Phase 5 | Sell at most q a day. Deposit what lies beyond 180 days of sales |

## 7. Ranked changes

The two councils' estimates differed by about ten times. The gap had three causes:

1. **The Sword.** Claude's first estimate counted Sword kills as wasted, but garbo already spends them.
2. **Stock sales.** Claude counted liquidation as daily income. It is a one-off, and the market's volume is unknown.
3. **Illustrative inputs.** ChatGPT used placeholder assumptions, such as a 300 Meat-a-turn farm improvement, where the logs give 1.4k to 2.0k of raw Meat.

The table below uses log figures where they exist. Rows overlap, so **don't add them up**.

| # | Change | Recurring gain/day | Basis |
|---|---|---|---|
| 1 | Barf instead of the Oasis for turns without a Museum gap (about 120) | **+170k to +230k cash**, plus a liquid item difference not yet measured | **Logs:** 3,723–4,329 against 2,367 raw Meat a turn |
| 2 | Runs that can't stall: MP bootstrap, no aborts, preset prompts, diet `yes`, restartable phases | +0.15M to +0.75M expected | **Logs:** Nov 21 was lost, and Nov 23's first two logins stalled. 1 lost day in 4 to 10, at 1.5M to 3M of liquid value per day |
| 3 | Fence Museum stock from garbo | +50k to +100k, plus Museum progress | **Logs:** 410 leaves, 7 Seasoning, 7 drum machines on Nov 19 |
| 4 | Stop drum-machine sandworms; free kills only on paid fights | +50k to +80k | **Logs:** 0 melange in 32 fights; 11 turns and 37k today |
| 5 | Drip eats only when `drippyJuice` is short | Up to 130k on days it would have eaten for nothing | **Source:** `smmUnrestricted.ash:1392-1399` |
| 6 | Guarantee 100 Sword kills and choose the seed by value | 0 on garbo days; about 1M to 2M liquid on a day garbo would have missed | Nov 19 haul; prices unmeasured |
| 7 | Fix the grind ledger, then apply the value test | Today about 80 turns earned 627–2,541 a turn; the gain depends on c\* | **Logs:** `Tquilla_20261123.txt:53462-53467` |
| 8 | Cap the route's paid turns and reserve phase-3 turns | Protects Museum grinds | `docs/iotm-route.md:43` |
| 9 | Dinseylandfill charter instead of daily tickets | +150k once paid back | **Logs:** 143k and 153k tickets |
| 10 | Copies to register targets; Lucky! to the Museum or the Embezzler | Museum points; 15k to 30k for Lucky! | Lucky! was spent in the Oasis on Nov 23 |
| 11 | Banishes managed per source, plus Peridot | 0 to 75k | ChatGPT estimate |
| 12 | Unlock Snojo, CyberRealm and the Heartstone | 30k to 100k after a one-time effort | Estimate |
| 13 | Adapters for the shrunken head, Möbius ring and Cooler Yeti (if owned) | 0 to 100k each | Estimate (mechanics from the wiki) |
| 14 | Buffs only for the turns left; one turn value everywhere | 10k to 50k | `burnMP` cast 662 turns of Fat Leon's with about 400 turns left |
| 15 | Halve the request load: dress once per block, a thin pre-adventure hook, autoattack, cached store work | About 15 minutes a day; fewer failures near rollover | About 3,000 requests today |

**One-off gains, not recurring:**

- the nine cheap #1s (about 2.5M; verify prices and ranks first);
- the gasoline and Z-Bone deposits;
- depositing the glut;
- the surplus selling schedule. The ledger values the stock at about 700M, but that is the shop's own asking prices, and the volume that will actually sell is unmeasured.

**Baseline lines** (breakfast, clovers, noodles, batteries, tea, the diet's roughly 230 adventures) are capacity to protect, not new gains.

## 8. Architecture

**Language.** ASH orchestrates. Everything it must call is ASH. `diet.js`, garbo, `fr`, `pr`, `nep` and `gbc` run as separate phases from the command line. Each is checked by what it changes in the game (counters, fullness, turns), never by parsing its output. A JS bridge for garbo, using its pure value functions and individually audited actions, is a later option under decision 1.

**Files.** Each file stays under about 600 lines, and no new code goes into `smmUnrestricted.ash`.

| File | Contents |
|---|---|
| `KoLUtils/scripts/smmBudget.ash` | Low-level cash admission, reservations and spend receipts. It is separate from `smmSpend.ash` because `smmSpend` imports `smmUtils`, and `fullAcquire` must call the gate without creating an import cycle |
| `scripts/smmDaily.ash` | Entry point: `plan`, `refresh-plan`, `run [phase\|task]`, `resume`, `status`, `journal`, `audit`, `reset` |
| `scripts/smmDailyCore.ash` | Task registry, engine loop, settings registry, journal, run lock, settings save and restore. Moved out of the IoTM route's harness (`smmIotmRoute.ash:421-511`) so both use the same code |
| `scripts/smmDailyGate.ash` | `smmDBuy`, `smmDCast`, `smmDUse`, `smmDAdventure`, `smmDCli`: every action with an effect, plus the dry run and the reserve checks |
| `scripts/smmDailyPools.ash` | Planner pools for MP, banishes (per source), paid turns, organs and the budget |
| `scripts/smmDailyTasks<Phase>.ash` | Fence, Bootstrap, Museum, Grinds, Garbo, Close, Audit |

**Tasks.** A task record holds the names of its `ready`, `done`, `estimate`, `do`, `observe` and `legacy` functions, plus `spends_turns` and `max_attempts` (default 2). Task files register themselves when imported, as Tour Guide modules do, and the engine dispatches with `call`. Data loaded from a file never becomes a CLI command.

For each phase, the engine collects the tasks that are ready and not done, and solves them with `smmRPSolve` (at most 64 candidates per block). It reserves pools for later phases. The engine trusts the done-test, not a task's report of success.

**State.**

- `smm.daily.<setting>`: each setting declared once, with type, default and a one-line description.
- `smm.daily.task.<id>` = `off | dry | legacy | on`.
- `_smm.daily.*`: only for things Mafia doesn't track.
- Never write a name that looks like Mafia's own (for example `_fantasyRealmDone`).
- Bulk state goes in `data/` files, not prefs. The prefs already hold 1,695 `smm.IR.museumHold.*` keys.
- Move the planner's epoch (`smmResourcePlanner.ash:106-108`, today's date plus ascensions) and the spend ledger to the new day key together. Never start a new-format ledger at zero spent partway through a day.

**Journal.** `data/smm-daily-<playerid>.txt` is append-only. Each action goes through **snapshot → plan → reserve → write intent → execute → observe → write receipt → replan**. The intent line is written and read back before the action runs.

- **On restart**, an intent with no receipt is reconciled against the game: current fight or choice, counters and inventory. Only then is it retried or marked done. Two attempts mark it FAIL, and the day moves on.
- **Resends.** A server request can succeed even when its response is lost, so the journal prevents blind repeats; it cannot promise "exactly once".
- **File checks.** `file_to_map` returns true for a missing file or a partly parsed one ([wiki](https://wiki.kolmafia.us/index.php/File_to_map)). Each generation therefore carries a schema version, player, epoch, sequence number and checksum, and the previous valid generation is kept. An empty or corrupt journal is never read as a new day with nothing spent.
- **Counting gains.** Gains come from the session's own results, as libram's `Session` does it, never from holdings diffs. Item changes are signed, and transfers and price changes are kept out of production profit.

**Gates.**

- **Spend gate.** `smmDBuy(item, qty, kind, value, why)` reserves the worst case before buying, caps the price at the average sale price and at the task's value, and records the actual Meat spent afterwards. Unknown average prices block the purchase. A one-copy probe purchase is a real purchase and goes through the gate.
- **No hidden purchases.** With auto-buying switched off, `retrieve_item`, `fullAcquire`, Asdon fuel and recovery can't buy anything silently. The maximizer is used only to simulate; equipping is a separate step, because a maximizer price of 0 or less falls back to the global limits.
- **Reserve gate.** Refuses a cast below R, and any use of a reserved banish or turn by a task that doesn't own it.

**Daily report and KPIs.**

- ΔS, and new top-ten or #1 places.
- Realized cash net, operating spend, allowance and purchases.
- Liquid value, kept apart from cash.
- Paid turns by purpose, and the marginal value of a turn.
- Every daily pool: used, reserved or expired, with a reason.
- Minimum MP against R; banish overwrites; Sword kills.
- Prompts, failures, duplicate actions; time per phase from `logprint` timestamps.

**Targets:**

- 100% of days reach the nightcap with no manual step;
- zero unexplained budget or reserve violations;
- at least 98% of daily pools used.

## 9. Testing and rollout

**Offline tests (in `tests/`).** First recover or recreate the missing `fixes/` harnesses: KoLmafia r29462 run in isolation with test preferences and a fake HTTP client that rejects real requests.

Then cover:

- **Compile and registry:** every entry point compiles; every `call` name resolves; every property used in a done-test exists in Mafia.
- **The Nov 21 incident:** reproduced, and no mood, burn or restore can drop MP below R.
- **Purchases:**
  - every nested buyer goes through the gate;
  - a price of 0 or below is refused;
  - a missing average price blocks the buy;
  - partial fills are recorded correctly;
  - the cap holds across reruns.
- **Accounting:** consumed inputs, transfers, sales, deposits, and a copy kept versus sold.
- **Capacity:** one fight can't fund two familiar strategies; banish overwrite and duration behave as modelled; the route keeps phase 3's reservation.
- **Museum rules:** ties, own entry excluded, the buffer, unknown ranks.
- **Diet:** Drip organs, Yeti ordering, the mojo filter limit.
- **Recovery:** a timeout after the server succeeded, a corrupt journal, rollover, a Windows/Mac handoff.
- **No prompts:** a grep test fails if `user_confirm` appears under the engine.

Decisions read from a property-map seam (`smmDProp`), so tests can supply snapshots.

**Day 0: settings only**, no new code:

- `smm.TurnValue=4500`;
- the six `smm.dailyGrind.*` presets;
- `libramSkillsSoftcore=none`;
- `smm.IR.maxPaidTurns=100`;
- `smm.dailyGrind.beerLens=false`;
- deposit gasoline and Z-Bone;
- closet drum machines, Seasoning and leaves before each garbo run;
- `garbo simdiet` as a smoke test.

**Stages after that:**

| Stage | What runs | What has to hold before moving on |
|---|---|---|
| A. Shadow plan | `smmdaily plan` beside the usual `dailyGrind` and garbo | Plan matches the session log |
| B. Safeguards | Journal, spend gate (books legacy and garbo purchases), MP bootstrap, prompt presets, day key, run lock | A full dry run (`smm.daily.dryRun=true`) is clean |
| C. Deterministic claims | Breakfast and summons, fence, deposits | One task per day moved from `legacy` to `on` |
| D. Free fights | Snojo, then CyberRealm, in small batches | Zero paid turns spent |
| E. Phase 3 grinds | One grind at a time, with turn, organ and banish reservations | Started well before rollover |
| F. Garbo phase and close | `garbo -N` inside the engine, booking, `smmSpendRun`, nightcap, audit | Journal reconciles |
| G. Garbo bridge (optional) | Audited JS calls instead of a plain `garbo -N` | Only if decision 1 or later evidence calls for it |

**Gates and safety nets.**

- **Promotion.** A phase is promoted only when the journal matches the session log within 1% on turns and Meat, every Meat outflow was booked, and the audit is empty.
- **Cutover.** After 7 clean days with everything `on`, `dailyGrind()` becomes a one-line call to `smmdaily run`. The old body stays as `dailyGrindLegacy()` for 30 days.
- **Rollback.** Set a task's flag back to `legacy`. Rollback never clears counters or spending, and never reruns the whole old `dailyGrind()` after a partial new run.
- **Never run `dailyGrind()` and `smmdaily` side by side.** The done-tests skip work that has already been done.

**Two machines.** Only Windows runs the day (`smm.daily.runner=true` in its local prefs). Elsewhere `smmdaily` runs dry. Changing machines mid-day means handing over the journal and refreshing the game state first. garbo is pinned to its release branch and updated once a week, after a `garbo simdiet` check, and the journal records its version.

## 10. Check in game

- [ ] **LED block and synthetic stuffing:** sales volume and Museum ranks. Should the Sword seed rotate?
- [ ] **Dinseylandfill charter:** its price, and `stenchAirportAlways`.
- [ ] **Monodent:** how many lightning banishes can be active at once?
- [ ] **Ownership:** Cooler Yeti, model train set, Eternity Codpiece, Allied Radio Backpack; Möbius ring and Peridot are probably owned.
- [ ] **garbo's garden step:** does it reset the mushroom plot? Does garbo need the ice-house bunny?
- [ ] **Unlocks:** Snojo (visit `place.php?whichplace=snojo`), CyberRealm requirements, Heartstone letters (LUCK first).
- [ ] **Leaf jump:** find its real counter (`prefref leaf`); `_leavesJumped` never appears.
- [ ] **Genie:** does "more wishes" give a tradeable pocket wish?
- [ ] **Pricegun:** confirm how it weights sales before trusting the minimum-sales screen.
- [ ] **Museum data:** run `dc refresh` and `targets refresh`, then compute c\* and check the nine #1 prices.
- [ ] **Turn value:** after 5 garbo days, set `smm.TurnValue` and `valueOfAdventure` from the measured marginal value.
- [ ] **Clan dungeons** (Hobopolis, Dreadsylvania) hold many hard Display Case items. They are out of scope for now.

## Sources

- **Repo:**
  - docs: `docs/aftercore-goals.md`, `docs/collection-objective.md:12`, `docs/daily-spending.md`, `docs/iotm-route.md:43`, `docs/resource-planner.md`, `docs/target-register.md`;
  - `scripts/smmUnrestricted.ash:808-852, 1392-1399, 2007-2015, 4892-4904, 6612-6860`;
  - `scripts/smmTargets.ash:257-259`, `scripts/smmMuseumPolicy.ash:33`, `scripts/fr.ash:29,61`;
  - `data/smm-prefs.txt:11`.
- **KoLUtils:** `smmUtils.ash:150, 2450-2516`; `smmResourcePlanner.ash:106-108`; `smmIotmRoute.ash:421-511`.
- **garbo:**
  - `packages/garbo/src/index.ts:153, 227-240, 270-272, 348-371, 531-534`;
  - `acquire.ts:60`, `restore.ts:28-32,73`, `session.ts`, `config.ts`;
  - `tasks/freeGiantSandworm.ts:395`, `tasks/dailyItems.ts:286,313,614-633`, `tasks/post/worksheds.ts:160`;
  - `resources/garden.ts:105-115`, `diet.ts:1485`;
  - `packages/garbo-lib/src/value.ts:237-246`.
- **Tour Guide:** `Items of the Month/2025/Seadent.ash`.
- **Logs:** `Tquilla_20261121.txt`, `Tquilla_20261123.txt`, the Nov 19 session log, `tquilla_prefs.txt`.
- **Wikis:**
  - [Mystical bookshelf](https://wiki.kingdomofloathing.com/Mystical_bookshelf)
  - [Sea \*dent: Throw a Lightning Bolt](https://wiki.kingdomofloathing.com/Sea_*dent:_Throw_a_Lightning_Bolt)
  - [Knob Goblin Embezzler](https://wiki.kingdomofloathing.com/Knob_Goblin_Embezzler)
  - [Banish](https://wiki.kingdomofloathing.com/Banish)
  - [buy](https://wiki.kolmafia.us/index.php/Buy)
  - [file_to_map](https://wiki.kolmafia.us/index.php/File_to_map)
