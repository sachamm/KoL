import <smmUtils.ash>
import <smmDailyGate.ash>
string __smmPreAdventure_version = "0.1";



void main() {
	smmDRequireActiveDay();
	preAdventureChecks();
	smmDCombatPrepare();
}



