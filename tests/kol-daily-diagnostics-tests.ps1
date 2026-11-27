$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\tools\KolDailyDiagnostics.ps1')
$diagnosticCases = @(
 @{Line='> executing script: abort missed 8;abort hppercentbelow 20;use blue rocket;'; Error=$false},
 @{Line='executing script: abort pastround 25;skill sing along;'; Error=$false},
 @{Line='> doMainLoop: stopping automation at the first execution. in combat? false, aborted? false'; Error=$false},
 @{Line='Preference lastMacroError changed from x to Macro Aborted'; Error=$false},
 @{Line='> You''re on your own, partner. (Macro Aborted ("abort hppercentbelow 20"))'; Error=$true},
 @{Line='> doMainLoop: stopping automation at the first execution. in combat? true, aborted? true'; Error=$true},
 @{Line='Could not match item(s) for use: use blue rocket'; Error=$true},
 @{Line='smmDaily: goodnight.adv.fax started 2 times without finishing; marked failed for today.'; Error=$true},
 @{Line='SMM_DAILY_RESULT INCOMPLETE: failed task goodnight.adv.fax'; Error=$true},
 @{Line='SMM_DAILY_RESULT COMPLETE'; Error=$false},
 @{Line='smmDaily: combat preparation needs 60000 HP after dressing'; Error=$true},
 @{Line=''; Error=$false}
 @{Line='DAILY-RUNNER: wrong or missing account'; Error=$true},
 @{Line='smmDaily: journal gap requires reconciliation from a backup before more tasks may run'; Error=$true}
 @{Line='smmDaily: pending fence transfer; inspect smmdaily fence-status'; Error=$true},
 @{Line='smmDaily: conflicting fence records require reconciliation; no closet move was authorized'; Error=$true}
 @{Line='SMM_DAILY_PRICE_AUDIT UNVERIFIED'; Error=$true},
 @{Line='SMM_DAILY_PRICE_AUDIT POTENTIAL_OVERPAYMENT'; Error=$true},
 @{Line='SMM_DAILY_PRICE_AUDIT VERIFIED_REQUEST_CAPS'; Error=$false},
 @{Line='errorOnAmbiguousFold => false'; Error=$false},
 @{Line='> errorOnAmbiguousFold => true'; Error=$false},
 @{Line='00:01:02 END garbo | turns 100, adv 20, Meat 5000, MP 100 | command failed: fixture; done-test still false'; Error=$false},
 @{Line='00:01:02 STOP garbo | turns 100, adv 20, Meat 5000, MP 100 | command failed: fixture; this task remains unfinished'; Error=$false},
 @{Line='00:01:02 NOTE close.book | turns 100, adv 20, Meat 5000, MP 100 | financial review required'; Error=$false},
 @{Line='smmDaily: stopped after garbo: paid farming remains held; this task remains unfinished'; Error=$true},
 @{Line='smmDaily: command failed: fixture'; Error=$true},
 @{Line='00:01:02 END garbo | command failed: fixture'; Error=$true},
 @{Line='00:01:02 Exception: fixture'; Error=$true},
 @{Line='00:01:02 UNKNOWN garbo | turns 100, adv 20, Meat 5000, MP 100 | command failed: fixture'; Error=$true},
 @{Line='errorOnAmbiguousFold => unexpected failure'; Error=$true}
)
foreach ($diagnosticCase in $diagnosticCases) {
 if ((Test-KolDailyProblemLine $diagnosticCase.Line) -ne $diagnosticCase.Error) { throw "Unexpected classification: $($diagnosticCase.Line)" }
}
$complete = "Script verification complete.`n> Script verification complete.`nScript verification complete.`r`nScript verification complete."
$compileCases = @(
 @{Result=[pscustomobject]@{Text=$complete;TimedOut=$false;ExitCode=0};Error=$false},
 @{Result=[pscustomobject]@{Text='Unknown variable import';TimedOut=$false;ExitCode=0};Error=$true},
 @{Result=[pscustomobject]@{Text='Script verification complete.';TimedOut=$false;ExitCode=0};Error=$true},
 @{Result=[pscustomobject]@{Text=($complete+"`nScript verification complete.");TimedOut=$false;ExitCode=0};Error=$true},
 @{Result=[pscustomobject]@{Text=$complete;TimedOut=$true;ExitCode=0};Error=$true},
 @{Result=[pscustomobject]@{Text=$complete;TimedOut=$false;ExitCode=1};Error=$true},
 @{Result=[pscustomobject]@{Text=(@('ash print("Script verification complete.");') * 4 -join "`n");TimedOut=$false;ExitCode=0};Error=$true},
 @{Result=$null;Error=$true}
)
foreach ($compileCase in $compileCases) {
 $problem = Get-KolDailyCompileProblem $compileCase.Result 4
 if ([bool]$problem -ne $compileCase.Error) { throw 'Compilation gate accepted incomplete or failed evidence.' }
}
$runnerTokens = $null; $runnerErrors = $null
$null = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot '..\tools\Invoke-KolDaily.ps1'), [ref]$runnerTokens, [ref]$runnerErrors)
if ($runnerErrors.Count) { throw ($runnerErrors | Out-String) }
$runnerText = Get-Content (Join-Path $PSScriptRoot '..\tools\Invoke-KolDaily.ps1') -Raw
if ($runnerText.IndexOf('Enter-KolDailyOwnership $MafiaRoot') -lt 0 -or $runnerText.IndexOf('Enter-KolDailyOwnership $MafiaRoot') -gt $runnerText.IndexOf('Stop-Mafia', $runnerText.IndexOf('Daily runner starting:'))) { throw 'Ownership must precede process handling' }
if (-not $runnerText.Contains('finally { Exit-KolDailyOwnership $ownership }')) { throw 'Ownership must release even if status writing fails' }
if ($runnerText.IndexOf('$compileResult = Invoke-MafiaCli') -gt $runnerText.IndexOf('Enter-KolDailyLoginGuard $MafiaRoot')) { throw 'Compilation must pass before login settings and account actions' }
Write-Output "PASS kol-daily-diagnostics: $($diagnosticCases.Count + $compileCases.Count) cases; runner parses; compilation and exclusive ownership guards preserved"
