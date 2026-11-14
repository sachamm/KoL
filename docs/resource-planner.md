# Shared resource planner

The planner allocates limited resources across competing tasks. It compares **incremental** Meat value, preserves named reservations, supports budgeted collection goals, and explains skipped actions. It does not perform combat, buy items, change equipment or install a workshed.

The implementation lives in `smmUtils/scripts/smmResourcePlanner.ash`. The `resources.ash` command lives in the KoL repository and imports that library. `smmUtils.ash` applies reservations in its existing `skillToUse()` and `skillsAvailable()` functions, covering the existing banish, replacement, yellow-ray and free-kill selectors. With no current reservations, selection retains its existing behavior. A priority tie-break bug in that selector was also corrected.

## Commands

```text
resources status
resources status all
resources demo
resources reserve doctor.xray quest 2
resources release quest
resources clear
```

`demo` uses synthetic values to demonstrate why two complementary actions can beat the best individual action. `status` reads cached Mafia state without refreshing the server or requesting prices. `status all` includes unavailable sources and unknown state. The initial live inventory includes 59 property-backed pools and five shared color cooldowns. It is scoped to unrestricted aftercore; unknown properties and missing sources cannot supply capacity.

`reserve` replaces that owner's reservation for one pool; it does not add to it. Other owners cannot use those units. Reserving more than the current unreserved balance is rejected. Reservations expire on a change of date or ascension. `release` removes that owner's holds. `clear` removes all holds. Neither command changes real Mafia usage counters.

Existing routines run as owner `legacy` unless explicitly wrapped in `smmRPBegin(owner)` / `smmRPFinish(lease)` or the caller sets `smmPlanner.owner`. Prefer the wrapper; it restores the previous identity even on a failed action. No reservations are created automatically on installation.

## Model a planning block

```ash
import <smmResourcePlanner.ash>

SmmRPResource [string] pools = smmRPLiveResources();
// Count only fights verified to permit this block's loot replacement.
pools["carrier.free"] = new SmmRPResource("compatible free fights", 10, true, "");

SmmRPAction [string] actions;
actions["sword"] = smmRPNewAction("Sword incremental loot", 10, 600);
actions["sword"].costs["sword.loot"] = 1;
actions["sword"].costs["carrier.free"] = 1;

// An alternative familiar competes for the same fights, not an additional ten.
actions["bones"] = smmRPNewAction("Bones minus forgone familiar income", 10, 400);
actions["bones"].costs["carrier.free"] = 1;

SmmRPContext context = new SmmRPContext("farm", 5000, false, 0, 20000);
SmmRPPlan plan = smmRPSolve(actions, pools, smmRPReservations(), context);
smmRPReport(plan, actions, context);
```

The figures above are examples, not measured prices or recommendations for your account. Workers must supply current realizable sale values, encounter compatibility, source availability and any change in familiar/equipment income. A plan is optimal only within those supplied assumptions. Use separate blocks when monsters, prices, buffs or familiar roles change. Shared counts represent fights or currency units; do not count the same encounter in two independent budgets.

Each action's economic value is:

```text
direct_meat + loot_value + adventure_delta * turn_value + avoided_cost
    - input_cost - displaced_value - future_cost
```

Positive `adventure_delta` means adventures saved or gained; a paid extra fight uses `-1`. For Sword, subtract the original monster's **item** loot and forgone familiar/equipment income. Native Meat is unchanged, so it is neither an added benefit nor an item-loot displacement. A drop-destroying free kill must subtract destroyed loot as well as crediting a genuinely saved turn. A buff's value is its benefit over remaining eligible encounters, after caps, rather than its nominal percentage.

All costs in `action.costs` are positive integral units per use. Currency recipes may consume multiple pools simultaneously. For mutually exclusive installations across the block, set `choice_group = "workshed"` and distinct `choice` strings. Matching choices can coexist. Do not use a block-wide exclusive choice for familiars that can be switched between fights; shared carrier capacity models that competition.

Nonlinear returns, escalating BCZ substat costs, setup costs, cooldown progress, rewards that create more capacity, and sequential dependencies must be represented by worker-generated bundles or by replanning after each step. This solver does not assume that future drops, free rests or copied fights already exist. Do not assign a constant per-use value to an escalating or declining reward unless that approximation is intentional.

## Collection goals

For a missing untradeable reward, set `goal`, `missing` and `collection_value`. Enable collection in the context and set `collection_budget`. `missing` caps the number of premium-bearing actions. `collection_value` is your willingness to pay per reward, not a resale price. An action's negative economic delta consumes the shared `budget.collection` capacity, rounded up per use; total expected loss cannot exceed that budget.

Completed goals, disabled collection mode, unknown values and nonpositive marginal returns are reported explicitly. Never give a repeatable duplicate the missing-item premium.

## Plan files

```text
resources plan smm-planner-example.txt farm 10
resources plan my-plan.txt farm 10 20000
resources reserve-plan my-plan.txt farm 10 20000
```

The first numeric argument is the caller-verified number of compatible free carriers. The optional second number enables collection with that Meat-loss budget. `plan` only reports. `reserve-plan` additionally reserves the selected live resource demands in one ledger write after taking another local snapshot and checking for staleness. It replaces all reservations belonging to that owner. Carrier forecasts and collection budgets remain local to the block.

Files are tab-separated, with the ID as the map key followed by these fields in order:

```text
id description limit eligible valued direct_meat loot_value adventure_delta avoided_cost input_cost displaced_value future_cost costs goal missing collection_value choice_group choice
```

`costs` has comma-separated `pool=units` terms. Duplicate costs, malformed numbers and nonpositive costs are rejected. A blank/false `valued` field does not mean a free action: it excludes the candidate. `eligible` is an explicit assertion by the producer, not proof of game eligibility. The example file contains synthetic values and is for checking the interface.

`smm.TurnValue` supplies CLI turn value, defaulting to 5000 if unset. `smmPlanner.nodeLimit` defaults to 20000; the library caps it at one million. The solver uses bounded branch-and-bound, not a greedy ranking. On cutoff, the result remains feasible and explicitly reports that optimality was not proven. A block accepts at most 64 eligible candidates and an action limit of 10000. Split larger horizons into coherent blocks.

## Sword adapter

`smmRPSwordCandidate(native, target, carriers, native_item_bonus, sword_item_bonus, familiar_and_gear_displacement, sale_values, verified_carrier)` builds a candidate from Mafia drop data. Supply `float [item] sale_values` containing realizable per-item values, including explicit zeroes when appropriate. Native and replacement item bonuses can differ after changing familiar/equipment.

The target must already match `swordOfSWordsMonster`; switching targets is a separate setup decision. Both monsters must be eligible copyable nonbosses, and the caller must verify the carrier preserves drops and remains free. Missing prices, conditional/unknown drop rates and unsupported flags leave the candidate unvalued. Pickpocket-only, bounty and accordion-only drops are excluded. More complex conditional-drop strategies should provide their own explicitly verified valuation instead of overriding the uncertainty with zero.

## Execute through a worker

The planner never executes its description or a file-supplied command. A worker decides how to implement a selected action and rechecks target, gear, cooldowns, resource counts and value immediately before use.

```ash
// After validating and optionally reserving the plan:
SmmRPLease lease = smmRPBegin("farm");
try {
    // Existing worker performs one verified action and processes its real results.
} finally {
    smmRPFinish(lease);
}
```

`Finish` takes a new local snapshot and releases only this owner's reservation units that were observably consumed. Failed/no-op actions retain their holds. It never releases another owner's reservation or changes real usage counters. It does not attribute consumption across a date/ascension change. Nested workers should finish leases in stack order.

`smmRPPlanIsCurrent(plan, actions, resources, reservations, context)` detects changed budgets, reservations, owner, valuations and action settings. Rebuild state before calling it. This is a local freshness check; it cannot detect unseen server changes. Avoid concurrent workers sharing the same account, or serialize their snapshot/action/observation sections.

The reservation gate covers mapped skills chosen through the shared selectors. Direct `use_skill()` calls, hand-written combat macros, passive Sword loot, item uses, shop purchases and third-party scripts must call the planner APIs themselves. They cannot be intercepted by importing this library. Installing the engine therefore does not yet automate every monthly item or replace every legacy routine's fixed preferences.

## Validation

Run `zsh fixes/resource-planner/run-tests.sh` from the KoL Automation workspace. It uses the installed KoLmafia JAR in an isolated runtime and test preferences, never your game session. Checks cover global allocation versus a greedy trap, shared resource capacity, owner reservations, negative marginal value, collection limits/budgets, unknown state, incompatible choices, search cutoff, stale plans, actual-observation commits, caller-data immutability and legacy-selector integration. Thirty independently enumerated allocation cases compare the optimizer against a brute-force reference. Registry checks resolve every source and property against Mafia.

No live game actions are needed for these tests. Live resource state, prices, encounter-specific outcomes and per-item worker implementations still require their own checks.
