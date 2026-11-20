# Independent diet optimizer

The previous lethe.xyz optimizer block has been removed from current
`scripts/diet.js`. Its replacement is newly authored code:

- `scripts/smmDietOptimizer.js`: a bounded resource-allocation solver.
- `scripts/smmDietPlanner.js`: conversion from this project's consumable records
  into the solver's inputs and back into the existing plan-row interface.
- `scripts/diet.js`: the retained KoLmafia integration, price/reservation logic,
  phase execution, gear handling and rollover selection.

This is a replacement design, not a translation or line-by-line rewrite of the
third-party implementation. The earlier code was inspected during the license
audit, so this is not a claim of a formally separated clean-room process.

## Objective and constraints

The solver maximizes modeled net value: expected adventures times their configured
value, plus PvP and item-effect utility, less item costs. Doing nothing is always
an option. It does not force uneconomic consumption just to fill every organ.

Each group represents one item, with alternative ways to consume it. A group's
limit applies across all alternatives. Its resource vector accounts for three
organs and shared daily allowances such as speakeasy drinks, Lucky effects and
the mime shotglass. Bounded cleaning items can supply space in multiple organs.
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

The copied optimizer's consumable-helper and diminishing-return chocolate
tables have not been transplanted. Purchases of those optional boosts are not
modeled by this replacement, and every plan prints that limitation. Existing
explicit simple-item records are still used. More models can be added once
their mechanics, interactions, limits and acquisition costs have independent
evidence and tests. This is a material difference from the prior optimizer;
the new implementation does not claim feature-for-feature or economic parity.

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

The license audit's original exact-line comparison is an investigation aid,
not a legal safe harbor or proof of independent authorship. Historical copies
of the removed implementation still need separate treatment; see
[LICENSING.md](../LICENSING.md).
