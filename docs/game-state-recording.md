# Recorded game state

A comprehensive live capture completed on November 27, 2026 at 14:29 Pacific
(22:29 UTC), using the already-open authenticated KoLmafia r29482 session.
The capture was authorized by Sacha, coordinated through the account ownership
lease, and followed `refresh all`. No gameplay spending commands were issued.

Sacha explicitly requested the sanitized capture files be committed, pushed and
merged into this repository. The versioned bundle is
[docs/data/game-state/tquilla-20261127T222920Z](data/game-state/tquilla-20261127T222920Z/README.md).
Credentials and raw client settings remain excluded. The original local bundle is:

`C:\Users\sacha\Projects\runtime\kol\verify-state-recording\tquilla-20261127T222920Z`

The downloadable archive is:

`C:\Users\sacha\Projects\runtime\kol\verify-state-recording\Tquilla_Game_State_2026-11-27.zip`

A durable copy is available as
[Tquilla_Game_State_2026-11-27.zip](https://chatgpt.com/library?file_id=libfile_4ede1fd64de88191b490826421adff01&account_id=personal).

The bundle includes the JSON export, exact exporter, README describing coverage,
file integrity manifest, and verbatim last-on-disk encounter/turn-count backups.
The JSON contains current in-memory combat and noncombat queues. The binary
backups have earlier filesystem timestamps and are supplementary evidence only.

Coverage includes character resources, item locations, shop prices and limits,
equipment, effects, available and permanent skills, familiars, campground,
workshed, dwelling, chateau, built-in gameplay properties, counters, modifiers,
and per-location queues and observed turn counts. Validation found no section
errors or missing queue fields. Turns, adventures and Meat were checked for
changes within the export. Raw credentials, session hashes, cookies, raw
preferences and raw server responses are excluded.

This records KoLmafia's knowledge at capture time. Unvisited unlocks, historical
collections, custom-script counters and some cached collections may be incomplete
or stale. It does not establish future Standard legality, a legal reincarnation
starting state, exhaustive ascension history or Museum ranks. Read the bundle's
README and manifest before using it as simulator evidence.
