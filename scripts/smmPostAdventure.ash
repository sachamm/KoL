import <smmUtils.ash>
string __smmPostAdventure_version = "0.1";

/*
Notes to myself:
you can always find any particular link you are looking for by using the cli 'debug trace on/off' commands.
Turn it on, click the link you want to capture, turn it off...then look in the TRACE log in your mafia folder for the link
*/


void check_doctor_bag_quest() {
	//print("last adventure: " + get_property("lastAdventure"));
	if (get_property("lastAdventure") == "A Pound of Cure") {
		print("adding quest number", "red");
		int numberOfCompletions = to_int(get_property("_doctorQuestNumber")) + 1;
		set_property("_doctorQuestNumber", numberOfCompletions);
	}
}



void main() {
	postAdventure();
}



