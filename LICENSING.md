# Licensing and attribution

The README's existing CC BY 4.0 statement applies to contributions that their
rights holders can license on those terms. It is not a grant of rights in
third-party material. No existing public license grant is revoked or replaced
by this clarification.

## Existing license declarations

- Repository default: [CC BY 4.0](LICENSES/CC-BY-4.0.txt), as already stated in
  the README. Retain author attribution, source references, and change notices
  required by that license.
- `scripts/dc.ash` carries its own help-text notice: CC BY-SA version 4.0 or any
  later version. That file-specific declaration is preserved; the complete
  [CC BY-SA 4.0 text](LICENSES/CC-BY-SA-4.0.txt) is included here. Do not describe
  the whole repository as uniformly CC BY without this exception.

Sacha Mallais (TQuilla) is identified as the repository author. Existing file
credits remain in place. This document does not assign other contributors'
copyrights or resolve conflicting historical grants.

## External sources requiring further clearance

| File                         | Existing source credit                                                                                   | Status                                                                                                                                    |
| ---------------------------- | -------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| Historical `scripts/diet.js` | tehtmi's [lethe.xyz calculator](https://www.lethe.xyz/kol/diets.php), which also credits Eleron/houeland | Public adaptation and redistribution permission has not been established. The repository's default license cannot supply that permission. |
| `scripts/smmHallo.ash`       | `tricktreat.ash` by guyy                                                                                 | Applicable source version and reuse terms still need confirmation.                                                                        |
| `scripts/endGameSummary.js`  | The two starter repositories linked in its header                                                        | Identify actual borrowed expression and the license at the revision used before assigning definitive terms.                               |

The old starter URLs now resolve to
[loathers/kolmafia-scripts](https://github.com/loathers/kolmafia-scripts) and
[docrostov/kol-ts-starter](https://github.com/docrostov/kol-ts-starter).
Their current metadata and notices do not by themselves establish which
historical code was used. In particular, the latter's package metadata and root
license name different licenses; that inconsistency needs source tracing.

## Independent diet replacement

The previous diet optimizer block is replaced in current source by newly
authored `scripts/smmDietOptimizer.js`, `scripts/smmDietPlanner.js` and
`scripts/smmDietMechanics.js`, under the
repository's existing CC BY 4.0 default. The retained KoLmafia integration calls
that replacement. See [the model and validation record](docs/diet-optimizer.md).
The historical diet-file entry above still applies to earlier commits and
public distributions; replacing current code does not retroactively clear them.

## Separately installed dependencies

- [Voting-Booth](https://github.com/Ezandora/Voting-Booth) and
  [Bastille](https://github.com/Ezandora/Bastille) are installed separately through
  `dependencies.txt`. Their upstream LICENSE files use the Unlicense.
- [KoLmafia](https://github.com/kolmafia/kolmafia) is a separate runtime under
  BSD 3-Clause. Its license does not automatically apply to independent scripts.
  Retain its required notices if incorporating protected code or data.
- Other imports, including `smmUtils.ash`, `smmResourcePlanner.ash`, and
  `zlib.ash`, require their own source and license records. The unpinned remote
  jQuery dependency in `endGameSummary.js` also needs an exact version/source
  record if retained.

Game names, text, and any independently protected data remain subject to their
owners' rights. An attribution or import statement is a provenance lead, not a
blanket permission grant. This document records known terms and open questions;
it does not certify all repository content for redistribution.
