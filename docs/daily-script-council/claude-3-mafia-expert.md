# Memo 3: KoLmafia expert

Council member 3 (KoLmafia). Round 1, 2026-11-23. Inputs: the brief, `docs/*`, the resource ledger, `tquilla_prefs.txt`, `dailyGrind()`, the `smmIotmRoute*` scripts, `smmRecovery.ash`, `smmUtils.ash` (KoLUtils), garbo's source, and three session logs: 11-19 (full day, about 7 MB), 11-21 (the stalled run) and 11-23 (today: four logins, then `dailyGrind`, then `garbo -10`). The log line numbers below are from those files.

## 0. Positions in one screen

1. **The MP "stall" has a different cause than the ledger says.** `burnMP burning -17797` means "keep 17,797 MP" (0.65 × max MP, from `manaBurningThreshold`), not "spend 17,797". Both stalled days began the script with almost no MP. On 11-21, mafia's breakfast spent it on `cast 22 Summon Dice`. On 11-23, the character logged in at 82 MP and was at 0 after breakfast. Then `secondBreakfast → burnFreeDaycare → daycareScavenge → preAdventureChecks(3) → burnExtraMP → burnMP → moodExecute` tried to cast songs and a facial expression with no MP. Recovery is switched off (`mpAutoRecovery=-0.05`, `recoveryScript` empty), and `moodExecute` calls `abort()` when the facial-expression cast fails. **Fix:** an MP bootstrap phase before any casting, and no `abort()` in mood upkeep.
2. **`valueOfAdventure` is now 4500, not 500.** The shared `smm-prefs.txt` sets it, and garbo printed `Using adventure value 4500.` The scripts still use 5,000 (`smm.TurnValue` is unset). Pick one number and have every script read `valueOfAdventure`.
3. **Lean on mafia** for: breakfast, mood upkeep, recovery (`restore_mp`/`restore_hp` with an explicit reserve), `choiceAdventureNNN` props, CCS plus a server-side autoattack macro for farming, `buy(qty, item, maxPrice)` with explicit limits, `historical_price` for valuation, `_`-prefixed daily props for "done today", `batch_open/close`, `reprice_shop`, and `logprint`. **Don't reimplement** mood burning every turn, outfit re-maximizing every turn, or session-scoped "done" checks.
4. **Make phases idempotent:** each phase has a "done" test made of mafia properties, a postcondition check, a loop guard, and settings saved and restored in `finally`. No `user_confirm` without a preset answer. No `my_session_*` as a done marker: today had 4 logins.
5. **The current run costs about 8 logged server requests per adventure** (≈3,000 for 350 adventures), plus about 250 real maximizer runs. Most of that is dressing and mood checks before every turn. About half can be cut without losing value.

## 1. What the logs show

### 1.1 MP: the actual failure chain

| Evidence (quoted) | Where |
|---|---|
| `MP: 2089 / 20,340` at login, then `cast 22 Summon Dice` in breakfast, then `MP: 10 / 20,340` | 11-21 l.542, 1424, 1501 |
| `> burnMP burning -17797 mp …` then `cast 1 Tongue of the Walrus`, `Closing session` (no `burnMP done`, no daycare adventure) | 11-21 tail |
| `MP: 82 / 20,122` (login), `MP: 0 / 20,122` (2nd login), the same `burnMP burning -17819` at daycare, then `Closing session` | 11-23 l.178, 1112, 4275–4282 |
| The run that worked started at `MP: 796 / 27,414`. It got through daycare and only refilled later from the route's 11 × `cast 1 Rest upside down` (`You gain 1,000 Muscularity Points` each) | 11-23 l.4989, 8484–8780 |
| `Round 3: You gain 39,200 Muscularity Points` after `casts GULP LATTE!` | 11-23 l.23293 |
| `moodExecute: not enough mp to fill song space with …` (4×), and `use 1 carbonated water lily` → `You gain 61 Muscularity Points` (14 single uses) | 11-23 |

Note: KoL calls MP "Muscularity Points" for muscle classes, so these are MP gains.

What follows from this:
- KoL rollover does not refill MP for this character: every morning starts near 0.
- `libramSkillsSoftcore` is now `none` in the shared prefs (it was `all` on 11-21; the burnMP backup `_smm.Backup_libramSkillsSoftcore=all` shows it).
- The 11-23 failure had no libram casts at all. The structural bug is the **order of steps**: MP-spending steps run before any MP-gaining step.
- `burnMP` sets `logPreferenceChange=false`. That is why the stall leaves no trace in the session log. Never turn it off; use `logPreferenceChangeFilter` for noisy properties instead.
- The biggest free MP sources are **not** being used in the morning:
  - License to Chill (`_licenseToChillUsed`), which `burnLicenseToChill` already uses after `maximize("mp")`. It refills MP, so its value scales with max MP, which reaches 75–80k in MP gear.
  - Gulp Latte: one gulp gave 39,200 MP.
  - Bat-wing rests: 11 × 1,000.
  - The nuns: `nunsVisits`, 3 × 1,000.
  - Free rests: `timesRested` vs `total_free_rests()`, plus `_cinchoRests`.

### 1.2 Prompts
- `dailyGrindConfirm` waits `user_confirm(prompt, 60000, default)`, and **no `smm.dailyGrind.*` preset exists** in the prefs file, so all six prompts can pause for 60 s each.
- Prompts that **abort when they time out** (default false): `smmUtils.ash:6144` (`buffColdRes`) and `smmUnrestricted.ash:6326–6338` (Dread gear).
- Prompts with **no timeout**, which block forever: `GodLobster.ash:114` and `smmUnrestricted.ash:5510`.
- `smmRecovery.ash` asks with `user_confirm` before eating a magical sausage. It is harmless only because `recoveryScript` is empty.

### 1.3 Other failures and wasted hits
- **Macro references an item that isn't there:** 104 × `lastMacroError → Could not match item(s) for use: use blue rocket` (11-23). `smmConsult.ash:1505` adds `use blue rocket;` whenever Everything Looks Blue is off, without checking that a rocket is in inventory. The rockets are bought only in the in-Ronin branch (`smmUtils.ash:10459`).
- **The leaf jump never confirms.** On 11-23 the route took `choice 1510/2 "Jump in the Flames"`, then printed `NOT achieved … postcondition not confirmed`, and planned it again in every later route invocation (11-23: 4 plans, 2 visits; 11-19: 4 visits). The worker keys on `_leavesJumped`, and **no such property ever appears** in the prefs file or the logs. Confirm the real name with `prefref leaf` in the gCLI, or own a `_smm.leafJumpTried` flag.
- **Store stocking churn:** `Removing 136 drippy nugget from store`, two `mallsearch "drippy nugget"`, then `Adding 136 …` at the same price. Over the day that was 40 removes, 46 adds, 31 `updateinv` reprices and 141 mall searches, and stocking ran in two sessions.
- **Daycare loop hazard:** `burnScavengeDaycare(0)` loops `while (turnsToSpend >= nextScavengeTurnCost)`. If `_daycareGymScavenges` doesn't increment (a choice mismatch, or a session reset), cost stays 0 and the loop never ends.
- **Grind ledger values are inflated:** `gingerbread took 0 turns … items worth 45899714`, `ghostCostume took 5 turns … items worth 16504714`. Item deltas probably pick up shop, closet or case moves, or prices like `drippy stake @ 5995948`. Don't let the turn-value test trust them until items are valued at realizable sale value and shop stock is counted.
- **The route's discovery pass ran 4 times on 11-23** (`79 actions … 28 planning passes`, then 13/2, 12/3, 2/2). Each pass re-reads inventory, item descriptions, garden pages and shops.
- **Garbo can't reach GitHub** from Windows: `Garbo may be out of date, unable to query GitHub`. This is cosmetic, but it means `git update` may be failing there too, which matters for shared settings.

### 1.4 Cost of today's `dailyGrind` (11-23, lines 4942–53442)

| Measure | Count | Per adventure (350) |
|---|---|---|
| `equip …` requests | 793 | 2.3 (latte mug 88, Kramco 70, cursed magnifying glass 44) |
| `dressup` calls / `Maximizer:` lines / "skipping maximize" | 630 / 593 / 342 | ≈250 real maximizer runs |
| `preAdventureChecks` / `burnMP` | 585 / 597 | 1.7 each (once from `betweenBattleScript`, again inside `dressup`/`daycareScavenge`) |
| `cast` / `use` / choice requests / macro submits | 549 / 86 / 381 / 442 | |
| `_concoctionDatabaseRefreshes` | +738 (1,065 by the end of the day) | CPU, not server |

That is about 3,000 logged requests plus unlogged status refreshes. At 0.3–0.6 s each, that is roughly 15–30 minutes of server time, plus several minutes of maximizer CPU. The logs have **no timestamps**, so wall-clock time can't be measured yet (see §5).

## 2. Mafia facilities to lean on

| Facility | Use it for | Concrete settings / signatures | Don't |
|---|---|---|---|
| **Breakfast** | Standard summons, clan furniture, garden (none: the route owns it), Crimbo toys | Keep `breakfastSoftcore` and `breakfastAlways`. Set `libramSkillsSoftcore=none`, `grimoireSkillsSoftcore=all`, `tomeSkillsSoftcore=all`, `loginRecoverySoftcore=true`. Breakfast is done when `breakfastCompleted=true` and `lastBreakfast` = today's day count | Don't rely on breakfast for casts when MP is ~0. Mafia sets `breakfastCompleted` even when casts fail, so after the MP bootstrap re-check each summon's own counter (`cocktailSummons`, `reagentSummons`, `noodleSummons`, `_candySummons`, `_lunchBreak`, `_holidayFunUsed`, `_summonCarrotUsed`, `_perfectFreezeUsed`, `_rhinestonesAcquired`, `_preventScurvy`, `_bowlFullOfJellyUsed`, `_eyeAndATwistUsed`, `_chubbyAndPlumpUsed`, `_radlibSummons`) and cast what's missing |
| **Moods** | Buff upkeep between battles: mafia runs the current mood before each adventure | `currentMood=current extends unrestricted, turtletamer`. Change moods per phase with `cli_execute("mood X")` | Don't run `mood execute` plus `burnMP` before every turn (597 calls today). Burn spare MP at phase boundaries only |
| **Mana burning** | Extending buffs with spare MP | Pick **one** of two: mafia's built-in burner (`manaBurningTrigger`/`manaBurningThreshold`, both fractions of max MP; a negative value disables it; `allowNonMoodBurning=false`), or smm's `burnMP(-reserve)` at phase ends | Don't use both, and never burn below the day's reserve |
| **Recovery** | Keeping MP/HP above a floor | Call `restore_mp(int)` / `restore_hp(int)` explicitly in the hook. Rewrite `mpAutoRecoveryItems` with big restores first and drop `carbonated water lily` (61 MP each). Add `free rest` (listed in the HP/MP Usage tab; `restUsingCampAwayTent`/`restUsingChateau` choose where to rest). Keep the global `mpAutoRecovery=-0.05` during scripted phases, as the route already does | Don't use a `recoveryScript` that prompts. Fix or delete `smmRecovery.ash` |
| **Maximizer** | One outfit per phase objective | `maximize(string expr, int maxPrice, int priceLevel, boolean simulate, boolean includeEquip)`. Use `maxPrice=0, priceLevel=0` in scripts so the maximizer never buys (today `maximizerEquipmentScope=2`, `maximizerMaxPrice=1000` and `maximizerCreateOnHand=true` let it buy or craft outside the spending cap). Weight like garbo: `"<baseMeat/100> Meat Drop, <Σvalue×rate/100> Item Drop, -tie"` plus `N bonus <item>` for gear with Meat value | Don't re-maximize every turn. Save the result with `outfit save smm.<phase>` and restore that |
| **Purchasing** | Every Meat-spending path | `buy(int qty, item it, int maxPrice)` returns the count bought. `retrieve_price(item, qty)` gives the cost before you commit. Keep `autoBuyPriceLimit=20000` as a backstop. In daily phases set `autoSatisfyWithMall=false` and `autoSatisfyWithCoinmasters=false` (the latter protects Interesting Coins and Rubees), as the route does | Don't let `retrieve_item`, `fullAcquire` or the maximizer buy silently. Each purchase should go through the smmSpend ledger |
| **Prices** | Valuation | `historical_price(item)` and `historical_age(item)` never hit the server. `mall_price(item)` searches once per item per session (later calls use the cached value). Garbo's rule: `historical_age ≤ 7` → `0.9 × historical_price`, or autosell if the price is the mall minimum. Pricegun only for the average sale price (the spending rule), cached daily | No `mallsearch` loops. Store stocking did 141 today |
| **Choices** | Fixed answers | `choiceAdventureNNN` properties, saved and restored per phase (`saveAndSetProperty`). `run_choice(int)` / `run_choice(int, string)`, `available_choice_options()`. For answers that depend on Museum need (PirateRealm, Drip), a `choiceAdventureScript` | Don't hard-code `visit_url("choice.php?…")` when a property would do |
| **Combat** | Fights | A CCS (`customCombatScript`) for general use, and an **autoattack macro** (`set_auto_attack(name)`, the macro stored on the KoL server) for repeated farm targets, which saves a request per fight. `adv1(location, -1, "")` for one encounter that follows preset choices. Check `lastMacroError` and `_lastCombatLost` after each fight | Don't put `use <item>` in a macro without `if hascombatitem <item>` |
| **Inventory moves** | Display Case, closet, shop | `batch_open(); put_display(…)…; batch_close();` folds same-command calls into one request. `reprice_shop(price, limit, item)` instead of take plus put | |
| **Session logging** | Audit | `logprint(now_to_string("HH:mm:ss") + " phase X start")` at every phase boundary. Keep `logPreferenceChange=true` and put noisy keys in `logPreferenceChangeFilter` (`_concoctionDatabaseRefreshes`, `lastEncounter`, …) | Don't toggle logging off inside helpers |
| **Tracking** | "Done today" | `_`-prefixed properties (mafia resets them at the first login of a new day) and day-reset counters without the underscore (`nunsVisits`, `noodleSummons`, `timesRested`, `tomeSummons`). `prefref <text>` lists names. `daycount()` and `today_to_string()` date-stamp script-owned state | Don't use `my_session_items`/`my_session_meat` as done markers: they reset at every login |

## 3. Robustness design

**Phase contract.** Each phase is `{ name; done(); ready(); run(); verify(); }`, the same shape as garbo's grimoire tasks (`completed`/`ready`/`do`).
- `done()` reads mafia properties first and `_smm.daily.<phase>=done` second.
- `run()` saves the settings it changes and restores them in `finally`.
- After `run()`, `verify()` compares property deltas. Two failed attempts mark `_smm.daily.<phase>=blocked`, and the day continues with the next phase.
- Loops carry an iteration cap (the daycare loop needs one).
- The route already does all of this (`smm.IR.activeEpoch` lock, `smm.IR.savedSettings`, `iotmroute reset`). Generalize it rather than invent a new pattern.

**Aborts.** ASH has `try/finally` but no `catch`, so one `abort()` ends the whole day. Use `abort` only for real safety stops: lost combat, Beaten Up, an unresolved fight or choice. Phases return booleans for everything else. If a phase is written in JS, wrap it in `try/catch` the way garbo does.

**On start or restart:**
1. If `current_round() > 0`, finish the fight with `run_combat()`. If `handling_choice()`, stop with a message, as the route does.
2. Run `smmPrefs check`. Refuse to continue if critical keys differ: `valueOfAdventure`, `libramSkillsSoftcore`, `customCombatScript`, the recovery keys.
3. Skip done phases, re-verify started ones, and print a one-line status per phase.

**Prompts.** One helper, `smmAsk(name, prompt, default)`:
- If `smm.dailyGrind.<name>` or `smm.ask.<name>` is set, use it.
- Else, if `smm.unattended=true`, return `default` immediately and log the choice (this is garbo's `garbo_autoUserConfirm` pattern).
- Else, `user_confirm(prompt, 60000, default)`.

Ban bare `user_confirm(msg)`. Give abort-on-false prompts a preset of `true`, or remove them from the daily path.

**Rollover.** Before each phase, compare ASH `rollover()` with now (smm's `timeToRollover()` already does). Below 30 minutes, skip straight to the nightcap and rollover-gear phase. Below 5 minutes, stop (garbo uses `garbo_rolloverBuffer=5`). Date-stamp every non-`_` state key with `today_to_string()`.

**Server lag and timeouts.** Mafia's request layer retries transient failures. The script's defence is to be restartable, not to sleep and retry. After any ambiguous result, run `refresh inventory` or `refresh status`, then re-read the properties before acting again.

**Two machines.**
- `_` counters live in each machine's own `tquilla_prefs.txt`. Many of them (`_batWingsRestUsed`, `_backUpUses`, `_godLobsterFights`, the `_smm.*` flags) are tracked only locally, so the second machine believes they are 0.
- Non-underscore script state (`smm.IR.garden*`, `smm.spend.*`, `smm.grind.hist*`) diverges between machines too.

Rules:
1. One **runner** machine per day. Set `smm.daily.runner=true` only in Windows's local prefs; it is not in `smm-prefs.txt`. On any other machine, `daily` defaults to dry-run.
2. If the runner changes mid-day, run `refresh all` and treat locally-tracked counters as unknown: attempt the action and parse the response.
3. Keep the moods file and the CCS in sync before running (`git update`, then copy the moods file per `shared-settings.md`).

## 4. Concrete fixes

**MP (this one blocks the day):**
1. New phase `mp_bootstrap` after mafia's breakfast and **before** `secondBreakfast`:
   1. `maximize("mp", 0, 0, false, true)`.
   2. If `!_licenseToChillUsed`, use the License to Chill.
   3. Top up in this order: `_batWingsRestUsed < 11` → `nunsVisits < 3` → free rests (`timesRested < total_free_rests()`, `_cinchoRests`) → `_eternalCarBatteryUsed`.
   4. Restore the farming outfit.
2. Then cast summons, songs and `burn` down to a **reserve R** (2,000, or computed as the combat skills' MP for the next N fights plus one cast of each mood skill).
3. `moodExecute`: replace the `abort` on a failed facial expression with a warning.
4. `burnMP` and `burnExtraMP` return early when `my_mp() < R`.
5. The pre-adventure hook does only `if (my_mp() < R) restore_mp(R);`. Mafia's mood handles buffs.
6. Spend Gulp Latte (`_latteDrinkUsed`, up to once per refill: `_latteRefillsUsed < 3`) in a fight when MP drops below 50%.
7. `mpAutoRecoveryItems`: keep `visit the nuns`, add `free rest`, remove `carbonated water lily`. Keep magical sausages (`_sausagesEaten`) behind the Museum guard, without a prompt.

**`valueOfAdventure`:** set `valueOfAdventure` and `smm.TurnValue` to the same value (5000 until the grind ledger measures it), and have `smmIRTurnValue()` and `smmRP` read `valueOfAdventure` when `smm.TurnValue` is unset. Garbo refuses to run at ≤3500, and its diet and copy-target values scale with this number. Mafia's maximizer and creation costs use it too.

**Prompts:** add the six presets to `smm-prefs.txt`. Recommended values, to confirm with the KoL expert: `sea=true`, `stopForBounty=false`, `useBanishers=true`, `highItem=true`, `dolphin=true`, `gingerbreadItems=true`. Add `smm.unattended=true`.

**Others:**
- Guard the blue rocket: `if (item_amount($item[blue rocket]) > 0)` or `if hascombatitem blue rocket`.
- Fix the leaf jump's counter name.
- Add a max-iteration guard to `burnScavengeDaycare`.
- Store stocking: use `reprice_shop`, skip when the price is unchanged, run once a day (`_smm.storeStocked`), and use `mall_price` instead of two `mallsearch`es.
- Cache route discovery per day.
- Don't toggle `logPreferenceChange`.
- Set `stopForUltraRare=false` for unattended runs, after logging `lastEncounter`; review that choice with the KoL expert.

## 5. Property map: "already done today"

| Ledger line | Mafia property (verified in the prefs file or the logs) |
|---|---|
| Hermit clovers | `_cloversPurchased` (3) |
| Potted power plant | `_pottedPowerPlant` (a per-plant list; all 0 = collected) |
| Noodles, reagents, cocktails | `noodleSummons`, `reagentSummons`, `cocktailSummons`; pasta wand crafts `_legendaryPastaWandCrafting` (5) |
| Time-Spinner | `_timeSpinnerMinutesUsed` (10), `_timeSpinnerReplicatorUsed` |
| Rad Libs, tomes | `_radlibSummons`, `tomeSummons` |
| BACON, candy cane, globs | `_baconMachineUsed`, `_candyCaneSwordOvergrownShrine`, `_aprilShowerGlobsCollected` |
| Daily item uses | `_snowballFactoryUsed`, `_cocoaDispenserUsed`, `_meatballMachineUsed`, `_airFryerUsed`, `_overflowingGiftBasketUsed`, `_gnollEyeUsed`, `_creepyVoodooDollUsed`, `_bagOfCandyUsed`, `_highTopPumps`, `_guildManualUsed`, `_bookOfEverySkillUsed`, `_2002MrStoreCreditsCollected` / `availableMrStore2002Credits` |
| Clan | `_klawSummons`, `_deluxeKlawSummons`, `_clanRumpusSpotNVisited`, `_lookingGlass`, `_floundryItemCreated`, `_fireworksShop`, `_poolGames`, `_photocopyUsed` |
| Adventures | `_etchedHourglassUsed`, `_latteRefillsUsed`, `_circadianRhythmsRecalled`, `_mafiaThumbRingAdvs`, `_licenseToChillUsed`, `_mayamSymbolsUsed`, `_juneCleaverFightsLeft`, `_sweatOutSomeBoozeUsed` (3), `_sausagesEaten`, `_universeCalculated`; organs via `my_fullness()`, `my_inebriety()`, `my_spleen_use()` |
| Beach Comb, Censer, TakerSpace | `_freeBeachWalksUsed` (10); `availableSeptEmbers` + `_septEmberBalanceChecked`; `_takerSpaceSuppliesDelivered`, `takerSpace*` balances |
| Free fights | `_neverendingPartyFreeTurns` (10) / `_questPartyFair`; `_sausageFights`; `_shadowRiftCombats` + `_shadowAffinityToday` / `encountersUntilSRChoice`; **`_cyberFreeFights` (10)**; **`_snojoFreeFights` (10)** + `snojoSetting`; `_loveTunnelUsed`; `_speakeasyFreeFights` (3); `_voteFreeFights` (3); `_godLobsterFights` (3); `_aprilBandTomUses` (3); `_voidFreeFights`; `_eldritchTentacleFought`, `_eldritchHorrorEvoked`; `_molehillMountainUsed`; `_glitchMonsterFights`; `_mushroomGardenFights`; `_witchessFights`; `_batWingsFreeFights` (5) |
| Free kills | `_chestXRayUsed`, `_shatteringPunchUsed`, `_gingerbreadMobHitUsed`, `_spikolodonSpikeUses`; dart bullseye uses the effect "Everything Looks Red" (`have_effect`) |
| Banishes | `_feelHatredUsed`, `_snokebombUsed`, `_kgbTranquilizerDartUses`, `_reflexHammerUsed`, `_latteBanishUsed`, `cosmicBowlingBallReturnCombats`, `scrapbookCharges`, `_saberForceUses`; active banishes in `banishedMonsters` |
| Copies, replacers | `_backUpUses` (11), `_powerfulGloveBatteryPowerUsed`, `_macrometeoriteUses`, `_pocketProfessorLectures`, `_locketMonstersFought`, `_monstersMapped`, `_feelNostalgicUsed`, `_feelEnvyUsed`, `_latteCopyUsed`, `_olfactionsUsed`, `_swordOfSWordsKills` / `_swordOfSWordsMonsterChanged` |
| Wishes | `_monkeyPawWishesUsed` (5), `_genieWishesUsed` (3), `_bookOfFactsWishes` |
| Restores | `nunsVisits`, `_batWingsRestUsed`, `_cinchoRests` / `_cinchUsed`, `timesRested`, `_eternalCarBatteryUsed`, `_hotTubSoaks`, `_latteDrinkUsed`, `_mayamRests`, `_knuckleboneRests` |
| IoTM route pools | `_legendaryAcornsUsed`, `_archSpadeDigs`, `_baseballInnings`, `_cupOf13sJewels`/`Charges`, `_heartstone*`, `_clubEm*`, `_seadentWaveUsed` / `_seadentLightningUsed`, `_beretBuskingUses`, `_bczBloodThinnerCasts`, `_blessingShield*Received`, `_crimboPastDailySpecial`, `_miniKiwi*` |
| Other dailies | `_bastilleGames`, `_daycareGymScavenges`, `_daycareRecruits`, `_autumnatonQuests` + `autumnatonQuestTurn`, `_cargoPocketEmptied`, `_boomBoxSongsLeft`, `_vampyreCloakeFormUses`, `_augSkillsCast` / `_augTodayCast`, `_birdsSoughtToday`, `_favoriteBirdVisited`, `_deckCardsDrawn`, `_guzzlrDeliveries`, `_guzzlrGoldDeliveries`, `_guzzlrPlatinumDeliveries` |
| Daily zones | `_spacegateToday` / `_spacegateTurnsLeft`; `_frHoursLeft`, `_frMonstersKilled`; `_pirateRealmSailingTurns` / `_questPirateRealm`; `dailyDungeonDone` / `_lastDailyDungeonRoom`; `_gingerbreadCityTurns` / `_gingerbreadCityToday`; `_stenchAirportToday` and the other airport passes |

**No usable mafia tracking, so the script must own a date-stamped key:**
- Drip daily completion (only per-door and per-item flags exist).
- "FantasyRealm/PirateRealm done": already script-owned as `_fantasyRealmDone` and `_smm.PirateRealmDone`.
- The leaf-pile jump (`_leavesJumped` is not observed).
- Display Case deposits.
- Store stocking.
- Pricegun lookups.
- The spending budget.
- Shrunken head, Peridot, toy Cupid bow, Clan Photo Booth beyond `_photoBooth*` and `_perilLocations`: verify with `prefref` before writing adapters.
- Bounty state: verify the `*Bounty*` keys with `prefref bounty`.

## 6. Performance plan (targets for the new script)

1. **Dress once per block.** Maximize once per (location, objective) and save it with `outfit save`. Between turns, change a slot only for a planned action, such as equipping the latte mug when a banish is due. Target: under 0.3 equips per adventure (from 2.3). Saves about 600 requests and about 250 maximizer runs.
2. **Thin pre-adventure hook.** Drop `dressup` and `burnMP` from it (−1,200 calls). Keep the MP floor check and the counter checks.
3. **Autoattack the Oasis macro** (`set_auto_attack`). Saves up to one request per fight (about 300 a day).
4. **Guard macros** against missing items (−104 failed submissions).
5. **Store stocking:** `reprice_shop`, once a day, cached prices (−250 requests).
6. **Museum deposits:** wrap them in `batch_open()`/`batch_close()` (59 deposits today, mostly separate requests).
7. **Route discovery:** once a day, cached, with a cheap `smmIRStateSignature` re-check on later invocations.
8. **Pricegun:** a file cache keyed by item and date (14-day averages barely move within a day), and keep the `smm.spend.maxLookups=60` cap.
9. **Instrumentation:** `logprint` phase start and end with timestamps, `my_turncount()` and `my_meat()`, so round 2 can measure wall-clock time per phase. The session log currently has no times.

## Sources

- KoLmafia wiki:
  - [mall_price](https://wiki.kolmafia.us/index.php/Mall_price): one search per item per session, cached until a buy.
  - [historical_price](https://wiki.kolmafia.us/index.php/Historical_price): never hits the server.
  - [historical_age](https://wiki.kolmafia.us/index.php/Historical_age).
  - [adv1](https://wiki.kolmafia.us/index.php/Adv1): one encounter, follows preset choice chains.
  - [batch_open](https://wiki.kolmafia.us/index.php/Batch_open) and [batch_close](https://wiki.kolmafia.us/index.php/Batch_close).
- kolmafia.us forum:
  - [Improve ASH batching](https://kolmafia.us/threads/improve-ash-batching.14329/): same-command calls are merged at `batch_close`.
  - [Free rests on the floor vs the campaway site](https://www.kolmafia.us/threads/mafia-has-decided-to-use-free-rests-on-the-floor-instead-of-at-the-campaway-site.26850): `free rest` in `mpAutoRecoveryItems`, `restUsingCampAwayTent`.
  - [retrieve_price bug thread](https://kolmafia.us/goto/post?id=176151).
  - [valueOfAdventure and crafting](https://kolmafia.us/threads/mafia-internal-value-of-chef-bartender-usage.3330/).
- Garbo source (`garbage-collector`):
  - `packages/garbo/src/index.ts`: the `propertyManager.set` list (`mpAutoRecovery: -0.05`, `libramSkillsSoftcore: "none"`, `currentMood: "apathetic"`, `choiceAdventureScript: "garbo_choice.js"`), and the `valueOfAdventure <= 3500` refusal.
  - `config.ts`: `garbo_autoUserConfirm`, `garbo_rolloverBuffer`.
  - `restore.ts`: `restoreMp` to a fixed target.
  - `garbo-lib/src/value.ts`: `historicalAge ≤ 7 → 0.9 × historicalPrice`.
  - `outfit/barf.ts`: Meat Drop and Item Drop weights.
- Repository and KoLUtils:
  - `smmUtils.ash`: `burnMP` l.2450, `burnExtraMP` l.2519, `moodExecute` l.2206, `preAdventureChecks` l.10233, daycare l.10591–10615.
  - `smmUnrestricted.ash`: `dailyGrind` l.6612, `secondBreakfast` l.2993, `dailyGrindConfirm` l.716.
  - `smmIotmRoute.ash`: l.400–520 (settings save/restore, lock, replanning).
  - `smmIotmRouteMore.ash`: l.204–212 (leaf jump).
  - `smmConsult.ash`: l.1504 (blue rocket).
  - `smmRecovery.ash`.
- Logs:
  - `Tquilla_20261121.txt`
  - `Tquilla_20261123.txt`
  - `Nov 19 session log` (11-19)
  - Prefs: `tquilla_prefs.txt`
