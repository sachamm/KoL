import <smmUtils.ash>
string __tc_version = "0.1";

/**
Test Case (tc)

Notes to myself:
you can always find any particular link you are looking for by using the cli 'debug trace on/off' commands.
Turn it on, click the link you want to capture, turn it off...then look in the TRACE log in your mafia folder for the link
*/


void testTrue(boolean tester) {
	if (!tester) abort("test failed");
	else print("test passed");
}

void testFalse(boolean tester) {
	if (tester) abort("test failed");
	else print("test passed");
}



void testAlreadyEquipping() {
	use_familiar($familiar[left-hand man]);
	testFalse(alreadyEquipping("+equip aerogel attache case", $slot[off-hand]));
	testTrue(alreadyEquipping("+equip aerogel attache case, +equip Kramco Sausage-o-Matic", $slot[off-hand]));
	testFalse(alreadyEquipping("equip Fourth of May Cosplay Saber, equip aerogel attache case", $slot[weapon]));
	testFalse(alreadyEquipping("equip Fourth of May Cosplay Saber, equip aerogel attache case", $slot[off-hand]));
	testFalse(alreadyEquipping("item, 0.25 meat, +equip mafia thumb ring, booze drop, equip cardboard wine carrier, equip booze drive button, +equip Kremlin's Greatest Briefcase, -equip broken champagne bottle, +equip pantogram pants", $slot[off-hand]));
	testTrue(canEquipWithMaxString("item, 0.25 meat, +equip mafia thumb ring, booze drop, equip cardboard wine carrier, equip booze drive button, +equip Kremlin's Greatest Briefcase, -equip broken champagne bottle, +equip pantogram pants", $item[latte lovers member's mug]));


	use_familiar($familiar[none]);
	testTrue(alreadyEquipping("equip aerogel attache case", $item[aerogel attache case]));
	testTrue(alreadyEquipping("+equip aerogel attache case", $item[aerogel attache case]));
	testFalse(alreadyEquipping("-equip aerogel attache case", $item[aerogel attache case]));
	testFalse(alreadyEquipping("item, 0.25 meat, +equip mafia thumb ring, +equip \"i voted\" sticker, +equip mafia thumb ring, -equip broken champagne bottle", $item[broken champagne bottle]));

	testFalse(alreadyEquipping("-equip aerogel attache case", $slot[weapon]));
	testFalse(alreadyEquipping("-equip aerogel attache case", $slot[off-hand]));

	testFalse(alreadyEquipping("-equip Fourth of May Cosplay Saber", $slot[weapon]));
	testFalse(alreadyEquipping("-equip Fourth of May Cosplay Saber", $slot[off-hand]));

	testFalse(alreadyEquipping("-equip Fourth of May Cosplay Saber, -equip aerogel attache case", $slot[weapon]));
	testFalse(alreadyEquipping("-equip Fourth of May Cosplay Saber, -equip aerogel attache case", $slot[off-hand]));

	testFalse(alreadyEquipping("-equip Fourth of May Cosplay Saber, -equip antique machete", $slot[weapon]));
	testFalse(alreadyEquipping("-equip Fourth of May Cosplay Saber, -equip antique machete", $slot[off-hand]));

	testFalse(alreadyEquipping("-equip mafia thumb ring", $slot[acc1]));
	testFalse(alreadyEquipping("-equip mafia thumb ring", $slot[acc2]));
	testFalse(alreadyEquipping("-equip mafia thumb ring", $slot[acc3]));

	testFalse(alreadyEquipping("-equip mafia thumb ring, -equip ring of the Skeleton Lord", $slot[acc1]));
	testFalse(alreadyEquipping("-equip mafia thumb ring, -equip ring of the Skeleton Lord", $slot[acc2]));
	testFalse(alreadyEquipping("-equip mafia thumb ring, -equip ring of the Skeleton Lord", $slot[acc3]));

	testFalse(alreadyEquipping("-equip mafia thumb ring, -equip ring of the Skeleton Lord, -equip Order of the Silver Wossname", $slot[acc1]));
	testFalse(alreadyEquipping("-equip mafia thumb ring, -equip ring of the Skeleton Lord, -equip Order of the Silver Wossname", $slot[acc2]));
	testFalse(alreadyEquipping("-equip mafia thumb ring, -equip ring of the Skeleton Lord, -equip Order of the Silver Wossname", $slot[acc3]));

	testFalse(alreadyEquipping("equip aerogel attache case", $slot[weapon]));
	testTrue(alreadyEquipping("equip aerogel attache case", $slot[off-hand]));

	testFalse(alreadyEquipping("equip Fourth of May Cosplay Saber", $slot[weapon]));
	testFalse(alreadyEquipping("equip Fourth of May Cosplay Saber", $slot[off-hand]));

	testTrue(alreadyEquipping("equip Fourth of May Cosplay Saber, equip aerogel attache case", $slot[weapon]));
	testTrue(alreadyEquipping("equip Fourth of May Cosplay Saber, equip aerogel attache case", $slot[off-hand]));

	testTrue(alreadyEquipping("equip Fourth of May Cosplay Saber, equip antique machete", $slot[weapon]));
	testTrue(alreadyEquipping("equip Fourth of May Cosplay Saber, equip antique machete", $slot[off-hand]));

	testFalse(alreadyEquipping("equip mafia thumb ring", $slot[acc1]));
	testFalse(alreadyEquipping("equip mafia thumb ring", $slot[acc2]));
	testFalse(alreadyEquipping("equip mafia thumb ring", $slot[acc3]));

	testFalse(alreadyEquipping("equip mafia thumb ring, equip ring of the Skeleton Lord", $slot[acc1]));
	testFalse(alreadyEquipping("equip mafia thumb ring, equip ring of the Skeleton Lord", $slot[acc2]));
	testFalse(alreadyEquipping("equip mafia thumb ring, equip ring of the Skeleton Lord", $slot[acc3]));

	testTrue(alreadyEquipping("equip mafia thumb ring, equip ring of the Skeleton Lord, equip Order of the Silver Wossname", $slot[acc1]));
	testTrue(alreadyEquipping("equip mafia thumb ring, equip ring of the Skeleton Lord, equip Order of the Silver Wossname", $slot[acc2]));
	testTrue(alreadyEquipping("equip mafia thumb ring, equip ring of the Skeleton Lord, equip Order of the Silver Wossname", $slot[acc3]));

	// make sure the "+equip" form works
	testFalse(alreadyEquipping("+equip aerogel attache case", $slot[weapon]));
	testTrue(alreadyEquipping("+equip aerogel attache case", $slot[off-hand]));

	testFalse(alreadyEquipping("+equip Fourth of May Cosplay Saber", $slot[weapon]));
	testFalse(alreadyEquipping("+equip Fourth of May Cosplay Saber", $slot[off-hand]));

	testTrue(alreadyEquipping("+equip Fourth of May Cosplay Saber, +equip aerogel attache case", $slot[weapon]));
	testTrue(alreadyEquipping("+equip Fourth of May Cosplay Saber, +equip aerogel attache case", $slot[off-hand]));

	testTrue(alreadyEquipping("+equip Fourth of May Cosplay Saber, +equip antique machete", $slot[weapon]));
	testTrue(alreadyEquipping("+equip Fourth of May Cosplay Saber, +equip antique machete", $slot[off-hand]));

	testFalse(alreadyEquipping("+equip mafia thumb ring", $slot[acc1]));
	testFalse(alreadyEquipping("+equip mafia thumb ring", $slot[acc2]));
	testFalse(alreadyEquipping("+equip mafia thumb ring", $slot[acc3]));

	testFalse(alreadyEquipping("+equip mafia thumb ring, +equip ring of the Skeleton Lord", $slot[acc1]));
	testFalse(alreadyEquipping("+equip mafia thumb ring, +equip ring of the Skeleton Lord", $slot[acc2]));
	testFalse(alreadyEquipping("+equip mafia thumb ring, +equip ring of the Skeleton Lord", $slot[acc3]));

	testTrue(alreadyEquipping("+equip mafia thumb ring, +equip ring of the Skeleton Lord, +equip Order of the Silver Wossname", $slot[acc1]));
	testTrue(alreadyEquipping("+equip mafia thumb ring, +equip ring of the Skeleton Lord, +equip Order of the Silver Wossname", $slot[acc2]));
	testTrue(alreadyEquipping("+equip mafia thumb ring, +equip ring of the Skeleton Lord, +equip Order of the Silver Wossname", $slot[acc3]));
}



void testexpandOutfits() {
	testTrue(expandOutfits("outfit swashbuckling getup").contains_text("equip swashbuckling pants"));
}



BanishSkillRecord [int] banishSkillTestData(boolean ignoreCost, int usesAvailable, int basePriority) {
	int kUnlimitedUses = 10000;
	BanishSkillRecord tempBSR;
	BanishSkillRecord [int] bsrArray;
	int i = 0;

	// Asdon Martin: Spring-Loaded Front Bumper
	tempBSR = new BanishSkillRecord();
	tempBSR.banishSkill = $skill[Asdon Martin: Spring-Loaded Front Bumper];
	tempBSR.banishItem = $item[none];
	tempBSR.meatCost = 1400;
	tempBSR.priority = 4.1;
	tempBSR.usesAvailable = kUnlimitedUses;
	tempBSR.isAvailableNow = ignoreCost;
	bsrArray[i++] = tempBSR;

	// Show them your ring
	tempBSR = new BanishSkillRecord();
	tempBSR.banishSkill = $skill[Show them your ring];
	tempBSR.banishItem = $item[mafia middle finger ring];
	tempBSR.priority = basePriority;
	tempBSR.usesAvailable = usesAvailable;
	tempBSR.isAvailableNow = true;
	bsrArray[i++] = tempBSR;

	// Throw Latte on Opponent
	tempBSR = new BanishSkillRecord();
	tempBSR.banishSkill = $skill[Throw Latte on Opponent];
	tempBSR.banishItem = $item[Latte lovers member's mug];
	tempBSR.priority = basePriority + 0.1;
	tempBSR.usesAvailable = usesAvailable;
	tempBSR.isAvailableNow = true;
	bsrArray[i++] = tempBSR;

	// KGB tranquilizer dart
	tempBSR = new BanishSkillRecord();
	tempBSR.banishSkill = $skill[KGB tranquilizer dart];
	tempBSR.banishItem = $item[Kremlin's Greatest Briefcase];
	tempBSR.priority = basePriority + 0.1;
	tempBSR.usesAvailable = 3;
	tempBSR.isAvailableNow = true;
	bsrArray[i++] = tempBSR;

	return bsrArray;
}


void testBanishToUse() {
//SkillRecord banishToUse(BanishSkillRecord [int] banishData, boolean isInCombat, location aLocation, boolean ignoreCost, BanishSkillRecord [int] excludedBanishes) {

	BanishSkillRecord [int] banishData = banishSkillTestData(true, 1, 3);
	testTrue(banishToUse(banishData, false, $location[none], true).skill_to_use == $skill[KGB tranquilizer dart]);

	banishData = banishSkillTestData(true, 4, 4);
	testTrue(banishToUse(banishData, false, $location[none], false).skill_to_use == $skill[Asdon Martin: Spring-Loaded Front Bumper]);

	banishData = banishSkillTestData(true, 4, 5);
	testTrue(banishToUse(banishData, false, $location[none], false).skill_to_use == $skill[Asdon Martin: Spring-Loaded Front Bumper]);

	banishData = banishSkillTestData(true, 4, 2);
	testTrue(banishToUse(banishData, false, $location[none], false).skill_to_use == $skill[Show them your ring]);

	banishData = banishSkillTestData(false, 1, 3);
	testTrue(banishToUse(banishData, false, $location[none], false).skill_to_use == $skill[KGB tranquilizer dart]);

	banishData = banishSkillTestData(false, 3, 3);
	testTrue(banishToUse(banishData, false, $location[none], false).skill_to_use == $skill[Show them your ring]);
}



void testUsingBanish() {
	// have to manually set up tests each time based on the current state
	printBSR(false, $location[none], false);
	printBSR(false, $location[the oasis], false);
	testTrue(using_banish($skill[Snokebomb], $location[the oasis]));
	testTrue(using_banish($skill[Snokebomb], $location[none]));
}



void allTests() {
	testUsingBanish();
	testAlreadyEquipping();
	testexpandOutfits();
	testBanishToUse();
}


void main(string arguments) {
	switch(arguments) {
		case "usingBanish":
			print("test usingBanish", "blue");
			testUsingBanish();
			break;

		case "alreadyEquipping":
			print("test alreadyEquipping", "blue");
			testAlreadyEquipping();
			break;

		case "expandOutfits":
			print("test expandOutfits", "blue");
			testexpandOutfits();
			break;

		case "banishToUse":
			print("test banishToUse", "blue");
			testBanishToUse();
			break;

		default:
			print("all tests", "blue");
			allTests();
	}
}



