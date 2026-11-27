"use strict";
const km = require("kolmafia");
const bridge = require("smmDailyBuyGuard.ash");
const adapter = require("smmDailyGarboAdapter.js");
exports.main = function () {
  let checks = 0, failures = 0;
  function check(ok, why) { checks++; if (!ok) { failures++; km.print("FAIL: " + why); } }
  function throws(fn, why) { let caught = false; try { fn(); } catch (_) { caught = true; } check(caught, why); }
  [
    ["5123.987654", 5123], ["0", 20000], ["0.000", 20000], ["-0", 20000],
    ["0e200", 20000], ["0.5", 0], ["1e-6", 0], ["1e-999", 0], ["-1e-999", -1],
    ["-0.5", -1], ["20000", 20000], ["2147483647", 2147483647], ["-2147483648", -1],
    ["0015.99", 15], ["5e3", 5000], ["1.", 1], [".5", 0],
    ["0.99999999999999999", 0], ["999.999999999999999e-3", 0]
  ].forEach(function (row) {
    const normalized = adapter.automaticBuyLimit(row[0]);
    const offer = normalized > 0 ? bridge.smmGuardOfferFor(1, normalized, normalized, normalized) : null;
    check(normalized === row[1] && (!offer || offer.limit === normalized && offer.quantity === 1), "normalized limit crosses the typed ASH boundary without reparsing: " + row[0]);
  });
  ["", "NaN", "Infinity", "2147483648", "-2147483649", "12oops", "0x20", "1e999"].forEach(function (value) {
    throws(function () { adapter.automaticBuyLimit(value); }, "invalid JS limit refuses: " + value);
  });
  throws(function () { adapter.automaticBuyLimit(0); }, "a nonstring property is invalid rather than silently defaulted");
  km.print((failures ? "FAILED" : "PASS") + " smmDailyGarboLimitsTest: " + checks + " checks");
};
