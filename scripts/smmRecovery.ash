import <smmUtils.ash>
string __smmRecovery_version = "0.1";



// adds the ability to use magical sausages for recovery
// type is either "HP" or "MP".
// amount is the desired amount of restoration needed or 0 to use mafia's default recovery level and target
// NOTE: this function is called by mafia's recovery system, so it should not call restore_hp or restore_mp
boolean main(string type, int amount) {
    print("custom recovery script, recovering " + amount + " " + type, "blue");

    if (type == "HP") {
        if (amount == 0) {

        } else {}

    } else if (type == "MP") {
        if (amount == 0) {
        } else {}

        while (my_mp() < amount && smmMuseumMaySpend($item[magical sausage], 1)
            // during an smmdaily run (smm.daily.active) nobody is there to answer: take the default at once
            && (get_property("smm.daily.active") != "" || user_confirm("Wasn't able to recover mp to " + amount + ". Use magical sausage to recover 999 mp?", 60000, true))) {
            eat(1, $item[magical sausage]);
        }
        return my_mp() >= amount;
    }

    abort("should never get here");
    return true; // satisfy the compiler
}
