const fs = require('fs');
const vm = require('vm');
const assert = require('assert/strict');
const source = fs.readFileSync(require('path').join(__dirname, '../scripts/diet.js'), 'utf8');
new vm.Script(source);
const start = source.indexOf('\tfunction calculate_adventures(');
const end = source.indexOf('\n\tfunction calculate_price(', start);
const half = source.slice(source.indexOf('function halfRange('), source.indexOf('\n// Phase 4 is a single overdrink, chosen'));
const ctx = vm.createContext({mafia_ring_available: false, with_pizzalover: false, with_saucemaven: false, tuxedo_available: false, classid: 1, affirmation_bonus: 0, calculate_munchies: a => a <= 3 ? 3 : a <= 6 ? 2 : 1});
vm.runInContext(source.slice(start, end) + '\n' + half, ctx);
let cases = 0;
function check(item, opts, average, maximum) {
  const mean = ctx.calculate_adventures(item, opts);
  const top = ctx.calculate_adventures(item, opts, true);
  assert.equal(mean, average);
  assert.equal(top, maximum);
  const spread = ctx.halfRange({spec: {item, adv: mean, advmax: top}});
  const stop = Math.floor(200 - 40 - mean - spread + 1e-8);
  assert.ok(stop + top + 40 <= 200, 'maximum roll must fit rollover cap');
  cases++;
}
check({name:'beer', type:'booze', 'item class':'beer', size:[0,1,0], advmin:10, advmax:14}, {'frosty mug':true}, 18.8, 22);
check({name:'salad', type:'food', 'item class':'salad', size:[1,0,0], advmin:10, advmax:14}, {'salad fork':true}, 18.2, 21);
check({name:'food', type:'food', size:[1,0,0], advmin:10, advmax:14}, {'dieting pill':true}, 24, 28);
check({name:'wine', type:'booze', 'item class':'wine', size:[0,1,0], advmin:10, advmax:14}, {'brie':true, 'frosty mug':true}, 19.4, 23);
ctx.mafia_ring_available = true;
check({name:'wine', type:'booze', 'item class':'wine', size:[0,1,0], advmin:10, advmax:14}, {'brie':true, 'frosty mug':true}, 21.6, 25);
console.log(`PASS ${cases} adventure-bound and rollover-cap regressions; JS syntax valid`);
