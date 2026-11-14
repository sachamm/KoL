import <smmResourcePlanner.ash>

// Input is a TSV map: ID, then fields below in declaration order.
record SmmRPRequest {
    string description;
    int limit;
    boolean eligible;
    boolean valued;
    float direct_meat;
    float loot_value;
    float adventure_delta;
    float avoided_cost;
    float input_cost;
    float displaced_value;
    float future_cost;
    string costs; // pool=units,pool=units
    string goal;
    int missing;
    float collection_value;
    string choice_group;
    string choice;
};

SmmRPContext smmRPDefaultContext(string owner, int collection_budget) {
    SmmRPContext context;
    context.owner=owner;
    string turn_value=get_property("smm.TurnValue");
    context.turn_value=turn_value == "" ? 5000 : turn_value.to_float();
    context.collection=collection_budget > 0;
    context.collection_budget=collection_budget;
    string nodes=get_property("smmPlanner.nodeLimit");
    context.node_limit=nodes == "" ? 20000 : nodes.to_int();
    return context;
}

void smmRPStatus(boolean all) {
    SmmRPResource [string] pools=smmRPLiveResources();
    SmmRPReservation [int] reservations=smmRPReservations();
    string owner=get_property("smmPlanner.owner");
    if (owner == "") owner="legacy";
    print("Shared resource status — " + smmRPEpoch() + "; owner=" + owner, "blue");
    foreach id, pool in pools {
        int reserved=smmRPReservedForOthers(id,owner,reservations);
        if (!all && pool.remaining == 0 && reserved == 0) continue;
        print(id + ": " + pool.remaining + " remaining; " + reserved + " reserved for others; "
            + smmRPSpendable(id,owner,pools,reservations) + " spendable"
            + (pool.reason == "" ? "" : " (" + pool.reason + ")"));
    }
    foreach i, entry in reservations print("  reservation " + entry.owner + ": " + entry.resource + " × " + entry.units);
}

void smmRPReleaseOwner(string owner) {
    if (!smmRPIdentifier(owner)) abort("Owner must contain only letters, digits, dot, colon, underscore or dash.");
    SmmRPReservation [int] entries=smmRPReservations();
    foreach i, entry in entries if (entry.owner == owner) entries[i].units=0;
    smmRPSaveReservations(entries);
    print("Released reservations for " + owner);
}

SmmRPAction [string] smmRPReadRequests(string filename) {
    SmmRPRequest [string] requests;
    SmmRPAction [string] actions;
    if (!file_to_map(filename, requests) || count(requests) == 0) abort("Cannot read nonempty planner request file: " + filename);
    foreach id, r in requests {
        SmmRPAction action;
        action.description=r.description; action.limit=r.limit; action.eligible=r.eligible;
        action.valued=r.valued; action.direct_meat=r.direct_meat; action.loot_value=r.loot_value;
        action.adventure_delta=r.adventure_delta; action.avoided_cost=r.avoided_cost;
        action.input_cost=r.input_cost; action.displaced_value=r.displaced_value; action.future_cost=r.future_cost;
        action.goal=r.goal; action.missing=r.missing; action.collection_value=r.collection_value;
        action.choice_group=r.choice_group; action.choice=r.choice;
        if (r.costs != "") foreach i, part in split_string(r.costs, ",") {
            string [int] pair=split_string(part, "=");
            if (count(pair) != 2 || !smmRPIdentifier(pair[0]) || !create_matcher("^[0-9]+$",pair[1]).find()
                || pair[1].to_int() <= 0 || action.costs contains pair[0]) abort("Invalid or duplicate cost in " + id + ": " + part);
            action.costs[pair[0]]=pair[1].to_int();
        }
        actions[id]=action;
    }
    return actions;
}

void smmRPDemo() {
    SmmRPResource [string] pools;
    pools["carrier.free"]=new SmmRPResource("Compatible free fights",2,true,"");
    pools["sword.loot"]=new SmmRPResource("Sword replacements",1,true,"");
    SmmRPAction [string] actions;
    actions["a.tempting"]=smmRPNewAction("Best individual action, uses both carriers",1,100);
    actions["a.tempting"].costs["carrier.free"]=2;
    actions["a.tempting"].costs["sword.loot"]=1;
    actions["b.sword"]=smmRPNewAction("One replacement after native/familiar displacement",1,70);
    actions["b.sword"].costs["carrier.free"]=1;
    actions["b.sword"].costs["sword.loot"]=1;
    actions["c.bones"]=smmRPNewAction("Bone collection, alternative familiar",1,50);
    actions["c.bones"].costs["carrier.free"]=1;
    SmmRPReservation [int] reservations;
    SmmRPContext context=smmRPDefaultContext("demo",0);
    smmRPReport(smmRPSolve(actions,pools,reservations,context),actions,context);
    print("Demo uses synthetic values and performs no game actions or reservation writes.");
}

void smmRPUsage() {
    print("resources status [all] — cached live budgets and reservations");
    print("resources reserve <pool> <owner> <units> — replace that owner's reservation");
    print("resources release <owner> | clear — release reservations");
    print("resources owner <owner> — set caller identity for legacy skill selectors");
    print("resources plan <file.txt> <owner> <compatible-free-fights> [collection-Meat-budget]");
    print("resources reserve-plan <file.txt> <owner> <compatible-free-fights> [collection-Meat-budget]");
    print("resources demo — synthetic competing allocations; no game actions");
}

boolean smmRPNatural(string input) {
    return create_matcher("^[0-9]+$",input).find() && input.to_int() >= 0;
}

void main(string arguments) {
    arguments=replace_all(create_matcher("^\\s+|\\s+$",arguments),"");
    string [int] args=split_string(arguments,"\\s+");
    if (arguments == "" || args[0] == "status") {
        smmRPStatus(count(args)>1 && args[1] == "all"); return;
    }
    if (args[0] == "demo") { smmRPDemo(); return; }
    if (args[0] == "clear" && count(args)==1) {
        SmmRPReservation [int] empty;
        smmRPSaveReservations(empty); print("Cleared shared reservations."); return;
    }
    if (args[0] == "release" && count(args)==2) { smmRPReleaseOwner(args[1]); return; }
    if (args[0] == "owner" && count(args)==2 && smmRPIdentifier(args[1])) {
        set_property("smmPlanner.owner",args[1]); print("Shared planner owner=" + args[1]); return;
    }
    if (args[0] == "reserve" && count(args)==4 && smmRPNatural(args[3])) {
        if (!smmRPReserve(args[1],args[2],args[3].to_int())) abort("Reservation rejected: unknown/unavailable pool, invalid owner or insufficient unreserved units.");
        print("Reserved " + args[3] + " " + args[1] + " for " + args[2]); return;
    }
    if ((args[0] == "plan" || args[0] == "reserve-plan") && (count(args)==4 || count(args)==5) && smmRPIdentifier(args[2])
        && smmRPNatural(args[3]) && (count(args)==4 || smmRPNatural(args[4]))) {
        SmmRPAction [string] actions=smmRPReadRequests(args[1]);
        SmmRPResource [string] pools=smmRPLiveResources();
        pools["carrier.free"]=new SmmRPResource("Caller-verified compatible free fights",args[3].to_int(),true,"");
        SmmRPContext context=smmRPDefaultContext(args[2],count(args)==5 ? args[4].to_int() : 0);
        SmmRPPlan plan=smmRPSolve(actions,pools,smmRPReservations(),context);
        print("Free carriers are a supplied forecast; target eligibility and prices come from the request file.");
        smmRPReport(plan,actions,context);
        if (args[0] == "reserve-plan") {
            if (!smmRPReservePlan(plan,actions,pools,context)) abort("Plan changed or could not be reserved; replan against current state.");
            print("Reserved selected live resource costs for " + context.owner + ".");
        }
        return;
    }
    smmRPUsage();
}
