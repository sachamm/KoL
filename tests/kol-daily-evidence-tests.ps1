$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\tools\KolDailyEvidence.ps1')
. (Join-Path $PSScriptRoot '..\tools\KolDailyDiagnostics.ps1')
$checks = 0
function Assert-Evidence([bool] $Ok, [string] $Reason) { $script:checks++; if (-not $Ok) { throw $Reason } }
$fixture = Join-Path $PSScriptRoot ('.runtime\evidence\' + [guid]::NewGuid().ToString('N'))
$root = Join-Path $fixture 'mafia'; $runner = Join-Path $fixture 'runner'
$null = New-Item -ItemType Directory -Force -Path $runner,(Join-Path $root 'scripts'),(Join-Path $root 'relay'),(Join-Path $root 'data'),(Join-Path $root 'settings')
Set-Content (Join-Path $root 'scripts/smmdaily.ash') 'fixture script'
Set-Content (Join-Path $root 'scripts/dependency.js') 'fixture dependency'
Set-Content (Join-Path $root 'relay/relay.ash') 'fixture relay'
Set-Content (Join-Path $root 'settings/passwords.txt') 'fixture only: never read'
$jar = Join-Path $root 'KoLmafia-00000.jar'; Set-Content $jar 'fixture jar, never executed'
foreach ($name in 'smm-prefs.txt','smm-target-sources.txt','smmFreeCraftingMethods.txt','unrestricted_use_map.txt','unrestricted_pull_map.txt','unrestricted_buy_map.txt') { Set-Content (Join-Path $root ('data/' + $name)) 'fixture policy' }
foreach ($name in 'Invoke-KolDaily.ps1','KolDailyDiagnostics.ps1','KolDailyOwnership.ps1','KolDailyEvidence.ps1','KolDailyLogin.ps1') { Set-Content (Join-Path $runner $name) 'fixture runner' }
$before = Get-KolDailySourceManifest $root $jar $runner
$again = Get-KolDailySourceManifest $root $jar $runner
Assert-Evidence ($before.digest -eq $again.digest) 'Capture time must not alter the content fingerprint'
Assert-Evidence ($before.files.Count -eq 15) 'Manifest includes all selected source, policy, runner and jar files'
Set-Content (Join-Path $root 'settings/passwords.txt') 'changed ignored fixture'
Assert-Evidence ((Get-KolDailySourceManifest $root $jar $runner).digest -eq $before.digest) 'Account settings stay outside the source manifest'
foreach ($path in (Join-Path $root 'scripts/dependency.js'),(Join-Path $root 'data/smm-prefs.txt'),(Join-Path $runner 'Invoke-KolDaily.ps1'),(Join-Path $runner 'KolDailyLogin.ps1'),$jar) {
 $old = Get-Content -LiteralPath $path -Raw
 Add-Content -LiteralPath $path 'changed'
 Assert-Evidence ((Get-KolDailySourceManifest $root $jar $runner).digest -ne $before.digest) "Changed source must change fingerprint: $path"
 [IO.File]::WriteAllText($path,$old)
}
$id = '0123456789abcdef0123456789abcdef'
$start = "SMM_DAILY_BOUNDARY $id START 20261126:5:123 100 10 5000 2000"
$end = "SMM_DAILY_BOUNDARY $id END 20261126:5:123 105 5 5500 1900"
$complete = 'SMM_DAILY_RESULT COMPLETE'
$text = @('ash print("SMM_DAILY_RESULT COMPLETE");',$start,'> SMM_DAILY_RESULT COMPLETE',$end) -join "`n"
$good = Get-KolDailyRunEvidence $text $id $before $before 'Run' $true
Assert-Evidence $good.candidateForLiveReview 'One ordered same-epoch completion with stable source is a review candidate'
Assert-Evidence ($good.start.turns -eq 100 -and $good.end.turns -eq 105) 'Actual boundary counters are parsed, echoed commands are excluded'
Assert-Evidence ($good.coverage -match 'Manual intervention.*separate review') 'Candidate evidence must not claim to prove no manual intervention'
# Replayed history can coexist with a corrected current completion. Current
# stops and missing completion must remain disqualifying after classification.
$history = '00:01:02 END garbo | turns 100, adv 20, Meat 5000, MP 100 | command failed: fixture'
$recoveredText = @($start,'errorOnAmbiguousFold => false',$history,$complete,$end) -join "`n"
$diagnosticProblems = @($recoveredText -split "`n" | Where-Object { Test-KolDailyProblemLine $_ })
Assert-Evidence ($diagnosticProblems.Count -eq 0) 'Historic failure and setting echo do not become current diagnostics'
Assert-Evidence (Get-KolDailyRunEvidence $recoveredText $id $before $before 'Run' ($diagnosticProblems.Count -eq 0)).candidateForLiveReview 'Corrected completion can pass with historical journal failures'
$heldText = $recoveredText + "`nsmmDaily: stopped after garbo: paid work remains held"
$heldProblems = @($heldText -split "`n" | Where-Object { Test-KolDailyProblemLine $_ })
Assert-Evidence (-not (Get-KolDailyRunEvidence $heldText $id $before $before 'Run' ($heldProblems.Count -eq 0)).candidateForLiveReview) 'Current held task still invalidates a completion claim'
Assert-Evidence (-not (Get-KolDailyRunEvidence ($recoveredText.Replace($complete,'')) $id $before $before 'Run' $true).candidateForLiveReview) 'Ignoring history never substitutes for actual current completion'
$invalid = @(
 @{why='missing end';text=($start+"`n"+$complete)},
 @{why='duplicate start';text=($start+"`n"+$text)},
 @{why='end before start';text=($end+"`n"+$complete+"`n"+$start)},
 @{why='rollover';text=($text.Replace('END 20261126','END 20261127'))},
 @{why='different player';text=($text.Replace('END 20261126:5:123','END 20261126:5:124'))},
 @{why='ascension changed';text=($text.Replace('END 20261126:5:123','END 20261126:6:123'))},
 @{why='backward turns';text=($text.Replace(':123 105',':123 99'))},
 @{why='contradictory incomplete';text=($text+"`nSMM_DAILY_RESULT INCOMPLETE: fixture")},
 @{why='bare incomplete';text=($text+"`nSMM_DAILY_RESULT INCOMPLETE")},
 @{why='logged out';text=($text.Replace(':5:123',':5:0'))},
 @{why='only echoed result';text=($start+"`nash print(`"SMM_DAILY_RESULT COMPLETE`" );`n"+$end)},
 @{why='complete outside boundaries';text=($complete+"`n"+$start+"`n"+$end)},
 @{why='duplicate result';text=($start+"`n"+$complete+"`n"+$complete+"`n"+$end)},
 @{why='wrong run ID';text=($text.Replace($id,('f'*32)))}
)
foreach ($case in $invalid) { Assert-Evidence (-not (Get-KolDailyRunEvidence $case.text $id $before $before 'Run' $true).candidateForLiveReview) $case.why }
Assert-Evidence (-not (Get-KolDailyRunEvidence $text $id $before $before 'Plan' $true).candidateForLiveReview) 'A plan never counts as a live executed run'
Assert-Evidence (-not (Get-KolDailyRunEvidence $text $id $before $before 'Run' $false).candidateForLiveReview) 'Timeout, failed login, exit or diagnostics prevent review candidacy'
$changed = [pscustomobject]@{digest='different'}
Assert-Evidence (-not (Get-KolDailyRunEvidence $text $id $before $changed 'Run' $true).candidateForLiveReview) 'Source changes invalidate evidence'
Assert-Evidence (-not (Get-KolDailyRunEvidence $text $id $before $null 'Run' $true).candidateForLiveReview) 'Missing final fingerprint invalidates evidence'
$command = New-KolDailyBoundaryCommand $id 'START'
Assert-Evidence ($command -match 'total_turns_played\(\)' -and $command -match 'my_id\(\)' -and $command -match 'START') 'Boundary command reads built-in game counters only'
$jsonPath = Join-Path $fixture 'result.json'
Write-KolDailyJson $jsonPath @{value='first'}
Write-KolDailyJson $jsonPath @{value='second'}
Assert-Evidence ((Get-Content $jsonPath -Raw | ConvertFrom-Json).value -eq 'second') 'Atomic JSON writing replaces an existing report'
Assert-Evidence (@(Get-ChildItem $fixture -Filter '*.tmp').Count -eq 0) 'Atomic writing leaves no temporary files after success'

# Execute the actual runner command construction, without a process or login.
$tokens=$null; $errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot '..\tools\Invoke-KolDaily.ps1'),[ref]$tokens,[ref]$errors)
Assert-Evidence ($errors.Count -eq 0) 'Updated runner parses'
$source = $ast.Extent.Text
Assert-Evidence ($source.IndexOf('$sourceBefore = Get-KolDailySourceManifest') -lt $source.IndexOf('$r = Invoke-MafiaCli')) 'Installed source identity is captured before login'
Assert-Evidence ($source -match 'my_name\(\).to_lower_case\(\) !=') 'Runner refuses the wrong account before the daily command'
Assert-Evidence ($source -match '\$r.ExitCode -ne 0') 'Nonzero Mafia exit is an explicit error'
Write-Output "PASS kol-daily-evidence: $checks checks; fixtures only, no game actions"
