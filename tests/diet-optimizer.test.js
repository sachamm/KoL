const test = require("node:test");
const assert = require("node:assert/strict");
const { solve } = require("../scripts/smmDietOptimizer.js");
const { plan } = require("../scripts/smmDietPlanner.js");
const integration = require("../scripts/diet.js");

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
