import <smmIotmRoute.ash>

void main(string command) {
    command=replace_all(create_matcher("^\\s+|\\s+$",command.to_lower_case()),"");
    switch (command) {
    case "":
    case "plan": smmIRDailyRoute(false,false); break;
    case "plan-free": smmIRDailyRoute(true,false); break;
    case "run": smmIRDailyRoute(false,true); break;
    case "free": smmIRDailyRoute(true,true); break;
    case "status":
        print("IoTM route enabled="+smmIREnabled()+", paid turns remaining="+smmIRPaidRemaining()+", active="+get_property("smm.IR.activeEpoch"));
        print("Garden="+my_garden_type()+", selected="+get_property("smm.IR.gardenPlan")+", changed today="+(get_property("smm.IR.gardenChangeDate")==today_to_string())+", collection budget remaining="+smmIRCollectionRemaining());
        break;
    case "reset":
        if (handling_choice() || current_round()>0) abort("Resolve the current encounter before resetting the route lock.");
        if (!smmIRRestorePendingGear()) abort("Could not restore the saved IoTM outfit; route state retained for inspection.");
        smmIRRestoreSettings();
        set_property("smm.IR.activeEpoch",""); set_property("smm.IR.combatSkill","");
        print("Cleared route lock. Daily usage and turn accounting were preserved.");
        break;
    default: abort("Use iotmroute plan | plan-free | run | free | status | reset");
    }
}
