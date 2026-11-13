script "econ";
notify TQuilla;
since r26333;

import <smmUtils.ash>
string __econ_version = "0.1";

/**
Economic reporting utils. Everything here displays info in the CLI about the current value (mall price) of various items.

To use the functions from this ASH file in the gCLI, do this:
using smmEcon.ash;

You can then call any function in this file from the command line. For example:
itemDescription (pantogram pants);
     NOTE this ^ space between the name of the subroutine and the parenthesis is important for some reason

Functions without any params must be called without the empty parens (), e.g.:
spacegateEconomics;

To stop using this on the CLI, do:
get commandLineNamespace
set commandLineNamespace=
(if you have other files that you are "using", the first command will show them -- you'll
have to re-"using" them after resetting the name space)

@author Sacha Mallais (TQuilla #2771003)
*/



// TODO economics of frat/hippy war items
void warProfiteering() {
}



// monster description monster details
void printMonsterDetails(monster aMonster) {
	print("[" + aMonster.id + "]" + aMonster);
	print("base_hp: " + aMonster.base_hp);
	print("base_attack: " + aMonster.base_attack);
	print("base_defense: " + aMonster.base_defense);
	print("raw_hp: " + aMonster.raw_hp);
	print("raw_attack: " + aMonster.raw_attack);
	print("raw_defense: " + aMonster.raw_defense);
	print("attack_element: " + aMonster.attack_element);
	print("defense_element: " + aMonster.defense_element);
	print("physical_resistance: " + aMonster.physical_resistance);
	print("phylum: " + aMonster.phylum);
	print("poison: " + aMonster.poison);
	print("boss: " + aMonster.boss);
	foreach aMod in aMonster.random_modifiers
		print("random_modifiers: " + aMod);
}



// print item details # item description #printiteminfo
void printItemDetails(item anItem) {
	print("[" + anItem.to_int() + "]" + anItem.name);
	print("levelreq: " + anItem.levelreq);
	print("quality: " + anItem.quality);
	print("adventures: " + anItem.adventures);
	print("fullness: " + anItem.fullness);
	print("muscle: " + anItem.muscle);
	print("mysticality: " + anItem.mysticality);
	print("moxie: " + anItem.moxie);
	print("inebriety: " + anItem.inebriety);
	print("spleen: " + anItem.spleen);
	print("minhp: " + anItem.minhp);
	print("maxhp: " + anItem.maxhp);
	print("notes: " + anItem.notes);
	print("combat: " + anItem.combat);
	print("combat_reusable: " + anItem.combat_reusable);
	print("usable: " + anItem.usable);
	print("reusable: " + anItem.reusable);
	print("multi: " + anItem.multi);
	print("fancy: " + anItem.fancy);
	print("seller: " + anItem.seller);
	print("buyer: " + anItem.buyer);
}



void printLocationDetails(location aLocation) {
	print("[" + aLocation.to_int() + "]" + aLocation);
	print("combat_percent: " + aLocation.combat_percent);
	print("zone: " + aLocation.zone);
	print("parent: " + aLocation.parent);
	print("parentdesc: " + aLocation.parentdesc);
	print("environment: " + aLocation.environment);
	print("bounty: " + aLocation.bounty);
	print("combat_queue: " + aLocation.combat_queue);
	print("noncombat_queue: " + aLocation.noncombat_queue);
	print("turns_spent: " + aLocation.turns_spent);
	print("kisses: " + aLocation.kisses);
	print("recommended_stat: " + aLocation.recommended_stat);
	print("water_level: " + aLocation.water_level);
	print("wanderers: " + aLocation.wanderers);
}



void listCoinmasters() {
	foreach cnm in $coinmasters[] {
		print(cnm + " " + cnm.token + " " + cnm.property);
	}
}



// prints the given item drops and their base drop rate modified by the bonusItemDrop
void printItemDrops(ItemDropRecord [int] itemDropsArray, float bonusItemDrop) {
	foreach index, data in itemDropsArray {
		float rate = data.rate * (1 + bonusItemDrop/100);
		string rateString = to_string(rate, "%.2f") + "%";
		string noteString;

		switch (data.type) {
			case "0":
				rateString = "0.1%?? --  " + rateString;
				noteString += " no information (or rare drop?)";
				break;

			case "p":
// 			    float ppChance = data.rate * (1.0 + numeric_modifier("Pickpocket Chance").to_float() / 100);
// 				print(ppChance + "% pickpocket rate for " + data.drop + "@" + historical_price(data.drop) + " (pickpocket only)");
				noteString += " pickpocket only.";
				break;

			case "n":
				noteString += " NON-pickpocketable item.";
				break;

			case "b":
				noteString += " bounty item.";
				break;

			case "a":
				noteString += " accordion item.";
				break;

			case "c":
				noteString += " conditional item.";
				break;

			default:
		}
		print(rateString + (data.type == "p" ? " PP chance for " : " drop rate for ") + data.drop + "@" + historical_price(data.drop) + noteString);
	}
}


// prints item drops and their base drop rate modified by the bonusItemDrop for the given monster
void printMonsterItemDrops(monster mob, float bonusItemDrop) {
	printItemDrops(normalized_item_drops_array(mob), bonusItemDrop);
	print("total value at +" + bonusItemDrop.to_string("%.2f") + "% item drop: " + monsterItemMeatValue(mob, bonusItemDrop));
}


// prints meat and item drops for the given mob
void printMonsterDropDetails(monster mob, float bonusItemDrop, float bonusMeatDrop) {
	int meatDropValue = monsterMeatDropValue(mob, bonusMeatDrop);
	print(mob + " (with +" + to_string(bonusItemDrop, "%.2f") + "% item and +" + to_string(bonusMeatDrop, "%.2f") + "% meat) drops " + meatDropValue + " meat");
	printMonsterItemDrops(mob, bonusItemDrop);
	print("GRAND TOTAL: " + monsterTotalMeatValue(mob, bonusItemDrop, bonusMeatDrop));
}

void printMonsterBaseDropDetails(monster mob) {
	printMonsterDropDetails(mob, 0, 0);
}

void printMonsterCurrentDropDetails(monster mob) {
	printMonsterDropDetails(mob, item_drop_modifier(), meat_drop_modifier());
}


// prints item drops and their base drop rate modified by the bonusItemDrop for the given monster
void printMonsterPickpocketDrops(monster mob, float bonusPPDrop) {
	printItemDrops(ppItemDropsArray(mob), bonusPPDrop);
	print("total value at +" + bonusPPDrop + "% item drop: " + monsterItemMeatValue(mob, bonusPPDrop));
}

void printMonsterBasePickpocketDrops(monster mob) {
	printMonsterPickpocketDrops(mob, 0);
}

void printMonsterCurrentPickpocketDrops(monster mob) {
	printMonsterPickpocketDrops(mob, pickpocketChance());
}



float [item] adventuresPerSpleen(boolean shouldPrint) {
	float [item] rval;
	float [item] spleenAdvPer;
	item [int] sortArray;
	int idx;
	foreach it in $items[] {
		if (it.spleen > 0 && it.adventures != "0") {
			spleenAdvPer[it] = it.nutrition() / it.spleen;
			sortArray[idx++] = it;
		}
	}

	sort sortArray by -spleenAdvPer[value];

	foreach i, it in sortArray {
		rval[it] = spleenAdvPer[it];
		cprint(shouldPrint, it + ": " + it.spleen + " spleen -- " + it.adventures + " adv, adv/spleen: " + rval[it].to_string("%.1f"));
	}

	return rval;
}

float [item] adventuresPerSpleen() {
	return adventuresPerSpleen(true);
}


float [item] costPerAdventureSpleenItems(boolean shouldPrint) {
	float [item] rval;
	item [int] sortArray;
	int idx;
	float [item] adventuresPerSpleen = adventuresPerSpleen(false);
	float [item] costsPerAdventureSpleenItems;

	foreach it in adventuresPerSpleen {
		int cost = current_price(it);
		if (cost > 0) {
			float costPerAdventureSpleenItems = cost / it.nutrition();
			sortArray[idx++] = it;
			costsPerAdventureSpleenItems[it] = costPerAdventureSpleenItems;
		}
	}

	sort sortArray by costsPerAdventureSpleenItems[value];

	foreach i, it in sortArray {
		rval[it] = costsPerAdventureSpleenItems[it];
		cprint(shouldPrint, it + ": " + it.spleen + " spleen -- " + it.adventures + " adv, adv/spleen: " + adventuresPerSpleen[it].to_string("%.1f") + ", cost per adventure: " + costsPerAdventureSpleenItems[it].to_string("%.0f"));
	}

	return rval;
}

float [item] costPerAdventureSpleenItems() {
	return costPerAdventureSpleenItems(true);
}


float [item] costPerAdvPerSpleen(boolean shouldPrint) {
	float [item] rval;
	item [int] sortArray;
	int idx;
	float [item] advPerSpleen = adventuresPerSpleen(false);
	float [item] costsPerAdvPerSpleen;

	foreach it, advPer in advPerSpleen {
		int cost = current_price(it);
		float costPerAdvPerSpleen = cost / advPerSpleen[it];
		if (costPerAdvPerSpleen > 0) {
			sortArray[idx++] = it;
			costsPerAdvPerSpleen[it] = costPerAdvPerSpleen;
		}
	}

	sort sortArray by costsPerAdvPerSpleen[value];

	foreach i, it in sortArray {
		rval[it] = costsPerAdvPerSpleen[it];
		cprint(shouldPrint, it + ": " + it.spleen + " spleen -- " + it.adventures + " adv, adv/spleen: " + advPerSpleen[it].to_string("%.1f") + " -- cost per adventure per spleen: " + costsPerAdvPerSpleen[it].to_string("%.0f"));
	}

	return rval;
}

float [item] costPerAdvPerSpleen() {
	return costPerAdvPerSpleen(true);
}



void printMPCost(item anItem, float costPerMPGained) {
	int mallPrice = cheapest_price(anItem);
	effect anEffect = effect_modifier(anItem, "Effect");
	if (anEffect != $effect[none]) {
		float mpPerTurn = (numeric_modifier(anEffect, "MP Regen Min") + numeric_modifier(anEffect, "MP Regen Max")) / 2;
		int effectTurns = numeric_modifier(anItem, "Effect Duration");
		print(anItem + ": " + to_string(mpPerTurn, "%.1f") + "mp/turn for " + effectTurns + " turns @" + mallPrice + ", " + costPerMPGained.to_string(, "%.3f") + "meat/mp");
	} else {
		float avgMP = (anItem.minmp + anItem.maxmp) / 2;
		print(anItem + ": " + to_string(avgMP, "%.1f") + "mp @" + mallPrice + ", " + costPerMPGained.to_string("%.3f") + "meat/mp");
	}
}

// cheapest mp restore
void restoreMPEconomics() {
	item [int] restoreItems = {
		$item[blue rocket],
		$item[mangled finger],
		$item[neurostim pill],
		$item[irradiated turtle],
		$item[orcish hand lotion],
		$item[carbonated water lily],
		$item[honey-dipped locust],
		$item[Monstar energy beverage],
		$item[ancient magi-wipes],
		$item[Doc Galaktik's Invigorating Tonic],
		$item[Dyspepsi-Cola],
		$item[Cloaca-Cola],
		$item[phonics down],
		$item[carbonated soy milk],
		$item[tiny house],
		$item[knob goblin seltzer],
		$item[Notes from the Elfpocalypse, Chapter I],
		$item[Mountain Stream soda],
		$item[dueling turtle],
		$item[elven magi-pack],
		$item[grogpagne],
		$item[Egnaro berry],
		$item[magical mystery juice],
		$item[shard of double-ice], // stand-in for April Shower
	};

	float [item] itemToMPGainPerMeat = {
		$item[Egnaro berry] : mall_price($item[Egnaro berry]) / (my_maxmp() / 2.0),
		$item[shard of double-ice] : (3.5 * mall_price($item[shard of double-ice])) / min(1000, my_maxmp()), // opportunity cost of April Shower
	};
	foreach idx, it in restoreItems {
		if ( ! (itemToMPGainPerMeat contains it))
			itemToMPGainPerMeat[it] = costPerMPGained(it);
	}

	sort restoreItems by itemToMPGainPerMeat[value];

	foreach idx, it in restoreItems {
		printMPCost(it, itemToMPGainPerMeat[it]);
	}

// 	print("gulp latte: 'free'");
// 	print("april shower: 1000mp @" + (3.5 * mall_price($item[shard of double-ice])) + " meat, " + ((3.5 * mall_price($item[shard of double-ice])) / min(1000, my_maxmp())) + " meat/mp");
// 	print("magical mystery juice: " + ((my_level() * 1.5) + 5) + "mp @45 meat, " + to_string(45 / ((my_level() * 1.5) + 5), "%.3f") + " meat/mp");
// 	printMPCost($item[mangled finger]);
// 	printMPCost($item[neurostim pill]);
// 	printMPCost($item[irradiated turtle]);
// 	printMPCost($item[orcish hand lotion]);
// 	printMPCost($item[carbonated water lily]);
// 	printMPCost($item[honey-dipped locust]);
// 	printMPCost($item[Monstar energy beverage]);
// 	printMPCost($item[ancient magi-wipes]);
// 	printMPCost($item[Doc Galaktik's Invigorating Tonic]);
// 	printMPCost($item[Dyspepsi-Cola]);
// 	printMPCost($item[Cloaca-Cola]);
// 	printMPCost($item[phonics down]);
// 	printMPCost($item[carbonated soy milk]);
// 	printMPCost($item[tiny house]);
// 	printMPCost($item[knob goblin seltzer]);
// 	printMPCost($item[Notes from the Elfpocalypse, Chapter I]);
// 	printMPCost($item[Mountain Stream soda]);
// 	printMPCost($item[dueling turtle]);
// 	printMPCost($item[elven magi-pack]);
// 	printMPCost($item[grogpagne]);
// 	print("Egnaro berry: " + floor(my_maxmp() / 2.0) + " @" + mall_price($item[Egnaro berry]) + " meat, " + (1.0 * mall_price($item[Egnaro berry]) / (my_maxmp() / 2)) + " meat/mp");
}


string mpCostHTML(item anItem) {
	string rval = "";

	int mallPrice = mall_price(anItem);
	effect anEffect = effect_modifier(anItem, "Effect");
	if (anEffect != $effect[none]) {
		float mpPerTurn = (numeric_modifier(anEffect, "MP Regen Min") + numeric_modifier(anEffect, "MP Regen Max")) / 2;
		int effectTurns = numeric_modifier(anItem, "Effect Duration");
		rval = "<tr><td>" + anItem + "</td><td>" + to_string(mpPerTurn, "%.1f") + "mp/turn for " + effectTurns + " turns</td><td>" + mallPrice + "</td><td>" + to_string(mallPrice/(mpPerTurn * effectTurns), "%.3f") + "</td></tr>";
	} else {
		float avgMP = (anItem.minmp + anItem.maxmp) / 2;
		rval = "<tr><td>" + anItem + "</td><td>" + to_string(avgMP, "%.1f") + "mp</td><td>" + mallPrice + "</td><td>" + to_string(mallPrice/avgMP, "%.3f") + "</td><tr>";
	}

	return rval;
}

// TODO update
void cheapestMPRegenHTML() {
	string mpTable = "<table><thead><tr><td>name</td><td>mp restored</td><td>mall price</td><td>meat/mp</td></tr></thead><tbody>";
	mpTable += "<tr><td>magical mystery juice</td><td>" + ((my_level() * 1.5) + 5) + "mp</td><td>45</td><td>" + to_string(45 / ((my_level() * 1.5) + 5), "%.3f") + "</td></tr>";
	mpTable += mpCostHTML($item[mangled finger]);
	mpTable += mpCostHTML($item[neurostim pill]);
	mpTable += mpCostHTML($item[irradiated turtle]);
	mpTable += mpCostHTML($item[orcish hand lotion]);
	mpTable += mpCostHTML($item[carbonated water lily]);
	mpTable += mpCostHTML($item[Monstar energy beverage]);
	mpTable += "<tr></tr>";
	mpTable += "<tr><td>Egnaro berry</td><td>" + floor(my_maxmp() / 2.0) + "</td><td>" + mall_price($item[Egnaro berry]) + " meat</td><td>" + to_string(1.0 * mall_price($item[Egnaro berry]) / (my_maxmp() / 2), "%.3f") + "</td></tr>";
	mpTable += "<tr><td>april shower</td><td>1000mp</td><td>" + (3.5 * mall_price($item[shard of double-ice])) + " meat</td><td>" + to_string((3.5 * mall_price($item[shard of double-ice])) / 1000, "%.3f") + "</td></tr>";
	mpTable += "<tr><td>gulp latte</td><td>" + floor(my_maxmp() / 2.0) + "</td><td>n/a</td><td>n/a</td></tr>";
	mpTable += "</tbody></table>";

	print_html(mpTable);
	print("");
}



void locationMeatDetails(location aLocation, float itemDrop, float meatDrop) {
	record dropdata {
		item drop;
		int rate;
		string type;
	};

	float perAdventureCost = perAdventureCost(aLocation);
	print(aLocation + ", per adv cost: " + perAdventureCost);
	foreach mob, rate in appearance_rates(aLocation) {
		print(mob + " (" + rate + "%) meat drop: " + monsterMeatDropValue(mob, meatDrop) + ", item drop: " + monsterItemMeatValue(mob, itemDrop) + " total: " + (monsterTotalMeatValue(mob, itemDrop, meatDrop) - perAdventureCost));
	}
}

void locationBaseMeatDetails(location aLocation) {
	locationMeatDetails(aLocation, 0, 0);
}

void locationCurrentMeatDetails(location aLocation) {
	locationMeatDetails(aLocation, item_drop_modifier(), meat_drop_modifier());
}



void locationDropDetails(location aLocation) {
	record dropdata {
		item drop;
		int rate;
		string type;
	};
	int counter;

	print("location drop information for: " + aLocation);
	dropdata [monster][int] all_mon_drops;
	foreach i1, mob in get_monsters(aLocation) {
// 		print("mob: " + mob);
		// KoLmafia's database is incomplete
		counter = 0;
		if (mob == $monster[board games elemental]) {
			all_mon_drops[mob][counter].drop = $item[extremely confusing manual];
			all_mon_drops[mob][counter].rate = 20;
			all_mon_drops[mob][counter++].type = "";
			all_mon_drops[mob][counter].drop = $item[foam pistol];
			all_mon_drops[mob][counter].rate = 20;
			all_mon_drops[mob][counter++].type = "";
			continue;
		}
		if (mob == $monster[nerd rapper]) {
			all_mon_drops[mob][counter].drop = $item[charisma potion];
			all_mon_drops[mob][counter].rate = 20;
			all_mon_drops[mob][counter++].type = "";
			all_mon_drops[mob][counter].drop = $item[droppable microphone];
			all_mon_drops[mob][counter].rate = 20;
			all_mon_drops[mob][counter++].type = "";
			continue;
		}
		if (mob == $monster[Arizona bark scorpion]) {
			all_mon_drops[mob][counter].drop = $item[baby bark scorpion];
			all_mon_drops[mob][counter].rate = 1;
			all_mon_drops[mob][counter++].type = "";
			continue;
		}
		if (mob == $monster[swimming pool monster]) {
			all_mon_drops[mob][counter].drop = $item[discarded swimming trunks];
			all_mon_drops[mob][counter].rate = 20;
			all_mon_drops[mob][counter++].type = "";
			all_mon_drops[mob][counter].drop = $item[diluted makeup];
			all_mon_drops[mob][counter].rate = 20;
			all_mon_drops[mob][counter++].type = "";
			continue;
		}
		if (mob == $monster[stumbling-drunk congoer (female)]) {
			all_mon_drops[mob][counter].drop = $item[unidentified drink];
			all_mon_drops[mob][counter].rate = 20;
			all_mon_drops[mob][counter++].type = "";
			all_mon_drops[mob][counter].drop = $item[KoL Con 13 T-shirt];
			all_mon_drops[mob][counter].rate = 20;
			all_mon_drops[mob][counter++].type = "";
			continue;
		}
		if (mob == $monster[stumbling-drunk congoer (male)]) {
			all_mon_drops[mob][counter].drop = $item[unidentified drink];
			all_mon_drops[mob][counter].rate = 20;
			all_mon_drops[mob][counter++].type = "";
			all_mon_drops[mob][counter].drop = $item[KoL Con 13 T-shirt];
			all_mon_drops[mob][counter].rate = 20;
			all_mon_drops[mob][counter++].type = "";
			continue;
		}

		foreach index, rec in item_drops_array(mob) {
// 			print("drop: " + rec.drop);
			all_mon_drops[mob][index].drop = rec.drop;
			all_mon_drops[mob][index].rate = rec.rate;
			all_mon_drops[mob][index].type = rec.type;
		}
	}

	foreach mob, index, data in all_mon_drops {
		string rate = data.rate + "%";
		if (data.type == "0")
			rate = "unknown rate";

		string note = " (" + dropTypeToString(data.type) + ")";
		print(mob + ", drops " + data.drop + ": " + rate + " @ " + cheapest_price(data.drop) + note);
	}
}



int [item] itemEconomics(int threshold) { // #best item
	item [int] sortedItems;
	int [item] rval;
	int sortedIdx;

	foreach anItem in $items[]
		sortedItems[sortedIdx++] = anItem;

	sort sortedItems by -historical_price(value);

	foreach idx, anItem in sortedItems {
		int aPrice = historical_price(anItem);
		if (aPrice >= threshold) {
			rval[anItem] = aPrice;
			print("[" + anItem.to_int() + "]" + anItem + "@" + aPrice);
		}
	}

	return rval;
}



void listHighQuantityItems() {
	item [int] invItems = inventoryArray();
	sort invItems by -available_amount(value);

	foreach x, it in invItems {
		int available = available_amount(it);
		if (available > 2 * my_ascensions()) {
			print(available + "X " + it);
		}
	}
}



// returns the item that sells for the highest price
item highestPriceZapItem(item itemToZap) {
	int highestPrice = 0;
	item highestPriceItem = $item[none];
	foreach zapItem in get_related(itemToZap, "zap") {
		int price = historical_price(zapItem);
		if (price > highestPrice) {
			highestPrice = price;
			highestPriceItem = zapItem;
		}
	}

	return highestPriceItem;
}

int zapProfit(item itemToZap) {
	int totalPrice;
	foreach zapItem in get_related(itemToZap, "zap")
		totalPrice += historical_price(zapItem);

	int zapOptions = count(get_related(itemToZap, "zap"));

// 	return historical_price(highestPriceZapItem(itemToZap)) * (1 / count(get_related(itemToZap, "zap"))) - historical_price(itemToZap);
	return (totalPrice / zapOptions) - historical_price(itemToZap);
}



void zapEconomics() {
	item [int] sortedZapItems;
	int sortedZapIdx;

	foreach anItem in $items[]
		if (highestPriceZapItem(anItem) != $item[none] && zapProfit(anItem) > 0)
			sortedZapItems[sortedZapIdx++] = anItem;

	sort sortedZapItems by -zapProfit(value);

	foreach idx, anItem in sortedZapItems {
		item highestPriceZapItem = highestPriceZapItem(anItem);
		print(anItem + "@" + historical_price(anItem) + " zaps into " + highestPriceZapItem + "@" + historical_price(highestPriceZapItem) + " - potential profit per zap: " + zapProfit(anItem));
	}
}



location [] _gkTTTLocations;
location [] tttLocations() {
	if (count(_gkTTTLocations) == 0) {
		_gkTTTLocations = {
			$location[the cave before time],
			$location[an illicit bohemian party],
			$location[moonshiners' woods],
			$location[the roman forum],
			$location[the post-mall],
			$location[The Spooky Old Abandoned Mine],
			$location[the rowdy saloon],
			$location[globe theatre backstage],
			$location[globe theatre main stage],
			$location[12 west main],
			$location[KoL Con Clan Party House],
			$location[Spring Bros. Solenoids],
			$location[Home of the Future],
			$location[Boltsmann Bearings],
		};
	}
	return _gkTTTLocations;
}


void tttEconomics() {
	foreach idx, loc in tttLocations() {
		int meatValue = locationCurrentMeatValue(loc);
		boolean ppUseful = isPPUseful(loc);
		print(loc + ": " + meatValue + (ppUseful ? " (pp useful)" : ""));
	}

	foreach idx, loc in tttLocations() {
		print("");
		locationCurrentMeatDetails(loc);
	}

	foreach idx, loc in tttLocations() {
		print("");
		locationDropDetails(loc);
	}
}



int [item] _gkChronerItems;
int [item] chronerItems() {
	if (count(_gkChronerItems) == 0) {
		_gkChronerItems = {
			$item[rack of dinosaur ribs] : 25,
			$item[scotch on the rocks] : 25,
			$item[wooly loincloth] : 100,
			$item[yabba dabba doo rag] : 100,
			$item[strange helix fossil] : 300,
			$item[dog ointment] : 25,
			$item[gumshoes] : 200,
			$item[flapper floppers] : 400,
			$item[sneakeasies] : 600,
			$item[centurion helmet] : 25,
			$item[pteruges] : 25,
			$item[unidentifiable dried fruit] : 25,
			$item[flat cider] : 50,
			$item[iShield] : 300,
			$item[white earbuds] : 600,
			$item[iFlail] : 900,
			$item[invisible potion] : 10,
			$item[time shuriken] : 200,
			$item[ninjammies] : 1000,
			$item[rotten tomato] : 25,
			$item[portable othello set] : 100,
			$item[twelve night energy] : 250,
			$item[yorick] : 1000,
			$item[Twitching Television Tattoo] : 1111,
		};
	}
	return _gkChronerItems;
}


void chronerEconomics() {
	foreach it, chroners in chronerItems() {
		int cp = cheapest_price(it);
		print(it + "@" + cp + ": " + chroners + " chroners, " + (cp / chroners) + " meat per chroner");
	}
}



void gardenEconomics() {
	int cmp = mall_price($item[cornucopia]);
	int mmp = mall_price($item[megacopia]);
	print("A Thanksgarden");
	print("day 1: 1X corucopia @ " + cmp + ", total: " + (1 * cmp) + ", per day: " + (1 * cmp / 1));
	print("day 2: 3X corucopia @ " + cmp + ", total: " + (3 * cmp) + ", per day: " + (3 * cmp / 2));
	print("day 3: 5X corucopia @ " + cmp + ", total: " + (5 * cmp) + ", per day: " + (5 * cmp / 3));
	print("day 4: 8X corucopia @ " + cmp + ", total: " + (8 * cmp) + ", per day: " + (8 * cmp / 4));
	print("day 5: 11X corucopia @ " + cmp + ", total: " + (11 * cmp) + ", per day: " + (11 * cmp / 5));
	print("day 6: 15X corucopia @ " + cmp + ", total: " + (15 * cmp) + ", per day: " + (15 * cmp / 6));
	print("day 7: 1X megacopia @ " + mmp + ", total: " + (1 * mmp) + ", per day: " + (1 * mmp / 7));

	int abmp = (mall_price($item[Egnaro berry]) + mall_price($item[Glum berry]) + mall_price($item[Jamocha berry]) + mall_price($item[Keese berry]) + mall_price($item[Nadsat berry]) + mall_price($item[Sitrep berry]) + mall_price($item[Snarf berry]) + mall_price($item[Tapioc berry])) / 14;
	int afmp = (mall_price($item[Unspeakachu]) + mall_price($item[Stooper]) + mall_price($item[Disgeist]) + mall_price($item[Bowlet]) + mall_price($item[Cornbeefadon])) / 5 + mall_price($item[Mu]) / 105;
	print("");
	print("Tall Grass");
	print("day 1-7: " + abmp + " per day");
	print("day 8: " + afmp + ", per day: " + (afmp / 8));

	int mfmp = mall_price($item[mushroom filet]);
	int msmp = mall_price($item[mushroom slab]);
	print("");
	print("Mushroom Garden");
	print("day 1: free-range mushroom @ " + (3 * mfmp) + ", per day: " + (3 * mfmp / 1));
	print("day 2: plump free-range mushroom @ " + (6 * mfmp) + ", per day: " + (6 * mfmp / 2));
	print("day 3: bulky free-range mushroom @ " + (9 * mfmp) + ", per day: " + (9 * mfmp / 3));
	print("day 4: giant free-range mushroom @ " + (1 * msmp + 9 * mfmp) + ", per day: " + ((1 * msmp + 9 * mfmp) / 4));
	print("day 5: immense free-range mushroom @ " + (2 * msmp + 9 * mfmp) + ", per day: " + ((2 * msmp + 9 * mfmp) / 4));
	print("day 11: colossal free-range mushroom @ " + mall_price($item[colossal free-range mushroom]) + ", per day: " + (mall_price($item[colossal free-range mushroom]) / 11));
}



void gingerbreadEconomics() {
	locationDropDetails($location[Gingerbread Train Station]);
	locationCurrentMeatDetails($location[Gingerbread Train Station]);
	print("");
	locationDropDetails($location[Gingerbread Civic Center]);
	locationCurrentMeatDetails($location[Gingerbread Civic Center]);
	print("");
	locationDropDetails($location[Gingerbread Industrial Zone]);
	locationCurrentMeatDetails($location[Gingerbread Industrial Zone]);
	print("");
	locationDropDetails($location[Gingerbread Upscale Retail District]);
	locationCurrentMeatDetails($location[Gingerbread Upscale Retail District]);
	print("");
	locationDropDetails($location[Gingerbread Sewers]);
	locationCurrentMeatDetails($location[Gingerbread Sewers]);
}



void roboEconomics() {
	item [phylum] drops = kRobortenderDrops();
	item [phylum] weak = kRobortenderWeakBooze();
	item [phylum] strong = kRobortenderStrongBooze;
	string printString = "<table><tr><th>strong</th><th>weak</th><th>drop</th><th>phylum</th></tr>";

	foreach phy in kRobortenderStrongBooze {
		printString += "<tr><td>"
			+ strong[phy] + "@" + cheapest_price(strong[phy]) + "</td><td>"
			+ weak[phy] + "@" + cheapest_price(weak[phy]) + "</td><td>"
			+ drops[phy] + "@" + cheapest_price(drops[phy]) + "</td><td>"
			+ phy
			+ "</td></tr>";
	}

	printString += "</table>";

	print_html(printString);
}


void spacegateEconomics() {
	print("Aldebaran sardines: " + cheapest_price($item[Aldebaran sardines]) + " @ 50 research = " + cheapest_price($item[Aldebaran sardines]) / 50 + " per research");
	print("Centauri fish wine: " + cheapest_price($item[Centauri fish wine]) + " @ 50 research = " + cheapest_price($item[Centauri fish wine]) / 50 + " per research");
	print("powdered oxygen: " + cheapest_price($item[powdered oxygen]) + " @ 100 research = " + cheapest_price($item[powdered oxygen]) / 100 + " per research");
	print("portable Spacegate: " + cheapest_price($item[portable Spacegate]) + " @ 1000 research = " + cheapest_price($item[portable Spacegate]) / 1000 + " per research");
	print("Spacegate scientist's insignia: " + cheapest_price($item[Spacegate scientist's insignia]) + " @ 3000 research = " + cheapest_price($item[Spacegate scientist's insignia]) / 3000 + " per research");
	print("Spacegate military insignia: " + cheapest_price($item[Spacegate military insignia]) + " @ 3000 research = " + cheapest_price($item[Spacegate military insignia]) / 3000 + " per research");
	print("Spacegate diplomat's insignia: " + cheapest_price($item[Spacegate diplomat's insignia]) + " @ 3000 research = " + cheapest_price($item[Spacegate diplomat's insignia]) / 3000 + " per research");
	print("Spacegate emergency disintegrator: " + cheapest_price($item[Spacegate emergency disintegrator]) + " @ 5000 research = " + cheapest_price($item[Spacegate emergency disintegrator]) / 5000 + " per research");
	print("Spacegate Initiative tattoo unit: " + cheapest_price($item[Spacegate Initiative tattoo unit]) + " @ 10000 research = " + cheapest_price($item[Spacegate Initiative tattoo unit]) / 10000 + " per research");

	cli_execute("dc alien rock sample");
	cli_execute("dc alien gemstone");
	cli_execute("dc alien plant fibers");
	cli_execute("dc alien plant sample");
	cli_execute("dc complex alien plant sample");
	cli_execute("dc fascinating alien plant sample");
	cli_execute("dc alien toenails");
	cli_execute("dc alien zoological sample");
	cli_execute("dc complex alien zoological sample");
	cli_execute("dc fascinating alien zoological sample");
	cli_execute("dc spant egg casing");
	cli_execute("dc murderbot memory chip");
}



// #fantasyrealmeconomics #fantasy realm economics
void frEconomics() {
	print("FantasyRealm guest pass @ 350 rubees and " + cheapest_price($item[FantasyRealm guest pass]) + " meat or " + cheapest_price($item[FantasyRealm guest pass]) / 350 + " meat / rubee");
	print("LyleCo Contractor's Manual @ 3000 rubees and " + cheapest_price($item[LyleCo Contractor's Manual]) + " meat or " + cheapest_price($item[LyleCo Contractor's Manual]) / 3000 + " meat / rubee");
	print("FantasyRealm tattoo kit @ 10000 rubees and " + cheapest_price($item[FantasyRealm tattoo kit]) + " meat or " + cheapest_price($item[FantasyRealm tattoo kit]) / 10000 + " meat / rubee");

	print("");
	print("hours are each 6 turns in the correct FR zone @ " + kTurnValue + " turn value");
	print("sachet of strange powder: 2 hours @ " + cheapest_price($item[sachet of strange powder]) + ", gain of " + (cheapest_price($item[sachet of strange powder]) / (6 * 2)) + " / turn");
	print("druidic s'more: 2 hours @ " + cheapest_price($item[druidic s'more]) + ", gain of " + (cheapest_price($item[druidic s'more]) / (6 * 2)) + " / turn");
	print("mourning wine: 2 hours @ " + cheapest_price($item[mourning wine]) + ", gain of " + (cheapest_price($item[mourning wine]) / (6 * 2)) + " / turn");
	print("denastified haunch: 4 hours @ " + cheapest_price($item[denastified haunch]) + ", gain of " + (cheapest_price($item[denastified haunch]) / (6 * 4)) + " / turn");
	print("bad rum and good cola: 4 hours @ " + cheapest_price($item[bad rum and good cola]) + ", gain of " + (cheapest_price($item[bad rum and good cola]) / (6 * 4)) + " / turn");
	print("Potion of Heroism: 4 hours @ " + cheapest_price($item[Potion of Heroism]) + ", gain of " + (cheapest_price($item[Potion of Heroism]) / (6 * 4)) + " / turn");
}



void prEconomics () {
	int [item] prItemToFunPoints = {
		$item[PirateRealm party hat] : 20,
		$item[crabsicle] : 100,
		$item[pirate shaving cream] : 100,
		$item[bottle of dark rhum] : 100,
		$item[bottle of extra-dark rhum] : 100,
		$item[bottle of super-extra-dark rhum] : 100,
		$item[PirateRealm guest pass] : 600,
		$item[conquistador's breastplate] : 1000,
		$item[pirate radio ring] : 1000,
		$item[piratical blunderbuss] : 1000,
		$item[plush sea serpent] : 1000,
		$item[pirate fork] : 2000,
		$item[Scurvy and Sobriety Prevention] : 2000,
		$item[lucky gold ring] : 2000,
		$item[Island Drinkin', a Tiki Mixology Odyssey] : 3000,
		$item[Red Roger tattoo kit] : 5000,
	};

	foreach it, fp in prItemToFunPoints {
		int price = cheapest_price(it);
		print(it + "@" + fp + " funpoints costs " + price + " or " + (price/fp) + "/fp");
	}
}



// TODO calculation is just a first rough pass, needs more detail to get it right
int autumnatonLocationMeatValue(location aloc, int acuityUpgrades) {
	float rval;

	foreach mob, appear in appearance_rates(aloc) {
		if (mob != $monster[none] && appear > 0 && count(ppItemDropsArray(mob)) > 1)
			foreach idx, idr in ppItemDropsArray(mob) {
				if (idr.type != "n" && idr.type != "b") {
					float meatValue = historical_price(idr.drop) * (idr.rate / 100.0);
					if (idr.type == "0")
						meatValue = historical_price(idr.drop) * (5.0 / 100.0); // NO DATA (possibly because pp isn't allowed in this zone, such as Gingerbread City zones), so make an assumption of 5% drop rate

// 					print("adding meatValue for " + aloc + ": " + meatValue);
					rval += meatValue;
					string ppType = dropTypeToString(idr.type);
				}
			}
	}

	return rval;
}

void autumnatonEconomicsForLocations(location [] locs) {
	int i;
	location [int] sortedLocations;
	int [location] locationToValue;

	foreach idx, aLoc in locs {
		int locVal = autumnatonLocationMeatValue(aLoc, 0);
		sortedLocations[i++] = aLoc;
		locationToValue[aLoc] = locVal;
	}

	sort sortedLocations by -locationToValue[value];

	foreach idx, loc in sortedLocations {
		int locVal = locationToValue[loc];
		if (locVal > 0)
			print("[" + loc.to_int() + "]" + loc + "@" + locVal);
	}
}

// environment is one of "outdoor", "indoor", "underground"
// difficultyLevel is one of "low", "mid", "high"
void bestAutumnatonLocations(string environment, string difficultyLevel) {
	int i;
	location [int] locs;
	foreach loc in $locations[] {
		if (loc.environment == environment && loc.difficulty_level == difficultyLevel) {
			locs[i++] = loc;
		}
	}
	autumnatonEconomicsForLocations(locs);
}

void autumnatonEconomics() {
	int i;
	location [int] locs;

	if (have_item($item[Autumn-aton])) {
		string autPage = visit_url("/inv_use.php?pwd&which=3&whichitem=10954");
		matcher desc_matcher = create_matcher("<option  value=\"([0-9]+)\">.*?</option>", autPage);

		while (find(desc_matcher)) {
			int locationID = group(desc_matcher, 1).to_int();
			locs[i++] = locationID.to_location();
		}
	} else {
		print("WARNING: Autumn-aton is away so I can't look at it's list of locations, using ALL locations by default", "orange");
		foreach aLoc in $locations[]
			locs[i++] = aLoc;
	}

	autumnatonEconomicsForLocations(locs);
}



void printCatalogueItem(item printItem) {
	print("[" + printItem + "] @ " + current_price(printItem));
}

// 2002 Mr. Store
void catalogueEconomics() {
	printCatalogueItem($item[Spooky VHS tape]);

	print("-");
	printCatalogueItem($item[&quot;I survived Y2K&quot; T-Shirt]);

	print("-");
	printCatalogueItem($item[Letter from Carrie Bradshaw]);
	printCatalogueItem($item[Mr. Big's Wallet]);
	printCatalogueItem($item[Sexy Cosmo]);
	printCatalogueItem($item[red-soled high heels]);
	printCatalogueItem($item[Souvenir Chopsticks]);

	print("-");
	printCatalogueItem($item[pro skateboard]);

	print("-");
	printCatalogueItem($item[Mr. Accessaturday]);

	print("-");
	printCatalogueItem($item[Meat Butler]);

	print("-");
	printCatalogueItem($item[Loathing Idol Microphone]);
	printCatalogueItem($item[Loathing Idol Microphone (75% charged)]);
	printCatalogueItem($item[Loathing Idol Microphone (50% charged)]);
	printCatalogueItem($item[Loathing Idol Microphone (25% charged)]);

	print("-");
	printCatalogueItem($item[Charter: Nellyville]);

	print("-");
	printCatalogueItem($item[Manual of Secret Door Detection]);
	printCatalogueItem($item[Arrow (+1)]);
	printCatalogueItem($item[Azurite]);
	printCatalogueItem($item[Eye Agate]);
	printCatalogueItem($item[Lapis Lazuli]);
	printCatalogueItem($item[scroll of protection from lycanthropes]);
	printCatalogueItem($item[scroll of minor invulnerability]);

	print("-");
	printCatalogueItem($item[Flash Liquidizer Ultra Dousing Accessory]);

	print("-");
	printCatalogueItem($item[Amulet of Perpetual Darkness]);

	print("-");
	printCatalogueItem($item[Giant black monolith]);

	print("-");
	printCatalogueItem($item[Crimbo cookie sheet]);
	printCatalogueItem($item[bell-shaped Crimbo cookie]);
	printCatalogueItem($item[blob-shaped Crimbo cookie]);
	printCatalogueItem($item[huge Crimbo cookie]);
	printCatalogueItem($item[nut-shaped Crimbo cookie]);
	printCatalogueItem($item[traditional Crimbo cookie]);
	printCatalogueItem($item[tree-shaped Crimbo cookie]);
	printCatalogueItem($item[wreath-shaped Crimbo cookie]);
	printCatalogueItem($item[bat-shaped Crimboween cookie]);
	printCatalogueItem($item[skull-shaped Crimboween cookie]);
	printCatalogueItem($item[tombstone-shaped Crimboween cookie]);
}



void main(string arguments) {
}
