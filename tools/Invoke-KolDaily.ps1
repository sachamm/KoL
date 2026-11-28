<#
  Nightly KoLmafia run for Tquilla on this PC.

  1. Acquires exclusive root/account ownership; closes only Mafia processes identified with this root.
  2. Installs the newest KoLmafia jar from github.com/kolmafia/kolmafia releases.
  3. Runs `git update` (sachamm/KoL, KoLUtils and the other git installs) logged out,
     and moves aside scripts the repo no longer ships that would shadow new ones
     (diet.js after diet.ash replaced it).
  4. Defers automatic breakfast to day.open/mp.bootstrap and freezes login updates;
     starts KoLmafia in CLI mode, logs in with the saved password (`login Tquilla`),
     runs `smmdaily run`, then `smmdaily status` and the journal tail, and exits.
  5. Writes a log and a status file (runlogs\daily\latest.json) listing anything
     that looks like an error, for the scheduled check to report.

  No password is stored here: `login <name>` uses the password KoLmafia saved
  when "save password" was ticked in the GUI.

  -Mode Plan still logs in with automatic breakfast disabled, then prints the plan.
  Other configured login hooks can act; Plan is not a read-only account API.
  For read-only inspection use the existing session; do not start this runner.
  -SkipJarUpdate / -SkipGitUpdate skip those steps.
#>
[CmdletBinding()]
param(
  [ValidateSet('Run', 'Plan')] [string] $Mode = 'Run',
  [ValidatePattern('^[^;"\\\r\n]+$')] [string] $Username = 'Tquilla',
  [string] $MafiaRoot = 'C:\Users\sacha\Projects\runtime\kol\mafia',
  [string] $BackupRoot = 'C:\Users\sacha\Projects\runtime\kol\backups',
  [string] $AccountLockRoot = 'C:\Users\sacha\Projects\runtime\kol\account-locks',
  [int] $RunTimeoutMinutes = 360,
  [int] $IdleMinutes = 20,
  [switch] $SkipJarUpdate,
  [switch] $SkipGitUpdate,
  # gCLI commands run right after login, before smmdaily (e.g. 'set smm.daily.garboAutoConfirm = true').
  [string[]] $AfterLoginCommands = @()
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if ([string]::IsNullOrWhiteSpace($AccountLockRoot)) { $AccountLockRoot = Join-Path (Split-Path $BackupRoot) 'account-locks' }
$MafiaRoot = [IO.Path]::GetFullPath($MafiaRoot)
$Username = $Username.Trim()
$runId = [guid]::NewGuid().ToString('N')

$stamp   = Get-Date -Format 'yyyyMMdd-HHmmss'
$logDir  = Join-Path $MafiaRoot 'runlogs\daily'
New-Item -ItemType Directory -Force $logDir | Out-Null
$stamp = $stamp + '-' + $runId.Substring(0,8)
$logFile = Join-Path $logDir "daily-$stamp.log"
$evidenceFile = Join-Path $logDir "daily-$stamp.evidence.json"
$statusFile = Join-Path $logDir 'latest.json'
$lockFile = Join-Path $logDir 'runner.lock'

$status = [ordered]@{
  started = (Get-Date).ToString('o'); finished = $null; mode = $Mode; result = 'running'
  log = $logFile; jarBefore = $null; jarAfter = $null; jarUpdate = $null; gitUpdate = $null
  closedProcesses = 0; movedStaleScripts = @(); mafiaExitCode = $null; timedOut = $false
  loggedIn = $false; errors = @(); warnings = @(); smmdailyLines = @()
  compileCheck = $null
  runId = $runId; evidenceFile = $evidenceFile; sourceDigest = $null; sourceStable = $null; candidateForLiveReview = $false
  customLoginCommands = ($AfterLoginCommands.Count -gt 0)
}

function Write-Log([string] $msg, [string] $level = 'INFO') {
  $line = '{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $level, $msg
  Add-Content -Path $logFile -Value $line -Encoding utf8
  if ($level -eq 'ERROR') { $script:status.errors += $msg }
  elseif ($level -eq 'WARN') { $script:status.warnings += $msg }
}
function Save-Status {
  Write-KolDailyJson (Join-Path $logDir "daily-$stamp.json") $script:status
  Write-KolDailyJson $statusFile $script:status
}

function Get-JavaExe {
  foreach ($j in 'C:\Users\sacha\Projects\runtime\tools\temurin25-jre\jdk-25.0.5.1+2-jre',
                 'C:\Users\sacha\Projects\runtime\tools\temurin21-jre\jdk-21.0.13.1+2-jre') {
    $exe = Join-Path $j 'bin\java.exe'
    if (Test-Path $exe) { return $exe }
  }
  throw 'No portable Java found under runtime\tools.'
}
function Get-NewestJar {
  Get-ChildItem $MafiaRoot -Filter 'KoLmafia-*.jar' |
    Where-Object { $_.BaseName -match '^KoLmafia-(\d+)$' } |
    Sort-Object { [int]($_.BaseName -replace '^KoLmafia-', '') } | Select-Object -Last 1
}

# Runs KoLmafia in CLI mode with a command file (which skips the login prompt).
# stdin is an empty file, so once the file is done (or aborts) the CLI reads EOF and exits.
function Invoke-MafiaCli([string] $name, [string[]] $commands, [int] $timeoutMinutes) {
  $cmdName = "zz_daily_$name.txt"
  $cmdPath = Join-Path $MafiaRoot "scripts\$cmdName"
  Set-Content -Path $cmdPath -Value (($commands + 'exit') -join "`r`n") -Encoding ascii
  $empty = Join-Path $logDir 'empty-stdin.txt'
  Set-Content -Path $empty -Value '' -NoNewline
  $out = Join-Path $logDir "daily-$stamp-$name.out.txt"
  $err = Join-Path $logDir "daily-$stamp-$name.err.txt"
  $jar = (Get-NewestJar).Name
  $jarPath = Join-Path $MafiaRoot $jar
  $rootTag = '-Dcodex.kol.root="' + ([IO.Path]::GetFullPath($MafiaRoot)) + '"'
  Write-Log "KoLmafia CLI ($name) with $jar : $($commands -join ' | ')"
  $p = Start-Process -FilePath (Get-JavaExe) -WorkingDirectory $MafiaRoot -WindowStyle Hidden -PassThru `
        -ArgumentList '-DuseCWDasROOT=true', $rootTag, '--enable-native-access=ALL-UNNAMED', '-jar', ('"' + $jarPath + '"'), '--CLI', $cmdName `
        -RedirectStandardInput $empty -RedirectStandardOutput $out -RedirectStandardError $err
  $null = $p.Handle
  # When a command in the file aborts, KoLmafia stops reading the file but does not exit,
  # so also stop it once its output has been silent for $IdleMinutes.
  $deadline = (Get-Date).AddMinutes($timeoutMinutes)
  $lastLen = -1; $lastChange = Get-Date; $timedOut = $false
  while (-not $p.WaitForExit(30000)) {
    $len = if (Test-Path $out) { (Get-Item $out).Length } else { 0 }
    if ($len -ne $lastLen) { $lastLen = $len; $lastChange = Get-Date }
    if ((Get-Date) -gt $deadline) { $timedOut = $true; $why = "still running after $timeoutMinutes minutes"; break }
    if (((Get-Date) - $lastChange).TotalMinutes -ge $IdleMinutes) { $timedOut = $true; $why = "silent for $IdleMinutes minutes (a command probably aborted and KoLmafia is waiting)"; break }
  }
  if ($timedOut) {
    Write-Log "KoLmafia CLI ($name) $why; stopping it." 'ERROR'
    Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
    $p.WaitForExit(30000) | Out-Null
  }
  Remove-Item $cmdPath -ErrorAction SilentlyContinue
  [pscustomobject]@{ ExitCode = $(if ($timedOut) { $null } else { $p.ExitCode }); TimedOut = $timedOut; Out = $out; Err = $err
                     Text = $(if (Test-Path $out) { Get-Content $out -Raw } else { '' }) }
}

function Stop-Mafia {
  $procs = Get-CimInstance Win32_Process -Filter "Name='java.exe' OR Name='javaw.exe'" |
           Where-Object { $_.CommandLine -match 'KoLmafia' }
  $unknown = @($procs | Where-Object { (Get-KolDailyProcessDisposition $_.CommandLine $MafiaRoot) -eq 'unknown' })
  if ($unknown.Count) { throw 'An unidentifiable Mafia process is running. Close or identify it before this runner starts; no process was stopped.' }
  foreach ($cp in $procs) {
    if ((Get-KolDailyProcessDisposition $cp.CommandLine $MafiaRoot) -ne 'owned') { continue }
    Write-Log "Closing KoLmafia (pid $($cp.ProcessId)): $($cp.CommandLine)"
    $p = Get-Process -Id $cp.ProcessId -ErrorAction SilentlyContinue
    if (-not $p) { continue }
    if ($p.MainWindowHandle -ne 0) { $p.CloseMainWindow() | Out-Null }
    if (-not $p.WaitForExit(90000)) {
      Write-Log "KoLmafia pid $($cp.ProcessId) did not close in 90 s; stopping it." 'WARN'
      Stop-Process -Id $cp.ProcessId -Force -ErrorAction SilentlyContinue
      Start-Sleep -Seconds 5
    }
    $script:status.closedProcesses++
  }
}

function Update-Jar {
  $current = Get-NewestJar
  $status.jarBefore = $current.Name
  $rel = Invoke-RestMethod 'https://api.github.com/repos/kolmafia/kolmafia/releases/latest' `
           -Headers @{ 'User-Agent' = 'kol-daily-runner'; 'Accept' = 'application/vnd.github+json' } -TimeoutSec 60
  $asset = $rel.assets | Where-Object { $_.name -match '^KoLmafia-(\d+)\.jar$' } | Select-Object -First 1
  if (-not $asset) { Write-Log "Latest release $($rel.tag_name) has no KoLmafia-N.jar asset." 'WARN'; $status.jarUpdate = 'no-asset'; return }
  $newRev = [int]($asset.name -replace '^KoLmafia-(\d+)\.jar$', '$1')
  $curRev = [int]($current.BaseName -replace '^KoLmafia-', '')
  if ($newRev -le $curRev) { Write-Log "KoLmafia r$curRev is current (latest release $($rel.tag_name))."; $status.jarUpdate = 'current'; $status.jarAfter = $current.Name; return }

  $dlDir = Join-Path (Split-Path $BackupRoot) 'downloads'
  New-Item -ItemType Directory -Force $dlDir | Out-Null
  $tmp = Join-Path $dlDir "$($asset.name).part"
  Write-Log "Downloading $($asset.name) ($($asset.size) bytes) from $($asset.browser_download_url)"
  Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $tmp -UseBasicParsing -TimeoutSec 600 -Headers @{ 'User-Agent' = 'kol-daily-runner' }
  $len = (Get-Item $tmp).Length
  if ($len -ne $asset.size) { Remove-Item $tmp; throw "Downloaded jar is $len bytes, release says $($asset.size)." }
  if ($asset.digest -and $asset.digest -match '^sha256:(.+)$') {
    $want = $Matches[1]; $got = (Get-FileHash $tmp -Algorithm SHA256).Hash
    if ($got -ne $want) { Remove-Item $tmp; throw "Downloaded jar SHA-256 $got does not match the release's $want." }
    Write-Log "SHA-256 matches the release digest."
  }
  # Sanity check: the new jar must start and report its version.
  $check = & (Get-JavaExe) -jar $tmp --CLI --Version 2>&1 | Out-String
  if ($check -notmatch "r$newRev") { Remove-Item $tmp; throw "New jar did not report r$newRev : $check" }

  $dest = Join-Path $MafiaRoot $asset.name
  Move-Item $tmp $dest -Force
  $old = Join-Path $MafiaRoot 'old-jars'
  New-Item -ItemType Directory -Force $old | Out-Null
  Get-ChildItem $MafiaRoot -Filter 'KoLmafia-*.jar' | Where-Object { $_.Name -ne $asset.name } | Move-Item -Destination $old -Force
  # Keep the five newest old jars.
  Get-ChildItem $old -Filter 'KoLmafia-*.jar' | Sort-Object LastWriteTime -Descending | Select-Object -Skip 5 | Remove-Item -Force
  Write-Log "Installed $($asset.name) (was $($current.Name))."
  $status.jarUpdate = "updated r$curRev -> r$newRev"
  $status.jarAfter = $asset.name
}

# A script the repo stopped shipping, left in scripts\, can shadow its replacement
# (diet.js beside diet.ash makes a bare `diet` ambiguous). Move such files aside when
# the checkout ships the replacement and no longer ships the old file.
function Remove-StaleScripts {
  $checkout = Join-Path $MafiaRoot 'git\sachamm-KoL-main\scripts'
  $scripts = Join-Path $MafiaRoot 'scripts'
  foreach ($pair in @(@{ old = 'diet.js'; new = 'diet.ash' })) {
    $oldPath = Join-Path $scripts $pair.old
    if ((Test-Path $oldPath) -and (Test-Path (Join-Path $checkout $pair.new)) -and -not (Test-Path (Join-Path $checkout $pair.old))) {
      $dest = Join-Path $BackupRoot "retired-scripts"
      New-Item -ItemType Directory -Force $dest | Out-Null
      Move-Item $oldPath (Join-Path $dest "$($pair.old).$stamp") -Force
      Write-Log "Moved stale scripts\$($pair.old) to $dest (the repo now ships $($pair.new))."
      $status.movedStaleScripts += $pair.old
    }
  }
}

. (Join-Path $PSScriptRoot 'KolDailyDiagnostics.ps1')
. (Join-Path $PSScriptRoot 'KolDailyOwnership.ps1')
. (Join-Path $PSScriptRoot 'KolDailyEvidence.ps1')
. (Join-Path $PSScriptRoot 'KolDailyLogin.ps1')
function Find-Problems([string] $text, [string] $phase) {
 foreach ($line in ($text -split "\r?\n")) {
  if (Test-KolDailyProblemLine $line) { $script:status.errors += "[$phase] $($line.Trim())" }
 }
}

# Obtain both leases before changing latest status or stopping any process.
# Failed contenders write only their own log, never the owner's latest.json.
$ownership = $null
$sourceBefore = $null; $sourceAfter = $null; $r = $null
try { $ownership = Enter-KolDailyOwnership $MafiaRoot $Username $AccountLockRoot }
catch { Write-Log "Runner ownership denied: $_" 'ERROR'; exit 2 }
try {
  Save-Status
  Write-Log "Daily runner starting: mode $Mode, user $Username, root $MafiaRoot"
  Stop-Mafia

  if ($SkipJarUpdate) { Write-Log 'Skipping the jar update.'; $status.jarUpdate = 'skipped'; $status.jarBefore = (Get-NewestJar).Name }
  else { try { Update-Jar } catch { Write-Log "Jar update failed, keeping $((Get-NewestJar).Name): $_" 'WARN'; $status.jarUpdate = 'failed' } }
  $status.jarAfter = (Get-NewestJar).Name

  if ($SkipGitUpdate) { Write-Log 'Skipping git update.'; $status.gitUpdate = 'skipped' }
  else {
    $g = Invoke-MafiaCli 'git' @('git update') 20
    Add-Content $logFile "----- git update output -----`r`n$($g.Text)`r`n-----------------------------" -Encoding utf8
    # Only mafia's own status lines count; commit messages in the output often say "error" or "failed".
    $gitBad = ($g.Text -split "`r?`n") | Where-Object { $_ -match '^(Failed|Error|Unable|Could not|.*Exception)' -or $_ -match 'TransportException|not authorized|Connection (refused|reset)' }
    if ($g.TimedOut -or $gitBad) {
      foreach ($b in $gitBad) { Write-Log "git: $b" 'WARN' }
      Write-Log 'git update reported a problem; see the output above. Continuing with the scripts already installed.' 'WARN'
      $status.gitUpdate = 'problem'
    } else { $status.gitUpdate = 'ok' }
  }
  Remove-StaleScripts
  # Dynamic CLI workers are not part of smmdaily's static import graph.
  # Verify them with the actual selected jar before any account login.
  $compileResult = Invoke-MafiaCli 'verify' @('verify smmdaily.ash','verify fr.ash','verify diet.ash','verify smmPreAdventure.ash') 20
  Add-Content $logFile "----- compilation output -----`r`n$($compileResult.Text)`r`n-----------------------------" -Encoding utf8
  $compileProblem = Get-KolDailyCompileProblem $compileResult 4
  if ($compileProblem) { $status.compileCheck = 'failed'; throw $compileProblem }
  $status.compileCheck = 'passed'
  Write-Log 'Four daily entry points compiled with the selected Mafia jar before login.'
  $sourceBefore = Get-KolDailySourceManifest $MafiaRoot (Join-Path $MafiaRoot (Get-NewestJar).Name) $PSScriptRoot
  $status.sourceDigest = $sourceBefore.digest
  # Persist the source identity before any login or custom command can act.
  Write-KolDailyJson $evidenceFile ([ordered]@{schemaVersion=1;runId=$runId;state='before-login';sourceBefore=$sourceBefore;candidateForLiveReview=$false})
  Save-Status

  # Mafia is stopped and both leases are held. Restore an interrupted guard,
  # then borrow only login flags; explicit breakfast runs after day.open.
  Enter-KolDailyLoginGuard $MafiaRoot $Username

  $smm = if ($Mode -eq 'Run') { 'try; smmdaily run' } else { 'smmdaily plan' }
  $cmds = @(
    "login $Username",
    ('ash if (my_name().to_lower_case() != "' + $Username.ToLowerInvariant() + '") abort("DAILY-RUNNER: wrong or missing account");'),
    $(if ($Mode -eq 'Run') { 'set _smm.daily.breakfastDeferred = true' }),
    $(if ($Mode -eq 'Run') { 'ash set_property("_smm.daily.runnerAuditEpoch", today_to_string() + ":" + my_ascensions() + ":" + my_id());' }),
    (New-KolDailyBoundaryCommand $runId 'START'),
    'ash print("DAILY-RUNNER: logged in as " + my_name() + ", day " + today_to_string() + ", rollover in " + (rollover() - now_to_int() / 1000) / 60 + " min");'
    # An open Combat Lover's Locket screen (choice 1463) left from manual play makes smmdaily refuse to start;
    # it costs nothing to walk away from, so leave it. Any other open fight or choice is left for Sacha.
    'ash if (handling_choice() && last_choice() == 1463) { visit_url("main.php"); print("DAILY-RUNNER: left the open locket screen; handling_choice=" + handling_choice()); }'
  ) + $AfterLoginCommands + @(
    $smm,
    $(if ($Mode -eq 'Run') { 'else; ash print("SMM_DAILY_COMMAND_FAILED");' }),
    $(if ($Mode -eq 'Run') { New-KolDailyAuditCommand }),
    'smmdaily status',
    'smmdaily journal 40',
    (New-KolDailyBoundaryCommand $runId 'END'),
    'ash print("DAILY-RUNNER: finished; adventures " + my_adventures() + ", meat " + my_meat() + ", inebriety " + my_inebriety() + "/" + inebriety_limit());'
  )
  $r = Invoke-MafiaCli 'run' $cmds $RunTimeoutMinutes
  Add-Content $logFile "----- KoLmafia output -----`r`n$($r.Text)`r`n---------------------------" -Encoding utf8
  if (Test-Path $r.Err) { $errText = Get-Content $r.Err -Raw; if ($errText) { Add-Content $logFile "----- stderr -----`r`n$errText" -Encoding utf8 } }
  $status.mafiaExitCode = $r.ExitCode
  $status.timedOut = $r.TimedOut
  if ($r.TimedOut -or $r.ExitCode -ne 0) { Write-Log 'KoLmafia did not exit successfully.' 'ERROR' }
  $status.loggedIn = $r.Text -match 'DAILY-RUNNER: logged in as'
  $status.smmdailyLines = @(($r.Text -split "`r?`n") | Where-Object { $_ -match '^(smmDaily|DAILY-RUNNER)' } | Select-Object -Last 60)

  Find-Problems $r.Text 'run'
  if (Test-Path $r.Err) { Find-Problems (Get-Content $r.Err -Raw) 'stderr' }
  if (-not $status.loggedIn) { Write-Log "Did not log in as $Username (saved password missing or rejected, or the server was down)." 'ERROR' }
  elseif ($r.Text -notmatch 'DAILY-RUNNER: finished') { Write-Log "The run stopped before its last step (smmdaily aborted or KoLmafia exited early)." 'ERROR' }
}
catch {
  Write-Log "Runner failed: $_ `n$($_.ScriptStackTrace)" 'ERROR'
}
finally {
 try {
  try { Stop-Mafia; $null = Restore-KolDailyLoginGuard $MafiaRoot }
  catch { Write-Log "Could not restore automatic-login settings: $_" 'ERROR' }
  $status.finished = (Get-Date).ToString('o')
  if ($Mode -eq 'Run' -and $r.Text -notmatch '(?m)^>?\s*SMM_DAILY_RESULT COMPLETE\s*$') {
    Write-Log 'smmdaily did not confirm a complete day; inspect the journal for failed, blocked or unfinished tasks.' 'ERROR'
  }
  if ($sourceBefore) {
   try { $sourceAfter = Get-KolDailySourceManifest $MafiaRoot (Join-Path $MafiaRoot (Get-NewestJar).Name) $PSScriptRoot }
   catch { Write-Log "Could not capture final source manifest: $_" 'ERROR' }
   $evidence = Get-KolDailyRunEvidence $r.Text $runId $sourceBefore $sourceAfter $Mode ($status.errors.Count -eq 0 -and $status.loggedIn -and -not $status.timedOut -and $r.ExitCode -eq 0)
   $status.sourceStable = $evidence.sourceStable
   if (-not $evidence.sourceStable) { Write-Log 'Installed source changed during the run or could not be verified.' 'ERROR' }
   if ($Mode -eq 'Run') {
    foreach ($issue in $evidence.issues) { Write-Log "Run evidence: $issue" 'ERROR' }
   }
   $status.candidateForLiveReview = $evidence.candidateForLiveReview
   try { Write-KolDailyJson $evidenceFile $evidence }
   catch { $status.candidateForLiveReview = $false; Write-Log "Could not persist final run evidence: $_" 'ERROR' }
  }
  $status.result = if ($status.errors.Count) { 'error' } elseif ($status.warnings.Count) { 'warning' } else { 'ok' }
  Write-Log "Daily runner finished: $($status.result) ($($status.errors.Count) error lines, $($status.warnings.Count) warnings)."
  Save-Status
  # Keep 60 days of runner logs.
  Get-ChildItem $logDir -File | Where-Object { $_.Name -like 'daily-*' -and $_.LastWriteTime -lt (Get-Date).AddDays(-60) } | Remove-Item -Force
 } finally { Exit-KolDailyOwnership $ownership }
}
if ($status.result -eq 'error') { exit 1 } else { exit 0 }
