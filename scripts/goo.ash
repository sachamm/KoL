import <smmUtils.ash>
string __goo_version = "0.5";

/*
*/

void printHelp() {
	print_html("<span style=\"font-size:1.5em;font-weight:bold;\">Display Case (dc) Commands:</span>");
	print_html("<small>Display case utilities centered around maintaining top 10 collections.</small>");
	print_html("<br/>These commands operate on a single item.");
	print_html("<strong style=\"color:blue;\"><i>&lt;item&gt;</i></strong>: print a short summary of the given item, including top 10 information");
	print_html("<strong style=\"color:blue;\">list <i>&lt;item&gt;</i></strong>: prints more detailed information on the item, especially the top 10 information");
	print_html("<strong style=\"color:blue;\">addall <i>&lt;item&gt;</i></strong>: add all items you own save one to the display case (unless it is a gift item, in which case every one is added)");
	print_html("<strong style=\"color:blue;\">top10 <i>&lt;item&gt;</i></strong>: add <b>or remove</b> items to make the top 10 -- will save one item for your inventory (unless it is a gift item), and will only put 11 more than the next lowest entry if it can't make it to the next higher entry. For example, if the top 1 entry is 200 and #2 is at 100 and you have 123 of that item, 'dc top10 myitem' will add enough to bring you to 111. If you instead had 500 of the same item, it would put in enough to bring you to 211 of that item in your display case.");

	print_html("<br/>These commands operate on an entire shelf in the display case.");
	print_html("<strong style=\"color:blue;\">shelf <i>&lt;name&gt;</i></strong>: list contents and amounts of the named shelf in the display case");
	print_html("<strong style=\"color:blue;\">addallshelf <i>&lt;name&gt;</i></strong>: run addall on each item of the named shelf");
	print_html("<strong style=\"color:blue;\">top10shelf <i>&lt;name&gt;</i></strong>: run top10 on each item of the named shelf");

	print_html("<br/><small>All commands will raid Hagnk's and/or your closet if required to achieve a top 10 spot or 'all' of an item.<br/><br/>To add a specific number of items to the display case, use the built-in 'display' command: display put|take [x] item</small>");
}


// can we do something with these args?
void verifyArguments(string arguments)
{
	string [int] argv = split_string(arguments, " ");

// 	if (argv[0] == "shelf" || argv[0] == "top10shelf" || argv[0] == "addallshelf") {
// 		return;
// 	} else if (argv[0] == "top10" || argv[0] == "auto") {
// 		string item_string = join_string(" ", cdr(argv));
// 		if (to_item(item_string) == $item[none]) abort("bad item");
// 		return;
// 	} else if (argv[0] == "addall") {
// 		string item_string = join_string(" ", cdr(argv));
// 		if (to_item(item_string) == $item[none]) abort("bad item");
// 		return;
// 	} else if (argv[0] == "list") {
// 		string item_string = join_string(" ", cdr(argv));
// 		if (to_item(item_string) == $item[none]) abort("bad item");
// 		return;
// 	} else if (is_integer(argv[0]) && to_int(argv[0]) != 0) {
// 		string item_string = join_string(" ", cdr(argv));
// 		if (to_item(item_string) == $item[none]) abort("bad item");
// 		return;
// 	} else if (to_item(arguments) == $item[none]) {
// 		abort("bad item");
//     }
}

void main(string arguments) {
	//arguments = arguments.to_lower_case(); NO!
	string [int] argv = split_string(arguments, " ");

	if (count(argv) == 1 && argv[0] == "version") {
		print("goo v" + __goo_version);
		return;
	} else if (count(argv) == 1 && argv[0] == "help") {
		printHelp();
		return;
	}

	verifyArguments(arguments);

	//maximize("mainstat", false);
	monster [] targets = {$monster[grey goo square], $monster[grey goo orb], $monster[grey goo torus], $monster[grey goo triangle], $monster[grey goo hexagon], $monster[grey goo cross], $monster[grey goo heart], $monster[grey goo octagon], $monster[grey goo squiggle], $monster[grey goo star]};
	target_mob($location[The Goo Fields], targets, $skill[none], 10, false, false); // optimal, ignore cost
}


