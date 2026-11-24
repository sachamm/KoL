Tquilla aftercore daily-script council plan

Date: 2026-11-23 (America/Vancouver)
Status: Research and design proposal. No script implementation, game action, purchase, or GitHub modification was performed.
Purpose: ChatGPT council contribution for reconciliation with the parallel Claude council and eventual incorporation into the KoL repository.

Executive decision

Build a single daily governor over the existing SMM libraries, with Museum milestones as the objective and Meat as their funding mechanism. Keep the existing, account-specific Oasis implementation as the initial residual farming engine after making it bounded. Recover missed free opportunities, reserve daily-limited Museum work, and route every purchase, recovery, consumable, familiar, and combat resource through the same admission rules.

Do not launch an unmodified garbo call as the core under the present hard rules. Current garbo has useful tactics and a sophisticated task model, but its options do not enforce Sacha's aggregate spending rule or protected Museum quantities. Prefer a small, audited JavaScript bridge or upstream integration over maintaining an entire ASH port.

The first implementation milestone should be a complete read-only plan with credible accounting, followed by narrow, qualified execution. The migration promise is that a working daily capability is not retired until its replacement and recovery path are qualified. It cannot guarantee that KoL or the network will never fail.

Evidence and scope

Read the goals first, then all seven docs and the relevant script/data files in the supplied repositories. Research snapshots:

Source	Audited revision
sachamm/KoL	afbfc6236c7fa25486eeb277b7a2ab4286387035
sachamm/KoLUtils	b0546d87003a388dbc90f5999475e8282a097049
loathers/garbage-collector main	eaa1455551c8a5ab114fa6942b2e3c9eaa186978
garbo release branch	6bc8b68f379d32ea00caff57f0f0a69175d7d836
KoLmafia r29462	e20f5d6c1508be750b94a2c20188cf7efaa4290d
loathers/TourGuide	e8d4fd2ba8c26814b91cf3fbed71a04288708bd4
loathers/ChIT	fa46ad81dce8e14d39e79d50f81adcce949f99c2
loathers/pricegun	489e352e96fd87149ee9e65095afa036cbd83b4e

The old LASS ChIT URL redirects to loathers/ChIT. The brief's balances, prices, daily yields, missed resources, and November 21 failure are user-supplied ledger evidence, not a refreshed live account snapshot. All benefit estimates below are conditional arithmetic, not measured forecasts.

KoLmafia wiki, original loathers analyses, public forum discussion, and repository source were accessible. KoL wiki requests returned HTTP 403. No private Discord archive was accessed; public published analyses and source code supply the supporting mechanics instead.

Primary project authority: 
aftercore goals.

1. The five specialist positions and the debate
1.1 Efficiency engineer — lead

Recommendation: Optimize finite Museum gaps using marginal opportunity cost. Separate realized cash, expected realizable output, retained-copy acquisition savings, and noncash Museum utility. A daily charge is not automatically worth using; a missing unbuyable reward is not automatically worth an unlimited number of turns.

Use one value of a marginal paid adventure across diet, buffs, resource allocation and farming. Start planning with the supplied 5,000 Meat policy value, then calibrate it against the best feasible remaining use of Tquilla's turns.

Disagreement: The KoL specialist initially gives unbuyables first claim; the engineer requires a funded turn/loss ceiling so one difficult collection cannot absorb the day indefinitely. The resolution is a bounded unbuyable portfolio, with expiring opportunities ranked inside it and residual resources assigned to earning.

1.2 Leaderboard-level KoL specialist

Recommendation: Schedule scarce resource combinations, rather than simply adding new dailies. Prioritize missing unbuyables, complete active short-lived encounter chains, reuse banish sources between finished zones, and compare farming versus buying for every tradeable product.

Treat Snojo/CyberRealm as restricted encounter carriers. Audit the genuine 2025 omissions—Peridot, Monodent, shrunken head, Yeti, Möbius, Cupid, Leprecondo—before crediting existing 2026 output generators as new income.

Disagreement: Reverse-release-order implementation is not an economic priority order. The resolution is to retain the release registry for coverage, but implement missing capabilities by expected payoff, confidence and shared-resource importance.

1.3 KoLmafia specialist

Recommendation: Enforce MP, spending, input and turn reservations before every mutating request, including nested recovery, moods, choices and acquisition. Canonical game counters establish what happened; an intent journal establishes what was authorized and accounted for.

The MP failure is not fixed by a different threshold: existing burnMP executes the mood before honoring its target and can execute it again while restoring the previous mood. No-prompt operation also requires auditing confirmations beyond the six dailyGrind presets.

Disagreement: A local lock and an after-the-fact spending report are insufficient for Windows/Mac operation or third-party execution. The resolution is one active runner, an explicit same-day journal handoff, and pre-action admission.

1.4 Garbo specialist

Recommendation: Reuse garbo's contextual free-fight, copy-chain, familiar and equipment ideas. Benchmark its supported farms against Tquilla's Oasis after common daily work, using the same accounting.

Disagreement: Stock garbo cannot currently honor the combined contract through a few flags. It enables acquisition, clears hooks, uses its own restoration target, and has no universal Museum inventory reserve. Conversely, permanently reimplementing all of garbo in ASH would create a large maintenance burden.

Resolution: An SMM governor with bounded Oasis first; pure garbo calculations and narrowly audited tactics next; an audited JS bridge/upstream hooks as the preferred long-term option.

1.5 ASH specialist

Recommendation: Reuse SmmRPAction, SmmRPPlan, SmmRPLease, SmmIRWork, the conversion graph, Museum cache and existing worker checks. Add a scheduler and low-level budget module, not another optimizer.

Disagreement: Calling the whole dailyGrind function inside a lease is not a bounded fallback. Its inner loops and acquisition paths remain uncontrolled. ASH persistence also needs integrity checks rather than trusting a successful file_to_map boolean.

Resolution: Exclusive ownership of each capability, atomic adapters, validated journal generations, pure planners, and rollout one capability at a time.

2. Unified objective, value and accounting
2.1 What counts as success

The ultimate target is #1 for every displayable item; top ten is an acceptable milestone. Count actual Display Case copies, not inventory, shop stock, learned familiars, tattoos, buffs, or hypothetical purchases.

For each item, keep:

Actual case quantity.
Eligible owned quantity after operational reserves.
Latest external leaderboard snapshot, timestamp and tie information.
Top-ten entry target, sole-first target, and optional defensive buffer.
Remaining physical acquisition gap and currently funded gap.
Acquisition modes: mall/NPC, buyable conversion, unbuyable drop/currency/craft, one-off, inaccessible or unknown.
Expected attempts, turns, shared resources and days to the next useful milestone.

Exclude Tquilla from comparison thresholds so an existing lead never raises its own target. One-per-account items may only permit tied first; do not manufacture an impossible sole-first requirement.

The current repository has a specific inconsistency: smmTargets accepts a tie at the tenth-largest other collection, whereas smmMuseumPolicy adds one. Normalize the rule after verifying Museum/wiki visibility at ties. Keep a strict-beat target available as an explicit reliability choice, rather than silently presenting both as the same threshold.

The default buffer of eleven copies must also remain visible. Recommend preserving already deposited copies, while letting future acquisition distinguish the minimum rank target from optional defensive extras. Buying eleven extra expensive copies should compete with other milestones.

Sources: 
collection objective, 
target register, 
Museum policy implementation.

2.2 Four separate values
Quantity	Purpose	May unlock cash spending?
Realized resource cash, net of agreed operating expenses	Enforce the daily spending cap	Yes, under the agreed accounting policy
Conservative realizable surplus value	Compare production, sale and conversion	No, until sold
Avoided purchase cost of a needed tradeable copy	Compare direct collection with earn-and-buy	No
Museum utility of a missing unbuyable/milestone	Allocate an explicit collection-loss budget	No

An output copy is retained or sold, never both. A batch crosses value boundaries at top ten, first place, buffer completion, and market depth. A needed input consumed in a recipe, potion or meal carries its replacement/opportunity cost. Unknown unbuyable inputs remain protected rather than receiving a fabricated zero price.

For one task or dependent bundle:

Economic delta = direct Meat + useful retained output + realizable surplus + net adventure change × marginal turn value − cash costs − consumed input value − displaced gear/familiar/resource value − future liabilities.

Then add separately disclosed, bounded Museum utility for selection. Do not book utility as income.

A free fight is worth its actual compatible outputs and charging opportunity. It is not automatically worth one paid adventure if no paid fight was displaced. A drop-destroying kill must subtract destroyed rewards. Sword loot replaces native item loot; it does not create a second native loot table or additional native Meat.

Inventory transfers must not create profit. For the economic ledger, reconcile signed item changes across inventory, closet, storage, equipment, shop and case; keep revaluation from price changes separate from production. The current dailyGrind ledger ignores negative item deltas and can therefore overstate profit when inputs are consumed.

Sources: 
resource model, 
smmValue, 
legacy ledger.

2.3 Adventure, MP, organ and control prices

Set one canonical adventure value, initially 5,000 for comparison with the supplied ledger, and derive both smm.TurnValue and valueOfAdventure from it. This is a provisional policy input, not proof that every Tquilla adventure earns 5,000.

Estimate the marginal value from feasible residual farming after operating costs, volume limits, location setup, equipment/familiar displacement and reserved Museum work. Use matched batches and report the uncertainty. A free daily spike should not inflate the recurring tail-turn estimate.

Select the earning core by its raw net return per paid turn; do not reject the best remaining positive farm merely because subtracting its own shadow price yields zero. Use the shadow price to compare other uses of that turn and purchases of additional turns.

Assign shadow prices to MP, familiar XP, organ space, free crafting, banish sources and copies from their best foregone use. These change during the day. A banish slot no longer needed by a finished zone is released; a buff near the end of its useful horizon is worth less.

Preserve approximately 2,000 MP initially for breakfast prerequisites and necessary casts, with the true reserve calculated from remaining scheduled casts plus combat/recovery margin. After those tasks finish, reduce the reserve. Do not maintain 2,000 forever merely because it was needed at breakfast.

At the supplied numbers, 230 additional adventures costing at most 1,650 each have approximately 770,500 Meat of net earning potential at 5,000/turn. That is existing capacity to preserve, not automatically a new gain. Do not generate adventures that will expire unused or displace a more valuable organ commitment.

2.4 Spending rules and the ambiguity to resolve

All buyers must use the same admission service: fullAcquire, buffs, recovery, Asdon fuel, diet, coinmaster/crafting Meat inputs, the route, DC purchases and future third-party adapters.

Enforce:

Positive marginal-return purchases first, after all relevant costs.
Remaining collection purchases by largest verified discount, with milestone progress as a tie-break unless Sacha explicitly chooses top-ten-first as an overriding portfolio rule.
For market purchases, never exceed a supported recent average completed-sale price.
Discount purchases require price at most 80% of that average.
Reserve worst-case quantity × allowed unit price before buying; settle actual quantities and actual Meat after partial fills.
Unknown/stale/manipulated-looking average evidence does not permit a fallback to an unrestricted current listing.
No forecast loot, unrealized stock, or Museum utility creates spending capacity.

Pricegun currently uses a time-weighted sale estimate with three-day half-life and square-root volume weighting. Keep the existing minimum-five-units screen as a starting point, but record units, distinct sales, age and concentration: five units are not necessarily five independent observations. Mafia historical_price is a cached quote, not historical average sales. Its mall quote is not a guarantee of cheap bulk depth.

A one-copy purchase probe is a real transaction. It needs admission, appears in the cash ledger, and cannot occur in plan mode. Rank known offers by discount, then reprice/re-rank when the current price tier is exhausted. Do not promise globally optimal ordering across undiscovered offers.

There are two unresolved accounting questions:

Does the half-of-net cap include operating purchases, or only spending after operating profit?
Do sales of old stock increase today's eligible net, or only liquidity?

Until resolved, show both ledgers and use the stricter interpretation for any future execution. One precise conservative formulation is:

G = eligible realized receipts.
C = operating cash expenses.
D = Museum/investment cash purchases.
N = max(0, G − C).
Require C + D ≤ 0.5 × N, reserving against the proposed post-purchase values and crediting no future revenue.

Example: G = 1,000,000 and C = 100,000 permits D ≤ 350,000. The less restrictive, operating-cost-excluded interpretation would permit D ≤ 450,000. This difference must be explicit, not hidden in a helper.

Before discretionary purchasing, encumber both the cash and the effect on the spending ceiling of all remaining approved operating costs. Under the conservative formula, one Meat of reserved operating expense consumes 1.5 Meat of current spending headroom; one Meat of collection purchasing consumes one. Do not spend the allowance needed to finish already-approved work.

With zero accrued eligible receipts, the strict policy cannot fund cash-consuming startup merely because 141.5M Meat is available. Claim no-cash resources first; a working-capital exception requires a stated policy. Classify old-stock liquidation and external gifts/transfers separately until their treatment is settled. The current documented ledger counts overnight shop receipts and does not distinguish gifts/manual transfers, which is precisely why reconciliation is needed.

The stated nine #1 spots at about 2.5M imply at least 5M of eligible net across the relevant days if no other spending uses the allowance. Verify those ranks, quantities and prices before treating them as an available shopping list.

Sources: 
daily spending policy, 
smmSpend implementation, 
Pricegun method, Pricegun API discussion, Mafia mall-price documentation.

3. Phases of the day

Phases express dependencies and deadlines, not an inflexible sequence. A live short-duration chain can preempt the next phase. A charging reward may make it worthwhile to interleave a drink or buff with free fights.

The whole-day plan may contain conditional commitments backed by forecast diet or charging rewards, but executable leases reserve only observed capacity. Convert a conditional commitment into an executable reservation only after its prerequisites and actual gains are confirmed.

Phase	Work	Exit invariant
0. Recover and preflight	Confirm Tquilla, unrestricted aftercore, revision/source hashes, sobriety, no unknown combat/choice, current epoch, journal and one active runner. Capture settings, hooks and gear.	State and ledger are trustworthy; no ambiguous action is blindly repeated.
1. Plan the whole day	Snapshot inventory, ranks, organs, buffs, currencies, workshed/garden, actual resources and prices. Pick funded Museum bundles and reserve their full completion requirements. Select provisional farm/copy/diet plans.	Every committed scarce use has one owner; no future capacity is counted as already available.
2. Collect safe early value	Claim admitted zero-turn outputs; perform MP-intensive prerequisite summons; choose garden/workshed policy before irreversible collection/swap. Collect breakfast, clovers, noodles, batteries and tea only through their assigned owners.	Prerequisite casts confirmed or explicitly deferred; authorized MP reservations consumed/released, with enough left for remaining commitments and recovery; no duplicate breakfast/route claims.
3. Configure and use free carriers	Set profitable persistent familiar/equipment/zombie plans; allocate Snojo, Cyber and existing free fights between native loot, copies, Sword, Maiden, Yeti/mimic XP and equipment drops. Interleave needed charging rewards.	Each carrier and its rewards counted once; actual paid turns remain zero in free-only mode.
4. Commit the organ plan	Execute the sole diet plan under cash/input gates. Reserve Drip fullness/liver if selected, coordinate Yeti next-drink boosts, sweat/cleaners, mojo filters, spleen consumers and nightcap.	No protected collectible consumed; all gained adventures have a useful planned destination; sober work remains possible.
5. Complete chosen limited targets	Run only the selected ghost/Spacegate/FantasyRealm/PirateRealm/Dungeon/Drip/Gingerbread bundles, with effect deadlines and source-specific control. Beer lenses compete as an economic candidate.	Enough resources remain to finish committed bundles; each result is observed, not inferred from CLI success.
6. Farm residual resources	Run bounded Oasis batches initially; re-evaluate beatles/blur and qualified alternatives. Interleave copied encounters, wanderers, digs, cooldowns and profitable replenishment.	Every next fight passes turn/cash/MP/loot checks; no entire-adventure drain can starve another owner.
7. Realize and purchase	At useful checkpoints, list verified surplus in sensible lots; reconcile actual sales; buy profitable inputs before discounted collection stock; compare conversion before deposit.	Cash cap and price ceiling hold cumulatively across reruns; no unsold item is booked as cash.
8. Salvage and close	Audit unused expiring opportunities against TourGuide/ChIT coverage; run only qualified independent positive/budgeted tasks; finish sober work, then selected nightcap/rollover setup; close report and handoff.	Every unused daily resource has a reason; settings restored; journal closed; persistent stock retained when saving is better.
Invariants at every phase
One identity/rollover epoch and one executor per capability.
No cash, turn, MP, organ, item or special-resource overspend; uncertain capacity is unavailable.
Checks occur before each individual mutation, not merely at the beginning of a long grind.
Required Display Case stock is protected, with no automatic removal from the case.
No unpriced unbuyable consumption and no duplicate retained/sale valuation.
No timed yes/no prompt as a substitute for policy.
Optional task failure blocks that task and its dependents; independent safe work continues.
Unknown combat/choice, ambiguous purchase, journal corruption or violated accounting stops further mutations until reconciliation.
A failed request can still have consumed resources; actual changes are always charged.
Replanning does not reset daily limits, reservations already consumed or recorded spending.
4. Concrete resource and route policy
4.1 MP and early claims

Run valuable summons and necessary utility casts before surplus-MP conversion. Schedule bat-wing recovery, available free rests, known MP-producing effects and other owned restoration against both their value and foregone alternative use. Paid restoration needs the same spending admission as everything else.

Replace long mood extensions with a horizon: enough useful buff duration for the next planned batch plus a small safety margin. Carryover duration can have value, so do not label every unused turn of a buff as waste. A mood restore must not silently cast additional buffs.

Audit normal breakfast, secondBreakfast, smmIRBreakfast and dailyDeedsAdv as overlapping capability owners. The supplied 350k breakfast, 97k clovers, 61.5k legendary noodles, 56.6k AAA batteries and 39.8k Time-Spinner tea are protected baseline lines; they must not all be counted again as new improvements.

Time-Spinner minutes must compare tea, rematches and other legal uses. Clover use must beat sale/collection value. Legendary noodles compete among direct deposit, sale, meals and diet; free cooking is limited and owned ingredients still cost something.

Source: 
MP and acquisition helpers.

4.2 Banishing and encounter control

Represent each source with remaining uses, active queue capacity, duration/reset condition, monster/phylum scope, turn cost, equipment/skill requirements, drop preservation and next owner.

The reported 13-versus-about-17 shortage is a planning symptom, not a sufficient resource model. The rough 4/8/5 reservations also should not be hard-coded as guaranteed requirements.

Monodent: _seadentLightningUsed allows eleven casts, but BanishManager defines one active Sea *dent banish. The kill takes a turn and retains drops. Reuse the slot only after its previous zone no longer needs it. Do not lightning the desired farm target unless ending that target's route.
Peridot of Peril: once per zone per day can select a native monster, conditional on encounter eligibility. It can save search/control setup, but does not itself make the combat free.
Existing sources: explicitly reserve Reflex Hammer, Feel Hatred, KGB dart, latte, Spring-Loaded Front Bumper, other valid skills and admitted consumables. A Turtle Tamer must not receive Seal Clubber-only Batter Up! capacity.
Anchor bomb: a 30-turn, one-slot banisher; repeated bombs do not create independent simultaneous banishes.
Preserve short-lived control for short bundles, reuse sources between completed bundles, and establish the long residual farm last.
Buy a control item only when the bundle's incremental return or bounded Museum utility exceeds its full cost. No assumption that “banishes are scarce” authorizes every purchase.

Sources: 
r29462 BanishManager, Monodent original analysis, Peridot original analysis.

4.3 Free fights, free kills, copies and replacements

The brief's approximately 45 free fights, seven-plus kills and forty-plus copies/replacements are not three independent piles of free adventures. Build compatible encounter bundles.

Snojo: snojoAvailable and 10 − _snojoFreeFights. Choose snojoSetting using ice rice, iced plum wine, ancient medicinal herbs and relevant collection/training milestones. Stop before the first unadmitted paid fight.
CyberRealm: the initial garbo-derived adapter requires accessible Cyberzone, Torso Awareness, OVERCLOCK(10), and the zero-trust tanktop owned and equipped; read _cyberFreeFights plus the three _cyberZoneNTurns counters. Constructs restrict ordinary skills. The halfway noncombat historically consumes an OVERCLOCK allowance; inspect counter/turn deltas and deliberately choose zones rather than promising ten interchangeable fights.
Native free encounters, free kills, locket seeds and copied monsters remain distinct. Locket supplies an encounter, normally paid; it is not intrinsically a free fight.
Reserve camera uses (_backUpUses), Macrometeorite uses (_macrometeoriteUses), mimic eggs/XP (_mimicEggsObtained), digitize/wanderer timing, nostalgia, latte, Time-Spinner and other owned sources independently. A replacement requires a compatible host; do not mint the host in the model.
Compare each target's conditional drop table, actual +item outfit, seed cost, copy legality, free/paid outcome and market saturation. Current garbo considers high-value wishable/free/copyable monsters; “always copy Embezzlers” is obsolete as a universal recommendation.
Deploy drop-preserving free kills where their saved turn is worth more than their alternative use; drop-destroying kills subtract the lost native/target loot.
Sword of S Words may replace item loot on a carrier. Charge its familiar slot and lost native items. Use its target-change and loot pools from the existing registry; do not simultaneously allocate that same familiar slot to Yeti or Mimic.

Sources: 
TourGuide, CyberRealm spading, CyberRealm overview, 
garbo free fights.

4.4 The nine legacy grinds
Grind	Proposed selection and control
Oasis	Residual earning candidate. Compare swarm of scarab beatles versus blur with volume-aware mojo-filter/hammer/drum-machine values, current buffs and control costs. One admitted fight at a time, with small batches for reporting.
beerLens	_beerLensDrops < 3 is a limit, not a profitability proof. Tradeable beer lenses compete against buying; pay the opportunity cost of approximately four legacy banish allocations. Validate copy/selection and conditional drop compatibility.
ghostCostume	Use a finite missing li'l ghost costume target. If Invisible Ties/Invisibly Ripped is active, protect the linked Laundry Room → Ninja Snowmen → Storage Room chain from unrelated turns. Reserve a completion margin rather than treating 5–11 turns as guaranteed.
Spacegate	Choose sample/research targets by useful expected progress and route cost, using _spacegateTurnsLeft, observed coordinates and hazards. A larger raw deficit is not automatically the better sample-kit choice.
FantasyRealm	Choose one shared daily route among verified rewards; existing planning constant is thirty adventures. Preserve _smm.frTarget on resume. Remove the unconditional scepter fallback when every target is complete/unknown/ineligible.
PirateRealm	Select supported reward/fun-point alternatives from actual gaps instead of always Red Roger's reliquary. Plan supply branches and safe continuation before entry; current short-run helper expects roughly forty adventures available.
Daily Dungeon	Compare fat loot token and conversions against the shortest legal route, using dailyDungeonDone and _lastDailyDungeonRoom, owned shortcuts and actual costs.
Drip	Choose the target and current juice's opportunity cost. drippyJuice persists; _drippyNuggetUsed and _drippyWineUsed are daily generation limits. Reserve five fullness only if selecting a drippy nugget, five liver only if selecting a glass of drippy wine, or neither when existing juice covers the route. Evaluate each source independently against displaced diet and actual turns.
Gingerbread	Select item/sprinkle/Museum objectives from real city counters. A winnable local sprinkles leaderboard is not automatically a Museum objective. Replace unattended “finish manually” as an implicit strategy with a supported plan or explicit skip.

Bounties sit beside this portfolio, with filthy lucre valued through its useful conversions/collection gap. They do not receive five banishes merely because the old function runs early.

Sources: 
dailyGrind, 
FantasyRealm, 
PirateRealm, 
installed-version defaults.

4.5 Surpluses and worksheds

Mojo filters: maintain an operational reserve, but use no more than the actual daily allowance (currentMojoFilters, three/day) and only when restored spleen's best net use beats the filter's sale/collection value. The stockpile is not an unlimited spleen engine.

TakerSpace: inspect all six balances. Daily supply while installed is three each of spice, rum, anchor and mast, plus one silk and one gold; supplies persist. One anchor bomb costs one rum, three anchors, one mast and one gold. Therefore 1,826 anchors alone do not imply 608 usable bombs. Compare scarce gold with a golden pet rock (seven gold), sleeping profane parrot (15 spice, three rum, two silk, one gold), tankard of spiced Goldschlepper (two rum, one gold), and collection needs. The existing route already crafts several outputs; the new opportunity is better tactical allocation and workshed planning.

Workshed: use the actual installed item and _workshedItemUsed. Collect/service the installed workshed before a justified switch. Do not assume TakerSpace → Asdon → train in one day. Compare across multiple days; value retained Driving Observantly duration, actual fuel and future train/cabinet/Taker returns. Replace the unconditional 600-turn fuel target with a profitable horizon, not a blind 400-turn target.

Approximately 700M of stock: classify operational reserve, Museum reserve, conversion inputs and true surplus. Use smmValue's conversion graph to compare MSG/dry noodles/savory dry noodles, fish-scale products and other recipes. Maxwell's Silver Hammers, happiness and other stock only sell after reserves. Limit lots by observed demand; an old asking-price valuation is not liquid cash. Historical liquidation is a balance-sheet action, separately reported from recurring daily production.

Source: TakerSpace analysis and recipes, 
existing TakerSpace workers.

4.6 Genuine recent-item additions
Capability	Initial adapter and key constraint
Shrunken head	Prefer a low-risk passive item/Meat zombie from an already selected encounter. Read shrunkenHeadZombieMonster, shrunkenHeadZombieHP and shrunkenHeadZombieAbilities; later evaluate deliberate loot-on-death chains. Zombie death drops are not simply a second full normal drop roll.
Monodent wave	Compare +30 percentage points of item/Meat modifiers with lost gear and underwater/Fishy requirements; verify actual turn cost. Do not model it as +30% to total income.
Cooler Yeti	Coordinate 225 XP for 100 turns of Looking Cool and 400 XP for next-booze turn doubling with the diet. Gate the latter with _coolerYetiAdventures and credit only the verified adventure increment, not an assumed doubling of every diet bonus. Charge displaced familiar output/XP and distinguish today from tomorrow's nightcap value.
Möbius ring	Integrate priming and stochastic time-cop opportunities into normal farming; up to eleven free cops is a limit, not eleven guaranteed immediate encounters. Charge the accessory slot and priming overhead.
toy Cupid's bow	Evaluate +2 familiar XP, equipment after five fights, and the missed-drop reroll. Several missed drops compete for the reroll; do not independently double every probability.
Leprecondo	Schedule up to three rearrangements against the known needs cycle and remaining horizon. Phosphor traces/pre-workout powder consume spleen, so their copying/control value must exceed displaced diet.
Existing 2026 collection	Audit remaining combat powers of acorndion, Sword, Heartstone, club, Cup and other owned items. The current source already handles many product generators; count only added or improved capabilities.
Other coverage	Check Eternity Codpiece, Peace Turkey, Clan Photo Booth and older owned sources against TourGuide/ChIT and the capability registry. Ownership and unlocked effects must be demonstrated.

Sources: head, Yeti, Möbius, Cupid, Leprecondo, 
current executor coverage.

5. Top fifteen changes by provisional daily economic opportunity

This is a planning ranking, not a measured forecast. The working cases make the ordering inspectable; they are assumptions to replace with shadow-run data. “High” confidence means the mechanism is well supported, not that the illustrative revenue is guaranteed. Zero remains possible where the current script already makes the optimal choice. Do not sum the rows: the same saved turn, free carrier or avoided failure may appear in more than one scenario.

Rank	Change	Working Meat-equivalent/day case and plausible condition	Confidence
1	MP reserve, restartability and failure isolation	Expected protection = failure probability × stranded net value. An illustrative 10% chance of losing 1.5M implies 150k/day; one prevented failed day could preserve roughly 350k–2M. Failure frequency is not measured.	High mechanism; low forecast
2	Better copy/replacement targets and chains	40 eligible uses × 2.5k incremental value = 100k/day; plausible research band 0–600k. Charge seeds, paid hosts, native loot displacement and demand saturation.	Low magnitude
3	One turn portfolio across route and legacy grinds	50 turns moved to an option 2k better = 100k/day; scenario band 0–300k. Intentional funded Museum turns are not “waste.”	High scheduling defect; low magnitude
4	Benchmark and select the best residual farm	250 turns × 300 Meat improvement = 75k/day; 0–300k conditional band. This is eventual qualified production upside. Record signed benchmark deltas, including negative experiments and their discovery cost; a losing alternative is rejected.	Low pending matched batches
5	Discount-aware Museum allocation	At 250k actually available and a 20% discount, acquisition savings versus the reference average are 62.5k. This is noncash collection purchasing power, not earned Meat; available offers may make the gain zero.	High arithmetic; low availability
6	Yeti/diet sequencing and organ coordination	Illustrative ten extra usable adventures × 5k minus 10k charging opportunity cost = 40k. Research band 0–100k after costs. Separately, missing the entire existing 230-adventure diet strands about 770.5k of potential; do not add that as routine new income.	Medium mechanics; low yield
7	Missing Snojo/Cyber automation	Roughly twenty unused allowances × 2k carrier value = about 40k/day; working band 0–100k after restrictions. Cyber may yield fewer useful combats.	High missing coverage; medium-low value
8	Source-specific banish reuse and Peridot selection	Eight saved turns × 5k minus 5k control cost = 35k; working band 0–75k. Overlaps turn allocation.	Medium
9	Useful passive shrunken-head zombie	Example 300 turns × 40% extra Meat × 100 base Meat = 12k before useful item drops; illustrative combined case 25k, band 0–100k after displacement.	Medium mechanics; low value
10	Native-loot-aware free-kill allocation	Four currently wasted/reassigned saved turns × 5k minus 5k displaced loot = 15k; upper illustration seven × 5k = 35k before losses. Existing efficient kills add zero.	Medium
11	Möbius integration during otherwise useful turns	Seven realized free carriers × 2k minus 2k equipment/setup cost = 12k; 0–55k gross opportunity band before costs. Eleven encounters are not promised.	Medium-low
12	Buff and MP spending matched to the horizon	Illustrative 10k MP no longer bought/wasted at 1 Meat/MP = 10k; 0–30k planning band. Value carryover buffs and separate this from failure protection.	High defect; low cash savings
13	Mojo-filter reservation/use	3 × max(0, best net restored-spleen value − filter opportunity cost); illustrative 9k, band 0–30k if presently underused.	High formula; price-dependent
14	Currency/conversion and workshed allocation	Illustrative 5k/day from better admitted conversion/fuel choices; use 0–30k only as a research budget range until all balances/recipes and future workshed returns are priced. Historical Taker stock liquidation excluded.	Low
15	Cupid equipment, Leprecondo and remaining capability gaps	No defensible combined market forecast yet; use a 0–25k/day discovery band, with a 5k placeholder for prioritization only. Museum-only equipment value is separately funded and XP overlaps other rows.	Low

The engineering implementation order is different: accounting, MP, ownership and journal safety come before enabling high-upside speculative target chains.

For the stockpile, publish a separate one-time liquidation/conversion schedule. Do not attach a recurring 700M/day or arbitrary amortized daily benefit to it. Likewise, the nine suggested #1 purchases are a finite milestone package, not recurring income.

6. Garbo decision and integration contract
6.1 What is verified

The audited main declares minimum KoLmafia r29401, so r29462 passes that declared check. This is not an end-to-end compatibility test.

Control	Verified meaning and limit
nodiet	Skips normal diet/Pantsgiving consumption, but the run still invokes nonOrganAdventures; restoration can eat magical sausages.
nobarf	Does setup, copied-target work and daily flags before ordinary farming. Not a free-only or no-spend mode.
turns=N / numeric N	Sets the ordinary farming stop condition; initial stages can spend before that loop.
Negative turn argument	Preserves a number of remaining adventures through the ordinary farming condition, not all nested actions.
0 turns	Default/unbounded behavior in the inspected conditional; do not use as “execute zero turns.”
simdiet	Does not consume the computed diet, but preceding setup can visit pages/change familiar or equipment; not a pure dry run.
target / garbo_copyTarget	One copy target, not per-resource leases.
garbo-price	Static item valuation override, not quantity-aware Museum protection or a purchase ceiling.
autoUserConfirm	Accepts coded defaults; does not encode Sacha's policy.

No general reserve, freeonly or nonightcap flag was found in the audited options. Do not invent one.

Current acquisition has per-item price caps and a default 3M per-call aggregate sanity check. It is not a daily cap. Startup enables mall/NPC/coinmaster acquisition and clears several adventure hooks. Its normal MP target is 200, with libram burning toward 400, so the required early 2,000-MP reserve is not inherited.

Current farming strategies include Barf Mountain, Coral Corral, Marinara Trench and Copperhead Club, not Oasis. Several alternatives compete for Fishy and two to four banishes. Current default copy-target logic also differs from a blanket Embezzler strategy.

6.2 Required contract for any garbo adapter
Central admission before every purchase, recovery, crafting input, diet item, free/paid encounter and scarce-resource use.
Quantity-aware protected inventory and case policy.
Per-action turn ceiling, including setup and copied encounters.
Shared MP/organ/counter/banish reservations and resource-owner identity.
Actual receipts and bounded failure handling.
Settings/hook restoration, supported pending-choice recovery and deterministic no-prompt behavior.
Exact pinned versions and a regression gate after upstream changes.

Use selected pure valuation/target enumeration functions first. Add narrow actions only where their complete side-effect surface is audited. Never rely on hiding stock in the closet or setting autoBuyPriceLimit as a substitute for this contract.

Sources: 
config, 
startup, 
acquisition, 
restoration, 
farm strategies.

7. Architecture, state and commands
7.1 Proposed module boundaries

All new filenames and CLI verbs below are proposals, not implemented features.

Module	Responsibility
KoLUtils/scripts/smmBudget.ash — new	Native-only low-level cash admission, reservations and spend receipts. No dependency on high-level Museum/route policy.
smmResourcePlanner.ash — existing	Resource snapshots, bounded allocation, leases and owner reservations; migrate epoch and add missing source/slot constraints.
smmValue.ash — existing	Conversion graph and distinct acquisition/liquidation values; add evidence, quantity and liquidity metadata.
smmUtils.ash — existing	Acquisition, buffs, recovery and consumption use low-level admission; eliminate reachable prompt/ungated fallback paths.
smmMuseumPolicy.ash / smmTargets.ash / dc.ash	One rank/tie/buffer policy, protected stock, targets and observed deposits.
smmSpend.ash — existing	High-level ROI/discount portfolio using smmBudget; never itself the low-level dependency of smmUtils.
smmDailyState.ash — new	Snapshot, versioned intent/receipt journal, restoration and cross-machine handoff.
smmDailyTasks.ash — new	Capability registry and static dispatch over existing atomic workers.
smmDaily.ash — new	Phases, deadlines, horizons, ownership, admission, replan and qualified fallback.
aftercore.ash — new	Thin CLI: plan, refresh-plan, run, resume, status, salvage, report.
diet.js — existing	Sole organ optimizer under shared reservations and budget admission.
smmGarboBridge.js — later	Audited pure calculations and individual actions; disabled until contract compliance.

The separation avoids a circular dependency: smmSpend already imports smmUtils, so fullAcquire must not call back into that high-level module.

The existing solver caps a block at 64 eligible candidates and defaults to 20,000 search nodes. Use small coherent horizons and bundles instead of one enormous day-long solve. Setup costs, sequential transitions and newly created capacity require bundles or replanning. Report “feasible, optimality not proved” when the search cuts off.

7.2 Task contract
Field/function	Design requirement
Identity	Stable capability/task ID, worker version, explicit target IDs and sole executor owner.
ready(snapshot)	Pure readiness predicate with reason; no acquisition, recovery, equipping or choice entry.
completed(snapshot)	Canonical counter/outcome evidence; distinguish done, exhausted, deferred, blocked and unknown.
value(snapshot)	Economic delta, separate Museum utility, uncertainty and rationale.
costs	Worst-case cash, MP, turns, organs, ingredients, carriers, copies, kills, banish source/lifetime and future commitments.
Dependencies	Required tasks, effects, equipment, sobriety, deadline and safe pause boundary.
do(context)	One admitted mutation or a provably bounded group; nested helpers share the same contract.
observe(before, after)	Confirmed success, partial success, no-op, failed or ambiguous, with actual resource deltas.
Limits/recovery	Attempts, no-progress guard, maximum cost, restoration, and which independent tasks can continue.

Use a typed record plus static dispatch on kind, matching SmmIRWork. Serialized task data must not become arbitrary CLI commands.

Execution protocol: snapshot → candidates → allocation/reservation → persisted intent → execute → observe → receipt → replan.

7.3 Restart, persistence and two machines

Use player ID + ascension + next-rollover epoch as the shared day identity. rollover() supplies that epoch. Current smmRPEpoch uses local today_to_string plus ascensions; migrate it together with the cash ledger so the two systems cannot disagree around midnight. Changing the epoch format must import a verified same-day legacy ledger or enter report-only reconciliation; it must never initialize today's spending to zero.

Persist intent before mutation. After a timeout, inspect current combat/choice, inventory, counters and relevant logs before retrying. Exactly-once remote execution cannot be guaranteed; the goal is to prevent blind duplicate execution.

Keep versioned journal generations with schema, required fields, player, epoch, sequence and integrity check. map_to_file overwrites; file_to_map can report success for missing or partially parseable data. Verify the new intent is readable before executing, retain the previous valid generation, and never interpret an empty/corrupt map as a new zero-spending day.

Use one active runner across Mac and Windows. A local lock does not provide a distributed lock. An explicit handoff includes the exact journal and refresh/reconciliation of authoritative game state. Unknown ownership or missing same-day journal permits reporting, not new expenditure.

Shared configuration remains in data/smm-prefs.txt. Keep daily counters, journals, credentials and machine paths out of git. Test the Mac symlink layout: JS require of ASH whose real path lies outside the Mafia folder is already a documented issue; reuse the existing deliberate bridge pattern rather than assume both installations behave identically.

Sources: 
shared settings, rollover, map_to_file, file_to_map.

7.4 Dry-run and Mafia facilities
plan: pure evaluation of a saved snapshot, ranks and prices; zero game mutations or purchase probes.
refresh-plan: validated read-only refresh and quote operations, then the same planner. A GET request is not assumed harmless merely because it is GET.
run/resume: fresh state checks and admitted mutations.
salvage: qualified, independent expiring opportunities within remaining policy limits.
report: receipts, pending work, unused-resource reasons and uncertain data.

Current iotmroute plan enters/leaves discovery menus and may participate in restoration; it is not the implementation of strict offline planning. Current overdrunk “free” routing also allows certain paid item-started locket fights; the new free mode means zero approved paid adventures.

Use maximize(expression, true) to inspect equipment possibilities and Generated:_spec, then admit/equip separately. Required survival, breathing, Fishy, MP capacity and stat constraints outrank a raw economic score.

Never treat autoBuyPriceLimit as a total budget. In buy(qty,item,price), price below one means no price limit. In maximize, max_price at or below zero falls back to autoBuyPriceLimit/available Meat. Reject unknown prices before calling these APIs.

Scope currentMood, customCombatScript, choiceAdventureScript, betweenBattleScript, afterAdventureScript, recoveryScript, autoattack and autoSatisfyWith* settings. Restore via try/finally and a durable interruption snapshot. Validate offered choice options rather than treating an old choiceAdventure number as proof the desired branch is currently present.

Sources: Buy, Maximize, 
current route core.

8. Testing, measurement and rollout
8.1 Required test foundation

The docs refer to fixes/resource-planner/run-tests.sh and fixes/iotm-route/run-tests.sh, but those harnesses are absent from the audited repository tree. The versioned test found is tests/nightcap-adventure-bounds.cjs. Recover the legitimate existing harnesses or recreate their stated contracts in the repository before depending on them as release gates. This council has not run those absent tests.

Compile entry points against r29462 and the exact selected dependency hashes in an isolated no-login runtime. Use fake HTTP rejecting unexpected mutations, realistic Mafia fixtures and brute-force allocation checks for small cases.

Necessary scenario tests:

November 21 MP incident: mood/burn/restore cannot cross the scheduled reserve.
Unified spending: each nested buyer, price-zero trap, missing average, partial fill, changing price tier, ROI buy after discount reservation, gifts and old-stock classification.
Economic accounting: consumed ingredients, sale/deposit/transfers, one copy retained versus sold, stale price revaluation.
Capacity: one carrier used by competing familiar/Sword/charge tasks, no fictional copy hosts, source-specific banish overwrite and duration.
Turn boundaries: first paid Snojo/Cyber encounter, locket seeding, underwater extra turn, per-step legacy limits.
Museum: ties, one-per-account items, own-entry exclusion, buffer, unknown ranks, full milestone, unbuyable preservation.
Diet: Drip organs, Yeti next-drink ordering, mojo daily limit, sweat/spleen overlap, last sober action, no stranded generated adventures.
Reliability: no progress, local optional failure, unknown choice, crash before/after response, already-completed summon, corrupt/missing journal, rollover and Windows/Mac handoff.
Coverage: every owned capability is new-owned, legacy-owned, intentionally deferred or unsupported with a reason—never silently unowned.
8.2 Migration with daily continuity

Stage A — shadow only. Existing execution remains the sole owner. Capture snapshots and compare the proposed allocation and economics with observed results. Do not skip working legacy actions merely because the new planner exists.

Stage B — governor safeguards. Qualify cash admission, MP control, journal/restoration, day identity, prompt elimination and ownership. Bring actual test harnesses into the repo. No speculative farm change.

Stage C — deterministic claims. Migrate a small set of verified summons/collections, disabling only their exact legacy equivalents. Confirm item/counter outcomes and restart behavior.

Stage D — individual free-fight sources. Add Snojo and then safe CyberRealm in small observed batches, with zero-paid-turn limits. Introduce passive zombie/XP/equipment choices only after the carrier model reconciles.

Stage E — daily target bundles. Migrate one route at a time with turns, cash, banish source, organ and deadline reservations. Test far enough before rollover to retain a practical recovery window.

Stage F — earning core and purchases. Make Oasis bounded, then compare qualified alternatives on matched marginal turns. Enable the unified spending portfolio after cap definitions and receipts are verified.

Stage G — garbo integration. Pure calculations first; individual auditable tasks next; wider invocation only after every side effect obeys the contract and measured return justifies it.

A rollback restores the previous qualified worker/hash and capability ownership. It never clears real counters, resets spending or runs the full old dailyGrind blindly after a partially completed new day.

8.3 KPIs and acceptance gates

Report daily and rolling medians/ranges:

Realized eligible cash profit, operating cost, policy allowance, actual purchases and unsettled reservations.
Economic profit including conservative surplus change, separately from cash.
Actual top-ten/#1 achievements, added case copies, funded remaining gaps and estimated days per active unbuyable target.
Paid turns by purpose, residual-farm net per paid turn, diet cost per useful added adventure.
Every daily resource's available/used/reserved/expired amounts and reason for non-use.
Banish source occupancy/overwrites, minimum MP against reserve, and shared carrier attribution.
Expected versus realized drops, price evidence freshness, sale-through and quantities still unsold.
Prompt count, unhandled failures, duplicate actions, no-progress retries, unsupported states and recovery time.

Promotion requires zero unexplained spending/turn/reserve violations, zero duplicated daily actions, reconciled receipts, no missed legacy-owned capability caused by migration, and verified recovery from interruption. Compare farms with compatible gear/buffs/state and enough matched batches to distinguish a real difference; do not blindly burn five days on an obviously losing route just to satisfy the old minimum-history switch.

9. Questions for Sacha, with concrete defaults

These are decisions for the merged plan and later execution, not blockers to completing this research.

Cap scope: should operating costs count inside the 50% limit as well as being deducted to compute net, or is the limit for purchases after operating profit? Until answered, show both and enforce the stricter formula.
Old-stock proceeds: should selling old hammers/MSG/noodles/etc. unlock today's spending budget? Default: classify separately and do not automatically treat it as new resource profit.
Unbuyable allocation: what maximum paid-turn allocation and economic loss per day should the portfolio use? Recommend a trial ceiling of 40 paid turns/200k opportunity loss at the provisional 5k value, with a review before allowing a longer bundled voyage. This is a proposal, not a claim that all unbuyable work fits forty turns.
Ranking: are tied top-ten places acceptable when displayed, and should the eleven-copy buffer be optional for expensive items? Recommend visible ties accepted, sole #1 where attainable, and minimum target before discretionary buffer.
Shopping order: preserve the literal biggest-discount-first rule, or let entering top ten override a better discount toward #1? Default: positive return first, then discount; use milestones as tie-breaks.
Operational preferences: confirm no ascending, no unapproved clan borrowing, usual overdrinking/nightcap, required manual/clan activities, and whether each day normally stays on one machine. These affect reservations; they are not assumed ownership or permissions.
Snapshot and benchmark: obtain a fresh inventory/capability/quest/rank/settings snapshot and several complete daily receipts before promoting a new earning engine. Confirm which recent IoTMs and their necessary skills are actually usable.
10. Merge checklist for the parallel council

Reconcile the two drafts by decision, not by concatenating two independently valued income lists.

Agree on cap scope, old-stock handling, rank ties/buffers and the funded unbuyable budget.
Select one task/capability registry, one day identity, one transaction journal, one price model and one set of source hashes.
Distinguish verified mechanics, user ledger facts, scenario estimates and unresolved spading.
Collapse overlapping estimates for copies, free carriers, saved turns, MP reliability and diet.
Keep existing baseline output separate from incremental improvements and one-time liquidation.
Require evidence for every claimed garbo flag, free-fight property and source capacity.
Give every legacy capability exactly one owner at each migration stage.
Turn the agreed plan into a dependency-ordered implementation backlog with the test gates above.