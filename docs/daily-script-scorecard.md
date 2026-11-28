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

## Current assessment

**Demonstrated live performance: 6.0/10. Corrected code, provisionally: 8.70/10.** The earlier 9.05 was a code-only forecast. It is superseded by the operational evidence and conservative assessment below, rather than treated as a demonstrated result.

| Criterion | Max | Demonstrated live outcomes | Corrected code, offline |
|---|---:|---:|---:|
| Whole day unattended | 2 | 0.8 | 1.65 |
| Worthwhile daily resources | 2 | 1.6 | 1.7 |
| Scarce resources protected and aimed | 1.5 | 1.2 | 1.40 |
| Paid adventures allocated well | 1.5 | 0.4 | 1.20 |
| Spending rules | 1 | 0.7 | 0.90 |
| Museum progress | 1 | 0.7 | 0.90 |
| Safety and reporting | 1 | 0.6 | 0.95 |
| **Total** | **10** | **6.0** | **8.70** |

### Quality cycle 31: standalone spending books manual costs too

The latest session's manual `good_night` spending reports still showed 15130 operating Meat while the later full audit booked 343317. The standalone budget refresh returned early whenever `smm.daily.active` was empty. Consequently, purchases made by direct/manual garbo could remain outside the next standalone collection-spending decision. This is a code gap, separate from whether historical request rows filled or what their average was at purchase time.

Operating-spend refresh now runs for any logged-in player with an opening ledger and an available session log, including standalone `good_night`/spending. It retains conservative purchase-request booking, own/diet exclusions, incremental parsing and the maximum already booked. Missing opening/player/log coverage grants no new spending allowance. No recorded expense, actual cash, quota or historical audit flag is cleared. Eight synthetic in-memory cases cover manual context, later purchases, duplicate parsing, shared-cap arithmetic, truncation, logout, missing opening and unavailable log. They do not rely on setting native user preferences while logged out.

[PR #83](https://github.com/sachamm/KoL/pull/83) merged as `d2789642d561b05aeaafa998e7fe0afd1e65d603`; its exact post-merge suite passed **1558 assertions (1266 ASH + 292 JavaScript)**, **20 refusal/abort scenarios** and **140 Windows cases**. The expanded outcome group passes 57 cases and the 637 native gate cases pass. Exact integration and capped native results follow execution. Historical over-budget/price-timing uncertainty, fresh Museum-count matches, source valuation and qualifying unattended days remain unresolved; they are not fixed by discarding evidence.

### Quality cycle 30: paid Daycare is an explicit investment

[PR #81](https://github.com/sachamm/KoL/pull/81) and the registration-test correction in [PR #82](https://github.com/sachamm/KoL/pull/82) integrated as `41d2ce0717b9052d316725cd8aef450b540415b8`. The corrected exact suite passed **1551 assertions (1259 ASH + 292 JavaScript)**, **20 refusal/abort scenarios** and **140 Windows cases**. Installed source matched and all four entry points compiled.

Native run `0bed274e9dcd4804ba6ab2221692d5c7` reconciled the actual prior standard garbo completion, skipped exhausted spinner/locket before preparation, reached the close report and final audit, and logged out normally. Source stayed stable with matching boundaries, no timeout and a clear fence (generation 161). Automatic-login settings restored. The run made **zero purchases**, with unchanged cash, and spent **three adventures** on Daycare gym equipment before reporting zero rollover overflow. That paid stat/equipment investment had no verified Meat or Museum return.

Paid Daycare now defaults to **zero**, retaining the free first scavenge subject to access and the legacy three-adventure safety reserve. `smm.daily.daycarePaidTurns` explicitly opts into at most three paid turns per day; observed turns consume that allocation even after an abort. The loop is bounded and stops on no confirmed progress. The manual `good_night_adv` path uses the same budget and avoids healing for an exhausted locket. No native usage counter or past expense is reset. Six allocation cases and native core/gate/entry-point verification passed; exact integrated results follow execution.

The day remains financially **INCOMPLETE**: all 54 purchased item types were quoted; 66 historical requests have 7224 Meat potential above-average excess, and recorded commitments exceed the shared cap by 29359 Meat. Current-run boundaries show no new purchase or cash loss. Requests/current quotes do not establish historical fills or the price at purchase; those flags cannot be dismissed to manufacture completion. Museum reporting confirmed 5053 added case copies across 168 items, but all ten fresh pages had older player counts, so **zero current ranks were verified**. The other 158 items were not freshly queried. Cached threshold crossings are not confirmed placements. The remaining Sword/saber capacity has no confirmed profitable use recorded, and garbo phase instrumentation remains unexercised on this already-overdrunk, largely exhausted account. A fresh corrected day and calibrated values are still needed.

### Quality cycle 29: exhausted-source preparation and command-file aborts

[PR #80](https://github.com/sachamm/KoL/pull/80) merged as `a6c72d4b6eafd2731a5896cdf4a01ca1af603888`. Its exact post-merge suite passed **1533 assertions (1241 ASH + 292 JavaScript)**, **19 refusal/abort scenarios**, compilation/planning/static checks and **137 Windows cases**. Nine installed scripts and all five runner modules matched tested source; all four installed entry points compiled before login.

Native run `c6805511528d486485f112aa3dfbe69b` exposed two defects. Spinner preparation spent available MP healing toward the unchanged 60% HP target even though all ten Time-Spinner minutes were already used. The allowed resources could not reach that target, so preparation refused combat, but it should never have started. The hard ASH abort stopped Mafia's command file before the new audit, status and end marker. The owned process timed out on the existing idle limit; source stayed stable, but no end boundary or complete day was demonstrated. The already-overdrunk account skipped garbo, so the new phase hooks were not exercised live.

Spinner and locket now use native source-unavailable/exhausted done-tests before MP hooks and retain defensive checks before dressing/healing. Actual usage counters are not rewritten. The runner uses Mafia's native `try;` file continuation, emits an explicit failure marker through `else;`, then performs the same-epoch audit and logout. A hard failure remains disqualifying even if a complete marker was printed earlier. The regression uses a real command file, proving abort continuation and no false failure after success.

The saved state also confirms completed standard manual garbo and actual Barf access while an old access-price hold remained. Run-start reconciliation clears only that stale local hold after a durable note: native completion must be standard, leaving no more than the configured stop point, and access must exist. Daily-only, custom, unknown, looser-stop or inaccessible outcomes cannot clear it. Native counters/completion and spending remain intact; prior/manual work is explicitly not unattended evidence. Phase estimates exclude setup/cleanup outside their boundaries and cannot calibrate realized marginal profit alone.

Pre-merge verification passed **1541 assertions** and **20 refusal/abort scenarios**, followed by ten native reconciliation cases (43 outcome checks total). Native r29482 also verified the file-abort/else/audit/exit protocol and entry-point compilation. Windows suites pass **140 cases**. Exact integration/native results follow execution. Scores remain **8.70 provisional code / 6.0 demonstrated live** pending new evidence.

### Quality cycle 28: latest-session review, guarded crafting and verifiable outcomes

The latest `Tquilla_20261127.txt` contains substantial later manual play: direct garbo bought/used a ticket, paid farming continued, the nightcap and `good_night` were run, and a state snapshot was taken. These actions are not retroactively attributed to the earlier guarded runner or counted as an unattended corrected day. The reviewed file was 10,596,732 bytes, SHA-256 `67c7aad9021a8890f6ea43b420d942ce8379c2c13a04cfba471145c970132e7f`. It still contains no complete-day result. Garbo's cumulative 402-turn report separates 1,635,267 raw Meat from 8,629,555 estimated item value; neither its estimate nor its NaN marginal-MPA output establishes realized profit. The legacy end report valued a worthless trinket at nearly a trillion Meat. A debuff macro attempted an unavailable pair of items; the fight later recovered, but the planner had promised unavailable actions.

| Remaining gap | Implemented response | Evidence still needed |
|---|---|---|
| Unattended end-to-end outcome | A same-player/day/ascension runner audit runs even after an early stop, inside the evidence boundaries; skipped coverage is an error. | Five corrected complete unattended days; resumed/manual work does not qualify. |
| Daily/expiring resources | Free-fight, copy and farming phases record opening pools and observed net capacity changes; the close audit includes the shared registry and actual reservations. | Net capacity is not gross use, a profitable alternative or causal attribution. |
| Scarce allocation | Existing reservation/turn protections remain; phase evidence exposes actual capacity changes to calibrate competing uses. | Global forced-NC target values and encounter-specific carrier comparisons remain uncalibrated; configured targeting is not called optimal. |
| Paid-turn economics | The inspected free/copy/farming functions have separate measured cash, signed physical inventory and backlog-limited liquidation receipts. Failed phases do not train completed-run history. | Measured phase aggregates can include incidental free encounters; inventory estimates, assumed demand share and old-stock sales are not realized resource profit or marginal turn value. |
| Purchase/consumption coverage | Native `create` receives only verified zero-turn cooking/mixing recipes with physical unreserved inputs, while automatic sources and buy hooks are disabled. A finished substitute must cost no more than ingredient opportunity cost and obey the original automatic limit, average ceiling and shared allowance. | Direct URLs, delegated scripts, combat macros and unsupported recipe fees/currencies remain cooperative-boundary gaps. Unsupported/unaffordable operations stop rather than bypass policy. |
| Museum positions | Changed case items get up to ten fresh requests (bounded to twenty). A rank is verified only when the request succeeds, its timestamp is current and its player-row count matches the case. Receipts retain failures and coverage limits. | Current positions do not prove a daily rank gain without a matching opening position; delayed Museum counts remain unverified. |
| Reporting/recovery | The legacy trillion-Meat report is replaced with conservative demand/backlog-limited positive-item estimates, explicitly excluding inputs/costs and never called profit. Crafting finally restores all nine settings, including after a real ASH abort. | Power-loss/external intervention and unobserved outcomes remain explicit limitations. |

Debuff selection now filters both paired tools and stagger items by physical stock and Museum surplus, accounts for consumable multiplicity and recognizes the separate native `combat_reusable` flag. No absent item is promised as a debuff action or credited as a staggering round. Eight synthetic cases cover missing stock, reserved copies, duplicate single copies, reusable tools and caller-data immutability. Other hand-written combat macros remain outside this boundary.

Pre-integration full verification passed **1524 assertions (1232 ASH + 292 JavaScript)**, **19 refusal/abort scenarios** and **137 Windows checks**, followed by the eight native debuff cases and an additional permanent-combat-tool case. The final outcome group has 25 checks. Native checks include the craft adapter, phase hooks, action-blocked actual-bundle loading and four entry-point compilations. A real ASH-abort fixture restored all nine crafting settings before native crafting, and the generated audit command skipped a logged-out/wrong-epoch account. Phase receipts use the parent's durable checkpoint and unique item-evidence paths so zero-turn retries cannot overwrite prior observations; missing item evidence stops work and truncated logs cannot train completed-run history. Exact merge and native results follow execution. Scores remain **8.70 provisional code / 6.0 demonstrated live** until new evidence justifies a change. This cycle addresses every gap explicitly; it does not declare every gap solved.

### Quality cycle 27: report current stops without replaying historical failures

The cycle 26 native retry (`616321b574304c5ba2c7ad57416780b2`) started a confirmed gold Guzzlr contract and used the received Witchess Bishop fax (`_photocopyUsed` changed to true). Garbo's daily worker returned, all fenced stock came back, source stayed stable and Mafia exited normally with matching boundaries. No turns or adventures were spent during this retry. Paid farming remained held: the ticket quote of 153000 exceeded the unchanged average-price ceiling of 152142. The daily task and nightcap remain incomplete; upstream item estimates do not establish realized profit.

The runner also falsely classified the boolean `errorOnAmbiguousFold` echo and rendered historical journal failures as current errors. Classification now excludes that exact valid boolean echo and strictly shaped known journal rows, while explicitly recognizing the current `smmDaily: stopped after` message. Malformed/unknown history-like lines, actual failures, incomplete/missing completion and boundary/source checks remain disqualifying. Reclassifying the private native output retains exactly its real paid-work stop. [PR #77](https://github.com/sachamm/KoL/pull/77) merged as `896fdd0969dfbb72969812e0c550ba154f718a2c`. Post-merge Windows checks passed **133 cases: 38 diagnostics, 40 evidence, 37 login and 18 ownership**. Game scripts, policy and ASH/JS fixtures were unchanged from the 1457-assertion full-suite merge.

The installed runner modules matched tested source. Native run `2fcced356c3c4d8daa624e65812eccf6` returned normally with stable source, matching boundaries, no timeout and unchanged turns/adventures. Its report now identifies only the current paid-work stop plus the consequent incomplete-day/evidence failures; it contains neither historical-failure nor setting-echo false positives. All fenced stock returned (generation 145, no recorded items), automatic-login settings restored, and review candidacy correctly remains false. The daily task and nightcap stay unfinished. Scores remain **8.70 provisional code / 6.0 demonstrated live**; **0 of 5 qualifying corrected unattended days** are demonstrated in this review. The resumed/intervened tests do not establish paid-turn profitability or fresh Museum places. Repeating the same held run supplies neither; 9.9 remains unachieved.

### Quality cycle 26: distinguish permanent menu use and verify contract acceptance

[PR #75](https://github.com/sachamm/KoL/pull/75) merged as `aa91c18010d1151a6610e04659556ab7d236d2a1`. Post-merge checks passed **1430 assertions: 1207 ASH and 223 JavaScript**, **18 refusal/abort scenarios**, compilation/planning/static checks and **118 Windows cases**. The native retry passed the sandworm eligibility gates without attempting blocked carriers, continued through daily fights, then repeatedly tried to start a Guzzlr contract because the Museum consumption guard incorrectly treated tablet navigation as consuming a protected copy. The owned process was interrupted normally: stable source, exit 130, no end boundary and no completed day.

Native r29482 journals preserved all **57 checked resource values**, with zero mismatches after replay; no counters were rewritten. Recovery restored the earliest captured values of **33 borrowed settings** across the interrupted attempts (30 required changes), returned the durable fence and reconciled purchase booking. The recovery-log parser now includes changes to an empty string. The native tablet probe opened and left choice 1412 successfully with item ownership, adventures and total turns unchanged and no open choice. Private recovery evidence remains outside Git.

The guard now recognizes this verified permanent menu item for `use` only. Contract choices 2–4 must return successfully with an active native quest (`started` or `step1`); denial, failed retrieval, a false request or an unconfirmed quest stops before upstream can repeat the menu loop. Leave/abandon choices and ordinary consumables retain their behavior. [PR #76](https://github.com/sachamm/KoL/pull/76) merged as `49e5a06a34c80d0db47e5028cdb2e169a1d7092d`. Post-merge verification passed **1457 assertions: 1207 ASH and 250 JavaScript**, **18 refusal/abort scenarios**, compilation/planning/static checks and **118 Windows cases**. Twenty-seven menu cases, an action-blocked load of the installed bundle and four entry-point compilations passed on r29482; all four installed entry points compiled too. The native retry confirmed contract acceptance, finished the free worker and stopped honestly at the existing paid-access ceiling. Scores remain **8.70 provisional code / 6.0 demonstrated live**; the intervened day is not a qualifying unattended outcome.

### Quality cycle 25: gate unavailable sandworm carriers and recover interruption

The fractional-limit fix passed natively. Garbo then retried sandworm tasks after capped drum-machine acquisitions returned no fill: the log contains 125 sandworm task attempts and 375 no-fill messages. Upstream has a 20-skip limit per carrier; this was excessive bounded retrying, not proof of an infinite loop. The process had progressed to fax setup by the time the owned test process was stopped. Its evidence has stable source, exit -1 and no end boundary; it is an interrupted test, not a completed day.

Recovery acquired exclusive ownership, returned the persisted fenced copies with conserved quantities, restored/verified all 19 captured borrowed settings and refreshed purchase booking. Native checks found no fight, choice, pending force or active map. The already requested Witchess Bishop fax was received and remains unused. The final recovery check found zero setting mismatches and a clear fence. Private snapshots and recovery files remain outside Git; resource counters, spending and completion records were not reset.

The loader now applies input eligibility to both inherited drum-machine tasks and their fight-estimate definitions, while preserving independent carriers such as the quad tom. It rechecks supply, Museum reserve, prices, source ceiling and shared allowance; a confirmed no-fill prevents repeating the same/lower guarded ceiling in that worker. Combat macros that spend shadow bricks or partial tombstones require actual unreserved stock until a replacement transaction is supported for those paths. Missing/changed hook metadata refuses loading. Fourteen factory cases, eight additional buy-observation cases (20 total), four entry-point compilations and an action-blocked load of the installed bundle passed on isolated r29482. Exact integration and native results follow after execution. Scores remain **8.70 provisional code / 6.0 demonstrated live**.

### Quality cycle 24: preserve fractional automatic-buy ceilings

The next native retry passed both protected-garden entry points and reached giant-sandworm preparation. Garbo supplied a calculated fractional `autoBuyPriceLimit`; the adapter's integer-string-only validation rejected it before acquisition. That stable-source attempt returned all fenced copies and ended incomplete with the paid-work hold intact.

Automatic-buy ceilings are now normalized once in JavaScript before crossing the typed ASH bridge. Valid finite decimals/scientific notation are bounded and rounded down using decimal digits, avoiding binary rounding that could authorize one Meat above a sub-Meat ceiling. Explicit zero retains the native default; negative values prohibit buying, and positive sub-Meat/underflowed ceilings allow no purchase. Malformed, nonfinite and out-of-range inputs still refuse. Replacement consumption and garden forecasts receive the normalized integer instead of independently coercing the setting into a default.

Twenty-eight normalization/typed-bridge cases, 46 retrieval checks (three new fractional/sub-Meat cases), existing consumption checks, four entry-point compilations and the action-blocked installed-bundle load passed in isolated r29482. [PR #74](https://github.com/sachamm/KoL/pull/74) merged as `d78dc1809bce1cda287ff013a720274dadd6847e`. Post-merge verification passed **1408 assertions: 1199 ASH and 209 JavaScript**, **18 refusal/abort scenarios**, compilation/planning/static checks and **118 Windows cases**. The installed source matched the tested merge and all four entry points compiled logged out. The native run accepted the fractional limit, then exposed the bounded no-fill retries described above and was interrupted. Scores remain **8.70 provisional code / 6.0 demonstrated live**; 9.9 is unachieved.

### Quality cycle 23: guard the separate garden planting task too

The cycle 22 native retry confirmed discovery was held and let more free fights run, then a separate `Plant Black Rose Garden` task still attempted the protected seed and failed its guard. The first hook had missed that independent task. Cleanup returned all fenced stock, retained the paid-work hold and recorded an incomplete stable-source run.

The loader now validates the actual planting task in the upstream free-fight list and combines its original readiness predicate with the same seed eligibility check. Its original completion and action callbacks remain intact; unavailable stock does not become a fake completed task. The factory regression exercises discovery and the separate task together, including later supply changes and changed/missing task structure. [PR #73](https://github.com/sachamm/KoL/pull/73) merged as `280d2f6d2abfcc844a7b8f3d911c68061e3cab95`. Post-merge verification passed **1377 assertions: 1199 ASH and 178 JavaScript**, **18 refusal/abort scenarios**, compilation/planning/static checks and **118 Windows cases**. Fifteen garden checks, 24 route checks and an action-blocked structural load passed on isolated r29482; the four installed entry points compiled logged out. The native retry passed the separate planting gate and exposed the fractional-limit issue above. The assessment remains **8.70 provisional code / 6.0 demonstrated live**, below 9.9.

### Quality cycle 22: optional garden fights respect protected planting stock

The next native retry confirmed the absinthe eligibility hook: it selected other item-steal encounters instead of retrying the unsuppliable prerequisite. It then reached Black Rose Garden discovery, whose attempted planting was correctly refused because the seed was protected. Upstream treated that refusal as fatal. The stable-source attempt ended incomplete with its paid-work hold and all fenced stock returned.

Garden discovery now checks usable seed supply first. Installed garden access and already finished discovery retain the original behavior. Otherwise the same supply, Museum reserve, automatic-source, price and allowance rules apply. An unavailable optional garden gets an empty in-memory monster list, allowing other daily work to continue; no native daily-used flag is fabricated. Readiness failures and actual planting failures still propagate. This cooperative hook validates the inspected private discovery function/cache and must be rechecked on upstream changes.

Thirteen synthetic factory checks, the existing 24 route cases, four entry-point compilations and the action-blocked structural load of the installed public bundle passed on isolated r29482. [PR #72](https://github.com/sachamm/KoL/pull/72) merged as `be36909d3587c9dc4631c65ab969eb0c61cb9ca3`. Post-merge verification passed **1375 assertions: 1199 ASH and 176 JavaScript**, **18 refusal/abort scenarios**, compilation/planning/static checks and **118 Windows cases**. Installed source matched the tested merge and compiled logged out at all four entry points. The native retry confirmed discovery refusal and exposed the separate planting task above; it did not establish a complete garden integration or day. Scores remain **8.70 provisional code / 6.0 demonstrated live**; the full day, economics and qualifying unattended sequence are still unproved.

### Quality cycle 21: exclude an unsuppliable item-steal prerequisite

The next native attempt selected the supported daily-work mode, completed daily-item work and several free encounters, then failed before entering an item-steal route because its absinthe acquisition could not fill under the guard. The boundary recorded no paid turns during this attempt. Source stayed stable, the paid-work hold survived, and all fenced items returned; the daily task and nightcap remained unfinished. Upstream's estimated item proceeds are not treated as realized profit.

The cooperative loader now adds an eligibility check to the actual Stately Pleasure Dome entry before its original selector ranks routes. The forecast includes accessible input, Museum replacements, permitted automatic sources, verified average, current quote, upstream acquisition ceiling and the shared allowance. An unsuppliable prerequisite yields to another originally eligible route; existing effects or supplied surplus remain usable. Prices and the original ranking function are unchanged. Real acquisition/consumption remains guarded, and a later failed fill still stops. This is one inspected route hook, not universal third-party purchasing coverage. Missing, duplicated or changed hook structure refuses loading before main.

Twenty-four synthetic input/selection assertions and the existing adapter/access cases passed on isolated r29482. A public copy of the actual installed bundle passed the structural load test with synthetic state and actions blocked; its main was never called in that check. [PR #71](https://github.com/sachamm/KoL/pull/71) merged as `82ae143f25d0a14946f9bd20966f3b078247d06a`. Post-merge verification passed **1362 assertions: 1199 ASH and 163 JavaScript**, **18 refusal/abort scenarios**, compilation/planning/static checks and **118 Windows cases**. Installed source matched the tested merge and compiled logged out at all four entry points. The next native run confirmed alternate selection and exposed the optional garden failure above. Scores stay **8.70 provisional code / 6.0 demonstrated live**.

### Quality cycle 20: run daily work when paid access is held

The cycle 19 retry completed `forced.nc`: the remaining Avalanche was confirmed, and Fiesta Exits used the available Cinch rests before garbo. Garbo then attempted a Dinseylandfill ticket above the verified average-price ceiling. The purchase guard correctly refused a fill; the worker failed, every fenced copy was returned, and the run ended with stable source, a matching end boundary and incomplete evidence. No cap is raised to get past that stop.

The standard garbo invocation now forecasts paid Barf access with the same allowance, average-price ceiling and upstream ticket maximum. When access is unavailable at those limits, it runs garbo's supported `nobarf` daily-work mode and persists a paid-work hold before dispatch. This mode disables bulk farming; individual upstream daily subworkers are not claimed universally turn-free. A partial worker setting its own completion property cannot release the daily/nightcap gate. Only a later standard invocation that returns with native completion and no access hold clears the marker. Custom arguments are preserved. A later quote change can still make the real guarded purchase fail; the forecast does not authorize it.

Thirty synthetic adapter/access checks and four completion-gate regressions passed in isolated r29482, alongside the existing purchase/retrieval/consumption cases and four entry-point compilations. [PR #70](https://github.com/sachamm/KoL/pull/70) merged as `4c71f37f77c8ce6162c2b2d5d17c52127c667b2d`. Post-merge verification passed **1338 assertions: 1199 ASH and 139 JavaScript**, **18 refusal/abort scenarios**, compilation/planning/static checks and **118 Windows cases**. Installed public source matched the tested code and all four entry points compiled logged out. The native retry confirmed the partial-mode branch and durable hold, then exposed the prerequisite-selection failure in cycle 21. Scores remain **8.70 provisional code / 6.0 demonstrated live**; this resumed, intervened day is not one of the five consecutive qualifying unattended days, and reconciled economic performance and fresh Museum ranks remain unproved.

### Quality cycle 19: declined carriers, post-merge and native results

[PR #69](https://github.com/sachamm/KoL/pull/69), merged as `754f20550ba3b9bf41923599d11e7f5bbbbf17eb`, distinguishes an explicit no-fight summon decline from an ambiguous force cast. The declined carrier is excluded only after unchanged encounter/usage state, an unclaimed consult flag, no pending force and a consistent read-only refresh. Ambiguous results still stop before a new carrier or target. General free-fight workers cannot loop on the rejected provider or run combat against a previous page.

Post-merge verification passed **1304 assertions: 1195 ASH and 109 JavaScript**, **18 refusal/abort scenarios**, compilation/planning/static checks and **118 Windows cases**. The force suite has 52 assertions; it and all four entry points passed in isolated r29482. Installed public code matches the tested merge and compiled logged out. The live retry used another eligible carrier, completed forced noncombats and exposed the paid-access stop above. The new decline/reselection branch is regression-tested; that retry did not need to reproduce another rejected Cat Day cast.

The preceding native healing retry also passed Gingerbread City and confirmed Display Case deposits including the li'l ghost costume. These are acquisition/deposit and resumed-stage outcomes, without a new competitor-rank measurement or a complete unattended day. No score increase is assigned for those narrower results.

### Quality cycle 18: high-HP healing, score unchanged pending the retry

[PR #67](https://github.com/sachamm/KoL/pull/67), merged as `ca7d4691cc7ab1bbb83af49e88e3dac48346c5a3`, removes an eight-cast cutoff from combat healing. The live attempt reached Gingerbread City, then stopped after eight confirmed Cocoon casts of 1000 HP each, still below the unchanged 60%-of-final-outfit target. Healing now continues only while a known skill is affordable with current MP and each successful cast increases HP. Failed casts, no progress and insufficient MP stop further healing; no MP purchase or rest is added by this loop.

The exact merge passed **1285 assertions: 1176 ASH and 109 JavaScript**, **18 refusal/abort scenarios**, main/FantasyRealm/diet compilation and planning/static checks, plus **118 Windows checks** (27 diagnostics, 36 evidence, 37 login, 18 ownership). Thirteen new healing checks and all four production entry points also passed in isolated r29482. Installed public source matches the merge and compiles logged out. The targeted native healing retry is outside this assessment cutoff; the preceding run is terminal with stable source and incomplete evidence.

### Quality cycle 17: recover the interrupted third map

[PR #66](https://github.com/sachamm/KoL/pull/66), merged as `b804c1893544e76c090d452e9a1bfb8b1fd3a3bb`, handles configured, currently offered June Cleaver choices and wandering fights while awaiting the actual mapping choice. It bounds transitions and stops on unknown or unavailable choices, unfinished combat, Beaten Up, lost mapping or exhausted adventures. An already active third map is reused despite an exhausted casting counter, without recasting.

Post-merge checks passed **1272 assertions: 1163 ASH and 109 JavaScript**, **18 refusal/abort scenarios**, compilation/planning/static checks and **118 Windows checks**. The 21 mapping checks also passed in isolated r29482. Native recovery submitted the inspected configured choice, used one available skip and retained the active map without incrementing its cast counter. A follow-up check identified the remaining refresh screen as the locket, which the existing runner cleanup handles. The subsequent retry **acquired the li'l ghost costume** and advanced through later grinds. This proves an owned acquisition, not a Display Case deposit or a fresh Museum rank. That run later stopped at the healing limit described above.

### Quality cycle 16: compile dynamic workers before login

[PR #65](https://github.com/sachamm/KoL/pull/65), merged as `30efc5b9ca933654d39677fc416ceca1f22fd4fa`, moves FantasyRealm's target import into its import block and verifies dynamically called workers before login. The authorized live test resumed an existing day at `deeds`, then exposed the late import through `fr quest`. The same error reproduced logged out on r29462 and r29482. The runner now requires four real successful compilation results for the main script, FantasyRealm, the diet and the pre-adventure hook before account actions.

The exact merge passed **1251 assertions**, **18 refusal/abort scenarios**, compilation/planning/static checks and **118 Windows checks**; all four installed entry points compiled on r29482. The corrected native retry passed `deeds`, then exposed the mapping interruption fixed in cycle 17. Each failed attempt ended with stable source but incomplete evidence; none is a qualifying fresh unattended day.

Scores remain **8.70/10 provisional code / 6.0/10 demonstrated live** through these assessments. The fixes restore intended behavior and provide useful partial native evidence, but do not establish a corrected unattended day, reconciled resource profit or fresh confirmed Museum ranks. **9.9 remains unachieved.**

### Quality cycle 15: deferred breakfast and stable login, score unchanged

[PR #63](https://github.com/sachamm/KoL/pull/63), merged as `3318e0f3125252f996c2b50b6bf5e2de0563b93d`, moves automatic breakfast behind the daily opening evidence. The stopped-process runner journals and temporarily disables only global/account breakfast and Git/SVN login updates, restores them after its child terminates, and recovers interrupted settings before a later login. The journal contains only selected boolean rows. All five runner modules are fingerprinted.

A native no-breakfast login reproduced `breakfastCompleted=true` from prior state. A run-only deferral marker now makes `mp.bootstrap` execute explicit breakfast after `day.open` despite that stale value. Successful command and native completion are both required to clear deferral; failure keeps breakfast unfinished. Plan mode does not set the marker. Configured login hooks other than automatic breakfast remain outside the recorded window.

The exact source merge passed **1251 assertions: 1142 ASH and 109 JavaScript**, **18 refusal/abort scenarios**, both compilations and planning/static checks. Windows tests passed **37 login + 36 evidence + 19 diagnostics + 18 ownership = 110 checks**. The eight breakfast checks also passed in isolated r29481. An authorized native information login retained stable source and unchanged observed resources, restored all selected original flags, and removed its guard journal. The newly updated garbo bundle loaded with synthetic state and actions blocked; its main was never called. Installed daily source and all five runner modules match the merge and compile while logged out.

Scores remain **8.70/10 provisional code / 6.0/10 demonstrated live**. These checks establish the observed login and dispatch boundaries, not breakfast resource output or a corrected unattended day. No resource-spending daily worker was started for this assessment. **9.9 remains unachieved.**

### Quality cycle 14: verified-cost Museum gap ordering

[PR #61](https://github.com/sachamm/KoL/pull/61), merged as `2658170c71424db052e7894a7ecd22779cb4fb38`, separates rank-pass quotes from purchases. Current verified whole-gap ceiling costs determine purchase order within top-ten and first-place tiers; missing or high historical estimates no longer exclude affordable candidates. A persistent discovery cursor rotates the bounded quote pool, and each purchase rechecks current stock and the remaining whole-gap allowance. Reports disclose the quoted coverage and do not claim a global optimum over unquoted gaps.

Museum code credit rises **0.05**, from **0.85 to 0.90**, for correcting a demonstrated purchase-selection error: the regression now selects a 20-Meat verified top-ten gap despite its 4000-Meat historical estimate, ahead of a historically cheap gap now costing 1000. Provisional code quality is **8.70/10**; demonstrated live performance stays **6.0/10**. This proves the modeled ordering and eligibility boundary, not an achieved place or the cheapest actual listing portfolio. Unknown rankings, unquoted alternatives, partial fills and fresh confirmed Museum outcomes still prevent full credit. The rubric is unchanged.

Post-merge checks on the exact source merge passed **1243 assertions: 1134 ASH and 109 JavaScript**, **18 refusal/abort scenarios**, both compilations and planning/static checks. Windows diagnostics, evidence and ownership passed **19 + 35 + 18 = 72 checks**. The 21 new ordering tests also passed in isolated r29481, including stale-price reversal, record aliasing, rank tiers beyond the former numeric offset, cursor coverage and changing whole-gap affordability. Installed public source matches the merge; `smmdaily.ash` and `smmSpend.ash` compile while logged out. No native purchase, Display Case transfer or daily worker was run. **9.9 remains unachieved.**

### Quality cycle 13: explicit garbo consumption, score unchanged

[PR #59](https://github.com/sachamm/KoL/pull/59), merged as `b861946eb366761f25873f44040bc304ece47049`, applies the existing Museum reserve to direct garbo `use`, `eat`, `drink`, `overdrink` and `chew` calls. Replacement copies pass through the verified-price and shared-budget bridge; partial fills cannot consume reserved stock. Finished items are retrieved with automatic purchase sources fenced before native consumption. Reusable metadata is read through ASH, so repeated use needs one tool. Epoch checks bracket consumption.

The exact merge passed **1222 assertions: 1113 ASH and 109 JavaScript**, including 36 new consumption checks, plus **18 refusal/abort scenarios**, both compilations and planning/static checks. Windows diagnostics, evidence and ownership passed **19 + 35 + 18 = 72 checks** after merge. The new checks also passed in isolated r29481. Synthetic action functions cover all five consumption APIs, overloads, reserve denial, missing stock, reusable tools, native failure and rollover; no native consumption was invoked. The installed public project matches the source merge, both requested compilations passed while logged out, and the entry point refused an inactive run.

Scores remain **8.65/10 provisional code / 6.0/10 demonstrated live**. This closes a specific collection-stock and implicit finished-item sourcing gap. It does not demonstrate Museum places, resource profit or an unattended day, and does not universally protect crafting ingredients, ancillary items, direct URLs or delegated workers. No additional points are awarded for synthetic assertions alone. **9.9 remains unachieved.**

### Quality cycle 12: marginal value before paid-route selection

[PR #56](https://github.com/sachamm/KoL/pull/56) applies completed-sale demand and existing stock to the IoTM route's reward estimates, rather than only reporting a stricter value after a grind. The regression changes the solver's paid-turn choice away from saturated production. Known retained Museum copies remain separate from surplus, consumed inputs keep their opportunity prices, and stock changes invalidate queued values. Batching respects both price tiers and rank milestones. Unknown demand and surplus beyond forecast capacity receive autosell value; untradeable outputs receive no unexecuted conversion proceeds. The forecast score is explicitly not realized profit or a joint liquidation portfolio.

The native information comparison found a separate ownership defect: the old snapshot omitted the active familiar's equipment. [PR #57](https://github.com/sachamm/KoL/pull/57), merged as `e24c0057b97593d1253ecd2c0be266a52a31cd4a`, corrects canonical equipped counts and includes free pulls. History version 6 excludes the older incomplete ownership bases. The exact proposed body reconciled **12,103 client-known item rows with zero mismatches** during an authorized information login. A stockpiled-item observation also confirmed valid market evidence and an autosell-only marginal surplus estimate. Character resources were unchanged within each information check; breakfast settings and temporary public code/probe files were restored. Account snapshots remain outside Git.

Final post-merge checks on `e24c0057b97593d1253ecd2c0be266a52a31cd4a` passed **1186 assertions: 1113 ASH and 73 JavaScript**, including **23 route-liquidity checks**, plus **18 refusal/abort scenarios**, both compilations and planning/static checks. Windows checks passed **19 diagnostics, 35 evidence and 18 ownership cases**. The valuation cases also passed in isolated r29481. Installed production sources match the verified code and compiled while logged out.

Paid-allocation code credit rises **0.05 to 1.20/1.5**, taking provisional code quality to **8.65/10**. This is credit for using constrained marginal values at selection time, not for the number of tests or a realized economic gain. Other criteria and the **6.0/10 live score** stay unchanged. Joint portfolio allocation, conversion bundles, market-share calibration, third-party economics and corrected unattended outcomes remain open. **9.9 is not achieved.**

### Quality cycle 11: confirmed forced-noncombat launches, score unchanged

[PR #54](https://github.com/sachamm/KoL/pull/54), merged as `4c2cf271ecffe7800e65708b211c29e9e8c17d74`, fixes a concrete scarce-resource execution defect: the spike loops could dispatch the next Rift adventure without confirming a cast and then consume more carriers after failure. Free-fight, free-kill and paid launches now require one observed use, clear their queued consult flag in `finally`, check epoch and carrier readiness, and stop before another launch/target when unconfirmed. Fiesta Exit requires the successful cast result and the observed 60-Cinch charge. The daily wrappers retain the failure as unfinished; an unowned Cincho no longer reaches the belt-equipping phase.

The exact merge passed **1163 assertions: 1090 ASH and 73 JavaScript**, including **33 launch checks**, plus **18 refusal/abort scenarios**, both compilations and planning/static checks. Windows verification passed **19 diagnostics, 35 evidence and 18 ownership checks**. The new launch cases and flag cleanup on abort/rollover also passed in isolated r29481. Both installed production files match the merge and compile while logged out. No live login, launch, target adventure or resource-spending worker was run in this cycle.

The score stays **8.60/10 provisional code / 6.0/10 demonstrated live**. Confirming a cast prevents assuming a force exists; it does not prove that the carrier was the best one, the target was eligible for that source, or the entire Rift sequence out-earned competing collection targets. Cross-worker reservations, source-specific target values and corrected unattended outcomes remain open. No strategic-allocation points are awarded for this failure-handling fix. **9.9 remains unachieved.**

### Quality cycle 10: explicit retrieval and native cleanup, score unchanged

[PR #52](https://github.com/sachamm/KoL/pull/52), merged as `0b4e9a222c31347ec3c08b7040d1a9981ee6b84a`, guards garbo's explicit `retrieveItem` calls as well as direct buys. Accessible stock is used first; missing finished copies need the existing verified price and shared allowance, within the caller's ceiling. Partial or denied fills cannot fall through to automatic sourcing. An owned transfer temporarily disables automatic purchase sources and `buyScript`, rechecks stock and epoch, and restores all five original settings even after an ASH abort through the JS bridge. A bare-native `none`-item compatibility defect was reproduced and corrected before merge.

The exact merge passed **1130 assertions: 1057 ASH and 73 JavaScript**, including 43 retrieval checks, plus **16 refusal/abort scenarios**, both compilations and planning/static checks. Windows verification passed **19 diagnostics, 35 evidence and 18 ownership checks**. The new retrieval cases, real ASH-abort fixture and blocked-action load of the installed bundle also passed in isolated r29481. Installed production files match the merge; compilation and inactive-run refusal passed while logged out.

A separately authorized information login tested the real account preferences with fake buying and transfer functions. All five settings were confirmed fenced and restored across a real ASH abort. Turns, adventures, cash, HP, MP and drunkenness were unchanged within that check; automatic breakfast was disabled and restored, and the temporary probe files were removed. This proves the observed cleanup boundary, not a full resource-spending or unattended day.

Scores remain **8.60/10 provisional code** and **6.0/10 demonstrated live**. Explicit retrieval is more constrained, but it currently holds missing unpriced/unbuyable finished items rather than safely pricing and executing their crafting paths. Implicit native sourcing, direct creation, URLs and delegated workers still need broader enforcement. No additional criterion receives points merely from more assertions or a synthetic account check. The **9.9 target remains open**.

### Quality cycle 9: direct garbo purchase enforcement

[PR #50](https://github.com/sachamm/KoL/pull/50), merged as `151fbf694c9d41ed1af98ace20b99ab3cac81dea`, adds a cooperative adapter for garbo's direct cash `buy` calls. It obtains a verified average-price ceiling, bounds quantity by the shared remaining allowance, preserves overload results and immediately books observed cash. Unknown quotes or missing allowance do not authorize a buy. An inactive account or changed epoch stops the entry point. Native coinmaster currency overloads remain separate.

Spending-rule code credit rises **0.05**, from **0.85 to 0.90**, for enforcing that direct-buy boundary before execution. Total provisional code quality is **8.60/10**. Automatic retrieval, crafting, recovery, direct URLs and delegated commands remain outside this adapter's guarantee; the post-execution audit remains required. This is not a sandbox, proof of all purchase paths or evidence of profitable spending. Every other criterion and the **6.0/10 live score** stays unchanged.

Post-merge checks on the exact merge passed **1087 assertions: 1057 ASH** (135 core, 633 gate, 25 fence, 34 income, 12 buy guard, 7 dressup, 94 diet, 62 review, 55 NPC) **and 30 JavaScript**, plus **15 refusal/abort scenarios**, both compilations and planning/static checks. Windows diagnostics, evidence and ownership passed **19 + 35 + 18 = 72 checks**. The installed garbo bundle (SHA-256 `21a6120faac275d8c8128cfaae38f5e3b20f459ec3e74116f2fd85d73142bd90`) loaded through the adapter with synthetic state and action functions blocked; its main was never called. The 42 new assertions, bundle-load check and inactive-run refusal also passed in isolated r29481. That load check establishes compatibility for the observed bundle, not live completion after upstream changes.

The live Mafia project was updated to the same source merge and compiled while logged out; its adapter correctly refused an inactive run. No live worker, login, purchase or resource use was performed in this cycle. The **9.9 target remains open**; corrected unattended days, source-derived profit and confirmed Museum progress are still required.

### Quality cycle 8: rollover boundaries, score unchanged

[PR #48](https://github.com/sachamm/KoL/pull/48), merged as `0fd610699130c997c4b0eed7392dcde4b1fda2ae`, stops a changed game epoch before another worker or a completion checkpoint, pins cached journals to their epoch and rejects old checkpoint replay. Pre-adventure and known recovery entry points check the active epoch. A deliberate fresh run can accept yesterday's stale active marker. These close a specific accounting and resource-reset defect; they cannot cancel an arbitrary third-party request already in flight or reconstruct its uncertain result. Safety remains **0.95/1**, provisional code **8.55/10** and demonstrated live **6.0/10**.

Post-merge verification on that exact merge passed **1045 ASH assertions** (135 core, 633 gate, 25 fence, 34 income, 7 dressup, 94 diet, 62 review, 55 NPC resale), **14 expected abort scenarios** (six rollover, two journal and six fence), both compilations, planning/static checks and **72 Windows checks** (19 diagnostics, 35 evidence, 18 ownership). The installed r29481 project was updated to the same merge and both `smmdaily.ash` and `smmPreAdventure.ash` compiled with an explicit logged-out marker. No live worker or resource-spending test was run.

The **9.9 target remains open**. Five corrected unattended days, reconciled source-derived economics, confirmed Museum outcomes, optimal forced-noncombat allocation and pre-purchase enforcement across third-party workers remain unproven or incomplete. Income attribution does not change the documented cash-budget policy while the user's optional policy clarification is pending.

### Quality cycle 7: post-merge evidence, score unchanged

[PR #45](https://github.com/sachamm/KoL/pull/45) adds observed cash-source windows, and [PR #46](https://github.com/sachamm/KoL/pull/46), merged as `717e7de765b04882286e30e472513705780175d7`, fixes the reproduced multiline-anchor serialization defect. The provisional code score remains **8.55/10**, with live performance **6.0/10**. Gross shop receipts and observed combat cash are useful evidence, but they do not establish old/new stock cost basis, complete resource profit or an unattended day. The documented cash-budget policy is unchanged.

Final post-merge checks passed **1043 ASH assertions** (133 core, 633 gate, 25 fence, 34 income, 7 dressup, 94 diet, 62 review, 55 NPC resale), both compilations, planning/static checks and eight expected abort scenarios. Windows checks passed **35 evidence cases, 19 diagnostics and 18 ownership checks**. Income tests cover duplicate receipts, shifting IDs, lost/late history, exact log boundaries, mirrored recovery, retained reports and long CRLF/tab serialization; reporting leaves the cash funding ledger untouched.

A read-only r29481 check parsed **3579 native shop receipts with zero unparsed entries**, preserving their 3551 normalized identities and duplicate counts. Turns, adventures, cash and MP were unchanged within that check. `smmdaily income` correctly reported today's opening snapshot missing; no retroactive baseline was created. The final fix was installed and compiled while logged out. The **9.9 target remains open**.

### Quality cycle 6: post-merge assessment

[PR #42](https://github.com/sachamm/KoL/pull/42), merged as `0a24a7d660e3741b5c2e0f1ddfd2ff40009da570`, adds **0.10** for charging diet cash to the shared cap, checking every observed request separately and refusing to claim a complete close with unknown coverage or unresolved financial issues. Provisional code quality is **8.55/10**. Third-party and early diet purchases are still audited after execution; universal pre-purchase enforcement and proof of resource-derived income remain open. Live performance stays **6.0/10**.

Post-merge checks passed **1009 ASH assertions** (133 core, 633 gate, 25 fence, 7 dressup, 94 diet, 62 review, 55 NPC resale), both compilations, planning/static checks and eight expected abort scenarios. Windows checks passed **35 evidence cases, 19 diagnostics and 18 ownership checks**. Repeated offline audits retain independent files and journal references.

The installed r29481 project was updated to this exact merge and compiled. A retrospective information-only audit covered **731 mall requests across 109/109 quoted items**, with zero unknown/unchecked items and **14,011 Meat of potential request excess**. Requests do not prove fills, and current/cache quotes do not reconstruct past prices; these are historical manual/legacy actions, not purchases by the corrected code. Turns, adventures, cash, HP and MP were unchanged across the audit; no daily worker was run. This strengthens audit evidence but does not establish a corrected unattended day. The **9.9 target remains open**.

### Quality cycle 5: post-merge assessment

[PR #40](https://github.com/sachamm/KoL/pull/40), merged as `f446fc27e3616a08c7488297d64055f2c8b47cb3`, adds **0.05** for preserving unfinished postconditions and adventure exhaustion through close reporting. Errors on repeatable close workers now prevent completion, and missing fenced stock stops before collection spending. Provisional code quality is **8.45/10**. Live performance remains **6.0/10**; a correct incomplete report is not an unattended completed day.

Post-merge verification passed **988 ASH assertions** (133 core, 612 gate, 25 fence, 7 dressup, 94 diet, 62 review, 55 NPC resale), both compilations, planning/static checks and eight expected abort scenarios. Windows verification passed **35 evidence cases, 16 diagnostics and 18 ownership checks**. Raw Witchess counters were traced to copied-monster fights; without a confirmed Set unlock they do not prove available remaining Witchess fights. The **9.9 target remains open**.

### Quality cycle 4: post-merge assessment

[PR #38](https://github.com/sachamm/KoL/pull/38), merged as `f57ce0f627e2a196a025a74eeb666dd8b190ecdc`, raises paid-turn allocation by **0.15** for demand- and backlog-limited marginal value. Provisional code quality is **8.40/10**. History and collection-loss settlement no longer assume every extra copy can sell at the average quote. Full signed inventory estimates remain diagnostic. The assumed market share and liquidation horizon still require calibration; realized sales and fresh grind samples remain missing.

The full post-merge suite passed **981 ASH assertions** (131 core, 612 gate, 22 fence, 7 dressup, 94 diet, 60 review, 55 NPC resale), both compilations, plan/static checks and eight expected journal/fence abort scenarios. Windows checks passed **35 evidence cases, 16 diagnostic cases and 18 ownership checks**. All four verified runner modules were installed with a backup. The installed Mafia project was updated to this exact merge; compilation and the live-state plan passed in r29481 with unchanged turns, adventures, cash, HP and MP before/after inspection. Automatic breakfast was disabled and restored for that login. No daily worker was run. Live performance remains **6.0/10** and the **9.9 target remains open**.

### Quality cycle 3: post-merge assessment

[PR #36](https://github.com/sachamm/KoL/pull/36), merged as `37cdee7fa027613344556c755ee3e29055674ff4`, raises scarce-resource protection by **0.05**, taking provisional code quality to **8.25/10**. Persistent write-ahead ownership now covers closet-transfer crash windows, preference loss and partial returns without taking original closet stock. Corrupt, conflicting and ambiguous records stop work; missing copies remain recorded. Forced-noncombat allocation and live economics still limit this criterion, and safety is not awarded full marks.

Post-merge checks passed **970 ASH assertions**, both compilations, plan/static checks, six expected fence abort/cleanup scenarios and both journal abort regressions. Windows checks passed **35 evidence cases, 16 diagnostic cases and 18 ownership checks**. A separately authorized information login disabled breakfast, exported account snapshots outside Git and closed without spending adventures or resources. It does not establish an unattended day. Live performance remains **6.0/10**; **9.9 is not achieved**.

### Quality cycle 2: post-merge assessment

[PR #34](https://github.com/sachamm/KoL/pull/34), merged as `64328111e8881f9604dc1cb4d9d989e0a1b13242`, advances the provisional code score by **0.05 to 8.20** for recovering completed tasks, attempts and Museum turn charges from journal checkpoints after lost preference updates. Explicit retry is durable and an unrecoverable journal gap stops work. The runner also fingerprints installed code, checks account identity and records strict run boundaries in atomic reports. These improve the evidence available for future reviews; they do not earn profitability or live-performance points. Safety remains below full marks: closet transfer bookkeeping still has a server-action-to-local-record crash window.

Post-merge verification passed **948 ASH assertions** (131 core, 612 gate, 7 dressup, 94 diet, 49 review, 55 NPC resale), both compilations, planning/static checks and both expected journal abort regressions. Windows checks passed **35 evidence cases, 14 diagnostic cases and 18 ownership checks**. The generated boundary commands also ran successfully in logged-out r29462. No live account actions were performed. Live performance stays **6.0/10**, and **9.9 remains unachieved**.

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
- A marginal liquidation model is not realized sales. Its horizon and market-share assumptions need calibration, farm history needs useful corrected samples, and one-off resource gains still need marginal attribution; 4,500 Meat/adventure remains provisional. Profitable bulk resale still depends on future sales.
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
