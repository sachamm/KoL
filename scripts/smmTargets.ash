// Target register: which Display Case items cannot be bought, where they come
// from, and how far each is from the Museum top ten.
//
// Classification uses only Mafia's local data. Ranking thresholds come from
// the Museum ranking store in smmUtils.ash, which rations requests to
// museum.loathers.net and keeps every answer across days. Nothing here adventures, buys, sells or
// moves an item. See docs/target-register.md.

import <smmUtils.ash>
import <smmValue.ash>

record SmmTGDrop {
    monster mon;
    float rate;      // percent; 0 means Mafia does not know it
    string type;     // "" normal, c conditional, p pickpocket only, n no pickpocket, f fixed, a accordion thief
};

record SmmTGSeed {
    string kind;     // repeatable | oneoff | ignore | buyable
    string cap;      // attempts per day, blank when unknown
    string source;   // the action that produces it
    string note;
};

record SmmTGRank {
    string date;     // yyyyMMdd of the lookup; blank means never looked up
    int mine;        // our quantity as the Museum last saw it
    int my_rank;     // 0 when we are not listed
    int top10;       // quantity that puts us in the top ten, ties included
    int top1;        // quantity for sole first place
    int holders;     // collectors listed, including us
    int top;         // largest quantity anyone has
};

record SmmTGRow {
    int id;
    string name;
    string kind;
    int in_case;
    int held;
    int short10;     // copies still to acquire for the top ten; -1 when unranked
    int short1;      // copies still to acquire for sole first; -1 when unranked
    int my_rank;
    int holders;
    string checked;
    string source;
};

string kSmmTGSeedFile = "smm-target-sources.txt";

SmmTGDrop [item,int] smmTGDrops;
string [monster] smmTGZones;
boolean smmTGIndexed;
string [item] smmTGMemo;
boolean [item] smmTGBusy;
SmmTGSeed [item] smmTGSeeds;
string [int] smmTGSeedErrors;
boolean smmTGSeedsLoaded;

string smmTGExportFile() { return "smm-targets-" + my_id() + ".txt"; }

// ---------------------------------------------------------------------------
// Seed file: sources that Mafia's data cannot tell us.

void smmTGLoadSeeds() {
    if (smmTGSeedsLoaded) return;
    smmTGSeedsLoaded = true;
    SmmTGSeed [string] raw;
    if (!file_to_map(kSmmTGSeedFile, raw)) return;
    foreach name, seed in raw {
        item it = to_item(name);
        if (it == $item[none]) { smmTGSeedErrors[count(smmTGSeedErrors)] = name; continue; }
        seed.kind = seed.kind.to_lower_case();
        smmTGSeeds[it] = seed;
    }
}

// ---------------------------------------------------------------------------
// Where items drop.

void smmTGIndex() {
    if (smmTGIndexed) return;
    smmTGIndexed = true;
    foreach loc in $locations[] foreach i, mon in get_monsters(loc)
        smmTGZones[mon] = (smmTGZones contains mon ? smmTGZones[mon] + ", " : "") + loc.to_string();
    foreach mon in $monsters[] foreach i, d in item_drops_array(mon) {
        SmmTGDrop entry;
        entry.mon = mon;
        entry.rate = d.rate;
        entry.type = d.type;
        int next = (smmTGDrops contains d.drop) ? count(smmTGDrops[d.drop]) : 0;
        smmTGDrops[d.drop, next] = entry;
    }
}

boolean smmTGHasDrop(item it) {
    smmTGIndex();
    return smmTGDrops contains it;
}

// Rank a drop for display: a monster we can find beats one with no zone, an
// unconditional drop beats a conditional one, then the higher rate wins.
float smmTGDropScore(SmmTGDrop d) {
    float score = d.rate;
    if (smmTGZones contains d.mon) score += 1000;
    if (d.type != "c" && d.type != "p" && d.type != "a") score += 500;
    return score;
}

string smmTGDropText(SmmTGDrop d) {
    string text = (d.rate > 0 ? d.rate.to_string() + "% " : "?% ") + d.mon;
    text += (smmTGZones contains d.mon) ? " @ " + smmTGZones[d.mon] : " (no zone)";
    if (d.type == "c") text += " [conditional]";
    if (d.type == "p") text += " [pickpocket only]";
    if (d.type == "a") text += " [accordion thief only]";
    if (d.mon.boss) text += " [boss]";
    return text;
}

// ---------------------------------------------------------------------------
// Can Meat get it?  mall | npc | coin-buy | craft-buy mean yes.
// drop | coin | craft | unknown mean no, and name the best known source.
//
// Shops and recipes come from smmValue.ash's conversion graph, which reads
// Mafia's own coinmaster, shop-row, recipe and NPC-store data. That is the same
// model the rest of the scripts price items with, and unlike get_ingredients()
// it does not depend on which recipes this character can currently make.

boolean smmTGBuyable(item it);

boolean smmTGPayable(SmmConversion conv) {
    foreach part in conv.inputs if (!smmTGBuyable(part)) return false;
    return true;
}

boolean smmTGIsCraft(SmmConversion conv) { return conv.kind == "craft"; }

// The conversion that best explains how to get the item: one Meat can pay for
// if there is one, otherwise a shop before a recipe. -1 when nothing makes it.
int smmTGBestConversion(item it) {
    smmVBuildGraph();
    int best = -1;
    int best_score = -1;
    foreach id in smmVProducedBy[it] {
        SmmConversion conv = smmVConversions[id];
        int score = (smmTGPayable(conv) ? 2 : 0) + (smmTGIsCraft(conv) ? 0 : 1);
        if (score > best_score) { best = id; best_score = score; }
    }
    return best;
}

string smmTGAcquire(item it) {
    if (smmTGMemo contains it) return smmTGMemo[it];
    if (smmTGBusy contains it) return "unknown"; // a recipe that loops back on itself
    smmTGBusy[it] = true;
    smmTGLoadSeeds();

    string result = "unknown";
    if (smmTGSeeds contains it && smmTGSeeds[it].kind == "buyable") result = "mall";
    else if (is_tradeable(it)) result = "mall";
    else if (is_npc_item(it) || npc_price(it) > 0) result = "npc";
    else {
        int id = smmTGBestConversion(it);
        boolean payable = false;
        if (id >= 0) {
            SmmConversion conv = smmVConversions[id];
            payable = smmTGPayable(conv);
            if (conv.kind == "npc") result = payable ? "npc" : "unknown";
            else if (smmTGIsCraft(conv)) result = payable ? "craft-buy" : "craft";
            else result = payable ? "coin-buy" : "coin";
        }
        if (!payable && smmTGHasDrop(it)) result = "drop";
    }

    remove smmTGBusy[it];
    // A verdict reached while another item was still being worked out may have
    // been cut short by the loop guard, so only keep it once nothing is pending.
    if (count(smmTGBusy) == 0 || result == "mall" || result == "npc" || result == "coin-buy" || result == "craft-buy") smmTGMemo[it] = result;
    return result;
}

boolean smmTGBuyable(item it) {
    string how = smmTGAcquire(it);
    return how == "mall" || how == "npc" || how == "coin-buy" || how == "craft-buy";
}

// "25 FunFunds* @ The Dinsey Company Store"; * marks an input Meat cannot buy.
string smmTGConversionText(SmmConversion conv) {
    string text;
    foreach part, amount in conv.inputs
        text += (text == "" ? "" : " + ") + amount + " " + part + (smmTGBuyable(part) ? "" : "*");
    if (conv.meat > 0) text += (text == "" ? "" : " + ") + conv.meat + " Meat";
    text += " @ " + conv.via;
    if (!smmTGIsCraft(conv) && conv.kind != "npc") {
        coinmaster shop = to_coinmaster(conv.via);
        if (shop != $coinmaster[none] && !shop.is_accessible()) text += " [not open to you now]";
    }
    return text;
}

// One line naming the best source we know. Blank when there is none.
string smmTGSource(item it) {
    smmTGLoadSeeds();
    if (smmTGSeeds contains it && smmTGSeeds[it].source != "") {
        SmmTGSeed seed = smmTGSeeds[it];
        return seed.source + (seed.cap != "" ? " (" + seed.cap + "/day)" : "");
    }
    string how = smmTGAcquire(it);
    if (how == "drop") {
        SmmTGDrop best;
        float best_score = -1;
        foreach i, d in smmTGDrops[it] if (smmTGDropScore(d) > best_score) { best = d; best_score = smmTGDropScore(d); }
        int more = count(smmTGDrops[it]) - 1;
        return smmTGDropText(best) + (more > 0 ? " +" + more + " more" : "");
    }
    int id = smmTGBestConversion(it);
    return id >= 0 ? smmTGConversionText(smmVConversions[id]) : "";
}

// repeatable | oneoff | ignore | buyable | unknown
string smmTGKind(item it) {
    smmTGLoadSeeds();
    if (smmTGSeeds contains it && smmTGSeeds[it].kind != "") return smmTGSeeds[it].kind;
    if (smmTGBuyable(it)) return "buyable";
    return smmTGAcquire(it) == "unknown" ? "unknown" : "repeatable";
}

// Display Case count, asked of Mafia once per item per run.
int [item] smmTGCases;
int smmTGCase(item it) {
    if (!(smmTGCases contains it)) smmTGCases[it] = have_display() ? display_amount(it) : 0;
    return smmTGCases[it];
}

int smmTGHeld(item it) {
    return item_amount(it) + closet_amount(it) + storage_amount(it) + equipped_amount(it);
}

// ---------------------------------------------------------------------------
// Museum rankings.

// Ranking figures for the register, worked out from the shared Museum ranking
// store. A blank date means the item has never been looked up.
SmmTGRank smmTGRank(item it) {
    SmmTGRank rank;
    if (!smmMuseumStored(it)) return rank;
    SmmMuseumEntry entry = smmMuseumEntry(it);
    rank.date = timestamp_to_date(entry.checked * 1000, "yyyy-MM-dd");
    rank.mine = entry.mine;
    rank.my_rank = entry.my_rank;
    rank.holders = entry.holders;
    // The stored list holds at least ten other players whenever that many exist.
    int [int] others;
    foreach place, name, amount in smmMuseumStoredList(it) if (!isMe(name)) others[count(others)] = amount;
    sort others by -value;
    rank.top = max(rank.mine, count(others) > 0 ? others[0] : 0);
    // Matching the tenth-largest other collection ties for a top-ten place.
    rank.top10 = count(others) >= 10 ? others[9] : 1;
    rank.top1 = count(others) > 0 ? others[0] + 1 : 1;
    return rank;
}

// ---------------------------------------------------------------------------
// The register itself.

// An item we would list: displayable, not obtainable with Meat, not ignored,
// and either we know a source or we already hold a copy.
boolean smmTGIsTarget(item it) {
    if (it == $item[none] || !is_displayable(it)) return false;
    string kind = smmTGKind(it);
    if (kind == "buyable" || kind == "ignore") return false;
    if (kind == "unknown") return smmTGCase(it) + smmTGHeld(it) > 0;
    return true;
}

SmmTGRow smmTGRow(item it) {
    SmmTGRow row;
    SmmTGRank rank = smmTGRank(it);
    row.id = it.to_int();
    row.name = it.to_string();
    row.kind = smmTGKind(it);
    row.in_case = smmTGCase(it);
    row.held = smmTGHeld(it);
    row.checked = rank.date;
    row.my_rank = rank.my_rank;
    row.holders = rank.holders;
    row.short10 = rank.date == "" ? -1 : max(0, rank.top10 - row.in_case - row.held);
    row.short1 = rank.date == "" ? -1 : max(0, rank.top1 - row.in_case - row.held);
    row.source = smmTGSource(it);
    if (row.kind != "oneoff" && rank.date != "" && rank.top == 1 && rank.holders >= 5)
        row.source += (row.source == "" ? "" : "; ") + "everyone listed has 1: probably one per account";
    return row;
}

// Order: closest to the top ten first, then those already there (closest to
// first place first), then unranked.
int smmTGSortKey(SmmTGRow row) {
    if (row.short10 < 0) return 2000000000 - min(1000000, row.in_case + row.held); // copies we hold first
    if (row.short10 == 0) return 1000000000 + row.short1;
    return row.short10;
}

SmmTGRow [int] smmTGRegister() {
    SmmTGRow [int] rows;
    foreach it in $items[] if (smmTGIsTarget(it)) rows[count(rows)] = smmTGRow(it);
    sort rows by smmTGSortKey(value);
    return rows;
}

// Look up the n targets whose ranking is missing or oldest. Returns how many
// lookups succeeded.
int smmTGRefresh(int limit) {
    limit = min(limit, smmMuseumLookupsLeft());
    if (limit < 1) { print("No Museum lookups left today (" + smmMuseumLookupsUsed() + " of " + smmMuseumLookupLimit() + " used).", "orange"); return 0; }
    item [int] queue;
    foreach it in $items[] if (smmTGIsTarget(it)) queue[count(queue)] = it;
    // Never-checked first, with copies we already hold ahead of the rest; then oldest.
    int [item] keys;
    foreach i, it in queue keys[it] = smmMuseumStored(it) ? smmMuseumEntry(it).checked : (smmTGCase(it) + smmTGHeld(it) > 0 ? 0 : 1);
    sort queue by keys[value];
    int done = 0;
    int failed = 0;
    foreach i, it in queue {
        if (done + failed >= limit) break;
        if (smmMuseumStored(it) && smmMuseumNow() - smmMuseumEntry(it).checked < 20 * 3600) break; // everything left is current
        if (done + failed > 0) waitq(1);
        if (smmMuseumFetch(it)) done += 1;
        else { failed += 1; print("Museum ranking not understood for " + it + "; left as it was.", "orange"); }
        if ((done + failed) % 10 == 0) print("Museum lookups: " + (done + failed) + " of " + min(limit, count(queue)) + "...");
        if (failed >= 5 && done == 0) { print("Five lookups failed in a row; stopping.", "red"); break; }
    }
    return done;
}
