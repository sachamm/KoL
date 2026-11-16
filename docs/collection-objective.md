# Standing automation objective: Museum collections

The primary objective is **rank #1 for every displayable item in the Museum**, with **top ten accepted as an intermediate result**. Rankings measure copies actually in the Display Case. Inventory, closet, storage, shop listings, learned familiars, tattoos and buffs do not themselves improve that rank.

Meat is purchasing power for this objective. An action can be productive by generating cash to buy missing collection items, acquiring missing copies directly, or providing an earning improvement whose future collection return covers its opportunity cost. Maximum daily Meat and exhausting daily charges are not independent win conditions.

## Implemented in the shared daily route

- Use `dc.ash`'s existing validated Museum ranking cache and lookup helpers. Compare against other collectors, excluding our own entry so an existing lead does not ratchet its own target upward. Prefer strictly exceeding the strongest other collection, with the existing overshoot setting as a buffer; separately track the strict top-ten entry threshold.
- Count Display Case copies separately from eligible owned stock. Owned stock can fund a placement, but it is not reported as an achieved Museum rank until a transfer is confirmed. Keep worn equipment and shop listings out of committed case stock. Respect existing `saveAmount` operating-stock rules, with `smm.IR.keepItem.<item ID>` as an explicit override.
- Value a retained tradeable copy at avoided acquisition cost, capped at the remaining target. Value surplus at realizable sale proceeds. Never add both for the same copy. If a needed copy is consumed in a recipe or drink, charge replacement cost; a batch can contain both needed and surplus inputs.
- Score progress toward the next rank milestone as separate non-cash utility, using `smm.IR.museumRankValue` (default: the existing value of a turn). Unavailable ranking data receives no invented direct-collection credit or rank claim.
- Compare placement with profitable crafting/transformation in the same resource solve. New outputs are earmarked first, not immediately deposited ahead of their possible conversions. Placement uses the same physical-item capacity as crafting; selected placement quantities are transferred in batches and must produce the expected increase in the actual case count. The route never removes case copies.
- Keep unrated route outputs reserved. The common `stockItem` helpers preserve these holds and stock needed for the acceptable top-ten threshold. They do not make hidden Museum requests during store heartbeats. Unknown rankings block automatic stocking of that item until a usable snapshot or explicit per-item liquidation policy exists.
- Keep a Gross Prophet chrysalis as a collectible hatchling in Museum mode. A learned familiar cannot be displayed. Other one-time learning, tattoo use, consumable use and item destruction require accounting for the collectible copy's opportunity cost.
- Evaluate every owned garden as an alternative for one slot, including growth, reset losses, finite collection gaps and cash surplus. Museum credit for a limited gap is not repeated on every hypothetical future harvest. The policy allows one attempted garden change per day, not one available garden of each kind.

## Owned copies and item values

Owned copies are never free while the Museum still needs them. `smmMuseumSpareCopies(item)` counts the copies beyond the #1 target (with buffer); only those may be spent, and an item without a usable ranking snapshot has none. `smmMuseumOwnedValue(item, quantity)` prices spending copies: spare copies at what they could otherwise be turned into (`smmItemLiquidValue` from `smmValue.ash`: mall, conversion or autosell), needed copies at their replacement price (`smm.IR.museumCopyValue.<item ID>`, else the mall price). An untradeable needed copy with no explicit value is effectively priceless and is never spent.

Making a new copy always costs its inputs, even after #1: `smmItemValue` prices an item that can't be bought by what it is made from (FantasyRealm mead = 100 Rubees x the value of a Rubee).

`diet.js` follows this: owned untradeable food, drink and spleen items are limited to spare copies, and a bought item is bought fresh instead of eating a reserved copy.

Scripts outside the route spend items through the `museumSafeEat/Drink/Overdrink/Chew/Use/Create` wrappers in `smmUtils.ash` (and `consume()`, which checks the same rule). They behave like the built-ins but refuse to spend copies the Museum still needs; for tradeable items they first get fresh copies with `retrieve_item`. Crafting checks every ingredient, and `fullAcquire` only folds when every other owned form has a spare copy. Reusable items are not checked. A blocked spend prints why and names `smm.IR.museumSpend.<item ID>=true`, the per-item override.

Deliberately not guarded: installing IoTM workshed and campground items (model train set, Dramatic range, Queue Du Coq kit, saltwaterbed), which is how those items are used, and the IoTM route's own crafting, which already applies this policy through `smmMuseumInput`. Store stocking still protects only the top-ten threshold (`smmMuseumSaleQuantity`), because a sold tradeable copy can be bought back.

## Commands and controls

```text
iotmroute plan
iotmroute run
museumroute floaty rock helmet
```

`museumroute` refreshes your case and reports actual Museum thresholds, eligible owned stock, the acquisition gap, and rough funding at the current one-copy market quote. It does not buy items or move copies. Bulk availability/prices may differ. Existing `dc --dry-run rankup <item>` remains available for reviewing purchases before using the existing buying utilities.

Museum policy is enabled by default. Relevant settings:

- `smm.IR.museum=false`: opt out to the previous monetary policy.
- `smm.IR.museumDeposit=false`: hold acquired copies without automatic placement.
- `smm.IR.museumLookups=50`: maximum Museum requests per day, shared by every script (see "Museum ranking store" below).
- `smm.IR.museumBuffer`: override the existing `smm.dcOvershootAmount` (default 11).
- `smm.IR.museumRankValue`: utility of completing a rank milestone, separate from Meat proceeds.
- `smm.IR.museumCopyValue.<item ID>`: explicit replacement/opportunity value when market acquisition is unavailable; it is not a claim of resale value.
- `smm.IR.museumSell.<item ID>=true`: explicit liquidation override for that item's automatic store stocking, to fund other collection goals.
- `smm.IR.keepItem.<item ID>`: operating copies to retain rather than placing or consuming them; zero can override an equipment/hatchling category reserve.

The existing paid-turn and cumulative collection-loss budgets still apply. Do not invent historical/current Museum quantities when the source is unavailable. Goal completion requires observed case counts and a usable ranking snapshot, and competitive thresholds can change later.

## Further work

This is the collection objective and the first rank-aware routing layer, not a claim of completed collections. Continue missing IoTM adapters in reverse release order. Extend the cash-versus-retain decision into a global, budgeted purchase/liquidation portfolio across many items, audit legacy consumers outside the route, and add collection-aware production/upgrade chains. The existing common stocking helpers are guarded, but arbitrary third-party scripts and direct commands are not intercepted.

## Museum ranking store

Museum requests are rationed, so every answer is kept and reused across days.

- **File:** `data/smm-museum-ranks-<player id>.txt`, one line per item: time of the request, number of collectors, your count and rank on that page, and the first 11 entries of the list (tied players each get an entry).
- **Budget:** `smm.IR.museumLookups` requests a day (default 50), counted in `_smm.museumLookupsUsed`, which Mafia clears at rollover. Every request goes through `smmMuseumFetch` in `smmUtils.ash`, so `dc`, `targets`, the route and the spending guards share the one budget.
- **Use:** `lookupCollection` and the Museum guards use the stored ranking whatever its age. They ask the Museum only for an item never looked up, and only while budget remains; otherwise the ranking is unknown and the guards reserve every copy.
- **Rotation:** `dc refresh [n]` renews the stalest rankings with what is left of today's budget. It covers the Display Case and every stored item: never-checked first, then oldest. Items you hold no copy of count as 30 days fresher, so the ones you are collecting come round first.
- **One item now:** `dc refresh <item>`.
- **Status:** `dc cache` shows how many rankings are stored, their ages, lookups used today, and how many days a full pass takes.

The old daily `_smm.DCTop10For<item>` preferences are no longer written or read.
