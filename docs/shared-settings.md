# Shared settings

Tquilla plays on more than one machine. The settings that should match everywhere are kept in this repository, so `git update` (or `git pull` on the development Mac) shares them.

## What is shared, and where

| What | In the repository | How it reaches KoLmafia |
| --- | --- | --- |
| Chosen preferences | `data/smm-prefs.txt` | KoLmafia's git install copies it to `data/`; `smmPrefs apply` sets the values |
| Combat scripts | every hand-written `ccs/*.ccs` (unrestricted, default, hardcore, normal, badmoon, dark_gyffte, glover, greygoo, plumber, smm-iotm-route) | KoLmafia's git install copies them to `ccs/` |
| Moods and aliases | `settings/tquilla_moods.txt`, `settings/GLOBAL_aliases.txt` | Copied by hand into KoLmafia's `settings/` folder while KoLmafia is closed (KoLmafia's git install skips `settings/`) |

Generated CCS files stay out: `garbo.ccs` (garbo writes it), `grimoire_macro.ccs` (libram) and `autoscend_null.ccs` (autoscend). Combat macros made on the KoL site are stored by the game, so every machine already shares them.

Never put these in the repository: `GLOBAL_prefs.txt` (saved login and password), the whole `tquilla_prefs.txt` (thousands of daily counters, quest state and script state), or anything with a machine path.

## smmPrefs

`data/smm-prefs.txt` lists one `name<TAB>value` per line. Lines starting with `#` are comments. An empty value means the preference should be empty, for example `afterAdventureScript`.

Run these in the gCLI while logged in, because most of these are character preferences:

- `smmPrefs check` lists what differs and changes nothing.
- `smmPrefs apply` sets everything that differs.
- `smmPrefs capture` writes this machine's current values back into the file. On the development Mac the file is a link into this repository, so commit and push afterwards. On a git-installed machine the change is overwritten by the next `git update`, so capture on the Mac.

To share another preference, add its name and value to `data/smm-prefs.txt` and commit. Leave out daily (`_`) preferences, counters, and `smm.IR.*` script state.

## Changing settings

Make changes on the development Mac, then publish them:

1. Change the preference or combat script in KoLmafia as usual.
2. Run `smmPrefs capture` (for preferences). If moods or aliases changed, copy `tquilla_moods.txt` or `GLOBAL_aliases.txt` from KoLmafia's `settings/` into the repository's `settings/`.
3. Commit and push.

On every other machine: run `git update` in the gCLI, then `smmPrefs apply`. If moods or aliases changed, quit KoLmafia and copy the files from `git/sachamm-KoL-main/settings/` into `settings/`.

## Setting up the development Mac

The Mac uses links into its clone of this repository instead of a KoLmafia git install (see the README, "Local development"). In Terminal, with your own clone path in place of `~/Projects/KoL`:

```sh
REPO=~/Projects/KoL
MAFIA="$HOME/Library/Application Support/KoLmafia"
cd "$REPO" && git checkout main && git pull

# Combat scripts: publish every hand-written CCS from the Mac (skip generated ones).
for f in "$MAFIA"/ccs/*.ccs; do
  n=$(basename "$f")
  case "$n" in garbo.ccs|grimoire_macro.ccs|autoscend_null.ccs) continue ;; esac
  [ -L "$f" ] || cp "$f" "ccs/$n"
done

# Moods and aliases: the Mac's copies are the source.
cp "$MAFIA/settings/tquilla_moods.txt" "$MAFIA/settings/GLOBAL_aliases.txt" settings/

git status --short    # review what differs from the Windows copies
git add ccs settings && git commit -m "Update CCS, moods and aliases from the Mac" && git push

# Link the repository files into KoLmafia (replaces the Mac's own copies).
for f in ccs/*.ccs; do ln -sfn "$REPO/$f" "$MAFIA/$f"; done
ln -sfn "$REPO/scripts/smmPrefs.ash" "$MAFIA/scripts/smmPrefs.ash"
ln -sfn "$REPO/data/smm-prefs.txt"   "$MAFIA/data/smm-prefs.txt"
```

Then in the gCLI, logged in: `smmPrefs check`. It should report that everything matches, because the file was built from the Mac's preferences.
