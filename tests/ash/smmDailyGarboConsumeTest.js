"use strict";
// Native types and ASH policy arithmetic; all transfers, buys and consumption
// are synthetic. This test must remain safe while logged out.
const km = require("kolmafia");
const bridge = require("smmDailyBuyGuard.ash");
const adapter = require("smmDailyGarboAdapter.js");
exports.main = function () {
  let checks = 0, failures = 0, allowed = true, stale = false, changeOnConsume = false, stock = 10, fill = true, calls = [], prepared = [], buys = 0;
  function check(ok, message) { checks++; if (!ok) { failures++; km.print("FAIL: " + message); } }
  function throws(fn, message) { let caught = false; try { fn(); } catch (_) { caught = true; } check(caught, message); }
  const tooth = km.Item.get("seal tooth"), tool = km.Item.get("Oscus's neverending soda");
  const native = { Item: km.Item, Coinmaster: km.Coinmaster,
    itemAmount: function () { return stock; }, availableAmount: function () { return stock; },
    getProperty: function (name) { return name === "autoBuyPriceLimit" ? "20000" : "true"; },
    buy: function () { throw new Error("UNSAFE_NATIVE_BUY"); }
  };
  ["use", "eat", "drink", "overdrink", "chew"].forEach(function (name) {
    native[name] = function (q, it) { calls.push([name, q, it]); if (changeOnConsume) stale = true; return fill; };
  });
  const wrapped = adapter.createModule(Object.freeze(native), {
    ready: function () { if (stale) throw new Error("fixture epoch changed"); },
    buy: function () { buys++; return 0; },
    consume: function (q, it, using) { prepared.push([q, it, using]); return allowed; },
    consumptionQuantity: function (q, it, using) { return bridge.smmGuardConsumptionQuantity(q, it, using); }
  });
  ["use", "eat", "drink", "overdrink", "chew"].forEach(function (name) {
    check(wrapped[name](tooth) === true && calls[calls.length - 1][0] === name, name + " single item reaches checked consumption");
    check(wrapped[name](2, tooth) === true && calls[calls.length - 1][1] === 2, name + " quantity-first overload");
    check(wrapped[name](tooth, 3) === true && prepared[prepared.length - 1][2] === (name === "use"), name + " item-first overload and reusable distinction");
    allowed = false;
    const before = calls.length;
    check(wrapped[name](tooth) === false && calls.length === before, name + " cannot spend a reserved copy");
    allowed = true;
  });
  const before = calls.length, beforePrepared = prepared.length;
  check(wrapped.eat(0, tooth) && wrapped.use(km.Item.get("none")) && calls.length === before && prepared.length === beforePrepared, "no-op calls never acquire or consume");
  stock = 0;
  check(!wrapped.eat(tooth) && calls.length === before && buys === 1, "missing finished copy cannot fall through to native implicit buying");
  stock = 1;
  check(bridge.smmGuardConsumptionQuantity(5, tool, true) === 1 && wrapped.use(5, tool) && calls[calls.length - 1][1] === 5, "repeated reusable use needs one tool, preserving invocation count");
  stock = 10; fill = false;
  check(wrapped.drink(tooth) === false, "native failure remains false");
  throws(function () { wrapped.eat(1.5, tooth); }, "fractional quantity rejected");
  throws(function () { wrapped.chew(tooth, 1, 2); }, "extra arguments rejected");
  throws(function () { wrapped.use("seal tooth"); }, "untyped item rejected");
  stale = true;
  const stopped = calls.length;
  throws(function () { wrapped.eat(tooth); }, "changed epoch stops consumption");
  check(calls.length === stopped, "readiness check precedes native action");
  stale = false; changeOnConsume = true;
  throws(function () { wrapped.eat(tooth); }, "rollover during consumption stops before returning to worker");
  check(calls.length === stopped + 1, "only the in-flight action ran on rollover");
  check(bridge.smmGuardConsumptionMissing(3, 10, 9) === 2, "replacement deficit leaves reserve intact");
  check(bridge.smmGuardConsumptionMissing(3, 10, 7) === 0, "exact surplus requires no purchase");
  check(bridge.smmGuardConsumptionMissing(3, 1, 1) === 3, "unknown ranking can preserve all existing copies");
  check(bridge.smmGuardConsumptionMissing(3, 0, 0) === 3, "absent items need finished copies");
  check(typeof bridge.smmGuardConsume === "function", "production consumption bridge resolves");
  km.print((failures ? "FAILED" : "PASS") + " smmDailyGarboConsumeTest: " + checks + " checks");
};
