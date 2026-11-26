#!/usr/bin/env bash
# Offline tests for smmDaily (scripts/smmdaily.ash and scripts/smmDaily*.ash).
#
#   tests/smmdaily-tests.sh
#
# Runs a logged-out, headless KoLmafia in a throwaway directory. Nothing logs
# in and nothing is sent to the game. The first run downloads KoLmafia and
# clones the scripts this repository imports; later runs reuse them.
#
#   SMM_TEST_RUNTIME   where the throwaway KoLmafia lives (default tests/.runtime)
#   SMM_KOLUTILS       an existing KoLUtils checkout to use instead of cloning
#
# Needs java 21+, git, curl and unzip.

set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
RUNTIME="${SMM_TEST_RUNTIME:-$REPO/tests/.runtime}"
REVISION=29462
JAR="$RUNTIME/KoLmafia-$REVISION.jar"
failures=0

fail() { echo "FAIL: $*"; failures=$((failures + 1)); }
pass() { echo "ok: $*"; }

# --- the runtime -------------------------------------------------------------

mkdir -p "$RUNTIME/scripts" "$RUNTIME/data" "$RUNTIME/relay" "$RUNTIME/ext"
if [ ! -f "$JAR" ]; then
	echo "Downloading KoLmafia r$REVISION..."
	curl -fsSL -o "$JAR" "https://github.com/kolmafia/kolmafia/releases/download/r$REVISION/KoLmafia-$REVISION.jar" \
		|| { echo "Could not download KoLmafia r$REVISION."; exit 2; }
fi

fetch() { # fetch <directory> <url> [branch]
	[ -d "$RUNTIME/ext/$1" ] && return 0
	git clone --quiet --depth 1 ${3:+--branch "$3"} "$2" "$RUNTIME/ext/$1" \
		|| { echo "Could not clone $2."; exit 2; }
}
KOLUTILS="${SMM_KOLUTILS:-$RUNTIME/ext/KoLUtils}"
[ -n "${SMM_KOLUTILS:-}" ] || fetch KoLUtils https://github.com/sachamm/KoLUtils.git
fetch Voting-Booth https://github.com/Ezandora/Voting-Booth.git
fetch Bastille https://github.com/Ezandora/Bastille.git Release

ln -sf "$REPO"/scripts/* "$REPO"/tests/ash/*.ash "$KOLUTILS"/scripts/*.ash \
	"$RUNTIME/ext/Voting-Booth/Release/scripts/VotingBooth.ash" "$RUNTIME/ext/Bastille/scripts/bastille.ash" "$RUNTIME/scripts/"
ln -sf "$RUNTIME"/ext/Bastille/relay/* "$RUNTIME/relay/"
ln -sf "$REPO"/data/* "$RUNTIME/data/"

mafia() { # mafia <gCLI command>...   The empty first line answers the login prompt.
	( cd "$RUNTIME" && { printf '\n'; printf '%s\n' "$@"; printf 'exit\n'; } \
		| java -Djava.awt.headless=true -DuseCWDasROOT=true -jar "$JAR" --CLI 2>&1 )
}

# --- 1. everything compiles --------------------------------------------------

out="$(mafia "verify smmdaily.ash")"
if grep -q "Script verification complete" <<<"$out"; then pass "smmdaily.ash and everything it imports compiles"
else fail "smmdaily.ash does not compile"; grep -n "smmDaily\|smmdaily\|smmSpend" <<<"$out" | head -20; fi

# --- 2. the ASH tests --------------------------------------------------------

for t in smmDailyCoreTest smmDailyGateTest smmDressupTest smmDietTest smmDailyReviewTest smmNpcResaleTest; do
	out="$(mafia "$t")"
	verdict="^[[:space:]]*(>[[:space:]]*)?PASS $t:"
	if grep -Eq "$verdict" <<<"$out"; then pass "$(grep -E "$verdict" <<<"$out" | sed 's/^[[:space:]>]*//')"

	else
		fail "$t"
		grep "FAIL\|Expected\|undefined\|aborted\|not an integer" <<<"$out" | head -40
		# no verdict at all means KoLmafia itself did not get through the script: show where it stopped
		grep -q "FAIL" <<<"$out" || { echo "  last lines of KoLmafia's output:"; tail -15 <<<"$out" | sed 's/^/  /'; }
	fi
done

# The expected abort proves intent must reach disk before a task can act.
out="$(mafia "smmDailyJournalFailureTest")"
if grep -q "could not write the journal" <<<"$out" && ! grep -qE "UNSAFE_(TASK|HOOK)_EXECUTED" <<<"$out"; then pass "journal failure stops before the task action"
else fail "journal failure did not prevent the task action"; fi

out="$(mafia "smmDailyJournalGapTest")"
if grep -q "journal gap requires reconciliation" <<<"$out" && ! grep -qE "UNSAFE_(TASK|HOOK)_EXECUTED" <<<"$out"; then pass "unrecoverable journal gap stops before any task or recovery hook"
else fail "journal gap did not prevent the task action"; fi

# --- 3. the plan prints logged out, start to finish --------------------------

out="$(mafia "smmdaily plan")"
if grep -q "Phase 0: preflight" <<<"$out" && grep -q "close.report" <<<"$out"; then pass "smmdaily plan lists the whole day"
else fail "smmdaily plan did not list the whole day"; tail -20 <<<"$out"; fi

# --- 4. no prompts in the new code -------------------------------------------

NEW="$REPO/scripts/smmdaily.ash $REPO/scripts/smmDailyCore.ash $REPO/scripts/smmDailyGate.ash $REPO/scripts/smmDailyTasks.ash $REPO/scripts/smmDailyLegacy.ash"
if grep -n "user_confirm\|user_prompt\|user_notify" $NEW; then fail "the engine must never ask a question"
else pass "no user_confirm, user_prompt or user_notify in the smmDaily files"; fi

# Free rests refill Cinch on the Cincho de Mayo (60 Cinch forces a noncombat),
# so the new code must never spend one, least of all for MP.
if grep -n '"camp rest\|"rest free\|"rest"\|CampgroundRequest\|campground.php' $NEW; then fail "the smmDaily files must not rest: free rests are kept for Cinch"
else pass "the smmDaily files never spend a free rest"; fi

# --- 5. every function a task names exists -----------------------------------

missing=0
for fn in $(grep "smmDTAdd(" "$REPO/scripts/smmDailyTasks.ash" | grep -o '"smmD[A-Za-z]*"\|need=smmD[A-Za-z]*' | tr -d '"' | sed 's/^need=//' | sort -u); do
	grep -qE "^(void|string|boolean|int) $fn\(\)" $NEW || { fail "task function $fn is not defined"; missing=1; }
done
[ $missing -eq 0 ] && pass "every function named in the task list is defined"

# --- 6. every KoLmafia preference the new code reads exists ------------------

defaults="$(unzip -p "$JAR" data/defaults.txt | cut -f2)"
missing=0
audited="$(sed -n '/^string \[int\] smmDTPools/,/^};/p' "$REPO/scripts/smmDailyTasks.ash" | grep '^	"' | cut -d'|' -f2)"
needed="$(grep -o 'pref:[A-Za-z_]*' "$REPO/scripts/smmDailyTasks.ash" | cut -d: -f2)"
read_directly="$(grep -oh 'get_property("[A-Za-z_]*")' $NEW | cut -d'"' -f2)"
for pref in $(printf '%s\n' $audited $needed $read_directly | sort -u); do
	case "$pref" in _smm*|smm*|_garbo*|garbo*|pref|_fantasyRealmDone) continue ;; esac # ours, garbo's, or the old code's own
	grep -qx "$pref" <<<"$defaults" || { fail "KoLmafia r$REVISION has no preference called $pref"; missing=1; }
done
[ $missing -eq 0 ] && pass "every KoLmafia preference the smmDaily files read exists in r$REVISION"

# --- 7. shared settings -------------------------------------------------------

prefs="$REPO/data/smm-prefs.txt"
missing=0
for line in "smm.TurnValue	4500" "smm.IR.maxPaidTurns	100" "smm.dailyGrind.sea	true" "smm.dailyGrind.stopForBounty	false" \
	"smm.dailyGrind.useBanishers	true" "smm.dailyGrind.highItem	true" "smm.dailyGrind.dolphin	true" "smm.dailyGrind.gingerbreadItems	true" \
	"smm.dailyGrind.beerLens	false" "libramSkillsSoftcore	none"; do
	grep -qxF "$line" "$prefs" || { fail "data/smm-prefs.txt is missing: $line"; missing=1; }
done
[ $missing -eq 0 ] && pass "the Day 0 settings are in data/smm-prefs.txt"
if grep -q "^smm\.daily\.runner" "$prefs"; then fail "smm.daily.runner must not be a shared setting: only one machine runs the day"
else pass "smm.daily.runner is not shared"; fi

# --- 8. diet.ash -------------------------------------------------------------

out="$(mafia "verify diet.ash")"
if grep -q "Script verification complete" <<<"$out"; then pass "diet.ash and everything it imports compiles"
else fail "diet.ash does not compile"; grep -n "smmDiet\|diet.ash" <<<"$out" | head -20; fi
dietBudget="$(sed -n 's/^int kSmmDietBudget = \([0-9]*\);.*/\1/p' "$REPO/scripts/smmDiet.ash")"
gateBudget="$(sed -n 's/^int kSmmDDietBudget = \([0-9]*\);.*/\1/p' "$REPO/scripts/smmDailyGate.ash")"
if [ -n "$dietBudget" ] && [ "$dietBudget" = "$gateBudget" ]; then pass "smmDiet.ash and smmDailyGate.ash have the same default diet budget ($dietBudget)"
else fail "the default diet budget differs: smmDiet.ash '$dietBudget', smmDailyGate.ash '$gateBudget'"; fi
out="$(mafia "call diet.ash rollover=40 overdrunk=0 sinkvalue=0 noRefresh")"
if grep -q "^Stop point:" <<<"$out" && ! grep -qi "aborted\|bad item\|undefined\|exception" <<<"$out"; then pass "diet.ash plans a day logged out"
else fail "diet.ash did not plan a day logged out"; tail -15 <<<"$out" | sed 's/^/  /'; fi

rm -f "$RUNTIME"/data/smm-daily-test*.txt
echo
if [ $failures -eq 0 ]; then echo "PASS smmdaily-tests"; else echo "FAILED smmdaily-tests: $failures"; exit 1; fi
