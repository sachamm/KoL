script "targets";
import <smmTargets.ash>

string smmTGCell(int amount) { return amount < 0 ? "?" : amount.to_string(); }

void smmTGPrintRows(SmmTGRow [int] rows, int limit) {
    buffer html;
    html.append("<table border=1 cellpadding=2><tr><th>item</th><th>kind</th><th>case</th><th>held</th><th>short of top 10</th><th>short of #1</th><th>rank</th><th>holders</th><th>checked</th><th>source</th></tr>");
    int shown = 0;
    foreach i, row in rows {
        if (shown >= limit) break;
        shown += 1;
        html.append("<tr><td>" + row.name + "</td><td>" + row.kind + "</td><td>" + row.in_case + "</td><td>" + row.held + "</td><td>"
            + smmTGCell(row.short10) + "</td><td>" + smmTGCell(row.short1) + "</td><td>" + (row.my_rank > 0 ? "#" + row.my_rank : "-") + "</td><td>"
            + (row.checked == "" ? "?" : row.holders.to_string()) + "</td><td>" + (row.checked == "" ? "never" : row.checked) + "</td><td>" + row.source + "</td></tr>");
    }
    html.append("</table>");
    print_html(html.to_string());
    if (count(rows) > shown) print("Showing " + shown + " of " + count(rows) + ". Use 'targets list all' for the rest; the full list is in data/" + smmTGExportFile() + ".");
}

void smmTGList(int limit) {
    SmmTGRow [int] rows = smmTGRegister();
    int ranked, in_ten, unranked, close;
    foreach i, row in rows {
        if (row.short10 < 0) unranked += 1;
        else { ranked += 1; if (row.short10 == 0) in_ten += 1; else if (row.short10 <= 5) close += 1; }
    }
    print("Unbuyable Display Case targets: " + count(rows) + ". Ranked " + ranked + " (enough copies for the top ten: " + in_ten + ", within 5 copies: " + close + "), not yet looked up: " + unranked + ".", "blue");
    if (unranked > 0) print("Run 'targets refresh' to look up more rankings.");
    foreach i, name in smmTGSeedErrors print("Unrecognised item in " + kSmmTGSeedFile + ": " + name, "red");
    smmTGPrintRows(rows, limit);
    map_to_file(rows, smmTGExportFile());
}

void smmTGUnknown(boolean everything) {
    SmmTGRow [int] rows;
    int total = 0;
    foreach it in $items[] {
        if (!is_displayable(it) || smmTGKind(it) != "unknown") continue;
        total += 1;
        if (everything || smmTGCase(it) + smmTGHeld(it) > 0) rows[count(rows)] = smmTGRow(it);
    }
    print(total + " unbuyable Display Case items have no source Mafia knows and no line in " + kSmmTGSeedFile + "."
        + (everything ? "" : " Listing the " + count(rows) + " you hold; 'targets unknown all' lists every one."), "blue");
    sort rows by value.name.to_lower_case();
    smmTGPrintRows(rows, count(rows));
}

void smmTGSummary() {
    int [string] how;
    int [string] kinds;
    int displayable;
    foreach it in $items[] {
        if (!is_displayable(it)) continue;
        displayable += 1;
        how[smmTGAcquire(it)] += 1;
        kinds[smmTGKind(it)] += 1;
    }
    print("Display Case items: " + displayable, "blue");
    print("Obtainable with Meat: mall " + how["mall"] + ", NPC store " + how["npc"] + ", coinmaster with buyable currency " + how["coin-buy"] + ", crafted from buyable parts " + how["craft-buy"]);
    print("Not obtainable with Meat: monster drop " + how["drop"] + ", coinmaster with unbuyable currency " + how["coin"] + ", crafted from unbuyable parts " + how["craft"] + ", no known source " + how["unknown"]);
    print("Register kinds: repeatable " + kinds["repeatable"] + ", one-off " + kinds["oneoff"] + ", ignored " + kinds["ignore"] + ", unknown " + kinds["unknown"] + ", buyable " + kinds["buyable"]);
}

void smmTGItem(string name) {
    item it = to_item(name);
    if (it == $item[none]) abort("No item matches '" + name + "'.");
    print("[" + it.to_int() + "] " + it, "blue");
    if (!is_displayable(it)) { print("Cannot be put in a Display Case."); return; }
    string how = smmTGAcquire(it);
    print("Acquisition: " + how + (smmTGBuyable(it) ? " (obtainable with Meat)" : " (not obtainable with Meat)") + "; register kind: " + smmTGKind(it));
    if (smmTGSeeds contains it) {
        SmmTGSeed seed = smmTGSeeds[it];
        print("Your source line: " + seed.source + (seed.cap != "" ? ", " + seed.cap + "/day" : "") + (seed.note != "" ? " -- " + seed.note : ""));
    }
    smmVBuildGraph();
    foreach id in smmVProducedBy[it] print("Made by: " + smmTGConversionText(smmVConversions[id]) + "  (* = Meat cannot buy this input)");
    if (smmTGHasDrop(it)) foreach i, d in smmTGDrops[it] print("Drop: " + smmTGDropText(d));
    SmmValue worth = smmValueOf(it);
    print("Worth if spent or sold (smmValue): " + (worth.known ? smmVFormat(worth.value) + " Meat [" + worth.method + "] " + worth.why : "unknown"));
    print("In case: " + smmTGCase(it) + ", held elsewhere: " + smmTGHeld(it));
    // Uses the stored ranking; asks the Museum only if the item was never looked up.
    if (!smmMuseumStored(it)) smmMuseumFetch(it);
    if (smmMuseumStored(it)) {
        SmmTGRank rank = smmTGRank(it);
        print("Ranking checked " + rank.date + " (" + smmMuseumAgeDays(it) + " days ago; 'dc refresh " + it + "' renews it).");
        int owned = smmTGCase(it) + smmTGHeld(it);
        print("Museum: " + rank.holders + " collectors, largest " + rank.top + "; we are " + (rank.my_rank > 0 ? "#" + rank.my_rank + " with " + rank.mine : "not listed") + ".");
        print("Top ten needs " + rank.top10 + " (ties count): " + max(0, rank.top10 - owned) + " more to acquire, " + max(0, min(smmTGHeld(it), rank.top10 - smmTGCase(it))) + " to move into the case.");
        print("Sole first needs " + rank.top1 + ": " + max(0, rank.top1 - owned) + " more to acquire.");
    } else print("Museum ranking unavailable.", "orange");
}

void smmTGHelp() {
    print_html("<b>targets</b> [list] [<i>n</i>|all] -- unbuyable Display Case items, closest to the top ten first (default 40 rows)");
    print_html("<b>targets refresh</b> [<i>n</i>] -- look up missing, then oldest, Museum rankings for register items (default: all missing or due; 'dc refresh' rotates everything)");
    print_html("<b>targets item</b> <i>name</i> -- everything known about one item, with its stored ranking");
    print_html("<b>targets unknown</b> [all] -- unbuyable items with no known source, to be described in data/" + kSmmTGSeedFile);
    print_html("<b>targets summary</b> -- how every Display Case item is classified");
    print("Nothing here adventures, buys, sells or moves items.");
}

void main(string arguments) {
    string [int] words = split_string(replace_all(create_matcher("^\\s+|\\s+$", arguments), ""), "\\s+");
    string command = words[0].to_lower_case();
    string rest = count(words) > 1 ? words[1].to_lower_case() : "";
    if (is_integer(command) || command == "all") { rest = command; command = "list"; }
    switch (command) {
    case "":
    case "list":
        smmTGList(rest == "all" ? 1000000 : is_integer(rest) ? rest.to_int() : 40);
        break;
    case "refresh": {
        int limit = is_integer(rest) ? rest.to_int() : 0;
        print("Looked up " + smmTGRefresh(limit) + " Museum rankings.", "blue");
        smmTGList(40);
        break;
    }
    case "item":
        smmTGItem(replace_all(create_matcher("(?i)^\\s*item\\s+", arguments), ""));
        break;
    case "unknown": smmTGUnknown(rest == "all"); break;
    case "summary": smmTGSummary(); break;
    default: smmTGHelp();
    }
}
