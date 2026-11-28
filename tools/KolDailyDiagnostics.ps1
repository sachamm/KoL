# Pure classification: macro definitions are normal output, actual failures are not.
function Get-KolDailyCompileProblem {
 param($Result, [int] $Expected)
 if ($null -eq $Result -or $Expected -lt 1) { return 'Missing compilation evidence.' }
 if ($Result.TimedOut -or $Result.ExitCode -ne 0) { return 'Compilation process did not finish successfully.' }
 $completed = [regex]::Matches([string]$Result.Text, '(?m)^[\t >]*Script verification complete\.[\t ]*\r?$').Count
 if ($completed -ne $Expected) { return "Compilation confirmed $completed of $Expected entry points; no login is authorized." }
 return ''
}

function Test-KolDailyProblemLine {
 param([AllowEmptyString()][string] $Line)
 $dailyLine = ($Line -replace '^\s*>\s*', '').Trim()
 if (-not $dailyLine) { return $false }
 if ($dailyLine -match '^(Preference |executing script:|Macro:|commandBufferGCLI|ash if \(my_name)') { return $false }
 # These are setting echoes and rendered journal history, not fresh failures.
 # Current stops have their own smmDaily message below; strict completion
 # evidence still requires a result inside this run's boundaries.
 if ($dailyLine -match '^errorOnAmbiguousFold => (true|false)$') { return $false }
 if ($dailyLine -match '^\d{2}:\d{2}:\d{2} (BEGIN|END|NOTE|SKIP|STOP|FAIL|RETRY) [A-Za-z0-9_.-]+ \| turns \d+, adv \d+, Meat -?\d+, MP \d+ \| ') { return $false }
 if ($dailyLine -match '^doMainLoop:.*in combat\? false, aborted\? false$') { return $false }
 if ($dailyLine -match '^WARNING: (A restricted method|java\.lang\.System|Use --enable-native-access|Restricted methods)') { return $false }
 $dailyFailures = @(
  'Unexpected error', 'Exception', 'debug log', 'aborted', 'ABORT', 'DAILY-RUNNER: not logged in', 'DAILY-RUNNER: wrong or missing account',
  'You are not logged in', 'Login failed', 'No password saved', 'Could not log in', 'Too many login', 'incorrect password',
  'marked failed', 'failed earlier today', 'still in a fight', 'could not write the journal', 'no phase or task is called',
  'Script parsing error', 'Unknown variable', 'Unknown function', 'ambiguous', 'matches more than one',
  'Nightly maintenance', 'timed out', 'Connection refused', 'could not be found',
  'cannot run now', 'finish the current fight or choice', 'SMM_DAILY_RESULT INCOMPLETE', 'smmDaily: stopped after ', 'SMM_DAILY_AUDIT SKIPPED',
  'Could not match item(s) for use', 'no safe affordable overdrunk spell', 'combat preparation needs',
  'could not save opening Display Case', 'could not write the', 'journal gap requires reconciliation', 'fenced items remain unreconciled', 'garbo was not started', 'command failed:',
  'pending fence transfer', 'unreadable fence records', 'conflicting fence records', 'invalid legacy fence record', 'fenced items remain from an earlier run',
  'SMM_DAILY_PRICE_AUDIT UNVERIFIED', 'SMM_DAILY_PRICE_AUDIT POTENTIAL_OVERPAYMENT', 'financial review required', 'recorded spending exceeds the shared cap'
 )
 foreach ($dailyFailure in $dailyFailures) {
  if ($dailyLine -match [regex]::Escape($dailyFailure)) { return $true }
 }
 return $false
}
