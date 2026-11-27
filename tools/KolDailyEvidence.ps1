# Read-only source fingerprints and strict evidence extraction. Never read
# settings, saved passwords, sessions or account data for the source manifest.
function Get-KolDailySourceManifest {
 param([string] $MafiaRoot, [string] $JarPath, [string] $RunnerRoot)
 $entries = @()
 foreach ($folder in 'scripts','relay') {
  $base = Join-Path $MafiaRoot $folder
  foreach ($file in (Get-ChildItem -LiteralPath $base -Recurse -File -ErrorAction Stop | Sort-Object FullName)) {
   if ($file.Extension -notin '.ash','.js') { continue }
   $relative = $folder + '/' + $file.FullName.Substring($base.TrimEnd('\','/').Length + 1).Replace('\','/')
   $entries += [pscustomobject]@{path=$relative; sha256=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant()}
  }
 }
 if (-not ($entries | Where-Object path -eq 'scripts/smmdaily.ash')) { throw 'Cannot fingerprint the installed smmdaily.ash' }
 # These are the repository's shipped policy tables, not personal preferences.
 foreach ($name in 'smm-prefs.txt','smm-target-sources.txt','smmFreeCraftingMethods.txt','unrestricted_use_map.txt','unrestricted_pull_map.txt','unrestricted_buy_map.txt') {
  $path = Join-Path $MafiaRoot ('data/' + $name)
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing installed policy table: $name" }
  $entries += [pscustomobject]@{path=('data/' + $name);sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant()}
 }
 foreach ($name in 'Invoke-KolDaily.ps1','KolDailyDiagnostics.ps1','KolDailyOwnership.ps1','KolDailyEvidence.ps1','KolDailyLogin.ps1') {
  $path = Join-Path $RunnerRoot $name
  $entries += [pscustomobject]@{path=('runner/' + $name);sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant()}
 }
 $entries += [pscustomobject]@{path=('jar/' + [IO.Path]::GetFileName($JarPath));sha256=(Get-FileHash -LiteralPath $JarPath -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant()}
 $lines = [string[]]@($entries | ForEach-Object { $_.path + "`t" + $_.sha256 })
 [Array]::Sort($lines, [StringComparer]::Ordinal)
 $sha = [Security.Cryptography.SHA256]::Create()
 try { $digest = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes(($lines -join "`n"))))).Replace('-','').ToLowerInvariant() }
 finally { $sha.Dispose() }
 [pscustomobject]@{algorithm='sha256'; digest=$digest; capturedUtc=[DateTime]::UtcNow.ToString('o'); files=$entries
  scope='Installed ASH/JS in scripts and relay, six shipped policy tables, runner modules and jar. Excludes account preferences, other runtime data and remote services.'}
}

function New-KolDailyBoundaryCommand {
 param([ValidatePattern('^[a-f0-9]{32}$')][string] $RunId, [ValidateSet('START','END')][string] $Boundary)
 'ash print("SMM_DAILY_BOUNDARY ' + $RunId + ' ' + $Boundary + ' " + today_to_string() + ":" + my_ascensions() + ":" + my_id() + " " + total_turns_played() + " " + my_adventures() + " " + my_meat() + " " + my_mp());'
}

function Get-KolDailyRunEvidence {
 param([string] $Text, [string] $RunId, $Before, $After, [string] $Mode, [bool] $RunnerSucceeded)
 $issues = @(); $starts = @(); $ends = @(); $complete = @(); $incomplete = @(); $index = 0
 foreach ($line in ($Text -split '\r?\n')) {
  $clean = ($line -replace '^\s*>\s*','').Trim()
  if ($clean -match ('^SMM_DAILY_BOUNDARY ' + [regex]::Escape($RunId) + ' (START|END) (\d{8}:\d+:\d+) (\d+) (\d+) (\d+) (\d+)$')) {
   $point = [pscustomobject]@{line=$index;epoch=$Matches[2];turns=[long]$Matches[3];adventures=[long]$Matches[4];meat=[long]$Matches[5];mp=[long]$Matches[6]}
   if ($Matches[1] -eq 'START') { $starts += $point } else { $ends += $point }
  }
  if ($clean -eq 'SMM_DAILY_RESULT COMPLETE') { $complete += $index }
  if ($clean -match '^SMM_DAILY_RESULT INCOMPLETE(?:\s|:|$)') { $incomplete += $index }
  $index++
 }
 $stable = $null -ne $Before -and $null -ne $After -and $Before.digest -eq $After.digest
 if (-not $stable) { $issues += 'Missing source manifest or installed code changed during the run' }
 if ($Mode -ne 'Run') { $issues += 'A plan is not an executed day' }
 if (-not $RunnerSucceeded) { $issues += 'Runner diagnostics, login, exit or timeout did not succeed' }
 if ($starts.Count -ne 1 -or $ends.Count -ne 1) { $issues += 'Expected exactly one matching start and end boundary' }
 $start = if ($starts.Count -eq 1) { $starts[0] } else { $null }
 $end = if ($ends.Count -eq 1) { $ends[0] } else { $null }
 if ($start -and $end) {
  if ($start.line -ge $end.line) { $issues += 'Run boundaries are out of order' }
  if ($start.epoch -ne $end.epoch) { $issues += 'Game date, ascension or player changed during the run' }
  if ($start.epoch -match ':0$') { $issues += 'Boundary has no logged-in player' }
  if ($end.turns -lt $start.turns) { $issues += 'Turn counter moved backwards' }
  if ($complete.Count -ne 1 -or $complete[0] -le $start.line -or $complete[0] -ge $end.line) { $issues += 'Expected one complete result inside the run boundaries' }
 }
 if ($incomplete.Count) { $issues += 'An incomplete result was reported' }
 [pscustomobject]@{schemaVersion=1;runId=$RunId;candidateForLiveReview=($issues.Count -eq 0);issues=$issues
  start=$start;end=$end;sourceStable=$stable;sourceBefore=$Before;sourceAfter=$After
  coverage='After login through the runner end boundary. Automatic breakfast is deferred to the recorded daily flow; other configured login hooks can precede this window. Manual intervention, resource reconciliation, realized earnings and Museum ranks require separate review.'}
}

function Write-KolDailyJson {
 param([string] $Path, $Value)
 $full = [IO.Path]::GetFullPath($Path)
 $temp = $full + '.' + [guid]::NewGuid().ToString('N') + '.tmp'
 try {
  [IO.File]::WriteAllText($temp, ($Value | ConvertTo-Json -Depth 12), (New-Object Text.UTF8Encoding $false))
  if ([IO.File]::Exists($full)) { [IO.File]::Replace($temp, $full, [NullString]::Value) }
  else { [IO.File]::Move($temp, $full) }
 } finally { if ([IO.File]::Exists($temp)) { [IO.File]::Delete($temp) } }
}
