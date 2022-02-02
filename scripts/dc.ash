script "dc";
notify TQuilla;
since r26135;

import <smmUtils.ash>
string __dc_version = "0.5";

/**
CLI display case utilities centered around maintaining top 10 collections.

"dc help" in the CLI for help

TODO save the top 10 of each item in the daily env vars _smm.DCTop10 <item>

@author Sacha Mallais (TQuilla #2771003)
*/

int gOvershootAmount = get_property("smm.DCOvershootAmount") == "" ? 11 : get_property("smm.DCOvershootAmount").to_int(); // amount to overshoot the next highest top 10 item
int gSaveAmount = get_property("smm.DCSaveAmount") == "" ? 1 : get_property("smm.DCSaveAmount").to_int(); // amount to save from going into the display case

record IntRange {
	int top;
	int bottom;
};



// dc will call these functions (is_hatchling, is_gift, etc) on each item. if that function returns true for the item, dc will save
// the associated number in this map instead of the default gSaveAmount
int [string] gTypeSaveMap = {
	"is_hatchling" : 0, // hatchlings
	"is_gift" : 0, // gifts
	"is_skillbook" : 0, // skillbooks
};


void printHelp() {
	print_html("<h2>Display Case (dc) Commands:</h2>");
	print_html("<br>Display case utilities centered around maintaining top 10 collections.</br>");
	print_html("<h3>Item commands:</h3>");
	print_html("<br/><strong style=\"color:blue;\"><i>&lt;item&gt;</i></strong>: print a short summary of the given item, including top 10 information");
	print_html("<strong style=\"color:blue;\">list <i>&lt;item&gt;</i></strong>: prints more detailed information on the item, especially the top 10 information");
	print_html("<strong style=\"color:blue;\">addall <i>&lt;item&gt;</i></strong>: add all items you own without regard for the other top 10 entries. Follows the item saving rules (see below)");
	print_html("<strong style=\"color:blue;\">top10 <i>&lt;item&gt;</i></strong>: add <b>or remove</b> items to make the top 10 -- will save some items for your inventory (unless it is a gift item), and will only put 11 more than the next lowest entry if it can't make it to the next higher entry. For example, if the top 1 entry is 200 and #2 is at 100 and you have 123 of that item, 'dc top10 myitem' will add enough to bring you to 111. If you instead had 500 of the same item, it would put in enough to bring you to 211 of that item in your display case.");

	print_html("<h3>Shelf commands:</h3>");
	print_html("<br/><strong style=\"color:blue;\">shelves</strong>: list shelves");
	print_html("<strong style=\"color:blue;\">shelf <i>&lt;name&gt;</i></strong>: list contents and amounts of the named shelf");
	print_html("<strong style=\"color:blue;\">addallshelf <i>&lt;name&gt;</i></strong>: run addall on each item of the named shelf");
	print_html("<strong style=\"color:blue;\">top10shelf <i>&lt;name&gt;</i></strong>: run top10 on each item of the named shelf");
	print_html("<br/>Shelf operations that make changes will print a receipt of operations done. They follow the item save rules (below).");

	print_html("<h3>Item saving rules:</h3>");
	print_html("<br/>All keywords (including 'addall') follow this convention. If the item is not one or more of:");
	print_html("<ul><li style='text-align: left;'>gift</li><li style='text-align: left;'>familiar hatchling</li></ul>");
	print_html("then at least smm.DCSaveAmount (default 1) of the items will be saved from going into the display case.");

	print_html("<br/>All commands will raid Hagnk's and/or your closet if required to achieve a top 10 spot or 'all' of an item.<br/><br/>To add a specific number of items to the display case, use the built-in 'display' command: display put|take [x] item");
}


// ensure there are 10 or 11 entries and that the ranks go sequentially from 1
boolean isValidTop10List(int [int, string] top10List) {
	int idx = 1;
	int totalCount = 0;
	foreach rank, name, num in top10List {
		if (rank == idx) {
			totalCount++;
			idx++;
			continue;
		}
		if (rank == idx - 1) { // same rank as last, i.e. a tie
			totalCount++;
			continue;
		}
		return false;
	}

	if (totalCount != 10 && totalCount != 11)
		return false;

	return true;
}


string toString(int [int, string] top10List) {
	string rval;
	foreach rank, name, num in top10List {
		rval += rank + ". " + name + ": " + num + "</br>\n";
	}
	return rval;
}

void printTop10List(int [int, string] top10List) {
	print_html(toString(top10List));
}


int rank1Amount(int [int, string] collection) {
	foreach s in collection[1] {
		return collection[1, s];
	}
	abort("could not find top");
	return 0;
}

int rank10Amount(int [int, string] collection) {
	int totalCount = 0;
	foreach rank, name, num in collection {
		totalCount++;
		if (totalCount == 10)
			return num;
	}
	abort("could not find bottom");
	return 0;
}

IntRange collectionRange(int [int, string] collection) {
	IntRange rval;
	rval.top = rank1Amount(collection);
	rval.bottom = rank10Amount(collection);
	return rval;
}


void dcPrintItemDetails(item anItem, int [int, string] top10List) {
	int equippedAmount = equipped_amount(anItem);
	int itemAmount = item_amount(anItem);
	int storageAmount = storage_amount(anItem);
	int closetAmount = closet_amount(anItem);
	int displayAmount = display_amount(anItem);
	int shopAmount = shop_amount(anItem);
	int total = equippedAmount + itemAmount + storageAmount + closetAmount + shopAmount + displayAmount;

	int availableAmount = available_amount(anItem);
	if ((availableAmount + displayAmount + shopAmount) != total)
		print("WARNING: inconsistent amount! available + display + shop: " + (availableAmount + displayAmount + shopAmount) + ", calculated: " + total + " -- check Left-Hand Man!", "red");

	string top10RangeString;
	IntRange top_10_range;
	if (count(top10List) > 0) {
		string myRankString;
		string myNewRankString;
		IntRange top_10_range = collectionRange(top10List);
		foreach rank, name, num in top10List {
			if (name.contains_text(my_name()) && myRankString == "")
				myRankString = " (my rank now: " + rank + ", ";
			if (displayAmount >= num && myNewRankString == "")
				myNewRankString = "will be: " + rank + ")";
		}

		if (myNewRankString == "")
			myNewRankString = ", will be: unranked)";
		if (myRankString == "")
			myRankString = " (my rank: unranked" + myNewRankString;
		else
			myRankString += myNewRankString;
		top10RangeString = " Top 10 range: " + top_10_range.top + "-" + top_10_range.bottom + myRankString;
	}

	print(equippedAmount + " equipped and " + itemAmount
		+ " in inv (+" + storageAmount + " stored +" + closetAmount + " in closet +" + shopAmount + " in the shop) and "
		+ displayAmount + " in case, total available: " + total + "." + top10RangeString);
}

void dcPrintItemDetails(item anItem) {
	int [int, string] emptyList;
	dcPrintItemDetails(anItem, emptyList);
}



// returns the value of the given index without having to dereference the string
int amount(int an_index, int [int, string] the_collection) {
	foreach s in the_collection[an_index]
		return the_collection[an_index, s];
	abort("could not find amount");
	return 0;
}

string name(int an_index, int [int, string] the_collection) {
	foreach s in the_collection[an_index]
		return s;
	abort("could not find name at index " + an_index);
	return "";
}



// returns true if the given item is in the top 10
boolean in_top10(item anItem, int [int, string] collection) {
	return display_amount(anItem) >= rank10Amount(collection);
}



// returns the top 10 list -- value is the number of items, indexed by user name and the top 10 spot number
// tries Jicken Wings first, then the wiki if that doesn't work
int [int, string] lookupCollection(item anItem) {
	int [int, string] top10List;
	string pageString = visit_url("http://dcdb.coldfront.net/collections/index.cgi?query_value=" + to_int(anItem) + "&query_type=item", true, false);

	matcher itemMatcher = create_matcher("<tr><td bgcolor=\"blue\" align=\"center\" valign=\"center\"><font color=\"white\"><b>(.*) \\(#([0-9]+)\\)</b></font></td></tr>", pageString);
	assert(find(itemMatcher), "lookupCollection: could not find the item name in Jicken Wings");
	print("[" + group(itemMatcher, 2) + "]" + group(itemMatcher, 1));

	matcher range_matcher = create_matcher("<tr><td bgcolor=\"white\" align=\"center\" valign=\"center\"><b>([0-9]+)</b></td>.*?<b>([^<]*)</b>.*?<b>([0-9,]+)</b></td></tr>", pageString);
	for i from 1 to 11 {
		boolean found = find(range_matcher);
		if (!found && i < 11) {
			if (i > 1) abort("unexpected error");
			print("problem matching the Top 10 list from coldfront, trying wiki");
			pageString = visit_url("https://kol.coldfront.net/thekolwiki/index.php/" + anItem.replace_string(" ", "_"), true, false);
			range_matcher = create_matcher("[0-9]+\. <a href=.*?player'>(.*?) - ([0-9]+)</a>", pageString);
			if (!find(range_matcher)) abort("wiki didn't work either");
		} else if (!found && i == 11) { // the wiki doesn't have entry #11
			continue;
		}
		top10List[group(range_matcher, 1).to_int(), group(range_matcher, 2)] = to_int(group(range_matcher, 3));
	}

	assert(isValidTop10List(top10List), "lookupCollection: something wrong with the top 10 list:\n" + toString(top10List));

	return top10List;
}



int saveAmount(item anItem) {
	int saveAmount = 1;
	foreach evalString, tmpSaveAmount in gTypeSaveMap {
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
	int goalIndex = 10;
	if (!in_top10(anItem, top10List)) {
		goalAmount = rank10Amount(top10List) + gOvershootAmount;
	} else {
		for i from 10 to 1 by -1
			if (amount(i, top10List) == displayAmount)
				goalIndex = i - 1;
		if (goalIndex < 1) goalIndex = 1;
		goalAmount = amount(goalIndex, top10List) + gOvershootAmount;
	}
	// don't go higher than the next spot up
	if (goalIndex > 1 && goalAmount > amount(goalIndex - 1, top10List))
		goalAmount = amount(goalIndex - 1, top10List) - 1;
	// if we don't have enough, try for the minimum
	if (goalAmount > availableAmount + displayAmount)
		goalAmount = amount(goalIndex, top10List) + 1;
	if (goalAmount > availableAmount + displayAmount)
		abort("don't have enough " + anItem + " to reach spot " + goalIndex + " (need " + (goalAmount - availableAmount - displayAmount) + " more to reach goal of " + goalAmount + " units -- have " + availableAmount + ")");

	return goalAmount;
}

// returns the number of items in the display case that would put us at the highest position
// in the Top 10 list that we can reach, trying to be +11 over the next highest
// (will be less than +11 if there aren't enough items)
int calcHighestGoalAmount(item anItem, int [int, string] top10List) {
	int invAmount = item_amount(anItem);

	int availableAmount = available_amount(anItem) + shop_amount(anItem) - saveAmount(anItem);

	int displayAmount = display_amount(anItem);

	int goalAmount = availableAmount + displayAmount;
	if (goalAmount < rank10Amount(top10List)) {
		print("goal amount of " + goalAmount + " isn't enough to beat #10 @ " + rank10Amount(top10List), "blue");
		return 0;
	}

	int goalIndex;
	for i from 1 to count(top10List) {
		if (amount(i, top10List) < goalAmount) {
			goalIndex = i;
			break;
		}
	}
	// if goalIndex is zero now, I'm not in the top 10 list, remove all items
	if (goalIndex == 0)
		return 0;

	// if i'm already at the goal index, the goal index is one less, unless i'm #10
	if (name(goalIndex, top10List) == my_name()) {
		// if we're #10, don't add or remove any
		if (goalIndex == 10)
			goalAmount = displayAmount;
		else
			goalIndex++;
	}
	if (goalAmount > amount(goalIndex, top10List) + gOvershootAmount)
		goalAmount = amount(goalIndex, top10List) + gOvershootAmount;
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
		if (putAmount > invAmount) {
			take_shop(min(shop_amount(anItem), putAmount - invAmount), anItem);
			invAmount = item_amount(anItem);
		}

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
void addallItem(item anItem) {
	addallItem(anItem, saveAmount(anItem));
}



// can we do something with these args?
void verifyArguments(string arguments) {
	string [int] argv = split_string(arguments, " ");

	if (argv[0] == "shelf" || argv[0] == "shelves" || argv[0] == "top10shelf" || argv[0] == "addallshelf") {
		return;
	} else if (argv[0] == "top10" || argv[0] == "auto") {
		string item_string = cdr(argv).joinString(" ");
		if (to_item(item_string) == $item[none]) abort("bad item: " + item_string);
		return;
	} else if (argv[0] == "addall") {
		string item_string = cdr(argv).joinString(" ");
		if (to_item(item_string) == $item[none]) abort("bad item: " + item_string);
		return;
	} else if (argv[0] == "list") {
		string item_string = cdr(argv).joinString(" ");
		if (to_item(item_string) == $item[none]) abort("bad item: " + item_string);
		return;
	} else if (is_integer(argv[0]) && to_int(argv[0]) != 0) {
		string item_string = cdr(argv).joinString(" ");
		if (to_item(item_string) == $item[none]) abort("bad item: " + item_string);
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
		addallItem(anItem, 0);

	// print top 10 details of given item
	} else if ((argv[0] == "list" || argv[0] == "info") && anItem == $item[none]) {
		anItem = to_item(cdr(argv).joinString(" "));
		top10List = lookupCollection(anItem);
		printTop10List(top10List);

	// print top 10 details of given item
	} else if (argv[0] == "shelves" && anItem == $item[none]) {
		string pageString = visit_url("/displaycollection.php?who=" + my_id(), true, false);
		print("Shelves:");
		matcher shelfMatcher = create_matcher("shelf([\\d]+)\\\"\\);\\\' class=nounder><font color=white>([\\w ]+?)</font>", pageString);
		while (find(shelfMatcher)) {
			int shelfNumber = to_int(group(shelfMatcher, 1));
			string shelfName = group(shelfMatcher, 2);
			print(shelfNumber + ": " + shelfName);
		}
		exit;

	// operate on a whole shelf
	} else if ((argv[0] == "shelf" || argv[0] == "top10shelf" || argv[0] == "addallshelf") && anItem == $item[none]) {
		int [item] receipt;
		string pageString = visit_url("/displaycollection.php?who=" + my_id(), true, false);

		string shelfName = optionArgvString;
		if (shelfName == "") shelfName = "Top 10";

		matcher shelfMatcher = create_matcher("<table.+?(shelf[0-9]+).+?" + shelfName + ".+?(shelf[0-9]+)(.+?)</table>", pageString);
		find(shelfMatcher);
		string shelfId = group(shelfMatcher, 1);
		string shelfPage = group(shelfMatcher, 3);
		int itemsOnShelf = 0;

		matcher listMatcher = create_matcher("<td valign=center><b>(.*?)</b> ?\\(?([0-9,]*)\\)?</td>", shelfPage);
		while (find(listMatcher)) {
			string itemName = group(listMatcher, 1);
			int itemAmount = to_int(group(listMatcher, 2));
			itemsOnShelf++;

			if (argv[0] == "shelf")
				print(itemName + " " + itemAmount);

			else if (argv[0] == "top10shelf") {
				print("");
				anItem = to_item(itemName);
				top10List = lookupCollection(anItem);
				int delta = top10Item(anItem, top10List);
				if (delta != 0)
					receipt[anItem] = delta;
				dcPrintItemDetails(anItem, top10List);

			} else { // addallshelf
				print("looking at: " + itemName);
				anItem = to_item(itemName);
				int delta = addallItem(anItem, 0);
				if (delta != 0)
					receipt[anItem] = delta;
				dcPrintItemDetails(anItem);
			}
		}
		print(itemsOnShelf + " items on the shelf, changes made: ");
		printReceipt(receipt);
		exit;
	}

	if (count(top10List) == 0)
		top10List = lookupCollection(anItem);
	dcPrintItemDetails(anItem, top10List);
}


