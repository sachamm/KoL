"use strict";
const km = require("kolmafia");
const adapter = require("smmDailyGarboAdapter.js");
exports.main = function () {
  let checks = 0, failures = 0;
  function check(ok, why) { checks++; if (!ok) { failures++; km.print("FAIL: " + why); } }
  function throws(fn, why) { let caught = false; try { fn(); } catch (_) { caught = true; } check(caught, why); }
  const state = { drums: 0, independent: 0, ready: true, independentReady: true };
  const native = { state: state };
  const source = "'use strict'; var k=require('kolmafia'); var _hasWorms=true; function sandwormValue(){return 19.75;} var DEFAULT_SANDWORM_TASK={do:function(){k.state.drums++;},spendsTurn:false}; var SANDWORM_TASK_DEFINITIONS=[{name:'Chest X-Ray',ready:function(){return k.state.ready;},completed:function(){return false;},combatCount:function(){return 3;}},{name:'quad tom',ready:function(){return k.state.independentReady;},completed:function(){return false;},combatCount:function(){return 2;},do:function(){k.state.independent++;}}]; var SandwormTasks=SANDWORM_TASK_DEFINITIONS.map(function(t){return Object.assign({},DEFAULT_SANDWORM_TASK,t);}); function expectedFreeGiantSandwormQuestFights(){return SANDWORM_TASK_DEFINITIONS.reduce(function(n,t){return n+(t.ready()&&!t.completed()?t.combatCount():0);},0);} function hasWorms(){return _hasWorms===undefined?(_hasWorms=expectedFreeGiantSandwormQuestFights()>0):_hasWorms;} exports.main=function(){var available=hasWorms(); if(available)SandwormTasks.forEach(function(t){if(t.ready()&&!t.completed())t.do();}); return {expected:expectedFreeGiantSandwormQuestFights(),available:available,done:SandwormTasks[0].completed()};};";
  let allowed = false, observed = [];
  const eligible = function (name, cap) { observed.push([name, cap]); return allowed; };
  const worker = adapter.loadWorker(source, native, undefined, undefined, eligible);
  check(observed.length === 0 && state.drums === 0 && state.independent === 0, "loading validates hooks without eligibility reads or carrier actions");
  let result = worker();
  check(result.expected === 2 && state.drums === 0 && state.independent === 1, "blocked drum carriers leave independent quad-tom fights eligible in estimates and execution");
  check(!result.done, "blocking a carrier does not fabricate task completion");
  check(observed.length > 0 && observed.every(function (row) { return row[0] === "Chest X-Ray" && row[1] === 18.75; }), "the gate sees the original source name and upstream acquisition ceiling");
  allowed = true; state.independentReady = false;
  result = worker();
  check(result.expected === 3 && state.drums === 1 && state.independent === 1, "available drum supply keeps the original carrier and count");
  allowed = false;
  result = adapter.loadWorker(source, native, undefined, undefined, eligible)();
  check(!result.available && result.expected === 0 && state.drums === 1, "a newly gated worker invalidates stale availability and attempts no unavailable carrier");
  state.ready = false; observed = [];
  result = adapter.loadWorker(source, native, undefined, undefined, eligible)();
  check(observed.length === 0 && !result.available, "original unavailable sources do not trigger extra policy work");
  state.ready = true;
  const failed = adapter.loadWorker(source, native, undefined, undefined, function () { throw new Error("fixture epoch changed"); });
  throws(function () { failed(); }, "policy readiness errors stop before a carrier action");
  check(state.drums === 1, "failed readiness did not start a drum fight");
  throws(function () { adapter.loadWorker("exports.main=function(){};", native, undefined, undefined, eligible); }, "missing sandworm metadata refuses loading");
  throws(function () { adapter.loadWorker(source.replace("combatCount:function(){return 3;}", "combatCount:0"), native, undefined, undefined, eligible); }, "changed source estimate shape refuses loading");
  throws(function () { adapter.loadWorker(source.replace("spendsTurn:false", "spendsTurn:true"), native, undefined, undefined, eligible); }, "changed carrier turn metadata refuses loading");
  throws(function () { adapter.loadWorker(source, native, undefined, undefined, true); }, "invalid eligibility callback refuses loading");
  check(adapter.loadWorker(source, native)().expected === 3 && state.drums === 2, "plain factories preserve original behavior without the hook");
  km.print((failures ? "FAILED" : "PASS") + " smmDailyGarboSandwormTest: " + checks + " checks");
};
