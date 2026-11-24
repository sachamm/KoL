# Memo 2: KoL expert. Best use of Tquilla's resources for Meat and Museum rank

Council round 1 · 2026-11-23 · from the leaderboard-level KoL expert

This memo covers what to spend each resource on, measured against Sacha's goal (Meat plus Museum #1, top ten accepted), not against speed. I checked the ledger against the session logs (Nov 19 full day, Nov 21, Nov 23 partial), the prefs file, the garbo checkout (commit `eaa1455`, 2026-11-22) and the Tour Guide 2024–2026 modules. Where a log contradicts the ledger, I go with the log. Confidence: **H** = seen in logs or source, **M** = wiki or source but not measured here, **L** = from memory, check before relying on it.

## 0. Headline positions

1. **The Sword of S Words is Tquilla's biggest single daily Meat source, and Sacha's own script wastes it (H).** It earned about 5M a day under garbo and 1 kill on Nov 23. With the Sword as the active familiar, its 100 daily kills each bring back the drops of a seeded monster. On Nov 19 garbo seeded a Ribbon-Cutting Elfborg and got 72 synthetic stuffing and 72 LED blocks (garbo valued them at 2.40M and 2.92M), plus iGooglies, hoverpads and string. `_swordOfSWordsKills` went 98→99→100 that day. On Nov 23 the IoTM route seeded a fabricator guài (estimated 80k a kill), then switched straight back to the Cat Burglar, so the Sword got **1 kill**. Rule: the Sword is the familiar for the first 100 kills of the day, free or paid. Nothing else Tquilla owns comes close to ~50k per kill.
2. **Since 2024-08-13 there is no Embezzler copy chain. Copies are now cheap for Meat and should go to Museum targets (H/M).** The Knob Goblin Embezzler can't be copied any more; you only meet it on a Lucky! adventure in the Treasury ([wiki](https://wiki.kingdomofloathing.com/Knob_Goblin_Embezzler)). garbo now copies the best wishable, free, copyable monster. For Tquilla that was the **Witchess Bishop**: 16 at the start of the day and about 45 in total on Nov 19. They dropped 73 Sacramento wines, about 1k each. So the ~40 daily copies (Professor, backup camera, mimic eggs, locket, Time-Spinner, Glove, Macrometeorite) are worth roughly 1–2k Meat each. The ledger says to aim them at scarab beatles, which is wrong (see §1). Aim them at monsters that drop Display Case items Tquilla is short of.
3. **The paid turns belong in Barf Mountain (garbo), not the Oasis, unless the Oasis is dropping something the Museum still needs (M/H).** garbo's own reports: 7.33M over 211 turns on Nov 19, 7.36M over 350 turns on Nov 22. The Oasis outputs are mojo filters, hammers, happiness, MSG and seasoning. Tquilla already holds 42k, 77k, 43k, 68k and 16k of those, and is #1 in all but seasoning. At asking price each Oasis turn looks like 4–6k. In practice almost none of it can be sold at that price, because Tquilla's stock is many times what the market buys in a year.
4. **There are plenty of banishes. The problem is the script's list and how it spends them (H/M).** Tquilla owns at least 6 banishes that last all day or reuse on a cooldown, plus about 22 short ones a day and 474 gingerbread restraining orders. `grindScarabBeatles` doesn't see half of them (§4.1).
5. **MP is an ordering bug, not a shortage (H).** Free supply is about 40k MP a day against a 20,340 maximum. On Nov 23 `burnMP` cast *Fat Leon's Phat Loot Lyric for 662 turns* when only about 400 turns were left. Cap song extensions at the turns actually remaining (§4.2).
6. **The "20 unused free fights" aren't simply sitting there (H).** garbo runs both CyberRealm and Snojo whenever they're available. On Nov 19 it ran neither. Snojo shows `snojoAvailable=false`. CyberRealm's free fights in garbo need OVERCLOCK(10), Torso Awareness and a zero-trust tanktop. Treat both as one-time unlock projects, not missing automation.
7. **Five 2024–2026 IoTMs are owned (seen in logs) but nothing uses them properly:** Peridot of Peril, Chest Mimic, Möbius ring, Monodent of the Sea and Heartstone (still locked). Each fills a gap: targeted encounters, copies, +item, all-day banishes, and an extra Lucky! plus 5 banishes once the Heartstone is unlocked.
8. **Museum: deposit surplus stock you can't sell. Don't hold it for sale (M).** Tens of thousands of MSG, hammers, happiness and mojo filters will never sell at market price. Putting them in the case costs almost nothing in Meat and secures #1 for good.

## 1. Ledger corrections

| Ledger says | Correction | Evidence | Conf. |
|---|---|---|---|
| Sword of S Words: "script only… loot gap" | Owned. Worth ~5M a day when it is the active familiar; capped at 100 kills a day | Nov 19 log: `_swordOfSWordsKills` reaches 100, 72 stuffing and 72 LED blocks; Nov 23: 1 kill | H (price durability M) |
| Copies and replacers: "aim at scarab beatle swarms" | Beatles add to stock Tquilla can't sell. Aim copies at register targets; failing that, let garbo run its chain | Holdings in ledger §Stockpiles | H |
| `valueOfAdventure` is 500 | It is **4,500** now | prefs `valueOfAdventure=4500` | H |
| CyberRealm and Snojo: "unused, add to `burnFreeCombats`" | Both need unlocking or confirmation first (see headline 6) | garbo `tasks/freeFight/index.ts:1112-1230`; Nov 19 log has no Cyberzone or Snojo fights | H |
| Drum machine plus free kill nets ~2,000; melange only if drop rate >2.5% | 32 sandworm fights on Nov 19 and Nov 23 dropped **0** spice melange. Stop it. Put drum machines toward Museum #3 and free kills on paid turns | `Encounter: giant sandworm` 21 + 11, `spice melange` 0 | H |
| Hermit clovers: Lucky! on a target worth >32k, else sell | Agree. An untradeable Lucky! (Apriling sax, later Heartstone LUCK) is worth about one Embezzler, ~16k at Tquilla's +meat. Nov 23 spent the sax Lucky! in the **Oasis** | Nov 23 log line ~14485; garbo `lib.ts` values a Treasury Lucky! at 3×VOA | M |
| Banishes: ~13 against ~17 wanted | Supply is well over 30 a day once all-day and cooldown banishes are counted (§4.1) | Script banisher list, Nov 23 log ~14470 | H |
| Monodent: "summon a Wave… needs an adapter" | Its lightning is the bigger power: per Tour Guide, 11 a day, each a turn-taking kill that **banishes until rollover and keeps the drops** | `TourGuide/.../2025/Seadent.ash` | M |
| Paid turns ~400 at 5,000 | garbo measured roughly 21k–35k per turn *including* free fights and the Sword. The marginal Barf turn is likely 5–6k. Measure it; don't assume | `garboResults*` prefs; garbo README (4,000–6,000 MPA) | M |
| Use 3 mojo filters a day; put 1,000 in the case | 3 a day is the game's daily use limit, so keep that. Put **10k+** in the case, not 1,000 (§3) | ledger stock | M |

## 2. Best use of each significant daily resource

Values assume `valueOfAdventure` = 4,500 and that liquid Meat at Barf is the baseline. "Museum" means the use beats Meat only when the item fills a known gap.

| Resource (per day) | Best use | Approx. value/day | Conf. |
|---|---|---|---|
| Sword of S Words, 100 kills | Active familiar for the first 100 kills (free fights first, then Barf). Seed the target with the locket (the route already does). Reseed toward a Museum drop only when its per-kill value beats ~50k | ~5M | H/M |
| ~400 paid turns | garbo Barf Mountain with its meat outfit. Oasis only for a measured Museum need | ~2M+ in Meat over the free-turn baseline | M |
| Dinseylandfill day ticket | garbo bought a one-day ticket on Nov 19 (it logged the ticket as −142,966). **Price the permanent airplane charter:** if it costs under about 100 tickets, it pays for itself, and the charter is itself a Display Case item | 143k/day saved | H (ticket) / L (charter price) |
| ~45 free fights | Wear +meat/+item gear with the Sword as familiar, then the best item familiar. Wanderers (Kramco, voting, magnifying glass) land in Barf | Loot plus Sword kills | H |
| 7+ free kills | Use only on *paid* turns in the farm zone (each saves 4,500). Never on drum-machine sandworms | ~35k + loot | H |
| ~40 copies and replacers | Museum register targets first. With no target, let garbo's free copy chain run (Witchess Bishop, ~1–2k each) | Museum, or ~60k | H |
| Peridot of Peril | First fight in each zone each day: pick the monster ([wiki](https://wiki.kingdomofloathing.com/Peridot_of_Peril)). Use it in every register zone visited, plus the start of Barf and the Oasis | 1 targeted encounter per zone | M |
| Hermit: 3 clovers | Sell (~32k each) unless a Lucky! Museum target is worth more | ~97k | H |
| Apriling sax Lucky!, Heartstone LUCK (once unlocked) | Lucky! Embezzler at the Treasury, ~1,000 base Meat × (1 + meat%) ≈ 16k. Use on a Museum Lucky! adventure instead when one exists | ~16k each | M |
| Genie bottle, 3 wishes | Check whether `genie wish for more wishes` makes a *tradeable* pocket wish (mall ~50k). If it does, selling 3 beats nearly every effect wish | up to ~150k | **L, check** |
| Cursed monkey's paw, 5 wishes | +item (Frosty) or +meat effect *before* the farm block. Using any wish turns off Monkey Slap that day | buff | M |
| Legendary seal-clubbing club, 5 Next Week | 5 delayed copies, a 7-turn wanderer each. garbo already treats them as copy-chain fights. Aim at Museum targets | 5 copies | M |
| Chest Mimic eggs (11 on Nov 19) | Copies of monsters in the Mimic's list. Museum targets; also the Heartstone A/P letters (Black Crayon monsters) | 11 copies | H (count) / M |
| Monodent | Lightning: all-day kill-banish of the farm zone's unwanted monsters. Wave: +30% item/Meat in the farm zone (wear the dent for Fishy if needed) | Banishes + 30% | M |
| Bat wings | 11 free rests of 1,000 MP each (log: "Rest upside down… 1,000 Muscularity Points"; Muscularity Points is MP for a Muscle class). Take them **before** buff songs | 11k MP | H |
| Magical sausages, up to 23 | Eat them all (adventures plus MP); garbo already does | 23 adv | H |
| Spice melange (from sandworms) | Not produced (0 in 32). Stop using drum machines in the desert | — | H |
| Legendary noodles, AAA batteries, Far Future tea, Rad Libs | Sell; the ledger is right | ~180k | H |
| Mr. Store 2002 credits (3) | Buy the catalog item with the best mall price *that day*, not always the cookie sheet | ~5–15k | M |
| Mojo filters, 3 | Spleen cleaners at the 3-a-day limit, allowing an extra spleen item. Worth it at ~1.9 adv per spleen point | ~25k | H |

## 3. How top aftercore farmers run a day in 2026, and what Tquilla should adopt

The 2026 garbo ordering (`packages/garbo/src/index.ts`, `tasks/`):
1. **No-turn dailies**: breakfast, IoTM collections, garden, workshed, Mr. Store, Bastille, and so on.
2. **Diet planned against MPA**: garbo's diet optimizer (`garbo simdiet`) prices every organ against `valueOfAdventure`, including Sweet Synthesis Greed, sweatpants, distention and dog-hair pills, and spleen cleaners.
3. **Copy chain at the start of the day** (`target/fights.ts`): Witchess, locket, fax, mimic eggs, Time-Spinner, putty, 4-d camera, Lucky!, digitize, Enamorang, Next Week, Habitats, Macrometeorite, Glove, backup camera, Professor chains. For this character the target is a free monster, so all of it is free fights.
4. **Lucky! Embezzlers**: clover, saxophone, pillkeeper and Heartstone Lucky! go to the Treasury when that beats the alternatives (`tasks/embezzler.ts`).
5. **Free fights** with a free-fight familiar and outfit (`tasks/freeFight/index.ts`).
6. **Barf Mountain** for every remaining turn. Wanderers land there; free kills and free fights are mixed in.
7. **Overdrink turns** with Drunkula's wineglass, then max adventures for rollover.

**Recommendation: hybrid, not a rewrite.** The new script should:
- **Do first, every day, before any adventuring:** the rate-limited Museum sources and no-turn dailies (§3.3). Each of these is lost permanently if skipped.
- **Steer the Museum-pointable resources itself:** copies, Peridot, locket, Sword seed, Next Week, Lucky! and Map the Monsters, aimed by the target register. Release the rest to garbo.
- **Hand the Meat engine to garbo** (`garbo` with `valueOfAdventure` set to the measured MPA), with its copy target set to a Museum target on days the register wants one (`garbo_copyTarget`). garbo's Sword and familiar logic already reaches 100 kills a day. Running garbo for the bulk turns also replaces `burnMP` buff spam with garbo's mood, which only buffs for turns it will spend.
- **Run the IoTM route only in `free` mode** before garbo (newest-first IoTM adapters), with `smm.IR.maxPaidTurns` set to the turns the Museum targets need. Today the route's uncapped zone farming would take garbo's turns.
- **Leave out** the legacy grinds that farm items Tquilla is already #1 in with years of stock (Oasis beatles, hammers, happiness). Keep the grinds that make unbuyable or #1-gap items (Drip, FantasyRealm, PirateRealm, Spacegate, Daily Dungeon, GBC, bounty lucre) and the ghost costume until its target is met.

Things top farmers do that Tquilla should **not** copy: maximum Meat at any Museum cost (for example, eating Display Case stock), and selling unbuyables.

### 3.3 Rate-limited sources to touch every day ("use it or lose it")
Hermit clovers 3 · Daily Dungeon token · FantasyRealm boss item (1 run) · PirateRealm voyage · Spacegate planet · Gingerbread City · Drip runs · bounty lucre (3) · Guzzlr (3) · Bastille (5) · Witchess (5) · NEP (10) · LOV · speakeasy (3) · Rufus/shadow rift · Mr. Store credits · Interesting Coin daily goods · Skeleton of Crimbo Past daily special · Sept-Ember embers · Cup of 13s jewels · TakerSpace delivery · black garden rose nodes · Mayam · Peridot (per zone) · Sword (100) · bat wings (11) · sausages (23) · clan VIP: Klaw ×3, pool, shower, Floundry, fax, Crimbo tree · Beach Comb · Autumn-aton (5, to the zone with the best Museum drop) · **any mall listing with a per-day buy limit that is ≥20% under its 7-day average** (these limits reset daily, so a missed day is lost).

**Seasonal:** Crimbo 2026 starts in December. Event monsters and drops become unbuyable or thin later. The Elfborg and the fabricator, today's top Sword seeds, look like 2025 event monsters (L). Budget turns and copies for the event's Museum items while it runs. They are the cheapest #1s Tquilla will ever get.

## 4. Fixes for the bottlenecks

### 4.1 Banishes: full inventory
Durations and limits are from the [wiki Banish page](https://wiki.kingdomofloathing.com/Banish) unless marked TG (Tour Guide module) or LOG.

| Source | Uses/day | Duration | Costs a turn? | In script list? |
|---|---|---|---|---|
| Spring Kick (spring shoes) | unlimited, 1 active at a time | **rollover** | no, combat continues | yes |
| Monodent lightning | 11 (TG) | **rollover** (TG); keeps drops | yes (kill) | **no** |
| Bowl a Curveball | 1 active, reusable on cooldown | until the ball returns | no | yes |
| Feel Hatred | 3 | 50 | no | yes |
| Snokebomb | 3 | 30 | no | yes |
| Reflex Hammer | 3 | 30 | no | yes |
| KGB tranquilizer dart | 3 | 20 | no | yes |
| Throw Latte | 4 (1 + 3 refills) | 30 | no | yes |
| Use the Force (Saber) | 5, shared with the yellow ray | 30 | no | **no** (all spent as yellow rays) |
| mafia middle finger ring | 1 | 60 | no | yes |
| familiar scrapbook | 1 per 100 scraps (69 now) | 100 | no | yes |
| gingerbread restraining order | **474 owned** | (check) | no | listed but blocked by the 100-Meat/turn cap (they're 2,250) |
| Breathe Out (hot jelly from the Space Jellyfish) | per hot jelly | 20 | no | listed, rarely available |
| Patriotic Screech (Eagle) | 1 when charged | phylum | no | listed |
| Licorice rope (GBC) | per item | rollover | — | listed |
| Heartstone GONE | 5 once unlocked (TG) | 50 | yes | no (locked) |
| Monkey Slap | rollover banish, only before any paw wish that day | rollover | yes, no drops | no |
| handful of split pea soup (Peace Turkey) | per item | 30 | no | no (ownership L) |
| anchor bomb (TakerSpace: 1 rum, **3 anchors**, 1 mast, 1 gold) | gold-limited | 30 | no | no |
| ice house | permanent; currently holds the **fluffy bunny** | permanent | — | — |
| Batter Up! | Seal Clubber only, **not usable** | — | — | listed (wrong) |

What to change:
- In a zone farmed all day (Oasis, Barf), **use the rollover banishes on the persistent unwanted monsters**: Spring Kick on one, Monodent lightning on the rest. The lightning fight takes a turn, but you were spending that turn in the zone anyway, and it keeps the drops. Two or three casts cover the whole day.
- **Save the 20–50-turn banishes for short grinds** (beer lens, ghost costume, bounty, Drip) that finish inside the banish's duration. Count demand as *unwanted monsters × ceil(turns ÷ duration)*, not as a number per grind.
- **Let restraining orders through the cost cap.** The 474 owned are priced at 2,250, half a turn.
- Consider moving the **ice house** to the farm zone's worst monster *if* garbo doesn't need the bunny banished. garbo used the Dire Warren 15 times on Nov 19, so check first (L).
- **Unlock the Heartstone** (§5): +5 GONE and +1 LUCK a day.

### 4.2 MP (Turtle Tamer, 20,340 max)
Free MP supply per day: bat wings 11 × 1,000 = 11,000 (LOG) · dwelling free rests ~160 each, 31 rests on Nov 19 ≈ 5,000 (LOG) · up to 23 magical sausages (MP plus an adventure each; amount per sausage L) · nuns 3 × 1,000 if open (first entry in `mpAutoRecoveryItems`) · eternal car battery · carbonated water lilies (~64 MP each; 8 gave 516; 112 collected on Nov 23).

Bought MP: magical mystery juice from the mall works for any class (only the NPC store is limited to myst classes). It restores about 1.5×level+5 MP, roughly 160 at level 105, for about 1 Meat per MP (scaling L). Add it to the end of `mpAutoRecoveryItems` with a price cap.

Fixes, in order:
1. **Cap buff extension** at turns remaining plus expected extra adventures. The Fat Leon's 662-turn cast is the clearest waste.
2. Keep a floor of 2,000 MP (the ledger is right).
3. Rest at the bat wings and campsite **before** casting songs.
4. When garbo runs the turns, it sets mood "apathetic" and handles restores itself. Most of the `burnMP` problem goes away.

### 4.3 Turn budget
- Set `valueOfAdventure` and `smm.TurnValue` to **one measured number**. Start at 5,000. After 5 garbo days, set it to `garboResultsMeat+Items` minus the free-fight and Sword share, divided by turns.
- Cap the IoTM route's paid turns (`smm.IR.maxPaidTurns`) and the legacy grinds at their *Museum* need. Every turn not needed for a Museum target goes to garbo.

### 4.4 Surpluses
- **TakerSpace anchors:** anchors only become useful together with the scarce rum, mast and gold, so 1,826 anchors are worth almost nothing. Let the route pick the product that is limited by the scarce supply. If another workshed you own makes more than a day's delivery, swap worksheds (once a day). Check whether the model train set is owned; I found no log evidence.
- **Mojo filters, MSG, hammers, happiness, savory noodles, grungy bandanas:** put a large deposit in the case (§6.4). List the rest in small daily lots at market. Don't farm more of them.
- **Shrunken head:** low value. Try a zombie with a +meat or +item ability during Barf once there's an adapter. Not a priority (L).
- **700M of stock:** realizable value is far lower. Sell only what the market absorbs. Rare drippy items stay in the case or the store at asking price.

## 5. 2025–2026 mechanics the scripts likely miss

| IoTM / mechanic | Owned? | What it gives | What to do |
|---|---|---|---|
| Sword of S Words (2026-06) | **Yes** (LOG) | 100 kills/day bring back a seeded monster's drops; value rises with +item (garbo `resources/swordOfSWords.ts`) | Familiar for the first 100 kills; reseed only for a Museum gap |
| Peridot of Peril (2025) | **Yes** (equipped Nov 19) | Pick the first monster in each zone, once per zone per day | Museum targeting in every register zone; the route lists it as "not yet adapted" |
| Chest Mimic (2024) | **Yes** (11 egg fights Nov 19) | Make eggs of monsters it has fought, then fight copies | Copy source for Museum targets; Heartstone A/P letters |
| Möbius ring (2025) | **Yes** (LOG) | Paradoxicity: at 13, +100% item and +50% booze drops; time-cop fights | Keep at 13 during Museum-drop turns; time cop gives Heartstone E |
| Monodent of the Sea (2025-09) | **Yes** | 11 lightning kill-banishes (rollover); daily +30% item/Meat wave | §4.1 |
| Heartstone (2026-02) | **Yes, nothing unlocked** | Spell words from monster letters: LUCK (1 Lucky!/day), GONE (5 banishes), BOOM (5 kills), BUDS (+5 familiar weight) | Letters that are reachable in aftercore (Tour Guide `2026/Heartstone.ash`): T from tektite (8-bit, green) or a blue/greyhat hacker (CyberRealm zone 1); A from fleaman (8-bit, black) or Black Crayon Fish (Chest Mimic); P from Black Crayon Spiraling Shape; E from met or Keese (8-bit) or time cop (Möbius). The continuum transfunctioner is owned. One-time project; LUCK first, then GONE |
| legendary seal-clubbing club (2026-01) | probable (18 log mentions) | 5 Next Week delayed copies; 5 Battlefield; 5 Back in Time free kills that destroy drops | Next Week on Museum targets; Back in Time only where the drops don't matter |
| Leprecondo (2025) | **installed** (`leprecondoInstalled`) | Furniture needs; Punch Out banish from preworkout powder | Needs an adapter; small |
| black garden rose (2026-10) | Yes (garbo ran 7 rose fights Nov 19) | Free fights, loot | Leave to garbo or the route; never reset |
| Eternity Codpiece (2026) | unknown | Gem slots for Heartstone, Peridot and zirconia (TG) | If owned, frees 2–3 accessory slots for +meat/+item |
| Allied Radio Backpack, Cooler Yeti | no log evidence | +100% item drop; sneak / booze | Check |
| Embezzler only via Lucky! (since 2024-08) | — | — | Change any plan that assumes Embezzler copies |

## 6. Museum strategy

1. **Sort every Display Case item by how it is supplied**: liquid buyable; thin buyable (old event items, discontinued, shrinking supply); unbuyable with a daily source; unbuyable one-off. Spend *daily resources* on the third group, *Meat* on the first two, and the *buy-limit sniper* on everything that is cheap.
2. **Order milestones by Meat per milestone, weighted by how long they will hold.** Entering the top ten is worth more per Meat than going from #2 to #1, because the wiki shows the top ten. Then go for #1 where the current leader's count hasn't moved between snapshots: one purchase holds that place for good. The ranking store already keeps dated snapshots, so add a "competitor delta per week" column and skip items where #1 is actively farming unless Tquilla can outproduce them from a daily source.
3. **Buffer:** at least +11 (the existing setting) *and* at least 1% over #2. For items where #2 is active, use a week of #2's measured growth.
4. **Deposit the surplus nobody will buy.** MSG 68k held / 3,680 in the case; hammers 77k / 10k; happiness 43k / 16k; mojo 42k / 4.1k (lead of 11!); savory noodles 13k / 1.5k. Rule: anything beyond about 180 days of the shop's measured sales goes in the case. The Meat given up is near zero, and the #1 becomes out of reach for anyone. The rough fish scale #1 (740k) can't be reached; lock #2 with 5k+.
5. **Free wins now:** impure gasoline (157 held, 0 in the case) and Z-Bone steak (150 held, 0 in the case) go in today. Then the ledger's nine #1s for ~2.5M.
6. **Buy timing:** event items are cheapest in the 1–3 weeks after an event ends, when farmers sell off (post-Crimbo January especially). Buy-limited cheap listings are rate-limited sources: scan the register's wanted items daily, pay at most 0.8× the 7-day average (Sacha's rule), and respect the half-of-net cap. Keep mall searches throttled (one search per item per day is plenty).
7. **Clan dungeons** (Hobopolis, Dreadsylvania, Slime Tube) are the largest pool of hard-to-get Display Case items. They need clan coordination, so they are out of scope for the script, but worth a separate discussion (L).

## 7. Check in game before building on this

- [ ] Mall sales volume for LED block and synthetic stuffing: can the market take ~70 a day each? If not, the Sword target should rotate between monsters, or go to Museum drops.
- [ ] Price of the Dinseylandfill airplane charter compared with ~143k a day of tickets.
- [ ] Snojo: open `place.php?whichplace=snojo` once to set `snojoAvailable`. CyberRealm: do we have OVERCLOCK(10), Torso Awareness and a zero-trust tanktop?
- [ ] Monodent lightning: does each cast keep its banish until rollover, or is only one active at a time like Spring Kick?
- [ ] Genie: does "for more wishes" make a *tradeable* pocket wish?
- [ ] Is the model train set owned? Is the Eternity Codpiece owned?
- [ ] Does garbo need the ice-house bunny banished?
- [ ] Measure the Barf MPA over 5 garbo days and set `valueOfAdventure` to it.

## Sources
- KoL wiki: [Banish](https://wiki.kingdomofloathing.com/Banish), [Knob Goblin Embezzler](https://wiki.kingdomofloathing.com/Knob_Goblin_Embezzler), [Peridot of Peril](https://wiki.kingdomofloathing.com/Peridot_of_Peril), [Anchor bomb](https://wiki.kingdomofloathing.com/Anchor_bomb), [Sea *dent: Throw a Lightning Bolt](https://wiki.kingdomofloathing.com/Sea_*dent:_Throw_a_Lightning_Bolt), [Monkey Slap](https://wiki.kingdomofloathing.com/Monkey_Slap).
- garbo `eaa1455`: `index.ts` (`defaultTarget`), `target/fights.ts`, `tasks/embezzler.ts`, `lib.ts` (Lucky! valuation), `resources/swordOfSWords.ts`, `tasks/freeFight/index.ts` (Snojo, CyberRealm), `restore.ts`, README (MPA).
- Tour Guide: `Items of the Month/2024/Spring Shoes.ash`, `2025/Seadent.ash`, `2025/Leprecondo.ash`, `2024/Peace Turkey.ash`, `2026/Heartstone.ash`, `2026/Legendary Seal-Clubbing Club.ash`, `2026/Eternity Codpiece.ash`.
- Logs: hearth `61cc0b24…` (Nov 19: garbo summary at line ~66131, Sword haul, sandworms, ticket), `Tquilla_20261123.txt` (Sword seed ~7466, banisher list ~14470, Fat Leon's 662 turns, lily MP ~10665), `Tquilla_20261121.txt` (burnMP −17,797); prefs `tquilla_prefs.txt`.
