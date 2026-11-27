"use strict";

// Cooperative instrumentation of garbo's CommonJS kolmafia import, not a
// sandbox. Never mutate Mafia's sealed native exports or fall back to raw garbo.
function integer(value) {
  return typeof value === "number" && isFinite(value) && Math.floor(value) === value && Math.abs(value) <= 2147483647;
}

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
      const configured = native.getProperty("autoBuyPriceLimit");
      if (!/^-?\d+$/.test(configured)) throw new Error("smmDaily: invalid automatic buy price limit");
      const limit = Number(configured);
      if (!integer(limit)) throw new Error("smmDaily: invalid automatic buy price limit");
      if (limit < 0) return false;
      policy.buy(missing, item, limit === 0 ? 20000 : limit);
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

exports.loadWorker = function (source, wrapped) {
  if (typeof source !== "string" || source.trim() === "") throw new Error("smmDaily: garbo source is missing");
  const module = { exports: {} };
  Function("require", "module", "exports", source)(function (name) {
    if (name !== "kolmafia") throw new Error("smmDaily: unsupported garbo dependency: " + name);
    return wrapped;
  }, module, module.exports);
  if (typeof module.exports.main !== "function") throw new Error("smmDaily: garbo has no CommonJS main export");
  return module.exports.main;
};
