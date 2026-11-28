"use strict";
const km = require("kolmafia"), adapter = require("smmDailyGarboAdapter.js");
exports.main = function () {
  let checks=0, failures=0, calls=0, allowed=true, fail=false, stale=false;
  function check(ok, why) { checks++; if(!ok){failures++;km.print("FAIL craft: "+why);} }
  function throws(fn,why){let caught=false;try{fn();}catch(_){caught=true;}check(caught,why);}
  const names=["autoSatisfyWithMall","autoSatisfyWithNPCs","autoSatisfyWithCoinmasters","autoSatisfyWithStash","autoSatisfyWithShop","autoSatisfyWithCloset","autoSatisfyWithStorage","buyScript","autoBuyPriceLimit"];
  const props={}; names.forEach(function(name){props[name]=name==="buyScript"?"fixture-hook":name==="autoBuyPriceLimit"?"123":"true";});
  const saved=JSON.stringify(props), it=km.Item.get("bloody mary");
  function restored(){return JSON.stringify(props)===saved;}
  const native={Item:km.Item,Coinmaster:km.Coinmaster,getProperty:function(name){return props[name];},setProperty:function(name,value){props[name]=value;},create:function(q,item){calls++;check(q>0 && item===it,"typed native quantity");if(fail)throw new Error("fixture create failure");return true;}};
  const policy={ready:function(){if(stale)throw new Error("fixture changed day");},craft:function(){check(names.every(function(name){return props[name]===(name==="buyScript"?"":name==="autoBuyPriceLimit"?"-1":"false");}),"all automatic acquisition paths fenced before policy");return allowed;}};
  const wrapped=adapter.createModule(native,policy);
  check(wrapped.create(it) && restored(),"single-item overload restores settings");
  check(wrapped.create(2,it) && restored(),"quantity-first overload restores settings");
  check(wrapped.create(it,2) && restored(),"item-first overload restores settings");
  let before=calls;allowed=false;
  throws(function(){wrapped.create(it);},"denied inputs stop before native create");
  check(calls===before && restored(),"denial restores every setting");
  allowed=true;fail=true;
  throws(function(){wrapped.create(it);},"native exception propagates");
  check(restored(),"native exception restores settings");
  fail=false;stale=true;before=calls;
  throws(function(){wrapped.create(it);},"changed epoch stops before crafting");
  check(calls===before && restored(),"epoch failure leaves original settings");
  stale=false;
  check(wrapped.create(0,it) && wrapped.create(km.Item.get("none")) && calls===before,"no-op creates make no requests");
  throws(function(){wrapped.create(1.5,it);},"fractional quantity refused");
  throws(function(){wrapped.create("bloody mary");},"untyped item refused");
  throws(function(){wrapped.create(1,it,2);},"unknown overload refused");
  const noPolicy=adapter.createModule(native,{ready:function(){}});
  throws(function(){noPolicy.create(it);},"missing craft policy refuses execution");
  check(restored(),"missing policy restores settings");
  allowed=false;before=calls;
  let fallback=0;
  policy.craftPurchase=function(q,item,limit){fallback++;check(q===2 && item===it && limit===123,"finished substitute receives the original ceiling");return true;};
  check(wrapped.create(2,it) && calls===before && fallback===1 && restored(),"verified cheaper substitute avoids native crafting and restores settings");
  policy.craftPurchase=function(){return false;};
  throws(function(){wrapped.create(it);},"unfilled substitute stops the worker");
  check(calls===before && restored(),"failed substitute cannot fall through to native create");
  let raw=0;
  native.craft=function(){raw++;return 1;};
  const guarded=adapter.createModule(native,policy);
  throws(function(){guarded.craft("combine",1,it,it);},"unmodeled raw craft overload cannot bypass policy");
  check(raw===0,"raw craft was never dispatched");
  km.print((failures?"FAILED":"PASS")+" smmDailyGarboCraftTest: "+checks+" checks");
};
