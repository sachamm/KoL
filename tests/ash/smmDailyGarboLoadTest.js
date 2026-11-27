"use strict";
// Optional installed-bundle compatibility check. Evaluates top-level code only,
// with synthetic state and all action functions blocked; never calls main.
const km = require("kolmafia");
const adapter = require("smmDailyGarboAdapter.js");
exports.main = function (path) {
  const fake = {};
  const calls = {};
  const conversions = /^to(Item|Effect|Familiar|Monster|Location|Phylum|Stat|Skill|Class|Coinmaster|Path|Element|Slot|Modifier|Thrall|Servant|Bounty|Int|Float|Boolean|String)$/;
  const falseReads = ["booleanModifier", "canAdventure", "isDarkMode", "canInteract", "inRonin", "haveSkill", "haveFamiliar", "sellsItem"];
  const zeroReads = ["sellPrice", "historicalPrice", "myTotalTurnsSpent", "myAscensions", "availableAmount", "itemAmount", "myLevel", "myAdventures", "myMp", "myMaxmp", "haveEffect", "familiarWeight", "myDaycount", "myTurncount", "totalTurnsPlayed", "numericModifier", "mallPrice", "autosellPrice", "npcPrice", "myMeat", "getAutoAttack", "modifierEval", "mySpleenUse", "myFullness", "myInebriety"];
  Object.getOwnPropertyNames(km).forEach(function (name) {
    const value = km[name];
    // Type factories and conversions access Mafia's static data, not the game.
    if (typeof value !== "function" || /^[A-Z]/.test(name) || conversions.test(name)) { fake[name] = value; return; }
    fake[name] = function () {
      calls[name] = (calls[name] || 0) + 1;
      if (falseReads.indexOf(name) >= 0) return false;
      if (zeroReads.indexOf(name) >= 0) return 0;
      if (["spleenLimit", "fullnessLimit", "inebrietyLimit"].indexOf(name) >= 0) return 15;
      if (["getProperty", "fileToBuffer", "stringModifier"].indexOf(name) >= 0) return "";
      if (name === "getCampground") return {};
      if (name === "getMonsters") return [];
      if (name === "getPermedSkills") return new Map();
      if (name === "myClass") return km.Class.get("Seal Clubber");
      if (name === "myPath") return km.Path.get("none");
      if (name === "myFamiliar") return km.Familiar.get("none");
      if (name === "effectFact") return km.Effect.get("none");
      if (name === "itemFact" || name === "familiarEquipment") return km.Item.get("none");
      if (name === "print" || name === "printHtml") return;
      throw new Error("blocked native function during bundle load: " + name);
    };
  });
  const wrapped = adapter.createModule(fake, {
    ready: function () {},
    buy: function () { throw new Error("blocked buy during bundle load"); }
  });
  try {
    const worker = adapter.loadWorker(String(km.fileToBuffer(path || "scripts/garbage-collector/garbo.js")), wrapped,
      function () { throw new Error("route eligibility must not run during bundle load"); },
      function () { throw new Error("garden eligibility must not run during bundle load"); },
      function () { throw new Error("sandworm eligibility must not run during bundle load"); });
    if (typeof worker !== "function") throw new Error("missing worker");
    km.print("PASS smmDailyGarboLoadTest: main loaded, never called; synthetic state; calls=" + JSON.stringify(calls));
  } catch (error) { km.print("FAILED smmDailyGarboLoadTest: " + String(error)); }
};
