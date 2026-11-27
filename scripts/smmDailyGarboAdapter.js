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
