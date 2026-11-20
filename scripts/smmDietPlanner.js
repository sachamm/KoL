// Copyright 2026 Sacha Mallais. Repository license: CC BY 4.0.
// Convert this project's live consumable records into an explicit resource
// problem. Game facts are documented in docs/diet-optimizer.md.
var solve = require("./smmDietOptimizer.js").solve;
var mechanics = require("./smmDietMechanics.js");

function positiveFlag(value) {
  return value === true || value === "yes";
}
function number(value, fallback) {
  return value === undefined ? fallback : Number(value);
}

function plan(consumables, settings, fortuneValue, enabledEffects) {
  if (enabledEffects === undefined) {
    // There are only two persistent boosts. Compare their four activation
    // scenarios instead of adding a large counter dimension to every DP state.
    var scenarios = [{}];
    [
      [
        "Gar-ish",
        "potion of the field gar",
        positiveFlag(settings["use potion of the field gar"]),
      ],
      ["Refined Palate", "pocket wish", true],
    ].forEach(function (entry) {
      if (
        !entry[2] ||
        positiveFlag(settings[entry[0] + " active"]) ||
        !consumables.some(function (x) {
          return (
            x.name === entry[1] &&
            x.price !== undefined &&
            x.limit !== 0 &&
            !(settings["excluded consumables"] || {})[x.name]
          );
        })
      )
        return;
      scenarios = scenarios.concat(
        scenarios.map(function (s) {
          var extra = Object.assign({}, s);
          extra[entry[0]] = true;
          return extra;
        }),
      );
    });
    var best;
    scenarios.forEach(function (scenario) {
      var candidate = plan(consumables, settings, fortuneValue, scenario);
      if (!best || candidate.value > best.value) best = candidate;
    });
    return best;
  }
  var advValue = number(settings["adventure value"], 5000);
  var pvpValue = number(settings["pvp fight value"], 0);
  if (
    !Number.isFinite(advValue) ||
    !Number.isFinite(pvpValue) ||
    advValue < 0 ||
    pvpValue < 0
  )
    throw new Error("Invalid economic value");
  var organs = (settings["organ sizes"] || [0, 0, 0]).slice();
  if (organs.length !== 3) throw new Error("Expected three organ capacities");
  var allowance = ["speakeasy", "lucky", "mime"];
  var quotas = {
    speakeasy: positiveFlag(settings.speakeasy)
      ? number(settings["speakeasy drinks left"], 3)
      : 0,
    lucky: number(settings["semirares available"], 0),
    mime: positiveFlag(settings["mime army shotglass available"]) ? 1 : 0,
  };
  var excluded = settings["excluded consumables"] || {};
  var groups = [],
    drinks = [],
    named = Object.create(null);
  var warnings = [];
  var catalog = Object.create(null);
  consumables.forEach(function (item) {
    if (catalog[item.name])
      throw new Error("Duplicate consumable: " + item.name);
    catalog[item.name] = item;
    // Finite helper stock is shared by every food/drink variant and chocolate tier.
    if (
      (!item.type || mechanics.chocolate(item.name, settings.classid)) &&
      item.limit !== undefined
    ) {
      var key = "stock:" + item.name;
      allowance.push(key);
      quotas[key] = Number(item.limit);
    }
  });
  allowance.push("spork");
  quotas.spork = Math.max(0, number(settings["fudge spork uses left"], 1));
  allowance.push("salty active");
  quotas["salty active"] = positiveFlag(settings["Salty Mouth active"]) ? 1 : 0;
  function helper(name) {
    var item = catalog[name];
    if (!item || excluded[name] || item.limit === 0 || item.price === undefined)
      return null;
    if (!Number.isFinite(Number(item.price)) || Number(item.price) < 0)
      throw new Error("Invalid price for " + name);
    return item;
  }
  function stock(shared, item) {
    var key = "stock:" + item.name;
    if (quotas[key] !== undefined) shared[key] = (shared[key] || 0) + 1;
  }
  var effectSources = {
    "Gar-ish": {
      name: "potion of the field gar",
      enabled: positiveFlag(settings["use potion of the field gar"]),
      option: "gar",
    },
    "Refined Palate": {
      name: "pocket wish",
      enabled: true,
      option: "palate",
      wish: true,
    },
  };
  Object.keys(effectSources).forEach(function (name) {
    var source = effectSources[name];
    source.active = positiveFlag(settings[name + " active"]);
    source.item = source.enabled ? helper(source.name) : null;
    source.usable =
      source.enabled &&
      (source.active || (source.item && enabledEffects[name]));
    source.reserve = source.usable && !source.active;
    if (source.reserve && source.item.limit !== undefined)
      quotas["stock:" + source.name]--;
  });

  function vector(size, shared) {
    return size.concat(
      allowance.map(function (name) {
        return shared[name] || 0;
      }),
    );
  }
  function row(option, quantity, nightcap) {
    var meal = option.meal;
    return {
      name: meal.item.name,
      amount: quantity,
      turns: meal.adventures * quantity,
      fights: meal.fights * quantity,
      price: meal.price * quantity,
      value: option.value * quantity,
      is_nightcap: !!nightcap,
      using_mime_shotglass: !!meal.mime,
      resources: Object.assign({}, meal.shared),
      spec: {
        item: meal.item,
        size: meal.size.slice(),
        adv: meal.adventures,
        opts: Object.assign(
          {},
          meal.opts,
          meal.fortune ? { fortune: true } : {},
        ),
        wishes: Object.assign({}, meal.wishes),
      },
      desc: {
        amount: quantity + "x",
        turns: String(meal.adventures * quantity),
        price: String(Math.round(meal.price)),
        name: meal.item.name,
        extra: meal.notes.slice(),
        notes: meal.item.specialprice || "",
      },
    };
  }
  function option(
    item,
    size,
    adventures,
    price,
    notes,
    shared,
    mime,
    fortune,
    opts,
    wishes,
  ) {
    var effectiveSize = size.slice();
    if (mime) effectiveSize[1]--;
    var fights = number(item.pvpfights, 0);
    var reward = number(item.bonusvalue, 0) + number(item.effectvalue, 0);
    if (fortune) reward += number(fortuneValue, 0);
    return {
      use: vector(effectiveSize, shared),
      value: adventures * advValue + fights * pvpValue + reward - price,
      meal: {
        item: item,
        size: size,
        adventures: adventures,
        fights: fights,
        price: price,
        notes: notes,
        shared: shared,
        mime: mime,
        fortune: fortune,
        opts: opts || {},
        wishes: wishes || {},
      },
    };
  }

  function variants(item, price, baseNotes, baseShared, nightcap) {
    var sets = [],
      kind = item["item class"];
    function choices(entries) {
      sets.push([null].concat(entries));
    }
    function boost(key, name) {
      var h = helper(name);
      return h ? { key: key, helper: h } : null;
    }
    function add(entries) {
      choices(entries.filter(Boolean));
    }
    if (Number(item.advmax === undefined ? item.advmin : item.advmax) > 0) {
      if (item.type === "food" && item.size[0] > 0) {
        add([
          boost("fork", "Ol' Scratch's salad fork"),
          quotas.spork ? boost("spork", "fudge spork") : null,
        ]);
        add([boost("munchies", "munchies pill")]);
        add([boost("seasoning", "Special Seasoning")]);
        if (kind === "taco")
          add([boost("taco", "Taco Dan's Super Taco-Riffic Taco Sauce!")]);
        if (settings.workshed === "mayo")
          add([boost("mayoflex", "Mayoflex"), boost("mayodiol", "Mayodiol")]);
        if (kind === "lasagna" && effectSources["Gar-ish"].usable)
          choices([{ key: "gar", effect: "Gar-ish" }]);
      }
      if (item.type === "booze") {
        // Speakeasy drinks cannot have a queued physical drink helper.
        if (!item.speakeasy)
          add([
            boost("mug", "Frosty's frosty mug"),
            boost("bge", "BGE shotglass"),
          ]);
        if (
          kind === "wine" &&
          (effectSources["Refined Palate"].usable ||
            (nightcap && effectSources["Refined Palate"].item))
        )
          choices([{ key: "palate", effect: "Refined Palate" }]);
        if (kind === "beer") {
          var salt = [];
          if (quotas["salty active"])
            salt.push({ key: "salty", effect: "Salty Mouth", active: true });
          if (helper("pocket wish"))
            salt.push({
              key: "salty",
              effect: "Salty Mouth",
              helper: helper("pocket wish"),
              wish: true,
            });
          choices(salt);
        }
      }
    }
    var result = [];
    function visit(index, chosen) {
      if (index < sets.length) {
        sets[index].forEach(function (entry) {
          visit(index + 1, entry ? chosen.concat([entry]) : chosen);
        });
        return;
      }
      var b = {},
        notes = baseNotes.slice(),
        shared = Object.assign({}, baseShared),
        opts = {},
        wishes = {},
        cost = price;
      var size = item.size.slice();
      chosen.forEach(function (entry) {
        b[entry.key] = true;
        if (entry.helper) {
          cost += Number(entry.helper.price);
          stock(shared, entry.helper);
          if (!entry.effect)
            notes.push({
              type: "item",
              verb: "using",
              item: { name: entry.helper.name },
              exclude: true,
            });
        }
        if (entry.key === "spork") shared.spork = 1;
        if (entry.active) shared["salty active"] = 1;
        if (entry.key === "mayodiol") {
          size[0]--;
          size[1]++;
        }
        if (entry.effect) {
          notes.push({ type: "effect", verb: "with", effect: entry.effect });
          if (entry.wish) wishes[entry.effect] = 1;
          var source = effectSources[entry.effect];
          if (source && !source.active) {
            if (nightcap) {
              cost += Number(source.item.price);
              stock(shared, source.item);
              if (source.wish) wishes[entry.effect] = 1;
            }
          }
        }
      });
      result.push({
        boosts: b,
        size: size,
        price: cost,
        notes: notes,
        shared: shared,
        opts: opts,
        wishes: wishes,
      });
    }
    visit(0, []);
    return result;
  }
  function bestByResources(choices) {
    var best = new Map();
    choices.forEach(function (choice) {
      var key = choice.use.join(","),
        previous = best.get(key);
      if (!previous || choice.value > previous.value) best.set(key, choice);
    });
    return Array.from(best.values());
  }

  consumables.forEach(function (input) {
    if (
      excluded[input.name] ||
      !input.type ||
      input.limit === 0 ||
      mechanics.chocolate(input.name, settings.classid)
    )
      return;
    if (named[input.name])
      throw new Error("Duplicate consumable: " + input.name);
    named[input.name] = true;
    var item = Object.assign({}, input);
    var limit = item.limit === undefined ? undefined : Number(item.limit);
    var price = item.price;
    if (item.speakeasy) {
      if (!quotas.speakeasy) return;
      price = item.speakeasy;
    }
    if (
      item.name === "spaghetti breakfast" &&
      positiveFlag(settings["spaghetti breakfast available"]) &&
      price === undefined
    ) {
      price = 5;
      limit = 1;
    }
    if (
      item.name === "Cold One" &&
      positiveFlag(settings["grab a cold one available"]) &&
      price === undefined
    ) {
      price = 5;
      limit = 1;
    }
    if (item.name === "spaghetti breakfast")
      limit = Math.min(limit === undefined ? 1 : limit, 1);
    if (limit !== undefined) item.limit = limit;
    if (price === undefined) return;
    price = Number(price);
    if (!Number.isFinite(price) || price < 0)
      throw new Error("Invalid price for " + item.name);
    var size = (item.size || [0, 0, 0]).slice();
    if (size.length !== 3)
      throw new Error("Invalid organ size for " + item.name);
    item.size = size;
    var notes = [],
      shared = {};
    if (item.speakeasy) shared.speakeasy = 1;
    if (
      item["tuxedo boostable drink"] === "yes" &&
      positiveFlag(settings["tuxedo shirt available"])
    )
      notes.push({
        type: "item",
        verb: "wearing",
        item: { name: "tuxedo shirt" },
        exclude: false,
      });
    if (
      item["item class"] === "wine" &&
      positiveFlag(settings["mafia pinky ring available"])
    )
      notes.push({
        type: "item",
        verb: "wearing",
        item: { name: "mafia pinky ring" },
        exclude: false,
      });
    var choices = [];
    variants(item, price, notes, shared, false).forEach(function (variant) {
      var mimes =
        item.type === "booze" && size[1] === 1 && quotas.mime
          ? [false, true]
          : [false];
      var fortunes =
        item.name === "Lucky Lindy" && quotas.lucky ? [false, true] : [false];
      mimes.forEach(function (mime) {
        fortunes.forEach(function (fortune) {
          var use = Object.assign({}, variant.shared),
            extra = variant.notes.slice();
          if (mime) {
            use.mime = 1;
            extra.push({
              type: "item",
              verb: "using",
              item: { name: "mime army shotglass" },
              exclude: false,
            });
          }
          if (fortune) {
            use.lucky = 1;
            extra.push({ type: "text", text: "Lucky!" });
          }
          choices.push(
            option(
              item,
              variant.size,
              mechanics.adventures(item, settings, variant.boosts, mime),
              variant.price,
              extra,
              use,
              mime,
              fortune,
              variant.opts,
              variant.wishes,
            ),
          );
        });
      });
    });
    var groupLimit = limit;
    if (
      groupLimit === undefined &&
      choices.some(function (o) {
        return o.use.some(function (n) {
          return n < 0;
        });
      })
    ) {
      // Unlimited spleen-cleaning food/drink still consumes the finite combined
      // stomach/liver budget. Derive a bound rather than rejecting those items.
      var anchor = organs[0] + organs[1] + quotas.mime;
      consumables.forEach(function (other) {
        if (!other.size) return;
        var net = other.size[0] + other.size[1];
        if (net < 0) {
          if (other.limit === undefined)
            throw new Error("Unbounded organ-cleaning cycle is not supported");
          anchor += -net * other.limit;
        }
      });
      var least = Math.min.apply(
        null,
        choices.map(function (o) {
          return o.use[0] + o.use[1] + o.use[3 + allowance.indexOf("mime")];
        }),
      );
      if (least <= 0)
        throw new Error("Organ cleaning has no finite stomach/liver bound");
      groupLimit = Math.floor(anchor / least);
    }
    groups.push({ limit: groupLimit, options: bestByResources(choices) });
    if (
      item.type === "booze" &&
      size[1] > 0 &&
      positiveFlag(settings["overdrink candidates"])
    ) {
      var nightItem = Object.assign({}, item, {
        bonusvalue: 0,
        effectvalue: 0,
      });
      var nightChoices = variants(nightItem, price, notes, shared, true).map(
        function (v) {
          return option(
            nightItem,
            v.size,
            mechanics.adventures(nightItem, settings, v.boosts, false),
            v.price,
            v.notes,
            v.shared,
            false,
            false,
            v.opts,
            v.wishes,
          );
        },
      );
      bestByResources(nightChoices).forEach(function (choice) {
        drinks.push(row(choice, 1, true));
      });
    }
  });

  if (
    positiveFlag(settings["ancestral recall available"]) &&
    !excluded["Ancestral Recall"]
  ) {
    var mana = consumables.find(function (item) {
      return (
        item.name === "blue mana" &&
        !excluded[item.name] &&
        item.price !== undefined
      );
    });
    if (mana) {
      var casts = number(settings["ancestral recall casts left"], 0);
      if (mana.limit !== undefined) casts = Math.min(casts, mana.limit);
      var recall = {
        name: "Ancestral Recall",
        type: "simple",
        size: [0, 0, 0],
        limit: casts,
      };
      groups.push({
        limit: casts,
        options: [
          option(
            recall,
            recall.size,
            3,
            Number(mana.price),
            [{ type: "text", text: "requires blue mana" }],
            {},
            false,
            false,
          ),
        ],
      });
    }
  }
  var counters = settings["chocolates used"] || {};
  ["fancy", "vitachoc", "cigar", "sculpture"].forEach(function (counter) {
    var used = number(counters[counter], 0);
    if (!Number.isInteger(used) || used < 0)
      throw new Error("Invalid chocolate counter");
    for (var tier = used; tier < 3; tier++) {
      var chocolates = [];
      consumables.forEach(function (item) {
        var rule = mechanics.chocolate(item.name, settings.classid);
        if (!rule || rule.counter !== counter || !helper(item.name)) return;
        var use = {};
        stock(use, item);
        var candy = Object.assign({}, item, {
          type: "simple",
          size: [0, 0, 0],
        });
        chocolates.push(
          option(
            candy,
            candy.size,
            rule.turns[tier],
            Number(item.price),
            [{ type: "text", text: "chocolate serving " + (tier + 1) }],
            use,
            false,
            false,
            { chocolate_tier: tier, chocolate_counter: counter },
          ),
        );
      });
      if (chocolates.length)
        groups.push({ limit: 1, options: bestByResources(chocolates) });
    }
  });
  if (helper("temporary X tattoos"))
    warnings.push(
      "Straight-Edgy rollover benefits from temporary X tattoos are not modeled.",
    );
  var solution = solve({
    capacity: organs.concat(
      allowance.map(function (name) {
        return quotas[name];
      }),
    ),
    groups: groups,
    maxStates: settings["search states"],
    maxTransitions: settings["search transitions"],
  });
  var rows = solution.selections.map(function (selection) {
    return row(selection.option, selection.count, false);
  });
  Object.keys(effectSources).forEach(function (name) {
    var source = effectSources[name];
    if (!source.reserve) return;
    var used = rows.some(function (r) {
      return r.desc.extra.some(function (n) {
        return n.effect === name;
      });
    });
    if (source.item.limit !== undefined) quotas["stock:" + source.name]++;
    if (!used) return;
    var shared = {},
      opts = {};
    stock(shared, source.item);
    if (source.wish) opts.wish_refined_palate = true;
    var activation = {
      name: source.name,
      type: "activation",
      size: [0, 0, 0],
      limit: 1,
    };
    var charge = option(
      activation,
      activation.size,
      0,
      Number(source.item.price),
      [],
      shared,
      false,
      false,
      opts,
    );
    rows.push(row(charge, 1, false));
    solution.value += charge.value;
  });
  rows.sort(function (a, b) {
    return (
      a.name.localeCompare(b.name) ||
      Number(a.using_mime_shotglass) - Number(b.using_mime_shotglass)
    );
  });
  return {
    diet_items: rows,
    value: solution.value,
    overdrinks: drinks,
    resource_limits: quotas,
    complete: solution.complete,
    transitions: solution.transitions,
    warnings: warnings,
  };
}

module.exports = { plan: plan };
