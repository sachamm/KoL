import <smmIotmRouteCore.ash>
import <smmIotmRouteExtras.ash>

// Second adapter batch, continuing in reverse release order after the first
// execution layer. Every worker here is free of adventures, produces a real
// item (or a confirmed daily flag) and is confirmed by an observed change.
// Mechanics are taken from the local KoLmafia source: coinmasters.txt,
// concoctions.txt, TakerSpaceRequest, BurningLeavesRequest and defaults.txt.

// Small per-day/ascension counters for limits the game does not track itself.
int smmIRDayCount(string name) {
    return get_property("smm.IR."+name+"Epoch")==smmRPEpoch() ? get_property("smm.IR."+name).to_int() : 0;
}

void smmIRDayBump(string name, int amount) {
    if (amount<1) return;
    int used=smmIRDayCount(name);
    set_property("smm.IR."+name+"Epoch",smmRPEpoch()); set_property("smm.IR."+name,used+amount);
}

// Walk away from a non-binding choice (workshed, leaf pile) so the route never
// reports an unfinished encounter for a page that merely stayed open.
void smmIRWalkAway(int choice) {
    if (handling_choice() && last_choice()==choice) smmIRVisit("main.php");
}

void smmIRMoreDiscover() {
    // The ember balance is only trustworthy after the shop was seen today.
    if (available_amount($item[Sept-Ember Censer])>0 && !get_property("_septEmberBalanceChecked").to_boolean())
        smmIRVisit("shop.php?whichshop=september");
}

// 2025-10 blood cubic zirconia: only the three item-making skills, and only
// the cheap early casts. Substat prices escalate steeply, so the cast count is
// capped and the observed substat loss is checked after every cast.
int smmIRSubstats() {
    return my_basestat($stat[submuscle])+my_basestat($stat[submysticality])+my_basestat($stat[submoxie]);
}

float smmIRZirconiaEstimate(int casts) {
    // Reported schedule: 11, 23, 37, then ten times as much every three casts.
    // An estimate for planning only; the worker measures the real loss.
    float [int] base={11.0,23.0,37.0};
    float cost=base[casts % 3];
    int tier=casts/3;
    while (tier>0) { cost*=10; tier-=1; }
    return cost;
}

void smmIRGenerateZirconia() {
    item gem=$item[blood cubic zirconia];
    if (available_amount(gem)<1 || !can_equip(gem)) return;
    int [int] ids={7577,7578,7579};
    item [int] products={$item[blood thinner],$item[spinal tapas],$item[pheromone cocktail]};
    string [int] counters={"_bczBloodThinnerCasts","_bczSpinalTapasCasts","_bczPheromoneCocktailCasts"};
    int cap=min(22,max(0,smmIRSetting("bczCasts",3).to_int()));
    foreach i, id in ids {
        int casts=get_property(counters[i]).to_int();
        if (casts>=cap) continue;
        float cost=smmIRZirconiaEstimate(casts)*max(0,smmIRSetting("substatValue",1));
        float value=smmIRRewardValue(products[i]);
        SmmIRWork work; work.kind="more.cast"; work.cast=to_skill(id); work.product=products[i]; work.counter=counters[i];
        work.option=ceil(smmIRZirconiaEstimate(casts)).to_int();
        work.why="Cast "+(casts+1)+" of "+work.cast+" costs about "+work.option+" base substats (valued at "+round(cost)+" Meat). It makes a "+products[i]+" worth "+round(value)+" Meat; "+smmIRValueNote(products[i])+". Only the cheapest casts (up to "+cap+" per skill today) are taken.";
        work.expect="Cast succeeds, "+products[i]+" +1 in inventory, and the substat loss stays near "+work.option+" (the worker stops this skill if it is far higher).";
        if (value>cost || (smmMuseumEnabled() && smmMuseumProgress(products[i],1)>0))
            smmIRAdd("2025-10.bcz."+id,"Zirconia: cheap cast "+(casts+1)+" making "+products[i],work,value,cost,"",0);
    }
}

// 2025-01 McHugeLarge duffel bag: unpack the ski set once per ascension.
void smmIRGenerateDuffel() {
    if (available_amount($item[McHugeLarge duffel bag])<1) return;
    foreach it in $items[McHugeLarge left pole,McHugeLarge right pole,McHugeLarge left ski,McHugeLarge right ski]
        if (available_amount(it)>0) return;
    SmmIRWork work; work.kind="more.duffel"; work.product=$item[McHugeLarge left pole];
    work.why="Free once per ascension: unpacking the duffel bag gives the McHugeLarge ski set (pole, skis). No Meat value is claimed; it is taken as a free utility and collection item.";
    work.expect="The four McHugeLarge pieces (left/right pole, left/right ski) appear in inventory.";
    smmIRAdd("2025-01.duffel","Unpack this ascension's McHugeLarge ski set",work,0,0,"",0);
    smmIRUtility("2025-01.duffel");
}

// 2024-12 TakerSpace: collect the delivery, then turn supplies into products.
// Costs are spice, rum, anchor, mast, silk, gold (from TakerSpaceRequest).
string [item] smmIRTakerRecipes() {
    string [item] recipes;
    recipes[$item[deft pirate hook]]="0,0,1,1,0,1"; recipes[$item[iron tricorn hat]]="0,0,2,1,0,0";
    recipes[$item[jolly roger flag]]="0,1,0,1,1,0"; recipes[$item[sleeping profane parrot]]="15,3,0,0,2,1";
    recipes[$item[pirrrate's currrse]]="2,2,0,0,0,0"; recipes[$item[tankard of spiced rum]]="1,2,0,0,0,0";
    recipes[$item[tankard of spiced Goldschlepper]]="0,2,0,0,0,1"; recipes[$item[packaged luxury garment]]="0,0,0,0,3,2";
    recipes[$item[harpoon]]="0,0,0,2,0,0"; recipes[$item[chili powder cutlass]]="5,0,1,0,0,0";
    recipes[$item[cursed Aztec tamale]]="2,0,0,0,0,0"; recipes[$item[golden pet rock]]="0,0,0,0,0,7";
    recipes[$item[groggles]]="0,6,0,0,0,0"; recipes[$item[anchor bomb]]="0,1,3,1,0,1";
    recipes[$item[silky pirate drawers]]="0,0,0,0,2,0"; recipes[$item[spices]]="1,0,0,0,0,0";
    // The tattoo kit and dinghy are one-time unlocks, not collection stock.
    return recipes;
}

void smmIRGenerateTaker() {
    if (get_workshed()!=$item[TakerSpace letter of Marque]) return;
    if (!get_property("_takerSpaceSuppliesDelivered").to_boolean()) {
        SmmIRWork work; work.kind="more.taker.collect"; work.counter="_takerSpaceSuppliesDelivered";
        work.why="The daily TakerSpace delivery is free and must be collected before any supplies can be spent; supply counts are unreliable until it is seen.";
        work.expect="Spice, rum, anchors and masts rise by about 3 each and silk and gold by about 1 each; the delivered flag becomes true.";
        smmIRAdd("2024-12.taker.collect","Collect today's TakerSpace delivery",work,0,0,"",0);
        smmIRUtility("2024-12.taker.collect");
        return; // supply counts are stale until the delivery is seen
    }
    string [int] pools={"taker.spice","taker.rum","taker.anchor","taker.mast","taker.silk","taker.gold"};
    string [int] props={"takerSpaceSpice","takerSpaceRum","takerSpaceAnchor","takerSpaceMast","takerSpaceSilk","takerSpaceGold"};
    float [int] delivery={3.0,3.0,3.0,3.0,1.0,1.0};
    // Supplies persist between days. Find the product earning most per day of
    // deliveries; while it is unaffordable, its supplies are saved, not spent
    // on cheap goods (a parrot needs five days of spices, a pet rock seven of gold).
    item target; float best_rate; int [int] saved;
    foreach it, recipe in smmIRTakerRecipes() {
        if (boolean_modifier(it,"Lasts Until Rollover")) continue;
        float days=1;
        foreach i, amount in split_string(recipe,",") days=max(days,amount.to_int()/delivery[i]);
        float rate=(smmIRRewardValue(it)+(smmMuseumEnabled() ? smmMuseumProgress(it,1) : 0))/days;
        if (rate>best_rate) { best_rate=rate; target=it; }
    }
    if (target!=$item[none] && creatable_amount(target)<1) {
        foreach i, amount in split_string(smmIRTakerRecipes()[target],",") saved[i]=amount.to_int();
        smmIRNote("TakerSpace supplies are being saved toward "+target+".");
    }
    foreach it, recipe in smmIRTakerRecipes() {
        // Rollover-melting gear is not permanent inventory or Museum stock.
        if (boolean_modifier(it,"Lasts Until Rollover") || creatable_amount(it)<1) continue;
        float value=smmIRRewardValue(it);
        if (value<=0 && !(smmMuseumEnabled() && smmMuseumProgress(it,1)>0)) continue;
        // Copies that fit without dipping into supplies saved for the target.
        int copies=creatable_amount(it);
        foreach i, amount in split_string(recipe,",") if (amount.to_int()>0) {
            int have=get_property(props[i]).to_int();
            copies=min(copies,(have-min(have,saved[i]))/amount.to_int());
        }
        if (copies<1) continue;
        SmmIRWork work; work.kind="more.create"; work.product=it; work.choice_id=1537;
        string id="2024-12.taker."+it.to_int();
        string [int] names={"spice","rum","anchor","mast","silk","gold"}; string uses;
        foreach i, amount in split_string(recipe,",") if (amount.to_int()>0) uses+=(uses=="" ? "" : ", ")+amount+" "+names[i];
        work.why="Spends "+uses+" of stored TakerSpace supplies. Supplies carry over and have no other use, so the cost is the products they would otherwise make; "+smmIRValueNote(it)+(it==target ? ". This is the best product per day of deliveries." : ". Supplies needed to save up for "+target+" are not touched.");
        work.expect=it+" +1 in inventory and "+uses+" removed from the supply counters, per copy.";
        smmIRAdd(id,"TakerSpace: make "+it,work,value,0,"",0);
        if (!(smmIRActions contains id)) continue;
        foreach i, amount in split_string(recipe,",") if (amount.to_int()>0) smmIRActions[id].costs[pools[i]]=amount.to_int();
        smmIRBatch(id,copies);
    }
}

// 2024-09 Sept-Ember Censer: spend embers above the reserve on the product
// that sells best or closes a collection gap. Untradeable gear has no invented
// resale value and is only bought for a known Museum gap.
void smmIRGenerateEmbers() {
    if (available_amount($item[Sept-Ember Censer])<1 || !get_property("_septEmberBalanceChecked").to_boolean()) return;
    coinmaster shop=$coinmaster[Sept-Ember Censer];
    int spendable=get_property("availableSeptEmbers").to_int()-max(0,smmIRSetting("emberReserve",0).to_int());
    if (spendable<1) return;
    foreach it in $items[bembershoot,blade of dismemberment,embers-only jacket,hat of remembering,wheel of camembert,
        Mmm-brr! brand mouthwash,head of emberg lettuce,Septapus summoning charm,throwin' ember,structural ember,miniature Embering Hulk] {
        int price=smmIRShopPrice(shop,it);
        if (price<1 || price>spendable) continue;
        float value=smmIRRewardValue(it);
        if (value<=0 && !(smmMuseumEnabled() && smmMuseumProgress(it,1)>0)) continue;
        SmmIRWork work; work.kind="more.buy"; work.product=it; work.option=price;
        work.why="Embers are a daily currency with no sale value, so only the "+(spendable)+" above the reserve are spendable. This buys "+it+" for "+price+" embers; "+smmIRValueNote(it)+". Embers are shared across candidates, so the planner takes the best use.";
        work.expect=it+" +1 in inventory and the ember balance drops by "+price+", per copy.";
        smmIRAdd("2024-09.ember."+it.to_int(),"Spend embers on "+it,work,value,price*max(0,smmIRSetting("emberValue",0)),"embers",price);
        smmIRBatch("2024-09.ember."+it.to_int(),spendable/price);
    }
}

// 2024-06 Mini Kiwi: trade surplus mini kiwis at the Kiwi Kwiki Mart when the
// product is worth more than the kiwis. Kiwis are tradeable and a Museum item,
// so they carry their own sale or collection cost. Mixed-currency rows (the
// kiwitini) are not priced by smmIRShopPrice and are skipped.
void smmIRGenerateKiwi() {
    item kiwi=$item[mini kiwi];
    coinmaster shop=$coinmaster[Kiwi Kwiki Mart];
    int trades=max(0,smmIRSetting("kiwiBuyCap",5).to_int())-smmIRDayCount("kiwiBuys");
    if (item_amount(kiwi)<1 || !is_accessible(shop) || trades<1) return;
    foreach it in $items[mini kiwi bikini,mini kiwi icepick,mini kiwi whipping stick,mini kiwi invisible dirigible,mini kiwi silicon tiepin,
        mini kiwi intoxicating spirits,mini kiwi antimilitaristic hippy petition,mini kiwi illicit antibiotic,mini kiwi tipi] {
        if (it==$item[mini kiwi intoxicating spirits] && get_property("_miniKiwiIntoxicatingSpiritsBought").to_boolean()) continue;
        int price=smmIRShopPrice(shop,it);
        if (price<1 || !smmIRMayConsume(kiwi,price)) continue;
        float value=smmIRRewardValue(it); float input=smmIRInputValue(kiwi,price);
        if (value<=input && !(smmMuseumEnabled() && smmMuseumProgress(it,1)>0)) continue;
        SmmIRWork work; work.kind="more.kiwi"; work.product=it; work.option=price; work.counter="kiwiBuys";
        work.why="Pays "+price+" mini kiwi"+(price>1 ? "s" : "")+" (worth "+round(input)+" Meat as inputs: "+smmIRValueNote(kiwi)+") for "+it+", which is worth "+round(value)+" Meat; "+smmIRValueNote(it)+".";
        work.expect=it+" +1 in inventory and mini kiwis -"+price+", per copy.";
        string id="2024-06.kiwi."+it.to_int();
        smmIRAdd(id,"Trade "+price+" mini kiwis for "+it,work,value,input,"route.item."+kiwi.to_int(),price);
        if (!(smmIRActions contains id)) continue;
        // The daily cap is shared by every kiwi trade in the plan.
        smmIRActions[id].costs["route.kiwiBuys"]=1;
        smmIRBatch(id,it==$item[mini kiwi intoxicating spirits] ? 1 : trades);
    }
}

// 2023-11 A Guide to Burning Leaves: the free daily jump, and a bounded number
// of leaf conversions. Leaves are themselves a Museum item, so the shared
// consumption rules decide whether any may be burned at all.
void smmIRGenerateLeaves() {
    if (!(get_campground() contains $item[A Guide to Burning Leaves])) return;
    if (!get_property("_leavesJumped").to_boolean()) {
        SmmIRWork work; work.kind="more.leaves.jump"; work.counter="_leavesJumped";
        work.why="The daily leaf-pile jump costs no adventure and yields inflammable leaves, which are Museum items and crafting inputs.";
        work.expect="Some inflammable leaves are added to inventory and the daily jumped flag becomes true.";
        smmIRAdd("2023-11.leaves.jump","Jump in the burning leaf pile (free, daily)",work,0,0,"",0);
        smmIRUtility("2023-11.leaves.jump");
    }
    item leaf=$item[inflammable leaf];
    int crafts=max(0,smmIRSetting("leafCraftCap",5).to_int())-smmIRDayCount("leafCrafts");
    if (crafts<1) return;
    int reserve=max(0,smmIRSetting("leafReserve",0).to_int());
    boolean held;
    foreach it in $items[autumnic bomb,distilled resin,autumnal aegis,lit leaf lasso,forest canopy bed,autumnic balm,day shortener,coping juice] {
        int cost=get_ingredients(it)[leaf];
        if (cost<1 || item_amount(leaf)-reserve<cost || creatable_amount(it)<1) continue;
        if (!smmIRMayConsume(leaf,cost)) { held=true; continue; }
        float value=smmIRRewardValue(it); float input=smmIRInputValue(leaf,cost);
        if (value<=input && !(smmMuseumEnabled() && smmMuseumProgress(it,1)>0)) continue;
        SmmIRWork work; work.kind="more.create"; work.product=it; work.choice_id=1510; work.counter="leafCrafts";
        work.why="Burns "+cost+" inflammable leaves (worth "+round(input)+" Meat as inputs: "+smmIRValueNote(leaf)+") to make "+it+" worth "+round(value)+" Meat; "+smmIRValueNote(it)+".";
        work.expect=it+" +1 in inventory and inflammable leaves -"+cost+", per copy.";
        string id="2023-11.leaves."+it.to_int();
        smmIRAdd(id,"Burn "+cost+" leaves for "+it,work,value,input,"route.item."+leaf.to_int(),cost);
        if (!(smmIRActions contains id)) continue;
        // The daily cap is shared by every leaf conversion in the plan.
        smmIRActions[id].costs["route.leafCrafts"]=1;
        smmIRBatch(id,min(crafts,min(creatable_amount(it),(item_amount(leaf)-reserve)/cost)));
    }
    if (held) smmIRNote("Inflammable leaves are held for their own Museum rank. Set smm.IR.museumCopyValue."+leaf.to_int()+" (Meat per leaf) to allow burning them.");
}

void smmIRMoreGenerate() {
    smmIRGenerateZirconia(); smmIRGenerateDuffel(); smmIRGenerateTaker(); smmIRGenerateEmbers(); smmIRGenerateKiwi(); smmIRGenerateLeaves();
}

boolean smmIRMoreDispatch(SmmIRWork work) {
    if (work.kind=="more.cast") {
        if (!smmIREquip($item[blood cubic zirconia]) || !have_skill(work.cast)) return false;
        int before=item_amount(work.product); int casts=get_property(work.counter).to_int(); int stats=smmIRSubstats();
        boolean cast=smmIRCast(work.cast);
        int lost=stats-smmIRSubstats();
        // Stop this skill for the run when the real price exceeds the plan.
        if (lost>max(500,4*work.option)) {
            print("Zirconia cast cost "+lost+" substats, above the planned "+work.option+"; not repeating it this run.","orange");
            return false;
        }
        return cast && item_amount(work.product)>before && get_property(work.counter).to_int()>casts;
    }
    if (work.kind=="more.duffel") {
        if (available_amount(work.product)>0) return false;
        smmIRVisit("inventory.php?action=skiduffel");
        return available_amount(work.product)>0;
    }
    if (work.kind=="more.taker.collect") {
        if (get_workshed()!=$item[TakerSpace letter of Marque] || get_property(work.counter).to_boolean()) return false;
        smmIRVisit("campground.php?action=workshed");
        smmIRWalkAway(1537);
        return get_property(work.counter).to_boolean();
    }
    if (work.kind=="more.leaves.jump") {
        if (get_property(work.counter).to_boolean()) return false;
        smmIRVisit("campground.php?preaction=leaves");
        if (!handling_choice() || last_choice()!=1510) return false;
        run_choice(2);
        smmIRWalkAway(1510);
        return get_property(work.counter).to_boolean();
    }
    if (work.kind=="more.buy") {
        coinmaster shop=$coinmaster[Sept-Ember Censer];
        int copies=max(1,work.batch);
        int price=smmIRShopPrice(shop,work.product); int balance=get_property("availableSeptEmbers").to_int();
        if (price<1 || price!=work.option || balance-price*copies<max(0,smmIRSetting("emberReserve",0).to_int())) return false;
        int before=item_amount(work.product);
        buy(shop,copies,work.product);
        return item_amount(work.product)>=before+copies && get_property("availableSeptEmbers").to_int()<balance;
    }
    if (work.kind=="more.kiwi") {
        coinmaster shop=$coinmaster[Kiwi Kwiki Mart];
        int price=smmIRShopPrice(shop,work.product);
        int copies=max(1,work.batch);
        if (price<1 || price!=work.option || !smmIRMayConsume($item[mini kiwi],price*copies)) return false;
        int before=item_amount(work.product); int kiwis=item_amount($item[mini kiwi]);
        buy(shop,copies,work.product);
        // Count what actually arrived, even when it is fewer than planned.
        smmIRDayBump(work.counter,item_amount(work.product)-before);
        return item_amount(work.product)>=before+copies && item_amount($item[mini kiwi])<kiwis;
    }
    if (work.kind=="more.create") {
        int copies=max(1,work.batch);
        if (creatable_amount(work.product)<copies) return false;
        if (work.choice_id==1510) {
            int cost=get_ingredients(work.product)[$item[inflammable leaf]]*copies;
            if (cost<1 || !smmIRMayConsume($item[inflammable leaf],cost)
                || item_amount($item[inflammable leaf])-max(0,smmIRSetting("leafReserve",0).to_int())<cost) return false;
        }
        // The workshed and leaf pile leave their page open after a request.
        smmIRWalkAway(work.choice_id);
        int made=smmIRCreateBatch(copies,work.product);
        smmIRWalkAway(work.choice_id);
        // Count what was actually made, even when it is fewer than planned.
        if (work.counter!="") smmIRDayBump(work.counter,made);
        return made>=copies;
    }
    return false;
}
