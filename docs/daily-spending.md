# Daily spending and grind controls

This is how `dailyGrind()` applies the spending rules in the aftercore goals: Meat goes first to purchases with a positive return, then to items on sale, biggest discount first; at most half of the day's net Meat is spent; nothing is bought above the market price; and "cheap" means 20% or more under the market price. The market price is the item's recent average sale price, read from Pricegun, not the current lowest mall listing.

The code is in `scripts/smmSpend.ash`. **It has not yet been run in KoLmafia.** Set `smm.spend.dryRun = true` for the first day to see what it would buy.

## The day's ledger

`dailyGrind()` and `dailyNoAdventureGrind()` record the opening Meat (on hand, closet and storage) the first time they run each day. The day's net is the Meat held now, minus that opening figure, with this script's own purchases added back. The budget is half of the net, less what has already been spent, and never more than the Meat on hand. A day that loses Meat has a budget of zero.

Only Meat is counted. Items gained are not valued, and Meat earned before the first `dailyGrind()` call of the day (overnight shop sales, for example) is in the opening figure, not the net.

## The spending step

`smmSpendRun()` runs at the end of `dailyGrind()` and again at the start of `good_night()`. It can run any number of times: each run spends only what the budget still allows.

1. **Positive return.** Reads `data/unrestricted_buy_map.txt` (item, what one copy is worth, how many to keep on hand). It buys an item when the mall price is under that worth, never paying more than the average sale price, best return per Meat first. When Pricegun has no sales for an item it pays no more than the current listing.
2. **Display Case items on sale.** Considers tradeable items that have a stored Museum ranking and are short of first place, items short of the top ten first. An item qualifies when its mall price is 20% or more under its average sale price. It buys the biggest discount first, pays at most 80% of the average, and adds the copies to the Display Case.

Price lookups are capped per pass per run. The second pass remembers where it stopped and continues from there the next day, so the whole list is covered over several days. The step makes no Museum requests; run `dc refresh` to store more rankings.

This replaces the old trigger in `secondBreakfast()` that ran `buyMallSpecials()` whenever total Meat was over 100,000,000.

| Setting | Default | Meaning |
|---|---|---|
| `smm.spend.enabled` | true | `false` turns the step off. |
| `smm.spend.dryRun` | false | `true` prints what would be bought and buys nothing. |
| `smm.spend.fraction` | 0.5 | Share of the day's net that may be spent. Capped at 0.5. |
| `smm.spend.minDiscount` | 0.2 | Discount that counts as a sale. Never under 0.2. |
| `smm.spend.maxLookups` | 60 | Items priced per pass per run. |

## Grind controls

The paid-turn grinds that follow the IoTM route are `oasis`, `beerLens`, `ghostCostume`, `spacegate`, `fantasyRealm`, `pirateRealm`, `dailyDungeon`, `drip` and `gingerbread`.

- `smm.dailyGrind.<name> = false` skips that grind.
- `smm.dailyGrind.maxPaidTurns` is an optional daily turn budget shared by all of them. Once it is used up, the rest are skipped. Unset means no limit. It is separate from the route's own `smm.IR.maxPaidTurns`, which is also uncapped unless set.
- Each grind's turns and Meat change are logged for the day and printed at the end of the run, with Meat per turn. Items are not valued in that figure.

Not done yet: these grinds are still not compared with the value of a turn before they run. The log is there to supply the numbers for that test.

The Oasis block now keeps banishes back only for the banisher grinds still to do that day: 4 for beer lenses, 8 for the li'l ghost costume, none when both are done.

## Prompts and reports

Each yes/no prompt can be answered ahead of time with `smm.dailyGrind.<name> = true` or `false`. Unset, it asks as before.

| Name | Prompt |
|---|---|
| `sea` | Grind the sea location? |
| `stopForBounty` | Stop for the bounty? |
| `useBanishers` | Continue into the banisher section? `false` stops the run. |
| `highItem` | Continue into the high item drop section? `false` stops the run. |
| `dolphin` | Use the dolphin whistle? |
| `gingerbreadItems` | Grind Gingerbread City items when the leaderboard can't be won? |

Other settings:

- `smm.dailyGrind.incomeReport = true` brings back the `currentIncome` and `incomeCalculator` reports, which are now off by default because they spend a turn of Asdon fuel and two outfit changes to print numbers.
- `smm.dailyGrind.asdonTurns` (default 600) is how many turns of Driving Observantly to fuel before swapping the workshed to the model train set.

## Museum-led choices

- The dolphin whistle is used when the item is worth more than a turn, or when the Display Case is known to be short of it.
- The Spacegate takes the zoological sample kit when both kits are usable and the Display Case is further short of zoological samples than plant samples.
- Not done yet: PirateRealm still always goes for Red Roger's reliquary, and the Drip choices are fixed. Both need new routes in their own scripts.

A missing li'l pirate or ninja costume, or a missing FantasyRealm reward, now prints a red warning and the run continues, so one failure no longer leaves the later daily resources unused.
