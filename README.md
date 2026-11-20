# KoL

My personal KoL code, not intended for public consumption at this point.

## Installation

Run this command in the graphical CLI:

<pre>
git checkout sachamm/KoL
</pre>

Will require [a recent build of KoLMafia](http://builds.kolmafia.us/job/Kolmafia/lastSuccessfulBuild/).

## Usage

Not really meant for public use at this point.

## Author

Sacha Mallais (ingame: TQuilla #2771003)
sachamallais@gmail.com

## License

The existing default license is [CC BY 4.0](LICENSES/CC-BY-4.0.txt) for material
its rights holders can license on those terms. `scripts/dc.ash` retains its
file-specific CC BY-SA 4.0-or-later notice. Third-party material retains its
applicable terms; some borrowed-source permissions remain unresolved.

See [Licensing and attribution](LICENSING.md) for the scope, source credits,
and outstanding permission questions. This clarification does not revoke or
replace existing license grants.

The diet command now uses an [independent optimizer](docs/diet-optimizer.md).
That document explains its supported predictions, optional-helper/chocolate
limitations, and offline tests.

## Local development

Edit scripts in this repository. On the development Mac, individual files in
both KoLmafia scripts directories are symbolic links to these source files,
so saved edits are immediately available in KoLmafia.

Do not install this same repository through KoLmafia Git or SVN on that Mac:
the updater can replace the development links. Other scripts can still update
normally. Commit and push here to publish changes; other installations can
install this repository with the Git command above.
