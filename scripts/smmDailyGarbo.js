"use strict";
const km = require("kolmafia");
const bridge = require("smmDailyBuyGuard.ash");
const adapter = require("smmDailyGarboAdapter.js");
const evidence = require("smmDailyGarboEvidence.ash");

exports.main = function (args) {
  bridge.smmGuardBeginWorker();
  const wrapped = adapter.createModule(km, {
    ready: function () { bridge.smmGuardReady(); },
    buy: function (quantity, item, limit) { return bridge.smmGuardBuy(quantity, item, limit); },
    craft: function (quantity, item) { return bridge.smmGuardCraft(quantity, item); },
    craftPurchase: function (quantity, item, limit) { return bridge.smmGuardCraftPurchase(quantity, item, limit); },
    consume: function (quantity, item, usingItem) {
      return bridge.smmGuardConsume(quantity, item, usingItem, adapter.automaticBuyLimit(km.getProperty("autoBuyPriceLimit")));
    },
    consumptionQuantity: function (quantity, item, usingItem) { return bridge.smmGuardConsumptionQuantity(quantity, item, usingItem); },
    afterUse: function (item, result) { bridge.smmGuardAfterUse(item, result); }
  });
  const source = String(km.fileToBuffer("scripts/garbage-collector/garbo.js"));
  const worker = adapter.loadWorker(source, wrapped,
    function (where) { return bridge.smmGuardItemStealEligible(where); },
    function () { return bridge.smmGuardBlackRoseEligible(adapter.automaticBuyLimit(km.getProperty("autoBuyPriceLimit"))); },
    function (name, cap) {
      if (typeof cap !== "number" || !isFinite(cap)) throw new Error("smmDaily: invalid sandworm acquisition ceiling");
      return bridge.smmGuardSandwormEligible(name, cap > 0 ? adapter.automaticBuyLimit(String(cap)) : 0);
    }, {
      begin: function (phase) { evidence.smmGarboEvidenceBegin(phase); },
      end: function (phase, completed) { evidence.smmGarboEvidenceEnd(phase, completed); }
    });
  adapter.runWorker(worker, args, km, {
    ready: function () { bridge.smmGuardReady(); },
    barfHold: function () { return bridge.smmGuardBarfHold(); }
  });
};
