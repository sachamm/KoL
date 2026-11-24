# smmdaily: the daily run

`smmdaily` runs the day as a list of tasks, in order, with a journal, no questions, and safeguards around spending, MP and garbo. It is built from [daily-script-plan.md](daily-script-plan.md). The goal it serves is in [aftercore-goals.md](aftercore-goals.md).

**Status: first milestone (the plan's stages A and B). It has not yet been run in the game.** It compiles in KoLmafia r29462 and passes its offline tests, which run logged out. Today's `dailyGrind()` still works and is unchanged. Use one or the other on a given day, not both: `smmdaily` skips what the game says is done, but `dailyGrind()` does not know what `smmdaily` did.

In this milestone almost every task runs today's code, lifted block by block out of `dailyGrind()`. What is new is the engine around it. Later milestones replace the blocks one at a time.

## First use

1. `git update`, then `smmPrefs apply`. This sets the Day 0 settings below.
2. `smmdaily plan` at any time. It changes nothing and shows every task, whether it would run now, and why not.
3. `smmdaily dry` walks the day without doing anything.
4. On the Windows machine only: `set smm.daily.runner = true`. On any other machine `smmdaily run` stays a dry run.
5. `smmdaily run` in place of `dailyGrind`. Then run garbo, the nightcap and `good_night` as you do now.

To stop a run cleanly, `set smm.daily.interrupt = true` from another gCLI tab: it stops before the next task. Running `smmdaily run` again carries on from where the day stopped.

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
| `smmdaily audit` | Books purchases, checks their prices, and lists daily resources with uses left. |
| `smmdaily unfence` | Takes fenced items back out of the closet. |
| `smmdaily settings` | Every `smm.daily.*` setting with its value and meaning. |
| `smmdaily reset` | Clears the run lock left by a crashed run. Nothing else is cleared. |

## The day

Each task has a mode: `off`, `dry` (announce it, do nothing), `legacy` (today's code) or `on` (the new code, where there is some). `set smm.daily.task.<id> = <mode>` sets one task. Otherwise the mode comes from the profile, `smm.daily.profile`:

- **`legacy`** (the default) is what `dailyGrind()` does today, in the same order, plus the new safeguards. garbo is announced and not run, so you run it yourself as now.
- **`plan`** is the plan's target under its recommended decisions: garbo is the Meat engine. The Oasis and the champagne bottle are off, because garbo uses those turns and the bottle. The IoTM route runs its free actions early and its paid ones after the Museum grinds. `smmdaily` runs `garbo` itself.

| Phase | Task | What it runs | legacy | plan |
|---|---|---|---|---|
| preflight | `day.open` | Records the opening Meat, warns about settings, runs `smmPrefs check` | on | on |
| | `store.open` | `stockStore` | legacy | legacy |
| breakfast | `mp.bootstrap` | Restores MP from free sources, then repeats breakfast if a summon failed | on | on |
| | `breakfast.second` | `secondBreakfast`, `burnHP`, `burnMP` | legacy | legacy |
| free | `route` | The IoTM route. `legacy` runs all of it, `on` only its free actions | legacy | on |
| | `deeds` | `dailyDeedsAdv` | legacy | legacy |
| grinds | `fishing`, `bounty`, `science`, `nep`, `pregrind`, `dolphin`, `workshed` | As in `dailyGrind()` | legacy | legacy |
| | `champagne`, `oasis` | As in `dailyGrind()` | legacy | off |
| | `beerLens`, `ghostCostume`, `spacegate`, `fantasyRealm`, `pirateRealm`, `dailyDungeon`, `drip`, `gingerbread` | The Museum grinds, as in `dailyGrind()` | legacy | legacy |
| | `route.paid` | The IoTM route again, with paid turns | off | legacy |
| garbo | `garbo` | Fence, `garbo -N`, unfence | dry | on |
| close | `close.unfence` | Takes back anything still fenced | on | on |
| | `close.book` | Books the day's purchases | on | on |
| | `close.store`, `close.spend` | `stockStore`, `smmSpendRun` | legacy | legacy |
| | `close.report` | Grind ledger, spending ledger, price check, unused daily resources | on | on |

The `close` tasks run on every `smmdaily run`, so `smmdaily run close` after garbo brings the books up to date.

The existing `smm.dailyGrind.<name>` switches, the paid-turn budget and the turn-value test in [daily-spending.md](daily-spending.md) still apply to the grinds, because the tasks call the same code.

## Safeguards

**Journal and resume.** `data/smm-daily-<playerid>.txt` gets a line when a task begins and another when it ends, each with turns played, adventures, Meat and MP. A finished task does not run again that day. A task that began and never ended is closed by the next run and tried once more. After two starts without finishing it is marked failed and the day moves on without it. If journal lines go missing, a `GAP` line says so. Spending totals are kept in preferences, not in the journal, so a lost journal never reads as "nothing spent".

**No questions.** The new code never asks anything. The six questions today's code asks are answered ahead of time, in the shared settings and again for the length of each run. To stop at a point, `set smm.daily.halt = <task>` stops the run after that task.

**MP.** The day used to stall at 0 MP after rollover. `mp.bootstrap` restores MP to `smm.daily.mpFloor` from free sources only: License to Chill when a lot is missing, bat-wing rests, nuns visits, free rests, the eternal car battery. If KoLmafia's breakfast did not finish its summons, it is run again. Before every later task up to and including garbo, MP under `smm.daily.mpLow` is topped up the same way. Nothing is bought to restore MP.

**Spending.** `close.book` reads the day's session log and counts every purchase `smmSpend` did not make as operating spend. `smmSpendRun` then allows half of the day's net, less its own purchases, less the operating spend. The report checks the day's biggest mall purchases against their average sale price and prints what was paid above it. The line in the log is the purchase request, so the total can run slightly high, never low. Only the log on the machine you are playing on is read.

**garbo.** The `garbo` task refuses to start unless `valueOfAdventure` is between 3,500 and 10,000. It always passes an explicit negative turn count, and refuses `ascend`, `workshed=`, `quick` and a turn count in `smm.daily.garboArgs`. While garbo runs, the items in `smm.daily.fenceItems` sit in the closet, recorded in `smm.daily.fenced`, and come back out afterwards even if garbo aborts.

**Turns.** A task that spends turns does not start when overdrunk, within `smm.daily.rolloverBufferMin` minutes of rollover, or with `smm.daily.garboLeaveTurns` adventures or fewer left. The Museum grinds share a cap of `smm.daily.museumTurns` paid turns, and leave `smm.daily.garboReserveTurns` more for garbo while the garbo task is on. Both are checked before a grind starts, not during it.

**Stops.** The run stops if a task leaves a fight or a choice open.

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
| `smm.daily.fenceItems` | drum machine\|Special Seasoning\|inflammable leaf | Items closeted while garbo runs. |
| `smm.daily.mpFloor` | 2000 | MP restored to after breakfast. |
| `smm.daily.mpLow` | 400 | No task starts under this while a free restore is left. |
| `smm.daily.halt` | | Stop after this task. |
| `smm.daily.interrupt` | false | `true` stops before the next task, then clears itself. |

**Day 0 settings** in `data/smm-prefs.txt`, applied by `smmPrefs apply`. They affect `dailyGrind()` too:

- `smm.TurnValue = 4500`, to match `valueOfAdventure`. Unset, the old code valued a turn at 5,000.
- `smm.IR.maxPaidTurns = 100` caps the IoTM route's paid turns.
- The six prompt answers: `sea`, `useBanishers`, `highItem`, `dolphin`, `gingerbreadItems` true, `stopForBounty` false.
- `smm.dailyGrind.beerLens = false`.

## Not built yet

These are in the plan and not in this milestone:

- **Blocking a purchase before it happens.** Today's code and garbo still buy through KoLmafia's automatic buying. Their purchases are booked and price-checked afterwards.
- **The nightcap and the end of the day.** `diet.js`, `good_night_adv` and `good_night` are still run by hand.
- **New implementations of the tasks.** Only `day.open`, `mp.bootstrap`, `garbo` and the close tasks are new code.
- **Museum valuation** (the Meat price of a Museum place), liquidity values and garbo's price overrides file.
- **The planner pools** for MP, banishes, paid turns and organs. The Museum turn cap is a simple counter.
- **Free-fight adapters** for Snojo and CyberRealm, and the fixes to `burnMP` and `moodExecute` in KoLUtils.
- **Values in the audit.** It lists the daily resources with uses left, without a value or an owner for each.

Known limits of what is built:

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
- the engine behaves: modes and profiles, run once and resume, not-ready and failed tasks, halt and interrupt, dry runs, the turn limits, the journal round trip, a lost journal and an interrupted task (`tests/ash/smmDailyCoreTest.ash`);
- the arithmetic is right: the allowance, the session-log parser, operating spend, overpayment, the fence record, garbo's arguments, the audit table and the task list (`tests/ash/smmDailyGateTest.ash`);
- `smmdaily plan` prints the whole day logged out;
- the new files never call `user_confirm`;
- every function a task names exists, and every KoLmafia preference the new files read exists in r29462;
- the Day 0 settings are in `data/smm-prefs.txt` and `smm.daily.runner` is not.

The tests cannot log in, so nothing that touches the game is exercised by them: the free MP restores, the fence moves, garbo and every legacy task are untested until the first live run. Start with `smmdaily plan` and `smmdaily dry`.
