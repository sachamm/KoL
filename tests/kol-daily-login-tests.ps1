$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\tools\KolDailyEvidence.ps1')
. (Join-Path $PSScriptRoot '..\tools\KolDailyLogin.ps1')
$checks = 0
function Assert-Login([bool] $Ok, [string] $Why) { $script:checks++; if (-not $Ok) { throw $Why } }
function Assert-Refused([scriptblock] $Action, [string] $Why) { $refused = $false; try { & $Action } catch { $refused = $true }; Assert-Login $refused $Why }
$root = Join-Path $PSScriptRoot ('.runtime\login\' + [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Force (Join-Path $root 'settings')
$globalPath = Join-Path $root 'settings/GLOBAL_prefs.txt'
$journal = Join-Path $root 'runlogs/daily/login-settings.json'
$original = @('getBreakfast=true','getBreakfast.fixture\ user=true','gitUpdateOnLogin=false','svnUpdateOnLogin=true','token=fixture-secret','other=keep')
[IO.File]::WriteAllLines($globalPath,$original)
Enter-KolDailyLoginGuard $root 'Fixture User'
$disabled = [IO.File]::ReadAllLines($globalPath)
foreach ($key in (Get-KolDailyLoginKeys 'Fixture User')) { Assert-Login ($disabled -ccontains ($key + '=false')) "Login flag is disabled: $key" }
Assert-Login ($disabled -contains 'token=fixture-secret' -and $disabled -contains 'other=keep') 'Unrelated settings are preserved'
$snapshot = [IO.File]::ReadAllText($journal)
Assert-Login ($snapshot -notmatch 'fixture-secret|other=keep') 'Recovery journal contains only selected flags, never unrelated settings'
Add-Content $globalPath 'nativeNewPref=kept'
Assert-Login (Restore-KolDailyLoginGuard $root) 'A completed or failed login can restore its guard'
$restored = [IO.File]::ReadAllLines($globalPath)
foreach ($line in $original) { Assert-Login ($restored -ccontains $line) "Original fixture row restored: $($line.Split('=')[0])" }
Assert-Login ($restored -contains 'nativeNewPref=kept') 'Restoration preserves preferences newly written by Mafia'
Assert-Login (-not (Test-Path $journal)) 'Recovery journal is removed only after successful restoration'
Assert-Login (-not (Restore-KolDailyLoginGuard $root)) 'Repeated restoration is an idempotent no-op'

# Simulate a dead runner: a second entry must recover the original values,
# rather than adopting the interrupted false flags as the user's defaults.
Enter-KolDailyLoginGuard $root 'Fixture User'
Enter-KolDailyLoginGuard $root 'Fixture User'
$null = Restore-KolDailyLoginGuard $root
Assert-Login ([IO.File]::ReadAllLines($globalPath) -ccontains 'getBreakfast=true') 'A subsequent run recovers an interrupted guard before taking its snapshot'
Enter-KolDailyLoginGuard $root 'Fixture User'
Assert-Login (Restore-KolDailyLoginGuard ($root + '/')) 'Equivalent root spelling does not block recovery'

[IO.File]::WriteAllLines($globalPath,@('other=keep'))
Enter-KolDailyLoginGuard $root 'Fixture User'
$null = Restore-KolDailyLoginGuard $root
Assert-Login (([IO.File]::ReadAllLines($globalPath) -join "`n") -ceq 'other=keep') 'Originally absent flags remain absent after restoration'

[IO.File]::WriteAllLines($globalPath,$original)
Enter-KolDailyLoginGuard $root 'Fixture User'
$validSnapshot = [IO.File]::ReadAllText($journal)
$beforeHash = (Get-FileHash $globalPath).Hash
foreach ($fault in 'schema','root','rows','key','username','truncated') {
 $bad = $validSnapshot | ConvertFrom-Json
 switch ($fault) {
  schema { $bad.schemaVersion = 99 }
  root { $bad.root = $root + '-other' }
  rows { $bad.rows = @($bad.rows[0]) }
  key { $bad.rows[0].key = 'token'; $bad.rows[0].line = 'token=true' }
  username { $bad.username = "Fixture`nInjected" }
 }
 if ($fault -eq 'truncated') { [IO.File]::WriteAllText($journal,'{') }
 else { Write-KolDailyJson $journal $bad }
 Assert-Refused { Restore-KolDailyLoginGuard $root } "Invalid $fault recovery refuses before changing preferences"
 Assert-Login ((Get-FileHash $globalPath).Hash -eq $beforeHash -and (Test-Path $journal)) 'Invalid recovery preserves current file and evidence'
}
[IO.File]::WriteAllText($journal,$validSnapshot)
$null = Restore-KolDailyLoginGuard $root
Add-Content $globalPath 'getBreakfast=true'
Assert-Refused { Enter-KolDailyLoginGuard $root 'Fixture User' } 'Duplicate automatic-login flags refuse before login'
Assert-Login (-not (Test-Path $journal)) 'Ambiguous originals do not create a misleading recovery snapshot'
[IO.File]::WriteAllLines($globalPath,@('gitUpdateOnLogin=unexpected','other=keep'))
Assert-Refused { Enter-KolDailyLoginGuard $root 'Fixture User' } 'Malformed original flag refuses before login'

$runner = Get-Content (Join-Path $PSScriptRoot '..\tools\Invoke-KolDaily.ps1') -Raw
Assert-Login ($runner.IndexOf('Enter-KolDailyLoginGuard $MafiaRoot') -lt $runner.IndexOf('$r = Invoke-MafiaCli')) 'Login settings are fenced before launching the login process'
Assert-Login ($runner.Contains('Restore-KolDailyLoginGuard $MafiaRoot')) 'Runner finally restores settings after its process terminates'
Assert-Login ($runner.LastIndexOf('Stop-Mafia') -lt $runner.LastIndexOf('Restore-KolDailyLoginGuard $MafiaRoot') -and $runner.LastIndexOf('Stop-Mafia') -gt $runner.IndexOf('$r = Invoke-MafiaCli')) 'Exceptional cleanup stops an owned child before restoring login flags'
Write-Output "PASS kol-daily-login: $checks checks; fixture preferences only, no login or game action"
