# Aftercore goals

These are the overarching goals that everything in this repository serves. The other documents describe how parts of them are implemented; this one says what the scripts are for.

## In Sacha's words

> In aftercore (which is the time after finishing the main goals of the game) the idea is to spend free and cheap resources -- especially daily resources and resources that expire -- to gain items and "meat" (money).
>
> A separate website called the Museum tracks all the display cases in the game with the top 10 being displayed on the item's wiki page. The ultimate goal is to get my character on the #1 spot on every list. I accept being anywhere on the top 10 that is visible on the wiki.
>
> Some items must be collected or crafted by me but most can be purchased from the mall, so the main choices are how many resources to spend on getting unbuyable items, and how to spend resources to gain the most meat in order to buy items and put them into my display case.

## What that means for the scripts

- **Ultimate goal:** #1 in the Museum for every Display Case item. **Acceptable result:** anywhere in the top ten, which is what the item's wiki page shows.
- **Resources to spend:** free and cheap ones first, especially daily resources and resources that expire if unused.
- **What they produce:** items and Meat. Meat matters because it buys collection items from the mall and those go into the Display Case.
- **Second goal: completionism.** Every IoTM Tquilla owns, other than clan items, is maximally unlocked and prepared. See [Completionism](#completionism).
- **The two main decisions:**
  1. How many resources to spend getting items that can't be bought (they must be collected or crafted by the character). See the [target register](target-register.md).
  2. How to spend the rest to earn the most Meat, to buy everything that can be bought. See the [collection objective](collection-objective.md), the [IoTM route](iotm-route.md) and the [resource planner](resource-planner.md).

## Spending rules

Sacha's answers, in their own words:

> 1: always try to be as efficient as possible, so meat goes to resources with a positive return first, then to resources that are on sale with the biggest discount; 2: the most we should spend per day is 1/2 the amount we net per day by expending our resources. Don't go above mall price at all; 3: you know it's cheap when it's being sold at least 20% under the market price, and there will often be limits on the number you can buy.

As rules for the scripts:

1. **Priority order for Meat.** Be as efficient as possible. Spend first on resources with a positive return, then on resources that are on sale, biggest discount first.
2. **Daily spending cap.** Spend at most half of the Meat netted that day by expending resources.
3. **Price ceiling.** Never pay above the mall price, measured as the item's recent average sale price.
4. **What counts as cheap.** A resource is cheap when it sells for at least 20% under its market price, where the market price is the item's recent average sale price (Sacha: "average sale price"), not the current lowest listing. Such offers often limit how many can be bought.

## Completionism

Sacha added this goal on 2026-11-28:

> let's add to our goals: completionism, including things like unlocking all IotM zones, adding all copyable monsters to Combat Locket and any other copier. Don't include clan items like the fax machine but all other IotM should be maximally unlocked and prepared.

What it covers:

- **Scope.** Every Item of the Month Tquilla owns, whether used from inventory, the campground, the workshed, the garden or the Chateau. Clan items (the fax machine, the clan VIP lounge furniture and other clan furnishings) are out of scope.
- **Zones.** Every zone an IoTM opens is unlocked and kept open where it can be: for example the Snojo, CyberRealm, the Shadow Rifts, the Neverending Party, the Gingerbread City, PirateRealm and the other "realm" and island zones. A zone that needs a daily or permanent unlock step (a quest, a ticket, a setting) has that step done.
- **Copier collections.** Every copyable monster is in the combat lover's locket, and the same holds for every other IoTM that keeps a per-monster collection or record for later copying or summoning. The locket gains a monster only when Tquilla fights it with the locket equipped, so the work is to fight each missing copyable monster once with the locket on.
- **Other permanent progress.** Upgrades, unlocks, trained levels, learned skills, collected letters and similar one-time or accumulating progress on an IoTM are completed, for example Heartstone letters and familiar training. "Prepared" means the item is ready to use at full strength on any day without further setup.

How it relates to the first goal:

- Completionism is a separate goal, not a source of Meat. An unlock can also pay back by opening free fights or income, and the [resource ledger](resource-ledger.md) values that, but the goal holds even when it does not.
- Progress is cheapest when it rides on fights and turns that happen anyway: equip the locket on a scheduled fight against a missing monster, or do an unlock step with leftover free resources.
- When progress needs paid turns or Meat of its own, the spending rules still apply. Like unbuyable Display Case items, it is collection progress with its own funded budget, and its spending counts against the daily cap.
- Each owned IoTM needs a checklist of what "maximally unlocked and prepared" means for it, read from current character state rather than old preferences. That checklist does not exist yet.
