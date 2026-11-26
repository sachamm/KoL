<#
  Nightly KoLmafia run for Tquilla on this PC.

  1. Closes KoLmafia if it is running.
  2. Installs the newest KoLmafia jar from github.com/kolmafia/kolmafia releases.
  3. Runs `git update` (sachamm/KoL, KoLUtils and the other git installs) logged out,
     and moves aside scripts the repo no longer ships that would shadow new ones
     (diet.js after diet.ash replaced it).
  4. Starts KoLmafia in CLI mode, logs in with the saved password (`login Tquilla`),
     runs `smmdaily run`, then `smmdaily status` and the journal tail, and exits.
  5. Writes a log and a status file (runlogs\daily\latest.json) listing anything
     that looks like an error, for the scheduled check to report.

  No password is stored here: `login <name>` uses the password KoLmafia saved
  when "save password" was ticked in the GUI.

  -Mode Plan runs `smmdaily plan` instead of `smmdaily run` (changes nothing in game).
  -SkipJarUpdate / -SkipGitUpdate skip those steps.
#>
[CmdletBinding()]
param(
  [ValidateSet('Run', 'Plan')] [string] $Mode = 'Run',
  [string] $Username = 'Tquilla',
  [string] $MafiaRoot = 'C:\Users\sacha\Projects\runtime\kol\mafia',
  [string] $BackupRoot = 'C:\Users\sacha\Projects\runtime\kol\backups',
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

$stamp   = Get-Date -Format 'yyyyMMdd-HHmmss'
$logDir  = Join-Path $MafiaRoot 'runlogs\daily'
New-Item -ItemType Directory -Force $logDir | Out-Null
$logFile = Join-Path $logDir "daily-$stamp.log"
$statusFile = Join-Path $logDir 'latest.json'
$lockFile = Join-Path $logDir 'runner.lock'

$status = [ordered]@{
  started = (Get-Date).ToString('o'); finished = $null; mode = $Mode; result = 'running'
  log = $logFile; jarBefore = $null; jarAfter = $null; jarUpdate = $null; gitUpdate = $null
  closedProcesses = 0; movedStaleScripts = @(); mafiaExitCode = $null; timedOut = $false
  loggedIn = $false; errors = @(); warnings = @(); smmdailyLines = @()
}

function Write-Log([string] $msg, [string] $level = 'INFO') {
  $line = '{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $level, $msg
  Add-Content -Path $logFile -Value $line -Encoding utf8
  if ($level -eq 'ERROR') { $script:status.errors += $msg }
  elseif ($level -eq 'WARN') { $script:status.warnings += $msg }
}
function Save-Status {
  $script:status | ConvertTo-Json -Depth 5 | Set-Content -Path $statusFile -Encoding utf8
  Copy-Item $statusFile (Join-Path $logDir "daily-$stamp.json") -Force
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
  Write-Log "KoLmafia CLI ($name) with $jar : $($commands -join ' | ')"
  $p = Start-Process -FilePath (Get-JavaExe) -WorkingDirectory $MafiaRoot -NoNewWindow -PassThru `
        -ArgumentList '-DuseCWDasROOT=true', '--enable-native-access=ALL-UNNAMED', '-jar', $jar, '--CLI', $cmdName `
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
  foreach ($cp in $procs) {
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
function Find-Problems([string] $text, [string] $phase) {
 foreach ($line in ($text -split "\r?\n")) {
  if (Test-KolDailyProblemLine $line) { $script:status.errors += "[$phase] $($line.Trim())" }
 }
}

try {
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
  Save-Status

  $smm = if ($Mode -eq 'Run') { 'smmdaily run' } else { 'smmdaily plan' }
  $cmds = @(
    "login $Username",
    'ash if (my_name() == "") abort("DAILY-RUNNER: not logged in");',
    'ash print("DAILY-RUNNER: logged in as " + my_name() + ", day " + today_to_string() + ", rollover in " + (rollover() - now_to_int() / 1000) / 60 + " min");'
    # An open Combat Lover's Locket screen (choice 1463) left from manual play makes smmdaily refuse to start;
    # it costs nothing to walk away from, so leave it. Any other open fight or choice is left for Sacha.
    'ash if (handling_choice() && last_choice() == 1463) { visit_url("main.php"); print("DAILY-RUNNER: left the open locket screen; handling_choice=" + handling_choice()); }'
  ) + $AfterLoginCommands + @(
    $smm,
    'smmdaily status',
    'smmdaily journal 40',
    'ash print("DAILY-RUNNER: finished; adventures " + my_adventures() + ", meat " + my_meat() + ", inebriety " + my_inebriety() + "/" + inebriety_limit());'
  )
  $r = Invoke-MafiaCli 'run' $cmds $RunTimeoutMinutes
  Add-Content $logFile "----- KoLmafia output -----`r`n$($r.Text)`r`n---------------------------" -Encoding utf8
  if (Test-Path $r.Err) { $errText = Get-Content $r.Err -Raw; if ($errText) { Add-Content $logFile "----- stderr -----`r`n$errText" -Encoding utf8 } }
  $status.mafiaExitCode = $r.ExitCode
  $status.timedOut = $r.TimedOut
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
  $status.finished = (Get-Date).ToString('o')
  if ($Mode -eq 'Run' -and $r.Text -notmatch '(?m)^>?\s*SMM_DAILY_RESULT COMPLETE\s*$') {
    Write-Log 'smmdaily did not confirm a complete day; inspect the journal for failed, blocked or unfinished tasks.' 'ERROR'
  }
  $status.result = if ($status.errors.Count) { 'error' } elseif ($status.warnings.Count) { 'warning' } else { 'ok' }
  Write-Log "Daily runner finished: $($status.result) ($($status.errors.Count) error lines, $($status.warnings.Count) warnings)."
  Save-Status
  Remove-Item $lockFile -ErrorAction SilentlyContinue
  # Keep 60 days of runner logs.
  Get-ChildItem $logDir -File | Where-Object { $_.Name -like 'daily-*' -and $_.LastWriteTime -lt (Get-Date).AddDays(-60) } | Remove-Item -Force
}
if ($status.result -eq 'error') { exit 1 } else { exit 0 }
