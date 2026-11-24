# smmdaily scorecard

How close `smmdaily` gets to the [aftercore goals](aftercore-goals.md): spend the free, cheap, daily and expiring resources to gain items and Meat, and turn them into Museum places. The yardstick is the "Tquilla resource ledger" Claude Doc (the net-positive resources and their best uses) and the spending rules in the goals.

Each score reads the code, not a day's log, unless it says otherwise. Add a row when the code changes.

## The rubric

| # | Criterion | Points | What full marks means |
|---|---|---|---|
| 1 | The whole day runs unattended | 2 | One `smmdaily run` covers breakfast, the diet, the grinds, garbo, the nightcap and `good_night`, in a safe order, with no questions asked. |
| 2 | Daily and expiring resources are spent | 2 | Every ledger resource with a net-positive use has an owner that spends it before rollover, and the report shows what really went unused. |
| 3 | Scarce resources are kept and aimed | 1.5 | Free rests, Cinch, spikes and Avalanches are not spent on anything else and each forced noncombat goes to the best choice of the day. |
| 4 | Paid turns go where they earn most | 1.5 | Each paid-turn grind is measured honestly and dropped when it earns under the turn value, unless it brings an unbuyable Museum item. |
| 5 | The spending rules hold | 1 | Half of the day's net at most, never above the average sale price, positive return first, then sales. |
| 6 | Museum progress | 1 | Unbuyable items are farmed, and the budget turns into Display Case places, cheapest first. |
| 7 | Safety and reporting | 1 | Resumes after a stop, never loses track of fenced items or spending, and says plainly when the day is not finished. |

## Scores

| Criterion | Max | Live run 2026-11-24 (log) | main, 2026-11-24 (code) | Round 1 | Round 2 |
|---|---|---|---|---|---|
| 1 Whole day | 2 | 0.5 | 0.5 | 1.6 | 1.6 |
| 2 Daily resources | 2 | 1.2 | 1.0 | 1.6 | 1.7 |
| 3 Scarce resources | 1.5 | 0.2 | 0.25 | 1.2 | 1.2 |
| 4 Paid turns | 1.5 | 0.6 | 0.5 | 1.0 | 1.0 |
| 5 Spending rules | 1 | 0.8 | 0.75 | 0.75 | 0.8 |
| 6 Museum | 1 | 0.9 | 0.5 | 0.5 | 0.9 |
| 7 Safety and reporting | 1 | 0.6 | 0.6 | 0.8 | 0.9 |
| **Total** | **10** | **4.8 (5)** | **4.1 (4)** | **7.45 (7)** | **8.1 (8)** |

The live run scored higher than main's code on the Museum and daily resources only because Sacha ran garbo, the nightcap, `good_night` and nine `dc rankup` commands by hand.

### main before 2026-11-25 (4)

- The default `legacy` profile ran breakfast and the grinds only. The diet, garbo, the nightcap steps and `good_night` were run by hand, and `diet.js` waited on a question.
- Garbo, run by hand first, rested 31 times and spent 430 Cinch on Projectile Piñatas, so the Shadow Rift work after it had no Fiesta Exit left (0 of 7). Nothing spent the Avalanches.
- Grind loot was valued at its lowest mall listing: 154 Oasis turns read as 37.6M Meat. With figures like that the turn-value test never skips anything.
- The diet filled the organs before the Drip's nugget and wine, so the Drip got no turns.
- The report ran before garbo and the nightcap, so its "unused" list was mostly wrong.

### Round 1 (7)

- `diet`, `forced.nc`, `garbo` (now on by default), and the nightcap phase (`nightcap.before`, `diet.turngen`, `garbo.final`, `diet.finish`, `goodnight.adv`, `goodnight`) are tasks. `diet.js` takes a `yes` option and records its stop point for `garbo.final`.
- `forced.nc` spends spikes, Avalanches (new in `grindRufusAndTheShadowRiftsForFree`) and every Fiesta Exit before garbo, and the Cincho de Mayo is fenced while garbo runs.
- Grind loot is valued at its average sale price, never above the listing, autosell when nothing sells. The inflated history is cleared once.
- `drip.prep` eats the drippy nugget and drinks the drippy wine before the diet.
- `day.open` runs `smmPrefs apply`. The report comes after `good_night`.

### Round 2 (8)

- `smmSpend` has a third pass: the cheapest whole Display Case gaps, top ten first, at no more than the average sale price, within half of the net. This is what the nine `dc rankup` commands did by hand.
- The report says first when the day is not finished (garbo not run, or the nightcap not in).
- History from before the valuation change is never used to skip a grind, and `smmdaily plan` changes nothing.

### What keeps it from 10

- Questions still asked outside `smmdaily` itself: Gingerbread City's buff cost (`gbc.ash`), cancelling a platinum bounty, the Dreadsylvania gear checks, wishing for a monster. garbo can also ask.
- Forced noncombats all go to the Shadow Rift. No target is chosen per day.
- The turn-value test needs 5 days of honest history before it can skip a grind, and an untradeable item the Museum still needs exempts a grind even when it is incidental loot.
- garbo buys at its own prices (for example a Dinsey day ticket at 145,350). Its purchases are booked against the cap afterwards, not blocked before.
- Unused for want of an owner: Feel Envy, the last Neverending Party fight. Snojo and CyberRealm are not unlocked.
- None of the round 1 and 2 code has run in the game yet.
