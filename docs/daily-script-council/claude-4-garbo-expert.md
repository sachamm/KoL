# Memo 4: garbo expert

Council round 1, garbo (garbage-collector) and how it fits Tquilla's Museum goal.

**Sources.** The garbo source is at `ext/garbage-collector` (HEAD `eaa1455`, 2026-11-22), and the paths below are relative to `packages/garbo/src` unless they say otherwise. I also used Sacha's prefs (`tquilla_prefs.txt`, `KoL/data/smm-prefs.txt`), three session logs and the repo docs. Upstream is <https://github.com/loathers/garbage-collector>, whose README matches the local copy. The sandbox could not reach kolmafia.us, the wikis or Discord, and one web search found nothing relevant, so every claim here comes from the source and from Sacha's own logs.

## 0. What the logs show

Sacha already runs garbo, and it earns well:

| Day | How it ran | Turns | Result garbo reported | Notes |
|---|---|---|---|---|
| Nov 19 (`hearth/61cc0b24…`) | Mid-day after smm work, then again, then `garbo nodiet turns=17` from `good_night_adv` with Drunkula's wineglass | 211 + 21 + 17 | 7.35M (1.06M Meat, 6.29M items) | Marginal MPA (Meat per adventure) on the last turns: **4,943 Meat + 14,214 items = 19,157**. Copies went to the Witchess Bishop: 45 fights from backup camera, Monster Habitats, Chest Mimic eggs and Professor chains. 10 giant sandworm fights used **7 drum machines**. It burned **410 inflammable leaves**, ate **7 Special Seasoning** and bought a Dinsey ticket for 143k. |
| Nov 22 (prefs `garboResults*`) | Full run | 350 | 1.30M Meat + 6.05M items = 7.36M | `garboTargetSources` lists the Time-Spinner, 15 Pocket Professor lectures and one other source. |
| Nov 23 (`Tquilla_20261123.txt` l.53693+) | After `dailyGrind` and the spending step, with 5:46 to rollover | (partial) | — | It bought a Dinsey ticket for **153,000**, planned and ate the whole diet (247 adventures for a net value of 933k, cost 113k), switched the BoomBox to Total Eclipse, planted the black garden rose and swapped back to mushroom, made 3 lassos and a day shortener from leaves, and ran shadow rifts. |

Two cautions about these numbers:

1. **Most of the item value is paper.** On Nov 19, 5.3M of the 6.4M came from **72 LED blocks (40.5k each) and 72 synthetic stuffing (33.3k each)**. These are old Crimbo toy parts that the **Sword of S Words** swapped into tourist loot. The Sword was seeded by Sacha's IoTM route: the log shows `swordOfSWordsMonster` set through a locket fight. `garboValue` prices them at the current mall listing (`garbo-lib/src/value.ts`, `getSaleValue`). Sacha's store asks 45,000 for an LED block. A thin market cannot absorb 72 a day, so this is an asset to sell slowly or to put in the Display Case, not Meat.
2. **The raw Meat per turn is real.** About **4,900 Meat per Barf turn** in cash is the honest benchmark. It already matches `valueOfAdventure = 4500` in `smm-prefs.txt` and `smm.TurnValue = 5000`. The "500" in the ledger is stale: the live prefs say 4500.

## 1. Resource by resource: garbo against dailyGrind and the IoTM route

### Where garbo is strictly better

- **Barf Mountain turns.** `outfit/barf.ts` and `familiar/barfFamiliar.ts` run the maximizer with per-item MPA bonuses for each turn. Garbo also handles wanderers between Barf turns (`tasks/farm/wanderer.ts`: Kramco, voting, darts bullseye, Lights Out, digitize, Rain Man and others) and plants Florist plants. Sacha's stack has no comparable Meat farm, and the Oasis is an item farm.
- **Free-fight coverage.** `tasks/freeFight/index.ts` runs everything in this list:
  - **The X-32-F Snojo (10)** and **CyberRealm Overclock (10)**: the ledger's "20 unused free fights" are already automated in garbo. CyberRealm needs the zero-trust tanktop, Torso Awareness and OVERCLOCK(10).
  - NEP, God Lobster, Machine Elf, Witchess, LOV, Eldritch, BRICKO, Glark cable, Grimacia maps, pygmies (`pygmy.ts`), shadow rifts (`shadowRift.ts`), black rose fights, the glitch reward, seal clubbing, the cursed magnifying glass and Kramco.
- **Copy-target chaining.** `target/fights.ts` covers Witchess, Chateau, Locket, fax, mimic eggs, Time-Spinner, Putty/Doh, digitize, Enamorang, Gregarious, **Monster Habitats** (Book of Facts: 15 fights a day that the ledger calls "passive, no action"), Macrometeorite, Powerful Glove, backup camera and the Professor chains.
  - With Curse of Weaksauce and Saucegeyser, the default target is the free, wishable, copyable monster whose drops `valueDrops` scores highest (`index.ts:defaultTarget`). For Tquilla that is the Witchess Bishop, whose Sacramento wine then feeds garbo's diet.
- **Diet.** `diet.ts` runs a multi-pass optimiser at `MPA = valueOfAdventure`. It uses sweatpants, a distention pill, a Refined Palate wish, a Legendary Digestion noodle, the shotglass, chocolates, clocks and tofu (`nonOrganAdventures`). Nov 23 cost 113k for 247 adventures, about 460 Meat per adventure. The ledger's diet estimate is 130 to 1,650 Meat per adventure.
- **Breadth of dailies.** `tasks/daily.ts`, `dailyItems.ts` and `dailyFamiliars.ts` hold about 120 small no-turn tasks: KGB, Clan Photo Booth, campsite, Mayam, devil candy, the candy map, Mind Control Device, demon summons and more. On Nov 23 these ran after `dailyGrind`, so dailyGrind had left them unused.
- **Measurement.** `session.ts` computes a *marginal* MPA: Meat over the last 75 to 25 turns, items over the last 200, with outliers excluded. It also writes `garboResultsMeat`, `garboResultsItems` and `garboResultsTurns` each day. Sacha's turn-value test needs exactly this number.

### Where Sacha's code is better

- **Museum awareness.** Garbo has none: `grep -i museum` finds only one ice-house URL. It has no rank model, no protected copies and no upward-only deposits (`dc.ash`, `collection-objective.md`).
- **Unbuyable grinds** garbo never touches: FantasyRealm, PirateRealm (garbo uses it only for a cockroach target), the Drip, Spacegate, Gingerbread City, beer lens, li'l ghost costume, bounty and Guzzlr.
- **The Oasis.** `FarmingMethod` allows only Barf, Coral Corral, Marinara Trench or Copperhead (`config.ts`). Garbo cannot farm the Oasis.
- **Valuation discipline.** The IoTM route discounts listings above the market minimum to 80% and values a minimum-price listing at autosell. Garbo trusts the current listing.
- **Newest IoTMs with Museum-aware policy:** Interesting Coin reserve, embers, the garden horizon, the TakerSpace product choice, leaves held for rank, and Sword seeding.
- **Spending rules.** Half of the day's net, never above the average sale price, and "cheap" meaning 20% under it (`smmSpend.ash`). Garbo has no budget.

### Where they overlap or fight

| Resource | garbo does | Sacha/ledger wants | Protection |
|---|---|---|---|
| Copies and replacers: backup camera 11, Glove 10, Macrometeorite 10, Professor ~15, locket 3, fax, Time-Spinner, Habitats 15, mimic eggs 11 | Chains its target, the Witchess Bishop | "Aim them at scarab beatle swarms" | Daily counters only. Whoever runs first wins |
| Free kills: X-Ray, Shattering Punch, Mob Hit, darts | Giant sandworms with drum machines (`tasks/freeGiantSandworm.ts`) and Robortender fish heads (`fights.ts:1270`) | Paid Oasis fights | Counters. The sandworm ROI uses `mallPrice` and ignores the Museum |
| **Drum machines** (Museum #4) | `acquire`s them for sandworms whenever `sandwormValue() > mallPrice(drum machine)` | Display Case | **Display or closet them.** A price override does not help because the ROI calls `mallPrice` |
| Banishes (bottleneck) | Snokebomb, Feel Hatred and others in pygmies and Grimacia (`freeFight/index.ts:627`, `pygmy.ts`), Snokebomb in Macrometeorite chains | Oasis, beer lens, ghost costume, bounty | Run banisher grinds first |
| Lucky!: sax, Aug 2nd scepter, Heartstone, pillkeeper (`resources/lucky.ts`) | Treasury or best lucky zone | Museum target or a drop worth more than 32k | Spend them first |
| **Inflammable leaves** (Museum 11341) | Burns 3 lassos and a day shortener every day, with no value check (`dailyItems.ts:614-633`) | Hold until rank is known | **Closet them** |
| **Special Seasoning** (#2, needs 22,904) | The game eats it with every food, and garbo buys more up to MPA (`diet.ts:1872`) | Keep for the #1 push | **Closet before any eating**. Applies to diet.js too |
| Garden | Plants the black garden rose, loots it, harvests and replants (`resources/garden.ts`) | IoTM route garden manager: one change a day, 14-day hold | Conflict. Pick one owner (see 4) |
| BoomBox | Total Eclipse (`daily.ts:686`) | Food Vibrations | Uses 2 of 11 changes; acceptable |
| Workshed | Drains TakerSpace **only** with `workshed=` or `ascend` (`tasks/post/worksheds.ts:160`); rotates the train set; drives Observantly with Asdon | `asdonTurns` 600 then the train set; TakerSpace by best product | Never pass `workshed=` or `ascend` |
| Embers and Interesting Coins | Spends all of them **only with `ascend`** (`dailyItems.ts:286,313`) | 10M coin reserve | Never pass `ascend` |
| Diet organs, 3 mojo filters | Fills everything | diet.js fills everything | One owner per day |
| Storage and Sacha's own store | `acquire.ts` **pulls from Hagnk's and takes from your mall store** before buying | Store stock is for sale; Hagnk's stock is reserves | Only the Display Case and the closet are safe (`autoSatisfyWithCloset=false`) |
| Sword of S Words | Uses the 100 swaps with whatever monster is seeded | The route seeds the target | **Synergy**: the route picks, garbo spends |

**The case for giving garbo the copies and the paid turns.** The ledger aims copies and turns at scarab beatles for mojo filters. Tquilla already holds **42,343 mojo filters beyond a #1 case**, so another filter has almost no Museum value, and its sale value cannot be realized at that volume. Barf raw Meat is liquid. Unless a beatle or drum-machine push serves a specific rank gap, the Oasis is the weaker use of a paid turn. Measure this; don't assume it (see 4).

## 2. Integration options

### (a) garbo is the Meat core; Sacha's Museum work wraps around it. **Recommended.**

Run order and hand-offs:

**Phase 0, fence (new, about 50 lines).** All of this runs before anything else:

1. Check that `3500 < valueOfAdventure < 10000`. Garbo throws outside that range with barf (`index.ts:217-231`).
2. Write `data/garbo_item_values.json` from the Museum store (section 3).
3. Closet the protected stock, or display it if that moves rank upward: drum machines, Special Seasoning, inflammable leaves while the route holds them, and any Museum item held as a reserve in Hagnk's or the store.
4. Choose who owns the copies today and set `garbo_copyTarget` if a Museum monster wins.
5. Set `_garbo_beSelfish` as preferred.
6. Check `stenchAirportAlways`. It is `false`, so garbo pays about 150k a day for a ticket (section 4).

**Phase A, Museum first (Sacha).** This phase spends the resources that are scarce or Museum-specific, so garbo's counter checks find them already used:

1. breakfast and `secondBreakfast` with the MP reserve;
2. `iotmroute free`;
3. Sword seeding;
4. the garden decision;
5. Lucky! spent on Museum targets;
6. the banisher grinds (beer lens, ghost costume, bounty);
7. the daily unbuyables (FR, PR, Spacegate, Drip, Daily Dungeon if it passes the turn test);
8. any copy chain deliberately aimed at a Museum gap.

Cap paid turns with `smm.IR.maxPaidTurns` and `smm.dailyGrind.maxPaidTurns`, or the uncapped route eats the day. Skip the Oasis grind unless today has a rank target for it.

**Phase B, garbo.**

- **Command:** `garbo -N`, where N is the turns Sacha still needs after garbo (for example Gingerbread, or 0). Garbo stops at N remaining (`config.ts` turns: a negative number saves turns).
- **Diet:** garbo owns the daytime diet. Use `nodiet` only on days diet.js already ate.
- **Flags to avoid:** never `ascend`, `workshed=` or `quick`.
- **Headless runs:** set `garbo_autoUserConfirm=true` only after a few supervised days, because it answers prompts such as "wish for the target". `garbo_interrupt=true` stops it safely between tasks.

**Phase C, after garbo (Sacha).**

1. Re-dress, restore the familiar and set the BoomBox (garbo restores prefs but not gear).
2. `dc` upward-only deposits of garbo loot, Sword toy parts included.
3. List the surplus in the store and sell it slowly.
4. `smmSpendRun`.
5. diet.js nightcap.
6. `good_night_adv`, which already sends overdrunk turns to `garbo nodiet turns=%d` with the wineglass (`smmUtils.ash:8267`).

### (a′) `garbo nobarf`

Garbo spends free fights, copies and dailies, then stops before Barf. Sacha keeps every paid turn. This is the right variant if measurement shows the Oasis or the grinds beat about 4,900 raw MPA. It still needs the same fences, and "May close NEP for the day" applies.

### (b) Borrow libram and garbo-lib inside a new script

`garbo-lib` exports `makeValue`, `WandererManager` and the resource helpers. libram wraps every IoTM (Witchess, CombatLoversLocket, BurningLeaves, TakerSpace and more).

- **For:** IoTM support that is current and maintained.
- **Against:** it brings a TypeScript, rollup and babel toolchain (see `packages/garbo/rollup.config.ts`) into an ASH codebase. It also reimplements what garbo already does well. Garbo's value comes from its tuning (outfits, familiars, combat), not from its libraries.
- **Verdict:** use it only for a new JS module the ASH expert already wants. Don't build a second garbo.

### (c) Keep Sacha's stack and port garbo tactics

Worth porting even under (a):

1. Snojo and CyberRealm free fights, using garbo's readiness checks, for days garbo doesn't run.
2. The marginal-MPA method from `session.ts`, so the turn-value test can use it.
3. The sandworm ROI formula, with a **Museum-aware drum-machine price**.
4. `garboValue`'s historical rule: use the historical price when it is under 7 days old, at 0.9×, and value a mall-minimum price at autosell (`garbo-lib/src/value.ts:saleValue`).
5. The idea in garbo-lib's `wanderer/itemdrop.ts`: choose the wanderer zone by the value of its drops.

**Recommendation: (a), with (c) items 2 and 4 ported, and (b) only on the ASH expert's call.** Garbo is the Meat engine and the turn-value benchmark. Sacha's code is the Museum allocator that runs first and fences stock.

## 3. Making garbo value Display Case items, and honouring the spending rules

**The lever is the price override.** `price_garbo.ts` reads `data/garbo_item_values.json`, and `garbo-price <item> <value>` writes it. `garboValue.ts` merges it last, so it wins over the special values. Generate it every day in Phase 0:

- **Buyable item short of the top ten or #1:** value it at its *avoided acquisition cost*, the Pricegun average sale price (the most Sacha would pay under rule 3). If the Museum store says a copy moves rank, add a small rank premium.
- **Unbuyable item the case still needs:** set a utility value equal to the `collection_value` the route already uses.
- **Surplus item** (mojo filters, hammers, MSG, happiness): override it **down** to a realizable price, for example 0.5 to 0.8 of market, so garbo stops valuing a glut at the listing.

**What the override changes.**

- Familiar choice and drop-gear bonuses (`outfit/dropsgear.ts`).
- Which monster the Sword's swaps target, since garbo values the swapped loot.
- The default copy target (`valueDrops`).
- **Wanderer zone choice**: with mojo filters valued high, garbo-lib would send Kramco, voting and magnifying-glass wanderers to the Oasis.
- The autumn-aton zone, the TakerSpace product (when garbo uses it), the Mr. Store, candy and KGB choices, and the Lucky! adventure.

**What it does not change.**

- **The farming zone** (Barf only).
- Every decision priced by `mallPrice`: the drum-machine ROI, `acquire` caps, diet costs and the ticket.
- Tasks with no value check: lassos and the day shortener.

**Two side effects of overrides.**

- Garbo's README and the red warning on every run say they "can have unexpected side effects on dieting".
- `garboResultsItems` and the end-of-run summary become inflated. When overrides are on, the spending step must **never** use `garboResults*` as income.

**Copy target.** When a free, copyable monster drops a Museum need, set `garbo_copyTarget` (the `target` argument). A non-free target spends a turn per copy, and garbo's README marks targets as experimental.

**Post-hoc buying.** Garbo's job is cash. Phase C converts it to rank with `dc` deposits of garbo's loot and `smmSpendRun`. The spending rules hold if garbo's purchases are treated as follows:

- Garbo's buys (diet ~113k, Dinsey ticket ~150k, potions, drum machines, absinthe) are **positive-return** purchases under rule 1. They already lower the day's cash net, because `smmSpend` measures Meat held against the opening figure.
- **Rule 3 is the gap.** `acquire.ts` raises `autoBuyPriceLimit` up to its own value cap, so garbo can pay above the average sale price, for example a 153k ticket. Two fixes:
  - buy the predictable big items (the ticket, `garbo_buyPass`) in Phase 0 through `smmSpend`'s price check, so garbo finds them already done;
  - parse the session log's `buy N X for P each` lines after garbo and book them in the spending ledger, so overspending is visible and counts against tomorrow.
- **Rule 2 (half of net)** keeps counting cash only. Garbo's item gains enter the net when they actually sell from the store, which matches how `daily-spending.md` already treats items.

## 4. Risks and safe testing

**Version drift.** Garbo moves daily: HEAD is 2026-11-22. Sacha's logs show three builds in five days (`c027608`, `2f4ee55`, `6bc8b68`), and every run warns "unable to query GitHub" (`lib.ts:checkGithubVersion`). It needs KoLmafia r29401 or later (`index.ts:sinceKolmafiaRevision`); Sacha is on r29462. Install from the `release` branch and update deliberately, not every day: once a week, followed by a `garbo simdiet` smoke test. Record the printed `Local Version` in the daily ledger, so an MPA change can be tied to a build.

**Settings garbo assumes, against Sacha's setup.** Garbo changes these through `propertyManager` and resets them in `finally` (`index.ts`):

- the CCS (`garbo`), `betweenBattleScript` (blank, so `smmPreAdventure.ash` and its `burnMP` stay off; good for MP), `choiceAdventureScript`, mood `apathetic`, recovery, `valueOfInventory 2`, the June cleaver choices, `allowNonMoodBurning` and library summons.
- If KoLmafia is killed mid-run, run `smmPrefs apply` afterwards. Garbo keeps its own `garbo.ccs`, which `shared-settings.md` already excludes.

Other settings and state to watch:

- **Gear and familiar** are left as garbo's last outfit, so Phase C must re-dress.
- **MP:** garbo spends MP on its own buffs. Cast Sacha's MP-critical buffs before garbo or after its free rests; don't run `burnMP` in the middle of garbo.
- **Workshed and Asdon:** dailyGrind's Asdon-to-train-set swap uses `_workshedItemUsed`, so garbo cannot swap afterwards. That is fine. Without `workshed=`, garbo only rotates the train set and fuels Asdon for Driving Observantly when Asdon is installed, buying bread to do it. That duplicates `smm.dailyGrind.asdonTurns`, so pick one.
- **Garden:** garbo's black-rose swap counts as an "observed outside change" for the route's garden manager. Either set the route to leave the black rose alone on garbo days, or accept garbo's daily loot-and-swap and let the route stop planning gardens.
- **Hagnk's:** garbo treats storage as owned and pulls freely. Anything there is spendable.
- **Clan:** `garbo_vipClan=14909` switches clans and switches back.
- **Dinseylandfill:** `stenchAirportAlways=false`, so it costs about 150k a day, roughly 0.5k per turn. Confirm in game. If Tquilla really doesn't own it, a permanent charter pays back after (charter price ÷ 150k) days.

**Testing safely**, in increasing order of risk:

1. **Read-only checks:** `garbo version`, `garbo help`, `garbo-price list`, and `garbo simdiet` (it plans and prints the diet, then exits; see `diet.ts:2072`). Note that simdiet still unequips some slots.
2. **Fence dry run:** run Phase 0 with the spending step's `dryRun` on. Confirm that the protected items' closet and display counts don't move across a garbo run.
3. **Short live run:** `garbo 10 nodiet`, or `garbo halt=<task name>`, with `garbo_history=true` (it writes the task CSV). Check that the CCS, mood and betweenBattleScript are back afterwards.
4. **Measurement:** six days of A/B. Odd days run the full plan (a); even days run (a′) with the Oasis for paid turns.
   - **Compare:** cash Meat (`smm.spend` net), deposits, and items valued with **one** rule (the IoTM route's realizable price, not garboValue).
   - **Afterwards:** set `smm.TurnValue` and `valueOfAdventure` to the measured raw-plus-liquid-items MPA, so the grind turn-value test compares every grind with garbo's real alternative.
