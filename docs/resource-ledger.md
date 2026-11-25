# Tquilla resource ledger

Nov 22, 2026 · Sacha

> Snapshot of the [live ledger doc](https://claude.ai/artifact/Xjw56BRhKZwbubhQu9WTSM), exported 2026-11-25. Edit the doc, then re-export here.

Every day Tquilla can spend about **350,000 Meat of free breakfast items, \~45 free fights, 7+ free kills, 40+ copies and replacements, and \~230 diet adventures that cost under 1,650 Meat each**, against a turn value of 5,000. On top of that sit 141.5M Meat and roughly 700M Meat of sellable stock beyond the Display Case. Only resources that gain Meat or Display Case items are listed, and every table has a best-use column. MP, banishes and paid turns are the bottlenecks; stock, anchors and two unused free-fight sources are the surpluses.

- **Biggest daily lines:** filling all three organs (\~230 adventures), 3 hermit clovers (\~97,000), 3 legendary noodles (\~61,500), 7 AAA batteries (\~56,600), the Time-Spinner tea (\~39,800).
- **Cheapest Museum gains:** nine #1 places for about 2.5M Meat in total (haunted foods, ghostly ectoplasm, spray chrome, impure gasoline and others).
- **Unspent today:** 20 free fights a day (CyberRealm and Snojo) have no automation, and the shrunken head and Monodent are not adapted yet.
- **Fix first:** the 2026-11-21 grind stopped after running out of MP, and Mafia's `valueOfAdventure` is 500 while the scripts use 5,000.

The report builds on the repo's [aftercore goals](https://github.com/sachamm/KoL/blob/main/docs/aftercore-goals.md), [target register](https://github.com/sachamm/KoL/blob/main/docs/target-register.md), [IoTM route](https://github.com/sachamm/KoL/blob/main/docs/iotm-route.md) and [resource planner](https://github.com/sachamm/KoL/blob/main/docs/resource-planner.md), plus the live KoLmafia state on the Windows machine. Each IoTM line says how sure the ownership is.

## Bottlenecks and surpluses

The day is limited by **MP, banishes and paid turns**; Tquilla is long on **sellable stock, TakerSpace anchors and unused free fights**. Fix the bottlenecks first, because each one caps the Oasis grind that earns most of the Meat.

| Resource | State | Evidence | Action |
| --- | --- | --- | --- |
| MP | Bottleneck | The 2026-11-21 run ended at 10 of 20,340 MP after `burnMP` spent 17,797 on song buffs; later casts failed | Keep a reserve of \~2,000 MP (raise `gUnrestrictedManaToSave` or pass a reserve to `burnMP`); take the 11 bat-wing rests, nuns and the eternal car battery before casting songs |
| Banishes | Bottleneck | \~13 a day; demand \~17 (Oasis, 4 beer lens, 8 ghost costume, 5 bounty) | Turn off the ghost-costume grind once the case has enough (`set smm.dailyGrind.ghostCostume = false`); use the scrapbook and cosmic bowling ball every Oasis day |
| Paid turns | Bottleneck | \~400 a day (169 after breakfast plus \~230 from diet) at 5,000 each; the route and 9 grinds compete | Let the turn-value test drop weak grinds after 5 days; spend free kills only on paid fights |
| Item-buff budget | Self-imposed cap | 100 Meat a turn in `grindMeatWithItemDrop` | Fine at today's prices; raise only for a short Museum push |
| Liver, stomach, spleen | Fixed | 20 / 15 / 15 | Always fill; sweat 3 booze; 3 mojo filters for spleen |
| Sellable stock | Surplus | \~700M at asking price: mojo filters, hammers, MSG, happiness, noodles, fish scales | Lock close leads with small deposits (1,000 mojo filters, 1,000 rough fish scales), then sell a few thousand a day at market |
| TakerSpace anchors | Surplus | 1,826 against 1 to 4 of each other supply | Craft anchor-heavy products; consider the model train set in the workshed until the other supplies matter |
| Free fights | Surplus | CyberRealm 10 and Snojo 10 a day unused | Add both to `burnFreeCombats` |
| Meat | Surplus for the Museum | 141.5M; nine #1s cost \~2.5M | Buy them now (Display Case section) |
| Copies and replacers | Surplus without a target | 40+ a day | Aim them at scarab beatle swarms unless a locket target is worth more |
| Forced noncombats | Scarce | 14 a day (5 spikes, 6 Fiesta Exits, 3 Avalanches); Shadow Rifts are the only spender, and neither the 11-21 nor the 11-23 log shows a Fiesta Exit | Never spend a free rest on MP; aim each forced noncombat at the best choice of the day (see Forced noncombats) |

## Daily passive income

Breakfast and the no-turn daily items are worth roughly **350,000 Meat a day** at today's mall prices, plus 14 adventures. All of it is already collected by Mafia's breakfast and `secondBreakfast()`. These lines are confirmed: every one appears in the 2026-11-21 session log.

| Source | Daily output | Value (Meat/day) | Best use |
| --- | --- | --- | --- |
| Hermit, via Manual of Labor and worthless items | 3 11-leaf clovers | \~97,000 | Spend as Lucky! adventures on a Museum target or a drop worth more than 32,400; otherwise sell. Never let them pile up |
| Potted power plant | 7 battery (AAA) | \~56,600 | Sell at 8,090 each; keep a few to combine into battery (car)/(lantern) only when you need +100% item for a big target |
| Legendary pasta wand and Pastamastery | 3 legendary noodles, 5 dry noodles | \~63,000 | Sell the legendary noodles (20,500); the IoTM route's free cooks turn dry noodles into the best meal only when it beats the sale |
| Time-Spinner, Far Future | Tea, Earl Grey, Hot | \~39,800 | Sell; `FarFuture food` already runs in `setupItems` |
| Rad Lib summons | 6 Rad Libs | \~18,300 | Sell in the shop |
| infinite BACON machine | 100 BACON | \~17,000 | Spend at the BACON store if a product beats 170 Meat a BACON, else sell |
| Candy cane sword cane, Overgrown Shrine | 10,500 Meat | 10,500 | Keep in `setupItems` (`burnCandyCaneSwordCane`) |
| April Shower Thoughts shield | 2 globs of wet paper | \~10,000 | Sell; nothing crafts them into more yet |
| Bowl Full of Jelly, Eye and a Twist, Chubby and Plump | 3 consumables | \~8,300 | Sell Eye and a Twist (6,349); drink or sell the rest |
| Advanced Saucecrafting | 5 scrumptious reagents | \~4,200 | Sell, or use as potion inputs if `burnFreeCrafting` finds a profitable recipe |
| Rhinestones, Perfect Freeze, dice, cocktail and Crimbo candy summons | small items | \~9,000 | Sell perfect ice cubes (2,251); autosell the minimum-price ones |
| Snowball factory, cocoa dispenser, Klaw machines, Looking Glass, lathe and other small dailies | small items | \~6,000 | Keep collecting; sell anything over 500 Meat |
| Clan Potted Meat Tree | 962 Meat | 962 | Breakfast |
| Clan rumpus room furniture | 9 adventures | 45,000 at 5,000/turn | Breakfast |
| Etched hourglass | 5 adventures | 25,000 at 5,000/turn | Breakfast |
| Beach Comb, 10 free walks | sand, sea grapes, driftwood, sand dollars | \~5,000 | Comb twinkle squares first (the comb script already does); keep 1 walk for the familiar buff |
| Sept-Ember Censer | 7 embers banked | route | Let the IoTM route buy the best product; set `smm.IR.emberReserve=0` |
| TakerSpace (installed workshed) | 1 supply delivery | route | Anchors are a surplus (see Bottlenecks and surpluses) |

Prices are KoLmafia's shared mall prices from 2026-11-22. Items at 100 Meat are usually priced at the mall minimum and are worth less than shown.

## IoTMs and their powers

About 75 owned IoTMs and IoTM-granted skills show up in the logs, and almost all have a net-positive daily use that some script already spends. The table is newest first. **Evidence** says how sure the ownership is: *used 11-21* (in the 2026-11-21 log), *skill* (in the character's skill list), *2024* (a daily counter reset from the last saved Mafia state, February 2024), or *script only* (the repo has code for it, but nothing in the logs proves Tquilla owns it).

Values use the scripts' turn value of 5,000 Meat. A free kill is worth a turn plus the monster's loot; a free fight is worth its loot. Release months before 2022 are from memory and may be off by a little; the route doc has the exact months for newer items.

### 2025 to 2026

| IoTM | Net-positive power | Rough value | Spent by | Evidence | Best use |
| --- | --- | --- | --- | --- | --- |
| legendary acorndion (2026-11) | Plant acorns in zones: sniff, MP, terrain effects, up to 12 plantings | Unpriced | IoTM route | script only | Plant sniff acorns in the Oasis on scarab beatles; set `smm.IR.acornTarget.<Oasis id>.SNIFF` |
| black garden rose (2026-10) | Garden loot, free fights, fountain Lucky! | Garden slot | IoTM route garden planner | script only | Let `iotmroute plan` pick the garden; keep `allowRoseReset=false` |
| Meat Shield Maiden (2026-09) | Six blessings, Tax Shield | Small | IoTM route | script only | Only on free garden fights; don't spend a paid locket turn on it |
| Interesting Coin (2026-08) | Daily goods, resale, Gross Prophet chrysalis | Compounding | IoTM route | flagged owned | Buy the chrysalis once 10M coins are saved, display the hatchling; until then only daily goods |
| Cup of 13s (2026-07) | 13 jewels into drinks, 5 charges | Liver-gated | IoTM route | counters | Use only when a Cup drink beats perfect dark and stormy per liver point (\~6.2 adv) |
| Sword of S Words (2026-06) | Swap loot, 100 a day | Loot gap | IoTM route | script only | Equip on the Oasis familiar; target a monster with a sellable or Museum drop |
| legendary pasta wand (2026-05) | 3 legendary noodles, 5 free cooks | \~61,500 | breakfast, route | used 11-21 | Sell noodles; free cooks only for meals worth more than inputs |
| Baseball Diamond (2026-04) | 3 innings | Small | IoTM route | script only | Run the 3 innings in route; skip if it costs a paid turn |
| Archaeologist's Spade (2026-03) | 11 digs | By zone | IoTM route | script only | Dig in the farm zone (Oasis) after each fight, not in a setup turn |
| Heartstone (2026-02) | Buffs and Lucky! once unlocked | None yet | IoTM route | flags false | Unlock the Lucky! power first (1 free Lucky! a day, \~32,000) |
| legendary seal-clubbing club (2026-01) | 15 charges | Unvalued | unused | script only | Use Into Next Week on a mojo filter or embezzler target; ignore Back in Time (destroys drops) |
| Skeleton of Crimbo Past (2025-12) | Knucklebones, daily special | Resale | IoTM route | script only | Buy the daily special when its resale beats the bones; keep `boneReserve=0` |
| shrunken head (2025-11) | Zombie abilities | Not adapted | nothing | flagged owned | Pick a +meat/+item zombie and keep it on while farming; needs an adapter |
| blood cubic zirconia (2025-10) | Blood thinner, tapas, cocktail | \~250 each | route, 3 casts | skill | First 3 casts of each only (`smm.IR.bczCasts=3`); stop after |
| Monodent of the Sea (2025-09) | Wave, lightning | Not adapted | nothing | skill | Summon a Wave daily in the farm zone for its bonus; needs an adapter |
| prismatic beret (2025-06) | 5 busks | Positive | route, `good_night` | skill | Busk 5 times at highest hat power (`burnPrismaticBeret`) |
| April Shower Thoughts shield (2025-04) | 2 globs | \~10,000 | IoTM route | used 11-21 | Sell globs |
| McHugeLarge duffel bag (2025-01) | Ski set | Small | route, once | audit 11-24 | Avalanche forces the next noncombat, 3 a day; nothing spends it yet |

### 2023 to 2024

| IoTM | Net-positive power | Rough value | Spent by | Evidence | Best use |
| --- | --- | --- | --- | --- | --- |
| TakerSpace letter of Marque (2024-12) | Daily supplies, crafted products | 1,826 anchors banked | route; installed | used 11-21 | Craft whatever uses the most anchors per run; anchors are the surplus, the other five supplies the bottleneck |
| bat wings (2024-10) | 11 free rests, 5 turn savings, pickpockets | Restores, turns | IoTM route | skill | Spend the 11 rests on MP before casting buff songs (fixes the 11-21 MP stall) |
| Sept-Ember Censer (2024-09) | Embers for products | 7 banked | IoTM route | used 11-21 | Route buys the best seller or Museum product; no reserve |
| Mini Kiwi (2024-06) | Kiwi trades | Small | IoTM route | script only | Trade up to `kiwiBuyCap` only when product beats kiwi value |
| Apriling band helmet (2024-04) | Bop buff; saxophone (Lucky!); quad tom (3 free fights) | 3 fights + Lucky! | `setupItems`, free fights | used 11-21 | Take sax + quad tom each day; spend the sax Lucky! like a clover |
| Everfull Dart Holster (2024-03) | Bullseye free kill | A turn each | free-kill list | used 11-21 | Wear it while farming the Oasis so every bullseye lands on a paid fight |
| Mayam Calendar (2024-01) | Yam battery, rests, rings | Adventures | `burnFreeTurnGen` | script only | `mayam resonance yam battery` for adventures, then the fur/meat/wall ring on Pocket Professor |
| candy cane sword cane (2023-12) | 10,500 Meat; Peppermint Rush | 10,500 | `setupItems`, `burnBuffs` | used 11-21 | Keep as is |
| A Guide to Burning Leaves (2023-11) | Free jump, leaf crafts | Small | IoTM route | script only | Hold leaves until their Museum rank is known (`dc refresh 11341`), then craft the top seller |
| Book of Facts (2023-09) | Wishes, tatters, drops | Small | combat | skill | Passive; no action |
| August Scepter (2023-08) | Daily date skill; Cat Day and Tooth Fairy fights; Waffle Day | 2 fights + buffs | `burnBuffs`, free fights | skill | Cast today's date skill, plus Cat Day and Tooth Fairy for free fights |
| Jurassic Parka (2023-05) | Spikolodon NC forcing | Saved turns | `spikolodonSneak` | 2024 | Force the Oasis/zone NC you want; 5 spikes a day |
| Cincho de Mayo (2023-05) | Salt and lime, Fiesta Exit | 6 forced noncombats a day | Shadow Rift work before the nightcap | skill | Fiesta Exit (60 Cinch) forces the next noncombat; keep every free rest for refilling Cinch |
| designer sweatpants (2023-03) | 3 booze reductions, Sweat-Ade | \~90,000 | diet | worn 11-21 | `cast 3 Sweat Out Some Booze` after drinking, then drink 3 more liver |
| Bird-a-Day calendar (2023-01) | Bird buffs, favorite bird +50% item | Buff | `setupItems` | used 11-21 | Visit favorite bird (+50% item) before the Oasis grind |

### 2019 to 2022

| IoTM | Net-positive power | Rough value | Spent by | Evidence | Best use |
| --- | --- | --- | --- | --- | --- |
| 2002 Mr. Store Catalog (2022-12) | 3 credits a day | Crimbo cookie sheets (1,500) | `burnFreeUseItems` | used 11-21 | Buy whichever catalog item sells highest today, not always the cookie sheet |
| Autumn-aton (2022-10) | 5 fetch quests | Zone loot | legacy | 2024 | Send it to the zone with the most valuable item you've visited (Oasis for mojo filters) |
| cursed monkey's paw (2022-07) | 5 wishes | Frosty (+100% item, 50 turns) | `burnFreeUseItems` | 2024 | Wish for Frosty before the Oasis grind, not at `good_night` when turns are gone |
| June cleaver (2022-06) | Free choice NCs | Adventures, Meat | choice settings | worn 11-21 | Keep option 1467=3 (+5 adventures) and 1469=4 (1,500 Meat) |
| Tiny stillsuit, combat lover's locket (2022) | Distillate drink; 3 reminisced fights | Drops | `burnCombatLoversLocket`, route | 2024 | Locket: pickpocket targets first, then Robortender fight (current code) |
| Cosmic bowling ball (2022-01) | Banish/stats, 12 uses | Banishes | banisher lists | pref | Throw it as the Oasis banish every time it returns |
| Daylight Shavings Helmet (2021-12) | Beard buffs | Meat/item | worn | worn 11-21 | Keep worn while farming |
| vampyric cloake (2021-10) | 10 form changes | Drop buffs | combat | worn 11-21 | Bat/wolf forms on the highest-value fights of the day |
| backup camera (2021-09) | 11 copies | 11 copies | `grindBackupCamera*` | 2024 | Back up a scarab beatle swarm or the best locket target; mode `meat` |
| Comprehensive Cartography, Emotion chip (2021) | Map the Monsters; Feel skills | Banish, item, copy | skill lists | skill | Map scarab beatles at the Oasis; Feel Envy on beatles; Feel Hatred as banish |
| fire extinguisher, Cargo Cultist shorts, Guzzlr tablet | Polar Vortex; one pocket; deliveries | Currency | `grindGuzzlr`, `cargo` | 2024 | Vortex beatles for extra drops; `cargo` best pocket daily; 3 Guzzlr deliveries, gold first |
| Powerful Glove (2020-10) | 10 replacements | Better fights | replacer list | skill | Replace blurs into beatles (or the reverse, whichever `scarabBeatleValue` says) |
| SongBoom BoomBox (2018-12) | Food Vibrations, 11 changes | Food drops | `setDefaultBoombox` | used 11-21 | Keep Food Vibrations; switch to Total Eclipse only for meat days |
| Lil' Doctor bag (2019-07) | 3 X-Rays, 3 hammers, 3 otoscopes | 3 free kills | free-kill list | 2024 | X-Ray paid Oasis fights; hammers as banishes |
| Beach Comb (2019-06) | 10 free walks | \~5,000 | `setupItems` | used 11-21 | Keep combing; spare overdrunk turns go here (`burnOverdrunkExcess`) |
| Fourth of May Cosplay Saber (2019-05) | 5 Use the Force | Yellow rays | combat | used 11-21 | Yellow-ray scarab beatles at the Oasis; mod +10 familiar weight |
| Kramco Sausage-o-Matic (2019-04) | Goblin fights; sausages | Fights + adv | `burn_sausages` | worn 11-21 | Wear in the off-hand while farming; eat sausages up to the rollover cap |
| Bastille Battalion (2019-03) | 5 games | Stat potions | `basty win` | 2024 | Play all 5 at `good_night`; sell spare potions |
| Neverending Party (2018-09) | 10 free fights + quest | 10 fights | `nep` | 2024 | Take the Meat quest when offered; run all 10 |
| Kremlin's Greatest Briefcase (2018-08) | 3 darts, buffs | Banishes | banisher lists | 2024 | Darts as Oasis banishes; `briefcase` buff `Items Are Forever` |
| Voting booth (2018-11) | 3 wanderers, daily buff | 3 fights | `voteInVotingBooth` | used 11-21 | Vote for the item or meat local each day |
| God Lobster (2018-06) | 3 fights | 3 fights | free fights | script only | Pick the item-regalia option each fight |
| Boxing Daycare (2018-04) | Daydream, recruits, scavenge | Small | `burnFreeDaycare` | used 11-21 | Free scavenge only; skip paid scavenges |
| latte lovers member's mug (2018-10) | Banish, copy, 3 refills | +4 adv, +40% meat | `good_night` | 2024 | Refill with cajun/carrot/guarna; throw on Oasis blurs as banish |
| Pocket Professor, Robortender, Space Jellyfish, Tot, Cat Burglar | Lectures, robo drops, jellies, costumes, heists | Copies, drops | various | 2024, 11-21 | Professor lectures on a beatle swarm; Tot as the farming familiar; heists on Oasis items |

### 2016 to 2018

| IoTM | Net-positive power | Rough value | Spent by | Evidence | Best use |
| --- | --- | --- | --- | --- | --- |
| Pocket Meteor Guide (2017-08) | 10 Macrometeorites | Replacements | replacer list | skill | Same as the Glove: turn Oasis fights into the better of beatle/blur |
| Spacegate | One planet a day | Research | `grindSpacegate` | used 11-21 | Keep `RATFINK`; take the kit the case is shorter of |
| Gingerbread City, FantasyRealm, PirateRealm, airports | Daily zones | See Paid-turn grinds | `gbc`, `fr`, `pr` | case items | `fr best` and `pr short` daily for unbuyables; `gbc win` by hand when the leaderboard is winnable |
| Time-Spinner (2016-12) | 10 minutes | \~39,800 | `setupItems` | used 11-21 | Far Future tea (2 minutes), then replay a recent beatle fight with the rest |
| Snojo, Numberology, Eldritch tentacle, Witchess, genie bottle | Free kills, universe, horror, wishes | Kills, fights, wishes | skills, `burnFreeUseItems` | skill, 2024 | Punch/Snokebomb on the Oasis; Calculate the Universe for the adventure number; genie wishes for Frosty-like +item effects or fights worth more than 50,000 |

## Free fights, free kills, copies and replacements

Tquilla has roughly **45 free fights, 7 or more free kills, 13 banishes and 40-plus copies or replacements a day**. Each is net-positive by definition: it costs no turn. The ones worth the most are the copies and replacements, because they turn a free fight into a fight against the best target (an embezzler, a pickpocket target, a Museum drop). Counts come from the daily limits the scripts read; the right-hand column says which code spends them.

### Free fights (no turn spent)

| Source | Per day | Spent by | Best use |
| --- | --- | --- | --- |
| Neverending Party | 10 | `nep party` | Full +item outfit and Tot; take the Meat quest |
| Kramco sausage goblins | about 10, getting rarer | wanderers | Leave Kramco on while farming; goblins land in the paid zone for free |
| Shadow rifts via Rufus | about 11 | `grindRufusAndTheShadowRiftsForFree` | Take the item quest; shadow items sell well |
| CyberRealm (server room) | 10 | not automated | **Unused.** Run 10 fights at `place.php?whichplace=serverroom` in +item gear; worth adding to `burnFreeCombats` |
| Snojo | 10 | not automated | **Unused.** 10 fights in the Snojo (`adventure 10 The X-32-F Combat Training Snowman`) for scraps and the daily item |
| LOV Tunnel | 3 | `LOVadv` | Earrings, Wandering Eye Surgery, Echinacea (current choices) |
| Speakeasy (Oliver's Place) | 3 | `grindFreeOliversPlace` | Keep before overdrinking |
| Voting booth wanderers | 3 | wanderers | Let them land in the Oasis |
| God Lobster | 3 | `burnFreeCombats` | Item regalia choice |
| Apriling quad tom | 3 | `burnFreeCombats` | Use in +item gear |
| Cursed magnifying glass | 3 | wanderers | Keep equipped as an accessory while farming until 3 void fights |
| Eldritch tentacle and Horror | 2 | `grindScience` | Keep |
| Molehill, glitch reward, mushroom garden | 1 each | `burnFreeCombats` | Keep |
| August Scepter Cat Day, Tooth Fairy | 1 each | `burnFreeCombats` | Only when today's 5 scepter casts aren't better spent on buffs |
| Bat wings turn savings | 5 | IoTM route | Use on paid Oasis fights |

### Free kills (end a fight in a paid zone without spending the turn)

| Source | Per day | Spent by | Best use |
| --- | --- | --- | --- |
| Chest X-Ray | 3 | `burnInstaKills` | On paid Oasis fights during the day, not on drum-machine fights at night: saves a turn and the 3,000 drum machine |
| Shattering Punch | 3 | `burnInstaKills` | Same |
| Gingerbread Mob Hit | 1 | `burnInstaKills` | Same |
| Everfull Dart Holster bullseye | when Everything Looks Red is off | `burnInstaKills` | Wear while farming so each bullseye ends a paid fight |

Each free kill saves a 5,000 Meat turn. `burnInstaKill` uses a drum machine (3,000) to start the fight, so a drum-machine kill nets about 2,000 plus the loot.

### Forced noncombats (the next adventure is the zone's choice)

Tquilla can force **14 noncombats a day: 5 spikolodon spikes, 6 Fiesta Exits and 3 McHugeLarge Avalanches**. A forced noncombat skips every fight between Tquilla and a zone's choice adventure, so it is worth the turns saved, or the item only that choice gives. Today only the Shadow Rift work spends them, and nothing spends the Avalanches.

| Source | Per day | Owned | Spent by today |
| --- | --- | --- | --- |
| Jurassic Parka, spikolodon spikes | 5 | yes (used 11-23) | `grindRufusAndTheShadowRiftsForFree`, launched on a free fight or free kill; `nep` |
| Cincho de Mayo, Fiesta Exit | 6: each costs 60 of 100 Cinch, and 17 of the 26 free rests refill it | yes (skill list) | `grindRufusAndTheShadowRiftsForFree`; no cast in the 11-21 or 11-23 logs |
| McHugeLarge Avalanche (left ski) | 3 | yes (audit 11-24) | nothing |
| Apriling band tuba | 3 | no: the two instrument picks are the saxophone and the quad tom | nothing |
| Allied Radio Backpack, sniper support | 3 radio drops | not in inventory (audit 11-24) | nothing |
| Clara's bell | 1 | not in inventory (audit 11-24) | nothing |
| Eight Days a Week Pill Keeper, Sneakisol | 1 free, then 3 spleen each | not in inventory (audit 11-24) | nothing |
| stench jelly | not capped: about 500 Meat and 1 spleen each | 1 in inventory; the 2,424 in the Display Case are protected | nothing |

**Free rests belong to this pool, not to MP.** Each free rest at the campsite refills Cinch: 30 for each of the first five, then 25, 20, 15, 10, and 5 after that. That makes 1 Fiesta Exit with no rests, 2 with 1 rest, 3 with 3, 4 with 5, 5 with 8 and 6 with 17. Tquilla has 26 free rests, so 6 a day. The last 9 rests add only 45 Cinch, short of a seventh exit. A rest taken while Cinch is full is wasted, so rest only after a Fiesta Exit. The bat wings' Rest upside down is a skill, not a campsite rest, and stays an MP source.

**Best use:** aim each one at the choice worth most that day. The Shadow Rift choice finishes a Rufus quest without the fights before it. A Display Case item that only drops from a zone's noncombat is the better target when the target register has one. Spikes need a fight to launch in, so pair them with a free fight or a free kill.

### Banishes and run-aways

Feel Hatred (3), Snokebomb (3), KGB tranquilizer darts (3), Reflex Hammer (3), the latte throw (1 per refill), cosmic bowling ball, familiar scrapbook (1 per 100 charges), Saber Force (shares 5 uses), and Spring Away if spring shoes are owned. **Best use:** banish the Oasis monsters you don't want (oasis monster, rolling stone) so every fight is a beatle swarm or blur. Demand is about 17 a day (Oasis, 4 beer lens, 8 ghost costume, 5 bounty) against about 13, so this is a bottleneck (see below).

### Copies, replacements and tracking

| Source | Per day | What it buys | Best use |
| --- | --- | --- | --- |
| backup camera | 11 | Repeat the last monster | Back up scarab beatle swarms (mojo filters) |
| Powerful Glove replace | 10 | Swap a fight | Oasis: swap into whichever of beatle/blur is worth more |
| Macrometeorite | 10 | Swap a fight | Same |
| Pocket Professor lectures | about 9 | Copies | Lecture on a beatle swarm at max weight |
| Combat lover's locket | 3 | Any past monster | Pickpocket target, +item target, Robortender fight (current code) |
| Map the Monsters | 3 | Pick a zone monster | Map scarab beatles |
| Feel Nostalgic, Feel Envy | 3 each | Copy drops; all drops | Envy on beatle swarms; Nostalgic after a locket fight |
| Latte, Saber, Time-Spinner | 1 to 5 | Copy, yellow ray, replay | Saber yellow ray on beatles; Time-Spinner replays a beatle fight |
| Sword of S Words | 100 swaps | Better loot | Equip on the farming familiar |
| Olfaction, Gallapagosian Mating Call | tracking | More of one monster | Track scarab beatles |

## Adventure sources and the value of a turn

The scripts value a turn at **5,000 Meat** (`smm.TurnValue` is unset, so the default applies), and every source below costs less than that per adventure. Tquilla started 2026-11-21 with 155 adventures and had 169 after breakfast.

| Source | Adventures a day | Cost per adventure | Best use |
| --- | --- | --- | --- |
| Rollover (base plus gear) | 40 plus gear | free | `maximize adventures` before logout (`good_night` does) |
| Drinking: 20 liver, perfect dark and stormy | about 6.2 per drunk point | well under 1,000 | Fill liver every day with `tquillaDrinks`; drink under Ode |
| Eating: 15 stomach, baked veggie ricotta casserole | about 5.7 per full | about 1,600 | Fill stomach every day with `tquillaEats` |
| Spleen: 15 | 1.88 per point | see Consumables | Chew agua de vida (cheapest per adventure) |
| Sweat Out Some Booze | 3 liver back | free | Cast all 3 after drinking, then drink again |
| Clan rumpus room | 9 | free | Breakfast |
| Etched hourglass | 5 | free | Breakfast |
| June cleaver +5 adventures | 5 when offered | free | Keep choice 1467=3 |
| Latte (Adventures +4) | 4 | free | Refill with guarna before rollover |
| Mafia thumb ring | about 6 | free | Wear in an accessory slot while farming |
| Circadian Rhythms | about 11 | free | Recall the phylum you farm most (bug for scarab beatles) early in the day |
| Class chocolate (5,700) | 3 then 2 | about 2,300 | Eat 2 a day (`burnFreeTurnGen`) |
| Essential tofu (10,948) | 5 | about 2,200 | Eat 1 a day |
| License to Chill | 5 | free | Use after maxing MP |
| Mayam yam battery | adventures | free | `mayam resonance yam battery` |
| Kramco sausages | 1 each | casing | Eat up to the rollover cap |

KoLmafia's own `valueOfAdventure` is set to **500**, a tenth of the scripts' figure. Mafia's maximizer and any tool that reads that setting will under-value adventures, for example when it picks rollover gear or decides whether a consumable is worth it. Setting it to 5,000 matches the rest of the system.

The 5,000 figure itself is an assumption. The daily-grind ledger (weighted over about 14 days) will measure real return per turn once it has 5 days of history on this machine.

## Consumables that pay for themselves

At 5,000 Meat a turn, **filling all three organs is the largest net-positive purchase every day**: roughly 230 adventures for well under 1,000 Meat each. Buff potions only pay when the zone's drops are worth more than their cost per turn, and today's prices make most of the item-drop list too dear. Prices are 2026-11-22 mall prices.

### Diet

| Item | Price | Organ | Adventures | Meat per adventure | Best use |
| --- | --- | --- | --- | --- | --- |
| perfect dark and stormy | 2,340 | 3 liver | about 18.5 | about 130 | Main drink: 6 a day plus 1 after sweating (buy map keeps 50) |
| splendid martini | 9,900 | 1 liver | about 6 | about 1,650 | Filler for the last liver point only |
| baked veggie ricotta casserole | about 8,900 | food | about 5.7 per full | about 1,600 | Main food; fill leftover stomach with roasted vegetable of Jarlsberg |
| agua de vida | 3,825 | 4 spleen | about 7.5 | about 510 | Chew 3 (12 spleen); buy map keeps 25 |
| grim fairy tale and other 1-spleen items | 3,549 to 3,950 | spleen | 1.88 per point | under 5,000 | Fill the last 3 spleen points |
| Frosty's frosty mug, salad fork | 290,000 and 149,400 | booster | part of a meal | far above 5,000 | Don't buy; the buy map waits for under 20,000 and 15,000 |

### Item-drop buffs (from `itemDropBuff` in smmUnrestricted.ash)

| Item | Price | Buff | Meat per buff-turn | Best use |
| --- | --- | --- | --- | --- |
| monkey's paw wish, Frosty | free, 5 a day | +100% item, 50 turns | 0 | `monkeypaw effect Frosty` before the Oasis grind (250 turns covered) |
| abstraction: certainty | 1,038 | +100% item, 50 turns, 1 spleen | about 21 + spleen | Chew instead of a filler spleen item on Oasis days |
| Sacramento wine | 995 | +50% item, 50 turns, 1 liver | about 20 | Use as the 1-liver filler instead of splendid martini |
| spider web + Synthesis: Collection | about 300 + spleen | +150% item, 30 turns | about 10 + spleen | `synthesize Synthesis: Collection` before the Oasis |
| cyclops eyedrops | 12,750 | +100% item, 10 turns | 1,275 | Only for a 10-turn push on a Museum drop |
| battery (car), (lantern) | 45,000 and 43,980 | +100% item, 30 turns | about 1,500 | Sell the AAA batteries instead |
| raven feather, sorority brain, frost flower, Affirmation, carrot juice | 19,500 to 108,000 | +50% to +100% | 1,000 to 3,600 | Don't buy |

`grindMeatWithItemDrop` allows at most **100 Meat a turn** on item buffs (0 for a Seal Clubber), so in practice only the first four lines are ever bought.

### Meat-drop buffs

The Meat buffs Tquilla holds come almost entirely from skills (Polka of Plenty, Disco Leer, Fat Leon's, Carol of the Bulls and others) and are free. A Meat potion is positive when the zone's base Meat times its bonus beats its cost per turn: at a base of about 300 Meat, +30% is worth about 90 Meat a turn. On that test Knob Goblin nasal spray (150 for 10 turns) passes and resolution: be wealthier (1,696) is break-even. Measure the farm zone's base Meat before buying more.

### Combat items

| Item | Price | Use | Best use |
| --- | --- | --- | --- |
| drum machine | 3,000 | Farmed from Oasis blurs; Museum item (#4); used in the desert it calls a sandworm (spice melange 342,000) | Put farmed copies toward the Museum (3,719 more takes #3 from Leon at 14,938; #1 has 39,183). Only use one for melange if the drop rate is above about 2.5% |
| drum machine + free kill | 3,000 | Starts a fight for a free kill | Prefer spending free kills on paid fights; this nets only \~2,000 |
| divine champagne popper | 8,249 | Free run-away | Don't buy; Spring Away is free. Fiesta Exit and Avalanche force noncombats and are not run-aways |
| pocket wish | 49,998 | One wish | Don't buy while the genie gives 3 a day |

## Paid-turn grinds and currency farms

These spend real turns, so each is net-positive only if it returns more than 5,000 Meat a turn or brings in a Display Case item Meat cannot buy. The daily-grind ledger measures this, but it has no history on this machine yet, so the figures below are what each grind produces, not a measured return. After 5 logged days `dailyGrind()` skips any grind under the turn value automatically, except one that recently brought an unbuyable item the case still needs.

| Grind | Turns | What it produces | Museum link | Best use |
| --- | --- | --- | --- | --- |
| Oasis: scarab beatles or blurs | most paid turns | mojo filters (4,969), drum machines (3,000) | mojo filter #1; drum machine #4 | Main turn sink: Ultrahydrated, Frosty, +item gear, Tot; copies and replacers all aimed here |
| The Drip | a few a day | drippy items | #1 in 14 drippy items | Run daily (`grindDrip`); the rare drops are where the value is |
| Beer lenses | 3 to 5, 4 banishes | 3 lenses (5,098) | #5 | Run while banishes allow; drop it first when banishes are short |
| Li'l ghost costume | 5 to 11, 8 banishes | Tot costume | case costume | Run only until the case has enough; then `set smm.dailyGrind.ghostCostume = false` to free 8 banishes |
| FantasyRealm | 1 run | boss item, Rubees | unbuyable | `fr best` daily |
| PirateRealm | 1 voyage | Red Roger's reliquary | unbuyable | `pr short` daily |
| Spacegate | one planet | Research, samples | samples | Daily; kit by Museum need |
| Daily Dungeon | up to 15 | fat loot token | vending items | Keep only if the ledger shows >5,000 a turn; tokens buy unbuyables |
| Gingerbread City | 20 | sprinkles, items | 5 gingerbread #1s | `gbc win` by hand when the leaderboard is winnable, else `gbc items` |
| Bounty | \~20, 5 banishes | filthy lucre | Hunter items | Easy bounty only; skip hard bounties that need banishes |
| Guzzlr | 3 deliveries | Guzzlrbucks | store items | Gold and platinum only |
| Sea zones | 20 on Fishy days | Mer-kin, rusty items | several #1s | Only on Fishy days (fishy pipe) |
| Dolphin whistle | 1 | the stolen item | when short | Whistle only when the item beats a turn |

The IoTM route's own zone farming runs before these grinds and books its turns in its own receipt (`data/smm-iotm-route-last.txt`). When a zone looks more profitable there, it takes turns these grinds would have used.

## Currency balances and stockpiles

Tquilla holds about **141.5M Meat** (28.7M on hand, the rest in the closet and storage) and roughly **700M Meat of sellable stock** at the shop's own asking prices. The stock is the biggest untapped resource: most of it sits beyond what the Display Case needs for #1. Selling in bulk would move prices, so the realizable value is lower.

### Currencies and charges

| Balance | Amount | Use | Best use |
| --- | --- | --- | --- |
| Meat, total | 141,519,354 | Spending step opening figure | Buy the nine cheap Museum #1s (\~2.5M) now; the rest funds `smmSpendRun` (half the day's net) |
| TakerSpace anchors | 1,826, with 3 spice, 4 rum, 4 mast, 2 silk, 1 gold | Route crafts | Anchors are 450x the other supplies: craft anchor-heavy products and consider switching the workshed to the model train set until the others catch up |
| Familiar scrapbook | 69 charges | Banish at 100 | Keep it in the off-hand on familiar-XP days; it banishes at 100 |
| Sept-Embers | 7 | Route | Spend daily; no reason to bank |
| Cup of 13s jewels | 13 a day | Route | Spend daily; they reset |
| Interesting Coins | not read | Route | Save to 10M for the Gross Prophet chrysalis, then display it |

### Largest stockpiles beyond the Display Case

Counts from the store-stocking pass on 2026-11-21. *Held* is inventory, closet and storage, not counting copies in the shop or the case.

| Item | Held | In case (rank) | Asking price | Held value | Best use |
| --- | --- | --- | --- | --- | --- |
| mojo filter | 42,343 | 4,130 (#1, lead of 11) | 4,969 | \~210M | Use 3 a day for spleen (diet.js does: 1.88 adventures each, worth \~9,400); put 1,000 in the case (#2 is 11 behind at 4,119); sell the rest slowly at market |
| Special Seasoning | 16,554 | 12,811 (#2) | 6,660 | \~110M | Keep for the #1 push (22,904 more needed); don't sell |
| Maxwell's Silver Hammer | 77,164 | 10,011 (#1) | 980 | \~76M | Surplus: list at market in the shop, a few thousand at a time |
| MSG | 68,087 | 3,680 (#1) | 950 | \~65M | Surplus: sell at market |
| happiness | 43,611 | 16,176 (#1) | 900 | \~39M | Surplus: sell at market |
| cyborg stompin' boot | 911 | 1,112 (#1) | 27,989 | \~25M | Sell steadily; best Meat per copy in the list |
| rough fish scale | 85,421 | 1,351 (#2) | 240 | \~21M | #1 (740,000) is out of reach and #3 is only 11 behind: put 1,000 in the case to lock #2, sell the rest |
| savory dry noodles | 13,368 | 1,548 (#1) | 1,508 | \~20M | Surplus: sell at market |
| drippy truncheon, nugget, wine, petri dish | 730, 1,408, 1,019, 843 | all #1 | 4,739 to 18,989 | \~40M | Sell 1 to 2 a day each to avoid crashing the price |
| counterfeit city | 300 | 509 (#1) | 50,000 | \~15M | Sell slowly |
| absentee voter ballot | 1,410 | 1,207 (#1) | 7,968 | \~11M | Sell slowly |
| grungy bandana | 7,807 | 880 (#1) | 1,431 | \~11M | Sell |
| sleaze jelly | 3,910 | 380 (#1) | 2,500 | \~10M | Sell; the jellyfish adds 3 a day |

Rare drippy items (drippy grub, stake, plum, khakis), mourning wine and gingerbread dog treats are listed at 0.6M to 72M each. Those prices are asks nobody has met, so they are left out of the 700M.

## Display Case: cheapest rank gains

Of the 85 items whose Museum ranking is stored on this machine, Tquilla is **#1 in 49, top ten in 34 more, and absent from 2**. Nine #1 places cost under 1M Meat each at today's mall price, about 2.5M for all nine. That is the best Meat-to-Museum conversion in this report. On 2026-11-21 the stocker also put 1,000 globs of undifferentiated tissue in the case, which should now be #1 (24,017 against 24,006).

| Item | Rank now | In case | #1 has | Copies to buy | Mall price | Cost to #1 | Best use |
| --- | --- | --- | --- | --- | --- | --- | --- |
| denastified haunch | 2 | 68 | 78 | 11 | 8,448 | \~93,000 | `dc rankup denastified haunch` |
| spray chrome | 7 | 221 | 1,222 | 1,002 | 100 | \~100,000 | `dc rankup` repeatedly (one rank per run) |
| haunted pizza | 3 | 748 | 1,075 | 328 | 393 | \~129,000 | `dc rankup` twice |
| haunted bottle of vodka | 2 | 572 | 969 | 398 (190 held) | 399 | \~83,000 | `dc top1 haunted bottle of vodka`, then `dc rankup` |
| haunted orange | 3 | 667 | 970 | 304 (165 held) | 625 | \~87,000 | `dc top1 haunted orange`, then `dc rankup` |
| ghostly ectoplasm | 2 | 7,640 | 9,069 | 1,430 | 170 | \~243,000 | `dc rankup ghostly ectoplasm` |
| impure gasoline | none | 0 | 4,006 | 4,007 (157 held) | 100 | \~385,000 | Put the 157 held in the case (`display put 157 impure gasoline`), buy 116 for top ten, then `dc rankup` |
| filthy monkey head | 7 | 261 | 4,975 | 4,715 | 100 | \~472,000 | `**dc rankup**` repeatedly |
| haunted Hell ramen | 2 | 1,055 | 1,269 | 215 | 4,400 | \~946,000 | `dc rankup` |
| Z-Bone steak | none | 0 | 2,644 | 150 held | 3,000 | top ten \~360,000 | Put the 150 held in the case, buy 120 more for top ten |

Preview any line first with `dc --dry-run rankup <item>`; rankup pays at most 1.05 times the mall price.

The next tier costs 1M to 10M each: viral DNA (1.3M), TI-9000 calculator (2.3M), unused soap (2.8M), stench jelly (3.6M), bottle of clam juice (3.8M), chocolate Spider Queen (4.8M), personal graffiti kit (6.1M), tarnished bottlecap (7.6M) and fiberglass insulation (10M). Mall prices are KoLmafia's fifth-cheapest listing; buying hundreds of copies will cost more.

The stored rankings cover only 85 items because this KoLmafia install is new. Running `dc refresh` and `targets refresh` fills in the rest of the case, and the spending step's second pass (Display Case items on sale) only sees items with a stored ranking.

## Left out, unconfirmed, and what to check in game

The ledger above leaves out anything that loses Meat at today's prices, and flags owned resources nothing spends yet.

**Left out as not net-positive now:** Frosty's frosty mug and Ol' Scratch's salad fork (10 to 20 times the buy-map ceiling), pocket wishes and divine champagne poppers (free alternatives exist), item-drop potions above about 1,000 Meat a buff-turn, blood cubic zirconia casts past the first 3 of each (the stat cost grows tenfold every three casts), and the legendary seal-clubbing club's charges until someone values them.

**Owned but not spent by any script:**

- CyberRealm: 10 free fights a day; only the server-room trash is collected.
- Snojo: 10 free fights a day; no code in either repo.
- shrunken head and Monodent of the Sea: both owned, neither adapted in the IoTM route.
- Heartstone: no letters unlocked, so none of its powers work yet.

**The 2026-11-21 run stopped early.** The grind log ends inside `secondBreakfast()`: `burnMP` spent 17,797 MP on buff songs, then Mafia "ran out of restores" casting during the daycare step and the session logged out. No IoTM route, free fights or paid grinds appear after that, so that day's daily resources look unspent. Worth checking before trusting the daily totals here.

**Check in game:**

- [ ] Confirm the script-only IoTMs are owned: legendary acorndion, black garden rose, Meat Shield Maiden, Sword of S Words, Baseball Diamond, Archaeologist's Spade, legendary seal-clubbing club, Skeleton of Crimbo Past, McHugeLarge duffel bag, Mini Kiwi, A Guide to Burning Leaves, Mayam Calendar, God Lobster.
- [ ] Read the Interesting Coin, knucklebone and Rubee balances, which the saved state does not show.
- [ ] Set `valueOfAdventure` to 5,000 to match `smm.TurnValue`.
- [ ] Run `dc refresh` and `targets refresh` so the Museum store covers the whole case, not 85 items.
- [ ] After 5 days, read `printDailyGrindLedger()` to replace the 5,000 assumption with a measured turn value and per-grind returns.
- [ ] Run `iotmroute plan`: it lists every IoTM action the route can take today with its value, which confirms ownership and prices the 2025 to 2026 items in one pass.

* [x] Read `total_free_rests()`: 26, from the audit on 11-24, which makes 6 Fiesta Exits a day.
* [x] Other noncombat forcers, from the audit on 11-24: the McHugeLarge duffel bag is owned. Clara's bell, the Pill Keeper and the Allied Radio Backpack are not in inventory.

## Sources

- Repo `sachamm/KoL` at main after PR #20: `docs/*.md`, `scripts/smmUnrestricted.ash` (`dailyGrind`, `good_night`, `secondBreakfast`, burn functions), `data/unrestricted_buy_map.txt`, `data/smm-target-sources.txt`.
- `sachamm/KoLUtils` as installed: `smmUtils.ash` (free-fight, free-kill and replacer lists, turn value) and `smmResourcePlanner.ash` (the 59 daily pools).
- KoLmafia on the Windows machine, read-only: `settings/tquilla_prefs.txt`, `sessions/Tquilla_20261121.txt` (player snapshot, breakfast, store stocking), `runlogs/grind-2026-11-21.log`, `data/smm-museum-ranks-2771003.txt`, `data/combo_results.json` (Beach Comb totals) and `data/mallprices.txt` (prices as of 2026-11-22), with item names from KoLmafia r29457's own item data.
- Not available: a full inventory list, Interesting Coin and other currency balances, and grind-ledger history (this install is new).
