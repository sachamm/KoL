# smmdaily scorecard

How close `smmdaily` gets to the [aftercore goals](aftercore-goals.md): spend the free, cheap, daily and expiring resources to gain items and Meat, and turn them into Museum places. The yardstick is the "Tquilla resource ledger" Claude Doc (the net-positive resources and their best uses) and the spending rules in the goals.

Live outcomes and code assessments are scored separately. Offline tests establish specific behavior, not live profitability or an unattended day. Add an assessment when the code changes; keep earlier scores as history.

## The rubric

| # | Criterion | Points | What full marks means |
|---|---|---|---|
| 1 | The whole day runs unattended | 2 | One `smmdaily run` covers breakfast, the diet, the grinds, garbo, the nightcap and `good_night`, in a safe order, with no questions asked. |
| 2 | Daily and expiring resources are spent | 2 | Every ledger resource with a net-positive use has an owner that spends it before rollover, and the report shows what really went unused. |
| 3 | Scarce resources are kept and aimed | 1.5 | Free rests, Cinch, spikes and Avalanches are not spent on anything else and each forced noncombat goes to the best choice of the day. |
| 4 | Paid turns go where they earn most | 1.5 | Each paid-turn grind is measured honestly and dropped when it earns under the turn value, unless it brings an unbuyable Museum item. |
| 5 | The spending rules hold | 1 | Half of the day's net at most, never above the average sale price, positive return first, then sales. |
| 6 | Museum progress | 1 | Unbuyable items are farmed, and the budget turns into Display Case places, cheapest first. |
| 7 | Safety and reporting | 1 | Resumes after a stop, never loses track of fenced items or spending, and says plainly when the day is not finished. |

## Current assessment: 2026-11-26

**Demonstrated live performance: 6.0/10. Corrected code, provisionally: 8.15/10.** The earlier 9.05 was a code-only forecast. It is superseded by the operational evidence and conservative assessment below, rather than treated as a demonstrated result.

| Criterion | Max | November 25–26 logs | Corrected code, offline |
|---|---:|---:|---:|
| Whole day unattended | 2 | 0.8 | 1.55 |
| Worthwhile daily resources | 2 | 1.6 | 1.7 |
| Scarce resources protected and aimed | 1.5 | 1.2 | 1.35 |
| Paid adventures allocated well | 1.5 | 0.4 | 1.0 |
| Spending rules | 1 | 0.7 | 0.75 |
| Museum progress | 1 | 0.7 | 0.85 |
| Safety and reporting | 1 | 0.6 | 0.95 |
| **Total** | **10** | **6.0** | **8.15** |

### Quality cycle 1: post-merge assessment

The provisional code assessment advances from **7.8 to 8.15**, following [PR #32](https://github.com/sachamm/KoL/pull/32). Whole-day handling gains 0.15 for explicit failed-command propagation, scarce-resource protection gains 0.10 for fail-closed and observed-quantity fencing, and safety/reporting gains 0.10 for durable intent, dated journal recovery and exclusive runner ownership. Other criteria do not gain points from this cycle. The live score remains 6.0.

Full verification was repeated on merged commit `6dd43ccd6f6da74b3f207687fd6e18af81a7b50c`: **937 ASH assertions** (120 core, 612 gate, 7 dressup, 94 diet, 49 review, 55 NPC resale), both compilations, logged-out plan/diet/static checks, and an expected-abort regression proving neither the task nor its recovery hook runs after failed journal persistence. Windows verification passed **12 diagnostic cases and 18 ownership/process/launcher checks** using real file exclusion and fake process APIs. No game actions were performed.

The user's later manual close on November 26 reported net 7,171,031 Meat, operating spend 326,807, collection spending 2,499,686, and three resource counters with uses left. It does not establish a fresh corrected unattended day, source provenance, realized per-grind item proceeds or new confirmed ranks. None of those gaps is awarded points here.

The unchanged target is **9.9**, not achieved. Continue with provenance, economic evidence and allocation; the five-day live acceptance milestone remains open. See [quality cycles](daily-script-quality-cycles.md).

### Evidence behind the live score

- November 25 reached the close after repeated intervention. Forced noncombats and overdrunk combat stopped; `goodnight.adv` ultimately exhausted its two attempts. The first November 26 snapshot also had interrupted nightcap work and no completed close. After the user finished manually, its journal recorded a close; that is recovery with intervention, not an unattended completion.
- November 25 used all five spikes, three Avalanches, three Feel Envy casts and 100 Sword charges. Fences and opening MP recovery worked. On November 26 the Party counter stopped at six, but a subsequent attempt returned “Party's Over”; those remaining charges were blocked at that point, not four confirmed missed fights.
- The November 25 grind report credited 143 Oasis turns with 32,812,113 Meat of items and four Daily Dungeon turns with 7,053,064. The positive-only holdings calculation omitted equipment and input consumption, so these totals cannot establish profitability. Their precise attribution has not been reconstructed from a complete opening inventory.
- The completed close reported net 4,295,136 Meat, operating spend 216,605, collection spending 351,613 and remaining allowance 1,579,350. That net includes sales of existing stock. The audit found 2,546 Meat above average sale prices among the checked purchases.
- `smmSpend` recorded 97 nonzero purchase entries across 91 items, with actual case deposits. Purchases and deposits alone do not prove 91 new Museum ranks.

The evidence is the local `Tquilla_20261125.txt` and `Tquilla_20261126.txt` sessions and `smm-daily-2771003[-prev].txt` journals, reviewed November 26. Private account state is not committed here. The live score stays at 6.0 until a corrected live day supplies new evidence.

### Implemented corrections

[PR #30](https://github.com/sachamm/KoL/pull/30) adds HP/MP preparation after dressing, an inventory check before using a rocket, bounded and price-capped nightcap medicine, and affordable overdrunk spell selection. Nightcap activities have separate resumable tasks. The existing plan profile becomes the default while respecting an explicit profile.

Grind accounting now measures signed physical ownership across storage and equipment, records session transactions, separates native retained loot estimates, charges consumed inputs at opportunity value and excludes reusable returns. Version-2 history is discarded. A collection exemption needs a named unbuyable target, a known cached gap and reserved adventure funding; unrelated untradeable drops no longer qualify a grind.

Collection buying refreshes its operating ledger before allowance decisions and requires verified average-price ceilings; unknown mall averages cannot authorize purchases. NPC resale and its logged-versus-actual price adjustment are preserved. The closing report records confirmed case-count changes, cached threshold crossings, resource owners and dispositions, and explicit complete/incomplete outcomes. Runner diagnostics distinguish printed macro definitions from actual failures. A follow-up restores the existing runner lock lifecycle and tests that it precedes stopping Mafia.

### Post-merge checks

The full offline suite was rerun against merged commit `1201789429655ddad5582055938aefa36731f7d7` on November 26, using KoLmafia r29462 in an isolated, logged-out runtime:

| Check | Result |
|---|---|
| `smmDailyCoreTest` | 113 assertions passed |
| `smmDailyGateTest` | 607 assertions passed |
| `smmDressupTest` | 7 assertions passed |
| `smmDietTest` | 94 assertions passed |
| `smmDailyReviewTest` | 49 assertions passed |
| `smmNpcResaleTest` | 55 assertions passed |
| **ASH total** | **925 assertions passed** |
| `smmdaily` and `diet.ash` compilation | Passed |
| Logged-out full-day plan and diet planning | Passed |
| Prompt, rest, task-function, preference and shared-setting checks | Passed |
| Windows runner diagnostics | 12 cases and parser check passed; lock-preservation checks added and passed on the follow-up |

Commands: `tests/smmdaily-tests.sh` and `tests/kol-daily-diagnostics-tests.ps1`. No live account actions were performed. The historical logs have not been relabeled as runs of the corrected code.

### What still limits the score

- A fresh live day must validate combat, recovery, task boundaries and the complete marker together. Missing safe recovery or an affordable spell still causes a deliberate stop.
- Third-party direct purchases are booked and audited; this code cannot universally intercept them. The medicine fallback can also refuse when no verified average is available.
- The adventure guard covers the automation paths and configured pre-adventure hook. Arbitrary third-party requests bypassing both cannot be stopped by it. Collection reservations conservatively charge other turns played during an interruption.
- A correct inventory estimate is not realized sales or a liquidity model. Farm history still needs useful samples; 4,500 Meat/adventure remains provisional. Profitable bulk resale still depends on actual demand and future sales.
- Forced-noncombat targeting remains partly configured rather than globally optimized. Resource dispositions identify blocked or unspent capacity without establishing every best alternative.
- Case-count increases are confirmed; threshold crossings use cached competitors. Fresh rankings are required to confirm current places and successful rank defense.

The next acceptance milestone is **five consecutive corrected live days that finish without intervention**, with no unexplained failed tasks, reconciled per-grind quantities and spending, and confirmed collection results. Re-score from those outcomes; do not award points merely because the tests pass.

## Historical scores

| Criterion | Max | Live run 2026-11-24 (log) | main, 2026-11-24 (code) | Round 1 | Round 2 | Round 3 | Round 4 |
|---|---|---|---|---|---|---|---|
| 1 Whole day | 2 | 0.5 | 0.5 | 1.6 | 1.6 | 1.75 | 1.8 |
| 2 Daily resources | 2 | 1.2 | 1.0 | 1.6 | 1.7 | 1.85 | 1.9 |
| 3 Scarce resources | 1.5 | 0.2 | 0.25 | 1.2 | 1.2 | 1.35 | 1.45 |
| 4 Paid turns | 1.5 | 0.6 | 0.5 | 1.0 | 1.0 | 1.3 | 1.3 |
| 5 Spending rules | 1 | 0.8 | 0.75 | 0.75 | 0.8 | 0.8 | 0.8 |
| 6 Museum | 1 | 0.9 | 0.5 | 0.5 | 0.9 | 0.9 | 0.9 |
| 7 Safety and reporting | 1 | 0.6 | 0.6 | 0.8 | 0.9 | 0.9 | 0.9 |
| **Total** | **10** | **4.8 (5)** | **4.1 (4)** | **7.45 (7)** | **8.1 (8)** | **8.85 (8)** | **9.05 (9)** |

The live run scored higher than main's code on the Museum and daily resources only because Sacha ran garbo, the nightcap, `good_night` and nine `dc rankup` commands by hand.

### main before 2026-11-25 (4)

- The default `legacy` profile ran breakfast and the grinds only. The diet, garbo, the nightcap steps and `good_night` were run by hand, and `diet.js` waited on a question.
- Garbo, run by hand first, rested 31 times and spent 430 Cinch on Projectile Piñatas, so the Shadow Rift work after it had no Fiesta Exit left (0 of 7). Nothing spent the Avalanches.
- Grind loot was valued at its lowest mall listing: 154 Oasis turns read as 37.6M Meat. With figures like that the turn-value test never skips anything.
- The diet filled the organs before the Drip's nugget and wine, so the Drip got no turns.
- The report ran before garbo and the nightcap, so its "unused" list was mostly wrong.

### Round 1 (7)

- `diet`, `forced.nc`, `garbo` (now on by default), and the nightcap phase (`nightcap.before`, `diet.turngen`, `garbo.final`, `diet.finish`, `goodnight.adv`, `goodnight`) are tasks. `diet.js` takes a `yes` option and records its stop point for `garbo.final`.
- `forced.nc` spends spikes, Avalanches (new in `grindRufusAndTheShadowRiftsForFree`) and every Fiesta Exit before garbo, and the Cincho de Mayo is fenced while garbo runs.
- Grind loot is valued at its average sale price, never above the listing, autosell when nothing sells. The inflated history is cleared once.
- `drip.prep` eats the drippy nugget and drinks the drippy wine before the diet.
- `day.open` runs `smmPrefs apply`. The report comes after `good_night`.

### Round 2 (8)

- `smmSpend` has a third pass: the cheapest whole Display Case gaps, top ten first, at no more than the average sale price, within half of the net. This is what the nine `dc rankup` commands did by hand.
- The report says first when the day is not finished (garbo not run, or the nightcap not in).
- History from before the valuation change is never used to skip a grind, and `smmdaily plan` changes nothing.

### Round 3 (8.85)

- Codex's two review findings: `diet.finish` spends down to finish's own stop point (Sweat Out Some Booze is counted only there) and finishes again; `goodnight` checks the rollover cap again after `good_night`'s turn generation.
- A grind under half the turn value is dropped after 2 logged days (`smm.dailyGrind.earlyDays`), not 5. The Museum exemption holds only while the untradeable item the grind brought in is still short in the Display Case.
- Spikes and Avalanches no longer go unused when the free fights and free kills run out: each takes one paid Shadow Rift fight, which pays for itself with about 11 free Rift fights (`smm.forcedNC.paidTurns`).
- Feel Envy has an owner: the consult script casts it on a monster whose uncertain drops are worth at least two turns (`smm.envy.minGain`).
- During a run, the questions the run can reach in the shared scripts answer their default at once instead of waiting a minute.

### Round 4 (9.05)

- `nep` fights the free party turns left after the quest finishes. On 2026-11-24 the quest finished on the 9th and the 10th went unused.
- Fiesta Exits can be aimed at chosen noncombats first: `smm.forcedNC.targets` lists location, choice and times a day, best first. The rest still go to the Shadow Rift.
- `smm.daily.garboAutoConfirm` (off by default) lets garbo answer its own questions while smmdaily runs it, so an unattended run cannot hang on one.

### What kept Round 4 from 10

- garbo can still ask, and its questions have no timeout, unless `smm.daily.garboAutoConfirm` is turned on (garbo calls that experimental). Winning the Gingerbread City sprinkles leaderboard is left to `gbc win` by hand.
- Nothing chooses a forced-noncombat target by itself: they go to the Shadow Rift unless `smm.forcedNC.targets` is set by hand, and only Fiesta Exits can go to a target.
- The turn-value test still needs 2 to 5 days of history before it can skip a grind.
- garbo buys at its own prices (for example a Dinsey day ticket at 145,350). Its purchases are booked against the cap afterwards, not blocked before.
- Snojo and CyberRealm are not unlocked. The audit lists unused resources without saying which task owns each.
- At the time of Round 4, those changes had not run in the game. The November 25–26 operational review above supersedes that forecast.
