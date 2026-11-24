// Offline test for the familiar side of dressup()'s outfit cache (scripts/smmAutomation.ash).
// Run by tests/smmdaily-tests.sh in a logged-out KoLmafia.
import <smmAutomation.ash>

int checks = 0;
int failed = 0;

void expect(string what, string got, string want) {
	checks++;
	if (got != want) {
		failed++;
		print("FAIL " + what + ": Expected " + want + ", got " + got, "red");
	}
}

void main() {
	familiar bat = $familiar[cookbookbat];
	familiar jill = $familiar[Jill-of-All-Trades];

	// the "default" selector gives one max string for many familiars
	expect("same familiar as cached", dressupCacheFamiliarAction("mainstat, equip tiny stillsuit", bat, bat), kDressupCacheRestoreFamiliar);
	expect("default choice moved on since the cache", dressupCacheFamiliarAction("mainstat, equip tiny stillsuit", bat, jill), kDressupCacheStale);
	expect("selector none, cached none", dressupCacheFamiliarAction("mainstat", $familiar[none], $familiar[none]), kDressupCacheRestoreFamiliar);
	expect("selector none, cached with a familiar", dressupCacheFamiliarAction("mainstat", bat, $familiar[none]), kDressupCacheStale);

	// an empty selector, or the caller's own -familiar: whatever is out stays out
	expect("-familiar, another familiar out", dressupCacheFamiliarAction("mainstat, -familiar", bat, jill), kDressupCacheLeaveFamiliar);
	expect("-familiar, same familiar out", dressupCacheFamiliarAction("mainstat, -familiar", bat, bat), kDressupCacheLeaveFamiliar);

	// the maximizer chose the familiar, so its choice comes back with the outfit
	expect("switch, another familiar out", dressupCacheFamiliarAction("-combat, switch Disgeist", $familiar[Disgeist], bat), kDressupCacheRestoreFamiliar);

	if (failed == 0)
		print("PASS smmDressupTest: " + checks + " checks");
	else
		print("FAILED smmDressupTest: " + failed + " of " + checks);
}
