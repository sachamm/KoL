import <smmUtils.ash>

/*
Format stuff for myself.
*/

// gah, tabs don't copy from the CLI, so just print the item number and do the rest in post
void formatArguments(string arguments) {
	boolean tryAll = false;
	string [int] argv = split_string(arguments, ", ");

	foreach i in argv {
		item theItem = to_item(argv[i]);
		if (theItem == $item[none]) {
			tryAll = true;
			break;
		}
		print("[" + to_int(theItem) + "]" + theItem);
	}

	if (tryAll) {
		item theItem = to_item(arguments);
		if (theItem == $item[none]) {
			print("unknown item: " + arguments, "red");
		} else
			print("[" + to_int(theItem) + "]" + theItem);
	}
}

void main(string arguments) {
	formatArguments(arguments);
}


