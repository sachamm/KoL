import <smmIotmRouteCore.ash>

// Included after the core records/valuation helpers, before route generation.
// No stand-alone entry point: every candidate uses the daily route's solver.

string smmIRTerrain(location zone) {
    return get_property("_seadentWaveZone")==zone.to_string() ? "underwater" : zone.environment;
}

string smmIRPlantEffect(string terrain, int column) {
    string [int] rows;
    rows[0]="PASSIVE_DMG,DAMAGE_REDUCTION,BANISH,PASSIVE_DMG_SPOOKY,BRIDGE_PARTS,INITIATIVE";
    rows[1]="WEAKEN,NONCOMBAT_5,MHP_DEBUFF,ENTANGLE,PASSIVE_DMG_SLEAZE,ITEM_DROPS";
    rows[2]="STAT_GAIN,STAT_BUFF,FRUIT,SNIFF,RESTORE,STUN";
    rows[3]="PASSIVE_DMG_PERCENT,SEA_FRUIT,NONCOMBAT_10,BANISH,SEA_COWS,BETTER_DIVER";
    int row=terrain=="indoor" ? 0 : terrain=="outdoor" ? 1 : terrain=="underground" ? 2 : terrain=="underwater" ? 3 : -1;
    if (row<0 || column<0 || column>5) return "";
    return split_string(rows[row],",")[column];
}

skill smmIRPlantSkill(int column) {
    skill [int] proper={$skill[Dissonant Riff],$skill[Cadenza],$skill[Accordion Bash],$skill[Concerto de los Muertos],$skill[Bawdy Refrain],$skill[Cone of Zydeco]};
    return have_skill(proper[column]) ? proper[column] : to_skill(7600+column);
}

int smmIRPlantSlots(location zone) {
    string effects=smmIRAcornEffects(zone);
    return min(max(0,3-smmIRAcornsToday(zone)),max(0,3-(effects=="" ? 0 : count(split_string(effects,",")))));
}

float smmIRCollectionRemaining() {
    float used=get_property("smm.IR.collectionEpoch")==smmRPEpoch() ? get_property("smm.IR.collectionSpent").to_float() : 0;
    return max(0,smmIRSetting("collectionBudget",0)-used);
}

void smmIRCollectionCharge(float amount) {
    if (amount<=0) return;
    if (get_property("smm.IR.collectionEpoch")!=smmRPEpoch()) {
        set_property("smm.IR.collectionEpoch",smmRPEpoch()); set_property("smm.IR.collectionSpent",0);
    }
    set_property("smm.IR.collectionSpent",get_property("smm.IR.collectionSpent").to_float()+amount);
}

void smmIRGoal(string id, string goal, float premium) {
    if (!(smmIRActions contains id)) return;
    smmIRActions[id].goal=goal; smmIRActions[id].missing=1;
    smmIRActions[id].collection_value=max(0,premium);
}

// Compare the reweighted combat distribution, without claiming Adventure Queue
// rejection is absent. The gain forecast is deliberately discounted by half.
float smmIRReweightGain(float average, float target_value, float target_fraction, boolean banish) {
    if (target_fraction<=0 || target_fraction>=1) return 0;
    float after=banish ? (average-target_fraction*target_value)/(1-target_fraction)
        : (average+3*target_fraction*target_value)/(1+3*target_fraction);
    return max(0,after-average)*0.5;
}

void smmIRGenerateMoreAcorns() {
    if (available_amount($item[legendary acorndion])<1 || !can_equip($item[legendary acorndion]) || smmIRPaidRemaining()<3
        || my_adventures()<3 || my_hp()<my_maxhp()/3 || my_mp()<30) return;
    foreach zone, ignored in smmIRZones {
        if (smmIRPlantSlots(zone)<1) continue;
        string terrain=smmIRTerrain(zone);
        int turns=min(10,min(my_adventures(),smmIRPaidRemaining()));
        float native=smmIRZoneIncome(zone);
        float turn_cost=smmIRTurnValue()+max(0,smmIRSetting("combatCost",50));
        if (native<=turn_cost) continue;
        float loss;
        float items=max(0,numeric_modifier(equipped_item($slot[weapon]),"Item Drop"))+max(0,numeric_modifier(equipped_item($slot[off-hand]),"Item Drop"));
        float meat=max(0,numeric_modifier(equipped_item($slot[weapon]),"Meat Drop"))+max(0,numeric_modifier(equipped_item($slot[off-hand]),"Meat Drop"));
        foreach foe, rate in appearance_rates(zone) if (foe!=$monster[none] && rate>0)
            loss+=rate/100.0*(max(0,smmIRLoot(foe,item_drop_modifier(),false)-smmIRLoot(foe,item_drop_modifier()-items,false))+meat_drop(foe)*meat/100.0);
        // Both the setup block and its incremental planting must pay for the
        // weapon/off-hand displacement; no credit for hypothetical later days.
        if (native-loss<=turn_cost) continue;
        for column from 0 to 5 {
            string effect_name=smmIRPlantEffect(terrain,column);
            if (effect_name=="" || smmIRAcornEffects(zone).contains_text(effect_name)) continue;
            if ((terrain=="outdoor" && effect_name=="ITEM_DROPS") || (terrain=="indoor" && effect_name=="BRIDGE_PARTS")) continue; // core adapter
            SmmIRWork work; work.kind="extra.acorn"; work.zone=zone; work.cast=smmIRPlantSkill(column); work.parameters=effect_name; work.allowed_turns=turns;
            float benefit; boolean targeted;
            float premium=max(0,smmIRSetting("acornValue."+effect_name,0));
            if (effect_name=="SNIFF" || effect_name=="BANISH") {
                // Permanent banishing requires an explicit target. Sniffing
                // defaults to the best eligible native target by expected loot.
                monster requested=to_monster(get_property("smm.IR.acornTarget."+zone.to_int()+"."+effect_name));
                float best;
                SmmIRWork gear; gear.companion=my_familiar(); gear.companion_equipment=equipped_item($slot[familiar]);
                float average; float total;
                foreach foe, rate in appearance_rates(zone) if (foe!=$monster[none] && rate>0) { total+=rate; average+=rate*smmIRCombatValue(foe,gear); }
                if (total<=0) continue;
                average/=total;
                foreach foe, rate in appearance_rates(zone) if (foe!=$monster[none] && rate>0 && foe.copyable && !foe.boss) {
                    if ((effect_name=="BANISH" && requested!=foe) || (requested!=$monster[none] && requested!=foe)) continue;
                    float chance=rate/total*min(1.0,zone.combat_percent/100.0);
                    if (chance<=0 || rate>=total) continue;
                    int future=max(0,turns-ceil(1/chance));
                    float gain=smmIRReweightGain(average,smmIRCombatValue(foe,gear),rate/total,effect_name=="BANISH")*future*zone.combat_percent/100.0;
                    // A banish forfeits the current monster's Meat/items.
                    if (effect_name=="BANISH") gain-=smmIRCombatValue(foe,gear);
                    if (gain>best || (requested==foe && premium>0)) { best=gain; work.foe=foe; }
                }
                benefit=best; targeted=true;
            } else if (effect_name=="RESTORE") {
                benefit=min(max(0,my_maxmp()-my_mp()),min(1000,floor(my_maxmp()*0.10))*max(0,turns-2))*max(0,smmIRSetting("mpValue",1));
            }
            float cost=loss*turns+mp_cost(work.cast)*max(0,smmIRSetting("mpValue",1));
            if (benefit<0) { cost-=benefit; benefit=0; }
            // Other terrain effects can be explicit utility goals. Their
            // actual setup expense is charged to the daily collection budget.
            if (benefit<=cost && premium<=cost) continue;
            if (targeted && work.foe==$monster[none]) continue;
            if (my_mp()<max(30,mp_cost(work.cast))) continue;
            string id="2026-11.extra."+zone.to_int()+"."+column;
            if (benefit>cost) smmIRAdd(id,"Plant "+effect_name+" in "+zone,work,native*turns+benefit,turn_cost*turns+cost,"acorn.plants",1);
            else {
                smmIRAdd(id,"Utility planting "+effect_name+" in "+zone,work,0,cost,"acorn.plants",1);
                smmIRGoal(id,"plant."+zone.to_int()+"."+effect_name,premium);
            }
        }
    }
}

int smmIRChoiceContaining(string [int] options, string token) {
    int found;
    foreach option, label in options if (label.to_lower_case().contains_text(token.to_lower_case())) {
        if (found!=0) return 0; // ambiguous options require a policy update
        found=option;
    }
    return found;
}

int smmIRMissingThorns() {
    int missing;
    foreach it in $items[black thorn crown,black thorn whip,black thorn sarong,black thorn necklace]
        if (smmMuseumEnabled() ? smmMuseumNeedsCopy(it) : available_amount(it)<1) missing+=1;
    return missing;
}

void smmIRGenerateMoreGarden() {
    if (smmIRChosenGarden!="" && smmIRChosenGarden!=my_garden_type()) return;
    foreach i, point in smmIRGarden if (!point.done && point.reachable) {
        SmmIRWork work; work.kind="extra.garden"; work.choice_id=1637; work.option=point.id;
        work.parameters="rgpoi="+point.id+"&rgx="+point.x+"&rgy="+point.y+"&rgf=0";
        string id="2026-10.extra."+point.id;
        if (point.kind=="chest") {
            if (!smmIRMayConsume($item[black thorn key],1)) continue;
            int missing=smmIRMissingThorns();
            float premium=missing>0 ? max(0,smmIRSetting("thornOutfitValue",0)) : 0;
            // The reward distribution is not documented. No invented average
            // value or guarantee that a missing piece will be selected.
            if (premium<=0) continue;
            work.product=$item[black thorn key]; work.counter="chest";
            smmIRAdd(id,"Open a keyed chest for missing Black Thorn outfit pieces",work,0,smmIRInputValue(work.product),"route.item."+work.product.to_int(),1);
            smmIRGoal(id,"thorn.chest."+point.id,premium);
        } else if (point.kind=="fountain") {
            if (have_effect($effect[Lucky!])<1 && smmIRMayConsume($item[black rose pentacle],1) && smmIRPaidRemaining()>0) {
                location [int] zones={$location[The Hidden Temple],$location[The Black Forest],$location[The Unquiet Garves],$location[The Batrat and Ratbat Burrow]};
                item [int] prizes={$item[stone wool],$item[black picnic basket],$item[poltergeist-in-the-jar-o],$item[Dogsgotnonoz pills]};
                foreach j, zone in zones if (can_adventure(zone)) {
                    SmmIRWork lucky=smmIRCopyWork(work); lucky.zone=zone; lucky.ingredient1=prizes[j]; lucky.product=$item[black rose pentacle];
                    lucky.allowed_turns=1; lucky.counter="fountain.lucky"; lucky.expected_adventures=j==0 ? 3 : 1;
                    smmIRAdd(id+".lucky."+zone.to_int(),"Garden fountain Lucky at "+zone,lucky,smmIRRewardValue(prizes[j],lucky.expected_adventures),
                        smmIRInputValue(lucky.product)+smmIRTurnValue(),"route.item."+lucky.product.to_int(),1);
                }
            }
            for option from 1 to 2 {
                effect buff=option==1 ? $effect[Black Rosacea] : $effect[Black Rose Guardin'];
                int price=option==1 ? 1 : 1000;
                float premium=smmIRSetting("gardenBuffValue."+buff.to_int(),0);
                if (have_effect(buff)>0 || my_meat()<price || premium<=price) continue;
                SmmIRWork gift=smmIRCopyWork(work); gift.counter=option==1 ? "fountain.hp" : "fountain.init";
                gift.expected_adventures=option;
                smmIRAdd(id+".buff."+option,"Garden fountain: "+buff,gift,0,price,"route.meat",price);
                smmIRGoal(id+".buff."+option,"garden.buff."+buff.to_int(),premium);
            }
        }
    }
    if (get_property("demonName15")=="" && ((get_campground() contains $item[black garden rose]) || available_amount($item[black garden rose])>0)
        && boolean_modifier("Adventure Underwater") && (get_property("questS02Monkees")=="finished" || get_property("questS02Monkees")=="step12"
            || get_property("questS02Monkees")=="step11" || get_property("questS02Monkees")=="step10" || get_property("questS02Monkees")=="step9")) {
        SmmIRWork work; work.kind="extra.garden.demon";
        smmIRAdd("2026-10.demon","Unlock the garden puzzle's permanent demon name",work,0,0,"",0); smmIRUtility("2026-10.demon");
    }
}

string smmIRBlessingType(monster foe) {
    // Mixed attacks can produce a different blessing. Only model a uniform
    // attack element, and confirm the actual received flag after the fight.
    if (count(foe.attack_elements)>1 || foe.defense_element!=foe.attack_element) return "";
    string type=foe.attack_element.to_string();
    return type=="none" ? "Physical" : type=="hot" ? "Hot" : type=="cold" ? "Cold" : type=="spooky" ? "Spooky" : type=="stench" ? "Stench" : type=="sleaze" ? "Sleaze" : "";
}

effect smmIRBlessingEffect(string type) {
    switch (type) {
    case "Physical": return $effect[Blessing of the Wind Shield];
    case "Hot": return $effect[Blessing of the Heat Shield];
    case "Cold": return $effect[Blessing of the Riot Shield];
    case "Spooky": return $effect[Blessing of the Mental Shield];
    case "Stench": return $effect[Blessing of the Privacy Shield];
    case "Sleaze": return $effect[Blessing of the Tax Shield];
    }
    return $effect[none];
}

boolean smmIRMaidenSafe(monster foe, int attack, int hp) {
    return foe!=$monster[none] && !foe.boss && foe.base_attack>0 && foe.poison==$effect[none]
        && smmIRBlessingType(foe)!="" && hp>max(100,4*max(attack,foe.base_attack)+100);
}

void smmIRGenerateMaidenCarrier(SmmIRWork carrier, string suffix) {
    monster foe=carrier.foe;
    string type=smmIRBlessingType(foe);
    if (type=="" || get_property("_blessingShield"+type+"Received").to_boolean() || have_effect(smmIRBlessingEffect(type))>0 || !smmIRMaidenSafe(foe,foe.base_attack+monster_level_adjustment(),my_hp())) return;
    SmmIRWork work=smmIRCopyWork(carrier); work.kind="extra.maiden"; work.cast=to_skill(7597); work.counter=type;
    work.companion=$familiar[Meat Shield Maiden]; work.companion_equipment=familiar_equipped_equipment(work.companion);
    if (available_amount($item[can of shield tenderizer])>0) work.companion_equipment=$item[can of shield tenderizer];
    float direct=smmIRCombatValue(foe,work);
    // Price the hit as restoration, not as a permanent tier upgrade. A blessing
    // lasts 50 adventures; the next day's cast can produce a different tier.
    float cost=max(0,smmIRSetting("hpValue",1))*max(1,2*(foe.base_attack+max(0,monster_level_adjustment())));
    float benefit;
    if (type=="Sleaze") {
        float base; int fights;
        foreach zone, ignored in smmIRZones if (smmIRZoneIncome(zone)>smmIRTurnValue()+max(0,smmIRSetting("combatCost",50))) {
            float weighted;
            foreach mob, rate in appearance_rates(zone) if (mob!=$monster[none] && rate>0) weighted+=rate/100.0*meat_drop(mob);
            base=max(base,weighted*zone.combat_percent/100.0); fights=min(49,smmIRPaidRemaining());
        }
        benefit=base*0.05*fights; // minimum possible tier, never pretend a 50% buff
    }
    string id="2026-09.blessing."+type+"."+suffix;
    smmIRAdd(id,"Maiden "+type+" blessing on "+foe,work,direct+benefit,cost,carrier.choice_id==1463 ? "route.locket" : "route.garden."+carrier.option,1);
    if (smmIRActions contains id) {
        smmIRActions[id].costs["maiden."+type.to_lower_case()]=1;
        if (carrier.choice_id==1463) smmIRActions[id].costs["route.foe."+foe.to_int()]=1;
        smmIRGoal(id,"blessing."+type,max(0,smmIRSetting("blessingValue."+type,0)));
    }
}

void smmIRGenerateMaiden() {
    if (!have_familiar($familiar[Meat Shield Maiden]) || my_adventures()<1 || my_mp()<30) return;
    foreach i, point in smmIRGarden if (!point.done && point.reachable && point.kind=="monster" && (smmIRChosenGarden=="" || smmIRChosenGarden==my_garden_type())) {
        SmmIRWork carrier; carrier.choice_id=1637; carrier.foe=to_monster(replace_string(point.label,"Fight ","")); carrier.option=point.id;
        carrier.parameters="rgpoi="+point.id+"&rgx="+point.x+"&rgy="+point.y+"&rgf=0";
        smmIRGenerateMaidenCarrier(carrier,"garden."+point.id);
    }
    if (my_familiar()==$familiar[Meat Shield Maiden] && have_effect($effect[Singing of your Prowess])==0 && my_mp()>=mp_cost(to_skill(7598))) {
        float premium=max(0,smmIRSetting("maidenSongValue",0));
        float cost=mp_cost(to_skill(7598))*max(0,smmIRSetting("mpValue",1));
        if (premium>cost) {
            SmmIRWork song; song.kind="extra.maiden.song"; song.cast=to_skill(7598);
            smmIRAdd("2026-09.song","Maiden song for explicitly valued Monster Level",song,0,cost,"",0);
            smmIRGoal("2026-09.song","maiden.song",premium);
        }
    }
    if (available_amount($item[combat lover's locket])>0 && count(cllMonstersFought(false))<3) {
        int [string] admitted;
        foreach foe, available in get_locket_monsters() if (available) {
            string type=smmIRBlessingType(foe);
            if (admitted[type]>=2 || !smmIRMaidenSafe(foe,foe.base_attack+monster_level_adjustment(),my_hp())) continue;
            SmmIRWork carrier; carrier.choice_id=1463; carrier.foe=foe;
            smmIRGenerateMaidenCarrier(carrier,"locket."+foe.to_int()); admitted[type]+=1;
        }
    }
}

void smmIRGenerateMoreCoins() {
    coinmaster shop=$coinmaster[Spend your Interesting Coins];
    int balance=item_amount($item[Interesting Coin]);
    if (balance<2) return;
    item [int] inflation={$item[homeowner's loam],$item[housing bubble],$item[balance sheet]};
    foreach i, it in inflation {
        int price=smmIRShopPrice(shop,it);
        int reserve=max(1,smmIRSetting("coinReserve",10000000).to_int());
        if (price<1 || balance-price<reserve) continue;
        SmmIRWork work; work.kind="extra.coin.sale"; work.product=it;
        smmIRAdd("2026-08.inflation."+it.to_int(),"Convert surplus coins at current inflationary price: "+it,work,smmIRRewardValue(it),price*max(0,smmIRSetting("coinValue",0)),"route.coins",price);
    }
    foreach it in $items[underdraft protection,401k gold ring,hedge fund clippers,financial instrument,selling shorts] {
        int price=smmIRShopPrice(shop,it);
        if (price<1 || balance-price<max(1,smmIRSetting("coinReserve",10000000).to_int()) || available_amount(it)>0
            || get_property("itemBoughtPerAscension"+it.to_int()).to_boolean()) continue;
        SmmIRWork work; work.kind="extra.coin.unique"; work.product=it;
        string id="2026-08.unique."+it.to_int();
        smmIRAdd(id,"Acquire missing unique coin equipment: "+it,work,0,price*max(0,smmIRSetting("coinValue",0)),"route.coins",price);
        smmIRGoal(id,"coin.equipment."+it.to_int(),max(0,smmIRSetting("coinEquipmentValue",0)));
    }
    // The default 10M reserve earmarks principal for this familiar; otherwise
    // the 16,777,215 item cap would make spending 10M above a 10M reserve impossible.
    if ((smmMuseumEnabled() && smmMuseumNeedsCopy($item[gross prophet chrysalis]))
        || (!smmMuseumEnabled() && !have_familiar($familiar[Gross Prophet]) && item_amount($item[gross prophet chrysalis])==0)) {
        int reserve=get_property("smm.IR.coinReserve")=="" ? 1 : max(1,smmIRSetting("coinReserve",10000000).to_int());
        int price=smmIRShopPrice(shop,$item[gross prophet chrysalis]);
        if (price>0 && balance-price>=reserve) {
            SmmIRWork work; work.kind=smmMuseumEnabled() ? "extra.coin.collection" : "extra.coin.prophet"; work.product=$item[gross prophet chrysalis]; work.option=reserve;
            smmIRAdd("2026-08.00-prophet",smmMuseumEnabled() ? "Acquire a Gross Prophet chrysalis for the Museum" : "Complete the earmarked Gross Prophet familiar goal",work,smmMuseumEnabled() ? smmIRRewardValue(work.product) : 0,price*max(0,smmIRSetting("coinValue",0)),"route.coinWallet",price);
            if (!smmMuseumEnabled()) smmIRGoal("2026-08.00-prophet","familiar.gross-prophet",max(0,smmIRSetting("grossProphetValue",1)));
        }
    }
}

void smmIRExtraGenerate() {
    smmIRGenerateMoreAcorns(); smmIRGenerateMoreGarden(); smmIRGenerateMaiden(); smmIRGenerateMoreCoins();
}

boolean smmIRGardenEnter(SmmIRWork work) {
    SmmIRGardenPoint [int] points=smmIRParseGarden(smmIRVisit("campground.php?action=rosegarden"));
    if (!handling_choice() || last_choice()!=1637 || !(points contains work.option) || points[work.option].done || !points[work.option].reachable) {
        smmIRLeaveChoice(1637,2); return false;
    }
    run_choice(1,work.parameters); return true;
}

boolean smmIRGardenRefresh(int point) {
    if (current_round()>0 || (handling_choice() && last_choice()!=1637)) return false;
    smmIRGarden=smmIRParseGarden(smmIRVisit("campground.php?action=rosegarden")); smmIRLeaveChoice(1637,2);
    return (smmIRGarden contains point) && smmIRGarden[point].done;
}

string smmIRMaidenPrefix(monster foe) {
    if (my_familiar()!=$familiar[Meat Shield Maiden] || foe.to_int()!=get_property("smm.IR.seedMonster").to_int()) return "";
    string type=smmIRBlessingType(foe);
    if (type=="" || get_property("_blessingShield"+type+"Received").to_boolean() || have_effect(smmIRBlessingEffect(type))>0 || !smmIRMaidenSafe(foe,monster_attack(),my_hp())
        || smmRPSpendable("maiden."+type.to_lower_case(),smmIROwner,smmIRPools(),smmRPReservations())<1) return "";
    set_property("smm.IR.combatSkill","");
    return "if hasskill 7597;skill 7597;endif;";
}

boolean smmIRExtraDispatch(SmmIRWork work) {
    if (work.kind=="extra.garden.demon") {
        if (get_property("demonName15")!="") return false;
        smmIRVisit("monkeycastle.php?action=grandpastory&topic=Gulrosa+the+Black");
        return get_property("demonName15")!="";
    }
    if (work.kind.starts_with("extra.coin.")) {
        int price=smmIRShopPrice($coinmaster[Spend your Interesting Coins],work.product);
        int reserve=(work.kind=="extra.coin.prophet" || work.kind=="extra.coin.collection") && get_property("smm.IR.coinReserve")=="" ? 1 : max(1,smmIRSetting("coinReserve",10000000).to_int());
        if (work.kind=="extra.coin.prophet" && (have_familiar($familiar[Gross Prophet]) || item_amount(work.product)>0)) return false;
        if (work.kind=="extra.coin.unique" && (available_amount(work.product)>0 || get_property("itemBoughtPerAscension"+work.product.to_int()).to_boolean())) return false;
        if (price<1 || item_amount($item[Interesting Coin])-price<reserve) return false;
        int before=item_amount(work.product); int coins=item_amount($item[Interesting Coin]);
        buy($coinmaster[Spend your Interesting Coins],1,work.product);
        boolean bought=item_amount(work.product)>before && item_amount($item[Interesting Coin])<coins;
        if (!bought) return false;
        smmIRVisit("shop.php?whichshop=interesting"); // refresh inflation before replanning
        if (work.kind=="extra.coin.prophet") return use(1,work.product) && have_familiar($familiar[Gross Prophet]);
        return true;
    }
    if (work.kind=="extra.maiden.song") {
        if (my_familiar()!=$familiar[Meat Shield Maiden] || have_effect($effect[Singing of your Prowess])>0) return false;
        return smmIRCast(to_skill(7598)) && have_effect($effect[Singing of your Prowess])>0;
    }
    if (work.kind=="extra.maiden") {
        if (get_property("_blessingShield"+work.counter+"Received").to_boolean() || have_effect(smmIRBlessingEffect(work.counter))>0
            || smmRPSpendable("maiden."+work.counter.to_lower_case(),smmIROwner,smmIRPools(),smmRPReservations())<1) return false;
        if (!use_familiar(work.companion) || !equip($slot[familiar],work.companion_equipment)) return false;
        if (!smmIRMaidenSafe(work.foe,work.foe.base_attack+monster_level_adjustment(),my_hp())) return false;
        set_property("smm.IR.seedMonster",work.foe.to_int()); set_property("smm.IR.combatSkill",7597);
        if (work.choice_id==1463) {
            if (!get_locket_monsters()[work.foe]) return false;
            cli_execute("reminisce "+work.foe.to_int());
        } else if (!smmIRGardenEnter(work)) return false;
        if (current_round()>0) run_combat();
        boolean received=get_property("_blessingShield"+work.counter+"Received").to_boolean() && have_effect(smmIRBlessingEffect(work.counter))>0;
        if (work.choice_id==1637) received=smmIRGardenRefresh(work.option) && received;
        return received && current_round()==0;
    }
    if (work.kind=="extra.acorn") {
        if (smmIRPlantSlots(work.zone)<1 || smmIRAcornEffects(work.zone).contains_text(work.parameters)
            || smmRPSpendable("acorn.plants",smmIROwner,smmIRPools(),smmRPReservations())<1 || !smmIREquip($item[legendary acorndion]) || !have_skill(work.cast)) return false;
        string before=smmIRAcornEffects(work.zone); int count_before=get_property("_legendaryAcornsUsed").to_int(); int start=smmIRTurns();
        set_property("smm.IR.plantZone",work.zone); set_property("smm.IR.plantEffect",work.parameters);
        set_property("smm.IR.plantTarget",work.foe.to_int()); set_property("smm.IR.combatSkill",work.cast.to_int());
        for attempt from 1 to work.allowed_turns+3 {
            if (smmIRTurns()-start>=work.allowed_turns || my_adventures()<1 || my_hp()<my_maxhp()/3 || my_mp()<30) break;
            if (smmIRZoneIncome(work.zone)<=smmIRTurnValue()+max(0,smmIRSetting("combatCost",50))) break;
            if (!smmIRAdventure(work.zone) || handling_choice() || current_round()>0) break;
        }
        return get_property("_legendaryAcornsUsed").to_int()>count_before && !before.contains_text(work.parameters) && smmIRAcornEffects(work.zone).contains_text(work.parameters);
    }
    if (work.kind=="extra.garden") {
        if (work.counter=="chest") {
            if (!smmIRMayConsume($item[black thorn key],1)) return false;
            int keys=item_amount($item[black thorn key]);
            if (!smmIRGardenEnter(work)) return false;
            return smmIRGardenRefresh(work.option) && item_amount($item[black thorn key])<keys;
        }
        boolean lucky=work.counter=="fountain.lucky";
        if (!lucky && have_effect(work.counter=="fountain.hp" ? $effect[Black Rosacea] : $effect[Black Rose Guardin'])>0) return false;
        if (lucky && (have_effect($effect[Lucky!])>0 || !smmIRMayConsume($item[black rose pentacle],1))) return false;
        int coins=item_amount($item[black rose pentacle]); int reward=item_amount(work.ingredient1);
        if (!smmIRGardenEnter(work) || !handling_choice() || last_choice()!=1639) return false;
        string token=lucky ? "black rose coin" : work.counter=="fountain.hp" ? "1 Meat" : "1,000 Meat";
        int option=smmIRChoiceContaining(available_choice_options(),token);
        if (option==0) { int leave=smmIRChoiceContaining(available_choice_options(),"leave"); if (leave>0) run_choice(leave); smmIRLeaveChoice(1637,2); return false; }
        run_choice(option);
        boolean done=smmIRGardenRefresh(work.option);
        if (!done) return false;
        if (!lucky) return have_effect(work.counter=="fountain.hp" ? $effect[Black Rosacea] : $effect[Black Rose Guardin'])>0;
        if (item_amount($item[black rose pentacle])>=coins || have_effect($effect[Lucky!])<1) return false;
        return smmIRAdventure(work.zone) && item_amount(work.ingredient1)>=reward+work.expected_adventures;
    }
    return false;
}
