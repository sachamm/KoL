// Read-only companion to docs/iotm-completion-audit.md.
// Writes the combat lover's locket collection, which KoLmafia keeps in memory
// only, to data/smm-completion-live-<player id>.txt. It visits the locket's
// reminisce page (no charge is used) and changes nothing else.
//
//   call smmCompletionLive.ash

string smmCLZones(monster foe, string [monster] zones) {
	return (zones contains foe) ? zones[foe] : "";
}

void main() {
	if (available_amount($item[combat lover's locket]) < 1) abort("No combat lover's locket.");
	boolean [monster] have = get_locket_monsters();

	string [monster] zones;
	foreach place in $locations[] {
		foreach index, foe in get_monsters(place) {
			if (foe == $monster[none]) continue;
			zones[foe] = (zones contains foe) ? zones[foe] + " | " + place : place.to_string();
		}
	}

	buffer out;
	int owned = 0;
	int missing = 0;
	foreach foe in $monsters[] {
		if (foe == $monster[none] || !foe.copyable || foe.boss) continue;
		if (have contains foe) {
			owned += 1;
			continue;
		}
		missing += 1;
		out.append("missing\t" + foe.id + "\t" + foe + "\t" + smmCLZones(foe, zones) + "\n");
	}
	string header = "captured\t" + today_to_string() + "\tturn " + total_turns_played() + "\n"
		+ "locket.total\t" + count(have) + "\n"
		+ "copyable.owned\t" + owned + "\n"
		+ "copyable.missing\t" + missing + "\n";
	string file = "smm-completion-live-" + my_id() + ".txt";
	buffer report;
	report.append(header);
	report.append(out);
	if (!buffer_to_file(report, file)) abort("Could not write data/" + file);
	print("Locket holds " + count(have) + " monsters. Copyable and not a boss: " + owned + " held, " + missing + " missing.");
	print("Wrote data/" + file);
}
