# Tquilla game-state capture — November 27, 2026

Captured at 14:29:20 Pacific (22:29:20 UTC) from the already-open authenticated KoLmafia r29482 session, after `refresh all`. No adventures, purchases, consumables, equipment changes, or skill casts were issued for this capture. The exporter checked turns, adventures and Meat for changes during export.

Current character: level 105 Turtle Tamer, no challenge path, 231 ascensions, aftercore. 29 adventures; 57,127,831 Meat on hand and 112,843,000 in the closet.

## Contents

- game-state.json: character resources and stats; equipment; 87 effects; 434 available skills; 327 permanent skills with hardcore/softcore flags; 173 familiars with experience/equipment; campground/workshed/dwelling/chateau; shop quantities/prices/limits; 2,253 built-in gameplay properties covering quests, daily resources and persistent unlocks; counters, locket, crafting/free-rest resources, modifiers; combat/noncombat queues and observed turns for 601 locations.
- Item rows by location: inventory 4,241; closet 30; storage 5,132; display case 2,576; mall shop 77; free-pull map empty in this aftercore session. These are distinct item rows per location, not total quantities or globally distinct items.
- tquilla_queue.ser and tquilla_turns.ser: verbatim last-on-disk KoLmafia backups. These were last written before this capture. The JSON contains the current in-memory queues and is authoritative for capture-time queue values.
- capture-exporter.js: exact exporter used.
- manifest.json: file integrity hashes and coverage limits.

## Limits

This is a broad export of KoLmafia's observed account state, not a complete server backup. Previously unvisited unlocks, collection/history records, and custom-script counters can remain unknown or stale. Display/storage/shop data reflect the client's knowledge and getter refresh behavior; `refresh all` does not promise a separate server fetch for every collection. Current aftercore ownership does not establish future Standard eligibility or the legal starting state after reincarnation. The export deliberately excludes credentials, raw preferences, cookies, session hashes and raw server pages. It does not include exhaustive ascension history or Museum ranks. Per-location last-noncombat timing is retained where available as gameplay properties and in the binary backup, not as a separate location field.

Capture section errors: none. Sacha explicitly requested this sanitized capture be committed, pushed and merged into the repository on November 27, 2026. Credentials and raw client settings remain excluded.