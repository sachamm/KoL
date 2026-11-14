script "dc";
notify TQuilla;
since r26333;

import <smmUtils.ash>
string __dc_version = "1.0";

/**
gCLI display case utilities centered around maintaining top 10 collections while saving items in your inventory.

"dc help" in the gCLI for help.

Reads top 10 collections from Museum and caches that info for the day.

# TODO check Item Filters in preferences (bottom group), Keep One

@author Sacha Mallais (TQuilla #2771003)
*/

int gkDCOvershootAmount = get_property("smm.dcOvershootAmount") == "" ? 11 : get_property("smm.dcOvershootAmount").to_int(); // amount to overshoot the next highest top 10 item


// lazy init
item [item, int] gkIotMItems; // don't use directly, use iotmItems() instead
item [item, int] iotmItems() {
	if (count(gkIotMItems) == 0)
		gkIotMItems = {
			$item[Mr. Accessory] : {},

			$item[Dear Past Self Package] : {$item[Time-Spinner], $item[compounded experience], $item[time residue],
				$item[Riker's Search History], $item[Shot of Kardashian Gin], $item[Memory Disk\, Alpha], $item[Tea\, Earl Grey\, Hot]},
			$item[li'l orphan tot] : {$item[li'l knight costume], $item[li'l unicorn costume], $item[li'l candy corn costume], $item[li'l ghost costume], $item[hoarded candy wad]},
			$item[Granny Tood's Thanksgarden Catalog] : {$item[packet of thanksgarden seeds], $item[cornucopia], $item[megacopia], $item[bomb of unknown origin],
				$item[raw green beans], $item[glass casserole dish], $item[green bean casserole], // green bean casserole
				$item[raw cranberry sauce], $item[can opener], $item[cranberry cylinder], // cranberry cylinder
				$item[raw potato], $item[potato masher], $item[mashed potatoes], // mashed potatoes
				$item[raw sweet potato], $item[mini-marshmallow dispenser], $item[candied sweet potatoes], // candied sweet potatoes
				$item[raw mincemeat], $item[glass pie plate], $item[mince pie], // mince pie
				$item[raw bread], $item[bread mold], $item[bread roll], // bread roll
				$item[raw stuffing], $item[stuffing fluffer], $item[baked stuffing], // baked stuffing
				$item[raw turkey], $item[turkey blaster], $item[thanksgiving turkey], // thanksgiving turkey
				$item[raw gravy], $item[gravy boat], $item[warm gravy], // warm gravy
				$item[cashew]},
			$item[Build-a-City Gingerbread kit] : {$item[counterfeit city], $item[sprinkles],
				$item[briefcase full of sprinkles], $item[The Gingerbread Vigilante's Handbook],
				$item[gingerbread mask], $item[gingerbread tophat],
				$item[gingerbread waistcoat], $item[gingerbread hoodie],
				$item[gingerbread trousers],
				$item[gingerbread pistol], $item[sprinkle-begging cup], $item[sugar raygun], $item[gingerbread moneybag], $item[gingerbread gavel],
				$item[sour ball and chain], $item[candy dress shoes], $item[candy necktie], $item[gingerbeard], $item[gingerservo],
				$item[chocolate puppy], $item[candy dog collar], $item[gingerbread dog treat], $item[gingerbread spice latte],
				$item[gingerbread restraining order], $item[gingerbread cigarette],
				$item[animal part cracker], $item[gingerbread mug], $item[ginger beer], $item[gingerbread wine], $item[fake cocktail], $item[high-end ginger wine],
				$item[broken chocolate pocketwatch], $item[chocolate pocketwatch], $item[spare chocolate parts],
				$item[tainted icing], $item[industrial frosting], $item[gingerbread smartphone]},

			$item[hopeful candle] : {$item[pewter candlestick], $item[glob of melted wax], $item[wax hand], $item[wax face], $item[wax pancake], $item[wax booze]},

			$item[space planula] : {$item[space jellybicycle], $item[sea jelly],
				$item[hot jelly], $item[toast with hot jelly],
				$item[cold jelly], $item[toast with cold jelly],
				$item[spooky jelly], $item[toast with spooky jelly],
				$item[sleaze jelly], $item[toast with sleaze jelly],
				$item[stench jelly], $item[toast with stench jelly]},
			$item[heart-shaped crate] : {$item[LOV Elixir #3], $item[LOV Elixir #6], $item[LOV Elixir #9], $item[LOV Enamorang], $item[LOV Emotionizer], $item[LOV Extraterrestrial Chocolate], $item[LOV Echinacea Bouquet], $item[LOV Elephant]},
			$item[unpowered Robortender] : {$item[toggle switch (Bartend)], $item[toggle switch (Bounce)],
				$item[pickled grasshopper], $item[bottle of an&iacute;s], $item[bottle of novelty hot sauce], $item[elemental sugarcube], $item[peppermint sprig], $item[bottle of clam juice], $item[cocktail mushroom], $item[shot of granola liqueur], $item[can of cherry-flavored sterno], $item[lump of black ichor], $item[bottle of gregnadigne], $item[bottle of Cr&egrave;me de Fugu], $item[baby oil shooter], $item[fish head], $item[limepatch], $item[pile of dirt], $item[slime shooter], $item[imaginary lemon],
				$item[literal grasshopper], $item[double entendre], $item[Phlegethon], $item[Siberian sunrise], $item[mentholated wine], $item[low tide martini], $item[shroomtini], $item[morning dew], $item[whiskey squeeze], $item[great old fashioned], $item[Gnomish sagngria], $item[vodka stinger], $item[extremely slippery nipple], $item[piscatini], $item[Churchill], $item[soilzerac], $item[London frog], $item[nothingtini],
				$item[eighth plague], $item[single entendre], $item[reverse Tantalus], $item[elemental caipiroska], $item[Feliz Navidad], $item[Bloody Nora], $item[moreltini], $item[hell in a bucket], $item[Newark], $item[R'lyeh], $item[Gnollish sangria], $item[vodka barracuda], $item[Mysterious Island iced tea], $item[drive-by shooting], $item[gunner's daughter], $item[dirt julep], $item[Simepore slime], $item[Phil Collins]},
			$item[Spacegate access badge] : {$item[Spacegate Research], $item[Non-Euclidean Finance], $item[Space Baby children's book], $item[Space Baby bawbaw], $item[Peek-a-Boo!], $item[space pirate treasure map], $item[Space Pirate Astrogation Handbook],
				$item[alien rock sample], $item[alien gemstone], $item[alien plant fibers], $item[alien plant sample], $item[complex alien plant sample], $item[fascinating alien plant sample], $item[alien toenails], $item[alien zoological sample], $item[complex alien zoological sample], $item[fascinating alien zoological sample], $item[spant egg casing], $item[murderbot memory chip],
				$item[Aldebaran sardines], $item[Centauri fish wine], $item[powdered oxygen], $item[portable Spacegate], $item[Spacegate scientist's insignia], $item[Spacegate military insignia], $item[Spacegate diplomat's insignia], $item[Spacegate emergency disintegrator], $item[Spacegate Initiative tattoo unit],
				$item[alien meat], $item[alien animal goo], $item[alien animal milk], $item[edible alien plant bit], $item[alien plant goo], $item[alien plant pod], $item[murderbot component casing], $item[murderbot monofilament], $item[murderbot power cell], $item[murderbot plasma rifle], $item[spant chitin], $item[spant tendon], $item[spant spear],
				$item[primitive alien salad], $item[primitive alien booze], $item[primitive alien medicine], $item[primitive alien mask]},
			$item[New-You Club Membership Form] : {$item[affirmation cookie],
				$item[Daily Affirmation: Adapt to Change Eventually],
				$item[Daily Affirmation: Always be Collecting],
				$item[Daily Affirmation: Be a Mind Master],
				$item[Daily Affirmation: Be Superficially interested],
				$item[Daily Affirmation: Keep Free Hate in your Heart],
				$item[Daily Affirmation: Think Win-Lose],
				$item[Daily Affirmation: Work For Hours a Week]},
			$item[Suspicious package] : {$item[basic martini], $item[improved martini], $item[splendid martini],
				$item[exploding cigar], $item[can of Minions-Be-Gone], $item[golden gun], $item[golden gum], $item[tiny plastic golden gundam], $item[golden tattoo gun]},
			$item[LI-11 Motor Pool voucher] : {},
			$item[Pocket Meteor Guide] : {$item[meteoreo], $item[meadeorite], $item[Meteorite-Ade], $item[metal meteoroid], $item[cute meteoroid],
				$item[asteroid belt], $item[meteorb], $item[shooting morning star], $item[meteorite guard], $item[meteortarboard], $item[meteorthopedic shoes]},
			$item[corked genie bottle] : {$item[pocket wish], $item[blessed rustproof +2 gray dragon scale mail], $item[dropped scrap of paper],
				$item[magical pony: Dusk Shiny], $item[magical pony: Pearjack], $item[magical pony: Rosey Cake], $item[magical pony: Shutterfly], $item[magical pony: Spectrum Dash], $item[magical pony: Uniquity]},
			$item[xo-skeleton-in-a-box] : {$item[exo-xo-skeleton-skeleton], $item[x], $item[o], $item[giant x], $item[giant o],
				$item[pair of candy glasses], $item[temporary X tattoos], $item[Hide-rox&trade; cookie], $item[jug of booze], $item[glyph of athleticism], $item[pair of scissors], $item[new habit]},
			$item[pantogram] : {},
			$item[locked mumming trunk] : {$item[mumming trunk]},

			$item[kerosene-soaked skip] : {$item[fireproof skip lid], $item[burning newspaper], $item[mulled hobo wine], $item[extra-toasted half sandwich]},

			$item[January's Garbage Tote (unopened)] : {$item[January's Garbage Tote]},
			$item[Clan Carnival Game] : {$item[Clan VIP Lounge key], $item[swedish massage fish], $item[heart-Shaped candy whetstone], $item[Bustle Hustler], $item[Third Base],
				$item[eaves droppers], $item[heart cozy], $item[lolsipop], $item[personal graffiti kit],
				$item[tonic o' banderas], $item[bettie page], $item[fabiotion], $item[heather graham cracker],
				$item[Mysterious Black Box], $item[Mysterious Blue Box], $item[Mysterious Green Box], $item[Mysterious Red Box],
				$item[genie's turbane], $item[genie's scimitar], $item[genie's pants], $item[genie's bracers],
				$item[psychic's circlet], $item[psychic's crystal ball], $item[psychic's pslacks], $item[psychic's amulet],
				$item[rubber baby doll], $item[rubber doll head], $item[rubber doll body], $item[plastic doll arms], $item[plastic doll legs]},
			$item[Pok&eacute;fam Guide to Capturing All of Them] : {$item[packet of tall grass seeds], $item[Pok&eacute;-Gro fertilizer],
				$item[Egnaro berry], $item[Glum berry], $item[Jamocha berry], $item[Keese berry], $item[Nadsat berry], $item[Sitrep berry], $item[Snarf berry], $item[Tapioc berry],
				$item[Globmule], $item[Bluzzard], $item[Faux], $item[Sledgehamster], $item[Pimpsqueak], $item[Pillowbug], $item[Dressage], $item[Sequestrian], $item[Carpricorn],
				$item[Turpin], $item[Morphan], $item[Cycloney], $item[Peaclock], $item[Turtive], $item[Lepardner], $item[Aiolion], $item[Waifuton], $item[Gorillape], $item[Wendtigo],
				$item[Snoutlet], $item[Ruffalo], $item[Vaporpoise], $item[Ghosprey], $item[Straypler], $item[Flan], $item[Mustardigrade], $item[Ched], $item[Gazelleton],
				$item[Mechamelion], $item[Bicycle], $item[Vamprey], $item[Wullabye], $item[Nursine], $item[Cantelope], $item[Ungulant], $item[Caramel], $item[Oppossum],
				$item[Amanitee], $item[Smashmoth], $item[Vulgure], $item[Squib], $item[Trafikoan], $item[Slotter], $item[Shudder], $item[Glamare],
				$item[Unspeakachu], $item[Stooper], $item[Disgeist], $item[Bowlet], $item[Cornbeefadon], $item[Mu]},
			$item[FantasyRealm membership packet] : {$item[Rubee&trade;], $item[FantasyRealm Warrior's Helm], $item[FantasyRealm Mage's Hat], $item[FantasyRealm Rogue's Mask],
				$item[FantasyRealm key], $item[FantasyRealm mead], $item[FantasyRealm turkey leg], $item[LyleCo premium magnifying glass], $item[LyleCo premium monocle], $item[LyleCo premium pickaxe], $item[LyleCo premium rope], $item[FantasyRealm guest pass],
				$item[map to the Cursed Village], $item[map to the Mystic Wood], $item[map to the Putrid Swamp], $item[map to the Sprawling Cemetery], $item[map to the Towering Mountains],
				$item[LyleCo Contractor's Manual], $item[FantasyRealm tattoo kit],
				$item[sachet of strange powder], $item[druidic s'more], $item[mourning wine], $item[denastified haunch], $item[bad rum and good cola], $item[Potion of Heroism],
				$item[the Archwizard's briefs], $item[Duke Vampire's regal cloak], $item[The Ghoul King's ghoulottes], $item[the Ley Incursion's waist], $item[Master Thief's utility belt], $item[belt of Ogrekind],
				$item[nozzle of the Phoenix], $item[Dragonscale breastplate], $item[leggings of the Spider Queen],
				$item[shield of the Skeleton Lord], $item[ring of the Skeleton Lord], $item[scepter of the Skeleton Lord], $item[Staff of Kitchen Royalty]},
			$item[God Lobster Egg] : {$item[Dish of Clarified Butter]},
			$item[SongBoom&trade; BoomBox Box] : {$item[SongBoom&trade; BoomBox], $item[Nightmare Fuel], $item[Special Seasoning], $item[Shielding Potion], $item[Punching Potion], $item[Gathered Meat-Clip]},
			$item[kitten burglar] : {$item[burglar/sleep mask]},
			$item[Bastille Battalion control rig crate] : {$item[Bastille Battalion control rig],
				$item[Bastille Battalion control rig loaner voucher], $item[Bastille Battalion cheese wheel], $item[Bastille Battalion tattoo kit], $item[Bastille Battalion Fondue Trophy],
				$item[sharkfin gumbo], $item[boiling broth], $item[interrogative elixir]},
			$item[Neverending Party invitation envelope] : {$item[Neverending Party guest pass], $item[PARTY HARD T-shirt],
				$item[gas can], $item[Middle of the Road&trade; brand whiskey], $item[neverending wallet chain], $item[pentagram bandana], $item[gold skull ring],
				$item[denim jacket], $item[ratty knitted cap], $item[van key], $item[jam band bootleg],
				$item[unremarkable duffel bag], $item[Purple Beast energy drink], $item[cosmetic football], $item[shoe ad T-shirt], $item[pump-up high-tops],
				$item[runproof mascara], $item[very small red dress], $item[noticeable pumps], $item[surprisingly capacious handbag], $item[everfull glass],
				$item[electronics kit], $item[PB&J with the crusts cut off], $item[dorky glasses], $item[ponytail clip], $item[paint palette],
				$item[Neverending Party favor], $item[party beer bomb], $item[sweet party mix], $item[party balloon], $item[fancy party pants], $item[party crasher], $item[Party Planning on a Budget],
				$item[deluxe Neverending Party favor], $item[TRIO cup of beer], $item[party platter for one], $item[Party-in-a-Can&trade;], $item[party pup], $item[party whip], $item[Living to Drink, Drinking to Live], $item[Party Tattoo&trade; gift certificate]},
			$item[latte lovers club card] : {$item[latte lovers member's mug]},
			$item[voter registration form] : {$item[government requisition form], $item[absentee voter ballot],
				$item[ghostly ectoplasm], $item[haunted orange], $item[haunted pizza], $item[haunted cherry pie], $item[haunted Hell ramen], $item[haunted bottle of vodka], $item[haunted martini], $item[haunted eggnog], $item[haunted gimlet], $item[twice-haunted screwdriver],
				$item[mutant arm], $item[mutant legs], $item[mutant crown], $item[glob of undifferentiated tissue],
				$item[snake skin], $item[snakeskin cowboy hat], $item[snakeskin thighboots], $item[snakeskin jacket],
				$item[orange slime glob], $item[green slime glob], $item[black slime glob], $item[slime knuckles], $item[slime fedora], $item[slime waders]},
			$item[Boxing Day care package] : {$item[body spradium], $item[glass of raw eggs], $item[punch-drunk punch],
				$item[bauxite beret], $item[bauxite boxers], $item[bauxite bow-tie], $item[My First Art of War], $item[Boxing Day Pass]},

			$item[elf sleeper agent] : {$item[red-and-green microcamera],
				$item[elf army field rations], $item[gingernade], $item[martiny], $item[prototype stimulant],
				$item[really nice net], $item[sew-on bandage], $item[tin thermos of chai], $item[tryptophan dart]},

			$item[Kramco Industries packing carton] : {$item[Kramco Sausage-o-Matic&trade;], $item[magical sausage], $item[magical sausage casing], $item[red-hot sausage fork], $item[bag of sausage links], $item[sausage golem]},
			$item[mint condition Lil' Doctor&trade; bag] : {$item[Lil' Doctor&trade; bag]},
			$item[vampyric cloake pattern] : {$item[vampyric cloake]},
			$item[PirateRealm membership packet] : {$item[PirateRealm guest pass],
				$item[PirateRealm party hat], $item[conquistador's breastplate], $item[piratical blunderbuss],
				$item[plush sea serpent], $item[pirate radio ring], $item[Pirate fork], $item[lucky gold ring],
				$item[Scurvy and Sobriety Prevention], $item[Island Drinkin', a Tiki Mixology Odyssey],
				$item[Red Roger's reliquary], $item[Red Roger's red right foot], $item[Red Roger's red left foot], $item[Red Roger's red right hand], $item[Red Roger's red left hand],
				$item[melty plastic grenade], $item[oversized ice molecule], $item[signal fragment], $item[windicle], $item[pewter shavings], $item[Red Roger's skull],
				$item[hibiscus petal], $item[huge mint leaf], $item[pineapple slab],
				$item[bottle of dark rhum], $item[Island Landslide], $item[Scorpion Bowl], $item[Skull Punch],
				$item[bottle of extra-dark rhum], $item[Electric Punch], $item[Island Thunderstorm], $item[Turtle Bowl],
				$item[bottle of super-extra-dark rhum], $item[Cobra Bowl], $item[Island Hurricane], $item[Smuggler's Punch]},
			$item[Fourth of May Cosplay Saber kit] : {$item[Fourth of May Cosplay Saber]},
			$item[rune-strewn spoon cocoon] : {$item[hewn moon-rune spoon], $item[cartoon harpoon]},
			$item[Beach Comb Box] : {$item[Beach Comb], $item[grain of sand], $item[small pile of sand], $item[pile of sand], $item[large pile of sand], $item[hourglass], $item[etched hourglass],
				$item[kelp], $item[bunch of sea grapes], $item[bottle of sea wine],
				$item[magenta seashell], $item[cyan seashell], $item[gray seashell], $item[green seashell], $item[yellow seashell], $item[sea jelly],
				$item[lucky rabbitfish fin], $item[spearfish fishing spear], $item[waders], $item[piece of coral], $item[piece of driftwood],
				$item[cursed pirate cutlass], $item[cursed swash buckle], $item[cursed tricorn hat],
				$item[meteorite fragment], $item[meteorite earring], $item[meteorite necklace], $item[Meteorite ring]},
			$item[Distant Woods Getaway Brochure] : {$item[stick of firewood], $item[bundle of firewood], $item[campfire smoke], $item[burnt stick],
				$item[campfire hot dog], $item[campfire beans], $item[campfire coffee], $item[campfire baked potato], $item[campfire stew], $item[campfire s'more]},
			$item[packaged Pocket Professor] : {$item[Pocket Professor memory chip]},
			$item[Unopened Eight Days a Week Pill Keeper] : {$item[Eight Days a Week Pill Keeper]},
			$item[unopened diabolic pizza cube box] : {$item[diabolic pizza cube]},
			$item[red-spotted snapper roe] : {$item[tinsel fin]},

			$item[Retrospecs try-at-home kit] : {$item[Retrospecs]},

			$item[unopened Bird-a-Day calendar] : {$item[Bird-a-Day calendar]},
			$item[mint-in-box Powerful Glove] : {$item[Powerful Glove]},
			$item[Better Shrooms and Gardens catalog] : {$item[packet of mushroom spores], $item[piranha pollen], $item[Pristine piranha seed],
				$item[mushroom filet], $item[mushroom tea], $item[mushroom whiskey],
				$item[mushroom slab], $item[house-sized mushroom],
				$item[free-range mushroom], $item[plump free-range mushroom], $item[bulky free-range mushroom], $item[giant free-range mushroom], $item[immense free-range mushroom], $item[colossal free-range mushroom]},
			$item[sinistral homunculus] : {$item[Left-hand man action figure]},
			$item[Guzzlr application] : {$item[Guzzlr tablet], $item[Guzzlrbuck],
				$item[Guzzlr hat], $item[Guzzlr pants], $item[Guzzlr shoes],
				$item[Guzzlr souvenir stein], $item[Never Don't Stop Not Striving], $item[Guzzlr tattoo kit],
				$item[Guzzlr cocktail set], $item[Buttery Boy], $item[Ghiaccio Colada], $item[Nog-on-the-Cob], $item[Sourfinger], $item[Steamboat]},
			$item[bag of Iunion stones] : {$item[Iunion Crown]},
			$item[baby camelCalf] : {$item[dromedary drinking helmet]},
			$item[packaged SpinMaster&trade; lathe] : {$item[SpinMaster&trade; lathe], $item[flimsy hardwood scraps],
				$item[hemlock helm], $item[balsam barrel], $item[purpleheart &quot;pants&quot;], $item[wormwood wedding ring], $item[redwood rain stick], $item[drippy diadem]},
			$item[Bagged Cargo Cultist Shorts] : {$item[Cargo Cultist Shorts], $item[flask of moonshine],
				$item[sizzling desk bell], $item[frost-rimed desk bell], $item[uncanny desk bell], $item[nasty desk bell], $item[greasy desk bell],
				$item[Yeg's Motel toothbrush], $item[Yeg's Motel hand soap], $item[Yeg's Motel mouthwash], $item[Yeg's Motel pillow mint], $item[Yeg's Motel minibar key],
				$item[Yeg's Motel alarm clock], $item[Yeg's Motel sewing kit], $item[Yeg's Motel ashtray], $item[Yeg's Motel disposable razor], $item[Yeg's Motel stationery],
				$item[alabaster bishop], $item[alabaster king], $item[alabaster knight], $item[alabaster pawn], $item[alabaster queen], $item[alabaster rook],
				$item[onyx bishop], $item[onyx king], $item[onyx knight], $item[onyx pawn], $item[onyx queen], $item[onyx rook]},
			$item[Comprehensive Cartographic Compendium] : {$item[Comprehensive Cartographic Compendium (well-read)]},
			$item[packaged knock-off retro superhero cape] : {$item[unwrapped knock-off retro superhero cape]},
			$item[box o' ghosts] : {$item[gregarious ghostling], $item[grinning ghostling], $item[greedy ghostling]},

			$item[fresh can of paint] : {$item[fresh coat of paint]},

			$item[packaged miniature crystal ball] : {$item[miniature crystal ball]},
			$item[emotion chip] : {$item[spinal-fluid-covered emotion chip]},
			$item[power seed] : {$item[potted power plant], $item[battery (AAA)], $item[battery (AA)], $item[battery (D)], $item[battery (9-Volt)], $item[battery (lantern)], $item[battery (car)]},
			$item[packaged backup camera] : {$item[backup camera]},
			$item[shortest-order cook] : {$item[blue plate], $item[short stack of pancakes], $item[short stick of butter], $item[short glass of water], $item[short white], $item[short beer]},
			$item[packaged familiar scrapbook] : {$item[familiar scrapbook]},
			$item[clan underground fireworks shop] : {$item[Clan VIP Lounge key], $item[Arr, M80], $item[fire crackers], $item[blue rocket], $item[red rocket], $item[yellow rocket]},
			$item[Our Daily Candles&trade; order form] : {$item[Napalm In The Morning&trade; candle], $item[Salsa Caliente&trade; candle],
				$item[Scent of a Human&trade; candle], $item[Smoldering Clover&trade; candle], $item[The Beast Within&trade; candle],
				$item[banana candle], $item[ear candle], $item[natural magick candle], $item[rainbow glitter candle], $item[votive of confidence]},
			$item[packaged industrial fire extinguisher] : {$item[industrial fire extinguisher]},
			$item[bottled Vampire Vintner] : {$item[French-Transylvanian Dictionary]},
			$item[packaged Daylight Shavings Helmet] : {$item[Daylight Shavings Helmet]},
			$item[packaged cold medicine cabinet] : {$item[cold medicine cabinet], $item[frozen tofu pop], $item[bone broth], $item[bowl of prescription candy], $item[fishcake], $item[star pop],
				$item[Doc's Fortifying Wine], $item[Doc's Smartifying Wine], $item[Doc's Limbering Wine], $item[Doc's Medical-Grade Wine], $item[Doc's Special Reserve Wine],
				$item[anti-burn cream], $item[anti-freeze cream], $item[anti-odor cream], $item[anti-creep cream], $item[anti-goosebump cream], $item[anti-pain cream],
				$item[Fleshazole&trade;], $item[Breathitin&trade;], $item[Extrovermectin&trade;], $item[Homebodyl&trade;]},

			$item[mint condition magnifying glass] : {$item[cursed magnifying glass], $item[void burger], $item[void lager], $item[void stone], $item[void shard]},

			$item[undrilled cosmic bowling ball] : {$item[cosmic bowling ball]},
			$item[combat lover's locket lockbox] : {$item[combat lover's locket]},
			$item[grey gosling] : {$item[grey down vest]},
			$item[undamaged Unbreakable Umbrella] : {$item[unbreakable umbrella]},
			$item[MayDay&trade; contract] : {$item[emergency glowstick], $item[spare battery], $item[space blanket], $item[single-use dust mask], $item[gaffer's tape],
				$item[20-lb can of rice and beans], $item[bar of freeze-dried water], $item[expired MRE], $item[cool mint precipice bar], $item[carrot cake precipice bar]},
			$item[packaged June cleaver] : {$item[June cleaver], $item[Dad's brandy], $item[guilty sprout], $item[mother's necklace], $item[savings bond], $item[trampled ticket stub], $item[fire-roasted lake trout], $item[teacher's pen]},
			$item[designer sweatpants (new old stock)] : {$item[designer sweatpants], $item[sweat-ade], },
			$item[unopened tiny stillsuit] : {$item[tiny stillsuit]},
			$item[packaged Jurassic Parka] : {$item[Jurassic Parka]},
			$item[boxed autumn-aton] : {$item[autumn-aton], $item[autumn breeze], $item[autumn dollar], $item[autumn leaf],
				$item[autumn years wisdom], $item[autumn-spice donut], $item[AutumnFest ale], },
			$item[mummified entombed cookbookbat] : {
				$item[Yeast of Boris], 										$item[Vegetable of Jarlsberg],								 $item[St. Sneaky Pete's Whey],
				$item[Recipe of Before Yore: Boris's beer],					$item[Recipe of Before Yore: ratatouille de Jarlsberg],		$item[Recipe of Before Yore: Pete's wily whey bar],
				$item[Recipe of Before Yore: honey bun of Boris],			$item[Recipe of Before Yore: Jarlsberg's vegetable soup],	$item[Recipe of Before Yore: St. Pete's sneaky smoothie],
				$item[Recipe of Before Yore: Boris's bread],				$item[Recipe of Before Yore: roasted vegetable of J.],		$item[Recipe of Before Yore: Pete's rich ricotta],
				$item[Recipe of Before Yore: roasted vegetable focaccia],	$item[Recipe of Before Yore: plain calzone],				$item[Recipe of Before Yore: baked veggie ricotta],
				$item[Recipe of Before Yore: Deep Dish of Legend],			$item[Recipe of Before Yore: Calzone of Legend],			$item[Recipe of Before Yore: Pizza of Legend],
				$item[Boris's beer],										$item[ratatouille de Jarlsberg],							$item[Pete's wiley whey bar],
				$item[honey bun of Boris],									$item[Jarlsberg's vegetable soup],							$item[St. Pete's sneaky smoothie],
				$item[Boris's bread],										$item[roasted vegetable of Jarlsberg],						$item[Pete's rich ricotta],
				$item[roasted vegetable focaccia],							$item[plain calzone],										$item[baked veggie ricotta casserole],
				$item[Deep Dish of Legend],									$item[Calzone of Legend],									$item[Pizza of Legend],},
			$item[packaged model train set] : {$item[model train set]},
			$item[Rock Garden Guide] : {$item[packet of rock seeds], $item[groveling gravel], $item[milestone], $item[whet stone], $item[fruity pebble],
				$item[bolder boulder], $item[hard rock], $item[lodestone], $item[molehill mountain], $item[strange stalagmite]},
			$item[S.I.T. Course Voucher] : {$item[S.I.T. Course Completion Certificate],
				$item[pebble of proud pyrite], $item[pile of gritty sand], $item[shim of shame shale], $item[angry agate], $item[hollow rock], $item[lump of loyal latite],
				$item[extra-grubby grub], $item[out-of-work circus flea], $item[fire ant pheromones], $item[filled mosquito], $item[flapper fly], $item[shot of wasp venom],
				$item[electric mushroom], $item[five-fingered fern resin], $item[glob of extra-green chlorophyll], $item[big hot pepper], $item[energized spores], $item[super good fruit]},
			$item[closed-circuit phone system] : {$item[closed-circuit pay phone],
				$item[shadow fluid], $item[shadow nectar], $item[shadow skin], $item[shadow flame], $item[shadow ice], $item[shadow glass],
				$item[shadow venom], $item[shadow bread], $item[shadow brick], $item[shadow stick], $item[shadow sinew], $item[shadow sausage]},
			$item[cursed monkey glove] : {$item[cursed monkey's paw]},
			$item[shrink-wrapped Cincho de Mayo] : {$item[Cincho de Mayo]},
			$item[shrink-wrapped 2002 Mr. Store Catalog] : {$item[2002 Mr. Store Catalog], $item[Spooky VHS tape], $item[&quot;I survived Y2K&quot; T-Shirt],
				$item[Letter from Carrie Bradshaw], $item[Mr. Big's Wallet], $item[Sexy Cosmo], $item[red-soled high heels], $item[Souvenir Chopsticks],
				$item[pro skateboard], $item[Mr. Accessaturday], $item[Meat Butler],
				$item[Loathing Idol Microphone], $item[Loathing Idol Microphone (75% charged)], $item[Loathing Idol Microphone (50% charged)], $item[Loathing Idol Microphone (25% charged)],
				$item[Charter: Nellyville],
				$item[Manual of Secret Door Detection], $item[Arrow (+1)], $item[Azurite], $item[Eye Agate], $item[Lapis Lazuli], $item[scroll of protection from lycanthropes], $item[scroll of minor invulnerability],
				$item[Flash Liquidizer Ultra Dousing Accessory], $item[Amulet of Perpetual Darkness], $item[Giant black monolith],
				$item[Crimbo cookie sheet], $item[bell-shaped Crimbo cookie], $item[blob-shaped Crimbo cookie], $item[huge Crimbo cookie], $item[nut-shaped Crimbo cookie], $item[traditional Crimbo cookie], $item[tree-shaped Crimbo cookie], $item[wreath-shaped Crimbo cookie], $item[bat-shaped Crimboween cookie], $item[skull-shaped Crimboween cookie], $item[tombstone-shaped Crimboween cookie],},
		};
	return gkIotMItems;
}


void printHelp() {
	print_html("<h3>dc [<i>options</i>] [<i>command</i>] <i>item</i></h3>");
	print_html("<br/><small>Replace <i>italicized words</i> with the appropriate argument. Arguments in [square brackets] are optional.</small>");
	print_html("Display case utilities centered around maintaining top 10 collections. With just an item, print a short summary of the disposition of the given item, including top 10 information. Ex: dc bone abacus");

	print_html("<h4>Options:</h4>");
	print_html("<br/><strong style=\"color:blue;\">--dry-run</strong>: Print out what the command WOULD do, but does NOT do it. Ex: dc --dry-run top10 bottle of rum (unimplemented except for rankup)");
	print_html("Options always come before the command.");

	print_html("<h4>Item commands:</h4>");
	print_html("<br/><strong style=\"color:blue;\">list <i>item</i></strong>: Print more detailed information on the item, especially the top 10 information. Ex: dc list finger cymbals");
	print_html("<strong style=\"color:blue;\">addall <i>item</i></strong>: Add all items you own without regard for the other top 10 entries. Follows the item saving rules (see below). Ex: dc addall bar skin");
	print_html("<strong style=\"color:blue;\">top10 <i>item</i></strong>: Add <b>or remove</b> items to make the top 10 -- will save items according to the item saving rules (see below), and will only put smm.dcOvershootAmount (default: 11) more than the next lowest rank if it can't make it to the next higher rank. Removes everything if it can't achieve rank #10.");
	print_html("• For example, if #1 is 200 and #2 is at 100 and you have 123 of that item, 'dc top10 myitem' will add enough to bring you to 111. If you instead had 500 of the same item, it would put in enough to bring you to 211 of that item in your display case.");
	print_html("<strong style=\"color:blue;\">rankup <i>[max-price-per-item]</i> <i>item</i></strong>: buy as many of item as needed to reach the next rank, and put them into the display case. Use --dry-run to get the cost of ranking up. The default max-price-per-item is the current mall cost of the item * 1.05.");
	print_html("<strong style=\"color:blue;\">iotm [<i>IotM</i>]</strong>: with no IotM lists IotMs in the database; with an IotM, print top 10 info for each item introduced by the IotM (very partially unimplemented)");
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
	print_html("<br/>If the item is not one or more of: equipment, gift, familiar hatchling, or skillbook then at least <i>smm.dcSaveAmount</i> (default 1) of the items will be saved from going into the display case.");
	print_html("Familiar hatchlings, skillbooks save 0 items in the inventory, gifts and equipment save 3 items in the inventory.");
	print_html("All commands (including 'addall') follow these rules.");

	print_html("<br/>All commands will raid Hagnk's and/or your closet (but not  your shop or clan) if required to achieve a top 10 spot or 'all' of an item.");

	print_html("<h4>Configuration:</h4>");
	print_html("<br/>dc recognizes these properties:");
	print_html("<strong style=\"color:blue;\">smm.dcOvershootAmount</strong>: the amount to overshoot. Use a very large number to put everything in the display case (still follows item saving rules, but see smm.dcSaveAmount)");
	print_html("<strong style=\"color:blue;\">smm.dcSaveAmount</strong>: the number of items to save from going into the display case. See above for details on the items saving rules");
	print_html("To see a property, use: get <i>property-name</i>");
	print_html("To set a property, use: set <i>property-name</i>=<i>property-value</i>");

	print_html("<h4>Example Usage</h4>");
	print_html("<br/>dc spider web");
	print_html("Summary of top 10 info for spider web.");
	print_html("<br/>dc --dry-run rankup spider web");
	print_html("Print the cost of ranking up to the next top 10 rank in spider web.");

	print_html("<br/>NB. If you don't care about top 10, use the built-in 'display' command: 'display put|take [x] <i>item</i>'");
	print_html("<br/><small>Version " + __dc_version + ". Copyright 2018-2022. Licensed under <a href=\"https://creativecommons.org/licenses/by-sa/4.0/\">CC BY-SA</a> version 4.0 or any later version. If this help looks poorly formatted, try 'clear; dc help' on the gCLI.</small>");
}



// prints a summary of the item and top 10 info -- used at the end of every operation
void dcPrintItemDetails(item anItem, int [int, string] top10List) {
	int equippedAmount = equipped_amount(anItem);
	int familiarEquippedAmount = familiar_equipped_amount(anItem); // familiars holding the equipment but NOT our current familiar, which will be caught by equippedAmount
	int itemAmount = item_amount(anItem);
	int storageAmount = storage_amount(anItem);
	int closetAmount = closet_amount(anItem);
	int displayAmount = display_amount(anItem);
	int shopAmount = shop_amount(anItem);
	int total = equippedAmount + familiarEquippedAmount + itemAmount + storageAmount + closetAmount + displayAmount + shopAmount;

	string top10RangeString;
	IntRange top_10_range;
	if (countTop10(top10List) > 0) { // count() would work, but use countTop10() for consistency
		string myRankString;
		string myNewRankString;
		IntRange top_10_range = collectionRange(top10List);
		foreach rank, name, num in top10List {
			if (isMe(name) && myRankString == "")
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
		top10RangeString = "Top 10 range: " + top_10_range.bottom + "-" + top_10_range.top + myRankString;
	}

	print(equippedAmount + " equipped (+" + familiarEquippedAmount + " by familiars that are NOT your current familiar) and " + itemAmount
		+ " in inv (+" + storageAmount + " stored +" + closetAmount + " in closet +" + shopAmount + " in the shop) and "
		+ displayAmount + " in case, total available: " + total + ".");
	print(top10RangeString);
}

void dcPrintItemDetails(item anItem) {
	int [int, string] emptyList;
	dcPrintItemDetails(anItem, emptyList);
}



// returns the number of items to add to the display case that would increase our position one spot, WITHOUT overshooting.
int neededToMoveUpOneRank(item anItem, int [int, string] top10List) {
	int invAmount = item_amount(anItem);
	int availableAmount = item_amount(anItem) + storage_amount(anItem) + closet_amount(anItem) - saveAmount(anItem);
	int displayAmount = display_amount(anItem);

	int goalAmount;
	int ourRank;
	int goalRank = 10;
	if (!in_top10(anItem, top10List)) {
		goalAmount = rank10Amount(top10List) + gkDCOvershootAmount;
	} else {
		// we're in the top 10 already, find our rank
		int lastRankAmt;
		for i from 10 to 1 by -1 {
			int rankAmt = amountAtRank(top10List, i);
			//print("amt at rank: " + i + ": " + rankAmt);
			if (rankAmt == displayAmount) { // we've found our current rank
				ourRank = i;
				goalRank = i - 1; // ... so our goal rank is one less than we're at now
			} else if (rankAmt < displayAmount) { // we already have more in the case than the rank we're looking at: likely cache not updated (ours or theirs)
				ourRank = i;
				goalRank = i - 1;
			} else if (rankAmt == lastRankAmt) {
				goalRank = i;
			}

			lastRankAmt = rankAmt;
		}

		// if we have enough in the case to reach rank #1, our goal rank might be 0
		if (goalRank < 1)
			goalRank = 1;

		goalAmount = amountAtRank(top10List, goalRank) + gkDCOvershootAmount;
		if (ourRank == 1 && goalRank == 1 && isMe(nameAtRank(top10List, 1))) // if we're the current top spot holder, we want 11 more than #2, not 11 more than our #1 spot
			goalAmount = amountAtRank(top10List, 2) + gkDCOvershootAmount;
	}

	// don't go higher than the next spot up, which can happen if they're closer than gkOvershootAmount
	if (goalRank > 1 && goalAmount > amountAtRank(top10List, goalRank - 1))
		goalAmount = max(amountAtRank(top10List, goalRank) + 1, amountAtRank(top10List, goalRank - 1) - 1);

	print("current rank: " + ourRank + ", goal rank: " + goalRank + ", goal amount: " + goalAmount);

	return goalAmount - displayAmount;
}


// returns the number of items in the display case that would put us at the highest position
// in the Top 10 list that we can reach, trying to be gkDCOvershootAmount over the next highest
// (will be less if there aren't enough items)
int calcHighestGoalAmount(item anItem, int [int, string] top10List) {
    assert(isValidTop10List(top10List), "calcHighestGoalAmount: not a valid top 10 list");

	int displayAmount = display_amount(anItem);
	int availableAmount = available_amount(anItem) - saveAmount(anItem);

	int goalAmount = availableAmount + displayAmount;
	if (goalAmount < rank10Amount(top10List)) {
		print("goal amount of " + goalAmount + " isn't enough to beat #10 @ " + rank10Amount(top10List), "green");
		return 0;
	}

	int goalRank;
	foreach rank, name, num in top10List {
		if (num <= goalAmount && !isMe(name)) {
			goalRank = rank;
			print("goal rank: " + goalRank + ", beating " + name + "@" + num);
			break;
		}
	}

	// if goalRank is zero now, I'm not in the top 10 list, remove all items
	if (goalRank == 0)
		return 0;

	// if i'm already at the goal index, the goal index is one less, unless i'm #10
	if (isMe(nameAtRank(top10List, goalRank))) {
		// if we're #10, don't add or remove any
		if (goalRank == 10)
			goalAmount = displayAmount;
		else
			goalRank++;
	}
	if (goalAmount > amountAtRank(top10List, goalRank) + gkDCOvershootAmount)
		goalAmount = amountAtRank(top10List, goalRank) + gkDCOvershootAmount;
	return goalAmount;
}


// put the given item into the dc, only goes to gkDCOvershootAmount more than next highest on the Top 10 list
// puts 0 in if you don't have enough to get higher than the next tier
// will also remove items to enforce the above rules
// follows the item saving rules (see help)
// returns the delta of items put in/taken out of the case
int top10Item(item anItem, int [int, string] top10List) {
	if (!isValidTop10List(top10List))
		return 0;
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

		print("dc: you have " + displayAmount + " " + anItem + " in the case and we want to get to " + goalAmount + ", adding " + putAmount, "blue");
		put_display(putAmount, anItem);
	} else if (putAmount < 0) {
		string logColour = "orange";
		if (-putAmount == displayAmount) logColour = "red"; // we're taking everything out of the dc (will affect future shelf operations)
		print("dc: you have " + displayAmount + " " + anItem + " in the case and we want to get to " + goalAmount + ", removing " + (-putAmount), logColour);
		take_display(-putAmount, anItem);
	} else
		print("dc: you have " + displayAmount + " " + anItem + " in the case and we want to get to " + goalAmount + ", doing nothing", "blue");

	return putAmount;
}



// puts all of the given item into the dc. follows item saving rules (see help)
int addallItem(item anItem, int amountToSave) {
	int invAmount = item_amount(anItem);
	int displayAmount = display_amount(anItem);
	int availableAmount = invAmount + storage_amount(anItem) + closet_amount(anItem);
	int goalAmount = displayAmount + availableAmount;

	// keep some out of the dc
	goalAmount -= amountToSave;

	int putAmount = goalAmount - displayAmount;
	retrieve_item(putAmount, anItem);

	if (putAmount > 0) { // we're adding, ignore less than 0
		print("putting " + putAmount + " " + anItem + " into display case", "blue");
		put_display(putAmount, anItem);
	}

	return putAmount;
}

int addallItem(item anItem) {
	return addallItem(anItem, saveAmount(anItem));
}



void listIotM(item anIotM) {
	foreach idx, anItem in iotmItems()[anIotM] {
		dcPrintItemDetails(anItem, lookupCollection(anItem, false));
		print("");
	}
}



void main(string arguments) {
	//arguments = arguments.to_lower_case(); NO!
	string [] argv = split_string(arguments, " ");
	int [item] receipt;

	// PROCESS ARGS: help and version
	if (count(argv) == 1 && argv[0] == "version") {
		print("DisplayCase v" + __dc_version);
		return;
	} else if (argv[0] == "" || argv[0] == "help") {
		printHelp();
		return;
	}

	// PROCESS ARGS: everything else
	boolean [string] kAcceptedOptions = {"--dry-run": true};
	boolean [string] kAcceptedCommands = {"top10": true, "auto": true, "addall": true, "rankup": true,
		"iotm": true, "iotmtop10": true, "loc": true, "top10loc": true, "list": true, "snipe": true, "snipemin": true, "shelf": true, "shelves": true, "top10shelf": true, "addallshelf": true};

	// options
	boolean dryRun = argv[0] == "--dry-run";

	// command -- see kAcceptedCommands
	int workingIndex = dryRun ? 1 : 0;
	string command;
	if (kAcceptedCommands contains argv[workingIndex]) {
		command = argv[workingIndex];
	    workingIndex++;
	}

	// arguments (item or shelf name, possibly preceded by a number which will be the max price of an item or the max number to buy)
	string [] tempArgv = argv;
	while (workingIndex > 0) {
		tempArgv = cdr(tempArgv);
		workingIndex--;
	}

	string tempString = tempArgv.joinString(" "); // what's left will be nothing or ...
	item anItem = tempString.to_item(); // ... an optional number followed by an item or ...
	location aLocation = tempString.to_location(); // ... a location or ...
	string shelfName = tempString; // ... a shelf name

	// optional number argument will be the max price per item of rankup or the max number to buy of snipe and snipemin
	int numberArgument;
	if (tempArgv[0].is_integer()) {
		numberArgument = tempArgv[0].to_int();
		tempArgv = cdr(tempArgv);
		tempString = tempArgv.joinString(" ");

		assert(anItem == $item[none] || tempString.to_item() == $item[none], "ambiguous case! " + anItem + " and " + tempString.to_item() + " are both items");
		if (anItem == $item[none]) {
			anItem = tempString.to_item(); // an item or ...
			shelfName = tempString; // ... a shelf name
		}
	}

	assert(anItem != $item[none] || command.contains_text("shel") || command.contains_text("loc"), "bad item: " + tempArgv.joinString(" "));


	// DO IT
	int [int, string] top10List;
	string pageString;
	switch (command) {
		case "top10":
		case "auto":
			top10List = lookupCollection(anItem, false);
			top10Item(anItem, top10List);
			break;

		// add all of the given item to the dc
		case "addall":
			addallItem(anItem);
			break;

		// cost to get to the next top 10 rank
		case "rankup":
			top10List = lookupCollection(anItem, false);
			if (!isValidTop10List(top10List)) {
				dcPrintItemDetails(anItem);
				return;
			}
			if (dryRun)
				printTop10List(top10List);
			int acquireCost = acquireCost(anItem, false);
			int saveAmount = saveAmount(anItem);
			int moveUpTotal = neededToMoveUpOneRank(anItem, top10List);
			int availableAmount = available_amount(anItem) - saveAmount;
			int acquireAmount = moveUpTotal - availableAmount;
			int totalCost = acquireAmount * acquireCost;
			print(moveUpTotal + " to move up to the next rank, have " + availableAmount + " available, need to acquire " + acquireAmount + " more, acquire @ " + acquireCost  + ", total: ~" + totalCost);
			if (!dryRun) {
				fullAcquire(anItem, moveUpTotal + saveAmount, numberArgument);
				top10Item(anItem, top10List);
			}
			break;

		// Item of the Month processing
		case "iotm":
			if (anItem == $item[none])
				foreach anItem in iotmItems()
					print(anItem + " @ " + historical_price(anItem));
			else
				listIotM(anItem);
			break;

		case "iotmtop10":
			foreach idx, it in iotmItems()[anItem] {
				top10List = lookupCollection(it, false);
				top10Item(it, top10List);
				print("");
			}
			break;

		case "loc":
		case "top10loc":
			assert(aLocation != $location[none], "unknown location: " + shelfName); // WARNING "shelfName" is just the raw string

			int itemsInLocation = 0;
			foreach idx, m in get_monsters(aLocation) {
				foreach it in m.item_drops() {
					itemsInLocation++;
					top10List = lookupCollection(it, false);

					if (command == "loc") {
						dcPrintItemDetails(it, top10List);

					} else if (command == "top10loc") {
						print("");
						int delta = top10Item(it, top10List);
						if (delta != 0)
							receipt[it] = delta;
						dcPrintItemDetails(it, top10List);
					}
				}
			}

			print(itemsInLocation + " items in location " + aLocation);
			printReceipt(receipt);
			exit;

		// print top 10 details of given item
		case "list":
		case "info":
			top10List = lookupCollection(anItem, false);
			printTop10List(top10List);
			break;

		// list shelves
		case "shelves":
			pageString = rawDisplayCase();
			print("Shelves:");
			foreach shelfNumber, shelfName in shelves()
				print(shelfNumber + ": " + shelfName + " (" + shelfItemCount(pageString, shelfName) + " items)");
			exit;

		// operate on a whole shelf
		case "shelf":
		case "top10shelf":
		case "addallshelf":
			pageString = rawDisplayCase();

			if (shelfName == "") shelfName = "Top 10";

			int itemsOnShelf = 0;
			foreach shelfItem, itemAmount in shelfItems(shelfName) {
				itemsOnShelf++;

				if (command == "shelf") {
					receipt[shelfItem] = itemAmount;

				} else if (command == "top10shelf") {
					print("");
					top10List = lookupCollection(shelfItem, false);
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

		default:
			if (command != "")
				print("unknown command: " + command, "red");
	}

	// we want this after most commands
	if (anItem != $item[none]) {
		if (count(top10List) == 0 && command != "top10" && command != "auto" && command != "list" && command != "info")
			top10List = lookupCollection(anItem, false);
		dcPrintItemDetails(anItem, top10List);
	}
}
