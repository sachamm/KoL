# smmdaily: the daily run

`smmdaily` runs the day as a list of tasks, in order, with a journal, no questions, and safeguards around spending, MP and garbo. It is built from [daily-script-plan.md](daily-script-plan.md). The goal it serves is in [aftercore-goals.md](aftercore-goals.md). How close it gets is scored in [daily-script-scorecard.md](daily-script-scorecard.md).

**Status: first milestone (the plan's stages A and B), run in the game on 2026-11-24, plus the whole-day changes made after that run (diet, forced noncombats, garbo, the nightcap and `good_night` in the run), which have not yet been run in the game.** It compiles in KoLmafia r29462 and passes its offline tests, which run logged out. Today's `dailyGrind()` still works and is unchanged. Use one or the other on a given day, not both: `smmdaily` skips what the game says is done, but `dailyGrind()` does not know what `smmdaily` did.

In this milestone almost every task runs today's code, lifted block by block out of `dailyGrind()`. What is new is the engine around it. Later milestones replace the blocks one at a time.

## First use

1. `git update`, then `smmPrefs apply`. This sets the Day 0 settings below. On the development Mac, link the five new files (`smmdaily.ash`, `smmDailyCore.ash`, `smmDailyGate.ash`, `smmDailyLegacy.ash`, `smmDailyTasks.ash`) into the KoLmafia scripts directories instead.
2. `smmdaily plan` at any time. It changes nothing and shows every task, whether it would run now, and why not.
3. `smmdaily dry` walks the day without doing anything.
4. On the Windows machine only: `set smm.daily.runner = true`. On any other machine `smmdaily run` stays a dry run.
5. `smmdaily run` in place of `dailyGrind`. Since 2026-11-24 it runs the whole day: the diet, the grinds, the forced noncombats, garbo, the nightcap and `good_night`, then the close. Do not run garbo, `diet.js` or `good_night` by hand as well.

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
| `smmdaily book` | Books today's purchases as operating spend and prints the ledger. |
| `smmdaily audit` | Books purchases, checks their prices, and lists daily resources with uses left. Before the nightcap that list still holds what the nightcap steps and `good_night` spend, so run it again after them. |
| `smmdaily unfence` | Takes fenced items back out of the closet. |
| `smmdaily settings` | Every `smm.daily.*` setting with its value and meaning. |
| `smmdaily reset` | Clears the run lock left by a crashed run. Nothing else is cleared. |

## The day

Each task has a mode: `off`, `dry` (announce it, do nothing), `legacy` (today's code) or `on` (the new code, where there is some). `set smm.daily.task.<id> = <mode>` sets one task. Otherwise the mode comes from the profile, `smm.daily.profile`:

- **`legacy`** (the default) is what `dailyGrind()` does today, in the same order, plus the new safeguards, followed by what used to be run by hand after it: `diet.js`, garbo, the nightcap steps and `good_night`.
- **`plan`** is the plan's target under its recommended decisions: garbo is the Meat engine. The Oasis and the champagne bottle are off, because garbo uses those turns and the bottle. The IoTM route runs its free actions early and its paid ones after the Museum grinds. `smmdaily` runs `garbo` itself.

| Phase | Task | What it runs | legacy | plan |
|---|---|---|---|---|
| preflight | `day.open` | Records the opening Meat, warns about settings, runs `smmPrefs apply` | on | on |
| | `store.open` | `stockStore` | legacy | legacy |
| breakfast | `mp.bootstrap` | Restores MP from free sources, then repeats breakfast if a summon failed | on | on |
| | `breakfast.second` | `secondBreakfast`, `burnHP`, `burnMP` | legacy | legacy |
| | `drip.prep` | Eats the drippy nugget and drinks the drippy wine, which give the Drip its turns, before the diet fills the organs | legacy | legacy |
| | `diet` | `call diet.js execute yes`: the first part of the day's diet | on | on |
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
| | `diet.turngen` | `call diet.js turngen yes` | on | on |
| | `garbo.final` | Fence, garbo down to the diet's stop point (`_smm.diet.stopAt`, all adventures when it is 0), unfence | on | on |
| | `diet.finish` | `call diet.js finish yes`: the rest of the diet and the nightcap drink. When finish's stop point is lower than turngen's (Sweat Out Some Booze is counted only by finish), it runs garbo down to the new one and finishes again, at most twice. | on | on |
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

**Journal and resume.** `data/smm-daily-<playerid>.txt` gets a line when a task begins and another when it ends, each with turns played, adventures, Meat and MP. A finished task does not run again that day. A task that began and never ended is closed by the next run and tried once more. After two starts without finishing it is marked failed and the day moves on without it. A grind that used turns and came back with no adventures left is not counted as finished or as failed: it runs again once there are adventures. If journal lines go missing, a `GAP` line says so. Spending totals are kept in preferences, not in the journal, so a lost journal never reads as "nothing spent".

**No questions.** The new code never asks anything. The six questions today's code asks are answered ahead of time, in the shared settings and again for the length of each run. An answer of `false` to `useBanishers` or `highItem` still stops the run after the bounty, as it does in `dailyGrind()`, so the banishers and item-drop buffs can be kept for work by hand. To stop anywhere else, `set smm.daily.halt = <task>` before the run.

**MP.** The day used to stall at 0 MP after rollover. `mp.bootstrap` restores MP to `smm.daily.mpFloor` from free sources only: License to Chill when a lot is missing, bat-wing rests, nuns visits, the eternal car battery. Free rests are never used for MP. Each one refills Cinch on the Cincho de Mayo, and 60 Cinch forces a noncombat (`grindRufusAndTheShadowRiftsForFree` spends them that way before the nightcap). If KoLmafia's breakfast did not finish its summons, it is run again. Before every later task up to and including garbo, MP under `smm.daily.mpLow` is topped up the same way. Nothing is bought to restore MP. While maximum MP is under `smm.daily.mpLow` no free restore is spent at all: each gives 1,000 MP or more, and a small maximum means the outfit or an effect is the problem.

**Spending.** `close.book` reads the day's session log and counts every purchase that neither `smmSpend` nor `diet.js` made as operating spend. The diet has a budget of its own, `smm.diet.budget` (see [daily-spending.md](daily-spending.md#the-diets-purchases)). `smmSpendRun` then allows half of the day's net, less its own purchases, less the operating spend. The report checks the day's biggest mall purchases against their average sale price and prints what was paid above it. The line in the log is the purchase request, so the total can run slightly high, never low. Only the log on the machine you are playing on is read.

**Forced noncombats.** Free rests and Cinch belong to the forced-noncombat pool, not to garbo. `forced.nc` runs before garbo and spends the spikes, the Avalanches and every Fiesta Exit the Cinch and free rests pay for (7 with 31 free rests) at the Shadow Rift, which finishes a Rufus quest. Spikes and Avalanches are cast in a fight: free fights and free kills first, then, when those are gone, one paid Shadow Rift fight each, since the Rufus quest it finishes gives about 11 free Rift fights (`smm.forcedNC.paidTurns = false` turns the paid fights off). Fiesta Exits go first to `smm.forcedNC.targets`, when set: entries separated by `|`, best first, each `location;choice N=option;times a day`, for example `The Haunted Billiards Room;choice 875=1;1`. Each casts a Fiesta Exit and adventures there once with that choice answered; the rest go to the Rift. The Cincho de Mayo is also in the fence while garbo runs, so garbo cannot rest for Cinch or cast Projectile Piñata with it: on 2026-11-24 it spent all 31 rests and 430 Cinch that way and no Fiesta Exit was cast.

**Feel Envy** (Emotion Chip, 3 a day: the monster drops every item it has) is cast by the consult script in fights the run's own scripts start (not garbo's), on a monster whose drops still left to chance are worth at least `smm.envy.minGain` (default two turns). Each drop counts its value times the chance it would not drop anyway; pickpocket-only, conditional and unknown-rate drops are left out.

**garbo.** The `garbo` task refuses to start unless `valueOfAdventure` is between 3,500 and 10,000. It always passes an explicit negative turn count, and refuses `ascend`, `workshed=`, `quick` and a turn count in `smm.daily.garboArgs`. While garbo runs, the items in `smm.daily.fenceItems` sit in the closet, recorded in `smm.daily.fenced`, and come back out afterwards even if garbo aborts.

**Turns.** The overdrunk nightcap steps check the rollover buffer themselves: `goodnight.adv` waits for the next run, `goodnight` still runs but leaves the adventures over the cap unspent, and `diet.finish` does not start its garbo spend-down. A task that spends turns does not start when overdrunk, within `smm.daily.rolloverBufferMin` minutes of rollover, or with `smm.daily.garboLeaveTurns` adventures or fewer left. A grind also needs enough adventures to finish, on top of those held back: 30 for a fresh FantasyRealm, 35 for PirateRealm, 20 for the Spacegate, Gingerbread City, the bounty and fishing, 15 for the Daily Dungeon and the Drip, 11 for the ghost costume and the champagne bottle, 9 for beer lenses. Today's code stops with an error when the adventures run out halfway, so a grind that cannot finish is not started. The Museum grinds share a cap of `smm.daily.museumTurns` paid turns, and leave `smm.daily.garboReserveTurns` more for garbo while the garbo task is on. Both are checked before a grind starts, not during it.

**Stops.** The run stops if a task leaves a fight or a choice open. The IoTM route counts as done only when it came back clean: if it stopped in a fight, a choice or Beaten Up, or at `smm.IR.maxActions`, the next run picks it up again.

## Settings

Run `smmdaily settings` for the full list with current values.

| Setting | Default | Meaning |
|---|---|---|
| `smm.daily.runner` | false | `true` on the one machine that runs the day. Set by hand. Never shared. |
| `smm.daily.profile` | legacy | `legacy` or `plan`. |
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

## Files

| File | Contents |
|---|---|
| `scripts/smmdaily.ash` | The command. |
| `scripts/smmDailyCore.ash` | Settings, day key, journal, task engine. No imports, no game actions. |
| `scripts/smmDailyGate.ash` | Booking and price check, free MP, the fence. |
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
- when node is installed, `diet.js` keeps its price rule and budget (`tests/diet-spending.cjs`) and its adventure bounds (`tests/nightcap-adventure-bounds.cjs`).

The tests cannot log in, so nothing that touches the game is exercised by them: the free MP restores, the fence moves, garbo and every legacy task are untested until the first live run. Start with `smmdaily plan` and `smmdaily dry`.
