import <smmIotmRouteCore.ash>
import <smmIotmRouteExtras.ash>

record SmmIRGardenModel {
    string type;
    item seed;
    boolean owned;
    boolean known;
    boolean installed;
    float horizon_value;
    float switching_cost;
    string reason;
};

SmmIRGardenModel [string] smmIRGardenModels;
float [string] smmIRGardenMemo;
int smmIRGardenHorizon;

int smmIRGardenDays(string since) {
    if (since=="") return 100000;
    return max(0,round((date_to_timestamp("yyyyMMdd",today_to_string())-date_to_timestamp("yyyyMMdd",since))/86400000.0));
}

void smmIRGardenBreakfast(boolean managed) {
    if (managed) {
        if (!get_property("smm.IR.gardenBreakfastManaged").to_boolean()) {
            set_property("smm.IR.gardenBreakfastPreference",get_property("harvestGardenSoftcore"));
            set_property("smm.IR.gardenBreakfastManaged",true);
        }
        set_property("harvestGardenSoftcore","none");
    } else if (get_property("smm.IR.gardenBreakfastManaged").to_boolean()) {
        set_property("harvestGardenSoftcore",get_property("smm.IR.gardenBreakfastPreference"));
        set_property("smm.IR.gardenBreakfastManaged",false);
    }
}

boolean smmIRGardenMayChange() {
    if (get_property("smm.IR.gardenChangeDate")==today_to_string() || get_property("smm.IR.gardenAttemptDate")==today_to_string()) return false;
    if (get_property("smm.IR.gardenHoldAscension")==my_ascensions().to_string()
        && smmIRGardenDays(get_property("smm.IR.gardenHoldStart"))<get_property("smm.IR.gardenHoldDays").to_int()) return false;
    return true;
}

record SmmIRGardenYield { item product; int quantity; };

SmmIRGardenYield smmIRGardenYield(string type, int age, int plot) {
    SmmIRGardenYield out;
    if (age<1) return out;
    out.quantity=1;
    if (type=="thanksgarden") {
        int [int] quantities={0,1,3,5,8,11,15};
        out.product=age>=7 ? $item[megacopia] : $item[cornucopia]; out.quantity=age>=7 ? 1 : quantities[age];
    } else if (type=="rock") {
        item [int] small={$item[groveling gravel],$item[milestone],$item[whet stone]};
        item [int] medium={$item[fruity pebble],$item[bolder boulder],$item[hard rock]};
        item [int] large={$item[lodestone],$item[molehill mountain],$item[strange stalagmite]};
        out.product=age>=7 ? large[plot] : age>=4 ? medium[plot] : small[plot]; out.quantity=age>=7 ? 1 : age>=4 ? age-3 : age;
    } else if (type=="mushroom") {
        item [int] sizes={$item[none],$item[free-range mushroom],$item[plump free-range mushroom],$item[bulky free-range mushroom],$item[giant free-range mushroom],$item[immense free-range mushroom]};
        out.product=age>=11 ? $item[colossal free-range mushroom] : sizes[min(5,age)];
    } else if (type=="pumpkin") { out.product=age>=11 ? $item[ginormous pumpkin] : age>=5 ? $item[huge pumpkin] : $item[pumpkin]; out.quantity=age>=5 ? 1 : age; }
    else if (type=="peppermint") { out.product=age>=5 ? $item[giant candy cane] : $item[peppermint sprout]; out.quantity=age>=5 ? 1 : age*3; }
    else if (type=="skeleton" && age<6) { out.product=$item[skeleton]; out.quantity=age*5; }
    else if (type=="beer") { out.product=age<3 ? $item[handful of barley] : $item[fancy beer label]; out.quantity=age<3 ? age*3 : (age-1)/2; }
    else if (type=="winter") { out.product=age<3 ? $item[ice harvest] : $item[frost flower]; out.quantity=age<3 ? age*3 : 1; }
    return out;
}

float smmIRGrassValue(int age, boolean collection, boolean progress) {
    if (age<1) return 0;
    item [int] outputs;
    if (age>=8) outputs={$item[Unspeakachu],$item[Stooper],$item[Disgeist],$item[Bowlet],$item[Cornbeefadon],$item[Mu]};
    else outputs={$item[amulet coin],$item[luck incense],$item[muscle band],$item[razor fang],$item[shell bell],$item[smoke ball],$item[Egnaro berry],$item[Glum berry],$item[Jamocha berry],$item[Keese berry],$item[Nadsat berry],$item[Sitrep berry],$item[Snarf berry],$item[Tapioc berry],$item[Mu]};
    float lowest=1000000000.0; int quantity=age>=8 ? 1 : age;
    foreach i, it in outputs lowest=min(lowest,progress ? smmMuseumProgress(it,quantity) : collection ? smmIRRewardValue(it,quantity) : quantity*smmIRSaleValue(it));
    return lowest;
}

float smmIRGardenHarvestValue(string type, int age, int plot) {
    if (type=="grass") return smmIRGrassValue(age,true,false);
    SmmIRGardenYield out=smmIRGardenYield(type,age,plot);
    return out.product==$item[none] ? 0 : smmIRRewardValue(out.product,out.quantity);
}

float smmIRGardenHarvestScore(string type, int age, int plot, boolean collection) {
    if (type=="grass") return smmIRGrassValue(age,collection,false)+(collection ? smmIRGrassValue(age,true,true) : 0);
    SmmIRGardenYield out=smmIRGardenYield(type,age,plot);
    if (out.product==$item[none]) return 0;
    return collection ? smmIRRewardValue(out.product,out.quantity)+smmMuseumProgress(out.product,out.quantity) : out.quantity*smmIRSaleValue(out.product);
}

int smmIRGardenMaxAge(string type) { return type=="grass" ? 8 : (type=="mushroom" || type=="pumpkin") ? 11 : type=="skeleton" ? 6 : type=="peppermint" ? 5 : 7; }

// Finite-horizon dynamic programming: harvest versus grow, one selected crop.
// Rock plots have independent harvest resets, but never extra garden slots.
float smmIRGardenFutureInner(string type, int age, int days, int plot, boolean collection) {
    if (days<1) return 0;
    age=min(smmIRGardenMaxAge(type),max(type=="mushroom" ? 1 : 0,age));
    string key=type+":"+age+":"+days+":"+plot+":"+collection;
    if (smmIRGardenMemo contains key) return smmIRGardenMemo[key];
    float grow=smmIRGardenFutureInner(type,min(smmIRGardenMaxAge(type),age+1),days-1,plot,collection);
    float pick=smmIRGardenHarvestScore(type,age,plot,collection)+smmIRGardenFutureInner(type,1,days-1,plot,false);
    float result=max(grow,pick);
    smmIRGardenMemo[key]=result; return result;
}

float smmIRGardenFuture(string type, int age, int days, int plot) {
    return smmIRGardenFutureInner(type,age,days,plot,true);
}

boolean smmIRGardenShouldPick(string type, int age, int plot) {
    if (age<1) return false;
    float pick=smmIRGardenHarvestScore(type,age,plot,true)+smmIRGardenFutureInner(type,1,max(0,smmIRGardenHorizon-1),plot,false);
    float wait=smmIRGardenFuture(type,min(smmIRGardenMaxAge(type),age+1),max(0,smmIRGardenHorizon-1),plot);
    return pick>=wait;
}

int smmIRRockAge(int plot) {
    int [item] camp=get_campground();
    item [int] small={$item[groveling gravel],$item[milestone],$item[whet stone]};
    item [int] medium={$item[fruity pebble],$item[bolder boulder],$item[hard rock]};
    item [int] large={$item[lodestone],$item[molehill mountain],$item[strange stalagmite]};
    if (camp contains large[plot]) return 7;
    if (camp contains medium[plot]) return 3+camp[medium[plot]];
    return camp[small[plot]];
}

float smmIRRoseLayout(boolean remaining_only) {
    float value;
    foreach i, point in smmIRGarden {
        if (remaining_only && (point.done || !point.reachable)) continue;
        if (remaining_only && point.kind=="monster" && (my_adventures()<1 || my_mp()<30 || my_hp()<my_maxhp()/3)) continue;
        if (point.kind=="food") value+=remaining_only ? smmIRRewardValue($item[black rose bowl])+smmMuseumProgress($item[black rose bowl],1) : smmIRSaleValue($item[black rose bowl]);
        else if (point.kind=="booze") value+=remaining_only ? smmIRRewardValue(to_item("black garden rosé"))+smmMuseumProgress(to_item("black garden rosé"),1) : smmIRSaleValue(to_item("black garden rosé"));
        else if ((point.kind=="incense" || point.kind=="spleen")) value+=remaining_only ? smmIRRewardValue($item[clove incense])+smmMuseumProgress($item[clove incense],1) : smmIRSaleValue($item[clove incense]);
        else if (point.kind=="monster") {
            monster foe=to_monster(replace_string(point.label,"Fight ",""));
            if (foe!=$monster[none]) {
                SmmIRWork gear=smmIRCombatLoadout(foe); gear.kind="garden"; gear.foe=foe;
                value+=max(0,(remaining_only ? smmIRCombatValue(foe,gear)+smmIRWorkProgress(gear) : smmIRCashLoot(foe,item_drop_modifier())+meat_drop(foe))-max(0,smmIRSetting("combatCost",50)));
            }
        }
    }
    return value;
}

void smmIRGardenEvaluate(boolean commit) {
    clear(smmIRGardenModels); clear(smmIRGardenMemo);
    smmIRGardenHorizon=max(1,min(60,smmIRSetting("gardenHorizon",14).to_int()));
    string current=my_garden_type(); int [item] camp=get_campground();
    string observed=get_property("smm.IR.gardenObservedType");
    boolean external_change=get_property("smm.IR.gardenObservedDate")==today_to_string() && observed!="" && observed!=current;
    if (commit) {
        smmIRGardenBreakfast(true);
        if (external_change)
            set_property("smm.IR.gardenChangeDate",today_to_string());
        set_property("smm.IR.gardenObservedDate",today_to_string()); set_property("smm.IR.gardenObservedType",current);
    }
    string [int] types={"black_rose","rock","mushroom","grass","thanksgarden"};
    item [int] seeds={$item[black garden rose],$item[packet of rock seeds],$item[packet of mushroom spores],$item[packet of tall grass seeds],$item[packet of thanksgarden seeds]};
    foreach i, type in types {
        SmmIRGardenModel model; model.type=type; model.seed=seeds[i]; model.installed=current==type;
        model.owned=model.installed || available_amount(model.seed)>0; model.known=true;
        if (!model.owned) { model.reason="seed not owned/accessible"; smmIRGardenModels[type]=model; continue; }
        if (type=="black_rose") {
            float configured=smmIRSetting("gardenDaily.black_rose",-1);
            if (model.installed && count(smmIRGarden)>0) model.horizon_value=smmIRRoseLayout(true)+max(0,smmIRGardenHorizon-1)*smmIRRoseLayout(false);
            else if (configured>=0) model.horizon_value=max(0,smmIRGardenHorizon-10)*configured; // no growth-day income invented
            else { model.known=false; model.reason="new random maze: future yields unpriced; set gardenDaily.black_rose for a forecast"; }
        } else if (type=="rock") {
            for plot from 0 to 2 model.horizon_value+=smmIRGardenFuture(type,model.installed ? smmIRRockAge(plot) : 0,smmIRGardenHorizon,plot);
        } else if (type=="mushroom") {
            int level=max(1,get_property("mushroomGardenCropLevel").to_int());
            int days=smmIRGardenHorizon-((get_property("_mushroomGardenVisited").to_boolean() || my_adventures()<1) ? 1 : 0);
            model.horizon_value=smmIRGardenFuture(type,level,max(0,days),0)
                +max(0,days)*max(0,smmIRCashLoot($monster[piranha plant],item_drop_modifier())-max(0,smmIRSetting("combatCost",50)));
        } else model.horizon_value=smmIRGardenFuture(type,model.installed ? camp[model.seed] : 0,smmIRGardenHorizon,0);
        if (!model.installed) {
            // Replacing a mature rose garden destroys its layout on rollover.
            // Charge ten days of currently observed income, plus any explicitly
            // valued outfit/puzzle/growth progress, before considering a change.
            if (current=="black_rose") model.switching_cost=10*smmIRRoseLayout(false)+max(0,smmIRSetting("gardenResetValue",0));
            model.switching_cost+=max(0,smmIRSetting("gardenSwitchCost",0));
        }
        smmIRGardenModels[type]=model;
    }
    string [int] older={"pumpkin","peppermint","skeleton","beer","winter"};
    int [int] ids={4760,5404,5880,6751,7070};
    foreach i, type in older if (available_amount(to_item(ids[i]))>0 || current==type) {
        SmmIRGardenModel model; model.type=type; model.seed=to_item(ids[i]); model.owned=true; model.installed=current==type;
        model.known=true;
        model.horizon_value=smmIRGardenFuture(type,model.installed ? camp[model.seed] : 0,smmIRGardenHorizon,0);
        if (!model.installed) {
            if (current=="black_rose") model.switching_cost=10*smmIRRoseLayout(false)+max(0,smmIRSetting("gardenResetValue",0));
            model.switching_cost+=max(0,smmIRSetting("gardenSwitchCost",0));
        }
        smmIRGardenModels[type]=model;
    }
    // Future unrecognized crops are not empty ground worth zero.
    // Pumpkin growth between the huge and ginormous images uses its known lower-bound stage.
    if (!(smmIRGardenModels contains current) && current!="none") {
        SmmIRGardenModel old; old.type=current; old.installed=true; old.owned=true; old.reason="installed older crop has no verified growth model";
        smmIRGardenModels[current]=old;
    }
    smmIRChosenGarden=current;
    boolean locked=get_property("smm.IR.gardenPlanEpoch")==smmRPEpoch();
    if (external_change) {
        smmIRChosenGarden=current;
        if (commit) { set_property("smm.IR.gardenPlan",current); set_property("smm.IR.gardenPlanEpoch",smmRPEpoch()); }
    } else if (locked) smmIRChosenGarden=get_property("smm.IR.gardenPlan");
    else if (smmIRGardenMayChange() && (current=="none" || smmIRGardenModels[current].known)) {
        float best=current=="none" ? 0 : smmIRGardenModels[current].horizon_value;
        foreach type, model in smmIRGardenModels if (model.owned && model.known && !model.installed) {
            if (current=="black_rose" && get_property("smm.IR.allowRoseReset")!="true") continue;
            float net=model.horizon_value-model.switching_cost;
            if (net>best+max(0,smmIRSetting("gardenSwitchMargin",1000))) { best=net; smmIRChosenGarden=type; }
        }
    }
    if (commit && !locked) { set_property("smm.IR.gardenPlanEpoch",smmRPEpoch()); set_property("smm.IR.gardenPlan",smmIRChosenGarden); }
    print("Shared garden slot: "+current+" -> "+smmIRChosenGarden+"; horizon "+smmIRGardenHorizon+" days; one change/day.","blue");
    foreach type, model in smmIRGardenModels if (model.owned)
        print("Garden "+type+": "+(model.known ? "forecast "+round(model.horizon_value)+", reset/switch cost "+round(model.switching_cost)+" objective units" : model.reason)+(model.installed ? " [installed]" : ""),"gray");
}

void smmIRGardenGenerate() {
    string current=my_garden_type();
    if (smmIRChosenGarden=="") smmIRChosenGarden=current;
    if (smmIRChosenGarden!=current) {
        if (!smmIRGardenMayChange() || !(smmIRGardenModels contains smmIRChosenGarden)) return;
        SmmIRGardenModel model=smmIRGardenModels[smmIRChosenGarden];
        if (!model.owned || !model.known) return;
        SmmIRWork work; work.kind="garden.switch"; work.product=model.seed; work.parameters=model.type;
        float baseline=(smmIRGardenModels contains current) ? smmIRGardenModels[current].horizon_value : 0;
        float advantage=max(0,model.horizon_value-model.switching_cost-baseline);
        smmIRAdd("2026-10.00-garden-switch","Select shared garden: "+model.type+" ("+smmIRGardenHorizon+"-day forecast advantage "+round(advantage)+")",work,0,0,"route.gardenChange",1);
        smmIRGoal("2026-10.00-garden-switch","garden.strategy",max(1,advantage)); // future forecast is not today's Meat
        return; // no claims from the unselected installed garden
    }
    if (current=="thanksgarden" || current=="grass" || current=="rock" || current=="pumpkin" || current=="peppermint" || current=="skeleton" || current=="beer" || current=="winter") {
        int [item] camp=get_campground();
        int plots=current=="rock" ? 3 : 1;
        for plot from 0 to plots-1 {
            int age=current=="rock" ? smmIRRockAge(plot) : camp[smmIRGardenModels[current].seed];
            if (smmIRGardenHarvestValue(current,age,plot)<=0 || !smmIRGardenShouldPick(current,age,plot)) continue;
            SmmIRWork work; work.kind="garden.harvest"; work.parameters=current; work.option=plot; work.expected_adventures=age;
            SmmIRGardenYield yield=smmIRGardenYield(current,age,plot); work.product=yield.product; work.choice_id=yield.quantity;
            smmIRAdd("2026-10.01-harvest."+plot,"Harvest selected "+current+" garden"+(plots>1 ? " plot "+(plot+1) : ""),work,smmIRGardenHarvestValue(current,age,plot),0,"route.harvest."+plot,1);
        }
    } else if (current=="mushroom" && !get_property("_mushroomGardenVisited").to_boolean() && my_adventures()>0 && my_mp()>=30 && my_hp()>=my_maxhp()/3) {
        int level=max(1,get_property("mushroomGardenCropLevel").to_int());
        boolean pick=smmIRGardenShouldPick(current,level,0);
        SmmIRWork work=smmIRCombatLoadout($monster[piranha plant]); work.kind="garden.mushroom"; work.option=pick ? 2 : 1; work.expected_adventures=level; work.foe=$monster[piranha plant];
        if (pick) { work.product=smmIRGardenYield(current,level,0).product; work.choice_id=1; }
        smmIRAdd("2026-10.01-mushroom","Selected mushroom garden: free fight and "+(pick ? "harvest" : "fertilize"),work,
            smmIRCombatValue($monster[piranha plant],work)+(pick ? smmIRGardenHarvestValue(current,level,0) : 0),max(0,smmIRSetting("combatCost",50)),"route.mushroom",1);
        if (!pick) smmIRUtility("2026-10.01-mushroom");
    }
}

boolean smmIRGardenDispatch(SmmIRWork work) {
    if (work.kind=="garden.switch") {
        if (!smmIRGardenMayChange() || my_garden_type()==work.parameters || available_amount(work.product)<1) return false;
        set_property("smm.IR.gardenAttemptDate",today_to_string()); // no second attempt even after an ambiguous response
        string before=my_garden_type();
        use(1,work.product); smmIRVisit("campground.php");
        if (my_garden_type()!=work.parameters || my_garden_type()==before) {
            smmIRChosenGarden=my_garden_type(); set_property("smm.IR.gardenPlan",smmIRChosenGarden);
            return false;
        }
        set_property("smm.IR.gardenChangeDate",today_to_string()); set_property("smm.IR.gardenObservedType",work.parameters);
        set_property("smm.IR.gardenHoldStart",today_to_string()); set_property("smm.IR.gardenHoldDays",smmIRGardenHorizon);
        set_property("smm.IR.gardenHoldAscension",my_ascensions());
        clear(smmIRGarden);
        if (work.parameters=="black_rose") { smmIRGarden=smmIRParseGarden(smmIRVisit("campground.php?action=rosegarden")); smmIRLeaveChoice(1637,2); }
        return true;
    }
    if (my_garden_type()!=smmIRChosenGarden) return false;
    if (work.kind=="garden.harvest") {
        int before=work.parameters=="rock" ? smmIRRockAge(work.option) : get_campground()[smmIRGardenModels[work.parameters].seed];
        if (before!=work.expected_adventures || !smmIRGardenShouldPick(work.parameters,before,work.option)) return false;
        string action=work.parameters=="rock" ? "rgarden"+(work.option+1) : "garden";
        int requests=work.parameters=="grass" && before<8 ? before : 1;
        for n from 1 to requests smmIRVisit("campground.php?action="+action);
        smmIRVisit("campground.php");
        int after=work.parameters=="rock" ? smmIRRockAge(work.option) : get_campground()[smmIRGardenModels[work.parameters].seed];
        return after<before;
    }
    if (work.kind=="garden.mushroom") {
        if (my_garden_type()!="mushroom" || get_property("_mushroomGardenVisited").to_boolean()) return false;
        string saved=get_property("choiceAdventure1410");
        try { set_property("choiceAdventure1410",work.option); smmIRAdventure($location[Your Mushroom Garden]); }
        finally { set_property("choiceAdventure1410",saved); }
        return get_property("_mushroomGardenVisited").to_boolean() && current_round()==0 && !handling_choice()
            && get_property("mushroomGardenCropLevel").to_int()==(work.option==2 ? 1 : min(11,work.expected_adventures+1));
    }
    return false;
}

void smmIRBreakfast() {
    if (!inRonin()) smmIRGardenBreakfast(smmIREnabled());
    cli_execute("breakfast");
}
