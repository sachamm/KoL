// Copyright 2026 Sacha Mallais. Repository license: CC BY 4.0.
// Convert this project's live consumable records into an explicit resource
// problem. Game facts are documented in docs/diet-optimizer.md.
var solve = require("./smmDietOptimizer.js").solve;

function positiveFlag(value) {
  return value === true || value === "yes";
}
function number(value, fallback) {
  return value === undefined ? fallback : Number(value);
}
function bankersRound(value) {
  var lower = Math.floor(value),
    fraction = value - lower;
  return fraction === 0.5 ? lower + (lower % 2) : Math.round(value);
}
function meanRoll(low, high, transform) {
  if (
    !Number.isFinite(low) ||
    !Number.isFinite(high) ||
    high < low ||
    high - low > 10000
  )
    throw new Error("Invalid adventure range");
  if (!Number.isInteger(low) || !Number.isInteger(high))
    return transform((low + high) / 2);
  var total = 0;
  for (var roll = low; roll <= high; roll++) total += transform(roll);
  return total / (high - low + 1);
}

function plan(consumables, settings, fortuneValue) {
  var advValue = number(settings["adventure value"], 5000);
  var pvpValue = number(settings["pvp fight value"], 0);
  if (!Number.isFinite(advValue) || !Number.isFinite(pvpValue))
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
        opts: meal.fortune ? { fortune: true } : {},
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
  function option(item, size, adventures, price, notes, shared, mime, fortune) {
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
      },
    };
  }

  consumables.forEach(function (input) {
    if (excluded[input.name] || !input.type || input.limit === 0) return;
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
    var low = number(item.advmin, 0),
      high = number(item.advmax, low);
    var notes = [],
      shared = {};
    if (item.speakeasy) shared.speakeasy = 1;
    var adventures =
      meanRoll(low, high, function (roll) {
        var bonus = 0;
        if (item.type === "food" && roll > 0) {
          if (positiveFlag(settings["gourmand available"])) bonus += size[0];
          if (
            item["item class"] === "saucy food" &&
            positiveFlag(settings["saucemaven available"])
          )
            bonus += settings.classid === 3 || settings.classid === 4 ? 5 : 3;
          if (
            item["item class"] === "pizza" &&
            positiveFlag(settings["pizza lover available"])
          )
            bonus += size[0];
        }
        if (item.type === "booze" && roll > 0) {
          if (settings["ode available"] !== false)
            bonus += Math.max(0, size[1]);
          if (
            item["tuxedo boostable drink"] === "yes" &&
            positiveFlag(settings["tuxedo shirt available"])
          )
            bonus += 2;
          if (
            item["item class"] === "wine" &&
            positiveFlag(settings["mafia pinky ring available"])
          )
            bonus += bankersRound(roll / 8);
        }
        return roll + bonus;
      }) + number(item.bonusadv, 0);
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
    var choices = [
      option(item, size, adventures, price, notes, shared, false, false),
    ];
    if (item.type === "booze" && size[1] === 1 && quotas.mime) {
      var mimeNotes = notes.concat([
        {
          type: "item",
          verb: "using",
          item: { name: "mime army shotglass" },
          exclude: false,
        },
      ]);
      choices.push(
        option(
          item,
          size,
          adventures -
            (settings["ode available"] === false || high <= 0 ? 0 : 1),
          price,
          mimeNotes,
          Object.assign({}, shared, { mime: 1 }),
          true,
          false,
        ),
      );
    }
    if (item.name === "Lucky Lindy" && quotas.lucky) {
      // Only the selected quota of Lucky effects receives economic credit.
      choices.push(
        option(
          item,
          size,
          adventures,
          price,
          notes.concat([{ type: "text", text: "Lucky!" }]),
          Object.assign({}, shared, { lucky: 1 }),
          false,
          true,
        ),
      );
      if (size[1] === 1 && quotas.mime)
        choices.push(
          option(
            item,
            size,
            adventures -
              (settings["ode available"] === false || high <= 0 ? 0 : 1),
            price,
            notes.concat([
              { type: "text", text: "Lucky!" },
              {
                type: "item",
                verb: "using",
                item: { name: "mime army shotglass" },
                exclude: false,
              },
            ]),
            Object.assign({}, shared, { lucky: 1, mime: 1 }),
            true,
            true,
          ),
        );
    }
    groups.push({ limit: limit, options: choices });
    if (
      item.type === "booze" &&
      size[1] > 0 &&
      positiveFlag(settings["overdrink candidates"])
    ) {
      // Organ-cleaning benefits do not apply after useful adventuring ends.
      var nightItem = Object.assign({}, item, {
        bonusvalue: 0,
        effectvalue: 0,
      });
      drinks.push(
        row(
          option(
            nightItem,
            size,
            adventures,
            price,
            notes,
            shared,
            false,
            false,
          ),
          1,
          true,
        ),
      );
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
  warnings.push(
    "Optional consumable-helper and chocolate purchases are not modeled; only explicit item statistics and validated passive bonuses are used.",
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
