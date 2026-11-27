"use strict";
const km = require("kolmafia");
const adapter = require("smmDailyGarboAdapter.js");
exports.main = function () {
  let checks = 0, failures = 0;
  function check(ok, why) { checks++; if (!ok) { failures++; km.print("FAIL: " + why); } }
  function throws(fn, why) { let caught = false; try { fn(); } catch (_) { caught = true; } check(caught, why); }
  const state = { prepares: 0, fail: false, props: { _garbo_blackRoseFightsDone: "false" } };
  const native = { state: state,
    getProperty: function (key) { return state.props[key] || ""; },
    setProperty: function (key, value) { state.props[key] = value; }
  };
  const source = "var cachedBlackRoseGardenMonsters=null; function refreshBlackRoseGardenMonsters(){var s=require('kolmafia').state; s.prepares++; if(s.fail)throw new Error('fixture plant failure'); cachedBlackRoseGardenMonsters=['rose monster'];} exports.main=function(){refreshBlackRoseGardenMonsters(); return cachedBlackRoseGardenMonsters;};";
  let eligible = false, probes = 0, stale = false;
  const worker = adapter.loadWorker(source, native, undefined, function () { probes++; if(stale)throw new Error("fixture epoch changed"); return eligible; });
  check(probes === 0 && state.prepares === 0, "loading validates the hook without evaluating supply or preparing a garden");
  check(worker().length === 0 && state.prepares === 0, "protected seed excludes only the unavailable garden fights without planting");
  check(state.props._garbo_blackRoseFightsDone === "false", "excluding the pool does not fabricate a daily-used flag");
  eligible = true;
  check(worker()[0] === "rose monster" && state.prepares === 1, "eligible supply retains native preparation and its observed monster list");
  eligible = false;
  check(worker().length === 0 && state.prepares === 1, "a later refusal clears a stale cached fight list without another preparation");
  stale = true;
  throws(function () { worker(); }, "failed epoch/readiness check cannot be treated as an unavailable pool");
  check(state.prepares === 1, "readiness failure precedes planting");
  stale = false; eligible = true; state.fail = true;
  throws(function () { worker(); }, "a failed native planting request still propagates instead of being silently skipped");
  check(state.prepares === 2 && state.props._garbo_blackRoseFightsDone === "false", "only the attempted request ran, without a fake completion marker");
  throws(function () { adapter.loadWorker("exports.main=function(){};", native, undefined, function () { return false; }); }, "missing garden hook refuses loading before main");
  throws(function () { adapter.loadWorker(source.replace("var cachedBlackRoseGardenMonsters=null;", ""), native, undefined, function () { return false; }); }, "missing cache shape refuses integration");
  throws(function () { adapter.loadWorker(source, native, undefined, true); }, "nonfunction eligibility cannot bypass the policy");
  state.fail = false;
  check(adapter.loadWorker(source, native)()[0] === "rose monster" && state.prepares === 3, "plain factories preserve the original worker when no hook is requested");
  km.print((failures ? "FAILED" : "PASS") + " smmDailyGarboGardenTest: " + checks + " checks");
};
