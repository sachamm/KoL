const test = require("node:test");
const assert = require("node:assert/strict");
const { solve } = require("../scripts/smmDietOptimizer.js");
const { plan } = require("../scripts/smmDietPlanner.js");
const integration = require("../scripts/diet.js");
const mechanics = require("../scripts/smmDietMechanics.js");
const fs = require("node:fs");
const vm = require("node:vm");
const { createRequire } = require("node:module");

function option(use, value) {
  return { use, value };
}
function settings(organs, extra) {
  return Object.assign(
    {
      "organ sizes": organs,
      "base organs": organs,
      "adventure value": 1,
      "ode available": false,
      "overdrink candidates": true,
      "rollover gain": 0,
      "excluded consumables": {},
    },
    extra,
  );
}
function item(name, size, adventures, price, extra) {
  return Object.assign(
    {
      name,
      size,
      advmin: adventures,
      advmax: adventures,
      price,
      type: size[0] > 0 ? "food" : size[1] > 0 ? "booze" : "spleen",
    },
    extra,
  );
}
function count(result, name) {
  return result.diet_items
    .filter((r) => r.name === name)
    .reduce((n, r) => n + r.amount, 0);
}

test("global allocation beats choosing the best single serving first", () => {
  const result = solve({
    capacity: [4],
    groups: [{ options: [option([3], 5)] }, { options: [option([2], 3.5)] }],
  });
  assert.equal(result.value, 7);
  assert.equal(result.use[0], 4);
});

test("bounded item variants share one inventory limit", () => {
  const result = solve({
    capacity: [4, 1],
    groups: [{ limit: 1, options: [option([1, 1], 10), option([2, 0], 8)] }],
  });
  assert.equal(result.value, 10);
  assert.equal(
    result.selections.reduce((n, s) => n + s.count, 0),
    1,
  );
});

test("unlimited variants may use different resources in combination", () => {
  const result = solve({
    capacity: [2, 2],
    groups: [{ options: [option([1, 0], 1), option([0, 1], 1)] }],
  });
  assert.equal(result.value, 4);
});

test("cleaning is worth buying only when the extra consumption pays for it", () => {
  const groups = [
    { options: [option([2, 0], 6)] },
    { limit: 1, options: [option([-1, -1], -2)] },
    { options: [option([0, 2], 5)] },
  ];
  const result = solve({ capacity: [1, 1], groups });
  assert.equal(result.value, 9);
  assert.deepEqual(result.use, [1, 1]);
  assert.equal(solve({ capacity: [0, 0], groups: [groups[1]] }).value, 0);
});

test("shared resource limits apply across different item groups", () => {
  const result = solve({
    capacity: [8, 2],
    groups: [
      { options: [option([1, 1], 9)] },
      { options: [option([2, 1], 10)] },
    ],
  });
  assert.equal(result.value, 20);
});

test("finite zero-organ rewards cannot be repeated beyond their limit", () => {
  const result = solve({
    capacity: [0],
    groups: [{ limit: 3, options: [option([0], 5)] }],
  });
  assert.equal(result.value, 15);
  assert.equal(result.selections[0].count, 3);
});

test("invalid and unbounded inputs fail before returning a plan", () => {
  for (const problem of [
    { capacity: [-1], groups: [] },
    { capacity: [1], groups: [{ options: [option([0], 1)] }] },
    { capacity: [1], groups: [{ options: [option([-1], 1)] }] },
    { capacity: [1], groups: [{ limit: 1, options: [option([0.5], 1)] }] },
    { capacity: [1], groups: [{ limit: 1, options: [option([1], NaN)] }] },
    { capacity: [1], groups: [{ limit: 1, options: [option([1, 1], 1)] }] },
  ])
    assert.throws(() => solve(problem));
});

test("search exhaustion throws instead of exposing a partial diet", () => {
  const p = { capacity: [5], groups: [{ options: [option([1], 1)] }] };
  assert.throws(() => solve({ ...p, maxStates: 1 }), /no partial plan/);
  assert.throws(() => solve({ ...p, maxTransitions: 1 }), /no partial plan/);
});

function brute(problem) {
  let best = 0;
  function group(index, use, value) {
    if (index === problem.groups.length) {
      if (use.every((n, i) => n <= problem.capacity[i]))
        best = Math.max(best, value);
      return;
    }
    const g = problem.groups[index];
    function units(left, used, total, first) {
      group(index + 1, used, total);
      if (!left) return;
      for (let j = first; j < g.options.length; j++) {
        const o = g.options[j];
        units(
          left - 1,
          used.map((n, i) => n + o.use[i]),
          total + o.value,
          j,
        );
      }
    }
    units(g.limit, use, value, 0);
  }
  group(
    0,
    problem.capacity.map(() => 0),
    0,
  );
  return best;
}

test("120 independently enumerated bounded allocation cases match exhaustive search", () => {
  let seed = 49021;
  function random(max) {
    seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
    return seed % max;
  }
  for (let n = 0; n < 120; n++) {
    const p = {
      capacity: [random(5), random(5)],
      groups: Array.from({ length: 4 }, () => ({
        limit: 1 + random(2),
        options: Array.from({ length: 2 }, () =>
          option([random(4) - 1, random(4) - 1], random(13) - 3),
        ),
      })),
    };
    const original = JSON.stringify(p);
    assert.equal(solve(p).value, brute(p), "allocation case " + n);
    assert.equal(JSON.stringify(p), original, "caller data was mutated");
  }
});

test("three-organ meal plan preserves limits, total cost and effect/PvP value", () => {
  const data = [
    item("food", [2, 0, 0], 6, 1),
    item("drink", [0, 1, 0], 3, 1),
    item("limited", [0, 0, 1], 0, 1, {
      limit: 1,
      pvpfights: 2,
      effectvalue: 5,
    }),
  ];
  const p = plan(data, settings([4, 2, 2], { "pvp fight value": 2 }), 0);
  assert.equal(count(p, "food"), 2);
  assert.equal(count(p, "drink"), 2);
  assert.equal(count(p, "limited"), 1);
  assert.equal(p.value, 22);
  assert.equal(
    p.diet_items.reduce((n, r) => n + r.price, 0),
    5,
  );
});

test("exclusions, zero limits, duplicate identities and invalid prices are enforced", () => {
  const x = item("x", [1, 0, 0], 10, 0);
  assert.equal(
    plan([x], settings([1, 0, 0], { "excluded consumables": { x: true } }))
      .value,
    0,
  );
  assert.equal(plan([{ ...x, limit: 0 }], settings([1, 0, 0])).value, 0);
  assert.throws(() => plan([x, x], settings([1, 0, 0])), /Duplicate/);
  assert.throws(
    () => plan([{ ...x, price: -1 }], settings([1, 0, 0])),
    /price/,
  );
});

test("speakeasy, Lucky and mime allowances are shared and can combine on one serving", () => {
  const data = [item("Lucky Lindy", [0, 1, 0], 1, 250, { speakeasy: 250 })];
  const p = plan(
    data,
    settings([0, 0, 0], {
      speakeasy: true,
      "speakeasy drinks left": 2,
      "semirares available": 1,
      "mime army shotglass available": true,
    }),
    1000,
  );
  assert.equal(count(p, "Lucky Lindy"), 1);
  assert.equal(p.diet_items[0].using_mime_shotglass, true);
  assert.equal(p.diet_items[0].resources.lucky, 1);
  assert.equal(p.value, 751);
});

test("passive bonuses, breakfast limit, and spell turn generation are explicit", () => {
  const data = [
    item("pasta", [2, 0, 0], 4, 0, { "item class": "saucy food" }),
    item("spaghetti breakfast", [1, 0, 0], 8, 0),
    { name: "blue mana", price: 1 },
  ];
  const p = plan(
    data,
    settings([3, 0, 0], {
      classid: 3,
      "saucemaven available": true,
      "gourmand available": true,
      "ancestral recall available": true,
      "ancestral recall casts left": 2,
    }),
  );
  assert.equal(count(p, "spaghetti breakfast"), 1);
  assert.equal(count(p, "pasta"), 1);
  assert.equal(count(p, "Ancestral Recall"), 2);
  assert.equal(p.value, 24);
});

test("integration retains four phases and respects shared quotas for the overdrink", () => {
  const data = [item("club drink", [0, 1, 0], 10, 0, { speakeasy: 1 })];
  const s = settings([0, 1, 0], {
    speakeasy: true,
    "speakeasy drinks left": 1,
  });
  integration._setData(data, 0);
  const p = integration.planDay(s, false);
  assert.equal(
    p.result.diet_items
      .filter((r) => r.name === "club drink")
      .reduce((n, r) => n + r.amount, 0),
    1,
  );
  assert.equal(p.overdrink, null);
  assert.equal(p.waste, 0);
});

test("cleaner rows and phase-two simple items survive the integration contract", () => {
  const data = [
    item("food", [2, 0, 0], 6, 0),
    item("cleaner", [-1, 0, 0], 0, 1, { type: "extender", limit: 1 }),
    item("tofu", [0, 0, 0], 5, 0, { type: "simple", limit: 1 }),
  ];
  integration._setData(data, 0);
  const p = integration.planDay(settings([1, 0, 0]), false);
  const tofu = p.result.diet_items.findIndex((r) => r.name === "tofu");
  const cleaner = p.result.diet_items.findIndex((r) => r.name === "cleaner");
  assert.equal(p.parts[tofu][2], 1);
  assert.equal(p.parts[cleaner][1], 1);
  assert.equal(p.value, 10);
});

test("large dominated catalogs stay bounded and do not mutate inputs", () => {
  const data = Array.from({ length: 500 }, (_, i) =>
    item("inferior " + i, [1, 0, 0], 1, 0),
  );
  data.push(item("best", [1, 0, 0], 2, 0));
  const original = JSON.stringify(data);
  const p = plan(data, settings([25, 0, 0]));
  assert.equal(count(p, "best"), 25);
  assert.ok(p.transitions < 1000);
  assert.equal(JSON.stringify(data), original);
});

function usesHelper(row, name) {
  return row.desc.extra.some((n) => n.item && n.item.name === name);
}
test("utensils are exclusive, the spork is daily, and unprofitable boosts are skipped", () => {
  const p = plan(
    [
      item("large salad", [1, 0, 0], 10, 0, {
        limit: 1,
        "item class": "salad",
      }),
      item("small meal", [1, 0, 0], 1, 0, { limit: 2 }),
      { name: "Ol' Scratch's salad fork", price: 0 },
      { name: "fudge spork", price: 0, limit: 3 },
    ],
    settings([3, 0, 0]),
  );
  assert.equal(p.value, 21);
  assert.equal(
    p.diet_items
      .filter((r) => usesHelper(r, "fudge spork"))
      .reduce((n, r) => n + r.amount, 0),
    1,
  );
  assert.ok(
    p.diet_items.every(
      (r) =>
        !(
          usesHelper(r, "fudge spork") &&
          usesHelper(r, "Ol' Scratch's salad fork")
        ),
    ),
  );
  const none = plan(
    [item("meal", [1, 0, 0], 2, 0), { name: "fudge spork", price: 5 }],
    settings([1, 0, 0]),
  );
  assert.equal(none.value, 2);
  assert.ok(!usesHelper(none.diet_items[0], "fudge spork"));
});

test("finite helper stock is shared by different item groups", () => {
  const data = [
    item("a", [1, 0, 0], 2, 0, { limit: 1 }),
    item("b", [1, 0, 0], 2, 0, { limit: 1 }),
    { name: "Special Seasoning", price: 0, limit: 1 },
  ];
  const original = JSON.stringify(data);
  const p = plan(data, settings([2, 0, 0]));
  assert.equal(p.value, 5);
  assert.equal(
    p.diet_items
      .filter((r) => usesHelper(r, "Special Seasoning"))
      .reduce((n, r) => n + r.amount, 0),
    1,
  );
  assert.equal(JSON.stringify(data), original);
});

test("integer-roll helper rounding and additive bonuses have explicit expectations", () => {
  assert.equal(
    mechanics.adventures(
      item("salad", [2, 0, 0], 10, 0, { "item class": "salad" }),
      {},
      { fork: true, seasoning: true, munchies: true },
    ),
    18,
  );
  assert.equal(
    mechanics.adventures(
      item("taco", [2, 0, 0], 10, 0, { "item class": "taco" }),
      {},
      { fork: true, taco: true },
    ),
    14,
  );
  assert.equal(
    mechanics.adventures(
      item("beer", [0, 2, 0], 10, 0, { "item class": "beer" }),
      {},
      { mug: true, salty: true },
    ),
    22,
  );
  assert.equal(
    mechanics.adventures(
      item("wine", [0, 2, 0], 10, 0, { "item class": "wine" }),
      { "mafia pinky ring available": true },
      { mug: true, palate: true },
    ),
    19,
  );
  assert.equal(
    mechanics.adventures(
      item("small", [1, 0, 0], 0, 0),
      {},
      { fork: true, munchies: true, mayoflex: true },
    ),
    0,
  );
  assert.equal(
    mechanics.adventures(
      item("range", [1, 0, 0], 4, 0, { advmax: 7 }),
      {},
      { munchies: true },
    ),
    7.25,
  );
});

test("Gar-ish is a single activation cost and never a stand-alone purchase", () => {
  const data = [
    item("lasagna", [2, 0, 0], 10, 1, { "item class": "lasagna" }),
    { name: "potion of the field gar", price: 5 },
  ];
  const p = plan(
    data,
    settings([4, 0, 0], { "use potion of the field gar": "yes" }),
  );
  assert.equal(p.value, 23);
  assert.equal(count(p, "potion of the field gar"), 1);
  assert.equal(p.diet_items.find((r) => r.name === "lasagna").turns, 30);
  assert.equal(
    plan(data, settings([1, 0, 0], { "use potion of the field gar": "yes" }))
      .value,
    0,
  );
  assert.equal(
    plan(
      data,
      settings([4, 0, 0], {
        "use potion of the field gar": "no",
        "Gar-ish active": true,
      }),
    ).value,
    18,
  );
});

test("Refined Palate shares one wish across wines and competes with salty wishes for stock", () => {
  const data = [
    item("wine", [0, 1, 0], 10, 0, { "item class": "wine" }),
    { name: "pocket wish", price: 3, limit: 1 },
  ];
  const p = plan(
    data,
    settings([0, 2, 0], { "mafia pinky ring available": true }),
  );
  assert.equal(p.value, 25);
  assert.equal(count(p, "pocket wish"), 1);
  const mixed = plan(
    data.concat([
      item("beer", [0, 1, 0], 1, 0, { "item class": "beer", limit: 1 }),
    ]),
    settings([0, 3, 0]),
  );
  const spent = mixed.diet_items.reduce(
    (n, r) => n + (r.resources["stock:pocket wish"] || 0) * r.amount,
    0,
  );
  assert.ok(spent <= 1);
});

test("an existing Salty Mouth boosts only the next beer", () => {
  const p = plan(
    [item("beer", [0, 1, 0], 2, 0, { "item class": "beer" })],
    settings([0, 2, 0], { "Salty Mouth active": true }),
  );
  assert.equal(p.value, 9);
  assert.equal(
    p.diet_items.reduce(
      (n, r) => n + (r.resources["salty active"] || 0) * r.amount,
      0,
    ),
    1,
  );
});

test("Mayodiol trades stomach for liver and cannot combine with Mayoflex", () => {
  const data = [
    item("meal", [2, 0, 0], 10, 0),
    { name: "Mayodiol", price: 1 },
    { name: "Mayoflex", price: 1 },
  ];
  const p = plan(data, settings([1, 1, 0], { workshed: "mayo" }));
  assert.equal(p.value, 9);
  assert.deepEqual(p.diet_items[0].spec.size, [1, 1, 0]);
  assert.ok(usesHelper(p.diet_items[0], "Mayodiol"));
  assert.ok(!usesHelper(p.diet_items[0], "Mayoflex"));
  assert.equal(plan(data, settings([1, 1, 0])).value, 0);
});

test("chocolate tiers share counters, respect stock and preserve separate pools", () => {
  const p = plan(
    [
      { name: "fancy chocolate", price: 0, limit: 1 },
      { name: "chocolate seal-clubbing club", price: 0 },
      { name: "chocolate cigar", price: 0 },
      { name: "vitachoconutriment capsule", price: 0 },
      { name: "fancy chocolate sculpture", price: 0 },
    ],
    settings([0, 0, 0], {
      classid: 1,
      "chocolates used": { fancy: 0, cigar: 1, vitachoc: 2, sculpture: 3 },
    }),
  );
  assert.equal(p.value, 13); // fancy 5+2+1, cigar 3+1, vitachoc 1.
  assert.equal(count(p, "fancy chocolate"), 1);
  assert.equal(count(p, "chocolate seal-clubbing club"), 2);
  assert.equal(count(p, "chocolate cigar"), 2);
  assert.equal(count(p, "fancy chocolate sculpture"), 0);
  assert.equal(
    plan(
      [{ name: "chocolate turtle totem", price: 0 }],
      settings([0, 0, 0], { classid: 1 }),
    ).value,
    3,
  );
});

test("unlimited spleen-cleaning food has a finite stomach/liver bound", () => {
  const p = plan(
    [item("cleaning food", [2, 0, -2], 4, 0), item("spleen", [0, 0, 1], 3, 0)],
    settings([2, 0, 1]),
  );
  assert.equal(p.value, 13);
  assert.equal(count(p, "cleaning food"), 1);
  assert.equal(count(p, "spleen"), 3);
});

test("a mixed catalog with all helper types completes within the default budget", () => {
  const data = [];
  for (let i = 0; i < 60; i++) {
    data.push(
      item(
        "food " + i,
        [1 + (i % 5), 0, i % 11 === 0 ? -3 : 0],
        2 + (i % 19),
        100 + i * 37,
        {
          advmax: 5 + (i % 19),
          "item class": ["salad", "lasagna", "pizza", "taco", "saucy food"][
            i % 5
          ],
        },
      ),
    );
    data.push(
      item(
        "drink " + i,
        [0, 1 + (i % 5), i % 11 === 0 ? -3 : 0],
        2 + (i % 19),
        100 + i * 37,
        { advmax: 5 + (i % 19), "item class": i % 2 ? "wine" : "beer" },
      ),
    );
  }
  for (const name of [
    "Ol' Scratch's salad fork",
    "fudge spork",
    "munchies pill",
    "Frosty's frosty mug",
    "BGE shotglass",
    "potion of the field gar",
    "pocket wish",
    "Taco Dan's Super Taco-Riffic Taco Sauce!",
    "Special Seasoning",
    "Mayoflex",
    "Mayodiol",
    "fancy chocolate",
    "chocolate cigar",
  ])
    data.push({ name, price: 500 });
  data.push(item("spleen", [0, 0, 1], 2, 100, { advmax: 3 }));
  const p = plan(
    data,
    settings([20, 20, 15], {
      "adventure value": 5000,
      workshed: "mayo",
      "use potion of the field gar": "yes",
      "mime army shotglass available": true,
    }),
  );
  assert.equal(p.complete, true);
  assert.ok(p.value > 0);
  const summed = p.diet_items.reduce((sum, r) => sum + r.value, 0);
  assert.equal(p.value, summed);
});

// Execute the retained integration against a tiny in-memory game. No runtime
// import, account, network connection or game action is involved.
function offlineGame(data, organs, options = {}) {
  const calls = [],
    messages = [],
    current = [0, 0, 0],
    effects = {};
  let adventures = 0,
    chocolateUsed = 0,
    mimeUsed = false;
  const get = (name) => ({
    name,
    toString() {
      return name;
    },
  });
  function consume(name) {
    const record = data.find((x) => x.name === name) || {};
    const size = (record.size || [0, 0, 0]).slice();
    if (options.mime && !mimeUsed && record.type === "booze" && size[1] === 1) {
      size[1] = 0;
      mimeUsed = true;
    }
    if (current.some((n, i) => n + size[i] > organs[i])) return false;
    size.forEach((n, i) => {
      current[i] += n;
    });
    const chocolate = mechanics.chocolate(name, 1);
    if (chocolate) adventures += chocolate.turns[chocolateUsed++] || 0;
    if (record.type === "booze") effects["Salty Mouth"] = 0;
    calls.push(name);
    return true;
  }
  const km = {
    Item: { get },
    Effect: { get },
    Skill: { get },
    availableAmount: () => 100,
    isDisplayable: () => false,
    retrieveItem: () => true,
    myAdventures: () => adventures,
    myMeat: () => 100000,
    myFullness: () => current[0],
    myInebriety: () => current[1],
    mySpleenUse: () => current[2],
    fullnessLimit: () => organs[0],
    inebrietyLimit: () => organs[1],
    spleenLimit: () => organs[2],
    myFamiliar: () => get("none"),
    haveSkill: () => false,
    haveEffect: (e) => effects[e.name] || 0,
    userConfirm: () => true,
    print: (s) => messages.push(s),
    cliExecute: (s) => {
      if (s.startsWith("genie effect ")) {
        effects[s.slice(13)] = 1;
        calls.push(s);
      }
      return true;
    },
    use: (n, it) => (it.name === options.failHelper ? false : consume(it.name)),
    eatsilent: (n, it) => consume(it.name),
    drinksilent: (n, it) => consume(it.name),
    chew: (n, it) => consume(it.name),
  };
  const filename = require.resolve("../scripts/diet.js");
  const localRequire = createRequire(filename);
  const context = vm.createContext({
    module: { exports: {} },
    require: (name) => (name === "kolmafia" ? km : localRequire(name)),
  });
  vm.runInContext(
    fs.readFileSync(filename, "utf8") +
      "\nmodule.exports.offlineExecute = executePlan;",
    context,
    { filename },
  );
  return {
    calls,
    messages,
    current,
    get adventures() {
      return adventures;
    },
    execute(result, s, phase) {
      context.module.exports._setData(data, 0);
      context.module.exports.offlineExecute(
        result,
        s,
        integration.splitPhases(result, s),
        phase,
      );
    },
  };
}

test("execution consumes chocolate tiers in counter order across item names", () => {
  const data = [
    { name: "fancy chocolate", price: 0, limit: 1 },
    { name: "chocolate seal-clubbing club", price: 0 },
  ];
  const s = settings([0, 0, 0], { classid: 1 });
  const p = plan(data, s),
    game = offlineGame(data, s["organ sizes"]);
  game.execute(p, s, 2);
  assert.deepEqual(game.calls, [
    "fancy chocolate",
    "chocolate seal-clubbing club",
    "chocolate seal-clubbing club",
  ]);
  assert.equal(
    game.adventures,
    p.diet_items.reduce((n, r) => n + r.turns, 0),
  );
});

test("execution uses the mime serving before other drinks and budgets each salty wish", () => {
  const data = [
    item("a large drink", [0, 2, 0], 10, 0),
    item("z small drink", [0, 1, 0], 2, 0),
  ];
  const s = settings([0, 2, 0], { "mime army shotglass available": true });
  const game = offlineGame(data, s["organ sizes"], { mime: true });
  game.execute(plan(data, s), s, 1);
  assert.deepEqual(game.calls, ["z small drink", "a large drink"]);
  assert.equal(game.current[1], 2);
  const beer = [
    item("beer", [0, 1, 0], 1, 0, { "item class": "beer" }),
    { name: "pocket wish", price: 0 },
  ];
  const wishes = offlineGame(beer, s["organ sizes"]);
  const plain = settings([0, 2, 0]);
  wishes.execute(plan(beer, plain), plain, 1);
  assert.equal(
    wishes.calls.filter((c) => c === "genie effect Salty Mouth").length,
    2,
  );
});

test("a failed consumption helper stops before eating the boosted food", () => {
  const data = [
    item("meal", [1, 0, 0], 2, 0),
    { name: "fudge spork", price: 0 },
  ];
  const s = settings([1, 0, 0]),
    game = offlineGame(data, s["organ sizes"], { failHelper: "fudge spork" });
  game.execute(plan(data, s), s, 1);
  assert.equal(game.calls.length, 0);
  assert.ok(
    game.messages.some((m) => m.includes("helper failed: fudge spork")),
  );
});
