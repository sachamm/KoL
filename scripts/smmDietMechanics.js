// Copyright 2026 Sacha Mallais. Repository license: CC BY 4.0.
// Numerical game rules, separate from allocation and KoLmafia actions.
function flag(value) {
  return value === true || value === "yes";
}
function bankersRound(value) {
  var lower = Math.floor(value);
  return value - lower === 0.5 ? lower + (lower % 2) : Math.round(value);
}
function average(low, high, transform) {
  if (
    !Number.isFinite(low) ||
    !Number.isFinite(high) ||
    high < low ||
    high - low > 10000
  )
    throw new Error("Invalid adventure range");
  if (!Number.isInteger(low) || !Number.isInteger(high))
    return transform((low + high) / 2);
  var total = 0;
  for (var roll = low; roll <= high; roll++) total += transform(roll);
  return total / (high - low + 1);
}
function adventures(item, settings, boosts, mime) {
  var low = item.advmin === undefined ? 0 : Number(item.advmin);
  var high = item.advmax === undefined ? low : Number(item.advmax);
  var size = item.size || [0, 0, 0],
    kind = item["item class"];
  return (
    average(low, high, function (base) {
      if (base <= 0) return base;
      var result = base;
      if (item.type === "food") {
        if (boosts.seasoning) result++;
        if (boosts.fork)
          result = Math.ceil(result * (kind === "salad" ? 1.5 : 1.3));
        if (boosts.spork) result += 3;
        if (boosts.munchies)
          result += Math.max(1, Math.min(3, Math.floor((12 - base) / 3)));
        if (boosts.taco) result++;
        if (boosts.mayoflex) result++;
        if (boosts.gar) result += 5;
        if (flag(settings["gourmand available"])) result += size[0];
        if (kind === "saucy food" && flag(settings["saucemaven available"]))
          result += settings.classid === 3 || settings.classid === 4 ? 5 : 3;
        if (kind === "pizza" && flag(settings["pizza lover available"]))
          result += size[0];
      } else if (item.type === "booze") {
        if (boosts.mug)
          result = Math.floor(base * (kind === "beer" ? 1.5 : 1.3));
        if (boosts.bge) result += 3;
        if (boosts.salty) result += 5;
        if (boosts.palate) result += Math.floor(base / 4);
        if (kind === "wine" && flag(settings["mafia pinky ring available"]))
          result += bankersRound(
            (boosts.palate ? Math.floor(base * 1.25) : base) / 8,
          );
        if (settings["ode available"] !== false)
          result += Math.max(0, size[1] - (mime ? 1 : 0));
        if (
          item["tuxedo boostable drink"] === "yes" &&
          flag(settings["tuxedo shirt available"])
        )
          result += 2;
      }
      return result;
    }) + Number(item.bonusadv || 0)
  );
}

var chocolateClasses = [
  "chocolate seal-clubbing club",
  "chocolate turtle totem",
  "chocolate pasta spoon",
  "chocolate saucepan",
  "chocolate disco ball",
  "chocolate stolen accordion",
];
var fancy = [
  "fancy chocolate",
  "fancy but probably evil chocolate",
  "fancy chocolate car",
  "beet-flavored Mr. Mediocrebar",
  "cabbage-flavored Mr. Mediocrebar",
  "sweet-corn-flavored Mr. Mediocrebar",
  "choco-Crimbot",
];
function chocolate(name, classid) {
  if (fancy.indexOf(name) >= 0) return { counter: "fancy", turns: [5, 3, 1] };
  var index = chocolateClasses.indexOf(name);
  if (index >= 0)
    return {
      counter: "fancy",
      turns: index + 1 === classid ? [3, 2, 1] : [2, 1, 0],
    };
  var separate = {
    "vitachoconutriment capsule": "vitachoc",
    "chocolate cigar": "cigar",
    "fancy chocolate sculpture": "sculpture",
  };
  if (separate[name]) return { counter: separate[name], turns: [5, 3, 1] };
  return null;
}
module.exports = { adventures: adventures, chocolate: chocolate };
