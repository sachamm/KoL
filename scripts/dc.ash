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


// Collection-specific products and opened forms; arbitrary copied/zone loot and random reward pools are not enumerated.
// lazy init
item [item, int] gkIotMItems; // don't use directly, use iotmItems() instead
item [item, int] iotmItems() {
	if (count(gkIotMItems) == 0)
		gkIotMItems = {
			$item[Mr. Accessory] : {},

			// 2004
			$item[Dark Jill-O-Lantern] : {$item[100-Watt bulb]},
			$item[hand turkey outline] : {$item[candied yam pinky ring]},
			$item[crimbo elfling] : {$item[dental pliers]},

			// 2005
			$item[Cheshire Bitten] : {$item[smile-sharpening stone]},
			$item[coffee sprite] : {$item[miniature espresso maker]},
			$item[orphan baby yeti] : {$item[penguin-smacking club]},
			$item[silk garter snake] : {$item[velvet choker]},
			$item[lucky Tam O'Shanter] : {$item[lucky Tam O'Shatner]},
			$item[emo roe] : {$item[gazing shoes]},
			$item[personal raindrop] : {$item[rainbow tie]},
			$item[miniature gravy-covered maypole] : {},
			$item[deflated inflatable dodecapede] : {$item[toy six-seater hovercraft]},
			$item[wax lips] : {},
			$item[pygmy bugbear shaman] : {$item[tiny nose-bone fetish]},
			$item[Jekyllin hide belt] : {},
			$item[doppelshifter egg] : {$item[tiny makeup kit]},
			$item[miniscule temporal rip] : {$item[1.21 jigawatts]},
			$item[sweet nutcracker] : {$item[metal mandible]},

			// 2006
			$item[calm attention-deficit demon] : {$item[attention spanner]},
			$item[unwound cymbal-playing monkey] : {$item[funky brass fez]},
			$item[Tome of Snowcone Summoning] : {$item[black snowcone], $item[blue snowcone], $item[green snowcone],
				$item[orange snowcone], $item[purple snowcone], $item[red snowcone],
				$item[yellow snowcone]},
			$item[iceberglet] : {$item[ice sickle], $item[ice baby], $item[ice pick],
				$item[ice skates]},
			$item[March hat] : {$item[miniature dormouse]},
			$item[McPhee's Grimoire of Hilarious Object Summoning] : {$item[whoopie cushion], $item[fake fake vomit], $item[explosion-flavored chewing gum],
				$item[clown hammer], $item[rubber emo roe]},
			$item[homeless hobo spirit] : {$item[weegee sqouija]},
			$item[astral badger] : {$item[badger badge], $item[astral mushroom], $item[blue-frosted astral cupcake],
				$item[green-frosted astral cupcake], $item[orange-frosted astral cupcake], $item[pink-frosted astral cupcake],
				$item[purple-frosted astral cupcake], $item[munchies pill]},
			$item[jewel-eyed wizard hat] : {},
			$item[Comma Chameleon egg] : {},
			$item[Travoltan trousers] : {},
			$item[plastic pumpkin bucket] : {},
			$item[pilgrim shield] : {},
			$item[yuletide troll chrysalis] : {$item[giant book of ancient carols]},

			// 2007
			$item[jitterbug larva] : {$item[bottle of perfume]},
			$item[nervous tick egg] : {$item[spoon!]},
			$item[Great Ball of Frozen Fire] : {$item[liar's pants], $item[flaming juggler's balls], $item[flaming pink shirt],
				$item[flaming familiar doppelg&auml;nger], $item[evil flaming eyeball pendant]},
			$item[Libram of Candy Heart Summoning] : {$item[green candy heart], $item[lavender candy heart], $item[orange candy heart],
				$item[pink candy heart], $item[white candy heart], $item[yellow candy heart]},
			$item[dandy lion cub] : {$item[woolen cravat]},
			$item[bad penguin egg] : {$item[tasteful black bow tie]},
			$item[Deactivated O. A. F.] : {$item[hardware upgrade]},
			$item[Mayflower bouquet] : {$item[begpwnia], $item[half-orchid], $item[lesser grodulated violet],
				$item[tin magnolia], $item[upsy daisy]},
			$item[bottled green pixie] : {$item[green pixie spog], $item[tiny bottle of absinthe]},
			$item[bottle-rocket crossbow] : {},
			$item[wizard action figure] : {$item[mint-condition magic wand]},
			$item[navel ring of navel gazing] : {},
			$item[class five ecto-larva] : {$item[plastic bib]},
			$item[V for Vivala mask] : {},
			$item[Crimbo P. R. E. S. S. I. E.] : {$item[metallic foil bow], $item[metallic foil radar dish], $item[metallic foil cat ears]},

			// 2008
			$item[siesta-ing Casagnova gnome] : {$item[miniature castagnets]},
			$item[unemployed hunchbacked minion] : {$item[miniature Jacob's ladder]},
			$item[Libram of Divine Favors] : {$item[divine noisemaker], $item[divine can of silly string], $item[divine blowout],
				$item[divine champagne popper], $item[divine cracker], $item[divine champagne flute]},
			$item[naughty origami kit] : {$item[naughty fortune teller], $item[origami &quot;gentlemen's&quot; magazine], $item[naughty paper shuriken],
				$item[origami pasties], $item[origami riding crop]},
			$item[sane hatrack] : {},
			$item[Sp'n-Zor's Grimoire of &quot;Tasteful&quot; Gifts] : {$item[flavored foot massage oil], $item[foam dart], $item[black-and-blue light],
				$item[Loudmouth Larry Lamprey], $item[cheap studded belt], $item[personal massager],
				$item[personalized coffee mug], $item[blue plasma ball], $item[stick-on eyebrow piercing]},
			$item[packet of mayfly bait] : {},
			$item[llama lama cria] : {$item[zen motorcycle], $item[llama lama gong], $item[mole mol&eacute;],
				$item[Morlock's Mark Bourbon], $item[glimmering buzzard feather], $item[glimmering great tit feather],
				$item[glimmering penguin feather], $item[glimmering phoenix feather], $item[glimmering raven feather],
				$item[glimmering roc feather], $item[Climate Colada], $item[digital underground potion]},
			$item[little box of fireworks] : {$item[prismatic wad], $item[rainbow bomb], $item[club of the five seasons],
				$item[rainbow crossbow], $item[six-rainbow shield]},
			$item[cotton candy cocoon] : {$item[cotton candy cordial], $item[cotton candy cone], $item[cotton candy pinch],
				$item[cotton candy smidgen], $item[cotton candy skoshe], $item[cotton candy plug],
				$item[cotton candy pillow], $item[cotton candy bale], $item[cotton candy corpsedriver]},
			$item[haiku katana] : {},
			$item[spooky rattling cigar box] : {$item[agua de vida]},
			$item[Scratch 'n' Sniff Sticker Tome] : {$item[scratch 'n' sniff sword], $item[scratch 'n' sniff crossbow], $item[scratch 'n' sniff unicorn sticker],
				$item[scratch 'n' sniff apple sticker], $item[scratch 'n' sniff UPC sticker], $item[scratch 'n' sniff wrestler sticker],
				$item[scratch 'n' sniff dragon sticker], $item[scratch 'n' sniff rock band sticker]},
			$item[candy cornucopia] : {$item[tiny ballet slippers]},

			// 2009
			$item[passed-out psychedelic bear] : {$item[psychedelic bubble wand]},
			$item[uniclops egg] : {$item[eye 'n' horn shampoo]},
			$item[container of Spooky Putty] : {$item[Spooky Putty sheet], $item[Spooky Putty monster], $item[Spooky Putty mitre],
				$item[Spooky Putty leotard], $item[Spooky Putty ball], $item[Spooky Putty snake]},
			$item[Libram of Love Songs] : {$item[love song of vague ambiguity], $item[love song of smoldering passion], $item[love song of icy revenge],
				$item[love song of sugary cuteness], $item[love song of disturbing obsession], $item[love song of naughty innuendo]},
			$item[Apathargic Bandersnatch] : {$item[aquaviolet jub-jub bird], $item[crimsilion jub-jub bird], $item[charpuce jub-jub bird]},
			$item[Elvish sunglasses] : {},
			$item[tiny costume wardrobe] : {},
			$item[Clan pool table] : {},
			$item[Clan VIP Lounge invitation] : {$item[Clan VIP Lounge key]},
			$item[infant sandworm] : {$item[string of dingle balls], $item[agua de vida]},
			$item[Bag o' Tricks] : {},
			$item[floaty stone sphere] : {$item[quadroculars], $item[floaty gravel], $item[floaty pebbles],
				$item[floaty rock], $item[charged magnet], $item[rock lobster],
				$item[rocky road ice cream], $item[pebblebr&auml;u], $item[floaty rock helmet],
				$item[floaty rock pants], $item[floaty rock necklace], $item[extra-strength rubber bands]},
			$item[Tome of Sugar Shummoning] : {$item[sugar sheet], $item[sugar shard], $item[sugar shotgun],
				$item[sugar shillelagh], $item[sugar shank], $item[sugar chapeau],
				$item[sugar shorts], $item[sugar shield], $item[sugar shirt]},
			$item[squamous polyp] : {$item[unspeakable lozenges], $item[agua de vida]},
			$item[moveable feast] : {},
			$item[suspicious stocking] : {$item[bag of many confections]},

			// 2010
			$item[hungover chauvinist pig] : {$item[bottle of Cochon Noir]},
			$item[perfectly ordinary frog] : {$item[miniature tophat]},
			$item[stinky cheese ball] : {$item[stinky cheese diaper], $item[stinky cheese sword], $item[stinky cheese wheel],
				$item[stinky cheese eye], $item[Staff of Queso Escusado]},
			$item[Libram of BRICKOs] : {$item[BRICKO brick], $item[BRICKO eye brick], $item[BRICKO hat],
				$item[BRICKO pants], $item[BRICKO sword], $item[BRICKO ooze],
				$item[BRICKO bat], $item[BRICKO oyster], $item[BRICKO turtle],
				$item[BRICKO elephant], $item[BRICKO octopus], $item[BRICKO python],
				$item[BRICKO vacuum cleaner], $item[BRICKO airship], $item[BRICKO cathedral],
				$item[BRICKO gargantuchicken], $item[BRICKO pyramid], $item[BRICKO pearl],
				$item[BRICKO bulwark], $item[BRICKO trunk], $item[gilded BRICKO brick],
				$item[gilded BRICKO chalice], $item[black BRICKO brick], $item[green BRICKO brick],
				$item[broken BRICKO brick], $item[BRICKO reactor], $item[BRICKO egg],
				$item[extra-heavy BRICKO brick], $item[BRICKO stud]},
			$item[Clan looking glass] : {$item[&quot;DRINK ME&quot; potion], $item[reflection of a map]},
			$item[panicked kernel] : {$item[bugged beanie], $item[bugged balaclava]},
			$item[Crown of Thrones] : {},
			$item[glowing frisbee] : {$item[portable motorcycle]},
			$item[Juju Mojo Mask] : {},
			$item[Schmalz's First Prize Beer] : {$item[ironic moustache], $item[Game Grid token], $item[Game Grid ticket],
				$item[finger cuffs], $item[little parachute guy], $item[superduperball],
				$item[coffee pixie stick], $item[plastic spider ring], $item[folder (Jackass Plumber)],
				$item[cheap plastic kazoo], $item[inflatable baseball bat], $item[googly-star hat],
				$item[googly-ball hat], $item[googly-heart hat], $item[Game Grid valued membership card],
				$item[super-sweet boom box], $item[Space Trip safety headphones], $item[sinister demon mask],
				$item[Dungeon Fist gauntlet], $item[streetfighting champion's belt], $item[Meteoid ice beam],
				$item[chiptune guitar], $item[fixed-gear bicycle]},
			$item[Greatest American Pants] : {},
			$item[organ grinder] : {$item[microwave stogie], $item[liver and let pie], $item[badass pie],
				$item[shoo-fish pie], $item[piping organ pie], $item[igloo pie],
				$item[dead lights pie], $item[throbbing organ pie]},
			$item[Grumpy Bumpkin's Pumpkin Seed Catalog] : {$item[Staff of the November Jack-O-Lantern], $item[shin gourds], $item[ginormous pumpkin],
				$item[pumpkin pie], $item[pumpkin beer], $item[pumpkin juice],
				$item[huge pumpkin], $item[packet of pumpkin seeds], $item[pumpkin],
				$item[pumpkin bomb], $item[pumpkin carriage]},
			$item[hibernating robot reindeer] : {$item[S.L.E.I.G.H.B.E.L.L.S.]},

			// 2011
			$item[sleeping piano cat] : {$item[kitty sheet music]},
			$item[rehearsing dramatic hedgehog] : {$item[tiny prop sword]},
			$item[Loathing Legion knife] : {$item[Loathing Legion abacus], $item[Loathing Legion can opener], $item[Loathing Legion chainsaw],
				$item[Loathing Legion corkscrew], $item[Loathing Legion defibrillator], $item[Loathing Legion double prism],
				$item[Loathing Legion electric knife], $item[Loathing Legion flamethrower], $item[Loathing Legion hammer],
				$item[Loathing Legion helicopter], $item[Loathing Legion jackhammer], $item[Loathing Legion kitchen sink],
				$item[Loathing Legion many-purpose hook], $item[Loathing Legion moondial], $item[Loathing Legion necktie],
				$item[Loathing Legion pizza stone], $item[Loathing Legion rollerblades], $item[Loathing Legion tape measure],
				$item[Loathing Legion tattoo needle], $item[Loathing Legion universal screwdriver]},
			$item[a cute angel] : {$item[quake of arrows]},
			$item[Sorcerers of the Shore Grimoire] : {$item[Pack of Alice's Army Cards], $item[Alice's Army Swordsman], $item[Alice's Army Spearsman],
				$item[Alice's Army Halberder], $item[Alice's Army Guard], $item[Alice's Army Wallman],
				$item[Alice's Army Ninja], $item[Alice's Army Alchemist], $item[Alice's Army Page],
				$item[Alice's Army Shieldmaiden], $item[Alice's Army Mad Bomber], $item[Alice's Army Nurse],
				$item[Alice's Army Hammerman], $item[Alice's Army Bowman], $item[Alice's Army Lanceman],
				$item[Alice's Army Horseman], $item[Alice's Army Coward], $item[Alice's Army Cleric],
				$item[Alice's Army Sniper], $item[Alice's Army Dervish], $item[Alice's Army Martyr],
				$item[Pack of Alice's Army Foil Cards], $item[Alice's Army Foil Swordsman], $item[Alice's Army Foil Spearsman],
				$item[Alice's Army Foil Halberder], $item[Alice's Army Foil Guard], $item[Alice's Army Foil Wallman],
				$item[Alice's Army Foil Ninja], $item[Alice's Army Foil Alchemist], $item[Alice's Army Foil Page],
				$item[Alice's Army Foil Shieldmaiden], $item[Alice's Army Foil Mad Bomber], $item[Alice's Army Foil Nurse],
				$item[Alice's Army Foil Hammerman], $item[Alice's Army Foil Bowman], $item[Alice's Army Foil Lanceman],
				$item[Alice's Army Foil Horseman], $item[Alice's Army Foil Coward], $item[Alice's Army Foil Cleric],
				$item[Alice's Army Foil Sniper], $item[Alice's Army Foil Dervish], $item[Alice's Army Foil Martyr],
				$item[Single Alice's Army Foil], $item[Alice's Army Foil tattoo], $item[Alice's Army booster box]},
			$item[Clan shower] : {},
			$item[My Own Pen Pal kit] : {},
			$item[mysterious chest] : {$item[tiny top hat and cane]},
			$item[Operation Patriot Shield] : {},
			$item[fairy-worn boots] : {$item[stomp box], $item[gooey paste], $item[beastly paste],
				$item[oily paste], $item[ectoplasmic paste], $item[greasy paste],
				$item[bug paste], $item[hippy paste], $item[orc paste],
				$item[demonic paste], $item[indescribably horrible paste], $item[fishy paste],
				$item[goblin paste], $item[pirate paste], $item[chlorophyll paste],
				$item[strange paste], $item[Mer-kin paste], $item[slimy paste],
				$item[penguin paste], $item[elemental paste], $item[cosmic paste],
				$item[hobo paste], $item[Crimbo paste]},
			$item[Tome of Clip Art] : {$item[Ur-Donut], $item[The Bomb], $item[box of Familiar Jacks],
				$item[bucket of wine], $item[ultrafondue], $item[oversized snowflake],
				$item[unbearable light], $item[crystal skull], $item[borrowed time],
				$item[box of hammers], $item[shining halo], $item[furry halo],
				$item[frosty halo], $item[time halo], $item[Lumineux Limnio],
				$item[Morto Moreto], $item[Temps Tempranillo], $item[Bordeaux Marteaux],
				$item[Fromage Pinotage], $item[Beignet Milgranet], $item[Muschat],
				$item[cool jelly donut], $item[shrapnel jelly donut], $item[occult jelly donut],
				$item[thyme jelly donut], $item[frozen danish], $item[smashed danish],
				$item[forbidden danish], $item[cool cat claw], $item[blunt cat claw],
				$item[shadowy cat claw], $item[cheezburger], $item[toasted brie],
				$item[potion of the field gar], $item[too legit potion], $item[Bright Water],
				$item[cold-filtered water], $item[graveyard snowglobe], $item[cool cat elixir],
				$item[potion of the captain's hammer], $item[potion of X-ray vision], $item[potion of the litterbox],
				$item[potion of animal rage], $item[potion of punctual companionship], $item[holy bomb\, batman],
				$item[bobcat grenade], $item[chocolate frosted sugar bomb], $item[broken glass grenade],
				$item[noxious gas grenade], $item[skull with a fuse in it], $item[boozebomb],
				$item[4:20 bomb], $item[blunt icepick], $item[fluorescent lightbulb],
				$item[blammer], $item[clock-cleaning hammer], $item[hammerus],
				$item[broken clock], $item[dethklok], $item[glacial clock]},
			$item[Make-Your-Own-Vampire-Fangs kit] : {$item[plastic vampire fangs]},
			$item[stuffed-shirt scarecrow] : {},
			$item[Mint Salton Pepper's Peppermint Seed Catalog] : {$item[Peppermint Pip Packet], $item[peppermint sprout], $item[peppermint crook],
				$item[peppermint twist], $item[peppermint parasol], $item[peppermint patty],
				$item[peppermint rhino baby], $item[candy cane candygram], $item[Vodka Matryoshka],
				$item[Gin Mint], $item[Tequiz Navidad], $item[Mint Yulep],
				$item[Crimbojito], $item[Sangria de Menthe], $item[cane-mail pants],
				$item[cane-mail shirt], $item[licorice boa]},

			// 2012
			$item[The Groose in the Hoose] : {$item[spruce juice], $item[groose grease]},
			$item[The Kloop in the Coop] : {$item[miniscule beatbox]},
			$item[Libram of Resolutions] : {$item[resolution: be feistier], $item[resolution: be happier], $item[resolution: be kinder],
				$item[resolution: be luckier], $item[resolution: be more adventurous], $item[resolution: be sexier],
				$item[resolution: be smarter], $item[resolution: be stronger], $item[resolution: be wealthier]},
			$item[can of Rain-Doh] : {$item[Rain-Doh violet bo], $item[Rain-Doh yellow laser gun], $item[Rain-Doh green lantern],
				$item[Rain-Doh red wings], $item[empty Rain-Doh can], $item[Rain-Doh black box],
				$item[Rain-Doh blue balls], $item[Rain-Doh box full of monster], $item[Rain-Doh indigo cup],
				$item[Rain-Doh orange agent]},
			$item[Small Medium] : {$item[crystal decanter], $item[Aura Libre], $item[Aye Aye],
				$item[Aye Aye\, Captain], $item[Aye Aye\, Tooth Tooth], $item[Black Hole],
				$item[Buttery Knob], $item[Caipiranha], $item[Candicaine],
				$item[Candy Alexander], $item[Cement Mixer], $item[Chakra Libre],
				$item[Crazymaker], $item[Dark & Starry], $item[Doublepunchplanter],
				$item[Drac & Tan], $item[Drunken Astrophysicist], $item[Drunken Neurologist],
				$item[Drunken Philosopher], $item[Dump Truck], $item[Earth and Firewater],
				$item[Earth\, Wind and Firewater], $item[Event Horizon], $item[Extra-slimy Slimosa],
				$item[Fauna Libre], $item[Firewater], $item[Flaming Caipiranha],
				$item[Flaming Knob], $item[Flaming Mohobo], $item[Flaming Sazerorc],
				$item[Flying Caipiranha], $item[Fuzzy Tentacle], $item[Golden Mean],
				$item[Grasshopper], $item[Great Older Fashioned], $item[Green Burlap],
				$item[Green Giant], $item[Green Muslin], $item[Green Velvet],
				$item[Haymaker], $item[Herring Daiquiri], $item[Herring Wallbanger],
				$item[Herringtini], $item[Humanitini], $item[Jackhammer],
				$item[Locust], $item[Lollipop Drop], $item[Mohobo],
				$item[Moonshine Mohobo], $item[More Humanitini than Humanitini], $item[Oh\, the Humanitini],
				$item[Plague of Locusts], $item[Punchplanter], $item[Red Dwarf],
				$item[Sazerorc], $item[Sazuruk-hai], $item[Shot of the Living Dead],
				$item[Sizzling Sinner], $item[Slimebite], $item[Slimosa],
				$item[Slippery Knob], $item[Sloe Comfortable Zoo], $item[Sloe Comfortable Zoo on Fire],
				$item[Suffering Sinner], $item[Suppurating Sinner], $item[Transylvania Sling],
				$item[Zoodriver]},
			$item[Boris's Helm] : {$item[Boris's Helm (askew)]},
			$item[Olympic-sized Clan crate] : {$item[Ze&trade; goggles], $item[stylish swimsuit], $item[lost key],
				$item[pool torpedo], $item[soggy used band-aid], $item[The Lost Pill Bottle]},
			$item[Moping Artistic Goth Kid] : {$item[little wooden mannequin], $item[crayon shavings], $item[wax bugbear],
				$item[wax hat], $item[wax pants]},
			$item[Camp Scout backpack] : {$item[bag of GORF], $item[bag of GORP], $item[bag of QWOP],
				$item[CSA cheerfulness ration], $item[CSA scoutmaster's &quot;water&quot;], $item[water purification pills],
				$item[CSA bravery badge], $item[Camp Scout pup tent], $item[CSA all-purpose soap],
				$item[CSA fire-starting kit], $item[CSA obedience grenade]},
			$item[Unagnimated Gnome] : {$item[gnomish athlete's foot], $item[gnomish coal miner's lung], $item[gnomish housemaid's kgnee],
				$item[gnomish swimmer's ears], $item[gnomish tennis elbow]},
			$item[Tome of Rad Libs] : {$item[Rad Lib], $item[papier-m&acirc;ch&eacute; glob], $item[papier-mochi],
				$item[papier-m&acirc;chaeranthera], $item[papier-m&acirc;ch&eacute; toothpicks], $item[papier-m&acirc;ch&eacute;te],
				$item[papier-m&acirc;chine gun], $item[papier-masque], $item[papier-mitre],
				$item[papier-m&acirc;churidars], $item[papier-m&acirc;ch&eacute; plaque], $item[papier-m&acirc;ch&eacute; handle],
				$item[papier-m&acirc;ch&eacute; base], $item[papier-m&acirc;ch&eacute; bowl], $item[papier-m&acirc;ch&eacute; trophy pi&ntilde;ata]},
			$item[box of bear arms] : {$item[right bear arm], $item[left bear arm]},
			$item[Pete & Jackie's Dragon Tooth Emporium Catalog] : {$item[Bonestabber], $item[skeletal scabbard], $item[skeleton skis],
				$item[auxiliary backbone], $item[ribcage rollcage], $item[Lazybones&trade; recliner],
				$item[skeleton quiche], $item[crystal skeleton vodka], $item[packet of dragon's teeth],
				$item[skeletal skiff], $item[skeleton], $item[skulldozer egg],
				$item[shaking skull]},
			$item[deactivated nanobots] : {$item[nanorhino credit card]},
			$item[Thinknerd's Grimoire of Geeky Gifts] : {$item[confusing LED clock], $item[haggis-infused soap], $item[magicberry tablets],
				$item[37x37x37 puzzle cube], $item[McLeod's Hard Haggis-Ade], $item[haggis-wrapped haggis-stuffed haggis],
				$item[home robotics kit], $item[old school calculator watch], $item[haggis socks],
				$item[airblaster gun], $item[Thinknerd T-shirt grab bag], $item[actual reality goggles],
				$item[Mr. Haggis], $item[magnetic sculpture kit], $item[Microplushie: Otakulone],
				$item[Microplushie: Hippylase], $item[Microplushie: Bropane], $item[Microplushie: Sororitrate],
				$item[Microplushie: Gothochondria], $item[Microplushie: Raverdrine], $item[Microplushie: Hobomosome],
				$item[Microplushie: Ermahgerdic Acid], $item[Microplushie: Dorkonide], $item[Microplushie: Fauxnerditide],
				$item[Microplushie: Hipsterine], $item[Thinknerd T-Shirt], $item[pile of useless robot parts],
				$item[homemade robot], $item[homemade robot gear], $item[classy monkey],
				$item[fancy gourd potion]},

			// 2013
			$item[avatar of the Unconscious Collective] : {$item[blue canary nightlight], $item[Unconscious Collective Dream Jar]},
			$item[dreaming Jung man] : {$item[Little Crimson Book], $item[psychoanalytic jar], $item[jar of psychoses (The Suspicious-Looking Guy)],
				$item[jar of psychoses (The Captain of the Gourd)], $item[jar of psychoses (The Crackpot Mystic)], $item[jar of psychoses (The Old Man)],
				$item[jar of psychoses (The Pretentious Artist)], $item[jar of psychoses (The Meatsmith)], $item[jar of psychoses (Jick)]},
			$item[Snow Suit] : {$item[carrot nose], $item[carrot cake], $item[carrot claret],
				$item[carrot juice]},
			$item[GameInformPowerDailyPro subscription card] : {$item[gold crown], $item[green cloth cap], $item[Helm of the Scream Emperor],
				$item[iron helmet], $item[Greaves of the Murk Lord], $item[flaming sword],
				$item[iron dagger], $item[steel sword], $item[Sword of Dark Omens],
				$item[Shield of Icy Fate], $item[Belt of Howling Anger], $item[Boots of Twilight Whispers],
				$item[Gauntlets of the Blood Moon], $item[Cloak of Dire Shadows], $item[hamburger],
				$item[slice of pizza], $item[whole roasted chicken], $item[bottle of wine],
				$item[shining goblet], $item[tankard of ale], $item[scroll of Protection from Bad Stuff],
				$item[scroll of Puddingskin], $item[blue potion], $item[cartoon heart],
				$item[dollar-sign bag], $item[dungeoneering kit], $item[extra-strength red potion],
				$item[fancy blue potion], $item[fireball], $item[GameInformPowerDailyPro magazine],
				$item[GameInformPowerDailyPro walkthru], $item[gold star], $item[huge gold coin],
				$item[massive gemstone], $item[red potion], $item[round blue bomb],
				$item[vial of holy water]},
			$item[Jarlsberg's pan] : {$item[Jarlsberg's pan (Cosmic portal mode)], $item[celestial au jus], $item[celestial carrot juice],
				$item[celestial olive oil], $item[celestial squid ink], $item[Cosmic Calorie]},
			$item[Libram of Pulled Taffy] : {$item[pulled blue taffy], $item[pulled green taffy], $item[pulled indigo taffy],
				$item[pulled orange taffy], $item[pulled red taffy], $item[pulled violet taffy],
				$item[pulled yellow taffy], $item[envyfish egg]},
			$item[Order of the Green Thumb Order Form] : {},
			$item[adventurer clone egg] : {$item[mini-Mr. Accessory]},
			$item[Clan hot dog stand] : {$item[ancient hot dog wrapper], $item[vicious spiked collar], $item[debonair deboner],
				$item[chicle de salchicha], $item[jar of frostigkraut], $item[gnawed-up dog bone],
				$item[Grey Guanon], $item[Engorged Sausages and You], $item[dream of a dog],
				$item[optimal spreadsheet], $item[defective Game Grid token]},
			$item[Folder Holder] : {$item[over-the-shoulder Folder Holder], $item[folder (barbarian)], $item[folder (blue)],
				$item[folder (catfish)], $item[folder (cyan)], $item[folder (D-Team)],
				$item[folder (dancing dolphins)], $item[folder (Ex-Files)], $item[folder (green)],
				$item[folder (heavy metal)], $item[folder (holographic fractal)], $item[folder (Jackass Plumber)],
				$item[folder (Knight Writer)], $item[folder (KOLHS)], $item[folder (magenta)],
				$item[folder (owl)], $item[folder (rainbow unicorn)], $item[folder (red)],
				$item[folder (Seawolf)], $item[folder (skull and crossbones)], $item[folder (smiley face)],
				$item[folder (space skeleton)], $item[folder (sports car)], $item[folder (sportsballs)],
				$item[folder (Stinky Trash Kid)], $item[folder (tranquil landscape)], $item[folder (wizard)],
				$item[folder (Yedi)], $item[folder (yellow)]},
			$item[KoLHS Pep Squad Box] : {$item[school spirit socket set], $item[tin tam], $item[tin drum],
				$item[tin foil], $item[tin roof (rusted)], $item[tin cup],
				$item[tin lizzie], $item[tin snips]},
			$item[Gordon Beer's Beer Garden Catalog] : {$item[packet of beer seeds], $item[bottle of Greedy Dog], $item[bottle of Lambada Lambic],
				$item[bottle of Old Pugilist], $item[bottle of Professor Beer], $item[bottle of Race Car Red],
				$item[bottle of Rapier Witbier], $item[can of Br&uuml;talbr&auml;u], $item[can of Drooling Monk],
				$item[can of Impetuous Scofflaw], $item[handful of barley], $item[cluster of hops],
				$item[fancy beer bottle], $item[fancy beer label], $item[artisanal homebrew sampler],
				$item[fancy tin beer can], $item[artisanal homebrew gift package], $item[liquid bread]},
			$item[deanimated reanimator's coffin] : {$item[flask of embalming fluid]},
			$item[Pantsgiving] : {},
			$item[The Smith's Tome] : {$item[handful of Smithereens], $item[Every Day is Like This Sundae], $item[Miserable Pie],
				$item[This Charming Flan], $item[Irish Coffee\, English Heart], $item[Strikes Again Bigmouth],
				$item[Paint A Vulgar Pitcher], $item[Flaskfull of Hollow], $item[Louder Than Bomb],
				$item[Golden Light], $item[Handsome Devil]},

			// 2014
			$item[hibernating Grimstone Golem] : {$item[grimstone galoshes], $item[grimstone mask]},
			$item[praying Grim Brother] : {$item[Grim Brothers' story book], $item[grim fairy tale]},
			$item[Discontent&trade; Winter Garden Catalog] : {$item[bod-ice], $item[ice nine], $item[snow shovel],
				$item[ice bucket], $item[snow mobile], $item[snow belt],
				$item[snow fort], $item[ice harvest], $item[snow berries],
				$item[snow crab], $item[Ice Island Long Tea], $item[frost flower],
				$item[liquid ice pack], $item[snow cleats], $item[ice house],
				$item[ice sculpture], $item[packet of winter seeds], $item[snow boards],
				$item[snow machine], $item[unfinished ice sculpture]},
			$item[Buddy Bjorn] : {},
			$item[Sneaky Pete's leather jacket] : {$item[Sneaky Pete's leather jacket (collar popped)]},
			$item[Little Geneticist DNA-Splicing Lab] : {$item[Gene Tonic: Beast], $item[Gene Tonic: Constellation], $item[Gene Tonic: Construct],
				$item[Gene Tonic: Demon], $item[Gene Tonic: Dude], $item[Gene Tonic: Elemental],
				$item[Gene Tonic: Elf], $item[Gene Tonic: Fish], $item[Gene Tonic: Goblin],
				$item[Gene Tonic: Hippy], $item[Gene Tonic: Hobo], $item[Gene Tonic: Horror],
				$item[Gene Tonic: Humanoid], $item[Gene Tonic: Insect], $item[Gene Tonic: Mer-kin],
				$item[Gene Tonic: Orc], $item[Gene Tonic: Penguin], $item[Gene Tonic: Pirate],
				$item[Gene Tonic: Plant], $item[Gene Tonic: Slime], $item[Gene Tonic: Undead],
				$item[Gene Tonic: Weird], $item[DNA extraction syringe]},
			$item[airplane charter: Spring Break Beach] : {$item[8-billed baseball cap], $item[Brogre bucket hat], $item[Brogre brorts],
				$item[Brogre brolo shirt], $item[extremely wet T-shirt], $item[giant shrimp fork],
				$item[Paradaisical Cheeseburger recipe], $item[sprinkle shaker], $item[Taco Dan's Taco Stand Cocktail Sauce Bottle],
				$item[string of moist beads], $item[Beefy Crunch Pastaco], $item[Brain Food Pastaco],
				$item[Cool Brunch Pastaco], $item[Energy Buzz Pastaco], $item[Ludovico Pastaco],
				$item[Medical Pastaco], $item[Taco Dan's Basic Taco Dan Taco], $item[Taco Dan's Taco Fish Fish Taco],
				$item[broberry brogurt], $item[brocolate brogurt], $item[French bronilla brogurt],
				$item[regular-size brogurt], $item[super-size brogurt], $item[BROS Energy Drink],
				$item[Fun-Guy spore], $item[Boletus Broletus mushroom], $item[Gyromitra Dynomita mushroom],
				$item[Helvella Haemophilia mushroom], $item[Omphalotus Omphaloskepsis mushroom], $item[Stemonitis Staticus mushroom],
				$item[Tremella Tarantella mushroom], $item[one-day ticket to Spring Break Beach], $item[Beach Buck],
				$item[bike rental broupon], $item[industrial strength anti-fungal spray], $item[Now You're Cooking With Grease],
				$item[Pastaco shell], $item[pencil thin mushroom], $item[Sloppy Seconds Diner Employee Handbook],
				$item[Spring Break Beach tattoo coupon], $item[Taco Dan's Super Taco-Riffic Taco Sauce!], $item[Taco Dan's Taco Stand's Taco Receipt],
				$item[History's Most Offensive Jokes\, Vol. IX]},
			$item[still grill] : {$item[box of hickory chips], $item[ash soda], $item[bottle of lighter fluid],
				$item[bowl of marinade], $item[dollop of barbecue sauce], $item[liquid smoke],
				$item[hot ashes], $item[shaker of dry rub]},
			$item[Clan speakeasy] : {$item[Bee's Knees], $item[cup of &quot;tea&quot;], $item[Flivver],
				$item[glass of &quot;milk&quot;], $item[Hot Socks], $item[Ish Kabibble],
				$item[Lucky Lindy], $item[Phonus Balonus], $item[Sloppy Jalopy],
				$item[Sockdollager], $item[thermos of &quot;whiskey&quot;]},
			$item[The Confiscator's Grimoire] : {$item[cap gun], $item[plastic nunchaku], $item[sticky hand whip],
				$item[glow-in-the-dark necklace], $item[Groll doll], $item[portable cassette player],
				$item[rubber cape], $item[confiscated cell phone], $item[confiscated comic book],
				$item[confiscated love note], $item[rubber nubbin], $item[&quot;KICK ME&quot; sign],
				$item[chewable paper], $item[LCD game: Burger Belt], $item[LCD game: Food Eater],
				$item[LCD game: Garbage River], $item[rubber spider]},
			$item[Xi Receiver Unit] : {$item[Xiblaxian circuitry], $item[Xiblaxian polymer], $item[Xiblaxian alloy],
				$item[Xiblaxian crystal], $item[Xiblaxian holo-wrist-puter simcode], $item[Xiblaxian cache locator simcode],
				$item[Xiblaxian holo-training simcode], $item[Xiblaxian direct marketing simcode], $item[Xiblaxian holo-buddy simcode],
				$item[Xiblaxian encrypted political prisoner], $item[Xiblaxian holo-schematic: stealth cowl], $item[Xiblaxian holo-schematic: stealth trousers],
				$item[Xiblaxian holo-schematic: stealth vest], $item[Xiblaxian holo-schematic: ultraburrito], $item[Xiblaxian holo-schematic: space whiskey],
				$item[Xiblaxian holo-schematic: residence cube], $item[Xiblaxian holo-schematic: xeno-goggles], $item[Xiblaxian 5D printer],
				$item[Xiblaxian holo-bowtie], $item[Xiblaxian xeno-detection goggles], $item[Xiblaxian stealth cowl],
				$item[Xiblaxian stealth trousers], $item[Xiblaxian stealth vest], $item[Xiblaxian ultraburrito],
				$item[Xiblaxian space-whiskey], $item[Xiblaxian residence-cube], $item[Xiblaxian holo-wrist-puter],
				$item[transmission from planet Xi]},
			$item[Thor's Pliers] : {},
			$item[airplane charter: Conspiracy Island] : {$item[giant yellow hat], $item[pair of plants], $item[camouflage T-shirt],
				$item[battery-powered drill], $item[mercenary pistol], $item[mercenary rifle],
				$item[cuddly teddy bear], $item[encrypted micro-cassette recorder], $item[gore bucket],
				$item[heavy-duty clipboard], $item[trench lighter], $item[ESP suppression collar],
				$item[first-aid pouch], $item[GPS-tracking wristwatch], $item[jangly bracelet],
				$item[Personal Ventilation Unit], $item[Sasq&trade; watch], $item[smoker's cloak],
				$item[&quot;meat&quot; stick], $item[initiative shawarma], $item[karma shawarma],
				$item[limp broccoli], $item[warm war shawarma], $item[Amnesiac Ale],
				$item[Highest Bitter], $item[Jungle Juice], $item[transdermal smoke patch],
				$item[airborne mutagen], $item[delicious candy], $item[experimental serum G-9],
				$item[experimental serum P-00], $item[monkey barf], $item[the most dangerous bait],
				$item[Agent Mauve], $item[Armory keycard], $item[bottle-opener keycard],
				$item[Coinspiracy], $item[ice-cold Cloaca Zero], $item[khaki duffel bag],
				$item[Merc Core challenge coin], $item[Merc Core deployment orders], $item[Merc Core Field Manual: Intimidation Techniques],
				$item[Merc Core Field Manual: Sanity Maintenance], $item[military-grade fingernail clippers], $item[one-day ticket to Conspiracy Island],
				$item[pack of smokes], $item[Project T. L. B.], $item[SHAWARMA Initiative Keycard],
				$item[special clip: boneburners], $item[special clip: graveburpers], $item[special clip: splatterers],
				$item[special clip: squelchers], $item[special clip: tracers], $item[special clip: wailers],
				$item[specialty ammo bandolier]},
			$item[fist turkey outline] : {$item[brass turkey knuckles], $item[Agitated Turkey], $item[Ambitious Turkey],
				$item[Friendly Turkey]},
			$item[Crimbo sapling] : {$item[even more tinsel]},

			// 2015
			$item[golden monkey statuette] : {$item[golden banana]},
			$item[Professor of Spelunkology] : {$item[Stembridge sidearm], $item[Tales of Spelunking], $item[Spelunker of Fortune],
				$item[Spelunker's Guild prize sack]},
			$item[Chateau Mantegna room key] : {$item[antler chandelier], $item[artificial skylight], $item[ceiling fan],
				$item[alpine watercolor set], $item[bowl of potpourri], $item[continental juice bar],
				$item[electric muscle stimulator], $item[fancy calligraphy pen], $item[fancy stationery set],
				$item[foreign language tapes], $item[Swiss piggy bank]},
			$item[bottle of lovebug pheromones] : {},
			$item[Ed the Undying exhibit crate] : {$item[The Crown of Ed the Undying]},
			$item[airplane charter: Dinseylandfill] : {$item[Dinsey mascot mask], $item[Dinsey's brain], $item[hazmat helmet],
				$item[isotophat], $item[Dinsey's pants], $item[ratskin pajama pants],
				$item[Three Mile Island shorts], $item[backwoods banjo], $item[Dinsey's pizza cutter],
				$item[garbage sticker], $item[sewage-clogged pistol], $item[toxic mop],
				$item[trash net], $item[Dinsey's radar dish], $item[dirty rigging rope],
				$item[fake washboard], $item[cheap sunglasses], $item[Dinsey's glove],
				$item[Dinsey's oculus], $item[expensive camera], $item[lube-shoes],
				$item[perfume-soaked bandana], $item[stinky fannypack], $item[filthy child leash],
				$item[lead collar], $item[Dinsey food-cone], $item[toxo],
				$item[Afternoon Delight], $item[Dinsey Whinskey], $item[Lemonade-235],
				$item[nasty snuff], $item[beard incense], $item[Dinsey face paint],
				$item[How to Avoid Scams], $item[turtle voicebox], $item[bag of gross foreign snacks],
				$item[bag of park garbage], $item[brain preservation fluid], $item[complimentary Dinsey refreshments],
				$item[Dinsey Maintenance Manual], $item[Dinsey tattoo kit], $item[FunFunds&trade;],
				$item[grody jug], $item[inert sludgepuppy], $item[jar of swamp honey],
				$item[keycard &alpha;], $item[keycard &beta;], $item[keycard &delta;],
				$item[keycard &gamma;], $item[one-day ticket to Dinseylandfill], $item[Scratch-and-Sniff Guide to Dinseylandfill],
				$item[toxic globule], $item[Trash\, a Memoir]},
			$item[portable Mayo Clinic] : {$item[miracle whip], $item[sphygmayomanometer], $item[acceptable mayolus],
				$item[enticing mayolus], $item[mouth-watering mayolus], $item[unappetizing mayolus],
				$item[uninteresting mayolus], $item[mayo lance], $item[Mayo Minder&trade;],
				$item[Mayodiol], $item[Mayoflex], $item[Mayonex],
				$item[Mayostat], $item[Mayozapine], $item[newly-hatched mayonnaise wasp],
				$item[tomayohawk-style reflex hammer], $item[mayo pump]},
			$item[yellow puck] : {$item[orange boxing gloves], $item[blue pumps], $item[kill screen],
				$item[pixel banana], $item[pixel lemon], $item[pixel beer],
				$item[pixel daiquiri], $item[miniature power pill], $item[pixel star],
				$item[power pill], $item[yellow pixel potion], $item[pixel coin],
				$item[yellow pixel], $item[yellow submarine]},
			$item[yellow puck with a bow on it] : {$item[blue pumps], $item[kill screen], $item[orange boxing gloves],
				$item[pixel banana], $item[pixel lemon], $item[pixel beer],
				$item[pixel daiquiri], $item[miniature power pill], $item[pixel star],
				$item[power pill], $item[yellow pixel potion], $item[pixel coin],
				$item[yellow pixel], $item[yellow submarine]},
			$item[Pack of Every Card] : {$item[The Emperor's new hat], $item[The Emperor's new pants], $item[The Emperor's new shirt],
				$item[candlestick], $item[knife], $item[lead pipe],
				$item[revolver], $item[rope], $item[wrench],
				$item[1952 Mickey Mantle card], $item[black mana], $item[blue mana],
				$item[bubblegum heart], $item[cubic zirconia], $item[Deck of Every Card],
				$item[gift card], $item[green mana], $item[hermit factoid],
				$item[red mana], $item[The Emperor's dry cleaning], $item[valuable coin],
				$item[white mana]},
			$item[airplane charter: That 70s Volcano] : {$item[biker's hat], $item[electrician's hardhat], $item[feathered headdress],
				$item[high-temperature mining mask], $item[lava balaclava], $item[smooth velvet hat],
				$item[lava-proof pants], $item[SMOOCH codpiece], $item[smooth velvet pants],
				$item[SMOOCH breastplate], $item[smooth velvet bra], $item[smooth velvet shirt],
				$item[grease cannon], $item[high-temperature mining drill], $item[lavalarva],
				$item[love], $item[Pener's drumstick], $item[basaltamander buckler],
				$item[blue LavaCo Lamp&trade;], $item[fireproof megaphone], $item[green LavaCo Lamp&trade;],
				$item[red LavaCo Lamp&trade;], $item[heat-resistant gloves], $item[heat-resistant necktie],
				$item[Mr. Cheeng's spectacles], $item[SMOOCH bracers], $item[SMOOCH kneepads],
				$item[SMOOCH spaulders], $item[smooth velvet hanky], $item[smooth velvet pocket square],
				$item[smooth velvet socks], $item[The One Mood Ring], $item[Lavalos's shell],
				$item[little deuce cape], $item[disco biscuit], $item[gooey lava globs],
				$item[lava cake], $item[mineapple], $item[smelted roe],
				$item[SMOOCH soda], $item[very hot lunch], $item[asbestos thermos],
				$item[Gold Velvet&trade; whiskey], $item[lavawater], $item[Quaatorade&trade;],
				$item[SMOOCH coffee cup], $item[basaltamander tongue], $item[demon makeup kit],
				$item[labrador cookie], $item[liquid rhinestones], $item[sticky lava globs],
				$item[&quot;DEBBIE&quot; tattoo kit], $item[1\,970 carat gold], $item[blue lava globs],
				$item[broken high-temperature mining drill], $item[capped blue lava bottle], $item[capped green lava bottle],
				$item[capped red lava bottle], $item[crystalline light bulb], $item[empty lava bottle],
				$item[full lava bottle], $item[fused fuse], $item[glass ceiling fragments],
				$item[glowing New Age crystal], $item[green lava globs], $item[half-melted hula girl],
				$item[heat-resistant sheet metal], $item[insulated gold wire], $item[Lava Miner's Daughter],
				$item[LavaCo&trade; Lamp housing], $item[Lavalos core], $item[Mr. Cheeng's 'stache],
				$item[Mr. Choch's bone], $item[New Age healing crystal], $item[New Age hurting crystal],
				$item[one-day ticket to That 70s Volcano], $item[Pener's crisps], $item[Psycho From The Heat],
				$item[Raul's guitar pick], $item[red lava globs], $item[Saturday Night thermometer],
				$item[signed deuce], $item[superduperheated metal], $item[superheated metal],
				$item[The Firegate Tapes], $item[the tongue of Smimmons], $item[thin gold wire],
				$item[uncapped blue lava bottle], $item[uncapped green lava bottle], $item[uncapped red lava bottle],
				$item[unsmoothed velvet], $item[viscous lava globs], $item[Volcoino]},
			$item[potted tea tree] : {$item[cuppa Flamibili tea], $item[cuppa Yet tea], $item[cuppa Boo tea],
				$item[cuppa Nas tea], $item[cuppa Improprie tea], $item[cuppa Frost tea],
				$item[cuppa Toast tea], $item[cuppa Net tea], $item[cuppa Proprie tea],
				$item[cuppa Morbidi tea], $item[cuppa Chari tea], $item[cuppa Serendipi tea],
				$item[cuppa Feroci tea], $item[cuppa Physicali tea], $item[cuppa Wit tea],
				$item[cuppa Neuroplastici tea], $item[cuppa Dexteri tea], $item[cuppa Flexibili tea],
				$item[cuppa Impregnabili tea], $item[cuppa Obscuri tea], $item[cuppa Irritabili tea],
				$item[cuppa Mediocri tea], $item[cuppa Loyal tea], $item[cuppa Activi tea],
				$item[cuppa Cruel tea], $item[cuppa Alacri tea], $item[cuppa Vitali tea],
				$item[cuppa Mana tea], $item[cuppa Monstrosi tea], $item[cuppa Twen tea],
				$item[cuppa Gill tea], $item[cuppa Uncertain tea], $item[cuppa Voraci tea],
				$item[cuppa Sobrie tea], $item[cuppa Royal tea], $item[cuppa Craft tea],
				$item[cuppa Insani tea]},
			$item[shrine to the Barrel god] : {$item[barrelhead], $item[bottoms of the barrel], $item[chest barrel],
				$item[barrel gun], $item[double barreled barrel gun], $item[triple barreled barrel gun],
				$item[barrel beryl], $item[barrel beryl choker], $item[barrel beryl nose ring],
				$item[barrel beryl ring], $item[barrel cracker], $item[barrel pickle],
				$item[water log], $item[barrel-aged martini], $item[bottle of Amontillado],
				$item[tiny barrel], $item[brass bung spigot]},
			$item[haunted doghouse] : {$item[bowl of eyeballs], $item[bowl of maggots], $item[bowl of mummy guts],
				$item[blood and blood], $item[Jack-O-Lantern beer], $item[zombie],
				$item[Ghost Dog Chow], $item[plastic nightmare troll], $item[Telltale&trade; rubber heart],
				$item[tennis ball], $item[wind-up spider]},
			$item[airplane charter: The Glaciest] : {$item[bellhop's hat], $item[norwhal helmet], $item[Wal-Mart overalls],
				$item[VYKEA hex key], $item[Wal-Mart snowglobe], $item[Walford's bucket],
				$item[sardine can key], $item[Wal-Mart nametag], $item[octolus-skin cloak],
				$item[iceberg lettuce], $item[tin of submardines], $item[VYKEA meatballs],
				$item[bottle of norwhiskey], $item[ice porter], $item[ice wine],
				$item[perfect cosmopolitan], $item[perfect dark and stormy], $item[perfect mimosa],
				$item[perfect negroni], $item[perfect old-fashioned], $item[perfect paloma],
				$item[VYKEA mead], $item[octolus oculus], $item[exotic travel brochure],
				$item[fancy chocolate], $item[frozen shampoo-conditioner], $item[shoulder-warming lotion],
				$item[VYKEA woadpaint], $item[Wal-Mart &quot;diamond&quot; ring], $item[bag of foreign bribes],
				$item[Cold Fang], $item[hotel minibar key], $item[ice hotel bell],
				$item[one-day ticket to The Glaciest], $item[perfect ice cube], $item[The Chill of the Wild],
				$item[The Fun-Guy Cold Weather Bartender's Guide], $item[To Build an Igloo], $item[VYKEA blood rune],
				$item[VYKEA bracket], $item[VYKEA dowel], $item[VYKEA frenzy rune],
				$item[VYKEA instructions], $item[VYKEA lightning rune], $item[VYKEA plank],
				$item[VYKEA rail], $item[Wal-Mart gift certificate], $item[Wal-Mart tattoo kit]},
			$item[machine elf capsule] : {$item[self-dribbling basketball], $item[Deep Machine Tunnels snowglobe], $item[abstraction: action],
				$item[abstraction: thought], $item[abstraction: sensation], $item[abstraction: purpose],
				$item[abstraction: category], $item[abstraction: perception], $item[abstraction: motion],
				$item[abstraction: joy], $item[abstraction: certainty], $item[abstraction: comprehension]},

			// 2016
			$item[basking robin] : {$item[tiny domino mask]},
			$item[X-32-F snowman crate] : {$item[training helmet], $item[training belt], $item[training legwarmers],
				$item[ice rice], $item[iced plum wine], $item[ancient medicinal herbs],
				$item[Martialest Arts trophy], $item[training scroll:  Shattering Punch], $item[training scroll:  Shivering Monkey Technique],
				$item[training scroll:  Snokebomb]},
			$item[LT&T telegraph office deed] : {$item[Amoon-Ra Cowtep's nemes], $item[Daisy's unclean bloomers], $item[Granny Hackleton's Gatling gun],
				$item[western-style skinning knife], $item[Heimz Fortified Kidney Beans], $item[Hellfire Spicy Beans],
				$item[Mixed Garbanzos and Chickpeas], $item[Pork 'n' Pork 'n' Pork 'n' Beans], $item[Shrub's Premium Baked Beans],
				$item[Tesla's Electroplated Beans], $item[Trader Olaf's Exotic Stinkbeans], $item[Val-U Brand Every Bean Salad],
				$item[World's Blackest-Eyed Peas], $item[Fancy Jeff's fancy pocket square], $item[Former Sheriff Dan's tin star],
				$item[Frigid Northern Beans], $item[nicksilver ring], $item[quicksilver ring],
				$item[sicksilver ring], $item[slicksilver ring], $item[steel knuckles],
				$item[thicksilver ring], $item[ticksilver ring], $item[wicksilver ring],
				$item[your cowboy boots], $item[diamondback skin], $item[frontwinder skin],
				$item[grizzled bearskin], $item[mountain lion skin], $item[nicksilver spurs],
				$item[quicksilver spurs], $item[thicksilver spurs], $item[ticksilver spurs],
				$item[bear claw], $item[plate of Frigid Northern Beans], $item[plate of Heimz Fortified Kidney Beans],
				$item[plate of Hellfire Spicy Beans], $item[plate of Mixed Garbanzos and Chickpeas], $item[plate of Pork 'n' Pork 'n' Pork 'n' Beans],
				$item[plate of Shrub's Premium Baked Beans], $item[plate of Tesla's Electroplated Beans], $item[plate of Trader Olaf's Exotic Stinkbeans],
				$item[plate of Val-U Brand Every Bean Salad], $item[plate of World's Blackest-Eyed Peas], $item[rotting beefsteak],
				$item[tainted milk], $item[firemilk], $item[moomy dust],
				$item[The Author's ink], $item[baconstone-handled sixgun], $item[custom sixgun],
				$item[hamethyst-handled sixgun], $item[makeshift sixgun], $item[Pecos Dave's sixgun],
				$item[porquoise-handled sixgun], $item[reliable sixgun], $item[rinky-dink sixgun],
				$item[buzzard feather], $item[demonic cow's blood], $item[ghost bit],
				$item[half-digested coal], $item[lion musk], $item[poker face paint],
				$item[rattler gland], $item[spidercow eye-cluster], $item[tightly-wound spine],
				$item[triggerfingerbone], $item[buffalo dime], $item[Clara's bell],
				$item[coal snakeskin], $item[cow poker], $item[El Vibrato restraints],
				$item[Glenn's golden dice], $item[gun parts], $item[Hell and How I Bent It],
				$item[inflatable LT&T telegraph office], $item[jangly spurs], $item[LT&T tattoo kit],
				$item[nugget of nicksilver], $item[nugget of quicksilver], $item[nugget of sicksilver],
				$item[nugget of slicksilver], $item[nugget of thicksilver], $item[nugget of ticksilver],
				$item[nugget of wicksilver], $item[plaintive telegram], $item[realistic cap gun],
				$item[red-hot knucklebone], $item[rotting cowskin], $item[shuddering cow skull],
				$item[sicksilver spurs], $item[silver cow skull], $item[slicksilver spurs],
				$item[Tales of Western Braggadoccio], $item[The Western Look], $item[wicksilver spurs],
				$item[rhinestone cowhorn]},
			$item[Witchess Set] : {$item[very pointy crown], $item[dented scepter], $item[ox-head shield],
				$item[battle broom], $item[jumping horseradish], $item[Sacramento wine],
				$item[armored prawn], $item[Greek fire]},
			$item[Clan Floundry] : {$item[fishin' hat], $item[troutsers], $item[tunac],
				$item[bass clarinet], $item[fish hatchet], $item[sonar fishfinder],
				$item[codpiece], $item[carpe], $item[bottle of Fishhead 900-Day IPA],
				$item[high-test fishing line], $item[wriggling worm], $item[antique tacklebox],
				$item[fishin' pole], $item[luxury fly-tying workbench], $item[Trout Fishing in Loathing]},
			$item[disconnected intergnat] : {$item[high-speed upgrade], $item[First Post shirt - Cir Senam], $item[gallon of milk],
				$item[BACON], $item[daily dungeon malware], $item[First Post shirt package],
				$item[infinite BACON machine], $item[internet point], $item[meme generator],
				$item[plus one], $item[print screen button], $item[screencapped monster],
				$item[viral video]},
			$item[Source terminal] : {$item[Source shades], $item[browser cookie], $item[hacked gibson],
				$item[green pill], $item[software bug], $item[Source essence],
				$item[Source terminal ASHRAM chip], $item[Source terminal CRAM chip], $item[Source terminal DIAGRAM chip],
				$item[Source terminal DRAM chip], $item[Source terminal file: compress.edu], $item[Source terminal file: cram.ext],
				$item[Source terminal file: critical.enh], $item[Source terminal file: damage.enh], $item[Source terminal file: dram.ext],
				$item[Source terminal file: duplicate.edu], $item[Source terminal file: familiar.ext], $item[Source terminal file: gram.ext],
				$item[Source terminal file: portscan.edu], $item[Source terminal file: pram.ext], $item[Source terminal file: protect.enq],
				$item[Source terminal file: spam.ext], $item[Source terminal file: stats.enq], $item[Source terminal file: substats.enh],
				$item[Source terminal file: tram.ext], $item[Source terminal file: turbo.edu], $item[Source terminal GRAM chip],
				$item[Source terminal INGRAM chip], $item[Source terminal PRAM chip], $item[Source terminal SCRAM chip],
				$item[Source terminal SPAM chip], $item[Source terminal TRAM chip], $item[Source terminal TRIGRAM chip],
				$item[missing semicolon]},
			$item[detective school application] : {$item[noir fedora], $item[trench coat], $item[detective roscoe],
				$item[bronze detective badge], $item[gold detective badge], $item[plastic detective badge],
				$item[silver detective badge], $item[hardboiled egg], $item[Falcon&trade; Maltese Liquor],
				$item[shoe gum], $item[cop dollar], $item[detective tattoo]},
			$item[DIY protonic accelerator kit] : {$item[protonic accelerator pack], $item[psychokinetic energy blob], $item[almost-dead walkie-talkie]},
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

			// 2017
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

			// 2018
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

			// 2019
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

			// 2020
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

			// 2021
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

			// 2022
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

			// 2023
			$item[unoccupied sheep suit] : {$item[half-height cigar], $item[grubby wool], $item[grubby wool hat], $item[grubby wool scarf],
				$item[grubby wool trousers], $item[grubby wool gloves], $item[grubby wool beerwarmer], $item[nice warm beer], $item[grubby woolball]},
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
			$item[sleeping patriotic eagle] : {$item[claw-held flag], $item[souvenir flag]},
			$item[boxed august scepter] : {$item[august scepter], $item[11-leaf clover],
				$item[watermelon], $item[watermelon seed], $item[water balloon],
				$item[magnificent oyster egg], $item[brilliant oyster egg], $item[glistening oyster egg], $item[scintillating oyster egg],
				$item[pearlescent oyster egg], $item[lustrous oyster egg], $item[gleaming oyster egg],
				$item[thriftshop coupon], $item[waffle], $item[fixodent], $item[cat o' nine teeth], $item[tooth cap], $item[toothy trousers],
				$item[banana split], $item[handful of toilet paper], $item[Mrs. Rush], $item[tiny gold medal],
				$item[bottle of Cabernet Sauvignon], $item[baywatch], $item[tiny consolation ribbon]},
			$item[book of facts] : {$item[book of facts (dog-eared)], $item[concentrated cooking], $item[ancient meat],
				$item[sparkling orb], $item[hardening cream], $item[pool shark hair oil], $item[pocket wish], $item[tattered scrap of paper]},
			$item[Dark Jill-of-All-Trades] : {$item[LED candle]},
			$item[A Guide to Burning Leaves] : {$item[inflammable leaf], $item[tiny rake], $item[rake],
				$item[autumnic bomb], $item[forest canopy bed], $item[day shortener], $item[extra time], $item[autumnal aegis],
				$item[distilled resin], $item[super-heated leaf], $item[lit leaf lasso],
				$item[tied-up flaming leaflet], $item[tied-up flaming monstera], $item[tied-up leaviathan],
				$item[impromptu torch], $item[flaming fig leaf], $item[smoldering drape], $item[smoldering leafcutter ant egg],
				$item[flaming leaf crown], $item[leafy browns], $item[autumnic balm], $item[coping juice]},
			$item[wrapped candy cane sword cane] : {$item[candy cane sword cane]},

			// 2024
			$item[Black and White Apron Enrollment Form] : {$item[Black and White Apron Meal Kit]},
			$item[baby chest mimic] : {$item[googly chest eyes], $item[mimic egg]},
			$item[in-the-box spring shoes] : {$item[spring shoes], $item[ultra-soft ferns], $item[crunchy brush]},
			$item[packaged Everfull Dart Holster] : {$item[Everfull Dart Holster]},
			$item[boxed Apriling band helmet] : {$item[Apriling band helmet], $item[Apriling band saxophone],
				$item[Apriling band quad tom], $item[Apriling band tuba], $item[Apriling band staff], $item[Apriling band piccolo]},
			$item[boxed Mayam Calendar] : {$item[Mayam Calendar], $item[yam], $item[yam martini], $item[sweet potato o' mine],
				$item[Southern yam], $item[sweet potato punch], $item[Mayam spinach], $item[yam and swiss], $item[yam cannon],
				$item[tiny yam cannon], $item[yam battery], $item[stuffed yam stinkbomb], $item[furry yam buckler],
				$item[thanksgiving bomb], $item[yamtility belt], $item[yam slider], $item[yam mayo], $item[yam burrito]},
			$item[mini kiwi egg] : {$item[aviator goggles], $item[mini kiwi], $item[mini kiwi bikini], $item[mini kiwitini],
				$item[mini kiwi invisible dirigible], $item[mini kiwi aioli], $item[mini kiwi silicon tiepin], $item[mini kiwi tipi],
				$item[mini kiwi digitized cookies], $item[mini kiwi intoxicating spirits], $item[mini kiwi antimilitaristic hippy petition],
				$item[mini kiwi illicit antibiotic], $item[mini kiwi whipping stick], $item[mini kiwi icepick], $item[mini kiwi-flavored aspirin-injecting lipstick]},
			$item[packaged Roman Candelabra] : {$item[Roman Candelabra]},
			$item[untorn tearaway pants package] : {$item[tearaway pants]},
			$item[boxed Sept-Ember Censer] : {$item[Sept-Ember Censer], $item[blade of dismemberment], $item[miniature Embering Hulk],
				$item[Mmm-brr! brand mouthwash], $item[Septapus summoning charm], $item[structural ember], $item[embers-only jacket],
				$item[bembershoot], $item[wheel of camembert], $item[hat of remembering], $item[throwin' ember], $item[head of emberg lettuce],
				$item[embering hunk], $item[ember egg], $item[tiny ember]},
			$item[boxed bat wings] : {$item[bat wings]},
			$item[photo booth sized crate] : {$item[Clan VIP Lounge key], $item[oversized monocle on a stick], $item[cheap plastic pipe],
				$item[fake arrow-through-the-head], $item[giant bow tie], $item[fake huge beard], $item[astronaut helmet],
				$item[feather boa], $item[Sheriff badge], $item[Sheriff pistol], $item[Sheriff moustache], $item[photo booth supply list]},
			$item[peace turkey outline] : {$item[tie-dye headband], $item[whirled peas], $item[peaza], $item[peace shooter],
				$item[pea brittle], $item[peasco sour], $item[piece of cake], $item[handful of split pea soup]},
			$item[Sealed TakerSpace letter of Marque] : {$item[TakerSpace letter of Marque], $item[deft pirate hook],
				$item[iron tricorn hat], $item[jolly roger flag], $item[sleeping profane parrot], $item[pirrrate's currrse],
				$item[tankard of spiced rum], $item[tankard of spiced Goldschlepper], $item[packaged luxury garment],
				$item[governor's daughter's lace collar], $item[governor's daughter's petticoats], $item[governor's daughter's pearl hairpin],
				$item[harpoon], $item[chili powder cutlass], $item[cursed Aztec tamale], $item[jolly roger tattoo kit], $item[golden pet rock],
				$item[groggles], $item[pirate dinghy], $item[anchor bomb], $item[silky pirate drawers], $item[profane eye patch], $item[spices]},

			// 2025
			$item[CyberRealm keycode] : {
				$item[cyburger], $item[cybeer], $item[ICEbox],
				$item[wired underwear], $item[1], $item[0],
				$item[eXpand], $item[brute force hammer], $item[datastick],
				$item[dedigitizer schematic: brute force hammer], $item[dedigitizer schematic: malware injector], $item[dedigitizer schematic: cybervisor],
				$item[dedigitizer schematic: digibritches], $item[dedigitizer schematic: cryptocloak], $item[dedigitizer schematic: zero-trust tanktop],
				$item[dedigitizer schematic: retro floppy disk], $item[dedigitizer schematic: pocket GPU], $item[dedigitizer schematic: trojan horseshoe],
				$item[dedigitizer schematic: familiar-in-the-middle], $item[cybervisor], $item[retro floppy disk],
				$item[pocket GPU], $item[malware injector], $item[server room key],
				$item[3d printed server room key], $item[dedigitizer schematic: 3d printed server room key], $item[logic grenade],
				$item[psilocyber mushroom], $item[dedigitizer schematic: SLEEP(5) rom chip], $item[dedigitizer schematic: OVERCLOCK(10) rom chip],
				$item[dedigitizer schematic: STATS+++ rom chip], $item[dedigitizer schematic: insignificant bit], $item[dedigitizer schematic: hashing vise],
				$item[dedigitizer schematic: geofencing rapier], $item[dedigitizer schematic: geofencing shield], $item[dedigitizer schematic: virtual cybertattoo],
				$item[SLEEP(5) rom chip], $item[OVERCLOCK(10) rom chip], $item[STATS+++ rom chip],
				$item[insignificant bit], $item[parity bit], $item[hashing vise],
				$item[geofencing rapier], $item[geofencing shield], $item[virtual cybertattoo],
				$item[synthetic coffee], $item[iDrops], $item[digibritches],
				$item[cryptocloak], $item[zero-trust tanktop], $item[familiar-in-the-middle wrapper],
				$item[trojan horseshoe], $item[dedigitizer schematic: cybeer], $item[dedigitizer schematic: cyburger],
				$item[dedigitizer schematic: psilocyber mushroom]},
			$item[McHugeLarge deluxe ski set] : {$item[McHugeLarge duffel bag], $item[McHugeLarge left pole],
				$item[McHugeLarge right pole], $item[McHugeLarge left ski], $item[McHugeLarge right ski]},
			$item[new-in-box toy Cupid bow] : {$item[toy Cupid bow]},
			$item[assemble-it-yourself Leprecondo] : {$item[Leprecondo], $item[scoop of pre-workout powder], $item[table tennis ball],
				$item[pint of Leprechaun Stout], $item[phosphor traces], $item[crafting plans], $item[Book of Irony], $item[spoon],
				$item[unironic knife], $item[bar dart], $item[leprechaun antidepressant pill], $item[Heck ramen], $item[tiny burrito],
				$item[small beer brat], $item[tiny peach pie], $item[incredible mini-pizza], $item[Divine sidecar], $item[tangarita sidecar],
				$item[gimlet sidecar], $item[vodka stratocaster sidecar], $item[prussian cathouse sidecar], $item[Mon Tiki sidecar]},
			$item[Packaged April Shower Thoughts Calendar] : {$item[April Shower Thoughts shield], $item[glob of wet paper],
				$item[spitball], $item[wet paper weights], $item[Three Sheets to the Wind], $item[pile of wet dates], $item[papier Mach 1 airplane],
				$item[wet blanket], $item[wet shower cap], $item[wet shower shoes], $item[wet shower shorts], $item[wet paper tiger],
				$item[wet paper eye], $item[wet shower curtain], $item[wet paper cup], $item[wet paperback], $item[wet shower radio], $item[wet shower stamp]},
			$item[Unpeeled Peridot of Peril] : {$item[Peridot of Peril]},
			$item[packaged prismatic beret] : {$item[prismatic beret]},
			$item[yeti in a travel cooler] : {$item[cold exchanger]},
			$item[M&ouml;bius ring box] : {$item[M&ouml;bius ring]},
			$item[packaged Monodent of the Sea] : {$item[Monodent of the Sea]},
			$item[lab-grown blood cubic zirconia] : {$item[blood cubic zirconia]},
			$item[shrunken head in a duffel bag] : {$item[shrunken head]},
			$item[stocking full of bones] : {$item[small peppermint-flavored sugar walking crook], $item[knucklebone],
				$item[Smoking Pope], $item[prize turkey], $item[medicinal gruel]},

			// 2026
			$item[discreetly-wrapped Eternity Codpiece] : {$item[The Eternity Codpiece]},
			$item[seal-clubbing club loot box] : {$item[legendary seal-clubbing club]},
			$item[boxed Heartstone] : {$item[Heartstone]},
			$item[boxed Archaeologist's Spade] : {$item[Archaeologist's Spade], $item[dinosaur bone fragment],
				$item[ancient Pork Elf pottery shard], $item[2015 landfill detritus], $item[intact dinosaur egg], $item[fossilized cow femur],
				$item[unopened Pork Elf toiletries kit], $item[Pork Elf toiletries kit], $item[Pork Elf mouthwash], $item[Pork Elf deodorant],
				$item[Pork Elf toothpaste], $item[bolt of striped fabric], $item[white and gold dress], $item[blue and black dress],
				$item[dinosaur bone broth], $item[giant gnawing bone], $item[dinosaur bone club], $item[dinosaur skull helmet], $item[dinosaur bone corset],
				$item[Pork Elf cough syrup], $item[Pork Elf neti pot], $item[Pork Elf medicine cabinet], $item[Pork Elf sink], $item[Pork Elf toilet],
				$item[rat pizza], $item[Fleek&trade; mascara], $item[hoverboard], $item[left shark fin], $item[fitness tracking bracelet]},
			$item[wrapped Baseball Diamond] : {$item[Baseball Diamond], $item[discarded hot dog], $item[most of a beer]},
			$item[pasta wand loot box] : {$item[legendary pasta wand], $item[legendary noodles],
				$item[Frutti di Scatoletta], $item[Pesto alla Marziano], $item[Arrattabbattabiata], $item[Orzo di Riso], $item[Pasta Grimavera],
				$item[Linguini Ubriacapa], $item[Formica e Pepe], $item[Tubetto Gelatto], $item[Gnocci Domani]},
			$item[scabbarded Sword of S Words] : {$item[second-hand synthetic sloth skin scabbard]},
			$item[shrink-wrapped Cup of 13s] : {$item[Cup of 13s]},
			$item[Interesting Coin Inheritance Letter] : {$item[Interesting Coin], $item[Roth IPA], $item[underdraft protection],
				$item[solvent], $item[soybean futures], $item[housing bubble], $item[Pixie-Swordz], $item[financial instrument],
				$item[hedge fund clippers], $item[selling shorts], $item[bear tattoo], $item[bull tattoo], $item[401k gold ring],
				$item[balance sheet], $item[invisible hand], $item[circle of overdraft protection scroll], $item[mint], $item[savings bondo],
				$item[homeowner's loam], $item[toxic asset], $item[intangible asset], $item[liquid asset], $item[gross prophet chrysalis]},
			$item[meat shield toddler] : {$item[can of shield tenderizer]},
			$item[black rosebud] : {$item[black rose bowl], $item[black garden rose], $item[pressed black garden rose], $item[black garden ros&eacute;],
				$item[clove incense], $item[black thorn key], $item[black rose pentacle], $item[statuary chunk], $item[partial tombstone],
				$item[giant stonefruit], $item[bed of stone roses], $item[wide-eyed cherub statue], $item[black thorn crown],
				$item[black thorn necklace], $item[black thorn whip], $item[black thorn sarong], $item[tiny stone harp],
				$item[black rose pastille], $item[black rose hips extract]},
			$item[unopened legendary acorndion] : {$item[legendary acorndion]},

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
	print_html("<strong style=\"color:blue;\">top10 <i>item</i></strong>: Add items to make the top 10 -- will save items according to the item saving rules (see below), and will only put smm.dcOvershootAmount (default: 11) more than the next lowest rank if it can't make it to the next higher rank. Copies already in the case are kept; with smm.dcAllowRemoval=true (or smm.IR.museum=false) it also removes copies beyond that amount, and everything if it can't achieve rank #10.");
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

	print_html("<h4>Museum rankings:</h4>");
	print_html("<br/>Rankings are stored in data/smm-museum-ranks-<i>id</i>.txt and reused across days. An item never seen before is looked up when first needed; after that only 'refresh' renews it.");
	print_html("<strong style=\"color:blue;\">refresh [<i>n</i>]</strong>: renew the <i>n</i> stalest rankings (default: everything due). Covers the Display Case and every stored item; never-checked first, then oldest.");
	print_html("<strong style=\"color:blue;\">refresh <i>item</i></strong>: renew one item now.");
	print_html("<strong style=\"color:blue;\">cache</strong>: how many rankings are stored, how old they are, and how many lookups were made today.");

    print_html("<br/><strong>target item</strong>: report the first-place target, reserves, and additional items needed; never moves or buys items.");
    print_html("<strong>top1 item</strong>: add owned items toward first place plus smm.dcOvershootAmount (default 11), respecting reserves; supports --dry-run and never buys or pulls shop stock.");
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
// Shared first-place policy for dc and crafting. Museum groups tied collectors
// in one row, so use player IDs when finding the highest other collection.
int dcHighestOther(string page, int ourId) {
    if (!contains_text(to_lower_case(page), "</table>")) return -1;
    matcher rows = create_matcher("(?is)<tr\\b[^>]*>(.*?)</tr>", page);
    boolean sawLeader;
    while (find(rows)) {
        string row = group(rows, 1);
        matcher players = create_matcher("href\\s*=\\s*['\"]/player/([0-9]+)['\"]", row);
        if (!find(players)) continue;
        boolean hasOther = to_int(group(players, 1)) != ourId;
        while (find(players)) if (to_int(group(players, 1)) != ourId) hasOther = true;
        row = replace_all(create_matcher("(?is)<style\\b[^>]*>.*?</style>", row), "");
        matcher cells = create_matcher("(?is)<td\\b[^>]*>(.*?)</td>", row);
        string [int] values;
        int idx;
        while (find(cells)) {
            string text = entity_decode(replace_all(create_matcher("(?s)<[^>]*>", group(cells, 1)), ""));
            values[idx++] = replace_all(create_matcher("^\\s+|\\s+$", text), "");
        }
        if (idx < 3 || (!sawLeader && values[0] != "🥇" && values[0] != "#1")) return -1;
        string amount = replace_string(values[2], ",", "");
        if (!amount.is_integer() || to_int(amount) < 1) return -1;
        sawLeader = true;
        if (hasOther) return to_int(amount);
    }
    return sawLeader ? 0 : -1;
}

record DCFirstPlacePlan {
    item result;
    int highestOther;
    int target;
    int displayed;
    int owned;
    int reserved;
    int needed;
};

DCFirstPlacePlan dcFirstPlacePlan(item it, int highestOther) {
    DCFirstPlacePlan plan;
    plan.result = it;
    plan.highestOther = highestOther;
    plan.target = -1;
    if (highestOther < 0 || !have_display() || !is_displayable(it)) return plan;
    plan.target = highestOther + gkDCOvershootAmount;
    plan.displayed = display_amount(it);
    plan.owned = item_amount(it) + closet_amount(it) + (can_interact() ? storage_amount(it) : 0);
    plan.reserved = saveAmount(it);
    // dc's established policy keeps reserved items out and does not pull shop stock.
    int displayShortfall = max(0, plan.target - plan.displayed);
    plan.needed = displayShortfall > 0 ? max(0, displayShortfall + plan.reserved - plan.owned) : 0;
    return plan;
}

DCFirstPlacePlan dcFirstPlacePlan(item it) {
    int highestOther = -1;
    if (have_display() && is_displayable(it)) {
        string key = "_smm.DCFirstRivalFor" + to_int(it);
        string cached = get_property(key);
        if (cached.is_integer() && to_int(cached) >= 0)
            highestOther = to_int(cached);
        else {
            highestOther = dcHighestOther(visit_url("https://museum.loathers.net/item/" + to_int(it), false, false), to_int(my_id()));
            if (highestOther >= 0) set_property(key, highestOther);
        }
    }
    return dcFirstPlacePlan(it, highestOther);
}

void dcPrintFirstPlacePlan(DCFirstPlacePlan plan) {
    // Stable, numeric-only interface for other scripts; target is -1 when unknown.
    print("DC_TARGET:" + to_int(plan.result) + ":" + plan.highestOther + ":" + plan.target
        + ":" + plan.displayed + ":" + plan.owned + ":" + plan.reserved + ":" + plan.needed);
}

int dcFillFirstPlace(item it, boolean dryRun) {
    DCFirstPlacePlan plan = dcFirstPlacePlan(it);
    dcPrintFirstPlacePlan(plan);
    if (plan.target < 0) return -1;
    int toMove = min(max(0, plan.target - plan.displayed), max(0, plan.owned - plan.reserved));
    print("dc top1: " + it + ", target " + plan.target + " (highest other " + plan.highestOther
        + " + " + gkDCOvershootAmount + "), reserve " + plan.reserved + ", "
        + (dryRun ? "would add " : "adding ") + toMove);
    if (dryRun || toMove == 0) return 0;
    int missing = max(0, toMove - item_amount(it));
    if (missing > 0 && can_interact()) take_storage(min(missing, storage_amount(it)), it);
    missing = max(0, toMove - item_amount(it));
    if (missing > 0) take_closet(min(missing, closet_amount(it)), it);
    if (item_amount(it) < toMove || !put_display(toMove, it)) return -1;
    return toMove;
}

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
// removes items to enforce the above rules only when smm.dcAllowRemoval=true or smm.IR.museum=false
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
		// Museum policy: copies already in the case stay there. Deposits aim at #1, so trimming
		// to the best rank reachable today only undoes them. smm.dcAllowRemoval=true restores trimming.
		if (get_property("smm.IR.museum") != "false" && get_property("smm.dcAllowRemoval") != "true") {
			print("dc: you have " + displayAmount + " " + anItem + " in the case; the top10 goal is " + goalAmount + ", keeping the extra " + (-putAmount) + " in the case (set smm.dcAllowRemoval=true to remove)", "blue");
			return 0;
		}
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



// ---------------------------------------------------------------- Museum ranking rotation
// Rankings are kept in the Museum ranking store (smmUtils.ash) and reused
// across days; 'dc refresh' renews the stalest ones, one request a second.

// Everything worth keeping current: what is in the Display Case, plus every
// item already in the store.
boolean [item] dcMuseumRotationItems() {
	boolean [item] rval;
	if (have_display())
		foreach it in get_display()
			rval[it] = true;
	smmMuseumStoreLoad();
	foreach id in smmMuseumStore
		if (id.to_item() != $item[none])
			rval[id.to_item()] = true;
	return rval;
}

// Never-checked items first, then the oldest. Items we hold no copy of count
// as 30 days fresher, so the ones we are actually collecting come round first.
int dcMuseumRotationKey(item it) {
	if (!smmMuseumStored(it)) return 0;
	boolean held = (have_display() && display_amount(it) > 0) || available_amount(it) > 0;
	return smmMuseumEntry(it).checked + (held ? 0 : 30 * 86400);
}

// Renew up to limit of the stalest rankings (everything due when limit is 0).
// Returns the number renewed.
int dcMuseumRefresh(int limit) {
	if (limit < 1) limit = 1000000;
	item [int] queue;
	foreach it in dcMuseumRotationItems()
		queue[count(queue)] = it;
	int [item] keys;
	foreach i, it in queue
		keys[it] = dcMuseumRotationKey(it);
	sort queue by keys[value];

	// what is due: never looked up, or last looked up more than 20 hours ago
	int due;
	int neverChecked;
	foreach i, it in queue {
		if (!smmMuseumStored(it)) neverChecked++;
		else if (smmMuseumNow() - smmMuseumEntry(it).checked < 20 * 3600) continue;
		due++;
	}
	int planned = min(limit, due);
	print("Museum refresh: " + count(queue) + " items in rotation, " + due + " due (" + neverChecked + " never looked up). Renewing "
		+ planned + " now, about " + planned + " seconds. Lookups made today: " + smmMuseumLookupsUsed() + ".", "blue");

	int done;
	int failed;
	foreach i, it in queue {
		if (done + failed >= limit) break;
		// already looked up in the last 20 hours: everything after it is at least as fresh
		if (smmMuseumStored(it) && smmMuseumNow() - smmMuseumEntry(it).checked < 20 * 3600) break;
		if (done + failed > 0) waitq(1);
		string before = smmMuseumStored(it) ? smmMuseumAgeDays(it) + " days old" : "new";
		string label = "[" + (done + failed + 1) + "/" + planned + "] " + it + " (" + before + "): ";
		if (smmMuseumFetch(it)) {
			done++;
			SmmMuseumEntry entry = smmMuseumEntry(it);
			int [int, string] ranks = smmMuseumStoredList(it);
			if (entry.holders == 0)
				print(label + "nobody displays it");
			else
				print(label + entry.holders + " collector" + (entry.holders == 1 ? "" : "s") + ", #1 has " + rank1Amount(ranks)
					+ (countTop10(ranks) >= 10 ? ", #10 has " + rank10Amount(ranks) : "")
					+ "; " + (entry.my_rank > 0 ? "we are #" + entry.my_rank + " with " + entry.mine : "we are not listed"));
		} else {
			failed++;
			print(label + "Museum page not understood; left as it was.", "orange");
			if (failed >= 5 && done == 0) {
				print("Five lookups failed in a row; stopping.", "red");
				break;
			}
		}
	}
	if (due - done > 0)
		print((due - done) + " items still due; run 'dc refresh' again to renew them.");
	print("Renewed " + done + " Museum ranking" + (done == 1 ? "" : "s") + (failed > 0 ? ", " + failed + " failed" : "")
		+ ". Lookups made today: " + smmMuseumLookupsUsed() + ".", "blue");
	return done;
}

void dcMuseumCacheStatus() {
	int stored;
	int missing;
	int oldest;
	int [int] ages; // age in days => number of items
	foreach it in dcMuseumRotationItems() {
		if (!smmMuseumStored(it)) {
			missing++;
			continue;
		}
		stored++;
		int age = smmMuseumAgeDays(it);
		oldest = max(oldest, age);
		ages[age < 1 ? 0 : age <= 7 ? 7 : age <= 30 ? 30 : 31]++;
	}
	print("Museum rankings stored: " + stored + "; Display Case items never looked up: " + missing, "blue");
	print("Age: today " + ages[0] + ", 1-7 days " + ages[7] + ", 8-30 days " + ages[30] + ", older " + ages[31] + " (oldest " + oldest + " days)");
	print("Lookups made today: " + smmMuseumLookupsUsed() + ". A full 'dc refresh' of " + (stored + missing) + " items takes about " + (stored + missing) + " seconds.");
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

	// Museum ranking store: no item argument needed
	if (argv[0] == "cache") {
		dcMuseumCacheStatus();
		return;
	}
	if (argv[0] == "refresh") {
		string what = cdr(argv).joinString(" ");
		if (what == "" || what.is_integer()) {
			dcMuseumRefresh(what == "" ? 0 : what.to_int());
			return;
		}
		item one = what.to_item();
		assert(one != $item[none], "bad item: " + what);
		if (!smmMuseumFetch(one))
			print("Museum ranking not understood for " + one + "; left as it was.", "orange");
		dcPrintItemDetails(one, lookupCollection(one, false));
		return;
	}

	// PROCESS ARGS: everything else
	boolean [string] kAcceptedOptions = {"--dry-run": true};
	boolean [string] kAcceptedCommands = {"target": true, "top1": true, "top10": true, "auto": true, "addall": true, "rankup": true,
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
	if (tempArgv[0].is_integer() && command != "target" && command != "top1") {
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
        case "target":
            dcPrintFirstPlacePlan(dcFirstPlacePlan(anItem));
            return;
        case "top1":
            if (dcFillFirstPlace(anItem, dryRun) < 0 && !dryRun)
                abort("dc top1: rankings unavailable or transfer failed");
            return;
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
