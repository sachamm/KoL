import <smmUtils.ash>

// Museum rank #1 is preferred; top ten is an intermediate acceptable result.
// Rankings come from the Museum ranking store in smmUtils.ash (kept across days,
// renewed oldest-first by "dc refresh"), never from old case counts.
record SmmMuseumGoal {
    boolean known;
    int first;
    int first_minimum;
    int tenth;
};

SmmMuseumGoal [item] smmMuseumGoals;
int [item] smmMuseumKeeps;

int smmMuseumDisplay(item it) { return display_amount(it); }

boolean smmMuseumEnabled() { return get_property("smm.IR.museum")!="false"; }

int [int,string] smmMuseumLookup(item it) { return lookupCollection(it,false); }
boolean smmMuseumPut(int quantity, item it) { return put_display(quantity,it); }

SmmMuseumGoal smmMuseumBounds(int [int,string] rankings, string player, int buffer_size) {
    SmmMuseumGoal goal;
    if (!isValidTop10List(rankings)) return goal;
    int [int] others;
    foreach rank, name, amount in rankings if (name.to_lower_case()!=player.to_lower_case()) others[count(others)]=amount;
    sort others by value;
    int strongest=count(others)>0 ? others[count(others)-1] : 0;
    goal.known=true;
    goal.first=max(1,strongest+max(1,buffer_size));
    goal.first_minimum=strongest+1;
    goal.tenth=count(others)>=10 ? others[count(others)-10]+1 : 1;
    return goal;
}

SmmMuseumGoal smmMuseumGoal(item it) {
    SmmMuseumGoal goal;
    if (!smmMuseumEnabled() || it==$item[none] || !is_displayable(it)) return goal;
    if (smmMuseumGoals contains it) return smmMuseumGoals[it];
    int [int,string] rankings=smmMuseumCachedCollection(it);
    // The stored ranking is used whatever its age ("dc refresh" renews the oldest).
    // Only an item never looked up costs a request, from the shared daily budget.
    if (!isValidTop10List(rankings) && !smmMuseumStored(it) && smmMuseumLookupsLeft()>0) rankings=smmMuseumLookup(it);
    int buffer_size=get_property("smm.IR.museumBuffer")=="" ? 11 : max(1,get_property("smm.IR.museumBuffer").to_int());
    if (get_property("smm.IR.museumBuffer")=="" && get_property("smm.dcOvershootAmount")!="") buffer_size=max(1,get_property("smm.dcOvershootAmount").to_int());
    goal=smmMuseumBounds(rankings,my_name(),buffer_size);
    // Nobody displays it: there is no list, but the targets are known.
    if (!goal.known && smmMuseumNobodyHas(it)) { goal.known=true; goal.first=buffer_size; goal.first_minimum=1; goal.tenth=1; }
    smmMuseumGoals[it]=goal;
    return goal;
}

int smmMuseumKeep(item it) {
    string explicit=get_property("smm.IR.keepItem."+it.to_int());
    if (explicit!="") return max(0,explicit.to_int());
    if (!(smmMuseumKeeps contains it)) smmMuseumKeeps[it]=max(0,saveAmount(it));
    return smmMuseumKeeps[it];
}

int smmMuseumStock(item it) {
    // Keep worn gear and shop listings out of committed Display Case stock.
    return max(0,item_amount(it)+closet_amount(it)+storage_amount(it)-smmMuseumKeep(it));
}

int smmMuseumMissing(item it, SmmMuseumGoal goal) {
    return goal.known ? max(0,goal.first-smmMuseumDisplay(it)-smmMuseumStock(it)) : 0;
}

boolean smmMuseumNeedsCopy(item it) {
    if (!smmMuseumEnabled() || it==$item[none] || !is_displayable(it)) return false;
    SmmMuseumGoal goal=smmMuseumGoal(it);
    return !goal.known || smmMuseumMissing(it,goal)>0;
}

float smmMuseumMoney(item it, int quantity, float sale, float replacement) {
    if (quantity<=0) return 0;
    if (!smmMuseumEnabled()) return quantity*sale;
    SmmMuseumGoal goal=smmMuseumGoal(it);
    if (!goal.known || replacement<=0) return quantity*sale;
    int direct=min(quantity,smmMuseumMissing(it,goal));
    // A copy is either retained (avoided purchase) or sold, never both.
    return direct*max(sale,replacement)+(quantity-direct)*sale;
}

float smmMuseumInput(item it, int quantity, float sale, float replacement) {
    if (!smmMuseumEnabled() || !is_displayable(it)) return quantity*sale;
    SmmMuseumGoal goal=smmMuseumGoal(it);
    int surplus=goal.known ? max(0,smmMuseumDisplay(it)+smmMuseumStock(it)-goal.first) : 0;
    int needed=max(0,quantity-surplus);
    if (needed>0 && replacement<=0) return 1000000000.0;
    return (quantity-needed)*sale+needed*max(sale,replacement);
}

float smmMuseumProgress(item it, float quantity) {
    if (!smmMuseumEnabled() || quantity<=0 || it==$item[none] || !is_displayable(it)) return 0;
    SmmMuseumGoal goal=smmMuseumGoal(it);
    if (!goal.known) return 0;
    int stock=smmMuseumDisplay(it)+smmMuseumStock(it);
    int missing=max(0,goal.first_minimum-stock);
    if (missing<1) return 0;
    int milestone=stock<goal.tenth ? goal.tenth : goal.first_minimum;
    float rank_value=get_property("smm.IR.museumRankValue")=="" ? max(0,kTurnValue) : max(0,get_property("smm.IR.museumRankValue").to_float());
    return rank_value*min(quantity,max(0,milestone-stock))/max(1,milestone-stock);
}

int smmMuseumHeld(item it) {
    if (!smmMuseumEnabled()) return 0;
    int held=min(item_amount(it),max(0,get_property("smm.IR.museumHold."+it.to_int()).to_int()));
    if (held<1) return 0;
    SmmMuseumGoal goal=smmMuseumGoal(it);
    if (goal.known) {
        held=min(held,max(0,goal.first-smmMuseumDisplay(it)));
        set_property("smm.IR.museumHold."+it.to_int(),held);
    }
    return held;
}

int smmMuseumDepositAmount(item it) {
    if (!smmMuseumEnabled() || !have_display() || get_property("smm.IR.museumDeposit")=="false") return 0;
    SmmMuseumGoal goal=smmMuseumGoal(it);
    if (goal.known) smmMuseumHeld(it);
    return goal.known ? min(max(0,item_amount(it)-smmMuseumKeep(it)),max(0,goal.first-smmMuseumDisplay(it))) : 0;
}

int smmMuseumConsumptionReserve(item it) {
    // Rated copies can compete between placement and profitable conversion.
    // Unrated earmarked stock must wait for a usable Museum snapshot.
    return smmMuseumGoal(it).known ? 0 : smmMuseumHeld(it);
}

int smmMuseumMilestone(item it) {
    SmmMuseumGoal goal=smmMuseumGoal(it);
    int current=smmMuseumDisplay(it);
    return current<goal.tenth ? goal.tenth : current<goal.first_minimum ? goal.first_minimum : goal.first;
}

boolean smmMuseumDeposit(item it, int quantity) {
    if (quantity<1 || quantity>smmMuseumDepositAmount(it)) return false;
    int previous=smmMuseumDisplay(it);
    if (!smmMuseumPut(quantity,it) || smmMuseumDisplay(it)<previous+quantity) return false;
    set_property("smm.IR.museumHold."+it.to_int(),max(0,get_property("smm.IR.museumHold."+it.to_int()).to_int()-quantity));
    set_property("smm.IR.lastMuseumDeposit",get_property("smm.IR.lastMuseumDeposit")+it.to_int()+":"+quantity+";");
    print("Museum: added "+quantity+" "+it+"; case now "+smmMuseumDisplay(it),"blue");
    return true;
}

void smmMuseumRetainGains(int [item] before) {
    if (!smmMuseumEnabled()) return;
    foreach it, amount in get_inventory() {
        int gained=max(0,amount-before[it]);
        if (gained<1 || !is_displayable(it)) continue;
        SmmMuseumGoal goal=smmMuseumGoal(it);
        int previous_hold=smmMuseumHeld(it);
        if (goal.known && smmMuseumDisplay(it)>=goal.first) continue; // surplus stays available for Meat funding
        int held=previous_hold+gained;
        if (goal.known) held=min(held,max(0,goal.first-smmMuseumDisplay(it)));
        set_property("smm.IR.museumHold."+it.to_int(),min(item_amount(it),held));
        // Placement is a competing worker in the next solve. Do not deposit
        // noodles/ingredients before comparing their more valuable conversions.
    }
}

void smmMuseumReport(item it) {
    SmmMuseumGoal goal=smmMuseumGoal(it);
    print("Museum objective: #1 preferred, top 10 acceptable. Item: "+it,"blue");
    if (!goal.known) { print("Museum rankings unavailable; rank progress is unpriced and new route copies remain reserved.","orange"); return; }
    print("In Display Case: "+smmMuseumDisplay(it)+"; eligible owned stock: "+smmMuseumStock(it)+"; operating reserve: "+smmMuseumKeep(it));
    print("Strict first-place target with buffer: "+goal.first+"; top-ten threshold: "+goal.tenth+"; additional acquisitions needed: "+smmMuseumMissing(it,goal));
}


// ---------------------------------------------------------------- owned copies
// Spending a copy you own (eating it, crafting with it, selling it) is not free:
// until you are #1 for that item, every copy you hold is collection stock.
// Only copies beyond the #1 target (with buffer) are spare, and a spare copy is
// worth what you could otherwise get for it (mall, a conversion or autosell).
// Making a NEW copy always costs its inputs: use smmItemValue() for that.

// Copies that can be spent without hurting the Museum goal. Items with no usable
// ranking snapshot have no spare copies: they stay reserved until one exists.
int smmMuseumSpareCopies(item it) {
    int owned=smmMuseumOwnedCopies(it);
    if (!smmMuseumEnabled() || !is_displayable(it)) return owned;
    if (!smmMuseumGoal(it).known) return 0; // budgeted lookup; fills the shared ranking cache
    return max(0,owned-smmMuseumReservedCopies(it,false)); // same rule as the museumSafe* guards
}

// What it costs to spend `quantity` owned copies. Spare copies cost their
// realizable value. Copies the Museum still needs cost their replacement price:
// smm.IR.museumCopyValue.<id>, else the mall price; an untradeable copy with
// neither is effectively priceless (1,000,000,000 Meat), so it is never spent.
float smmMuseumOwnedValue(item it, int quantity) {
    if (quantity<=0) return 0;
    float sale=smmItemLiquidValue(it);
    string explicit=get_property("smm.IR.museumCopyValue."+it.to_int());
    float replacement=explicit!="" ? explicit.to_float() : (it.tradeable ? smmItemValue(it) : 0);
    return smmMuseumInput(it,quantity,sale,replacement);
}

// Bridge for JavaScript, which cannot require() these symlinked ASH files:
// "id,id,..." -> "id:spare:liquidValue;..." for each item.
string smmMuseumSpareList(string ids) {
    buffer out;
    foreach i, id in split_string(ids,",") {
        if (id=="") continue;
        item it=id.to_int().to_item();
        if (it==$item[none]) continue;
        out.append(it.to_int()+":"+smmMuseumSpareCopies(it)+":"+round(smmItemLiquidValue(it))+";");
    }
    return out.to_string();
}
