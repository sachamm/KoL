"use strict";
const km=require("kolmafia"), adapter=require("smmDailyGarboAdapter.js");
exports.main=function(){
  let checks=0,failures=0,events=[],fail="",badBegin=false,badEnd=false;
  function check(ok,why){checks++;if(!ok){failures++;km.print("FAIL phase: "+why);}}
  function throws(fn,why){let caught=false;try{fn();}catch(_){caught=true;}check(caught,why);}
  const source="const km=require('kolmafia'); function freeFights(){km.step('free');return 7;} function dailyFights(){km.step('copy');} function runGarboFarmQuests(arg){km.step(arg);} exports.main=function(){freeFights();dailyFights();return runGarboFarmQuests('paid');};";
  const wrapped={step:function(id){events.push(id);if(fail===id)throw new Error("fixture phase failure");}};
  const observer={begin:function(id){events.push("begin:"+id);if(badBegin)throw new Error("fixture opening failure");},end:function(id,done){events.push("end:"+id+":"+done);if(badEnd)throw new Error("fixture end failure");}};
  const worker=adapter.loadWorker(source,wrapped,undefined,undefined,undefined,observer);
  check(events.length===0,"loading does not measure or act");worker();
  check(events.join("|")==="begin:garbo.free|free|end:garbo.free:true|begin:garbo.copy|copy|end:garbo.copy:true|begin:garbo.paid|paid|end:garbo.paid:true","three phases stay independently ordered");
  events=[];fail="copy";
  throws(function(){worker();},"native phase failure propagates");
  check(events[events.length-1]==="end:garbo.copy:false" && events.indexOf("paid")<0,"partial phase is marked incomplete before any later farming");
  events=[];fail="";badBegin=true;
  throws(function(){worker();},"opening evidence failure stops before action");
  check(events.length===1,"failed opening sends no native action or fabricated end");
  events=[];badBegin=false;badEnd=true;
  throws(function(){worker();},"closing evidence failure stops later phases");
  check(events.indexOf("copy")<0,"no next phase after unpersisted close");
  throws(function(){adapter.loadWorker(source.replace("function dailyFights()","function renamed()"),wrapped,undefined,undefined,undefined,observer);},"changed private phase shape refuses loading");
  throws(function(){adapter.loadWorker(source,wrapped,undefined,undefined,undefined,{});},"incomplete observer refuses loading");
  km.print((failures?"FAILED":"PASS")+" smmDailyGarboPhasesTest: "+checks+" checks");
};
