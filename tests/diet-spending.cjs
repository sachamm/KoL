// diet.js's spending rules: nothing bought above its average sale price, and
// the diet's own daily budget. Runs under node, with no game:
//   node tests/diet-spending.cjs
const fs = require('fs');
const path = require('path');
const assert = require('assert/strict');
const diet = require('../scripts/diet.js');

let cases = 0;
function check(actual, expected, what) {
  assert.deepEqual(actual, expected, what);
  cases++;
}

// --- the average sale price, as Pricegun gives it ---------------------------
const melange = {itemId: 1633, sales: [{unitPrice: 215000}], history: [{volume: 12}], value: {__decimal__: '216771.5'}};
const answer = (change) => JSON.stringify(Object.assign({}, melange, change));
check(diet._parseAverage(answer({}), 1633), 216771.5, 'a decimal value');
check(diet._parseAverage(answer({value: 216771.5}), 1633), 216771.5, 'a plain number');
check(diet._parseAverage(answer({}), 1634), 0, "another item's answer is unknown");
check(diet._parseAverage(answer({sales: []}), 1633), 0, 'no sales on record is unknown');
check(diet._parseAverage(answer({history: []}), 1633), 0, 'no history is unknown');
check(diet._parseAverage(answer({value: {__decimal__: '0'}}), 1633), 0, 'a zero value is unknown');
check(diet._parseAverage(answer({value: null}), 1633), 0, 'a missing value is unknown');
check(diet._parseAverage('', 1633), 0, 'no answer is unknown');
check(diet._parseAverage('<html>502 Bad Gateway</html>', 1633), 0, 'an error page is unknown');
check(diet._parseAverage('null', 1633), 0, 'null is unknown');

// --- the rule: the purchase of 2026-11-24 (326,000 against 216,771) ----------
check(diet._averageRule(326000, 216771.5, 0), 'drop', 'above the average and none owned: left out');
check(diet._averageRule(326000, 216771.5, 2), 'owned', 'above the average with spare copies: only those');
check(diet._averageRule(216771, 216771.5, 0), 'buy', 'at the average: bought');
check(diet._averageRule(150000, 216771.5, 0), 'buy', 'under the average: bought');
check(diet._averageRule(326000, 0, 0), 'buy', 'unknown average: the listing is the only price');

// --- the most acquire() may pay per copy ------------------------------------
check(diet._buyCap(200000, 216771.5), 216771, 'the slack on the plan never passes the average');
check(diet._buyCap(100000, 216771.5), 130000, 'under the average the plan and its slack decide');
check(diet._buyCap(326000, 216771.5), 216771, 'a plan above the average is still capped');
check(diet._buyCap(1000, 0), 1300, 'unknown average: the plan and its slack');
check(diet._buyCap(0, 216771.5), 0, 'an unplanned item is not bought');

// --- planning under a budget -------------------------------------------------
function settings(value) {
  return {
    'adventure value': value, 'pvp fight value': 0, 'classid': 1, 'include nightcap': 'no', 'overdrink candidates': true,
    'rollover gain': 40, 'overdrunk turns': 0, 'overdrunk sink': null,
    'saucemaven available': false, 'pizza lover available': false, 'ancestral recall available': false,
    'spaghetti breakfast available': false, 'grab a cold one available': false, 'use potion of the field gar': 'no',
    'tuxedo shirt available': false, 'tiny plastic sword available': false, 'mafia pinky ring available': false,
    'mime army shotglass available': false, 'speakeasy': false, 'semirares available': 0, 'lucky wanted': 0,
    'effect rates': {}, 'workshed': 'none', 'excluded consumables': {}, 'organ sizes': [15, 14, 15], 'base organs': [15, 14, 15],
    'capacity gear': [], 'stooper': false, 'sweat': 0, 'sweat casts': 0, 'affirmation bonus': 0, 'speakeasy drinks left': 0,
    'ancestral recall casts left': 0, 'chocolates used': {fancy: 0, vitachoc: 0, cigar: 0, sculpture: 0},
  };
}
function market() {
  return [
    {name: 'fine food', advmin: 30, advmax: 30, type: 'food', size: [5, 0, 0], price: 60000},
    {name: 'plain food', advmin: 20, advmax: 20, type: 'food', size: [5, 0, 0], price: 10000},
    {name: 'fine drink', advmin: 12, advmax: 12, type: 'booze', size: [0, 2, 0], price: 20000},
    {name: 'plain drink', advmin: 8, advmax: 8, type: 'booze', size: [0, 2, 0], price: 3000},
    {name: 'spleen thing', advmin: 5, advmax: 5, type: 'spleen', size: [0, 0, 3], price: 4000},
    {name: 'spice melange', advmin: 0, advmax: 0, price: 200000, type: 'extender', size: [-3, -3, 0], limit: 1},
  ];
}
const none = () => 0;
function fit(room, refresh, spareOf, consumables) {
  const cons = consumables || market();
  diet._setData(cons, 30000);
  const s = settings(5000);
  const result = diet._fitPlan(diet.planDay(s, false), s, false, room, refresh || null, spareOf || none);
  return {value: s['adventure value'], toBuy: result.toBuy, over: result.over, ownedOnly: result.ownedOnly, units: diet._planUnits(result.plan), cons};
}

const free = fit(Infinity);
check(free.value, 5000, 'with room to spare an adventure keeps its value');
check(free.over, false, 'and the plan is within budget');
assert.ok(free.units['fine food'] > 0 && free.toBuy > 100000, 'the unconstrained toy day buys the fine food');
cases++;
check(diet._planPurchaseCost(free.units, free.cons, none), free.toBuy, 'the cost is the units at their prices');

const tight = fit(free.toBuy - 1);
assert.ok(tight.value < 5000, 'over budget, the plan values an adventure lower');
assert.ok(tight.toBuy <= free.toBuy - 1 && !tight.over, 'and then fits the budget');
assert.ok(tight.toBuy > 0 && !tight.ownedOnly, 'a tight budget still buys the cheap adventures');
cases += 3;

// no room at all: only what is owned, at the full value of an adventure
const spareFood = (name) => (name == 'plain food' ? 2 : 0);
for (const room of [0, -50000]) {
  const broke = fit(room, null, spareFood);
  check(broke.toBuy, 0, 'no budget left: nothing is bought');
  check(broke.over, false, 'and that plan is allowed');
  check(broke.ownedOnly, true, 'it is made from owned copies only');
  check(broke.value, 5000, 'at the full value of an adventure');
  check(broke.units, {'plain food': 2}, 'it uses the spare copies and nothing else');
}
// a budget too small for any purchase worth making ends the same way
const crumbs = fit(100, null, spareFood);
check([crumbs.toBuy, crumbs.over, crumbs.ownedOnly, crumbs.value], [0, false, true, 5000], 'a budget nothing fits in buys nothing');

// spare copies owned are not purchases
const owned = fit(Infinity, null, (name) => (name == 'fine food' ? 2 : 0));
check(owned.toBuy, free.toBuy - 2 * 60000, 'copies already owned cost nothing');
const mixed = [{name: 'a', price: 100}, {name: 'b', price: 100, owned: true}, {name: 'c', price: 100, speakeasy: 1}, {name: 'd', price: 100}];
check(diet._planPurchaseCost({a: 3, b: 3, c: 3}, mixed, none), 300, 'owned-only and speakeasy entries are not purchases, nor unplanned ones');

// a refresh that takes an overpriced item off the list re-plans without it,
// and that alone does not lower the value of an adventure
let dropped = false;
const cons = market();
const capped = fit(Infinity, () => {
  if (dropped) return false;
  cons.splice(cons.findIndex((e) => e.name == 'spice melange'), 1);
  dropped = true;
  return true;
}, none, cons);
check(capped.value, 5000, 'a price change is not a budget squeeze');
check(capped.units['spice melange'], undefined, 'the dropped item is out of the plan');

// --- the two files agree on the default budget -------------------------------
const js = fs.readFileSync(path.join(__dirname, '../scripts/diet.js'), 'utf8');
const ash = fs.readFileSync(path.join(__dirname, '../scripts/smmDailyGate.ash'), 'utf8');
const jsBudget = /^var DIET_BUDGET = (\d+)$/m.exec(js);
const ashBudget = /^int kSmmDDietBudget = (\d+);$/m.exec(ash);
assert.ok(jsBudget && ashBudget, 'both defaults are declared');
check(jsBudget[1], ashBudget[1], 'diet.js and smmDailyGate.ash have the same default budget');

console.log(`PASS ${cases} diet spending checks`);
