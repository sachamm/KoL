// (not strict: the ported optimizer is pre-strict-mode code)

// diet.js -- daily diet optimizer for KoLmafia.
//
// The optimizer (tehtmi() below) is a port of the Kingdom of Loathing diet
// calculator at https://www.lethe.xyz/kol/diets.php (diet-code-1.0.0.js).
// It is kept as close to the original as possible so it can be diffed against
// it; local changes are marked with "smm:". Everything after the optimizer
// replaces the page's static 2023 price table and settings form with live
// KoLmafia data: remaining organ space, skills, equipment, daily-use
// counters and mall prices.
//
// Every plan covers the whole day: all organs full, cleaners used, organ-size
// gear (and the Stooper) worn for extra space, and an overdrink at the end.
// It is carried out in four phases:
//   1. now: food, booze and spleen in the organs' normal space, with the
//      cleaners; then adventure until those adventures are spent;
//   2. other turn generation that uses no organ (chocolates, tofu and other
//      simple items, magical sausages, Ancestral Recall); then adventure
//      until those are spent;
//   3. end of day: Sweat Out Some Booze, wear the organ-size gear / Stooper
//      and fill every organ to that capacity, never past it;
//   4. overdrink exactly one drink: the one worth most, counting only the
//      adventures that fit under the cap. Nothing is eaten after it.
// Phases 3 and 4 end useful adventuring (the gear costs you, and overdrunk you
// can't adventure), so their adventures roll over to tomorrow. Rollover keeps
// at most 200 adventures, so phases 3-4 are planned to end the day as close to
// 200 minus what rollover adds as possible without passing it.
//
// Usage (gCLI):  call diet.js [options]     (prints the whole-day plan)
//   execute        buy and consume phase 1 (asks to confirm)
//   turngen        once phase 1's adventures are spent: re-plan, then buy and
//                  consume phases 1-2 (asks to confirm)
//   finish         once phase 2's adventures are spent: re-plan, then buy and
//                  consume everything left, phases 1 to 4 (asks to confirm).
//                  With designer sweatpants, it first casts Sweat Out Some
//                  Booze as often as your sweat allows (25 each, 3 a day) and
//                  plans the drunkenness that frees; other runs only flag it
//   value=N        meat per adventure (default: smm.TurnValue, else 5000)
//   rollover=N     adventures rollover will add (default: smmUtils'
//                  adventureGainAtRollover with the best adventure gear)
//   organs=F,D,S   override remaining fullness,drunkenness,spleen (no gear counted)
//   lucky=N        Lucky! adventures wanted from Lucky Lindy (default 3)
//   pvp=N          meat per PvP fight (default 0)
//   itemdrop=N     meat one adventure with +1% Item Drop is worth, for the
//                  effects consumables give (default: smm.ItemDropValue, else
//                  0.2% of the adventure value: +100% is worth a fifth of an
//                  adventure). Every modifier in EFFECT_MODIFIERS has such an
//                  option and preference, named after it without spaces
//                  (meatdrop=N / smm.MeatDropValue, familiarweight=N / ...);
//                  0 ignores that modifier
//   noRefresh      don't re-check live mall prices of the chosen items
//   exclude=a|b|c  item names to leave out
//   (execute, turngen and finish handle helpers, effects, Ode to Booze and gear, then
//   restore your outfit and familiar)

var semirare_value = 0  // smm: set from the 11-leaf clover price before running
var diet_consumables = []  // smm: built from KoLmafia data before running

// TODO: distention pill value

// TODO: timespinner

// TODO: LOV Extraterrestrial Chocolate
// TODO: Gratitude chocolate (thyme-filled)

// TODO: sun-dried tofu + soyburger juice
// TODO: rotten tomato
// TODO: pr0n cocktail

// TODO: beer nuts + food mods, beer nuts + mug/shotglass (?)
// TODO: same for toasted brie
// TODO: brie with nightcap (separate)
// TODO: technically, fullness helpers should be in booze phase, as this can check fullness...

// TODO: Pantsgiving
// TODO: timespinner
// TODO: ghost pepper and Gets-You-Drunk
// TODO: knuckle sandwich

// TODO: pocket wish for (field-gar)

var k_epsilon = 0.000001

var chocolate_starting_weapon_lookup = {
	1: "chocolate seal-clubbing club",
	2: "chocolate turtle totem",
	3: "chocolate pasta spoon",
	4: "chocolate saucepan",
	5: "chocolate disco ball",
	6: "chocolate stolen accordion"
}

function desc_number(n) {
	if (n < 0) return "-" + desc_number(-n)
	if (n > 3000000000) return (n / 1000000000.0).toFixed(1) + "G"
	else if (n > 3000000) return (n / 1000000.0).toFixed(1) + "M"
	else if (n > 3000) return (n / 1000.0).toFixed(1) + "k"
	else if (Math.floor(n) == n) return n.toFixed(0)
	else return n.toFixed(1)
}

function tehtmi_sortkey(diet_item, mods) {
	var c = diet_item["spec"]["item"]
	var is_nightcap = diet_item["is_nightcap"]
	//if (c["type"] == "modifier") return 0
	if (c["type"] == "extender") return 1
	else if (c["type"] == "simple") return 2
	else if (!c["type"]) return 3
	else if (c["name"] == "fortune cookie") return 1000
	else if (c["type"] == "food") return 1010
	else if (c["type"] == "booze" && !is_nightcap) return 2000
	else if (c["type"] == "booze" && is_nightcap) return 3000
	else if (c["type"] == "spleen") return 4000
	else return -1000
}

function calculate_munchies(adv) {
	if(adv <= 3) {
		return 3
	} else if(adv <= 6) {
		return 2
	} else {
		return 1
	}
}

function tehtmi(diet_settings) {
	var before = new Date().getTime()
	
	var adv_value = diet_settings["adventure value"]
	var fight_value = diet_settings["pvp fight value"]
	var classid = diet_settings["classid"]
	var include_nightcap = (diet_settings["include nightcap"] == "yes") || (diet_settings["include nightcap"] == "limited")
	var with_saucemaven = diet_settings["saucemaven available"]
	var with_pizzalover = diet_settings["pizza lover available"]
	var with_recall = diet_settings["ancestral recall available"]
	var with_breakfast = diet_settings["spaghetti breakfast available"]
	var with_cold_one = diet_settings["grab a cold one available"]
	var try_field_gar = (diet_settings["use potion of the field gar"] == "yes")
	var tuxedo_available = diet_settings["tuxedo shirt available"]
	var tps_available = diet_settings["tiny plastic sword available"]
	var mafia_ring_available = diet_settings["mafia pinky ring available"]
	var mime_shotglass_available = diet_settings["mime army shotglass available"]
	var use_speakeasy = diet_settings.speakeasy
	var semirares_available = diet_settings["semirares available"]
	
	var use_nightcap_limit = diet_settings["include nightcap"] == "limited" && include_nightcap
	var nightcap_limit = diet_settings["nightcap limit"]
	// smm: strict -- never plan past the limit (adventures past it are lost to
	// the 200-adventure cap), instead of counting what's past it as worthless
	var strict_nightcap_limit = use_nightcap_limit && diet_settings["strict nightcap limit"]
	// smm: single-drink overdrink candidates, chosen outside the optimizer
	// (with "include nightcap" "no"): booze needing no stomach or spleen. Kept
	// only if no other is at least as many adventures for no more cost
	// (cost = adv * adv_value - value), so any adventure cap still finds the best.
	var overdrink_list = diet_settings["overdrink candidates"] ? [] : null

	var workshed = diet_settings["workshed"]

	// smm: daily counters the page assumed were all unused
	var affirmation_bonus = diet_settings["affirmation bonus"]
	var speakeasy_left = diet_settings["speakeasy drinks left"]
	var recall_left = diet_settings["ancestral recall casts left"]
	var chocolates_used = diet_settings["chocolates used"]

	var excluded = diet_settings["excluded consumables"]
	
	var organ_settings = diet_settings["organ sizes"]
	var stomach = organ_settings[0]
	var liver = organ_settings[1]
	var spleen = organ_settings[2]
	
	//for(var idx in chocolate_starting_weapon_lookup) {
	//	console.log(idx, idx == 1, chocolate_starting_weapon_lookup[1], chocolate_starting_weapon_lookup["1"])
	//}
	
	var chocolate_starting_weapon_name = chocolate_starting_weapon_lookup[classid]
	//console.log(chocolate_starting_weapon_name)
	
	var fortune_value = semirare_value
	var fortune_cookie_turns = 1.25
	var lucky_lindy_turns = 1
	
	var fork_item
	var spork_item
	var munchies_item
	var frosty_mug_item
	var shotglass_item
	var field_gar_item
	var beer_nuts_item
	var brie_item
	var wish_item
	var blue_mana_item
	var x_tattoo_item
	var taco_sauce_item
	var dieting_pill_item
	var special_seasoning_item
	var mayoflex_item
	var mayodiol_item
	
	for(var idx in diet_consumables) {
		var item = diet_consumables[idx]
		if(!excluded[item.name]) {
			item["idx"] = idx
			if(item["name"] == "Ol' Scratch's salad fork") {
				fork_item = item
			} else if(item["name"] == "fudge spork") {
				spork_item = item
			} else if(item["name"] == "munchies pill") {
				munchies_item = item
			} else if(item["name"] == "Frosty's frosty mug") {
				frosty_mug_item = item
			} else if(item["name"] == "BGE shotglass") {
				shotglass_item = item
			} else if(item["name"] == "potion of the field gar") {
				field_gar_item = item
			} else if(item["name"] == "packet of beer nuts") {
				beer_nuts_item = item
			} else if(item["name"] == "toasted brie") {
				brie_item = item
			} else if(item["name"] == "pocket wish") {
				wish_item = item
			} else if(item["name"] == "blue mana") {
				blue_mana_item = item
			} else if(item["name"] == "temporary X tattoos") {
				x_tattoo_item = item
			} else if(item["name"] == "Taco Dan's Super Taco-Riffic Taco Sauce!") {
				taco_sauce_item = item
			} else if(item["name"] == "dieting pill") {
				dieting_pill_item = item
			} else if(item["name"] == "Special Seasoning") {
				special_seasoning_item = item
			} else if(item["name"] == "Mayoflex") {
				mayoflex_item = item
			} else if(item["name"] == "Mayodiol") {
				mayodiol_item = item
			}
		}
	}
	
	function calculate_adventures(item, opts) {
		var sum = 0.0
		var count = 0.0
		if(item["advmax"] == 0) return 0
		for(var base_adv = item["advmin"]; base_adv <= item["advmax"]; ++base_adv) {
			var adv = base_adv
			
			if(opts["munchies pill"]) {
				adv += calculate_munchies(adv)
			}
			
			var wine_bonus = 0
			if(mafia_ring_available && item["item class"] == "wine") {
				wine_bonus += Math.floor(0.5 + 0.5 * Math.floor(adv * 0.25))
			}
			
			if(opts["brie"] && item["item class"] == "wine") {
				wine_bonus += Math.floor(adv * 0.25)
			}
			
			adv = adv + wine_bonus
			
			if(opts["salad fork"]) {
				if(item["item class"] == "salad") {
					adv = Math.ceil(adv * 1.5)
				} else {
					adv = Math.ceil(adv * 1.3)
				}
			} else if(opts["fudge spork"]) {
				adv += 3
			} else if(opts["frosty mug"]) {
				if(item["item class"] == "beer") {
					adv = Math.floor(adv * 1.5)
				} else {
					adv = Math.floor(adv * 1.3)
				}
			} else if(opts["shotglass"]) {
				adv += 3
			}
			if((opts["beer nuts"] || opts["beer nuts (wish)"]) && item["item class"] == "beer") {
				adv += 5
			}
			
			if(opts["taco sauce"] && item["item class"] == "taco") {
				adv += 1
			}
			
			if(item["type"] == "booze" && adv > 0) {
				// Ode to Booze
				adv += item["size"][1]
			}
			
			if(opts["gar-ish"] && item["item class"] == "lasagna") {
				adv += 5
			}
			
			if(with_pizzalover && item["item class"] == "pizza") {
				adv += item["size"][0]
			}
			
			if(with_saucemaven && item["item class"] == "saucy food") {
				adv += 3
				if(classid == 3 || classid == 4) {
					adv += 2
				}
			}
			
			if(tuxedo_available && item["tuxedo boostable drink"]) {
				adv += 2
			}
			
			if(opts["mayoflex"]) {
				adv += 1
			}
			
			if(opts["special seasoning"]) {
				adv += 1
			}
			
			// item-specific bonuses counted separately AFTER bonuses from munchies/fork/etc
			
			if(item["name"] == "Affirmation Cookie") {
				adv += affirmation_bonus  // smm: was a flat +6; 0 under KoLmafia, whose data already includes it
			}

			// smm: KoLmafia's data already lists spaghetti breakfast and Cold One
			// at 6 adventures, so the page's +5 bonus for them is not added here.
			
			sum += adv
			count += 1.0
		}
		
		var result = sum / count
		
		if(opts["dieting pill"]) {
			result = result + (item["advmin"] + item["advmax"]) / 2
		}
		
		return result
		//var adv = (item["advmin"] + item["advmax"]) / 2
		//if(item["type"] == "booze" && adv > 0) {
		//	adv = adv + item["size"][1]
		//}
	}

	function calculate_price(item) {
		if(item.name == "spaghetti breakfast" && with_breakfast) {
			return 5
		} else if(item.name == "Cold One" && with_cold_one) {
			return 5
		} else if(tps_available && item["tpsprice"] && (!item["price"] || item["tpsprice"] < item["price"])) {
			return item["tpsprice"]
		} else if(use_speakeasy && item["speakeasy"]) {
			return item["speakeasy"]
		} else {
			return item["price"]
		}
	}

	function create_spec(item, opts, after_nightcap) {
		if(item["item class"] == "taco" && taco_sauce_item) {
			if(taco_sauce_item["price"] + k_epsilon < adv_value) {
				opts["taco sauce"] = true
			}
		}
		if(item["type"] == "food" && special_seasoning_item) {
			if(special_seasoning_item["price"] + k_epsilon < adv_value) {
				opts["special seasoning"] = true
			}
		}
		
		var adv = calculate_adventures(item, opts)
		var price = calculate_price(item)
		if(!price) return
		
		if(opts["munchies pill"]) price += munchies_item["price"]
		if(opts["taco sauce"]) price += taco_sauce_item["price"]
		if(opts["salad fork"]) price += fork_item["price"]
		if(opts["fudge spork"]) {
			price += spork_item["price"]
		}
		if(opts["frosty mug"]) price += frosty_mug_item["price"]
		if(opts["shotglass"]) price += shotglass_item["price"]
		if(opts["mayoflex"]) price += 1000
		if(opts["mayodiol"]) price += 1000
		if(opts["dieting pill"]) price += dieting_pill_item["price"]
		if(opts["special seasoning"]) price += special_seasoning_item["price"]
		var value = adv * adv_value - price
		var fvalue = 0
		if(opts["fortune"]) {
			var turn_penalty 
			if(item.name == "fortune cookie") {
				turn_penalty = fortune_cookie_turns
			} else if(item.name == "Lucky Lindy") {
				turn_penalty = lucky_lindy_turns
			} else {
				throw "error"
			}
			fvalue = fortune_value - turn_penalty * adv_value
			value += fvalue
		}
		var pvp = 0
		if(item["pvpfights"]) {
			pvp = item["pvpfights"]
			value += pvp * fight_value
		}
		// smm: flat extras the item gives once, not scaled by fork/mug/Ode
		if(item["bonusadv"]) {
			adv += item["bonusadv"]
			value += item["bonusadv"] * adv_value
		}
		if(item["bonusvalue"]) value += item["bonusvalue"]
		if(item["effectvalue"]) value += item["effectvalue"]  // smm: the effect it gives (see effectOf)
		var spec = {"item": item, "opts": opts, "value": value, "size": item["size"], "adv": adv, "pvp": pvp, "price": price, "limit": item["limit"]}
		
		if(opts["fortune"]) {
			spec.fortune_value = fvalue
		}
		
		if(item.speakeasy) {
			spec.limit = speakeasy_left  // smm: was 3
			spec.limit_key = "speakeasy"
		}
		
		if(opts["mayodiol"]) {
			var size = spec["size"]
			spec["size"] = [size[0] - 1, size[1] + 1, size[2]]
		} else if(after_nightcap) {
			var size = spec["size"]
			spec["size"] = [size[0], 0, size[2]]
			spec["after_nightcap"] = true
		}
		if(opts["beer nuts"]) {
			var size = spec["size"]
			spec["size"] = [size[0] + 1, size[1], size[2]]
			//spec["helper"] = create_spec(beer_nuts_item, {})
			spec["helper"] = optimize_food(beer_nuts_item)
			spec["value"] += spec["helper"]["value"]
			spec["helper"]["value"] = 0
		}
		if(opts["beer nuts (wish)"]) {
			spec["helper"] = {"item": wish_item, "value": 0, "size": [0, 0, 0], "price": wish_item["price"], "adv": 0, "opts": {"wish_salty_mouth": true}}
			spec["value"] -= wish_item["price"]
			//console.log("beer nuts value", spec["value"], spec.item.name)
		}
		if(opts["dieting pill"]) {
			var size = spec["size"]
			spec["size"] = [size[0] * 2, size[1], size[2] + 3]
		}
		//if(item.name == "Mr. Burnsger") console.log("create_spec test", item.name, spec.size, spec.limit)
		if(tuxedo_available && item["tuxedo boostable drink"]) {
			spec["tuxedo_boosted"] = true
		}
		return spec
	}
	
	var best_consumables = {}
	var best_field_gar_lasagna = {}
	var best_brie_wine = {}
	var limited_nightcaps = []
	
	function create_spec_and_test(item, opts, best_list) {
		best_list = best_list || best_consumables
		var spec = create_spec(item, opts, false)
		if(!spec || !spec.value) return
		var size = spec["size"]
		
		var key = size
		var after_nightcap_spec
		if(item["limit"]) {
			key = key + item["name"]
		} else if(item["speakeasy"]) {
			key = key + "speakeasy"
		}
		if(spec.opts && spec.opts["fortune"]) {
			key = key + "fortune"
		}
		if(spec.opts && spec.opts["fudge spork"]) {
			key = key + "spork"
		}
		if(spec.opts && spec.opts["mayodiol"]) {
			key = key + "mayodiol"
		} else if(include_nightcap && item["type"] == "food" && size[0] > 0 && size[1] > 0) {
			after_nightcap_spec = create_spec(item, opts, true)
		}
		
		var best = best_list[key]
		
		if(!best || spec["value"] > best["value"] + k_epsilon) {
			//if(opts["salad fork"]) console.log("fork", item["name"])
			best_list[key] = spec
		}
		
		function strict_nightcap_compare(spec1, spec2) {
			if(spec1.size[0] <= spec2.size[0] &&
			   spec1.size[2] <= spec2.size[2] &&
			   spec1.value + spec1.price >= spec2.value + spec2.price - k_epsilon &&
			   spec1.price <= spec2.price + k_epsilon ) {return true}
			else {return false}
		}
		
		if(use_nightcap_limit) {
			if(!spec.opts || (!spec.opts["mayodiol"] && !spec.opts["brie"])/* && !spec["limit"]*/) {
				if(size[1] > 0 && (spec.value > 0 || size[0] < 0 || size[2] < 0)) {
					var add_to_list = true
					for(var i = 0; i < limited_nightcaps.length; i++) {
						var other = limited_nightcaps[i]
						if(strict_nightcap_compare(spec, other)) {
							limited_nightcaps[i] = limited_nightcaps[limited_nightcaps.length - 1]
							i--
							limited_nightcaps.pop()
						} else if(strict_nightcap_compare(other, spec)) {
							add_to_list = false
							break
						}
					}
					if(add_to_list) {
						limited_nightcaps.push(spec)
					}
				}
			}
		}
		
		if(overdrink_list && item["type"] == "booze" && size[1] > 0 && size[0] <= 0 && size[2] <= 0 &&
		   !item["speakeasy"] && spec.value > k_epsilon &&  // limits are checked when choosing
		   !(spec.opts && (spec.opts["mayodiol"] || spec.opts["brie"] || spec.opts["fortune"]))) {
			var od_cost = function (s) { return s.adv * adv_value - s.value }
			// a limited drink may be used up by the rest of the plan, so it never rules others out
			var od_dominates = function (a, b) { return !a.item["limit"] && a.adv >= b.adv && od_cost(a) <= od_cost(b) + k_epsilon }
			var od_keep = true
			for(var odi = 0; odi < overdrink_list.length; odi++) {
				if(od_dominates(overdrink_list[odi], spec)) { od_keep = false; break }
			}
			if(od_keep) {
				overdrink_list = overdrink_list.filter(function (o) { return !od_dominates(spec, o) })
				overdrink_list.push(spec)
			}
		}

		if(after_nightcap_spec) {
			spec = after_nightcap_spec
			key = key + "after_nightcap"
			best = best_list[key]
			if(!best || spec["value"] > best["value"] + k_epsilon) {
				best_list[key] = spec
			}
		}
		
		//return spec
	}
	
	var food_flag_list = []
	var fork_flags = []
	if(fork_item) fork_flags.push({flag: "salad fork"})
	if(spork_item) fork_flags.push({flag: "fudge spork", complicated: true})
	food_flag_list.push(fork_flags)
	if(munchies_item) food_flag_list.push([{flag: "munchies pill"}])
	//if(dieting_pill_item) food_flag_list.push([{flag: "dieting pill"}])
	// smm: fortune cookies stopped giving semi-rares in the 2021 luck update, so
	// only Lucky Lindy (booze, below) still gets the "fortune" option.
	//if(semirares_available > 0) food_flag_list.push([{flag: "fortune"}])
	if(workshed == "mayo") {
		var mayo_flags = [];
		if(mayoflex_item) {
			mayo_flags.push({flag: "mayoflex"});
		}
		if(mayodiol_item) {
			mayo_flags.push({flag: "mayodiol", min_fullness: 2})
		}
		if(mayo_flags.length > 0) {
			food_flag_list.push(mayo_flags)
		}
	}
	if(try_field_gar && field_gar_item) {
		food_flag_list.push([{flag: "gar-ish", item_class: "lasagna", complicated: true, list: best_field_gar_lasagna}])
	}
	
	function create_food_variations(item) {
		food_variations_helper(item, false, best_consumables, {}, 0)
	}
	
	function get_simple_food_variations(item, list) {
		food_variations_helper(item, true, list, {}, 0)
	}
	
	function food_variations_helper(item, complicated, list, flags, idx) {
		if(idx < food_flag_list.length) {
			var family = food_flag_list[idx]
			food_variations_helper(item, complicated, list, flags, idx + 1)
			for(var jdx in family) {
				var fi = family[jdx]
				if(complicated && fi["complicated"]) {
					// nothing
				} else if(fi["item_class"] && fi["item_class"] != item["item class"]) {
					// nothing
				} else if(fi["min_fullness"] && item["size"][0] < fi["min_fullness"]) {
					// nothing
				} else if(fi["flag"] == "fortune" && !(item["name"] == "fortune cookie" && semirares_available > 0)) {
					// nothing
				} else {
					var rlist = list
					if(fi["list"]) rlist = fi["list"]
					var rcomplicated = complicated
					if(fi["complicated"]) rcomplicated = true
					flags[fi["flag"]] = true
					food_variations_helper(item, rcomplicated, rlist, flags, idx + 1)
					flags[fi["flag"]] = false
				}
			}
		} else {
			var opts = {}
			for(var flag in flags) {
				if(flags[flag]) {
					opts[flag] = true
				}
			}
			
			//console.log(item.name, opts)
			create_spec_and_test(item, opts, list)
		}
	}
	
	function optimize_food(item) {
		var temp_list = {}
		get_simple_food_variations(item, temp_list)
		return temp_list[item.size]
	}
	
	var field_gar_spec
	var extenders = []
	var simple = []
	var chocolate = []
	var nano_chocolate = []
	var tobacco_chocolate = []
	var sculpture_chocolate = []
	
	for(var idx in diet_consumables) {
		var item = diet_consumables[idx]
		if(item["name"] == "Cold One" ||
		   item["name"] == "spaghetti breakfast"
		) {
			item["limit"] = 1
			item.internal_limit = true
		}
		
		if(!excluded[item.name]) {
			
			if(item["type"] == "food" || item["type"] == "booze" || item["type"] == "spleen") {
				if(item["size"][0] <= stomach && item["size"][2] <= spleen) {
					if(item["type"] == "food") {
						create_food_variations(item)
					} else if(item["type"] == "booze") {
						create_spec_and_test(item, {})
						if(item.speakeasy) {
							if(item.name == "Lucky Lindy") {
								create_spec_and_test(item, {"fortune": true})
							}
						} else {
							if(frosty_mug_item) create_spec_and_test(item, {"frosty mug": true})
							if(shotglass_item) create_spec_and_test(item, {"shotglass": true})
							if(beer_nuts_item && item["item class"] == "beer") {
								create_spec_and_test(item, {"beer nuts": true})
								if(frosty_mug_item) create_spec_and_test(item, {"beer nuts": true, "frosty mug": true})
								if(shotglass_item) create_spec_and_test(item, {"beer nuts": true, "shotglass": true})
							}
							if(wish_item && item["item class"] == "beer") {
								create_spec_and_test(item, {"beer nuts (wish)": true})
								if(frosty_mug_item) create_spec_and_test(item, {"beer nuts (wish)": true, "frosty mug": true})
								if(shotglass_item) create_spec_and_test(item, {"beer nuts (wish)": true, "shotglass": true})
							}
							if((brie_item || wish_item) && item["item class"] == "wine") {
								create_spec_and_test(item, {"brie": true}, best_brie_wine)
								if(frosty_mug_item) create_spec_and_test(item, {"frosty mug": true, "brie": true}, best_brie_wine)
								if(shotglass_item) create_spec_and_test(item, {"shotglass": true, "brie": true}, best_brie_wine)
							}
						}
					} else {
						create_spec_and_test(item, {})
					}
				}
			} else if(item["type"] == "extender") {
				var spec = {"item": item, "value": -item["price"], "size": item["size"], "limit": item["limit"], "price": item["price"], "adv": 0}
				extenders.push(spec)
			} else if(item["type"] == "simple") {
				var adv = (item["advmin"] + item["advmax"]) / 2
				var pvp = item["pvpfights"]
				var value = adv * adv_value + pvp * fight_value - item["price"]
				var spec = {"item": item, "value": value, "adv": adv, "pvp": pvp, "price": item["price"], "limit": item["limit"]}
				simple.push(spec)
			}
			if(item["name"] == "potion of the field gar") {
				field_gar_spec = {"item": item, "value": -item["price"], "size": [0, 0, 0], "price": item["price"], "adv": 0}
			}
			if(item["name"] == "fancy chocolate" ||
			   item["name"] == "fancy but probably evil chocolate" ||
			   item["name"] == "fancy chocolate car" ||
			   item["name"] == "beet-flavored Mr. Mediocrebar" ||
			   item["name"] == "cabbage-flavored Mr. Mediocrebar" ||
			   item["name"] == "sweet-corn-flavored Mr. Mediocrebar" ||
			   item["name"] == "choco-Crimbot"
			) {
				chocolate.push({"item": item, "adv": [5, 3, 1]})
			}
			if(item["name"] == chocolate_starting_weapon_name) {
				chocolate.push({"item": item, "adv": [3, 2, 1]})
			} else if(item["name"] == "chocolate seal-clubbing club" ||
				item["name"] == "chocolate turtle totem" ||
				item["name"] == "chocolate pasta spoon" ||
				item["name"] == "chocolate saucepan" ||
				item["name"] == "chocolate disco ball" ||
				item["name"] == "chocolate stolen accordion"
			) {
				chocolate.push({"item": item, "adv": [2, 1, 0]})
			}
			if(item["name"] == "vitachoconutriment capsule") {
				nano_chocolate.push({"item": item, "adv": [5, 3, 1]})
			}
			if(item["name"] == "chocolate cigar") {
				tobacco_chocolate.push({"item": item, "adv": [5, 3, 1]})
			}
			if(item["name"] == "fancy chocolate sculpture") {
				sculpture_chocolate.push({"item": item, "adv": [5, 3, 1]})
			}
		}
	}
	
	//console.log("try field gar", try_field_gar)
	if(try_field_gar) {
		var field_gar_is_maybe_useful = false
		for(var idx in best_field_gar_lasagna) {
			var gar_ish_spec = best_field_gar_lasagna[idx]
			var normal_spec = best_consumables[idx]
			//console.log(gar_ish_spec.item.name, gar_ish_spec.value, normal_spec.item.name, normal_spec.value)
			if(gar_ish_spec.value > normal_spec.value + k_epsilon) {
				field_gar_is_maybe_useful = true
				break
			}
		}
		//console.log("field gar", field_gar_is_maybe_useful)
		if(!field_gar_is_maybe_useful) {
			try_field_gar = false
		}
	}
	
	//console.log(best_consumables[[1,0,0,0,0]]["item"]["name"])
	
	var normal_consumables_list = []
	for(var idx in best_consumables) {
		var spec = best_consumables[idx]
		var size = spec["size"]
		if(!spec["limit"] && !spec.opts["fudge spork"] && !spec.opts["fortune"]) {
			normal_consumables_list.push(spec)
		}
	}
	function quick_fill(fullness, drunkenness, spleen, idx, cache) {
		//console.log(fullness, drunkenness, spleen, idx)
		var key = [fullness, drunkenness, spleen]
		var memo = cache[key]
		if(memo) {
			return memo
		} else {
			var spec = normal_consumables_list[idx]
			var best_value = 0
			var best_result = "nothing"
			if(spec) {
				var size = spec["size"]
				best_value = quick_fill(fullness, drunkenness, spleen, idx + 1, cache)
				if(size[0] <= fullness && size[1] <= drunkenness && size[2] <= spleen && (size[0] > 0 || size[1] > 0 || size[2] > 0)) {
					var value = spec["value"] + quick_fill(fullness - size[0], drunkenness - size[1], spleen - size[2], idx, cache)
					if(value > best_value + k_epsilon) {
						best_value = value
						best_result = spec
					}
				}
			}
			//if(best_result != "nothing") console.log(best_result, key, idx)
			if(idx == 0) cache[key] = best_value
			return best_value
		}
	}
	
	function create_list() {
		return {"list":[], "limited":{}}
	}
	
	function add_to_list(list, spec) {
		//if(spec.item.name == "Mr. Burnsger") {
		//	console.log("Mr. Burnsger test", spec.size, spec.limit, spec.item.limit)
		//}
		if(spec["limit"] || spec.opts["fudge spork"] || spec.opts["fortune"]) {
			var limited_map = list["limited"]
			var key
			if(spec.limit) {
				key = spec.limit_key || spec.item.name
			} else if(spec.opts["fudge spork"]) {
				if(spec.opts["fortune"]) {
					key = "hybrid"
				} else {
					key = "fudge spork"
				}
			} else if(spec.opts["fortune"]) {
				key = "fortune"
			} else {
				console.log(spec)
				throw "error"
			}
			
			var limited_list = limited_map[key]
			if(!limited_list) {
				limited_list = []
				limited_map[key] = limited_list
			}
			limited_list.push(spec)
			//console.log(spec.item.name, key, limited_list.length, list)
		} else {
			list.list.push(spec)
		}
	}
	
	function resolve_list(list) {
		var final_list = []
		var fudge = []
		var hybrid = []
		var fortune = []
		var speakeasy = []
		for(var idx in list["limited"]) {
			var limited_list = list["limited"][idx]
			var offset = limited_list.length
			for(var j = 0; j < limited_list.length; j++) {
				var spec = limited_list[j]
				//console.log("create limited", spec.item.name, j, offset, spec["size"], idx)
				
				spec["offset"] = offset
				if(idx == "fudge spork") {
					fudge.push(spec)
				} else if(idx == "hybrid") {
					hybrid.push(spec)
				} else if(idx == "fortune") {
					fortune.push(spec)
				} else if(idx == "speakeasy") {
					speakeasy.push(spec)
				} else {
					final_list.push(spec)
				}
				offset--
			}
		}
		for(var i = 0; i < fudge.length; i++) {
			final_list.push(fudge[i])
		}
		for(var i = 0; i < hybrid.length; i++) {
			final_list.push(hybrid[i])
		}
		for(var i = 0; i < fortune.length; i++) {
			final_list.push(fortune[i])
		}
		for(var i = 0; i < speakeasy.length; i++) {
			final_list.push(speakeasy[i])
		}
		for(var i = 0; i < list.list.length; i++) {
			final_list.push(list.list[i])
		}
		return final_list
	}
	
	var food_items = create_list()
	var booze_helpers = create_list()
	var booze_real_items = create_list()
	var best_nightcaps = {}
	var spleen_items = []
	var quick_fill_cache = {}
	for(var idx in best_consumables) {
		var spec = best_consumables[idx]
		
		var size = spec["size"]
		var item = spec["item"]
		var has_mayodiol = spec["opts"] && spec["opts"]["mayodiol"]
		var has_fork = spec["opts"] && spec["opts"]["salad fork"]
		var has_spork = spec["opts"] && spec["opts"]["fudge spork"]
		var has_seasoning = spec["opts"] && spec["opts"]["special seasoning"]
		var post_nightcap = include_nightcap && !has_mayodiol && size[1] > 0 && item["type"] == "food"
		if(size[0] >= 0 && size[1] >= 0 && size[2] >= 0 && quick_fill(size[0], (post_nightcap ? 0 : size[1]), size[2], 0, quick_fill_cache) > spec["value"]) {
			//console.log("useless item (1): ", item["name"], " (mayodiol:", has_mayodiol, ")", " (spork:", has_spork, ") (fork", has_fork, ") (season ", has_seasoning, ")")
			//console.log(quick_fill(size[0], (post_nightcap ? 0 : size[1]), size[2], 0, quick_fill_cache), "; ", spec["value"])
			//var key__ = [15, 0, 0]
			//console.log(quick_fill_cache[ key__ + "spec" ])
		} else if(best_consumables[size] && best_consumables[size] != spec && best_consumables[size].value > spec.value + k_epsilon) {
			//console.log("useless item (2): ", item["name"], " (mayodiol:", has_mayodiol, ")", " (spork:", has_spork, ")")
		} else if(has_spork && best_consumables[spec.size + item.name] && best_consumables[spec.size + item.name].value > spec.value + k_epsilon) {
			//console.log("useless item (3): ", item["name"], " (mayodiol:", has_mayodiol, ")", " (spork:", has_spork, ")")
		} else {
			//console.log("useful item: ", item["name"], " (mayodiol:", has_mayodiol, ")", " (spork:", has_spork, ")")
			//console.log(best_consumables[spec.size + item.name] && best_consumables[spec.size + item.name].value, spec.value + k_epsilon)
			if(size[0] == 0 && size[1] == 0 && size[2] > 0 && item["type"] == "spleen") {
				spleen_items.push(spec)
			} else if(size[1] > 0 && size[2] <= 0 && item["type"] == "booze") {
				add_to_list(booze_real_items, spec)
			} else if(size[1] < 0) {
				add_to_list(booze_helpers, spec)
			} else if(size[1] > 0 || has_mayodiol || (mayodiol_item && item["type"] == "food" && item["limit"] && workshed == "mayo")) {
				add_to_list(booze_helpers, spec)
			} else if(spec["opts"] && (spec["opts"]["fudge spork"] || spec["opts"]["fortune"]) || spec.limit) {
				//if(include_nightcap && size[1] > 0 && item["type"] == "food") {
				//	spec.size = [spec.size[0], 0, spec.size[2]]
				//	spec.after_nightcap = true
				//}
				add_to_list(booze_helpers, spec)
			} else if(size[0] > 0 && item["type"] == "food") {
				add_to_list(food_items, spec)
			} else {
				console.log("unhandled item: " + item["name"] + ", " + spec.opts["dieting pill"])
			}
		}
		if(size[1] > 0 && !has_mayodiol) {
			var key = [size[0], size[2]]
			var best = best_nightcaps[key]
			if(!best || spec["value"] > best["value"] + k_epsilon) {
				best_nightcaps[key] = spec
			}
		}
	}
	
	if(use_nightcap_limit) {
		best_nightcaps = limited_nightcaps
	}
	
	//for(var idx in best_nightcaps) {
	//	var spec = best_nightcaps[idx]
	//	console.log(idx, spec.item.name, spec.opts, spec.adv, spec.price)
	//}
	//return
	
	var field_gar_food_items = []
	if(try_field_gar) {
		for(var idx in food_items) {
			var spec = food_items[idx]
			var size = spec.size
			// TODO: optimize
			field_gar_food_items[idx] = spec
		}
		for(idx in best_field_gar_lasagna) {
			field_gar_food_items.push(best_field_gar_lasagna[idx])
		}
	}
	
	food_items = resolve_list(food_items)
	booze_real_items = resolve_list(booze_real_items)
	booze_helpers = resolve_list(booze_helpers)
	
	if(try_field_gar) {
		var list = food_items
		var method = "push"
		if(workshed == "mayo" && mayodiol_item) {
			list = booze_helpers
			method = "unshift"
		}
		field_gar_spec["limit"] = 1
		field_gar_spec["skip"] = field_gar_food_items.length
		if(method == "push") list.push(field_gar_spec)
		for(var i = 0; i < field_gar_food_items.length; i++) {
			list[method](field_gar_food_items[i])
		}
		if(method == "unshift") list.unshift(field_gar_spec)
	}

	if(brie_item || wish_item) {
		//var brie_spec = create_spec(brie_item, {})
		var brie_spec
		var wish_spec
		if(brie_item) {
			brie_spec = optimize_food(brie_item)
		}
		if(wish_item) {
			wish_spec = {"item": wish_item, "value": -wish_item["price"], "size": [0, 0, 0], "price": wish_item["price"], "adv": 0, "opts": {"wish_refined_palate": true}}
		}
		//var count = 0
		var brie_list = []
		for(var idx in best_brie_wine) {
			//count = count + 1
			var spec = best_brie_wine[idx]
			var quick_value = quick_fill(spec.size[0], spec.size[1], spec.size[2], 0, quick_fill_cache)
			//console.log(spec.item.name, spec.value, quick_value)
			if(spec.value > quick_value + k_epsilon) {
				brie_list.push(spec)
			}
		}
		//console.log(brie_list.length, count)
		if(brie_list.length > 0) {
			if(brie_spec) {
				brie_spec["limit"] = 1
				if(wish_spec) {
					brie_spec["real-offset"] = 2
				} else {
					brie_spec["skip"] = brie_list.length
				}
				//console.log(brie_spec["offset"])
				booze_helpers.push(brie_spec)
			}
			if(wish_spec) {
				wish_spec["limit"] = 1
				wish_spec["skip"] = brie_list.length
				booze_helpers.push(wish_spec)
				//console.log(wish_spec.skip)
			}
			//console.log(brie_spec.skip)
			
			for(var i = 0; i < brie_list.length; i++) {
				booze_helpers.push(brie_list[i])
			}
		}
	}
	
	// Calculate intervals for possible value of each type of capacity.
	// This can be used to optimize out consideration of capacity helpers in cases where they are way too expensive.
	// (Or theoretically, force include them cases where they are obviously valuable.)
	// (This must be after brie/field-gar, as these increase the potential max value at margin. Don't consider for min, though.)
	
	var fullness_min_value = quick_fill(1, 0, 0, 0, quick_fill_cache)
	var drunk_min_value = quick_fill(0, 1, 0, 0, quick_fill_cache)
	var spleen_min_value = quick_fill(0, 0, 1, 0, quick_fill_cache)
	
	function find_max_value(items, size_idx, exclude, min_values, feedback_values) {
		var max_value = 0
		//var best_name
		for(var idx in items) {
			var spec = items[idx]
			if(!exclude[spec.item.name] && spec.size[size_idx] > 0) {
				var value = spec["value"]
				for(var si = 0; si < 3; si++) {
					if(size_idx != si && spec.size[si] != 0) {
						if(spec.size[si] > 0) {
							value -= min_values[si] * spec.size[si]
						} else {
							value += feedback_values[si] * -spec.size[si]
						}
					} else if(size_idx == si) {
						value -= min_values[si] * (spec.size[si] - 1)
					}
				}
				if(value > max_value + k_epsilon) {
					max_value = value
					//best_name = spec.item.name
				}
			}
		}
		//console.log("best item: ", best_name)
		return max_value
	}
	
	var all_food_booze_list = []
	for(var idx in food_items) {
		all_food_booze_list.push(food_items[idx])
	}
	for(var idx in booze_real_items) {
		all_food_booze_list.push(booze_real_items[idx])
	}
	for(var idx in booze_helpers) {
		all_food_booze_list.push(booze_helpers[idx])
	}
	
	var min_values = [fullness_min_value, drunk_min_value, spleen_min_value]
	var spleen_max_value = find_max_value(spleen_items, 2, {}, min_values, [0, 0, 0])
	var fullness_max_value_nofeedback = find_max_value(all_food_booze_list, 0, {"Mr. Burnsger": true, "The Plumber's mushroom stew":true}, min_values, [0, 0, spleen_max_value])
	var drunkenness_max_value_nofeedback = find_max_value(all_food_booze_list, 1, {"Doc Clock's thyme cocktail": true, "The Mad Liquor":true}, min_values, [0, 0, spleen_max_value])
	// two feedback items can be used for each of fullness and drunkenness, so do two steps of feedback
	// -- stage 1 -- can eat Mr. Burnsger then drink booze that gives no fullness back
	var fullness_max_value_feedback0 = find_max_value(all_food_booze_list, 0, {}, min_values, [0, drunkenness_max_value_nofeedback, spleen_max_value])
	var drunkenness_max_value_feedback0 = find_max_value(all_food_booze_list, 1, {}, min_values, [fullness_max_value_nofeedback, 0, spleen_max_value])
	// -- stage 2 -- can eat Mr. Burnsger then drink thyme cocktail then another food (but not stew)
	var fullness_max_value_feedback1 = find_max_value(all_food_booze_list, 0, {}, min_values, [0, drunkenness_max_value_feedback0, spleen_max_value])
	var drunkenness_max_value_feedback1 = find_max_value(all_food_booze_list, 1, {}, min_values, [fullness_max_value_feedback0, 0, spleen_max_value])
	// -- stage 3 -- can eat Mr. Burnsger then drink thyme cocktail then stew then another booze but not Mad Liquor
	var fullness_max_value_feedback2 = find_max_value(all_food_booze_list, 0, {}, min_values, [0, drunkenness_max_value_feedback1, spleen_max_value])
	var drunkenness_max_value_feedback2 = find_max_value(all_food_booze_list, 1, {}, min_values, [fullness_max_value_feedback1, 0, spleen_max_value])
	// -- stage 4 -- can eat Mr. Burnsger then drink thyme cocktail then stew then Mad Liquor, then stop (correct)
	var fullness_max_value = find_max_value(all_food_booze_list, 0, {}, min_values, [0, drunkenness_max_value_feedback2, spleen_max_value])
	var drunkenness_max_value = find_max_value(all_food_booze_list, 1, {}, min_values, [fullness_max_value_feedback2, 0, spleen_max_value])
	
	//console.log("min values", fullness_min_value, drunk_min_value, spleen_min_value)
	//console.log("max values (no feedback)", fullness_max_value_nofeedback, drunkenness_max_value_nofeedback, spleen_max_value)
	//console.log("max values", fullness_max_value, drunkenness_max_value, spleen_max_value)
	
	function is_size_reducer_possibly_helpful(spec) {
		var value = spec.value
		if(spec.size[0] < 0) {
			value += fullness_max_value * -spec.size[0]
		}
		if(spec.size[1] < 0) {
			value += drunkenness_max_value * -spec.size[1]
		}
		if(spec.size[2] < 0) {
			value += spleen_max_value * -spec.size[2]
		}
		//if(value > k_epsilon) {console.log("Fullness reducer may be helpful", spec.item.name)}
		return value > k_epsilon
	}
	
	for(var idx in extenders) {
		var spec = extenders[idx]
		if(is_size_reducer_possibly_helpful(spec)) {
			if(spec.size[1] < 0) {
				booze_helpers.unshift(spec)
			} else if(spec.size[0] < 0) {
				food_items.unshift(spec)
			} else {
				spleen_items.unshift(spec)
			}
		}
	}
	
	var booze_items = []
	
	for(var idx in booze_helpers) {
		booze_items.push(booze_helpers[idx])
	}
	
	for(var idx in booze_real_items) {
		booze_items.push(booze_real_items[idx])
	}
	
	function best_spleen_iter(spleen_capacity, cache, nightcap_limit, nightcap_spleen, idx, is_nightcap) {
		var key = [spleen_capacity, nightcap_limit, nightcap_spleen, idx, is_nightcap]
		var memo = cache[key]
		if(memo) {
			return memo
		}
		else
		{
			var best = {"value": 0}
			if(!is_nightcap && use_nightcap_limit) {
				var new_capacity = spleen_capacity + nightcap_spleen
				var rest = best_spleen_iter(new_capacity, cache, nightcap_limit, 0, 0, true)
				if(rest["value"] > best["value"] + k_epsilon) {
					best = rest
				}
			}
			
			if(idx < spleen_items.length) {
				var spec = spleen_items[idx]
				var size = spec["size"][2]
				
				var best_i = -1
				var best_rest
				var best_value = best["value"]
				var best_adv_adjust = 0
				
				var limit = 1000
				if(spec["limit"]) {limit = spec["limit"]}
				for(var i = 0; i <= limit; i++) {
					var new_capacity = spleen_capacity - size * i
					var nightcap_adv = 0
					if(use_nightcap_limit && is_nightcap) {nightcap_adv = spec["adv"] * i}
					
					if(strict_nightcap_limit && nightcap_adv > nightcap_limit) break;  // smm
					var adv_adjust = 0
					var value_adjust = 0
					if(nightcap_limit < nightcap_adv) {
						adv_adjust = nightcap_adv - nightcap_limit
						value_adjust -= adv_adjust * adv_value
					}
					
					var rest = best_spleen_iter(new_capacity, cache, nightcap_limit - nightcap_adv + adv_adjust, nightcap_spleen, idx + 1, is_nightcap)
					
					var value = rest["value"] + i * spec["value"] + value_adjust
					if(value > best_value + k_epsilon) {
						best_i = i
						best_rest = rest
						best_value = value
						best_adv_adjust = adv_adjust
					}
					if(use_nightcap_limit && nightcap_adv > nightcap_limit) break;
					if(new_capacity < size) break;
				}
				if(best_i >= 0) {
					best = best_rest
					for(var i = 1; i <= best_i; ++i) {
						best = {"first": spec, "rest": best, "value": best["value"] + spec["value"]}
						if(best_adv_adjust > 0) {
							best["adv_override"] = spec["adv"] - best_adv_adjust
							best_adv_adjust = 0
						}
					}
					best["value"] = best_value
				}
			}
			
			cache[key] = best
			return best
		}
	}
	
	function best_spleen(spleen_capacity, cache, nightcap_limit, nightcap_spleen) {
		// smm: callers never pass nightcap_spleen, so on the page it was undefined,
		// spleen capacity became NaN in limited-nightcap mode, and plans used
		// more spleen than exists (31 of 15).
		nightcap_spleen = nightcap_spleen || 0
		var key = [spleen_capacity, nightcap_limit, nightcap_spleen]
		var memo = cache[key]
		if(memo)
		{
			return memo
		}
		else
		{
			var spleen_cache = cache["spleen"]
			if(!spleen_cache) {
				spleen_cache = {}
				cache["spleen"] = spleen_cache
			}
			
			var best = best_spleen_iter(spleen_capacity, spleen_cache, nightcap_limit, nightcap_spleen, 0, false)
			
			if(!best) {
				best = {"value": 0.0}
			}
			
			cache[key] = best
			return best
		}
	}
	
	function best_food_iter(capacity, cache, idx, food_cache, food_list, nightcap_limit, nightcap_spleen) {
		var fullness = capacity[0]
		var key = [capacity[0], capacity[2], idx, nightcap_limit, nightcap_spleen]
		var memo = food_cache[key]
		if(memo) {
			return memo
		} else {
			var best
			
			var spec = food_list[idx]
			if(!spec) {
				best = best_spleen(capacity[2], cache, nightcap_limit, nightcap_spleen)
				//console.log("spleen best", best)
				
				//console.log("done food")
				
			} else {
				var nightcap_size = 0
				if(use_nightcap_limit && spec["after_nightcap"]) {
					nightcap_size = spec["adv"]
				}
				
				var limit = 1000
				if(spec["limit"]) {limit = spec["limit"]}
				//if(spec.item.name == "Kudzu salad") {console.log("food", spec.item.name, spec.value)}
				//if(spec.item.name == "tin cup of mulligan stew") {console.log("food", spec.item.name, spec.value)}
				var size = spec["size"]
				var best_i = -1
				var best_rest
				var best_value
				var best_adv_adjust = 0
				for(var i = 0; i <= limit; i++) {
					//console.log(spec.item.name)
					var new_capacity = [capacity[0] - i * size[0], -1000, capacity[2] - i * size[2]]
					if(strict_nightcap_limit && i * nightcap_size > nightcap_limit) break;  // smm
					var adv_adjust = 0
					var value_adjust = 0
					if(nightcap_limit < i * nightcap_size) {
						adv_adjust = i * nightcap_size - nightcap_limit
						value_adjust -= adv_adjust * adv_value
						//console.log(spec.item.name, i, nightcap_limit, nightcap_size, adv_adjust, value_adjust)
					}
					//if(spec["offset"]) console.log("has offset", spec.item.name, spec["offset"])
					var offset = 1
					if(i > 0 && spec["offset"]) {offset = spec["offset"]}
					if(i == 0 && spec["skip"]) {offset += spec["skip"]}
					var rest = best_food_iter(new_capacity, cache, idx + offset, food_cache, food_list, nightcap_limit - i * nightcap_size + adv_adjust)
					//console.log("food rest", rest)
					var value = rest["value"] + i * spec["value"] + value_adjust
					if(best_i < 0 || value > best_value + k_epsilon) {
						best_i = i
						best_rest = rest
						best_value = value
						best_adv_adjust = adv_adjust
					}
					if(new_capacity[0] < size[0]) break;
					if(use_nightcap_limit && nightcap_size * i > nightcap_limit) break;
				}
				best = best_rest
				//console.log("food end", best, spec["item"]["name"], best_i)
				for(var i = 1; i <= best_i; ++i) {
					best = {"first": spec, "rest": best, "value": best["value"] + spec["value"]}
					if(best_adv_adjust > 0) {
						//console.log("adjusted", spec.item.name, best_adv_adjust)
						best["adv_override"] = spec["adv"] - best_adv_adjust
						best_adv_adjust = 0
					}
					//if(size[1] > 0) best["after_nightcap"] = true
				}
				best["value"] = best_value
			}
			
			food_cache[key] = best
			return best
		}
	}
	
	function best_food(capacity, cache, nightcap_limit, nightcap_spleen) {
		var best = best_food_iter(capacity, cache, 0, cache, food_items, nightcap_limit, nightcap_spleen)
		return best
	}
	
	function best_booze(capacity, cache, idx, spork, semirare, limit_count, nightcap_limit, free_one_drunk) {
		var drunkenness = capacity[1]
		if(drunkenness < 0) { drunkenness = -1000 }
		if(idx > last_spork) { spork = false }
		if(idx > last_fortune) { semirare = 0 }
		var key = [capacity[0], capacity[1], capacity[2], idx, spork, semirare, limit_count, nightcap_limit, free_one_drunk]
		var memo = cache[key]
		if(memo) {
			return memo
		} else {
			var best
			
			var spec = booze_items[idx]
			if(!spec) {
				// nightcap
				var no_nightcap_capacity = [capacity[0], -1000, capacity[2]]
				var best_nightcap = best_food(no_nightcap_capacity, cache, nightcap_limit)
				
				if(x_tattoo_item && drunkenness >= 0) {
					var rest = best_nightcap
					var adv = Math.ceil((drunkenness + 1) * 4.5)
					var price = x_tattoo_item["price"]
					var value = adv * adv_value - price
					//console.log("xx value", value, adv, adv_value, price)
					if(value > k_epsilon) {
						var spec = {"item": x_tattoo_item, "value": value, "adv": adv, "price": price}
						best_nightcap = {"first": spec, "rest": rest, "value": value + rest["value"]}
					}
				}
				
				if(include_nightcap) {
					for(var idx in best_nightcaps) {
						var spec = best_nightcaps[idx]
						//console.log("nightcap", spec.item.name, idx)
						
						if(strict_nightcap_limit && spec["adv"] > nightcap_limit) continue;  // smm
						if(spec["item"]["type"] == "booze" && capacity[0] >= spec["size"][0] && !spec["limit"]) {
							var value_adjust = 0
							var adv = spec["adv"]
							if(use_nightcap_limit && adv > nightcap_limit) {
								value_adjust -= (adv - nightcap_limit) * adv_value
								adv = nightcap_limit
							} else if(!use_nightcap_limit) {
								adv = 0
							}
							var new_capacity = [capacity[0] - spec["size"][0], -1000, capacity[2] - spec["size"][2]]
							var rest = best_food(new_capacity, cache, nightcap_limit - adv)
							var value = rest["value"] + spec["value"] + value_adjust
							if(value > best_nightcap["value"] + k_epsilon) {
								best_nightcap = {"first": spec, "rest": rest, "value": value, "is_nightcap": true}
								if(value_adjust < 0) {
									best_nightcap["adv_override"] = adv
								}
								if(spec.helper) {
									best_nightcap = {"first": spec.helper, "rest": best_nightcap, "value": best_nightcap["value"]}
								}
							}
						}
					}
				}
				
				return best_nightcap
				
				//console.log("trying food with: ", new_capacity, best["value"])
			} else {
				//console.log("try booze", idx, spec["item"]["name"], capacity)
				var limit = 1000
				if(spec["limit"]) {limit = spec["limit"] - limit_count}
				var size = spec["size"]
				var has_mayodiol = spec.opts && spec.opts.mayodiol
				var with_beer_nuts = spec.opts && spec.opts["beer nuts"]
				//var with_brie = spec.opts && spec.opts["brie"]
				var using_spork = spec.opts && spec.opts["fudge spork"]
				var fortune = spec.opts && spec.opts["fortune"]
				if(using_spork) {limit = Math.min(1, limit)}
				if(using_spork && !spork) {limit = 0}
				if(fortune) {limit = Math.min(semirare, limit)}
				
				var fullness_offset = has_mayodiol ? 1 : 0
				var nightcap_size = 0
				if(use_nightcap_limit && spec["after_nightcap"]) {
					nightcap_size = spec.adv
				}
				var best_i = -1
				var best_rest
				var best_value
				var best_free
				for(var i = 0; i <= limit; i++) {
					var new_capacity = [capacity[0] - i * size[0], capacity[1] - i * size[1], capacity[2] - i * size[2]]
					var free_drunk_used = 0
					if(i > 0 && free_one_drunk > 0 && size[1] == 1 && spec["item"]["type"] == "booze") {
						free_drunk_used = Math.min(i, free_one_drunk)
						new_capacity[1] += free_drunk_used
					}
					var offset = 1
					if(i > 0 && spec["real-offset"]) {offset = spec["real-offset"]}
					var new_limit_count = 0
					if(spec["limit"] && spec["offset"] && spec["offset"] > 1) new_limit_count = i + limit_count
					if(i == 0 && spec["skip"]) {offset += spec["skip"]}
					
					var rest = best_booze(new_capacity, cache, idx + offset, (i > 0 && using_spork) ? false : spork, fortune ? semirare - i : semirare, new_limit_count, nightcap_limit - nightcap_size * i, free_one_drunk - free_drunk_used)
					//console.log("booze rest", rest)
					var value = rest["value"] + i * spec["value"] - free_drunk_used * adv_value
					//if(idx == 2) {console.log("value", i, value, spec["item"]["name"])}
					if(best_i < 0 || value > best_value + k_epsilon) {
						best_i = i
						best_rest = rest
						best_value = value
						best_free = free_drunk_used
						//best_is_nightcap = new_capacity[1] < 0
					}
					if((new_capacity[0] - fullness_offset) < size[0] || new_capacity[1] < size[1]) {
						//if(idx == 5 && i >= 3) console.log("break on", i, idx, spec["item"]["name"], capacity, new_capacity)
						break
					}
					if(use_nightcap_limit && nightcap_size * (i + 1) > nightcap_size) {
						break
					}
				}
				//if(idx == 2) {console.log("best value", best_i, best_value, spec["item"]["name"])}
				best = best_rest
				for(var i = 1; i <= best_i; ++i) {
					var value = best["value"] + spec["value"]
					best = {"first": spec, "rest": best, "value": value}
					if(i <= best_free) {
						best["mime shotglass"] = true
						best["adv_override"] = spec["adv"] - 1
						best["value"] -= adv_value
					}
					if(with_beer_nuts) {
						best = {"first": spec.helper, "rest": best, "value": best["value"]}
					} else if(spec["helper"]) {
						best = {"first": spec.helper, "rest": best, "value": best["value"]}
					}
				}
			}
			
			cache[key] = best
			return best
		}
	}
	
	/*
	var to_delete = []
	for(var size in best_consumables) {
		var spec = best_consumables[size]
		size = spec["size"]
		if(size[0] >= 0 && size[1] >= 0 && size[2] >= 0 && (size[1] == 0 || size[0] + size[2] > 0)) {
			var replacement = best_diet(size, {})
			//console.log(size)
			//console.log(replacement)
			//console.log(replacement["value"] + " vs " + spec["value"])
			if(replacement["value"] > spec["value"] + k_epsilon) {
				to_delete.push(size)
			}
		}
	}
	for(var i in to_delete) {
		var size = to_delete[i]
		var spec = best_consumables[size]
		//console.log("deleting: " + spec["item"]["name"])
		delete best_consumables["size"]
	}*/
	
	// Find unspork and unfortune indices
	var last_spork = -1
	var last_fortune = -1
	for(var i = 0; i < booze_items.length; i++) {
		var spec = booze_items[i]
		if(spec.opts) {
			if(spec.opts["fudge spork"]) {
				last_spork = i
			}
			if(spec.opts.fortune) {
				last_fortune = i
			}
		}
	}
	
	var free_one_drunk = 0
	if(mime_shotglass_available) {
		free_one_drunk += 1
	}
	var diet = best_booze([stomach, liver, spleen], {}, 0, true, semirares_available, 0, nightcap_limit, free_one_drunk)
	//console.log("done")
	
	// chocolate time!
	function try_chocolate(chocolate_list, already_used) {
		for(var i = already_used || 0; i < 3; ++i) {  // smm: skip chocolates already eaten today
			var best = false
			for(var idx in chocolate_list) {
				var entry = chocolate_list[idx]
				var item = entry.item
				var adv = entry.adv[i]
				if(adv > 0) {
					var value = adv * adv_value - item["price"]
					//console.log("chocolate", item["name"], i + 1, value)
					// {"item": item, "opts": opts, "value": value, "size": item["size"], "adv": adv, "price": price, "limit": item["limit"]}
					var spec = {"item": item, "value": value, "adv": adv, "price": item["price"]}
					if(value > k_epsilon) {
						var chocolate_diet = {"first": spec, "rest": diet, "value": diet["value"] + value}
						if(!best || chocolate_diet["value"] > best["value"] + k_epsilon) {
							best = chocolate_diet
						}
					}
				}
			}
			if(best) {
				diet = best
			} else {
				break
			}
		}
	}
	
	try_chocolate(chocolate, chocolates_used.fancy)
	try_chocolate(nano_chocolate, chocolates_used.vitachoc)
	try_chocolate(tobacco_chocolate, chocolates_used.cigar)
	try_chocolate(sculpture_chocolate, chocolates_used.sculpture)

	if(blue_mana_item && with_recall && recall_left > 0) {
		var spec = {
			"item": {
				"name": "Ancestral Recall",
				"advmin": 3,
				"advmax": 3,
				"price": blue_mana_item.price,
				"specialprice": "1 blue mana",
			},
			"value": 3 * adv_value - blue_mana_item.price,
			"adv": 3,
			"pvp": 0,
			"price": blue_mana_item.price,
			"limit": recall_left,  // smm: was 10
		}
		simple.push(spec)
	}
	
	function try_add_item(item, count, adv, pvp) {
		if(item) {
			var value = adv * adv_value + pvp * fight_value - item["price"]
			if(value > k_epsilon) {
				var spec = {"item": item, "value": value, "adv": adv, "pvp": pvp, "price": item["price"]}
				for(var i = 0; i < count; i++) {
					diet = {"first": spec, "rest": diet, "value": diet["value"] + value}
				}
			}
		}
	}
	
	for(var idx in simple) {
		var spec = simple[idx]
		var value = spec["value"]
		if(value > k_epsilon) {
			for(var i = 0; i < spec["limit"]; i++) {
				diet = {"first": spec, "rest": diet, "value": diet["value"] + value}
			}
		}
	}
	
	var after = new Date().getTime()
	//console.log("time taken", after - before)
	
	// convert to Eleron's format
	// smm: a function, so overdrink candidates get rows in the same format
	function diet_rows(diet) {
		var diet_map = {}
		var node = diet
		while(node["first"]) {
			var spec = node["first"]
			//console.log(spec.item.name)
			var key = spec["desc"]
			if(!key) {key = spec["item"]["name"]}
			var is_nightcap = node["is_nightcap"]
			var is_fortune = spec.opts && spec.opts["fortune"]
			var has_mayodiol = spec["opts"] && spec.opts["mayodiol"]
			var using_spork = spec["opts"] && spec.opts["fudge spork"]
			var with_beer_nuts = spec.opts && (spec.opts["beer nuts"] || spec.opts["beer nuts (wish)"])
			var with_brie = spec.opts && spec.opts["brie"]
			var wish_refined_palate = spec.opts && spec.opts["wish_refined_palate"]
			var wish_salty_mouth = spec.opts && spec.opts["wish_salty_mouth"]
			var with_mime_shotglass = node["mime shotglass"]
			var with_dieting_pill = spec.opts && spec.opts["dieting pill"]
			var with_special_seasoning = spec.opts && spec.opts["special seasoning"]
			if(is_nightcap) {
				key += " (nightcap)"
			}
			if(is_fortune) {
				key += " (fortune)"
			}
			if(has_mayodiol) {
				key += " (mayodiol)"
			}
			if(using_spork) {
				key += " (fudge spork)"
			}
			if(with_beer_nuts) {
				key += " (with beer nuts)"
			}
			if(with_brie) {
				key += " (with brie)"
			}
			if(wish_refined_palate) {
				key += " (wish refined)"
			}
			if(wish_salty_mouth) {
				key += " (wish salty)"
			}
			if(with_mime_shotglass) {
				key += " (with mime shotglass)"
			}
			if(with_dieting_pill) {
				key += " (with dieting pill)"
			}
			if(with_special_seasoning) {
				key += " (with special seasoning)"
			}
			var entry = diet_map[key]
			if(!entry) {
				entry = {
					"spec": spec,
					"node": node,
					"amount": 1,
					"name": spec["item"]["name"],
					"turns": node["adv_override"] || spec["adv"],
					"fights": (spec["pvp"] || 0),
					"price": spec["price"],
					"value": spec["value"],
					"idx": spec["item"]["idx"],
					"is_nightcap": is_nightcap,
					"using_mime_shotglass": with_mime_shotglass,
					"fortune": 0,
					"fortune_value": spec["fortune_value"] || 0,
					//"after_nightcap": node["after_nightcap"]
				}
				diet_map[key] = entry
			} else {
				entry["amount"]++
				entry["turns"] += node["adv_override"] || spec["adv"]
				entry["fights"] += (spec["pvp"] || 0)
				entry["value"] += spec["value"]
			}
			node = node["rest"]
		}
		var diet_items = []
		for(idx in diet_map) {
			var item = diet_map[idx]
			var spec = item["spec"]
			item["desc"] = {
				"amount": item["amount"] + "x",
				"turns": "",//(item["turns"] ? item["turns"].toFixed(0) : ""),
				"idx": item["idx"],
				"price": item["price"].toFixed(0),
				"name": item["name"],
				"extra": [],
				"notes": (spec.item.specialprice || ""),
				"item": item,
			}
			
			if(item["fights"] && item["turns"]) {
				item.desc["turns"] = item.turns.toFixed(0) + " + " + item.fights.toFixed(0) + " PvP"
			} else if(item["turns"]) {
				item.desc["turns"] = item.turns.toFixed(0)
			} else if(item["fights"]) {
				item.desc["turns"] = item.fights.toFixed(0) + " PvP"
			}
			
			item["price"] *= item["amount"]
			
			var notes = []
			
			if(item["is_nightcap"]) {
				notes.push({type: "text", text: "nightcap"})
			} else if(item["after_nightcap"] || spec["after_nightcap"]) {
				notes.push({type: "text", text: "after nightcap"})
			}
			if(spec.opts && spec.opts["fortune"]) {
				item.fortune = item.amount
				item.fortune_value *= item.amount
				notes.push({type: "text", text: "semi-rare"})
			}
			if(spec.opts && spec.opts["wish_refined_palate"]) {
				notes.push({type: "effect", verb: "wish for", effect: "Refined Palate"})
			}
			if(spec.opts && spec.opts["wish_salty_mouth"]) {
				notes.push({type: "effect", verb: "wish for", effect: "Salty Mouth"})
			}
			if(spec.opts && spec.opts["salad fork"]) {
				notes.push({type: "item", verb: "using", item: fork_item, exclude: true})
			}
			if(spec.opts && spec.opts["fudge spork"]) {
				notes.push({type: "item", verb: "using", item: spork_item, exclude: true})
			}
			if(spec.opts && spec.opts["taco sauce"]) {
				notes.push({type: "item", verb: "with", item: taco_sauce_item, exclude: true})
			}
			if(spec.opts && spec.opts["frosty mug"]) {
				notes.push({type: "item", verb: "using", item: frosty_mug_item, exclude: true})
			}
			if(spec.opts && spec.opts["shotglass"]) {
				notes.push({type: "item", verb: "using", item: shotglass_item, exclude: true})
			}
			if(spec.opts && spec.opts["gar-ish"]) {
				notes.push({type: "effect", verb: "with", effect: "Gar-ish"})
			}
			if(spec.opts && (spec.opts["beer nuts"] || spec.opts["beer nuts (wish)"])) {
				notes.push({type: "effect", verb: "with", effect: "Salty Mouth"})
			}
			if(spec.item["item class"] == "wine" && mafia_ring_available) {
				notes.push({type: "item", verb: "wearing", item: {name: "mafia pinky ring"}, exclude: false})
			}
			if(spec.opts && spec.opts["brie"]) {
				notes.push({type: "effect", verb: "with", effect: "Refined Palate"})
			}
			if(spec.opts && spec.opts["munchies pill"]) {
				notes.push({type: "item", verb: "with", item: munchies_item, exclude: true})
			}
			if(spec.opts && spec.opts["dieting pill"]) {
				notes.push({type: "item", verb: "with", item: dieting_pill_item, exclude: true})
			}
			if(spec.opts && spec.opts["special seasoning"]) {
				notes.push({type: "item", verb: "with", item: special_seasoning_item, exclude: true})
			}
			if(spec.opts && spec.opts["mayoflex"]) {
				notes.push({type: "item", verb: "with", item: mayoflex_item, exclude: true})
			}
			if(spec.opts && spec.opts["mayodiol"]) {
				notes.push({type: "item", verb: "with", item: mayodiol_item, exclude: true})
			}
			if(spec["tuxedo_boosted"]) {
				notes.push({type: "item", verb: "wearing", item: {name: "tuxedo shirt"}, exclude: false})
			}
			if(item["using_mime_shotglass"]) {
				notes.push({type: "item", verb: "using", item: {name: "mime army shotglass"}, exclude: false})
			}
			for(var i in notes) {
				item.desc.extra.push(notes[i]);
			}
			
			//console.log("price", item["name"], item["price"], desc_number(item["price"]))
			item.sortkey = tehtmi_sortkey(item)
			diet_items.push(item)
		}
		
		diet_items.sort(function (a, b) {
			if (a.sortkey < b.sortkey) return -1
			if (a.sortkey > b.sortkey) return 1
			return a.name.localeCompare(b.name)
		})
		
		return diet_items
	}
	var diet_items = diet_rows(diet)
	var overdrinks = !overdrink_list ? [] : overdrink_list.map(function (spec) {
		return diet_rows({"first": spec, "rest": {}, "value": spec.value, "is_nightcap": true})[0]
	})
	return {diet_items: diet_items, value: diet.value, overdrinks: overdrinks}
}


// ===========================================================================
// smm: KoLmafia layer -- builds diet_consumables and diet_settings from live
// game data, runs tehtmi(), and prints the plan.
// ===========================================================================

var km = (function () {
	try { return require('kolmafia') } catch (e) { return null }  // null under node (tests)
})()

// Organ cleaning that KoLmafia lists only as a note tag ("-2 Drunkenness",
// "-5 spleen"): tag regex -> index into [fullness, drunkenness, spleen].
var CLEANING_TAG = /^-(\d+) (fullness|drunkenness|spleen)$/i
var ORGAN_INDEX = {"fullness": 0, "drunkenness": 1, "spleen": 2}

// Limited organ items: name -> [KoLmafia counter, uses allowed]. From
// KoLmafia's dailylimits.txt; the counter is a "true"/"false" flag or a count.
// Prefs without a leading underscore persist for the whole ascension.
var ORGAN_LIMITS = {
	"Kudzu salad": ["_kudzuSaladEaten", 1],
	"Miss Graves' vermouth": ["_missGravesVermouthDrunk", 1],
	"Mr. Burnsger": ["_mrBurnsgerEaten", 1],
	"The Plumber's mushroom stew": ["_plumbersMushroomStewEaten", 1],
	"The Mad Liquor": ["_madLiquorDrunk", 1],
	"Doc Clock's thyme cocktail": ["_docClocksThymeCocktailDrunk", 1],
	"Affirmation Cookie": ["_affirmationCookieEaten", 1],
	"Hodgman's blanket": ["_hodgmansBlanketDrunk", 1],
	"jar of fermented pickle juice": ["_pickleJuiceDrunk", 1],
	"extra-greasy slider": ["_extraGreasySliderEaten", 1],
	"tin cup of mulligan stew": ["_mulliganStewEaten", 1],
	"drippy caviar": ["_drippyCaviarUsed", 1],
	"drippy nugget": ["_drippyNuggetUsed", 1],
	"drippy plum(?)": ["_drippyPlumUsed", 1],
	"drippy pilsner": ["_drippyPilsnerUsed", 1],
	"glass of drippy wine": ["_drippyWineUsed", 1],
	"Pizza of Legend": ["pizzaOfLegendEaten", 1],
	"Calzone of Legend": ["calzoneOfLegendEaten", 1],
	"Deep Dish of Legend": ["deepDishOfLegendEaten", 1],
	"The Author's ink": ["_authorsInkUsed", 1],
	"The Inquisitor's unidentifiable object": ["_inquisitorsUnidentifiableObjectUsed", 1],
	"mansquito serum": ["_mansquitoSerumUsed", 1],
	"voodoo snuff": ["_voodooSnuffUsed", 1],
	"turkey blaster": ["_turkeyBlastersUsed", 3],
}

// Uses of a limited item left (today, or this ascension).
function limitLeft(limit) {
	var v = pref(limit[0])
	var used = v == "true" ? 1 : (v == "false" ? 0 : parseInt(v, 10) || 0)
	return Math.max(0, limit[1] - used)
}

// Spleen items whose value isn't adventures: name -> PvP fights.
var SPLEEN_PVP = {"Purple Beast energy drink": 3, "sweat-ade": 5}

// Equipment that adds organ capacity: name -> [slot, [stomach, liver, spleen]].
// Accessories share the three accessory slots.
var CAPACITY_GEAR = {
	"angelbone chopsticks": ["acc", [1, 0, 0]],
	"angelbone dice": ["acc", [0, 1, 0]],
	"devilbone rosary": ["acc", [0, 1, 0]],
	"devilbone corset": ["shirt", [1, 0, 0]],
	"angelbone totem": ["weapon", [0, 0, 1]],
	"devilbone greaves": ["pants", [0, 0, 1]],
}

// Clan speakeasy drinks, keyed by item id (names contain quotes / entities).
var SPEAKEASY = {
	7589: 250, 7590: 250, 7591: 250, 7592: 500, 7593: 500, 7594: 500,
	7595: 500, 7596: 5000, 7597: 10000, 7598: 20000, 7599: 100000,
}

// KoLmafia note tags -> the page's "item class".
var CLASS_TAGS = {
	"SAUCY": "saucy food", "PIZZA": "pizza", "TACO": "taco", "SALAD": "salad",
	"LASAGNA": "lasagna", "BEER": "beer", "WINE": "wine",
}

// Non-organ items the optimizer uses as helpers or chocolates.
var HELPERS = [
	"Ol' Scratch's salad fork", "fudge spork", "munchies pill", "Frosty's frosty mug",
	"BGE shotglass", "potion of the field gar", "pocket wish", "blue mana",
	"temporary X tattoos", "Taco Dan's Super Taco-Riffic Taco Sauce!", "Special Seasoning",
	"fancy chocolate", "fancy but probably evil chocolate", "fancy chocolate car",
	"beet-flavored Mr. Mediocrebar", "cabbage-flavored Mr. Mediocrebar",
	"sweet-corn-flavored Mr. Mediocrebar", "choco-Crimbot",
	"chocolate seal-clubbing club", "chocolate turtle totem", "chocolate pasta spoon",
	"chocolate saucepan", "chocolate disco ball", "chocolate stolen accordion",
	"vitachoconutriment capsule", "chocolate cigar", "fancy chocolate sculpture",
]

function pref(name) { return km.getProperty(name) }
function prefInt(name) { return parseInt(pref(name), 10) || 0 }
function prefBool(name) { return pref(name) == "true" }

// Organ-space extenders: [name, size, uses left today]
function extenderList() {
	return [
		["mojo filter", [0, 0, -1], 3 - prefInt("currentMojoFilters")],
		["spice melange", [-3, -3, 0], prefBool("spiceMelangeUsed") ? 0 : 1],
		["Ultra Mega Sour Ball", [-3, -3, 0], prefBool("_ultraMegaSourBallUsed") ? 0 : 1],
		["lupine appetite hormones", [-3, 0, 0], prefBool("_lupineHormonesUsed") ? 0 : 1],
		["sweet tooth", [-1, 0, 0], prefBool("_sweetToothUsed") ? 0 : 1],
		["distention pill", [-1, 0, 0], prefBool("_distentionPillUsed") ? 0 : 1],
		["cuppa Voraci tea", [-1, 0, 0], prefBool("_voraciTeaUsed") ? 0 : 1],
		["cuppa Sobrie tea", [0, -1, 0], prefBool("_sobrieTeaUsed") ? 0 : 1],
		["synthetic dog hair pill", [0, -1, 0], prefBool("_syntheticDogHairPillUsed") ? 0 : 1],
		["alien plant pod", [0, -3, 0], prefBool("_alienPlantPodUsed") ? 0 : 1],
		["alien animal milk", [-3, 0, 0], prefBool("_alienAnimalMilkUsed") ? 0 : 1],
	]
}

// Items that give adventures/fights without using an organ: [name, adv, pvp, uses left]
function simpleList() {
	return [
		["milk of magnesium", 5, 0, prefBool("_milkOfMagnesiumUsed") ? 0 : 1],
		["essential tofu", 5, 0, prefBool("_essentialTofuUsed") ? 0 : 1],
		["resolution: be more adventurous", 2, 0, Math.max(0, 5 - prefInt("_resolutionAdv"))],
		["Hunger&trade; Sauce", 3, 0, prefBool("_hungerSauceUsed") ? 0 : 1],
		["brain preservation fluid", 5, 0, prefBool("_brainPreservationFluidUsed") ? 0 : 1],
		["Twelve Night Energy", 12, 0, prefBool("_twelveNightEnergyUsed") ? 0 : 1],
		["confusing LED clock", -5, 5, prefBool("_confusingLEDClockUsed") ? 0 : 1],
		["Jerks' Health&trade; Magazine", 0, 1, Math.max(0, 5 - prefInt("_jerksHealthMagazinesUsed"))],
		["Meteorite-Ade", 0, 5, Math.max(0, 3 - prefInt("_meteoriteAdesUsed"))],
	]
}

var price_cache = {}

// Everything buildConsumables might price: organ items plus helpers, extenders and simple items.
function dietCandidates() {
	var list = []
	var all = km.Item.all()
	for (var i = 0; i < all.length; i++) {
		if (all[i].fullness > 0 || all[i].inebriety > 0 || all[i].spleen > 0) list.push(all[i])
	}
	var names = HELPERS.slice()
	var ext = extenderList(), simp = simpleList()
	for (var e = 0; e < ext.length; e++) names.push(ext[e][0])
	for (var k = 0; k < simp.length; k++) names.push(simp[k][0])
	names.push("magical sausage")
	for (var n = 0; n < names.length; n++) list.push(km.Item.get(names[n]))
	return list
}

// smm: Museum collection. Until you are #1 for an item, every copy you own is
// collection stock, not free food. smmMuseumPolicy.ash decides how many owned
// copies are spare (beyond the #1 target); only those may be eaten, and a
// bought item is bought fresh rather than taken from the reserved copies.
// JS can't require() the symlinked ASH file, so this asks through the gCLI.
var museum_spare = null  // item id -> {spare, liquid}; null when Museum data is unavailable

function loadMuseumSpare(items) {
	museum_spare = null
	var ids = [], seen = {}
	for (var i = 0; i < items.length; i++) {
		var id = km.toInt(items[i])
		if (seen[id] || km.availableAmount(items[i]) <= 0 || !km.isDisplayable(items[i])) continue
		seen[id] = true
		ids.push(id)
	}
	if (ids.length == 0) { museum_spare = {}; return }
	var out = ""
	try {
		out = km.cliExecuteOutput('ash import <smmMuseumPolicy.ash>; smmMuseumSpareList("' + ids.join(",") + '")')
	} catch (e) { out = "" }
	var m = /Returned: ([0-9:;]*)\s*$/.exec(out || "")
	if (!m) {
		km.print("Museum data unavailable: owned displayable items are kept out of the diet.", "orange")
		return
	}
	museum_spare = {}
	var rows = m[1].split(";")
	for (var r = 0; r < rows.length; r++) {
		var f = rows[r].split(":")
		if (f.length == 3) museum_spare[f[0]] = {spare: parseInt(f[1], 10), liquid: parseInt(f[2], 10)}
	}
}

// Owned copies the diet may use up.
function spareCopies(it) {
	var have = km.availableAmount(it)
	if (have <= 0 || !km.isDisplayable(it)) return have
	var entry = museum_spare && museum_spare[km.toInt(it)]
	return entry ? Math.min(have, entry.spare) : 0
}

// Owned copies the Museum still needs: never consumed.
function reservedCopies(it) {
	return Math.max(0, km.availableAmount(it) - spareCopies(it))
}

// Meat cost of one of an item: mall (or NPC store if cheaper). Untradeable
// items cost what a spare owned copy could otherwise be turned into (at least
// 1 meat) and are capped at the number of spare copies.
// Returns null when the item can't be had.
function priceOf(it, fresh) {
	var key = it.name
	if (!fresh && price_cache[key]) return price_cache[key]
	var p = 0
	if (it.tradeable) {
		p = fresh ? km.mallPrice(it) : km.historicalPrice(it)
		if (p <= 0 && !fresh) p = 0
	}
	var npc = km.npcPrice(it)
	if (npc > 0 && (p <= 0 || npc < p)) p = npc
	var result = null
	if (p > 0) {
		result = {price: p}
	} else {
		var spare = spareCopies(it)
		var entry = museum_spare && museum_spare[km.toInt(it)]
		var liquid = entry ? entry.liquid : km.autosellPrice(it)
		if (spare > 0) result = {price: Math.max(1, liquid), limit: spare, owned: true}
	}
	price_cache[key] = result
	return result
}

// Magical sausages: no fullness, 1 adventure each, 23 a day. Owned spare ones
// are free; more are ground from casings with a Kramco Sausage-o-Matic for
// 111 meat times the number made today (meat already in the grinder counts).
// Priced at the average cost of all of them, since at any sensible adventure
// value every one is worth eating.
function sausageEntry() {
	var it = km.Item.get("magical sausage")
	var left = 23 - prefInt("_sausagesEaten")
	if (left <= 0) return null
	var owned = Math.min(left, spareCopies(it))
	var make = 0, makeCost = 0
	var grinder = km.availableAmount(km.Item.get("Kramco Sausage-o-Matic&trade;")) > 0 ||
		km.availableAmount(km.Item.get("replica Kramco Sausage-o-Matic&trade;")) > 0
	if (grinder) {
		make = Math.min(left - owned, km.availableAmount(km.Item.get("magical sausage casing")))
		var made = prefInt("_sausagesMade")
		for (var j = 1; j <= make; j++) makeCost += 111 * (made + j)
		makeCost = Math.max(0, makeCost - prefInt("sausageGrinderUnits"))
	}
	var n = owned + make
	if (n <= 0) return null
	return {"name": it.name, "advmin": 1, "advmax": 1, "pvpfights": 0, "type": "simple",
		"size": [0, 0, 0], "limit": n, "price": Math.max(1, Math.round(makeCost / n)),
		"owned": true, "eat": true}
}

// smm: effects. A consumable that gives an effect (Sacramento wine: 50
// adventures of +50% Item Drop) is worth more than its adventures. Effects only
// wear off as you adventure, so every turn of one counts, whenever it is
// consumed. Each modifier below is worth a set amount of meat per adventure
// per point, given here as a fraction of the adventure value and anchored at
// +100% Item Drop = a fifth of an adventure. The rest are rough estimates
// relative to that for aftercore farming; override any of them with its option
// or preference (see effectRates). Left out: modifiers whose worth has no fixed
// sign or size (Combat Rate, Fumble, zone- and path-specific ones).
var EFFECT_MODIFIERS = {
	// drops
	"Item Drop": 0.002, "Item Drop Penalty": 0.002, "Sporadic Item Drop": 0.0005,
	"Meat Drop": 0.001, "Meat Drop Penalty": 0.001, "Sporadic Meat Drop": 0.00025,
	"Food Drop": 0.0005, "Booze Drop": 0.0005, "Candy Drop": 0.0005, "Gear Drop": 0.0005,
	"Hat Drop": 0.0005, "Weapon Drop": 0.0005, "Offhand Drop": 0.0005, "Shirt Drop": 0.0005,
	"Pants Drop": 0.0005, "Accessory Drop": 0.0005, "Spleen Drop": 0.0005, "Potion Drop": 0.0005,
	"Pickpocket Chance": 0.0005,
	// familiar
	"Familiar Weight": 0.005, "Hidden Familiar Weight": 0.005, "Familiar Weight Percent": 0.001,
	"Familiar Experience": 0.005, "Familiar Action Bonus": 0.0005, "Familiar Damage": 0.00002,
	// stats and experience
	"Experience": 0.0005, "Monster Level": 0.0002, "Monster Level Percent": 0.0002,
	"Muscle Experience": 0.0002, "Mysticality Experience": 0.0002, "Moxie Experience": 0.0002,
	"Muscle Experience Percent": 0.00005, "Mysticality Experience Percent": 0.00005,
	"Moxie Experience Percent": 0.00005,
	"Muscle": 0.00002, "Mysticality": 0.00002, "Moxie": 0.00002,
	"Muscle Percent": 0.00002, "Mysticality Percent": 0.00002, "Moxie Percent": 0.00002,
	// HP and MP (a cheaper skill is a negative Mana Cost)
	"Maximum HP": 0.000005, "Maximum MP": 0.000005, "Maximum HP Percent": 0.00001, "Maximum MP Percent": 0.00001,
	"HP Regen Min": 0.00002, "HP Regen Max": 0.00002, "MP Regen Min": 0.0002, "MP Regen Max": 0.0002,
	"Mana Cost": -0.001, "Stackable Mana Cost": -0.001, "Combat Mana Cost": -0.0005,
	// combat
	"Initiative": 0.00005, "Initiative Penalty": 0.00005,
	"Damage Absorption": 0.00001, "Damage Reduction": 0.0001,
	"Cold Resistance": 0.0002, "Hot Resistance": 0.0002, "Sleaze Resistance": 0.0002,
	"Spooky Resistance": 0.0002, "Stench Resistance": 0.0002,
	"Weapon Damage": 0.00002, "Weapon Damage Percent": 0.00002, "Ranged Damage": 0.00002,
	"Ranged Damage Percent": 0.00002, "Spell Damage": 0.00002, "Spell Damage Percent": 0.00002,
	"Cold Damage": 0.00002, "Hot Damage": 0.00002, "Sleaze Damage": 0.00002,
	"Spooky Damage": 0.00002, "Stench Damage": 0.00002,
	"Cold Spell Damage": 0.00002, "Hot Spell Damage": 0.00002, "Sleaze Spell Damage": 0.00002,
	"Spooky Spell Damage": 0.00002, "Stench Spell Damage": 0.00002,
	"Critical Hit Percent": 0.00005, "Spell Critical Percent": 0.00005,
	"Damage Aura": 0.00002, "Thorns": 0.00002,
}

// Meat per adventure per point of each valued modifier. "Item Drop" is set by
// option itemdrop=N, else preference smm.ItemDropValue, else its fraction
// above; the others likewise.
function effectRates(opts, adv_value) {
	var rates = {}
	for (var name in EFFECT_MODIFIERS) {
		var key = name.replace(/[^A-Za-z]/g, "")
		var v = parseFloat(opts[key.toLowerCase()])
		if (isNaN(v)) v = parseFloat(pref("smm." + key + "Value"))
		if (isNaN(v)) v = EFFECT_MODIFIERS[name] * adv_value
		if (v) rates[name] = v
	}
	return rates
}

// The effect one of an item gives and what it is worth: {name, turns, value},
// or null when it gives none or none of its modifiers is valued.
function effectOf(it, rates) {
	var eff = km.effectModifier(it, "Effect")
	if (!eff || !eff.name || eff.name == "none") return null
	var turns = km.numericModifier(it, "Effect Duration")
	if (!(turns > 0)) return null
	var perTurn = 0
	for (var name in rates) perTurn += km.numericModifier(eff, name) * rates[name]
	if (!perTurn) return null
	return {name: eff.name, turns: turns, value: Math.round(turns * perTurn)}
}

function parseAdventures(s) {
	var m = /^\s*(-?\d+(?:\.\d+)?)(?:\s*-\s*(-?\d+(?:\.\d+)?))?\s*$/.exec(s || "")
	if (!m) return [0, 0]
	var lo = parseFloat(m[1])
	return [lo, m[2] ? parseFloat(m[2]) : lo]
}

// bonus: {lucky: Lucky! effects wanted, effects: effectRates()}
function buildConsumables(excluded, bonus) {
	var cons = []
	var myLevel = km.myLevel()
	var items = km.Item.all()
	for (var i = 0; i < items.length; i++) {
		var it = items[i]
		var f = it.fullness, d = it.inebriety, s = it.spleen
		if (f <= 0 && d <= 0 && s <= 0) continue
		if (excluded[it.name]) continue
		if (it.levelreq > myLevel) continue
		if (it.quality == "pseudoitem") continue
		var tags = (it.notes || "").split(/\s*,\s*/)
		if (tags.indexOf("Vampyre") >= 0 || tags.indexOf("KOLHS") >= 0) continue

		var adv = parseAdventures(it.adventures)
		var entry = {
			"name": it.name, "advmin": adv[0], "advmax": adv[1],
			"type": f > 0 ? "food" : (d > 0 ? "booze" : "spleen"),
			"size": [f, d, s],
		}
		for (var t = 0; t < tags.length; t++) {
			var tag = tags[t].replace(/\s+$/, "")
			var clean = CLEANING_TAG.exec(tag)
			if (clean) entry.size[ORGAN_INDEX[clean[2].toLowerCase()]] -= parseInt(clean[1], 10)
			if (CLASS_TAGS[tag]) entry["item class"] = CLASS_TAGS[tag]
			if (tag == "MARTINI") entry["tuxedo boostable drink"] = "yes"
		}
		if (ORGAN_LIMITS[it.name]) {
			entry["limit"] = limitLeft(ORGAN_LIMITS[it.name])
			if (entry["limit"] <= 0) continue
		}
		if (SPLEEN_PVP[it.name]) entry["pvpfights"] = SPLEEN_PVP[it.name]
		if (it.name == "clovermint") {
			// Lucky! doesn't stack, so one is worth a clover; skip it if no Lucky! is wanted
			if (bonus.lucky <= 0 || km.haveEffect(km.Effect.get("Lucky!")) > 0) continue
			entry["bonusvalue"] = semirare_value
			entry["limit"] = 1
		}
		if (it.name == "Three Sheets to the Wind") {
			// Wetted Whistle: +10 adventures at rollover, if nothing is adventured
			// after it -- so it is always drunk in phase 3 (see splitPhases)
			entry["bonusadv"] = 10
			entry["limit"] = 1
		}

		var effect = bonus.effects ? effectOf(it, bonus.effects) : null
		if (effect) {
			entry["effect"] = effect
			entry["effectvalue"] = effect.value
		}

		var id = km.toInt(it)
		if (SPEAKEASY[id]) {
			entry["speakeasy"] = SPEAKEASY[id]
		} else if (it.name == "Cold One" || it.name == "spaghetti breakfast") {
			// priced by the optimizer (5 meat) when the skill is available;
			// otherwise only if you already have some
			var cp = priceOf(it)
			if (cp) { entry["price"] = cp.price; entry["owned"] = true }
		} else {
			var pr = priceOf(it)
			if (!pr) continue
			entry["price"] = pr.price
			if (pr.limit) {
				entry["limit"] = Math.min(entry["limit"] || pr.limit, pr.limit)
				entry["owned"] = true
			}
		}
		cons.push(entry)
	}

	for (var h = 0; h < HELPERS.length; h++) {
		var hi = km.Item.get(HELPERS[h])
		if (excluded[hi.name]) continue
		var hp = priceOf(hi)
		if (hp && !hp.owned) cons.push({"name": hi.name, "advmin": 0, "advmax": 0, "price": hp.price})
	}
	var sausage = sausageEntry()
	if (sausage && !excluded[sausage.name]) cons.push(sausage)
	if (km.getWorkshed().name == "portable Mayo Clinic") {
		cons.push({"name": "Mayoflex", "advmin": 0, "advmax": 0, "price": 1000})
		cons.push({"name": "Mayodiol", "advmin": 0, "advmax": 0, "price": 1000})
	}

	var ext = extenderList()
	for (var e = 0; e < ext.length; e++) {
		if (ext[e][2] <= 0 || excluded[ext[e][0]]) continue
		var ep = priceOf(km.Item.get(ext[e][0]))
		if (ep) cons.push({"name": ext[e][0], "advmin": 0, "advmax": 0, "price": ep.price,
			"type": "extender", "size": ext[e][1], "limit": Math.min(ext[e][2], ep.limit || 99)})
	}
	var simp = simpleList()
	for (var k = 0; k < simp.length; k++) {
		if (simp[k][3] <= 0 || excluded[simp[k][0]]) continue
		var sp = priceOf(km.Item.get(simp[k][0]))
		if (sp) cons.push({"name": km.Item.get(simp[k][0]).name, "advmin": simp[k][1], "advmax": simp[k][1],
			"pvpfights": simp[k][2], "price": sp.price, "type": "simple", "size": [0, 0, 0],
			"limit": Math.min(simp[k][3], sp.limit || 99)})
	}
	return cons
}

var CLASS_IDS = {
	"Seal Clubber": 1, "Turtle Tamer": 2, "Pastamancer": 3,
	"Sauceror": 4, "Disco Bandit": 5, "Accordion Thief": 6,
}

function isGarishDay() {
	// Gar-ish does nothing on Mondays (KoL server time, Arizona = UTC-7).
	return new Date(Date.now() - 7 * 3600 * 1000).getUTCDay() != 1
}

var GEAR_SLOTS = ["acc1", "acc2", "acc3", "shirt", "weapon", "pants"]
var ACC_SLOTS = ["acc1", "acc2", "acc3"]

function isCapacityGearIn(slot) {
	return !!CAPACITY_GEAR[km.equippedItem(km.Slot.get(slot)).name]
}

// Organ-capacity gear for phase 3: [{name, slot, size, worn}]. Gear you are
// wearing now counts too, but not toward phase 1, since you'd take it off to
// adventure. The corset is skipped when a tuxedo shirt can boost martinis, and
// one accessory slot is left for the pinky ring.
function capacityGear(tuxedo, ring) {
	var gear = [], taken = {}
	for (var i = 0; i < GEAR_SLOTS.length; i++) {
		var worn = km.equippedItem(km.Slot.get(GEAR_SLOTS[i])).name
		if (CAPACITY_GEAR[worn] && !taken[worn]) {
			gear.push({name: worn, slot: GEAR_SLOTS[i], size: CAPACITY_GEAR[worn][1], worn: true})
			taken[worn] = true
		}
	}
	var accSlots = ACC_SLOTS.filter(function (s) { return !isCapacityGearIn(s) })
	if (ring) accSlots.pop()
	for (var name in CAPACITY_GEAR) {
		if (taken[name]) continue
		var g = CAPACITY_GEAR[name], it = km.Item.get(name)
		if (km.availableAmount(it) <= 0 || !km.canEquip(it)) continue
		if (g[0] == "shirt" && (tuxedo || !(km.haveSkill(km.Skill.get("Torso Awareness")) ||
			km.haveSkill(km.Skill.get("Best Dressed"))))) continue
		var slot = g[0]
		if (slot == "acc") {
			if (!accSlots.length) continue
			slot = accSlots.shift()
		}
		gear.push({name: name, slot: slot, size: g[1], worn: false})
	}
	return gear
}

// Accessory slot for the pinky ring: one not holding capacity gear.
function ringSlot() {
	for (var i = ACC_SLOTS.length - 1; i >= 0; i--) {
		if (!isCapacityGearIn(ACC_SLOTS[i])) return ACC_SLOTS[i]
	}
	return "acc3"
}

function haveUsable(name) {
	var it = km.Item.get(name)
	return km.availableAmount(it) > 0 && km.canEquip(it)
}

// Sweat Out Some Booze (designer sweatpants, held or worn): 25 sweat for -1
// drunkenness, 3 casts a day. Sweat builds while you adventure in the pants.
var SWEAT_PER_CAST = 25
var SWEAT_CASTS_PER_DAY = 3

function sweatBooze() {
	var have = km.availableAmount(km.Item.get("designer sweatpants")) > 0
	var sweat = prefInt("sweat")
	var left = have ? Math.max(0, SWEAT_CASTS_PER_DAY - prefInt("_sweatOutSomeBoozeUsed")) : 0
	return {have: have, sweat: sweat, left: left, ready: Math.min(left, Math.floor(sweat / SWEAT_PER_CAST))}
}

// Casts worth making now: each needs drunkenness to remove, and casting is
// pointless if you'd still be over your liver limit afterwards.
function sweatCastsNow(sweat) {
	var n = Math.min(sweat.ready, km.myInebriety())
	if (km.myInebriety() - n > km.inebrietyLimit()) return 0
	return Math.max(0, n)
}

// One cast at a time (multicasting it has been unreliable).
function castSweatOutBooze(n, log) {
	var skill = km.Skill.get("Sweat Out Some Booze")
	var done = 0
	for (var i = 0; i < n; i++) {
		var used = prefInt("_sweatOutSomeBoozeUsed"), drunk = km.myInebriety()
		if (!km.useSkill(1, skill) || (prefInt("_sweatOutSomeBoozeUsed") == used && km.myInebriety() == drunk)) break
		done++
	}
	if (done < n) log.push("warning: cast Sweat Out Some Booze " + done + " of " + n + " times; plan may not fit")
	return done
}

function parseArgs(argString) {
	var opts = {}
	var parts = (argString || "").split(/\s+(?=\w+=|noRefresh\b|execute\b|turngen\b|finish\b)/)
	for (var i = 0; i < parts.length; i++) {
		var p = parts[i].replace(/^\s+|\s+$/g, "")
		if (!p) continue
		var eq = p.indexOf("=")
		if (eq < 0) opts[p] = true
		else opts[p.substring(0, eq)] = p.substring(eq + 1)
	}
	return opts
}

function buildSettings(opts) {
	var adv_value = parseFloat(opts.value) ||
		parseFloat(pref("smm.TurnValue")) || 5000
	// Sweat Out Some Booze is cast only by finish (the day's last run), so
	// only finish counts the drunkenness it frees.
	var sweat = sweatBooze()
	var sweatCasts = opts.finish && !opts.organs ? sweatCastsNow(sweat) : 0
	var inebriety = km.myInebriety() - sweatCasts
	var overdrunk = inebriety > km.inebrietyLimit()
	var organs = [
		km.fullnessLimit() - km.myFullness(),
		Math.max(0, km.inebrietyLimit() - inebriety),
		km.spleenLimit() - km.mySpleenUse(),
	]
	// The optimizer plans no nightcap: phase 4 is one overdrink, picked by
	// planDay from the optimizer's single-drink candidates.

	// organs: space for the whole day. base: what phase 1 may use -- without
	// organ gear or the Stooper, even if they're on now.
	var gear = [], stooper = false
	if (opts.organs) {
		organs = opts.organs.split(",").map(function (x) { return parseInt(x, 10) || 0 })
	} else {
		gear = capacityGear(haveUsable("tuxedo shirt"), haveUsable("mafia pinky ring"))
		if (overdrunk) gear = gear.filter(function (g) { return g.size[1] == 0 })
		var st = km.Familiar.get("Stooper")
		var stooperOut = km.myFamiliar().toString() == st.toString()
		stooper = !overdrunk && km.haveFamiliar(st)
		if (stooper && !stooperOut) organs[1] += 1
		for (var g = 0; g < gear.length; g++) {
			if (gear[g].worn) continue
			for (var o = 0; o < 3; o++) organs[o] += gear[g].size[o]
		}
	}
	var base = organs.slice()
	for (var b = 0; b < gear.length; b++) {
		for (var bo = 0; bo < 3; bo++) base[bo] -= gear[b].size[bo]
	}
	if (stooper) base[1] -= 1

	var lounge = km.getClanLounge()
	var speakeasy_left = Math.max(0, 3 - prefInt("_speakeasyDrinksDrunk"))
	var has_speakeasy = !!lounge["Clan speakeasy"] && speakeasy_left > 0

	var excluded = {}
	if (opts.exclude) {
		var ex = opts.exclude.split("|")
		for (var i = 0; i < ex.length; i++) excluded[ex[i].replace(/^\s+|\s+$/g, "")] = true
	}
	if (prefBool("_fudgeSporkUsed")) excluded["fudge spork"] = true
	if (prefBool("_affirmationCookieEaten")) excluded["Affirmation Cookie"] = true
	if (prefBool("_spaghettiBreakfastEaten") || km.myFullness() > 0) excluded["spaghetti breakfast"] = true
	if (prefBool("_coldOne") && km.availableAmount(km.Item.get("Cold One")) == 0) excluded["Cold One"] = true

	var lucky = opts.lucky !== undefined ? parseInt(opts.lucky, 10) || 0 : 3

	return {
		"adventure value": adv_value,
		"pvp fight value": parseFloat(opts.pvp) || 0,
		"classid": CLASS_IDS[km.myClass().toString()] || 0,
		"include nightcap": "no",
		"overdrink candidates": !overdrunk,
		"rollover gain": 0,   // set by main
		"saucemaven available": km.haveSkill(km.Skill.get("Saucemaven")),
		"pizza lover available": km.haveSkill(km.Skill.get("Pizza Lover")),
		"ancestral recall available": km.haveSkill(km.Skill.get("Ancestral Recall")),
		"spaghetti breakfast available": km.haveSkill(km.Skill.get("Spaghetti Breakfast")) && !excluded["spaghetti breakfast"],
		"grab a cold one available": km.haveSkill(km.Skill.get("Grab a Cold One")) && !prefBool("_coldOne"),
		"use potion of the field gar": isGarishDay() ? "yes" : "no",
		"tuxedo shirt available": haveUsable("tuxedo shirt"),
		"tiny plastic sword available": false,  // TPS drink recipes aren't priced here
		"mafia pinky ring available": haveUsable("mafia pinky ring"),
		"mime army shotglass available": km.availableAmount(km.Item.get("mime army shotglass")) > 0 &&
			!prefBool("_mimeArmyShotglassUsed"),
		"speakeasy": has_speakeasy,
		"semirares available": has_speakeasy ? Math.min(lucky, speakeasy_left) : 0,
		"lucky wanted": lucky,
		"effect rates": effectRates(opts, adv_value),
		"workshed": km.getWorkshed().name == "portable Mayo Clinic" ? "mayo" : "none",
		"excluded consumables": excluded,
		"organ sizes": organs,
		"base organs": base,
		"capacity gear": gear,
		"stooper": stooper,
		"sweat": sweat,
		"sweat casts": sweatCasts,  // Sweat Out Some Booze casts finish makes first
		// smm additions
		// KoLmafia already rewrites the cookie's adventures from affirmationCookiesEaten
		// (3, 5, 7, then 9), so no bonus is added on top.
		"affirmation bonus": 0,
		"speakeasy drinks left": speakeasy_left,
		"ancestral recall casts left": Math.max(0, 10 - prefInt("_ancestralRecallCasts")),
		"chocolates used": {
			fancy: prefInt("_chocolatesUsed"), vitachoc: prefInt("_vitachocCapsulesUsed"),
			cigar: prefInt("_chocolateCigarsUsed"), sculpture: prefInt("_chocolateSculpturesUsed"),
		},
	}
}

// Every purchasable item a plan relies on (the consumables and their helpers).
function planItemNames(result) {
	var names = {}
	for (var i = 0; i < result.diet_items.length; i++) {
		var row = result.diet_items[i]
		names[row.name] = true
		var extra = row.desc.extra
		for (var j = 0; j < extra.length; j++) {
			if (extra[j].type == "item" && extra[j].exclude) names[extra[j].item.name] = true
		}
	}
	return names
}

function fmt(n) {
	return Math.round(n).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")
}

function noteText(note) {
	if (note.type == "text") return note.text
	if (note.type == "effect") return note.verb + " " + note.effect
	return note.verb + " " + note.item.name
}

// ---------------------------------------------------------------------------
// Phases. The optimizer plans the whole day; splitPhases decides which units
// are consumed in each phase:
//   1 now: food, booze and spleen that fit the organs' normal space, with all
//     cleaners
//   2 once phase 1's adventures are spent: other turn generation that uses no
//     organ (chocolates, simple items such as tofu, magical sausages,
//     Ancestral Recall) -- by then you have ground more sausages and built
//     more sweat
//   3 end of day, wearing organ gear / Stooper (and after Sweat Out Some
//     Booze): the units that need the extra space, plus Three Sheets to the
//     Wind (its rollover bonus is lost if you adventure after it)
//   4 overdrink: one drink, picked by chooseLate (the optimizer plans none)
// Phases 1-2 are adventured today; phases 3-4 roll over.
// ---------------------------------------------------------------------------

var LAST_PHASE = 4

// Turn generation that uses no organ: phase 2. Milk of magnesium boosts the
// food eaten after it, so it stays with the food.
function isTurngen(row) {
	var s = unitSize(row), item = row.spec.item
	if (s[0] || s[1] || s[2] || row.is_nightcap || row.name == "milk of magnesium") return false
	return item.type == "simple" || !!CHOCOLATE_NAMES[row.name] || row.name == "Ancestral Recall"
}

// Organ use of one unit of a plan row.
function unitSize(row) {
	var s = row.spec.size
	if (!s) return [0, 0, 0]
	s = [s[0], s[1], s[2]]
	if (row.using_mime_shotglass) s[1] = Math.max(0, s[1] - 1)
	if (row.spec.after_nightcap) s[1] = 0
	return s
}

// Smallest subset of units whose organ-o sizes add up to at least need
// (fewest units on a tie); all of them if no subset reaches it.
function smallestCover(units, o, need) {
	var best = {0: []}
	for (var u = 0; u < units.length; u++) {
		var sz = units[u].size[o]
		var sums = Object.keys(best).map(Number)
		for (var k = 0; k < sums.length; k++) {
			if (sums[k] >= need) continue
			var t = sums[k] + sz, pick = best[sums[k]].concat([units[u]])
			if (!best[t] || best[t].length > pick.length) best[t] = pick
		}
	}
	var covered = Object.keys(best).map(Number).filter(function (x) { return x >= need })
	if (!covered.length) return units
	covered.sort(function (a, b) { return a - b })
	return best[covered[0]]
}

// Units of each plan row per phase: parts[i] = [0, phase1, phase2, phase3, phase4].
function splitPhases(result, settings) {
	var rows = result.diet_items, room = settings["base organs"].slice()
	var used = [0, 0, 0], movable = [], parts = []
	for (var i = 0; i < rows.length; i++) {
		var r = rows[i], s = unitSize(r), item = r.spec.item
		parts.push([0, 0, 0, 0, 0])
		if (r.is_nightcap || r.spec.after_nightcap) { parts[i][4] = r.amount; continue }
		if (item.bonusadv) { parts[i][3] = r.amount; continue }
		if (isTurngen(r)) { parts[i][2] = r.amount; continue }
		parts[i][1] = r.amount
		for (var o = 0; o < 3; o++) {
			if (s[o] > 0) used[o] += s[o] * r.amount
			else room[o] -= s[o] * r.amount  // cleaning frees space for phase 1
		}
		// Lucky! (fortune drinks, clovermint) is only worth something while
		// you can still adventure, and cleaners belong to phase 1.
		var canMove = s.some(function (x) { return x > 0 }) && !s.some(function (x) { return x < 0 }) &&
			!(r.spec.opts && r.spec.opts.fortune) && !item.bonusvalue
		if (canMove) for (var k = 0; k < r.amount; k++) movable.push({row: i, size: s})
	}
	for (var org = 0; org < 3; org++) {
		var need = used[org] - room[org]
		if (need <= 0) continue
		var pick = smallestCover(movable.filter(function (m) { return m.size[org] > 0 }), org, need)
		for (var p = 0; p < pick.length; p++) {
			parts[pick[p].row][1]--
			parts[pick[p].row][3]++
			for (var q = 0; q < 3; q++) used[q] -= pick[p].size[q]
			movable.splice(movable.indexOf(pick[p]), 1)
		}
	}
	return parts
}

var ADVENTURE_CAP = 200  // most adventures rollover keeps (only enforced at rollover)

// Adventures rollover will add, with the best adventure gear on: smmUtils'
// adventureGainAtRollover(true), asked through the gCLI like loadMuseumSpare.
function rolloverGain(opts) {
	if (opts.rollover !== undefined) return parseInt(opts.rollover, 10) || 0
	var out = ""
	try {
		out = km.cliExecuteOutput("ash import <smmUtils.ash>; adventureGainAtRollover(true)")
	} catch (e) { out = "" }
	var m = /Returned: (-?\d+)\s*$/.exec(out || "")
	if (m) return parseInt(m[1], 10)
	var guess = 40 + Math.round(km.numericModifier("Adventures"))
	km.print("smmUtils' adventureGainAtRollover is unavailable; assuming " + guess +
		" rollover adventures (current gear).", "orange")
	return guess
}

// Adventures each phase actually gives (the nightcap's uncapped).
function phaseAdventures(result, parts) {
	var adv = [0, 0, 0, 0, 0], rows = result.diet_items
	for (var i = 0; i < rows.length; i++) {
		var r = rows[i]
		var per = r.is_nightcap ? (r.spec.adv || 0) : (r.turns || 0) / r.amount
		for (var ph = 1; ph <= LAST_PHASE; ph++) adv[ph] += per * parts[i][ph]
	}
	return adv
}

// Adventures of phases from..LAST_PHASE.
function advFrom(adv, from) {
	var sum = 0
	for (var ph = from; ph <= LAST_PHASE; ph++) sum += adv[ph]
	return sum
}

// Plan the day so the adventures that roll over end as close to the
// adventure cap after rollover as possible without passing it -- tomorrow
// then starts with the most adventures. Phases 3-4 roll over; at finish,
// adventures you still hold and phase 1-2 leftovers eaten then roll over too.
// The optimizer fills every organ (organ gear and Stooper included) with no
// nightcap; chooseLate then picks the one overdrink and trims phase 3 to fit.
// Phase 2 turn generation is never dropped to fit: if it (with phase 1
// leftovers and the adventures you hold) would overflow at finish, finish
// warns and stops instead.
function planDay(settings, finish) {
	var roll = finish ? 1 : 3  // first phase whose adventures roll over
	var room = ADVENTURE_CAP - settings["rollover gain"] - (finish ? km.myAdventures() : 0)
	var result = tehtmi(settings), parts = splitPhases(result, settings)
	var adv = phaseAdventures(result, parts)
	var plan = {result: result, parts: parts, adv: adv.slice(), room: room, roll: roll, value: 0}
	for (var i = 0; i < result.diet_items.length; i++) plan.value += result.diet_items[i].value || 0
	// Only phase 3 is trimmed: phase 1-2 leftovers are worth eating, so if
	// they alone overflow at finish, finish stops instead (earlyWaste).
	plan.earlyWaste = finish ? Math.max(0, Math.round(adv[1] + adv[2] - Math.max(0, room))) : 0
	chooseLate(plan, settings)
	return plan
}

// Phase 4 is a single overdrink: the candidate worth most, counting only the
// adventures that fit under the cap (value of those adventures minus what it
// costs). It is chosen together with the phase 3 units to keep -- a small
// knapsack over phase 3 (it holds only a few units), tried with the room each
// overdrink would leave. Ties go to more adventures, to end the day closer to
// the cap.
function chooseLate(plan, settings) {
	var rows = plan.result.diet_items, advValue = settings["adventure value"]
	plan.dropped = {}
	plan.overdrink = null
	var units = [], fixed = 0
	for (var f = plan.roll; f < 3; f++) fixed += plan.adv[f]  // rolled over but not trimmed
	for (var i = 0; i < rows.length; i++) {
		if (rows[i].is_nightcap) continue  // the optimizer plans none; never trim one
		var a = (rows[i].turns || 0) / rows[i].amount
		for (var ph = 3; ph <= LAST_PHASE; ph++) {
			for (var k = 0; k < plan.parts[i][ph]; k++) {
				var v = (rows[i].value || 0) / rows[i].amount
				units.push({row: i, phase: ph, adv: Math.ceil(a - k_epsilon), value: v,
					score: Math.max(v, 0) + (a + 1) * k_epsilon})  // keep 0-value units when they fit
			}
		}
	}
	var avail = Math.max(0, Math.floor(plan.room - fixed))
	// best[c] = {score, take}: the phase 3 units worth most using at most c adventures
	var best = []
	for (var c = 0; c <= avail; c++) best.push({score: 0, take: []})
	for (var u = 0; u < units.length; u++) {
		for (var c2 = avail; c2 >= units[u].adv; c2--) {
			var prev = best[c2 - units[u].adv], cand = prev.score + units[u].score
			if (cand > best[c2].score + k_epsilon * k_epsilon) best[c2] = {score: cand, take: prev.take.concat([u])}
		}
	}

	var used = {}  // copies of each item the plan already uses
	for (var r = 0; r < rows.length; r++) {
		var n = 0
		for (var up = 1; up <= LAST_PHASE; up++) n += plan.parts[r][up]
		used[rows[r].name] = (used[rows[r].name] || 0) + n
	}
	var pick = {score: best[avail].score, take: best[avail].take, drink: null, value: 0}
	var drinks = plan.result.overdrinks || []
	for (var d = 0; d < drinks.length; d++) {
		var od = drinks[d], limit = od.spec.item.limit
		if (limit && (used[od.name] || 0) >= limit) continue
		var counted = Math.min(od.turns, avail)  // adventures that fit under the cap
		var odValue = od.value - (od.turns - counted) * advValue
		if (odValue <= k_epsilon) continue
		var left = avail - Math.ceil(counted - k_epsilon)
		var score = best[left].score + odValue + counted * k_epsilon
		if (score > pick.score + k_epsilon * k_epsilon) pick = {score: score, take: best[left].take, drink: od, value: odValue}
	}

	var keep = {}
	for (var t = 0; t < pick.take.length; t++) keep[pick.take[t]] = true
	for (var x = 0; x < units.length; x++) {
		if (keep[x]) continue
		var un = units[x], row = rows[un.row]
		plan.parts[un.row][un.phase]--
		plan.adv[un.phase] -= (row.turns || 0) / row.amount
		plan.value -= un.value
		plan.dropped[row.name] = (plan.dropped[row.name] || 0) + 1
	}
	if (pick.drink) {
		rows.push(pick.drink)
		plan.parts.push([0, 0, 0, 0, 1])
		plan.adv[LAST_PHASE] += pick.drink.turns
		plan.value += pick.value
		plan.overdrink = pick.drink
	}
	plan.waste = Math.max(0, Math.round(advFrom(plan.adv, plan.roll) - Math.max(0, plan.room)))
}

function gearDescription(settings) {
	var names = (settings["capacity gear"] || []).map(function (g) { return g.name })
	if (settings["stooper"]) names.push("Stooper (familiar)")
	return names.join(", ")
}

var PHASE_TITLES = {
	1: "Phase 1 -- now (execute): food, booze and spleen, with the cleaners; then adventure until these are spent",
	2: "Phase 2 -- then (turngen): other turn generation; then adventure until these are spent",
	3: "Phase 3 -- end of day (finish): ",
	4: "Phase 4 -- overdrink one drink, the one worth most (adventures past the cap count for nothing)",
}

function printPlan(plan, settings, finish) {
	var result = plan.result, parts = plan.parts
	var o = settings["organ sizes"], base = settings["base organs"]
	km.print("Whole-day diet for " + o[0] + " fullness, " + o[1] + " drunkenness, " + o[2] +
		" spleen (" + base.join("/") + " without organ gear) at " +
		fmt(settings["adventure value"]) + " meat/adventure", "blue")
	var rows = result.diet_items, totalTurns = 0, cost = 0, pvp = 0, effects = 0, phaseTurns = [0, 0, 0, 0, 0]
	for (var ph = 1; ph <= LAST_PHASE; ph++) {
		var lines = []
		for (var i = 0; i < rows.length; i++) {
			var r = rows[i], n = parts[i][ph]
			if (!n) continue
			var notes = r.desc.extra.map(noteText)
			if (r.desc.notes) notes.push(r.desc.notes)
			var eff = r.spec.item.effect
			if (eff) {
				notes.push(fmt(eff.turns * n) + " adv of " + eff.name + " worth " + fmt(eff.value * n) + " meat")
				effects += eff.value * n
			}
			var turns = (r.turns || 0) * n / r.amount
			lines.push(n + "x " + r.name + " -- " + fmt(turns) + " adv, " +
				fmt((r.price || 0) * n / r.amount) + " meat" + (notes.length ? " (" + notes.join("; ") + ")" : ""))
			phaseTurns[ph] += turns
		}
		if (!lines.length) continue
		var title = PHASE_TITLES[ph]
		if (ph == 3) title += gearDescription(settings) ? "wear " + gearDescription(settings) +
			", fill every organ to the new capacity (never over)" : "fill every organ (never over)"
		km.print(title + " (" + fmt(phaseTurns[ph]) + " adv):", "blue")
		for (var l = 0; l < lines.length; l++) km.print("  " + lines[l])
	}
	for (var j = 0; j < rows.length; j++) {
		var units = 0
		for (var up = 1; up <= LAST_PHASE; up++) units += parts[j][up]
		totalTurns += (rows[j].turns || 0) * units / rows[j].amount
		cost += (rows[j].price || 0) * units / rows[j].amount
		pvp += (rows[j].fights || 0) * units / rows[j].amount
	}
	for (var dn in plan.dropped) km.print("Leaving out " + plan.dropped[dn] + "x " + dn +
		": its adventures would pass " + ADVENTURE_CAP + " at rollover.", "gray")
	if (!plan.overdrink && settings["overdrink candidates"])
		km.print("No overdrink: no single drink is worth its price in the adventures that fit under " +
			ADVENTURE_CAP + ".", "orange")
	km.print("Total: " + fmt(totalTurns) + " adventures" + (pvp ? " + " + fmt(pvp) + " PvP fights" : "") +
		" for " + fmt(cost) + " meat; net value " + fmt(plan.value) + " meat" +
		(effects ? " (" + fmt(effects) + " of it from effects)" : ""), "green")
	if (finish) km.print("Everything left is consumed now, so all " + fmt(totalTurns) + " roll over to tomorrow.", "green")
	else km.print(fmt(phaseTurns[1] + phaseTurns[2]) + " adventures from phases 1-2 to use today; " +
		fmt(phaseTurns[3] + phaseTurns[4]) + " from phases 3-4 roll over to tomorrow.", "green")
	var late = Math.round(advFrom(plan.adv, plan.roll))
	var lateWhat = finish ? "the rest of the diet adds " : "phases 3-4 add "
	km.print("Rollover adds about " + settings["rollover gain"] + " (best adventure gear)" +
		(finish ? " to the " + km.myAdventures() + " you hold" : "") + "; " + lateWhat + late +
		" of the " + Math.max(0, plan.room) + " that fit under " + ADVENTURE_CAP + ".", "gray")
	if (plan.waste > 0)
		km.print(plan.waste + " adventures will be lost at rollover (" + ADVENTURE_CAP + " max).", "orange")
	if (o[1] > 0) km.print("Booze adventures assume Ode to Booze is active.", "gray")
	printSweatFlag(settings, finish)
}

// Flag Sweat Out Some Booze: what finish will cast, or why it isn't counted.
function printSweatFlag(settings, finish) {
	var s = settings["sweat"], casts = settings["sweat casts"]
	if (!s || !s.have || !s.left) return
	if (casts > 0) {
		km.print("Sweat Out Some Booze: casting it " + casts + "x first (" + (casts * SWEAT_PER_CAST) + " of " +
			s.sweat + " sweat) for " + casts + " more drunkenness (counted above).", "blue")
		if (s.left > casts) km.print("  " + (s.left - casts) + " more casts left today.", "gray")
		return
	}
	var why
	if (!finish) why = "not counted; it is cast by the last run of the day (call diet.js finish)"
	else if (s.ready == 0) why = "not enough sweat (" + s.sweat + " of " + SWEAT_PER_CAST + " per cast)"
	else if (km.myInebriety() == 0) why = "no drunkenness to sweat out yet"
	else why = "you would still be over your liver limit"
	km.print("Sweat Out Some Booze: " + s.left + " casts left today, " + s.sweat + " sweat (" + SWEAT_PER_CAST +
		" per cast) -- " + why + ".", "orange")
}

function main(argString) {
	if (!km) throw "diet.js must be run inside KoLmafia"
	var opts = parseArgs(argString)
	var settings = buildSettings(opts)
	semirare_value = km.mallPrice(km.Item.get("11-leaf clover"))
	price_cache = {}
	loadMuseumSpare(dietCandidates())
	diet_consumables = buildConsumables(settings["excluded consumables"], {lucky: settings["lucky wanted"], effects: settings["effect rates"]})

	settings["rollover gain"] = rolloverGain(opts)
	var plan = planDay(settings, !!opts.finish)

	// Historical prices can be stale: re-check live mall prices for everything
	// the plan uses, and re-plan until those prices stop changing.
	for (var pass = 0; pass < 3 && !opts.noRefresh; pass++) {
		var names = planItemNames(plan.result)
		var changed = false
		for (var c = 0; c < diet_consumables.length; c++) {
			var entry = diet_consumables[c]
			if (!names[entry.name] || entry.speakeasy || entry.owned) continue
			var live = priceOf(km.Item.get(entry.name), true)
			if (live && Math.abs(live.price - entry.price) > 0.02 * entry.price) {
				km.print("Price of " + entry.name + ": " + fmt(entry.price) + " -> " + fmt(live.price), "gray")
				entry.price = live.price
				changed = true
			}
		}
		if (!changed) break
		plan = planDay(settings, !!opts.finish)
	}

	printPlan(plan, settings, !!opts.finish)
	if (opts.finish && plan.earlyWaste > 0) {
		km.print("Not finishing: you hold " + km.myAdventures() + " adventures and phases 1-2 still add " +
			fmt(plan.adv[1] + plan.adv[2]) + ", so finishing now would waste " + plan.earlyWaste +
			" adventures at rollover (" + ADVENTURE_CAP + " max, rollover adds about " + settings["rollover gain"] +
			"). Spend some adventures first (call diet.js turngen uses phase 2 today), then run finish again.", "red")
		return
	}
	if (opts.finish) executePlan(plan.result, settings, plan.parts, LAST_PHASE)
	else if (opts.turngen) executePlan(plan.result, settings, plan.parts, 2)
	else if (opts.execute) executePlan(plan.result, settings, plan.parts, 1)
	// Return nothing: KoLmafia converts a JS return value to ASH, and the plan
	// object (with its undefined fields) can't be converted.
}


// ===========================================================================
// smm: execution -- buys and consumes a plan in a safe order.
// ===========================================================================

var PRICE_SLACK = 1.3  // pay at most 30% over the planned price
var USE_BEFORE = {  // helpers used right before the item they boost
	"Ol' Scratch's salad fork": true, "fudge spork": true, "Frosty's frosty mug": true,
	"BGE shotglass": true, "munchies pill": true, "dieting pill": true,
	"Mayoflex": true, "Mayodiol": true,
}
var KEEP_IN_INVENTORY = {  // consumed automatically by KoL while held
	"Taco Dan's Super Taco-Riffic Taco Sauce!": true, "Special Seasoning": true,
}
var CHOCOLATE_NAMES = {}
for (var ch = 11; ch < HELPERS.length; ch++) CHOCOLATE_NAMES[HELPERS[ch]] = true

function plannedPrice(name) {
	for (var i = 0; i < diet_consumables.length; i++) {
		if (diet_consumables[i].name == name) return diet_consumables[i].price || 0
	}
	return 0
}

// Make sure n of an item are in inventory, buying at most PRICE_SLACK over plan.
function acquire(name, n) {
	var it = km.Item.get(name)
	var reserved = reservedCopies(it)  // smm: Museum copies stay; eat spare or freshly bought ones
	n += reserved
	var have = km.availableAmount(it)
	if (have >= n) return km.retrieveItem(n, it)
	if (name == "Cold One" || name == "spaghetti breakfast") {
		var skill = km.Skill.get(name == "Cold One" ? "Grab a Cold One" : "Spaghetti Breakfast")
		km.useSkill(1, skill)
		return km.availableAmount(it) >= n
	}
	if (it.tradeable && km.canInteract()) {
		var cap = Math.ceil(plannedPrice(name) * PRICE_SLACK)
		if (cap > 0) km.buy(n - have, it, cap)
	}
	if (km.availableAmount(it) < n) km.retrieveItem(n, it)  // NPC stores, Mayo Clinic, crafting
	return km.availableAmount(it) >= n
}

function phaseOf(row) {
	var spec = row.spec, type = spec.item.type, opts = spec.opts || {}
	if (row.name == "milk of magnesium") return 0
	if (type == "extender") return -1                     // used on demand
	if (opts.wish_refined_palate || opts.wish_salty_mouth) return -1  // wished on demand
	if (row.name == "potion of the field gar") return -1  // used on demand
	if (type == "simple" || CHOCOLATE_NAMES[row.name] || row.name == "Ancestral Recall") return 1
	if (row.name == "spaghetti breakfast") return 2
	if (type == "food" && !spec.after_nightcap) return 3
	if (type == "spleen") return 4
	if (type == "booze" && !row.is_nightcap) return 5
	if (row.name == "temporary X tattoos") return 6
	if (row.is_nightcap) return 7
	if (type == "food") return 8                          // eaten after the nightcap
	return 1
}

function organState() {
	return [km.myFullness(), km.myInebriety(), km.mySpleenUse()]
}
function organLimits() {
	return [km.fullnessLimit(), km.inebrietyLimit(), km.spleenLimit()]
}

// Which organ (0-2) this unit would overflow right now, or -1 if it fits.
function blockingOrgan(step) {
	var row = step.row, size = row.spec.size
	if (!size || row.is_nightcap) return -1
	var cur = organState(), lim = organLimits()
	var add = [size[0], size[1], size[2]]
	if (row.using_mime_shotglass) add[1] = Math.max(0, add[1] - 1)
	if (row.spec.after_nightcap) add[1] = 0
	for (var o = 0; o < 3; o++) {
		if (add[o] > 0 && cur[o] + add[o] > lim[o]) return o
	}
	return -1
}

// Pocket wishes the plan budgeted, per effect. The optimizer prices one wish
// per drink, but one wish lasts for all of them, so most of these go unused.
var wish_budget = {}

function ensureEffect(effectName) {
	var eff = km.Effect.get(effectName)
	if (km.haveEffect(eff) > 0) return true
	if (effectName == "Gar-ish") {
		if (!acquire("potion of the field gar", 1)) return false
		km.use(1, km.Item.get("potion of the field gar"))
	} else if (wish_budget[effectName] > 0) {
		if (!acquire("pocket wish", 1)) return false
		km.cliExecute("genie effect " + effectName)
		wish_budget[effectName]--
	}
	return km.haveEffect(eff) > 0
}

function consumeUnit(step, log) {
	var row = step.row, spec = row.spec, name = row.name
	var notes = row.desc.extra
	for (var i = 0; i < notes.length; i++) {
		var n = notes[i]
		if (n.type == "effect") {
			if (!ensureEffect(n.effect))
				log.push("warning: no " + n.effect + " for " + name + " (fewer adventures)")
		} else if (n.type == "item" && n.verb == "wearing") {
			var gear = km.Item.get(n.item.name)
			if (!km.haveEquipped(gear)) {
				// the pinky ring goes in the accessory slot capacityGear left free
				if (gear.name == "mafia pinky ring") km.equip(km.Slot.get(ringSlot()), gear)
				else km.equip(gear)
			}
		} else if (n.type == "item" && n.exclude) {
			if (!acquire(n.item.name, 1)) return "cannot get " + n.item.name
			if (USE_BEFORE[n.item.name]) km.use(1, km.Item.get(n.item.name))
		}
	}

	if (name == "Ancestral Recall") {
		if (!acquire("blue mana", 1)) return "cannot get blue mana"
		return km.useSkill(1, km.Skill.get("Ancestral Recall")) ? "" : "Ancestral Recall failed"
	}
	var it = km.Item.get(name)
	if (spec.item.speakeasy) {
		return km.cliExecute("drinksilent 1 [" + km.toInt(it) + "]") ? "" : "speakeasy drink failed"
	}
	if (!acquire(name, 1)) return "cannot get " + name
	var type = spec.item.type, ok
	if (row.is_nightcap) ok = km.overdrink(1, it)
	else if (type == "food") ok = km.eatsilent(1, it)
	else if (type == "booze") ok = km.drinksilent(1, it)
	else if (type == "spleen") ok = km.chew(1, it)
	else if (spec.item.eat) ok = km.eatsilent(1, it)  // magical sausage: food with no fullness
	else ok = km.use(1, it)
	return ok ? "" : "consuming " + name + " failed"
}

// Use one extender that frees space in the given organ. Single-organ ones go
// first, so two-organ ones (spice melange) aren't spent while the other organ
// is still empty.
// True if cleaning by `size` now would be partly wasted (organ not used enough).
function wastesCleaning(size, skipOrgan) {
	var cur = organState()
	for (var o = 0; o < 3; o++) {
		if (o != skipOrgan && size[o] < 0 && cur[o] < -size[o]) return true
	}
	return false
}

function useExtenderFor(organ, extenders, allowWaste) {
	var organsTouched = function (e) {
		return e.row.spec.size.filter(function (x) { return x < 0 }).length
	}
	var candidates = extenders.filter(function (e) {
		return e.left > 0 && e.row.spec.size[organ] < 0 && (allowWaste || !wastesCleaning(e.row.spec.size, organ))
	})
	candidates.sort(function (a, b) { return organsTouched(a) - organsTouched(b) })
	for (var i = 0; i < candidates.length; i++) {
		var e = candidates[i]
		{
			if (!acquire(e.row.name, 1)) return false
			if (!km.use(1, km.Item.get(e.row.name))) return false
			e.left--
			return true
		}
	}
	return false
}

// Cast enough Ode to Booze for the booze among these steps.
function castOde(steps) {
	var drunk = 0
	for (var i = 0; i < steps.length; i++) {
		var spec = steps[i].row.spec
		if (spec.item.type == "booze" && spec.size) drunk += Math.max(0, spec.size[1])
	}
	if (!drunk) return
	var ode = km.Skill.get("The Ode to Booze"), eff = km.Effect.get("Ode to Booze")
	if (!km.haveSkill(ode)) {
		km.print("You don't have The Ode to Booze; booze will give about " + drunk + " fewer adventures.", "orange")
		return
	}
	for (var tries = 0; tries < 6 && km.haveEffect(eff) < drunk; tries++) {
		if (!km.useSkill(1, ode)) break
	}
	if (km.haveEffect(eff) < drunk)
		km.print("Only " + km.haveEffect(eff) + " turns of Ode to Booze for " + drunk +
			" drunkenness (song slots full?).", "orange")
}

// Consume steps in a safe order. Multiple passes: units that don't fit yet
// (food waiting on a cleaning booze), and cleaning items whose organ isn't
// full enough yet, are retried later. The overdrink waits until everything
// else is in, so organs are filled to capacity first and only that one drink
// goes over. Waste is allowed only when a pass makes no other progress.
// Returns {error, left}; units that never fit are an error only when strict.
function runSteps(steps, extenders, log, strict) {
	var pending = steps, allowWaste = false, error = "", odeDone = false
	while (pending.length && !error) {
		var next = [], progress = false
		for (var s = 0; s < pending.length && !error; s++) {
			var step = pending[s]
			if (step.row.is_nightcap && (next.length || pending.slice(s + 1).some(function (p) { return !p.row.is_nightcap }))) {
				next.push(step); continue
			}
			if (step.row.is_nightcap && km.myInebriety() < km.inebrietyLimit())
				log.push("note: overdrinking at " + km.myInebriety() + " of " + km.inebrietyLimit() + " drunkenness (liver not full)")
			if (step.phase >= 5 && !odeDone) { castOde(steps); odeDone = true }
			var organ = blockingOrgan(step)
			while (organ >= 0 && useExtenderFor(organ, extenders, allowWaste)) organ = blockingOrgan(step)
			if (organ >= 0) { next.push(step); continue }
			var size = step.row.spec.size
			if (size && !allowWaste && wastesCleaning(size, -1) &&
				(next.length || s < pending.length - 1)) {
				next.push(step); continue
			}
			var err = consumeUnit(step, log)
			if (err) error = err
			else progress = true
		}
		if (progress) allowWaste = false
		else if (!allowWaste && next.length) allowWaste = true
		else if (next.length && !error) {
			if (!strict) return {error: "", left: next}
			error = "can't fit " + next[0].row.name + " (organs " + organState().join("/") +
				" of " + organLimits().join("/") + ")"
		}
		pending = next
	}
	return {error: error, left: pending}
}

// Phase 3 setup: put on the organ-capacity gear and take out the Stooper.
function wearPhase2Gear(settings, log) {
	var gear = settings["capacity gear"] || []
	for (var g = 0; g < gear.length; g++) {
		var slot = km.Slot.get(gear[g].slot)
		if (km.equippedItem(slot).name == gear[g].name) continue
		if (!km.equip(slot, km.Item.get(gear[g].name)))
			log.push("warning: couldn't wear " + gear[g].name + "; plan may not fit")
	}
	if (settings["stooper"]) {
		var st = km.Familiar.get("Stooper")
		if (km.myFamiliar().toString() != st.toString() && !km.useFamiliar(st))
			log.push("warning: couldn't take out the Stooper; plan may not fit")
	}
}

// Carry out phases 1 to lastPhase (1 execute, 2 turngen, 4 finish), with anything earlier left over.
function executePlan(result, settings, parts, lastPhase) {
	var finish = lastPhase == LAST_PHASE
	var rows = result.diet_items
	var steps = [], extenders = [], cost = 0
	wish_budget = {}
	for (var r = 0; r < rows.length; r++) {
		var row = rows[r], n = 0
		for (var ph = 1; ph <= lastPhase; ph++) n += parts[r][ph]
		if (!n) continue
		cost += (row.price || 0) * n / row.amount
		var wopts = row.spec.opts || {}
		if (wopts.wish_salty_mouth) wish_budget["Salty Mouth"] = (wish_budget["Salty Mouth"] || 0) + n
		if (wopts.wish_refined_palate) wish_budget["Refined Palate"] = (wish_budget["Refined Palate"] || 0) + n
		var order = phaseOf(row)
		if (order < 0) {
			if (row.spec.item.type == "extender") extenders.push({row: row, left: n})
			continue
		}
		for (var ph2 = 1; ph2 <= lastPhase; ph2++) {
			for (var k = 0; k < parts[r][ph2]; k++) steps.push({row: row, phase: order, stage: ph2})
		}
	}
	var byOrder = function (a, b) { return a.phase - b.phase }
	steps.sort(byOrder)
	// early: phases 1-2 (organs' normal space, no gear); late: phases 3-4
	var early = steps.filter(function (s) { return s.stage <= 2 })
	var late = steps.filter(function (s) { return s.stage > 2 })
	var nextRun = lastPhase == 1 ? "call diet.js turngen" : "call diet.js finish"
	if (!steps.length && !extenders.length) {
		if (finish) km.print("Nothing worth consuming.", "blue")
		else km.print("Nothing to consume in phase" + (lastPhase == 1 ? " 1" : "s 1-2") +
			". Once your adventures are spent, run: " + nextRun, "blue")
		return
	}
	if (finish && late.length && km.myAdventures() > 0 &&
		!km.userConfirm("You still have " + km.myAdventures() + " adventures. Phases 3-4 (organ gear, " +
			"overdrinking) end useful adventuring for today. Finish anyway?", 60000, false)) {
		km.print("Diet not finished.", "blue")
		return
	}
	var what = finish ? "the rest of today's diet" : (lastPhase == 1 ? "phase 1 of the diet" : "phases 1-2 of the diet")
	var sweatCasts = finish ? settings["sweat casts"] || 0 : 0
	if (sweatCasts) what = "cast Sweat Out Some Booze " + sweatCasts + "x, then buy and consume " + what
	else what = "buy and consume " + what
	if (!km.userConfirm(what.charAt(0).toUpperCase() + what.substring(1) + " (about " + fmt(cost) + " meat)?", 60000, false)) {
		km.print("Diet not executed.", "blue")
		return
	}

	var startMeat = km.myMeat(), startAdv = km.myAdventures()
	var log = [], error = "", left = [], wore = false
	var familiar = km.myFamiliar()
	km.cliExecute("checkpoint")
	try {
		if (sweatCasts) castSweatOutBooze(sweatCasts, log)
		var run = runSteps(early, extenders, log, false)
		error = run.error
		left = run.left
		if (finish && !error) {
			wearPhase2Gear(settings, log)
			wore = true
			run = runSteps(left.concat(late).sort(byOrder), extenders, log, true)
			error = run.error
			left = run.left
		}
	} finally {
		km.cliExecute("outfit checkpoint")
		if (km.myFamiliar().toString() != familiar.toString()) km.useFamiliar(familiar)
	}
	if (error && wore && km.myInebriety() > km.inebrietyLimit())
		log.push("warning: stopped in phase 3-4 and the organ gear is off -- you are over your liver limit")

	for (var l = 0; l < log.length; l++) km.print(log[l], "orange")
	for (var e = 0; e < extenders.length; e++) {
		if (extenders[e].left > 0) km.print("Didn't need " + extenders[e].left + "x " + extenders[e].row.name, "gray")
	}
	var summary = "Gained " + (km.myAdventures() - startAdv) + " adventures for " +
		fmt(startMeat - km.myMeat()) + " meat."
	if (error) {
		km.print("Diet stopped: " + error + ". " + summary, "red")
	} else if (!finish) {
		if (left.length) km.print("Didn't fit yet, left for the end of the day: " +
			left.map(function (s) { return s.row.name }).join(", "), "gray")
		km.print((lastPhase == 1 ? "Phase 1" : "Phases 1-2") + " done. " + summary +
			" Adventure until these are spent, then run: " + nextRun, "green")
	} else {
		km.print("Diet done. " + summary, "green")
	}
}

module.exports.main = main
module.exports.tehtmi = tehtmi
module.exports.splitPhases = splitPhases
module.exports.planDay = planDay
module.exports.effectRates = effectRates
module.exports.effectOf = effectOf
module.exports._setData = function (consumables, srValue) {  // for tests
	diet_consumables = consumables
	semirare_value = srValue
}
