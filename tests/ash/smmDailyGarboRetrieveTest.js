"use strict";
const km = require("kolmafia");
const adapter = require("smmDailyGarboAdapter.js");
exports.main = function () {
  let checks = 0, failures = 0;
  function check(ok, message) { checks++; if (!ok) { failures++; km.print("FAIL: " + message); } }
  function throws(fn, message) { let caught = false; try { fn(); } catch (_) { caught = true; } check(caught, message); }
  const item = km.Item.get("seal tooth");
  function fixture(inv, owned, fill) {
    const state = { inv: inv, owned: owned, fill: fill, buys: [], transfers: 0, ready: 0, reads: 0, throwTransfer: false, falseTransfer: false, vanish: false, staleAfter: 0 };
    const initial = { autoSatisfyWithMall: "true", autoSatisfyWithNPCs: "true", autoSatisfyWithCoinmasters: "true", buyScript: "fixture-user-hook", autoBuyPriceLimit: "321" };
    const props = Object.assign({}, initial);
    const native = {
      Item: km.Item, Coinmaster: km.Coinmaster,
      itemAmount: function () { return state.inv; },
      availableAmount: function () { state.reads++; return state.vanish && state.reads >= 3 ? 0 : state.inv + state.owned; },
      getProperty: function (name) { return props[name]; },
      setProperty: function (name, value) { props[name] = value; },
      buy: function () { throw new Error("UNSAFE_NATIVE_BUY"); },
      retrieveItem: function (q, it) {
        state.transfers++;
        check(q <= state.inv + state.owned, "transfer never has a deficit");
        check(it === item && props.autoSatisfyWithMall === "false" && props.autoSatisfyWithNPCs === "false" && props.autoSatisfyWithCoinmasters === "false" && props.buyScript === "" && props.autoBuyPriceLimit === "-1", "all automatic-source and hook paths fenced during transfer");
        if (state.throwTransfer) throw new Error("fixture transfer abort");
        if (state.falseTransfer) return false;
        state.owned -= Math.max(0, q - state.inv); state.inv = q;
        return true;
      }
    };
    state.module = adapter.createModule(native, {
      ready: function () { state.ready++; if (state.staleAfter && state.ready >= state.staleAfter) throw new Error("fixture changed epoch"); },
      buy: function (q, it, cap) {
        state.buys.push([q, it, cap]);
        const bought = Math.min(q, state.fill); state.inv += bought; return bought;
      }
    });
    state.props = props;
    state.restored = function () { return JSON.stringify(props) === JSON.stringify(initial); };
    return state;
  }
  let s = fixture(5, 0, 0);
  check(s.module.retrieveItem(item) === true && s.transfers === 0 && s.buys.length === 0, "inventory-only request has no actions");
  s = fixture(0, 5, 0);
  check(s.module.retrieveItem(5, item) === true && s.transfers === 1 && s.buys.length === 0, "owned copies transfer without buying");
  check(s.restored(), "normal transfer restores exact settings and custom buy hook");
  s = fixture(1, 1, 3);
  check(s.module.retrieveItem(item, 5) === true && s.buys.length === 1 && s.buys[0][0] === 3 && s.buys[0][2] === 321 && s.transfers === 1, "mixed stock buys only deficit at the caller's ceiling then transfers owned stock");
  check(s.restored(), "mixed buy/transfer restores settings");
  s = fixture(0, 2, 1);
  check(s.module.retrieveItem(5, item) === false && s.buys.length === 1 && s.transfers === 0, "partial guarded fill never falls through to automatic buying");
  check(s.restored(), "partial fill leaves settings untouched");
  s = fixture(0, 0, 0);
  check(s.module.retrieveItem(item) === false && s.transfers === 0, "denied or unknown quote never invokes native retrieval");
  s = fixture(0, 0, 1); s.props.autoSatisfyWithMall = "false";
  check(s.module.retrieveItem(item) === false && s.buys.length === 0 && s.transfers === 0, "ownership-only mall-disabled retrieval does not buy");
  s = fixture(0, 0, 1); s.props.autoSatisfyWithNPCs = "false";
  check(s.module.retrieveItem(item) === false && s.buys.length === 0, "restricted source configuration stays held");
  s = fixture(0, 1, 0); s.props.autoSatisfyWithMall = "false";
  check(s.module.retrieveItem(item) === true && s.buys.length === 0 && s.props.autoSatisfyWithMall === "false", "owned transfer works and preserves ownership-only configuration");
  s = fixture(0, 0, 1); s.props.autoBuyPriceLimit = "0";
  check(s.module.retrieveItem(item) === true && s.buys[0][2] === 20000, "zero ceiling uses the native default, never unlimited");
  s = fixture(0, 0, 1); s.props.autoBuyPriceLimit = "-1";
  check(s.module.retrieveItem(item) === false && s.buys.length === 0, "negative purchase ceiling prohibits buying");
  s = fixture(0, 0, 1); s.props.autoBuyPriceLimit = "23.75";
  check(s.module.retrieveItem(item) === true && s.buys[0][2] === 23, "fractional upstream ceiling rounds down before the guarded buy");
  check(s.props.autoBuyPriceLimit === "23.75", "fractional caller setting is preserved");
  s = fixture(0, 0, 1); s.props.autoBuyPriceLimit = "0.5";
  check(s.module.retrieveItem(item) === false && s.buys.length === 0 && s.transfers === 0, "sub-Meat positive ceiling cannot turn into the default buy allowance");
  s = fixture(0, 0, 1); s.props.autoBuyPriceLimit = "2.5oops";
  throws(function () { s.module.retrieveItem(item); }, "malformed ceiling stops before buying");
  check(s.buys.length === 0 && s.transfers === 0, "invalid ceiling has no actions");
  s = fixture(0, 1, 0); s.falseTransfer = true;
  check(s.module.retrieveItem(item) === false && s.restored(), "false native result restores settings");
  s = fixture(0, 1, 0); s.throwTransfer = true;
  throws(function () { s.module.retrieveItem(item); }, "native transfer abort propagates");
  check(s.restored(), "native abort restores settings");
  s = fixture(0, 1, 0); s.staleAfter = 2;
  throws(function () { s.module.retrieveItem(item); }, "epoch change before transfer stops work");
  check(s.transfers === 0 && s.restored(), "pre-transfer epoch failure restores settings without an action");
  s = fixture(0, 1, 0); s.staleAfter = 3;
  throws(function () { s.module.retrieveItem(item); }, "epoch change during transfer cannot return success");
  check(s.transfers === 1 && s.restored(), "post-transfer epoch failure restores settings");
  s = fixture(0, 1, 0); s.vanish = true;
  check(s.module.retrieveItem(item) === false && s.transfers === 0 && s.restored(), "lost stock is rechecked inside the source fence");
  s = fixture(0, 0, 0);
  check(s.module.retrieveItem(0, item) === true && s.module.retrieveItem(item, -1) === true && s.module.retrieveItem(km.Item.get("none")) === true, "native nonpositive and none no-ops preserved");
  check(s.buys.length === 0 && s.transfers === 0, "no-op requests have no actions");
  throws(function () { s.module.retrieveItem(1.5, item); }, "fractional retrieval rejected");
  throws(function () { s.module.retrieveItem(Infinity, item); }, "nonfinite retrieval rejected");
  throws(function () { s.module.retrieveItem(2147483648, item); }, "overflow retrieval rejected");
  throws(function () { s.module.retrieveItem("seal tooth"); }, "untyped retrieval rejected");
  throws(function () { s.module.retrieveItem(item, 1, 100); }, "extra retrieval arguments rejected");
  check(s.buys.length === 0 && s.transfers === 0, "invalid requests have no actions");
  km.print((failures ? "FAILED" : "PASS") + " smmDailyGarboRetrieveTest: " + checks + " checks");
};
