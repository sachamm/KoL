# Daily spending and grind controls

This is how `dailyGrind()` applies the spending rules in the aftercore goals: Meat goes first to purchases with a positive return, then to items on sale, biggest discount first; at most half of the day's net Meat is spent; nothing is bought above the market price; and "cheap" means 20% or more under the market price. The market price is the item's recent average sale price, read from Pricegun, not the current lowest mall listing.

The code is in `scripts/smmSpend.ash`, with NPC resale planning in `scripts/smmNpcResale.ash`. The earlier spending passes ran on November 25. **The new NPC resale pass and November 26 corrections have only been tested offline, logged out.** Set `smm.spend.dryRun = true` for the first day to see what it would buy.


## The day's ledger

The day opens at the Meat (on hand, closet and storage) held when the spending step last finished, which is normally the previous night's `good_night()`. Shop sales made since then, including while logged out, therefore count as today's net. The very first run has no earlier figure and opens at the Meat held at that moment.

The day's net is the Meat held now, minus the opening figure, with this script's own purchases added back. The collection budget is half of the net, less this script's spending, operating purchases and actual diet purchases, and never more than the Meat on hand. A day that loses Meat has a collection budget of zero.

**Other purchases.** `smmdaily` (see [daily-script.md](daily-script.md)) reads the day's session log and books every purchase that neither this step nor `diet.ash` made (the old daily code, garbo, buying by hand) as operating spend in `_smm.spend.operating`. Actual diet purchases are tracked separately in `_smm.diet.bought` and also debit the shared half-net cap exactly once. The diet retains its own additional planning budget. Collection allowance refreshes operating purchases while a daily run is active. Direct third-party and early diet spending can still exceed the eventual cap; the final report then remains incomplete rather than claiming compliance.

Only Meat is counted: items gained are not valued until they sell. Anything else that moves Meat between two runs (a gift, a manual Display Case purchase) lands in the next day's net too.

The cash budget is not labeled as verified resource profit. `day.open` now records a separate observation boundary: current cash, a local-session-log anchor and normalized shop receipts. The closing report separates observed new shop proceeds, cash gains following combat wins, other logged gains/losses, pre-observation cash and remaining unexplained movements. It preserves duplicate receipts and detects lost anchors, unparsed history and changed local-log boundaries. Buyer names are not stored in the new normalized evidence.

This observation window begins after login, so it cannot reconstruct overnight income, login breakfast, old-stock cost basis or every unlogged purchase/transfer. An unavailable opening does not turn the full historical shop log into today's income. `SMM_DAILY_INCOME_COVERAGE OBSERVED_WINDOW` means the specified window's source records were retained, while `RESOURCE_PROFIT UNVERIFIED` remains explicit. Shop proceeds are gross receipts, not earnings. The budget continues to follow the existing cash-basis policy, including overnight shop sales; no new exclusion of those proceeds is inferred.

## The spending step

`smmSpendRun()` runs at the end of `dailyGrind()` and again at the start of `good_night()`. It can run any number of times: each run spends only what the budget still allows.

1. **Positive return.** Reads `data/unrestricted_buy_map.txt` (item, what one copy is worth, how many to keep on hand). It buys an item when the mall price is under that worth, never paying more than the average sale price, best return per Meat first. When Pricegun has no verified average, it skips the purchase.
2. **NPC resale.** Screens the installed KoLmafia NPC catalog for supported, accessible Meat shops. Compares pants-only batches with batches using one sleaze jelly, ranks profitable offers by projected profit per Meat committed, and recalculates quantity against the remaining daily budget immediately before buying. See the details below.
3. **Display Case items on sale.** Considers tradeable items that have a stored Museum ranking and are short of first place, items short of the top ten first. The average sale price is trusted only when at least `smm.spend.minSales` copies sold in Pricegun's history. Each candidate is probed by buying one copy at no more than 80% of its average: the mall fills that from its cheapest listing, so a sale of only a few copies is found, which the quoted mall price (the fifth-cheapest listing) would hide. Items whose probe filled are then bought biggest discount first, to the top ten for every item before any is bought toward first place, and the copies go into the Display Case.


4. **Display Case places at the average sale price.** What the budget still allows goes to the cheapest whole gaps in the Display Case: to the top ten for every item before any toward first place, the cheapest gap first (sorted by the stored mall price, so no request is made to sort them). Each copy costs no more than the item's average sale price, and only a gap the budget can close in full is bought, because part of a gap gains no place. A gap whose lookup came to nothing (no sales history, too few sales, nothing listed at or under the average) is passed over for `smm.spend.rankRetryDays` days (default 3, kept in `smm.spend.rankMiss`), so the same cheap gaps cannot use every lookup each day. `smm.spend.rankPass = false` turns this pass off. On 2026-11-24 nine such gaps (about 2.5M Meat for nine #1 places) were bought by hand after the day was over.

Every purchase is sized by the most it may pay per copy, so the budget cannot be exceeded. The probes run in list order, one copy each, before the discounts are known; the larger purchases that follow are in discount order. In a dry run nothing is probed, so the quoted mall price stands in and small sales are not shown.

Price lookups are capped per pass per run. NPC resale and the Display Case sale pass remember where they stopped and continue from there next run, so the lists are covered over several days. The collection purchase passes make no Museum requests; the NPC pass may look up the jelly's ranking to protect owned copies. Run `dc refresh` to store more rankings.

### NPC resale batches

Demand is Pricegun's observed market sales over the **previous 14 complete UTC dates**, with zero for dates without sales and today's partial bucket excluded. At least three selling dates and `smm.spend.minSales` units are required; a single date contributing over 80% of volume is rejected as a spike. This is sampled market demand, not a promise that our shop will capture those sales.

The stock ceiling is `floor(volume / 14 × min(365, npcBufferDays))`. Subtract all copies already in inventory, closet, storage, equipped or in the mall shop; Display Case copies stay out of this resale stock calculation. Thus one sale per day allows 365 total resale copies, or a batch of 300 if 65 are already held. Repeated runs cannot buy another year's stock on top of unsold copies. A lower remaining budget shrinks the batch, and a batch that no longer covers its costs is skipped.

The listing price is the lower of the recent average sale price and the median of Pricegun's returned recent transaction prices, rounded down. An existing lower shop price is retained and used to calculate profitability. NPC quotes in Mafia's mall-price cache are not evidence of mall resale proceeds. Newly bought copies are listed at this price, retaining any existing per-buyer limit; old copies are not added to the listing. These are projected proceeds; prices and demand can change while stock is selling.

Travoltan trousers must be in inventory or equipped and usable. Already-owned designer sweatpants or replica designer sweatpants can supply the same 5% discount instead. No equipment is bought automatically. Five Finger Discount is included when known. The script checks the exact visible item, vendor row, bulk-buy button and Meat-only price with the pants worn. Inaccessible stores, outfit conflicts, quantity-restricted catalog offers, closed holiday shops, coinmasters and special Doc Galaktik pricing are excluded rather than guessed from the old research snapshot.

For a jelly batch, include both the jelly's value and the spleen it displaces. The spleen default is `1.88 × smm.TurnValue`, the historical adventure yield per spleen of a sweet spleen item; `smm.spend.npcSpleenValue` can override it, including zero when that spleen would otherwise expire unused. Only an owned spare jelly beyond the Museum reserve is consumed. Otherwise one fresh copy is explicitly bought at no more than its average sale price, on the same spending budget. Unknown jelly prices or full spleen disable jelly batches while leaving pants-only trades available. The jelly is chosen only if its net profit beats both pants-only resale and skipping the purchase.

All price requests, stock checks, equipment changes and jelly acquisition finish **before chewing**. Automatic item sourcing is temporarily disabled. After confirming exactly one jelly disappeared and one spleen was used, the next game request is **one direct NPC bulk purchase of one item**. It never goes through `buy()` or falls back to the mall after chewing. Each further jelly-assisted item batch requires a fresh jelly. Previous pants and sourcing settings are restored afterward.

Quantity reserves enough cash for the full pants-only charge plus any jelly acquisition, even though the expected jelly charge is lower. Actual Meat paid is booked to `_smm.spend.spent`; `_smm.spend.logAdjustment` reconciles the NPC log's potentially higher pants-only quote so `smmdaily book` does not charge the discount again as operating spend. Failed listings leave the new stock in inventory, where it prevents a duplicate restock.

Before consuming or purchasing, `smm.spend.npcPending` records the item ID, quantity, expected unit cost and starting Meat. Failed/ambiguous chewing, an interrupted request, or an unexpected quantity/charge stops spending without retrying. This marker survives rollover. Check the session log, inventory, Meat and any remaining one-purchase discount; reconcile spending counters if execution was interrupted before booking, then clear the marker manually. Do not clear it just to retry an uncertain purchase.

In a dry run, no pants, jelly, Meat or shop listings are changed and the NPC cursor is not advanced. Printed offers are conditional previews against the current budget, rather than a simulated shared portfolio with hypothetical purchases deducted. Offline tests cover the demand window, annual ceiling, budget arithmetic, discount choice, vendor rows, receipt checks and log reconciliation; the actual game requests remain untested until a live run.

This replaces the old trigger in `secondBreakfast()` that ran `buyMallSpecials()` whenever total Meat was over 100,000,000.

| Setting                    | Default             | Meaning                                                                                                   |
| -------------------------- | ------------------- | --------------------------------------------------------------------------------------------------------- |
| `smm.spend.enabled`        | true                | `false` turns the step off.                                                                               |
| `smm.spend.dryRun`         | false               | `true` prints what would be bought and buys nothing.                                                      |
| `smm.spend.fraction`       | 0.5                 | Share of the day's net that may be spent. Capped at 0.5.                                                  |
| `smm.spend.minDiscount`    | 0.2                 | Discount that counts as a sale. Never under 0.2.                                                          |
| `smm.spend.minSales`       | 5                   | Copies sold recently before an item's average sale price is trusted for NPC resale or Display Case sales. |
| `smm.spend.maxLookups`     | 60                  | Items priced per pass per run.                                                                            |
| `smm.spend.rankPass`       | true                | `false` turns off Display Case places at the average sale price.                                          |
| `smm.spend.npcResale`      | true                | `false` turns off the NPC resale pass.                                                                    |
| `smm.spend.npcBufferDays`  | 365                 | Total resale-stock horizon, clamped to 0–365 days. Zero disables restocking.                              |
| `smm.spend.npcSpleenValue` | `1.88 × turn value` | Opportunity cost per spleen spent on jelly, in Meat.                                                      |

## The diet's purchases

`diet.ash` follows the same price rule and has its own budget, apart from the half-of-net rule.

**Never above the average sale price.** Before it settles on a plan, the diet looks up the average sale price (Pricegun) of every item the plan would buy in the mall. An item listed above its average is not bought: the plan is limited to the spare copies already owned, or made without the item, and a line says so. When it buys, the most it pays per copy is the planned price plus 30%, and never more than the average. Pricegun having no sales for an item, or not answering, counts as "unknown": no mall purchase is authorized. Spare owned copies can still be planned at their existing opportunity value. Items an NPC store sells for no more than the mall are not checked. KoLmafia's own mall buying (`autoSatisfyWithMall`) is switched off while the diet fetches an item it could not buy under its cap, because that path knows neither cap.

**Its own budget.** The diet may pay `smm.diet.budget` Meat a day (default 500,000; `budget=N` on the command line overrides it for one run). `_smm.diet.spent` holds what its runs have paid today. Every run plans the rest of the day, and the purchases of that plan (copies beyond the spare ones owned, at the planned price) must fit in what is left. A plan that does not fit is made again with an adventure valued 15% lower, as often as needed, so the purchases that return the fewest adventures per Meat go first. When nothing is left, or nothing worth buying fits, the plan uses only what is owned. Either case prints an orange line.

The estimate counts everything the plan pays Meat for: store and mall purchases, the blue mana behind Ancestral Recall, pocket wishes, speakeasy drinks and sausage grinding. The budget also holds while the plan is carried out, because prices can rise between the plan and the purchase: no purchase may cost more than the Meat left at that moment, and a speakeasy drink, a store purchase or a sausage grind that no longer fits is skipped. Making an item from what is owned costs nothing and is always allowed. The run then stops with "cannot get" for that item, and the next run plans within what is left.

`smmdaily` leaves the diet's purchases (`_smm.diet.bought`) out of operating spend to avoid counting them twice, then debits them separately from the same allowance. They also lower the day's cash net like any other cost. A day that brings in 1,000,000 and pays 200,000 for the diet has netted 800,000: half is 400,000, of which 200,000 is already spent, leaving at most 200,000 for collection before other commitments. The report prints the diet's figures separately, and the price check covers its mall requests too. Food and drink bought through garbo, `tquillaFillUp` or by hand remain operating spend.

`tests/ash/smmDietTest.ash` checks the price rule and the budget; `tests/smmdaily-tests.sh` runs it.

## Grind controls

The paid-turn grinds that follow the IoTM route are `oasis`, `beerLens`, `ghostCostume`, `spacegate`, `fantasyRealm`, `pirateRealm`, `dailyDungeon`, `drip` and `gingerbread`.

- `smm.dailyGrind.<name> = false` skips that grind. `true` runs it whatever its logged return.
- `smm.dailyGrind.maxPaidTurns` is an optional daily turn budget shared by all of them. Once it is used up, the rest are skipped. Unset means no limit. It is separate from the route's own `smm.IR.maxPaidTurns`, which is also uncapped unless set.
- Each grind's turns, Meat change and items gained are logged and printed at the end of the run. Items are counted across inventory, closet and Display Case, at their average sale price (Pricegun), never above the lowest listing. An item with no recent sales counts at its autosell price: its listing is an ask nobody has met. Until 2026-11-24 the lowest listing was used, which valued 154 Oasis turns at 37.6M Meat (they brought about 75 mojo filters and 369,000 Meat) and kept the test below from ever skipping a grind. The history from then is cleared once, at the first grind after the change (`smm.grind.valueVersion = 2`), and is not used to skip anything before that.
- **Turn-value test.** The log is kept across days, weighted toward about the last 14. Once a grind has `smm.dailyGrind.minDays` (default 5) logged days, it is skipped while its return per turn is under the value of a turn. One that is clearly losing, under half the value of a turn, is skipped sooner, after `smm.dailyGrind.earlyDays` (default 2). A grind that brought in an untradeable item the Display Case still needs within its last `minDays` logged days is not skipped while that item is still short (`smm.grind.histMuseumItems.<grind>` keeps which ones): such an item has no price, and unbuyable Museum items come first. Once the Display Case has enough, the grind is judged on its return like any other.

A skipped grind prints an orange line with its figures. To clear a grind's history, remove its `smm.grind.hist*.<name>` properties.

The Oasis block now keeps banishes back only for the banisher grinds still to do that day: 4 for beer lenses, 8 for the li'l ghost costume, none when both are done.

## November 26 accounting and allocation corrections

Every `smmSpend` allowance decision during an active daily run first refreshes operating purchases from the session log, including the spending inside `good_night`. Its common purchase boundary requires a verified average and clamps each caller's limit. Daily garbo commands use `smmDailyGarbo`: direct cash buys and missing finished copies in explicit `retrieveItem` calls use that verified ceiling and shared allowance. Accessible copies transfer with automatic sources and `buyScript` temporarily disabled; settings restore on return or abort. Partial fills do not fall through to an unguarded retrieval. Missing crafting inputs and unpriced finished items are held. Implicit sourcing inside other native methods, direct URLs and delegated code still require broader enforcement and the closing audit. The diet also fails closed on unknown mall averages; NPC purchases retain their documented treatment.

The closing price audit checks each mall request independently against an integer per-copy cap rounded down from its quoted average. Cheap purchases cannot cancel expensive requests for the same item. One quote per distinct item is reused; the default `smm.daily.priceCheckLookups` is 150. The report discloses unknown averages and unchecked items, so a lower explicit lookup limit cannot silently claim full coverage. Each audit keeps independent per-request evidence outside Git in `data/smm-price-audit-<date>-<ascension>-<player>-<journal-seq>.txt`, referenced by its journal notes; rerunning an audit does not erase earlier quotes.

These log lines are purchase requests, not proof of fills. Above-cap requests are potential violations requiring review of actual receipts and quote timing; cached quotes are not a reconstructed historical market. `SMM_DAILY_PRICE_AUDIT VERIFIED_REQUEST_CAPS` means the observed request ceilings passed, not that every purchase on other machines was observed. Unknown coverage, potential excess, evidence write failure or recorded spending above the shared cap prevents the close's complete marker. No purchases are undone or retried by the audit.

The version-4 grind ledger retains signed physical ownership changes across storage and equipment, session transactions and separate native-loot estimates. Consumed owned inputs count at Museum-aware opportunity value; selling reduces stock as well as adding Meat. Buying then consuming is charged through its cash cost. Equipment moves and reusable returns do not manufacture production.

Future paid-turn selection and collection-loss settlement use a separate **marginal liquidation estimate**. Positive copies receive sale-price value only within `floor(14-day market volume / 14 × liquidationDays × marketShare)`, after subtracting existing non-Display-Case stock. Other positive copies receive only their autosell floor. The default horizon is 7 days, with a 10% market share; settings `smm.dailyGrind.liquidationDays` and `smm.dailyGrind.marketShare` clamp to 0–30 days and 0–25%. Zero gives autosell-only selection. The demand window, three selling-date requirement, spike rejection and conservative recent-price median reuse the NPC market parser; at least `smm.spend.minSales` units are required. Missing, stale or sparse demand gives no mall premium.

The full signed inventory estimate remains diagnostic. Evidence records the marginal estimate, demand, capacity and existing stock for each changed item. Version-3 and older selection history is discarded once; selection needs fresh samples. This is a conservative planning estimate, not realized sale proceeds or a calibrated guarantee of our market share. It can understate slow valuable drops. It does not increase the cash spending budget or liquidate any items automatically.

The old exemption for any recently acquired untradeable item is replaced by a known gap for a named output and a funded collection-loss allocation. See the daily-script operational corrections for settings and interruption behavior. The 100-adventure Museum cap remains in addition to that allocation.

## Prompt controls

Each yes/no prompt can be answered ahead of time with `smm.dailyGrind.<name> = true` or `false`. Unset, it asks as before.

| Name               | Prompt                                                           |
| ------------------ | ---------------------------------------------------------------- |
| `sea`              | Grind the sea location?                                          |
| `stopForBounty`    | Stop for the bounty?                                             |
| `useBanishers`     | Continue into the banisher section? `false` stops the run.       |
| `highItem`         | Continue into the high item drop section? `false` stops the run. |
| `dolphin`          | Use the dolphin whistle?                                         |
| `gingerbreadItems` | Grind Gingerbread City items when the leaderboard can't be won?  |

Other settings:

- `smm.dailyGrind.incomeReport = true` brings back the `currentIncome` and `incomeCalculator` reports, which are now off by default because they spend a turn of Asdon fuel and two outfit changes to print numbers.
- `smm.dailyGrind.asdonTurns` (default 600) is how many turns of Driving Observantly to fuel before swapping the workshed to the model train set.

## Museum-led choices

- The dolphin whistle is used when the item is worth more than a turn, or when the Display Case is known to be short of it.
- The Spacegate takes the zoological sample kit when both kits are usable and the Display Case is further short of zoological samples than plant samples.
- Not done yet: PirateRealm still always goes for Red Roger's reliquary, and the Drip choices are fixed. Both need new routes in their own scripts.

A missing li'l pirate or ninja costume, or a missing FantasyRealm reward, now prints a red warning and the run continues, so one failure no longer leaves the later daily resources unused.
