"use strict";
const km = require("kolmafia");
const bridge = require("smmDailyBuyGuard.ash");
const adapter = require("smmDailyGarboAdapter.js");

exports.main = function (args) {
  bridge.smmGuardReady();
  const wrapped = adapter.createModule(km, {
    ready: function () { bridge.smmGuardReady(); },
    buy: function (quantity, item, limit) { return bridge.smmGuardBuy(quantity, item, limit); }
  });
  const source = String(km.fileToBuffer("scripts/garbage-collector/garbo.js"));
  const worker = adapter.loadWorker(source, wrapped);
  worker(args || "");
};
