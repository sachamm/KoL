# Exclusive local runner ownership; acquiring a lease never logs into KoL.
function Get-KolDailyLockKey([string] $Value) {
 $dailyBytes = [Text.Encoding]::UTF8.GetBytes($Value.Trim().Normalize().ToLowerInvariant())
 $dailySha = [Security.Cryptography.SHA256]::Create()
 try { return ([BitConverter]::ToString($dailySha.ComputeHash($dailyBytes))).Replace('-', '').ToLowerInvariant() }
 finally { $dailySha.Dispose() }
}
function Open-KolDailyLease([string] $Path, [hashtable] $Owner) {
 $dailyStream = $null
 try {
  $dailyStream = [IO.File]::Open($Path, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
  $dailyReader = [IO.StreamReader]::new($dailyStream, [Text.Encoding]::UTF8, $true, 1024, $true)
  try { $dailyPrior = $dailyReader.ReadToEnd().Trim() } finally { $dailyReader.Dispose() }
  # An older runner used a plain PID without holding a file handle.
  $dailyPriorPid = 0
  if ([int]::TryParse($dailyPrior, [ref]$dailyPriorPid) -and $dailyPriorPid -gt 0 -and (Get-Process -Id $dailyPriorPid -ErrorAction SilentlyContinue)) {
   throw 'An older runner still owns this root; no process was stopped.'
  }
  $dailyPayload = [Text.Encoding]::UTF8.GetBytes(($Owner | ConvertTo-Json -Compress))
  $dailyStream.SetLength(0); $dailyStream.Position = 0
  $dailyStream.Write($dailyPayload, 0, $dailyPayload.Length); $dailyStream.Flush($true)
  return $dailyStream
 } catch {
  if ($dailyStream) { $dailyStream.Dispose() }
  throw "Cannot acquire exclusive KoL ownership at $Path : $($_.Exception.Message)"
 }
}
function Enter-KolDailyOwnership([string] $MafiaRoot, [string] $Username, [string] $AccountLockRoot) {
 if ([string]::IsNullOrWhiteSpace($Username)) { throw 'An account name is required for ownership.' }
 $dailyRoot = [IO.Path]::GetFullPath($MafiaRoot).TrimEnd([IO.Path]::DirectorySeparatorChar)
 $dailyLogRoot = Join-Path $dailyRoot 'runlogs\daily'
 $null = New-Item -ItemType Directory -Force -Path $dailyLogRoot, $AccountLockRoot
 $dailyOwner = @{ pid=$PID; account=$Username; root=$dailyRoot; acquired=[DateTime]::UtcNow.ToString('o') }
 $dailyRootLease = $null; $dailyAccountLease = $null
 try {
  $dailyRootLease = Open-KolDailyLease (Join-Path $dailyLogRoot 'runner.lock') $dailyOwner
  $dailyAccountLease = Open-KolDailyLease (Join-Path $AccountLockRoot ((Get-KolDailyLockKey $Username) + '.lock')) $dailyOwner
  return [pscustomobject]@{ Root=$dailyRootLease; Account=$dailyAccountLease }
 } catch {
  if ($dailyAccountLease) { $dailyAccountLease.Dispose() }
  if ($dailyRootLease) { $dailyRootLease.Dispose() }
  throw
 }
}
function Exit-KolDailyOwnership($Lease) {
 if ($Lease) {
  if ($Lease.Account) { $Lease.Account.Dispose() }
  if ($Lease.Root) { $Lease.Root.Dispose() }
 }
}
function Get-KolDailyProcessDisposition([string] $CommandLine, [string] $MafiaRoot) {
 if ($CommandLine -notmatch '(?i)KoLmafia[^\s"/\\]*\.jar') { return 'unrelated' }
 $dailyTagPatterns = @('(?:^|\s)"-Dcodex\.kol\.root=([^"]+)"', '(?:^|\s)-Dcodex\.kol\.root="([^"]+)"', '(?:^|\s)-Dcodex\.kol\.root=([^\s"]+)')
 $dailyPath = $null
 foreach ($dailyPattern in $dailyTagPatterns) { if ($CommandLine -match $dailyPattern) { $dailyPath=$Matches[1]; break } }
 if (-not $dailyPath -and $CommandLine -match '(?:^|\s)-jar\s+(?:"([^"]+)"|([^\s"]+))') {
  $dailyJar = if ($Matches[1]) { $Matches[1] } else { $Matches[2] }
  if ([IO.Path]::IsPathRooted($dailyJar)) { $dailyPath = [IO.Path]::GetDirectoryName($dailyJar) }
 }
 if (-not $dailyPath) { return 'unknown' }
 try {
  $dailyCandidate = [IO.Path]::GetFullPath($dailyPath).TrimEnd([IO.Path]::DirectorySeparatorChar)
  $dailyExpected = [IO.Path]::GetFullPath($MafiaRoot).TrimEnd([IO.Path]::DirectorySeparatorChar)
  if ([StringComparer]::OrdinalIgnoreCase.Equals($dailyCandidate, $dailyExpected)) { return 'owned' }
  return 'foreign'
 } catch { return 'unknown' }
}
