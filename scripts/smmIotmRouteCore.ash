import <smmUtils.ash>
import <smmMuseumPolicy.ash>

// Executable, incremental aftercore route. Prices are estimates, not booked sales.
string __smm_iotm_route_version = "1.1";

record SmmIRWork {
    string kind;
    item product;
    item ingredient1;
    item ingredient2;
    item ingredient3;
    skill cast;
    familiar companion;
    item companion_equipment;
    location zone;
    monster foe;
    string parameters;
    string counter;
    int choice_id;
    int option;
    int allowed_turns;
    int expected_adventures;
};

record SmmIRGear {
    familiar companion;
    item [slot] gear;
    item [familiar] familiar_gear;
};

record SmmIRGardenPoint {
    int id;
    int x;
    int y;
    string kind;
    string label;
    boolean done;
    boolean reachable;
};

record SmmIRResult {
    boolean attempted;
    boolean success;
    int turns;
    int adventures_gained;
    int meat_delta;
    string reason;
    string displayed;
};

SmmRPAction [string] smmIRActions;
SmmIRWork [string] smmIRWorkers;
float [item] smmIRPrices;
float [item] smmIRReplacementPrices;
boolean [string] smmIRBlocked;
boolean [location] smmIRZones;
string [int] smmIRNotes;
SmmIRGardenPoint [int] smmIRGarden;
string smmIRInventory;
boolean smmIRDiscovered;
boolean smmIRNoPaidTurns;
string smmIROwner = "iotm.route";
int smmIRQuotes;
float smmIRSelectedLoss;
string smmIRChosenGarden;

float smmIRSetting(string name, float fallback) {
    string value=get_property("smm.IR."+name);
    return value == "" ? fallback : value.to_float();
}

boolean smmIREnabled() { return get_property("smm.IR.enabled") != "false"; }

float smmIRTurnValue() { return max(0,kTurnValue.to_float()); }

int smmIRPaidRemaining() {
    int used=get_property("smm.IR.epoch")==smmRPEpoch() ? get_property("smm.IR.paidTurns").to_int() : 0;
    return smmIRNoPaidTurns ? 0 : max(0,min(200,smmIRSetting("maxPaidTurns",20).to_int())-used);
}

void smmIRAccountTurns(int turns) {
    if (get_property("smm.IR.epoch") != smmRPEpoch()) {
        set_property("smm.IR.epoch",smmRPEpoch()); set_property("smm.IR.paidTurns",0);
    }
    set_property("smm.IR.paidTurns",get_property("smm.IR.paidTurns").to_int()+max(0,turns));
}

// Wrappers are the boundary replaced by the isolated regression harness.
string smmIRVisit(string url) { return visit_url(url); }
boolean smmIRCast(skill sk) { return use_skill(1,sk); }
int smmIRQuote(item it) { return mall_price(it); }
int smmIRTurns() { return my_turncount(); }
boolean smmIRAdventure(location zone) {
    if ((zone.environment=="underwater" || get_property("_seadentWaveZone")==zone.to_string()) && have_effect($effect[Fishy])<1) return false;
    return adv1(zone,-1,"");
}
void smmIRSetAutoAttack(int attack) { set_auto_attack(attack); }

float smmIRSaleValue(item it) {
    if (smmIRPrices contains it) return smmIRPrices[it];
    float value=max(0,autosell_price(it));
    int quote;
    if (it.tradeable) {
        if (smmIRQuotes<max(0,smmIRSetting("maxQuotes",150).to_int())) { quote=smmIRQuote(it); smmIRQuotes+=1; }
        // A minimum-price listing is not evidence that an unlimited amount sells.
        if (quote > max(100,2*autosell_price(it)))
            value=max(value,quote*min(1.0,max(0.0,smmIRSetting("saleDiscount",0.8))));
    }
    smmIRReplacementPrices[it]=max(0,smmIRSetting("museumCopyValue."+it.to_int(),quote));
    smmIRPrices[it]=value;
    return value;
}

float smmIRRewardValue(item it, int quantity) {
    float sale=smmIRSaleValue(it);
    return smmMuseumMoney(it,quantity,sale,smmIRReplacementPrices[it]);
}

float smmIRRewardValue(item it) { return smmIRRewardValue(it,1); }

float smmIRInputValue(item it, int quantity) {
    if (it==$item[none] || quantity<1) return 0;
    float sale=smmIRSaleValue(it);
    return smmMuseumInput(it,quantity,sale,smmIRReplacementPrices[it]);
}

float smmIRInputValue(item it) { return smmIRInputValue(it,1); }

boolean smmIRMayConsume(item it, int amount) {
    if (it==$item[none]) return false;
    int keep=max(0,smmIRSetting("keepItem."+it.to_int(),0).to_int());
    if (smmMuseumEnabled()) keep=max(keep,max(smmMuseumConsumptionReserve(it),smmMuseumKeep(it)));
    if (item_amount(it)-keep<amount) return false;
    if (smmMuseumNeedsCopy(it)) {
        smmIRSaleValue(it);
        if (smmIRReplacementPrices[it]<=0) return false;
    }
    return true;
}

SmmIRGear smmIRSaveGear() {
    SmmIRGear state;
    state.companion=my_familiar();
    foreach sl in $slots[hat,weapon,off-hand,shirt,pants,back,acc1,acc2,acc3,familiar]
        state.gear[sl]=equipped_item(sl);
    foreach fam in $familiars[] if (have_familiar(fam)) state.familiar_gear[fam]=familiar_equipped_equipment(fam);
    return state;
}

boolean smmIRRestoreGear(SmmIRGear state) {
    boolean ok=true;
    if (my_familiar()!=state.companion) ok=use_familiar(state.companion) && ok;
    if (equipped_item($slot[weapon])!=state.gear[$slot[weapon]] || equipped_item($slot[off-hand])!=state.gear[$slot[off-hand]]) {
        ok=equip($slot[off-hand],$item[none]) && ok;
        ok=equip($slot[weapon],state.gear[$slot[weapon]]) && ok;
        ok=equip($slot[off-hand],state.gear[$slot[off-hand]]) && ok;
    }
    foreach sl in $slots[hat,shirt,pants,back,acc1,acc2,acc3,familiar]
        if (equipped_item(sl)!=state.gear[sl]) ok=equip(sl,state.gear[sl]) && ok;
    // Verify all companions because Mafia may migrate familiar equipment;
    // inactive companions in case a user hook moved something.
    foreach fam, it in state.familiar_gear if (fam!=state.companion && familiar_equipped_equipment(fam)!=it)
        ok=equip(fam,it) && ok;
    return ok;
}

void smmIRStoreGear(SmmIRGear state) {
    string packed="active="+state.companion.to_int()+"|";
    foreach sl, it in state.gear packed+="slot."+sl+"="+it.to_int()+"|";
    foreach fam, it in state.familiar_gear packed+="fam."+fam.to_int()+"="+it.to_int()+"|";
    set_property("smm.IR.pendingGear",packed);
}

boolean smmIRRestorePendingGear() {
    string packed=get_property("smm.IR.pendingGear");
    if (packed=="") return true;
    if (handling_choice() || current_round()>0) return false;
    SmmIRGear state; boolean active;
    foreach i, entry in split_string(packed,"\\|") {
        string [int] fields=split_string(entry,"=");
        if (count(fields)!=2) continue;
        if (fields[0]=="active") { state.companion=to_familiar(fields[1].to_int()); active=true; }
        if (fields[0].starts_with("slot.")) state.gear[to_slot(substring(fields[0],5))]=to_item(fields[1].to_int());
        if (fields[0].starts_with("fam.")) state.familiar_gear[to_familiar(substring(fields[0],4).to_int())]=to_item(fields[1].to_int());
    }
    if (!active || count(state.gear)!=10) abort("Incomplete saved IoTM outfit; inspect smm.IR.pendingGear before restoring manually.");
    string [string] acquisition;
    foreach i, prop in split_string("autoSatisfyWithMall|autoSatisfyWithNPCs|autoSatisfyWithCoinmasters|autoSatisfyWithStash|autoSatisfyWithShop","\\|") {
        acquisition[prop]=get_property(prop); set_property(prop,false);
    }
    boolean restored;
    try { restored=smmIRRestoreGear(state); }
    finally { foreach prop, value in acquisition set_property(prop,value); }
    if (restored) set_property("smm.IR.pendingGear","");
    return restored;
}

boolean smmIREquip(item it) {
    if (equipped_amount(it)>0) return true;
    if (available_amount(it)<1 || !can_equip(it)) return false;
    return retrieve_item(1,it) && equip(it);
}

string smmIRHidden(string html, string name) {
    matcher inputs=create_matcher("(?is)<input\\b[^>]*>",html);
    while (inputs.find()) {
        string tag=inputs.group(0);
        matcher n=create_matcher("(?i)\\bname\\s*=\\s*(?:\"([^\"]*)\"|'([^']*)'|([^\\s>]+))",tag);
        if (!n.find()) continue;
        string key=n.group(1)+n.group(2)+n.group(3);
        if (key!=name) continue;
        matcher v=create_matcher("(?i)\\bvalue\\s*=\\s*(?:\"([^\"]*)\"|'([^']*)'|([^\\s>]+))",tag);
        return v.find() ? entity_decode(v.group(1)+v.group(2)+v.group(3)) : "";
    }
    return "";
}

string smmIRUseLink(string inventory, item it) {
    matcher row=create_matcher("(?is)\\bid\\s*=\\s*[\"']?ic"+it.to_int()+"\\b(.*?)(?=\\bid\\s*=\\s*[\"']?ic[0-9]+\\b|$)",inventory);
    if (!row.find()) return "";
    matcher link=create_matcher("(?is)<a\\b[^>]*href\\s*=\\s*(?:\"([^\"]*)\"|'([^']*)'|([^\\s>]+))[^>]*>\\s*(?:use|play ball|dig|shower|drink)\\s*</a>",row.group(1));
    while (link.find()) {
        string url=entity_decode(link.group(1)+link.group(2)+link.group(3));
        if (create_matcher("^(?:/?inventory|/?inv_use|/?main|/?choice)\\.php\\?",url).find()) return url;
    }
    return "";
}

SmmIRGardenPoint [int] smmIRParseGarden(string html) {
    SmmIRGardenPoint [int] points;
    matcher rows=create_matcher("(?s)\\{\"i\":([0-9]+),\"x\":([0-9]+),\"y\":([0-9]+),\"k\":\"([^\"]+)\",\"d\":([01]),\"label\":\"([^\"]*)\"",html);
    while (rows.find()) {
        SmmIRGardenPoint p;
        p.id=rows.group(1).to_int(); p.x=rows.group(2).to_int(); p.y=rows.group(3).to_int();
        p.kind=rows.group(4); p.done=rows.group(5)=="1"; p.label=rows.group(6);
        p.reachable=true; points[p.id]=p;
    }
    matcher forms=create_matcher("(?is)<form\\b[^>]*>.*?</form>",html);
    while (forms.find()) {
        string form=forms.group(0); string id=smmIRHidden(form,"rgpoi");
        if (id!="" && (points contains id.to_int())) points[id.to_int()].reachable=!create_matcher("(?i)\\bdisabled\\b",form).find();
    }
    return points;
}

void smmIRLeaveChoice(int id, int option) {
    if (handling_choice() && last_choice()==id) run_choice(option);
}

boolean smmIROpenItem(item it, int choice) {
    if (handling_choice()) return last_choice()==choice;
    if (available_amount(it)<1 || !retrieve_item(1,it)) return false;
    string link=smmIRUseLink(smmIRInventory,it);
    if (link=="") {
        smmIRInventory=smmIRVisit("inventory.php?which=2");
        link=smmIRUseLink(smmIRInventory,it);
    }
    // Spade is an actual reusable item; other special links must come from the server.
    if (link=="" && it==$item[Archaeologist's Spade]) link="inv_use.php?whichitem="+it.to_int();
    if (link=="") return false;
    smmIRVisit(link);
    return handling_choice() && last_choice()==choice;
}

string smmIRAcornEffects(location zone) {
    foreach i, part in split_string(get_property("legendaryAcornsPlanted"),"\\|") {
        int colon=index_of(part,":");
        if (colon>=0 && substring(part,0,colon)==zone.to_string()) return substring(part,colon+1);
    }
    return "";
}

int smmIRAcornsToday(location zone) {
    foreach i, part in split_string(get_property("_legendaryAcornZonesToday"),"\\|") {
        int colon=index_of(part,":");
        if (colon>=0 && substring(part,0,colon)==zone.to_string()) return substring(part,colon+1).to_int();
    }
    return 0;
}

void smmIRNote(string message) {
    foreach i, text in smmIRNotes if (text==message) return;
    smmIRNotes[count(smmIRNotes)]=message;
}

void smmIRDiscover() {
    if (smmIRDiscovered) return;
    smmIRDiscovered=true;
    if (handling_choice() || current_round()>0) abort("Finish the current encounter before planning an IoTM route.");
    smmIRInventory=smmIRVisit("inventory.php?which=2");
    if (smmMuseumEnabled() && have_display()) smmIRVisit("managecollectionshelves.php");
    smmIRVisit("campground.php");
    if (item_amount($item[Interesting Coin])>smmIRSetting("coinReserve",10000000)) smmIRVisit("shop.php?whichshop=interesting");
    if (available_amount($item[combat lover's locket])>0) { smmIRVisit("inventory.php?reminisce=1"); smmIRLeaveChoice(1463,2); }
    location [int] choices={$location[The Oasis],$location[The Skeleton Store],$location[The Haunted Library],
        $location[The Haunted Ballroom],$location[The Haunted Wine Cellar],$location[The Haunted Laboratory]};
    string configured=get_property("smm.IR.locations");
    if (configured!="") {
        clear(choices);
        foreach i, name in split_string(configured,"\\|") choices[count(choices)]=to_location(name);
    }
    foreach i, zone in choices if (zone!=$location[none] && can_adventure(zone)) smmIRZones[zone]=true;
    if (my_location()!=$location[none] && can_adventure(my_location())) smmIRZones[my_location()]=true;
    if (available_amount($item[legendary acorndion])>0)
        smmIRVisit("desc_item.php?whichitem="+$item[legendary acorndion].descid);
    // Discover the existing garden only; never plant or replace a crop here.
    int [item] camp=get_campground();
    if ((camp contains $item[black garden rose]) && my_inebriety()<=inebriety_limit()) {
        string page=smmIRVisit("campground.php?action=rosegarden");
        if (handling_choice() && last_choice()==1637) {
            smmIRGarden=smmIRParseGarden(page);
            smmIRLeaveChoice(1637,2);
        }
    }
    if (have_familiar($familiar[Skeleton of Crimbo Past])) {
        // Visiting through the coinmaster refreshes the rotating special in Mafia.
        smmIRVisit("main.php?talktosocp=1");
        if (handling_choice() && last_choice()==1567) {
            foreach option, text in available_choice_options()
                if (text.to_lower_case().contains_text("leave")) { run_choice(option); break; }
        }
    }
}

boolean smmIRSkeleton(monster foe) { return foe.attributes.contains_text("SKELETON"); }

boolean smmIRSimpleLoot(monster foe) {
    foreach i, drop in item_drops_array(foe)
        if (drop.type=="c" || drop.type=="0" || drop.rate<=0) return false;
    return true;
}

float smmIRLoot(monster foe, float bonus, boolean forced) {
    float value;
    foreach i, drop in item_drops_array(foe) {
        if (drop.type=="p" || drop.type=="b" || drop.type=="a" || drop.type=="c" || drop.type=="0") continue;
        if (drop.type!="" && drop.type!="n" && drop.type!="f") continue;
        float chance=forced ? 1.0 : min(1.0,max(0.0,drop.rate*(drop.type=="f" ? 1 : 1+bonus/100.0)/100.0));
        value += chance*smmIRRewardValue(drop.drop);
    }
    return value;
}

float smmIRCashLoot(monster foe, float bonus) {
    float result;
    foreach i, drop in item_drops_array(foe) {
        if (drop.rate<=0 || (drop.type!="" && drop.type!="n" && drop.type!="f")) continue;
        float chance=min(1.0,drop.rate*(drop.type=="f" ? 1 : 1+bonus/100.0)/100.0);
        result+=chance*smmIRSaleValue(drop.drop);
    }
    return result;
}

float smmIRBoneValue() {
    coinmaster shop=$coinmaster[Skeleton of Crimbo Past];
    item [int] goods={$item[Smoking Pope],$item[prize turkey],$item[medicinal gruel],to_item(get_property("_crimboPastDailySpecialItem"))};
    string [int] flags={"_crimboPastSmokingPope","_crimboPastPrizeTurkey","_crimboPastMedicalGruel","_crimboPastDailySpecial"};
    int demand; float floor=1000000000.0;
    foreach i, it in goods if (it!=$item[none] && !get_property(flags[i]).to_boolean()) {
        int cost=buy_price(shop,it);
        if (cost>0) { demand+=cost; floor=min(floor,smmIRRewardValue(it)/cost); }
    }
    return demand>item_amount($item[knucklebone]) ? floor : 0;
}

float smmIRFamiliarBonus(monster foe, familiar fam, item eq) {
    int weight=familiar_weight(fam)+weight_adjustment();
    float items=numeric_modifier(fam,"Item Drop",weight,eq);
    float meat=numeric_modifier(fam,"Meat Drop",weight,eq);
    float result=smmIRLoot(foe,item_drop_modifier()-numeric_modifier(my_familiar(),"Item Drop",familiar_weight(my_familiar())+weight_adjustment(),equipped_item($slot[familiar]))+items,false)
        + meat_drop(foe)*(1+(meat_drop_modifier()-numeric_modifier(my_familiar(),"Meat Drop",familiar_weight(my_familiar())+weight_adjustment(),equipped_item($slot[familiar]))+meat)/100.0);
    monster target=to_monster(get_property("swordOfSWordsMonster"));
    if (fam==$familiar[Sword of S Words] && target!=$monster[none] && target.copyable && foe.copyable && !foe.boss
        && get_property("_swordOfSWordsKills").to_int()<100) {
        if (!smmIRSimpleLoot(foe) || !smmIRSimpleLoot(target)) return 0;
        float item_bonus=item_drop_modifier()-numeric_modifier(my_familiar(),"Item Drop",familiar_weight(my_familiar())+weight_adjustment(),equipped_item($slot[familiar]))+items;
        result-=smmIRLoot(foe,item_bonus,false); result+=smmIRLoot(target,item_bonus,false);
    }
    if (fam==$familiar[Robortender]) {
        // Price only the actual raw drop. Potential cocktail sales would also
        // require ingredients and crafting, which this familiar comparison lacks.
        item [phylum] drops=kRobortenderDrops();
        result+=roboDropChance()*smmIRRewardValue(drops[foe.phylum]);
    }
    if (fam==$familiar[Mini Kiwi]) result += min(1.0,weight*(eq==$item[aviator goggles] ? 0.0075 : 0.005))*smmIRRewardValue($item[mini kiwi]);
    if (fam==$familiar[Skeleton of Crimbo Past] && get_property("_knuckleboneDrops").to_int()<100 && smmIRSkeleton(foe))
        result += (eq==$item[small peppermint-flavored sugar walking crook] ? 1.0 : 0.9)*smmIRBoneValue();
    return result;
}

SmmIRWork smmIRCombatLoadout(monster foe) {
    SmmIRWork work;
    work.companion=my_familiar(); work.companion_equipment=equipped_item($slot[familiar]);
    float best=smmIRFamiliarBonus(foe,work.companion,work.companion_equipment);
    familiar [int] families={$familiar[Robortender],$familiar[Mini Kiwi],$familiar[Skeleton of Crimbo Past],$familiar[Meat Shield Maiden]};
    foreach i, fam in families if (have_familiar(fam)) {
        item eq=familiar_equipped_equipment(fam);
        float value=smmIRFamiliarBonus(foe,fam,eq);
        if (value>best) { best=value; work.companion=fam; work.companion_equipment=eq; }
    }
    if (have_familiar($familiar[Sword of S Words]) && get_property("_swordOfSWordsKills").to_int()<100
        && smmRPSpendable("sword.loot",smmIROwner,smmRPLiveResources(),smmRPReservations())>0) {
        familiar fam=$familiar[Sword of S Words]; item eq=familiar_equipped_equipment(fam);
        float value=smmIRFamiliarBonus(foe,fam,eq);
        if (value>best) { work.companion=fam; work.companion_equipment=eq; }
    }
    return work;
}

float smmIRCombatValue(monster foe, SmmIRWork gear) {
    return smmIRFamiliarBonus(foe,gear.companion,gear.companion_equipment);
}

SmmIRWork smmIRCopyWork(SmmIRWork source) {
    return new SmmIRWork(source.kind,source.product,source.ingredient1,source.ingredient2,source.ingredient3,
        source.cast,source.companion,source.companion_equipment,source.zone,source.foe,source.parameters,
        source.counter,source.choice_id,source.option,source.allowed_turns,source.expected_adventures);
}

float smmIRMonsterProgress(monster foe) {
    float bonus;
    foreach i, drop in item_drops_array(foe) {
        if (drop.rate<=0 || (drop.type!="" && drop.type!="n" && drop.type!="f")) continue;
        float chance=min(1.0,drop.rate*(drop.type=="f" ? 1 : 1+item_drop_modifier()/100.0)/100.0);
        bonus+=chance*smmMuseumProgress(drop.drop,1);
    }
    return bonus;
}

float smmIRWorkProgress(SmmIRWork work) {
    if (!smmMuseumEnabled()) return 0;
    if (work.kind=="garden.harvest") return smmMuseumProgress(work.product,work.choice_id);
    if (work.kind=="garden.mushroom") return smmIRMonsterProgress($monster[piranha plant])+smmMuseumProgress(work.product,work.choice_id);
    if (work.kind=="coin.buy" || work.kind=="bones.buy" || work.kind=="craft" || work.kind=="pasta.summon"
        || work.kind=="extra.coin.sale" || work.kind=="extra.coin.unique" || work.kind=="extra.coin.collection"
        || (work.kind=="garden" && work.foe==$monster[none])) return smmMuseumProgress(work.product,1);
    if (work.kind=="locket" || work.kind=="sword.seed" || (work.kind=="garden" && work.foe!=$monster[none])) {
        monster loot=work.foe;
        if (work.kind!="sword.seed" && work.companion==$familiar[Sword of S Words] && work.foe.copyable && !work.foe.boss && get_property("_swordOfSWordsKills").to_int()<100) {
            monster target=to_monster(get_property("swordOfSWordsMonster")); if (target!=$monster[none]) loot=target;
        }
        return smmIRMonsterProgress(loot);
    }
    return 0;
}

void smmIRAdd(string id, string description, SmmIRWork work, float benefits, float costs, string resource, int units) {
    if (smmIRBlocked[id]) return;
    SmmRPAction action=smmRPNewAction(description,1,benefits);
    action.input_cost=costs;
    if (resource!="") action.costs[resource]=units;
    if (work.allowed_turns>0) action.costs["route.paid"]=work.allowed_turns;
    if (work.kind=="locket" || work.kind=="sword.seed") {
        action.choice_group="locket."+work.foe.to_int(); action.choice=work.kind;
    }
    if ((work.kind=="farm" || work.kind=="acorn.block") && my_familiar()==$familiar[Sword of S Words]) action.costs["sword.loot"]=work.allowed_turns;
    if (work.kind=="cup") {
        action.costs["route.item."+work.ingredient1.to_int()]+=1;
        action.costs["route.item."+work.ingredient2.to_int()]+=1;
        action.costs["route.item."+work.ingredient3.to_int()]+=1;
        action.costs["route.liver"]=1;
    }
    if (work.kind=="craft") {
        foreach it, quantity in get_ingredients(work.product) action.costs["route.item."+it.to_int()]=quantity;
        action.costs["route.cooks"]=1;
    }
    if (work.kind=="garden" || work.kind=="extra.garden" || (work.kind=="extra.maiden" && work.choice_id==1637)) action.costs["route.garden."+work.option]=1;
    if (work.kind=="museum.deposit") action.costs["route.item."+work.product.to_int()]=1;
    if (work.kind=="locket" || work.kind=="sword.seed") action.costs["route.foe."+work.foe.to_int()]=1;
    if (work.kind=="acorn.block" || work.kind=="extra.acorn") action.costs["route.acornZone."+work.zone.to_int()]=1;
    if (resource=="route.coins" || resource=="route.coinWallet") action.costs["route.coinWallet"]=units;
    float museum_progress=smmIRWorkProgress(work);
    if (museum_progress>0) { action.goal="museum."+id; action.missing=1; action.collection_value=museum_progress; }
    smmIRActions[id]=action; smmIRWorkers[id]=smmIRCopyWork(work);
}

void smmIRUtility(string id) {
    if (!(smmIRActions contains id) || smmIRActions[id].goal!="") return;
    // A one-point preference for a free, non-Meat bonus. No negative-EV utility
    // action can pass the default zero collection-loss budget.
    smmIRActions[id].goal="free.utility"; smmIRActions[id].missing=1; smmIRActions[id].collection_value=1;
}

float smmIRLocalDigFloor(location zone) {
    float lowest=1000000000.0; boolean found;
    foreach foe, ignored in get_location_monsters(zone) foreach i, drop in item_drops_array(foe) {
        if (drop.type!="") continue;
        found=true; lowest=min(lowest,smmIRRewardValue(drop.drop));
    }
    return found ? lowest : 0;
}

void smmIRGenerateGarden() {
    if (my_inebriety()>inebriety_limit() || (smmIRChosenGarden!="" && smmIRChosenGarden!=my_garden_type())) return;
    foreach id, point in smmIRGarden {
        if (point.done || !point.reachable) continue;
        SmmIRWork work;
        work.kind="garden"; work.option=point.id;
        work.parameters="rgpoi="+point.id+"&rgx="+point.x+"&rgy="+point.y+"&rgf=0";
        float value;
        if (point.kind=="monster") {
            work.foe=to_monster(replace_string(point.label,"Fight ",""));
            if (my_adventures()<1 || work.foe==$monster[none] || my_hp()<max(1,my_maxhp()/3) || my_mp()<30) continue;
            SmmIRWork gear=smmIRCombatLoadout(work.foe);
            work.companion=gear.companion; work.companion_equipment=gear.companion_equipment;
            value=smmIRCombatValue(work.foe,work);
        } else if (point.kind=="food") { work.product=$item[black rose bowl]; value=smmIRRewardValue(work.product); }
        else if (point.kind=="booze") { work.product=to_item("black garden rosé"); value=smmIRRewardValue(work.product); }
        else if ((point.kind=="incense" || point.kind=="spleen")) { work.product=$item[clove incense]; value=smmIRRewardValue(work.product); }
        else { smmIRNote("Garden chests, fountain and puzzle are evaluated by the shared garden/collection adapters."); continue; }
        string key="2026-10.garden."+point.id;
        smmIRAdd(key,point.label,work,value,0,"",0);
        if (value==0) smmIRUtility(key);
        if (work.companion==$familiar[Sword of S Words] && (smmIRActions contains key)) smmIRActions[key].costs["sword.loot"]=1;
    }
}

void smmIRGenerateCoins() {
    int coins=item_amount($item[Interesting Coin]);
    int reserve=smmIRSetting("coinReserve",10000000).to_int();
    int surplus=max(0,coins-max(1,reserve));
    if (surplus<=0) { if (coins>0) smmIRNote("Interesting Coins are accumulating toward the configured reserve (default 10,000,000); no daily liquidation of capital."); return; }
    coinmaster shop=$coinmaster[Spend your Interesting Coins];
    item [int] products={$item[liquid asset],$item[intangible asset],$item[toxic asset],$item[invisible hand],
        $item[circle of overdraft protection scroll],$item[mint],$item[solvent],$item[Roth IPA],$item[savings bondo],$item[soybean futures]};
    foreach i, it in products {
        int cost=buy_price(shop,it);
        if (cost<=0 || cost>surplus || get_property("_itemBoughtPerDay"+it.to_int()).to_int()>=3) continue;
        SmmIRWork work; work.kind="coin.buy"; work.product=it;
        float shadow=max(0,smmIRSetting("coinValue",0));
        smmIRAdd("2026-08.coin."+it.to_int(),"Convert surplus coins to "+it,work,smmIRRewardValue(it),cost*shadow,"route.coins",cost);
    }
}

void smmIRGenerateCup() {
    if (available_amount($item[Cup of 13s])<1 || !can_drink() || my_inebriety()>=inebriety_limit()) return;
    int jewels=get_property("_cupOf13sJewels").to_int();
    if (jewels<1 || smmIRUseLink(smmIRInventory,$item[Cup of 13s])=="") return;
    item [int] best; float [int] cost;
    // Only tradeable, physically owned inputs. Never destroy an untradeable unlock.
    foreach it, amount in get_inventory() if (it.tradeable && smmIRMayConsume(it,1)) {
        int tier=cup_of_13s_tier(it);
        if (tier<1 || tier>5) continue;
        float price=smmIRInputValue(it);
        if (!(best contains tier) || price<cost[tier]) { best[tier]=it; cost[tier]=price; }
    }
    float best_net; SmmIRWork selected; int best_adventures;
    foreach a, it1 in best foreach b, it2 in best foreach c, it3 in best {
        int [item] quantities; quantities[it1]+=1; quantities[it2]+=1; quantities[it3]+=1;
        boolean available=true;
        foreach it, amount in quantities if (!smmIRMayConsume(it,amount)) available=false;
        if (!available) continue;
        int adventures=min(jewels,a+b+c);
        float input_cost;
        foreach it, amount in quantities input_cost+=smmIRInputValue(it,amount);
        float net=adventures*smmIRTurnValue()-input_cost-max(0,smmIRSetting("liverValue",6.17*smmIRTurnValue()-2850));
        if (net>best_net) {
            best_net=net; selected.kind="cup"; selected.ingredient1=it1; selected.ingredient2=it2; selected.ingredient3=it3;
            selected.expected_adventures=adventures; best_adventures=adventures;
        }
    }
    if (best_net>0) smmIRAdd("2026-07.cup","Cup drink after ingredients and liver opportunity cost",selected,best_net,0,"cup.jewels",best_adventures);
}

void smmIRGeneratePasta() {
    if (available_amount($item[legendary pasta wand])<1) return;
    skill sk=have_skill($skill[Pastamastery]) ? $skill[Pastamastery] : $skill[Wave your Pasta Wand];
    if ((sk==$skill[Pastamastery] && get_property("noodleSummons").to_int()<3)
        || (sk==$skill[Wave your Pasta Wand] && !get_property("_legendaryPastaWaveCast").to_boolean())) {
        if (my_mp()>=mp_cost(sk)) {
            SmmIRWork work; work.kind="pasta.summon"; work.cast=sk; work.product=$item[legendary noodles];
            smmIRAdd("2026-05.noodles","Summon legendary noodles",work,smmIRRewardValue(work.product),mp_cost(sk)*max(0,smmIRSetting("mpValue",1)),"",0);
        }
    }
    if (item_amount($item[legendary noodles])<1 || free_cooks()<1) return;
    foreach it in $items[] {
        if (it.fullness!=1 || !it.tradeable) continue;
        int [item] ingredients=get_ingredients(it);
        if (!(ingredients contains $item[legendary noodles])) continue;
        boolean owned=true; float input;
        foreach ingredient, amount in ingredients {
            if (!smmIRMayConsume(ingredient,amount)) { owned=false; break; }
            input += smmIRInputValue(ingredient,amount);
        }
        if (!owned) continue;
        SmmIRWork work; work.kind="craft"; work.product=it;
        smmIRAdd("2026-05.craft."+it.to_int(),"Cook profitable legendary pasta: "+it,work,smmIRRewardValue(it),input,"pasta.crafts",1);
    }
}

void smmIRGenerateSpade() {
    if (available_amount($item[Archaeologist's Spade])<1 || get_property("_archSpadeDigs").to_int()>=11) return;
    location zone=to_location(get_property("lastAdventure"));
    if (zone==$location[none]) return;
    SmmIRWork work; work.kind="spade"; work.zone=zone; work.option=1; work.counter="_archSpadeDigs";
    float value=smmIRLocalDigFloor(zone);
    float ancient=min(smmIRRewardValue($item[dinosaur bone fragment]),min(smmIRRewardValue($item[ancient Pork Elf pottery shard]),smmIRRewardValue($item[2015 landfill detritus])));
    if (ancient>value) { value=ancient; work.option=2; }
    if (value>0) smmIRAdd("2026-03.dig","Spade dig with conservative known output value",work,value,0,"spade.digs",1);
    if (my_adventures()<1 || my_inebriety()>inebriety_limit() || my_mp()<30 || my_hp()<my_maxhp()/3) return;
    monster best; float best_value;
    foreach foe, ignored in get_location_monsters(zone) if (smmIRSkeleton(foe) && !foe.boss) {
        SmmIRWork gear=smmIRCombatLoadout(foe);
        float amount=smmIRCombatValue(foe,gear);
        if (amount>best_value) { best=foe; best_value=amount; }
    }
    // The actual skeleton is random. Use the minimum native payout, not the best.
    if (best!=$monster[none]) {
        float floor=best_value;
        SmmIRWork gear=smmIRCombatLoadout(best);
        foreach foe, ignored in get_location_monsters(zone) if (smmIRSkeleton(foe) && !foe.boss)
            floor=min(floor,smmIRCombatValue(foe,gear));
        work.option=3; work.foe=best; work.companion=gear.companion; work.companion_equipment=gear.companion_equipment;
        smmIRAdd("2026-03.skeleton","Spade free skeleton (competes with an item dig)",work,floor,0,"spade.digs",1);
        // Unknown skeleton mixes cannot safely preselect a replacement-loot target.
        if (work.companion==$familiar[Sword of S Words] && (smmIRActions contains "2026-03.skeleton")) smmIRActions["2026-03.skeleton"].costs["sword.loot"]=1;
    }
}

float smmIRZoneIncome(location zone) {
    if ((zone.environment=="underwater" || get_property("_seadentWaveZone")==zone.to_string()) && have_effect($effect[Fishy])<1) return 0;
    float value;
    SmmIRWork gear; gear.companion=my_familiar(); gear.companion_equipment=equipped_item($slot[familiar]);
    foreach foe, rate in appearance_rates(zone) if (foe!=$monster[none] && rate>0) {
        if (gear.companion==$familiar[Sword of S Words] && (!foe.copyable || !smmIRSimpleLoot(foe)
            || get_property("_swordOfSWordsKills").to_int()>=100 || to_monster(get_property("swordOfSWordsMonster"))==$monster[none])) return 0;
        value += rate/100.0*smmIRCombatValue(foe,gear);
    }
    return value*min(1.0,max(0.0,zone.combat_percent/100.0));
}


void smmIRGenerateHeart() {
    if (available_amount($item[Heartstone])<1 || my_adventures()<1) return;
    if (get_property("heartstonePalsUnlocked").to_boolean() && have_effect($effect[Best Pals])<min(25,my_adventures()) && my_mp()>=mp_cost(to_skill(7590))) {
        float gain;
        familiar fam=my_familiar(); item eq=equipped_item($slot[familiar]);
        int weight=familiar_weight(fam)+weight_adjustment();
        float delta=numeric_modifier(fam,"Meat Drop",weight+5,eq)-numeric_modifier(fam,"Meat Drop",weight,eq);
        float base=1000000000.0; boolean scheduled;
        foreach zone, ignored in smmIRZones if (smmIRZoneIncome(zone)>smmIRTurnValue()+max(0,smmIRSetting("combatCost",50))) {
            foreach foe, rate in appearance_rates(zone) if (rate>0 && foe!=$monster[none]) base=min(base,meat_drop(foe));
            scheduled=true;
        }
        gain=scheduled ? max(0,base*delta/100.0)*min(25,smmIRPaidRemaining()) : 0;
        SmmIRWork work; work.kind="buff"; work.cast=to_skill(7590); work.product=$item[Heartstone]; work.counter="_heartstonePalsUsed";
        smmIRAdd("2026-02.pals","Heartstone familiar-weight buff",work,gain,mp_cost(work.cast)*max(0,smmIRSetting("mpValue",1)),"heart.pals",1);
    }
    if (!get_property("heartstoneLuckUnlocked").to_boolean() || get_property("_heartstoneLuckUsed").to_boolean() || smmIRPaidRemaining()<1 || have_effect($effect[Lucky!])>0) return;
    location [int] zones={$location[The Hidden Temple],$location[The Black Forest],$location[The Unquiet Garves],$location[The Batrat and Ratbat Burrow]};
    item [int] prizes={$item[stone wool],$item[black picnic basket],$item[poltergeist-in-the-jar-o],$item[Dogsgotnonoz pills]};
    foreach i, place in zones if (can_adventure(place)) {
        float value=smmIRRewardValue(prizes[i],i==0 ? 3 : 1);
        SmmIRWork work; work.kind="heart.lucky"; work.cast=to_skill(7589); work.zone=place; work.product=$item[Heartstone]; work.allowed_turns=1;
        smmIRAdd("2026-02.lucky."+place.to_int(),"Heartstone Lucky at "+place,work,value,smmIRTurnValue()+mp_cost(work.cast)*max(0,smmIRSetting("mpValue",1)),"heart.luck",1);
    }
}


void smmIRGenerateAcorn() {
    if (!can_equip($item[legendary acorndion]) || available_amount($item[legendary acorndion])<1 || get_property("_legendaryAcornsUsed").to_int()>=12
        || smmIRPaidRemaining()<3 || my_adventures()<3 || my_inebriety()>inebriety_limit()) return;
    foreach zone, ignored in smmIRZones {
        string effects=smmIRAcornEffects(zone);
        // Never evict an older planting. Its unpriced future value belongs to the user.
        if ((effects!="" && count(split_string(effects,","))>=3) || smmIRAcornsToday(zone)>=3) continue;
        SmmIRWork work; work.kind="acorn.block"; work.zone=zone;
        work.allowed_turns=min(10,min(my_adventures(),smmIRPaidRemaining()));
        float extra;
        if (zone.environment=="outdoor" && get_property("_seadentWaveZone")!=zone.to_string() && !effects.contains_text("ITEM_DROPS")) {
            work.cast=have_skill($skill[Cone of Zydeco]) ? $skill[Cone of Zydeco] : $skill[Line of Zydeco]; work.parameters="ITEM_DROPS";
            foreach foe, rate in appearance_rates(zone) if (foe!=$monster[none] && rate>0)
                extra += rate/100.0*max(0,smmIRLoot(foe,item_drop_modifier()+30,false)-smmIRLoot(foe,item_drop_modifier(),false));
        } else if (zone.environment=="indoor" && get_property("_seadentWaveZone")!=zone.to_string() && !effects.contains_text("BRIDGE_PARTS") && get_property("_legendaryAcornBridgeParts").to_int()<10) {
            work.cast=have_skill($skill[Bawdy Refrain]) ? $skill[Bawdy Refrain] : $skill[Juvenile Refrain]; work.parameters="BRIDGE_PARTS";
            float wood=min(smmIRRewardValue($item[thick caulk]),min(smmIRRewardValue($item[long hard screw]),smmIRRewardValue($item[messy butt joint])));
            float fastener=min(smmIRRewardValue($item[raging hardwood plank]),min(smmIRRewardValue($item[weirdwood plank]),smmIRRewardValue($item[raging hardwood plank])));
            extra=0.05*(wood+fastener); // deliberately use the last possible proc rate
        } else continue;
        if (my_mp()<max(30,mp_cost(work.cast))) continue;
        // Commit to the block whose future benefit paid for planting. It is not
        // credited against hypothetical fights in a zone we never visit again.
        float native=smmIRZoneIncome(zone)*work.allowed_turns;
        if (native<=work.allowed_turns*(smmIRTurnValue()+max(0,smmIRSetting("combatCost",50)))) continue;
        float benefit=extra*max(0,work.allowed_turns-2)*zone.combat_percent/100.0;
        float weapon_loss=numeric_modifier(equipped_item($slot[weapon]),"Item Drop")+numeric_modifier(equipped_item($slot[off-hand]),"Item Drop");
        float meat_loss=numeric_modifier(equipped_item($slot[weapon]),"Meat Drop")+numeric_modifier(equipped_item($slot[off-hand]),"Meat Drop");
        foreach foe, rate in appearance_rates(zone) if (foe!=$monster[none] && rate>0) benefit-=rate/100.0*meat_drop(foe)*max(0.0,meat_loss)/100.0*work.allowed_turns;
        if (weapon_loss>0) {
            foreach foe, rate in appearance_rates(zone) if (foe!=$monster[none] && rate>0)
                benefit -= rate/100.0*max(0,smmIRLoot(foe,item_drop_modifier(),false)-smmIRLoot(foe,item_drop_modifier()-weapon_loss,false))*work.allowed_turns;
        }
        if (native+min(0.0,benefit)<=work.allowed_turns*(smmIRTurnValue()+max(0,smmIRSetting("combatCost",50)))) continue;
        smmIRAdd("2026-11.acorn."+zone.to_int(),"Plant a persistent bonus and farm "+zone,work,native+benefit,
            work.allowed_turns*(smmIRTurnValue()+max(0,smmIRSetting("combatCost",50)))+mp_cost(work.cast)*max(0,smmIRSetting("mpValue",1)),"acorn.plants",1);
    }
}

void smmIRGenerateBaseball() {
    if (available_amount($item[Baseball Diamond])<1 || get_property("_baseballInnings").to_int()>=3
        || count(split_string(get_property("baseballTeam"),","))<9 || smmIRUseLink(smmIRInventory,$item[Baseball Diamond])=="") return;
    SmmIRWork work; work.kind="baseball"; work.product=$item[Baseball Diamond]; work.counter="_baseballInnings";
    smmIRAdd("2026-04.baseball","Play a ready inning; choose useful pitches without harmful banishes",work,0,0,"baseball.innings",1);
    smmIRUtility("2026-04.baseball");
}

void smmIRGenerateFarming() {
    if (smmIRPaidRemaining()<1 || my_adventures()<1 || my_inebriety()>inebriety_limit()
        || my_hp()<my_maxhp()/3 || my_mp()<30) return;
    foreach zone, ignored in smmIRZones {
        float income=smmIRZoneIncome(zone);
        if (income<=smmIRTurnValue()) continue;
        SmmIRWork work; work.kind="farm"; work.zone=zone; work.allowed_turns=1;
        smmIRAdd("2026-01.farm."+zone.to_int(),"Profitable native/Sword farming at "+zone,work,income,smmIRTurnValue()+max(0,smmIRSetting("combatCost",50)),"",0);
    }
}

void smmIRGenerateLocket() {
    if (available_amount($item[combat lover's locket])<1 || my_adventures()<1 || my_inebriety()>inebriety_limit()
        || count(cllMonstersFought(false))>=3 || my_hp()<my_maxhp()/3 || my_mp()<30) return;
    // Locket is an older dependency: these free carriers feed newer abilities.
    monster [int] shortlist;
    foreach foe, available in get_locket_monsters() if (available && foe.copyable && !foe.boss) shortlist[count(shortlist)]=foe;
    sort shortlist by -monsterItemMeatValue(value,false,item_drop_modifier());
    int inspected;
    foreach i, foe in shortlist {
        if (inspected>=12) break;
        inspected+=1;
        SmmIRWork work=smmIRCombatLoadout(foe);
        work.kind="locket"; work.foe=foe;
        float value=smmIRCombatValue(foe,work);
        smmIRAdd("2022-02.locket."+foe.to_int(),"Free locket fight: "+foe,work,value,0,"route.locket",1);
        if (work.companion==$familiar[Sword of S Words] && (smmIRActions contains ("2022-02.locket."+foe.to_int())))
            smmIRActions["2022-02.locket."+foe.to_int()].costs["sword.loot"]=1;
    }
}

void smmIRGenerateSwordSeed() {
    if (!have_familiar($familiar[Sword of S Words]) || get_property("_swordOfSWordsMonsterChanged").to_int()>=3
        || get_property("_swordOfSWordsKills").to_int()>=100 || count(cllMonstersFought(false))>=3
        || available_amount($item[combat lover's locket])<1 || my_adventures()<1 || my_mp()<30
        || my_inebriety()>inebriety_limit()) return;
    monster old=to_monster(get_property("swordOfSWordsMonster"));
    float old_value=old==$monster[none] ? 0 : smmIRLoot(old,item_drop_modifier(),false);
    monster [int] shortlist;
    foreach foe, available in get_locket_monsters() if (available && foe.copyable && !foe.boss && foe!=old && smmIRSimpleLoot(foe))
        shortlist[count(shortlist)]=foe;
    sort shortlist by -monsterItemMeatValue(value,false,item_drop_modifier());
    int seen;
    foreach i, foe in shortlist {
        if (seen>=12) break;
        seen+=1;
        float value=smmIRLoot(foe,item_drop_modifier(),false);
        // Value only the guaranteed seed fight here; subsequent fights are
        // independently replanned. No credit for 100 uncreated carriers.
        SmmIRWork work; work.kind="sword.seed"; work.foe=foe; work.companion=$familiar[Sword of S Words];
        work.companion_equipment=familiar_equipped_equipment(work.companion);
        
        if (value<=old_value) continue;
        smmIRAdd("2026-06.seed."+foe.to_int(),"Seed improved Sword target in a free locket fight: "+foe,work,
            value+meat_drop(foe),0,"sword.targets",1);
        if (smmIRActions contains ("2026-06.seed."+foe.to_int())) smmIRActions["2026-06.seed."+foe.to_int()].costs["route.locket"]=1;
    }
}

int smmIRArmorPower() {
    int tao=have_skill($skill[Tao of the Terrapin]) ? 1 : 0;
    int hammer=have_effect($effect[Hammertime])>0 ? 3 : 0;
    return get_power(equipped_item($slot[hat]))*(1+tao)+get_power(equipped_item($slot[pants]))*(1+tao+hammer)+get_power(equipped_item($slot[shirt]));
}

void smmIRGenerate2025() {
    if (have_familiar($familiar[Skeleton of Crimbo Past])) {
        coinmaster shop=$coinmaster[Skeleton of Crimbo Past];
        item [int] goods={$item[Smoking Pope],$item[prize turkey],$item[medicinal gruel],to_item(get_property("_crimboPastDailySpecialItem"))};
        string [int] flags={"_crimboPastSmokingPope","_crimboPastPrizeTurkey","_crimboPastMedicalGruel","_crimboPastDailySpecial"};
        int reserve=max(0,smmIRSetting("boneReserve",0).to_int());
        foreach i, it in goods if (it!=$item[none] && !get_property(flags[i]).to_boolean()) {
            int cost=buy_price(shop,it);
            if (cost<1 || item_amount($item[knucklebone])-reserve<cost) continue;
            SmmIRWork work; work.kind="bones.buy"; work.product=it; work.counter=flags[i];
            smmIRAdd("2025-12.shop."+it.to_int(),"Redeem knucklebones for "+it,work,smmIRRewardValue(it),0,"route.bones",cost);
        }
    }
    if (available_amount($item[prismatic beret])>0 && get_property("_beretBuskingUses").to_int()<5) {
        // The no-argument API predicts the actual current outfit. Only the hat
        // is temporarily changed by the worker, so evaluate that exact power.
        int power=smmIRArmorPower()-get_power(equipped_item($slot[hat]))*(have_skill($skill[Tao of the Terrapin]) ? 2 : 1)
            +get_power($item[prismatic beret])*(have_skill($skill[Tao of the Terrapin]) ? 2 : 1);
        int [effect] results=beret_busking_effects(power,get_property("_beretBuskingUses").to_int());
        SmmIRWork work; work.kind="beret"; work.product=$item[prismatic beret]; work.cast=$skill[Beret Busking]; work.counter="_beretBuskingUses";
        // Guaranteed Meat alone pays. Valuable effects remain a conservative bonus.
        smmIRAdd("2025-06.beret","Busk with the beret (predicted actual outfit)",work,results[$effect[none]],0,"beret.busking",1);
    }
    if (available_amount($item[April Shower Thoughts shield])>0 && !get_property("_aprilShowerGlobsCollected").to_boolean()) {
        SmmIRWork work; work.kind="shower"; work.product=$item[April Shower Thoughts shield]; work.counter="_aprilShowerGlobsCollected";
        smmIRAdd("2025-04.shower","Collect daily Shower Thoughts currency",work,0,0,"",0); smmIRUtility("2025-04.shower");
    }
}

void smmIRGenerateRecovery() {
    if (available_amount($item[bat wings])<1 || get_property("_batWingsRestUsed").to_int()>=11) return;
    int mp=min(1000,my_maxmp()-my_mp()); int hp=min(1000,my_maxhp()-my_hp());
    if (mp<100 && hp<my_maxhp()/3) return;
    SmmIRWork work; work.kind="buff"; work.product=$item[bat wings]; work.cast=$skill[Rest upside down]; work.counter="_batWingsRestUsed";
    smmIRAdd("2024-10.recovery","Free bat-wing recovery before buying restoration",work,mp*max(0,smmIRSetting("mpValue",1)),0,"bat.rest",1);
    if (mp==0 && hp>0) smmIRUtility("2024-10.recovery");
}

