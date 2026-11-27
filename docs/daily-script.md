# smmdaily: the daily run

`smmdaily` runs the day as a list of tasks, in order, with a journal, no questions, and safeguards around spending, MP and garbo. It is built from [daily-script-plan.md](daily-script-plan.md). The goal it serves is in [aftercore-goals.md](aftercore-goals.md). How close it gets is scored in [daily-script-scorecard.md](daily-script-scorecard.md).

**Status (2026-11-26): November 25–26 live logs reviewed; reliability, accounting, allocation and reporting corrections implemented and tested offline. Five consecutive unattended live completions remain the acceptance milestone.**

In this milestone almost every task runs today's code, lifted block by block out of `dailyGrind()`. What is new is the engine around it. Later milestones replace the blocks one at a time.

## First use

1. `git update`, then `smmPrefs apply`. This sets the Day 0 settings below. On the development Mac, link the five new files (`smmdaily.ash`, `smmDailyCore.ash`, `smmDailyGate.ash`, `smmDailyLegacy.ash`, `smmDailyTasks.ash`) into the KoLmafia scripts directories instead.
2. `smmdaily plan` at any time. It changes nothing and shows every task, whether it would run now, and why not.
3. `smmdaily dry` walks the day without doing anything.
4. On the Windows machine only: `set smm.daily.runner = true`. On any other machine `smmdaily run` stays a dry run.
5. `smmdaily run` in place of `dailyGrind`. Since 2026-11-24 it runs the whole day: the diet, the grinds, the forced noncombats, garbo, the nightcap and `good_night`, then the close. Do not run garbo, `diet.ash` or `good_night` by hand as well.

If `smmdaily plan` prints `Returned: aggregate location [0]`, KoLmafia has no script called `smmdaily`: the files are not installed on that machine. With no script of that name it runs the command-line namespace instead and prints the value of its last line.

**Stopping a run.** KoLmafia runs one command at a time, so nothing can be set from the gCLI while a run is going: a second command waits until the run ends.

- To stop at a point you know ahead of time, `set smm.daily.halt = <task>` before the run. It stops after that task and clears itself.
- To stop right now, press Esc, as with any script. That aborts in the middle of the current task.

Either way, `smmdaily run` again carries on from where the day stopped. A task that was aborted is closed in the journal and started again from its beginning. Today's code already skips what the game says is done, as it does when you rerun `dailyGrind`. A task aborted twice in one day is marked failed and skipped. `smmdaily retry <task>` lets it run again.

## Commands

| Command | What it does |
|---|---|
| `smmdaily plan [phase\|task]` | Lists the tasks and where each stands. Changes nothing. |
| `smmdaily dry [phase\|task]` | Walks the day and prints what would run. Changes nothing. |
| `smmdaily run [phase\|task]` | Runs the day, or one phase (`preflight`, `breakfast`, `free`, `grinds`, `garbo`, `close`) or one task. |
| `smmdaily status` | The plan, the spending ledger, the fence and the run lock. |
| `smmdaily journal [n]` | Today's journal, or its last n lines. |
| `smmdaily retry <task>` | Lets a failed or finished task run again. Counters and spending are kept. |
| `smmdaily fence-status` | Reads persistent fence ownership and pending transfer counts without moving items. |
| `smmdaily income` | Reports the observed cash-source window; does not buy, sell or claim resource profit. |
| `smmdaily book` | Books today's purchases as operating spend and prints the ledger. |
| `smmdaily audit` | Books purchases, checks their prices, and lists daily resources with uses left. Before the nightcap that list still holds what the nightcap steps and `good_night` spend, so run it again after them. |
| `smmdaily unfence` | Takes fenced items back out of the closet. |
| `smmdaily settings` | Every `smm.daily.*` setting with its value and meaning. |
| `smmdaily reset` | Clears the run lock left by a crashed run. Nothing else is cleared. |

## The day

Each task has a mode: `off`, `dry` (announce it, do nothing), `legacy` (today's code) or `on` (the new code, where there is some). `set smm.daily.task.<id> = <mode>` sets one task. Otherwise the mode comes from the profile, `smm.daily.profile`:

- **`legacy`** (opt-in) is what `dailyGrind()` does today, in the same order, plus the new safeguards, followed by what used to be run by hand after it: `diet.ash` (see [diet.md](diet.md)), garbo, the nightcap steps and `good_night`.
- **`plan`** (the default) is the plan's target under its recommended decisions: garbo is the Meat engine. The Oasis and the champagne bottle are off, because garbo uses those turns and the bottle. The IoTM route runs its free actions early and its paid ones after the Museum grinds. `smmdaily` runs `garbo` itself.

| Phase | Task | What it runs | legacy | plan |
|---|---|---|---|---|
| preflight | `day.open` | Records the opening Meat, warns about settings, runs `smmPrefs apply` | on | on |
| | `store.open` | `stockStore` | legacy | legacy |
| breakfast | `mp.bootstrap` | Restores MP from free sources, then repeats breakfast if a summon failed | on | on |
| | `breakfast.second` | `secondBreakfast`, `burnHP`, `burnMP` | legacy | legacy |
| | `drip.prep` | Eats the drippy nugget and drinks the drippy wine, which give the Drip its turns, before the diet fills the organs | legacy | legacy |
| | `diet` | `call diet.ash execute yes`: the first part of the day's diet | on | on |
| free | `route` | The IoTM route. `legacy` runs all of it, `on` only its free actions | legacy | on |
| | `deeds` | `dailyDeedsAdv` | legacy | legacy |
| grinds | `fishing`, `bounty`, `science`, `nep`, `pregrind`, `dolphin`, `workshed` | As in `dailyGrind()`. `nep` also fights the free party turns left after the quest finishes (it finished on the 9th of 10 on 2026-11-24). | legacy | legacy |
| | `hold` | Stops the run after the bounty when `smm.dailyGrind.useBanishers` is `false`, or `highItem` is `false` with the champagne bottle still usable | legacy | legacy |
| | `champagne`, `oasis` | As in `dailyGrind()` | legacy | off |
| | `beerLens`, `ghostCostume`, `spacegate`, `fantasyRealm`, `pirateRealm`, `dailyDungeon`, `drip`, `gingerbread` | The Museum grinds, as in `dailyGrind()` | legacy | legacy |
| | `route.paid` | The IoTM route again, with paid turns | off | legacy |
| garbo | `forced.nc` | `grindRufusAndTheShadowRiftsForFree`: spikolodon spikes, McHugeLarge Avalanches and Fiesta Exits (resting for Cinch) at the Shadow Rift, before garbo can spend the rests and Cinch | legacy | legacy |
| | `garbo` | Fence, `garbo -N`, unfence | on | on |
| nightcap | `nightcap.before` | `beforeOverdrunkGoodNight` | legacy | legacy |
| | `diet.turngen` | `call diet.ash turngen yes` | on | on |
| | `garbo.final` | Fence, garbo down to the diet's stop point (`_smm.diet.stopAt`, all adventures when it is 0), unfence | on | on |
| | `diet.finish` | `call diet.ash finish yes`: the rest of the diet and the nightcap drink. When finish's stop point is lower than turngen's (Sweat Out Some Booze is counted only by finish), it runs garbo down to the new one and finishes again, at most twice. | on | on |
| | `goodnight.adv` | `good_night_adv`: the overdrunk turns | legacy | legacy |
| | `goodnight` | `good_night`, then the rollover check again, since its free turn generation can add adventures | legacy | legacy |
| close | `close.unfence` | Takes back anything still fenced | on | on |
| | `close.book` | Books the day's purchases | on | on |
| | `close.store`, `close.spend` | `stockStore`, `smmSpendRun` | legacy | legacy |
| | `close.report` | Grind ledger, spending ledger, price check, unused daily resources | on | on |

The `close` tasks run on every `smmdaily run`, and come after `good_night`, so the report's list of unused daily resources is the day's real one. If the nightcap is not in when the report runs, it says so first.

The nightcap tasks wait for garbo to have finished today, so with `smm.daily.task.garbo = dry` you can still run garbo by hand and then `smmdaily run` again for the rest. `goodnight.adv` and `goodnight` wait for the nightcap drink.

The existing `smm.dailyGrind.<name>` switches, the paid-turn budget and the turn-value test in [daily-spending.md](daily-spending.md) still apply to the grinds, because the tasks call the same code.

## Safeguards

**Journal and resume.** `data/smm-daily-<playerid>.txt` gets a line when a task begins and another when it ends, each with turns played, adventures, Meat and MP. A finished task does not run again that day. A task that began and never ended is closed by the next run and tried once more. After two starts without finishing it is marked failed and the day moves on without it. A grind that used turns and came back with no adventures left is not counted as finished or as failed: it runs again once there are adventures. Dated archives recover a truncated journal where possible. If lines remain missing, a `GAP` blocks further tasks until the journal is reconciled from a backup. New journal checkpoints recover completion, attempts, task errors, explicit retries and absolute Museum turn charges after lost preference updates; replay does not charge turns twice. An interrupted task still has an uncertain outcome and must use its game-state checks before repeating. Spending totals are kept in preferences, not in the journal, so a lost journal never reads as "nothing spent".

**No questions.** The new code never asks anything. The six questions today's code asks are answered ahead of time, in the shared settings and again for the length of each run. An answer of `false` to `useBanishers` or `highItem` still stops the run after the bounty, as it does in `dailyGrind()`, so the banishers and item-drop buffs can be kept for work by hand. To stop anywhere else, `set smm.daily.halt = <task>` before the run.

**MP.** The day used to stall at 0 MP after rollover. `mp.bootstrap` restores MP to `smm.daily.mpFloor` from free sources only: License to Chill when a lot is missing, bat-wing rests, nuns visits, the eternal car battery. Free rests are never used for MP. Each one refills Cinch on the Cincho de Mayo, and 60 Cinch forces a noncombat (`grindRufusAndTheShadowRiftsForFree` spends them that way before the nightcap). If KoLmafia's breakfast did not finish its summons, it is run again. Before every later task up to and including garbo, MP under `smm.daily.mpLow` is topped up the same way. Nothing is bought to restore MP. While maximum MP is under `smm.daily.mpLow` no free restore is spent at all: each gives 1,000 MP or more, and a small maximum means the outfit or an effect is the problem.

**Spending.** `close.book` reads the day's session log and counts every purchase that neither `smmSpend` nor `diet.ash` made as operating spend. Actual diet purchases also debit the shared half-net cap once, while the diet retains its own additional planning budget. Collection allowance subtracts its own spending, operating purchases and diet purchases. The close audits each mall request against its per-copy average-price ceiling; it cannot offset expensive requests with cheap ones. Its default quote limit is 150 distinct items. Unknown or unchecked quotes, potential above-cap requests, failed evidence persistence or recorded spending above the cap keep the final result incomplete. Requests can overbook failed fills, so potential violations require receipt and quote-timing review. Direct third-party spending is still audited after the fact. Only this machine's session log is read. See [daily spending](daily-spending.md).

**Income observations.** `day.open` saves mirrored cash, local-log boundary and normalized shop-receipt snapshots outside Git. The close and `smmdaily income` compare new receipts with that opening multiset, preserving duplicate sales while ignoring buyer names and unstable row numbers. A missing recent anchor, unparsed entries, an unavailable opening or a changed local-log boundary leaves coverage partial/unverified. Each report retains its own normalized evidence. The observed window begins after login; overnight/pre-opening cash, old versus newly produced stock, complete purchase costs and other transfers are not fully attributed. Gross shop receipts are not profit. The documented cash-budget policy is unchanged.

**Forced noncombats.** Free rests and Cinch belong to the forced-noncombat pool, not to garbo. `forced.nc` runs before garbo and spends the spikes, the Avalanches and every Fiesta Exit the Cinch and free rests pay for (7 with 31 free rests) at the Shadow Rift, which finishes a Rufus quest. Spikes and Avalanches are cast in a fight: free fights and free kills first, then, when those are gone, one paid Shadow Rift fight each, since the Rufus quest it finishes gives about 11 free Rift fights (`smm.forcedNC.paidTurns = false` turns the paid fights off). Fiesta Exits go first to `smm.forcedNC.targets`, when set: entries separated by `|`, best first, each `location;choice N=option;times a day`, for example `The Haunted Billiards Room;choice 875=1;1`. Each casts a Fiesta Exit and adventures there once with that choice answered; the rest go to the Rift. The Cincho de Mayo is also in the fence while garbo runs, so garbo cannot rest for Cinch or cast Projectile Piñata with it: on 2026-11-24 it spent all 31 rests and 430 Cinch that way and no Fiesta Exit was cast.

**Feel Envy** (Emotion Chip, 3 a day: the monster drops every item it has) is cast by the consult script in fights the run's own scripts start (not garbo's), on a monster whose drops still left to chance are worth at least `smm.envy.minGain` (default two turns). Each drop counts its value times the chance it would not drop anyway; pickpocket-only, conditional and unknown-rate drops are left out.

**garbo.** The `garbo` task refuses to start unless `valueOfAdventure` is between 3,500 and 10,000. It always passes an explicit negative turn count, and refuses `ascend`, `workshed=`, `quick` and a turn count in `smm.daily.garboArgs`. While garbo runs, the items in `smm.daily.fenceItems` sit in the closet. Two versioned files (`data/smm-daily-fence-<playerid>[-backup].txt`) record transfer intent before each request and confirm conserved inventory/closet changes afterwards; `smm.daily.fenced` is their compatibility cache. The finalizer attempts to return confirmed copies and restores temporary settings even if recovery fails. Missing copies stay recorded. A restart stops before workers if a transfer is pending or items remain fenced. Inspect `smmdaily fence-status`, then use `smmdaily unfence` to reconcile conserved counts; ambiguous changes require manual investigation. Neither file should be deleted to bypass a pending transfer.

**Turns.** The overdrunk nightcap steps check the rollover buffer themselves: `goodnight.adv` waits for the next run, `goodnight` still runs but leaves the adventures over the cap unspent, and `diet.finish` does not start its garbo spend-down. A task that spends turns does not start when overdrunk, within `smm.daily.rolloverBufferMin` minutes of rollover, or with `smm.daily.garboLeaveTurns` adventures or fewer left. A grind also needs enough adventures to finish, on top of those held back: 30 for a fresh FantasyRealm, 35 for PirateRealm, 20 for the Spacegate, Gingerbread City, the bounty and fishing, 15 for the Daily Dungeon and the Drip, 11 for the ghost costume and the champagne bottle, 9 for beer lenses. Today's code stops with an error when the adventures run out halfway, so a grind that cannot finish is not started. The Museum grinds share a cap of `smm.daily.museumTurns` paid turns, and leave `smm.daily.garboReserveTurns` more for garbo while the garbo task is on. Both are checked before a grind starts, not during it.

**Stops.** The run stops if a task leaves a fight or a choice open. The IoTM route counts as done only when it came back clean: if it stopped in a fight, a choice or Beaten Up, or at `smm.IR.maxActions`, the next run picks it up again.

## Settings

Run `smmdaily settings` for the full list with current values.

| Setting | Default | Meaning |
|---|---|---|
| `smm.daily.runner` | false | `true` on the one machine that runs the day. Set by hand. Never shared. |
| `smm.daily.profile` | plan | `legacy` or `plan`. |
| `smm.daily.task.<id>` | | `off`, `dry`, `legacy` or `on` for one task. |
| `smm.daily.dryRun` | false | `true` makes every run a dry run. |
| `smm.daily.museumTurns` | 100 | Paid-turn cap shared by the Museum grinds. |
| `smm.daily.garboLeaveTurns` | 10 | Adventures garbo leaves, and the fewest a turn-spending task may start with. |
| `smm.daily.garboReserveTurns` | 30 | Adventures the Museum grinds leave for garbo, on top of the line above. |
| `smm.daily.garboArgs` | | Extra arguments for garbo. |
| `smm.daily.fenceItems` | drum machine\|Special Seasoning\|inflammable leaf\|Cincho de Mayo | Items closeted (taken off first, if worn) while garbo runs. |
| `smm.daily.garboAutoConfirm` | false | `true` sets `garbo_autoUserConfirm` while smmdaily runs garbo, so garbo answers its own questions. garbo calls that option experimental; left off, a garbo question waits with no timeout. |
| `smm.daily.mpFloor` | 2000 | MP restored to after breakfast. |
| `smm.daily.mpLow` | 400 | No task starts under this while a free restore is left. |
| `smm.daily.halt` | | Set before a run: stop after this task, then clear itself. |
| `smm.daily.applyPrefs` | true | `day.open` runs `smmPrefs apply`, so settings that `git update` brought in apply the same day. `false` only checks. |

**Day 0 settings** in `data/smm-prefs.txt`, applied by `smmPrefs apply`. They affect `dailyGrind()` too:

- `smm.TurnValue = 4500`, to match `valueOfAdventure`. Unset, the old code valued a turn at 5,000.
- `smm.IR.maxPaidTurns = 100` caps the IoTM route's paid turns.
- The six prompt answers: `sea`, `useBanishers`, `highItem`, `dolphin`, `gingerbreadItems` true, `stopForBounty` false.
- `smm.dailyGrind.beerLens = false`.

## Not built yet

These are in the plan and not in this milestone:

- **Blocking a purchase before it happens.** Today's code and garbo still buy through KoLmafia's automatic buying. Their purchases are booked and price-checked afterwards.
- **New implementations of the tasks.** Only `day.open`, `mp.bootstrap`, `garbo` and the close tasks are new code.
- **Museum valuation** (the Meat price of a Museum place), liquidity values and garbo's price overrides file.
- **The planner pools** for MP, banishes, paid turns and organs. The Museum turn cap is a simple counter.
- **Free-fight adapters** for Snojo and CyberRealm, and the fixes to `burnMP` and `moodExecute` in KoLUtils.
- **Values in the audit.** It lists the daily resources with uses left, without a value or an owner for each.
- **Choosing where each forced noncombat goes on its own.** `forced.nc` aims them at the Shadow Rift unless `smm.forcedNC.targets` names better ones (see Forced noncombats); nothing picks a target by itself yet.

Known limits of what is built:

- A grind that takes more adventures than are left is held back and says so, and `smmdaily run` picks it up later.
- "No questions": the six `dailyGrind` prompts are answered ahead of time, and during a run (`smm.daily.active` set) the questions the run can reach in the shared scripts (the magical sausage for MP, the smut orc camp, a target with no dressup) take their default answer at once instead of waiting a minute. The rest (`gbc win`'s buff cost, cancelling a platinum Guzzlr location, the Dreadsylvania gear checks, wishing for a monster) are in code no task runs. garbo can still ask its own, unless `smm.daily.garboAutoConfirm` is true.
- ASH cannot catch an `abort()`. When today's code aborts, the run stops there. `smmdaily run` picks the day up.
- The fence keeps garbo from using what is in the closet. It cannot stop garbo buying more of the same item.
- In the `plan` profile the free route skips the Sword seed and Lucky! adventures, which cost one turn each. `route.paid` picks them up later.

## November 26 operational corrections

- The default profile is **plan**. An explicitly chosen profile is respected. It leaves Oasis and champagne adventures to garbo. Explicit task overrides still apply. Keep both adventure values at the provisional 4,500 until ordinary farming samples support a change; whole-day loot estimates and short-run NaNs are not calibration data.
- Combat preparation runs after dressing in the automation/redirection path and in `smmPreAdventure`. It uses free MP recovery and HP skills, preserving campsite rests. Overdrunk fights can buy fresh Doc Galaktik tonic at no more than a verified average price, within both `smm.daily.combatMpBudget` (5,000 Meat/day; 0 disables purchases) and the spending allowance. The consult checks rocket inventory and uses an affordable spell plan while overdrunk. It stops safely if none exists.
- `goodnight.adv` now runs the route pass, followed by separately journaled `goodnight.adv.fax`, `goodnight.adv.spinner`, `goodnight.adv.locket`, `goodnight.adv.daycare` and `goodnight.adv.excess`. Selecting the old group name selects its children; retrying a child affects only that child. An old completed parent does not mark the new children complete; their workers check actual usage counters.
- A collection exemption requires a **named unbuyable output, known cached rank gap and funded adventures**. Defaults name the ghost costume, Spacegate Research, selected FantasyRealm reward, Red Roger's reliquary and fat loot token. `smm.dailyGrind.target.<name>` overrides the item; `smm.dailyGrind.targetTurns.<name>` overrides its maximum funded paid adventures. Unknown ranks and incidental untradeable drops grant no exemption. Readiness does not fetch missing ranks.
- `smm.dailyGrind.collectionLossBudget` defaults to 450,000 Meat of forgone farming income. A collection task reserves its maximum turn cost before starting, checks remaining paid turns before the next automated fight, and settles against observed results. Interrupted work retains its reservation and original start. External/manual turns during an interruption are conservatively charged. Third-party actions bypassing both automation and the configured pre-adventure hook cannot be intercepted.
- Grind history migrates to version 3. Physical snapshots include inventory, closet, storage, shop, all equipment slots and inactive familiar equipment. Signed changes charge consumed owned inputs at opportunity value. Reusable returns are excluded unless an observed native drop establishes production. Session transactions distinguish purchase requests and acquisitions. Per-item evidence is written to `data/smm-grind-<player>-<date>-<grind>-<starting-turn>.txt`. The report separates native retained loot estimates from the complete signed inventory estimate. Neither is realized sales.
- The close report compares actual case counts with the saved opening counts. It prints confirmed added copies and threshold crossings against cached competitor rankings, without claiming fresh ranks. Resource rows include an owner and used, blocked, deliberately retained, unspent or missed outcomes. A Party attempt without counter advancement is recorded as blocked.
- A nightcap and successful garbo are insufficient for completion. Required nightcap children and `goodnight` must finish, and enabled failed tasks keep the result incomplete. Only the end of a successful closing report prints `SMM_DAILY_RESULT COMPLETE`. A run clears its previous completion marker first.
- `tools/Invoke-KolDaily.ps1` is the versioned Windows runner. Install `KolDailyDiagnostics.ps1`, `KolDailyOwnership.ps1`, `KolDailyEvidence.ps1` and `KolDailyLogin.ps1` beside any copied runner. Diagnostics ignore macro definitions but retain actual macro failures; a live run requires the explicit completion marker. The runner holds exclusive root/account leases before process handling, refuses an unknown Mafia process, and checks that the requested account actually logged in.
- Before login, the runner compiles `smmdaily.ash`, `fr.ash`, `diet.ash` and `smmPreAdventure.ash` using the selected jar. FantasyRealm is called dynamically and is not compiled by verifying the main import graph alone. Four real verification-complete lines and a successful non-timeout process are required; incomplete compilation stops before account actions. `compileCheck` in the status JSON records the result.
- While Mafia is stopped, the runner borrows four automatic-login flags: global/account breakfast and Git/SVN login updates. A journal in `runlogs/daily/login-settings.json` stores only their original presence and boolean rows, never other settings or credentials. Settings are replaced atomically, restored only after the owned child terminates, and recovered before a subsequent run after a crash. Unrelated settings written by Mafia are retained. Corrupt recovery evidence stops login. Automatic breakfast is deferred to `mp.bootstrap`, after `day.open` records cash, receipts and case counts; a run-only deferral marker overrides a stale `breakfastCompleted` value. Failed or unconfirmed breakfast stays unfinished. Explicit breakfast performs its full actions in the [installed Mafia build](https://github.com/kolmafia/kolmafia/blob/a40009d/src/main/java/net/sourceforge/kolmafia/textui/command/BreakfastCommand.java).
- Each run has a unique ID, atomic dated status and an evidence JSON beside its log. Before login and after execution, the runner fingerprints installed ASH/JS scripts, relay code, six shipped policy tables, all five runner modules and the jar. Settings, saved passwords, sessions and other account data are excluded from that manifest. Matching game date, ascension, player and turn counters bracket one completion marker. Source changes, missing or contradictory markers, nonzero exit and failed diagnostics invalidate the review candidate. The window begins after login; other configured login hooks, manual intervention, resource reconciliation, actual earnings and Museum ranks still need separate evidence. `-Mode Plan` disables automatic breakfast and updates but still logs in and can run other configured login hooks; use the existing session for read-only inspection.
- Runner checks: `tests/kol-daily-diagnostics-tests.ps1`, `tests/kol-daily-ownership-tests.ps1`, `tests/kol-daily-evidence-tests.ps1` and `tests/kol-daily-login-tests.ps1`. These use fixtures and fake process APIs, without logging into an account.

The added `smmDailyReviewTest` covers combat policies, signed item changes, transaction classification, price ceilings, child selection, incomplete days and collection budgets. Offline success does not establish live unattended completion or market liquidity.

## Implementation files

| File | Contents |
|---|---|
| `scripts/smmdaily.ash` | The command. |
| `scripts/smmDailyCore.ash` | Settings, day key, journal, task engine. No imports, no game actions. |
| `scripts/smmDailyGate.ash` | Booking and price check, free MP. |
| `scripts/smmDailyFence.ash` | Persistent fence ownership, transfer intent and recovery. |
| `scripts/smmDailyLegacy.ash` | Today's code, one function per task. |
| `scripts/smmDailyTasks.ash` | The new tasks, the audit table, and the day's task list. |
| `scripts/smmSpend.ash` | Gained the operating-spend figure in the budget. |

## Tests

`tests/smmdaily-tests.sh` runs a logged-out KoLmafia r29462 in `tests/.runtime` (downloaded on first use). Nothing logs in. It checks that:

- `smmdaily.ash` and everything it imports compiles;
- the engine behaves: modes and profiles, run once and resume, not-ready and failed tasks, halt, dry runs, the turn limits, the journal round trip, a lost journal and an interrupted task (`tests/ash/smmDailyCoreTest.ash`);
- the arithmetic is right: the Fiesta Exits the Cinch and free rests pay for, the grind loot valued at its sale price, the last garbo run's command, the allowance, the session-log parser, operating spend, overpayment, the fence record, garbo's arguments, the audit table and the task list (`tests/ash/smmDailyGateTest.ash`);
- `smmdaily plan` prints the whole day logged out;
- the new files never call `user_confirm`;
- every function a task names exists, and every KoLmafia preference the new files read exists in r29462;
- the Day 0 settings are in `data/smm-prefs.txt` and `smm.daily.runner` is not.
- `diet.ash` compiles, plans a day logged out, keeps its price rule, budget and adventure bounds (`tests/ash/smmDietTest.ash`), and has the same default budget as `smmDailyGate.ash`.
- NPC resale respects the fourteen-day demand window, one-year stock ceiling, remaining spending budget, jelly versus pants-only profit, exact vendor rows and receipt checks, and reconciles the NPC log's pants-only charge (`tests/ash/smmNpcResaleTest.ash`). See [daily-spending.md](daily-spending.md#npc-resale-batches).

The tests cannot log in, so nothing that touches the game is exercised by them: the free MP restores, the fence moves, garbo and every legacy task are untested until the first live run. Start with `smmdaily plan` and `smmdaily dry`.
