import <smmIotmRoute.ash>

void main(string name) {
    item it=to_item(name);
    if (it==$item[none]) abort("Use museumroute <item>, for example museumroute floaty rock helmet");
    if (!is_displayable(it)) { print(it+" cannot be put in a Display Case.","orange"); return; }
    if (have_display()) smmIRVisit("managecollectionshelves.php");
    smmMuseumReport(it);
    SmmMuseumGoal goal=smmMuseumGoal(it);
    smmIRSaleValue(it);
    float price=smmIRReplacementPrices[it];
    if (goal.known && price>0) {
        int owned=smmMuseumDisplay(it)+smmMuseumStock(it);
        print("Additional copies for top ten: "+max(0,goal.tenth-owned)+"; rough funding at the current one-copy quote: "+round(max(0,goal.tenth-owned)*price)+" Meat.");
        print("Additional copies for buffered first place: "+max(0,goal.first-owned)+"; rough funding: "+round(max(0,goal.first-owned)*price)+" Meat. Bulk supply/prices may differ.");
    }
    print("This command only inspects the goal; purchases and transfers are not performed.");
}
