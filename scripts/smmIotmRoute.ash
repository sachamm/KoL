import <smmIotmRouteCore.ash>
import <smmIotmRouteExtras.ash>
import <smmIotmRouteMore.ash>
import <smmGardenPlanner.ash>

SmmRPResource [string] smmIRResources() {
    SmmRPResource [string] pools=smmRPLiveResources();
    pools["route.paid"]=new SmmRPResource("Remaining route turn budget",min(my_adventures(),smmIRPaidRemaining()),true,"");
    pools["route.coins"]=new SmmRPResource("Coins above savings reserve",max(0,item_amount($item[Interesting Coin])-max(1,smmIRSetting("coinReserve",10000000).to_int())),true,"");
    pools["route.bones"]=new SmmRPResource("Bones above reserve",max(0,item_amount($item[knucklebone])-max(0,smmIRSetting("boneReserve",0).to_int())),true,"");
    pools["route.locket"]=new SmmRPResource("Locket reminiscences",max(0,3-count(cllMonstersFought(false))),true,"");
    pools["route.liver"]=new SmmRPResource("Available liver",max(0,inebriety_limit()-my_inebriety()),true,"");
    pools["route.cooks"]=new SmmRPResource("Available free cooking",max(0,free_cooks()),true,"");
    foreach id, action in smmIRActions foreach resource, cost in action.costs if (resource.starts_with("route.item.")) {
        item it=to_item(substring(resource,11));
        int keep=max(0,smmIRSetting("keepItem."+it.to_int(),0).to_int());
        if (smmMuseumEnabled()) keep=max(keep,max(smmMuseumConsumptionReserve(it),smmMuseumKeep(it)));
        if (it==$item[inflammable leaf]) keep=max(keep,max(0,smmIRSetting("leafReserve",0).to_int()));
        pools[resource]=new SmmRPResource("Owned ingredient: "+it,max(0,item_amount(it)-keep),it!=$item[none],"");
    }
    pools["route.leafCrafts"]=new SmmRPResource("Leaf conversions left under today's cap",max(0,max(0,smmIRSetting("leafCraftCap",5).to_int())-smmIRDayCount("leafCrafts")),true,"");
    pools["route.kiwiBuys"]=new SmmRPResource("Kiwi trades left under today's cap",max(0,max(0,smmIRSetting("kiwiBuyCap",5).to_int())-smmIRDayCount("kiwiBuys")),true,"");
    pools["route.gardenChange"]=new SmmRPResource("Single garden change today",smmIRGardenMayChange() ? 1 : 0,true,"");
    pools["route.mushroom"]=new SmmRPResource("Selected garden's mushroom visit",my_garden_type()=="mushroom" && !get_property("_mushroomGardenVisited").to_boolean() ? 1 : 0,true,"");
    for plot from 0 to 2 pools["route.harvest."+plot]=new SmmRPResource("Selected garden harvest",1,true,"");
    pools["route.coinWallet"]=new SmmRPResource("Shared coin wallet (retain one coin)",max(0,item_amount($item[Interesting Coin])-1),true,"");
    pools["route.meat"]=new SmmRPResource("Owned Meat",max(0,my_meat()),true,"");
    foreach id, action in smmIRActions foreach resource, cost in action.costs {
        if (resource.starts_with("route.garden.")) {
            int point=substring(resource,13).to_int();
            pools[resource]=new SmmRPResource("Single garden encounter",(smmIRGarden contains point) && !smmIRGarden[point].done && smmIRGarden[point].reachable ? 1 : 0,true,"");
        } else if (resource.starts_with("route.foe.")) {
            monster foe=to_monster(substring(resource,10).to_int());
            pools[resource]=new SmmRPResource("Unused locket monster",get_locket_monsters()[foe] ? 1 : 0,true,"");
        } else if (resource.starts_with("route.acornZone.")) {
            pools[resource]=new SmmRPResource("Unoccupied persistent zone planting slots",smmIRPlantSlots(to_location(substring(resource,16).to_int())),true,"");
        }
    }
    return pools;
}

void smmIRGenerateMuseumDeposits() {
    if (!smmMuseumEnabled() || !have_display() || get_property("smm.IR.museumDeposit")=="false") return;
    foreach it, amount in get_inventory() if (is_displayable(it) && (get_property("smm.IR.museumHold."+it.to_int()).to_int()>0
        || smmMuseumStored(it))) {
        int quantity=min(smmMuseumDepositAmount(it),max(0,smmMuseumMilestone(it)-smmMuseumDisplay(it)));
        if (quantity<1) continue;
        SmmIRWork work; work.kind="museum.deposit"; work.product=it; work.option=1;
        string id="2026-11.00-display."+it.to_int();
        smmIRAdd(id,"Place owned copies into Display Case: "+it,work,0,0,"",0);
        if (smmIRActions contains id) {
            smmIRActions[id].limit=quantity;
            smmIRActions[id].goal="museum.placement."+it.to_int(); smmIRActions[id].missing=quantity;
            SmmMuseumGoal target=smmMuseumGoal(it);
            float value=get_property("smm.IR.museumRankValue")=="" ? kTurnValue : max(0,get_property("smm.IR.museumRankValue").to_float());
            smmIRActions[id].collection_value=smmMuseumDisplay(it)>=target.first_minimum ? 0.01 : value/max(1,smmMuseumMilestone(it)-smmMuseumDisplay(it));
        }
    }
}

SmmRPPlan smmIRGenerate() {
    clear(smmIRActions); clear(smmIRWorkers);
    // Generators only read state, so one pool snapshot serves the whole pass
    // instead of re-reading every pool for each candidate monster.
    smmIRPoolSnapshot=smmRPLiveResources(); smmIRPoolSnapshotValid=true;
    smmIRLocketRankingValid=false;
    try {
        smmIRGenerateAcorn(); smmIRGenerateGarden(); smmIRGenerateCoins(); smmIRGenerateCup();
        smmIRGenerateSwordSeed(); smmIRGeneratePasta(); smmIRGenerateBaseball(); smmIRGenerateSpade();
        smmIRGenerateHeart(); smmIRGenerateFarming(); smmIRGenerate2025(); smmIRGenerateRecovery(); smmIRGenerateLocket();
        smmIRGardenGenerate(); smmIRExtraGenerate(); smmIRMoreGenerate(); smmIRGenerateMuseumDeposits();
    } finally {
        smmIRPoolSnapshotValid=false;
    }
    SmmRPContext context=new SmmRPContext(smmIROwner,smmIRTurnValue(),true,smmIRCollectionRemaining().to_int(),20000);
    // The solver has a bounded block size. Preserve high-value older carriers
    // as alternatives to newer familiar policies; date controls execution order,
    // not whether a valuable competing use is deleted before optimization.
    boolean pruned;
    while (count(smmIRActions)>60) {
        string worst; float lowest=1000000000000.0;
        foreach id, action in smmIRActions {
            float net=smmRPEconomicValue(action,context);
            float score=(net+(action.goal!="" ? action.collection_value*min(action.limit,action.missing) : 0))/max(1,action.costs["route.paid"]);
            if (net<0 && -net>smmIRCollectionRemaining()) score=-1000000000000.0;
            if (worst=="" || score<lowest) { worst=id; lowest=score; }
        }
        remove smmIRActions[worst]; remove smmIRWorkers[worst]; pruned=true;
    }
    if (pruned) smmIRNote("Candidate limit: retained higher forecast marginal values, including older competing carriers; this is a bounded route search.");
    return smmRPSolve(smmIRActions,smmIRResources(),smmRPReservations(),context);
}

// The consult runs in a separate interpreter. Only this short-lived intent is
// shared; it is never treated as evidence that a skill actually fired.
string smmIRCombatPrefix(monster foe) {
    if (get_property("smm.IR.activeEpoch")!=smmRPEpoch()) return "";
    int id=get_property("smm.IR.combatSkill").to_int();
    if (id<1) return "";
    skill sk=to_skill(id);
    if (!have_skill(sk) || my_mp()<mp_cost(sk) || smmRPAllowedSkillUses(sk,1)<1) return "";
    if (id==7597) return smmIRMaidenPrefix(foe);
    if (id==7593) {
        if (my_familiar()!=$familiar[Sword of S Words] || foe.to_int()!=get_property("smm.IR.seedMonster").to_int()
            || !foe.copyable || foe.boss || get_property("_swordOfSWordsMonsterChanged").to_int()>=3) return "";
    } else {
        location zone=to_location(get_property("smm.IR.plantZone"));
        if (smmRPSpendable("acorn.plants",smmIROwner,smmIRPools(),smmRPReservations())<1) return "";
        int target=get_property("smm.IR.plantTarget").to_int();
        if (target>0 && foe.to_int()!=target) return "";
        if (my_location()!=zone || !(get_location_monsters(zone) contains foe)
            || smmIRAcornEffects(zone).contains_text(get_property("smm.IR.plantEffect"))
            || smmIRAcornsToday(zone)>=3 || get_property("_legendaryAcornsUsed").to_int()>=12) return "";
    }
    // Never queue twice if the consult is called again after an abort.
    set_property("smm.IR.combatSkill","");
    return "if hasskill "+id+";skill "+id+";endif;";
}

int smmIRPitch(string [int] options) {
    if (options contains 6) return 6;
    // No banishing, tracking, +ML, or unpriced farming commitments.
    string [int] preference={"Schenectady","Garbageball","Snowball","Ghost Pitch","Some Smoke","Bring the Heat","Deep Freeze","Slurve","Slider","Skullball","Beanball"};
    foreach i, wanted in preference foreach option, label in options
        if (label.to_lower_case().contains_text(wanted.to_lower_case())) return option;
    return 0;
}

boolean smmIRPrepare(SmmIRWork work) {
    if (work.product!=$item[none] && (work.kind=="buff" || work.kind=="beret") && !smmIREquip(work.product)) return false;
    if (work.kind=="pasta.summon" && !smmIREquip($item[legendary pasta wand])) return false;
    if (work.kind=="acorn.block" && !smmIREquip($item[legendary acorndion])) return false;
    if (work.kind=="heart.lucky" && !smmIREquip($item[Heartstone])) return false;
    if (work.companion!=$familiar[none]) {
        if (!use_familiar(work.companion)) return false;
        if (equipped_item($slot[familiar])!=work.companion_equipment && !equip($slot[familiar],work.companion_equipment)) return false;
    }
    return true;
}

boolean smmIRDispatch(SmmIRWork work) {
    if (work.kind=="museum.deposit") return smmMuseumDeposit(work.product,work.option);
    // A queued summon can become unavailable after planning. Check before
    // equipping the wand so an exhausted skill causes no equipment churn.
    if (work.kind=="pasta.summon" && work.cast.dailylimit<1) return false;
    if (!smmIRPrepare(work)) return false;
    if (work.kind.starts_with("garden.")) return smmIRGardenDispatch(work);
    if (work.kind.starts_with("extra.")) return smmIRExtraDispatch(work);
    if (work.kind.starts_with("more.")) return smmIRMoreDispatch(work);
    if (work.kind=="buff" || work.kind=="beret") {
        string before=get_property(work.counter);
        return have_skill(work.cast) && smmIRCast(work.cast) && get_property(work.counter)!=before;
    }
    if (work.kind=="pasta.summon") {
        int before=item_amount(work.product);
        return have_skill(work.cast) && smmIRCast(work.cast) && item_amount(work.product)>=before+work.option;
    }
    if (work.kind=="craft") {
        int copies=max(1,work.batch);
        if (free_cooks()<copies) return false;
        foreach it, quantity in get_ingredients(work.product) if (!smmIRMayConsume(it,quantity*copies)) return false;
        return smmIRCreateBatch(copies,work.product)>=copies;
    }
    if (work.kind=="coin.buy" || work.kind=="bones.buy") {
        coinmaster shop=work.kind=="coin.buy" ? $coinmaster[Spend your Interesting Coins] : $coinmaster[Skeleton of Crimbo Past];
        item currency=work.kind=="coin.buy" ? $item[Interesting Coin] : $item[knucklebone];
        int reserve=max(work.kind=="coin.buy" ? 1 : 0,smmIRSetting(work.kind=="coin.buy" ? "coinReserve" : "boneReserve",work.kind=="coin.buy" ? 10000000 : 0).to_int());
        int price=smmIRShopPrice(shop,work.product);
        if (price<1 || item_amount(currency)-price<reserve) return false;
        int before=item_amount(work.product); int balance=item_amount(currency);
        buy(shop,1,work.product);
        return item_amount(work.product)>before && item_amount(currency)<balance;
    }
    if (work.kind=="shower") {
        smmIRVisit("inventory.php?action=shower");
        return get_property("_aprilShowerGlobsCollected").to_boolean();
    }
    if (work.kind=="cup") {
        int [item] needed; needed[work.ingredient1]+=1; needed[work.ingredient2]+=1; needed[work.ingredient3]+=1;
        foreach it, quantity in needed if (!smmIRMayConsume(it,quantity)) return false;
        if (my_inebriety()>=inebriety_limit() || !can_drink() || !smmIROpenItem($item[Cup of 13s],1601)) return false;
        int jewels=get_property("_cupOf13sJewels").to_int(); int liver=my_inebriety(); int adv=my_adventures();
        run_choice(1,"whichitem1="+work.ingredient1.to_int()+"&whichitem2="+work.ingredient2.to_int()+"&whichitem3="+work.ingredient3.to_int());
        smmIRLeaveChoice(1601,4);
        return my_inebriety()>liver && my_adventures()>adv && get_property("_cupOf13sJewels").to_int()<jewels;
    }
    if (work.kind=="garden") {
        string page=smmIRVisit("campground.php?action=rosegarden");
        SmmIRGardenPoint [int] points=smmIRParseGarden(page);
        if (!handling_choice() || last_choice()!=1637 || !(points contains work.option) || points[work.option].done || !points[work.option].reachable) { smmIRLeaveChoice(1637,2); return false; }
        run_choice(1,work.parameters);
        if (current_round()>0) run_combat();
        if (current_round()>0 || (handling_choice() && last_choice()!=1637)) return false;
        page=smmIRVisit("campground.php?action=rosegarden");
        smmIRGarden=smmIRParseGarden(page); smmIRLeaveChoice(1637,2);
        return (smmIRGarden contains work.option) && smmIRGarden[work.option].done;
    }
    if (work.kind=="spade") {
        if (to_location(get_property("lastAdventure"))!=work.zone || !smmIROpenItem($item[Archaeologist's Spade],1596)) return false;
        int before=get_property("_archSpadeDigs").to_int();
        string [int] options=available_choice_options();
        if (!(options contains work.option)) { smmIRLeaveChoice(1596,4); return false; }
        run_choice(work.option);
        if (current_round()>0) run_combat();
        smmIRLeaveChoice(1596,4);
        return get_property("_archSpadeDigs").to_int()>before && current_round()==0;
    }
    if (work.kind=="baseball") {
        int before=get_property("_baseballInnings").to_int();
        if (!smmIROpenItem($item[Baseball Diamond],1598)) return false;
        for pitch from 1 to 30 {
            if (!handling_choice() || last_choice()!=1598) break;
            int option=smmIRPitch(available_choice_options());
            if (option==0) abort("Unrecognized baseball pitches: finish this inning manually. Its entry already spent an inning.");
            run_choice(option);
        }
        return !handling_choice() && get_property("_baseballInnings").to_int()>before;
    }
    if (work.kind=="locket" || work.kind=="sword.seed") {
        if (!get_locket_monsters()[work.foe]) return false;
        int before=count(cllMonstersFought(false));
        if (work.kind=="sword.seed") {
            set_property("smm.IR.seedMonster",work.foe.to_int()); set_property("smm.IR.combatSkill",7593);
        }
        cli_execute("reminisce "+work.foe.to_int());
        if (current_round()>0) run_combat();
        return count(cllMonstersFought(false))>before && current_round()==0
            && (work.kind!="sword.seed" || to_monster(get_property("swordOfSWordsMonster"))==work.foe);
    }
    if (work.kind=="heart.lucky") {
        if (!smmIRCast(work.cast) || have_effect($effect[Lucky!])<1) return false;
        return smmIRAdventure(work.zone);
    }
    if (work.kind=="farm" || work.kind=="acorn.block") {
        int start=smmIRTurns(); int before=get_property("_legendaryAcornsUsed").to_int();
        if (work.kind=="acorn.block") {
            if (!have_skill(work.cast)) return false;
            set_property("smm.IR.plantZone",work.zone);
            set_property("smm.IR.plantEffect",work.parameters);
            set_property("smm.IR.combatSkill",work.cast.to_int());
        }
        for attempt from 1 to work.allowed_turns+3 {
            if (smmIRTurns()-start>=work.allowed_turns || smmIRPaidRemaining()<1 || my_adventures()<1) break;
            if (my_hp()<my_maxhp()/3 || my_mp()<30 || have_effect($effect[Beaten Up])>0) break;
            // Recompute expected base yield before each paid turn. Stop rather
            // than continue a stale profitable-looking forecast after a buff ends.
            if (smmIRZoneIncome(work.zone)<=smmIRTurnValue()+max(0,smmIRSetting("combatCost",50))) break;
            if (!smmIRAdventure(work.zone)) break;
            if (handling_choice() || current_round()>0) break;
        }
        return smmIRTurns()>start && (work.kind!="acorn.block" || get_property("_legendaryAcornsUsed").to_int()>before);
    }
    return false;
}

// Pool snapshots taken around the last attempted worker, kept so the route
// loop can compare the observed change with what the plan expected.
SmmRPResource [string] smmIRPoolsBefore;
SmmRPResource [string] smmIRPoolsAfter;

SmmIRResult smmIRExecute(SmmIRWork work) {
    SmmIRResult result;
    clear(smmIRPoolsBefore); clear(smmIRPoolsAfter);
    if (work.allowed_turns>smmIRPaidRemaining()) { result.reason="insufficient remaining paid-turn budget"; return result; }
    if (smmIRSelectedLoss>smmIRCollectionRemaining()) { result.reason="daily collection-loss budget exhausted"; smmIRSelectedLoss=0; return result; }
    set_property("smm.IR.lastMuseumDeposit","");
    int [item] before_inventory=get_inventory();
    SmmRPResource [string] before_resources=smmIRResources();
    set_property("smm.IR.plantTarget",0);
    SmmIRGear gear=smmIRSaveGear();
    smmIRStoreGear(gear);
    SmmRPLease lease=smmRPBegin(smmIROwner);
    int turns=smmIRTurns(); int adv=my_adventures(); int meat=my_meat();
    try {
        result.attempted=true;
        result.success=smmIRDispatch(work);
        if (!result.success) result.reason="postcondition not confirmed; blocked for this run";
        if (have_effect($effect[Beaten Up])>0 || handling_choice() || current_round()>0) {
            result.success=false; result.reason="unfinished encounter or defeat; route stopped";
        }
    } finally {
        result.turns=max(0,smmIRTurns()-turns);
        result.adventures_gained=my_adventures()-adv+result.turns;
        result.meat_delta=my_meat()-meat;
        smmIRAccountTurns(result.turns);
        set_property("smm.IR.combatSkill","");
        smmRPFinish(lease);
        if (current_round()==0 && !handling_choice() && !smmIRRestorePendingGear()) abort("Could not restore the pre-route equipment. Route stopped; saved outfit retained for iotmroute reset.");
        if (current_round()==0 && !handling_choice()) smmMuseumRetainGains(before_inventory);
        result.displayed=get_property("smm.IR.lastMuseumDeposit");
        boolean consumed=result.success || result.turns>0 || result.meat_delta<0;
        SmmRPResource [string] after_resources=smmIRResources();
        smmIRPoolsBefore=before_resources; smmIRPoolsAfter=after_resources;
        foreach resource, previous in before_resources if ((after_resources contains resource) && previous.known && after_resources[resource].known
            && after_resources[resource].remaining<previous.remaining) consumed=true;
        foreach it, quantity in before_inventory if (item_amount(it)<quantity) consumed=true;
        if (consumed) smmIRCollectionCharge(smmIRSelectedLoss);
        smmIRSelectedLoss=0;
        if (result.turns>work.allowed_turns) abort("An expected free/bounded action spent extra turns; recorded the actual cost and stopped the route.");
    }
    return result;
}

// Cheap fingerprint of the character state the candidate generators gate or
// value on. Gates are recorded as crossings, not raw numbers, so ordinary
// HP/MP/adventure movement does not look like a change.
string smmIRStateSignature() {
    string value=(my_adventures()>0)+"|"+(my_adventures()>=3)+"|"+(my_hp()<my_maxhp()/3)+"|"+(my_mp()<30)
        +"|"+(my_inebriety()<inebriety_limit())+"|"+(my_inebriety()>inebriety_limit())
        +"|"+(have_effect($effect[Lucky!])>0)+"|"+(have_effect($effect[Fishy])>0)+"|"+(have_effect($effect[Beaten Up])>0)
        +"|"+item_drop_modifier()+"|"+meat_drop_modifier()+"|"+weight_adjustment()+"|"+monster_level_adjustment()
        +"|"+my_familiar()+"|"+equipped_item($slot[familiar])
        +"|"+get_property("swordOfSWordsMonster")+"|"+(get_property("_swordOfSWordsKills").to_int()>=100)
        +"|"+get_property("_seadentWaveZone")+"|"+my_garden_type();
    // The spade candidates are tied to the last adventured zone.
    if (available_amount($item[Archaeologist's Spade])>0 && get_property("_archSpadeDigs").to_int()<11) value+="|"+get_property("lastAdventure");
    foreach id, point in smmIRGarden value+="|"+id+":"+point.done+":"+point.reachable;
    // A later batch cannot reuse demand capacity or Museum tiers consumed by
    // an earlier worker. Count total non-case ownership, not inventory moves.
    foreach it, price in smmIRPrices value+="|valuedStock."+it.to_int()+"="+smmIRResaleStock(it);
    return value;
}

// Actions whose results change prices or create capacity that neither the pool
// comparison nor the state signature can see.
boolean smmIREnabler(string kind) {
    return kind=="coin.buy" || kind.starts_with("extra.coin.") || kind=="bones.buy" || kind=="pasta.summon"
        || kind=="more.taker.collect" || kind=="more.leaves.jump" || kind=="garden.switch";
}

// A stale plan must not get a worker blocked for a gate the generators would
// have applied. Returns the reason to replan before running this action.
string smmIRStaleReason(string id) {
    SmmIRWork work=smmIRWorkers[id];
    if (work.cast!=$skill[none] && my_mp()<mp_cost(work.cast)) return "not enough MP left for "+work.cast;
    return "";
}

// Actions that make or buy identical copies and can do the whole planned
// quantity in one worker call (see smmIRBatch).
boolean smmIRBatchable(string kind) {
    return kind=="craft" || kind=="more.create" || kind=="more.buy" || kind=="more.kiwi";
}

// Decide whether the action just run changed anything the rest of the plan
// depends on. Returns "" when the remaining plan is still valid, otherwise the
// reason for replanning. Gains outside valued stock and used pools (unpriced
// loot, extra Meat) are left for the confirming replan at the end of the plan.
string smmIRMaterialChange(string id, int units, SmmIRResult result, string before, string after, int [string] queued) {
    if (!result.success) return "action failed or was blocked";
    if (before!=after) return "character state changed (gate, modifier, Sword target, garden or valued stock)";
    if (smmIREnabler(smmIRWorkers[id].kind)) return "action changes prices or creates new capacity";
    // Each action priced its ingredients as if it were their only user. Under
    // tiered Museum pricing the next user of the same ingredient may now be
    // drawing on dearer copies, so reprice it before it runs.
    if (smmMuseumEnabled()) foreach pool, cost in smmIRActions[id].costs if (pool.starts_with("route.item."))
        foreach other, quantity in queued if (other!=id && quantity>0 && (smmIRActions[other].costs contains pool))
            return "ingredient "+to_item(substring(pool,11).to_int())+" is shared with a later action";
    // Only pools some candidate draws on can change the allocation.
    boolean [string] used;
    foreach other, action in smmIRActions foreach pool, cost in action.costs used[pool]=true;
    foreach pool, previous in smmIRPoolsBefore {
        if (!(used contains pool) || !(smmIRPoolsAfter contains pool)) continue;
        if (!previous.known || !smmIRPoolsAfter[pool].known) {
            if (previous.known!=smmIRPoolsAfter[pool].known) return "pool "+pool+" changed availability";
            continue;
        }
        int expected=previous.remaining;
        if (smmIRActions[id].costs contains pool) expected-=units*smmIRActions[id].costs[pool];
        int actual=smmIRPoolsAfter[pool].remaining;
        if (actual<expected) return "pool "+pool+" has "+actual+" left, "+expected+" expected";
        // Extra Meat cannot invalidate anything already planned.
        if (actual>expected && pool!="route.meat") return "pool "+pool+" has "+actual+" left, "+expected+" expected";
    }
    return "";
}

string smmIRNext(int [string] quantities) {
    string next;
    foreach id, q in quantities if (q>0 && (next=="" || substring(id,0,7)>substring(next,0,7))) next=id;
    return next;
}

void smmIRReport(SmmRPPlan plan) {
    if (!plan.valid) { print("IoTM route: "+plan.error,"red"); return; }
    print("IoTM route: forecast score "+round(plan.economic_value)+" Meat equivalent (marginal sale estimates or avoided collection purchases); paid turns remaining "+smmIRPaidRemaining()+".","blue");
    print("Values are repriced after valued stock changes. This is not realized profit or a joint liquidation portfolio.","gray");
    if (smmMuseumEnabled()) print("Objective: Museum #1 per item, top 10 acceptable. Rank utility is scored separately; unavailable rankings are never treated as zero targets.","blue");
    int [string] remaining;
    foreach id, q in plan.quantity if (q>0) remaining[id]=q;
    while (count(remaining)>0) {
        string id=smmIRNext(remaining);
        SmmRPContext context=new SmmRPContext(smmIROwner,smmIRTurnValue(),true,0,20000);
        print(id+": "+smmIRActions[id].description+(remaining[id]>1 ? " x"+remaining[id] : "")+" [estimated net "+round(smmRPEconomicValue(smmIRActions[id],context)*remaining[id])+" Meat]");
        print("    why: "+smmIRWhy[id],"gray"); print("    expected result: "+smmIRExpect[id],"gray");
        if (smmIRThen[id]!="") print("    then: "+smmIRThen[id],"gray");
        remove remaining[id];
    }
    foreach i, message in smmIRNotes print(message,"gray");
    if (!plan.optimal) print("Search limit reached: this is a feasible route, without an optimality claim.","gray");
}

void smmIRRestoreSettings() {
    string packed=get_property("smm.IR.savedSettings");
    if (packed=="") return;
    foreach i, entry in split_string(packed,"\\|") {
        int equals=index_of(entry,"=");
        if (equals<0) continue;
        string key=url_decode(substring(entry,0,equals)); string value=url_decode(substring(entry,equals+1));
        if (key=="routeAutoAttack") smmIRSetAutoAttack(value.to_int());
        else if (key=="currentMood") cli_execute("mood "+value);
        else set_property(key,value);
    }
    set_property("smm.IR.savedSettings","");
}

void smmIRDailyRoute(boolean free_only, boolean execute) {
    if (!smmIREnabled()) { if (execute) smmIRGardenBreakfast(false); return; }
    if (inRonin() || my_path()!=$path[none]) { print("IoTM route requires unrestricted aftercore.","gray"); return; }
    // Overdrunk (good_night_adv, after the nightcap): a free-only pass. Zone generators
    // already skip when overdrunk; what is left is work started from an item or skill,
    // chiefly the locket fights held back for this pass (smmIRGenerateLocket).
    boolean overdrunk=my_inebriety()>inebriety_limit();
    if (overdrunk) { free_only=true; print("IoTM route: overdrunk pass (no zones; locket fights and other item/skill work).","blue"); }
    string active=get_property("smm.IR.activeEpoch");
    if (active!="" && active!=smmRPEpoch() && !handling_choice() && current_round()==0) {
        // A lock from an earlier day or ascension cannot belong to a running
        // route: it was left by an interrupted session. Recover as iotmroute
        // reset does, so one interruption does not block every later daily run.
        print("Clearing an IoTM route lock left by an interrupted earlier session ("+active+").","orange");
        if (!smmIRRestorePendingGear()) abort("Could not restore the outfit saved by an interrupted IoTM route; inspect smm.IR.pendingGear, then use iotmroute reset.");
        smmIRRestoreSettings();
        set_property("smm.IR.combatSkill",""); set_property("smm.IR.activeEpoch","");
    }
    if (get_property("smm.IR.activeEpoch")!="") abort("IoTM route is already active, or was interrupted. Use iotmroute reset after resolving the encounter.");
    if (get_property("smm.IR.pendingGear")!="") abort("An interrupted IoTM outfit is waiting to be restored. Resolve the encounter and use iotmroute reset.");
    smmIRNoPaidTurns=free_only;
    clear(smmIRBlocked); clear(smmIRNotes); clear(smmIRPrices); clear(smmIRReplacementPrices); clear(smmIRMarkets); clear(smmMuseumGoals); clear(smmMuseumKeeps); clear(smmIRZones); clear(smmIRGarden);
    smmIRShopStockLoaded=false;
    smmIRQuotes=0; smmIRDiscovered=false;
    clear(smmIROwnedFamiliars);
    smmIRDiscover(); smmIRMoreDiscover();
    if (handling_choice() || current_round()>0) abort("Route discovery reached an unexpected encounter. Resolve it before continuing.");
    smmIRGardenEvaluate(execute && !overdrunk); // garden encounters can't be fought overdrunk
    SmmRPPlan plan=smmIRGenerate(); smmIRReport(plan);
    if (!execute || !plan.valid) return;
    string [string] saved;
    foreach i, prop in split_string("customCombatScript|battleAction|beforeAdventureScript|betweenBattleScript|afterAdventureScript|autoSatisfyWithMall|autoSatisfyWithNPCs|autoSatisfyWithCoinmasters|autoSatisfyWithStash|autoSatisfyWithStorage|autoSatisfyWithCloset|autoSatisfyWithShop|familiarScript|currentMood|recoveryScript|manaBurningThreshold|manaBurningTrigger|hpAutoRecovery|mpAutoRecovery","\\|") saved[prop]=get_property(prop);
    string packed;
    foreach prop, value in saved packed+=url_encode(prop)+"="+url_encode(value)+"|";
    packed+="routeAutoAttack="+get_auto_attack();
    set_property("smm.IR.savedSettings",packed);
    string epoch=smmRPEpoch();
    buffer log;
    try {
        set_property("smm.IR.activeEpoch",epoch);
        set_property("customCombatScript","smm-iotm-route"); set_property("battleAction","custom combat script"); smmIRSetAutoAttack(0);
        foreach prop, value in saved {
            if (prop.starts_with("autoSatisfyWith") && prop!="autoSatisfyWithCloset" && prop!="autoSatisfyWithStorage") set_property(prop,false);
            if (prop.ends_with("AdventureScript") || prop=="betweenBattleScript") set_property(prop,"");
        }
        cli_execute("mood apathetic"); set_property("recoveryScript","");
        set_property("manaBurningThreshold",-0.05); set_property("manaBurningTrigger",-0.05);
        set_property("familiarScript", ""); set_property("hpAutoRecovery",-0.05); set_property("mpAutoRecovery",-0.05);
        // The solved plan is a work queue. It is rebuilt only when something
        // material changed (see smmIRMaterialChange), and once more when the
        // queue empties, to pick up actions the day's results made possible.
        int steps; int plans=1; boolean stale;
        // No cap on actions unless smm.IR.maxActions is set.
        int max_steps=get_property("smm.IR.maxActions")=="" ? 0 : max(1,get_property("smm.IR.maxActions").to_int());
        while ((max_steps==0 || steps<max_steps) && epoch==smmRPEpoch() && plan.valid) {
            string next=smmIRNext(plan.quantity);
            string replan;
            if (next=="") {
                if (!stale) break; // a fresh plan with nothing to do: finished
                replan="plan completed; checking for newly available actions";
            } else if (stale) replan=smmIRStaleReason(next);
            if (replan=="") {
                SmmIRWork work=smmIRCopyWork(smmIRWorkers[next]);
                // Batched actions run their whole planned quantity in one worker.
                int units=1;
                if (work.kind=="museum.deposit") { units=plan.quantity[next]; work.option=units; }
                else if (work.kind=="farm") { units=plan.quantity[next]; work.allowed_turns=units; }
                else if (smmIRBatchable(work.kind)) { units=plan.quantity[next]; work.batch=units; }
                print("IoTM route: "+smmIRActions[next].description+(units>1 && work.kind=="farm" ? " (up to "+units+" turns)" : units>1 && smmIRBatchable(work.kind) ? " x"+units+" in one batch" : ""),"blue");
                print("    why: "+smmIRWhy[next],"gray"); print("    expected result: "+smmIRExpect[next],"gray");
                if (smmIRThen[next]!="") print("    then: "+smmIRThen[next],"gray");
                log.append("ATTEMPT\t"+next+"\n"); log.buffer_to_file("smm-iotm-route-last.txt");
                SmmRPContext valuation=new SmmRPContext(smmIROwner,smmIRTurnValue(),true,0,20000);
                smmIRSelectedLoss=max(0.0,-smmRPEconomicValue(smmIRActions[next],valuation))*(work.kind=="farm" || smmIRBatchable(work.kind) ? units : 1);
                string before=smmIRStateSignature();
                SmmIRResult result=smmIRExecute(work); steps+=1;
                log.append(next+"\t"+result.success+"\tpaid="+result.turns+"\tMeat="+result.meat_delta+"\tadventures gained="+result.adventures_gained+"\tdisplay="+result.displayed+"\t"+result.reason+"\n");
                if (!result.success) { smmIRBlocked[next]=true; print("    NOT achieved ("+smmIRExpect[next]+") - "+result.reason,"orange"); }
                else print("    achieved: "+smmIRExpect[next],"green");
                if (handling_choice() || current_round()>0 || have_effect($effect[Beaten Up])>0) break;
                // Real properties/inventory are read after every worker. When they
                // match what the plan expected, the rest of the plan still stands.
                replan=smmIRMaterialChange(next,units,result,before,smmIRStateSignature(),plan.quantity);
                if (replan=="") {
                    plan.quantity[next]-=units;
                    if (plan.quantity[next]<1) remove plan.quantity[next];
                    stale=true;
                    continue;
                }
            }
            print("IoTM route: replanning - "+replan,"gray");
            log.append("REPLAN\t"+replan+"\n");
            plan=smmIRGenerate(); plans+=1; stale=false;
        }
        print("IoTM route: "+steps+" actions attempted with "+plans+" planning passes.","blue");
        log.append("SUMMARY\tactions="+steps+"\tplans="+plans+"\n");
        if (max_steps>0 && steps>=max_steps) print("IoTM route step limit reached; inspect the receipt before continuing.","orange");
    } finally {
        log.buffer_to_file("smm-iotm-route-last.txt");
        smmIRRestoreSettings();
        set_property("smm.IR.combatSkill",""); set_property("smm.IR.activeEpoch","");
    }
}
