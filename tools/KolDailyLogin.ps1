# Borrow only automatic-login flags while Mafia is stopped and the caller
# owns both leases. The recovery journal contains no credentials.
function Get-KolDailyLoginKeys([string] $Username) {
 $userKey = $Username.Trim().ToLowerInvariant().Replace('\','\\').Replace(' ','\ ').Replace('=','\=').Replace(':','\:')
 @('getBreakfast', ('getBreakfast.' + $userKey), 'gitUpdateOnLogin', 'svnUpdateOnLogin')
}

function Set-KolDailyLoginRows([string] $GlobalPath, $Rows) {
 $lines = [Collections.Generic.List[string]]::new()
 foreach ($line in [IO.File]::ReadAllLines($GlobalPath)) {
  $selected = $false
  foreach ($row in $Rows) { if ($line.StartsWith($row.key + '=', [StringComparison]::Ordinal)) { $selected = $true; break } }
  if (-not $selected) { $lines.Add($line) }
 }
 foreach ($row in $Rows) { if ($row.present) { $lines.Add($row.line) } }
 $temp = $GlobalPath + '.' + [guid]::NewGuid().ToString('N') + '.tmp'
 try {
  [IO.File]::WriteAllLines($temp, $lines, [Text.UTF8Encoding]::new($false))
  [IO.File]::Replace($temp, $GlobalPath, [NullString]::Value)
 } finally { if ([IO.File]::Exists($temp)) { [IO.File]::Delete($temp) } }
}

function Restore-KolDailyLoginGuard([string] $MafiaRoot) {
 $root = [IO.Path]::GetFullPath($MafiaRoot).TrimEnd('\','/')
 $journal = Join-Path $root 'runlogs/daily/login-settings.json'
 if (-not [IO.File]::Exists($journal)) { return $false }
 $saved = [IO.File]::ReadAllText($journal) | ConvertFrom-Json -ErrorAction Stop
 if ($saved.schemaVersion -ne 1 -or [string]::IsNullOrWhiteSpace($saved.root) -or -not [StringComparer]::OrdinalIgnoreCase.Equals([IO.Path]::GetFullPath($saved.root).TrimEnd('\','/'), $root) -or [string]::IsNullOrWhiteSpace($saved.username) -or $saved.username -match '[\r\n\t]') {
  throw 'Login-settings recovery journal is invalid; no login is authorized.'
 }
 $keys = @(Get-KolDailyLoginKeys $saved.username)
 $rows = @($saved.rows)
 if ($rows.Count -ne $keys.Count) { throw 'Login-settings recovery rows are incomplete.' }
 for ($i = 0; $i -lt $keys.Count; $i++) {
  $row = $rows[$i]
  if ($row.key -cne $keys[$i] -or $row.present -isnot [bool] -or
      ($row.present -and $row.line -cnotmatch ('^' + [regex]::Escape($row.key) + '=(true|false)$')) -or
      (-not $row.present -and $row.line -ne '')) { throw 'Login-settings recovery contains an unexpected preference.' }
 }
 Set-KolDailyLoginRows (Join-Path $root 'settings/GLOBAL_prefs.txt') $rows
 [IO.File]::Delete($journal)
 return $true
}

function Enter-KolDailyLoginGuard([string] $MafiaRoot, [string] $Username) {
 if ([string]::IsNullOrWhiteSpace($Username) -or $Username -match '[\r\n\t]') { throw 'A valid login account is required.' }
 $root = [IO.Path]::GetFullPath($MafiaRoot).TrimEnd('\','/')
 $null = Restore-KolDailyLoginGuard $root
 $path = Join-Path $root 'settings/GLOBAL_prefs.txt'
 $lines = [IO.File]::ReadAllLines($path)
 $rows = @()
 foreach ($key in (Get-KolDailyLoginKeys $Username)) {
  $preferenceRows = @($lines | Where-Object { $_.StartsWith($key + '=', [StringComparison]::Ordinal) })
  if ($preferenceRows.Count -gt 1 -or ($preferenceRows.Count -eq 1 -and $preferenceRows[0] -cnotmatch ('^' + [regex]::Escape($key) + '=(true|false)$'))) {
   throw 'Automatic-login preferences are ambiguous; no login is authorized.'
  }
  $rows += [pscustomobject]@{key=$key;present=($preferenceRows.Count -eq 1);line=$(if ($preferenceRows.Count) { $preferenceRows[0] } else { '' })}
 }
 $journal = Join-Path $root 'runlogs/daily/login-settings.json'
 $null = New-Item -ItemType Directory -Force -Path (Split-Path $journal)
 Write-KolDailyJson $journal ([ordered]@{schemaVersion=1;root=$root;username=$Username;rows=$rows})
 $disabled = @($rows | ForEach-Object { [pscustomobject]@{key=$_.key;present=$true;line=($_.key + '=false')} })
 Set-KolDailyLoginRows $path $disabled
}
