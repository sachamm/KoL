"use strict";
const km = require("kolmafia");
const bridge = require("smmDailyBuyGuard.ash");
const adapter = require("smmDailyGarboAdapter.js");
exports.main = function () {
  let checks = 0, failures = 0;
  function check(ok, why) { checks++; if (!ok) { failures++; km.print("FAIL: " + why); } }
  function throws(fn, why) { let caught = false; try { fn(); } catch (_) { caught = true; } check(caught, why); }
  check(bridge.smmGuardBarfHold(true, 0, 0, 0, 0) === "", "existing access needs no ticket quote or allowance");
  check(bridge.smmGuardBarfHold(false, 1, 0, 0, 0) === "", "owned ticket leaves acquisition and consumption to the guarded worker");
  check(bridge.smmGuardBarfHold(false, 0, 200.9, 200, 200) === "", "a ticket at the floor of the average can be attempted");
  check(bridge.smmGuardBarfHold(false, 0, 200.9, 201, 1000) !== "", "one Meat above the average ceiling holds paid access");
  check(bridge.smmGuardBarfHold(false, 0, 0, 100, 1000) !== "", "unknown average holds paid access");
  check(bridge.smmGuardBarfHold(false, 0, 200, 0, 1000) !== "", "unknown current quote holds paid access");
  check(bridge.smmGuardBarfHold(false, 0, 200, 100, 199) !== "", "insufficient existing allowance holds paid access");
  check(bridge.smmGuardBarfHold(false, 0, 600000, 500001, 1000000) !== "", "upstream ticket cap is retained as well as the average");
  function fixture() {
    const s = { args: [], props: {}, reason: "ticket above ceiling", reads: 0, checks: 0, abort: false, stale: false, complete: true, printed: [] };
    s.native = {
      setProperty: function (key, value) { s.props[key] = value; },
      getProperty: function (key) { return s.props[key] || ""; },
      print: function (value) { s.printed.push(value); }
    };
    s.policy = {
      ready: function () { s.checks++; if (s.stale && s.checks >= 2) throw new Error("fixture epoch changed"); },
      barfHold: function () { s.reads++; return s.reason; }
    };
    s.worker = function (args) {
      check(!s.reason || s.props["_smm.daily.garboPaidHold"] === s.reason || s.reads === 0, "partial intent exists before the worker acts");
      s.args.push(args);
      if (s.abort) throw new Error("fixture worker failure");
      if (s.complete) s.props._garboCompleted = "fixture completion";
    };
    s.run = function (args) { adapter.runWorker(s.worker, args, s.native, s.policy); };
    return s;
  }
  let s = fixture(); s.run("-10");
  check(s.args[0] === "-10 nobarf" && s.reads === 1, "unavailable default access selects the supported daily-work mode once");
  check(s.props._garboCompleted !== "" && s.props["_smm.daily.garboPaidHold"] === s.reason, "upstream partial completion cannot clear the persistent paid hold");
  check(s.printed.length === 1 && s.printed[0].includes("remains unfinished"), "partial execution is reported plainly");
  s.reason = ""; s.run("-10");
  check(s.args[1] === "-10" && s.props["_smm.daily.garboPaidHold"] === "", "a later successful standard paid run clears the hold");
  s = fixture(); s.abort = true;
  throws(function () { s.run(""); }, "partial worker failure propagates without trying another worker");
  check(s.args.length === 1 && s.props["_smm.daily.garboPaidHold"] === s.reason, "failed partial work retains intent for restart");
  s = fixture(); s.stale = true;
  throws(function () { s.run("-10"); }, "changed epoch after worker stops before success handling");
  check(s.props["_smm.daily.garboPaidHold"] === s.reason, "epoch failure retains the paid hold");
  s = fixture(); s.reason = ""; s.complete = false; s.props["_smm.daily.garboPaidHold"] = "old hold"; s.run("-10");
  check(s.props["_smm.daily.garboPaidHold"] === "old hold", "an unconfirmed regular return cannot clear a prior hold");
  ["-10 nobarf", "-10 farmingmethod=copperhead", "-10 quick", "help"].forEach(function (args) {
    s = fixture(); s.props["_smm.daily.garboPaidHold"] = "old hold"; s.run(args);
    check(s.args[0] === args && s.reads === 0 && s.props["_smm.daily.garboPaidHold"] === "old hold", "custom arguments keep their meaning and cannot clear an automatic hold: " + args);
  });
  km.print((failures ? "FAILED" : "PASS") + " smmDailyGarboAccessTest: " + checks + " checks");
};
