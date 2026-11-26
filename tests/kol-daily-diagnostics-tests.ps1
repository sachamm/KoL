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
)
foreach ($diagnosticCase in $diagnosticCases) {
 if ((Test-KolDailyProblemLine $diagnosticCase.Line) -ne $diagnosticCase.Error) { throw "Unexpected classification: $($diagnosticCase.Line)" }
}
$runnerTokens = $null; $runnerErrors = $null
$null = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot '..\tools\Invoke-KolDaily.ps1'), [ref]$runnerTokens, [ref]$runnerErrors)
if ($runnerErrors.Count) { throw ($runnerErrors | Out-String) }
Write-Output "PASS kol-daily-diagnostics: $($diagnosticCases.Count) cases; runner parses"
