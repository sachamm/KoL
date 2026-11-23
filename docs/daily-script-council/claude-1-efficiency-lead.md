# Memo 1 — Efficiency lead: decision framework for the new daily script

Council round 1 · 2026-11-23 · Efficiency engineer (lead)

This memo sets the rules every other part of the plan should follow. It has five parts: one objective function, a resource taxonomy and allocation order, the phases of a day, what to measure, and ten ranked changes. Numbers marked **(guess)** are my estimates. Everything else comes from the repo, the ledger or the session logs, and I cite each source.

Three findings from the logs change the starting assumptions in the brief, so they come first:

1. **The Sword of S Words is the largest single lever, and today it is almost unused.** On Nov 19, garbo used all 100 Sword kills. The two items those kills brought back were worth 5.3M at mall price: 72 LED blocks at 2,916,000 and 72 synthetic stuffing at about 2,397,600 (`hearth/61cc0b24…:66134-66140`). garbo reported a marginal MPA of 19,157, of which 4,943 was raw Meat (`:66145`). By the end of today's grinds, 220 paid turns, the route had used **1 of 100** kills (`Tquilla_20261123.txt:7498-7523`).
2. **The grind ledger's measurements are wrong, so the turn-value test can never drop a grind.** Today's ledger gives the Oasis 325,044 Meat per turn, ghost costume 3.3M per turn, and Gingerbread 45.9M in **0 turns**. Every grind is flagged "Museum item gained recently", which exempts it from the test (`Tquilla_20261123.txt:53460-53469`). The causes are in the code. Gains are diffs of inventory, closet and Display Case holdings, so storage pulls and stock moves count as income. Items are valued at `historical_price`. Any untradeable displayable drop, such as an inflammable leaf, sets the exemption (`smmUnrestricted.ash:808-833`).
3. **The 11-21 MP stall was not "burnMP spent 17,797 MP".** A negative argument to `burnMP` means "keep this much" (`smmUtils.ash:2450-2457`). The real story: the day started at 2,089 of 20,340 MP (`Tquilla_20261121.txt:542`). Mafia's breakfast cast **22 libram summons** (`:1424`). Libram cost is `1+n(n-1)/2` for the n-th cast ([KoL wiki](https://wiki.kingdomofloathing.com/Mystical_bookshelf)), so 22 casts cost about **1,793 MP for 22 dice**, and MP was 10 after breakfast (`:1501`). Mafia's auto-recovery is switched off (`mpAutoRecovery=-0.05`, `hpAutoRecovery=-0.05`, `tquilla_prefs.txt:3280, 2894`). Today also started at **82 MP** (`Tquilla_20261123.txt:178`). MP cannot hold up the day: restoring it costs about 1 Meat per MP. The stall comes from the order of steps and missing guards.

---

## 1. One objective function

### 1.1 The unit: Museum points, priced in Meat at the margin

Sacha's goal is lexicographic: #1 everywhere, with the top ten acceptable (`docs/aftercore-goals.md:15`). I propose one score:

> **Museum score S = N₁ + α·N₁₀**, where N₁ is the number of items where Tquilla is #1, and N₁₀ is the number in the top ten but not #1. Starting value **α = 0.5 (guess; Sacha to set)**. A lost #1 counts against S, so defending a lead is valued the same way as gaining one.

Meat and items are converted into S through one shadow price:

> **c\* = the Meat cost of the most expensive Museum milestone the day's spending budget still buys** (the cutoff in a queue of buyable milestones sorted by Meat per point).

- A **buyable** gain is worth its acquisition cost: the lower of the average sale price and the current listing (`aftercore-goals.md:32-33`).
- An **unbuyable** copy that closes or narrows a gap is worth `Δpoints × c*`, spread over the copies still needed. Example: if a FantasyRealm boss item needs 3 more copies for top ten, each copy is worth `α·c*/3`.
- **Meat itself** turns into S only through the spending cap. Spending is limited to half of the day's net (`aftercore-goals.md:31`), so a marginal Meat netted today buys **0.5/c\*** points. The other half is retained, and I give it no Museum value until Sacha changes the rule. 141.5M Meat is already sitting idle, which shows the cap, not Meat, is what limits purchases today (open question for Sacha).

This replaces two existing figures. First, `smm.IR.museumRankValue`, which defaults to one turn, 5,000 (`docs/collection-objective.md:12`). That is two orders of magnitude too low: the ledger's cheapest #1s cost 93k to 946k each (`resource-ledger.md:336-345`), so c\* is somewhere from about 300k to a few million. Second, the per-grind "untradeable item → never skip" exemption, which is unbounded.

### 1.2 Realizable value, not the asking price

An item's value is what it can actually turn into, and when:

```
v(item) = max( museum_need_value, use_value, liquid_value )
liquid_value = 0.9 · avgSalePrice(14d) · L
L = 1                                if surplus ≤ H · q
  = (H · q) / surplus                otherwise   (H = 30-day horizon, q = sellable copies/day ≈ 20% of avg daily volume)
```

This is garbo's rule (0.9 × historical price, autosell at the mall minimum; `garbo-lib/src/value.ts:237-246`) with a liquidity factor added. garbo can omit the factor; Tquilla cannot, because Tquilla holds **42,343 mojo filters, 77,164 hammers, 43,611 happiness and 85,421 fish scales** (`resource-ledger.md:314-320`). At that depth, one more hammer is worth close to nothing for months. Pricegun volume is already fetched by `smmSpend` (`smmUnrestricted.ash:2007-2015`), so q costs nothing to get.

### 1.3 The value of a turn (MPA) comes from the marginal sink

**Definition:** MPA is the liquid value of the **last** turn of the day, the one spent in the open-ended sink. It is not the average over the grinds. garbo measures it on a window near the end of the barf turns, roughly 75 to 25 turns left for Meat (`garbo/src/session.ts:41-73`). It also refuses a `valueOfAdventure` that is ≤3,500 or ≥10,000 as implausible (`garbo/src/index.ts:227-240`).

What the logs measure (raw Meat is exact; items are valued at mall price before the liquidity factor):

| Sink | Turns | Raw Meat/turn | Items/turn | Source |
|---|---|---|---|---|
| Barf, garbo, Nov 19 | 211 | 4,329 | 30,388 (25,100 of it Sword) → about 5,300 excluding Sword | `hearth/61cc0b24…:66140` |
| Oasis, Nov 23 | 117 | 2,367 | about 1,000 to 6,000 depending on L: 65 mojo filters, 66 hammers, 70 happiness, 10 Special Seasoning, about 500 low-value drops | `Tquilla_20261123.txt` Oasis block to `:39205` |

**Proposal:** keep `smm.TurnValue = 5000` until 5 days of clean marginal-sink data exist. After that, set it daily to an EWMA (half-life 7 days) of the marginal-sink MPA, excluding the Sword and other capped carriers, which are valued as their own resources. Clamp it to [3,500, 10,000] as garbo does. Write the same number to Mafia's `valueOfAdventure`, which is **500** today (`resource-ledger.md:225`). That value makes the maximizer and Mafia's consumption logic undervalue turns tenfold, and garbo refuses to run with it. My prior for the sink MPA after the liquidity factor: **5,000 to 9,000 (guess)**, likely higher in Barf than in the Oasis.

### 1.4 The value of an action

The planner's formula stays (`docs/resource-planner.md:51-53`). Two changes: every item term uses `v()` from §1.2, and Museum gains enter as `Δpoints × c*` instead of `museumRankValue`. Nonlinear items (escalating BCZ, rising Interesting Coin prices) stay as bundles, as the planner doc already requires.

---

## 2. Resource taxonomy and allocation order

| Class | Examples | Shadow price | Rule |
|---|---|---|---|
| **A. Expiring, use-or-lose** | Free fights (about 45), free kills (7+), copies/replacers (40+), Sword kills (100), banishes (13), clovers, wishes, daily zones (Spacegate energy, FR/PR passes, Drip), breakfast summons | Their best use today; **0 if unused** | Spend all of them, or reserve each for a named later phase. Never let one expire silently |
| **B. Regenerating, carries over** | MP, HP, buff turns, Cinch, scrapbook charges | MP ≈ 1 Meat/MP (cheapest restore); buffs = value over remaining eligible turns | Keep a **floor**, never a stockpile. Buffs carry over rollover, so MP spent on persistent songs at night is not wasted |
| **C. Paid turns** | Rollover, diet and turn-gen, about 400 a day | MPA | Allocate by value per turn with MPA as the hurdle. The **open-ended sink always takes the remainder** |
| **D. Organ space** | 15 stomach, 20 liver, 15 spleen, plus mojo filter cleanings | (adventures × MPA) − cost | Fill daily. Every diet line costs 130 to 1,650 per adventure, against MPA ≥ 5,000 (`resource-ledger.md:237-241`) |
| **E. Stock and surplus** | 700M sellable stock, 1,826 anchors, 141.5M Meat | `v()` with the liquidity factor; anchors ≈ 0 at the margin | Liquidate at the volume-bounded rate. Proceeds go into the day's net (`docs/daily-spending.md:9`) |
| **F. Slots (one-of choices)** | Familiar per fight, workshed, garden, off-hand | The best alternative's value | Compare marginal values per fight or per day, never "owned, therefore use" |

**Allocation order:** A first, then D (it fixes the turn count, so it comes early), then the expiring part of C, then the open-ended C, then E. B is a constraint at every step. F is chosen per phase.

### Conflicts, resolved

- **The IoTM route versus the daily-limited grinds.** The route's zone farming is the open-ended sink, and it runs first with no cap (`docs/iotm-route.md:43`, `smmUnrestricted.ash:6630`). **Resolution:** split the route into its non-farming actions (phase 3) and its zone farming (phase 5). Before phase 5, set `smm.IR.maxPaidTurns = remaining − Σ(turns reserved for later expiring work)`. Expiring always runs before open-ended.
- **Banishes, 13 available against 17 wanted.** Value each banish as `Δ(value per turn) × turns remaining in that zone`. Beer lens costs 4 banishes and about 9 turns for 3 lenses worth about 15k (`Tquilla_20261123.txt:41433`; lens price at `resource-ledger.md:279`), which is about −30k at MPA 5,000. **Turn beer lens off** unless the Museum gap value × c\* covers it. Turn the ghost-costume grind off once the case meets its target. That frees 12 banishes for the sink. Bounty runs only when a lucre item closes a gap.
- **MP reserve.** Use a floor, `R = max(2,000, MP the rest of the day needs + 500)`. Checked **before** every MP-consuming step, it guarantees that a library call can never run MP to zero. Free sources come first: 11 bat-wing rests, 3 nuns visits, the eternal car battery, and the about 112 carbonated water lilies a day from the Oasis. After those, buy MP. No libram summons until R holds. Nightcap must leave tomorrow's breakfast MP need in reserve.
- **About 400 paid turns.** Phase 4 grinds run only if `value per turn ≥ MPA`, counting Museum value through c\*. Today's honest-looking per-turn returns: Spacegate 627, FantasyRealm 785, PirateRealm 752, Daily Dungeon 2,541 (`Tquilla_20261123.txt:53464-53467`). That is 79 turns at under 1/5 of MPA, kept alive only by the over-broad Museum exemption. Each must now earn its turns through a named gap item.
- **20 unused free fights (CyberRealm and Snojo).** They are class A, so add them. Their value is loot plus a carrier for Sword kills and copies: small (guess 20 to 60k a day), but it costs nothing.
- **1,826 TakerSpace anchors.** Their marginal value is about 0. Never let the planner value anchors at a price. The workshed is a class F slot: compare the TakerSpace delivery value (the scarce supplies only) with the model train set's daily value, and pick the higher.
- **700M stock liquidation.** Sell each surplus item at no more than q per day (§1.2), prioritised by days of supply × price. Keep #1 plus the buffer in reserve (`collection-objective.md`, "Owned copies"). Proceeds raise the day's net, and through it the spending budget.
- **Mojo filters.** Using one cleans 1 spleen, which is 1.88 adventures, or about 9,400 at MPA 5,000, against a 4,969 asking price and a much lower liquid value given 42k in stock. **Use 3 a day, always.** Lock 1,000 more in the case: the lead is only 11 (`resource-ledger.md:314`). Sell the rest only at the q rate.
- **Sword kills, the familiar slot.** A Sword kill is worth about 30k to 75k (guess; garbo's Nov 19 data gives about 53k per kill at mall price, and the route valued the fabricator guài at 80,020, `Tquilla_20261123.txt:7505`). The farming familiar adds perhaps 0.5k to 2k per turn. So the Sword is the familiar for **the first 100 fights of the day**, free fights first because they carry no turn cost.

---

## 3. Scheduling: the phases of a day and their invariants

| # | Phase | Contents | Invariants guaranteed at exit |
|---|---|---|---|
| 0 | **Preflight** | Load state; check date and epoch; check prefs (`valueOfAdventure`, recovery, CCS, no pending prompts); refresh prices and volumes up to a cap; compute MPA, c\*, the floor R; build the day plan and reservations | Plan written to the day ledger. Every prompt preset (the six `dailyGrindConfirm` prompts, `docs/daily-spending.md:68-79`). Restartable: each phase is idempotent and records a `_smm.day.phase` checkpoint |
| 1 | **Breakfast** | Mafia breakfast with **libram off**, then `secondBreakfast` collections (zero-MP actions first), then free MP sources | MP ≥ R. Every daily collection flag set. Nothing bought |
| 2 | **Diet and turn-gen** | Fill organs (Ode, sweat-out, mojo ×3, spleen); class chocolate, tofu, yam battery; thumb ring | Organs full except what is deliberately held for the nightcap. Turn budget T known |
| 3 | **Free and expiring, no turn cost** | Free fights (including CyberRealm and Snojo) with the Sword as familiar; route non-farming actions; copies aimed at the best target; clovers and wishes | Each class A counter is spent or holds a named reservation. Sword kills used = min(100, fights so far) |
| 4 | **Expiring paid grinds** | Daily zones in descending order of value per turn, each with a turn cap, only above the hurdle | `turns_left ≥ reserved_for_sink_minimum + nightcap`. Banishes spent per the banish plan |
| 5 | **Open-ended sink** | All remaining turns in the zone with the highest liquid MPA; free kills on **paid** fights; remaining Sword kills; buffs bought only while cost per turn < marginal gain | MP ≥ R before every turn. No stall: on failure, recover or skip, never abort the day. Stops at the nightcap reserve |
| 6 | **Spending** | Positive-return buys, then the Museum queue (cost per point), then discounts (`docs/daily-spending.md` rules); deposits | Σ spend ≤ 0.5 × net, **including every buy made earlier in the day**: `fullAcquire`, buff buyers and drum machines all post to the same ledger. No price above the average sale price |
| 7 | **Nightcap and rollover** | Overdrink, overdrunk free turns, MP surplus into persistent buffs, rollover gear by MPA, unused-resource audit, day report | Day ledger closed. MP ≥ tomorrow's breakfast need. Audit lists every expired class A unit with its estimated lost value |

Two moves from today's code. `burnInstaKills` runs at night and starts each fight with a bought drum machine (`smmUnrestricted.ash:3844-3871`, called at `:6835`). Free kills belong in phase 5, where each one saves a paid turn worth MPA. `burnChampagneBottle(drumMachine)` spent **11 paid turns and 11 drum machines at 3,400** today for about 35k Meat, 33 spices and one Special Seasoning, with no melange (`Tquilla_20261123.txt:10404`, drum fights at `[196]`→`[186]`). That is about −50k a day. Gate it on expected value.

---

## 4. Measurement

### 4.1 What each action logs

One TSV row per action in `data/smm-day-<date>.tsv`, with these columns:

`time, phase, action_id, location, monster, turns_spent, free(bool), pools_consumed{pool:units}, MP_before/after, meat_delta, items_gained{item:qty}` (from **session results**, as libram's `Session` does for garbo, not holdings diffs), `items_consumed{item:qty}` at `v()`, `case_delta{item:qty}`, `price_source/age/volume/L` per item, `expected_value, achieved(bool)`.

Inventory, closet, storage and case snapshots taken at phase boundaries serve only as a reconciliation check, never as income.

### 4.2 Daily figures

- **Liquid net (Meat-equivalent):** Δ Meat (on hand + closet + storage) + Σ `v(gained)` − Σ `v(consumed)` − purchases, **excluding** stock liquidation, which is reported on its own line (conversion, not earnings).
- **Realized MPA:** liquid value / paid turns, by phase. **Marginal MPA:** the same figure over the last 50 sink turns.
- **Museum:** S today − S yesterday (from the ranking store after `dc refresh` on the changed items), Meat spent per point, copies deposited toward each unbuyable gap, and days-to-top-10 per register target. The register already lacks attempt and outcome logging (`docs/target-register.md:331`); this fills it in.

### 4.3 Retuning from the logs

- **Turn value:** daily EWMA of marginal MPA, clamped, written to both preferences (§1.3).
- **Per-grind test:** keep the 14-day weighted history (`smmUnrestricted.ash:836-852`), with three changes: (a) session-based item counting at `v()`; (b) **shrinkage** toward MPA with a prior of 30 turns, so a 4-turn Daily Dungeon sample cannot swing the result; (c) the Museum exemption applies only when the gained item has a gap and `expected Δpoints × c* ≥ turns × MPA`. Rare drops such as Drip uniques and FR rewards are valued at **expected** value (drop rate × v), not realized value.
- **Weekly:** recompute c\*, α (Sacha), the liquidity horizon H, and the banish and familiar allocations from the logged per-fight values.
- **A/B the sink:** alternate Barf and Oasis for the sink over 6 days (3 each) with identical buffs, and compare liquid marginal MPA. This settles the largest open number in §1.3.

### 4.4 KPIs: "the script is maximizing our goals"

1. **ΔS per day** (and N₁, N₁₀ trends). This is the ultimate measure.
2. **Liquid net per day** and **marginal MPA**, both rising or stable.
3. **Utilization:** at least 98% of class A units used, Sword kills 100/100, organs 100%, unused-resource audit value under 50k.
4. **Allocation quality:** every paid-turn bucket at or above MPA, or justified by c\*. Hurdle violations listed.
5. **Spending compliance:** 0 buys above the average sale price, Σ spend ≤ 0.5 × net, Meat per point falling over time.
6. **Reliability:** the day reaches phase 7 without manual intervention (target 100%), 0 MP-floor breaches, restarts resume from the checkpoint.

---

## 5. Top 10 changes by expected Meat-equivalent per day

| # | Change | Expected gain/day | Basis |
|---|---|---|---|
| 1 | **Use all 100 Sword of S Words kills daily** on the best target, with the Sword as familiar for the first 100 fights | **+2M to +5M** (guess; conservative ~2M after liquidity) | Nov 19 garbo: 100 kills → 5.3M of LED block and stuffing (`hearth…:66134-66140`); the 72 LED blocks also went to the case (`:68184`). Today 1/100 used (`Tquilla_20261123.txt:7523`). Check sale volume before valuing at 40k |
| 2 | **Volume-bounded liquidation of surplus stock**, with proceeds feeding the day's net | +1M to +3M Meat (guess, bounded by mall volume) → +0.5M to +1.5M a day more Museum spending | 700M of surplus beyond the case (`resource-ledger.md:312-326`); sales count as net (`daily-spending.md:9`) |
| 3 | **No-stall runtime:** MP floor, libram off at breakfast, recovery guards, phase checkpoints and restart | +0.6M to +1M expected (guess: a full day of about 3M to 5M lost roughly 1 day in 5) | 11-21 ended at second breakfast with the day's resources unspent (`resource-ledger.md:366`); MP evidence in finding 3 above |
| 4 | **Choose the open-ended sink by liquid marginal MPA** (A/B Barf against the Oasis); stop growing stock that is already deep | +0.3M to +0.8M (guess) | Barf 4,329 raw per turn against the Oasis 2,367 raw per turn plus already-deep surplus items (§1.3 table) |
| 5 | **Fix the grind ledger, then enforce the hurdle**; drop or cap beer lens, Spacegate, PirateRealm and Daily Dungeon unless a gap justifies them | +0.2M to +0.4M | About 88 turns today at 627 to 2,541 per turn (`Tquilla_20261123.txt:53462-53467`) against an MPA of about 5,000 |
| 6 | **Price Museum progress at c\*** (replacing `museumRankValue = 5,000`) and run a cost-per-point purchase queue; buy the nine cheap #1s now | +9 #1s for 2.5M once; ongoing ΔS of about +1 a day (guess) | `resource-ledger.md:332-346`; `collection-objective.md:12` |
| 7 | **Run expiring grinds before the route's farming**, with paid-turn reservations | Protects the Drip and FR/PR gap items; +0.1M to +0.3M equivalent (guess) | `iotm-route.md:43`; `smmUnrestricted.ash:6630` |
| 8 | **Free kills on paid daytime fights; gate the champagne-bottle sandworms on expected value** | +80k | 7 kills × 5k a turn saved, plus about −50k a day avoided on drum-machine sandworms (§3) |
| 9 | **Calibrate `valueOfAdventure` and `smm.TurnValue` daily** from measured MPA | +20k to +50k (guess: rollover gear, Mafia/garbo consumption choices) | `resource-ledger.md:225`; garbo's bounds at `index.ts:227-240` |
| 10 | **Automate CyberRealm and Snojo (20 free fights)**, plus the unused-resource audit | +20k to +60k (guess), and they carry Sword kills | `resource-ledger.md:158-159`; prefs show `_cyberFreeFights=0`, `_snojoFreeFights=0` |

Total, rough and overlapping: **+4M to +10M Meat-equivalent a day**, about 70% of it from items 1 and 2. Both depend on mall liquidity, which is the first thing to measure.

### How I will resolve disagreements between members

Every proposal states (a) which resource class it consumes, (b) its value per unit under §1 (with `v()`, MPA and c\*), and (c) the phase it belongs in. When two proposals compete for the same unit, the higher marginal value wins. A tie goes to the one that is cheaper to build and easier to restart. Anything that cannot state (b) runs as a measured experiment with a turn cap, not as a default.

## Sources

- Repo: `docs/aftercore-goals.md`, `docs/collection-objective.md:12`, `docs/daily-spending.md:9,44,68-79`, `docs/iotm-route.md:43`, `docs/resource-planner.md:51-53`, `docs/target-register.md:331`; `scripts/smmUnrestricted.ash:779-852, 2007-2015, 3844-3871, 4892-4904, 6612-6810, 6814-6860`.
- `council/ext/KoLUtils/scripts/smmUtils.ash:150, 169, 2450-2516`; `council/resource-ledger.md`.
- garbo: `packages/garbo/src/session.ts:41-160`, `packages/garbo/src/index.ts:227-240`, `packages/garbo-lib/src/value.ts:237-246`.
- Logs: `Tquilla_20261121.txt:542,1424,1501,3449`; `Tquilla_20261123.txt:178,7498-7523,10404,39205,53460-53469`; `Nov 19 session log:66134-66145,68184`; prefs `tquilla_prefs.txt:2894,3280,5401-5432`.
- [KoL wiki: Mystical Bookshelf (libram cost)](https://wiki.kingdomofloathing.com/Mystical_bookshelf).
