# Target register

Some Display Case items cannot be bought: they only come from an action, and usually from a random result. Meat buys everything else, so reaching the Museum top ten for these items is the first claim on each day's resources. The register is the list of those items, where each comes from, and how far each is from the top ten.

It only reads. It never adventures, buys, sells or moves an item.

## Commands

```text
targets                 # the 40 targets closest to the top ten
targets list all        # every target
targets refresh [n]     # look up missing, then oldest, rankings for register items (default: all missing or due)
targets item <name>     # everything known about one item, with its stored ranking
targets unknown         # unbuyable items you hold that have no known source
targets unknown all     # every unbuyable item with no known source
targets summary         # how every Display Case item is classified
```

`targets` also writes the full list to Mafia's `data/smm-targets-<player id>.txt`.

## What counts as unbuyable

An item can be had for Meat when it is tradeable, sold by an NPC store, or made by a shop or recipe whose every input can itself be had for Meat. Everything else is unbuyable.

Shops and recipes come from the conversion graph in `smmValue.ash`, the same model the other scripts price items with. It reads Mafia's own coinmaster, shop-row, recipe and NPC-store data, so the answer does not depend on which recipes the current character can make.

The register lists an unbuyable item when a source is known, or when you already hold a copy.

| Acquisition | Meaning |
|---|---|
| `mall`, `npc`, `coin-buy`, `craft-buy` | Meat gets it. Not listed. |
| `drop` | A monster drops it. The best drop is shown with its rate and zone. |
| `coin` | A shop sells it for a currency Meat cannot buy. The currency is the real target. |
| `craft` | A recipe makes it from at least one unbuyable part. |
| `unknown` | Mafia's data names no source. Describe it in the source file. |

In a source line, `*` marks an input Meat cannot buy. `[boss]` drops are usually once per ascension or per dungeon instance. `[not open to you now]` means the shop is closed to this character at the moment, which includes past event shops.

## The source file

`data/smm-target-sources.txt` holds what Mafia's data cannot say. It is tab-separated: item (name or number), kind, attempts per day, source, note.

| Kind | Use it for |
|---|---|
| `repeatable` | Can be attempted again. |
| `oneoff` | Fixed supply, such as one per account. |
| `ignore` | Leave it out of the register, for example an item from an event that is over. |
| `buyable` | Meat does get it, by a route Mafia cannot see (worthless trinkets from chewing gum on a string). |

A line overrides the derived source text and kind. The first lines were seeded from what `dailyGrind()` already farms and should be checked.

## Rankings

Rankings come from the shared Museum ranking store in `smmUtils.ash` (see "Museum ranking store" in `collection-objective.md`). The store keeps every answer in `data/smm-museum-ranks-<player id>.txt` with no daily request limit. `targets refresh` looks up register items never looked up, then the oldest; `dc refresh` rotates through everything stored plus the Display Case.

The Museum page lists every collector, with tied players sharing a row. The register counts each player in a tie.

| Column | Meaning |
|---|---|
| case / held | Copies in the Display Case, and copies in inventory, closet, storage or equipped. |
| short of top 10 | Copies still to acquire to match the tenth-largest other collection. A tie counts as a top-ten place. |
| short of #1 | Copies still to acquire for sole first place, with no buffer. |
| rank / holders | Your rank and the number of collectors, as the Museum last saw them. |

When every listed collector has exactly one copy, the source column says the item is probably one per account.

`targets item` also shows what a copy is worth if spent or sold, from `smmValue`. The spending rules in `smmMuseumPolicy.ash` are separate and stricter: they reserve owned copies up to first place plus the buffer.

## Not done yet

- Attempts and outcomes are not logged, so there are no measured drop rates and no days-to-top-ten estimate.
- The register does not yet steer `dailyGrind()` or the IoTM route.
- `dc.ash` has a map from each IoTM to its opened form and products. The register does not read it, so an opened IoTM shows as `unknown` even though the package is sold in the mall.
