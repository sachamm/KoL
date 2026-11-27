"use strict";
const km = require("kolmafia");
const bridge = require("smmDailyBuyGuard.ash");
const adapter = require("smmDailyGarboAdapter.js");
exports.main = function () {
  let checks = 0, failures = 0;
  function check(ok, why) { checks++; if (!ok) { failures++; km.print("FAIL: " + why); } }
  function throws(fn, why) { let caught = false; try { fn(); } catch (_) { caught = true; } check(caught, why); }
  check(bridge.smmGuardInputAvailable(1, 1, 2, 1, 0, 0, 0, 0, false), "accessible unreserved input needs no new purchase");
  check(!bridge.smmGuardInputAvailable(1, 1, 1, 1, 0, 0, 0, 0, false), "owned reserved input alone is not consumable");
  check(bridge.smmGuardInputAvailable(1, 0, 0, 0, 200, 100.9, 100, 100, true), "exact guarded price and allowance can supply the route");
  check(!bridge.smmGuardInputAvailable(1, 0, 0, 0, 200, 100.9, 101, 1000, true), "above-average current quote excludes the route");
  check(!bridge.smmGuardInputAvailable(1, 0, 0, 0, 90, 100, 100, 1000, true), "caller ceiling still applies");
  check(!bridge.smmGuardInputAvailable(1, 0, 0, 0, 200, 100, 100, 99, true), "insufficient shared allowance excludes the route");
  check(!bridge.smmGuardInputAvailable(1, 0, 0, 0, 200, 0, 100, 1000, true), "unknown average excludes buying");
  check(!bridge.smmGuardInputAvailable(1, 0, 0, 0, 200, 100, 0, 1000, true), "unknown current quote excludes buying");
  check(!bridge.smmGuardInputAvailable(1, 0, 0, 0, 200, 100, 100, 1000, false), "disabled automatic buying is respected");
  check(bridge.smmGuardInputAvailable(1, 1, 1, 1, 200, 100, 100, 100, true), "a funded replacement can protect the existing Museum copy");
  check(bridge.smmGuardInputAvailable(1, 0, 10, 0, 200, 100, 100, 100, true), "inaccessible owned stock still needs an accessible supplied copy");
  check(!bridge.smmGuardInputAvailable(3, 1, 1, 1, 200, 100, 100, 299, true), "all needed replacements must be funded");
  check(bridge.smmGuardInputAvailable(3, 1, 1, 1, 200, 100, 100, 300, true), "funded replacements and retrieval deficit are not charged twice");
  check(bridge.smmGuardInputAvailable(1, 0, 0, 0, 80, 200, 40, 80, true), "the upstream ceiling can reduce the allowance reservation");
  const native = { Location: km.Location };
  const fixture = "var itemStealZones=[{location:require('kolmafia').Location.get('The Stately Pleasure Dome'),value:100,isOpen:function(){return true;},openCost:function(){return 1;},preReq:function(){throw new Error('UNSAFE_PREREQUISITE');}},{location:require('kolmafia').Location.get('The Haunted Library'),value:10,isOpen:function(){return true;}}]; exports.main=function(){return itemStealZones.filter(function(z){return z.isOpen();}).sort(function(a,b){return b.value-a.value;})[0].location;};";
  let allowed = false, probes = 0;
  const worker = adapter.loadWorker(fixture, native, function (where) { probes++; check(where === km.Location.get("The Stately Pleasure Dome"), "eligibility hook sees only its known route"); return allowed; });
  check(probes === 0, "source load validates the hook without checking live eligibility or running main");
  check(worker() === km.Location.get("The Haunted Library"), "an ineligible high-value route yields to the next eligible target without its prerequisite");
  allowed = true;
  check(worker() === km.Location.get("The Stately Pleasure Dome"), "a later eligible input restores the original selection");
  const throwing = adapter.loadWorker(fixture, native, function () { throw new Error("fixture stale epoch"); });
  throws(function () { throwing(); }, "readiness failure propagates before route preparation");
  throws(function () { adapter.loadWorker("exports.main=function(){};", native, function () { return true; }); }, "a missing bundle hook holds before main");
  throws(function () { adapter.loadWorker(fixture.replace("openCost:function(){return 1;}", "openCost:1"), native, function () { return true; }); }, "changed upstream route shape refuses integration");
  throws(function () { adapter.loadWorker(fixture.replace("var itemStealZones=[", "var itemStealZones=[null,"), native, true); }, "a nonfunction policy cannot bypass eligibility");
  check(adapter.loadWorker(fixture, native)() === km.Location.get("The Stately Pleasure Dome"), "plain test factories preserve original behavior without a route hook");
  km.print((failures ? "FAILED" : "PASS") + " smmDailyGarboRoutesTest: " + checks + " checks");
};
