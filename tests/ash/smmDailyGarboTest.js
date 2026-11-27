"use strict";
// Real Mafia type wrappers, synthetic buys only. Never invoke native buy or garbo.
const km = require("kolmafia");
const bridge = require("smmDailyBuyGuard.ash");
const adapter = require("smmDailyGarboAdapter.js");
exports.main = function () {
  let checks = 0, failures = 0, guarded = [], coins = [], ready = 0, fill = 2, denied = false;
  function check(ok, message) { checks++; if (!ok) { failures++; km.print("FAIL: " + message); } }
  function throws(fn, message) { let caught = false; try { fn(); } catch (_) { caught = true; } check(caught, message); }
  const item = km.Item.get("seal tooth");
  const coin = km.Coinmaster.get("The Frozen Brogurt Stand");
  const native = Object.freeze({ Item: km.Item, Coinmaster: km.Coinmaster, print: km.print,
    buy: function () { coins.push(Array.prototype.slice.call(arguments)); return true; } });
  const wrapped = adapter.createModule(native, {
    ready: function () { ready++; if (denied) throw new Error("fixture stale epoch"); },
    buy: function (q, it, cap) { guarded.push([q, it, cap]); return Math.min(fill, q); }
  });
  check(item instanceof km.Item && coin instanceof km.Coinmaster, "native types support overload detection");
  check(wrapped.print === native.print && wrapped.buy !== native.buy, "copy retains API without mutating sealed native exports");
  check(wrapped.buy(item) === true && guarded[0][0] === 1 && guarded[0][2] === 0, "single item uses guarded unlimited-price proposal");
  check(wrapped.buy(2, item) === true && guarded[1][0] === 2, "quantity-first boolean overload");
  check(wrapped.buy(item, 3) === false && guarded[2][0] === 3, "item-first boolean overload reports partial fill false");
  check(wrapped.buy(5, item, 100) === 2 && guarded[3][2] === 100, "capped overload returns actual count");
  check(wrapped.buy(item, 1, 0) === 1 && guarded[4][2] === 0, "item-first capped overload");
  fill = 0;
  check(wrapped.buy(item) === false, "denied or unknown quote returns false");
  check(wrapped.buy(3, item, 100) === 0, "denied capped request returns zero");
  const before = guarded.length;
  check(wrapped.buy(0, item) === true && wrapped.buy(-1, item, 100) === 0 && guarded.length === before, "nonpositive quantities never buy");
  check(wrapped.buy(coin, 2, item) === true && coins.length === 1 && coins[0][0] === coin, "coinmaster overload keeps native currency behavior");
  throws(function () { wrapped.buy(1.5, item); }, "fractional quantity rejected");
  throws(function () { wrapped.buy(Infinity, item); }, "nonfinite quantity rejected");
  throws(function () { wrapped.buy(2147483648, item); }, "overflow quantity rejected");
  throws(function () { wrapped.buy(1, item, NaN); }, "nonfinite limit rejected");
  throws(function () { wrapped.buy("seal tooth"); }, "unsupported item type rejected");
  throws(function () { wrapped.buy(1, item, 100, 4); }, "extra arguments rejected");
  check(coins.length === 1, "no cash overload reached unguarded native buy");
  denied = true;
  const count = guarded.length;
  throws(function () { wrapped.buy(item); }, "readiness abort stops before guarded buy");
  throws(function () { wrapped.buy(coin, 1, item); }, "readiness abort stops coinmaster request too");
  check(guarded.length === count && coins.length === 1, "epoch check precedes both request types");
  denied = false; fill = 1;
  const worker = adapter.loadWorker("const k=require('kolmafia'); exports.main=function(a){return [a,k.buy(k.Item.get('seal tooth'))];};", wrapped);
  const result = worker("-10 nobarf");
  check(result[0] === "-10 nobarf" && result[1] === true, "worker factory injects guard and preserves args");
  check(coins.length === 1, "factory worker never called native cash buy");
  throws(function () { adapter.loadWorker("", wrapped); }, "missing source rejected");
  throws(function () { adapter.loadWorker("exports.main=;", wrapped); }, "invalid source rejected");
  throws(function () { adapter.loadWorker("require('other'); exports.main=function(){};", wrapped); }, "unknown dependency rejected without fallback");
  throws(function () { adapter.loadWorker("exports.other=function(){};", wrapped); }, "missing main rejected");
  const offer = bridge.smmGuardOfferFor(10, 500, 100.9, 250);
  check(offer.quantity === 2 && offer.limit === 100, "real JS-to-ASH bridge preserves offer fields and argument order");
  check(typeof bridge.smmGuardReady === "function" && typeof bridge.smmGuardBuy === "function", "production ASH bridge exports resolve");
  check(ready > guarded.length, "every overload checks readiness including rejected requests");
  km.print((failures ? "FAILED" : "PASS") + " smmDailyGarboTest: " + checks + " checks");
};
