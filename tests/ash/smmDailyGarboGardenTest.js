"use strict";
const km = require("kolmafia");
const adapter = require("smmDailyGarboAdapter.js");
exports.main = function () {
  let checks = 0, failures = 0;
  function check(ok, why) { checks++; if (!ok) { failures++; km.print("FAIL: " + why); } }
  function throws(fn, why) { let caught = false; try { fn(); } catch (_) { caught = true; } check(caught, why); }
  const state = { prepares: 0, plants: 0, fail: false, props: { _garbo_blackRoseFightsDone: "false" } };
  const native = { state: state,
    getProperty: function (key) { return state.props[key] || ""; },
    setProperty: function (key, value) { state.props[key] = value; }
  };
  const source = "var cachedBlackRoseGardenMonsters=null; var FreeFightTasks=[{name:'Plant Black Rose Garden',ready:function(){return true;},completed:function(){return false;},spendsTurn:false,do:function(){require('kolmafia').state.plants++;}}]; function refreshBlackRoseGardenMonsters(){var s=require('kolmafia').state; s.prepares++; if(s.fail)throw new Error('fixture plant failure'); cachedBlackRoseGardenMonsters=['rose monster'];} exports.main=function(){refreshBlackRoseGardenMonsters(); var task=FreeFightTasks[0]; var ready=task.ready(); if(ready)task.do(); cachedBlackRoseGardenMonsters.plantReady=ready; cachedBlackRoseGardenMonsters.taskComplete=task.completed(); return cachedBlackRoseGardenMonsters;};";
  let eligible = false, probes = 0, stale = false;
  const worker = adapter.loadWorker(source, native, undefined, function () { probes++; if(stale)throw new Error("fixture epoch changed"); return eligible; });
  check(probes === 0 && state.prepares === 0, "loading validates the hook without evaluating supply or preparing a garden");
  let result = worker();
  check(result.length === 0 && state.prepares === 0 && state.plants === 0 && !result.plantReady, "protected seed excludes discovery and the separate planting task without acting");
  check(state.props._garbo_blackRoseFightsDone === "false" && !result.taskComplete, "excluding the pool does not fabricate a daily-used flag or task completion");
  eligible = true;
  result = worker();
  check(result[0] === "rose monster" && state.prepares === 1 && state.plants === 1 && result.plantReady, "eligible supply retains native discovery and separate planting readiness");
  eligible = false;
  check(worker().length === 0 && state.prepares === 1 && state.plants === 1, "a later refusal clears a stale cached fight list without another preparation or planting");
  stale = true;
  throws(function () { worker(); }, "failed epoch/readiness check cannot be treated as an unavailable pool");
  check(state.prepares === 1, "readiness failure precedes planting");
  stale = false; eligible = true; state.fail = true;
  throws(function () { worker(); }, "a failed native planting request still propagates instead of being silently skipped");
  check(state.prepares === 2 && state.props._garbo_blackRoseFightsDone === "false", "only the attempted request ran, without a fake completion marker");
  throws(function () { adapter.loadWorker("exports.main=function(){};", native, undefined, function () { return false; }); }, "missing garden hook refuses loading before main");
  throws(function () { adapter.loadWorker(source.replace("var cachedBlackRoseGardenMonsters=null;", ""), native, undefined, function () { return false; }); }, "missing cache shape refuses integration");
  throws(function () { adapter.loadWorker(source, native, undefined, true); }, "nonfunction eligibility cannot bypass the policy");
  throws(function () { adapter.loadWorker(source.replace("name:'Plant Black Rose Garden'", "name:'Changed planting task'"), native, undefined, function () { return false; }); }, "missing planting task refuses before main");
  throws(function () { adapter.loadWorker(source.replace("spendsTurn:false", "spendsTurn:true"), native, undefined, function () { return false; }); }, "changed task shape refuses before main");
  state.fail = false;
  check(adapter.loadWorker(source, native)()[0] === "rose monster" && state.prepares === 3, "plain factories preserve the original worker when no hook is requested");
  km.print((failures ? "FAILED" : "PASS") + " smmDailyGarboGardenTest: " + checks + " checks");
};
