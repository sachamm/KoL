# Independent diet optimizer

The previous lethe.xyz optimizer block has been removed from current
`scripts/diet.js`. Its replacement is newly authored code:

- `scripts/smmDietOptimizer.js`: a bounded resource-allocation solver.
- `scripts/smmDietPlanner.js`: conversion from this project's consumable records
  into the solver's inputs and back into the existing plan-row interface.
- `scripts/smmDietMechanics.js`: independently expressed numerical consumption
  rules and chocolate counter definitions.
- `scripts/diet.js`: the retained KoLmafia integration, price/reservation logic,
  phase execution, gear handling and rollover selection.

This is a replacement design, not a translation or line-by-line rewrite of the
third-party implementation. The earlier code was inspected during the license
audit, so this is not a claim of a formally separated clean-room process.
Small synthetic evaluations of the previous routine were also used to check
functional expectations. Its implementation and downloaded consumable catalog
are not included in the replacement or its tests.

## Objective and constraints

The solver maximizes modeled net value: expected adventures times their configured
value, plus PvP and item-effect utility, less item costs. Doing nothing is always
an option. It does not force uneconomic consumption just to fill every organ.

Each group represents one item, with alternative ways to consume it. A group's
limit applies across all alternatives. Its resource vector accounts for three
organs and shared daily allowances such as speakeasy drinks, Lucky effects and
the mime shotglass, the daily spork and finite helper inventory. Bounded cleaning
items can supply space in multiple organs. Spleen-cleaning food and drink are
bounded by the combined available stomach/liver space and the mime allowance.
An unsupported unbounded cleaning cycle causes an error.
The search uses sparse dynamic-programming frontiers keyed by resource use and
keeps the best value at each state. An item is discarded as dominated only when
an unlimited alternative uses no more resources and yields strictly more value.

The default search limits are 250,000 states per frontier and 10,000,000
transitions. Exceeding either throws an error before a plan can be printed or
executed; the solver never presents a truncated search as an optimum. Those are
resource limits, not a claim that every possible live catalog will finish.

The solver's exactness concerns this explicit numerical model. Organ-cleaning
order, actual random adventure yields, prices, effect duration and live changes
remain gameplay facts checked by the integration. The existing executor checks
each unit's current organ fit, preserves reserved Museum copies, confirms
purchases, and stops on failed actions. No live account action was used to
validate this replacement.

## Supported predictions and intentional differences

The adapter handles priced food, drink, spleen, bounded simple items and organ
cleaners from the existing live-data builder. It retains item limits, exclusions,
effect/PvP values, daily speakeasy quotas, a quota for Lucky Lindy value, and the
one-use mime shotglass. Ancestral Recall uses the remaining cast limit and blue
mana cost. Spaghetti breakfast is limited to one serving. Owned limited stock
keeps its stock bound rather than becoming unlimited.

Validated passive models cover Saucemaven, Pizza Lover, Gourmand/Neurogourmet,
tuxedo martinis, wine with a mafia pinky ring, and Ode when the skill is
available. Wine rounding is averaged over the integer base-adventure range;
the mime shotglass does not receive Ode credit on its free drunkenness unit.
The mechanical reference is KoLmafia's
[ConsumablesDatabase](https://github.com/kolmafia/kolmafia/blob/main/src/main/java/net/sourceforge/kolmafia/persistence/ConsumablesDatabase.java)
and
[item proxy](https://github.com/kolmafia/kolmafia/blob/main/src/main/java/net/sourceforge/kolmafia/textui/parsetree/ProxyRecordValue.java),
which identifies the item adventure field as the base range. The new solver and
adapter do not incorporate those Java implementations.

Optional variants cover salad forks, the daily fudge spork, munchies pills,
Special Seasoning, taco sauce, frosty mugs, BGE shotglasses, Mayoflex and
Mayodiol. Mutually exclusive utensils/mayo stay exclusive; helper prices and
finite stock are included in every alternative. Mayodiol transfers one unit
of stomach use to liver use. A variant with the same resource use and lower
net value is discarded before the main search.

Gar-ish on eligible days and Refined Palate are compared in up to four
activation scenarios. Each scenario reserves its source item and charges one
activation only when boosted regular consumption is selected. Salty Mouth
charges one wish per boosted beer; an already active Salty Mouth supplies one
free serving. Existing active persistent effects do not incur an activation
charge. Overdrink candidates conservatively include a separate activation
cost when the effect was not active at planning time.

Chocolate options use their daily counters: the shared fancy/class-chocolate
pool, plus separate capsule, cigar and sculpture pools. Marginal returns are
5/3/1 for ordinary chocolates, 3/2/1 for the matching class chocolate and 2/1/0
for other class chocolates. The executor consumes selected tiers in counter
order across item names. It also prioritizes the mime serving before other
drinks, budgets per-serving wishes and stops if a queued helper fails.

The sources for counter tracking and helper execution include KoLmafia's
[UseItemRequest](https://github.com/kolmafia/kolmafia/blob/main/src/main/java/net/sourceforge/kolmafia/request/UseItemRequest.java),
[EatItemRequest](https://github.com/kolmafia/kolmafia/blob/main/src/main/java/net/sourceforge/kolmafia/request/EatItemRequest.java)
and
[DrinkItemRequest](https://github.com/kolmafia/kolmafia/blob/main/src/main/java/net/sourceforge/kolmafia/request/DrinkItemRequest.java).
The developers' [chocolate tracking discussion](https://kolmafia.us/threads/track-chocolate-consumption.5328/)
records the shared counter and class-dependent returns. These are references
for mechanics, not incorporated implementations.

Remaining differences are explicit: Straight-Edgy from temporary X tattoos
is not modeled and triggers a warning when that item is available. Tiny
plastic sword recipes are not priced by the live-data builder. Persistent
effect predictions assume a contiguous batch of consumption; adventuring
between phases can expire an effect and require another activation. Replan
at each phase. Unmodeled path-specific bonuses, random outcomes and changing
prices can also affect actual results. This is not a claim of universal
feature-for-feature or economic parity with the previous calculator.

The four-phase integration remains: ordinary consumption, zero-organ turn
generation, late capacity/rollover consumption, and one overdrink. Shared
allowances are checked again when choosing that overdrink. The exported
`tehtmi` property is a compatibility name for the new implementation, not a
retained copy of the original function.

## Offline verification

Run from the repository root:

```sh
node --test tests/diet-optimizer.test.js
```

Tests cover a greedy trap, bounded variants, mixed-resource alternatives,
multi-organ cleaning, shared quotas, finite zero-organ rewards, invalid inputs,
search exhaustion, caller-data immutability, scoring, exclusions, passive
bonuses, phase integration and overdrink quotas. Another 120 small allocation
problems are independently enumerated by a brute-force reference. A 501-item
dominated catalog checks that the pruning rule retains the actual best item.
Helper/chocolate tests cover shared inventory, fixed activation costs, rounding,
exclusivity, daily limits and chocolate pools. A mixed 134-record catalog with
cleaners and all helper families completes within the default search budget.
An in-memory game verifies chocolate execution order, mime priority, wish
budgets and stopping on a failed helper; it cannot validate the real server.

The license audit's original exact-line comparison is an investigation aid,
not a legal safe harbor or proof of independent authorship. Historical copies
of the removed implementation still need separate treatment; see
[LICENSING.md](../LICENSING.md).
