import <smmConsult.ash>
import <smmIotmRoute.ash>

void main(int round, monster foe, string page) {
    if (get_property("smm.IR.activeEpoch")!=smmRPEpoch()) abort("The IoTM combat script is only for an active IoTM route.");
    initConsult(foe);
    // Reuse the existing damage/survival strategy, without its optional items,
    // olfaction, replacements, banishes, or instakills. Preserve the valued loot.
    doMainLoop(foe,real_monster_hp(page),setupAborts(foe)+smmIRCombatPrefix(foe));
}
