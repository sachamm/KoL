# Shared settings

Tquilla plays on more than one machine. The settings that should match everywhere are kept in this repository, so `git update` (or `git pull` on the development Mac) shares them.

## What is shared, and where

| What | In the repository | How it reaches KoLmafia |
| --- | --- | --- |
| Chosen preferences | `data/smm-prefs.txt` | KoLmafia's git install copies it to `data/`; `smmPrefs apply` sets the values |
| Combat script | `ccs/unrestricted.ccs` (and `ccs/smm-iotm-route.ccs`) | KoLmafia's git install copies it to `ccs/` |
| Moods | `settings/tquilla_moods.txt` | Copied by hand into KoLmafia's `settings/` folder while KoLmafia is closed (KoLmafia's git install skips `settings/`) |

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
2. Run `smmPrefs capture` (for preferences). Copy `settings/tquilla_moods.txt` from KoLmafia into the repository if moods changed.
3. Commit and push.

On every other machine: run `git update` in the gCLI, then `smmPrefs apply`. If moods changed, quit KoLmafia and copy `git/sachamm-KoL-main/settings/tquilla_moods.txt` into `settings/`.

## Setting up the development Mac

The Mac uses links into its clone of this repository instead of a KoLmafia git install (see the README, "Local development"). In Terminal, with your own clone path in place of `~/Projects/KoL`:

```sh
REPO=~/Projects/KoL
MAFIA="$HOME/Library/Application Support/KoLmafia"
cd "$REPO" && git checkout main && git pull

# If the Mac's combat script is newer than the repository's, publish it first.
diff -q "$MAFIA/ccs/unrestricted.ccs" ccs/unrestricted.ccs || {
  cp "$MAFIA/ccs/unrestricted.ccs" ccs/unrestricted.ccs
  git add ccs/unrestricted.ccs && git commit -m "Update unrestricted CCS from the Mac" && git push
}

# Moods: the Mac's copy is the source.
cp "$MAFIA/settings/tquilla_moods.txt" settings/tquilla_moods.txt
git diff --quiet settings/tquilla_moods.txt || {
  git add settings/tquilla_moods.txt && git commit -m "Update moods from the Mac" && git push
}

# Link the new files into KoLmafia.
ln -sfn "$REPO/scripts/smmPrefs.ash"     "$MAFIA/scripts/smmPrefs.ash"
ln -sfn "$REPO/data/smm-prefs.txt"       "$MAFIA/data/smm-prefs.txt"
ln -sfn "$REPO/ccs/unrestricted.ccs"     "$MAFIA/ccs/unrestricted.ccs"
ln -sfn "$REPO/ccs/smm-iotm-route.ccs"   "$MAFIA/ccs/smm-iotm-route.ccs"
```

Then in the gCLI, logged in: `smmPrefs check`. It should report that everything matches, because the file was built from the Mac's preferences.
