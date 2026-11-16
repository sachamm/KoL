# Executable daily IoTM route

The standing objective is **Museum rank #1 for each displayable item, accepting top ten as a milestone**. Meat funds collection purchases. See [the collection policy](collection-objective.md) for rank-aware valuation, protected stock, competing conversions and verified upward-only deposits.

`dailyGrind()` now invokes `smmIRDailyRoute(false,true)` after second breakfast and before legacy daily deeds. `dailyNoAdventureGrind()` invokes `smmIRDailyRoute(true,true)` at the same point. The existing older daily routines continue afterward.

The route builds executable candidates from current character state, solves their shared resource allocation with `smmResourcePlanner.ash`, executes the selected candidates newest first, and verifies each result. The model is regenerated only when something material changed (see *When the route replans*). A dependency such as a locket fight can carry a newer Sword ability; it is dated as that newer ability. Merely owning an item or having its counter in the planner does **not** mean every ability has an executor.

## When the route replans

A solved plan is a work queue, not a single step. After each worker the route compares real state with what the plan expected and keeps the remaining plan when they match. It regenerates and re-solves only when:

- the action failed or was blocked;
- a pool some candidate draws on holds more or less than the plan expected (extra Meat is ignored);
- a generator gate was crossed (adventures at 0 or below 3, HP below a third, MP below 30, drunkenness, Lucky!, Fishy), or the item/Meat drop modifiers, familiar weight, Sword target or garden layout changed;
- the action changes prices or creates capacity the checks above cannot see: Interesting Coin and knucklebone purchases, the noodle summon, the TakerSpace collection, the leaf jump and a garden switch;
- the next queued cast can no longer be afforded;
- the queue is empty. This confirming pass picks up actions that ordinary loot made possible, and the run ends when it selects nothing.

Zone farming is one candidate covering all remaining paid turns, run as a single block; its worker still rechecks zone income before every turn. Repeated actions other than farming are planned one per pass, so they interleave across passes instead of running back to back. The run prints its action and planning-pass counts.

## Commands

```text
iotmroute plan       # server reads and current-price estimates; no workers
iotmroute plan-free  # exclude paid turns
iotmroute run        # execute, newest selected item first
iotmroute free       # execute free workers only
iotmroute status
iotmroute reset      # recover saved settings/lock after an interruption
```

Planning reads inventory, item descriptions, accessible locations, the existing rose garden and shops. It enters and leaves the garden/shop menus to inspect their actual forms. It does not play a baseball inning, cast a skill, consume a drink, purchase goods, replace the garden, or equip gear.

Execution requires sober unrestricted aftercore. It never opens packaged IoTMs automatically. `reset` requires the current combat/choice to be resolved and preserves actual daily usage and the route's paid-turn accounting.

## Economics and limits

The monetary component is **expected net Meat equivalent**: realizable sale proceeds for surplus, or avoided acquisition cost for copies still needed by a known Museum target. Separate rank-progress utility favors closing collection gaps. These are estimates, not booked sales or a guarantee of profit. Input items retain their sale opportunity cost. Paid adventures cost `smm.TurnValue` (the existing default is 5,000); ordinary combat has an additional configurable cost allowance. Cup drinks include liver opportunity cost. Zero-cost non-Meat utility has a small positive preference; the default collection-loss budget is zero. Collection expense is cumulative across workers and repeated runs in the same day/ascension; failed actions that actually consume resources still count.

Sale estimates use autosell as a floor. Listings above the market minimum are discounted to 80%; a minimum-price listing alone is valued at autosell. Conditional/unknown drops are excluded, and Sword candidates require simple known drop tables. Mall quotes are cached within the run, with a 150-quote limit; subsequent unknown prices fall back to autosell. This can miss profitable opportunities, especially in a very large locket collection.

The route's default cumulative limit is **20 actually spent paid adventures per day/ascension**, across repeated runs; it stops at 200 workers per invocation. It may spend fewer or none when prices and available encounters do not support a profitable action. An unexpectedly costly nominally free action records its actual cost and stops. Underwater/flooded paid adventures require Fishy; the route does not automate flooding.

Examples of settings in Mafia's CLI:

```text
set smm.IR.enabled = false
set smm.IR.maxPaidTurns = 20
set smm.IR.locations = The Oasis|The Skeleton Store
set smm.IR.saleDiscount = 0.8
set smm.IR.combatCost = 50
set smm.IR.mpValue = 1
set smm.IR.coinReserve = 10000000
set smm.IR.boneReserve = 0
set smm.IR.collectionBudget = 0
set smm.IR.bczCasts = 3
set smm.IR.substatValue = 1
set smm.IR.emberReserve = 0
set smm.IR.emberValue = 0
set smm.IR.leafCraftCap = 5
set smm.IR.leafReserve = 0
set smm.IR.kiwiBuyCap = 5
```

`smm.IR.keepItem.<item ID>` preserves that many physically owned ingredients. Cup and cooking candidates share ingredient capacities, free cooking capacity and organ capacity. The default Cup liver value is `max(0,6.17 * smm.TurnValue - 2850)`; override `smm.IR.liverValue` to match your diet.

Ordinary Interesting Coin purchases occur only above the reserve, never down to zero. `smm.IR.coinValue` prices each spent surplus coin's future value (default 0 after meeting the reserve). Set it above zero to include further compounding beyond the reserve. That policy is a user-configurable savings target, not a claim that surplus coins have no future value. With no explicit `coinReserve`, the default 10M is earmarked for the Gross Prophet target: once affordable, acquisition may spend that earmarked principal while retaining one coin. Requiring an additional 10M reserve would be impossible under the 16,777,215 item cap. Any explicitly configured reserve takes precedence. `grossProphetValue` in monetary mode and an explicitly set `coinEquipmentValue` are functional-goal premiums, never fictitious Museum progress or Meat sale proceeds; `coinValue` and the collection-loss budget still apply. Knucklebone familiar income is bounded by remaining daily redemption demand; it is not valued as unlimited daily-special stock.

## One shared garden slot

The planner evaluates **Black Rose, Rock, Mushroom, Tall Grass, and Thanksgarden together**, using owned seeds and the actual installed crop. They are alternatives for one slot, not five simultaneous sources of daily income. Owned Pumpkin, Peppermint, Skeleton, Beer and Winter seeds are also evaluated using Mafia's native growth tables. They are not assumed owned from your stated date range. An unrecognized future crop is explicitly unpriced and retained. The Skeleton garden's day-six combat is not treated as a normal item harvest. Pumpkin growth between the huge and ginormous images uses the minimum age known from the current image, which can understate how near the next stage is.

The default horizon is 14 days. Dynamic programming compares picking now against growing: cornucopia/megacopia schedules, three independent rock plots, Mushroom fertilization and harvest levels, and ordinary/very-tall grass yields. Ordinary grass and mature-grass outputs use conservative minimum documented reward prices because their probability distribution is unknown. Mushroom crop level persists while a different garden is installed; the model does not grow it passively during that absence. Piranha daily loot is counted only in the Mushroom alternative.

For an installed Black Rose, the actual known layout is extrapolated across the horizon, excluding already-taken nodes today. Unknown future maze growth is not credited. A new random maze is unpriced unless Future cash surplus is scored separately; finite Museum credit is applied to the first harvest batch only, not repeatedly over the horizon. `gardenDaily.black_rose` supplies a forecast; that forecast gets no income during its first ten growth days. Replacing an installed Black Rose includes ten days of observed daily income as a reset penalty, plus `gardenResetValue` for other progress. Automatic Black Rose replacement is disabled unless `allowRoseReset=true`.

One selected garden is committed per day. When a change is chosen, old-garden claims are suppressed until the verified switch; only the new selected garden can produce workers. There is at most **one attempted change per calendar day**, even after an ambiguous response. Successful changes commit to the forecast horizon to avoid repeatedly booking long-term benefits while swapping back tomorrow. The horizon advantage is a strategy score, not today's Meat income. Observed outside changes also spend today's allowance; unobserved external history remains subject to the game's restriction.

The manager disables native Softcore breakfast harvesting while it owns garden planning, saving the prior preference. Disabling the IoTM route and running it or second breakfast restores that preference. Legacy grass/Mushroom harvest helpers defer during unrestricted aftercore; garden tending before nightcap also uses the shared route. The manager does not alter Hardcore garden preferences.

```text
set smm.IR.gardenHorizon = 14
set smm.IR.gardenSwitchMargin = 1000
set smm.IR.gardenSwitchCost = 0
set smm.IR.gardenResetValue = 0
set smm.IR.allowRoseReset = false
```

Preview with `iotmroute plan`: it prints every owned garden's forecast, reset cost, and selected strategy. Future cash surplus is scored separately; finite Museum credit is applied to the first harvest batch only, not repeatedly over the horizon. `gardenDaily.black_rose` supplies a forecast for an otherwise unpriced newly planted maze. After setting `smm.IR.enabled=false`, `iotmroute run` or second breakfast restores the saved native breakfast preference. If you install a garden manually, run a preview before other automation so the observed change is included.

## Optional collection and utility policies

Default zero collection spending preserves sellable keys and does not invent resale values for unique equipment or buffs. To fund a goal, set a positive **daily** `collectionBudget` and a larger utility premium for that goal:

- `thornOutfitValue`: value of an attempt at a missing Black Thorn outfit piece. A chest consumes a real key and may give another reward; no missing-piece guarantee is assumed.
- `gardenBuffValue.<effect ID>`: value of the fountain's 1-Meat HP/MP-capacity buff or 1,000-Meat initiative buff. Fountain options are read from actual offered labels.
- `blessingValue.Physical/Hot/Cold/Spooky/Stench/Sleaze`: non-Meat value of a 50-turn blessing. Known native free fights compete with their ordinary familiar/Sword alternatives for the same encounter.
- `maidenSongValue`: value of the song's +ML while Maiden is active; its 50 MP is a cost.
- `acornValue.<EFFECT>`: explicit value of an otherwise unpriced terrain effect, using Mafia's effect keys such as `STUN`, `SEA_FRUIT` or `SEA_COWS`.
- `acornTarget.<location ID>.SNIFF` or `.BANISH`: a native monster name/ID. Banishing is permanent for that planting and never chooses an unsolicited target. Unsupported bosses, empty-zone banishes and ambiguous targets are rejected.

The six Maiden blessings are now registered centrally as `maiden.physical`, `maiden.hot`, `maiden.cold`, `maiden.spooky`, `maiden.stench`, and `maiden.sleaze`, so other scripts can reserve them with the existing shared planner.

## Current executor coverage, newest first

| Month/item | Executed policy | Remaining specialized abilities |
|---|---|---|
| 2026-11 legendary acorndion | Existing item/bridge plantings plus profitable underground sniff/MP restoration; actual flooded terrain; explicit valued policies for all 24 skill/terrain combinations. Sniff waits for the modeled native target, and permanent banishing requires an explicit target. All plantings share remaining zone slots and daily charges. | Autonomous flooding, unverified fruit/sea-cow encounter rates, and replacing existing full planting sets. Unpriced effects need an explicit utility value and a funded collection budget. |
| 2026-10 black garden rose | Joint garden selection; parse blocked/live forms; collect recurring loot (including native `spleen` incense nodes), free fights, budgeted keyed outfit chests, fountain buffs/Lucky with actual input costs, and the puzzle's demon-name unlock through Grandpa. | Chest probabilities remain unknown; no promised missing-piece drop. Demon summoning, outfit tattoo, and spending loam for speculative maze growth are not automatic. |
| 2026-09 Meat Shield Maiden | Commanded blessings on known free garden/locket carriers; individual shared blessing pools, hit survival margin, actual buff confirmation, minimum-tier Tax Shield economics. Optional explicitly valued +ML song while Maiden is already active. | Deliberately taking dangerous hits for higher tiers. Mixed/ambiguous elemental attacks are excluded. Tiers describe the current 50-turn buff, not a permanent trained upgrade. |
| 2026-08 Interesting Coin | Daily goods, current inflationary-price resale, missing once-per-ascension equipment, and an earmarked Gross Prophet chrysalis acquisition. Museum mode retains the hatchling; monetary mode can use the explicit familiar acquisition/hatch policy. All purchases share one actual wallet and refresh inflation before replanning. Explicit reserves remain protected. | Tattoo ownership discovery/use and the drop-destroying coin kill. Existing owned tradeable chrysalis is preserved rather than consumed without a diet/collection opportunity-cost policy. |
| 2026-07 Cup of 13s | Select owned tradeable inputs using current Mafia tiers, actual jewels, available liver and input/diet opportunity costs. Require actual liver/adventure/jewel changes. | Optimizing the equipment's repeated booze drops and special drink effects. |
| 2026-06 Sword of S Words | Compare replacement loot against native loot and alternative familiars; reserve replacement capacity in the model. Seed an improved simple-drop target in a free locket fight, checking the actual new target. | Full equipment-name optimization, conditional tables and deliberate chains of paid/copied encounters. |
| 2026-05 legendary pasta wand | Summon noodles; cook positive-value size-one tradeable meals with physically owned ingredients and free cooking available. | Eating/digestion policy and thrall-specific extra encounters. |
| 2026-04 Baseball Diamond | Play existing full lineups using actual offered pitches; prefer useful drops/restoration/stats and avoid banish/tracking/+ML commitments. Verify completion, not merely entry. | Building a particular lineup and routing Curveball carriers. An unknown pitch set stops for manual completion because entry itself spends an inning. |
| 2026-03 Archaeologist's Spade | Compare conservative local/ancient loot against the minimum payout of the current zone's eligible random skeletons. Item and skeleton digs share the same eleven uses. Require an observed successful dig. | Buying a paid setup adventure solely for a dig target and bias-effect optimization. |
| 2026-02 Heartstone | Already-unlocked familiar-weight buff with an evaluated farming use; best available supported Lucky encounter after turn and MP costs. | Letter/word unlock routes, kills, banishes, stuns and attribute buffs. |
| 2026-01 legendary seal-clubbing club | Its pools remain available to the shared reservation system; no new speculative worker spends them. | Across the Battlefield valuation, delayed Next Week landing and drop-destroying Back in Time policy. |
| 2025-12 Skeleton of Crimbo Past | Evaluate skeleton-carrier bone income; redeem unclaimed regular/daily-special goods above the bone reserve. Refresh actual shop stock first. | Campground-rest bone timing and long-term currency goals. |
| 2025-10 blood cubic zirconia | The three item-making skills (blood thinner, spinal tapas, pheromone cocktail), limited to the first `bczCasts` cheap casts of each per day. Requires the product and the cast counter to increase, and stops a skill for the run if the measured substat loss is far above plan. | The six combat/buff skills, Refracted Gaze versus Sword loot, and a base-stat floor. The planned substat prices (11, 23, 37, then tenfold every three casts) are a reported schedule, not Mafia data. |
| 2025-06 prismatic beret | Predict the exact replacement hat/outfit power; busk for guaranteed Meat and retain unpriced effects as additional benefits. | Outfit search for specific effects, Blasts and Boasts. |
| 2025-04 April Shower Thoughts shield | Collect daily wet-paper currency and require the actual collection flag. | Currency crafts and individual enhanced class-skill buff policies. |
| 2025-01 McHugeLarge duffel bag | Unpack the ski set once per ascension when no piece is owned. | Avalanche, Ski Plow and Slash. |
| 2024-12 TakerSpace letter of Marque | Collect the daily delivery when it is the installed workshed; make saleable or collection products from the six supplies, which share the planner's `taker.*` pools. Supplies needed by the best product per day of deliveries are saved until it is affordable. Rollover-melting gear, the tattoo kit and the dinghy are excluded. | Comparing worksheds, anchor-bomb use, and consuming the food/booze. |
| 2024-10 bat wings | Free HP/MP recovery when restoration is useful, with observed use accounting. | Other wing combat/exploration abilities remain with legacy routines or future adapters. |
| 2024-09 Sept-Ember Censer | Read today's balance, then spend embers above `emberReserve` on products that sell or close a Museum gap. Requires the item and a lower balance. | Hulk/Septapus fights, structural ember use, mouthwash as a levelling tool. Untradeable gear is bought only for a known Museum gap. |
| 2024-06 Mini Kiwi | Trade owned mini kiwis at the Kiwi Kwiki Mart, up to `kiwiBuyCap` (default 5) a day, when the product is worth more than the kiwis' own sale or Museum value. | The kiwitini (two-currency row), consuming products, and familiar choice beyond the existing combat comparison. |
| 2023-11 A Guide to Burning Leaves | The free daily jump; up to `leafCraftCap` leaf conversions per day into tradeable products, honouring Mafia's daily limits. Leaves are a Museum item: with unknown or unmet rankings they are held until `museumCopyValue.11341` prices them. | Leaf monsters, the ant egg, tattoo leaf and quest gear. |
| 2022-02 combat lover's locket | Up to three identified free carriers, evaluated against native/Sword loot and alternative familiars. A repeated target cannot be simultaneously booked as both ordinary fight and Sword seed. | Broader conditional-drop evaluation and exhaustive target search. |

The second batch lives in `smmIotmRouteMore.ash` (`more.*` workers). Its mechanics come from the local Mafia source; it has compiled and planned in an offline mock, and has not yet been run against the live game.

Shop prices use `smmIRShopPrice`: `buy_price()` returns 0 for coinmasters defined by shop rows, which had left the Interesting Coin and knucklebone purchases without candidates.

Every planned action prints a `why:` line (the economic or Museum reasoning: gain, cost, shared pools, and whether the product is kept for rank or sold) and an `expected result:` line, plus a `then:` line saying what happens to the product (Display Case for rank, held pending rankings, or surplus for you to sell) and flagging food, drink, spleen, potion, combat and equipment items worth keeping on hand via `smm.IR.keepItem.<id>`. When the action runs, the route prints `achieved:` or `NOT achieved` against that expectation. Adapters set `work.why` and `work.expect` explicitly; actions that don't get a generated explanation from their benefit, cost and pool figures.

Not yet adapted, newest first: shrunken head, Monodent wave/lightning, Möbius ring, Cooler Yeti, Peridot of Peril, Leprecondo, toy Cupid bow, Peace Turkey, Clan Photo Booth, and everything from 2024-08 back that is not listed above. Other items in the 2016-09–2026-11 registry retain their research and existing daily automation. This execution layer does not claim complete automation of all 123 monthly offerings. Add further generators/workers in reverse release order, with verified prerequisites, explicit shared costs and actual-result checks.

## Resource ownership, combat and recovery

The solver respects current-epoch reservations belonging to other scripts. Each worker runs under owner `iotm.route`, inside `smmRPBegin`/`smmRPFinish`; only observed counter changes decrement that owner's existing holds. Route-local ingredient, currency, organ, carrier and turn capacities are freshly rebuilt rather than written as fake Mafia usage properties. This is synchronous execution, not a reservation protocol for independent concurrent Mafia processes.

The dedicated `smm-iotm-route.ccs` invokes the existing damage/survival strategy through `smmIotmCombat.ash`. It bypasses the broader routine's optional replacements, banishes, item uses and instakills. A queued acorn/Sword intent is checked against the actual foe and current skill availability; queuing is never recorded as successful use.

Workers restore equipment and familiar equipment when the encounter is finished. The outer route saves/restores CCS, battle action, autoattack, mood, adventure hooks, familiar script, recovery and automatic-purchase settings. Mall/NPC/coinmaster/stash/shop acquisition is disabled while workers run; existing preferences for retrieving owned closet/storage items are retained. Saved settings can be recovered with `reset` following a hard interruption. An unfinished encounter or defeat stops the route; gear restoration waits until that encounter can be resolved.

The receipt is Mafia's `data/smm-iotm-route-last.txt`: attempted action IDs, confirmed success, actual paid turns, direct Meat delta, adventures gained, and confirmed Display Case transfers. `REPLAN` lines give the reason for each new planning pass and the final `SUMMARY` line counts actions and passes. Loot may be retained/placed rather than sold, so direct Meat receipts do not equal avoided collection purchases or non-cash rank utility. Consult Mafia's session log for item drops. A failed worker is blocked for the rest of that invocation; it cannot loop indefinitely on a stale flag.

## Validation

`fixes/iotm-route/run-tests.sh` compiles all production entry points and the full daily automation against the installed Mafia jar in an isolated runtime. It uses a fake HTTP client that rejects unexpected requests; no account login or live adventure is used. Real Mafia rose-garden, campground and Cup HTML fixtures exercise parsing. Additional tests cover blocked nodes, all five owned garden alternatives, harvest-versus-grow decisions, shared-slot gating, one-change/commitment limits, breakfast ownership, terrain changes, targeted plant economics, blessing reservations and persistent collection spending. The shared allocator regressions and thirty independently enumerated allocation models also run against the updated planner. Regressions cover Sword replacement accounting, shared input quantities, newest-first execution, cumulative/free turn budgets, failed casts, partially consumed failed actions, reservation preservation, receipts, and configuration restoration. Live economic outcomes remain dependent on prices, RNG, gear and encounter state.
