# Daily script quality cycles

The target is 9.9 under the existing scorecard rubric. A new code assessment does not replace the demonstrated live score. Normal game actions are separate from offline validation; the current end-of-day account was offered for information only.

## Cycle 1: persistent intent, explicit failure and exclusive ownership

- A journal write failure stops before both the task body and its MP/recovery hook. A dated archive is written first and can recover a truncated compatibility journal. Prior epochs retain their own archives rather than only the latest previous day.
- Required command failures are explicit task errors, remain unfinished, stop dependent work and appear in the close report. Diet execution/turn generation/finish, garbo and the FantasyRealm/PirateRealm CLI workers use this path. Retry clears the recorded error.
- Garbo temporarily disables closet sourcing, restores it afterwards, and cannot start when a fence move fails. Failed unequipping and unknown fence items stop the run. Unfencing removes only observed returned copies from the record; missing quantities remain unreconciled and prevent a complete day.
- The Windows runner holds actual exclusive file handles for both its Mafia root and its account. Account locks use one common directory by default, independent of the chosen Mafia root. Failed contenders do not overwrite the active owner's latest status. Kernel-released handles allow recovery after a crash without an arbitrary stale timer; an older runner's live plain PID remains protected.
- Process handling is scoped to a matching root tag or an absolute jar path in the requested root. Foreign roots are untouched. An unidentifiable relative-jar Mafia process blocks startup before anything is stopped. New launches carry the root tag and use an absolute quoted jar path in a hidden background console.
- Ownership is released even when status writing fails. The ownership tests use real file exclusion but fake process APIs; they do not stop an application or log into an account.

The account lock coordinates cooperating local runners. It cannot prevent manual browser play or another computer from using the same account. Continue the explicit ownership coordination required by the workspace instructions. Use the same AccountLockRoot for every local runner for an account.

Validation commands: tests/smmdaily-tests.sh, tests/kol-daily-diagnostics-tests.ps1 and tests/kol-daily-ownership-tests.ps1. The scorecard is updated only after merge and verification. Live acceptance still requires corrected unattended days and measured economics.

## Cycle 2: recoverable outcomes and attributable run evidence

Journal checkpoints now persist completion, attempt counts, failed commands, explicit retries and absolute Museum turn charges before updating their preference cache. A restart reconstructs them from the journal. An interrupted task still has an uncertain outcome; the journal does not turn an arbitrary game action into an exactly-once transaction. Its game-state checks and attempt ceiling remain necessary. A missing journal segment blocks actions until reconciled, rather than silently authorizing repeated work. The old `goodnight.adv` group is accepted by selector validation as well as child selection.

The runner records the installed code identity before login and again after execution, with a unique run ID and bounded game counters. Fingerprints cover installed ASH/JS, relay code, shipped policy tables, runner modules and the jar; account settings and saved credentials are excluded. Reports distinguish a candidate for live review from verified unattended operation or profit. Contradictory/missing completion markers, changed epochs/players, changed code, nonzero exit or failed diagnostics invalidate that candidate. Atomic status writes retain a complete previous JSON if replacement fails. A wrong-account login stops before custom commands and smmdaily.

Validation adds crash/preference-loss and replay tests, an expected abort on unrecoverable gaps, and fixture tests for source drift, marker ordering, wrong player/day/ascension, echoed commands, failed exits and atomic report replacement. Generated boundary commands are also exercised in the isolated logged-out Mafia. No live game actions are part of this cycle.

## Cycle 3: write-ahead closet transfers

Fence ownership moves from a preference-only record to two versioned files outside Git. Each transfer records its direction, requested copies and pre-transfer inventory/closet counts before sending the game request. Settlement requires matching conserved changes in both containers. The newest complete record wins after a truncated or interrupted mirror write; a final seal detects incomplete rows. Conflicting same-generation records, wrong-player files and ambiguous changes stop work. The preference remains a compatibility cache, and an existing valid legacy ledger migrates without claiming original closet stock.

A restarted daily run stops before its first worker when a transfer is pending or known copies remain fenced. `smmdaily fence-status` reads the recorded and current counts; an explicit `smmdaily unfence` can reconcile conserved changes and return confirmed copies. It refuses ambiguous changes. Missing copies stay recorded. This cannot infer unrelated manual changes that happen to reproduce the same conserved counts, nor recover both lost files and lost preferences without a backup. Garbo's temporary settings restore in a nested finally even when unfencing aborts.

Fake-quantity tests cover lost preferences, crash after put/return, partial transfers, missing stock, legacy migration and mirror write ordering. Expected-abort scenarios cover rejected writes, garbo cleanup, pending startup, ambiguous movement, corrupt records and conflicting records. No game requests are made by those tests.

## Cycle 4: marginal liquidation value

The information-only snapshot confirmed the practical need to distinguish producing copies from selling them when substantial stock already exists. Paid-grind selection now limits the mall premium by recent complete-date demand, a bounded liquidation horizon and a partial market share, after existing non-case stock. Remaining positive copies receive only autosell value. Negative consumed inputs keep their opportunity cost. The full signed holdings estimate remains visible, while history and collection-loss settlement use the more conservative marginal value.

The implementation reuses the tested NPC demand parser and records per-item stock, demand, capacity, quote and marginal estimate outside Git. Pre-liquidity histories migrate to version 4. The model is an explicit conservative assumption, not observed sales or proof that our shop captures the assumed demand. It does not authorize purchases, sell items, or change the cash ledger. Calibration and corrected live samples remain open.
