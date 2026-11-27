"use strict";

// Cooperative instrumentation of garbo's CommonJS kolmafia import, not a
// sandbox. Never mutate Mafia's sealed native exports or fall back to raw garbo.
function integer(value) {
  return typeof value === "number" && isFinite(value) && Math.floor(value) === value && Math.abs(value) <= 2147483647;
}

function automaticBuyLimit(configured) {
  const match = typeof configured === "string" && /^(-?)([0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE]([+-]?[0-9]+))?$/.exec(configured);
  if (!match) throw new Error("smmDaily: invalid automatic buy price limit");
  const amount = Number(configured);
  if (!isFinite(amount) || amount < -2147483648 || amount > 2147483647)
    throw new Error("smmDaily: invalid automatic buy price limit");
  // Underflow of a nonzero amount must never become the zero/default sentinel.
  if (amount === 0 && /[1-9]/.test(match[2])) return match[1] === "-" ? -1 : 0;
  if (amount < 0) return -1;
  if (amount === 0) return 20000;
  // Floor decimal digits directly: binary rounding must not turn a ceiling
  // just below one Meat into permission to spend one Meat.
  const digits = match[2].replace(".", ""), first = digits.search(/[1-9]/);
  const dot = match[2].indexOf(".");
  const places = (dot < 0 ? match[2].length : dot) + (match[3] ? Number(match[3]) : 0) - first;
  if (places <= 0) return 0;
  if (places > 10) throw new Error("smmDaily: invalid automatic buy price limit");
  let whole = digits.substring(first, first + places);
  while (whole.length < places) whole += "0";
  const limit = Number(whole);
  if (!integer(limit)) throw new Error("smmDaily: invalid automatic buy price limit");
  return limit;
}
exports.automaticBuyLimit = automaticBuyLimit;

exports.createModule = function (native, policy) {
  const wrapped = {};
  Object.getOwnPropertyNames(native).forEach(function (name) { wrapped[name] = native[name]; });
  wrapped.buy = function () {
    const args = Array.prototype.slice.call(arguments);
    policy.ready();
    // Coinmasters spend their own currencies; keep the native overload. This
    // adapter does not choose which scarce currencies garbo should spend.
    if (args.length === 3 && args[0] instanceof native.Coinmaster) return native.buy.apply(native, args);
    let item, quantity;
    if (args[0] instanceof native.Item) {
      item = args[0]; quantity = args.length === 1 ? 1 : args[1];
    } else {
      quantity = args[0]; item = args[1];
    }
    if (args.length < 1 || args.length > 3 || !(item instanceof native.Item) || !integer(quantity)
        || (args.length === 3 && !integer(args[2]))) throw new Error("smmDaily: unsupported direct buy arguments");
    if (quantity <= 0) return args.length === 3 ? 0 : true;
    const bought = policy.buy(quantity, item, args.length === 3 ? args[2] : 0);
    if (!integer(bought) || bought < 0 || bought > quantity) throw new Error("smmDaily: invalid guarded buy result");
    return args.length === 3 ? bought : bought === quantity;
  };
  wrapped.retrieveItem = function () {
    const args = Array.prototype.slice.call(arguments);
    policy.ready();
    let item, quantity;
    if (args[0] instanceof native.Item) {
      item = args[0]; quantity = args.length === 1 ? 1 : args[1];
    } else {
      quantity = args[0]; item = args[1];
    }
    if (args.length < 1 || args.length > 2 || !(item instanceof native.Item) || !integer(quantity))
      throw new Error("smmDaily: unsupported retrieveItem arguments");
    if (quantity <= 0 || item === native.Item.get("none")) return true; // native no-op conventions
    const accessible = native.availableAmount(item);
    if (!integer(accessible) || accessible < 0) throw new Error("smmDaily: invalid accessible item count");
    const missing = Math.max(0, quantity - accessible);
    if (missing > 0) {
      // Respect ownership-only retrieval and restrictive automatic-source
      // settings. The direct-buy bridge cannot promise an NPC-only seller.
      if (native.getProperty("autoSatisfyWithMall") !== "true" || native.getProperty("autoSatisfyWithNPCs") !== "true") return false;
      const limit = automaticBuyLimit(native.getProperty("autoBuyPriceLimit"));
      if (limit <= 0) return false;
      policy.buy(missing, item, limit);
      policy.ready();
    }
    if (native.itemAmount(item) >= quantity) return true;
    // No native retrieval with a deficit: it could buy or recursively source
    // crafting inputs outside the direct-buy guard. Recheck after the buy.
    if (native.availableAmount(item) < quantity) return false;
    const settings = ["autoSatisfyWithMall", "autoSatisfyWithNPCs", "autoSatisfyWithCoinmasters", "buyScript", "autoBuyPriceLimit"];
    const saved = settings.map(function (name) { return native.getProperty(name); });
    try {
      native.setProperty("autoSatisfyWithMall", "false");
      native.setProperty("autoSatisfyWithNPCs", "false");
      native.setProperty("autoSatisfyWithCoinmasters", "false");
      native.setProperty("buyScript", "");
      // Zero is a native default-reset sentinel, not a no-purchase ceiling.
      native.setProperty("autoBuyPriceLimit", "-1");
      policy.ready();
      if (native.availableAmount(item) < quantity) return false;
      const retrieved = native.retrieveItem(quantity, item);
      policy.ready();
      return retrieved;
    } finally {
      for (let i = settings.length - 1; i >= 0; i--) native.setProperty(settings[i], saved[i]);
    }
  };
  ["use", "eat", "drink", "overdrink", "chew"].forEach(function (name) {
    if (typeof native[name] !== "function") return;
    wrapped[name] = function () {
      const args = Array.prototype.slice.call(arguments);
      policy.ready();
      let item, quantity;
      if (args[0] instanceof native.Item) {
        item = args[0]; quantity = args.length === 1 ? 1 : args[1];
      } else {
        quantity = args[0]; item = args[1];
      }
      if (args.length < 1 || args.length > 2 || !(item instanceof native.Item) || !integer(quantity))
        throw new Error("smmDaily: unsupported " + name + " arguments");
      if (quantity <= 0 || item === native.Item.get("none")) return true;
      if (!policy.consume(quantity, item, name === "use")) return false;
      // Supplying the finished item first prevents implicit native sourcing
      // inside these consumption calls from escaping the purchase guard.
      // Bare Mafia JS items do not expose ASH proxy-record metadata reliably.
      const needed = policy.consumptionQuantity(quantity, item, name === "use");
      if (!integer(needed) || needed < 1 || needed > quantity) throw new Error("smmDaily: invalid consumption quantity");
      if (!wrapped.retrieveItem(needed, item)) return false;
      policy.ready();
      const result = native[name](quantity, item);
      policy.ready();
      return result;
    };
  });
  return wrapped;
};

exports.loadWorker = function (source, wrapped, routeEligible, gardenEligible) {
  if (typeof source !== "string" || source.trim() === "") throw new Error("smmDaily: garbo source is missing");
  const module = { exports: {} };
  // Return the bundle's actual zone objects, without rewriting its selector
  // or changing its prices. The optional hook is checked before main can run.
  const hooks = Function("require", "module", "exports", source + "\n;return {zones: typeof itemStealZones === 'undefined' ? null : itemStealZones, garden: typeof refreshBlackRoseGardenMonsters === 'function' && typeof cachedBlackRoseGardenMonsters !== 'undefined' ? {tasks:typeof FreeFightTasks === 'undefined' ? null : FreeFightTasks, refresh:refreshBlackRoseGardenMonsters, replace:function(fn){refreshBlackRoseGardenMonsters=fn;}, clear:function(){cachedBlackRoseGardenMonsters=[];}} : null};")(function (name) {
    if (name !== "kolmafia") throw new Error("smmDaily: unsupported garbo dependency: " + name);
    return wrapped;
  }, module, module.exports);
  if (typeof module.exports.main !== "function") throw new Error("smmDaily: garbo has no CommonJS main export");
  if (routeEligible !== undefined) {
    const zones = hooks.zones;
    if (typeof routeEligible !== "function" || !Array.isArray(zones) || !wrapped.Location)
      throw new Error("smmDaily: unsupported garbo item-steal eligibility hook");
    const target = wrapped.Location.get("The Stately Pleasure Dome");
    const matches = zones.filter(function (zone) { return zone && zone.location === target; });
    if (matches.length !== 1 || typeof matches[0].isOpen !== "function"
        || typeof matches[0].openCost !== "function" || typeof matches[0].preReq !== "function")
      throw new Error("smmDaily: unsupported garbo absinthe route shape");
    const zone = matches[0], original = zone.isOpen;
    zone.isOpen = function () { return original.apply(this, arguments) && routeEligible(zone.location); };
  }
  if (gardenEligible !== undefined) {
    if (typeof gardenEligible !== "function" || !hooks.garden)
      throw new Error("smmDaily: unsupported garbo Black Rose Garden hook");
    const garden = hooks.garden;
    if (!Array.isArray(garden.tasks)) throw new Error("smmDaily: missing garbo garden task list");
    const plants = garden.tasks.filter(function (task) { return task && task.name === "Plant Black Rose Garden"; });
    if (plants.length !== 1 || typeof plants[0].ready !== "function" || typeof plants[0].do !== "function"
        || typeof plants[0].completed !== "function" || plants[0].spendsTurn !== false)
      throw new Error("smmDaily: unsupported garbo garden planting task");
    const plant = plants[0], ready = plant.ready;
    plant.ready = function () { return ready.apply(this, arguments) && gardenEligible(); };
    garden.replace(function () {
      if (!gardenEligible()) { garden.clear(); return; }
      return garden.refresh.apply(this, arguments);
    });
  }
  return module.exports.main;
};

exports.runWorker = function (worker, args, native, policy) {
  policy.ready();
  args = args || "";
  // Only the standard daily invocation has an implicit Barf strategy. Custom
  // arguments retain their meaning and never have a farming method replaced.
  const standard = /^(?:-\d+)?$/.test(args.trim());
  const hold = standard ? policy.barfHold() : "";
  const key = "_smm.daily.garboPaidHold";
  if (hold) {
    native.setProperty(key, hold); // durable before the partial worker can act
    native.print("smmDaily: paid farming held: " + hold + "; running garbo nobarf; the daily task remains unfinished", "orange");
  }
  worker(hold ? args + " nobarf" : args);
  policy.ready();
  // A partial worker may set garbo's own completion property. Keep our hold
  // until a subsequent standard paid invocation actually returns complete.
  if (standard && !hold && native.getProperty("_garboCompleted") !== "") native.setProperty(key, "");
};
