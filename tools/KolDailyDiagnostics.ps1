# Pure classification: macro definitions are normal output, actual failures are not.
function Test-KolDailyProblemLine {
 param([AllowEmptyString()][string] $Line)
 $dailyLine = ($Line -replace '^\s*>\s*', '').Trim()
 if (-not $dailyLine) { return $false }
 if ($dailyLine -match '^(Preference |executing script:|Macro:|commandBufferGCLI|ash if \(my_name)') { return $false }
 if ($dailyLine -match '^doMainLoop:.*in combat\? false, aborted\? false$') { return $false }
 if ($dailyLine -match '^WARNING: (A restricted method|java\.lang\.System|Use --enable-native-access|Restricted methods)') { return $false }
 $dailyFailures = @(
  'Unexpected error', 'Exception', 'debug log', 'aborted', 'ABORT', 'DAILY-RUNNER: not logged in', 'DAILY-RUNNER: wrong or missing account',
  'You are not logged in', 'Login failed', 'No password saved', 'Could not log in', 'Too many login', 'incorrect password',
  'marked failed', 'failed earlier today', 'still in a fight', 'could not write the journal', 'no phase or task is called',
  'Script parsing error', 'Unknown variable', 'Unknown function', 'ambiguous', 'matches more than one',
  'Nightly maintenance', 'timed out', 'Connection refused', 'could not be found',
  'cannot run now', 'finish the current fight or choice', 'SMM_DAILY_RESULT INCOMPLETE',
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
