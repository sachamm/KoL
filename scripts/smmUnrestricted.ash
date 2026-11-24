import "smmUtils.ash";
import "smmAutomation.ash";
import "VotingBooth.ash";
import <smmIotmRoute.ash>
import <smmSpend.ash>
string __unrestricted_version = "0.9";

/*
  A collection of functions for use in aftercore or in an unrestricted run.

  To use the functions in this ASH script in another ASH script, add this to your script:
  import "smmUnrestricted.ash";

  To use the functions in this ASH script from your command line, do this in the gCLI:
  using smmUnrestricted;

  This will add all the functions in smmUnrestricted.ash AND all it's imports to your command line name space.
  You can then call any function in this file from the command line. For example:

  tm (The Haunted Bathroom, claw-foot bathtub, cannelloni cannon, 14, true, true);
    ^
  NOTE the space between the name of the subroutine and the parenthesis is important for some reason

  Subroutines without any params must be called without the empty parens (), e.g.:
  LOVprep;

  To stop using this and get rid of all traces, do:
  get commandLineNamespace
  set commandLineNamespace=
  (i.e. set the commandLineNamespace to empty. If you have other files that you are "using", the first command
  will show them -- you'll have to re-"using" them after resetting the name space)


  Notes to myself:
  you can always find any particular link you are looking for by using the cli 'debug trace on/off' commands.
  Turn it on, click the link you want to capture, turn it off...then look in the TRACE log in your mafia folder for the link

  KoLmafia SVN connection string
  https://svn.code.sf.net/p/kolmafia/code
*/


string gkSpacegateCoordinates = "RATFINK";
item gkJellyToGet = $item[sleaze jelly];
item gkFishyGearToGet = $item[tunac];
# item gkFishyGearToGet = $item[troutsers];


// see also tquillaEats
item gkPreeatItem = $item[none]; // things we "eat" to boost the output of the thing eaten
item gkFoodItem = $item[baked veggie ricotta casserole];
item gkFoodFillItem = $item[roasted vegetable of Jarlsberg]; // should be a 1-fullness item, used to fill any space left over from eating the main item
int gkEatSpleenReduction = 0;
float gkFoodAdvGains = 5.67 + (gkEatSpleenReduction * kTurnsPerSpleen / gkFoodItem.fullness); // per-fullness adv gain
int gkExpectedPreFoodCostPer = 0;
int gkExpectedFoodCostPer = 8899;
int gkExpectedFillFoodCostPer = 3000;
int gkStomachValue = gkFoodAdvGains * kTurnValue;

item gkPredrinkItem = $item[none];
// item gkDrinkItem = $item[jar of fermented pickle juice];
item gkDrinkItem = $item[perfect dark and stormy];
item gkDrinkFillItem = $item[splendid martini]; // should be a 1-fullness item, used to fill any space left over from drinking the main item
item gkStooperDrink = gkDrinkFillItem;
int gkDrinkItemSpleenReduction = 0;
float gkDrinkAdvGains = 6.17 + (gkDrinkItemSpleenReduction * kTurnsPerSpleen / gkDrinkItem.inebriety); // per-inebriety adv gain
int gkExpectedPreDrinkCostPer = 0;
int gkExpectedDrinkCostPer = 2850;
int gkLiverValue = gkDrinkAdvGains * kTurnValue;

item gkPreoverdrinkItem = $item[none];
item gkOverdrinkDrinkItem = $item[sangria del diablo]; // nightcap night cap -- OR sangria del diablo, probably with no pre-drink?
int gkOverdrinkSpleenReduction = 0;

item gkSpleenItem = kSpleenItem;
float gkSpleenAdvGains = kTurnsPerSpleen;

int gkBastilleBuffAmount = 11;


string MallSpecialsPurchasedKey = "_smm.MallSpecialsPurchased";
string ShelfSpecialsPurchasedKey = "_smm.ShelfSpecialsPurchased";
string gDailyFishingGrindKey = "_smm.DailyFishingGrind";

int gStoreSaveAmount = get_property("smm.StoreSaveAmount") == "" ? 11 : get_property("smm.StoreSaveAmount").to_int(); // amount to save from going on sale default 11


// COLD RES BUFFS TODO KGB, pillkeeper, frosty hand (cargo pocket)
AnalyzeRecord [item] gkColdResistanceItems = { // buff amt, is % based?, duration, opportunity cost, effect, effectactivationString // CLI string where %d is number of activations, e.g. "synthesize %d Synthesis: Cold". default activations are handled automatically (use, chew, eat, drink)
	$item[Dreadsylvanian grimlet]: new AnalyzeRecord(5, false, 200, (gkDrinkAdvGains - 9.5) * kTurnValue, $effect[Dreadful Fear]),
	$item[Dreadsylvanian spooky pocket]: new AnalyzeRecord(5, false, 200, (gkFoodAdvGains - 9.5) * kTurnValue, $effect[Dreadful Fear]),
	$item[Dreadsylvanian hot toddy]: new AnalyzeRecord(5, false, 200, (gkDrinkAdvGains - 9.5) * kTurnValue, $effect[Dreadful Heat]),
	$item[Dreadsylvanian hot pocket]: new AnalyzeRecord(5, false, 200, (gkFoodAdvGains - 9.5) * kTurnValue, $effect[Dreadful Heat]),
	$item[bottle of antifreeze]: new AnalyzeRecord(9, false, 10, 0, $effect[Fever From the Flavor]),
	$item[red-hot boilermaker]: new AnalyzeRecord(5, false, 50,  (gkDrinkAdvGains - 3.25) * kTurnValue, $effect[Boilermade]),
	$item[patch of extra-warm fur]: new AnalyzeRecord(5, false, 20, 0, $effect[Furrier Than Thou]),
	$item[oversized ice molecule]: new AnalyzeRecord(5, false, 50, (gkSpleenAdvGains - 0) * kTurnValue, $effect[Icy Composition]),
	$item[Asbestos thermos]: new AnalyzeRecord(5, false, 100, (gkDrinkAdvGains - 3.75) * kTurnValue, $effect[Inner Warmth]),
	$item[Very hot lunch]: new AnalyzeRecord(5, false, 100, (gkFoodAdvGains - 3.75) * kTurnValue, $effect[Inner Warmth]),
	$item[moosemeat pie]: new AnalyzeRecord(5, false, 50, (gkFoodAdvGains - 3.0) * kTurnValue, $effect[Moose-Warmed Belly]),
	$item[warm war shawarma]: new AnalyzeRecord(3, false, 30, (gkFoodAdvGains - 5.5) * kTurnValue, $effect[Shawarma Warm War]),
	$item[cold wad]: new AnalyzeRecord(2, false, 20, (gkSpleenAdvGains - 0) * kTurnValue, $effect[Cold Blooded]),
	$item[lotion of hotness]: new AnalyzeRecord(2, false, 15, 0, $effect[Hot Hands]), // TODO More duration for saucerors
	$item[lotion of spookiness]: new AnalyzeRecord(2, false, 15, 0, $effect[Spooky Hands]), // TODO More duration for saucerors
	$item[penguin paste]: new AnalyzeRecord(2, false, 15, (gkSpleenAdvGains - 1.88) * kTurnValue, $effect[Penguinny Flavor]),
	$item[cold powder]: new AnalyzeRecord(1, false, 5, 0, $effect[Insulated Trousers]),
	$item[cyan seashell]: new AnalyzeRecord(1, false, 20, 0, $effect[Shells of the Damned]),
	$item[recording of Rolando's Rondo of Resisto]: new AnalyzeRecord(5, false, 20, 0, $effect[Rolando's Rondo of Resisto]),
	$item[murderbot shield unit]: new AnalyzeRecord(5, false, 20, 0, $effect[Shielded Unit]),
	$item[vodka barracuda]: new AnalyzeRecord(4, false, 40, (gkDrinkAdvGains - 5.0) * kTurnValue, $effect[Mer-kinkiness]),
	$item[scintillating oyster egg]: new AnalyzeRecord(3, false, 20, (gkSpleenAdvGains - 0) * kTurnValue, $effect[Eggscitingly Colorful]),
	$item[Ish Kabibble]: new AnalyzeRecord(3, false, 25, (gkDrinkAdvGains - 3.5) * kTurnValue, $effect[Feeling No Pain]),
	$item[Party-in-a-Can&trade;]: new AnalyzeRecord(3, false, 50, (gkSpleenAdvGains - 0) * kTurnValue, $effect[Party on Your Skin]),
	$item[rainbow glitter candle]: new AnalyzeRecord(2, false, 80, 0, $effect[Covered in the Rainbow]),
	$item[vodka stinger]: new AnalyzeRecord(2, false, 40, (gkDrinkAdvGains - 4.0) * kTurnValue, $effect[Mer-kindliness]),
	$item[pec oil]: new AnalyzeRecord(2, false, 20, 0, $effect[Oiled-Up]),
	$item[scroll of Protection from Bad Stuff]: new AnalyzeRecord(2, false, 20, 0, $effect[Protection from Bad Stuff]),
	$item[can of black paint]: new AnalyzeRecord(2, false, 10, 0, $effect[Red Door Syndrome]),
	$item[programmable turtle]: new AnalyzeRecord(2, false, 15, 0, $effect[Spiro Gyro]),
	$item[beefy pill]: new AnalyzeRecord(1, false, 30, (gkSpleenAdvGains - 0) * kTurnValue, $effect[Beefy]),
	$item[Tapioc berry]: new AnalyzeRecord(1, false, 20, 0, $effect[Berry Elemental]),
	$item[sticky lava globs]: new AnalyzeRecord(3, false, 20, 0, $effect[Burning Hands]),
	$item[marzipan skull]: new AnalyzeRecord(9, false, 30, 100 + (kTurnValue * kTurnsPerSpleen), $effect[Synthesis: Cold], "synthesize %d Synthesis: Cold"),
	$item[jagged tooth]: new AnalyzeRecord(7, false, 50, -100, $effect[Cold Sweat], "mom cold"),
	$item[grisly shell fragment]: new AnalyzeRecord(3, false, 30, -100, $effect[Rainbow Vaccine], "spacegate vaccine 1"),
	$item[kelp]: new AnalyzeRecord(3, false, 50, -100, $effect[Cold as Nice], "beach head Cold as Nice"),
};



void setDefaultState() {
	setDefaultKoLState();
	setDefaultAutomationState();
}



// -------------------------------------
// FINANCES
// -------------------------------------


// target stock amount is the available amount times the stockFraction minus gStoreSaveAmount
// will save and NOT sell a number of theItem equal to 1/2 the given rank in the top 10 list
boolean stockTop10Item(item theItem, int minPrice, int limit, int targetRank, float stockFraction) {
	// Missing rankings must skip this item before any collection or shop changes.
	int [int, string] collection = lookupCollection(theItem, false);
	if (!isValidTop10List(collection))
		return false;
	int targetRankAmount = amountAtRank(collection, targetRank);
	int amountToSave = targetRankAmount / 2;
	int stockTarget = max(0, ceil((available_amount(theItem) + shop_amount(theItem) - saveAmount(theItem) - amountToSave) * stockFraction));

	print("stockTop10Item target rank: " + targetRank + " @ " + targetRankAmount, "green");
	boolean unused = cli_execute("dc top10 " + theItem);
	return stockItem(minPrice, limit, stockTarget, amountToSave, theItem);
}



void roboritrage(int amountToStock) {
	foreach phy, strongBooze in kRobortenderStrongBooze {
		print("");
		doArrbitrage(strongBooze, amountToStock);
	}
}



// waitTime is the number of milliseconds that we should wait before stocking the store
void stockStore(int waitTime) {
	assert(kTurnValue > 0, "didn't get a turn value!");
	int kSleazeJellyOpportunityCost = kSpleenValue;

	string kLastStockStoreTimeKey = "_smm.LastStockStoreTime";
	int lastTime = kLastStockStoreTimeKey.get_property().to_int();
	if (gametime_to_int() - lastTime < waitTime) {
		print("too soon to stock the store!", "green");
		return;
	}
	kLastStockStoreTimeKey.set_property(gametime_to_int());
	print("stocking store", "green");
	refresh_shop();

	// VENDOR items: stuff we buy cheaper than others can and resell for profit -- theItem, minPrice, limit, targetRank, stockFraction
	stockTop10Item($item[MSG], 1000, 0, 1, 0.09); // min price possible is 1000!!!!!!!!!!
	stockTop10Item($item[savory dry noodles], 1000 + current_price($item[dry noodles]) + kCraftingTurnValue, 0, 1, 0.09);

	// DRIP -- theItem, minPrice, limit, targetRank, stockFraction
	int kDripTurnCost = 8 * kTurnValue;
	int kDripletCost = 2 * kDripTurnCost; // possible to get 5-6 per 11 turns with bats
	stockTop10Item($item[drippy nugget], 8500 + ceil(kSleazeJellyOpportunityCost/1000.0), 0, 1, 0.09);
	stockTop10Item($item[glass of drippy wine], 8500 + ceil(kSleazeJellyOpportunityCost/1000.0), 0, 1, 0.09);
	stockTop10Item($item[Drip Institute petri dish], 4250 + ceil(kSleazeJellyOpportunityCost/1000.0), 0, 1, 0.09);
	stockTop10Item($item[drippy truncheon], 17000 + ceil(kSleazeJellyOpportunityCost/1000.0), 0, 1, 0.09);
	stockTop10Item($item[drippy stake], kDripTurnCost * 16 + 16000 + ceil(kSleazeJellyOpportunityCost/1000.0), 0, 1, 0.09);
	stockTop10Item($item[drippy plum(?)], kDripTurnCost * 16, 0, 1, 0.09); // NC happens every 16 turns
	stockTop10Item($item[drippy khakis], kDripletCost * 30, 0, 1, 0.09);
	stockTop10Item($item[drippy candy bar], kDripTurnCost * 13 + 10000, 0, 1, 0.09); // NC happens every 13 turns
	stockTop10Item($item[drippy caviar], 850000 + ceil(kSleazeJellyOpportunityCost/1000.0), 0, 1, 0.09);
// 	stockTop10Item($item[drippy staff], 850000 + ceil(kSleazeJellyOpportunityCost/1000.0), 0, 1, 0.09);
	stockTop10Item($item[drippy grub], kDripTurnCost * 12, 0, 1, 0.03); // NC happens every 12 turns
// 	stockTop10Item($item[drippy enzyme], kDripTurnCost * 12, 0, 1, 0.09); // do manually?
	stockTop10Item($item[Gooey drippy candy bar], kDripTurnCost * 12 * 2, 0, 1, 0.09);

	// LATHE
// 	stockTop10Item($item[Dripwood slab], kDripTurnCost * 100, 0, 1, 0.09); // do manually????

	// HALLOWE'EN candy -- theItem, minPrice, limit, targetRank, stockFraction -- get ~30 outfit candies per 5-turn block, 6 per turn
	int candyMinValue = kTurnValue * 5.0 / 6.0;
	stockTop10Item($item[chocolate Spider Queen], candyMinValue, 0, 2, 0.09);
	stockTop10Item($item[Wrotz], candyMinValue, 0, 1, 0.09);
	stockTop10Item($item[fiberglass insulation], candyMinValue, 0, 1, 0.09);
	stockTop10Item($item[polyeaster egg], candyMinValue, 0, 1, 0.09);
	stockTop10Item($item[porcelain candy dish], candyMinValue, 0, 3, 0.09);

	// theItem, minPrice, limit, targetRank, stockFraction
	stockTop10Item($item[mojo filter], kTurnValue * 1.5, 0, 1, 0.02);
	stockTop10Item($item[drum machine], kTurnValue, 0, 4, 0.09);
	stockTop10Item($item[Maxwell's Silver Hammer], 13000, 0, 1, 0.01);
	stockTop10Item($item[happiness], 900, 0, 1, 0.11);
	stockTop10Item($item[beer lens], 2 * kTurnValue, 0, 5, 0.09); // 50% drop chance MAX = 2 turns per drop, plus banishes spent

	// sea stuff -- theItem, minPrice, limit, targetRank, stockFraction
	stockTop10Item($item[rusty broken diving helmet], kTurnValue * 1.5, 0, 1, 0.09);
	stockTop10Item($item[rusty rivet], kTurnValue, 0, 1, 0.09);
	stockTop10Item($item[rusty porthole], kTurnValue * 1.5, 0, 1, 0.09);
	stockTop10Item($item[dull fish scale], 100, 0, 2, 0.11);
	stockTop10Item($item[rough fish scale], max(mall_price($item[pristine fish scale]) / 10, mall_price($item[dull fish scale])) * 10, 0, 2, 0.09);
	stockTop10Item($item[Mer-kin pressureglobe], 2 * kTurnValue * (1 / 0.5), 0, 2, 0.09); // 0.5 is the approx drop rate, 2 is for the Fishy buff

	// Time-Spinner #timespinner #time spinner
	stockTop10Item($item[Memory Disk, Alpha], 10000, 0, 1, 0.11);

	// Gingerbread City
	// min price, limit, fraction to stock, item
	//stockTop10Item(15 * kTurnValue, 0, 0.5, $item[broken chocolate pocketwatch]);
	// min price, limit, amount to stock, amount to save, item
	stockItem(15 * kTurnValue, 0, 1, 22, $item[broken chocolate pocketwatch]);
	stockTop10Item($item[gingerbread mug], 1000, 0, 1, 0.09);
	stockTop10Item($item[gingerbread mask], 1000, 0, 1, 0.09);
	stockTop10Item($item[tainted icing], 21000, 0, 1, 0.09);
	stockTop10Item($item[gingerbread dog treat], kTurnValue * 10, 0, 1, 0.09);
	stockTop10Item($item[counterfeit city], 96000, 0, 2, 0.09); // real min price is kTurnValue * 13, but market dictates...

	// space jellyfish -- theItem, minPrice, limit, targetRank, stockFraction
	stockTop10Item($item[sleaze jelly], 30000, 1, 1, 0.06);
	stockTop10Item($item[stench jelly], 30000, 1, 2, 0.06);

	// FantasyRealm -- theItem, minPrice, limit, targetRank, stockFraction
	int frKeyCost = round(smmItemValue($item[FantasyRealm key])); // 10 Rubees, valued by what Rubees buy in the mall
	stockTop10Item($item[sachet of strange powder], 2 * 6 * kTurnValue, 0, 1, 0.09);
	stockTop10Item($item[druidic s'more], 2 * 6 * kTurnValue, 0, 1, 0.09);
	stockTop10Item($item[mourning wine], 2 * 6 * kTurnValue, 0, 1, 0.09);
	stockTop10Item($item[denastified haunch], (4 * 6 * kTurnValue) + frKeyCost, 0, 1, 0.09);
	stockTop10Item($item[bad rum and good cola], (4 * 6 * kTurnValue) + frKeyCost, 0, 1, 0.09);

	// Fortune Teller #madame zatara
	stockTop10Item($item[personal graffiti kit], 150, 0, 1, 0.05);

	// BoomBox -- theItem, minPrice, limit, targetRank, stockFraction
	stockTop10Item($item[Special Seasoning], kTurnValue, 0, 3, 0.06); // TODO should change kTurnValue to 5000???? and set this minPrice to kTurnValue

	// Robortender
	int kRobortenderLowestPrice = 25000;
	int bestPrice = max(kRobortenderLowestPrice, current_price($item[bottle of clam juice]));
	bestPrice = max(bestPrice, current_price($item[low tide martini]));
	bestPrice = max(bestPrice, current_price($item[Bloody Nora]));
	stockTop10Item($item[bottle of clam juice], bestPrice, 0, 2, 0.09);

	bestPrice = max(kRobortenderLowestPrice, current_price($item[peppermint sprig]));
	bestPrice = max(bestPrice, current_price($item[mentholated wine]));
	bestPrice = max(bestPrice, current_price($item[Feliz Navidad]));
	stockTop10Item($item[mentholated wine], bestPrice, 0, 1, 0.09);

	// Neverending Party -- theItem, minPrice, limit, targetRank, stockFraction
	stockTop10Item($item[van key], 5000, 0, 1, 0.09);
	stockTop10Item($item[unremarkable duffel bag], 5000, 0, 1, 0.09);
	stockTop10Item($item[electronics kit], 222, 0, 1, 0.01);

	// Voting Booth -- theItem, minPrice, limit, targetRank, stockFraction
	stockTop10Item($item[absentee voter ballot], kTurnValue, 0, 1, 0.05);
	int bestEctoPrice = max(kTurnValue / 1.5, current_price($item[ghostly ectoplasm])); // ~1.5 drops per adv
	bestEctoPrice = max(bestEctoPrice, current_price($item[haunted orange]) - 63);
	bestEctoPrice = max(bestEctoPrice, current_price($item[haunted bottle of vodka]) - 100);
	bestEctoPrice = max(bestEctoPrice, current_price($item[haunted pizza]) - 163);
	bestEctoPrice = max(bestEctoPrice, current_price($item[haunted martini]) - 163);
	bestEctoPrice = max(bestEctoPrice, current_price($item[haunted cherry pie]) - current_price($item[cherry]) - 100);
	bestEctoPrice = max(bestEctoPrice, current_price($item[haunted Hell ramen]) - current_price($item[Hell ramen]));
	bestEctoPrice = max(bestEctoPrice, current_price($item[haunted eggnog]) - current_price($item[eggnog]));
	bestEctoPrice = max(bestEctoPrice, current_price($item[haunted gimlet]) - current_price($item[gimlet]) - kCraftingTurnValue);
	print("best ectoplasm price: " + bestEctoPrice, "green");
	stockTop10Item($item[ghostly ectoplasm], bestEctoPrice, 0, 1, 0.01);
	stockTop10Item($item[haunted orange], bestEctoPrice + 63, 0, 1, 0.09);
	stockTop10Item($item[haunted bottle of vodka], bestEctoPrice + 100, 0, 1, 0.09);
	stockTop10Item($item[haunted pizza], bestEctoPrice + 163, 0, 1, 0.09);
	stockTop10Item($item[haunted martini], bestEctoPrice + 163, 0, 1, 0.09);
	stockTop10Item($item[haunted cherry pie], bestEctoPrice + current_price($item[cherry]) + 100, 0, 1, 0.09);
	stockTop10Item($item[haunted Hell ramen], bestEctoPrice + current_price($item[Hell ramen]), 0, 1, 0.09);
	stockTop10Item($item[haunted eggnog], bestEctoPrice + current_price($item[eggnog]), 0, 1, 0.09);
	stockTop10Item($item[haunted gimlet], bestEctoPrice + current_price($item[gimlet]) + kCraftingTurnValue, 0, 1, 0.09);
	stockTop10Item($item[glob of undifferentiated tissue], 9000, 0, 1, 0.03);

	// PirateRealm -- theItem, minPrice, limit, targetRank, stockFraction
	float fpPerTurn = 7.0; // seems to be a reasonable guestimate
	int funpointCost = kTurnValue / fpPerTurn;
	stockTop10Item($item[pirate shaving cream], 100 * funpointCost, 0, 1, 0.09);
	stockTop10Item($item[plush sea serpent], 1000 * funpointCost, 0, 1, 0.09);
	stockTop10Item($item[cocoa of youth], 12 * kTurnValue, 0, 1, 0.09); // 12?? turns to get? looks like 8 might be the minimum number of turns required
	stockTop10Item($item[oversized ice molecule], kTurnValue, 0, 1, 0.09);
	stockTop10Item($item[melty plastic grenade], kTurnValue, 0, 1, 0.09);

	// Fireworks Store -- arr, m80 stuff, only sell ABOVE 100 meat
	// theItem, minPrice, limit, targetRank, stockFraction
	stockTop10Item($item[bottle of rum], 100, 0, 5, 0.09);
	stockTop10Item($item[crowbarrr], 150, 0, 2, 0.09);
	stockTop10Item($item[eyepatch], 100, 0, 2, 0.09);
	stockTop10Item($item[flaregun], 222, 0, 5, 0.05);
	stockTop10Item($item[grogpagne], 100, 0, 1, 0.05);
	stockTop10Item($item[grungy bandana], 100, 0, 1, 0.05); // gets up to 600 when someone buys
	stockTop10Item($item[leotarrrd], 200, 0, 1, 0.09);
	stockTop10Item($item[stuffed shoulder parrot], 180, 0, 5, 0.05);
	stockTop10Item($item[sunken chest], 3000, 0, 2, 0.05);
	stockTop10Item($item[swashbuckling pants], 180, 0, 1, 0.09);

	// Combat Lover's Locket -- theItem, minPrice, limit, targetRank, stockFraction
	stockTop10Item($item[cyborg stompin' boot], kTurnValue, 0, 4, 0.05);
	// min price, limit, amount to stock, amount to save, item
	stockItem(kTurnValue, 0, 33, 33, $item[mime soul fragment]);

	// TTT time twitching tower
	// 					theItem, minPrice, limit, targetRank, stockFraction
	stockTop10Item($item[tarnished bottlecap], kTurnValue, 0, 3, 0.05);
	stockTop10Item($item[unused soap], kTurnValue, 0, 4, 0.09);
	stockTop10Item($item[filthy monkey head], 250, 0, 5, 0.09);
	stockTop10Item($item[impure gasoline], kTurnValue, 0, 10, 0.09);
	stockTop10Item($item[viral DNA], kTurnValue, 0, 3, 0.09);
	stockTop10Item($item[TI-9000 calculator], kTurnValue, 0, 5, 0.09);
	stockTop10Item($item[spray chrome], 250, 0, 6, 0.09);
	stockTop10Item($item[z-bone steak], kTurnValue, 0, 10, 0.09);
	stockTop10Item($item[chlorine crystal], kTurnValue, 0, 1, 0.05);

	// 2002 Mr. Store
	int bradshawsPrice = current_price($item[Letter from Carrie Bradshaw]);
	checkIfRunningOut($item[Mr. Big's Wallet], 1);
	stockItem(bradshawsPrice, 0, kMaxInt, 0, $item[Mr. Big's Wallet]);

	// min price, limit, amount to stock, amount to save, item
	stockItem(current_price($item[unused soap]) + current_price($item[TI-9000 calculator]), 0, 2, 0, $item[99.44% pure math]);
// 	stockItem(kTurnValue, 0, 2, 0, $item[Z-Bone steak]);
// 	stockItem(current_price($item[Z-Bone steak]) + current_price($item[viral DNA]), 0, 2, 0, $item[gelatinous meat mass]);

	// ARBITRAGE
// 	if (questStage("questS02Monkees") >= 9) {
// 		doArbitrage($item[scimitar cozy], 7);
// 		doArbitrage($item[fish stick cozy], 4);
// 		doArbitrage($item[bazooka cozy], 4);
// 	}
// 	doArrbitrage($item[4-d camera], 11);
// 	doArrbitrage($item[bartender-in-the-box], 7);
// 	doArrbitrage($item[clockwork bartender-in-the-box], 11);
// 	doArrbitrage($item[internet point], 11);
//
// 	doArbitrage($item[BRICKO bat], 22);
// 	doArbitrage($item[BRICKO oyster], 11);
// 	doArbitrage($item[BRICKO turtle], 11);
// 	doArbitrage($item[BRICKO ooze], 11);
// 	doArbitrage($item[BRICKO octopus], 11);
// 	doArbitrage($item[BRICKO elephant], 22);
// 	doArbitrage($item[BRICKO python], 22);
//
// 	doArrbitrage($item[corrupted bird DNA], 3);
//
// 	roboritrage(11);
//
// 	// XO Skeleton arbitrage
// 	doArbitrage($item[glyph of athleticism], 3);
// 	doArbitrage($item[new habit], 3);
//
// 	// campsite arbitrage
// 	doArbitrage($item[burnt stick], 22);

	// COMBAT LOVER'S LOCKET drops
	stockAllItem($item[evil googly eye], kTurnValue, 0);
	stockAllItem($item[spooky felt], kTurnValue, 0);
	stockAllItem($item[spooky length of string], kTurnValue, 0);
	stockAllItem($item[spooky stuffing], kTurnValue, 0);
	stockAllItem($item[spooky toy wheel], kTurnValue, 0);
	stockAllItem($item[spooky wooden block], kTurnValue, 0);

	// LUCKY items --                                                    amount to stock, limit
	stockLuckyItem($item[frozen Mob Penguin], available_amount($item[frozen Mob Penguin]) + shop_amount($item[frozen Mob Penguin]), 0);
	stockLuckyItem($item[roll of drink tickets], available_amount($item[roll of drink tickets]) + shop_amount($item[roll of drink tickets]), 0);
	stockLuckyItem($item[irradiated pet snacks], available_amount($item[irradiated pet snacks]) + shop_amount($item[irradiated pet snacks]), 0);
	stockLuckyItem($item[bottle of antifreeze], available_amount($item[bottle of antifreeze]) + shop_amount($item[bottle of antifreeze]), 0);

	// 	put_shop(0, 0, available_amount($item[rocky raccoon]) - 250, $item[rocky raccoon]);
	// 	put_shop(0, 0, available_amount($item[savoy truffle]) - 250, $item[savoy truffle]);
	// 	put_shop(0, 0, available_amount($item[hot date]) - 250, $item[hot date]);
	// 	put_shop(0, 0, available_amount($item[palm frond]) - 500, $item[palm frond]);
	// 	put_shop(0, 0, available_amount($item[happiness]) - 1, $item[happiness]);
	// 	put_shop(0, 0, available_amount($item[Maxwell's Silver Hammer]) - 1, $item[Maxwell's Silver Hammer]);
	// 	put_shop(0, 0, available_amount($item[Colonel Mustard's Lonely Spades Club Jacket]) - 1, $item[Colonel Mustard's Lonely Spades Club Jacket]);
	// 	put_shop(0, 0, available_amount($item[Corporal Fennel's Lonely Clubs Club Jacket]) - 1, $item[Corporal Fennel's Lonely Clubs Club Jacket]);
	// 	put_shop(0, 0, available_amount($item[General Sage's Lonely Diamonds Club Jacket]) - 1, $item[General Sage's Lonely Diamonds Club Jacket]);
	// 	put_shop(0, 0, available_amount($item[Private Pepper's Lonely Hearts Club Jacket]) - 1, $item[Private Pepper's Lonely Hearts Club Jacket]);
}

void stockStore() {
	stockStore(0);
}



// current income for sea locations
void currentIncomeSea(float itemDrop, float meatDrop) {
	int perAdventureCost = perAdventureCost($location[The Briny Deeps]);
	print("The Briny Deeps", "blue");
	print("funk sole brother: " + (monsterTotalMeatValue($monster[funk sole brother], false, itemDrop, meatDrop) - perAdventureCost));
	print("pumped-up bass: " + (monsterTotalMeatValue($monster[pumped-up bass], false, itemDrop, meatDrop) - perAdventureCost));
	print("school of wizardfish: " + (monsterTotalMeatValue($monster[school of wizardfish], false, itemDrop, meatDrop) - perAdventureCost));

	perAdventureCost = perAdventureCost($location[The Brinier Deepers]);
	print("The Brinier Deepers", "blue");
	print("bazookafish: " + (monsterTotalMeatValue($monster[bazookafish], false, itemDrop, meatDrop) - perAdventureCost));
	print("clubfish: " + (monsterTotalMeatValue($monster[clubfish], false, itemDrop, meatDrop) - perAdventureCost));
	print("scimitarfish: " + (monsterTotalMeatValue($monster[scimitarfish], false, itemDrop, meatDrop) - perAdventureCost));
	print("trophyfish: " + (monsterTotalMeatValue($monster[trophyfish], false, itemDrop, meatDrop) - perAdventureCost));

	perAdventureCost = perAdventureCost($location[The Briniest Deepests]);
	print("The Briniest Deepests", "blue");
	print("acoustic electric eel: " + (monsterTotalMeatValue($monster[acoustic electric eel], false, itemDrop, meatDrop) - perAdventureCost));
	print("decent white shark: " + (monsterTotalMeatValue($monster[decent white shark], false, itemDrop, meatDrop) - perAdventureCost));
	print("ganger: " + (monsterTotalMeatValue($monster[ganger], false, itemDrop, meatDrop) - perAdventureCost));

	perAdventureCost = perAdventureCost($location[An Octopus's Garden]);
	print("An Octopus's Garden", "blue");
	print("neptune flytrap: " + (monsterTotalMeatValue($monster[neptune flytrap], false, itemDrop, meatDrop) - perAdventureCost));
	print("octopus gardener: " + (monsterTotalMeatValue($monster[octopus gardener], false, itemDrop, meatDrop) - perAdventureCost));
	print("sponge: " + (monsterTotalMeatValue($monster[sponge], false, itemDrop, meatDrop) - perAdventureCost));
	print("stranglin' algae: " + (monsterTotalMeatValue($monster[stranglin' algae], false, itemDrop, meatDrop) - perAdventureCost));

	perAdventureCost = perAdventureCost($location[The Wreck of the Edgar Fitzsimmons]);
	print("The Wreck of the Edgar Fitzsimmons", "blue");
	print("mer-kin scavenger: " + (monsterTotalMeatValue($monster[mer-kin scavenger], false, itemDrop, meatDrop) - perAdventureCost));
	print("cargo crab: " + (monsterTotalMeatValue($monster[cargo crab], false, itemDrop, meatDrop) - perAdventureCost));
	print("drowned sailor: " + (monsterTotalMeatValue($monster[drowned sailor], false, itemDrop, meatDrop) - perAdventureCost));
	print("mine crab: " + (monsterTotalMeatValue($monster[mine crab], false, itemDrop, meatDrop) - perAdventureCost));
	print("unholy diver: " + (monsterTotalMeatValue($monster[unholy diver], false, itemDrop, meatDrop) - perAdventureCost));

	perAdventureCost = perAdventureCost($location[The Coral Corral]);
	print("The Coral Corral", "blue");
	print("sea cowboy: " + (monsterTotalMeatValue($monster[sea cowboy], false, itemDrop, meatDrop) - perAdventureCost));
	print("sea cow: " + (monsterTotalMeatValue($monster[sea cow], false, itemDrop, meatDrop) - perAdventureCost));
	print("mer-kin rustler: " + (monsterTotalMeatValue($monster[mer-kin rustler], false, itemDrop, meatDrop) - perAdventureCost));

	perAdventureCost = perAdventureCost($location[The Dive Bar]);
	print("The Dive Bar", "blue");
	print("mer-kin tippler: " + (monsterTotalMeatValue($monster[mer-kin tippler], false, itemDrop, meatDrop) - perAdventureCost));
	print("lounge lizardfish: " + (monsterTotalMeatValue($monster[lounge lizardfish], false, itemDrop, meatDrop) - perAdventureCost));
	print("nurse shark: " + (monsterTotalMeatValue($monster[nurse shark], false, itemDrop, meatDrop) - perAdventureCost));

	perAdventureCost = perAdventureCost($location[Anemone Mine]);
	print("Anemone Mine", "blue");
	print("anemone combatant: " + (monsterTotalMeatValue($monster[anemone combatant], false, itemDrop, meatDrop) - perAdventureCost));
	print("killer clownfish: " + (monsterTotalMeatValue($monster[killer clownfish], false, itemDrop, meatDrop) - perAdventureCost));
	print("mer-kin miner: " + (monsterTotalMeatValue($monster[mer-kin miner], false, itemDrop, meatDrop) - perAdventureCost));

	perAdventureCost = perAdventureCost($location[The Marinara Trench]);
	print("The Marinara Trench", "blue");
	print("diving belle: " + (monsterTotalMeatValue($monster[diving belle], false, itemDrop, meatDrop) - perAdventureCost));
	print("fisherfish: " + (monsterTotalMeatValue($monster[fisherfish], false, itemDrop, meatDrop) - perAdventureCost));
	print("giant squid: " + (monsterTotalMeatValue($monster[giant squid], false, itemDrop, meatDrop) - perAdventureCost));
	print("mer-kin diver: " + (monsterTotalMeatValue($monster[mer-kin diver], false, itemDrop, meatDrop) - perAdventureCost));

	perAdventureCost = perAdventureCost($location[The Mer-Kin Outpost]);
	print("The Mer-Kin Outpost", "blue");
	print("mer-kin burglar: " + (monsterTotalMeatValue($monster[mer-kin burglar], false, itemDrop, meatDrop) - perAdventureCost));
	print("mer-kin raider: " + (monsterTotalMeatValue($monster[mer-kin raider], false, itemDrop, meatDrop) - perAdventureCost));
	print("mer-kin healer: " + (monsterTotalMeatValue($monster[mer-kin healer], false, itemDrop, meatDrop) - perAdventureCost));

	perAdventureCost = perAdventureCost($location[The Caliginous Abyss]);
	print("The Caliginous Abyss", "blue");
	print("eye in the darkness: " + (monsterTotalMeatValue($monster[eye in the darkness], false, itemDrop, meatDrop) - perAdventureCost));
	print("peanut: " + (monsterTotalMeatValue($monster[peanut], false, itemDrop, meatDrop) - perAdventureCost));
	print("school of many: " + (monsterTotalMeatValue($monster[school of many], false, itemDrop, meatDrop) - perAdventureCost));
	print("slithering thing: " + (monsterTotalMeatValue($monster[slithering thing], false, itemDrop, meatDrop) - perAdventureCost));

	perAdventureCost = perAdventureCost($location[Madness Reef]);
	print("Madness Reef", "blue");
	print("jamfish: " + (monsterTotalMeatValue($monster[jamfish], false, itemDrop, meatDrop) - perAdventureCost));
	print("magic dragonfish: " + (monsterTotalMeatValue($monster[magic dragonfish], false, itemDrop, meatDrop) - perAdventureCost));
	print("pufferfish: " + (monsterTotalMeatValue($monster[pufferfish], false, itemDrop, meatDrop) - perAdventureCost));

	perAdventureCost = perAdventureCost($location[Mer-kin Elementary School]);
	print("Mer-kin Elementary School", "blue");
	print("Mer-kin monitor: " + (monsterTotalMeatValue($monster[Mer-kin monitor], false, itemDrop, meatDrop) - perAdventureCost));
	print("Mer-kin punisher: " + (monsterTotalMeatValue($monster[Mer-kin punisher], false, itemDrop, meatDrop) - perAdventureCost));
	print("Mer-kin teacher: " + (monsterTotalMeatValue($monster[Mer-kin teacher], false, itemDrop, meatDrop) - perAdventureCost));

	perAdventureCost = perAdventureCost($location[Mer-kin Library]);
	print("Mer-kin Library", "blue");
	print("Mer-kin alphabetizer: " + (monsterTotalMeatValue($monster[Mer-kin alphabetizer], false, itemDrop, meatDrop) - perAdventureCost));
	print("Mer-kin drifter: " + (monsterTotalMeatValue($monster[Mer-kin drifter], false, itemDrop, meatDrop) - perAdventureCost));
	print("Mer-kin researcher: " + (monsterTotalMeatValue($monster[Mer-kin researcher], false, itemDrop, meatDrop) - perAdventureCost));

	perAdventureCost = perAdventureCost($location[Mer-kin Gymnasium]);
	print("Mer-kin Gymnasium", "blue");
	print("Mer-kin juicer: " + (monsterTotalMeatValue($monster[Mer-kin juicer], false, itemDrop, meatDrop) - perAdventureCost));
	print("Mer-kin poseur: " + (monsterTotalMeatValue($monster[Mer-kin poseur], false, itemDrop, meatDrop) - perAdventureCost));
	print("Mer-kin trainer: " + (monsterTotalMeatValue($monster[Mer-kin trainer], false, itemDrop, meatDrop) - perAdventureCost));

	perAdventureCost = perAdventureCost($location[Mer-kin Colosseum]);
	print("Mer-kin Colosseum", "blue");
	print("Mer-kin balldodger: " + (monsterTotalMeatValue($monster[Mer-kin balldodger], false, itemDrop, meatDrop) - perAdventureCost));
	print("Mer-kin bladeswitcher: " + (monsterTotalMeatValue($monster[Mer-kin bladeswitcher], false, itemDrop, meatDrop) - perAdventureCost));
	print("Mer-kin netdragger: " + (monsterTotalMeatValue($monster[Mer-kin netdragger], false, itemDrop, meatDrop) - perAdventureCost));
	print("Georgepaul, the Balldodger: " + (monsterTotalMeatValue($monster[Georgepaul, the Balldodger], false, itemDrop, meatDrop) - perAdventureCost));
	print("Johnringo, the Netdragger: " + (monsterTotalMeatValue($monster[Johnringo, the Netdragger], false, itemDrop, meatDrop) - perAdventureCost));
	print("Ringogeorge, the Bladeswitcher: " + (monsterTotalMeatValue($monster[Ringogeorge, the Bladeswitcher], false, itemDrop, meatDrop) - perAdventureCost));
}

void currentIncomeSea() {
	currentIncomeSea(item_drop_modifier(), meat_drop_modifier());
}



void currentIncome(float itemDrop, float meatDrop) {
	int perAdventureCost = perAdventureCost($location[none]);
	print("****INCOME WITH: " + perAdventureCost + " meat spent/adv, +" + itemDrop + "% item, +" + meatDrop + "% meat");

	perAdventureCost = perAdventureCost($location[The Neverending Party]);
	int bikerGain = monsterTotalMeatValue($monster[biker], false, itemDrop, meatDrop) - perAdventureCost;
	int burnoutGain = monsterTotalMeatValue($monster[burnout], false, itemDrop, meatDrop) - perAdventureCost;
	int jockGain = monsterTotalMeatValue($monster[jock], false, itemDrop, meatDrop) - perAdventureCost;
	int partyGirlGain = monsterTotalMeatValue($monster[party girl], false, itemDrop, meatDrop) - perAdventureCost;
	int plainGirlGain = monsterTotalMeatValue($monster["plain" girl], false, itemDrop, meatDrop) - perAdventureCost;
	print("neverending party: " + perAdventureCost + " meat spent/adv, +" + itemDrop + "% item, +" + meatDrop + "% meat");
	print("biker: " + bikerGain);
	print("burnout: " + burnoutGain);
	print("jock: " + jockGain);
	print("party girl: " + partyGirlGain);
	print("'plain' girl: " + plainGirlGain);
	print("neverending party average: " + ((bikerGain + burnoutGain + jockGain + partyGirlGain + plainGirlGain) / 5));
	print("");

	perAdventureCost = perAdventureCost($location[none]);
	print("angry ghost: " + (monsterTotalMeatValue($monster[angry ghost], false, itemDrop, meatDrop) - perAdventureCost));
	print("slime blob: " + (monsterTotalMeatValue($monster[slime blob], false, itemDrop, meatDrop) - perAdventureCost));
	print("terrible mutant: " + (monsterTotalMeatValue($monster[terrible mutant], false, itemDrop, meatDrop) - perAdventureCost));
	print("government bureaucrat: " + (monsterTotalMeatValue($monster[government bureaucrat], false, itemDrop, meatDrop) - perAdventureCost));
	print("annoyed snake: " + (monsterTotalMeatValue($monster[annoyed snake], false, itemDrop, meatDrop) - perAdventureCost));
	print("");

	perAdventureCost = perAdventureCost($location[The Haunted Library]);
	print("The Haunted Library: " + perAdventureCost + " meat spent/adv, +" + itemDrop + "% item, +" + meatDrop + "% meat");
	print("bookbat: " + (mall_price($item[tattered scrap of paper]) * (0.10 * (1.0 + (itemDrop/100.0))) - perAdventureCost)); // mafia's drop rate for tattered scrap of paper is wrong

	perAdventureCost = perAdventureCost($location[Thugnderdome]);
	print("Thugnderdome: " + perAdventureCost + " meat spent/adv, +" + itemDrop + "% item, +" + meatDrop + "% meat");
	print("gnarly/gnasty gnome: " + ((mall_price($item[clockwork key]) * (0.017 * (1.0 + (itemDrop/100.0))) * 2.0) + (mall_price($item[flange]) * (0.022 * (1.0 + itemDrop/100.0))) - perAdventureCost)); // mafia's drop rate for clockwork keys is horribly wrong
	print("gnarly/gnasty gnome: " + (monsterTotalMeatValue($monster[gnasty gnome], false, itemDrop, meatDrop) - perAdventureCost));

	perAdventureCost = perAdventureCost($location[The Oasis]);
	print("The Oasis: " + perAdventureCost + " meat spent/adv, +" + itemDrop + "% item, +" + meatDrop + "% meat");
	print("blur: " + (monsterTotalMeatValue($monster[blur], false, itemDrop, meatDrop) - perAdventureCost));
	print("swarm of scarab beatles: " + (monsterTotalMeatValue($monster[swarm of scarab beatles], false, itemDrop, meatDrop) - perAdventureCost));
}

void currentIncome() {
	currentIncome(item_drop_modifier(), meat_drop_modifier());
}


void printIncomeDetails(monster aMonster) {
	print(aMonster);
	float [item] itemDrops = item_drops(aMonster);
	foreach anItem in itemDrops {
		print(anItem + ": " + itemDrops[anItem] + "% drop @" + mall_price(anItem) + " meat");
	}
}



void luckyIncome() {
	int [location] luckyAdventuresByMeatGainMap = luckyAdventuresByMeatGainMap();
	location [] luckyEconomics = luckyEconomics(false);
	print("turn value: " + kTurnValue + " -- cost to get lucky! with:");
	print("pillkeeper (first): 0, subsequent: " + (3 * kSpleenValue));
	print("Lucky Lindy: " + (kTurnValue * 3 + 500));
	print("11-leaf clover: " + historical_price($item[11-leaf clover]));
	foreach ind, aloc in luckyEconomics {
		print(aloc + ": " + luckyAdventuresByMeatGainMap[aloc]);
	}
}


void luckyCurrentIncome() {
	int [location] luckyAdventuresByMeatGainMap = luckyAdventuresByMeatGainMap();
	location [] luckyEconomics = luckyEconomics(false);
	foreach ind, aloc in luckyEconomics {
		print(aloc + ": " + (luckyAdventuresByMeatGainMap[aloc] - kTurnValue));
	}
}



item [] kCimboItems = {
	$item[gooified animal matter],
	$item[gooified vegetable matter],
	$item[gooified mineral matter],

	$item[fleshy putty],
	$item[third ear],
	$item[festive egg sac],

	$item[poisonsettia],
	$item[peppermint-scented socks],
	$item[the Crymbich Manuscript],

	$item[projectile chemistry set],
	$item[depleted Crimbonium football helmet],
	$item[synthetic rock],

	$item[&quot;caramel&quot; orange],
	$item[self-repairing earmuffs],
	$item[carnivorous potted plant],

	$item[universal biscuit],
	$item[yule hatchet],
	$item[potato alarm clock],

	$item[lab-grown meat],
	$item[golden fleece],
	$item[boxed gumball machine],

	$item[cloning kit],
	$item[electric pants],
	$item[can of mixed everything],
};

void crimcome() {
	string printString = "<table><tr><th>item</th><th>mall value</th></tr>";

	foreach idx, critem in kCimboItems {
		printString += "<tr><td>"
			+ critem + "</td><td>"
			+ mall_price(critem)
			+ "</td></tr>";
	}

	printString += "</table>";

	print_html(printString);
}



// calculates income from some monsters. Dresses up in all item (and then all meat) gear
// use bonusItemDrop and bonusMeatDrop to simulate other item or meat drop buffs that aren't
// currently in effect
void incomeCalculator(int bonusItemDrop, int bonusMeatDrop) {
	clearAutomateDressup();
	use_familiar($familiar[Trick-or-Treating Tot]);

	print("TESTING WITH +ITEM", "blue");
	if (isAsdonWorkshed())
		fueled_asdonmartin("observantly", 1);
	// 	foreach i, rec in maximize("item, 0.1 meat, +switch tot, +switch cat burglar", 1, 2, true, true) {
	// 		if (rec.score >= 1.0) {
	// 			print_html("item #" + i + " score: " + to_string(rec.score, "%.2f") + ", '" + rec.command + "'");
	// 			print("effect: " + rec.effect + ", item: " + rec.item + " skill: " + rec.skill);
	// 			if (rec.effect != $effect[none] && rec.item != $item[none])
	// 				print("cost: " + mall_price(rec.item));
	// 			print("");
	// 		}
	// 	}
	// 	currentIncome(numeric_modifier("Generated:_spec", "Item Drop"), numeric_modifier("Generated:_spec", "Meat Drop"));
	automate_dressup($location[none], "item", "item", "");
	currentIncome(item_drop_modifier() + bonusItemDrop, meat_drop_modifier() + bonusMeatDrop);


	print("TESTING WITH +MEAT", "blue");
	// 	foreach i, rec in maximize("meat, 0.1 item, +switch tot, +switch cat burglar, +switch hobo monkey", 1, 2, true, true) {
	// 		if (rec.score >= 1.0) {
	// 			print_html("item #" + i + " score: " + to_string(rec.score, "%.2f") + ", '" + rec.command + "'");
	// 			print("effect: " + rec.effect + ", item: " + rec.item + " skill: " + rec.skill);
	// 			if (rec.effect != $effect[none] && rec.item != $item[none])
	// 				print("cost: " + mall_price(rec.item));
	// 			print("");
	// 		}
	// 	}
	// 	currentIncome(numeric_modifier("Generated:_spec", "Item Drop"), numeric_modifier("Generated:_spec", "Meat Drop"));
	automate_dressup($location[none], "meat", "meat", "");
	currentIncome(item_drop_modifier() + bonusItemDrop, meat_drop_modifier() + bonusMeatDrop);
}



// calculates income from some monsters. Dresses up in all item (and then all meat) gear
// use bonusItemDrop and bonusMeatDrop to simulate other item or meat drop buffs that aren't
// currently in effect
void incomeCalculator() {
	incomeCalculator(0, 0);
}



// -------------------------------------
// DAILY GRIND CONTROLS -- see docs/daily-spending.md
// -------------------------------------

// A yes/no decision in the daily run. Set smm.dailyGrind.<name> to true or false to
// answer it ahead of time (no pause); leave it unset to be asked as before.
boolean dailyGrindConfirm(string name, string prompt, boolean defaultAnswer) {
	string preset = get_property("smm.dailyGrind." + name);
	if (preset == "true" || preset == "false") {
		print(prompt + " -- " + preset + " (smm.dailyGrind." + name + ")", "blue");
		return preset.to_boolean();
	}
	return user_confirm(prompt, 60000, defaultAnswer);
}

// Copies the Display Case is still short of first place, over a set of items.
// Unranked items count as 0: an unknown gap can't be compared.
int museumShortfall(boolean [item] theItems) {
	int total = 0;
	foreach it in theItems {
		SmmMuseumGoal goal = smmMuseumGoal(it);
		if (goal.known)
			total += smmMuseumMissing(it, goal);
	}
	return total;
}

// The paid-turn grinds that run after the IoTM route share one optional daily
// turn budget (smm.dailyGrind.maxPaidTurns, unset = no limit) and can each be
// switched off (smm.dailyGrind.<name>=false) or forced on (=true).
//
// Each one's turns, Meat and items gained are logged. Once a grind has
// smm.dailyGrind.minDays (default 5) logged days, it is skipped while its
// return per turn stays under kTurnValue. One that is clearly losing, under
// half of kTurnValue, is skipped after smm.dailyGrind.earlyDays (default 2).
// A grind that recently brought in an untradeable item the Display Case
// still needs is never skipped for that, while that item is still short:
// such an item has no price, and unbuyable Museum items come first.
string kGrindTurnsTotalKey = "_smm.grind.turnsTotal";
int gGrindTurnMark;
int gGrindMeatMark;
int [item] gGrindInventoryMark;

// The grind history before 2026-11-25 was valued at listing prices (above).
// It is cleared once, so the turn-value test starts again from honest figures.
string kGrindValueVersionKey = "smm.grind.valueVersion";
boolean [string] kDailyGrindNames = $strings[oasis, beerLens, ghostCostume, spacegate, fantasyRealm, pirateRealm, dailyDungeon, drip, gingerbread];

void dailyGrindMigrateHistory() {
	if (get_property(kGrindValueVersionKey) == "2") return;
	foreach name in kDailyGrindNames {
		foreach key in $strings[histTurns, histValue, histRuns, histMuseumAt, histMuseumItems]
			set_property("smm.grind." + key + "." + name, "");
	}
	set_property(kGrindValueVersionKey, "2");
	print("dailyGrind: cleared the grind history, which valued items at their listing price instead of their sale price", "orange");
}

int dailyGrindMinDays() {
	string explicit = get_property("smm.dailyGrind.minDays");
	return explicit == "" ? 5 : max(1, explicit.to_int());
}

int dailyGrindEarlyDays() {
	string explicit = get_property("smm.dailyGrind.earlyDays");
	return explicit == "" ? 2 : max(1, explicit.to_int());
}

// Why a grind with this history is skipped, "" when it runs. perTurn is -1
// with no history; museumShort is true while an untradeable item it brought
// in recently is still short in the Display Case.
string dailyGrindSkipReason(int runs, int perTurn, int minDays, int earlyDays, int turnValue, boolean museumShort) {
	if (museumShort || perTurn < 0) return "";
	if (runs >= minDays && perTurn < turnValue)
		return "it has returned " + perTurn + " Meat per turn over " + runs + " days against a turn value of " + turnValue;
	if (runs >= earlyDays && perTurn * 2 < turnValue)
		return "it has returned " + perTurn + " Meat per turn over " + runs + " days, under half the turn value of " + turnValue;
	return "";
}

// Logged return per turn over the grind's history, -1 when there is none.
int dailyGrindReturnPerTurn(string name) {
	int turns = get_property("smm.grind.histTurns." + name).to_int();
	if (turns <= 0) return -1;
	return get_property("smm.grind.histValue." + name).to_int() / turns;
}

// True while the grind brought in, within the last minDays logged days, an
// untradeable item the Display Case is still short of. The items are kept in
// smm.grind.histMuseumItems.<name>; history from before that list counts as
// still short.
boolean dailyGrindMuseumRecent(string name) {
	string at = get_property("smm.grind.histMuseumAt." + name);
	if (at == "" || get_property("smm.grind.histRuns." + name).to_int() - at.to_int() >= dailyGrindMinDays()) return false;
	string ids = get_property("smm.grind.histMuseumItems." + name);
	if (ids == "") return true;
	foreach i, id in split_string(ids, ",") {
		item it = id.to_int().to_item();
		if (it == $item[none]) continue;
		SmmMuseumGoal goal = smmMuseumGoal(it);
		if (!goal.known || smmMuseumMissing(it, goal) > 0) return true;
	}
	return false;
}

boolean dailyGrindMayRun(string name) {
	string preset = get_property("smm.dailyGrind." + name);
	if (preset == "false") {
		print("dailyGrind: skipping " + name + " (smm.dailyGrind." + name + "=false)", "blue");
		return false;
	}
	string limit = get_property("smm.dailyGrind.maxPaidTurns");
	if (limit != "" && get_property(kGrindTurnsTotalKey).to_int() >= limit.to_int()) {
		print("dailyGrind: skipping " + name + ", the day's paid-turn budget of " + limit + " is used up", "blue");
		return false;
	}
	// history from before the sale-price valuation is cleared at the next grind, and never skips one before that
	boolean honestHistory = get_property(kGrindValueVersionKey) == "2";
	int runs = get_property("smm.grind.histRuns." + name).to_int();
	if (preset != "true" && honestHistory && runs >= min(dailyGrindEarlyDays(), dailyGrindMinDays())) {
		int perTurn = dailyGrindReturnPerTurn(name);
		// the Museum check reads the Display Case, so it comes last
		string why = dailyGrindSkipReason(runs, perTurn, dailyGrindMinDays(), dailyGrindEarlyDays(), kTurnValue, false);
		if (why != "" && !dailyGrindMuseumRecent(name)) {
			print("dailyGrind: skipping " + name + ", " + why + " (smm.dailyGrind." + name + "=true runs it anyway)", "orange");
			return false;
		}
	}
	return true;
}

// Copies held in inventory, closet and Display Case together. The grinds move
// what they farm between the three (the Spacegate closets its samples, dc top10
// fills the case), so gains are measured over all of them.
int [item] dailyGrindHoldings() {
	int [item] held;
	foreach it, amount in get_inventory() held[it] += amount;
	foreach it, amount in get_closet() held[it] += amount;
	foreach it, amount in get_display() held[it] += amount;
	return held;
}

void dailyGrindBegin() {
	dailyGrindMigrateHistory();
	gGrindTurnMark = total_turns_played();
	gGrindMeatMark = my_meat();
	gGrindInventoryMark = dailyGrindHoldings();
}

// What one gained copy is worth for the log: what it really sells for. The
// stored mall price is the lowest listing, and for an item nobody buys that
// is an ask, not a price: on 2026-11-24 it valued 154 Oasis turns at 37.6M
// (about 75 mojo filters and 369,000 Meat), which kept the turn-value test
// from ever skipping a grind. So the average sale price (Pricegun) is used,
// never above the lowest listing, and an item with no recent sales counts at
// its autosell price.
int dailyGrindItemValueFrom(boolean tradeable, int listed, float average, int autosell) {
	if (!tradeable) return autosell;
	if (average <= 0) return autosell;
	int sells = floor(average);
	return listed > 0 ? min(listed, sells) : sells;
}

int dailyGrindItemValue(item it) {
	if (!it.tradeable) return autosell_price(it);
	return dailyGrindItemValueFrom(true, historical_price(it), smmSpendAveragePrice(it), autosell_price(it));
}


void dailyGrindEnd(string name) {
	int turns = total_turns_played() - gGrindTurnMark;
	int meat = my_meat() - gGrindMeatMark;
	int itemValue = 0;
	boolean museumGain = false;
	string museumIds = "";
	// Only gains count: copies used up or sold along the way are not losses here.
	foreach it, amount in dailyGrindHoldings() {
		int gained = amount - gGrindInventoryMark[it];
		if (gained <= 0) continue;
		itemValue += gained * dailyGrindItemValue(it);
		if (!it.tradeable && is_displayable(it)) {
			SmmMuseumGoal goal = smmMuseumGoal(it);
			if (goal.known && smmMuseumMissing(it, goal) > 0) {
				museumGain = true;
				museumIds += (museumIds == "" ? "" : ",") + it.to_int();
			}
		}
	}
	if (turns <= 0 && meat == 0 && itemValue == 0) return;

	set_property("_smm.grind.turns." + name, get_property("_smm.grind.turns." + name).to_int() + turns);
	set_property("_smm.grind.meat." + name, get_property("_smm.grind.meat." + name).to_int() + meat);
	set_property("_smm.grind.items." + name, get_property("_smm.grind.items." + name).to_int() + itemValue);
	set_property(kGrindTurnsTotalKey, get_property(kGrindTurnsTotalKey).to_int() + turns);

	// history across days: about the last 14 logged days, older days fading out
	int histTurns = get_property("smm.grind.histTurns." + name).to_int();
	int histValue = get_property("smm.grind.histValue." + name).to_int();
	int histRuns = get_property("smm.grind.histRuns." + name).to_int();
	if (!get_property("_smm.grind.counted." + name).to_boolean()) {
		if (histRuns >= 14) {
			histTurns = histTurns * 13 / 14;
			histValue = histValue * 13 / 14;
		}
		histRuns += 1;
		set_property("smm.grind.histRuns." + name, histRuns);
		set_property("_smm.grind.counted." + name, "true");
	}
	set_property("smm.grind.histTurns." + name, histTurns + turns);
	set_property("smm.grind.histValue." + name, histValue + meat + itemValue);
	if (museumGain) {
		set_property("smm.grind.histMuseumAt." + name, histRuns);
		set_property("smm.grind.histMuseumItems." + name, museumIds);
	}

	print("dailyGrind: " + name + " took " + turns + " turns, Meat " + (meat >= 0 ? "+" : "") + meat + ", items worth " + itemValue
		+ (museumGain ? ", including an untradeable item the Museum needs" : ""), "blue");
}

void printDailyGrindLedger() {
	print("dailyGrind paid-turn ledger (turn value " + kTurnValue + "):", "blue");
	foreach name in kDailyGrindNames {
		int turns = get_property("_smm.grind.turns." + name).to_int();
		int perTurn = dailyGrindReturnPerTurn(name);
		if (turns <= 0 && perTurn < 0) continue;
		int meat = get_property("_smm.grind.meat." + name).to_int();
		int items = get_property("_smm.grind.items." + name).to_int();
		print(name + ": today " + turns + " turns, Meat " + meat + ", items " + items
			+ (turns > 0 ? " (" + ((meat + items) / turns) + " per turn)" : "")
			+ "; over " + get_property("smm.grind.histRuns." + name).to_int() + " logged days " + perTurn + " per turn"
			+ (dailyGrindMuseumRecent(name) ? ", Museum item gained recently" : ""));
	}
	print("total paid turns: " + get_property(kGrindTurnsTotalKey).to_int());
}



// -------------------------------------
// AUTOMATION -- DAILY
// -------------------------------------

void useNashCrosbyStill() {
	print("useNashCrosbyStill", "green");
	item[int] distilledLiquour;
	for i from 0 to 11 {
			distilledLiquour[i] = to_item(i + 1551);
		}
	distilledLiquour[12] = $item[bottle of Pete's Sake];
	distilledLiquour[13] = $item[bottle of Ooze-O];

	sort distilledLiquour by available_amount(value);
	int i = 0;
	while (stills_available() > 0) {
		museumSafeCreate(min(stills_available(), creatable_amount(distilledLiquour[i])), distilledLiquour[i]);
		i++;
	}
}



string maxStringForSausageGoblin() {
	return "exp, 0.1 meat";
}



void dressupForBackupCamera(location aLocation, int copiesToMake) {
	monster cameraMonster = last_monster();

	// DRESS UP
	string familiarSelector = (copiesToMake >= 2 && pocketProfessorLecturesAvailable() > 0) ? "Pocket Professor" : "default";
	string selector = "item";
	string maxString = "equip backup camera, pickpocket chance, 5 familiar weight";

	if (cameraMonster == $monster[sausage goblin]) {
		maxString = maxStringAppend(maxString + ", -equip mafia thumb ring, -equip \"i voted!\" sticker, -equip June cleaver", maxStringForSausageGoblin()); //  should we -equip Kramco Sausage-o-Matic&trade; ???
	}

	// initial maximize so we know where our familiar's final level will be
	automate_dressup(aLocation, selector, familiarSelector, maxString);

	// buff up if we need it
	if (copiesToMake >= 2 && copiesToMake - 1 >= pocketProfessorLecturesAvailable()) {
		cli_execute_if_needed("beach head Do I Know You From Somewhere?", $effect[Do I Know You From Somewhere?]);
	}

	// don't use the pocket professor if we have no charges left
	if (copiesToMake == 1 || pocketProfessorLecturesAvailable() == 0) {
		familiarSelector = "default";
	}

	automate_dressup(aLocation, selector, familiarSelector, maxString); // item and pp chance in case we are backing up to something that might drop something
}


// handles the chained combat if we decide to use the pocket professor's relativity
// assumes we're in combat with the right monster, i.e. the one we want to fight and potentially copy
// returns the number of times we fought
int grindBackupCameraFightHelper(int times, monster cameraMonster, string aPage) {
	assert(inCombat(), "grindBackupCameraFightHelper: we're not in combat");
	int copiesToMake = times;
	string scriptString;
	boolean goingToMultifight = copiesToMake >= 1 && my_familiar() == $familiar[Pocket Professor] && pocketProfessorLecturesAvailable() > 0 && my_hp() >= my_maxhp() / 4;

	if (goingToMultifight) {
		scriptString = "skill lecture on relativity;";
	}
	if (!"_circadianRhythmsRecalled".get_property().to_boolean())
		scriptString += "skill Recall Facts: " + cameraMonster.phylum + " Circadian Rhythms;";

	aPage = customScriptWithDefaultKill(current_round(), cameraMonster, aPage, scriptString);
	assert(!macroAborted(aPage), "grindBackupCameraFightHelper: macro aborted");
	assert("_circadianRhythmsRecalled".get_property().to_boolean(), "grindBackupCameraFightHelper: we didn't Recall Facts");
	copiesToMake--;

	boolean conditionsSatisfied = postAdventure();
	if (conditionsSatisfied) {
		print("conditions satisfied, exiting chained fight", "orange");
		return times - copiesToMake;
	}

	if (goingToMultifight) {
		visit_url("/main.php", false, false); // get to the new fight
		assert(current_round() == 1, "We didn't get to a new Pocket Professor fight! current round = " + current_round());
		return grindBackupCameraFightHelper(copiesToMake - 1, cameraMonster, aPage);
	}

	assert(!inCombat() || current_round() == 1, "grindBackupCameraFightHelper: we should be done combat or be at the start of a new one");
	return times - copiesToMake;
}

// backs up to the last monster, adventuring at aLocation
// will kill the target "times" times, which may not exactly correspond to number of backups used
// as other copiers might be used
// if aLocation == none, will use redirectionDelayLocation() to determine the location to grind
// if stopMonster != none, will stop automation and return if we meet stopMonster
// returns the number of backups actually done
int grindBackupCamera(location aLocation, int times, monster stopMonster) {
	assert(equipped_amount($item[backup camera]) >= 1, "grindBackupCamera: no backup camera equipped");
    assert(backupCameraUsesAvailable() > 0, "grindBackupCamerasWithDressup: no backup cameras available");

	boolean hadGoals = haveGoals();
	location advLocation = aLocation;
	monster cameraMonster = last_monster();
	int copiesToMake = min(times, backupCameraUsesAvailable() + pocketProfessorLecturesAvailable());
	int kStartingCopies = copiesToMake;
	print("grindBackupCamera: " + cameraMonster + " at "
	      + (aLocation == $location[none] ? " delay locations " : aLocation.to_string()) + " -- " + copiesToMake + " times (wanted " + times + ")", "green");

	// GRIND
	try {
		saveAndSetProperty(kCheckForLastSausageGoblinKey, "false");

		while ((!hadGoals || haveGoals()) && copiesToMake > 0 && last_monster() == cameraMonster && backupCameraUsesAvailable() > 0) {
			boolean conditionsSatisfied;
			string aPage;

			if (aLocation == $location[none])
				advLocation = redirectionDelayLocation();

			if (!inCombat()) {
				healAndRemoveDebuffsWithMPRestore();
				aPage = advURL(advLocation); // never want to redirect or the monster would change!
			}

			if (isErrorPage(aPage)) {
				print("got an error page:\n" + aPage, "red");
				abort("grindBackupCamera: didn't get to the adventure location: " + advLocation);
			}

			if (handling_choice()) {
				run_choice(-1);

			// no action adventure
			} else if (!contains_text(aPage, "fight.php")) {
				if (postAdventure())
					break; // goals found

			// stop monster
			} else if (last_monster() == stopMonster) {
				abort("grindBackupCamera: stop monster found: " + stopMonster);

			// we're fighting...
			// the right monster
			} else if (last_monster() == cameraMonster) {
				copiesToMake -= grindBackupCameraFightHelper(copiesToMake, cameraMonster, aPage);

			// a different monster: backup to the target
			} else {
				string script = "pickpocket;pickpocket;if !monstername \"" + cameraMonster + "\";skill back-up to your last enemy;endif;";
				aPage = executeScript(script);
				visit_url("/fight.php", true, false); // get to the new fight
				copiesToMake -= grindBackupCameraFightHelper(copiesToMake, cameraMonster, aPage);
			}

			assert(!postAdventure(), "grindBackupCamera: goals completed!");

			if ((my_familiar() == $familiar[Pocket Professor]) && (copiesToMake >= 1 || pocketProfessorLecturesAvailable() == 0) && !in_multi_fight())
				break; // return with only partial done if we can't use the pocket professor any more??
		}
	} finally {
		restoreSavedProperty(kCheckForLastSausageGoblinKey);
	}

	if (kStartingCopies - copiesToMake > 0)
		print("WARNING: still have copies to make -- did we switch monsters?? original target: " + cameraMonster + ", we're now targetting: " + last_monster(), "red");
	return kStartingCopies - copiesToMake;
}

// dresses appropriately and then calls grindBackupCamera
void grindBackupCameraWithDressup(location aLocation, int times, monster stopMonster) {
	int copiesToMakeAvailable = min(times, backupCameraUsesAvailable() + pocketProfessorLecturesAvailable());
	monster cameraMonster = last_monster();

	boolean hadGoals = haveGoals();
	while (copiesToMakeAvailable > 0 && last_monster() == cameraMonster && (!hadGoals || haveGoals())) {
		dressupForBackupCamera(aLocation, times);
		setDefaultMoodForLocation(aLocation);

		grindBackupCamera(aLocation, times, stopMonster);

		times--;
		copiesToMakeAvailable = min(times, backupCameraUsesAvailable() + pocketProfessorLecturesAvailable());
	}
}

void grindNextBackupCameraWithDressup() {
	int copiesToMake = backupCameraUsesAvailable() + pocketProfessorLecturesAvailable(); // the max possible copies we can make
	monster stopMonster;
	boolean unknownCopiesToMake = true;

    setDefaultKoLState();
	location advLocation = redirectionDelayLocation();

	if (advLocation == $location[The Smut Orc Logging Camp])
		stopMonster = $monster[smut orc pervert];

	else if (advLocation == "guzzlrQuestLocation".get_property().to_location()) {
		copiesToMake = min(copiesToMake, max(1, guzzlrQuestTurns(true) - 1));
        cli_execute("goal clear; goal add Guzzlrbuck;"); // TODO this shouldn't be necessary as we know the number of turns
		unknownCopiesToMake = false;

	} else if (!"_sotParcelReturned".get_property().to_boolean() && advLocation == sotsQuestLocation()) {
        copiesToMake = min(copiesToMake, 10 - 1); // 10 turns to complete the sot's quest but we don't know how many turns we've already done
        cli_execute("goal clear; goal add The Sot's Parcel;");
        unknownCopiesToMake = false;

    } else if (advLocation == $location[The Unquiet Garves] && questStage("questG04Nemesis") == 0) {
        copiesToMake = max(1, min(copiesToMake, 5 - $location[The Unquiet Garves].turns_spent)); // 10 turns to complete the sot's quest but we don't know how many turns we've already done
        stopMonster = ("The Unknown " + my_class()).to_monster();
        unknownCopiesToMake = false;
    }

	print("grindNextBackupCameraWithDressup: " + advLocation + " make " + copiesToMake + " copies", "green");
	if (unknownCopiesToMake) {
		print("warning: unknown location, might overshoot!", "red");
		wait(6);
	}

	grindBackupCameraWithDressup(advLocation, copiesToMake, stopMonster);
}

// expends all backup camera uses
void grindBackupCamerasWithDressup() {
    while (backupCameraUsesAvailable() > 0) {
        grindNextBackupCameraWithDressup();
    }
}


// backup at the current location
void delayBackupCameraWithDressup(int times, monster stopMonster) {
	grindBackupCameraWithDressup(my_location(), times, stopMonster);
}



float synthGreedValueOfSpleen(int baseMeatDrop) {
	float kSweetSynthGreedMultiplier = 3.0;
	int costOfSweetSynth = 2000;
	int sweetSynthTurns = 30;
	return (baseMeatDrop * kSweetSynthGreedMultiplier * sweetSynthTurns) - costOfSweetSynth;
}

void spleenBreakpoints(monster testMonster) {
	print("spleen is worth " + kTurnsPerSpleen + " advs and an adv is worth " + kTurnValue + " meat, therefore a spleen is worth " + kSpleenValue + " meat if used for turngen");

	int baseMeatDrop = monsterBaseMeatDropValue(testMonster);
	int currentMeatDrop = monsterCurrentMeatDropValue(testMonster);
	float greedValue = monsterMeatDropValue(testMonster, meat_drop_modifier() + 300) - currentMeatDrop;
	print("when used to target " + testMonster + ", with " + baseMeatDrop + " base and " + currentMeatDrop + " current meat drop, Synth: Greed will give " + greedValue + " extra meat per turn, " + greedValue * 30 + " meat over 30 turns");

	print("");

	int baseItemDrop = monsterBaseItemMeatValue(testMonster, false);
	int currentItemDrop = monsterCurrentItemMeatValue(testMonster, false);
	float collectValue = monsterItemMeatValue(testMonster, false, item_drop_modifier() + 150) - monsterCurrentItemMeatValue(testMonster, false);
	print("when used to target " + testMonster + ", with items worth " + baseItemDrop + " base and " + currentItemDrop + " current, Synth: Collection will give " + collectValue + " extra meat per turn, " + collectValue * 30 + " meat over 30 turns");
}



void getDocGalaktikQuest() {
	if (!is_on_quest("What's Up, Doc?")) {
		visit_url("/shop.php?whichshop=doc&action=talk", false, false);
		run_choice(1);
	}
    assert(!handling_choice(), "getDocGalaktikQuest: still handling a choice somehow");
}

void getMeatsmithQuest() {
	if (!is_on_quest("Helping Make Ends Meat")) {
		visit_url("/shop.php?whichshop=meatsmith&action=talk", false, false);
		run_choice(1);
	}
    assert(!handling_choice(), "getMeatsmithQuest: still handling a choice somehow");
}

void getArmoryQuest() {
    if (questStage("questM25Armorer") < 0) {
//	if (!is_on_quest("Lending a Hand (and a Foot)")) {
		visit_url("/shop.php?whichshop=armory&action=talk", false, false);
		run_choice(1);
	}
    assert(!handling_choice(), "getArmoryQuest: still handling a choice somehow");
}

void getOldLandfillQuest() {
	if (!is_on_quest("Give a Hippy a Boat...")) {
		visit_url("/place.php?whichplace=woods&action=woods_smokesignals", false, false);
		run_choice(1);
		run_choice(2);
	}
    assert(!handling_choice(), "getOldLandfillQuest: still handling a choice somehow");
}



// buffs item drop as much as we can while spending less than maxMeatCostPerTurn
// returns the actual amount of meat used per turn
int itemDropBuff(int buffTurnsNeeded, int maxMeatCostPerTurn) {
	boolean unused;

	AnalyzeRecord [item] itemDropBuffs = { // buff amt, is % based?, duration, opportunity cost, effectactivationString // CLI string where %d is number of activations, e.g. "synthesize %d Synthesis: Cold". default activations are handled automatically (use, chew, eat, drink)
		$item[spider web]: new AnalyzeRecord(150, false, 30, kSpleenValue + current_price($item[ribbon candy]) + current_price($item[ribbon candy]) - current_price($item[spider web]), $effect[Synthesis: Collection], "synthesize %d Synthesis: Collection"),
		$item[Battery (car)]: new AnalyzeRecord(100, false, 30, 0, $effect[Car-Charged]),
		$item[abstraction: certainty]: new AnalyzeRecord(100, false, 50, kSpleenValue, $effect[Certainty]),
		$item[bottle of Lambada Lambic]: new AnalyzeRecord(100, false, 20, ((19+3) - (gkDrinkAdvGains * 3)) * kTurnValue, $effect[Dancin' Drunk]),
		$item[frost flower]: new AnalyzeRecord(100, false, 50, 0, $effect[Frosty]),
		$item[Battery (lantern)]: new AnalyzeRecord(100, false, 30, 0, $effect[Lantern-Charged]),
		$item[cyclops eyedrops]: new AnalyzeRecord(100, false, 10, 0, $effect[One Very Clear Eye]),
		$item[sorority brain]: new AnalyzeRecord(75, false, 20, 0, $effect[Let's Go Shopping!]),
		$item[glimmering raven feather]: new AnalyzeRecord(60, false, 20, kSpleenValue, $effect[Melancholy Burden]),
		$item[Daily Affirmation: Always be Collecting]: new AnalyzeRecord(50, false, 100, 0, $effect[Always be Collecting]),
		$item[hi-octane carrot juice]: new AnalyzeRecord(50, false, 30, 0, $effect[Beta Carotene Overdose]),
		$item[none]: new AnalyzeRecord(50, false, 30, costOfAsdonMartinBuff(), $effect[Driving Observantly], "multi_asdonmartin (observantly, %d)"),
		$item[twice-haunted screwdriver]: new AnalyzeRecord(50, false, 40, ((11+2) - (gkDrinkAdvGains * 2)) * kTurnValue, $effect[Haunted Liver]),
		$item[Sacramento wine]: new AnalyzeRecord(50, false, 50, ((5.5+1) - (gkDrinkAdvGains * 1)) * kTurnValue, $effect[Sacr&eacute; Mental]),
		$item[moreltini]: new AnalyzeRecord(50, false, 40, ((4+1) - (gkDrinkAdvGains * 1)) * kTurnValue, $effect[Truffle Tango]),
		$item[Highest Bitter]: new AnalyzeRecord(40, false, 60, ((13.5+3) - (gkDrinkAdvGains * 3)) * kTurnValue, $effect[ Mercenary]),
// 		$item[]: new AnalyzeRecord(10, false, 2, 0, $effect[]),
// 		$item[]: new AnalyzeRecord(10, false, 2, 0, $effect[]),
	};

	// FAMILIAR WEIGHT BUFFS
//	AnalyzeRecord [item] itemsToAnalyze = famWeightItemsToAnalyze();
	AnalyzeRecord [item] itemsToAnalyze = itemDropBuffs;
	item [int] sortArray;
	int ctr = 0;
	foreach it in itemsToAnalyze {
		sortArray[ctr] = it;
		ctr += 1;
	}
	sort sortArray by costPerBuffTurn(value, itemsToAnalyze[value].duration, buffTurnsNeeded, itemsToAnalyze[value].opportunityCost);

	// CHOOSE BUFFS TO USE
	int totalBuffs;
	int totalCostPerTurn;
	foreach idx, anItem in sortArray {
		int costPerBuffTurn = costPerBuffTurn(anItem, itemsToAnalyze[anItem].duration, buffTurnsNeeded, itemsToAnalyze[anItem].opportunityCost);
		int useAmount = ceil(buffTurnsNeeded / itemsToAnalyze[anItem].duration);
		string colour = "blue";

		if ((totalCostPerTurn + costPerBuffTurn) <= maxMeatCostPerTurn && haveRoom(anItem)) {
			colour = "green";
			totalBuffs += itemsToAnalyze[anItem].buffAmount;
			totalCostPerTurn += costPerBuffTurn;
		}

		print(anItem + "@" + costPerBuffTurn + "/buff turn", colour);
	}

	if (totalBuffs == 0) {
		print("WARNING: no buffs were chosen, try raising maxMeatCostPerTurn", "red");
		totalBuffs = 1; // just to avoid a div by zero
	} else
		print("total cost per turn: " + totalCostPerTurn + ", total buff: " + totalBuffs + "%, total cost per turn per buff percent: " + (totalCostPerTurn / totalBuffs));
	print("Total Item drop bonus: " + item_drop_modifier() + "%, Total Meat drop bonus: " + meat_drop_modifier() + "%", "blue");

	// BUFF UP
// 	if (!user_confirm("Proceed under the following circumstances?\ntotal buff cost: " + totalCost + ", total buff: " + totalBuffs + "%, total cost per buff percent: " + (totalCost / totalBuffs) + " meat\nturn cost: " + (kTurnValue * 30) + " -- TOTAL COST: " + (totalCost + (kTurnValue * 30)) + "\nVS gain from winning: " + mall_price($item[my life of crime, a memoir]), 60000, false))
// 		abort();
//
// 	// ONE-OFF BUFFS
// 	if (maxMeatCostPerTurn > 0) {
// 		unused = cli_execute_if_needed("beach head Do I Know You From Somewhere?", $effect[Do I Know You From Somewhere?], buffTurnsNeeded);
// 		unused = cli_execute_if_needed("pool aggressive", $effect[Billiards Belligerence], buffTurnsNeeded);
// 		unused = cli_execute_if_needed("fortune buff familiar", $effect[A Girl named Sue], buffTurnsNeeded);
// 		if (!to_boolean(get_property("_madTeaParty")))
// 			unused = cli_execute_if_needed("hatter 24", $effect[You Can Really Taste the Dormouse], buffTurnsNeeded);
// 	}
//
// 	// ACQUIRE AND CONSUME ITEMS
// 	foreach idx, anItem in sortArray {
// 		int costPerBuffPercent = costPerBuffPercent(anItem, itemsToAnalyze[anItem].buffAmount, itemsToAnalyze[anItem].duration, itemsToAnalyze[anItem].opportunityCost);
// 		if (costPerBuffPercent <= maxMeatCostPerBuffPercent && haveRoom(anItem)) {
// 			int amt = ceil(buffTurnsNeeded.to_float() / itemsToAnalyze[anItem].duration);
// 			if (fullAcquire(anItem, amt) < amt) {
// 				abort("could not acquire consumable: " + anItem);
// 			}
// 			consumeIfNeededWithUneffect(anItem, itemsToAnalyze[anItem].theEffect, buffTurnsNeeded);
// 		}
// 	}
// 	print("Total Item drop bonus: " + item_drop_modifier() + "%, Total Meat drop bonus: " + meat_drop_modifier() + "%", "blue");

	return totalCostPerTurn;
}



// given a location and targets, maximizes +item and buffs for +item and grinds numberToGet of targets
void grindMeatWithItemDrop(location targetLoc, monster [] monsterArray, int numberToGet, int maxPerTurnCost, string outfitTweak) {
	int kBuffTurns = ceil(numberToGet * 1);
	int perAdventureCost = perAdventureCost(targetLoc);
	monster targetMonster;
	if (count(monsterArray) > 0)
		targetMonster = monsterArray[0];

	print("grindMeatWithItemDrop: " + numberToGet + "X " + targetLoc + " targetting: " + targetMonster + ", maxPerTurnCost: " + maxPerTurnCost, "green");

	// buffs
	setCurrentMood("meat");
	setBoombox("meat");
	boolean useSweetSynthesis = spleen_limit() - my_spleen_use() >= kBuffTurns / 15;
	buffForItemDrop(kBuffTurns, targetLoc, useSweetSynthesis); // use sweet synthesis if we have the spleen
	int availableSpleen = spleen_limit() - my_spleen_use();
	if (useSweetSynthesis && (availableSpleen > ceil(kBuffTurns / 30.0)))
		sweetSynthesis($effect[Synthesis: Greed], kBuffTurns);

	// dress up
	int chargesAvailable = to_int(get_property("garbageChampagneCharge"));
	if (chargesAvailable == 0 && !to_boolean(get_property("_garbageItemChanged"))) {
		cli_execute("tote 2");
		chargesAvailable = to_int(get_property("garbageChampagneCharge"));
	}
	string champagneString = chargesAvailable > 0 ? ", equip broken champagne bottle" : "";
	string sabreString = (to_int(get_property("_saberForceUses")) < 5 && champagneString == "") ? ", equip Fourth of May Cosplay Saber" : "";

	automate_dressup(targetLoc, "item", "item", maxStringAppend(outfitTweak, "0.25 meat, -equip aerogel attache case, -equip fishin' hat, -equip government-issued slacks, -equip pantogram pants" + champagneString + sabreString));

	healAndRemoveDebuffsWithMPRestore();

	int misses = 3;
	while (numberToGet > 0 && misses > 0) {
		string textColour = "green";
		skill skillToUse = $skill[none];

		if (targetMonster != $monster[none]) {
			int targetValue = monsterCurrentTotalMeatValue(targetMonster, false) - perAdventureCost;
			if (get_property("olfactedMonster").to_monster() != targetMonster)
				skillToUse = $skill[Transcendent Olfaction];
			else if (canYellowRay() && (item_drop_modifier() < 600 || meat_drop_modifier() < 800) && equipped_amount($item[broken champagne bottle]) == 0) {
				prepForYellowRay();
				skillToUse = chooseYellowRaySkill().theSkill; // not in combat
			}

			if (targetMob(targetLoc, monsterArray, skillToUse, 1, true, maxPerTurnCost))
				numberToGet--;
			else
				misses--;

			targetValue = monsterCurrentTotalMeatValue(targetMonster, false) - perAdventureCost;
			if (targetValue < kTurnValue)
				textColour = "red";
			print("target value: " + targetValue + ", including per adv cost of " + perAdventureCost, textColour);
		} else {
			if (redirectAdventure(targetLoc, 1))
				numberToGet--;

			int lastMonsterValue = monsterCurrentTotalMeatValue(last_monster(), false) - perAdventureCost;
			if (lastMonsterValue < kTurnValue)
				textColour = "red";
			print("last monster value: " + lastMonsterValue + ", including per adv cost of " + perAdventureCost, textColour);
		}

	}

	if (misses == 0)
		print("exiting as a result of too many misses!", "red");
}



record MaximizerRecord {
	string display; //What would be shown in the Modifier Maximizer tab
	string command; //The CLI command the Maximizer would execute
	float score;    //The score added from equipping the item or gaining 1 turn of the effect
	effect anEffect;  //The effect you would gain
	item anItem;      //The item being used or equipped
	skill aSkill;    //The skill you need to cast
};


void grindGlitchSeasonReward() {
	print("grindGlitchSeasonReward", "green");

	automate_dressup($location[none], "exp", "default", "-equip Everfull Dart Holster");

	advURL("/inv_eat.php?pwd&which=3&whichitem=10207", true, false);
	assert(inCombat(), "grindGlitchSeasonReward: didn't get into combat!");
	run_combat(); postAdventure();
	// 	assert(get_property("_glitchMonsterFights").to_boolean(), "did not flight the glitch monster");
}



void dressupForDrip(location dripLoc, string dressupTweak, int turnsToGrind) {
	if (item_amount($item[drippy stake]) > 1) put_closet(item_amount($item[drippy stake]) - 1, $item[drippy stake]);

	string maxString = "0.2 mus, +equip drippy stake, +equip drippy khakis, +equip Drip harness, +equip lustrous drippy orb, -equip Everfull Dart Holster, -equip \"i voted!\" sticker";
	maxString = maxStringAppend(maxString, fixupCLArtifacts(dressupTweak));
	if (!wantsToEquip(maxString, $slot[off-hand]) && !wantsToNotEquip(maxString, $item[drippy truncheon]) && countHandsUsed(maxString) < 2)
		maxString = maxStringAppend(maxString, "equip drippy truncheon");
	if (!wantsToEquip(maxString, $slot[off-hand]) && !wantsToNotEquip(maxString, $item[drippy shield]) && countHandsUsed(maxString) < 2)
		maxString = maxStringAppend(maxString, "equip drippy shield");
	if (can_equip($item[sea salt scrubs]))
		maxString += ", +equip sea salt scrubs";
	automate_dressup(dripLoc, "item", "item", maxString);

	use_if_needed($item[handful of hand chalk], $effect[Chalky Hand], turnsToGrind);
	if (my_buffedstat($stat[muscle]) < 200)
		use_if_needed($item[Ferrigno's Elixir of Power], $effect[Incredibly Hulking], turnsToGrind);
	if (my_buffedstat($stat[muscle]) < 200)
		abort("not enough muscle!");
}

// The drippy nugget and glass of drippy wine are where the Drip's turns
// (drippyJuice) come from. Each takes 5 organ space, so they go in before the
// day's diet fills the organs: on 2026-11-24 the diet ran first and the Drip
// got no turns at all.
boolean dripConsumePending() {
	return (!to_boolean(get_property("_drippyNuggetUsed")) && available_amount($item[drippy nugget]) > 0)
		|| (!to_boolean(get_property("_drippyWineUsed")) && available_amount($item[glass of drippy wine]) > 0);
}

void dripConsume() {
	if (!to_boolean(get_property("_drippyNuggetUsed")) && my_fullness() <= fullness_limit() - 5) {
		useMoMifNeeded();
		museumSafeEat(1, $item[drippy nugget]);
	}
	if (!to_boolean(get_property("_drippyWineUsed")) && my_inebriety() <= inebriety_limit() - 5) {
		useOdeToBoozeIfNeeded(5);
		museumSafeDrink(1, $item[glass of drippy wine]);
	}
}

void grindDrip(location dripLoc, string dressupTweak) {
	print("grindDrip at " + dripLoc + " with dressupTweak: " + dressupTweak, "green");

	setDefaultState();
	change_mcd(0);

	dripConsume();
	int turnsToGrind = to_int(get_property("drippyJuice"));

	if (turnsToGrind > 0) {
		dressupForDrip(dripLoc, dressupTweak, turnsToGrind);
		while (turnsToGrind > 0 && my_adventures() > 0) {
			healAndRemoveDebuffsWithMPRestore();
			if (!adventure(1, dripLoc))
				abort("grindDrip: failed adventuring at " + dripLoc);
			turnsToGrind = to_int(get_property("drippyJuice"));
		}
	}

}

void grindDrip() {
	if (have_item($item[maple magnet])) {
		try {
			saveAndSetProperty("choiceAdventure1406", "4"); // drippy plum(?)
			fullAcquire($item[drippy truncheon]); // for a drippy stake
			grindDrip($location[the dripping trees], "equip maple magnet");
		} finally {
			restoreSavedProperty("choiceAdventure1406");
		}
	} else {
		try {
			saveAndSetProperty("choiceAdventure1411", "3"); // door 3: drippy grub
			saveAndSetProperty("choiceAdventure1415", "1"); // buy drippy candy bar
			grindDrip($location[the dripping hall], "");
		} finally {
			restoreSavedProperty("choiceAdventure1411");
			restoreSavedProperty("choiceAdventure1415");
		}
	}
}



// fight the tentacle from the skill -- ASSUMES WE ARE DOING Neverending Party NEXT!!!!!!!!!!!!!!!!
void grindEldritchHorror(boolean useSweetSynthesis) {
	print("grindEldritchHorror", "green");
	if (to_boolean(get_property("_eldritchHorrorEvoked")))
		return;

	if (isAsdonWorkshed() && !drivingAsdonMartin())
		fueled_asdonmartin("observantly", 1);
	if (useSweetSynthesis && my_spleen_use() < spleen_limit())
		sweetSynthesis($effect[Synthesis: Collection], 1);

	burnMP();
	string maxString = "spell dmg, -equip Kramco Sausage-o-Matic&trade;, -equip \"i voted!\" sticker, -equip Everfull Dart Holster, -equip mafia thumb ring";
	if (my_primestat() != $stat[moxie] && my_basestat($stat[moxie]) >= 200)
		maxString = maxString + ", +equip mime army infiltration glove, +equip meteorb";
	else if (my_primestat() != $stat[moxie])
		maxString = maxString + ", +equip Tiny black hole";
	else
		maxString = maxString + ", +equip meteorb";

	restore_mp(100);

	dressup($location[none], "spell damage percent", "magic dragonfish", maxString + ", equip Jurassic Parka");
	setParkaMode("spikolodon"); // dressup is changing the parka mode
	set_property(kSpikolodonNextCombatKey, "true");
	healAndRemoveDebuffsWithMPRestore();
	use_if_needed($item[crappy waiter disguise], $effect[Crappily Disguised as a Waiter], 1);
	use_skill($skill[Evoke Eldritch Horror]);

	if (have_effect($effect[Crappily Disguised as a Waiter]) > 0) {
		string savedProperty = get_property("choiceAdventure855");
		set_property("choiceAdventure855", "4");
		adv1($location[The Copperhead Club], 0);
		set_property("choiceAdventure855", savedProperty);
	}
}

void grindEldritchHorror() {
	grindEldritchHorror(false);
}



// fight the tentacle at the science tent
void grindEldritchTentacle(boolean useSweetSynthesis) {
	print("grindEldritchTentacle", "green");
	if (to_boolean(get_property("_eldritchTentacleFought")))
		return;

	if (isAsdonWorkshed() && !drivingAsdonMartin())
		fueled_asdonmartin("observantly", 1);
	if (useSweetSynthesis && my_spleen_use() < spleen_limit())
		sweetSynthesis($effect[Synthesis: Collection], 1);

	burnMP();
	string maxString = "spell dmg, -equip Kramco Sausage-o-Matic&trade;, -equip \"i voted!\" sticker, -equip Everfull Dart Holster, -equip mafia thumb ring";
	if (my_primestat() != $stat[moxie] && my_basestat($stat[moxie]) >= 200)
		maxString = maxString + ", equip mime army infiltration glove, equip meteorb";
	else if (my_primestat() != $stat[moxie])
		maxString = maxString + ", +equip Tiny black hole";
	else
		maxString = maxString + ", +equip meteorb";

	restore_mp(100);

	dressup($location[none], "spell damage percent", "magic dragonfish", maxString);
	healAndRemoveDebuffsWithMPRestore();
	buffer page = visit_url("/place.php?whichplace=forestvillage&action=fv_scientist", true, false);
	run_choice(1);
	healAndRemoveDebuffsWithMPRestore();
}

void grindEldritchTentacle() {
	grindEldritchTentacle(false);
}



void grindScience(boolean useSweetSynthesis) {
	grindEldritchHorror(useSweetSynthesis);
	grindEldritchTentacle(useSweetSynthesis);
}



void grindMolehillMountain() {
	print("grindMolehillMountain", "green");
	if ("_molehillMountainUsed".get_property().to_boolean())
		return;

	burnMP();
	automate_dressup($location[none], "100 exp", "default", "mainstat, -equip \"i voted!\" sticker, -equip Kramco Sausage-o-Matic&trade;, -equip \"i voted!\" sticker, -equip Everfull Dart Holster, -equip mafia thumb ring");
	healIfRequiredWithMPRestore();
	restore_mp(100);

	use($item[molehill mountain]);
}



void grindToothFairy() {
	print("grindToothFairy", "green");
	if (!canAugustSkill(22))
		return;

	burnMP();
	automate_dressup($location[none], "100 exp", "default", "mainstat, -equip Kramco Sausage-o-Matic&trade;, -equip \"i voted!\" sticker, -equip Everfull Dart Holster, -equip mafia thumb ring");
	healIfRequiredWithMPRestore();
	restore_mp(100);

	use_skill($skill[Aug. 22nd: Tooth Fairy Day!]);
}


void grindCatDay() {
	print("grindCatDay", "green");
	if (!canAugustSkill(8))
		return;

	burnMP();
	automate_dressup($location[none], "100 exp", "default", "mainstat, -equip Kramco Sausage-o-Matic&trade;, -equip \"i voted!\" sticker, -equip Everfull Dart Holster, -equip mafia thumb ring");
	healIfRequiredWithMPRestore();
	restore_mp(100);

	use_skill($skill[Aug. 8th: Cat Day!]);
}



// grind ONE quad tom fight (i.e. wormride)
// might be called from freeCombatData in smmUtils
void burnNextAprilingBandQuadTom() {
	print("burnNextAprilingBandQuadTom", "green");
    assert(have_item($item[Apriling Band quad tom]), "Apriling Band quad tom not available");
	if ("_aprilBandTomUses".get_property().to_int() >= 3)
		return;

   	burnMP();
   	automate_dressup($location[none], "item", "item", "-equip Kramco Sausage-o-Matic&trade;, -equip \"i voted!\" sticker, -equip Everfull Dart Holster, -equip mafia thumb ring");
   	healIfRequiredWithMPRestore();
   	restore_mp(100);
    cli_execute("apriling wormride");
}



void grindMushroomGarden(boolean harvest) {
	if (smmIREnabled() && !inRonin() && my_path()==$path[none]) {
		print("Garden harvesting is managed by the shared daily IoTM route.", "blue");
		return;
	}

	// Crop level persists even when a different garden is planted.
	if (!can_adventure($location[your mushroom garden])) {
		print("Skipping mushroom garden: area is not available.", "blue");
		return;
	}
	if (get_property("_mushroomGardenVisited").to_boolean()) {
		print("Skipping mushroom garden: already tended today.", "blue");
		return;
	}

	int choiceNumber = 1;
	if (harvest)
		choiceNumber = 2;

	int cropLevel = to_int(get_property("mushroomGardenCropLevel"));
	print("grindMushroomGarden, crop level: " + cropLevel, "green");

	if (cropLevel == 5 || cropLevel >= 11) {
		print("auto-picking mushroom", "blue");
		saveAndSetProperty("choiceAdventure1410", "2");
	} else {
		print(choiceNumber == 1 ? "fertilizing mushroom" : "picking mushroom", "blue");
		saveAndSetProperty("choiceAdventure1410", choiceNumber.to_string());
	}

	try {
		if (to_int(get_property("_mushroomGardenFights")) >= 1) {
			// we've done the fight but maybe not the choice
			adv1($location[your mushroom garden], 0);
			return;
		}

		automate_dressup($location[your mushroom garden], "10 exp", "default", "mainstat, -equip Kramco Sausage-o-Matic&trade;, -equip \"i voted!\" sticker, -equip Everfull Dart Holster, -equip mafia thumb ring");

		healAndRemoveDebuffsWithMPRestore();
		adventure(1, $location[your mushroom garden]); // 0 turns, so will auto-follow to the choice and auto-pick the choice
	} finally {
		restoreSavedProperty("choiceAdventure1410");
	}
}



// get the +10 level goodness
void grind_poke_familiar_items() {
	if (smmIREnabled() && !inRonin() && my_path()==$path[none]) {
		print("Garden harvesting is managed by the shared daily IoTM route.", "blue");
		return;
	}

	if (have_item($item[amulet coin]) || have_item($item[luck incense]) || have_item($item[muscle band]) || have_item($item[razor fang]) || have_item($item[shell bell]) || have_item($item[smoke ball]))
		return;

	cli_execute("garden pick");
	while (!have_item($item[amulet coin]) && !have_item($item[luck incense]) && !have_item($item[muscle band]) && !have_item($item[razor fang]) && !have_item($item[shell bell]) && !have_item($item[smoke ball])) {
		if (!museumSafeUse(1, $item[Pok&eacute;-Gro fertilizer])) break;
		cli_execute("garden pick");
	}
}



// find an existing guzzlr quest and do it, doesn't do special dressup or using items like the platinum- and gold-specific scripts below
void grindGuzzlr(string tweakOutfit) {
	assert(onGuzzlrQuest(), "grindGuzzlr: we're not on a guzzlr quest");

	// GET QUEST LOCATION AND BOOZE
	string boozeString = get_property("guzzlrQuestBooze");
	item boozeToTake;
	if (boozeString == "special personalized cocktail")
		boozeToTake = $item[buttery boy];
	else
		boozeToTake = boozeString.to_item();
	location locationToGoTo = get_property("guzzlrQuestLocation").to_location();
	assert(locationToGoTo != $location[none], "grindGuzzlr: didn't get the location to go to");
	assert(boozeToTake != $item[none], "grindGuzzlr: didn't get the booze to take");

	print("going to " + locationToGoTo + " to give a " + boozeToTake, "green");

	if (item_amount(boozeToTake) == 0)
		if (fullAcquire(boozeToTake) < 1)
			abort("don't have the booze " + boozeToTake + " and couldn't acquire it!");
	assert(item_amount(boozeToTake) > 0, "grindGuzzlr: still don't have booze:" + boozeToTake);

	// DRESSUP
	string selector = "0.1 item";
	string familiarSelector = "default";
	string maxString = fixupCLArtifacts(tweakOutfit);
	if (last_monster() == $monster[sausage goblin]) { // if the last monster is the sausage goblin, use that to get free turns at the guzzlr location
		setCurrentMood("meat");
		if (pocketProfessorLecturesAvailable() > 0)
			familiarSelector = "pocket professor";
		if (pocketProfessorLecturesPossiblyAvailable() > 0)
			selector = "familiar weight";
		maxString = maxStringAppend(maxStringForSausageGoblin() + ", equip backup camera", maxString);
	} else {
		setCurrentMood("+combat");
		maxString = maxStringAppend("0.01 mp regen, +combat 25 max", maxString);
	}

	string testString = maxStringAppend(maxString, maxStringForLocation(locationToGoTo, maxString)); // looking ahead to what automate_dressup WILL do
	// guzzlr equipment shoes = less adv, pants = more bucks, hat = more stats TODO should warn or something if we aren't equipping everything we need to properly finish the GUZZLR quest
	maxString = maxStringAppendIfPossibleToEquip(testString, $item[Guzzlr shoes]);
	maxString = maxStringAppendIfPossibleToEquip(testString, $item[Guzzlr pants]);
	maxString = maxStringAppendIfPossibleToEquip(testString, $item[Guzzlr hat]);

	automate_dressup(locationToGoTo, selector, familiarSelector, maxString);

	// DO IT
	clearGoals();
	add_item_condition(1, $item[Guzzlrbuck]);
	healAndRemoveDebuffsWithMPRestore();

	// if last monster is a sausage goblin, grind the backup camera at this location
	if (last_monster() == $monster[sausage goblin]) {
		while (haveGoals() && backupCameraUsesAvailable() > 0) {
			grindBackupCamera(locationToGoTo, 25, $monster[none]);
			selector = "0.1 item";
			familiarSelector = "default";
			automate_dressup(locationToGoTo, selector, familiarSelector, maxString);
		}

	} else if (kTargetableMonstersMap[locationToGoTo] != $monster[none]) {
		monster [] bestTarget = {kTargetableMonstersMap[locationToGoTo]};
		targetMob(locationToGoTo, bestTarget, $skill[none], 25, false, kMaxInt);
	} else {
		healAndRemoveDebuffsWithMPRestore();
		adventure(25, locationToGoTo); // do not need to redirect as all wandering monsters adv advance the goal
	}
}

void grindGuzzlr() {
	grindGuzzlr("");
}


void grindGuzzlrWithSausageGoblin() {
	if (last_monster() != $monster[sausage goblin])
		abort("sausage goblin was not the last monster!");
	grindGuzzlr("");
}


// check the platinum guzzlr quest, possibly doing it, and then do the 3 gold quests
void grindGoldGuzzlr() {
	string tweakOutfit = "";
	getGuzzlrQuest(3); // gold

	location questLocation = to_location(get_property("guzzlrQuestLocation"));

	if (questLocation == $location[Barrrney's Barrr] || questLocation == $location[The F'c'le] || questLocation == $location[The Poop Deck] || questLocation == $location[Belowdecks]) {
		if (have_item($item[pirate fledges]))
			tweakOutfit = "equip pirate fledges";
		else
			tweakOutfit = "outfit swashbuckling getup";

	} else if (questLocation == $location[8-bit Realm]) {
		tweakOutfit = "equip continuum transfunctioner";

	} else if (questLocation == $location[The Haunted Laboratory]) {
		saveAndSetProperty("choiceAdventure884", "6");

	} else if (questLocation == $location[The Haunted Nursery]) {
		saveAndSetProperty("choiceAdventure885", "6");

	} else if (questLocation == $location[The Spooky Forest]) {
		saveAndSetProperty("choiceAdventure502", "2");
		saveAndSetProperty("choiceAdventure505", "2");

	} else if (questLocation == $location[The Penultimate Fantasy Airship]) {
		saveAndSetProperty("choiceAdventure178", "2");

	} else if (questLocation == $location[The Castle in the Clouds in the Sky (Ground Floor)]) {
		saveAndSetProperty("choiceAdventure647", "3");

	} else if (questLocation == $location[The Castle in the Clouds in the Sky (Top Floor)]) {
		saveAndSetProperty("choiceAdventure677", "2");
		saveAndSetProperty("choiceAdventure678", "3");

	} else if (questLocation == $location[The Haunted Bedroom]) {
		saveAndSetProperty("choiceAdventure876", "1");
		saveAndSetProperty("choiceAdventure878", "4");
		saveAndSetProperty("choiceAdventure879", "2");
		saveAndSetProperty("choiceAdventure880", "2");

	} else if (questLocation == $location[Guano Junction]) {
		saveAndSetProperty("choiceAdventure1427", "2");
	}


	try {
		grindGuzzlr(tweakOutfit);

	} finally {
		if (questLocation == $location[The Haunted Laboratory]) {
			restoreSavedProperty("choiceAdventure884");

		} else if (questLocation == $location[The Haunted Nursery]) {
			restoreSavedProperty("choiceAdventure885");

		} else if (questLocation == $location[The Spooky Forest]) {
			restoreSavedProperty("choiceAdventure502");
			restoreSavedProperty("choiceAdventure505");

		} else if (questLocation == $location[The Penultimate Fantasy Airship]) {
			restoreSavedProperty("choiceAdventure178");

		} else if (questLocation == $location[The Castle in the Clouds in the Sky (Ground Floor)]) {
			restoreSavedProperty("choiceAdventure647");

		} else if (questLocation == $location[The Castle in the Clouds in the Sky (Top Floor)]) {
			restoreSavedProperty("choiceAdventure677");
			restoreSavedProperty("choiceAdventure678");

		} else if (questLocation == $location[The Haunted Bedroom]) {
			restoreSavedProperty("choiceAdventure876");
			restoreSavedProperty("choiceAdventure878");
			restoreSavedProperty("choiceAdventure879");
			restoreSavedProperty("choiceAdventure880");

		} else if (questLocation == $location[Guano Junction]) {
			restoreSavedProperty("choiceAdventure1427");
		}
	}
}


// check the platinum guzzlr quest, possibly doing it
void grindPlatinumGuzzlr() {
	buffer pageText;
	string tweakOutfit = "";

	if ((get_property("questGuzzlr") == "unstarted") && (to_int(get_property("_guzzlrPlatinumDeliveries")) == 0)) {
		getGuzzlrQuest(4); // platinum
	} else {
		if (get_property("guzzlrQuestTier") != "platinum") {
			print("we're in grindPlatinumGuzzlr, but a quest of a different tier is already started! returning", "red");
			return;
		}
	}

	location questLocation = to_location(get_property("guzzlrQuestLocation"));

	cli_execute("prefref guzzlr");
	if (!user_confirm("Cancel platinum location and continue?", 60000, true)) {
		abort("manual platinum location: " + questLocation);
	} else { // cancel the platinum quest and continue
		visit_url("/inventory.php?tap=guzzlr", false, false);
		assert(handling_choice() && last_choice() == 1412, "not on the guzzlr choice page");
		run_choice(1);
		run_choice(5);
		return;
	}


	// customizations DON'T DO ANY MORE, KEEP THE DAILY ITEM INSTEAD
	// 	if (questLocation == $location[Hamburglaris Shield Generator]) {
	// 		if (get_property("questF04Elves") != "finished") abort("about to adventure in spaaaace, but we haven't done the quest yet!");
	// 		use_if_needed($item[transporter transponder], $effect[Transpondent], max(1, 10 - to_int(get_property("guzzlrDeliveryProgress"))));
	//
	// 	} else if (questLocation == $location[The Red Queen's Garden]) {
	// 		use_if_needed($item[&quot;DRINK ME&quot; potion], $effect[Down the Rabbit Hole], max(1, 10 - to_int(get_property("guzzlrDeliveryProgress"))));
	//
	// 	} else { // default action: cancel the platinum quest and continue, but check with user first
	// 		cli_execute("prefref guzzlr");
	// 		if (!user_confirm("Cancel platinum location and continue?", 60000, true)) {
	// 			abort("manual platinum location: " + questLocation);
	// 		} else { // cancel the platinum quest and continue
	// 			visit_url("/inventory.php?tap=guzzlr", false, false);
	// 			run_choice(1);
	// 			return;
	// 		}
	// 	}
	//
	// 	item someBooze = $item[Buttery Boy];
	// 	if (!have_item(someBooze) && fullAcquire(someBooze) < 1)
	// 		abort("don't have a Buttery Boy and couldn't acquire it!");
	// 	print("going to " + questLocation + " to give a " + someBooze, "green");
	// 	grindGuzzlr(questLocation, someBooze, tweakOutfit);
	//
	// 	if (questLocation == $location[Hamburglaris Shield Generator]) {
	// 		print("leaving spaaaaace with " + have_effect($effect[Transpondent]) + " turns of Transpondent remaining. Cancel within 3 seconds...", "blue");
	// 		wait(3);
	// 	}
}


void grindGoldAndPlatinumGuzzlr() {
	int tries = 3 - to_int(get_property("_guzzlrGoldDeliveries")) + 2;
	while (((to_int(get_property("_guzzlrGoldDeliveries")) < 3 && get_property("questGuzzlr") == "unstarted") || get_property("guzzlrQuestTier") == "gold") && tries > 0) {
		grindGoldGuzzlr();
		tries--;
	}
	if (to_int(get_property("_guzzlrGoldDeliveries")) < 3)
		print("WARNING: " + (3 - to_int(get_property("_guzzlrGoldDeliveries"))) + " gold quest(s) remain undone", "red");

	if (get_property("guzzlrQuestTier") == "platinum" || (to_int(get_property("_guzzlrPlatinumDeliveries")) < 1 && get_property("questGuzzlr") == "unstarted")) {
		grindPlatinumGuzzlr();
	}
	if (to_int(get_property("_guzzlrPlatinumDeliveries")) < 1)
		print("WARNING: platinum quest remains undone", "red");
}



// TODO: complete this...
// CAN ONLY GRIND BEFORE BEATING THE GHOST, i.e. before completing the Spookyraven quests
void grindPoolSkill() {
	setDefaultState();
	setCurrentMood("-combat, meat");
	automate_dressup($location[The Haunted Billiards Room], "-combat", "default", "equip staff of fats");
	if (combat_rate_modifier() > -25) abort("not enough -combat");
}



// One recipe execution, priced using the full output and ingredient quantities.
record FreeCraftingChoice {
	item result;
	int quantity;
	int turns;
	float profit;
	float profitPerTurn;
    float score;
    boolean forDisplayCase;
    int collectionTarget;
    int collectionNeed;
    int salesUnits14d;
    int salesDays14d;
};

// Batch yields from the installed KoLmafia recipe data. New recipes default
// to one output; generate_yields.py refreshes explicit yield and SX3 exceptions.
int freeCraftingYield(item result) {
    int quantity = 1;
    switch (result) {
    case $item[bottle of gin]: quantity = 3; break;
    case $item[bottle of rum]: quantity = 3; break;
    case $item[bottle of sake]: quantity = 3; break;
    case $item[bottle of tequila]: quantity = 3; break;
    case $item[bottle of vodka]: quantity = 3; break;
    case $item[bottle of whiskey]: quantity = 3; break;
    case $item[boxed wine]: quantity = 3; break;
    case $item[glob of cream cheese]: quantity = 3; break;
    case $item[grubby woolball]: quantity = 3; break;
    case $item[mediocre lager]: quantity = 6; break;
    case $item[pumpkin beer]: quantity = 3; break;
    case $item[pumpkin juice]: quantity = 3; break;
    case $item[space port]: quantity = 3; break;
    case $item[stick of firewood]: quantity = 10; break;
    case $item[tropical orchid]: quantity = 6; break;
    }
    if (my_class() == $class[Sauceror]) {
        switch (result) {
        case $item[Connery's Elixir of Audacity]:
        case $item[Ferrigno's Elixir of Power]:
        case $item[Frogade]:
        case $item[Hawking's Elixir of Brilliance]:
        case $item[banana smoothie]:
        case $item[blackberry polite]:
        case $item[cologne of contempt]:
        case $item[concentrated cordial of concentration]:
        case $item[cordial of concentration]:
        case $item[cranberry cordial]:
        case $item[eyedrops of newt]:
        case $item[eyedrops of the ermine]:
        case $item[eyedrops of the ocelot]:
        case $item[libation of liveliness]:
        case $item[lotion of coldness]:
        case $item[lotion of hotness]:
        case $item[lotion of sleaziness]:
        case $item[lotion of spookiness]:
        case $item[lotion of stench]:
        case $item[milk of magnesium]:
        case $item[oil of expertise]:
        case $item[oil of oiliness]:
        case $item[oil of slipperiness]:
        case $item[oil of stability]:
        case $item[ointment of the occult]:
        case $item[papotion of papower]:
        case $item[peach lozenge]:
        case $item[pear lozenge]:
        case $item[perfume of prejudice]:
        case $item[philter of phorce]:
        case $item[plum lozenge]:
        case $item[potent potion of potency]:
        case $item[potion of potency]:
        case $item[potion of temporary gr8ness]:
        case $item[salamander slurry]:
        case $item[serum of sarcasm]:
        case $item[tomato juice of powerful power]:
            quantity *= 3;
        }
    }
    return quantity;
}

int [item] freeCraftingYields() {
    int [item] yields;
    foreach result in $items[]
        if (result.tradeable && count(get_ingredients(result)) > 0)
            yields[result] = freeCraftingYield(result);
    return yields;
}

// Cache market quotes for this run, so rescanning recipes doesn't repeat searches.
int freeCraftingPrice(item it, int [item] prices) {
	if (!(prices contains it)) prices[it] = it.tradeable ? mall_price(it) : 0;
	return prices[it];
}

// NPC prices can be lower than mall prices; keep output sale quotes separate.
int freeCraftingIngredientPrice(item ingredient, int [item] prices) {
    int market = freeCraftingPrice(ingredient, prices);
    int npc = npc_price(ingredient);
    return npc > 0 && (market <= 0 || npc < market) ? npc : market;
}

// All figures use Pricegun's default fourteen daily history buckets.
int [item] freeCraftingSalesUnits;
int [item] freeCraftingSalesDays;
void freeCraftingReadSalesVolume(item result, string response) {
    freeCraftingSalesUnits[result] = 0;
    freeCraftingSalesDays[result] = 0;
    matcher history = create_matcher("(?s)\"history\"\\s*:\\s*\\[(.*?)\\]", response);
    if (!find(history)) return;
    matcher volumes = create_matcher("\"volume\"\\s*:\\s*([0-9]+)", group(history, 1));
    while (find(volumes)) {
        int units = to_int(group(volumes, 1));
        if (units > 0) {
            freeCraftingSalesUnits[result] += units;
            freeCraftingSalesDays[result]++;
        }
    }
    freeCraftingSalesDays[result] = min(14, freeCraftingSalesDays[result]);
}


// Pricegun's value is a time-weighted completed-sale estimate. Its default
// history contains 14 days of trades; require recent evidence, not just an
// old accumulator. Missing, invalid or unavailable data is worth zero here.
float freeCraftingParseSalePrice(item result, string response) {
    matcher identity = create_matcher("\"itemId\"\\s*:\\s*([0-9]+)", response);
    if (!find(identity) || to_int(group(identity, 1)) != to_int(result)) return 0;
    matcher sales = create_matcher("\"sales\"\\s*:\\s*\\[\\s*\\{", response);
    matcher history = create_matcher("\"history\"\\s*:\\s*\\[\\s*\\{", response);
    if (!find(sales) || !find(history)) return 0;
    matcher value = create_matcher("\"value\"\\s*:\\s*\\{\\s*\"__decimal__\"\\s*:\\s*\"([0-9]+(?:\\.[0-9]+)?)\"\\s*\\}", response);
    if (!find(value)) return 0;
    return max(0.0, to_float(group(value, 1)));
}

float [item] freeCraftingSalePrices;
float freeCraftingExpectedSalePrice(item result) {
    if (!(freeCraftingSalePrices contains result)) {
        string response = visit_url("https://pricegun.loathers.net/api/" + to_int(result), false, false);
        freeCraftingSalePrices[result] = freeCraftingParseSalePrice(result, response);
        freeCraftingReadSalesVolume(result, freeCraftingSalePrices[result] > 0 ? response : "");
    }
    return freeCraftingSalePrices[result];
}

// Recipe methods are extracted from the installed Mafia data. Keeping this
// separate from creatable_turns avoids charging turns for ingredients we buy.
string [item] freeCraftingMethods;
string freeCraftingMethod(item result) {
	if (count(freeCraftingMethods) == 0)
		assert(file_to_map("smmFreeCraftingMethods.txt", freeCraftingMethods), "Could not load smmFreeCraftingMethods.txt");
	return freeCraftingMethods[result];
}

int freeCraftingRecipeTurns(item result) {
	string method = freeCraftingMethod(result);
	if (method == "SMITH" || method == "SSMITH") {
		if (method == "SMITH" && knoll_available()) return 0;
		return availableFreeCraftTurns("universal") > 0 ? 1 : 0;
	}
	// Servants make these crafts intrinsically free; they don't burn free turns.
	if (method == "COOK_FANCY" && !have_chef() && !to_boolean(get_property("autoRepairBoxServants")))
		return availableFreeCraftTurns("food") > 0 ? 1 : 0;
	if (method == "MIX_FANCY" && !have_bartender() && !have_skill($skill[Cocktail Magic]) && !to_boolean(get_property("autoRepairBoxServants")))
		return availableFreeCraftTurns("drink") > 0 ? 1 : 0;
	return 0;
}

// Stored ingredients can be moved without spending turns or crafting anything.
int freeCraftingOwned(item ingredient) {
	return item_amount(ingredient) + closet_amount(ingredient) + (can_interact() ? storage_amount(ingredient) : 0);
}

boolean acquireFreeCraftingIngredients(FreeCraftingChoice choice, int [item] prices) {
	foreach ingredient, amount in get_ingredients(choice.result) {
		int missing = max(0, amount - item_amount(ingredient));
		if (missing > 0 && closet_amount(ingredient) > 0)
			take_closet(min(missing, closet_amount(ingredient)), ingredient);
		missing = max(0, amount - item_amount(ingredient));
		if (missing > 0 && can_interact() && storage_amount(ingredient) > 0)
			take_storage(min(missing, storage_amount(ingredient)), ingredient);
		missing = max(0, amount - item_amount(ingredient));
		if (missing > 0) {
			int limit = freeCraftingIngredientPrice(ingredient, prices);
			if (limit <= 0 || buy(missing, ingredient, limit) < missing) {
				print("Could not buy " + ingredient + " at the ranked price; stopping free crafting.", "orange");
				return false;
			}
		}
		if (item_amount(ingredient) < amount) return false;
	}
	return true;
}

// Cache stock checks per quoted price. Apply the same market-depth standard
// to finished goods and every ingredient, including materials already owned.
boolean [item, int] freeCraftingStockChecks;
boolean freeCraftingWellStocked(item it, int quotedPrice) {
    if (quotedPrice <= 0) return false;
    if (!(freeCraftingStockChecks[it] contains quotedPrice))
        freeCraftingStockChecks[it, quotedPrice] = well_stocked(to_string(it), 20, floor(to_float(quotedPrice) * 1.2));
    return freeCraftingStockChecks[it, quotedPrice];
}

int freeCraftingSetting(string key, int defaultValue) {
    string value = get_property(key);
    return value.is_integer() && to_int(value) > 0 ? to_int(value) : defaultValue;
}

boolean freeCraftingRegularSales(item result) {
    return freeCraftingSalesUnits[result] >= freeCraftingSetting("smm.FreeCraftingMinSales14d", 14)
        && freeCraftingSalesDays[result] >= freeCraftingSetting("smm.FreeCraftingMinActiveDays14d", 7);
}

// A bounded liquidity weight keeps the score in meat per free turn. Reward
// regular selling days, and discount adding stock beyond a day's recent demand.
float freeCraftingSalesScore(item result, int quantity, float profitPerTurn) {
    int unsold = freeCraftingOwned(result) + shop_amount(result);
    float turnover = min(1.0, freeCraftingSalesUnits[result] / 14.0 / max(1, unsold + quantity));
    float regularity = freeCraftingSalesDays[result] / 14.0;
    return profitPerTurn * turnover * regularity;
}

// dc.ash owns Museum parsing, the eleven-item lead, reserves, and holdings.
// Query its read-only machine interface each time so deficits follow live counts.
int [item] freeCraftingCollectionTargets;
int freeCraftingCollectionNeed(item result) {
    freeCraftingCollectionTargets[result] = -1;
    string response = cli_execute_output("dc --dry-run target " + to_int(result));
    matcher plan = create_matcher("DC_TARGET:([0-9]+):(-?[0-9]+):(-?[0-9]+):([0-9]+):([0-9]+):([0-9]+):([0-9]+)", response);
    if (!find(plan) || to_int(group(plan, 1)) != to_int(result) || to_int(group(plan, 3)) < 0) return 0;
    freeCraftingCollectionTargets[result] = to_int(group(plan, 3));
    return to_int(group(plan, 7));
}

FreeCraftingChoice bestFreeCrafting(int [item] yields, int [item] prices) {
    FreeCraftingChoice bestSale;
    float [item] costs;
    int [item] turnsFor;
    // First establish the best regularly selling alternative. Collection savings
    // are compared with this volume-adjusted opportunity, not an asking-price gain.
    foreach result, quantity in yields {
        if (!result.tradeable || quantity <= 0) continue;
        int turns = freeCraftingRecipeTurns(result);
        if (turns <= 0) continue;
        int [item] ingredients = get_ingredients(result);
        if (count(ingredients) == 0) continue;
        boolean ready = true;
        float cost;
        float purchaseCost;
        foreach ingredient, amount in ingredients {
            int price = freeCraftingIngredientPrice(ingredient, prices);
            if (price <= 0) { ready = false; break; }
            cost += price * to_float(amount);
            int missing = max(0, amount - freeCraftingOwned(ingredient));
            if (missing > 0 && !can_interact()) { ready = false; break; }
            purchaseCost += price * to_float(missing);
        }
        if (!ready || cost > 10000 || purchaseCost > my_meat()) continue;
        foreach ingredient, amount in ingredients
            if (!freeCraftingWellStocked(ingredient, freeCraftingIngredientPrice(ingredient, prices))) { ready = false; break; }
        if (!ready) continue;
        int marketPrice = freeCraftingPrice(result, prices);
        if (marketPrice <= 0) continue;
        costs[result] = cost;
        turnsFor[result] = turns;
        float salePrice = min(to_float(marketPrice), freeCraftingExpectedSalePrice(result));
        if (!freeCraftingRegularSales(result)) continue;
        float profit = salePrice * quantity - cost;
        if (profit <= 0 || !freeCraftingWellStocked(result, marketPrice)) continue;
        float score = freeCraftingSalesScore(result, quantity, profit / turns);
        if (score > bestSale.score) {
            bestSale = new FreeCraftingChoice(result, quantity, turns, profit, profit / turns);
            bestSale.score = score;
            bestSale.salesUnits14d = freeCraftingSalesUnits[result];
            bestSale.salesDays14d = freeCraftingSalesDays[result];
        }
    }
    FreeCraftingChoice best = bestSale;
    foreach result, cost in costs {
        int quantity = yields[result];
        int turns = turnsFor[result];
        float buyPrice = freeCraftingIngredientPrice(result, prices);
        if (buyPrice <= 0) continue;
        // A thin market's high asking quote must not manufacture a collection
        // saving when recent completed sales show the item can be much cheaper.
        if (freeCraftingSalePrices[result] > 0)
            buyPrice = min(buyPrice, freeCraftingSalePrices[result]);
        // Skip Museum requests when even a full needed batch cannot beat selling.
        if ((buyPrice * to_float(quantity) - cost) / turns <= best.score) continue;
        int needed = freeCraftingCollectionNeed(result);
        if (needed <= 0) continue;
        // Value only the units still needed; bonus batch output gets no credit.
        float saving = buyPrice * to_float(min(quantity, needed)) - cost;
        float score = saving / turns;
        if (score <= best.score) continue;
        best = new FreeCraftingChoice(result, quantity, turns, 0, 0);
        best.score = score;
        best.forDisplayCase = true;
        best.collectionTarget = freeCraftingCollectionTargets[result];
        best.collectionNeed = needed;
        best.salesUnits14d = freeCraftingSalesUnits[result];
        best.salesDays14d = freeCraftingSalesDays[result];
    }
    return best;
}

int [item] burnFreeCrafting() {
	int [item] receipt;
	int inigosCasts = max(0, 5 - to_int(get_property("_inigosCasts")));
	if (inigosCasts > 0) {
		restore_mp(100 * inigosCasts);
		ensureSongRoom($skill[Inigo's Incantation of Inspiration]);
		if (!use_skill(inigosCasts, $skill[Inigo's Incantation of Inspiration]))
			abort("failed casting inigo's");
	}
	clear(freeCraftingStockChecks);
	clear(freeCraftingSalePrices);
    clear(freeCraftingSalesUnits);
    clear(freeCraftingSalesDays);
    clear(freeCraftingCollectionTargets);
	int [item] yields = freeCraftingYields();
	int [item] prices;
	// Each selected recipe must consume at least one free turn. The bound also
	// protects against recipes whose actual behavior differs from Mafia's model.
	int tries = availableFreeCraftTurns("all") + 3;
	while (tries-- > 0) {
		FreeCraftingChoice choice = bestFreeCrafting(yields, prices);
		if (choice.result == $item[none]) {
			print("No affordable profitable recipes with sufficient free crafting turns.", "orange");
			break;
		}
        if (choice.forDisplayCase)
            print("Free crafting for Display Case: " + choice.quantity + " " + choice.result
                + "; rank-1 target " + choice.collectionTarget + ", still need " + choice.collectionNeed
                + "; acquisition cost avoided " + choice.score + " meat per free turn", "green");
        else
            print("Free crafting for sales: " + choice.quantity + " " + choice.result
                + "; expected profit " + choice.profitPerTurn + " meat per free turn, volume-adjusted score "
                + choice.score + "; " + choice.salesUnits14d + " units on " + choice.salesDays14d + "/14 days", "green");
		int adventuresBefore = my_adventures();
		if (!acquireFreeCraftingIngredients(choice, prices)) break;
		assert(my_adventures() == adventuresBefore, "burnFreeCrafting spent adventures acquiring ingredients");
		// Now that all direct ingredients are in inventory, Mafia's calculation
		// cannot include hypothetical crafts of missing subingredients.
		if (creatable_turns(choice.result, choice.quantity, false) <= 0
			|| creatable_turns(choice.result, choice.quantity, true) != 0
			|| creatable_amount(choice.result) < choice.quantity) {
			print("Recipe is no longer an available free craft: " + choice.result, "orange");
			break;
		}
		int amountBefore = item_amount(choice.result);
		boolean created = museumSafeCreate(choice.quantity, choice.result);
		assert(my_adventures() == adventuresBefore, "burnFreeCrafting spent adventures crafting " + choice.result);
		int made = item_amount(choice.result) - amountBefore;
		if (made > 0) receipt[choice.result] += made;
        if (made > 0 && choice.forDisplayCase) {
            if (!cli_execute("dc top1 " + to_int(choice.result))) {
                print("dc could not update the Display Case; stopping.", "red");
                break;
            }
        }
		if (!created || made <= 0) {
			print("Failed creating " + choice.result + "; stopping free crafting.", "red");
			break;
		}
	}
	print("items created using burnFreeCrafting:", "green");
	printReceipt(receipt);
	return receipt;
}



void burnFortuneTellerBuff(string buffString) {
	print("burnFortuneTellerBuff", "green");
	if (!vipLoungeAvailable())
		return;

	if (!to_boolean(get_property("_clanFortuneBuffUsed"))) {
		print("getting fortune buff: " + buffString);
		cli_execute("fortune buff " + buffString);
	} else
		print("already got the fortune teller buff", "green");
}


// uses CWBot only
boolean burnFortuneTellerConsult(boolean compatible) {
	print("burnFortuneTellerConsult", "green");
	if (!vipLoungeAvailable())
		return false;

	return cli_execute("fortune CWBot " + (compatible ? "" : " unmatchable gibberish blerrrrg")); // COMPATIBLE = "" vs INCOMPATIBLE = something random that won't match anything
}


void burnFortuneTeller(string buffString, boolean compatible1, boolean compatible2, boolean compatible3) {
	print("burnFortuneTeller", "green");
	if (!vipLoungeAvailable())
		return;

	cli_execute("zatara"); // auto-reply to requested consults

	if (!to_boolean(get_property("_clanFortuneBuffUsed"))) {
		print("getting fortune buff: " + buffString);
		cli_execute("fortune buff " + buffString);
	}

	boolean [] compatibleArray = {compatible1, compatible2, compatible3};

	// names with spaces will mess up incompatible fortune-telling
	string [] consults = {
		"CWBot",
		"PeKaJe",
		"infopowerbroker",
		"djve",
		"Weakling",
		"busstop82",
		"Quelzie",
		"Kuile",
		"bombzar",
		"TheBarracuda",
		"unusualscar",
		"Mhoraigh",
		"nixon66",
		"footrest",
		"Thaz",
		"Aaro",
		"Beljeferon",
	};

	int i = 0;
	int consultNumber = 1 + to_int(get_property("_clanFortuneConsultUses"));
	while (consultNumber <= 3 && i < count(consults)) {
		boolean worked = cli_execute("fortune " + consults[i] + (compatibleArray[consultNumber - 1] ? "" : " unmatchable gibberish blerrrrg")); // COMPATIBLE = "" vs INCOMPATIBLE = something random that won't match anything
		consultNumber = 1 + to_int(get_property("_clanFortuneConsultUses"));
		i++;
	}

	assert(get_property("_clanFortuneConsultUses").to_int() >= 3, "burnFortuneTeller: unused fortune teller consultations");
}



// if we're getting the ninja costume, we banish all elementals with Patriotic Eagle if we can
void grindTotCostume(item costume) {
	print("grindTotCostume: " + costume, "green");
	if (have_item(costume)) return;

	setDefaultState();
	ensureSongRoom($skill[Carlweather's Cantata of Confrontation]);

	// we're going to do a free kill
	string maxString = "-equip mafia thumb ring";
	string scriptString = "pickpocket;pickpocket;";

	location advLocation;
	string selector;

    // DRESSUP
	string famSelector = "item";
	if (costume == $item[li'l ninja costume]) { // if we have any +combat, we will be more and more likely to get the assassins
		setCurrentMood("-combat");
		advLocation = $location[Lair of the Ninja Snowmen];
		selector = "-combat";
		if ("screechCombats".get_property().to_int() == 0) {
			famSelector = "Patriotic Eagle";
			maxString += ", equip tiny rake"; // TODO need a better way to get default fam equip
		}
	} else if (costume == $item[li'l pirate costume]) {
		// need to handle non-combats
		setCurrentMood("+combat");
		advLocation = $location[Barrrney's Barrr];
		if (isUnlocked($location[Belowdecks])) {
            advLocation = $location[Belowdecks];
            famSelector = "Patriotic Eagle";
		}
		selector = "+combat";
		if (have_item($item[pirate fledges]))
			maxString += ", equip pirate fledges";
		else
			maxString += ", outfit swashbuckling getup";
	} else
		abort("unknown tot costume");
	maxString = dressForPickpocket(advLocation, maxString);

	PrioritySkillRecord instaKillSkill = chooseInstaKillSkill();
    if (instaKillSkill.theItem != $item[none])
	   maxString += ", equip " + instaKillSkill.theItem;

	automate_dressup(advLocation, selector, famSelector, maxString);

    // SCRIPT
	if (instaKillSkill.theSkill != $skill[none]) {
		restore_mp(mp_cost(instaKillSkill.theSkill) + 11);
		scriptString += "if " + isMonsterFromLocationScript(advLocation) + ";";
		if (famSelector == "Patriotic Eagle" && "_citizenZone".get_property() == ""
		  && (advLocation == $location[Belowdecks] || advLocation == $location[Lair of the Ninja Snowmen]))
            scriptString += "skill " + my_familiar().name + ", let's pledge allegiance to " + advLocation + ";";
		if (famSelector == "Patriotic Eagle" && "screechCombats".get_property().to_int() == 0 && advLocation == $location[Lair of the Ninja Snowmen])
			scriptString += "skill Release the Patriotic Screech!;";
		scriptString += "skill " + instaKillSkill.theSkill + ";";
		scriptString += "endif;abort;"; // abort in case something goes wrong
	} else
		scriptString = "";

	int tries = 3;
	while (tries > 0 && !have_item(costume)) { // in case of wandering monsters
		healAndRemoveDebuffsWithMPRestore();
		redirectAdventure(advLocation, scriptString);
		tries--;
	}

	assert(available_amount(costume) > 0, "didn't get tot costume!");
}



void applyMummingBuffs() {
	print("applyMummingBuffs", "green");
	familiar old_familiar = my_familiar();
	visit_url("/inv_use.php?which=3&pwd&whichitem=9592", true, false); // prime the pump

	if (my_daycount() == 1) {
		safeMumming($familiar[Gelatinous Cubeling], "myst"); // extra mys gain
	}

	if (inRonin()) {
		safeMumming($familiar[Cat Burglar], "item"); // extra mus (and stagger), mys, mox gain, bleed (item)
		safeMumming($familiar[Hobo Monkey], "meat"); // 1.25x leprechaun; extra mus, mys gain, extra item, meat drop
		safeMumming($familiar[Garbage Fire], "mp"); // hot dmg (mp)
		safeMumming($familiar[Robortender], "hp"); // extra mys gain, extra meat drop, extra hp
		if (my_daycount() != 1)
			safeMumming($familiar[Optimistic Candle], "myst"); // hot dmg (mp), extra mys gain
	} else { // TODO figure a fam to use hp, mys buffs
		safeMumming($familiar[Trick-or-Treating Tot], "item"); // extra meat, item drop, extra mys gain
		safeMumming($familiar[Robortender], "meat"); // extra mys gain, extra meat drop, extra hp
		// 		safeMumming($familiar[Robortender], "hp"); // extra mys gain, extra meat drop, extra hp
		// 		safeMumming($familiar[Hobo Monkey], "meat"); // extra meat drop (and delevel), extra mus gain, extra item, extra mys gain
		safeMumming($familiar[Space Jellyfish], "mus"); // extra mus gain
		safeMumming($familiar[Chocolate Lab], "mox"); // extra mus, mys gain
		safeMumming($familiar[Cat Burglar], "mp"); // extra mus (and stagger), mys, mox gain, bleed (item)

		if(to_int(get_property("optimisticCandleProgress")) / 30 > kPersueFamiliarIfOver)
			safeMumming($familiar[Optimistic Candle], "myst"); // hot dmg (mp), extra mys gain
	}

	if (!use_familiar(old_familiar)) abort("unable to switch back to original familiar");
}



void buyShelfSpecials() {
	print("buyShelfSpecials", "green");
	if (to_boolean(get_property(ShelfSpecialsPurchasedKey)))
		return;

	int [item, int] buy_map;
	buySpecials(buy_map);
	set_property(ShelfSpecialsPurchasedKey, "true");
}


void buyMallSpecials() {
	print("buyMallSpecials", "green");
	if (to_boolean(get_property(MallSpecialsPurchasedKey)))
		return;

	int [item, int] buy_map;
	file_to_map("unrestricted_buy_map.txt", buy_map);

	buySpecials(buy_map);
	set_property(MallSpecialsPurchasedKey, "true");
}



void timespinner_prank(string playerName) {
	if (to_int(get_property("_timeSpinnerMinutesUsed")) >= 10) return;
	cli_execute("timespinner prank " + playerName + " msg=Tequila!");
}

void burn_timespinner_pranks() {
	print("burn_timespinner_pranks", "green");
	string [int] pranks = {
		1:"cyberdyne",
		2:"PeKaJe",
		3:"djve",
		4:"infopowerbroker",
		5:"busstop82",
		6:"Weakling",
		7:"TheBarracuda",
		8:"llubgnuoy",
		9:"beljeferon",
		10:"bombzar",
		11:"dragonfrog",
		12:"nixon66"
	};

	for i from 1 to count(pranks) {
			if (to_int(get_property("_timeSpinnerMinutesUsed")) >= 10) return;
			timespinner_prank(pranks[i]);
		}
}

void burnTimeSpinnerWayBackInTime() {
	print("burn_timespinner_fights", "green");
	setDefaultMood();

	if (to_int(get_property("_timeSpinnerMinutesUsed")) >= 10) return;

	// lower stats for Krakrox!!
	cli_execute("mcd 0");
	cli_execute("uneffect ode");
	buffIfNeededWithUneffect($skill[Jackasses' Symphony of Destruction], 11);
	burnMP();

	clearAutomateDressup();
	dressup($location[none], "0.1 hp", "default", "-mys, -mus, -mox, -ml, 0.1 mp, -equip wristwatch of the white knight");

	for i from 1 to 11 - to_int(get_property("_timeSpinnerMinutesUsed")) {
			healAndRemoveDebuffsWithMPRestore();
			visit_url("/inv_use.php?which=3&pwd&whichitem=9104&ajax=1", true, false);
			run_choice(3);
		}
}


void burnTimeSpinnerRecentFights() {
	monster [] tsMonsters = timespinnerRecentFightEconomics(false);
	int bestIndex = 0;
	monster timespinnerTarget = tsMonsters[bestIndex++];
	if (timespinnerTarget == $monster[unemployed knob goblin] && "_beerLensDrops".get_property().to_int() >= 3)
		timespinnerTarget = tsMonsters[bestIndex++];

	int timespinnerMinutesUsed = get_property("_timeSpinnerMinutesUsed").to_int();
	while(timespinnerMinutesUsed <= 7) {
		print("targetting " + timespinnerTarget + " with the remaining " + (10 - timespinnerMinutesUsed) + " Time-Spinner minutes", "blue");

		timespinnerRecentFight(timespinnerTarget);
		run_combat();
		postAdventure();

		timespinnerMinutesUsed = get_property("_timeSpinnerMinutesUsed").to_int();
		if (timespinnerTarget == $monster[unemployed knob goblin] && "_beerLensDrops".get_property().to_int() >= 3)
			timespinnerTarget = tsMonsters[bestIndex++];
	}

}


void burn_timespinner() {
	if (to_int(get_property("_timeSpinnerMinutesUsed")) >= 10) return;
	burnTimeSpinnerRecentFights();
	burnTimeSpinnerWayBackInTime();
}


// fight a photocopied monster.
// first, if putFax is true, will send our current fax
// if we have one in our inv already, will fight that, otherwise will get a fax first and then fight it
// finally, will get a fax and leave it in our inv for tomorrow
void burnFax(boolean putFax) {
	assert(!get_property("_photocopyUsed").to_boolean(), "fax already burned");
	print("burnFax: current photocopy: " + get_property("photocopyMonster") + ", put fax first: " + putFax, "green");
	assert(!putFax || have_item($item[photocopied monster]), "we don't have a fax to put");

	if (putFax)
		cli_execute("fax put");

	if (item_amount($item[photocopied monster]) == 0)
		cli_execute("fax get");

	monster monsterToFight = get_property("photocopyMonster").to_monster();

	// dress up
	string selector = "item";
	string familiarSelector = "item";
	string maxString;
	if (!cllHasReminiscence(monsterToFight))
		maxString = "equip combat lover's locket";

	if (roboEconomicsForMonster(monsterToFight) >= 3333) { // TODO figure out benefit from other fams
		familiarSelector = "robortender";
	}
	automate_dressup($location[none], selector, familiarSelector, maxString);

	healAndRemoveDebuffsWithMPRestore();
	anyAdventure(new AdventureRecord($location[none], $skill[none], $item[photocopied monster]));

	cli_execute("fax get");
}



// burn all remaining genie wishes using wish, stopping if we encounter the goal item
void burnGenieWishes(item goalItem, string wish) {
	int genieWishesPossible = 3 - to_int(get_property("_genieWishesUsed"));

	// figure the meat gain per wish
	boolean willCombat = !wish.contains_text("pony") && !wish.contains_text("pocket wish");
	monster fightMon = wish.to_monster();
	int monsterMeatValue = monsterCurrentTotalMeatValue(fightMon, false);
	int meatWishValue = min(50000, my_level() * 500);

	print("burnGenieWishes, wishes to make: " + genieWishesPossible + ", wish: '" + wish + "', stopping on goal item: " + goalItem, "green");
	if (genieWishesPossible == 0) return;

	int startingGoalAmount = 0;
	if (willCombat) {
		assert(fightMon != $monster[none], "wish should resolve to a monster");
		if (monsterMeatValue < meatWishValue && !user_confirm("About to wish a monster worth " + monsterMeatValue + ", but we can just wish meat worth " + meatWishValue + ". Continue?", 60000, true))
			abort("user aborted");

		if (goalItem != $item[none]) {
			startingGoalAmount = my_session_items(goalItem);
			if (startingGoalAmount > 0 && !user_confirm("We already got at least one " + goalItem + ". Continue to wish for another " + fightMon + "?", 60000, true))
				abort("user aborted");
		}
	}

	// compose wish string
	string genie_string = "monster " + wish;
	if (!willCombat)
		genie_string = "item " + wish;

	while (genieWishesPossible > 0 && (goalItem == $item[none] || my_session_items(goalItem) <= startingGoalAmount)) {
		print("wishing for: " + genie_string);
		cli_execute("genie " + genie_string);
		if (willCombat) {
			visit_url("/main.php", true, false); // get to the fight
			run_combat();
		}

		genieWishesPossible--;
	}

	if (to_int(get_property("_genieWishesUsed")) < 3)
		print("WARNING: unused genie wishes", "red");
}



// costs min 200 meat for the bricks and ~1600 meat for the eye -- doesn't seem worth it
void burn_bricko_fights(item bricko_monster) {
	print("burn_bricko_fights", "green");
	int brickoFightsPossible = 10 - to_int(get_property("_brickoFights"));

	fullAcquire(bricko_monster);
	while (brickoFightsPossible > 0 && have_item(bricko_monster) && smmMuseumMaySpend(bricko_monster, 1)) {
		print("fighting: " + bricko_monster);
		cli_execute("use " + bricko_monster);
		visit_url("/main.php", true, false); // get to the fight
		visit_url("/fight.php?action=steal", true, false); // pickpocket if able
		run_combat();

		brickoFightsPossible--;
	}
}

void burn_bricko_fights() {
	burn_bricko_fights($item[BRICKO ooze]);
}


void burn_kgb(string buff_to_get) {
	print("burn_kgb", "green");
	effect [string] buff_map = {
		"meat":$effect[A View to Some Meat],
		"item":$effect[Items Are Forever]
	};

	int kgbClicksUsed = to_int(get_property("_kgbClicksUsed"));
	int kgb_buffs_possible = (27 - kgbClicksUsed) / 3;

	string buff_string = "briefcase buff " + buff_to_get;
	string alt_buff_string = "briefcase buff ";
	if (buff_to_get == "item")
		alt_buff_string += "meat";
	else
		alt_buff_string += "item";

	for i from 1 to kgb_buffs_possible {
			if (have_effect(buff_map[buff_to_get]) < 500)
				cli_execute(buff_string);
			else
				cli_execute(alt_buff_string);
		}
}



// where "free" = no turns
void burnFreeDaycare() {
	print("burnFreeDaycare", "green");

	burnScavengeDaycare(0); // spend 0 turns scavenging

	int toddlerRecruits = to_int(get_property("_daycareRecruits"));
	print("recruiting toddlers, we have " + get_property("daycareToddlers") + " toddlers before recruiting", "blue");
	while (toddlerRecruits < 2) {
		daycareRecruit();
		toddlerRecruits = to_int(get_property("_daycareRecruits"));
	}
	print(get_property("daycareToddlers") + " toddlers after recruiting", "blue");
}


// burn mana, maximize mp, use license to chill, then burnHP and burnMP
// burnAmount is any value accepted by burnMP/burn, use kMinInt to save all mana
void burnLicenseToChill(int burnAmount) {
	if (!to_boolean(get_property("_licenseToChillUsed"))) {
		burnMP(0);
		maximize("mp", false);

		use(1, $item[license to chill]);

		burnHP();
		burnMP(burnAmount);
	}
}

void burnLicenseToChill() {
	burnLicenseToChill(gUnrestrictedManaToSave);
}



boolean mayamSymbolsAvailable(string symbols) {
    string used = "," + get_property("_mayamSymbolsUsed") + ",";
    foreach i, symbol in split_string(symbols, ",") {
        if (used.contains_text("," + symbol + ",")) return false;
    }
    return true;
}

void burnMayamCalendar(boolean genTurns) {
    if (item_amount($item[Mayam Calendar]) + equipped_amount($item[Mayam Calendar]) == 0) return;

    if (genTurns && mayamSymbolsAvailable("yam1,lightning,yam3,clock")) {
        cli_execute("mayam resonance yam battery");
        return;
    }

	// This is worth ~5k meat but free rests MIGHT MIGHT MIGHT be worth a lot
    if (mayamSymbolsAvailable("vessel,yam2,cheese,explosion"))
        cli_execute("mayam resonance stuffed yam stinkbomb");

    if (mayamSymbolsAvailable("fur,meat,wall,yam4")) {
        use_familiar($familiar[Pocket Professor]);
        cli_execute("mayam rings fur meat wall yam");
    }
}



// where "free" means less than the current value of kTurnValue
void burnFreeTurnGen() {
	print("burnFreeTurnGen", "green");

	int tries = 3;
	while ("_chocolatesUsed".get_property().to_int() < 2 && tries > 0) {
		int kChocolatesToEat = 2;
		item [class] classItemMap = {
			$class[seal clubber]:$item[chocolate seal-clubbing club],
			$class[turtle tamer]:$item[chocolate turtle totem],
			$class[pastamancer]:$item[chocolate pasta spoon],
			$class[sauceror]:$item[chocolate saucepan],
			$class[disco bandit]:$item[chocolate disco ball],
			$class[accordion thief]:$item[chocolate stolen accordion]
		};

		int chocolatesToEat = kChocolatesToEat - to_int(get_property("_chocolatesUsed"));
		item chocolateToEat = classItemMap[my_class()];
		if (chocolateToEat != $item[none]) {
			newAcquire(chocolateToEat, chocolatesToEat, kTurnValue * 2);
			if (available_amount(chocolateToEat) >= chocolatesToEat)
				museumSafeUse(chocolatesToEat, chocolateToEat);
		}
		tries--;
	}

	if (!"_essentialTofuUsed".get_property().to_boolean()) {
		newAcquire($item[essential tofu], 1, 5 * kTurnValue);
		use($item[essential tofu], 1);
	}

    burnMayamCalendar(true);

	// burn mana, maximize mp, and use license to chill only if we aren't doing fernswarthy
	// in which case, save for later use in fernswarthy
	if (fernswarthy_level() <= 1 || fernswarthy_level() >= 500) {
		burnLicenseToChill();
	}
}


void printPottedPowerPlant() {
	visit_url("/inv_use.php?pwd&which=3&whichitem=10738", true, false);
	string plantStatus = get_property("_pottedPowerPlant");
	print("\npotted power plant: " + plantStatus, "red");
	if (plantStatus.contains_text("6")) {
		print("************* WARNING: potted power plant ready for harvest ****************\n", "red");
		print("************* WARNING: potted power plant ready for harvest ****************\n", "red");
		print("************* WARNING: potted power plant ready for harvest ****************\n", "red");
		wait(15);
	}
}



// sets up for and then prints basic daily info that might be relevant to the current daily run
void printDailyInfo(int [location] endGameTurnsSpent) {
	cli_execute("inv baconstone; inv hamethyst");
	print("today's daily special: " + daily_special());

	printEffectDescription($effect[Blessing of the bird]);
	printEffectDescription($effect[Blessing of your favorite Bird]);

	// display bounties in case we want one
	cli_execute("bounty");
	if (vipLoungeAvailable()) printFloundrySpots();
	cli_execute("cheapest affirmation cookie");
	if (have_item($item[Love Potion #XYZ]))
		print_description($item[Love Potion #XYZ]);
	else
		print("drank love potion");

	printPottedPowerPlant();
}

void printDailyInfo() {
	int [location] endGameTurnsSpent;
	printDailyInfo(endGameTurnsSpent);
}



item defaultZap(boolean zapMoreThanOncePerDay) {
	if (!zapMoreThanOncePerDay && to_int(get_property("_zapCount")) > 0) {
		print("skipping zap, already zapped", "blue");
		return $item[none];
	}

	item zapItem = mostOfItemAvailable(item [] {
		$item[tiny plastic turtle tamer],
		$item[tiny plastic seal clubber],
		$item[tiny plastic disco bandit],
		$item[tiny plastic accordion thief],
		$item[tiny plastic pastamancer],
		$item[tiny plastic sauceror],
	});

	retrieve_item(zapItem);
	checkIfRunningOut(zapItem, 50);
	int zapItemPrice = current_price(zapItem);
	string zapResultString = cli_execute_output("zap " + zapItem);
	int [item] zapResultItems = extract_items(zapResultString);

	foreach it in zapResultItems {
		int zapResultPrice = current_price(it);
		print("net value of zapping: " + it + "@" + zapResultPrice + " less original item " + zapItem + "@" + zapItemPrice + " = " + (zapResultPrice - zapItemPrice));
		return it;
	}
	return $item[none];
}

void defaultZap() {
	defaultZap(false);
}



void burnCandyCaneSwordCane() {
    equip($item[candy cane sword cane]);
    if (!"_candyCaneSwordOvergrownShrine".get_property().to_boolean()) {
        advURL($location[An Overgrown Shrine (Northeast)]);
        run_choice(4); // free money
        run_choice(6); // exit
    }
}



// all the setup for items
void setupItems() {
	print("setupItems", "green");
	boolean unused;

	setDefaultBoombox();

	// do this early so we have a better chance at rare spots
	burnFreeCombs(1); // save 1 for +fam

	// time-spinner
	if (!to_boolean(get_property("_timeSpinnerReplicatorUsed"))) {
		equip($slot[weapon], $item[none]); // ensure we aren't wearing anything that would mess with FarFuture
		cli_execute("FarFuture food");
		assert(my_session_items($item[Tea, Earl Grey, Hot]) > 0, "didn't get far future item!");
	}

	if (!have_item($item[pantogram pants])) {
		fullAcquire($item[bubblin' crude]);
// 		fullAcquire($item[porquoise]); // meat 2
		fullAcquire($item[taco shell]); //  meat 1
		fullAcquire($item[ten-leaf clover]);
		summon_pants("sleaze", "mp regen 2", "meat drop 1", "hilarity"); // bubblin' crude, taco shell, ten-leaf clover
	}

	// mod the Cosplay sabre
	if (get_property("_saberMod") == "0") {
		visit_url("main.php?action=may4");
		visit_url("choice.php?pwd&whichchoice=1386&option=4"); // +10 fam weight
		// 		visit_url("choice.php?pwd&whichchoice=1386&option=3"); // +3 all res
	}

	if (item_amount($item[runed taper candle]) == 0)
		buy($item[oversized sparkler]);
	fullAcquire(gkFishyGearToGet);

	if (item_amount($item[soap knife]) > 0)
		put_closet(item_amount($item[soap knife]), $item[soap knife]);
	use_skill($skill[That's Not a Knife]);

	voteInVotingBooth();

// 	cli_execute("briefcase collect");

	//buy(1, $item[game grid token]);
	visit_url("/place.php?whichplace=arcade&action=arcade_plumber", false, false); // can get a random game token?

	// use quest items
	use(available_amount($item[fisherman's sack]), $item[fisherman's sack]);

	// do this after license to chill in case we get free buff turns
	if (!get_property("_bastilleGamesLockedIn").to_boolean()
	    && (have_effect($effect[Shark-Tooth Grin]) > gkBastilleBuffAmount - 3
	        || have_effect($effect[Boiling Determination]) > gkBastilleBuffAmount - 3
	        || have_effect($effect[Enhanced Interrogation]) > gkBastilleBuffAmount - 3)) {
		use_if_needed($item[sharkfin gumbo], $effect[Shark-Tooth Grin], gkBastilleBuffAmount);
		use_if_needed($item[boiling broth], $effect[Boiling Determination], gkBastilleBuffAmount);
		use_if_needed($item[interrogative elixir], $effect[Enhanced Interrogation], gkBastilleBuffAmount);
		unused = cli_execute("basty win");
	} else if (to_boolean(get_property("_bastilleGamesLockedIn")) == false && to_int(get_property("_bastilleGames")) < 5 && (have_effect($effect[Shark-Tooth Grin]) > 0 || have_effect($effect[boiling determination]) > 0 || have_effect($effect[enhanced interrogation]) > 0))
		print("have bastille buffs but not enough", "red");

    // CANDY CANE SWORD CANE
    burnCandyCaneSwordCane();

    // APRILING BAND HELMET
    if (have_effect($effect[Apriling Band Celebration Bop]) == 0) {
        cli_execute("apriling drop");
    }
    if (!have_item($item[Apriling band saxophone]) && "_aprilBandInstruments".get_property().to_int() < 2) {
        cli_execute("apriling sax");
    }
    if (!have_item($item[Apriling band quad tom]) && "_aprilBandInstruments".get_property().to_int() < 2) {
        cli_execute("apriling drum");
    }

	if (get_property("_birdOfTheDay") == "")
		use($item[Bird-a-Day calendar], 1);
}



void setupChoiceAdventures() {
	if (!"_smm.JuneCleaverChoiceAdventuresSet".get_property().to_boolean()) {
		set_property("choiceAdventure1467", "3"); // +5 adv (vs stats)
		set_property("choiceAdventure1468", "4"); // 5 meat and stats (vs stats)
		set_property("choiceAdventure1469", "4"); // 1500 meat (vs dad's brandy or ml)
		set_property("choiceAdventure1470", "4"); // teacher's pen (vs stats or lame buff)
		set_property("choiceAdventure1471", "1"); // savings bond (vs 250 meat or stats) -- same choice as before
		set_property("choiceAdventure1472", "4"); // trampled ticket stub or fire-roasted lake trout (vs stats) -- choose the one we have least of
		set_property("choiceAdventure1473", "4"); // gob of wet hair and stats (vs lame buffs)
		set_property("choiceAdventure1474", "4"); // guilty sprout (vs stats)
		set_property("choiceAdventure1475", "1"); // mother's necklace (vs stats or random buffs) -- same choice as before

		set_property("_smm.JuneCleaverChoiceAdventuresSet", "true");
	}
}



// TODO Jingle Bells TT buff bot buff
string gkSecondBreakfastDoneKey = "_smm.SecondBreakfastDone";
void secondBreakfast(int [location] endGameTurnsSpent) {
	boolean unused;

	smmIRBreakfast();

	setupChoiceAdventures();

	setUpMood();
	setupItems();

	if (!inRonin()) { // setup the default outfit
		dressup($location[none], "item", "item", "");
		saveOutfit(kDefaultOutfit);
	}

	if (have_mushroom_plot())
		cli_execute("planting/auto_mushroom.ash");

	burnFreeDaycare();
	applyMummingBuffs();

	// STUFF THAT COSTS MANA AFTER THIS -- these first ones cost lots of mana
	if (my_basestat($stat[moxie]) >= 133) { // 150 minus some to allow for stat gains and wearing later in the day
		use_skill(1, $skill[Ceci N'Est Pas Un Chapeau]);
		assert(have_item($item[no hat]), "didn't get no hat!");
	}

	if (have_skill($skill[canticle of carboloading])) {
		use_skill(1, $skill[canticle of carboloading]);
	}

	healAndRemoveDebuffsWithMPRestore();
	use_skill(1, $skill[blood blade]);
	use_skill(1, $skill[blood blade]);
	if (!have_item($item[maple magnet]))
		fullAcquire($item[maple magnet]);

	// Buying is now the budgeted step at the end of the day (smmSpendRun), which
	// reads the same buy map. See docs/daily-spending.md.

	set_property(gkSecondBreakfastDoneKey, "true");

	printDailyInfo(endGameTurnsSpent);
}

void secondBreakfast() {
	secondBreakfast(endGameTurnsSpent());
}



boolean checkLOVprepStats(boolean shouldAbort) {
	boolean isError = false;
	string errorString = "";

	if (my_buffedstat($stat[moxie]) - monster_level_adjustment() < my_buffedstat($stat[muscle]) * 1.1) {
		isError = true;
		errorString += "check monster level (muscle * 1.1 &gt; mox - ml) but should be lesser. ";
	}
	if (my_buffedstat($stat[mysticality]) < my_buffedstat($stat[moxie]) * 0.8) {
		isError = true;
		errorString += "mysticality &lt; moxie * 0.8 but should be greater. ";
	}
	if (equipped_item($slot[weapon]) == $item[none]) {
		isError = true;
		errorString += "no weapon! ";
	}

	if (isError && shouldAbort)
		abort("aborting due to incorrect LOV stats: " + errorString);

	return !isError;
}

// preps for the lov tunnel, returns true if it successfully burnt all mana, false otherwise
boolean LOVprep() {
	boolean unused;
	float ml_mod = -5;
	float mus_mod = -1;
	float mys_mod;
	float mox_mod;

	change_mcd(0);
	setDefaultMood();
	if (available_amount($item[FantasyRealm G. E. M.]) == 0)
		cli_execute("fr quest"); // getFantasyrealmQuest(); // need the FantasyRealm G. E. M.
	cli_execute("uneffect arrowsmith, sonata, cantata, ur-kel");
	buffIfNeededWithUneffect($skill[The Magical Mojomuscular Melody]);
	if (my_class() == $class[pastamancer] && have_skill($skill[Dismiss Pasta Thrall])) // TODO detect specific thrall that causes a problem
		use_skill($skill[Dismiss Pasta Thrall]);

	string maxString = "-familiar, -melee, pickpocket chance, init";
	if (!have_item($item[broken champagne bottle]) || to_int(get_property("garbageChampagneCharge")) == 0) {
		maxString += ", +equip makeshift garbage shirt";
		if (to_int(get_property("garbageShirtCharge")) < 3)
			cli_execute("tote 5");
	}

	burnMP();
	use_familiar($familiar[space jellyfish]);
	cli_execute("equip space jellybicycle");

	if (my_primestat() == $stat[moxie]) {
		mys_mod = 2;
		mox_mod = 1;
		if (my_class() == $class[accordion thief]) {
			//maxString += ", +outfit Master Squeezeboxer";
		} else {
			maxString += ", +equip aerogel attache case"; // gives +pickpocket and cocktail mat drops
		}
	} else if (my_primestat() == $stat[muscle]) {
		buffIfNeededWithUneffect($skill[Disco Smirk]);
		mus_mod = -5;
		mys_mod = 3;
		mox_mod = 6;
		if (my_basestat($stat[moxie]) >= 200)
			maxString += ", +equip mime army infiltration glove, +equip aerogel attache case";
		else
			maxString += ", +equip tiny black hole";
	} else {
		buffIfNeededWithUneffect($skill[Disco Smirk]);
		mys_mod = 1;
		mox_mod = 3;
		if (my_basestat($stat[moxie]) >= 200)
			maxString += ", +equip mime army infiltration glove, +equip aerogel attache case";
		else
			maxString += ", +equip tiny black hole";
	}

	int tries = 4;
	clearAutomateDressup();
	repeat {
		// we want LOW stats: makes Krakrox easier, but we need some stats to overcome +ml, which is +75 right now...
		string temp_maxString = maxString + ", equip FantasyRealm G. E. M., " + mys_mod + " mys, " + mus_mod + " mus, " + mox_mod + " mox, " + ml_mod + " ml";
		assert(maximize(temp_maxString, false), "maximize failed");

		int buffedMus = my_buffedstat($stat[muscle]);
		int buffedMys = my_buffedstat($stat[mysticality]);
		int buffedMox = my_buffedstat($stat[moxie]);

		if (buffedMys < buffedMox * 0.8)
			mys_mod += 6;
		if (buffedMox - monster_level_adjustment() < buffedMus * 1.1) {
			mox_mod *= 4;
			mus_mod -= 8;
			ml_mod -= 4;
		}

		if (buffedMox - monster_level_adjustment() < buffedMus * 1.1)
			buffIfNeededWithUneffect($skill[The Moxious Madrigal]);
		if (buffedMox - monster_level_adjustment() < buffedMus * 1.1)
			buffIfNeededWithUneffect($skill[Blubber Up]);
		if (buffedMox - monster_level_adjustment() < buffedMus * 1.1) {
			if (my_basestat($stat[moxie]) > 40)
				buffIfNeededWithUneffect($skill[Quiet Desperation]);
			else
				buffIfNeededWithUneffect($skill[Disco Smirk]);
		}

		if (tries < 3 && buffedMys < buffedMox * 0.8)
			use_if_needed($item[ointment of the occult], $effect[Mystically Oiled], 1);
		if (tries < 3 && buffedMox - monster_level_adjustment() < buffedMus * 1.1) // Sleepy
			use_if_needed(potionOfDoom("sleepiness"), $effect[Sleepy], 1);
		if (tries < 3 && buffedMys < buffedMox * 0.8)
			use_if_needed($item[gummi snake], $effect[Gummibrain], 1);

		if (tries < 2 && buffedMys < buffedMox * 0.8)
			cli_execute_if_needed("beach head We're All Made of Starfish", $effect[We're All Made of Starfish]);
		if (tries < 2 && buffedMox - monster_level_adjustment() < buffedMus * 1.1)
			use_if_needed($item[serum of sarcasm], $effect[Superhuman Sarcasm], 1);
		if (tries < 2 && buffedMox - monster_level_adjustment() < buffedMus * 1.1)
			cli_execute_if_needed("beach head Pomp & Circumsands", $effect[Pomp & Circumsands]);

		tries--;
	} until (tries < 0 || checkLOVprepStats(false));

	// sanity checks
	checkLOVprepStats(true);

	if (my_daycount() == 1) {
		if (my_hp() < my_maxhp() * 0.9)
			cli_execute("hottub");
	} else {
		healAndRemoveDebuffsWithMPRestore(); // heal up after changing equipment
		burnMP(0);
	}

	if (my_mp() > 10) {
		print("warning: unburnt mana", "blue");
		return false;
	}
	return true;
}


void LOVadv(item clothes, effect buff, item emporium) {
	print("LOVadv", "green");
	if (to_boolean(get_property("_loveTunnelUsed")))
		return;

	LOVprep();

	int [item] clothes_map = {
		$item[LOV Eardigan]:1,
		$item[LOV Epaulettes]:2,
		$item[LOV Earrings]:3,
		$item[none]:4
	};
	int [effect] buff_map = {
		$effect[Lovebotamy]:1,
		$effect[Open Heart Surgery]:2,
		$effect[Wandering Eye Surgery]:3,
		$effect[none]:4
	};
	int [item] emporium_map = {
		$item[LOV Enamorang]:1,
		$item[LOV Emotionizer]:2,
		$item[LOV Extraterrestrial Chocolate]:3,
		$item[LOV Echinacea Bouquet]:4,
		$item[LOV Elephant]:5,
		$item[toast]:6,
		$item[none]:7
	};

	if (!(clothes_map contains clothes)) abort ("clothes value '" + clothes + "' unknown");
	if (!(buff_map contains buff)) abort ("buff value '" + buff + "' unknown");
	if (!(emporium_map contains emporium)) abort ("emporium value '" + emporium + "' unknown");

	visit_url("/place.php?whichplace=town_wrong&action=townwrong_tunnel", true, false);
	assert(handling_choice() && last_choice() == 1222, "not on the LOV Tunnel choice page");

	run_choice(1); // visit LOV tunnel
	run_choice(1); // fight enforcer
	run_combat();
	visit_url("/place.php?whichplace=town_wrong&action=townwrong_tunnel", true, false);

	int clothesBefore = item_amount(clothes);
	run_choice(clothes_map[clothes]);
	assert(clothes == $item[none] || item_amount(clothes) > clothesBefore, "didn't get " + clothes);
	run_choice(1); // fight engineer
	run_combat();
	visit_url("/place.php?whichplace=town_wrong&action=townwrong_tunnel", true, false);

	run_choice(buff_map[buff]);
	visit_url("/choice.php?whichchoice=1227&option=1&pwd", true, false); // fight equivocator
	visit_url("/fight.php?action=steal", true, false); // pickpocket if able
	run_combat();

	visit_url("/place.php?whichplace=town_wrong&action=townwrong_tunnel", true, false);
	int emporiumBefore = item_amount(emporium);
	run_choice(emporium_map[emporium]); // boomerang, etc.
	// Session item totals are net changes: earlier Museum deposits can make them negative.
	assert(emporium == $item[none] || item_amount(emporium) > emporiumBefore, "didn't get " + emporium);

	if (my_class() == $class[pastamancer])
		getDefaultPastaThrall();
	max_mcd();
}



void grindJellyWithEnemyReplacement(boolean usePowerglove, boolean useMacro, item jellyType, boolean zeroTurns) {
	print("grindJellyWithEnemyReplacement", "green");

	int kMinimumGoalJellies = 3;
	int jelliesDropped = "_spaceJellyfishDrops".get_property().to_int();
	int macroUsesAvailable = 10 - to_int(get_property("_macrometeoriteUses"));
	int gloveUsesAvailable = 10 - ceil(to_int(get_property("_powerfulGloveBatteryPowerUsed")) / 10.0);

	if (jelliesDropped >= kMinimumGoalJellies && gloveUsesAvailable == 0) return;

	string maxString = "equip familiar scrapbook, -equip Kramco Sausage-o-Matic&trade;, -equip \"i voted!\" sticker, -equip mafia thumb ring";
	if (usePowerglove) maxString = maxString.maxStringAppend("equip Powerful Glove");
	if (!zeroTurns) maxString = maxString.maxStringAppend("-equip mafia thumb ring"); // only wear if we DON'T banish

	location gotoLo;
    switch(jellyType) {
        case $item[cold jelly]:
            gotoLo = $location[Lair of the Ninja Snowmen];
            setCurrentMood("meat");
            automate_dressup(gotoLo, "item", "space jellyfish", maxString);
            break;

        case $item[stench jelly]:
            gotoLo = mysterious_island_camp("hippy");
            setCurrentMood("meat");
            automate_dressup(gotoLo, "item", "space jellyfish", maxString.maxStringAppend("+combat"));
            break;

        case $item[sleaze jelly]:
            gotoLo = mysterious_island_camp("frat");
            setCurrentMood("+combat, meat");
            automate_dressup(gotoLo, "+combat", "space jellyfish", maxString.maxStringAppend("0.1 item"));
            break;

        default:
            abort("Unknown jelly type: " + jellyType);
    }

	PrioritySkillRecord instaKillSkill = chooseInstaKillSkill();
	if (instaKillSkill.theSkill != $skill[none]) {
		if (instaKillSkill.theItem != $item[none])
			dressup("equip " + instaKillSkill.theItem);
	}

	healAndRemoveDebuffsWithMPRestore();

	int tries = 3;
	while ((jelliesDropped < kMinimumGoalJellies || gloveUsesAvailable > 0) && tries > 0) {
		assert(willRedirect(gotoLo) || equipped_amount($item[powerful glove]) >= 1, "BEFORE: we should be wearing the powerful glove at this point");
		string page = advURLWithWanderingMonsterRedirect(gotoLo);
		assert(my_location() != gotoLo || equipped_amount($item[powerful glove]) >= 1, "AFTER: we should be wearing the powerful glove at this point");

		if (handling_choice())
			run_choice(-1);
		else if (!contains_monster(gotoLo, last_monster())) // wandering monster
			run_combat();
		else {
			string theScript = pickpocket_sub();
			if (usePowerglove && gloveUsesAvailable > 0)
				theScript += "sub pgMain;if !times " + gloveUsesAvailable + ";skill extract jelly;skill CHEAT CODE: Replace Enemy;call pgMain;endif;endsub;call pgMain;";
			executeScript(theScript);

			if (useMacro && macroUsesAvailable > 0)
				theScript = "sub macroMain;if !times " + min(macroUsesAvailable, 13 - gloveUsesAvailable) + ";skill extract jelly;skill Macrometeorite;call macroMain;endif;endsub;call macroMain;";
			theScript += "skill extract jelly;";

			if (zeroTurns && instaKillSkill.theSkill != $skill[none])
				theScript += "skill " + instaKillSkill.theSkill;
			else
				theScript += "attack;repeat;"; // attack until dead

			executeScript(theScript);
		}

		tries--;
		jelliesDropped = to_int(get_property("_spaceJellyfishDrops"));
		macroUsesAvailable = 10 - to_int(get_property("_macrometeoriteUses"));
		gloveUsesAvailable = 10 - ceil(to_int(get_property("_powerfulGloveBatteryPowerUsed")) / 10.0);
	}
}

void grindJellyWithEnemyReplacement() {
	grindJellyWithEnemyReplacement(true, true, $item[cold jelly], true);
}



// should take 0 adventures, but goes on adventures
void dailyDeedsAdv() {
	if (my_garden_type() == "grass") // means we're using the tall grass garden
		grind_poke_familiar_items();

	grindJellyWithEnemyReplacement(true, true, $item[cold jelly], true); // 0 adv

	grindTotCostume($item[li'l pirate costume]);
	// warn instead of stopping: one missing costume shouldn't strand the rest of the day's resources
	if (available_amount($item[li'l pirate costume]) <= 0)
		print("didn't get li'l pirate costume, continuing", "red");
	// grindTotCostume($item[li'l ninja costume]); should be done by jelly grinding
	if (available_amount($item[li'l ninja costume]) <= 0)
		print("didn't get li'l ninja costume, continuing", "red");

	if (!to_boolean(get_property("_loveTunnelUsed"))) {
		LOVadv($item[LOV Earrings], $effect[Wandering Eye Surgery], $item[LOV Echinacea Bouquet]);
	}
}



int totalSausagesToMake() {
	// 	int sausagesToMake = kSausagesToEat + 2;
	// 	sausagesToMake = min(sausagesToMake, get_property("_sausageFights").to_int() + 11); // right now we have a lot of spare sausages, save casings
	// 	fullAcquire(sausagesToMake, $item[magical sausage casing]);
	// 	return min(sausagesToMake, available_amount($item[magical sausage casing]));
	return 25;
}

int sausagesToMake() {
	// want to make (collected casings - 2) sausages each day
	// int sausagesToMake = (kSausagesToGet - 2) - to_int(get_property("_sausagesMade"));
	// sausagesToMake = min(sausagesToMake, to_int(get_property("_sausageFights")) - 2);

	// we're now getting more than 23 (which is the max eatable/day), make all 23 plus some extra for the display case
	return totalSausagesToMake() - to_int(get_property("_sausagesMade"));
}

// return the number of sausages we can theoretically eat if we had the sausages
// if doNotOvereat is true, will limit the number returned to a number that won't make us overeat
int sausagesToEat(boolean doNotOvereat) {
	int sausagesToEat = 23 - to_int(get_property("_sausagesEaten"));
	if (doNotOvereat) { // make sure we don't eat so much that we lose adv at rollover
		int adventuresAtRollover = myAdventuresAtRollover();
		return min(sausagesToEat, 200 - adventuresAtRollover);
	} else
		return sausagesToEat;
}

int sausagesToEat() {
	return sausagesToEat(false);
}



// adventures good_night_adv will spend while overdrunk (smmUtils' goodNightAdvTurns,
// which is kept in step with good_night_adv below)
int drunkTurnsPending(boolean shouldPrint) {
	return goodNightAdvTurns(shouldPrint);
}

int drunkTurnsPending() {
	return drunkTurnsPending(true);
}


// given the current state of consumption (fullness, drunkenness, spleen), return the ideal
// number of adv to start end-of-day consumption so as to end near but not over 200 adv at rollover
// target is 5-10 advs shy of 200 to allow for variations in end-of-day consumption gain
int idealAdvToOverdrink() {
	if (!readyToOverdrink(true)) abort("we're not ready to overdrink");

	int drunkTurnsPending = drunkTurnsPending(true);

	int foodGains = 0; // TODO
	int drinkGains = 0; // TODO
	int chocolatesUsed = "_chocolatesUsed".get_property().to_int();
	int chocolateGains = chocolatesUsed == 3 ? 0 : chocolatesUsed == 2 ? 1 : chocolatesUsed == 1 ? 3 : 6;
	int tofuGains = ("_essentialTofuUsed".get_property().to_boolean() ? 0 : 5);
	int sausageGains = sausagesToEat(true);
	int licenseToChillGains = to_boolean(get_property("_licenseToChillUsed")) ? 0 : 5;
	int aug16Gains = ("_aug16Cast".get_property().to_boolean() ? 0 : gkFoodAdvGains);
	int mayamCalendarGains = "_mayamSymbolsUsed".get_property().contains_text("clock") ? 0 : 5;
	int spleenGains = round(kTurnsPerSpleen * (gkOverdrinkSpleenReduction + spleen_limit() - my_spleen_use()));
	int stooperGains = (isStooperPending() ? gkDrinkAdvGains : 0);
	int overdrinkGains = gkOverdrinkDrinkItem.inebriety * 6 * 1;
	int sneakyPeteGains = isSneakyPeteDay() ? (2 * (10 - 1 - gkOverdrinkDrinkItem.inebriety)) : 0;
	int rolloverGains = adventureGainAtRollover(true);

	int totalGains = foodGains + drinkGains
	   + chocolateGains + tofuGains + sausageGains + licenseToChillGains + aug16Gains + mayamCalendarGains
	   + spleenGains
	   + stooperGains + overdrinkGains + sneakyPeteGains
	   + rolloverGains;

	print("food gains: " + foodGains
	   + ", drink gains: " + drinkGains
	   + ", chocolate gains: " + chocolateGains
	   + ", tofu gains: " + tofuGains
       + ", magical sausage gains: " + sausageGains
       + ", license to chill gains: " + licenseToChillGains
	   + ", aug 16 gains: " + aug16Gains
	   + ", Mayam calendar gains: " + mayamCalendarGains
	   + ", spleen gains: " + spleenGains
	   + ", stooper gains: " + stooperGains
	   + ", overdrink gains: " + overdrinkGains
	   + (isSneakyPeteDay() ? ", Sneaky Pete gains: " + sneakyPeteGains : "")
	   + ", rollover gains: " + rolloverGains
    );
	print("TOTAL GAINS: " + totalGains);
	print("GAINS - PENDING = " + (totalGains - drunkTurnsPending));

	int rval = 200 - totalGains + drunkTurnsPending;
	print("IDEAL ADV TO OVERDRINK AT: " + rval);

	return rval;
}



// -------------------------------------
// AUTOMATION -- GRINDING -- CLASS
// -------------------------------------

void grindSeal(item sealFigurine) {
	print("grindSeal: " + sealFigurine, "green");
	healAndRemoveDebuffsWithMPRestore();
	visit_url("/inv_use.php?checked=1&pwd&whichitem=" + to_int(sealFigurine), true, false);
	run_combat("skill Lunging Thrust-Smack;");
}

// #iseals #grind infernal seals #grindInfernalSeals
void grindSeals(item sealFigurine) {
	int [item] FigurineToCandlesMap = {
		$item[figurine of an ancient seal]:3,
		$item[figurine of a sleek seal]:3
	};

	burnMP();
	setDefaultMood();
	string famSelector = "default";
	automate_dressup($location[none], "item", famSelector, "+club, -equip Kramco Sausage-o-Matic&trade;, -equip \"i voted!\" sticker, -equip Everfull Dart Holster, -equip mafia thumb ring, -equip june cleaver");
	if (sealFigurine == $item[figurine of a sleek seal] && item_drop_modifier() < 186) {
		famSelector = "item";
		automate_dressup($location[none], "item", famSelector, "+club, -equip Kramco Sausage-o-Matic&trade;, -equip \"i voted!\" sticker, -equip Everfull Dart Holster, -equip mafia thumb ring");
	}

	// sanity checks
	if (sealFigurine == $item[figurine of a sleek seal] && item_drop_modifier() < 186) abort("not enough item drop to guarantee 35% drop");

	int candlesToBuy = FigurineToCandlesMap[sealFigurine] * infernalSealFights();
	fullAcquire($item[seal-blubber candle], candlesToBuy);

	while (infernalSealFights() > 0 && sealFigurine != $item[none]) {
		grindSeal(sealFigurine);
	}
}



// -------------------------------------
// AUTOMATION -- GRINDING -- IOTM
// -------------------------------------

void burnGodLobster() {
	int glFightsAvailable = 3 - to_int(get_property("_godLobsterFights"));
	if (glFightsAvailable <= 0) return;

	print("burnGodLobster, " + glFightsAvailable + " fights available", "green");

	while (glFightsAvailable > 0) {
		burnNextGodLobster();
		glFightsAvailable = 3 - to_int(get_property("_godLobsterFights"));
	}
}



void getCampAwayBuff() {
	visit_url("/place.php?whichplace=campaway&action=campaway_sky", true, false);
}

void burnCampAwayBuffs() {
	print("burnCampAwayBuffs", "green");
	int numberToDo = 4 - to_int(get_property("_campAwayCloudBuffs")) - to_int(get_property("_campAwaySmileBuffs"));
	if (numberToDo > 0)
		for i from 1 to numberToDo {
				getCampAwayBuff();
			}
}



// TODO conditional-ize this to make it faster
void burnBuffs() {
//	burn_kgb("item");
//	burnFortuneTeller("item", true, true, true); //  buffString, compatible1, compatible2, compatible3
	burnCampAwayBuffs();

	boolean unused = cli_execute("friars familiar");
	unused = cli_execute("telescope high");
	unused = cli_execute("use fishy pipe");
	unused = cli_execute("monorail"); // favoured by Lyle
	unused = cli_execute("mom stats");
	unused = cli_execute("swim laps");
	unused = cli_execute("ballpit");
	unused = cli_execute("pool aggressive, strategic, stylish");
	unused = cli_execute("shower cold");
	unused = cli_execute("spacegate vaccine 3");
	unused = cli_execute("cast incredible self-esteem");
	unused = cli_execute("daycare mysticality");
	unused = cli_execute("use circle drum");

	use_skill(3, $skill[Feel Disappointed]);
	use_skill(3, $skill[Feel Excitement]);
	use_skill(3, $skill[Feel Nervous]);
	use_skill(3, $skill[Feel Peaceful]);

    // visit Lyle with the candy cane sword for 10 turns of Peppermint Rush
    if (!"_candyCaneSwordLyle".get_property().to_boolean()) {
        equip($item[candy cane sword cane]);
        visit_url("/place.php?whichplace=monorail&action=monorail_lyle", true, false); // visit Lyle
        assert(have_effect($effect[Peppermint Rush]) >= 10, "burnBuffs: didn't get Peppermint Rush from Lyle");
    }

	if (canAugustSkill(24))
	    unused = use_skill(1, $skill[Aug. 24th: Waffle Day!]);
	if (!"_augTodayCast".get_property().to_boolean()) {
	    int dayOfMonth = today_to_string().substring(6).to_int();
	    assert(dayOfMonth > 0 && dayOfMonth < 32, "burnBuffs: didn't get today's date!");
	    unused = use_skill(1, to_skill("Aug. " + dayOfMonth));
	}
}



void burnPrismaticBeret() {
	maximize("equip Prismatic Beret", false); // more power = more meat

	use_skill(5, $skill[Beret Busking]);
}



void burnNuns() {
	print("burnNuns", "green");
	int do_it = 3 - to_int(get_property("nunsVisits"));
	maximize("mp", false);
	while (do_it > 0) {
		do_it--;
		burnMP(0);
		boolean unused = cli_execute("nuns");
	}
	burnMP();
}



void burnFreeRests() {
	print("burnFreeRests", "green");
	int do_it = total_free_rests() - to_int(get_property("timesRested"));
	burnMP();
	while (do_it > 0) {
		do_it--;
		cli_execute("camp rest");
	}
}



void burnFreeMP() {
	print("burnFreeMP", "green");

	maximize("mp", false);

	boolean eternalCarBatteryUsed = to_boolean(get_property("_eternalCarBatteryUsed"));
	int nunsVisitsAvailable = 3 - to_int(get_property("nunsVisits"));
	if (!to_boolean(get_property("sidequestNunsCompleted"))) nunsVisitsAvailable = 0;
	int campRestsAvailable = total_free_rests() - to_int(get_property("timesRested"));

	int tries = 3;
	while ((nunsVisitsAvailable > 0 || campRestsAvailable > 0 || !eternalCarBatteryUsed) && tries > 0) {
		while (nunsVisitsAvailable > 0 && my_maxmp() - my_mp() >= 1000) {
			nunsVisitsAvailable--;
			cli_execute("nuns");
			tries = 3;
		}

		while (campRestsAvailable > 0 && my_maxmp() - my_mp() >= 160) {
			campRestsAvailable--;
			cli_execute("camp rest");
			tries = 3;
		}

		if (!eternalCarBatteryUsed && my_maxmp() - my_mp() >= 55) {
			eternalCarBatteryUsed = use(1, $item[eternal car battery]);
			tries = 3;
		}

		burnMP(gUnrestrictedManaToSave);
		tries--;
	}
}



void burnSpleen() {
	print("burnSpleen", "green");
	// if i'm both overdrunk and the hippy stone is broken, don't burn spleen items: we're about to ascend
	if (!isOverdrunk() || !hippy_stone_broken()) {
		int spleenAvailable = spleen_limit() - my_spleen_use();
		//chew(spleenAvailable, $item[Knob Goblin pet-buffing spray]);
		chew(floor(spleenAvailable / 4.0), $item[agua de vida]);
		spleenAvailable = spleen_limit() - my_spleen_use();
		if (spleenAvailable > 0) print("WARNING: spleen available!!!!!!!!!!!!!!!!!!!!", "red");
	}
}



// should be called while overdrunk after dressing for rollover
// handles making up to 46 sausages
void burn_sausages(boolean doNotOvereat) {
	saveOutfit();
	int sausagesToMake = sausagesToMake();
	int sausagesToEat = sausagesToEat(doNotOvereat);
	int startingSausagesToEat = sausagesToEat;
	print("burn_sausages: doNotOvereat: " + doNotOvereat + ", making: " + sausagesToMake + ", eating: " + sausagesToEat, "green");

	try {
		// FIRST MAKE SAUSAGES
		if (sausagesToMake > 0 && smmMuseumMaySpendIngredients($item[magical sausage], sausagesToMake))
			if (!cli_execute("make " + sausagesToMake + " magical sausage"))
				abort("failed while MAKING sausages");
		// Museum: only eat sausages beyond the Display Case reserve
		sausagesToEat = min(sausagesToEat, max(0, smmMuseumOwnedCopies($item[magical sausage]) - smmMuseumReservedCopies($item[magical sausage])));

		// try to work around the user confirmation
		// 		set_property("_sausagesMade", "0");
		//
		// 		int sausagesMade = 0;
		// 		int tries = 0;
		// 		while (sausagesToMake > 0 || tries < 10) {
		// 			if (sausagesToMake > kMaxSausagesToEat)
		// 				sausagesToMake = kMaxSausagesToEat;
		//
		// 			if (!cli_execute("make " + sausagesToMake + " magical sausage"))
		// 				abort("failed while MAKING sausages");
		// 			sausagesMade += to_int(get_property("_sausagesMade"));
		// 			sausagesToMake = kSausagesToMake - sausagesMade;
		//
		// 			set_property("_sausagesMade", "0");
		// 			tries++;
		// 		}
		// 		set_property("_sausagesMade", sausagesMade + kSausagesPreviouslyMade);

		// THEN EAT SAUSAGES
		int adventuresAtRollover = myAdventuresAtRollover();
		if (sausagesToEat > 0 && !(isOverdrunk() && hippy_stone_broken())) { // if i'm both overdrunk and the hippy stone is broken, don't burn sausages: we're about to ascend
			maximize("mp", false);
			while (sausagesToEat > 0) {
				if (my_mp() + 999 > my_maxmp())
					burnMP(0);
				if (cli_execute("eat magical sausage"))
					sausagesToEat--;
				else
					abort("failed while EATING sausages");
			}

		} else if (sausagesToEat > 0) {
			print("NOT EATING sausages due to being overdrunk AND in PVP (which usually means we're about to ascend, so no reason for extra turns)", "orange");
		}

	} finally {
		burnMP();
		if (!restoreOutfit())
			print("burn_sausages: COULD NOT RESTORE EQUIPPED SET!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!", "red");
		print((startingSausagesToEat - sausagesToEat) + " sausages eaten, total eaten: " + get_property("_sausagesEaten") + " of 23", "green");
	}
}

void burn_sausages() {
	burn_sausages(true);
}



// fight the default monsters #combatlocket #combat lover's locket #combat locket
void burnCombatLoversLocketPickpocketHelper(monster foe) {
	int polarVortexUses = get_property("_fireExtinguisherCharge").to_int() / 10;
	int douseFoeUses = 3 - get_property("_douseFoeUses").to_int();
	if (polarVortexUses > 0 && cllNumMonstersFought() < 3 && !cllHasFought(foe)) {
		automate_dressup($location[none], "item", "xo skeleton", "0.5 meat, "
			+ (polarVortexUses > 0 ? "equip industrial fire extinguisher, " : "")
			+ (douseFoeUses > 0 ? "equip Flash Liquidizer Ultra Dousing Accessory, " : "")
			+ "-equip Kramco Sausage-o-Matic&trade;, -equip \"i voted!\" sticker, -equip mafia thumb ring");
		healAndRemoveDebuffsWithMPRestore();
		restore_mp(80);
		string cllPage = cllGetToFight(foe);

		string pvScript = polarVortexUses > 0 ? "if !times " + polarVortexUses + ";skill Fire Extinguisher: Polar Vortex;call pv;endif;" : "";
		string dfScript = douseFoeUses > 0 ? "skill Douse Foe;" : "";
		customScriptWithDefaultKill(current_round(), foe, cllPage,
			"skill Hugs and Kisses!;" + dfScript + "sub pv;" + pvScript + "endsub;call pv;");
		postAdventure();
	}
}

void burnCombatLoversLocketItemDropHelper(monster foe) {
	int feelNostalgicUses = 3 - "_feelNostalgicUsed".get_property().to_int();
	string feelNostalgicString = feelNostalgicUses > 0 ? "skill Feel Nostalgic;" : "";
	if (!cllHasFought(foe)) {
		automate_dressup($location[none], "item", "item", "0.5 meat, -equip Kramco Sausage-o-Matic&trade;, -equip \"i voted!\" sticker");
		healAndRemoveDebuffsWithMPRestore();
		restore_mp(80);
		string cllPage = cllGetToFight(foe);
		customScriptWithDefaultKill(current_round(), last_monster(), cllPage, feelNostalgicString);
		postAdventure();
	}
}

void burnCombatLoversLocket() {
	print("burnCombatLoversLocket", "green");
	if (cllNumMonstersFought() >= 3) {
		print("no Combat Lover's Locket charges remaining!", "green");
		return;
	}

	setCurrentMood("meat");
	monster ppFight1 = $monster[four-shadowed mime]; // pickpocket: four-shadowed mime, stomper stomping, superdupervirus, T-9000, Z-Rex, damned dirty ape, official seal, ghastly organist, possessed eyewashing station -- stomper stomping seems to die before we can use all Polar Vortexes
	monster ppFight2 = $monster[stomper stomping]; // if we don't use up all the polar vortex charges

	monster itemFight1 = $monster[super-sized Cola Wars soldier]; // +item: menacing lawn gnome, Red Fox? for glove (which might not drop), Mrs. K, the Chemistry Teacher, bow-making mummy, wastoid, sexy sorority ghost
	monster itemFight2 = $monster[Red Fox]; // +item
	if (my_class() == $class[Accordion Thief]) {
		itemFight1 = $monster[lively Cajun accordionist];
		itemFight2 = $monster[quirky indie-rock accordionist];
	}

	monster roboFight = $monster[Ribbon-Cutting Elfborg]; // robortender, do last... Ribbon-Cutting Elfborg, Arc-Welding Elfborg, Weapons-Assembly Elfborg, Decal-Applying Elfborg

	// PICKPOCKET
	burnCombatLoversLocketPickpocketHelper(ppFight1);
	burnCombatLoversLocketPickpocketHelper(ppFight2);

	// ITEM DROP: if we've already used up the Polar Vortex, we haven't done any fights yet, so start us off
	if (cllNumMonstersFought() < 2)
		burnCombatLoversLocketItemDropHelper(itemFight1);
	if (cllNumMonstersFought() < 2)
		burnCombatLoversLocketItemDropHelper(itemFight2);

	// ROBORTENDER -- leaves locket bonuses as +candy
	int feelNostalgicUses = 3 - "_feelNostalgicUsed".get_property().to_int();
	string feelNostalgicString = feelNostalgicUses > 0 ? "skill Feel Nostalgic;" : "";
	if (cllNumMonstersFought() < 3 && !cllHasFought(roboFight)) {
		automate_dressup($location[none], "item", "robortender", "0.5 meat, -equip Kramco Sausage-o-Matic&trade;, -equip \"i voted!\" sticker, -equip mafia thumb ring");
		healAndRemoveDebuffsWithMPRestore();
		restore_mp(80);
		string cllPage = cllGetToFight(roboFight);
		customScriptWithDefaultKill(current_round(), last_monster(), cllPage, feelNostalgicString);
		postAdventure();
	}

	if ("_feelNostalgicUsed".get_property().to_int() < 3 && cllNumMonstersFought() >= 3)
		kNostalgiaNextCombatKey.set_property("true");


	// crimbylow
	// bow-making mummy
	// gingerbread maw
	// Knob Goblin Embezzler meat
	// ice conceirge for bag of foreign bribes
	// swarm of scarab beatles for mojo filter
}



// burn free turns granted from items/skills
// can be used overdrunk if we're able to get into a combat while overdrunk (such as with drum machines)
void burnInstaKill() {
	print("burnInstaKill", "green");
	assert(my_adventures() > 0, "we have insta-kills but we can't insta-kill without any turns!");

	// a drum machine fight without a free kill costs a turn and the drum machine, so make sure we
	// actually have a free-kill skill before using one
	PrioritySkillRecord instaKillSkill = chooseInstaKillSkill();
	assert(instaKillSkill.theSkill != $skill[none], "burnInstaKill: no free-kill skill available, not using a drum machine");

	automate_dressup($location[none], "item", "item", "-equip \"i voted!\" sticker, -equip Kramco Sausage-o-Matic&trade;, -equip Everfull Dart Holster, -equip mafia thumb ring");
	if (instaKillSkill.theItem != $item[none]) {
		fullAcquire(instaKillSkill.theItem);
		dressup("equip " + instaKillSkill.theItem);
		assert(equipped_amount(instaKillSkill.theItem) > 0, "burnInstaKill: couldn't equip " + instaKillSkill.theItem + " for " + instaKillSkill.theSkill + ", not using a drum machine");
	}

	fullAcquire($item[drum machine]);
	advURL("/inv_use.php?pwd&which=3&whichitem=2328", true, false);
// 	run_combat("pickpocket; pickpocket; skill " + instaKillSkill.theSkill);
	instaKill();
	postAdventure();
}

void burnInstaKills() {
	print("burnInstaKills", "green");
	PrioritySkillRecord instaKillSkill = chooseInstaKillSkill();

	if (instaKillSkill.theSkill == $skill[none]) {
		print("no insta-kill skills left", "blue");
		return;
	}
	if (my_adventures() == 0)
		abort("we have insta-kills but we can't insta-kill without any turns!");

	if (instaKillSkill.theSkill != $skill[none])
		automate_dressup($location[none], "item", "item", "-equip \"i voted!\" sticker");
	int tries = 3;
	while (instaKillSkill.theSkill != $skill[none] && tries > 0) {
		if (instaKillSkill.theItem != $item[none]) {
			fullAcquire(instaKillSkill.theItem);
			dressup("equip " + instaKillSkill.theItem);
		}
		fullAcquire($item[drum machine]);
		advURL("/inv_use.php?pwd&which=3&whichitem=2328", true, false);
		run_combat("pickpocket; pickpocket; skill " + instaKillSkill.theSkill); postAdventure();
		instaKillSkill = chooseInstaKillSkill();
	}
}



// burn all 0-turn combats: science, tentacle, god lobster, glitch season reward, mushroom garden
void burnFreeCombats() {
	print("burnFreeCombats", "green");

	while (freeCombatsAvailable() > 0) {
		AdventureRecord ar = chooseFreeCombat();
		anyAdventure(ar);
	}

// 	grindGlitchSeasonReward();
// 	burnGodLobster();
// 	grindScience(false); // use synthesis?
// 	// 	grindMushroomGarden(false); // this must be run when not overdrunk, but we don't know if we're ascending yet, so don't normally run it here
// 	grindMolehillMountain();

	// seal clubber fights
	if (my_class() == $class[seal clubber]) {
		while (infernalSealFights() > 0) {
			if (available_amount($item[figurine of a sleek seal]) >= infernalSealFights())
				grindSeals($item[figurine of a sleek seal]);
			else {
				fullAcquire($item[figurine of an ancient seal], infernalSealFights());
				grindSeals($item[figurine of an ancient seal]);
			}
		}
	}
}



void burnFreeUseItems() {
	boolean unused;

	while (get_property("_genieWishesUsed").to_int() < 3)
		burnGenieWishes($item[none], "pony");

	while ("_monkeyPawWishesUsed".get_property().to_int() < 5) {
		cli_execute("monkeypaw effect Frosty");
// 		if (gnomads_available())
// 			cli_execute("monkeypaw item clockwork key");
// 		else if (knoll_available())
// 			cli_execute("monkeypaw item software glitch");
// 		else
// 			cli_execute("monkeypaw item mojo filter");
	}

	if (!get_property("_defectiveTokenUsed").to_boolean())
		use($item[defective Game Grid token], 1);

	// TODO burn Strange Stalagmite

	burnFreeCombs(0);

	burnLicenseToChill();

    burnMayamCalendar(false);

	burnPrismaticBeret();

	if ( ! "expressCardUsed".get_property().to_boolean()) {
		defaultZap();
		burnMP(0);
		maximize("mp", false);
		use(1, $item[Platinum Yendorian Express Card]); // Extends the duration of all current effects by 5 adventures, restores all MP, and cools zap wands
	}
	defaultZap();

	unused = cli_execute("teatree cuppa Sobrie tea");

	if (!get_property("_cargoPocketEmptied").to_boolean())
		cli_execute("cargo " + bestCargoPocket());

	// Spend 2002 Mr. Store credits TODO sniff best and buy that catalogueEconomics
	int availableMrStore2002Credits = "availableMrStore2002Credits".get_property().to_int();
	if (availableMrStore2002Credits >= 1)
		for i from 1 to availableMrStore2002Credits
			cli_execute("coinmaster buy 2002 crimbo cookie sheet");
}



// trigger a spikolodon sneak by using a free kill and/or insta kill. #spikolodon spikes
// will change outfits TODO which outfit is best for each free combat?
void spikolodonSneak() {
	int spikolodonUsesBefore = spikolodonSpikesUsed();

	automate_dressup($location[none], "mainstat", "default", "10 item, equip Jurassic Parka");
	cli_execute("parka spikolodon");
	set_property("_smm.kSpikolodonNextCombat", "true");
	healIfRequiredWithMPRestore();

	// trigger spikes on free combats
	if (spikolodonSpikesUsed() < 5 && freeCombatsAvailable() > 0) {
		AdventureRecord ar = chooseFreeCombat();
		print("using free combat " + ar.toString() + " to trigger spikolodon spikes", "green");
		anyAdventure(ar);

	} else if (spikolodonSpikesUsed() < 5 && instaKillsAvailable() > 0) {
		print("using instakill to trigger spikolodon spikes", "green");
		burnInstaKill();
	}

	assert(spikolodonSpikesUsed() > spikolodonUsesBefore, "spikolodonSneak: uses didn't increase");
	assert(!inCombat(), "spikolodonSneak: we're still in combat");
	assert(!handling_choice(), "spikolodonSneak: we're handling a choice");
}



// # Oliver's Place
void grindOliversPlace(int turnsToGrind, int maxPerTurnCost) {
	print("grindOliversPlace", "green");

// 	automate_dressup($location[An Unusually Quiet Barroom Brawl], "item", "default", "0.5 meat");
//
// 	while (turnsToGrind > 0) {
// 		healAndRemoveDebuffsWithMPRestore();
// 		dressup();
// 		redirectAdventure($location[An Unusually Quiet Barroom Brawl], "");
//
// 		turnsToGrind--;
// 	}

	grindMeatWithItemDrop($location[An Unusually Quiet Barroom Brawl], monster [] {}, turnsToGrind, maxPerTurnCost, "-equip \"i voted!\" sticker, -equip Kramco Sausage-o-Matic&trade;, -equip Everfull Dart Holster, -equip mafia thumb ring");
}


void grindFreeOliversPlace() {
	int turnsToGrind = 3 - "_speakeasyFreeFights".get_property().to_int();
	if (turnsToGrind > 0)
		grindOliversPlace(turnsToGrind, 0);
}



void getDolphinItemWithDressup() {
	automate_dressup($location[none], "item", "item", "mp regen");

	cli_execute("use dolphin whistle");
}


void grindDolphinItem() {
	item dolphinItem = get_property("dolphinItem").to_item();
	assert(dolphinItem != $item[none], "no dolphinItem to grind");
	print("grindDolphinItem: " + dolphinItem, "green");

	int meatValue = dolphinItem.current_price();
	// a copy the Display Case is known to still need is worth the turn whatever its price
	boolean [item] dolphinItems;
	dolphinItems[dolphinItem] = true;
	boolean museumNeedsIt = museumShortfall(dolphinItems) > 0;
	if (meatValue < kTurnValue && !museumNeedsIt) {
		print("... skipping, meat value too low @ " + meatValue + " and the Museum doesn't need it", "green");
		return;
	}

	if (!get_property("_smm.ShouldUseDolphinWhistleQueryDone").to_boolean()
		&& dailyGrindConfirm("dolphin", "Use dolphin whistle for dolphinItem: " + dolphinItem + ", price: " + meatValue + (museumNeedsIt ? " (Museum needs it)" : ""), true)) {
		getDolphinItemWithDressup();
	}
	set_property("_smm.ShouldUseDolphinWhistleQueryDone", "true");
}



void prepForRufusAndTheShadowRifts(int turns, location advLocation) {
	setDefaultMood();

	string maxString = "-equip aerogel attache case, -equip \"i voted!\" sticker, -equip Kramco Sausage-o-Matic&trade;, -equip Everfull Dart Holster, -equip mafia thumb ring";
	maxString = maxStringForLocation(advLocation, maxString);
	automate_dressup(advLocation, "item", "item", maxString);
}


string runRufusTurn(string pageString, string scriptString) {
// 	boolean [monster] shadowBosses = {$monster[shadow cauldron] : true, $monster[shadow matrix] : true, $monster[shadow orrery] : true, $monster[shadow scythe] : true, $monster[shadow spire] : true, $monster[shadow tongue] : true, };
// 	if (inCombat() && shadowBosses contains last_monster())
// 		abort("boss!");
//
	return runTurn(pageString, scriptString);
}

void grindRufusAndTheShadowRifts(int turns, location advLocation) {
	print("grindRufusAndTheShadowRifts " + advLocation + " for " + turns + " turns", "green");
	assert(questStage("questRufus") >= 0, "Rufus quest isn't started!");

    prepForRufusAndTheShadowRifts(turns, advLocation);

	saveAndSetProperty("hpAutoRecovery", "0.05"); // we need everything for the bosses, at least after many boss kills.
	saveAndSetProperty("hpAutoRecoveryTarget", "1.0");

	try {
        healIfRequiredWithMPRestore();
		redirectAdventure(advLocation, turns, "", "runRufusTurn");

	} finally {
		restoreSavedProperty("hpAutoRecovery");
		restoreSavedProperty("hpAutoRecoveryTarget");
	}
}

void grindRufusAndTheShadowRifts(int turns) {
	location advLocation = shadowEconomics(false)[0]; // false = don't print
	grindRufusAndTheShadowRifts(turns, advLocation);
}



void useRufusLodestone() {
	print("useLodestone", "green");
	assert(have_item($item[Rufus's shadow lodestone]), "no lodestone!");
	assert(!inCombat() && !in_multi_fight(), "we're in combat!");
	assert(!handling_choice(), "we're in a choice!");

	boolean shouldLootShadowForest = !"_shadowForestLooted".get_property().to_boolean();
	location advLocation = shadowEconomics(false)[0]; // false = don't print

	string maxString = maxStringForLocation(advLocation, "");
	if (maxString != "")
		maximize(maxString + ", -tie", false); // -tie should make it only change the minimum required to satisfy the max string

	if (shouldLootShadowForest) {
		advURL(advLocation);
		run_choice(3);
	} else {
		advURL(advLocation);
		run_choice(2);
	}
}



void grindRufusAndTheShadowRiftsForFreeHelper() {
	// postadv should return the quest
	if (have_item($item[Rufus's shadow lodestone]))
		useRufusLodestone();

	if (questStage("questRufus") < 0)
		getRufusQuest(1);

	while (have_effect($effect[Shadow Affinity]) > 0) {
		grindRufusAndTheShadowRifts(have_effect($effect[Shadow Affinity]));
		if (have_item($item[Rufus's shadow lodestone]))
			grindRufusAndTheShadowRiftsForFreeHelper();
	}
}

int avalanchesUsed() {
	return get_property("_mcHugeLargeAvalancheUses").to_int();
}

// Spikes and Avalanches need a fight to be cast in. Once the free fights and
// free kills are gone, one paid Shadow Rift fight still pays for itself: the
// noncombat it forces finishes a Rufus quest, and the lodestone gives about
// 11 free Rift fights. smm.forcedNC.paidTurns=false turns this off.
boolean forcedNcPaidFightAllowed() {
	return get_property("smm.forcedNC.paidTurns") != "false" && my_adventures() > 0 && my_inebriety() <= inebriety_limit();
}

// One paid Rift fight with the given key set (the consult script casts the
// skill and clears it), then the forced noncombat and the free Rift fights.
// Returns false when the skill was not cast.
boolean forcedNcPaidFight(string key, string what, int usedBefore, string usesPref) {
	print("no free fight left: using a paid Shadow Rift fight to cast " + what, "green");
	set_property(key, "true");
	try {
		grindRufusAndTheShadowRifts(1);
	} finally {
		set_property(key, "false");
	}
	if (get_property(usesPref).to_int() <= usedBefore) {
		print("grindRufusAndTheShadowRiftsForFree: " + what + " was not cast in the paid fight, so the rest are left", "orange");
		return false;
	}
	grindRufusAndTheShadowRifts(1); // should be the boss
	grindRufusAndTheShadowRiftsForFreeHelper();
	return true;
}

// Forced noncombats aimed somewhere better than the Shadow Rift. Set
// smm.forcedNC.targets to entries separated by |, best first, each
//   location;choice number=option;times a day
// for example "The Haunted Billiards Room;choice 875=1;1". Each one casts a
// Fiesta Exit (resting for Cinch as needed) and adventures once there with
// that choice answered. What is left goes to the Rift.
record ForcedNcTarget {
	location where;
	int choice;
	int option;
	int perDay;
};

// An entry's problem, "" when it is usable.
string forcedNcTargetProblem(ForcedNcTarget t) {
	if (t.where == $location[none]) return "unknown location";
	if (t.choice <= 0 || t.option <= 0) return "needs 'choice N=option'";
	if (t.perDay <= 0) return "needs a number of times a day";
	return "";
}

string forcedNcTrim(string text) {
	matcher m = create_matcher("^\\s*(.*?)\\s*$", text);
	return m.find() ? m.group(1) : text;
}

ForcedNcTarget parseForcedNcTarget(string entry) {
	ForcedNcTarget t;
	string [int] parts = entry.split_string(";");
	if (count(parts) < 3) return t;
	t.where = forcedNcTrim(parts[0]).to_location();
	matcher m = create_matcher("^\\s*choice\\s*(\\d+)\\s*=\\s*(\\d+)\\s*$", parts[1]);
	if (m.find()) {
		t.choice = m.group(1).to_int();
		t.option = m.group(2).to_int();
	}
	string times = forcedNcTrim(parts[2]);
	t.perDay = times.is_integer() ? times.to_int() : 0;
	return t;
}

void forcedNcTargets() {
	string list = get_property("smm.forcedNC.targets");
	if (list == "") return;
	foreach i, entry in list.split_string("\\|") {
		if (forcedNcTrim(entry) == "") continue;
		ForcedNcTarget t = parseForcedNcTarget(entry);
		string problem = forcedNcTargetProblem(t);
		if (problem != "") {
			print("smm.forcedNC.targets: '" + entry + "' skipped: " + problem, "red");
			continue;
		}
		string doneKey = "_smm.forcedNC.done." + i;
		while (get_property(doneKey).to_int() < t.perDay && readyCinch(60)) {
			string key = "choiceAdventure" + t.choice;
			string before = get_property(key);
			set_property(key, t.option.to_string());
			try {
				use_skill($skill[Cincho: Fiesta Exit]);
				healIfRequiredWithMPRestore();
				boolean unused = adv1(t.where, -1, "");
			} finally {
				set_property(key, before);
			}
			set_property(doneKey, (get_property(doneKey).to_int() + 1).to_string());
			print("forced noncombat at " + t.where + " (choice " + t.choice + ", option " + t.option + "): last choice was " + last_choice(), "blue");
			equip($item[Cincho de Mayo]);
		}
	}
}

void grindRufusAndTheShadowRiftsForFree() {
	print("grindRufusAndTheShadowRiftsForFree: " + (5 - spikolodonSpikesUsed()) + " spikolodon spikes available and " + cinchUsed() + " cinch used with " + cinchRestsUsed() + " cinch rests used and " + total_free_rests() + " total free rests", "green");

	// FIRST, make sure we are in a known state with the quest started, no lodestone, and no Shadow Affinity buff
	grindRufusAndTheShadowRiftsForFreeHelper();

	assert(!have_item($item[Rufus's shadow lodestone]), "grindRufusAndTheShadowRiftsForFree: we haven't cashed in the lodestone!");
	assert(questStage("questRufus") == 0, "grindRufusAndTheShadowRiftsForFree: before checking for shadow affinity: we haven't started the quest!");

	assert(have_effect($effect[Shadow Affinity]) == 0, "grindRufusAndTheShadowRiftsForFree: we haven't spent all turns of Shadow Affinity!");
	assert(questStage("questRufus") == 0, "grindRufusAndTheShadowRiftsForFree: we haven't started the quest!");

	// SPIKOLODON SPIKES
	// trigger spikes on free combats
	while (spikolodonSpikesUsed() < 5 && freeCombatsAvailable() > 0 && questStage("questRufus") == 0) {
		set_property("_smm.kSpikolodonNextCombat", "true");
		AdventureRecord ar = chooseFreeCombat();
		print("using free combat " + ar.toString() + " to trigger spikolodon spikes", "green");

		healIfRequiredWithMPRestore();
		anyAdventure(ar);

		grindRufusAndTheShadowRifts(1); // should be the boss
		grindRufusAndTheShadowRiftsForFreeHelper();

		assert(questStage("questRufus") == 0, "grindRufusAndTheShadowRiftsForFree: Spikes on free combats: we haven't started the quest!");
	}

	// trigger any remaining spikes on instakills
	while (spikolodonSpikesUsed() < 5 && instaKillsAvailable() > 0 && questStage("questRufus") == 0) {
		set_property("_smm.kSpikolodonNextCombat", "true");
		print("using instakill to trigger spikolodon spikes", "green");
		burnInstaKill();
		grindRufusAndTheShadowRifts(1); // should be the boss
		grindRufusAndTheShadowRiftsForFreeHelper();

		assert(questStage("questRufus") == 0, "grindRufusAndTheShadowRiftsForFree: Spikes on Instakills: we haven't started the quest!");
	}

	set_property("_smm.kSpikolodonNextCombat", "false");

	// then paid fights
	while (spikolodonSpikesUsed() < 5 && questStage("questRufus") == 0 && forcedNcPaidFightAllowed()) {
		if (!forcedNcPaidFight("_smm.kSpikolodonNextCombat", "spikolodon spikes", spikolodonSpikesUsed(), "_spikolodonSpikeUses")) break;
	}

	// McHUGELARGE AVALANCHE: 3 a day, cast in a fight like the spikes, forces the next noncombat
	boolean haveSki = available_amount($item[McHugeLarge left ski]) > 0;
	while (haveSki && avalanchesUsed() < 3 && (freeCombatsAvailable() > 0 || instaKillsAvailable() > 0) && questStage("questRufus") == 0) {
		int before = avalanchesUsed();
		set_property(kAvalancheNextCombatKey, "true");
		if (freeCombatsAvailable() > 0) {
			AdventureRecord ar = chooseFreeCombat();
			print("using free combat " + ar.toString() + " to cast McHugeLarge Avalanche", "green");
			healIfRequiredWithMPRestore();
			anyAdventure(ar);
		} else {
			print("using instakill to cast McHugeLarge Avalanche", "green");
			burnInstaKill();
		}
		set_property(kAvalancheNextCombatKey, "false");
		if (avalanchesUsed() <= before) {
			print("grindRufusAndTheShadowRiftsForFree: McHugeLarge Avalanche was not cast, so the rest are left", "orange");
			break;
		}
		grindRufusAndTheShadowRifts(1); // should be the boss
		grindRufusAndTheShadowRiftsForFreeHelper();
		assert(questStage("questRufus") == 0, "grindRufusAndTheShadowRiftsForFree: Avalanche: we haven't started the quest!");
	}
	while (haveSki && avalanchesUsed() < 3 && questStage("questRufus") == 0 && forcedNcPaidFightAllowed()) {
		if (!forcedNcPaidFight(kAvalancheNextCombatKey, "McHugeLarge Avalanche", avalanchesUsed(), "_mcHugeLargeAvalancheUses")) break;
	}

	// running out of free combats and free kills before the spikes is normal; leftover spikes are a
	// missed opportunity, not a reason to abort the rest of the free Rufus/Cincho work and the day
	cprint(spikolodonSpikesUsed() < 5, "grindRufusAndTheShadowRiftsForFree: " + (5 - spikolodonSpikesUsed()) + " spikolodon spikes left unused: no free combats (" + freeCombatsAvailable() + ") or free kills (" + instaKillsAvailable() + ") left to trigger them, and no paid fight (smm.forcedNC.paidTurns, adventures, sobriety)", "orange");


	// CINCHO DE MAYO: first the day's chosen targets, then the Rift
	equip($item[Cincho de Mayo]);
	forcedNcTargets();
	equip($item[Cincho de Mayo]);
	while (readyCinch(60) && questStage("questRufus") == 0) {
		use_skill($skill[Cincho: Fiesta Exit]);
		grindRufusAndTheShadowRifts(1); // should be the boss
		grindRufusAndTheShadowRiftsForFreeHelper();

		equip($item[Cincho de Mayo]);
		assert(questStage("questRufus") == 0, "grindRufusAndTheShadowRiftsForFree at Cincho: we haven't started the quest!");
	}

	cprint(cinchUsed() <= 40 || cinchRestsUsed() < 3, "exiting grindRufusAndTheShadowRiftsForFree with: " + cinchUsed() + " cinch and " + cinchRestsUsed() + " cinch rests used", "orange");
}



void beforeOverdrunkGoodNight() {
	stockStore(gkStoreHeartbeat);

	if (get_property("dolphinItem") != "") {
		grindDolphinItem();
	}

	if (smmIREnabled() && !inRonin() && my_path()==$path[none])
		smmIRDailyRoute(true,true);
	else if (my_garden_type() == "mushroom")
		grindMushroomGarden(false); // false=fertilize (will auto-pick on max growth)
	grindFreeOliversPlace();
	grindRufusAndTheShadowRiftsForFree();
}


// Adventures that would still pass the rollover cap go to the best way of spending them while
// overdrunk (smmUtils' overdrunkSinks: trick-or-treating on Hallowe'en, garbo with Drunkula's
// wineglass, the Beach Comb). Rollover is counted with the best adventure gear, as diet.js does.
void burnOverdrunkExcess() {
	if (my_inebriety() <= inebriety_limit()) return; // only after the nightcap
	int excess = my_adventures() + adventureGainAtRollover(true) - 200;
	print("burnOverdrunkExcess: " + max(0, excess) + " adventures would pass 200 at rollover", "green");
	foreach i, sink in overdrunkSinks() {
		if (excess <= 0) break;
		if (sink.value <= 0) continue;
		int amount = sink.name == "trick-or-treating" ? excess / 5 : excess; // ~5 adventures a block
		if (amount <= 0) continue;
		// combo counts combs, including the remaining free daily walks.
		if (sink.name == "Beach Comb") amount += max(0, 11 - get_property("_freeBeachWalksUsed").to_int());
		int before = my_adventures();
		print("spending " + excess + " overdrunk adventures on " + sink.name + " (" + sink.value + " meat each)", "blue");
		if (!cli_execute(sink.how.replace_string("%d", amount.to_string())))
			print(sink.name + " failed, trying the next way", "orange");
		excess -= before - my_adventures();
	}
	cprint(excess > 0, excess + " adventures will still pass 200 at rollover: no way left to spend them overdrunk", "red");
}


// Every turn-costing fight that can be started while overdrunk (from an item or skill, not
// a zone), plus Boxing Daycare scavenging, then any adventures that would still pass the
// rollover cap. Run it after the nightcap: the adventures it needs are held back for it
// (diet.js plans the stop point with goodNightAdvTurns in smmUtils, which must count exactly
// what the fixed part spends). Each part is skipped when already used today, so it is safe
// to run again.
void good_night_adv() {
	int planned = goodNightAdvTurns(true);
	cprint(my_adventures() < planned, "good_night_adv: only " + my_adventures() + " adventures for " + planned + " planned", "orange");

	// the IoTM route's overdrunk pass: the locket fights it held back, valued for the Museum
	if (my_adventures() > 0 && smmIREnabled() && !inRonin() && my_path() == $path[none])
		smmIRDailyRoute(true, true);

	automate_dressup($location[none], "item", "item", "-equip \"i voted!\" sticker, -equip Kramco Sausage-o-Matic&trade;");

	// fax: whatever is in the fax machine (or already in inventory); leaves a fresh fax for tomorrow
	if (my_adventures() > 0 && !get_property("_photocopyUsed").to_boolean()
		&& (item_amount($item[photocopied monster]) > 0 || (get_clan_lounge() contains $item[deluxe fax machine])))
		burnFax(false);

	if (my_adventures() > 0)
		burn_timespinner();

	healAndRemoveDebuffsWithMPRestore();
	//burnGenieWishes($item[bag of foreign bribes], "ice concierge"); // get ponies for now if we don't otherwise use it
	if (my_adventures() > 0)
		burnCombatLoversLocket(); // reminiscences the route left

	burnScavengeDaycare(min(3, my_adventures()));

	burnOverdrunkExcess();
}



// if fillToMax is false, will only use (presumably larger sized) spleen items that are optimal in terms of cost per adv_turns, which may result in unused spleen.
// if fillToMax is true, will also use enough smaller-sized spleen items to fill spleen to max.
void tquillaFillSpleen(boolean fillToMax) {
	museumSafeChew(floor((spleen_limit() - my_spleen_use()) / kSpleenItem.spleen), kSpleenItem);
	if (spleen_limit() - my_spleen_use() >= kSpleenItem.spleen) abort("something wrong with spleen");
	if (fillToMax) {
		museumSafeChew(spleen_limit() - my_spleen_use(), kFillerSpleenItem);
	}
}


// will raise if it can't eat the pre-eat item (assuming there is one) and returns false if it wasn't able to eat numberToEat of foodItem
boolean tquillaEat(item foodItem, int spleenReduction, int numberToEat, item preeatItem) {
	int kDaysOfEats = 20;

	// sanity checks
	assert(foodItem != $item[none], "tquillaEat: no food item");
	assert(numberToEat >= 1, "tquillaEat: number to eat is 0 or less?");
	assert( ! ($items[gnat lasagna, long pork lasagna, fishy fish lasagna] contains foodItem) || (have_effect($effect[Gar-ish]) > 0 && !isMonday()), "need Gar-ish and NOT Monday if we're going to eat a lasagna");

	// do we have enough capacity available?
	assert(fullness_limit() - my_fullness() >= foodItem.fullness * numberToEat, "tquillaEat: we're too full, we can't eat " + numberToEat + " of " + foodItem);
	assert(my_spleen_use() >= (spleenReduction * numberToEat), "tquillaEat: not enough spleen use, eating will reduce spleen by " + (spleenReduction * numberToEat));

	// ACQUIRE ensure we have everything -- we should have acquired before we entered this function
// 	assert(retrieve_item(numberToEat, foodItem), "tquillaEat: couldn't retrieve enough " + foodItem);
// 	assert(retrieve_item(numberToEat, $item[Special Seasoning]), "tquillaEat: couldn't retrieve enough Special Seasoning");
// 	checkIfRunningOut(foodItem, (fullness_limit() * kDaysOfEats) / foodItem.fullness);
// 	checkIfRunningOut($item[Special Seasoning], (fullness_limit() * kDaysOfEats) / foodItem.fullness);

	if (preeatItem != $item[none]) {
		assert(retrieve_item(numberToEat, preeatItem), "tquillaEat: couldn't retrieve enough " + preeatItem);
		checkIfRunningOut(preeatItem, (fullness_limit() * kDaysOfEats) / foodItem.fullness);
	}

	// EAT
	useMoMifNeeded();
	if (preeatItem != $item[none])
		assert( museumSafeEat(numberToEat, preeatItem), "was not able to successfully eat the pre-eating item " + preeatItem);
	return museumSafeEat(numberToEat, foodItem);
}


// tries to fill our stomach -- tightly coupled to the food data at the top of the file. Any change there will likely require a change here.
void tquillaEats(boolean drippyEats, boolean refillSpleen) {
	int kAffirmationCookieMaxCost = 12899; // not sure when they become worth it... https://www.lethe.xyz/kol/diets.php indicates this is a good start
	int startingMeat = my_meat();
	int startingAdv = my_adventures();
	boolean ateAffirmationCookie = false;
	boolean ateDrippyNugget = false;
	int [item] receipt;
	int stomachSpace = fullness_limit() - my_fullness();

	assert(stomachSpace < 3 || available_amount($item[astral hot dog]) == 0, "we have astral hot dogs leftover, we should eat those manually first");

	// AFFIRMATION COOKIE
	if ( ! "_affirmationCookieEaten".get_property().to_boolean()
		&& mall_price($item[affirmation cookie]) < kTurnValue * 3
		&& stomachSpace >= 1) {
		if (preferNewAcquire($item[affirmation cookie], 1, kAffirmationCookieMaxCost) >= 1) {
			ateAffirmationCookie = tquillaEat($item[affirmation cookie], 0, 1, $item[none]);
			if (ateAffirmationCookie)
				receipt[$item[affirmation cookie]] = 1;
		}
	}

	// DRIPPY NUGGET
	stomachSpace = fullness_limit() - my_fullness();
	if (drippyEats && ! get_property("_drippyNuggetUsed").to_boolean() && stomachSpace >= 5
		&& (gameday_to_string() != "Porktober 8" && !today_to_string().contains_text("1031"))) { // not on halloween
		(fullAcquire($item[drippy nugget], 1, 9000) >= 1).assert("tquillaEat: wasn't able to acquire a drippy nugget");
		ateDrippyNugget = tquillaEat($item[drippy nugget], 0, 1, $item[none]);
		if (ateDrippyNugget)
			receipt[$item[drippy nugget]] = 1;
	}

	// MAIN COURSE
	if (refillSpleen)
		tquillaFillSpleen(false); // false = don't use smaller spleen items to fill right to max

	stomachSpace = fullness_limit() - my_fullness();
	int numberToEat = floor(stomachSpace / gkFoodItem.fullness.to_float());
	if (numberToEat > 0) {
		if (gkPreeatItem != $item[none])
			(preferNewAcquire(gkPreeatItem, numberToEat, gkExpectedPreFoodCostPer) >= numberToEat).assert("tquillaEat: wasn't able to acquire " + gkPreeatItem);

		(preferExistingAcquire(gkFoodItem, numberToEat, gkExpectedFoodCostPer) >= numberToEat).assert("tquillaEat: wasn't able to acquire " + gkFoodItem);

		tquillaEat(gkFoodItem, gkEatSpleenReduction, numberToEat, gkPreeatItem).assert("tquillaEat: was not able to eat " + numberToEat + "X" + gkFoodItem);
		receipt[gkFoodItem] = numberToEat;

		if (refillSpleen)
			tquillaFillSpleen(false); // false = don't use smaller spleen items to fill right to max
	}

	// AUGUST SCEPTRE DAY 16
	if (canAugustSkill(16)) {
		assert(my_fullness() >= 1, "tquillaEats: we wanted to empty our stomach, but we have no fullness");
		use_skill($skill[Aug. 16th: Roller Coaster Day!]);
		tquillaEats(drippyEats, refillSpleen);
	}

	// FILLER
	stomachSpace = fullness_limit() - my_fullness();
	assert(stomachSpace <= gkFoodItem.fullness, "tquillaEat: we have enough capacity for another " + gkFoodItem);
	numberToEat = stomachSpace;
	if (numberToEat > 0) {
		(fullAcquire(gkFoodFillItem, numberToEat, gkExpectedFillFoodCostPer) >= numberToEat).assert("tquillaEat: wasn't able to acquire " + gkFoodItem);
		tquillaEat(gkFoodFillItem, 0, numberToEat, $item[none]).assert("tquillaEat: was not able to eat " + numberToEat + "X" + gkFoodFillItem);
		receipt[gkFoodFillItem] = numberToEat;
	}

	// SUMMARY
	int advGain = my_adventures() - startingAdv;
	int meatCost = startingMeat - my_meat();
	printReceipt(receipt);
	print("gained " + advGain + " at a cost of " + meatCost + " meat", "green");
}

void tquillaEats() {
	tquillaEats(true, true);
}



boolean kgSaveRoomForStillsuitSweat = true; // "familiarSweat".get_property().to_int() > 672 - kExpectedDailyTurns; // save 1 inebriety in case we want to use stillsuit sweat, 672=14 turns

// does all the checks required to drink something
// if drinking would reduce our pool skill, visit Oliver's Place before drinking
boolean tquillaDrink(item drinkItem, int spleenReduction, int numberToDrink, item preDrinkItem) {
	int myLimitWithoutStooper = inebriety_limit();
	if (kgSaveRoomForStillsuitSweat)
		myLimitWithoutStooper -= 2;
	if (my_familiar() == $familiar[Stooper]) myLimitWithoutStooper--; // we want the limit without the stooper
	if (drinkItem.inebriety == 1 && !get_property("_mimeArmyShotglassUsed").to_boolean()) myLimitWithoutStooper++;

	// sanity checks
	assert(drinkItem != $item[none], "tquillaDrink: no drink item");
	assert(numberToDrink >= 1, "tquillaDrink: number to eat is 0 or less?");
	assert(drinkItem != $item[Sacramento wine] || have_effect($effect[Refined Palate]) > 0, "need Refined Palate to drink a Sacramento wine");
	// do we have enough capacity available?
	assert(myLimitWithoutStooper - my_inebriety() >= drinkItem.inebriety * numberToDrink, "tquillaDrink: we're too drunk, we can't drink " + numberToDrink + " of " + drinkItem);
	assert(my_spleen_use() >= (spleenReduction * numberToDrink), "tquillaDrink: not enough spleen use, drinking will reduce spleen by " + (spleenReduction * numberToDrink));

	// ensure we have everything
	assert(retrieve_item(numberToDrink, drinkItem), "tquillaDrink: couldn't retrieve enough " + drinkItem);
	checkIfRunningOut(drinkItem, (myLimitWithoutStooper * 10) / drinkItem.inebriety); // make sure we have enough for 10 days of use

	if (preDrinkItem != $item[none]) {
		assert(retrieve_item(numberToDrink, preDrinkItem), "tquillaDrink: couldn't retrieve enough " + preDrinkItem);
		checkIfRunningOut(preDrinkItem, (myLimitWithoutStooper * 10) / drinkItem.inebriety);
	}

	restore_mp(mp_cost($skill[The Ode to Booze]));
	useOdeToBoozeIfNeeded(drinkItem.inebriety * numberToDrink);

	if (gkPredrinkItem != $item[none])
		assert( museumSafeDrink(numberToDrink, preDrinkItem), "tquillaDrink: was not able to successfully drink the pre-drink item " + preDrinkItem);
	return museumSafeDrink(numberToDrink, drinkItem);
}

// tries to fill our liver -- TODO Hollow Leg
void tquillaDrinks(boolean drippyDrinks, boolean refillSpleen) {
	int myLimitWithoutStooper = inebriety_limit();
	if (kgSaveRoomForStillsuitSweat)
		myLimitWithoutStooper -= 2;
	if (my_familiar() == $familiar[Stooper]) myLimitWithoutStooper--; // we want the limit without the stooper

	int startingMeat = my_meat();
	int startingAdv = my_adventures();
	boolean drankDrippyWine = false;
	int [item] receipt;

	assert(available_amount($item[astral pilsner]) == 0, "we have astral drinks leftover, we should drink those manually first");

	// DRIPPY WINE
	if (drippyDrinks && ! get_property("_drippyWineUsed").to_boolean() && my_inebriety() <= myLimitWithoutStooper - 5) {
		(fullAcquire($item[glass of drippy wine], 1, 9000) >= 1).assert("tquillaDrink: wasn't able to acquire a drippy wine");
		drankDrippyWine = tquillaDrink($item[glass of drippy wine], 0, 1, $item[none]);
		if (drankDrippyWine)
			receipt[$item[glass of drippy wine]] = 1;
	}

	// MAIN COURSE
	if (refillSpleen)
		tquillaFillSpleen(false); // false = don't use smaller spleen items to fill right to max

	int numberToDrink = floor((myLimitWithoutStooper - my_inebriety()) / gkDrinkItem.inebriety.to_float());
	while (numberToDrink > 0) {
		if (gkPredrinkItem != $item[none])
			(preferNewAcquire(gkPredrinkItem, numberToDrink, gkExpectedPreDrinkCostPer) >= numberToDrink).assert("tquillaDrink: wasn't able to acquire " + gkPredrinkItem);
		(preferNewAcquire(gkDrinkItem, numberToDrink, gkExpectedDrinkCostPer) >= numberToDrink).assert("tquillaDrink: wasn't able to acquire " + gkDrinkItem);

		tquillaDrink(gkDrinkItem, gkDrinkItemSpleenReduction, numberToDrink, gkPredrinkItem).assert("tquillaDrink: was not able to drink " + numberToDrink + "X" + gkDrinkItem);
		receipt[gkDrinkItem] = numberToDrink;

		if (refillSpleen)
			tquillaFillSpleen(false); // false = don't use smaller spleen items to fill right to max

		// SWEAT OUT SOME BOOZE -- do one at a time, apparently the multicast is bugged
		int boozeSweats = 3 - get_property("_sweatOutSomeBoozeUsed").to_int();
		while (boozeSweats > 0 && my_inebriety() > 0) {
			use_skill($skill[Sweat Out Some Booze]);
			boozeSweats = 3 - get_property("_sweatOutSomeBoozeUsed").to_int();
		}

		numberToDrink = floor((myLimitWithoutStooper - my_inebriety()) / gkDrinkItem.inebriety.to_float());
	}
	assert(myLimitWithoutStooper - my_inebriety() < gkDrinkItem.inebriety, "tquillaDrink: we have enough capacity for another " + gkDrinkItem);


	// MIME ARMY SHOT GLASS AND FILLER
	int shotglassAmount = get_property("_mimeArmyShotglassUsed").to_boolean() ? 0 : 1;
	numberToDrink = myLimitWithoutStooper - my_inebriety() + shotglassAmount;
	if (numberToDrink > 0) {
		(fullAcquire(gkDrinkFillItem, numberToDrink, gkExpectedFillFoodCostPer) >= numberToDrink).assert("tquillaDrink: wasn't able to acquire " + gkDrinkFillItem);
		tquillaDrink(gkDrinkFillItem, 0, numberToDrink, $item[none]).assert("tquillaDrink: was not able to drink " + numberToDrink + "X" + gkDrinkFillItem);
		receipt[gkDrinkFillItem] = numberToDrink;
	}

	// SUMMARY
	int advGain = my_adventures() - startingAdv;
	int meatCost = startingMeat - my_meat();
	printReceipt(receipt);
	print("gained " + advGain + " at a cost of " + meatCost + " meat", "green");
}

void tquillaDrinks() {
	tquillaDrinks(true, true);
}


void tquillaFillUp(boolean fillSpleen) {
	equip($item[designer sweatpants]);
	tquillaEats(my_daycount() > 3 && "drippyJuice".get_property().to_int() < 50, fillSpleen);
	tquillaDrinks(my_daycount() > 3 && "drippyJuice".get_property().to_int() < 50, fillSpleen);
}


void tquillaFillUpPVP() {
// use confusing LED clock; camp rest; #need 5 adventures!!! AND NEED TO MANUALLY REST SO WE DON'T DO IN THE CAMPAWAY TENT
	assert(hippy_stone_broken(), "hippy stone is not broken!");

	// GENERAL
	use($item[meteorite-ade], 3);
	use($item[School of Hard Knocks Diploma], 1);

	// EAT
	while (fullness_limit() - my_fullness() >= 5) {
		eat($item[angst burger]);

		// AUGUST SCEPTRE DAY 16
		if (!"_aug16Cast".get_property().to_boolean()) {
			assert(my_fullness() >= 1, "tquillaFillUpPVP: we wanted to empty our stomach, but we have no fullness");
			use_skill($skill[Aug. 16th: Roller Coaster Day!]);
		}
	}

	// DRINK
	while (inebriety_limit() - my_inebriety() >= 5) {
		drink($item[5-hour acrimony]);

		int boozeSweats = 3 - get_property("_sweatOutSomeBoozeUsed").to_int();
		while (boozeSweats > 0 && my_inebriety() > 0) {
			use_skill($skill[Sweat Out Some Booze]);
			boozeSweats = 3 - get_property("_sweatOutSomeBoozeUsed").to_int();
		}
	}
	assert(inebriety_limit() - my_inebriety() != 4, "need stooper to drink 5-hour acrimony");
	while (my_inebriety() < inebriety_limit() || !"_mimeArmyShotglassUsed".get_property().to_boolean()) {
		useOdeToBoozeIfNeeded(1);
		drink($item[Shot of Kardashian Gin]);

		int boozeSweats = 3 - get_property("_sweatOutSomeBoozeUsed").to_int();
		while (boozeSweats > 0 && my_inebriety() > 0) {
			use_skill($skill[Sweat Out Some Booze]);
			boozeSweats = 3 - get_property("_sweatOutSomeBoozeUsed").to_int();
		}
	}

	// SPLEEN
	while (spleen_limit() - my_spleen_use() >= 4) {
		chew($item[sweat-ade]);
	}
	while (my_spleen_use() < spleen_limit() && spleen_limit() - my_spleen_use() < 3) {
		use($item[mojo filter]);
	}
	chew($item[purple beast energy drink]);

	// SPAR
	if (!"_daycareFights".get_property().to_boolean())
		daycareSpar();

	// confusing LED clock
	if (!"_confusingLEDClockUsed".get_property().to_boolean()) {
		use($item[confusing LED clock], 1);
		abort("rest in your dwelling manually!");
	}

}


void tquillaOverdrink(boolean refillSpleen) {
	// sanity checks
	assert(gkOverdrinkDrinkItem != $item[none], "no overdrink item");
	assert(gkStooperDrink != $item[none], "no stooper drink item");

	int myLimitWithoutStooper = inebriety_limit();
	if (my_familiar() == $familiar[Stooper]) myLimitWithoutStooper--;

	assert(my_inebriety() >= myLimitWithoutStooper, "we're not drunk enough to overdrink");
	assert(my_fullness() == fullness_limit(), "we should be full before overdrinking, but we only have " + my_fullness() + " used of " + fullness_limit());
	assert(my_spleen_use() >= gkOverdrinkSpleenReduction, "overdrinking will get rid of spleen, but we only have " + my_spleen_use() + " spleen used");

	assert("_sweatOutSomeBoozeUsed".get_property().to_int() >= 3, "we haven't used all our Sweat Out Some Booze uses!");
	assert("_aug16Cast".get_property().to_boolean(), "we haven't used Aug 16!");

	if (effectiveGingerbreadCityTurns() == 0) {
		printGingerbreadLeaderboard();
		if (!user_confirm("Gingerbread city not done... continue to overdrink?", 60000, true))
			abort("user aborted");
	}

	if (have_effect($effect[Shadow Waters]) == 0) {
		if (!user_confirm("Rufus not done, continue to overdrink?", 60000, true))
			abort("user aborted");
	}

	restore_mp(mp_cost($skill[The Ode to Booze]));
	if (!useOdeToBoozeIfNeeded(gkOverdrinkDrinkItem.inebriety + gkStooperDrink.inebriety))
		abort("didn't get enough ode to booze");

	saveOutfit();
	try {
		// STOOPER DRINK
		use_familiar($familiar[stooper]);
		// we should be 1 or 0 away from our limit at this point
		assert(my_inebriety() == myLimitWithoutStooper || my_inebriety() == inebriety_limit(), "we should be at our inebriety limit or 1 away from it if we are using Stooper");
		while (my_inebriety() == inebriety_limit() - 1) { // haven't done stooper yet -- use a "while" in case there are free 1-sized drinks available
			if (!museumSafeDrink(1, gkStooperDrink)) break;
		}

		// OVERDRINK
		assert(my_familiar() == $familiar[Stooper] && my_inebriety() == inebriety_limit(), "tquillaOverdrink: we should have the Stooper familiar and be at our inebriety limit");

		if (gkPreoverdrinkItem != $item[none])
			museumSafeDrink(1, gkPreoverdrinkItem); // stuff like frosty's frosty mug
		museumSafeOverdrink(1, gkOverdrinkDrinkItem);

		// ST. SNEAKY PETE'S DAY
		if (isSneakyPeteDay()) {
			assert(my_inebriety() >= inebriety_limit() + gkOverdrinkDrinkItem.inebriety, "tquillaOverdrink: we're not at the right inebriety for St. Sneaky Pete's Day");
			int extraBeer = 10 - (inebriety_limit() - my_inebriety());
			fullAcquire($item[green beer], extraBeer);
			museumSafeOverdrink(extraBeer, $item[green beer]);
		}

		if (refillSpleen)
			tquillaFillSpleen(true);
	} finally {
		restoreOutfit();
	}

	// the turn-costing fights that work overdrunk come after the nightcap, then whatever
	// would still pass the rollover cap
	good_night_adv();
}



// returns a string that can be passed to maximize to dressup for most boss fights
// currently maximizes xp by equipping the makeshift garbage shirt if it's available
// and excludes pickpocket-enabling items from being equipped (as bosses don't need to be pickpocketed usually)
string defaultDressupStringForBossFight(string maxString) {
	string rval = "";

	// bosses give lots of xp
	// 	if (!wantsToNotEquip(maxString, $item[makeshift garbage shirt]) && to_int(get_property("garbageShirtCharge")) > 0)
	rval = maxStringAppend(rval, "exp");

	// bosses almost never have pickpocketable items
	if (!wantsToEquip(maxString, $item[mime army infiltration glove]))
		rval = maxStringAppend(rval, "-equip mime army infiltration glove");
	if (!wantsToEquip(maxString, $item[tiny black hole]))
		rval = maxStringAppend(rval, "-equip tiny black hole");

	// don't redirect to vote monster
	if (!wantsToEquip(maxString, $item[&quot;I Voted!&quot; sticker]))
		rval = maxStringAppend(rval, "-equip \"i voted!\" sticker");

	// don't get sausage goblins
	if (!wantsToEquip(maxString, $item[Kramco Sausage-o-Matic&trade;]))
		rval = maxStringAppend(rval, "-equip Kramco Sausage-o-Matic&trade;");

	// don't use aerogel attache case
	if (!wantsToEquip(maxString, $item[aerogel attache case]))
		rval = maxStringAppend(rval, "-equip aerogel attache case");

	// don't use pantogram pants
	if (!wantsToEquip(maxString, $item[pantogram pants]))
		rval = maxStringAppend(rval, "-equip pantogram pants");

	// don't use Everfull Dart Holster
	if (!wantsToEquip(maxString, $item[Everfull Dart Holster]))
		rval = maxStringAppend(rval, "-equip Everfull Dart Holster");

	// don't use mafia thumb ring
	if (!wantsToEquip(maxString, $item[mafia thumb ring]))
		rval = maxStringAppend(rval, "-equip mafia thumb ring");

	return maxStringAppend(maxString, rval);
}


void bossFight(location aLocation, string additionalEquipment, string familiarSelector) {
	string maxString = additionalEquipment.replace_string("|", ",");

	// 	clearAutomateDressup();
	// 	chooseFamiliar(familiarSelector);
	// 	maxString = maxStringAppend(maxString, defaultDressupStringForBossFight(additionalEquipment));
	// 	maximize(maxStringAppend("mainstat", maxString), false);
	automate_dressup(aLocation, "mainstat", familiarSelector, defaultDressupStringForBossFight(maxString));

	healToMaxWithMPRestore();
}

void bossFight() {
	bossFight($location[none], "", "fight");
}


void bossMonster(monster whichBoss) {
	if (whichBoss == $monster[The Big Wisniewski]) {
		bossFight(mysterious_island_camp("hippy"), "outfit frat warrior fatigues, hp, dr", "default");

		// Beelzebozo
	} else if (whichBoss == $monster[The Clownlord Beelzebozo]) {
		setCurrentMood("-combat");
		burnMP();
		bossFight($location[The "Fun" House], "clownosity 4 min, -500 combat", "default");
		if (numeric_modifier("Clowniness") < 4) abort("clowniness is not at 4!");
		if (combat_rate_modifier() > -25) abort("combat is not at -25%!");

		// amorphous blob -- low stats and hp and kill with spells
	} else if (whichBoss == $monster[amorphous blob]) {
		setDefaultMood();
		bossFight($location[none], "-ml, -hp", "mosquito");
		print("strat: low stats and hp and kill with spells", "blue");

		// default
	} else
		bossFight($location[none], "", "fight");

	healToMaxWithMPRestore();
}



// -------------------------------------
// AUTOMATION -- GRINDING -- IOTM
// -------------------------------------

// TODO do first before grinding scarab beatles, use red-nosed snapper to track undead (sheet ghost), check others for tracking possibility
void grindGhostCostume() {
	if (to_boolean(get_property("_smm.GotGhostCostume")) || banishesAvailable(kMaxInt) < 3 || my_session_items($item[li'l ghost costume]) >= 1) {
		print("grindGhostCostume: already got it or not enough banishers", "green");
		return;
	}
	print("grindGhostCostume", "green");

	monster [] target;
	cli_execute("refresh inv");

	// STEP 3
	if (have_effect($effect[Invisibly Ripped]) > 0 || have_item($item[invisible seam ripper])) {
		print("STEP 3: getting li'l ghost costume from sheet ghost @ The Haunted Storage Room", "green");
		clearGoals();
		setDefaultState();
		if (have_item($item[invisible seam ripper]))
			use(1, $item[invisible seam ripper]);

		automate_dressup($location[The Haunted Storage Room], "item", "default", "item");

		// Display-case deposits can leave the session tally negative after a drop.
		int costumesBefore = item_amount($item[li'l ghost costume]);
		try {
			target = {$monster[sheet ghost]};
			add_item_condition(1, $item[li'l ghost costume]);
			while (have_effect($effect[Invisibly Ripped]) > 0) {
				if (!targetMob($location[The Haunted Storage Room], target, $skill[none], 1, true, kMaxInt)) // optimal, max banisher cost
					abort("grindGhostCostume: failed targeting at The Haunted Storage Room");
			}
		} finally {
			if (item_amount($item[li'l ghost costume]) <= costumesBefore)
				abort("didn't get ghost costume!");
			else
				set_property("_smm.GotGhostCostume", "true");
			return;
		}

		// STEP 2 -- DO NOT WANT +combat!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	} else if (have_effect($effect[Invisible Ties]) > 0 || have_item($item[invisible string])) {
		print("STEP 2: getting invisible seam ripper from Ninja Snowman Weaponmaster @ Lair of the Ninja Snowmen", "green");
		setDefaultState();
		setCurrentMood("-combat");
		if (have_item($item[invisible string]))
			use(1, $item[invisible string]);

		automate_dressup($location[Lair of the Ninja Snowmen], "-combat", "default", "item");
		// 		assert(-combat < -25, "");
		target = {$monster[Ninja Snowman Weaponmaster]};
		while (!have_item($item[invisible seam ripper]) && have_effect($effect[Invisible Ties]) > 0) {
			if (!targetMob($location[Lair of the Ninja Snowmen], target, $skill[none], 1, true, kMaxInt)) // optimal, max banisher cost
				abort("grindGhostCostume: failed targeting at Lair of the Ninja Snowmen");
			cli_execute("refresh inv");
		}
		if (!have_item($item[invisible seam ripper]))
			abort("don't have invisible seam ripper");
		use(1, $item[invisible seam ripper]);
		grindGhostCostume();
		return;

		// STEP 1
	} else {
		print("STEP 1: getting invisible string from plaid ghost @ The Haunted Laundry Room", "green");
		setDefaultState();
		automate_dressup($location[The Haunted Laundry Room], "item", "default", "item");

		target = {$monster[plaid ghost]};
		int tries = 9 + 3; // highest number of turns i've seen, plus an extra 3
		while (!have_item($item[invisible string]) && tries > 0) {
			if (!targetMob($location[The Haunted Laundry Room], target, $skill[none], 1, true, kMaxInt)) // optimal, max banisher cost
				abort("grindGhostCostume: failed targeting at The Haunted Laundry Room");
			cli_execute("refresh inv");
			tries--;
		}
		if (!have_item($item[invisible string]))
			abort("don't have invisible string");
		grindGhostCostume();
		return;
	}
}



void grindJelly(item jellyType, int numberToGet) {
	int maxTurnsToBurn = 30;

	clearGoals();
	add_item_condition(numberToGet, jellyType);

	// burn the LOV potion if we haven't already
	if (have_item($item[Love Potion #XYZ])) museumSafeUse(1, $item[Love Potion #XYZ]); // TODO: make this more general, look for specific buffs

	if (jellyType == $item[stench jelly]) {
		set_location(mysterious_island_camp("hippy"));
		cli_execute("mood current, meat");
		automate_dressup(my_location(), "item", "space jellyfish", "");
	} else if (jellyType == $item[sleaze jelly]) {
		set_location(mysterious_island_camp("frat"));
		cli_execute("mood current, +combat, meat");
		automate_dressup(my_location(), "+combat", "space jellyfish", "0.1 item");
	}

	healAndRemoveDebuffsWithMPRestore();
	adventure(maxTurnsToBurn, my_location(), default_sub());
}


void grindJelly(item jellyType) {
	int numberToGet = 5;
	numberToGet = numberToGet - to_int(get_property("_spaceJellyfishDrops"));
	print("getting " + numberToGet + " " + jellyType);
	if (numberToGet > 0)
		grindJelly(jellyType, numberToGet);
}



// Returns the broken champagne bottle charges we can use now. NOTE: may fold the garbage tote (side effect).
// Unused charges carry over from the previous day, and the first form change of the day resets them to 11.
// So: if charges are held over, return them as-is and don't fold (folding first would throw the leftovers away).
// Once they reach 0, if we haven't changed form today, fold to the bottle to reset to 11. Callers that loop on
// this function therefore burn the leftovers first and then a fresh 11.
int garbageChampagneCharge() {
	int chargesAvailable = to_int(get_property("garbageChampagneCharge"));
	if (chargesAvailable == 0 && !to_boolean(get_property("_garbageItemChanged"))) {
		cli_execute("tote 2");
		chargesAvailable = 11;
	}
	return chargesAvailable;
}



void burnBrokenChampagneBottle(AdventureRecord advRecord, int turns) {
	print("burnBrokenChampagneBottle: " + advRecord.toString(), "green");
	// turns is the cap on the total number of adventures, across held-over charges AND the fresh 11 after a refold
	int turnsLeft = turns;
	int chargesAvailable = min(garbageChampagneCharge(), turnsLeft);

	int tries = chargesAvailable + 5;
	while (chargesAvailable > 0 && turnsLeft > 0 && tries > 0) {
		int turnsToBurn = chargesAvailable;
		int otoscopeChargesAvailable = 3 - to_int(get_property("_otoscopeUsed"));
		int cloakChargesAvailable = 10 - to_int(get_property("_vampyreCloakeFormUses"));
		int professorLecturesAvailable = pocketProfessorLectures() - to_int(get_property("_pocketProfessorLectures"));

		if (otoscopeChargesAvailable > 0) {
			turnsToBurn = min(turnsToBurn, otoscopeChargesAvailable);
		}
		if (cloakChargesAvailable > 0) {
			turnsToBurn = min(turnsToBurn, cloakChargesAvailable);
		}
		if (professorLecturesAvailable > 0) {
			turnsToBurn = min(turnsToBurn, professorLecturesAvailable);
		}

		maximizeForItemDrop(turnsToBurn, advRecord.locationToUse);
		if (have_item($item[maple magnet]))
			equip($item[maple magnet]);

		healAndRemoveDebuffsWithMPRestore();
		getToAdventure(advRecord);
		run_turn();
		turnsLeft--;

		int newCharges = garbageChampagneCharge(); // folds for a fresh 11 if we just used the last held-over charge
		if (newCharges > chargesAvailable)
			tries += newCharges; // fresh bottle: give it the same tries budget the first batch got
		chargesAvailable = min(newCharges, turnsLeft);
		tries--;
	}
}

void burnChampagneBottle(boolean drumMachine) {
	AdventureRecord ar;

	if (drumMachine)
		ar = new AdventureRecord($location[none], $skill[none], $item[drum machine]);
	else {
		if (have_item($item[maple magnet]))
			ar = new AdventureRecord($location[Dreadsylvanian Woods], $skill[none], $item[none]);
		else
			ar = new AdventureRecord($location[Dreadsylvanian Village], $skill[none], $item[none]);
	}
	burnBrokenChampagneBottle(ar, kMaxInt); // burn everything: held-over charges, then the fresh 11 if we haven't folded today
}



// does a run through the spacegate at the given coordinates
// if gateString is empty, will use random coordinates
void grindSpacegate(string gateString) {
	int turnsLeft = spacegateEnergy();
	if (turnsLeft <= 0) return;
	print("grindSpacegate '" + gateString + "' for " + turnsLeft + " turns", "green");

	item [] spacegateEquipment = {
		$item[filter helmet],
		$item[exo-servo leg braces],
		$item[high-friction boots],
		$item[gate transceiver],
		$item[rad cloak]
	};

	clearGoals();
	setDefaultMood();

	if (get_property("_spacegateCoordinates") == "") {
		cli_execute("spacegate destination " + gateString);
		adv1($location[Through the Spacegate], 0, ""); // zero-turn adventure, will acquire the equipment needed
	}

	string familiarSelector = "item";
	string offhandString = "";
	string maxString = "0.1 mp regen, equip combat lover's locket"; // , -equip \"i voted!\" sticker ??
	string plantLife = get_property("_spacegatePlantLife");
	string animalLife = get_property("_spacegateAnimalLife");

	set_property("choiceAdventure1243", "1"); // Interstellar Trade: buy anything

	// When both kits are usable, take the one whose samples the Display Case is further short of (plant on a tie).
	boolean plantKitUsable = (plantLife.contains_text("primitive") || plantLife.contains_text("advanced") || plantLife.contains_text("anomalous")) && !plantLife.contains_text("hostile");
	boolean animalKitUsable = (animalLife.contains_text("primitive") || animalLife.contains_text("advanced") || animalLife.contains_text("anomalous")) && !animalLife.contains_text("hostile");
	boolean preferAnimalKit = plantKitUsable && animalKitUsable
		&& museumShortfall($items[alien zoological sample, complex alien zoological sample, fascinating alien zoological sample])
			> museumShortfall($items[alien plant sample, complex alien plant sample, fascinating alien plant sample]);
	if (preferAnimalKit)
		print("grindSpacegate: the Museum is further short of zoological samples, using the zoological sample kit", "green");

	if (plantLife.contains_text("primitive") || plantLife.contains_text("advanced") || plantLife.contains_text("anomalous")) {
		if (!plantLife.contains_text("hostile") && offhandString == "" && !preferAnimalKit) {
			fullAcquire($item[botanical sample kit]);
			offhandString = "equip botanical sample kit";
			set_property("choiceAdventure1237", "3"); // A Simple Plant: alien plant sample
			set_property("choiceAdventure1238", "3"); // A Complicated Plant: complex alien plant sample
			set_property("choiceAdventure1239", "3"); // What a Plant!: fascinating alien plant sample
		} else {
			familiarSelector = "robortender"; // TODO sniff value and switch based on that???
			set_property("choiceAdventure1237", "1"); // A Simple Plant: edible alien plant bit
			set_property("choiceAdventure1238", "1"); // A Complicated Plant: edible alien plant bit
			set_property("choiceAdventure1239", "1"); // What a Plant!: edible alien plant bit
		}
	}

	if (animalLife.contains_text("primitive") || animalLife.contains_text("advanced") || animalLife.contains_text("anomalous")) {
		if (!animalLife.contains_text("hostile") && offhandString == "") { // the plant block above leaves this free when preferAnimalKit
			fullAcquire($item[zoological sample kit]);
			offhandString = "equip zoological sample kit";
			set_property("choiceAdventure1240", "3"); // The Animals, The Animals: alien zoological sample
			set_property("choiceAdventure1241", "3"); // buffalo-like animal: complex alien zoological sample
			set_property("choiceAdventure1242", "3"); // house-sized animal: fascinating alien zoological sample
		} else {
			set_property("choiceAdventure1240", "2"); // The Animals, The Animals: alien toenails
			set_property("choiceAdventure1241", "2"); // buffalo-like animal: alien toenails
			set_property("choiceAdventure1242", "2"); // house-sized animal: alien toenails
		}
	}

	if (offhandString == "") {
		fullAcquire($item[geological sample kit]);
		offhandString = "equip geological sample kit";
		set_property("choiceAdventure1236", "2"); // Space Cave: just core sample
		set_property("choiceAdventure1255", "2"); // cool space rocks: core sample
		set_property("choiceAdventure1256", "2"); // wide open spaces: core sample
	} else {
		set_property("choiceAdventure1236", "6"); // Space Cave: just leave
		set_property("choiceAdventure1255", "1"); // cool space rocks: rocks
		set_property("choiceAdventure1256", "1"); // wide open spaces: rocks
	}

	maxString = maxString.maxStringAppend(offhandString);
	foreach sgEquipmentIndex in spacegateEquipment {
		if (have_item(spacegateEquipment[sgEquipmentIndex]))
			maxString = maxString.maxStringAppend("equip " + spacegateEquipment[sgEquipmentIndex]);
	}

	automate_dressup($location[Through the Spacegate], "item", familiarSelector, maxString);

	boolean unused;
	if (get_property("_spacegateCoordinates") > "DAAAAAA")
		unused = cli_execute("ballpit");

	while (turnsLeft > 0 && my_adventures() > 0) {
		healAndRemoveDebuffsWithMPRestore();
		restore_mp(3 * mp_cost($skill[Weapon of the Pastalord]));
		if (!redirectAdventure($location[Through the Spacegate], 1)) {
			// KoLmafia zeroes _spacegateTurnsLeft on "The spacegate is out of energy": our count was high, not a failure
			if (get_property("_spacegateTurnsLeft").to_int() == 0 || spacegateEnergy() == 0) {
				print("grindSpacegate: the Spacegate ran out of energy before the expected " + turnsLeft + " turns", "orange");
				turnsLeft = 0;
				break;
			}
			abort("grindSpacegate: failed adventuring through the Spacegate");
		}

		turnsLeft--;
		set_property("_spacegateTurnsLeft", turnsLeft);
	}

	if (spacegateEnergy() > 0 && my_adventures() > 0)
		grindSpacegate(gateString);
	else {
		// put into the closet if they can be accidentally used
		put_closet(item_amount($item[alien rock sample]), $item[alien rock sample]);
		put_closet(item_amount($item[alien toenails]), $item[alien toenails]);
		put_closet(item_amount($item[alien zoological sample]), $item[alien zoological sample]);
		put_closet(item_amount($item[complex alien zoological sample]), $item[complex alien zoological sample]);
		put_closet(item_amount($item[fascinating alien zoological sample]), $item[fascinating alien zoological sample]);
		put_closet(item_amount($item[alien plant fibers]), $item[alien plant fibers]);
		put_closet(item_amount($item[alien plant sample]), $item[alien plant sample]);
		put_closet(item_amount($item[complex alien plant sample]), $item[complex alien plant sample]);
		put_closet(item_amount($item[fascinating alien plant sample]), $item[fascinating alien plant sample]);
		put_closet(item_amount($item[spant egg casing]), $item[spant egg casing]);
		put_closet(item_amount($item[murderbot memory chip]), $item[murderbot memory chip]);
	}
}

void grindSpacegate() {
	grindSpacegate(gkSpacegateCoordinates);
}



void grindGlaciest(boolean banishesAvailable) {
	int kTurnsToAdventure = 20;
	string kWalfordQuestString = "Filled to the Brim";
	monster [] bestTarget = {$monster[ice bartender]};
	monster [] noBanishesRemainingTargets = {$monster[ice bartender], $monster[ice clerk]}; // clerk = ice bell (banish); housekeeper = minibar key (fancy chocolate)
	monster [] noBagTargets = {$monster[ice bartender], $monster[ice concierge]};
	boolean unused;

	// set choiceAdventure1116=4
	setCurrentMood("-combat");

	string additionalString = "-combat";
	if (to_int(get_property("_voteFreeFights")) > 2) // only equip vote sticker for free fights
		additionalString = "-equip \"i voted!\" sticker";
	clear_quest_log_cache();
	if (to_int(get_property("walfordBucketProgress")) < 100 && is_on_quest(kWalfordQuestString)) {
		additionalString = "+equip Walford's bucket";
		if (quest(kWalfordQuestString).contains_text("blood"))
			additionalString += ", +equip remorseless knife";
	}
	automate_dressup($location[The Ice Hotel], "item", "default", additionalString);

	monster [] targets = bestTarget;
	if (!banishesAvailable) targets = noBanishesRemainingTargets;
	if (item_amount($item[bag of foreign bribes]) == 0) targets = noBagTargets;

	targetMob($location[The Ice Hotel], targets, $skill[none], kTurnsToAdventure, banishesAvailable, kMaxInt);
	// set choiceAdventure1116=
}


// -------------------------------------
// AUTOMATION -- GRINDING -- ASCENSION PREP
// -------------------------------------

// gets 1 smut orc keepsake box, ensures won't dressup in a free-combat generating item
// (which will overwrite the pervert and thus the keepsake box)
// turns_until_box should INCLUDE the turn to get the box
void grind_smut_orc_keepsake_box(int turns_until_box) {
	setMood("current, meat");
	automate_dressup($location[The Smut Orc Logging Camp], "meat", "", "+equip Kramco Sausage-o-Matic&trade;");

	if (turns_until_box > 1) {
		//print("MACRO: " + default_sub());
		for i from 1 to (turns_until_box - 1) {
				check_counters(kAbortOnCounter);
				healAndRemoveDebuffsWithMPRestore();
				print("doing adv #" + i);
				if (!adv1($location[The Smut Orc Logging Camp], 1, default_sub()))
					abort("adv1 failed");
				if (last_monster() == $monster[smut orc pervert])
					abort("unexpected pervert. Stopping.");
			}
	}

	clearAutomateDressup();
	dressup($location[none], "meat", "default", "-equip Kramco Sausage-o-Matic&trade;, -equip \"i voted!\" sticker");
	if (!adv1($location[The Smut Orc Logging Camp], 1, default_sub()))
		abort("final adv1 failed");

	if (last_monster() == $monster[smut orc pervert])
		print("success", "green");
	else
		print("failed -- you might not have specified enough turns OR you overwrote it with a wandering monster", "red");
}

void grind_smut_orc_keepsake_box() {
	grind_smut_orc_keepsake_box(20);
}



void grindSpace(int turnsToGrind, int maxPerTurnCost) {
	int kBuffTurns = ceil(turnsToGrind * 1.2);
	setMood("current, meat");
	if (isAsdonWorkshed() && (!drivingAsdonMartin() || have_effect($effect[Driving Observantly]) > 0))
		fueled_asdonmartin("observantly", kBuffTurns);
	//sweetSynthesis($effect[Synthesis: Collection], kBuffTurns); // not needed to finish in 30 turns?
	briefcase_if_needed($effect[Items Are Forever], kBuffTurns);

	automate_dressup($location[Domed City of Grimacia], "item", "item", "-equip \"i voted!\" sticker");

	monster [] monsterArray = {$monster[grizzled survivor], $monster[unhinged survivor], $monster[whiny survivor]};
	targetMob($location[Domed City of Grimacia], monsterArray, $skill[none], turnsToGrind, true, maxPerTurnCost);
}



void grindReflections(int reflectionsToGet, int maxPerTurnCost) {
	int kBuffTurns = ceil(reflectionsToGet * 1.2);
	setMood("current, meat");
	if (isAsdonWorkshed() && (!drivingAsdonMartin() || have_effect($effect[Driving Observantly]) > 0))
		fueled_asdonmartin("observantly", kBuffTurns);
	//sweetSynthesis($effect[Synthesis: Collection], kBuffTurns);
	briefcase_if_needed($effect[Items Are Forever], kBuffTurns);

	automate_dressup($location[The Red Queen's Garden], "item", "item", "");

	monster [] monsterArray = {$monster[grizzled survivor], $monster[unhinged survivor], $monster[whiny survivor]};
	targetMob($location[The Red Queen's Garden], monsterArray, $skill[none], reflectionsToGet, true, maxPerTurnCost);
}


boolean getUltrahydrated() {
	if (have_effect($effect[Lucky!]) == 0 && nextLuckyCost() < 2.6 * kTurnValue) // we lose 2.6 turns when we don't lucky
		getLucky();

	int tries = 3;
	while (have_effect($effect[Ultrahydrated]) == 0 && tries > 0) {
		redirectAdventure($location[The Oasis], 1);
		tries--;
	}

	return have_effect($effect[Ultrahydrated]) > 0;
}


boolean olfactionNeeded(monster aMon) {
	return olfactsAvailable() > 0
		&& ("olfactedMonster".get_property().to_monster() == aMon
			&& "_latteMonster".get_property().to_monster() == aMon);
}

int scarabBeatleValue(int perAdventureCost) {
    float fractionOfTurnsSpentGettingUltrahydrated = 5.0 / 6.0;
    if (canGetLucky(kTurnValue * 2.6)) // we lose 2.6 turns when we don't lucky
        fractionOfTurnsSpentGettingUltrahydrated = 19.0 / 20.0;

	return monsterCurrentTotalMeatValue($monster[swarm of scarab beatles], false) * fractionOfTurnsSpentGettingUltrahydrated - perAdventureCost; // 1 turn in 6 is getting ultrahydrated
}

boolean scarabWorthItHelper() {
	return (item_drop_modifier() >= 800 && meat_drop_modifier() >= 700);
}

boolean scarabYellowRayWorthItHelper() {
	return canYellowRay()
		&& !scarabWorthItHelper()
		&& equipped_amount($item[broken champagne bottle]) == 0;
}

boolean scarabScreechWorthItHelper() {
	return count(parseBanishedPhyla()) == 0 && "screechCombats".get_property().to_int() <= 0
		&& scarabWorthItHelper();
}

void getScarabBeatles(int numberToGet, int maxPerTurnCost, boolean doYellowRay, boolean doBlur) {
	int kBuffTurns = ceil(numberToGet * 1);
	int perAdventureCost = perAdventureCost($location[The Oasis]);
	print("getScarabBeatles, " + numberToGet + " to get, maxPerTurnCost: " + maxPerTurnCost + ", do blur: " + doBlur, "green");

	// get Ultrahydrated first to save a turn of our buffs
	if (have_effect($effect[Ultrahydrated]) == 0)
		assert(getUltrahydrated(), "getScarabBeatles: didn't get Ultrahydrated!");

	// BUFFS
	setCurrentMood("meat");
	setBoombox("meat");
	boolean useSweetSynthesis = spleen_limit() - my_spleen_use() >= kBuffTurns / 15;
	buffForItemDrop(kBuffTurns, $location[The Oasis], useSweetSynthesis); // use sweet synthesis if we have the spleen
	int availableSpleen = spleen_limit() - my_spleen_use();
	if (useSweetSynthesis && (availableSpleen > ceil(kBuffTurns / 30.0)))
		sweetSynthesis($effect[Synthesis: Greed], kBuffTurns);

	// DRESS UP
	// TODO skateboard is equivalent to +100% PLUS all the existing drop bonuses
	int chargesAvailable = to_int(get_property("garbageChampagneCharge"));
	if (chargesAvailable == 0 && !to_boolean(get_property("_garbageItemChanged"))) {
		cli_execute("tote 2");
		chargesAvailable = to_int(get_property("garbageChampagneCharge"));
	}
	string champagneString = chargesAvailable > 0 ? ", equip broken champagne bottle" : "";
	string sabreString = (to_int(get_property("_saberForceUses")) < 5 && champagneString == "" && doYellowRay) ? ", equip Fourth of May Cosplay Saber" : "";
	string familiarSelector = have_effect($effect[Citizen of a Zone]) == 0 ? "Patriotic Eagle" : "item";
// 	string familiarSelector = "item";
	automate_dressup($location[The Oasis], "item", familiarSelector, "0.25 meat, -equip aerogel attache case, -equip fishin' hat, -equip government-issued slacks, -equip pantogram pants" + champagneString + sabreString);
	healAndRemoveDebuffsWithMPRestore();

	monster [] monsterArray = {$monster[swarm of scarab beatles]};
// 	if (doBlur && "_circadianRhythmsRecalled".get_property().to_boolean() && have_effect($effect[Recalling Circadian Rhythms]) == 0) monsterArray = {$monster[swarm of scarab beatles], $monster[blur]};
	int beatleValue = monsterCurrentTotalMeatValue($monster[swarm of scarab beatles], false) * (5.0 / 6.0) - perAdventureCost; // 1 turn in 6 is getting ultrahydrated

// 	while (numberToGet > 0 && beatleValue > kTurnValue) {
	while (numberToGet > 0 || (have_effect($effect[Ultrahydrated]) > 0 && banishesInEffect($location[The Oasis]) >= 2)) {
		skill skillToUse = $skill[none];
		PrioritySkillRecord yellowRay = chooseYellowRaySkill();
		string scriptToUse = "";
// 		if (!"_circadianRhythmsRecalled".get_property().to_boolean())
// 			skillToUse = $skill[Recall Facts: %phylum Circadian Rhythms];
		if (olfactsAvailable() > 0
			&& "olfactedMonster".get_property().to_monster() != $monster[swarm of scarab beatles]) {
			// adv1TargetingMobs already adds Olfaction; do not cast it twice.
			if (!"_latteCopyUsed".get_property().to_boolean())
				dressup("equip latte lovers members mug");
			else
				dressup();
		} else if (doYellowRay && scarabYellowRayWorthItHelper()) {
			print("going to yellow ray!", "green");
			prepForYellowRay();
			skillToUse = yellowRay.theSkill; // not in combat
			if (yellowRay.theItem != $item[none] && can_equip(yellowRay.theItem)) // might be a combat item like yellow rocket
				dressup("equip " + yellowRay.theItem);
			else
				dressup();
		} else
			dressup();
		if (skillToUse != $skill[none])
			scriptToUse += "skill " + skillToUse + ";";

		// make sure we're still Ultrahydrated?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
		if (have_effect($effect[Ultrahydrated]) == 0)
			assert(getUltrahydrated(), "getScarabBeatles: didn't get Ultrahydrated!");

		// The active effect is authoritative: _citizenZone can remain blank until
		// Mafia reads its description. Screech's recharge does not track pledge.
		boolean needsAllegiance = familiarSelector == "Patriotic Eagle" && have_effect($effect[Citizen of a Zone]) == 0;
		if (needsAllegiance)
			// Availability is only known in combat, after dressing and redirects.
			// Use the ID because the displayed name varies by familiar and zone.
			scriptToUse = "if hasskill 7449;skill 7449;endif;" + scriptToUse;
		boolean wonTargetFight = isWinPage(adv1TargetingMobs($location[The Oasis], monsterArray, maxPerTurnCost, true, scriptToUse))
			&& last_monster() == $monster[swarm of scarab beatles];
		if (wonTargetFight)
			numberToGet--;

		beatleValue = monsterCurrentTotalMeatValue($monster[swarm of scarab beatles], false) * (5.0 / 6.0) - perAdventureCost; // 1 turn in 6 is getting ultrahydrated
		print("swarm of scarab beatles: " + beatleValue);
		if (doBlur)
			print("blur: " + ((monsterTotalMeatValue($monster[blur], false, item_drop_modifier(), meat_drop_modifier()) - perAdventureCost - mall_price($item[ten-leaf clover])/20) * 0.95)); // include cost of the ten-leaf clover and the 1 turn in 20 to get Ultrahydrated

// 		assert(skillToUse != $skill[Recall Facts: %phylum Circadian Rhythms] || "_circadianRhythmsRecalled".get_property().to_boolean(), "getScarabBeatles: we wanted to learn facts about circadian rhythms, but the spell wasn't cast!!!");
		if (wonTargetFight && needsAllegiance && have_effect($effect[Citizen of a Zone]) == 0)
			print("Oasis pledge was unavailable; retrying on a later target fight.", "orange");

		if (familiarSelector == "Patriotic Eagle" && have_effect($effect[Citizen of a Zone]) > 0) {
			familiarSelector = "item";
			automate_dressup($location[The Oasis], "item", familiarSelector, "0.25 meat, -equip aerogel attache case, -equip fishin' hat, -equip government-issued slacks, -equip pantogram pants" + champagneString + sabreString);
		}
	}

	if (beatleValue < kTurnValue)
		print("WARNING: beatle value (" + beatleValue + ") is less than turn value (" + kTurnValue + ")", "red");
}

// attempts to grind while saving banishesToSave banishes
void grindScarabBeatles(int maxPerTurnCost, boolean doBlur, int banishesToSave) {
	print("grindScarabBeatles, banishesToSave: " + banishesToSave, "green");
	clearAutomateDressup();
	printBanishPriorityArray(true, false, $location[The Oasis], maxPerTurnCost);
	// stops when banishes run out, when we're down to the last 10 adventures, or when a pass doesn't use any banishes
	int banishesAvailable = max(0, banishesAvailable(maxPerTurnCost) - banishesToSave);
	int tries = 5;
	while (banishesAvailable > 0 && my_adventures() > 10 && tries > 0) {
		getScarabBeatles(min(banishesAvailable * 10, my_adventures() - 10), maxPerTurnCost, false, doBlur); // false = don't yellow ray
		int banishesLeft = max(0, banishesAvailable(maxPerTurnCost) - banishesToSave);
		if (banishesLeft >= banishesAvailable) {
			print("grindScarabBeatles: no banishes used in the last pass, stopping", "orange");
			break;
		}
		banishesAvailable = banishesLeft;
		tries--;
	}
// 	assert(banishesAvailable(maxPerTurnCost) - banishesToSave == 0, "we should have exactly " + banishesToSave + " banishes available, but we have " + banishesAvailable(maxPerTurnCost));

	
}

// tries to grind until all banishes are done
void grindScarabBeatles(int maxPerTurnCost, boolean doBlur) {
	abort("needs work see other grindScarabBeatles");
	clearAutomateDressup();
	int banishesAvailable = banishesAvailable(maxPerTurnCost);
	int tries = 3;
	while (banishesAvailable > 0 && tries > 0) {
		getScarabBeatles(min((banishesAvailable + 1) * 10, my_adventures() - 10), maxPerTurnCost, false, doBlur);
		banishesAvailable = banishesAvailable(maxPerTurnCost);
		tries--;
	}
}


// only need +234% item to get drum machines
// will yellow ray beatles if getBeatlesOnYellowRay is true
void grindDrumMachine(int numberToGet, int maxPerTurnCost, boolean getBeatlesOnYellowRay) {
	int kTargetItemDrop = 234;
	int kBuffTurns = ceil(numberToGet * 1.2);
	print("grindDrumMachine, targetting " + numberToGet + " drums @ " + maxPerTurnCost + " max cost/turn, getBeatlesOnYellowRay: " + getBeatlesOnYellowRay, "green");

	if (!drivingAsdonMartin($effect[Driving Observantly]))
		print("WARNING: overwriting existing Asdon buff!", "red");
	buffForMeatDrop(kBuffTurns, false); // use sweet Synthesis

	// DRESSUP
	string familiarSelector = "default";
	string maxString = "item";
	float meatBonus = 1;
	int tries = 4;
	repeat {
		automate_dressup($location[The Oasis], meatBonus + " meat", familiarSelector, maxString);

		if (item_drop_modifier() < kTargetItemDrop * 1.1 && tries == 4)
			familiarSelector = "item";
		if (item_drop_modifier() < kTargetItemDrop * 1.1)
			meatBonus = meatBonus / 4;
		if (item_drop_modifier() > kTargetItemDrop * 2)
			meatBonus = meatBonus * 3;

		tries--;
	} until (tries <= 0 || (item_drop_modifier() >= kTargetItemDrop && item_drop_modifier() <= kTargetItemDrop * 2));

	// GRIND
	tries = 1.5 * numberToGet;
	while (numberToGet > 0 && tries > 0) {
		monster [] monsterArray = {$monster[blur], $monster[swarm of scarab beatles]};
// 		monster [] monsterArray = {$monster[blur]};
// 		if (getBeatlesOnYellowRay && canYellowRay()) monsterArray = {$monster[blur], $monster[swarm of scarab beatles]};

		skill skillToUse = $skill[none];
		string dressupTweak = "";

		// only do YR processing if we have already olfacted the blur -- otherwise the beatles will be olfacted and then we'll be sad
		if (canYellowRay() && getBeatlesOnYellowRay && isOlfacted($monster[blur])) {
			monsterArray = {$monster[swarm of scarab beatles], $monster[blur]}; // beatles need to be first or the yellow ray won't fire

			PrioritySkillRecord psr = chooseYellowRaySkill();
			skillToUse = psr.theSkill;
			if (psr.theItem != $item[none] && can_equip(psr.theItem)) // meant to catch non-equippable items like yellow rocket -- TODO we might not be able to equip because of stats
				dressupTweak = "equip " + psr.theItem;
		}
		if (skillToUse == $skill[none] &&  !isOlfacted($monster[blur])) {
			skillToUse = $skill[Transcendent Olfaction];
		}

		// if the vote monster comes up, we might be in targetMob for 2 turns
		// if we're looking for more than 1 mob, we might be in targetMob for an unspecified number of turns
		// if another wandering mob (event mobs for example) comes up, we might be in targetMob for an unspecified number of turns
		// if we're not targeting optimally, we might be targetMob for more than 1 turn -- we are currently only targeting optimally
		if (have_effect($effect[Ultrahydrated]) == 0) {
			if (!freePillKeeperUsed())
				cli_execute("pillkeeper free semirare");
		}

		// target that mob
		assert(item_drop_modifier() >= kTargetItemDrop, "grindDrumMachine: not enough +item"); // TODO: this might get triggered when we redirect
		dressup(dressupTweak);
		if (targetMob($location[The Oasis], monsterArray, skillToUse, 0, true, maxPerTurnCost))
			numberToGet--;
		print("blur: " + ((monsterTotalMeatValue($monster[blur], false, item_drop_modifier(), meat_drop_modifier()) - perAdventureCost($location[The Oasis]) - mall_price($item[ten-leaf clover])/20) * 0.95)); // include cost of the ten-leaf clover and the 1 turn in 20 to get Ultrahydrated

		tries--;
	}
}


void grindDrumMachine(int maxPerTurnCost, boolean getBeatlesOnYellowRay, int banishesToSave) {
	printBanishPriorityArray(true, false, $location[The Oasis], maxPerTurnCost);
	int banishesAvailable = max(0, banishesAvailable(maxPerTurnCost) - banishesToSave);
	if (banishesAvailable > 0 && my_adventures() > 10)
		grindDrumMachine(min(banishesAvailable * 10, my_adventures() - 10), maxPerTurnCost, getBeatlesOnYellowRay);
}


void grindDrumMachine(int maxPerTurnCost, boolean getBeatlesOnYellowRay) {
	printBanishPriorityArray(true, false, $location[The Oasis], maxPerTurnCost);
	int banishesAvailable = banishesAvailable(maxPerTurnCost);
	if (banishesAvailable > 0 && my_adventures() > 10)
		grindDrumMachine(min((banishesAvailable + 1) * 10, my_adventures() - 10), maxPerTurnCost, getBeatlesOnYellowRay);
}



void useDrumMachine(int turnsToGrind) {
	automate_dressup($location[none], "item", "item", "-equip \"i voted!\" sticker");
	if (isAsdonWorkshed())
		fueled_asdonmartin("observantly", turnsToGrind);
	//sweetSynthesis($effect[Synthesis: Collection], turnsToGrind);
	briefcase_if_needed($effect[Items Are Forever], turnsToGrind);
	museumSafeUse(turnsToGrind, $item[drum machine]);
}


void grindThugnderdome(int turnsToGrind, int maxPerTurnCost) {
	setDefaultMood();

	if (isAsdonWorkshed() && (!drivingAsdonMartin() || have_effect($effect[Driving Observantly]) < turnsToGrind))
		fueled_asdonmartin("observantly", turnsToGrind);
	//sweetSynthesis($effect[Synthesis: Collection], turnsToGrind);
	briefcase_if_needed($effect[Items Are Forever], turnsToGrind);

	automate_dressup($location[Thugnderdome], "item", "item", "0.1 meat");

	monster [] monsterArray = {$monster[gnarly gnome], $monster[gnasty gnome]};
	targetMob($location[Thugnderdome], monsterArray, $skill[none], turnsToGrind, false, maxPerTurnCost);
}



void burnYellowRays(int maxPerTurnCost, boolean useClover) {
	try {
		setMood("current, meat");
		set_property("choiceAdventure1387", "3");

		automate_dressup($location[The Oasis], "meat", "default", "-equip Kramco Sausage-o-Matic&trade;");

		int tries = 30; // random guess
		while (canYellowRay() && tries > 0) {
			prepForYellowRay();
			skill skillToUse = chooseYellowRaySkill().theSkill;

			if (have_effect($effect[Ultrahydrated]) == 0 && useClover) {
				if (!get_property("_freePillKeeperUsed").to_boolean())
					cli_execute("pillkeeper free semirare");
			}

			tm($location[The Oasis], $monster[swarm of scarab beatles], skillToUse, 1, true, maxPerTurnCost);

			tries--;
		}
	} finally {
		remove_property("choiceAdventure1387");
	}
}


void grindBeerLens(int maxPerTurnCost) {
	print("grindBeerLens", "green");
	int banishesAvailable = banishesAvailable(maxPerTurnCost);
	if (banishesAvailable < 3) {
		print("not enough banishes available, skipping", "blue");
		return;
	}

	int beerLensToGet = 3 - to_int(get_property("_beerLensDrops"));
	if (beerLensToGet > 0) {
		setCurrentMood("meat");
		string maxString = "meat";
		automate_dressup($location[A Barroom Brawl], "item 300 min", "item [tracker]", maxString);
		healAndRemoveDebuffsWithMPRestore();

		monster [] bestTarget = {$monster[unemployed knob goblin]};
		while (beerLensToGet > 0 && my_adventures() > 0) {
			if (!targetMob($location[A Barroom Brawl], bestTarget, $skill[none], beerLensToGet, true, maxPerTurnCost)) // optimal, ignore cost
				abort("grindBeerLens: failed targeting unemployed knob goblins");
			beerLensToGet = 3 - to_int(get_property("_beerLensDrops"));
		}
	}
}


void grindDailyDungeon() {
	print("grindDailyDungeon", "green");
	if (!to_boolean(get_property("dailyDungeonDone"))) {
		setDefaultState();
		automate_dressup($location[The Daily Dungeon], "mp regen", "default", "equip ring of detect boring doors, equip candy cane sword cane, -equip Kramco Sausage-o-Matic&trade;, -equip Everfull Dart Holster");
		int roomsToDo = 15 - to_int(get_property("_lastDailyDungeonRoom"));
		while (roomsToDo > 0 && my_adventures() > 0) {
			healAndRemoveDebuffsWithMPRestore();
			if (!redirectAdventure($location[The Daily Dungeon], 1))
				abort("grindDailyDungeon: failed adventuring in the Daily Dungeon");
			roomsToDo = 15 - to_int(get_property("_lastDailyDungeonRoom"));
		}
	}
}



void remove_properties(string filter) {
	foreach prop in get_all_properties(filter, false) { // false = not global properties file
		if (user_confirm("Should we delete property '" + prop + "'?\nValue = '" + get_property(prop) + "'"))
			remove_property(prop, false); // false = not global properties file
	}
}



// -------------------------------------
// AUTOMATION -- GRINDING -- SEA QUEST
// -------------------------------------

boolean getFishy(int minTurns) {
	print("getFishy for a minimum of " + minTurns, "green");
	int neededFishy = minTurns - have_effect($effect[Fishy]);
	if (neededFishy <= 0) return true;

	int skateParkFishy = get_property("skateParkStatus") == "ice" ? 30 : 0;
	int pipeFishy = get_property("_fishyPipeUsed").to_boolean() ? 0 : 10;

	if (pipeFishy > 0 && neededFishy > 0 && pipeFishy >= neededFishy) {
		use(1, $item[fishy pipe]);
		neededFishy = minTurns - have_effect($effect[Fishy]);
	}

	if (skateParkFishy > 0 && neededFishy > 0 && skateParkFishy >= neededFishy) {
		cli_execute("skate lutz");
		neededFishy = minTurns - have_effect($effect[Fishy]);
	}

	return have_effect($effect[Fishy]) >= minTurns;
}


boolean getBreathWater(int minTurns) {
	assert(breatheWaterTurns() == 0, "getBreathWater: we're already breathing water");
	assert(minTurns <= 20, "getBreathWater: can't get more than 20 turns of breathing water at a time");

	item [] breatheWaterItems = {$item[hyperinflated seal lung], $item[ballast turtle], $item[tempura air], $item[pressurized potion of pneumaticity]};
	sort breatheWaterItems by -historical_price(value);
	int idx = 0;
	while (breatheWaterTurns() == 0 && idx < count(breatheWaterItems)) {
		item breatheWaterItem = breatheWaterItems[idx++];
		if (have_item(breatheWaterItem))
			museumSafeUse(1, breatheWaterItem);
	}

	if (breatheWaterTurns() == 0 && isAsdonWorkshed())
		safeFueledAsdonMartin($effect[Driving Observantly], minTurns);

	return breatheWaterTurns() >= minTurns;
}


// prep for success in the sea
// gets fishy, underwater breathing and reduces pressure penalties as possible
void prepForSea(location seaLocation, boolean isGrinding) {
	print("prepForSea: lasso training: " + get_property("lassoTraining"));

    // FISHY
	if ( ! get_property("_fishyPipeUsed").to_boolean())
		use($item[fishy pipe]);
	int seaTurns = have_effect($effect[Fishy]);
	assert(seaTurns >= 1, "wasn't able to get Fishy");

    // WATER BREATHING
   	int breathTurns = min(20, seaTurns);
    if (seaLocation != $location[Mer-kin Gymnasium] && seaLocation != $location[Mer-kin Elementary School]
        && seaLocation != $location[Mer-kin Colosseum] && seaLocation != $location[Mer-kin Library]) {
	   if (breatheWaterTurns() == 0 && breathTurns > 11) { // water-breathing buffs overlap, so only get a new one when we run out of the last
	       getBreathWater(breathTurns);
    	}
    	cprint(breatheWaterTurns() < breathTurns, "wasn't able to get " + seaTurns + " turns of water breathing, only have " + breatheWaterTurns() + "!", "red");
    } else
        breathTurns = kMaxInt;
	int advTurns = min(seaTurns, breathTurns);

	// REDUCE PRESSURE
	ensureSongRoom($skill[Donho's Bubbly Ballad]);
	if (have_skill($skill[Donho's Bubbly Ballad]))
		buffIfNeededWithUneffect($skill[Donho's Bubbly Ballad], advTurns);
	else
		use_if_needed($item[recording of Donho's Bubbly Ballad], $effect[Donho's Bubbly Ballad], advTurns);
	assert(have_effect($effect[Donho's Bubbly Ballad]) >= advTurns, "did not get Donho effect");

	if (have_effect($effect[Juiced Up]) < advTurns) {
		newAcquire($item[Mer-kin fastjuice], ceil((seaTurns - have_effect($effect[Juiced Up])) / 10.0), 444);
		use_if_needed($item[Mer-kin fastjuice], $effect[Juiced Up], advTurns);
	}

	//use shavin' razor; use shark cartilage;

	switch (seaLocation) {
		case $location[The Briny Deeps]:
			cli_execute("grandpa wizardfish; grandpa avius ticklium;");
			break;

		case $location[The Brinier Deepers]:
			cli_execute("grandpa trophyfish");
			break;

		case $location[The Briniest Deepests]:
			newAcquire($item[bazookafish bubble gum], ceil((seaTurns - have_effect($effect[fishbreath])) / 5.0), 101);
			use_if_needed($item[bazookafish bubble gum], $effect[fishbreath], advTurns);
			cli_execute("grandpa eel");
			break;

		default:
	}

	if (isGrinding)
		buffForItemDrop(advTurns, seaLocation, true);

	if ( ! "expressCardUsed".get_property().to_boolean()
	   && have_effect($effect[Fishy]) > 0 && breatheWaterTurns() > 0
	   && breatheWaterTurns() <= 15) { // some of these buffs don't go over 20 turns (???), so wait to use the express card until they're closer to running out
		defaultZap(); // express card reduces zap wand cooldown
		burnMP(0);
		use(1, $item[Platinum Yendorian Express Card]); // Extends the duration of all current effects by 5 adventures, restores all MP, and cools zap wands
	}
}


// dress for success in the sea
void dressForSea(location seaLocation, boolean isGrinding) { // sea_quest sea quest
	boolean unused;
	retrieve_item($item[cozy scimitar]);

	string selectorString = "item";
	string familiarString = "robortender [tracker]";

	//string maxString = "+equip lucky gold ring, -equip \"i voted!\" sticker, -equip Kramco Sausage-o-Matic&trade;, -equip pantogram pants, -equip aerogel attache case, -equip mafia thumb ring"; // needed to stop some automation
	string maxString = "-equip \"i voted!\" sticker, -equip Kramco Sausage-o-Matic&trade;, -equip mafia thumb ring, -equip designer sweatpants, -equip pantogram pants";
	if (isGrinding && !"_epicMcTwistUsed".get_property().to_boolean())
		maxString += ", equip pro skateboard";
	// 	if (my_class() == $class[accordion thief]) // causes problems in octopus' garden
	// 		maxString += ", +four songs";

	switch (seaLocation) {
		case $location[An Octopus's Garden]:
			setCurrentMood("-combat");
			selectorString = "-5 combat";
			familiarString = "Space Jellyfish"; // for sea truffles
			maxString += ", 0.1 item, 0.01 hp, +equip straw hat";
			if (can_equip($item[octopus's spade]))
				maxString += ", +equip octopus's spade";
			break;

		case $location[The Wreck of the Edgar Fitzsimmons]:
			if (!isGrinding) {
				setCurrentMood("-combat");
				selectorString = "-combat";
				familiarString = "robortender";
				use_familiar($familiar[Robortender]); equip($item[toggle switch (Bartend)]);
				if (can_equip($item[sea salt scrubs]))
					maxString += ", +equip sea salt scrubs";
				if (can_equip($item[cozy scimitar]))
					maxString += ", +equip cozy scimitar";
			} else {
				// option 1: drowned sailor
				// 		setCurrentMood("+combat");
				// 		selectorString = "item";
				// 		maxString += ", +10 combat, -equip pantogram pants, -equip aerogel attache case";
				// 		setRedNosedSnapperGuideMe("undead");

				// option 2: unholy diver
				setCurrentMood("-combat");
				selectorString = "item";
				maxString += ", -50 combat, -equip pantogram pants, -equip aerogel attache case";
				setRedNosedSnapperGuideMe("horror");

				if (to_int(get_property("garbageChampagneCharge")) > 0)
					maxString += ", +equip broken champagne bottle";
				else if (can_equip($item[cozy scimitar]))
					maxString += ", +equip cozy scimitar";
				if ((to_int(get_property("_chestXRayUsed")) < 3) || (to_int(get_property("_otoscopeUsed")) < 3))
					maxString += ", +equip Lil' Doctor&trade; bag";
				if (to_int(get_property("_vampyreCloakeFormUses")) < 10)
					maxString += ", +equip vampyric cloake";
			}
			break;

		case $location[The Mer-Kin Outpost]:
			if (!isGrinding) {
				familiarString = "robortender";
				use_familiar($familiar[Robortender]); equip($item[toggle switch (Bartend)]);
				if (have_item($item[Mer-kin lockkey])) {
					setCurrentMood("-combat");
					selectorString = "-combat";
				} else if ("seahorseName".get_property() == "") {
					setCurrentMood("+combat");
					selectorString = "+combat";
				} else if (have_item($item[Grandma's Map])
					|| (!have_item($item[Grandma's Note]) || !have_item($item[Grandma's Fuchsia Yarn]) || !have_item($item[Grandma's Chartreuse Yarn]))) {
					setCurrentMood("-combat");
					selectorString = "-combat";
				} else {
					setCurrentMood("+combat");
					selectorString = "+combat";
				}
				if (can_equip($item[sea salt scrubs]) && selectorString == "-combat") // seems we need the shirt slot to achieve +25 combat
					maxString += ", +equip sea salt scrubs";
				if (can_equip($item[cozy scimitar]))
					maxString += ", +equip cozy scimitar";
			} else {
				setCurrentMood("+combat");
				selectorString = "item";
				maxString += ", +combat, -equip pantogram pants, -equip aerogel attache case";
				if (to_int(get_property("garbageChampagneCharge")) > 0)
					maxString += ", +equip broken champagne bottle";
				else if (can_equip($item[cozy scimitar]))
					maxString += ", +equip cozy scimitar";
				if ((to_int(get_property("_chestXRayUsed")) < 3) || (to_int(get_property("_otoscopeUsed")) < 3))
					maxString += ", +equip Lil' Doctor&trade; bag";
				if (to_int(get_property("_vampyreCloakeFormUses")) < 10)
					maxString += ", +equip vampyric cloake";
			}
			break;

		case $location[Anemone Mine]:
			if (!isGrinding) {
				setCurrentMood("-combat");
				selectorString = "-5 combat";
				familiarString = "red-nosed snapper";
				if (can_equip($item[sea salt scrubs]))
					maxString += ", +equip sea salt scrubs";
				if (can_equip($item[cozy scimitar]))
					maxString += ", +equip cozy scimitar";
				if (get_property("redSnapperPhylum") != "horror")
					setRedNosedSnapperGuideMe("horror");
			} else {
				setCurrentMood("meat");
				selectorString = "item";
				maxString += ", 0.5 meat";
				if (can_equip($item[cozy scimitar]))
					maxString += ", +equip cozy scimitar";
			}
			break;

		case $location[The Marinara Trench]:
			if (kSpaceJellyfishDeepSauceCollectedKey.get_property().to_boolean()) {
				familiarString = "robortender [tracker]";
				if (get_property("redSnapperPhylum") != "merkin")
					setRedNosedSnapperGuideMe("merkin");
				set_property("choiceAdventure305", "1");
			} else {
				familiarString = "space jellyfish";
				set_property("choiceAdventure305", "3");
			}

			setCurrentMood("-combat");
			selectorString = "-combat";
			maxString += ", -75 combat";

			if (isGrinding) {
				maxString += ", 5 item";
				if (to_int(get_property("garbageChampagneCharge")) > 0)
					maxString += ", +equip broken champagne bottle";
				else if (can_equip($item[cozy scimitar]))
					maxString += ", +equip cozy scimitar";
				if ((to_int(get_property("_chestXRayUsed")) < 3) || (to_int(get_property("_otoscopeUsed")) < 3))
					maxString += ", +equip Lil' Doctor&trade; bag";
				if (to_int(get_property("_vampyreCloakeFormUses")) < 10)
					maxString += ", +equip vampyric cloake";
			} else {
				maxString += ", item";
				if (can_equip($item[cozy scimitar]))
					maxString += ", +equip cozy scimitar";
			}

			assert(fullAcquire($item[Mer-kin pressureglobe]) >= 1, "didn't get a pressureglobe");
			restore_mp(225);
			break;

		case $location[The Dive Bar]:
			if (isGrinding) {
				setDefaultMood();
				selectorString = "item";
				if (to_int(get_property("garbageChampagneCharge")) > 0)
					maxString += ", +equip broken champagne bottle";
			} else {
				setCurrentMood("-combat");
				selectorString = "-combat";
			}
			maxString += ", -equip pantogram pants, -equip aerogel attache case";
			if (can_equip($item[cozy scimitar]) && countHandsUsed(maxString) == 0)
				maxString += ", +equip cozy scimitar";
			if ((to_int(get_property("_chestXRayUsed")) < 3) || (to_int(get_property("_otoscopeUsed")) < 3))
				maxString += ", +equip Lil' Doctor&trade; bag";
			if (to_int(get_property("_vampyreCloakeFormUses")) < 10)
				maxString += ", +equip vampyric cloake";
			familiarString = "";
			use_familiar($familiar[Robortender]); equip($item[toggle switch (Bartend)]);
			break;

		case $location[Madness Reef]:
			if (isGrinding) {
				setCurrentMood("+combat");
				maxString += ", +combat";
			}
			else {
				setCurrentMood("-combat");
				maxString += ", -combat";
			}
			maxString += ", 10 item";
			if (to_int(get_property("garbageChampagneCharge")) > 0)
				maxString += ", +equip broken champagne bottle";
			else if (can_equip($item[cozy scimitar]))
				maxString += ", +equip cozy scimitar";
			if ((to_int(get_property("_chestXRayUsed")) < 3) || (to_int(get_property("_otoscopeUsed")) < 3))
				maxString += ", +equip Lil' Doctor&trade; bag";
			if (to_int(get_property("_vampyreCloakeFormUses")) < 10)
				maxString += ", +equip vampyric cloake";
			break;

		case $location[The Coral Corral]:
			if (!isGrinding) {
				setCurrentMood("meat");
				selectorString = "item";
				maxString += ", +equip aquamariner's necklace, +equip aquamariner's ring";
				if (can_equip($item[sea salt scrubs]))
					maxString += ", +equip sea salt scrubs";
				if (can_equip($item[cozy scimitar]))
					maxString += ", +equip cozy scimitar";
				familiarString = "";
				use_familiar($familiar[Robortender]); equip($item[toggle switch (Bartend)]);
			} else {
				setCurrentMood("meat");
				selectorString = "item";
				maxString += ", 0.5 meat";
				if (can_equip($item[cozy scimitar]))
					maxString += ", +equip cozy scimitar";
			}
			break;

		case $location[The Skate Park]:
			setCurrentMood("-combat");
			selectorString = "-combat";
			break;

		case $location[The Caliginous Abyss]:
			setCurrentMood("-combat");
			selectorString = "-combat";
			maxString += ", +equip black glass, +equip shark jumper, +equip scale-mail underwear";
			if (can_equip($item[cozy scimitar]))
				maxString += ", +equip cozy scimitar";
			use_if_needed($item[comb jelly], $effect[Jelly Combed], 20);
			break;

		case $location[Mer-kin Elementary School]:
			setCurrentMood("-combat");
			maxString += ", -combat, item, outfit Mer-kin Scholar's Vestments";
			if (can_equip($item[cozy scimitar]))
				maxString += ", +equip cozy scimitar";
			break;

		case $location[Mer-kin Library]:
			setDefaultMood();
			maxString += ", item, outfit Mer-kin Scholar's Vestments";
			if (can_equip($item[cozy scimitar]))
				maxString += ", +equip cozy scimitar";
			break;

		case $location[Mer-kin Gymnasium]:
			setCurrentMood("-combat");
			maxString += ", -combat, outfit Mer-kin Gladiatorial Gear";
			if (can_equip($item[cozy scimitar]))
				maxString += ", +equip cozy scimitar";
			break;

		case $location[Mer-kin Colosseum]:
			setDefaultMood();
			maxString += ", item, outfit Mer-kin Gladiatorial Gear";
			if (can_equip($item[cozy scimitar]))
				maxString += ", +equip cozy scimitar";
			break;

		default:
			setDefaultMood();
			selectorString = "item";
			if (can_equip($item[cozy scimitar]))
				maxString += ", +equip cozy scimitar";
			familiarString = "";
	}

	if (get_property("lassoTraining") != "expertly" && seaLocation != $location[An Octopus's Garden]) {
		maxString += ", +equip sea cowboy hat, +equip sea chaps";
	}

	if (familiarString.contains_text("robortender")) {
		use_familiar($familiar[robortender]);
		doseRobortender($item[Bloody Nora]);
	}

	//use_familiar($familiar[Space Jellyfish]); equip($item[Li'l Businessman Kit]); // kit = more sand dollars
	automate_dressup(seaLocation, selectorString, familiarString, maxString);

	string currentMood = getMood();
	int targetCombat = equipped_amount($item[mer-kin sneakmask]) > 0 ? -30 : -25;
	if (currentMood.contains_text("-combat") && combat_rate_modifier() > targetCombat) {
		if (have_effect($effect[Feeling Lonely]) < 1)
			use_skill($skill[Feel Lonely]);
		assert(combat_rate_modifier() <= targetCombat, "didn't get enough -combat!");
	}
	if (currentMood.contains_text("+combat") && combat_rate_modifier() < 25)
		abort("didn't get enough +combat!");
}


// prep for and dress for success in the sea
// gets fishy, underwater breathing and reduces pressure penalties as possible
void seaQuest(location seaLocation, boolean isGrinding) { // sea_quest sea quest
	prepForSea(seaLocation, isGrinding);
	dressForSea(seaLocation, isGrinding);
}


void grindSeaLocation(location seaLocation, monster [] targetArray, boolean maximizeItemDrop, int maxPerTurnCost) {
	print("grinding sea location: " + seaLocation + ", targetting: " + targetArray[0] + " (total targets: " + count(targetArray) + ") max per turn cost: " + maxPerTurnCost, "green");

	seaQuest(seaLocation, true);
	int turnsToGrind = min(have_effect($effect[Fishy]), breatheWaterTurns()) + instaKillsAvailable();

	// do all this for the results of Harpoon! and Summon Leviatuga OR just wield the broken champagne bottle and the rest of the items and let the consult script do the rest
	int tries = turnsToGrind + 5; // some extra tries for turtle finding
	while (have_effect($effect[fishy]) > 0 && have_effect($effect[Donho's Bubbly Ballad]) > 0 && canBreatheWater() && tries > 0) {
		string itemScript = main_sub() + init_sub() + setup_aborts_sub() + "call init;";

		if (equipped_amount($item[cozy scimitar]) == 1)
			itemScript += "skill Summon Leviatuga; skill Harpoon!; ";

		//itemScript += "if monstername \"*" + targetArray[0] + "*\";  skill Transcendent Olfaction; skill Gallapagosian Mating Call; skill Offer Latte to Opponent; "; // this stuff happens above?????
		itemScript += "if monstername \"*" + targetArray[0] + "*\"; ";

		if (maximizeItemDrop && equipped_amount($item[vampyric cloake]) >= 1 && to_int(get_property("_vampyreCloakeFormUses")) < 10)
			itemScript += "skill become a bat;";

		if (maximizeItemDrop && equipped_amount($item[Lil' Doctor&trade; bag]) >= 1 && to_int(get_property("_otoscopeUsed")) < 3)
			itemScript += "skill otoscope;";

		PrioritySkillRecord instaKillSkill = chooseInstaKillSkill();
		if (instaKillSkill.theSkill != $skill[none]) {
			itemScript += "skill " + instaKillSkill.theSkill + ";";
			if (instaKillSkill.theItem != $item[none])
				dressup("equip " + instaKillSkill.theItem);
		}

		itemScript += "endif;";
		itemScript += "call main;repeat;";

		healAndRemoveDebuffsWithMPRestore();
		if (!isWinPage(adv1TargetingMobs(seaLocation, targetArray, maxPerTurnCost, true, itemScript)) && !arrayContains(targetArray, last_monster())) {
			// wrong target or failed adventuring in the sea
			//print("failed adventuring in the sea!", "red");
		}
		// The last fight can exhaust Fishy; prepForSea requires it to still be active.
		if (have_effect($effect[Fishy]) == 0)
			break;

		if (available_amount($item[cozy scimitar]) == 0)
			fullAcquire($item[cozy scimitar]);

		seaQuest(seaLocation, true);
		tries--;
	}
}


// favour stranglin' algae if we don't favourGardener
void grindOctopusesGarden(int maxPerTurnCost, boolean favourGardener) {
	set_property("choiceAdventure298", "3");
	monster [] monsterArray = {$monster[octopus gardener], $monster[stranglin' algae]};
	if (!favourGardener) monsterArray = {$monster[stranglin' algae], $monster[octopus gardener]};

	grindSeaLocation($location[An Octopus's Garden], monsterArray, true, maxPerTurnCost);

	set_property("choiceAdventure298", "");
}


void grindMerkinOutpost(int maxPerTurnCost) {
	set_property("choiceAdventure312", "4");
	monster [] monsterArray = {$monster[mer-kin raider]};

	grindSeaLocation($location[The Mer-Kin Outpost], monsterArray, true, maxPerTurnCost);

	set_property("choiceAdventur312", "");
}


void grindEdgarFitzsimmons(int maxPerTurnCost) {
	// drowned sailor
	// 	set_property("choiceAdventure299", "2");
	// 	monster mainTarget = $monster[drowned sailor];
	// 	monster [] monsterArray = {$monster[drowned sailor]};
	// unholy diver
	set_property("choiceAdventure299", "1");
	monster mainTarget = $monster[unholy diver];
	monster [] monsterArray = {$monster[unholy diver]};

	grindSeaLocation($location[The Wreck of the Edgar Fitzsimmons], monsterArray, true, maxPerTurnCost);

	set_property("choiceAdventure299", "");
}


// champagne bottle is overkill (mer-kin diver's biggest drop is 10%), but other +item is not
void grindMarinaraTrench(int maxPerTurnCost) {
	monster [] monsterArray = {$monster[mer-kin diver]};
	grindSeaLocation($location[The Marinara Trench], monsterArray, true, maxPerTurnCost);
}


void grindCoralCorral(int maxPerTurnCost) {
	monster [] monsterArray = {$monster[sea cow], $monster[sea cowboy]};
	grindSeaLocation($location[The Coral Corral], monsterArray, true, maxPerTurnCost);
}


void grindAnemoneMine(int maxPerTurnCost) {
	monster [] monsterArray = {$monster[killer clownfish]};
	grindSeaLocation($location[Anemone Mine], monsterArray, true, maxPerTurnCost);
}


// target mer-kin tippler if we don't targetNurseShark
void grindDiveBar(int maxPerTurnCost, boolean targetNurseShark) {
	seaQuest($location[The Dive Bar], true);

	monster [] monsterArray = {$monster[nurse shark]};
	if (!targetNurseShark) {
		monsterArray = {$monster[mer-kin tippler]};
	}

	grindSeaLocation($location[The Dive Bar], monsterArray, true, maxPerTurnCost);

	// shop put -1 nurse's hat;
	// shop put -1 sea salt scrubs;
	// shop put -250 slug of rum;
	// shop put -250 alewife ale;
	// shop put -250 mer-kin pinkslip;
	// shop put * blank prescription sheet;
	// print dolphinItem
}


void grindMadnessReef(int maxPerTurnCost) {
	monster [] monsterArray = {$monster[jamfish], $monster[magic dragonfish]};
	grindSeaLocation($location[Madness Reef], monsterArray, true, maxPerTurnCost);
}


void grindMerkinGym(int maxPerTurnCost) {
	monster [] monsterArray = {$monster[Mer-kin poseur]};
	grindSeaLocation($location[Mer-kin Gymnasium], monsterArray, true, maxPerTurnCost);
}


void grindMerkinElementary(int maxPerTurnCost) {
	monster [] monsterArray = {$monster[Mer-kin punisher]};
	grindSeaLocation($location[Mer-kin Elementary School], monsterArray, true, maxPerTurnCost);
}



// -------------------------------------
// AUTOMATION -- GRINDING -- END GAME
// -------------------------------------


void grindHobopolisSewers(int maxPerTurnCost) {
	// umbrella reduces sewers by 1 turn out of 15, 30% of the time with +25% NC
	int umbrellaCostSaving = kTurnValue; // AT MOST
	int umbrellaCostToUse = current_price($item[gatorskin umbrella]) - umbrellaCostSaving;
	int neededDropBonus = itemDropBonusNeededToGuarantee($item[bottle of sewage schnapps], $monster[C. H. U. M.]);
	print("grindHobopolisSewers, maxPerTurnCost: " + maxPerTurnCost + ", cost to use umbrella: " + umbrellaCostToUse, "green");

	setDefaultState();
	setCurrentMood("-combat");

	// ACQUIRE ITEMS
	boolean shouldUseUmbrella = umbrellaCostToUse < 0;
	if (shouldUseUmbrella && !have_item($item[gatorskin umbrella]))
		newAcquire($item[gatorskin umbrella], 1, kTurnValue / 10);

	// DRESSUP
	// don't equip the pants so we can get more +item and don't equip the thumb ring so we can get more -combat
	string maxString = "0.2 item, 0.1 pickpocket chance, 0.01 init, equip Li'l Businessman Kit, equip hobo code binder, -equip mafia thumb ring, -equip pantogram pants";
	if (shouldUseUmbrella) maxString += ", equip gatorskin umbrella";

	automate_dressup($location[A Maze of Sewer Tunnels], "-20 combat", "default", maxString);

	if (item_drop_modifier() < neededDropBonus)
		automate_dressup($location[A Maze of Sewer Tunnels], "-20 combat", "item", maxString);
	setParkaMode("spikolodon"); // dressup is changing the parka mode

	monster [] targets = {$monster[C. H. U. M.]};
	int advs = my_adventures();
	while (true) {
		// ACQUIRE ITEMS
		boolean shouldUseUmbrella = umbrellaCostToUse < 0;
		if (shouldUseUmbrella && !have_item($item[gatorskin umbrella]))
			newAcquire($item[gatorskin umbrella], 1, kTurnValue / 10);

		// BUFFS
		if (item_drop_modifier() < neededDropBonus && isAsdonWorkshed())
			safeFueledAsdonMartin($effect[Driving Observantly], 1);

		healAndRemoveDebuffsWithMPRestore();

		if ("_spikolodonSpikeUses".get_property().to_int() < 5) {
			dressup("equip Jurassic Parka (spikolodon mode)");
			setParkaMode("spikolodon"); // dressup is changing the parka mode
			set_property(kSpikolodonNextCombatKey, "true");
		} else {
			dressup();
		}

		assert(combat_rate_modifier() <= -25.0 || equipped_amount($item[&quot;I Voted!&quot; sticker]) > 0
			|| (equipped_amount($item[Jurassic Parka]) > 0 && "_spikolodonSpikeUses".get_property().to_int() < 5 && "parkaMode".get_property() == "spikolodon"), "not enough -combat"); // unless we're redirecting, we should have -25 combat
		targetMob($location[A Maze of Sewer Tunnels], targets, $skill[none], 1, false, maxPerTurnCost); // not optimal, i.e. continue if we're out of banishers

		// when we reach the end of the sewers, we will be spending no turns
		if (my_adventures() == advs)
			break;
		advs = my_adventures();
	}
}



int slimeTubeTurnsToSpend() {
	int turnsToSpend = have_effect($effect[Coated in Slime]);
	if (turnsToSpend == 0)
		turnsToSpend = max(1, 11 - ceil(monster_level_adjustment() / 100.0));
	return turnsToSpend;
}


boolean clearCoatedInSlime() {
	if (get_property("_hotTubSoaks") < 5)
		cli_execute("hottub");
	else
		cli_execute("chamois");
	return have_effect($effect[Coated in Slime]) == 0;
}


int expectedCoatedInSlimeDmg(int coatedTurns) {
	int effective_turns = max(0, 11 - coatedTurns);
	float res_percent = 100.0 - elemental_resistance($element[slime]);
	return expression_eval("ceil(" + effective_turns + "^2.727*" + res_percent + "*" + my_maxhp() + "/10000)");
}

int expectedCoatedInSlimeDmg() {
	int coatedTurns = have_effect($effect[Coated in Slime]);
	if (coatedTurns == 0)
		coatedTurns = max(1, 11 - ceil(monster_level_adjustment() / 100.0));
	return expectedCoatedInSlimeDmg(coatedTurns);
}

int safeExpectedCoatedInSlimeDmg() {
	return expectedCoatedInSlimeDmg() * kExpectedDamageSafetyFactor;
}


void prepForSlimeTube(int turnsToSpend, boolean wantEngulfed, boolean burnSpleen) {
	int coatedTurns = have_effect($effect[Coated in Slime]);

	max_mcd();

	if (wantEngulfed)
 		setCurrentMood("ml, -combat");
	else
 		setCurrentMood("ml, +combat");

	if (burnSpleen && my_spleen_use() < spleen_limit())
		cli_execute_if_needed("synthesize Synthesis: Strong", $effect[Synthesis: Strong], turnsToSpend);

	if (isAsdonWorkshed())
		safeFueledAsdonMartin($effect[Driving Recklessly], turnsToSpend);
}


// adventure once in the slime tube
void adv1SlimeTube() {
	int expectedDmg = safeExpectedCoatedInSlimeDmg();
	haveAtLeastHPWithMPRestore(expectedDmg);
	restore_mp(mp_cost($skill[saucestorm]) * 6);

	print("entering combat with " + my_hp() + " hp, expecting " + expectedDmg + " dmg.");

	adv1($location[The Slime Tube], -1, "");
	assert(have_effect($effect[Beaten Up]) == 0, "unexpectedly beaten up! expected dmg: " + expectedDmg);
	//if (!contains_monster($location[The Slime Tube], last_monster())) abort("wandering monster? " + last_monster());
}


// adventure in the slime tube with the current outfit until adventuring would cause us to be beaten up
// then clear the Coated in Slime debuff with either a hottub soak or a chamois
// buffs with free/cheap monster-level adjustment skills
void slimetube(boolean wantEngulfed, boolean burnSpleen) {
	print("slimetube with " + have_effect($effect[Coated in Slime]) + " turns of Coated in Slime, Slime res: " + numeric_modifier("Slime Resistance"), "blue");

	prepForSlimeTube(slimeTubeTurnsToSpend(), wantEngulfed, burnSpleen);

	int expectedDmg = safeExpectedCoatedInSlimeDmg();
	int tries = 15;
	while (expectedDmg < my_maxhp() && tries > 0) {
		adv1SlimeTube();
		expectedDmg = safeExpectedCoatedInSlimeDmg();
		tries--;
	}

	print("exiting The Slime Tube with " + have_effect($effect[Coated in Slime]) + " turns of Coated in Slime", "green");

	clearCoatedInSlime();
	assert(have_effect($effect[Coated in Slime]) == 0, "still have Coated in Slime!!!");
}


// for low-ml, casual grinding
// dresses in low-ml outfit for first adventure (i.e. without Coated in Slime)
// otherwise, dresses in high-ml outfit
void slimetubeWithDressup(boolean wantEngulfed, boolean burnSpleen, int runawayMaxCost) {
	// COATED IN SLIME debuff if we don't have it
	// getting it with lower ML means we can last longer
	int coatedTurns = have_effect($effect[Coated in Slime]);
	if (coatedTurns == 0) {
        print("getting Coated in Slime", "blue");
		uneffect($effect[Ur-Kel's Aria of Annoyance]);
		setCurrentMood("+combat");

		string maxString = "-ml, -equip pantogram pants";
		if (canFreeRunaway(runawayMaxCost))
			maxString += ", -equip mafia thumb ring";

		automate_dressup($location[The Slime Tube], "10 item", "robortender", maxString);

		int tries = 3;
		while (coatedTurns == 0 && tries > 0) {
			ActionRecord freeRunaway;
			string tweakString = "";
			if (canFreeRunaway(runawayMaxCost)) {
				freeRunaway = chooseFreeRunaway(runawayMaxCost);
				tweakString = equipStringForAction(freeRunaway);
			}
			dressup(tweakString);
			logEquipment(true);

			restore_mp(mp_cost($skill[saucestorm]) * 6);
			string aPage = advURLWithWanderingMonsterRedirect($location[The Slime Tube]);

			if (isErrorPage(aPage)) {
				print("got an error page:\n" + aPage, "red");
				abort("slimetubeWithDressup: didn't get to the slime tube");
			}
			if (handling_choice()) {
				run_choice(-1);
				continue;
			}

			if (canFreeRunaway(runawayMaxCost) && contains_monster($location[The Slime Tube], last_monster())) {
				steal();
				takeAction(freeRunaway);
			} else
				run_combat();
			postAdventure();

			coatedTurns = have_effect($effect[Coated in Slime]);
			tries--;
		}

		// 		assert(last_monster() == $monster[slime tube monster], "wandering monster? " + last_monster());
	}
	assert(have_effect($effect[Coated in Slime]) > 0, "didn't get Coated in Slime??");

	// MAIN EVENT -- we will have Coated in Slime at this point
	int slimeResPriority = 200 / (coatedTurns ** 1.5); // increase slime res with each less Coated in Slime turn

	use_familiar($familiar[robortender]); equip($item[toggle switch (Bartend)]);
	clearAutomateDressup(); // we're running close to the wire at the end of each run, so no auto dressup (TODO early turns could work)
	maximize("0.1 ml, " + slimeResPriority + " slime res, -familiar, item", false);
	maximize("0.1 ml, " + slimeResPriority + " slime res, -familiar, item", false);
	logEquipment(true);

	prepForSlimeTube(slimeTubeTurnsToSpend(), wantEngulfed, burnSpleen);
	// 	assert(numeric_modifier("Slime Resistance") >= 3.0, "not enough slime resistance to proceed!");

	int expectedDmg = safeExpectedCoatedInSlimeDmg();
	int tries = 15;
	while (expectedDmg < my_maxhp() && tries > 0) {
		adv1SlimeTube();

		coatedTurns = have_effect($effect[Coated in Slime]);
		slimeResPriority = 200 / (coatedTurns ** 1.5); // increase slime res with each less Coated in Slime turn
		maximize("0.1 ml, " + slimeResPriority + " slime res, -familiar, item", false);
		logEquipment(true);

		expectedDmg = safeExpectedCoatedInSlimeDmg();
		tries--;
	}

	print("exiting The Slime Tube with " + have_effect($effect[Coated in Slime]) + " turns of Coated in Slime", "green");

	clearCoatedInSlime();
	assert(have_effect($effect[Coated in Slime]) == 0, "still have Coated in Slime!!!");
}



void grindDreadsylvania(location dreadLoc, int grindTurns) {
	setDefaultState();
	setCurrentMood("+combat, [primestat]gains");
	string maxString = "+combat, 0.01 mp regen, -equip pantogram pants"; // not sure if we should equip the pantogram pants or not

	if (my_basestat($stat[muscle]) < 200) {
		if (!user_confirm("Can't equip the dreadful glove (need 200 base mus). Continue without the glove?", 60000, false))
			abort();
	} else
		maxString += ", equip dreadful glove";

	if (my_basestat($stat[moxie]) < 200) {
		if (!user_confirm("Can't equip the dreadful fedora (need 200 base mox). Continue without the fedora?", 60000, false))
			abort();
	} else
		maxString += ", equip dreadful fedora";

	if (my_basestat($stat[mysticality]) < 200) {
		if (!user_confirm("Can't equip the dreadful sweater or Dreadsylvania Auditor's badge (need 200 base mys). Continue without these?", 60000, false))
			abort();
	} else
		maxString += ", equip dreadful sweater, equip Dreadsylvania Auditor's badge";

	buffForItemDrop(grindTurns, dreadLoc, false);
	automate_dressup(dreadLoc, "10 item", "item", maxString);

	healAndRemoveDebuffsWithMPRestore();
	redirectAdventure(dreadLoc, grindTurns);
}



void grindTatteredScrapOfPaper(int kills, int maxPerTurnCost) {
	setDefaultMood();
	automate_dressup($location[The Haunted Library], "item", "item", "+switch cat burglar");

	if (isAsdonWorkshed())
		fueled_asdonmartin("observantly", kills);
	briefcase_if_needed($effect[Items Are Forever], kills);
	// sweetSynthesis($effect[Synthesis: Collection], kills); // analysis indicates better meat/turn with coffee pixie sticks

	tm($location[The Haunted Library], $monster[bookbat], $skill[none], kills, true, maxPerTurnCost);
}



// -------------------------------------
// AUTOMATION -- GRINDING -- ULTRARARE
// -------------------------------------

// #PYEC
void grindRepaidDiaper(int times) {
	setDefaultState();
	try {
		skill [] songsToPlay = {$skill[Carlweather's Cantata of Confrontation]};
		ensureSongRoom(songsToPlay);
		setCurrentMood("+combat, [primestat]gains");
// 		setCurrentMood("+combat, ml, [primestat]gains");

		automate_dressup($location[Inside the Palindome], "item", "default", "+10 combat");
		healAndRemoveDebuffsWithMPRestore();
		monster [] bestTarget = {$monster[Bob Racecar], $monster[Racecar Bob]};
		targetMob($location[Inside the Palindome], bestTarget, $skill[none], times, false, 0); // false = not optimal (will continue without banishes), 0 = maxPerTurnCost
	} finally {
	}
}



void grindPlatinumYendoranExpressCard(int times) {
	if (get_property("lastPlusSignUnlock").to_int() < my_ascensions()) {
		print("WARNING: haven't gained access to Dungeon of Doom!");
		waitq(5);
	}

	setDefaultState();
	try {
		saveAndSetProperty("choiceAdventure25", "1"); // 1 for magic lamp, 2 for mimic, 3 for skip

		skill [] songsToPlay = {$skill[Carlweather's Cantata of Confrontation]};
		ensureSongRoom(songsToPlay);
		setCurrentMood("+combat, [primestat]gains");
// 		setCurrentMood("+combat, ml, [primestat]gains");

		if (get_property("lastPlusSignUnlock").to_int() < my_ascensions()) {
			// target the Quantum Mechanic for it's PP-only item (stack of cash)
			// TODO targetting doesn't work because mafia reports the location as Dungeon of Doom, which means all the monsters are detected as wanderers
			automate_dressup($location[The Enormous Greater-Than Sign], "item", "default", "+20 combat 20 min");
			healAndRemoveDebuffsWithMPRestore();
			redirectAdventure($location[The Enormous Greater-Than Sign], times);
		} else {
			automate_dressup($location[The Dungeons of Doom], "item", "default", "+10 combat, 2 pickpocket chance, init");
			healAndRemoveDebuffsWithMPRestore();
			monster [] bestTarget = {$monster[Uppercase Q]};
			targetMob($location[The Dungeons of Doom], bestTarget, $skill[none], times, false, 0); // false = not optimal (will continue without banishes), 0 = maxPerTurnCost
		}


	} finally {
		restoreSavedProperty("choiceAdventure25");
	}
}

void grindPlatinumYendoranExpressCard() {
	grindPlatinumYendoranExpressCard(min(my_adventures(), 20));
}



// -------------------------------------
// AUTOMATION -- GRINDING -- EVENTS
// -------------------------------------

void donateResourcesCrimbo2020(boolean allResources, string player) {
	string pageResult;

	if (allResources) {
		pageResult = visit_url("/inv_use.php?pwd&which=3&whichitem=10685", true, false);
		pageResult = visit_url("/choice.php?whichchoice=1442&option=1&pwd&who=" + player, true, false);
		if (pageResult.contains_text("You fill out all the appropriate forms"))
			print("sent food to " + player);
		else
			print("send failed!", "red");

		pageResult = visit_url("/inv_use.php?pwd&which=3&whichitem=10686", true, false);
		pageResult = visit_url("/choice.php?whichchoice=1443&option=1&pwd&who=" + player, true, false);
		if (pageResult.contains_text("You fill out all the appropriate forms"))
			print("sent booze to " + player);
		else
			print("send failed!", "red");
	}

	pageResult = visit_url("/inv_use.php?pwd&which=3&whichitem=10687", true, false);
	pageResult = visit_url("/choice.php?whichchoice=1444&option=1&pwd&who=" + player, true, false);
	if (pageResult.contains_text("You fill out all the appropriate forms"))
		print("sent candy to " + player);
	else
		print("send failed!", "red");
}



void grindCrimbo2024Boss(location crimboLo) {
    if (mayamCalendarUsesAvailable() >= 1 && !"_mayamSymbolsUsed".get_property().contains_text("chair"))
		cli_execute("mayam rings chair yam cheese explosion"); // 5 free rests

	// boss is guaranteed??
	if (currentlySneaking()) {
		automate_dressup(crimboLo, "-combat", "shorter-order cook", "prismatic dmg");
//		adventure(crimboLo, 1);
	}
}



void grindCrimbo2019(location seaLoc, monster sideCritter, int kills) {
	if (available_amount($item[cozy scimitar]) == 0)
		fullAcquire($item[cozy scimitar]);

	if (seaLoc == $location[gingerbread reef] || seaLoc == $location[The Wreck of the H. M. S. Kringle] || seaLoc == $location[The Impenetrable Kelp-Holly Forest]) {
		prepForSea(seaLoc, true);
		automate_dressup(seaLoc, "", $familiar[red-nosed snapper], "item, +equip cozy scimitar, +equip mime army infiltration glove, +equip thumb ring");
	} else {
		seaQuest(seaLoc, true);
	}

	healAndRemoveDebuffsWithMPRestore();

	// stop when the cozy wears out
	clearGoals();
	add_item_condition(1, $item[fish scimitar]);

	monster [] monsterArray = {sideCritter, $monster[dolphin "orphan"]};
	targetMob(seaLoc, monsterArray, $skill[none], kills, false, kMaxInt); // not optimal, max cost per turn
}


void grindDolphinOrphans(location seaLoc, monster sideCritter, int kills) {
	fullAcquire($item[cozy scimitar]);
	if (seaLoc == $location[gingerbread reef] || seaLoc == $location[The Wreck of the H. M. S. Kringle] || seaLoc == $location[The Impenetrable Kelp-Holly Forest]) {
		prepForSea(seaLoc, true);
		clearAutomateDressup();
		use_familiar($familiar[red-nosed snapper]);
		maximize("item, +equip cozy scimitar, +equip mime army infiltration glove, +equip thumb ring", false);
	} else {
		seaQuest(seaLoc, true);
	}

	healAndRemoveDebuffsWithMPRestore();

	monster [] monsterArray = {$monster[dolphin "orphan"]};
	if (sideCritter != $monster[none])
		monsterArray = {sideCritter, $monster[dolphin "orphan"]};
	targetMob(seaLoc, monsterArray, $skill[none], kills, false, kMaxInt); // not optimal, max cost per turn
}



// -------------------------------------

void doBounty() {
	if (!to_boolean(get_property("_smm.BountyCheckDone"))) {
		cli_execute("bounty");
		if (dailyGrindConfirm("stopForBounty", "stop for bounty?", false))
			abort("bounty");
		else
			set_property("_smm.BountyCheckDone", "true");
	}
}



void dailyNoAdventureGrind() {
	smmSpendDayStart();
	secondBreakfast();
	smmIRDailyRoute(true,true);
	burnMP(-500);

	grindJellyWithEnemyReplacement(true, true, $item[cold jelly], true);

	dailyDeedsAdv(); // 0 adv
	LOVadv($item[LOV Earrings], $effect[Wandering Eye Surgery], $item[LOV Echinacea Bouquet]);
	burnHP();
	burnMP();

	grindScience(true);
	cli_execute("nep prep; nep party;"); // Neverending Party -- prep or prephard
}


void dailyFishingGrind(int [location] endGameTurnsSpent, int maxPerTurnCost) {
	print("dailyFishingGrind", "green");

	// SEA QUESTING/GRINDING
	if (have_effect($effect[Fishy]) > 1) { //  && breatheWaterTurns() >= 1 we won't have breathe water the first time through
		if (!to_boolean(get_property("_smm.SeaPreGrindDone"))) { // sea preparation has its own completion flag
			seaQuest($location[the coral corral], true);
			currentIncomeSea();
    		set_property("_smm.SeaPreGrindDone", "true");
		}

        // if we're not set for sea at this point, we must have burned it already
    	if (have_effect($effect[Fishy]) == 0 || breatheWaterTurns() == 0)
            return;

		if (get_property("seahorseName") == "")
			abort("sea quest isn't complete!"); // TODO automate sea quest
		else {
			location grindLoc = $location[The Marinara Trench];
			if ( ! "mapToTheMarinaraTrenchPurchased".get_property().to_boolean()) {
				if ("mapToAnemoneMinePurchased".get_property().to_boolean())
					grindLoc = $location[Anemone Mine];
				else
					grindLoc = $location[The Dive Bar];
			}

			if ((!property_exists("_smm.DoSeaQuest") && dailyGrindConfirm("sea", "Grind sea location: " + grindLoc + "?", true)) || "_smm.DoSeaQuest".get_property().to_boolean()) {
				set_property("_smm.DoSeaQuest", "true");
				switch (grindLoc) {
					case $location[The Marinara Trench]:
						grindMarinaraTrench(maxPerTurnCost); // unholy diver
						break;

					case $location[Anemone Mine]:
						grindAnemoneMine(maxPerTurnCost);
						break;

					case $location[The Dive Bar]:
						grindDiveBar(maxPerTurnCost, true); // true = target nurse shark
						break;

					case $location[Madness Reef]:
						grindMadnessReef(maxPerTurnCost); // jamfish, magic dragonfish
						break;
				}
			} else {
				set_property("_smm.DoSeaQuest", "false");
				return;
			}
		}

		assert(have_effect($effect[Fishy]) == 0 || breatheWaterTurns() == 0, "we should have used all the Fishy OR all the breathing buff by now!");
	}
}

void dailyFishingGrind(int maxPerTurnCost) {
	int [location] endGameTurnsSpent = endGameTurnsSpent();
	dailyFishingGrind(endGameTurnsSpent, maxPerTurnCost); // 20 turns, burns item buffs
}



void dailyGrind() {
	boolean unused;
	int maxPerTurnCost = my_class() == $class[seal clubber] ? 0 : 100; // Batter Up! is a beast

	// default is false and we set to true iff we have a significant amount of Fishy
	if (have_effect($effect[Fishy]) >= 8)
		set_property(gDailyFishingGrindKey, "true");

	smmSpendDayStart(); // opening Meat for the day's spending budget, before anything is earned or bought
	stockStore(gkStoreHeartbeat);
	int [location] endGameTurnsSpent = endGameTurnsSpent();

	if (!get_property(gkSecondBreakfastDoneKey).to_boolean()) {
		secondBreakfast(endGameTurnsSpent);
		burnHP();
		burnMP();
	}

	smmIRDailyRoute(false,true);
	dailyDeedsAdv(); // 0 adv

	// if we have the Fishy buff from the pipe from yesterday
	if (get_property(gDailyFishingGrindKey).to_boolean())
		dailyFishingGrind(endGameTurnsSpent, maxPerTurnCost); // 20 turns, burns item buffs

	// stuff that needs BANISHERS
	doBounty(); // 20 adv, 5 banishers?
	if (!to_boolean(get_property("_smm.UseBanishersConfirmDone")) && !dailyGrindConfirm("useBanishers", "We're about to use up the banishers. Continue?", true))
		abort("user aborted");
	set_property("_smm.UseBanishersConfirmDone", "true");

	// stuff that needs ITEM DROP -- buffs AFTER this point in case we want to stop and burn the 50 Dreadsylvania turns before boss
	endGameTurnsSpent = endGameTurnsSpent(); // refresh: the clan may have killed more Dread monsters since the start of the run
	if (!get_property("_smm.HighItemConfirmDone").to_boolean()
	    && (get_property("garbageChampagneCharge").to_int() > 0 || !get_property("_garbageItemChanged").to_boolean())
	    && !dailyGrindConfirm("highItem", "Continue to high item drop section? Dread woods: "
	                     + endGameTurnsSpent[$location[Dreadsylvanian Woods]] + ", village: "
	                     + endGameTurnsSpent[$location[Dreadsylvanian Village]] + ", castle: "
	                     + endGameTurnsSpent[$location[Dreadsylvanian Castle]], true))
		abort("user aborted before the high item drop section");
	set_property("_smm.HighItemConfirmDone", "true");

	// stuff that needs ITEM DROP
	if (garbageChampagneCharge() > 0)
		burnChampagneBottle( !isRegularClass()
							|| ! (endGameTurnsSpent[$location[Dreadsylvanian Woods]] < 930
								&& endGameTurnsSpent[$location[Dreadsylvanian Village]] < 930
								&& (my_basestat($stat[muscle]) >= 200
									&& my_basestat($stat[mysticality]) >= 200
									&& my_basestat($stat[moxie]) >= 200)) );
	grindScience(true); // useSweetSynthesis?
	if ("_questPartyFair".get_property() != "finished" && "_neverendingPartyFreeTurns".get_property().to_int() < 10) {
		cli_execute("nep prep; nep party;"); // Neverending Party -- prep or prephard
	}

	if (!to_boolean(get_property("_smm.LandPreGrindDone"))) {
		int birdsToSeek = 6 - to_int(get_property("_birdsSoughtToday"));
		if (have_skill($skill[seek out a bird]) && birdsToSeek > 0) {
			if (!use_skill($skill[seek out a bird], birdsToSeek)) // optional buff, don't stop the run over it
				print("couldn't seek out all " + birdsToSeek + " birds, continuing", "orange");
		}
		maximizeForItemDrop(1, $location[none]);
		// print-only reports that cost a turn of Asdon fuel and two outfit changes: opt in
		if (get_property("smm.dailyGrind.incomeReport") == "true") {
			currentIncome();
			incomeCalculator();
		}
		set_property("_smm.LandPreGrindDone", "true");
	}

	// keep banishes back only for the banisher grinds still to do today
	boolean beerLensPending = get_property("_beerLensDrops").to_int() < 3 && dailyGrindMayRun("beerLens");
	boolean ghostCostumePending = !to_boolean(get_property("_smm.GotGhostCostume")) && my_session_items($item[li'l ghost costume]) < 1 && dailyGrindMayRun("ghostCostume");
	int kSaveBanishes = (beerLensPending ? 4 : 0) + (ghostCostumePending ? 8 : 0); // for grindBeerLens and grindGhostCostume below
	if (banishesAvailable(maxPerTurnCost) > kSaveBanishes && my_adventures() > 10 && !to_boolean(get_property("_smm.GrindDone")) && dailyGrindMayRun("oasis")) {
		dailyGrindBegin();
		int perAdventureCost = perAdventureCost($location[The Oasis]);
		int beatleValue = scarabBeatleValue(perAdventureCost);
		int blurValue = monsterCurrentTotalMeatValue($monster[blur], false) - perAdventureCost;
		print("swarm of scarab beatles: " + beatleValue + ", blurs: " + blurValue, "blue");

		if (beatleValue > kTurnValue && beatleValue > blurValue)
			grindScarabBeatles(maxPerTurnCost, true, kSaveBanishes); // maxPerTurnCost, getBlur, banishes to save
		else if (blurValue > kTurnValue)
			grindDrumMachine(maxPerTurnCost, true, kSaveBanishes); // maxPerTurnCost, getBeatlesOnYellowRay, banishesToSave

		dailyGrindEnd("oasis");
	}
	// Set even when no farming happened: this phase saves banishers and may skip
	// farming (or have no banishes available) or leave yellow rays unused.
	set_property("_smm.GrindDone", "true");

	// stuff that needs BANISHERS total 13 right now
	if (beerLensPending) {
		dailyGrindBegin();
		grindBeerLens(maxPerTurnCost); // 3-5 adv, 4 banishers
		dailyGrindEnd("beerLens");
	}
	if (ghostCostumePending) {
		dailyGrindBegin();
		grindGhostCostume(); // 5-11 adv, 9 banishers
		dailyGrindEnd("ghostCostume");
	}

	// stuff that doesn't need item drop or banishes
	if (dailyGrindMayRun("spacegate")) {
		dailyGrindBegin();
		try {
			saveAndSetProperty("choiceAdventure1251", "6");
			grindSpacegate(gkSpacegateCoordinates);
		} finally {
			restoreSavedProperty("choiceAdventure1251");
		}
		dailyGrindEnd("spacegate");
	}

	// FANTASYREALM: fr.ash picks the reward closest to Museum #1 (smm.frTarget names one instead)
	boolean frAlreadyDone = "_fantasyRealmDone".get_property().to_boolean();
	if (frAlreadyDone || dailyGrindMayRun("fantasyRealm")) {
		dailyGrindBegin();
		if (!frAlreadyDone)
			cli_execute("fr best");
		item frTargetItem = get_property("_smm.frTarget").to_item();
		// warn instead of stopping: the grinds below still have daily resources to use
		if (frTargetItem == $item[none] && !frAlreadyDone)
			print("fr best didn't record its target in _smm.frTarget, continuing", "red");
		if (frTargetItem != $item[none]) {
			if (my_session_items(frTargetItem) <= 0 && !"_fantasyRealmDone".get_property().to_boolean())
				print("didn't get " + frTargetItem + ", continuing", "red");
			unused = cli_execute("dc top10 " + frTargetItem);
		}
		set_property("_fantasyRealmDone", "true");
		dailyGrindEnd("fantasyRealm");
	}

	// PIRATE REALM
	item prGoalItem = $item[Red Roger's reliquary];
	if (my_session_items(prGoalItem) <= 0 && !"_smm.PirateRealmDone".get_property().to_boolean() && dailyGrindMayRun("pirateRealm")) {
		dailyGrindBegin();
		cli_execute("pr short"); // grind PirateRealm
		dailyGrindEnd("pirateRealm");
	}

	if (dailyGrindMayRun("dailyDungeon")) {
		dailyGrindBegin();
		grindDailyDungeon();
		dailyGrindEnd("dailyDungeon");
	}
	if (dailyGrindMayRun("drip")) {
		dailyGrindBegin();
		grindDrip(); // TODO: don't run on the day of breaking the prism
		dailyGrindEnd("drip");
	}

	if (get_property("dolphinItem") != "") {
		grindDolphinItem();
	}

	if (!get_property("_workshedItemUsed").to_boolean() && isAsdonWorkshed()) {
		if (!have_item($item[model train set])) {
			print("Asdon Martin is in the workshed but we have no model train set to swap to, leaving the Asdon in place", "orange");
		} else {
			// Driving Observantly outlasts the day; smm.dailyGrind.asdonTurns sets how much fuel to commit before the swap
			int goalDuration = get_property("smm.dailyGrind.asdonTurns") == "" ? 600 : max(1, get_property("smm.dailyGrind.asdonTurns").to_int());
			unused = fueled_asdonmartin("observantly", goalDuration); // the assert below reports a failure more clearly
			assert(have_effect($effect[Driving Observantly]) >= goalDuration, "didn't get " + goalDuration + " turns of Driving Observantly");
			assert(use(1, $item[model train set]), "couldn't swap the workshed to the model train set");
		}
	}

    int [int, string] leaderboard = gingerbreadLeaderboard();
    boolean winSprinkles = leaderboard.rank1Amount() <= 3000; // we can get to 3000 in 30 turns
    int gbcTurns = effectiveGingerbreadCityTurns();

    if (winSprinkles && gbcTurns == 0) {
        print("We can win the Gingerbread City sprinkles leaderboard, but this should be done manually with 'gbc win'");
        printTop10List(leaderboard);
    } else if (winSprinkles && gbcTurns < 20) {
        print("Gingerbread City is part done (" + gbcTurns + " turns) and the sprinkles leaderboard looked winnable, finish it manually", "orange");
        printTop10List(leaderboard);
    } else if (!winSprinkles && gbcTurns < 20 && dailyGrindMayRun("gingerbread")) {
        if (gbcTurns > 0 || dailyGrindConfirm("gingerbreadItems", "We can't win the Gingerbread City sprinkles leaderboard, should we grind items?", true)) {
            dailyGrindBegin();
            if (!cli_execute("gbc items")) // last grind of the day, report instead of stopping
                print("'gbc items' failed, finish Gingerbread City manually", "red");
            dailyGrindEnd("gingerbread");
        }
    }

    printEndGameTurnsSpent();
    printDailyGrindLedger();

    // spend up to half of what the day has netted so far: positive-return buys, then Display Case items on sale
    stockStore(gkStoreHeartbeat);
    smmSpendRun();

	timeToRollover();
}



// burn all remaining buffs and 0-adv stuff like free combats
void good_night() {
	boolean unused;
	if (!isOverdrunk()) abort("should be overdrunk before running good_night");

	if (!get_property("_bastilleGamesLockedIn").to_boolean()) {
		use_if_needed($item[sharkfin gumbo], $effect[Shark-Tooth Grin], gkBastilleBuffAmount);
		use_if_needed($item[boiling broth], $effect[Boiling Determination], gkBastilleBuffAmount);
		use_if_needed($item[interrogative elixir], $effect[Enhanced Interrogation], gkBastilleBuffAmount);
		unused = cli_execute("basty win");
	}
	assert(get_property("_bastilleGames").to_int() > 0, "didn't play Bastille Battalion but should have!");

	stockStore(gkStoreHeartbeat);
	smmSpendRun(); // tops up the day's budgeted buying with whatever was netted since dailyGrind

	useNashCrosbyStill();
	burnBuffs();
	burnSpleen();
	burnFreeUseItems();

	burnFreeCombats();
	burnInstaKills();

	burnFreeMP();
	burnFreeCrafting();
	burnFreeTurnGen();

	unused = cli_execute("latte refill cajun carrot guarna"); // meat, item, adv
	maximize("adventures, switch tot", false);

	print("burn sausages!!!!!!!!!!!!!!!", "red");
	burn_sausages(true); // called after maximizing adv, will ensure we don't overeat

	if (to_int(get_property("garbageChampagneCharge")) > 0)
		cli_execute("tote 2"); // broken champagne bottle
	else
		cli_execute("tote 5"); // makeshift garbage shirt

	printIRefuseSessionItems();

	if (!get_property("_guzzlrQuestAbandoned").to_boolean())
		print("we haven't abandoned a Guzzlr quest today!!!!", "red");
}



// -------------------------------------
// OUT OF RONIN/HARDCORE
// -------------------------------------

void setupCrafting() {
	if (!get_property("hasRange").to_boolean()) {
		fullAcquire($item[Dramatic&trade; range], 1, 950);
		use(1, $item[Dramatic&trade; range]);
	}
	if (!get_property("hasCocktailKit").to_boolean()) {
		fullAcquire($item[Queue Du Coq cocktailcrafting kit], 1, 950);
		use(1, $item[Queue Du Coq cocktailcrafting kit]);
	}
}



void pullEverythingAfterRonin() {
	batch_open();
	int [item] pull_map;
	file_to_map("unrestricted_pull_map.txt", pull_map);
	foreach pull_item, amt in pull_map {
		print("pulling " + (amt == 0 ? "all" : amt.to_string() + " " + pull_item));
		take_storage(amt == 0 ? storage_amount(pull_item) : amt, pull_item);
	}
	print("pull batch successful: " + batch_close());
	cli_execute("pull * meat");
}



void useSkillbooksAfterRonin() {
	boolean unused;
	int [item] use_map;
	file_to_map("unrestricted_use_map.txt", use_map);
	foreach use_item in use_map {
		print("using: " + use_item, "blue");
		if (have_item(use_item))
			unused = museumSafeUse(use_map[use_item], use_item);
	}
}



void latteAdventure(location place, string ingredient, int maxTurns) {
	print("latteAdventure looking for '" + ingredient + "' at: " + place + " within " + maxTurns + " turns", "green");

	clearGoals();
	setDefaultMoodForLocation(place);
	automate_dressup(place, "meat", "default", "equip latte lovers member's mug");

	if (check_counters(maxTurns, kDontAbort) && !isLatteIngredientUnlocked(ingredient))
		print("WARNING: counter possible before finishing latteAdventure (will abort script at counter) while looking for " + ingredient + " at " + place, "orange");

	int tries = maxTurns;
	while (!isLatteIngredientUnlocked(ingredient) && tries > 0) {
		assert(equipped_amount($item[latte lovers member's mug]) >= 1, "we aren\'t equipping the latte lovers member\'s mug");
		healIfRequiredWithMPRestore();
		if (!adv1(place))
			abort("latteAdventure: did not successfully adventure at " + place);
		tries--;
	}

	assert(isLatteIngredientUnlocked(ingredient), "latteAdventure: did not unlock " + ingredient + " at " + place + " within " + maxTurns + " turns");
	print("ingredient '" + ingredient + "' UNLOCKED!", "green");
}


void latteAdventure(location place, string ingredient) {
	latteAdventure(place, ingredient, 5);
}


// grind default latte lovers member's mug locations until we get their ingredient
void grindLatteIngredients() {
	string ingredient = nextLatteIngredient();
	while (ingredient != "") {
		assert(!isLatteIngredientUnlocked(ingredient), "nextLatteIngredient returned an unlocked ingredient");
		latteAdventure(kLatteLocations[ingredient], ingredient);
		ingredient = nextLatteIngredient();
	}
}



// TODO identify Dungeon of Doom potions?? i think these are being done in smmConsult.ash
void outOfRonin() {
	boolean unused;
	print("outOfRonin", "green");

	cli_execute("ccs unrestricted");
	set_property("choiceAdventure786", "6"); // skip pygmy office building NC
	set_property("gingerPhotoTaken", "false"); // for the sprinkle briefcase quest
	set_property("gotSugarRaygun", "false"); // for the sprinkle briefcase quest
	set_property("trackVoteMonster", "false"); // don't stop for the vote monster, we'll detect it ourselves
	max_mcd();
	cli_execute("briefcase unlock");

    // QUESTS
	getDocGalaktikQuest();
	getMeatsmithQuest();
	getArmoryQuest();
	getOldLandfillQuest();
	visit_url("/place.php?whichplace=sea_oldman&action=oldman_oldman", false, false); // visit the old man near the sea

    // PULLS AND ITEMS
	pullEverythingAfterRonin();
	pull_high_quantity_items(); // for use with the asdon martin
	fullAcquire(gkFishyGearToGet); // use(1, gkFishyGearToGet);
	setupCrafting();
	visit_url("/place.php?whichplace=sea_oldman&action=oldman_oldman&preaction=buytank&pwd", false, false); // scuba tank

	checkIfRunningOut($item[saltwaterbed], 50);
	if (have_item($item[saltwaterbed]))
		use(1, $item[saltwaterbed]);
	else
		print("no saltwaterbed!", "red");

    // FAMILIARS
	cycleFavouriteFamiliars();
	equip_all_familiars();

	// SKILLS
	useSkillbooksAfterRonin();
	unused = use_skill(1, $skill[spirit of cayenne]);

    // CLASS-SPECIFIC
	if (my_class() == $class[seal clubber]) {
		unused = use_skill(1, $skill[Iron Palm Technique]);
		unused = use_skill(1, $skill[blood sugar sauce magic]);
	}

	if (my_class() == $class[turtle tamer]) {
		unused = use_skill(1, $skill[Blessing of the Storm Tortoise]);
		unused = use_skill(1, $skill[blood sugar sauce magic]);
	}

	if (my_class() == $class[pastamancer]) {
		unused = use_skill(1, $skill[bind spice ghost]);
		print("GET canticle of carboloading from guild!!!!", "blue");
	}

	if (my_class() == $class[sauceror]) {
		unused = use(1, $item[Zu Mannk&auml;se Dienen (used)]);
	}

	if (my_class() == $class[disco bandit]) {
		unused = use(1, $item[Autobiography Of Dynamite Superman Jones (used)]);
	}

	if (my_class() == $class[accordion thief]) {
		print("CHECK FOR Ballad of Richie Thingfinder!!!!", "blue");
	}

    // BUFFS AND MOOD
	cli_execute("ballpit; spacegate vaccine 2"); // extra stats for extra MP
	setupMood();
	burnMP();
	burn_sausages(false);

    // PREP FOR AZAZEL
    secondBreakfast();
    dailyDeedsAdv();
    grindLatteIngredients();

	print("remember to twiddle the skill bar in the web UI to the generic skill selection (#1)", "blue");
	print("next up: Azazel's quest, then dailyGrind iff'n you got the time"); // #up next
}




// -------------------------------------
// GUILD
// -------------------------------------

// set the currently worn pants as a goal for the DB/AT guild starter quest
void setPantsGoal() {
	cli_execute("goal clear; goal add " + equipped_item($slot[pants]));
}

string check_gothy_sub() {
	return "sub checkGothy; if (match \"You watch him go, and soon realize he isn't actually running anywhere\" && !hasskill run like the wind) || (match \"The raver's movements suddenly become spastic and jerky\" && !hasskill pop and lock it) || (match \"The raver drops to the ground and starts spinning his legs wildly\" && !hasskill break it on down); skill gothy; attack; endif; endsub;";
}

string otc_main_sub() {
	fullAcquire($item[seal tooth]);
	return "sub otcMain; if (monstername \"*pop-and-lock*\" && hasskill pop and lock it) || (monstername \"*breakdancing*\" && hasskill break it on down) || (monstername \"*running man*\" && hasskill run like the wind); attack; attack; endif; use seal tooth; call checkGothy; endsub;";
}

void outside_the_club() {
	automate_dressup($location[outside the club], "raveosity", "", "-equip Kramco Sausage-o-Matic&trade;, -equip \"i voted!\" sticker, -equip Everfull Dart Holster");

	string combat_macro;
	if (have_skill($skill[pop and lock it]) && have_skill($skill[break it on down]) && have_skill($skill[run like the wind])) {
		combat_macro = default_sub();
	} else {
		combat_macro = init_sub() + check_gothy_sub() + otc_main_sub() + "sub outside_the_club; if !gotjump; call checkGothy; endif; call init; call otcMain; repeat; endsub; abort pastround 25; call outside_the_club;";
	}

	print("MACRO: " + combat_macro);
	adv1($location[outside the club], -1, combat_macro);
}

void db_nemesis() {
	//automate_dressup($location[The Nemesis' Lair], "mp regen", "", "+equip Shagadelic Disco Banjo, -equip \"i voted!\" sticker");
	dressup($location[none], "mp regen", "default", "+equip Shagadelic Disco Banjo, -equip \"i voted!\" sticker");
	adv1($location[The Nemesis' Lair], -1, default_sub());
}



// -------------------------------------
// ASCENSION
// -------------------------------------

void dehaunt_aboo_peak() {
	if (item_amount($item[a-boo clue]) * 30 < to_int(get_property("booPeakProgress"))) abort("not enough clues!");
	set_property("choiceAdventure611", 1);

	automate_dressup($location[a-boo peak], "", "", "spooky res, cold res, hp");
	while (to_int(get_property("booPeakProgress")) > 0) {
		healAndRemoveDebuffsWithMPRestore();
		if (!museumSafeUse(1, $item[a-boo clue])) abort("a-boo clues are kept for the Display Case");
		adventure(1, $location[a-boo peak], "");
	}
}



void junkyard_quest() {
	use_familiar($familiar[Robortender]);
	automate_dressup($location[Next to that Barrel with Something Burning in it], "", "", "outfit frat warrior fatigues, dr, da, hp, mox");
	fullAcquire($item[seal tooth]);
	healAndRemoveDebuffsWithMPRestore();
}



void scavenger_hunt() {
	automate_dressup($location[The Haunted Wine Cellar], "item", "", "+equip broken champagne bottle");
	healAndRemoveDebuffsWithMPRestore();
}

void scavenger_hunt_charge() {
	automate_dressup($location[The Haunted Wine Cellar], "ml 82 min", "", "+equip unstable fulminate");
	healAndRemoveDebuffsWithMPRestore();
}



// returns the percent done of the desert, taking into account all the Gnasir items
int desert_completion() {
	int rval = to_int(get_property("desertExploration"));
	if (item_amount($item[can of black paint]) > 0) rval += 15;
	if (item_amount($item[stone rose]) > 0) rval += 15;
	if (item_amount($item[worm-riding manual page]) >= 15 && item_amount($item[drum machine]) > 0) rval += 30;
	return rval;
}

void desert_quest() {
	use_familiar($familiar[Garbage Fire]);
	automate_dressup($location[The Arid, Extra-Dry Desert], "", "", "+equip uv-resistant compass");

	healAndRemoveDebuffsWithMPRestore();
	while ((to_int(get_property("desertExploration")) < 70 && item_amount($item[worm-riding manual page]) < 15) || (to_int(get_property("desertExploration")) < 40)) {
		if (have_effect($effect[Ultrahydrated]) < 1) {
			check_counters(kAbortOnCounter);
			fullAcquire($item[11-leaf clover]);
			adventure(1, $location[The Oasis], "");
		}
		check_counters(kAbortOnCounter);
		adventure(1, $location[The Arid, Extra-Dry Desert], "");
	}
}



void pyramid_quest_top() {
	automate_dressup($location[The Upper Chamber], "-combat", "default", "");
	healAndRemoveDebuffsWithMPRestore();
}


void pyramid_quest_mid() {
	automate_dressup($location[The Middle Chamber], "item", "item", "");
	healAndRemoveDebuffsWithMPRestore();
}



void lighthouse_quest() {
	automate_dressup($location[Sonofa Beach], "+combat", "default", "");
	healAndRemoveDebuffsWithMPRestore();
}



void orchard_quest() {
	use_familiar($familiar[XO Skeleton]);
	automate_dressup($location[The Hatching Chamber], "", "", "");
	healAndRemoveDebuffsWithMPRestore();
}



void nuns_quest() {
	use_familiar($familiar[Hobo Monkey]);
	automate_dressup($location[The Themthar Hills], "meat", "", "outfit frat warrior fatigues");
	healAndRemoveDebuffsWithMPRestore();
}



void island_war_frat() {
	use_familiar($familiar[Cat Burglar]);
	automate_dressup($location[the battlefield (frat uniform)], "item", "", "outfit frat warrior fatigues");
	healAndRemoveDebuffsWithMPRestore();
}
