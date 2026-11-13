KoL
=====
My personal KoL code, not intended for public consumption at this point.

Installation
----------------
Run this command in the graphical CLI:
<pre>
git checkout sachamm/KoL
</pre>
Will require [a recent build of KoLMafia](http://builds.kolmafia.us/job/Kolmafia/lastSuccessfulBuild/).

Usage
----------------
Not really meant for public use at this point.


Author
----------------
Sacha Mallais (ingame: TQuilla #2771003)
sachamallais@gmail.com

License
----------------
Licenced under CC BY 4.0
https://creativecommons.org/licenses/by/4.0/


Local development
-----------------
Edit scripts in this repository. On the development Mac, individual files in
both KoLmafia scripts directories are symbolic links to these source files,
so saved edits are immediately available in KoLmafia.

Do not install this same repository through KoLmafia Git or SVN on that Mac:
the updater can replace the development links. Other scripts can still update
normally. Commit and push here to publish changes; other installations can
install this repository with the Git command above.

`testbase.ash` requires `testinc.ash`, which was absent from the migrated scripts.
