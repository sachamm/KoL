"use strict";
// Real item metadata/pure ASH policy, synthetic inventory and menu requests.
// Safe while logged out: never call the native use/buy/contract bridge.
const km = require("kolmafia");
const bridge = require("smmDailyBuyGuard.ash");
const adapter = require("smmDailyGarboAdapter.js");
exports.main = function () {
  let checks = 0, failures = 0, stock = 1, allowed = true, ok = true;
  let decision = 3, quest = "started", uses = 0, buys = 0, posts = 0;
  function check(value, why) { checks++; if (!value) { failures++; km.print("FAIL menu: " + why); } }
  function stopped(fn, why) {
    let caught = false;
    try { fn(); } catch (error) { caught = String(error).indexOf("CONTRACT_UNCONFIRMED") >= 0; }
    check(caught, why);
  }
  const tablet = km.Item.get("Guzzlr tablet"), bottle = km.Item.get("tiny bottle of absinthe");
  check(bridge.smmGuardUsePreservesItem(tablet), "tablet use preserves the permanent menu item");
  check(!bridge.smmGuardUsePreservesItem(bottle), "ordinary consumables retain their reserve");
  check(bridge.smmGuardConsumptionQuantity(5, tablet, true) === 1, "repeated menu requests need one tablet");
  check(bridge.smmGuardConsumptionQuantity(5, tablet, false) === 5, "exception applies only to use");
  const native = { Item: km.Item, Coinmaster: km.Coinmaster,
    itemAmount: function () { return stock; }, availableAmount: function () { return stock; },
    getProperty: function (name) { return name === "autoBuyPriceLimit" ? "20000" : "true"; },
    buy: function () { throw new Error("UNSAFE_NATIVE_BUY"); },
    use: function () { uses++; return ok; }, eat: function () { return ok; }
  };
  const wrapped = adapter.createModule(native, {
    ready: function () {}, buy: function () { buys++; return 0; },
    consume: function (q, it, using) { return allowed && (using && bridge.smmGuardUsePreservesItem(it)); },
    consumptionQuantity: function (q, it, using) { return bridge.smmGuardConsumptionQuantity(q, it, using); },
    afterUse: function (it, result) {
      posts++;
      if (!bridge.smmGuardMenuConfirmed(it, decision, result, quest)) throw new Error("CONTRACT_UNCONFIRMED");
    }
  });
  [2, 3, 4].forEach(function (choice) {
    decision = choice;
    ["started", "step1"].forEach(function (state) {
      quest = state;
      check(wrapped.use(tablet) && stock === 1 && buys === 0, "confirmed contract choice " + choice + "/" + state);
    });
  });
  check(uses === 6 && posts === 6, "every native menu result checked once");
  ["", "unstarted", "finished"].forEach(function (state) {
    quest = state;
    const before = uses;
    stopped(function () { for (let i = 0; i < 3; i++) wrapped.use(tablet); }, "unconfirmed quest " + state + " interrupts upstream retry loop");
    check(uses === before + 1, "only one menu attempt for unconfirmed " + state);
  });
  quest = "started"; ok = false;
  stopped(function () { wrapped.use(tablet); }, "native false cannot be masked by an old active quest");
  ok = true; allowed = false;
  let before = uses, beforePosts = posts;
  stopped(function () { wrapped.use(tablet); }, "reserve denial also interrupts menu loop");
  check(uses === before && posts === beforePosts + 1, "reserve denial checked before native request");
  allowed = true; stock = 0; beforePosts = posts;
  stopped(function () { wrapped.use(tablet); }, "missing tablet interrupts menu loop");
  check(uses === before && posts === beforePosts + 1 && buys === 1, "unfilled retrieval checked before native request");
  stock = 1; quest = "unstarted"; decision = 5;
  check(wrapped.use(tablet), "leave-menu choice requires no contract");
  decision = 1;
  check(wrapped.use(tablet), "abandon-menu choice can clear the quest");
  check(bridge.smmGuardMenuConfirmed(bottle, 3, false, ""), "unrelated item retains normal false return");
  beforePosts = posts;
  check(wrapped.eat(tablet) === false && posts === beforePosts, "non-use calls have no menu postcondition");
  check(typeof bridge.smmGuardAfterUse === "function", "production postcondition bridge resolves");
  km.print((failures ? "FAILED" : "PASS") + " smmDailyGarboMenuTest: " + checks + " checks");
};
