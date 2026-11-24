# Daily spending and grind controls

This is how `dailyGrind()` applies the spending rules in the aftercore goals: Meat goes first to purchases with a positive return, then to items on sale, biggest discount first; at most half of the day's net Meat is spent; nothing is bought above the market price; and "cheap" means 20% or more under the market price. The market price is the item's recent average sale price, read from Pricegun, not the current lowest mall listing.

The code is in `scripts/smmSpend.ash`. **It has not yet been run in KoLmafia.** Set `smm.spend.dryRun = true` for the first day to see what it would buy.

## The day's ledger

The day opens at the Meat (on hand, closet and storage) held when the spending step last finished, which is normally the previous night's `good_night()`. Shop sales made since then, including while logged out, therefore count as today's net. The very first run has no earlier figure and opens at the Meat held at that moment.

The day's net is the Meat held now, minus the opening figure, with this script's own purchases added back. The budget is half of the net, less what has already been spent, and never more than the Meat on hand. A day that loses Meat has a budget of zero.

**Other purchases.** `smmdaily` (see [daily-script.md](daily-script.md)) reads the day's session log and books every purchase this step did not make itself (the old daily code, garbo, buying by hand) as operating spend in `_smm.spend.operating`. The budget is then half of the net, less this step's purchases, less the operating spend. Until something books it the figure is 0, so `dailyGrind()` on its own behaves as before.

Only Meat is counted: items gained are not valued until they sell. Anything else that moves Meat between two runs (a gift, a manual Display Case purchase) lands in the next day's net too.

## The spending step

`smmSpendRun()` runs at the end of `dailyGrind()` and again at the start of `good_night()`. It can run any number of times: each run spends only what the budget still allows.

1. **Positive return.** Reads `data/unrestricted_buy_map.txt` (item, what one copy is worth, how many to keep on hand). It buys an item when the mall price is under that worth, never paying more than the average sale price, best return per Meat first. When Pricegun has no sales for an item it pays no more than the current listing.
2. **Display Case items on sale.** Considers tradeable items that have a stored Museum ranking and are short of first place, items short of the top ten first. The average sale price is trusted only when at least `smm.spend.minSales` copies sold in Pricegun's history. Each candidate is probed by buying one copy at no more than 80% of its average: the mall fills that from its cheapest listing, so a sale of only a few copies is found, which the quoted mall price (the fifth-cheapest listing) would hide. Items whose probe filled are then bought biggest discount first, to the top ten for every item before any is bought toward first place, and the copies go into the Display Case.

Every purchase is sized by the most it may pay per copy, so the budget cannot be exceeded. The probes run in list order, one copy each, before the discounts are known; the larger purchases that follow are in discount order. In a dry run nothing is probed, so the quoted mall price stands in and small sales are not shown.

Price lookups are capped per pass per run. The second pass remembers where it stopped and continues from there the next day, so the whole list is covered over several days. The step makes no Museum requests; run `dc refresh` to store more rankings.

This replaces the old trigger in `secondBreakfast()` that ran `buyMallSpecials()` whenever total Meat was over 100,000,000.

| Setting | Default | Meaning |
|---|---|---|
| `smm.spend.enabled` | true | `false` turns the step off. |
| `smm.spend.dryRun` | false | `true` prints what would be bought and buys nothing. |
| `smm.spend.fraction` | 0.5 | Share of the day's net that may be spent. Capped at 0.5. |
| `smm.spend.minDiscount` | 0.2 | Discount that counts as a sale. Never under 0.2. |
| `smm.spend.minSales` | 5 | Copies sold recently before an item's average sale price is trusted in pass 2. |
| `smm.spend.maxLookups` | 60 | Items priced per pass per run. |

## Grind controls

The paid-turn grinds that follow the IoTM route are `oasis`, `beerLens`, `ghostCostume`, `spacegate`, `fantasyRealm`, `pirateRealm`, `dailyDungeon`, `drip` and `gingerbread`.

- `smm.dailyGrind.<name> = false` skips that grind. `true` runs it whatever its logged return.
- `smm.dailyGrind.maxPaidTurns` is an optional daily turn budget shared by all of them. Once it is used up, the rest are skipped. Unset means no limit. It is separate from the route's own `smm.IR.maxPaidTurns`, which is also uncapped unless set.
- Each grind's turns, Meat change and items gained are logged and printed at the end of the run. Items are counted across inventory, closet and Display Case, at the stored mall price (autosell when there is none).
- **Turn-value test.** The log is kept across days, weighted toward about the last 14. Once a grind has `smm.dailyGrind.minDays` (default 5) logged days, it is skipped while its return per turn is under the value of a turn. A grind that brought in an untradeable item the Display Case still needs within its last `minDays` logged days is not skipped: such an item has no price, and unbuyable Museum items come first.

A skipped grind prints an orange line with its figures. To clear a grind's history, remove its `smm.grind.hist*.<name>` properties.

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
