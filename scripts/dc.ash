script "dc";
notify TQuilla;
since r26135;

import <smmUtils.ash>
string __dc_version = "0.9";

/**
gCLI display case utilities centered around maintaining top 10 collections while saving items in your inventory.

"dc help" in the gCLI for help.

Scrapes the top 10 info from Jicken Wings (or the KoL wiki if that isn't available), and then caches
that info for the day.

@author Sacha Mallais (TQuilla #2771003)
*/

int gkDCOvershootAmount = get_property("smm.dcOvershootAmount") == "" ? 11 : get_property("smm.dcOvershootAmount").to_int(); // amount to overshoot the next highest top 10 item
int gkDCSaveAmount = get_property("smm.dcSaveAmount") == "" ? 1 : get_property("smm.dcSaveAmount").to_int(); // amount to save from going into the display case


// dc will call these functions (is_hatchling, is_gift, etc) on each item. if that function returns true for
// the item, dc will save the associated number in this map instead of the default gkDCSaveAmount
int [string] gkTypeSaveMap = {
	"is_equipment" : 3, // any type of equipment TODO is_equipment is buggy right now
	"is_gift" : 3, // gifts
	"is_skillbook" : 0, // skillbooks
	"is_hatchling" : 0, // hatchlings
};



void printHelp() {
	print_html("<br/>dc [<i>options</i>] <i>command</i> <i>parameters</i>");
	print_html("<br/>Display case utilities centered around maintaining top 10 collections.</br>\nReplace <i>italicized words</i> with the appropriate argument. Arguments in square brackets [] are optional.");

	print_html("<h4>Options:</h4>");
	print_html("<br/><strong style=\"color:blue;\">--dry-run</strong>: Print out what the command WOULD do, but does NOT do it. Ex: dc --dry-run top10 bottle of rum (unimplemented)");
	print_html("Options always come before the command.");

	print_html("<h4>Item commands:</h4>");
	print_html("<br/><strong style=\"color:blue;\"><i>item</i></strong>: Print a short summary of the disposition of the given item, including top 10 information. Ex: dc bone abacus");
	print_html("<strong style=\"color:blue;\">list <i>item</i></strong>: Print more detailed information on the item, especially the top 10 information. Ex: dc list finger cymbals");
	print_html("<strong style=\"color:blue;\">addall <i>item</i></strong>: Add all items you own without regard for the other top 10 entries. Follows the item saving rules (see below). Ex: dc addall bar skin");
	print_html("<strong style=\"color:blue;\">top10 <i>item</i></strong>: Add <b>or remove</b> items to make the top 10 -- will save items according to the item saving rules (see below), and will only put <i>smm.dcOvershootAmount</i> (default: 11) more than the next lowest rank if it can't make it to the next higher rank. Removes everything if it can't achieve rank #10.");
	print_html("• For example, if #1 is 200 and #2 is at 100 and you have 123 of that item, 'dc top10 myitem' will add enough to bring you to 111. If you instead had 500 of the same item, it would put in enough to bring you to 211 of that item in your display case.");
	print_html("<strong style=\"color:blue;\">snipemin <i>[max-number-to-buy]</i> <i>item</i></strong>: Buy any minimum-priced items on the mall (unimplemented)");
	print_html("<strong style=\"color:blue;\">snipe <i>max-price</i> <i>[max-number-to-buy]</i> <i>item</i></strong>: Buy any minimum-priced items on the mall (unimplemented)");

	print_html("<h4>Shelf commands:</h4>");
	print_html("<br/><strong style=\"color:blue;\">shelves</strong>: list shelves");
	print_html("<strong style=\"color:blue;\">shelf <i>name</i></strong>: list contents and amounts of the named shelf");
	print_html("<strong style=\"color:blue;\">addallshelf <i>name</i></strong>: run addall on each item of the named shelf");
	print_html("<strong style=\"color:blue;\">top10shelf <i>name</i></strong>: run top10 on each item of the named shelf");
	print_html("<strong style=\"color:blue;\">snipeminshelf <i>[max-number-to-buy]</i> <i>name</i></strong>: run snipemin on each item of the named shelf (unimplemented)");
	print_html("<br/>Shelf operations that make changes will print a receipt of operations done. They follow the item save rules (below).");

	print_html("<h4>Item saving rules:</h4>");
	print_html("<br/>If the item is not one or more of: gift, familiar hatchling, or skillbook then at least <i>smm.dcSaveAmount</i> (default 1) of the items will be saved from going into the display case.");
	print_html("Familiar hatchlings, skillbooks save 0 items in the inventory, gifts save 3 items in the inventory.");
	print_html("All commands (including 'addall') follow these rules.");
	print_html("Why save items?");
	print_html("• Keep at least one of the item available for use. Especially useful for equipment.");
	print_html("• Obscure the number of items you actually have.");
	print_html("• Don't waste items that don't help you get a higher rank. Sell the rest!");

	print_html("<br/>All commands will raid Hagnk's and/or your closet (but not  your shop) if required to achieve a top 10 spot or 'all' of an item.");

	print_html("<h4>Configuration:</h4>");
	print_html("<br/>dc recognizes these properties:");
	print_html("<strong style=\"color:blue;\">smm.dcOvershootAmount</strong>: the amount to overshoot. Use a very large number to put everything in the display case (still follows item saving rules, but see smm.dcSaveAmount)");
	print_html("<strong style=\"color:blue;\">smm.dcSaveAmount</strong>: the number of items to save from going into the display case. See above for details on the items saving rules");
	print_html("To see a property, use: get <i>property name</i>");
	print_html("To set a property, use: set <i>property name</i>=<i>property value</i>");

	print_html("<h4>Example Usage</h4>");
	print_html("<br/>dc spider web");
	print_html("Summary of top 10 info for spider web.");

	print_html("<br/>NB. To add a specific number of items to the display case, use the built-in 'display' command: 'display put|take [x] <i>item</i>'");
	print_html("<br/><small>Version " + __dc_version + ". Copyright 2018-2022. Licensed under <a href=\"https://creativecommons.org/licenses/by-sa/4.0/\">CC BY-SA</a> version 4.0 or any later version. If this help looks poorly formatted, try 'clear; dc help' on the gCLI.</small>");
}


void dcPrintItemDetails(item anItem, int [int, string] top10List) {
	int equippedAmount = equipped_amount(anItem);
	int familiarEquippedAmount = familiar_equipped_amount(anItem); // familiars holding the equipment but NOT our current familiar, which will be caught by equippedAmount
	int itemAmount = item_amount(anItem);
	int storageAmount = storage_amount(anItem);
	int closetAmount = closet_amount(anItem);
	int displayAmount = display_amount(anItem);
	int shopAmount = shop_amount(anItem);
	int total = equippedAmount + familiarEquippedAmount + itemAmount + storageAmount + closetAmount + displayAmount + shopAmount;

	int availableAmount = available_amount(anItem);
	if ((availableAmount + displayAmount + shopAmount) != total)
		print("WARNING: inconsistent amount! available + display + shop: " + (availableAmount + displayAmount + shopAmount) + ", calculated: " + total + " -- check familiar equipment!", "red");

	string top10RangeString;
	IntRange top_10_range;
	if (count(top10List) > 0) {
		string myRankString;
		string myNewRankString;
		IntRange top_10_range = collectionRange(top10List);
		foreach rank, name, num in top10List {
			if (name.contains_text(my_name()) && myRankString == "")
				myRankString = " (my rank now: " + rank;
			if (displayAmount >= num && myNewRankString == "")
				myNewRankString = ", will be: " + rank + ")";
		}

		if (myNewRankString == "")
			myNewRankString = ", will be: unranked)";
		if (myRankString == "")
			myRankString = " (my rank: unranked" + myNewRankString;
		else
			myRankString += myNewRankString;
		top10RangeString = " Top 10 range: " + top_10_range.top + "-" + top_10_range.bottom + myRankString;
	}

	print(equippedAmount + " equipped (" + familiarEquippedAmount + " by familiars that are NOT your current familiar) and " + itemAmount
		+ " in inv (+" + storageAmount + " stored +" + closetAmount + " in closet +" + shopAmount + " in the shop) and "
		+ displayAmount + " in case, total available: " + total + "." + top10RangeString);
}

void dcPrintItemDetails(item anItem) {
	int [int, string] emptyList;
	dcPrintItemDetails(anItem, emptyList);
}



int saveAmount(item anItem) {
	int saveAmount = 1;
	foreach evalString, tmpSaveAmount in gkTypeSaveMap {
		boolean shouldSave = call boolean evalString (anItem);
		if (shouldSave) {
			saveAmount = tmpSaveAmount;
			print(evalString + " is saving " + saveAmount);
		}
	}
	return saveAmount;
}



// returns the number of items in the display case that would increase our position one spot,
// trying to be +11 over the next highest
// (though will be less than +11 if there aren't enough items)
int calcMoveUpOneSpot(item anItem, int [int, string] top10List) {
	int invAmount = item_amount(anItem);
	int availableAmount = item_amount(anItem) + storage_amount(anItem) + closet_amount(anItem) - 1; // keeps 1 out of the dc
	int displayAmount = display_amount(anItem);

	int goalAmount;
	int goalRank = 10;
	if (!in_top10(anItem, top10List)) {
		goalAmount = rank10Amount(top10List) + gkDCOvershootAmount;
	} else {
		for i from 10 to 1 by -1
			if (amountAtRank(i, top10List) == displayAmount)
				goalRank = i - 1;
		if (goalRank < 1) goalRank = 1;
		goalAmount = amountAtRank(goalRank, top10List) + gkDCOvershootAmount;
	}
	// don't go higher than the next spot up
	if (goalRank > 1 && goalAmount > amountAtRank(goalRank - 1, top10List))
		goalAmount = amountAtRank(goalRank - 1, top10List) - 1;
	// if we don't have enough, try for the minimum
	if (goalAmount > availableAmount + displayAmount)
		goalAmount = amountAtRank(goalRank, top10List) + 1;
	if (goalAmount > availableAmount + displayAmount)
		abort("don't have enough " + anItem + " to reach spot " + goalRank + " (need " + (goalAmount - availableAmount - displayAmount) + " more to reach goal of " + goalAmount + " units -- have " + availableAmount + ")");

	return goalAmount;
}

// returns the number of items in the display case that would put us at the highest position
// in the Top 10 list that we can reach, trying to be +11 over the next highest
// (will be less than +11 if there aren't enough items)
int calcHighestGoalAmount(item anItem, int [int, string] top10List) {
	int displayAmount = display_amount(anItem);
	int availableAmount = available_amount(anItem) - saveAmount(anItem);

	int goalAmount = availableAmount + displayAmount;
	if (goalAmount < rank10Amount(top10List)) {
		print("goal amount of " + goalAmount + " isn't enough to beat #10 @ " + rank10Amount(top10List), "blue");
		return 0;
	}

	int goalRank;
	foreach rank, name, num in top10List {
		if (num < goalAmount) {
			goalRank = rank;
			break;
		}
	}

	// if goalRank is zero now, I'm not in the top 10 list, remove all items
	if (goalRank == 0)
		return 0;

	// if i'm already at the goal index, the goal index is one less, unless i'm #10
	if (nameAtRank(goalRank, top10List) == my_name()) {
		// if we're #10, don't add or remove any
		if (goalRank == 10)
			goalAmount = displayAmount;
		else
			goalRank++;
	}
	if (goalAmount > amountAtRank(goalRank, top10List) + gkDCOvershootAmount)
		goalAmount = amountAtRank(goalRank, top10List) + gkDCOvershootAmount;
	return goalAmount;
}


// put the given item into the dc, only goes to +11 more than next highest on the Top 10 list
// puts 0 in if you don't have enough to get higher than the next tier
// will also remove items to enforce the above rules
// always keeps one item out of the display case for use
// returns the delta of items put in/taken out of the case
int top10Item(item anItem, int [int, string] top10List) {
	int displayAmount = display_amount(anItem);
	int goalAmount = calcHighestGoalAmount(anItem, top10List);
	int putAmount = goalAmount - displayAmount;

	if (putAmount > 0) {
		int invAmount = item_amount(anItem);
		if (putAmount > invAmount) {
			take_storage(min(storage_amount(anItem), putAmount - invAmount), anItem);
			invAmount = item_amount(anItem);
		}
		if (putAmount > invAmount) {
			take_closet(min(closet_amount(anItem), putAmount - invAmount), anItem);
			invAmount = item_amount(anItem);
		}
		// DON'T take from the shop
// 		if (putAmount > invAmount) {
// 			take_shop(min(shop_amount(anItem), putAmount - invAmount), anItem);
// 			invAmount = item_amount(anItem);
// 		}

		print("dc: putting " + putAmount + " " + anItem + " into display case", "green");
		put_display(putAmount, anItem);
	} else if (putAmount < 0) {
		string logColour = "orange";
		if (-putAmount == displayAmount) logColour = "red"; // we're taking everything out of the dc (will affect future shelf operations)
		print("dc: taking " + -putAmount + " " + anItem + " from display case", logColour);
		take_display(-putAmount, anItem);
	} else
		print("dc: nothing to do");

	return putAmount;
}



// puts all of the given item into the dc. saves amountToSave outside the dc
int addallItem(item anItem, int amountToSave) {
	int invAmount = item_amount(anItem);
	int displayAmount = display_amount(anItem);
	int availableAmount = invAmount + storage_amount(anItem) + closet_amount(anItem);
	int goalAmount = displayAmount + availableAmount;

	// keep 1 out of the dc
// 	if (!anItem.gift)
	goalAmount -= amountToSave;

	int putAmount = goalAmount - displayAmount;
	retrieve_item(putAmount, anItem);

	if (putAmount > 0) { // we're adding, ignore less than 0
		print("putting " + putAmount + " " + anItem + " into display case", "green");
		put_display(putAmount, anItem);
	}

	return putAmount;
}

// puts all of the given item into the dc. saves one outside the dc if it isn't a gift item
int addallItem(item anItem) {
	return addallItem(anItem, saveAmount(anItem));
}



// can we do something with these args?
void verifyArguments(string arguments) {
	string [] argv = split_string(arguments, " ");
	string itemString = cdr(argv).joinString(" ");

	if (argv[0] == "shelf" || argv[0] == "shelves" || argv[0] == "top10shelf" || argv[0] == "addallshelf") {
		return;
	} else if (argv[0] == "top10" || argv[0] == "auto") {
		if (to_item(itemString) == $item[none]) abort("bad item: " + itemString);
		return;
	} else if (argv[0] == "addall") {
		if (to_item(itemString) == $item[none]) abort("bad item: " + itemString);
		return;
	} else if (argv[0] == "list") {
		if (to_item(itemString) == $item[none]) abort("bad item: " + itemString);
		return;
	} else if (argv[0] == "snipemin") {
		string [] snipeArgv = split_string(itemString, " ");
		if (to_item(itemString) == $item[none])
			abort("bad item: " + itemString);
		return;
	} else if (is_integer(argv[0]) && to_int(argv[0]) != 0) {
		if (to_item(itemString) == $item[none]) abort("bad item: " + itemString);
		return;
	} else if (to_item(arguments) == $item[none]) {
		abort("bad item: " + arguments);
    }
}

void main(string arguments) {
	//arguments = arguments.to_lower_case(); NO!
	string [int] argv = split_string(arguments, " ");

	if (count(argv) == 1 && argv[0] == "version") {
		print("DisplayCase v" + __dc_version);
		return;
	} else if (count(argv) == 1 && argv[0] == "help") {
		printHelp();
		return;
	}

	verifyArguments(arguments);
	item anItem = to_item(arguments); // just a default, most likely will actually fail due to argv[0] being an option selector (auto, list, shelf, etc.) -- this will be handled below
	string [int] cdrArgv = cdr(argv);
	string optionArgvString = cdrArgv.joinString(" ");

	// check for ambiguous cases
	if (anItem != $item[none] && (argv[0] == "top10" || argv[0] == "auto" || argv[0] == "addall" || argv[0] == "list" || argv[0] == "shelf" || argv[0] == "top10shelf" || argv[0] == "addallshelf" || (is_integer(argv[0]) && to_int(argv[0]) != 0)) && (to_item(optionArgvString) != $item[none])) {
		abort("ERROR ambiguous: " + anItem + " and " + to_item(optionArgvString) + " are both items!");
	}

	int [int, string] top10List;
	// case: put the given item into the dc, only goes to +11 more than next highest on the Top 10 list
	// puts 0 in if you don't have enough to get higher than the next tier
	if ((argv[0] == "top10" || argv[0] == "auto") && anItem == $item[none]) {
		anItem = to_item(optionArgvString);
		top10List = lookupCollection(anItem);
		top10Item(anItem, top10List);

	// add all of the given item to the dc
	} else if ((argv[0] == "addall") && anItem == $item[none]) {
		anItem = to_item(optionArgvString);
		addallItem(anItem);

	// print top 10 details of given item
	} else if ((argv[0] == "list" || argv[0] == "info") && anItem == $item[none]) {
		anItem = to_item(cdr(argv).joinString(" "));
		top10List = lookupCollection(anItem);
		printTop10List(top10List);

	// list shelves
	} else if (argv[0] == "shelves" && anItem == $item[none]) {
		string pageString = rawDisplayCase();
		print("Shelves:");
		foreach shelfNumber, shelfName in shelves() {
			print(shelfNumber + ": " + shelfName);
		}
		exit;

	// operate on a whole shelf
	} else if ((argv[0] == "shelf" || argv[0] == "top10shelf" || argv[0] == "addallshelf") && anItem == $item[none]) {
		int [item] receipt;
		string pageString = rawDisplayCase();

		string shelfName = optionArgvString;
		if (shelfName == "") shelfName = "Top 10";

		int itemsOnShelf = 0;
		foreach shelfItem, itemAmount in shelfItems(shelfName) {
			itemsOnShelf++;

			if (argv[0] == "shelf") {
				receipt[shelfItem] = itemAmount;

			} else if (argv[0] == "top10shelf") {
				print("");
				top10List = lookupCollection(shelfItem);
				int delta = top10Item(shelfItem, top10List);
				if (delta != 0)
					receipt[shelfItem] = delta;
				dcPrintItemDetails(shelfItem, top10List);

			} else { // addallshelf
				print("looking at: " + shelfItem);
				int delta = addallItem(shelfItem);
				if (delta != 0)
					receipt[shelfItem] = delta;
				dcPrintItemDetails(shelfItem);
			}
		}
		print(itemsOnShelf + " items on the shelf");
		printReceipt(receipt);
		exit;
	}

	if (count(top10List) == 0)
		top10List = lookupCollection(anItem);
	dcPrintItemDetails(anItem, top10List);
}


