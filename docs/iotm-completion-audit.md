# IoTM completion audit

Audit date: 2026-11-28. This is the groundwork for a completionism phase in `smmdaily`: the list of owned Items of the Month that are not yet "maximally unlocked and prepared", what each one needs, what it costs and whether a script can do it. Nothing here is implemented.

The goal it serves is the completionism goal in [aftercore goals](aftercore-goals.md): every non-clan IoTM maximally unlocked and prepared, its zones open, and every copyable monster in the combat lover's locket and other copier collections. The [resource ledger](resource-ledger.md) and the [IoTM route](iotm-route.md) cover how each item's daily charges are spent; this document covers one-time and accumulating progress only.

## Sources and limits

Everything below was read from files on the Windows KoLmafia install, not from the live game:

| Source | Date | Used for |
|---|---|---|
| `data/smm-comprehensive-state-2771003-20261127.json` | 2026-11-27 22:29 UTC | Inventory, closet, storage, Display Case, familiars, skills, campground, workshed |
| `settings/tquilla_prefs.txt` | 2026-11-28 04:52 UTC | Unlock and progress preferences |
| `runlogs/daily/daily-20261127-210002-72433e6a.log` | 2026-11-27 nightly run | Which IoTMs the run actually touched |
| `data/av-snapshot-mritems.txt` | list version 2026.11.08 | The master list of 307 monthly Mr. Store items |
| KoLmafia source and data, r29462 and `main` of 2026-11-27 | | Latte ingredients, Leprecondo furniture, autumn-aton upgrades, monster flags |

Limits to keep in mind:

- **A preference is KoLmafia's memory, not the server's.** A `false` can mean "not unlocked" or "KoLmafia never saw it". Rows that rest on a preference alone say so, and the phase must confirm them in game before spending anything.
- **The locket and the Mimic DNA bank are not in any file.** KoLmafia holds the locket list in memory only, and the state capture recorded it as empty. `scripts/smmCompletionLive.ash` reads it; see [Live read](#live-read).
- **No prices were looked up.** Meat costs are left as "mall price" where a purchase is needed.
- Tquilla is on day 842 of ascension 231, with the level 12 war finished. Several unlocks live in zones that only exist during the war and cannot be reached again without ascending.

## Summary

The list has 140 items from the Time-Spinner (October 2016) onward. Tquilla owns 129 of them, does not own 9, and 2 subscriptions could not be told from files. Nothing older is owned apart from a clan VIP key. Of the 129:

- **3 are still in their packages** and have never been used.
- **1 is the locket**, whose state needs a live read. It is expected to be the largest job by far.
- **9 rows of unfinished permanent progress** are visible in preferences and inventory: Heartstone, latte, Leprecondo, autumn-aton, Gingerbread City, familiar training, Tot costumes, candy cane sword cane and the Lil' Doctor bag.
- **3 more need a live read** before anything can be said: the Mimic DNA bank, the toy Cupid bow and tattoos.
- The rest are either complete or have no permanent progress to make.

Suggested order for the phase, cheapest first: open the three packages (a decision for Sacha), fix the autumn-aton's destination, start Heartstone letters and locket ride-alongs on fights that happen anyway, then spend leftover turns on latte ingredients, Leprecondo furniture and targeted locket sweeps.

## Needs action

"Turns" are paid adventures at the turn value of 4,500 Meat unless the row says the work rides on fights that happen anyway.

| IoTM | State found | Action | Cost | Automatable |
|---|---|---|---|---|
| **Skeleton of Crimbo Past** (stocking full of bones) | Package in inventory. No such familiar in the terrarium; the nightly log never mentions it or knucklebones. | Use the package. Then train the familiar and start earning knucklebones. | No turns. Opening is permanent and gives up the package's resale value. | One `use` command, but `iotmroute` deliberately never opens packages. Needs Sacha's yes. |
| **Legendary seal-clubbing club** (seal-clubbing club loot box) | Package in inventory. No club owned. The route lists its three skills as "pools available, no worker". | Use the package. | As above. | As above. |
| **Meat Shield Maiden** (meat shield toddler) | Package in inventory. No such familiar. The route already has blessing workers that cannot run. | Use the package, then train the familiar. | As above. | As above. |
| **Combat lover's locket** | Owned and worn on Spacegate turns. Collection unknown (see limits). KoLmafia r29462 lists 1,449 monsters that are copyable and not bosses. | Fight each missing monster once with the locket equipped. | One fight per monster. Free when the monster is met on a turn or free fight that happens anyway, at the price of an accessory slot. Otherwise 1 turn each, more for rare monsters. Some need a day pass, an event zone or a wish. | Yes, in two parts: keep the locket on whenever the current zone still holds a missing monster, and sweep zones with leftover turns. The live read gives the per-zone list. |
| **Heartstone** | `heartstoneKillUnlocked`, `BanishUnlocked`, `StunUnlocked`, `LuckUnlocked`, `PalsUnlocked` and `BuffUnlocked` are all `false`; `heartstoneLetters` is empty; the stone is in inventory, not worn. Preference only. | Spell KILL, BANISH, STUN, LUCK, PALS and BUFF. A letter comes from a kill, with the stone equipped, of a monster whose name (spaces removed) has an odd length; the letter is the middle one. | 26 letters, so at least 26 kills. Free if they ride on scheduled fights against suitable monsters, at the price of an accessory slot; otherwise up to 26 turns. | Yes. KoLmafia tracks letters, and the middle letter is computable from a monster's name, so a script can pick monsters per missing letter. The route automates none of this today. |
| **Latte lovers member's mug** | 10 of 55 ingredients unlocked: pumpkin, cinnamon, vanilla, cajun, carrot, guarna, ink, paradise, rawhide, sandalwood. | Adventure in each missing ingredient's zone with the mug equipped until it is found. List under [Latte ingredients](#latte-ingredients). | A few turns per ingredient, so roughly 150 to 400 turns for the 41 that can be reached, plus access costs for sea, Hobopolis, FantasyRealm and Worm Wood zones. Off-hand slot. Whether free fights can find an ingredient is not verified. | Yes. KoLmafia records `latteUnlocks`, and `smmUtils` already maps ingredients to zones. Four ingredients are in wartime zones and are blocked. |
| **Leprecondo** | 19 of 27 furniture pieces discovered. Missing: 7, 10, 15, 16, 18, 19, 24, 26. | Adventure in each missing piece's zone with the Leprecondo in inventory. List under [Leprecondo furniture](#leprecondo-furniture). | A few turns per piece. The sensory deprivation tank also needs the Marinara Trench map, which is not bought. | Yes. KoLmafia records `leprecondoDiscovered`. At most five of the eight are reachable this ascension. |
| **Autumn-aton** | 7 of 9 upgrades: missing the energy-absorptive hat (`base_blackhat`) and dual exhaust (`dualexhaust`). The nightly run sends it to the Copperhead Club every time. | Send it once to a zone of each type that holds a missing upgrade. | No turns. Two dispatches, each replacing one Copperhead Club trip. | Yes, a small change to where the daily script sends it until both are attached. The zone type for each upgrade needs looking up. |
| **Gingerbread City** | Clock, retail district and sewers are unlocked. `gingerExtraAdventures=false`, `gingerSubwayLineUnlocked=false`, `gingerTrainScheduleStudies=0`, `gingerDigCount=0`, `gingerLawChoice=0`, `gingerMuscleChoice=0`, `gingerBlackmailAccomplished=false`. Preference only. | Buy the extra-adventures upgrade if it is truly missing; study the train schedule (KoLmafia counts up to 10 studies); finish the dig, law, gym and blackmail chains. | Sprinkles for the upgrade. The chains use the city's noon and midnight choices, one a day, so they ride on the existing daily Gingerbread grind for a few weeks. | Yes, by choice settings inside the existing grind. Confirm each state in game first. |
| **IoTM familiars under 20 lb** | Cooler Yeti 1 lb (0 XP), Grey Goose 5, Optimistic Candle 10, God Lobster 10, Melodramedary 10, Mini Kiwi 10, Peace Turkey 10, Elf Operative 10, Garbage Fire 13, Vampire Vintner 14, the three Crimbo ghosts 17 each. | Train each to 400 XP. | About 3,260 familiar XP in total, plus 400 for each of the two packaged familiars once hatched. No Meat. The Mayam fur ring (100 XP a day) and the Apriling piccolo (120 XP a day) would cover it in about three weeks if nothing else claims them. | Yes. The planner already has pools for both sources. |
| **Trick-or-Treating Tot** | Costumes owned: unicorn, pirate, ninja, candy corn, knight, ghost. Missing: robot, liberty, eldritch horror, clown. | Buy the four missing costumes. | Mall price, under the spending rules. | Yes, through `smmSpend`. |
| **Candy cane sword cane** | Once-per-ascension choices not yet taken: the Fun House and the Shore. Three more are in wartime zones. | Take the two reachable choices with the cane equipped. | 1 turn each (the Shore trip costs 3). | Yes. |
| **Lil' Doctor bag** | `doctorBagUpgrades=7`. A house call is open: bring anti-anti-antidote to the Hidden Hospital. | Finish the open house call, and keep doing them if the bag is not at its upgrade cap. | An item at mall price and about a turn per call. | Yes. The upgrade cap was not confirmed. |

### Latte ingredients

The 45 missing ingredients and where KoLmafia says each is found.

- **Ordinary zones:** basil (The Overgrown Lot), belgian (Whitey's Grove), butternut (Madness Bakery), carrrdamom (Barrrney's Barrr), chalk (The Haunted Billiards Room), chili (The Haunted Kitchen), cloves (The Sleazy Back Alley), coal (The Haunted Boiler Room), cocoa (The Icy Peak), dwarf (Itznotyerzitz Mine), flour (The Road to the White Citadel), fungus (The Fungal Nethers), grass (The Hidden Park), greasy (Cobb's Knob Barracks), healing (The Daily Dungeon), hellion (The Dark Neck of the Woods), lihc (The Defiled Niche), lizard (The Arid, Extra-Dry Desert), mega (Cobb's Knob Laboratory), mold (The Unquiet Garves), noodles (The Haunted Pantry), norwhal (The Ice Hole), oil (The Old Landfill), paint (The Haunted Gallery), sausage (Cobb's Knob Kitchens), space (The Hole in the Sky), squash (The Copperhead Club), teeth (The VERY Unquiet Garves), venom (The Middle Chamber), vitamins (The Dark Elbow of the Woods), wing (The Dark Heart of the Woods).
- **Need extra access:** salt (The Briny Deeps), rock (The Brinier Deepers), msg (The Briniest Deepests) and squamous (The Caliginous Abyss) are underwater; ancient (The Mouldering Mansion) needs absinthe; grobold (The Old Rubee Mine) is a FantasyRealm zone; hobo (Hobopolis Town Square) is a clan dungeon; bug-thistle (The Bugbear Pen) and gunpowder (1st Floor, Shiawase-Mitsuhama Building) may not be open to this character; filth (The Feeding Chamber) is part of the war's orchard.
- **Wartime only, blocked:** diet (Battlefield, no uniform), dyspepsi (Battlefield, Dyspepsi uniform), greek (Wartime Frat House, hippy disguise), kombucha (Wartime Hippy Camp, frat disguise).

### Leprecondo furniture

| # | Piece | Zone | Reachable now |
|---|---|---|---|
| 7 | gigantic chess set | An Octopus's Garden | Yes, underwater |
| 10 | beer pong table | The Orcish Frat House | Only if the frat house was not bombed |
| 15 | sensory deprivation tank | The Marinara Trench | Yes, underwater, after buying the map |
| 16 | fruit-smashing robot | Wartime Hippy Camp (Frat Disguise) | No, wartime only |
| 18 | couch and flatscreen | The Orcish Frat House | Only if the frat house was not bombed |
| 19 | kegerator | The Orcish Frat House (Bombed Back to the Stone Age) | Only if the frat house was bombed |
| 24 | ultimate retro game console | Megalo-City | Not verified |
| 26 | fully-stocked wet bar | The Purple Light District | Clan dungeon |

## Needs a live read

Nothing can be said about these from files.

| IoTM | What is unknown | How to read it | Likely action |
|---|---|---|---|
| Combat lover's locket | Which monsters it holds. | `call smmCompletionLive.ash` | See [Needs action](#needs-action). |
| Chest Mimic | Which monsters are in the Mimic DNA bank. KoLmafia tracks only today's counts (3 donations and 11 eggs a day) and the eggs currently held, which is none. | Visit the DNA bank choice and parse it. Not scripted yet. | Donate an egg of each monster not yet banked: at most 3 a day, each egg costing familiar XP. This is the other per-monster copier collection. |
| Toy Cupid bow | Which familiars have already had their equipment from the bow. | Compare owned familiar equipment against the 173 familiars. Not done here. | Five fights with the bow on each remaining familiar. Rides on any fights. Overlaps the Museum goal, since familiar equipment is displayable. |
| IoTM tattoos and trophies | FantasyRealm, Spacegate, PirateRealm, TakerSpace, burning leaves, Interesting Coin and similar tattoos; the state capture does not include tattoos. | Read the tattoo page. | Buy or craft any that are missing with the item's own currency. |

### Live read

`scripts/smmCompletionLive.ash` is read-only. It opens the locket's reminisce page, which uses no charge, and writes `data/smm-completion-live-<player id>.txt`: the count held, and one line per missing copyable non-boss monster with the zones KoLmafia lists for it. It has compiled offline and has not been run in game.

## Blocked or needing a decision

- **Open the three packages?** Opening is permanent, and the route has never opened a package on its own. Completionism says yes.
- **Wartime zones.** Four latte ingredients, one to three Leprecondo pieces and three candy cane sword cane choices cannot be had on day 842 of an ascension with the war over. They become possible only by ascending. If Tquilla stays in aftercore, the checklist should count them as out of reach rather than as open work.
- **Cargo Cultist shorts.** 428 of 666 pockets are emptied and pockets only refill on ascension. At one a day the shorts run dry in about 238 days. Nothing to do now.
- **Clan zones.** Hobopolis and Dreadsylvania hold a latte ingredient and Leprecondo furniture. Clan items are out of scope, but these unlock progress on non-clan IoTMs, so they are listed.

## Checked, nothing to do

Complete on the evidence available:

- **Beach Comb:** all 11 beach heads unlocked.
- **PirateRealm:** all 18 Fun-a-Log unlocks, both skill books learned.
- **Spacegate:** all three vaccines unlocked.
- **God Lobster:** all five regalia owned.
- **Guzzlr:** platinum deliveries unlocked (428 bronze, 5,277 gold, 65 platinum), all three pieces of gear owned.
- **Everfull Dart Holster:** 20 perks, 8,457 darts thrown.
- **Bat wings:** all four Bat Hole shortcuts taken.
- **Emotion chip, Comprehensive Cartography, Pocket Meteor Guide, book of facts, August Scepter, 2002 Mr. Store Catalog:** skills learned, monolith installed.
- **CyberRealm:** open (`crAlways`), daily zones rolling, every Dedigitizer product owned at least once.
- **FantasyRealm, Neverending Party, the LOV Tunnel, the Speakeasy, the Getaway Campsite, the voting booth, Boxing Daycare, the Shadow Rifts:** open.
- **Time-Spinner:** 6,276 medals.

No permanent progress to make, daily use only (see the ledger): potted tea tree, Space Jellyfish, Robortender, Kremlin's Greatest Briefcase, genie bottle, XO Skeleton, pantogram, mumming trunk, garbage tote, SongBoom BoomBox, Cat Burglar, Bastille Battalion, Kramco, vampyric cloake, Cosplay Saber, moon-rune spoon, Pocket Professor, pill keeper, Red-Nosed Snapper, Retrospecs, Bird-a-Day calendar, Powerful Glove, Left-Hand Man, Iunion Crown, SpinMaster lathe, retro superhero cape, the Crimbo ghosts' box, fresh coat of paint, miniature crystal ball, potted power plant, backup camera, Shorter-Order Cook, familiar scrapbook, fire extinguisher, Daylight Shavings Helmet, cursed magnifying glass, cosmic bowling ball, unbreakable umbrella, MayDay contract, June cleaver, designer sweatpants, tiny stillsuit, Jurassic Parka, cookbookbat, Hobo in Sheep's Clothing, S.I.T. certificate, pay phone, monkey's paw, Cincho de Mayo, Patriotic Eagle, Jill-of-All-Trades, burning leaves, spring shoes, Apriling band helmet, Mayam Calendar, Roman Candelabra, tearaway pants, Sept-Ember Censer, McHugeLarge duffel bag, April Shower Thoughts shield, Peridot of Peril, prismatic beret, Möbius ring, Monodent of the Sea, blood cubic zirconia, shrunken head, Archaeologist's Spade, Baseball Diamond, legendary pasta wand, Sword of S Words, Cup of 13s, Interesting Coin, legendary acorndion.

One slot, several owners. Being "prepared" here means owning each so it can be swapped in:

- **Workshed:** TakerSpace is installed. Asdon Martin, diabolic pizza cube, cold medicine cabinet and model train set are owned and idle.
- **Garden:** mushroom is installed. Thanksgarden, tall grass, rock and black rose are owned.

Several of the daily-use items have abilities the route does not use yet. Those are listed in the "Remaining specialized abilities" column of the [IoTM route](iotm-route.md#current-executor-coverage-newest-first) and are not repeated here.

## Not owned

Out of scope until bought. From the Time-Spinner onward: Beer Garden, Xi Receiver Unit, New-You Club, Horsery, lucky Tam O'Shatner, wardrobe-o-matic, Allied Radio Backpack, Eternity Codpiece, Portable Laughing Stock. Nothing older than the Time-Spinner is owned, which also rules out the Snojo, the Chateau, the Source Terminal, Witchess, the elemental airports and the other older zones the goal names. Two subscriptions could not be told from files: Our Daily Candles and the Black and White Apron (946 meal kits are on hand, so the Apron is probably owned).

## Not covered

- Zones that no IoTM opens, such as the unbought sea maps (Marinara Trench, Dive Bar, Madness Reef, Skate Park).
- The 140 familiars under 20 lb that are not IoTMs.
- Shop gear that was never bought with an IoTM's own currency (Sept-Ember gear, lathe weapons, Mini Kiwi gear, Spacegate gear). These are Display Case targets and belong to the [target register](target-register.md).

## What the phase needs first

1. Sacha's answers on the three packages and on wartime-only progress.
2. One run of `smmCompletionLive.ash`, so the locket work can be sized.
3. A checklist that reads each state above from the game rather than from preferences, as the goals document asks. Each row in [Needs action](#needs-action) names the preference or item to start from.
