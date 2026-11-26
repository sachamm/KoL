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
