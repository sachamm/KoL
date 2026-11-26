# Tquilla resource ledger

Recommendations reviewed 2026-11-26.

The goal is **Museum #1 for every displayable item, accepting top ten as a milestone**. Use daily-limited resources for worthwhile collection gaps that Meat cannot buy, earn liquid Meat with the remaining resources, and spend that Meat on attainable Museum places. Exhausting every charge and maximizing paper inventory value are not goals of their own.

This began as a [ledger artifact](https://claude.ai/artifact/Xjw56BRhKZwbubhQu9WTSM), dated 2026-11-22 and exported 2026-11-25. This revision updates the repository copy with the resource-by-resource review. The external artifact has not been synchronized. Historical quantities, prices and ranks below are evidence from November 19–24, **not a fresh account or market snapshot**. Recommendations do not establish ownership, current unlocks or executor coverage.

Read this with [aftercore goals](aftercore-goals.md), [collection policy](collection-objective.md), [target register](target-register.md), [daily spending](daily-spending.md), [diet](diet.md), [IoTM route](iotm-route.md), [resource planner](resource-planner.md) and [daily script plan](daily-script-plan.md). The plan and council papers explain corrections to the original ledger; plans and code coverage are not proof that a live day completed.

## Decisions that change the allocation

- **Start at 4,500 Meat per paid adventure.** Both `valueOfAdventure` and `smm.TurnValue` are 4,500 in `data/smm-prefs.txt`. Replace that provisional figure with measured marginal farming income. Do not restore the ledger's stale 500-versus-5,000 mismatch.
- **The Oasis is a collection farm when a gap justifies it.** Barf is the documented cash alternative. Historical Barf raw Meat was 3,723–4,329 per turn, versus 2,367 in the cited Oasis block, before comparing liquid item proceeds and operating costs. Large existing Oasis stockpiles sharply limit the value of further surplus.
- **Sword loot is important, but separate from ordinary farming income.** Its historical LED-block and stuffing haul was valued at listing prices, not booked sales. Charge for native item loot replaced and the other familiar displaced. Garbo already spent its charges on completed days; the missing guarantee concerns days that stop or omit that work.
- **The nine cheap #1 purchases were reported completed on November 24.** Refresh and defend their ranks rather than repeating the old purchase quantities.
- **MP needs recovery before spending.** The negative `burnMP` argument was a reserve, not 17,797 MP spent. Breakfast summons, disabled recovery and mood ordering caused the stall; excessive buff extension was a separate waste. Reserve campsite rests for useful Cinch recovery.
- **Banishes need a complete, per-source model.** Uses, active slots, duration, scope and turn cost matter. Monodent lightning has one active banish, not eleven simultaneous all-day banishes.
- **Snojo and CyberRealm need access/readiness checks.** They are not twenty confirmed unused fights. Garbo already supports them when available; CyberRealm also needs its relevant skill and combat setup.

## Value and spending rules

For each candidate, compare:

```text
useful collection output or realizable proceeds
    + avoided costs + adventures saved or gained × turn value
    - inputs - displaced earnings - paid turns × turn value
```

- A needed tradeable copy is worth avoided acquisition cost up to the remaining target; surplus is worth realizable proceeds. Never count the same copy as both retained and sold. Unbuyable collection progress is separate non-cash utility with a funded loss budget.
- Owned inputs are not free. Protect required copies, equipment and operating reserves. Unknown rankings do not justify consumption, sale or invented Museum credit. Display Case copies stay in the case.
- A free fight is worth its rewards and compatible charging opportunities, less costs. A loot-preserving free kill on an already-scheduled paid encounter chiefly saves the turn; the encounter's ordinary loot is not an additional windfall. A copy or replacement is not automatically a free fight.
- Value buffs over the remaining eligible encounters, after caps. Include MP, organs, ingredients, familiar/equipment displacement and setup. Do not extend a buff beyond useful turns.
- Treat asking prices as provisional. Use recent sales, market depth and likely sale volume; a large stockpile cannot all be sold at one quote. Stock moves and deposits are not production income.
- Follow the goals' spending order: positive return first, then qualifying discounts, biggest discount first. Spend at most half the day's net under the budget accounting in [daily spending](daily-spending.md). Do not pay above recent average sale price; a qualifying sale is at least 20% below it. The diet has its own documented budget treatment.
- Do not translate a recommendation into an assumed capability. Reserve a resource before another routine spends it, and use one owner for a shared garden, workshed, diet or encounter pool. The shared selectors do not intercept every direct call or third-party consumer.

## Bottlenecks, reserves and surpluses

| Resource                | Best use                                                                                         | What to measure or preserve                                                                                               |
| ----------------------- | ------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------- |
| MP                      | Recover before summons, moods and combat buffs; buy restoration only after useful free recovery. | Remaining scheduled casts plus a combat margin; about 2,000 is a starting breakfast reserve, not a universal fixed floor. |
| Paid adventures         | Fund justified unbuyable collection work, then the best net cash farm.                           | Actual paid turns and net marginal return, excluding daily Sword windfalls.                                               |
| Banishes                | Persistent control for long blocks; short-duration sources for bounded grinds.                   | Active slots, duration, scope, costs and all competing targets.                                                           |
| Forced noncombats       | Choose valuable eligible collection choices or the best remaining reward sequence.               | Launch costs, choice eligibility and the whole sequence unlocked.                                                         |
| Stomach, liver, spleen  | Optimize jointly with access items, buffs, cleaners and the nightcap.                            | Organ displacement and whether generated adventures can actually be used.                                                 |
| Item-buff budget        | Buy incremental drop gains that pay over useful encounters.                                      | The old 100-Meat-per-turn cap is a guardrail, not an economic optimum.                                                    |
| Sellable stock          | Keep operating stock, close useful case gaps and offer quantities the market will absorb.        | Realized sales and a reasonable sales horizon; historical asks totaled about 700M but were not liquid wealth.             |
| TakerSpace anchors      | Treat excess anchors as abundant inputs while conserving scarce complementary supplies.          | Profit or collection progress per scarce rum, mast, silk and gold.                                                        |
| Meat                    | Maintain operating liquidity; use the permitted spending budget for attainable progress.         | Historical balance was 141.5M, not today's balance or spending allowance.                                                 |
| Copies and replacements | Target worthwhile collection needs or profitable eligible chains.                                | Actual free status, target access and the alternative use of each source.                                                 |
| Free fights             | Take profitable available encounters with compatible equipment and familiar.                     | Unlocks, actual remaining counters and restoration/setup costs.                                                           |

## IoTMs and granted powers, newest first

Counts are nominal limits or historical observations, not a promise that all are owned and unused today. The original ledger marked acorndion, Maiden, Baseball Diamond, Spade and several older sources as script-only. Later logs establish more ownership, including the Sword and rose, but current availability must still be read. For implemented workers and remaining gaps, use [IoTM executor coverage](iotm-route.md#current-executor-coverage-newest-first).

### 2025–2026

| Resource                               | Recommended allocation and tradeoff                                                                                                                                                                                                                                                                |
| -------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Legendary acorndion                    | Plant for the zone actually scheduled. Sniff a needed native monster; value MP restoration against bought restores. Include weapon displacement and shared planting slots. An Oasis planting needs a justified Oasis block.                                                                        |
| Black garden rose                      | Collect accessible recurring loot, useful fountain rewards and profitable fights. Compare the established layout with other owned gardens over several days, including lost growth. Keep automatic speculative resets disabled.                                                                    |
| Meat Shield Maiden                     | Obtain useful blessings on compatible scheduled fights. Subtract displaced familiar income and restoration. A paid locket setup must earn back its turn; do not take dangerous hits merely to pursue higher tiers.                                                                                 |
| Interesting Coin                       | Protect productive capital and the earmarked chrysalis reserve. Spend surplus only when goods beat forgone growth. Refresh inflation after purchases. Reassess reserves after the selected collection goal rather than liquidating every later coin.                                               |
| Gross Prophet chrysalis                | Keep the hatchling displayable while the case needs it. Hatching requires a separate future-earnings justification that charges for consuming the collectible.                                                                                                                                     |
| Cup of 13s                             | Solve jewels, eligible inputs and remaining liver together. Compare net value per liver point with the optimized diet, including input replacement cost and useful effects. Do not force a weak drink just to exhaust jewels.                                                                      |
| Sword of S Words                       | Seed a valuable eligible drop table, then use the Sword as the active familiar while replacement loot beats native items and the alternative familiar. Use compatible free fights first; revalue targets as gaps close or liquidity weakens. The 100-use limit is capacity, not guaranteed profit. |
| Legendary pasta wand                   | Collect the noodle batch. Compare sales with profitable free cooking and digestion benefits across the whole diet before selling everything. Free cooking saves a turn, not ingredient cost.                                                                                                       |
| Baseball Diamond                       | Use available innings for useful drops, recovery or buffs from actual offered pitches. Avoid harmful encounter commitments and unjustified paid setup. Unknown pitches require inspection rather than assumed rewards.                                                                             |
| Archaeologist's Spade                  | Spend the eleven shared digs in places already worth visiting. Compare ordinary excavation with eligible skeleton encounters and collection needs. Charge for any trip taken solely to enable a dig.                                                                                               |
| Heartstone                             | Treat the letter/unlock route as an investment in recurring powers. Compare unlock cost with useful Lucky!, control and buffs; allocate each unlocked power separately. The route does not automate all unlocks.                                                                                   |
| Legendary club: Next Week              | Aim delayed encounters at worthwhile eligible collection targets or profitable chains. Start early enough for the wanderer to arrive during useful adventuring; account for actual encounter and turn costs.                                                                                       |
| Legendary club: Across the Battlefield | Use only for a specific encounter-control plan whose gain beats the shared alternatives and setup. No fixed universal target is established.                                                                                                                                                       |
| Legendary club: Back in Time           | Use on a paid encounter when the turn saved exceeds destroyed drops and setup cost. Do not spend it on a valuable collection-drop fight merely because it is a free kill.                                                                                                                          |
| Skeleton of Crimbo Past                | Acquire enough knucklebones for useful redemptions, favoring suitable phyla. Equip for qualifying rests when practical. Familiar income is bounded by useful currency demand, not unlimited copies of the daily special.                                                                           |
| Shrunken head                          | Select a zombie for a needed recurring drop or valuable farming ability. Include the equipment slot, zombie upkeep and survival. A missing unbuyable output can beat a generic +item bonus.                                                                                                        |
| Blood cubic zirconia                   | Compare each early item-producing cast with actual substat loss and product value. Three casts per skill is a conservative starting limit, not proof they all pay. Evaluate combat powers separately, including conflicts with Sword loot.                                                         |
| Monodent lightning                     | Kill and retain drops while banishing one unwanted monster until rollover. It costs a turn and supports only one active lightning banish; later casts move it. Use it where persistent control has the greatest benefit.                                                                           |
| Monodent wave                          | Flood the zone with the best net benefit over the day's encounters. Include Fishy, underwater gear and displaced equipment; an extra adventure per encounter can overwhelm the apparent +30% item/Meat benefit.                                                                                    |
| Prismatic beret                        | Busk before useful encounters. Search outfit power for valuable effects rather than maximizing power and collecting Meat after adventuring. Include short effect durations and the opportunity cost of each cast.                                                                                  |
| April Shower Thoughts shield           | Collect wet paper; protect collection needs, then compare conversions with surplus sales. Evaluate enhanced class-skill effects against the upcoming block instead of counting only the daily globs.                                                                                               |
| McHugeLarge duffel bag / Avalanche     | Use the ski set's Avalanches for valuable eligible forced choices. Launch on scheduled compatible fights where possible. If a paid launch is needed, compare its cost with the full reward sequence unlocked.                                                                                      |

### 2023–2024

| Resource                  | Recommended allocation and tradeoff                                                                                                                                                                                                |
| ------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| TakerSpace                | Collect supplies; optimize products around scarce rum, masts, silk and gold. Burning the most anchors is not the objective. Compare a day's delivery with other owned worksheds before changing installation.                      |
| Bat wings                 | Recover useful HP/MP before paid restoration and heavy casting. Put turn-saving combat powers on otherwise paid fights; use pickpockets on valuable eligible drops. The eleven upside-down rests are separate from campsite rests. |
| Sept-Ember Censer         | Buy outputs closing known gaps or offering the best realizable surplus. Reserve only for a concrete better use. Compare mouthwash and combat options with goods; do not assume every ember should buy the same product.            |
| Mini Kiwi                 | Compare familiar drops with displaced familiar income. Trade owned kiwis only when outputs beat their sale or collection value. A daily buy cap is a limit, not a target.                                                          |
| Apriling band helmet      | Choose the two instruments for today's plan: sax for valuable Lucky!, tuba for forced choices, quad tom for profitable free fights, piccolo for useful familiar experience. Compare song benefits with the target encounters.      |
| Everfull Dart Holster     | Arrange eligible bullseyes on worthwhile paid encounters. Charge accessory displacement; a bullseye on an already-free fight does not save an additional turn.                                                                     |
| Mayam Calendar            | Plan ring combinations jointly for adventures, useful rests, familiar experience and outputs. Experience enabling valuable familiar abilities can beat a fixed adventure reward.                                                   |
| Candy cane sword cane     | Collect the profitable direct-Meat opportunity. Use other choice/encounter benefits for selected targets; equip it only while its contribution beats the displaced weapon.                                                         |
| A Guide to Burning Leaves | Take the free daily benefit. Hold leaves until ranks are known, then compare crafts, monsters and other uses. Protected leaves must not disappear into automatic lassos or day shorteners.                                         |
| Book of Facts             | Allocate Recall Habitat, valuable facts and Circadian Rhythms actively. Habitat is a targeted-encounter resource; wishes and other useful facts can justify deliberate targeting. It is not merely passive loot.                   |
| August Scepter            | Take useful date benefits and assign discretionary casts by payoff among Lucky!, fights, diet support and buffs. Cat Day and Tooth Fairy are candidates, not mandatory choices.                                                    |
| Jurassic Parka            | Aim spikes at the best eligible forced choices and launch them on compatible scheduled fights. Its restrictions are distinct from Fiesta Exit; verify that the intended choice is eligible.                                        |
| Cincho de Mayo            | Reserve useful Cinch before incidental spending. Compare each Fiesta Exit's full sequence with other Cinch uses. Rest after spending so recovery is not wasted at the cap.                                                         |
| Designer sweatpants       | Preserve enough sweat for profitable liver clearing, and use the cleared capacity in the diet. Other sweat powers compete with that reserve. Extra booze has value only if its adventures can be used.                             |
| Bird-a-Day calendar       | Take the useful favorite-bird buff before farming. Value the actual bonuses over remaining relevant encounters, not a permanent assumption of an Oasis day.                                                                        |

### Older equipment, familiars and skills

| Resource                             | Recommended allocation and tradeoff                                                                                                                                                                                                                         |
| ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 2002 Mr. Store Catalog               | Spend credits on the best combination of needed outputs and realizable surplus. Reprice daily instead of always buying cookie sheets.                                                                                                                       |
| Autumn-aton                          | Dispatch early and promptly. Compare useful drops, mission duration and upgrades; a needed exclusive item can beat a higher-priced commodity with weak demand.                                                                                              |
| Cursed monkey's paw                  | Wish for eligible items or effects with the largest benefit over useful remaining encounters. Consider Monkey Slap before the first wish. Do not buy excessive Frosty coverage after valuable farming ends.                                                 |
| June cleaver                         | Choose adventures when they beat the actual alternative at the current turn value. Reevaluate fixed choice settings, weapon displacement and encounter timing.                                                                                              |
| Tiny stillsuit                       | Put it on a familiar already worth using, or charge equipment/familiar displacement. Compare distillate with alternative liver uses in the appropriate diet phase.                                                                                          |
| Combat lover's locket                | Spend reminiscences on valuable hard-to-reach monsters, pickpockets or a Sword seed. Ordinary locket fights take a turn unless the monster or an effect makes them free.                                                                                    |
| Cosmic bowling ball                  | Maintain useful encounter control and redeploy when the ball returns. Model cooldown and one active banish instead of independent all-day removals.                                                                                                         |
| Daylight Shavings Helmet             | Acquire useful beard effects at useful times. Keep it on only while its total contribution beats competing hats.                                                                                                                                            |
| Vampyric cloake                      | Put limited forms on encounters where their specific benefit is greatest. Reserve them when better collection or earning encounters remain.                                                                                                                 |
| Backup camera                        | Back up a valuable eligible target; prefer an inherently free target when paid collection copies are not justified. Recheck the previous monster and choose mode for the current activity.                                                                  |
| Comprehensive Cartography            | Map valuable monsters that would otherwise require searching. Mapping targets the encounter but does not itself make the fight free.                                                                                                                        |
| Feel Envy                            | Force eligible uncertain drops on valuable monsters. Incremental value is low when ordinary item drop already guarantees them.                                                                                                                              |
| Feel Nostalgic                       | Arrange a valuable previous monster, then a compatible later encounter. Plan the sequence instead of using it arbitrarily after any locket fight.                                                                                                           |
| Feel Hatred                          | Use its banishes for bounded grinds whose unwanted encounters and duration justify them. Avoid needless overwrites.                                                                                                                                         |
| Industrial fire extinguisher         | Use Polar Vortex on eligible valuable drops when its incremental gain beats alternative extinguisher uses. Needed collection drops take precedence over abundant unsaleable stock.                                                                          |
| Cargo Cultist shorts                 | Pick a pocket for a known collection need, useful consumable or best realizable output. Charge for opening or consuming collectible outputs.                                                                                                                |
| Guzzlr tablet                        | Choose deliveries by incremental setup, travel, drink cost and reward. Overlap profitable farming where possible; gold/platinum is not automatically optimal.                                                                                               |
| Powerful Glove                       | Replace encounters only when the resulting distribution improves value. It does not select an arbitrary monster. Include battery, equipment and actual free-status restrictions.                                                                            |
| Pocket Meteor Guide / Macrometeorite | Apply the same distribution and free-status test as the Glove. Reserve uses for worthwhile collection targeting or profitable eligible chains.                                                                                                              |
| SongBoom BoomBox                     | Compare Food Vibrations with Total Eclipse for the actual farm and switch for worthwhile blocks. Neither song is a universal default.                                                                                                                       |
| Lil' Doctor bag: Chest X-Ray         | Use on valuable otherwise-paid encounters with useful rewards preserved, not on already-free fights.                                                                                                                                                        |
| Lil' Doctor bag: Reflex Hammer       | Use for bounded encounter control and charge the off-hand commitment.                                                                                                                                                                                       |
| Lil' Doctor bag: Otoscope            | Reserve for eligible encounters with substantial extra drop value; avoid use after other methods already guarantee the reward.                                                                                                                              |
| Beach Comb                           | Allocate free walks between valuable squares and useful head buffs. Charge paid/overdrunk walks for their adventure opportunity cost. Read the actual remaining allowance rather than hard-coding the old ten-walk estimate.                                |
| Fourth of May Cosplay Saber          | Allocate five shared Force uses among eligible loot guarantees, control and follow-up targeting. Choose the daily modification for the familiar strategy; do not assign every Force to scarab beatles.                                                      |
| Kramco Sausage-o-Matic               | Take worthwhile goblins while charging the growing off-hand commitment between encounters. Coordinate sausages between MP recovery and adventures under the same daily allowance.                                                                           |
| Bastille Battalion                   | Choose a useful first-game configuration, then value further games by their actual rewards. Five playable games are not five identical configuration reward packages.                                                                                       |
| Neverending Party                    | Use remaining profitable free fights even if the quest finishes early. Compare quest costs and rewards rather than always choosing the Meat quest.                                                                                                          |
| Kremlin's Greatest Briefcase         | Use darts for short grinds and collect worthwhile daily goods. Schedule item buffs before useful drops; compare consumables with sale and collection value.                                                                                                 |
| Voting booth                         | Choose initiatives and the monster reward together. Land wanderers in a compatible profitable zone with suitable familiar and equipment.                                                                                                                    |
| God Lobster                          | Take worthwhile free challenges. Choose missing useful regalia, then the best available blessing/experience. Regalia depends on familiar equipment and is not available unconditionally every fight.                                                        |
| Boxing Daycare                       | Take free useful benefits and schedule buffs before relevant encounters. Paid activities must justify their own inputs and costs.                                                                                                                           |
| Latte lovers member's mug            | Coordinate banish, copy, gulp and refills. Gulp can be important MP recovery. Use farming ingredients during the farm and adventure ingredients for rollover when worthwhile.                                                                               |
| Pocket Professor                     | Build useful weight before valuable lecture chains. Charge setup and familiar displacement; lecture capacity depends on weight and counters, not a fixed nine.                                                                                              |
| Robortender                          | Supply drinks whose future contribution covers acquisition/setup. Compare with remaining Sword value and other familiars; do not buy long-lived benefits for very few turns.                                                                                |
| Space Jellyfish                      | Collect valuable jellies where familiar contribution wins. Preserve collection copies and compare sale with effect use, including organ cost.                                                                                                               |
| Trick-or-Treating Tot                | Use the relevant costume when its farming bonus beats the alternatives, including remaining profitable Sword uses.                                                                                                                                          |
| Cat Burglar                          | Build charges on suitable encounters and heist valuable eligible drops. Charge the familiar slot used to build those charges.                                                                                                                               |
| Time-Spinner                         | Compare the entire ten-minute budget among a two-minute Far Future reward, three-minute recent fights and meal replication. The usual future-plus-two-replays bundle can lose to a valuable meal or collection encounter. Replays are not necessarily free. |
| Snojo                                | Confirm access first; the later analysis reports it unavailable. Once ready, use profitable free fights and useful settings, stopping before a paid encounter.                                                                                              |
| Calculate the Universe / Numberology | Choose the best accessible adventure result unless a targeted encounter is worth more. Read the actual daily allowance and result conditions.                                                                                                               |
| Eldritch tentacle / Horror           | Take available profitable encounters with reliable survival. Pair compatible setup abilities with them. Respect daily free-tentacle limits instead of treating every summoned tentacle as free.                                                             |
| Witchess                             | Choose daily fights for useful outputs. An eligible free monster can seed a profitable copy chain; Bishop wine is a historical fallback, not a permanent optimum.                                                                                           |
| Genie bottle                         | Compare direct Meat, a saleable pocket wish, effects and a valuable summon/chain. Existing code caps direct Meat at 50,000 per wish at level 100+. A target chain must beat the foregone alternative, not merely have a valuable-looking drop.              |
| Pocket wishes                        | Price owned wishes at sale/replacement opportunity cost. Buy extra wishes only when their effect or encounter sequence beats that cost and fits the spending rules. Three bottle wishes do not make a fourth wish automatically unprofitable.               |

Embezzlers are uncopiable: Lucky! Treasury encounters remain an option, but an Embezzler copy chain is not a valid fallback.

## Resources missing or understated in the original ledger

| Resource                    | Recommended allocation and tradeoff                                                                                                                                                                               |
| --------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Peridot of Peril            | Equip before the relevant zone-specific encounter and target valuable collection monsters. Its once-per-zone opportunity is especially useful across several target locations.                                    |
| Chest Mimic                 | Allocate experience and eggs to eligible collection monsters or profitable free-monster chains. Charge displaced familiar income while earning experience.                                                        |
| Möbius ring                 | Use useful item-drop benefits during collection work and evaluate time-cop encounters separately. A maximum possible encounter count is not guaranteed daily income.                                              |
| Leprecondo                  | Satisfy needs when benefits exceed inputs and detours; feed useful outputs into the corresponding resource pools.                                                                                                 |
| Eternity Codpiece, if owned | Compare gem configurations and the accessory slots freed with the best full outfit. Do not book a benefit before ownership and actual gem choices are known.                                                      |
| Model train set, if owned   | Compare expected rewards over remaining encounters with TakerSpace and other worksheds, including installation restrictions.                                                                                      |
| Asdon Martin, if owned      | Buy fuel/buffs only for useful turns remaining. Coordinate driving, banishes and workshed changes under one plan.                                                                                                 |
| Dinseylandfill access       | Deduct day tickets from Barf returns. Compare a permanent charter with expected future ticket savings, charging for consuming a displayable charter. The historical 143k–153k ticket cost is not a current quote. |

## Garden and workshed choices

There is one garden slot and one workshed slot. Do not sum incompatible installations as simultaneous daily income. The route's one-change/commitment policy and rose reset protection are documented in [IoTM route](iotm-route.md#one-shared-garden-slot). A forecast is not today's booked income.

| Garden                                                   | Recommended decision                                                                                                                                         |
| -------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Black Rose                                               | Preserve established growth/layout; compare recurring actual nodes, fights and collection outputs with alternatives after reset losses.                      |
| Mushroom                                                 | Compare growth/harvest levels and native daily encounters with the alternatives. Do not count Mushroom encounters while assuming the rose occupies the slot. |
| Rock                                                     | Evaluate the independent plots and useful output gaps rather than treating every harvest identically.                                                        |
| Tall Grass                                               | Compare ordinary and mature rewards with growth time and known collection needs; use conservative values where reward probabilities are unknown.             |
| Thanksgarden                                             | Compare harvest schedules, future yields and finite collection gaps over the same horizon.                                                                   |
| Pumpkin, Peppermint, Skeleton, Beer and Winter, if owned | Evaluate actual growth and outputs as alternatives for the slot. Do not infer ownership, skip growth delays or treat special combats as ordinary harvests.   |

For worksheds, compare net benefit over the remaining day and expected future use. Surplus anchors alone are not a reason to replace TakerSpace, and collecting its delivery does not prove an automatic switch is worthwhile.

## Daily passive collections

Collect after establishing useful recovery and MP reserves. A free summon still consumes MP; an owned output retains sale or collection opportunity cost.

Recovery sources belong before MP spending:

- **Nuns:** take useful visits when the sidequest is available and enough MP is missing to avoid wasting the restoration. Preserve the planned casting reserve afterward.
- **Eternal car battery:** use its daily restoration when it displaces bought MP or prevents a stall, after arranging useful maximum capacity and sufficient missing MP.
- **Carbonated water lilies:** compare restoration with their sale/replacement and collection value. Owned lilies are an option after useful free sources, not costless MP.

| Source or output                   | Recommended allocation and tradeoff                                                                                                                                                                                                                               |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Hermit clovers                     | Acquire the daily allowance cheaply. Sell unless the best Lucky! reward exceeds the clover's sale value plus its paid adventure, or a funded unbuyable collection need justifies it. Clover items can be held; do not force a poor use merely to empty inventory. |
| Manual of Labor / worthless items  | Use as low-cost Hermit inputs, retaining operating copies. Avoid acquisition beyond useful demand.                                                                                                                                                                |
| Potted power plant / AAA batteries | Harvest available value. Compare direct sales with conversions and useful effects; do not assume seven identical batteries or one fixed sell price every day.                                                                                                     |
| Pastamastery / dry noodles         | Summon after recovery; compare ingredient sales, cooking and diet. Free cooking does not erase ingredient value.                                                                                                                                                  |
| Far Future tea                     | Sell surplus or retain needed copies unless eating it beats sale value after stomach displacement. Generation does not make it free food.                                                                                                                         |
| Rad Lib summons                    | Collect profitable output, protect collection needs and sell surplus at realizable prices.                                                                                                                                                                        |
| Infinite BACON machine             | Collect BACON and compare direct sale with store conversions, including useful unbuyable rewards. Choose by value per BACON.                                                                                                                                      |
| Bowl Full of Jelly                 | Compare consumption, conversion and sale after reserving collection copies.                                                                                                                                                                                       |
| Eye and a Twist                    | Sell surplus unless diet benefit exceeds sale value and organ displacement.                                                                                                                                                                                       |
| Chubby and Plump                   | Compare diet and sale rather than consuming automatically because it was summoned.                                                                                                                                                                                |
| Advanced Saucecrafting             | Compare reagent sales with profitable potions after all ingredients and crafting costs.                                                                                                                                                                           |
| Rhinestone summons                 | Summon when output value covers MP; reserve needed copies and liquidate surplus practically.                                                                                                                                                                      |
| Perfect Freeze                     | Compare cube sales with the incremental value of perfect cocktails, charging the cube as an input.                                                                                                                                                                |
| Dice summons                       | Compare each further summon with escalating MP costs; essential recovery and useful buffs come first.                                                                                                                                                             |
| Cocktail summons                   | Collect profitable inputs after bootstrap and craft only where finished drink value exceeds all inputs.                                                                                                                                                           |
| Crimbo candy summons               | Compare sales, diet and synthesis. Summoned candy spent on synthesis is still consumed stock.                                                                                                                                                                     |
| Snowball factory                   | Collect, retain collection needs and compare sale with effect use.                                                                                                                                                                                                |
| Cocoa dispenser                    | Collect and compare consumption with sale and organ displacement.                                                                                                                                                                                                 |
| Klaw machines                      | Take free plays; retain missing collectibles and sell surplus where demand exists.                                                                                                                                                                                |
| Looking Glass                      | Collect daily benefits and schedule useful effects before the work they improve.                                                                                                                                                                                  |
| Lathe                              | Compare available products with inputs and the daily-use opportunity. Reprice instead of fixing one craft.                                                                                                                                                        |
| Clan Potted Meat Tree              | Collect the direct Meat.                                                                                                                                                                                                                                          |
| Clan rumpus furniture              | Claim available adventures while they can be used without rollover-cap waste.                                                                                                                                                                                     |
| Etched hourglass                   | Claim adventures while profitable use and cap room remain.                                                                                                                                                                                                        |
| Other small dailies                | Apply retain/convert/sell consistently. A 500-Meat listing threshold ignores demand and alternative use.                                                                                                                                                          |

## Free fights and free kills

Use the remaining source counters and actual observed costs. Some sources require a particular familiar or equipment: the same fight cannot simultaneously support incompatible Sword, Professor, God Lobster and other familiar benefits.

| Resource                                                                        | Recommended allocation and tradeoff                                                                                                                                                                                                                 |
| ------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Rufus / Shadow Rifts                                                            | Value the entire quest/reward sequence, including the free-fight window it enables. Reserve quest inputs and choose the accessible Rift with the best useful drops. Do not count the same unlocked fights repeatedly.                               |
| CyberRealm                                                                      | Confirm access, OVERCLOCK and the chosen runner's readiness requirements. Use a valid cyber-combat strategy; constructs block ordinary skills. Replacements do not universally preserve free status, and the halfway choice needs correct counting. |
| LOV Tunnel                                                                      | Take useful free fights and choose rewards for collection, future adventures or useful effects. Fixed earrings/surgery/Echinacea choices need the same comparison.                                                                                  |
| Oliver's Place / speakeasy                                                      | Use available profitable free fights before overdrinking, with the best compatible familiar and setup abilities.                                                                                                                                    |
| Cursed magnifying glass                                                         | Earn useful void fights while charging accessory displacement during buildup. Remove when further use no longer pays.                                                                                                                               |
| Molehill mountain                                                               | Take the profitable free encounter and compatible setup benefits after restoration costs.                                                                                                                                                           |
| Glitch reward                                                                   | Take the worthwhile daily fight with reliable survival and combat handling.                                                                                                                                                                         |
| Mushroom garden fight                                                           | Include only under the chosen garden; compare its full benefit with that garden's alternatives.                                                                                                                                                     |
| Shattering Punch                                                                | Use on a worthwhile otherwise-paid encounter when turn savings exceed lost rewards and setup.                                                                                                                                                       |
| Gingerbread Mob Hit                                                             | Assign the daily use to the best compatible paid encounter, not an already-free fight or unnecessary purchased sandworm.                                                                                                                            |
| Apriling quad tom                                                               | Value its free sandworms by actual useful rewards and compatible abilities. Do not book reliable melange income without evidence.                                                                                                                   |
| NEP, Kramco, voting, God Lobster, X-Ray, bullseye, bat wings and Scepter fights | Follow their individual rows above. Their capacity is shared with all other routines reading the same counters.                                                                                                                                     |

A loot-preserving free kill usually belongs on an already-scheduled paid encounter. Using one on a drum-machine fight adds an avoidable item cost unless the summoned fight has enough additional value.

## Forced noncombats

Reserve forces before other routines spend their supporting rests, Cinch or casts. Target a valuable eligible noncombat-only collection reward, then compare the best remaining use with the **whole** Shadow Rift sequence, not merely its next choice reward.

| Resource                | Recommended allocation and tradeoff                                                                                                                                                       |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Campsite free rests     | Combine restoration with useful Cinch recovery. Rest after spending Cinch; recovery at full Cinch wastes later force capacity. Do not use all rests as an early generic MP pool.          |
| Fiesta Exit             | Choose eligible collection choices or the best remaining reward sequence. Recompute from current Cinch and usable rests, not a fixed daily count.                                         |
| Spikolodon spikes       | Launch on compatible scheduled free fights/kills where practical. Verify the intended next choice is forceable under this source's rules.                                                 |
| McHugeLarge Avalanches  | Use the same target-value comparison, including paid launch costs when needed. Keep separate source counters and eligibility.                                                             |
| Apriling tuba           | Choose the instrument when its three forces beat the alternative instrument's contribution. It is a daily selection, not permanently unavailable just because yesterday's picks differed. |
| Allied Radio Backpack   | If available, compare sniper support with other drops/buffs. The ledger audit did not establish ownership; exclude from confirmed capacity.                                               |
| Clara's bell            | If available, reserve its force for the best eligible target. Ownership was not established in the ledger audit.                                                                          |
| Pill Keeper / Sneakisol | If available, compare the free force and spleen-costing further forces with alternative Pill Keeper benefits and marginal spleen value.                                                   |
| Stench jelly            | Spend a spare/new copy only when the choice beats jelly price, spleen displacement and paid-turn costs. Display Case copies remain protected.                                             |

The 2026-11-24 audit counted 26 campsite free rests, which could support six Fiesta Exits under the recorded Cinch schedule. The first five rests each restore 30, then 25, 20, 15, 10, and five per later rest; an Exit costs 60. Recalculate with actual remaining rests/Cinch. Bat-wing upside-down rests are separate and remain an MP source.

## Banishes and escapes

Use persistent control for long blocks and short-duration banishes for grinds that finish within their duration. Count demand by monsters, active slots and coverage, not a flat number per grind.

| Resource                         | Recommended allocation and tradeoff                                                                                                                             |
| -------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Feel Hatred                      | Spend on bounded targeted work; avoid needless overwrites.                                                                                                      |
| Snokebomb                        | Use for a short targeted grind and include MP cost. Reserve before competing copy-chain work.                                                                   |
| KGB darts                        | Prefer grinds fitting their duration and minimize equipment commitment.                                                                                         |
| Reflex Hammer                    | Remove unwanted encounters where the bounded grind saves meaningful turns.                                                                                      |
| Throw Latte                      | Coordinate with useful refills, copies and gulps. A refill solely for a banish must pay its own costs.                                                          |
| Cosmic bowling ball              | Reuse when returned; track cooldown and its one active banish.                                                                                                  |
| Familiar scrapbook               | Spend a charged long-duration banish where it matters. Charge-building must justify off-hand displacement.                                                      |
| Spring Kick, if available        | Place its persistent banish on a monster unwanted for a long block, respecting its active-slot limit.                                                           |
| Spring Away, if available        | Use as an escape when conditions/cooldown permit. An escape is not a persistent banish.                                                                         |
| Saber Force banish               | Compare encounter control with other uses of the same five shared Force charges.                                                                                |
| Gingerbread restraining orders   | Spend spare/new orders when full turn savings exceed price and collection opportunity cost. A generic buff cost cap can reject a profitable banish incorrectly. |
| Mafia middle finger ring         | Reserve its limited banish for a block using the duration effectively.                                                                                          |
| Patriotic Screech                | Use when phylum removal improves the whole encounter distribution without excluding the desired target.                                                         |
| Hot-jelly banish                 | Compare control with the jelly's alternative uses and any organ cost.                                                                                           |
| Licorice rope                    | Protect collectible copies; spend surplus only when persistent control pays for the item.                                                                       |
| Monkey Slap                      | Consider before paw wishes on a monster whose exclusion outweighs its paid fight and destroyed drops.                                                           |
| Monodent lightning               | Use as one movable all-day banish; it takes a turn and retains drops. Eleven casts are not eleven active banishes.                                              |
| Heartstone banish, once unlocked | Price actual turn cost, duration and competing powers. Do not count locked uses.                                                                                |
| Ice house                        | Change its persistent target only after checking all routines that rely on the existing banish, including copy-chain setup.                                     |

## Copies, replacements and tracking

| Resource                            | Recommended allocation and tradeoff                                                                                                                                                      |
| ----------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Ordinary-monster copies             | Charge paid turns unless a verified effect makes the encounter free. Admit collection copies within a justified loss budget; compare farming with earning Meat and buying when possible. |
| Inherently free-monster copies      | Prefer useful eligible collection outputs or liquid drops, respecting source-specific limits. Good cash-chain candidates do not justify assuming every source works.                     |
| Glove / Macrometeorite replacements | Compare actual replacement distributions and free-status rules with the encounter displaced. Do not value every use as a guaranteed chosen monster.                                      |
| Backup camera                       | Validate the previous monster and compare its copy with other available targets before each use.                                                                                         |
| Pocket Professor lectures           | Use weight-dependent remaining capacity on the best eligible target after setup and familiar costs.                                                                                      |
| Locket / Mimic / Time-Spinner       | Target scarce eligible monsters with actual turn and input costs; reserve shared encounters and seed dependencies once.                                                                  |
| Recall Habitat                      | Allocate targeted follow-up encounters to worthwhile eligible monsters and verify carrier/free-status behavior.                                                                          |
| Map the Monsters                    | Save search turns for a useful zone monster; count the resulting encounter's actual cost.                                                                                                |
| Feel Envy / Nostalgic               | Reserve for valuable uncertain drops or a planned previous-monster sequence, not automatic scarab use.                                                                                   |
| Latte / Saber targeting             | Compare with the same source's banish, restoration or loot-guarantee alternatives.                                                                                                       |
| Olfaction                           | Track a monster wanted for a substantial upcoming block and reassess when targets change.                                                                                                |
| Gallapagosian Mating Call           | Add compatible tracking when it meaningfully increases desired encounters.                                                                                                               |
| Lucky! from untradeable sources     | Take the best eligible collection or cash encounter after its turn cost; there is no direct sale alternative for the Lucky! charge.                                                      |
| Lucky! from clovers                 | Apply the encounter test and also charge the clover's foregone sale value.                                                                                                               |
| Professor weight boosts             | Apply when extra lecture/chain return exceeds setup cost and displaced equipment.                                                                                                        |

## Diet, adventures and buffs

Use the [whole-day diet planner](diet.md), with one owner for organ capacity. The old fixed menu is a candidate list, not a permanent shopping instruction. Reserve access items only when needed and worthwhile; generated adventures must fit the day's spending and rollover plan.

| Resource                                  | Recommended allocation and tradeoff                                                                                                                                          |
| ----------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Stomach                                   | Optimize food, helpers, seasoning and digestion jointly. Reserve Drip capacity only when existing juice is insufficient and the target pays for the displaced diet.          |
| Liver                                     | Plan Ode, ordinary drinks, shotglass, sweat clearing, buff drinks and nightcap together.                                                                                     |
| Spleen                                    | Compare turn generation with synthesis, certainty, jelly effects and collection uses. The cheapest adventure item is not always the best use of the organ.                   |
| Sweat Out Some Booze                      | Use profitable available liver clearing and refill through the diet, after preserving enough sweat. Extra adventures must be usable.                                         |
| Mojo filters                              | Use up to the daily limit when marginal extra spleen value exceeds filter sale/replacement value. Keep operating stock; protected copies are not automatic cleaner supply.   |
| Perfect dark and stormy                   | Retain as a candidate while its net adventures/effects per liver beat current alternatives.                                                                                  |
| Splendid martini                          | Use only when it wins the remaining-capacity solve; being size one does not justify a premium by itself.                                                                     |
| Baked veggie ricotta casserole            | Compare with the full food catalog and effect/helper combinations rather than fixing it as the staple.                                                                       |
| Roasted vegetable of Jarlsberg            | Use as filler only when it is the best marginal use of remaining stomach.                                                                                                    |
| Agua de vida                              | Compare adventures, cost and spleen displacement with current alternatives.                                                                                                  |
| Grim fairy tales / other one-spleen items | Fill remaining capacity only when net adventure value beats alternative spleen uses.                                                                                         |
| Class chocolates                          | Evaluate successive diminishing returns individually and stop when marginal adventures no longer cover cost.                                                                 |
| Essential tofu                            | Buy when adventures beat price and the purchase fits current price/budget rules.                                                                                             |
| License to Chill                          | Use its restoration after maximizing the relevant capacity, at a point when it prevents further spending. Do not waste useful early recovery by automatically postponing it. |
| Magical sausages                          | Coordinate MP recovery and adventures under the same daily allowance. Eating one for MP still uses an adventure-generation allowance.                                        |
| Rollover gear                             | Maximize useful next-day adventures while respecting the rollover cap and required persistent equipment.                                                                     |
| Mafia thumb ring                          | Wear when expected saved turns exceed displaced accessory income.                                                                                                            |
| Circadian Rhythms                         | Recall early for the phylum actually planned most; do not permanently assume bug farming.                                                                                    |
| Latte rollover adventures                 | Arrange the useful refill before rollover if its gain exceeds the alternatives.                                                                                              |
| Mayam yam battery                         | Compare its total useful reward with other ring combinations and their enabled familiar/rest benefits.                                                                       |
| Frosty's frosty mug                       | Buy only when incremental adventures on the selected drink exceed cost, accounting for all helpers. Historical rejection prices are not permanent economic thresholds.       |
| Ol' Scratch's salad fork                  | Apply the corresponding incremental-food calculation, including helpers and the selected food.                                                                               |
| Abstraction: certainty                    | Use when incremental eligible drops exceed price plus displaced spleen value over useful duration.                                                                           |
| Sacramento wine                           | Compare adventures and item buff with the liver alternative; drink before useful drop encounters.                                                                            |
| Synthesis: Collection                     | Use when added eligible drops exceed candy costs and spleen displacement. Avoid credit for already-guaranteed drops.                                                         |
| Synthesis: Greed                          | Compare incremental cash-farm Meat with candy and spleen alternatives; it can beat Collection on a Meat day.                                                                 |
| Spider webs / synthesis candy             | Select a low-opportunity-cost eligible pair. Charge consumed stock and protect collection copies.                                                                            |
| Cyclops eyedrops                          | Reserve for a short valuable block whose added drop probability covers cost.                                                                                                 |
| Battery (car) / battery (lantern)         | Compare useful buff return with market value and constituent-battery opportunity cost.                                                                                       |
| Raven feathers                            | Sell/retain unless actual buff return justifies consumption.                                                                                                                 |
| Sorority brains                           | Compare marginal buff gains with price and all consumption costs.                                                                                                            |
| Frost flowers                             | Compare direct use with cheaper or expiring sources of the same effect.                                                                                                      |
| Affirmations                              | Buy only for a measured profitable block and preserve needed collectible copies.                                                                                             |
| Carrot juice                              | Count actual extra drops during useful remaining turns rather than nominal percentage.                                                                                       |
| Knob Goblin nasal spray                   | A plausible cheap Meat buff when zone base Meat and useful duration support it. Recalculate with current price.                                                              |
| Resolution: be wealthier                  | Include consumption rules and useful benefit; the old break-even description is not today's valuation.                                                                       |
| Skill-based buffs                         | Cast after recovery for useful turns remaining. MP and song slots have opportunity costs; Fat Leon's is an item-drop buff, not a Meat-drop buff.                             |

## Combat items and paid-turn grinds

| Resource or activity        | Recommended allocation and tradeoff                                                                                                                            |
| --------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Drum machines               | Protect the Museum target. Spend a spare/new machine only when the entire encounter benefit beats machine price, paid turns and alternative resource uses.     |
| Drum machine plus free kill | Usually worse than putting the kill on a scheduled paid fight because the machine is an added cost. Require additional summoned-encounter value to justify it. |
| Spice melange speculation   | Zero drops in 32 historical fights proves neither zero rate nor a profitable rate. Do not book reliable melange income from a high asking price.               |
| Divine champagne poppers    | Buy only when the enabled escape exceeds price and available alternatives are better reserved or unavailable.                                                  |
| Oasis scarab beatles        | Run for a specific remaining gap or measured liquid return. More filters/common outputs are not default income when existing stock already overwhelms demand.  |
| Oasis blurs                 | Consider for a deliberate drum-machine push or demonstrated profitable liquid drops. Compare with earning cash and buying needed machines.                     |
| Barf Mountain               | Default documented cash alternative. Measure net marginal return after access, restoration and buffs; exclude daily Sword windfalls from the turn benchmark.   |
| The Drip                    | Run for useful remaining gaps or demonstrated surplus profit. Spend stored juice before consuming access items; charge fresh nugget/wine for displaced organs. |
| Beer lenses                 | Require collection value or realizable proceeds sufficient for turns and banishes. Historical quoted output was weak as a pure cash grind.                     |
| Li'l ghost costume          | Run only for a meaningful remaining collection/operating gap; protect a worthwhile chain once started and stop when the target is met.                         |
| FantasyRealm                | Choose the daily reward and Rubee route by remaining needs. A once-daily allowance is not a reason to repeat a completed target indefinitely.                  |
| PirateRealm                 | Select rewards by missing items rather than always choosing Red Roger's reliquary. Charge the full voyage.                                                     |
| Spacegate                   | Pick planet/equipment for needed samples or research rewards. Fixed coordinates need a continuing target justification.                                        |
| Daily Dungeon               | Minimize turns with available tools; value the token by its useful reward and compare with the full run cost.                                                  |
| Gingerbread City            | Choose a missing item, conversion or realistic leaderboard objective before entering. Use actual city state and requirements.                                  |
| Bounties / filthy lucre     | Compare expected turns, banishes and progress toward a useful reward. Easy is a heuristic, not proof that the actual bounty pays.                              |
| Guzzlr deliveries           | Prefer profitable route overlap and include drink/setup/travel costs. Tier alone does not decide.                                                              |
| Sea zones                   | Use Fishy turns on the best remaining underwater targets, including access, survival and equipment displacement.                                               |
| Fishy pipe                  | Prepare the underwater block before starting the effect so useful duration is not lost to setup.                                                               |
| Dolphin whistle             | Recover the item only when collection/realizable value exceeds whistle, encounter and opportunity costs.                                                       |
| Airports                    | Evaluate each target and daily reward separately and deduct access costs. One owned airport does not establish access elsewhere.                               |
| Shore scrip                 | Charge both the trip's adventures and Meat; use only for a worthwhile reward or superior conversion.                                                           |

## Currencies and charges

Price a currency by its best remaining useful conversion and the resources needed to earn more. Do not count conversion value again after counting the resulting item.

| Balance or charge  | Recommended allocation                                                                                                                                                              |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Meat               | Keep operating liquidity and follow the day's permitted budget. The historical 141,519,354 balance is not a fresh cash total or spending authorization beyond the goals.            |
| TakerSpace anchors | Treat excess as abundant input, retaining scarce complementary supplies for the best products. The old balance was 1,826 anchors versus 3 spice, 4 rum, 4 masts, 2 silk and 1 gold. |
| Knucklebones       | Redeem for needed collectibles or profitable useful goods; bank only for a concrete better future use. Read the actual wallet and shop stock.                                       |
| Rubees             | Allocate among missing FantasyRealm goods and useful conversions. Food made from Rubees retains currency opportunity cost.                                                          |
| Guzzlrbucks        | Acquire remaining useful store rewards; reassess deliveries after those goals are met.                                                                                              |
| Spacegate Research | Save/spend toward selected useful rewards rather than low-value goods competing with a constrained target.                                                                          |
| Filthy lucre       | Save for the best remaining Hunter reward; bounty farming needs a new justification once targets are complete.                                                                      |
| Fat loot tokens    | Redeem for useful missing outputs; do not accumulate without a selected purpose.                                                                                                    |
| Sprinkles          | Compare collection goods, crafting, leaderboard commitments and surplus conversions in one budget.                                                                                  |
| BACON              | Convert only when goods beat sale or needed-currency retention.                                                                                                                     |
| Sept-Embers        | Spend the actual balance on the best remaining use, with a reserve only for a specific better option. The old balance was seven.                                                    |
| Cup jewels         | Allocate actual jewels and liver together. Do not confuse jewelry capacity with five independent free drinks.                                                                       |
| Interesting Coins  | Preserve productive principal and the selected chrysalis goal. Purchases cost future growth. The old ledger did not establish the wallet balance.                                   |
| Scrapbook charges  | Value a usable banish and its actual target, not an arbitrary value per charge. The old balance was 69, below the 100-charge banish threshold.                                      |

## NPC vendor discounts and bulk resale

**MSG is also deliberate trading stock, not just farmed surplus.** Sacha reports chewing a sleaze jelly, then buying roughly 10,000 MSG from an NPC vendor at a 10% discount: 900 Meat each instead of 1,000. The intended mall resale is 1,000 each. Keep this acquisition strategy separate from farming decisions.

At those reported prices, the batch costs 9M Meat and would return 10M if all copies sell at 1,000: **1M gross profit**, before the jelly's opportunity cost, displaced spleen use and any other costs. Unsold stock is inventory, not realized profit. Keep acquisition cost and sales separate from farming income and from Museum placement.

| Discount source                      | Use in this strategy                                                                                                                                                    |
| ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Sleaze jelly / Sleazy Jellied        | The 10% NPC discount can cover a bulk purchase of one item. Prepare the intended batch before consuming the discount; unrelated intervening NPC purchases can waste it. |
| Travoltan trousers                   | 5% off eligible NPC-store purchases while equipped. Check ownership, store eligibility and actual charged price before valuing a combined discount.                     |
| Five Finger Discount                 | Another 5% NPC discount when the skill is available. Do not assume this character has it.                                                                               |
| Post-holiday sale coupon / Black Day | A separate 10% discount candidate, but the documented restriction limits its purchase to one copy; do not project it across a 10,000-item batch like sleaze jelly.      |

The [KoLmafia discount discussion](https://kolmafia.us/threads/track-black-day-and-sleazy-jellied-npc-discounts.23013/) documents the bulk distinction, trousers/skill discounts and historical limitations in displayed `npc_price` estimates. Verify the actual purchase/Meat delta rather than assuming that an effect duration or cached quote means every later purchase remains discounted.

**Other tradeable NPC goods have been screened below.** Buy only a batch supported by demand and the available spending budget. Recheck access, quantity limits, discount stacking, actual charged price and competing sellers before acting. The screen is research; it does not automate purchases or establish a guaranteed sale price.

A positive-return resale purchase belongs in the goals' positive-return category even when its purchase discount is only 10%; the separate 20% threshold defines a qualifying bargain, not the minimum margin for every profitable investment. The existing spending cap and price ceiling still apply. Automation must use the intended vendor/batch and charge the discount once, not assume every independent buy receives it.

### NPC resale screen, November 26, 2026

**Implemented in daily spending:** `smmSpendRun()` now includes an NPC resale pass before collection purchases. It reads the installed vendor catalog and fresh Pricegun evidence, sizes a batch to at most 365 days of observed sales minus existing stock, and stays within the existing half-of-net spending budget. It compares pants-only profit with jelly-assisted profit after jelly and spleen costs. The pants stay equipped; each jelly is chewed immediately before one direct single-item bulk purchase. The dated shortlist below is research evidence, not a fixed shopping list. See [daily-spending.md](daily-spending.md#npc-resale-batches) for controls, stock accounting and interrupted-purchase handling. This implementation has been tested offline only; no live purchase or listing was made while adding it.

The complete screen is in [the dated NPC resale snapshot](data/npc-vendor-resale-2026-11-26.json). It covers **414 catalog offers, 377 distinct items and all 247 tradeable items** in KoLmafia's catalog at commit `3317ceb532e8bcd2d85d46b614d1ceae179e7a0f`. None of the item names were unmatched. Public Pricegun responses supplied recorded sales in the returned window for 173 tradeable items; 74 had no window sales, which means insufficient evidence rather than proven lack of demand.

The returned daily buckets span November 12–26 UTC; endpoint days may be partial. Counts below are **observed Pricegun sales across contributors**, not sales this shop can capture or a complete census of the market. The reference resale price is the whole-Meat floor of the lower of Pricegun's time-weighted value and the median unit price of its returned recent transactions. It is a historical reference, not a live lowest listing or a buyer's bid. Shared Mafia `mallprices.txt` was not used as the resale price because it can include NPC offers.

For an eligible shop, the modeled two-discount cost is `floor(base × 0.85)`: jelly's 10% plus one 5% pants discount, without Five Finger Discount. Verify the actual charge before relying on that stacking model. Current Mafia also recognizes **designer sweatpants** and their replica as alternative 5% discount pants; they do not add another pants discount on top of Travoltan trousers, and their gift-shop exception matters. Already-owned sweatpants may remove the need to acquire Travoltan trousers for these shops.

#### Best starting candidates

All amounts are Meat per item. Spread excludes the jelly, spleen opportunity cost and other batch costs. Shop access is conditional; the screen did not log into the account to check it.

| Item (ID)                            | NPC source and base        | Modeled cost, both discounts | Reference resale | Spread | Recorded units / active date buckets | Decision                                                                                                                                                                                                                                     |
| ------------------------------------ | -------------------------- | ---------------------------- | ---------------- | ------ | ------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Bowl of Scorpions (6681)             | Hidden Tavern, 500         | 425                          | 463              | 38     | 15,773 / 15                          | **Strongest new volume-backed candidate.** Unlock the tavern this ascension. At the reference price, pants alone cost 475 and lose money; the jelly creates the margin.                                                                      |
| MSG (1549)                           | Gouda's guild store, 1,000 | 850                          | 1,000            | 150    | 3,240 / 15                           | Confirms the original strategy; both discounts improve the modeled margin over the reported 900 purchase. Requires the appropriate guild/class access. Existing MSG stock and recorded turnover argue against another blind 10,000-copy buy. |
| Knob Goblin nasal spray (1515)       | Knob Dispensary, 150       | 127                          | 150              | 23     | 1,678 / 14                           | Repeated sales support a candidate batch once the dispensary is unlocked. Size it to sell-through and the jelly-versus-pants test below.                                                                                                     |
| Knob Goblin pet-buffing spray (1512) | Knob Dispensary, 250       | 212                          | 250              | 38     | 896 / 14                             | Another repeated-sales candidate, with a larger spread but lower volume than nasal spray. Requires dispensary access and enough batch size to justify the jelly.                                                                             |

**Illustrative batch, not a purchase instruction:** 1,000 Bowls of Scorpions at 425 cost 425,000 and would return 463,000 if all sell at 463. That is 38,000 before batch costs, or 35,500 after a jelly valued at 2,500, before spleen and other costs. That batch is about 6.3% of all units recorded in the window; the evidence does not promise that share or immediate sales. Reserve budget and choose quantity from actual shop sell-through.

#### Margins that do not automatically justify a jelly

These items also have positive modeled spreads, but many are better stocked with pants alone in modest batches. Cheaper alternatives in another NPC store must be accessible before using their price.

| Item (ID)               | NPC source and base          | Modeled cost, both | Reference resale | Spread | Recorded units / active buckets | Practical treatment                                                                                                              |
| ----------------------- | ---------------------------- | ------------------ | ---------------- | ------ | ------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| Lemon (332)             | Eligible Hippy Store, 70     | 59                 | 100              | 41     | 1,906 / 14                      | Repeated sales, but a jelly saves only 7 more per copy than pants alone. Verify store access without a pants-conflicting outfit. |
| Olive (245)             | Eligible Hippy Store, 70     | 59                 | 100              | 41     | 7,068 / 14                      | 6,241 units occurred in one date bucket; do not extrapolate that spike into steady demand. Same outfit/access restriction.       |
| Grapefruit (243)        | Eligible Hippy Store, 70     | 59                 | 100              | 41     | 4,895 / 14                      | 4,771 units were in one bucket. Restock against actual sales, not the headline volume.                                           |
| Grapes (244)            | Eligible Hippy Store, 70     | 59                 | 100              | 41     | 178,582 / 3                     | 178,538 units were in one bucket. A speculative enormous batch is not justified by this concentrated history.                    |
| Fermenting powder (247) | General Store, 70            | 59                 | 100              | 41     | 147,555 / 2                     | 147,550 units were in one bucket. Keep as a spike-driven watch candidate rather than assume repeat daily demand.                 |
| Sprocket (119)          | Degrassi Knoll, 20           | 17                 | 100              | 83     | 1,632 / 15                      | Useful small resale stock if Knoll is accessible. Jelly improves cost by only 2; pants alone usually wins for a modest restock.  |
| Cog (120)               | Degrassi Knoll, 20           | 17                 | 100              | 83     | 1,625 / 15                      | Same economics: preserve the jelly unless the batch is genuinely large enough.                                                   |
| Spring (118)            | Degrassi Knoll, 20           | 17                 | 100              | 83     | 1,261 / 15                      | Same 2-per-copy incremental saving, with less observed demand.                                                                   |
| Tires (136)             | Degrassi Knoll, 28           | 23                 | 100              | 77     | 799 / 15                        | Only 3 extra saved per copy with jelly. Start with pants-only restocks.                                                          |
| Empty meat tank (124)   | Degrassi Knoll, 20           | 17                 | 100              | 83     | 337 / 14                        | Positive resale spread, insufficient evidence for a jelly-sized bulk restock.                                                    |
| Wad of dough (159)      | Madeline's Baking Supply, 40 | 34                 | 100              | 66     | 472 / 5                         | Cheaper than the 50-Meat stores if the Armory quest is finished. The jelly saves only 4 per copy versus pants.                   |
| Taco shell (173)        | Madeline's Baking Supply, 60 | 51                 | 100              | 49     | 582 / 2                         | Positive spread but concentrated sales; do not assume stable bulk turnover.                                                      |
| Skewer (165)            | Madeline's Baking Supply, 60 | 51                 | 100              | 49     | 574 / 3                         | Same small incremental jelly saving and concentrated demand.                                                                     |
| Gnollish pie tin (158)  | Madeline's Baking Supply, 25 | 21                 | 100              | 79     | 92 / 7                          | Small pants-only inventory; jelly savings of 2 per copy do not support a speculative bulk purchase.                              |

Thin but positive-spread watch items are **Synapse Blaster** (11678: Hack Market 500 → 425, reference 469, spread 44, 165 units/13 buckets; CyberRealm access required), **high-test fishing line** (9010: General Store 2,500 → 2,125, reference 2,323, spread 198, 61 units/4 buckets; fishing pole required), **drippy nugget** (10445: 10,000 → 8,500, reference 8,994, spread 494, eight units/eight buckets), and **glass of drippy wine** (10446: 10,000 → 8,500, reference 9,001, spread 501, five units/five buckets). The Drip items require actual shop/charge confirmation and comparison with already-held stock; do not buy large batches merely because the unit margin is positive. **Kickback cookbook** (521: 4,000 → 3,400, reference 4,000, six units/three buckets) is similarly too thin to support a large new batch, and has guild/class access restrictions.

#### Charge the jelly once per batch, and compare pants alone

The queried jelly reference was 2,500 Meat. Let `F` be that opportunity/replacement cost **plus displaced spleen value and any other setup cost**. For a batch of `Q` copies:

```text
batch profit = Q × (reference resale - modeled two-discount cost) - F
strictly profitable quantity = floor(F / per-copy spread) + 1
```

When pants-only resale is already profitable, spending a jelly must also beat that cheaper setup:

```text
extra saving from jelly = Q × (pants-only cost - two-discount cost)
use jelly only when extra saving > F
```

With `F=2,500` and **no spleen/setup displacement**, the extra-saving test needs 51 Bowls, 26 MSG, 167 nasal sprays, 101 pet sprays, 358 of a 70-Meat fruit/powder, or 1,251 of a 20-Meat part. These are marginal-jelly thresholds, not minimum quantities for every resale opportunity; pants-only profits and doing nothing remain alternatives. A 1,251-part batch is most of the recorded window's demand for some parts, so chasing the discount can be worse than a small pants-only restock. Increase every threshold when spleen is scarce. Use one jelly per separate intended single-item batch, not one jelly for the whole multi-item shortlist.

For Bowls specifically, pants-only resale loses money: compare with skipping the trade, which needs **66 copies** to cover a 2,500-Meat jelly at a 38-Meat spread. The 51-copy figure above measures the extra discount only and is not that trade's profit threshold. If spleen/setup brings `F` to 11,000, the strict profit threshold becomes 290 Bowls. Both tests matter when choosing a batch.

#### False positives and access restrictions

- **Closed Crimbo shops:** candles, Carols, tattoo kits, old cafe foods and ornaments retain catalog prices but are not current bulk vendors. Current Mafia explicitly marks these historical shops closed.
- **White rice:** attractive 250 → 212 versus reference 512 and 572 recorded units, but the General Store offer is Sea-path-only. Exclude from an ordinary unrestricted-aftercore shopping list.
- **Nervewrecker's appliances:** the 500-Meat Dramatic range and Queue Du Coq kit offers are Bad Moon-only. Their attractive sales histories do not make those prices available to this aftercore run.
- **Green rockets and holiday goods:** green rockets require both Dependence Day and St. Sneaky Pete's Day. Other fireworks, party hats and marshmallows have their own holiday gates. Do not project today's access from old sales.
- **Heavy-duty umbrellas and water wings for babies:** path-gated Heavy Rains offers, not ordinary General Store stock for unrestricted aftercore.
- **Nuclear Autumn vault shops:** cheap holo-records and radiation supplies are path-restricted, not current unrestricted stock.
- **Outfit conflicts:** Bugbear Bakery requires its costume, and some Hippy Store states require an outfit. A required pants slot can invalidate the combined discount. Madeline's cheaper baking offers have a different quest gate.
- **Guild stores:** Gouda's requires a Mysticality class or level-9+ Accordion Thief and an open guild. A historical Turtle Tamer snapshot must not be treated as proof of current MSG-vendor access; Sacha's reported purchase remains a historical observation.
- **Chinatown:** requires strange goggles and a suspicious jar. Bonsai trees show only 12 units in six buckets despite a high margin; they are not established bulk demand.
- **Doc Galaktik:** the completed-quest discount changes the base calculation; evaluate that case separately rather than apply the generic 85% model blindly.
- **'Villa' document and drippy caviar:** no sales in the returned window. High old quotes do not support tying up a large cash balance. Drippy truncheon/petri-dish references likewise did not support a positive margin under the conservative method.

Evidence: [revision-pinned NPC catalog](https://github.com/kolmafia/kolmafia/blob/3317ceb532e8bcd2d85d46b614d1ceae179e7a0f/src/main/resources/data/npcstores.txt), [store access rules](https://github.com/kolmafia/kolmafia/blob/3317ceb532e8bcd2d85d46b614d1ceae179e7a0f/src/main/java/net/sourceforge/kolmafia/persistence/NPCStoreDatabase.java), [pants discount handling](https://github.com/kolmafia/kolmafia/blob/3317ceb532e8bcd2d85d46b614d1ceae179e7a0f/src/main/java/net/sourceforge/kolmafia/request/NPCPurchaseRequest.java), and the public Pricegun API, for example [Bowls](https://pricegun.loathers.net/api/6681), [nasal spray](https://pricegun.loathers.net/api/1515), [pet spray](https://pricegun.loathers.net/api/1512) and [jelly](https://pricegun.loathers.net/api/9294). The dated snapshot preserves all 247 screened items, prices, volumes and access flags. No game purchase, consumption, listing or account action was performed.

## Stockpiles: retain, place, then sell what will move

These quantities are from the November 21 stocking snapshot and are retained as a baseline, not a current inventory. Held excludes shop and Display Case stock. Reconcile current quantities before allocating them.

Keep operating copies, fill worthwhile case gaps and offer quantities the market will absorb. Compare larger deposits with a measured sales horizon for stock unlikely to sell. An extra 1,000 copies does not permanently lock a competitive rank. A decision to deposit long-term excess must account for upward-only placement: the automation normally does not take it back out.

| Item                                     | Historical held / case                      | Recommended allocation                                                                                                                                                                                |
| ---------------------------------------- | ------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Mojo filter                              | 42,343 / 4,130 (#1)                         | Keep profitable cleaner and measured sale stock. Compare a stronger case buffer with realistically saleable surplus; stop adding large production without demand.                                     |
| Special Seasoning                        | 16,554 / 12,811 (#2)                        | Reserve the current selected rank gap and keep it out of automatic eating. Spare copies may be consumed when their adventure benefit beats sale value. The old 22,904-copy gap is not a fresh target. |
| Maxwell's Silver Hammer                  | 77,164 / 10,011 (#1)                        | Sell modest quantities at realistic prices; compare stock beyond a reasonable sales horizon with a stronger case position.                                                                            |
| MSG                                      | 68,087 / 3,680 (#1)                         | Trading stock as well as farm drops: buy discounted NPC batches for resale. Record cost basis and realized margins; see NPC vendor discounts above. Retain operating/collection copies.               |
| Happiness                                | 43,611 / 16,176 (#1)                        | Size shop stock by turnover; consider case placement for long-term excess.                                                                                                                            |
| Cyborg stompin' boot                     | 911 / 1,112 (#1)                            | Sell gradually where genuine demand exists; high price per copy does not establish bulk liquidity.                                                                                                    |
| Rough fish scale                         | 85,421 / 1,351 (#2)                         | Secure an affordable accepted place and reasonable buffer. Compare the enormous historical #1 gap with many cheaper milestones before pursuing it.                                                    |
| Savory dry noodles                       | 13,368 / 1,548 (#1)                         | Keep useful crafting stock, sell realistic quantities and consider placement of excess with little prospective demand.                                                                                |
| Drippy truncheon                         | 730 / #1                                    | Preserve case requirements and sell to observed demand rather than multiplying one quote by all stock.                                                                                                |
| Drippy nugget                            | 1,408 / #1                                  | Reserve only profitable Drip-access needs; compare sale and placement for the rest. Consumption also costs stomach capacity.                                                                          |
| Drippy wine                              | 1,019 / #1                                  | Reserve worthwhile access, then compare sale and placement. Include liver displacement when drinking.                                                                                                 |
| Drippy petri dish                        | 843 / #1                                    | Retain collection requirements and sell according to actual demand.                                                                                                                                   |
| Counterfeit city                         | 300 / 509 (#1)                              | Preserve the target, compare conversions and list surplus gradually.                                                                                                                                  |
| Absentee voter ballot                    | 1,410 / 1,207 (#1)                          | Retain operating/collection copies and offer surplus in realistic quantities.                                                                                                                         |
| Grungy bandana                           | 7,807 / 880 (#1)                            | Sell into demonstrated demand; compare unsaleable long-term excess with placement.                                                                                                                    |
| Sleaze jelly                             | 3,910 / 380 (#1)                            | Reserve spare copies for profitable bulk NPC discounts as well as other effects. Compare batch savings with jelly/spleen cost before selling; protect the case. See NPC vendor discounts above.       |
| Rare drippy grub, stake, plum and khakis | Not fully quantified                        | Preserve valuable collection copies. Extreme asking prices need actual sales evidence before entering income estimates.                                                                               |
| Mourning wine                            | Not fully quantified                        | Protect the collectible and charge scarce replacement cost for consumption.                                                                                                                           |
| Gingerbread dog treats                   | Not fully quantified                        | Preserve collection needs and price any use against reliable acquisition/sale evidence.                                                                                                               |
| Globs of undifferentiated tissue         | 24,017 case copies reported after a deposit | Verify the resulting rank and current competitors. Add only a justified gap or defense amount.                                                                                                        |

The old approximately 700M stock estimate used shop asks. It is not an amount available to fund today's purchases. Realized surplus sales count under the documented spending accounting and should be reported separately from recurring production.

## Display Case purchase queue

[daily-spending.md](daily-spending.md) reports that nine cheap #1 gaps, costing about 2.5M, were bought by hand on November 24. The first nine rows below preserve the old candidate list; verify completed placements and defend refreshed ranks instead of repeating those purchases. Competitive counts and bulk prices can change.

| Item                    | Historical estimated gap cost          | Recommended next action                                                                                 |
| ----------------------- | -------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| Denastified haunch      | 93k                                    | Refresh the ranking and buy only a new affordable gap.                                                  |
| Spray chrome            | 100k                                   | Verify completed placement; discard the old 1,002-copy shopping quantity.                               |
| Haunted pizza           | 129k                                   | Verify rank and protect needed copies from consumption.                                                 |
| Haunted bottle of vodka | 83k after held stock                   | Verify placement before consuming or selling remaining copies.                                          |
| Haunted orange          | 87k after held stock                   | Recalculate the current gap and protect needed ingredients.                                             |
| Ghostly ectoplasm       | 243k                                   | Maintain the selected place from refreshed counts, not the old 1,430-copy gap.                          |
| Impure gasoline         | 385k after held stock                  | Confirm which held/purchased copies reached the case, then recalculate.                                 |
| Filthy monkey head      | 472k                                   | Verify the current place and compare defense with other attainable milestones.                          |
| Haunted Hell ramen      | 946k                                   | Protect the reported completed collection and buy only a justified new gap.                             |
| Z-Bone steak            | 360k for top ten after 150 held copies | Check whether deposit/purchases occurred; compare any remaining whole gap with other attainable places. |
| Viral DNA               | 1.3M                                   | Reprice the complete attainable gap and compare cost per milestone.                                     |
| TI-9000 calculator      | 2.3M                                   | Use refreshed ranks, actual quantity available and the average-price ceiling.                           |
| Unused soap             | 2.8M                                   | Protect collectible copies from casual use and compare the whole gap.                                   |
| Stench jelly            | 3.6M                                   | Reserve the collection allocation separately from useful forced-choice consumption.                     |
| Bottle of clam juice    | 3.8M                                   | Check market depth and full gap cost before a large commitment.                                         |
| Chocolate Spider Queen  | 4.8M                                   | Protect collectible copies from automatic use and compare cheaper milestones.                           |
| Personal graffiti kit   | 6.1M                                   | Charge collectible destruction for use; buy for rank only when the whole milestone fits.                |
| Tarnished bottlecap     | 7.6M                                   | Price available volume rather than multiplying a single quote by the gap.                               |
| Fiberglass insulation   | 10M                                    | Rank against cheaper opportunities unless current prices/ranks materially improve it.                   |

The old `dc rankup` ceiling of 1.05 times a mall quote is not necessarily the allowed ceiling in the goals. Use recent average sale price and the remaining permitted budget. `dc --dry-run rankup <item>` is a preview, not a replacement for those constraints. Do not claim a rank until placement and a usable ranking snapshot confirm it.

## Recommended daily order

1. Reconcile the case, wallet, inventory, daily counters and unknown collection values. Protect inputs before consumers run.
2. Recover MP before expensive summons/moods; reserve campsite rests for useful Cinch recovery.
3. Choose concrete collection targets and reserve their turns, encounters, organs and ingredients.
4. Choose the garden, workshed, Sword seed and instrument combination from those targets and current economics.
5. Collect worthwhile no-turn dailies, then use selected Lucky!, forced-choice and targeted-encounter opportunities with their actual paid-turn budgets.
6. Finish justified daily-limited collection work. Stop completed/weak grinds rather than exhausting allowances automatically.
7. Use remaining profitable free fights, copies, familiar abilities and cash-farming turns. Respect existing resource reservations across runners.
8. Place needed outputs, sell realistic surplus quantities and spend the permitted share of realized net.
9. Finish diet/nightcap and rollover preparation without consuming protected stock or wasting adventures at the cap.

## What still needs current evidence

- Read current ownership, unlocks, source counters, wallets and garden/workshed state. Script references and old preferences are not proof of availability today.
- Refresh the Museum ranking store and target register; compare actual case counts, held stock and competitors. Unknown rankings block speculative consumption/sales.
- Measure marginal cash-farm return, liquid sales volume and operating costs. Keep Sword replacement gains and one-off stock liquidation separate.
- Check actual free status and eligible combat abilities for every carrier/replacement chain. Record setup costs, consumed inputs, banish overwrites and failed actions that spent resources.
- Compare the best forced-choice targets with the full Rift reward sequence. Source-specific restrictions and paid launch costs can change the winner.
- Review coverage and execution receipts. The current scorecard reports remaining unlock/automation gaps and code that still needs live validation; this ledger does not close them by documentation alone.

## Evidence and sources

### Repository evidence

- [Aftercore goals](aftercore-goals.md), [collection objective](collection-objective.md), [target register](target-register.md), [daily spending](daily-spending.md), [diet](diet.md), [IoTM route](iotm-route.md), [resource planner](resource-planner.md), [daily script plan](daily-script-plan.md) and [scorecard](daily-script-scorecard.md).
- [KoL expert memo](daily-script-council/claude-2-kol-expert.md) and [garbo expert memo](daily-script-council/claude-4-garbo-expert.md), checked against their corrections in the merged daily plan. Memo claims explicitly left unverified are not promoted to observed account facts here.
- `data/smm-prefs.txt`: both turn values are 4,500 in this revision. `scripts/smmUnrestricted.ash`, `smmIotmRoute*.ash`, `smmDailyTasks.ash`, `smmDiet*.ash` and related code establish current policy/coverage, not successful live results.
- The original ledger cited November 19–24 session/state evidence, shared mall prices dated November 22, the Museum rank store and installed KoLUtils. Those historical observations have not been refreshed for this revision.
- Installed Tour Guide and Far Future source were consulted for Time-Spinner allocation, Cinch recovery, God Lobster reward restrictions, club powers, Monodent and other mechanics. Their observed behavior still needs current source counters and encounter compatibility.

### Public mechanics references

- [Official KoL changes](https://kingdomofloathing.com/static.php?id=trivial): Embezzler copying restriction and free-tentacle limit.
- [Monodent mechanics](https://www.loathers.net/analysis/2025-09-monodent/): one active lightning banish, retained drops and flooding/Fishy costs.
- [CyberRealm overview](https://www.loathers.net/analysis/2025-12-cyberrealm/): OVERCLOCK, cyber combat and replacement restrictions.
- [Apriling band options](https://loathers.net/analysis/2024-04-apriling-band-helmet/): instrument choices and abilities.
- [Book of Facts](https://www.loathers.net/analysis/2023-09-bofa/): Habitat, facts and Rhythms.
- [Prismatic beret](https://www.loathers.net/analysis/2025-06-beret/): outfit-power targeting and useful short effects.
- [Bastille implementation notes](https://kolmafia.us/threads/r26319-initial-development-of-bastille-battalion-support-by-verac.27420/): five games versus first-game configuration rewards.
- [TakerSpace recipes](https://www.loathers.net/analysis/2024-12-takerspace/): shared supplies and competing conversions.
- [garbo documentation](https://github.com/loathers/garbage-collector/blob/main/README.md): maintained runner options and scope; Museum protection and spending rules remain separate responsibilities.
