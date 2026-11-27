"use strict";
const km = require("kolmafia");
const bridge = require("smmDailyBuyGuard.ash");
const adapter = require("smmDailyGarboAdapter.js");

exports.main = function (args) {
  bridge.smmGuardReady();
  const wrapped = adapter.createModule(km, {
    ready: function () { bridge.smmGuardReady(); },
    buy: function (quantity, item, limit) { return bridge.smmGuardBuy(quantity, item, limit); },
    consume: function (quantity, item, usingItem) { return bridge.smmGuardConsume(quantity, item, usingItem); },
    consumptionQuantity: function (quantity, item, usingItem) { return bridge.smmGuardConsumptionQuantity(quantity, item, usingItem); }
  });
  const source = String(km.fileToBuffer("scripts/garbage-collector/garbo.js"));
  const worker = adapter.loadWorker(source, wrapped, function (where) { return bridge.smmGuardItemStealEligible(where); });
  adapter.runWorker(worker, args, km, {
    ready: function () { bridge.smmGuardReady(); },
    barfHold: function () { return bridge.smmGuardBarfHold(); }
  });
};
