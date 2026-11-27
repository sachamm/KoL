"use strict";
const km = require("kolmafia");
const adapter = require("smmDailyGarboAdapter.js");
const fixture = require("smmDailyGarboAbortFixture.ash");
exports.main = function (mode) {
  const settings = ["autoSatisfyWithMall", "autoSatisfyWithNPCs", "autoSatisfyWithCoinmasters", "buyScript", "autoBuyPriceLimit"];
  const actual = mode === "native";
  if (actual && km.myId() <= 0) throw new Error("native preference check requires an information login");
  const props = { autoSatisfyWithMall: "true", autoSatisfyWithNPCs: "true", autoSatisfyWithCoinmasters: "true", buyScript: "fixture-user-hook", autoBuyPriceLimit: "321" };
  const read = actual ? km.getProperty : function (name) { return props[name]; };
  const write = actual ? km.setProperty : function (name, value) { props[name] = value; };
  const prefix = "SMM_RETRIEVAL_" + (actual ? "NATIVE" : "FIXTURE");
  const saved = settings.map(function (name) { return read(name); });
  const native = {
    Item: km.Item, Coinmaster: km.Coinmaster,
    itemAmount: function () { return 0; }, availableAmount: function () { return 1; },
    getProperty: read, setProperty: write,
    retrieveItem: function () { km.print("UNSAFE_RETRIEVAL_EXECUTED"); return true; }
  };
  let ready = 0;
  const wrapped = adapter.createModule(native, {
    ready: function () {
      ready++;
      if (ready === 2) {
        const expected = ["false", "false", "false", "", "-1"];
        km.print(prefix + "_FENCED " + settings.every(function (name, i) { return read(name) === expected[i]; }));
        fixture.smmRetrievalAbortFixture();
      }
    },
    buy: function () { km.print("UNSAFE_BUY_EXECUTED"); return 0; }
  });
  try { wrapped.retrieveItem(km.Item.get("seal tooth")); }
  finally {
    const restored = settings.every(function (name, i) { return read(name) === saved[i]; });
    km.print(prefix + "_RESTORED " + restored);
    // Keep the isolated runtime reusable even if this test reveals a regression.
    settings.forEach(function (name, i) { write(name, saved[i]); });
  }
};
