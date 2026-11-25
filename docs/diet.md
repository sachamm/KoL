# The diet: `diet.ash`

`diet.ash` plans the whole day's food, booze, spleen and other turn generation from live KoLmafia data, then buys and consumes it in four phases. `smmdaily` runs it (see [daily-script.md](daily-script.md)); by hand it is `call diet.ash [execute | turngen | finish] [options]`. The options, the phases and the stop point are described at the top of `scripts/smmDiet.ash`.

It replaced `scripts/diet.js` on 2026-11-25. The commands, options, preferences (`smm.diet.budget`, `_smm.diet.spent`, `_smm.diet.bought`, `_smm.diet.stopAt`) and printed plan are the same.

## Files

- `scripts/diet.ash`: the command.
- `scripts/smmDiet.ash`: the KoLmafia layer. It reads organs, skills, gear, daily counters, prices and Museum spare copies, splits the plan into phases around the rollover cap, applies the price rule and the diet's budget (see [daily-spending.md](daily-spending.md#the-diets-purchases)), and buys and consumes the plan.
- `scripts/smmDietOptimizer.ash`: the optimizer.

## Credit

The optimizer is an ASH port of the diet calculator by **tehtmi** at [lethe.xyz/kol/diets.php](https://www.lethe.xyz/kol/diets.php), which in turn credits **Eleron** and **houeland** for earlier work. `diet.js` carried the same code in JavaScript from 2023. Local changes are marked `smm:` in the file. [LICENSING.md](../LICENSING.md) records the open question about permission to redistribute it.

## Changes from diet.js

- Ode to Booze's adventures count only when you have the skill.
- The executor stops when a helper (a fork, mug or pill used just before its food or drink) fails to be used.
- The drink planned for the mime army shotglass is drunk before the other booze.
- The price check before buying also covers the potion of the field gar and pocket wishes the plan relies on.
- Museum spare copies and the smmUtils figures (rollover gain, good_night_adv turns, overdrunk sinks) are read by importing the ASH files. diet.js asked for them through the gCLI.
- A beer nuts plan that diet.js crashed on is skipped instead.

PR #19's independent planner was not used. It never ran in game, did not have the stop point or budget work from PRs #13, #25 and #26, and its search would be slow in ASH. The first four items above come from it.

## Checks

- Before diet.js was removed, both optimizers were run on the same 37 random catalogs built from KoLmafia's item data, with random prices, organs, skills and helpers. Six were full size, about 1,400 items. diet.js crashed on one full-size catalog (the beer nuts case above). On the other 36 the plans matched exactly. In ASH a full-size plan takes about 0.5 to 1.5 seconds; diet.js took 30 to 100 ms.
- `tests/ash/smmDietTest.ash` (run by `tests/smmdaily-tests.sh`) covers the price rule, the buying cap, sausages, the budget and owned-only plans, every paid resource in the cost estimate, the adventure bounds behind the stop point, the phase split and the options. The suite also plans a day logged out and checks that the default budget matches `smmDailyGate.ash`.

None of this has run in game yet.

On a machine whose `scripts/` folder still has an old `diet.js` next to `diet.ash`, type `call diet.ash`. A bare `diet` is ambiguous there. smmdaily always uses `call diet.ash`.
