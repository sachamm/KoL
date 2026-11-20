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
- **The two main decisions:**
  1. How many resources to spend getting items that can't be bought (they must be collected or crafted by the character). See the [target register](target-register.md).
  2. How to spend the rest to earn the most Meat, to buy everything that can be bought. See the [collection objective](collection-objective.md), the [IoTM route](iotm-route.md) and the [resource planner](resource-planner.md).

## Open questions

Details not yet decided; record the answers here as they are settled.

- Which items or display cases come first when the budget can't cover everything.
- How much Meat may be spent per day or per item, and how much risk is acceptable (for example, buying at inflated mall prices).
- What counts as a "cheap" resource: is there a Meat-per-adventure or price ceiling above which a resource is no longer worth spending?
