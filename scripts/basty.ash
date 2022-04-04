script "basty";
notify TQuilla;
since r26135;

import <smmUtils.ash>;
import <bastille.ash>;
import <relay/BastilleRelay.ash>;

string __basty_version = "0.8";

/**
Win Bastille Battalion (BB) for some definition of "win".

Utilizes code for BB written by Ezandora

"basty help" in the CLI for help

@author Sacha Mallais (TQuilla #2771003)
*/

int gkBastilleBuffAmount = 11;
int gkBastilleWinThreshold = 1900;


void printHelp() {
	print_html("<h2>basty</h2>");
	print_html("<br>Will burn all your Bastille Battalion games in an attempt to get a high score. Locks in whenever it gets over 1900, regardless of other high scores. TODO: sniff high scores and only stop when you've hit that.</br>");
	print_html("<h3>Commands:</h3>");
	print_html("<br/><strong style=\"color:blue;\">win</strong>: just do 'basty win' from the CLI to 'win' Bastille Battalion!");
	print_html("<strong style=\"color:blue;\">list</strong>: list the high scores (unimplemented)");
	print_html("<strong style=\"color:blue;\">buff <i>&lt;number&gt;</i></strong>: with no argument, returns the number of buff potions to drink before playing; with a number argument, sets the number of buff potions to drink (unimplemented)");
	print_html("<strong style=\"color:blue;\">threshold <i>&lt;number&gt;</i></strong>: with no argument, returns the win threshold; with a number argument, sets win threshold (unimplemented)");
	print_html("<br>A negative threshold less than -1 means lock in score iff you achieve a the high score AND it is at least the absolute value of the threshold. (unimplemented)</br>");
	print_html("<br>A threshold of -1 means lock in score iff you win high score. (unimplemented)</br>");
	print_html("<br>A threshold of 1 means lock in score if you win high score OR it is your last game. (unimplemented)</br>");
	print_html("<br>A positive threshold over 1 means lock in score if you achieve the threshold score OR it is your last game.</br>");
}



boolean playBastille() {
	// use the item
	visit_url("/inv_use.php?pwd&which=3&whichitem=9928", true, false);

	int totalCheeseGained = 0;
	CheeseDataEntry [int] cheese_data;
	file_to_map("Bastille Cheese Data.txt", cheese_data);

	buffer pageText = runBastilleChoice(1313, 5);

	int breakout = 100;
	while (breakout > 0) {
		breakout -= 1;
		BastilleStateParse(pageText, false);
		if (__bastille_state.current_choice_adventure_id == 1313) {
			break;
		} else if (__bastille_state.current_choice_adventure_id == 1314) { // Main screen
			pageText = runBastilleChoice(__bastille_state.current_choice_adventure_id, 3); //look for cheese
			continue;
		} else if (__bastille_state.current_choice_adventure_id == 1319) { // Cheese
			string [int][int] buttons = pageText.group_string("<input  class=button type=submit value=\"(.*?)\">");
			int choiceWithTheMost = 0;
			int mostCheese = 0;
			int wishingWellOption = 0;
			foreach key in buttons {
				string button_text = buttons[key][1];
				float cheese_gained = calculateAverageCheeseGained(cheese_data, button_text);
				//print("option '" + button_text + "' gets " + cheese_gained + "cheese.");
				if (button_text == "Use the wishing well")
					wishingWellOption = key + 1;
				if (cheese_gained > mostCheese) {
					mostCheese = cheese_gained;
					choiceWithTheMost = key + 1;
				}
			}
			if (mostCheese <= 100 && wishingWellOption > 0 && totalCheeseGained >= 10) {
				choiceWithTheMost = wishingWellOption;
				print("USING WISHING WELL", "blue");
			}
			//print("choosing option " + choiceWithTheMost + ", which gets " + mostCheese + " cheese.");
			pageText = runBastilleChoice(__bastille_state.current_choice_adventure_id, choiceWithTheMost);
		} else if (__bastille_state.current_choice_adventure_id == 1315) { //Castle versus castle:
			//pageText = runBastilleChoice(__bastille_state.current_choice_adventure_id, random(3) + 1); //random fight choice
			pageText = runBastilleChoice(__bastille_state.current_choice_adventure_id, 2);
		} else if (__bastille_state.current_choice_adventure_id == 1316) {
			//GAME OVER
			print("GRAND TOTAL CHEESE: " + totalCheeseGained, "blue");
			if ((totalCheeseGained > 1900 || to_int(get_property("_bastilleGames")) == 5) && pageText.contains_text("Lock in your score")) {
				print("locking in score", "red");
				pageText = runBastilleChoice(__bastille_state.current_choice_adventure_id, 1); //lock in score
				set_property("_bastilleGamesLockedIn", true); // so we don't try and do more
				return true;
			} else {// if (!pageText.contains_text("Lock in your score"))
				pageText = runBastilleChoice(__bastille_state.current_choice_adventure_id, 3); //stop playing
				return false;
			}
		} else {// we don't know what's going on
			abort("should never get here!");
		}

		matcher cheeseMatcher = create_matcher("You gain ([0-9]*) cheese", to_string(pageText));
		if (find(cheeseMatcher))
			totalCheeseGained += to_int(group(cheeseMatcher, 1));
		print("total cheese: " + totalCheeseGained, "blue");
	}

	// we shouldn't get here
	print("playBastille: unexpected end", "red");
	return false;
}

void doBastille() {
	int bastilleGamesPlayed = to_int(get_property("_bastilleGames"));
	while (bastilleGamesPlayed < 5 && !playBastille()) {
		bastilleGamesPlayed = to_int(get_property("_bastilleGames"));
	}
}



// can we do something with these args?
void verifyArguments(string arguments) {
}


void main(string arguments) {
	print("basty args: " + arguments, "green");
	string [int] argv = split_string(arguments, " ");

	if (count(argv) == 1 && argv[0] == "version") {
		print("basty v" + __basty_version);
		return;
	} else if (count(argv) == 1 && argv[0] == "help") {
		printHelp();
		return;
	}

	verifyArguments(arguments);

	doBastille();
}



