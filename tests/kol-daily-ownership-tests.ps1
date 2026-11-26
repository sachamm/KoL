$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\tools\KolDailyOwnership.ps1')
$script:ownershipChecks = 0
function Assert-Owned([bool] $Ok, [string] $Reason) { $script:ownershipChecks++; if (-not $Ok) { throw $Reason } }
$fixtureBase = Join-Path $PSScriptRoot ('.runtime\ownership\' + [guid]::NewGuid().ToString('N'))
$rootA = Join-Path $fixtureBase 'a'
$rootB = Join-Path $fixtureBase 'b'
$lockRoot = Join-Path $fixtureBase 'accounts'
$leaseA=$null; $leaseB=$null
try {
 $leaseA=Enter-KolDailyOwnership $rootA 'FixtureAccount' $lockRoot
 $refused=$false
 try { $leaseB=Enter-KolDailyOwnership $rootA 'DifferentAccount' $lockRoot } catch { $refused=$true }
 Assert-Owned $refused 'Different accounts cannot share a root concurrently'
 $refused=$false
 try { $leaseB=Enter-KolDailyOwnership $rootB 'fixtureaccount' $lockRoot } catch { $refused=$true }
 Assert-Owned $refused 'Same account cannot run concurrently in different roots (case-insensitive)'
 $leaseB=Enter-KolDailyOwnership $rootB 'DifferentAccount' $lockRoot
 Assert-Owned ($null -ne $leaseB) 'Separate accounts and roots can run independently'
 Exit-KolDailyOwnership $leaseB; $leaseB=$null
 Exit-KolDailyOwnership $leaseA; $leaseA=$null
 $leaseA=Enter-KolDailyOwnership $rootA 'FixtureAccount' $lockRoot
 Assert-Owned ($null -ne $leaseA) 'Released ownership can be reacquired without an eight-hour stale delay'
 Exit-KolDailyOwnership $leaseA; $leaseA=$null
 $legacy=Join-Path $fixtureBase 'legacy.lock'
 Set-Content $legacy $PID
 $refused=$false
 try { $leaseA=Open-KolDailyLease $legacy @{pid=$PID} } catch { $refused=$true }
 Assert-Owned $refused 'A live older plain-PID owner is preserved'
} finally { Exit-KolDailyOwnership $leaseB; Exit-KolDailyOwnership $leaseA }
$ownedCommand='java -Dcodex.kol.root="' + $rootA + '" -jar "' + (Join-Path $rootA 'KoLmafia-29462.jar') + '"'
$foreignCommand='java -Dcodex.kol.root="' + $rootB + '" -jar "' + (Join-Path $rootB 'KoLmafia-29462.jar') + '"'
Assert-Owned ((Get-KolDailyProcessDisposition $ownedCommand $rootA) -eq 'owned') 'Explicit root marker identifies owned process'
Assert-Owned ((Get-KolDailyProcessDisposition $foreignCommand $rootA) -eq 'foreign') 'Foreign marked process remains foreign'
Assert-Owned ((Get-KolDailyProcessDisposition ('java -jar "' + (Join-Path $rootA 'KoLmafia-29462.jar') + '"') $rootA) -eq 'owned') 'Absolute owned jar identifies its root'
Assert-Owned ((Get-KolDailyProcessDisposition 'java -jar KoLmafia-29462.jar' $rootA) -eq 'unknown') 'Relative unmarked jar cannot authorize stopping a process'
Assert-Owned ((Get-KolDailyProcessDisposition 'java -jar another-app.jar' $rootA) -eq 'unrelated') 'Unrelated Java application is ignored'
$spaceRoot=Join-Path $fixtureBase 'root with spaces'
Assert-Owned ((Get-KolDailyProcessDisposition ('java "-Dcodex.kol.root=' + $spaceRoot + '" -jar KoLmafia.jar') $spaceRoot) -eq 'owned') 'Quoted root argument with spaces is recognized'

# Execute the actual stopping function against fake process APIs only.
$parseTokens=$null; $parseErrors=$null
$runnerAst=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot '..\tools\Invoke-KolDaily.ps1'),[ref]$parseTokens,[ref]$parseErrors)
if ($parseErrors.Count) { throw ($parseErrors | Out-String) }
$stopAst=$runnerAst.Find({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Stop-Mafia'}, $true)
Invoke-Expression $stopAst.Extent.Text
$script:fakeProcesses=@([pscustomobject]@{ProcessId=9001;CommandLine=$foreignCommand},[pscustomobject]@{ProcessId=9002;CommandLine=$ownedCommand})
$script:lookedUp=@(); $script:stopped=@(); $script:status=@{closedProcesses=0};$MafiaRoot=$rootA
function Get-CimInstance { param($ClassName,$Filter) return $script:fakeProcesses }
function Get-Process {
 param($Id,$ErrorAction)
 $script:lookedUp += $Id
 $fixtureProcess=[pscustomobject]@{MainWindowHandle=0}
 $fixtureProcess | Add-Member ScriptMethod WaitForExit {param($milliseconds) return $true}
 return $fixtureProcess
}
function Stop-Process { param($Id,$Force,$ErrorAction) $script:stopped += $Id }
function Write-Log { param($msg,$level) }
Stop-Mafia
Assert-Owned ($script:lookedUp.Count -eq 1 -and $script:lookedUp[0] -eq 9002) 'Actual Stop-Mafia touches only the owned fixture'
Assert-Owned ($script:stopped.Count -eq 0) 'No force stop when the owned fixture exits cleanly'
$script:lookedUp=@()
$script:fakeProcesses += [pscustomobject]@{ProcessId=9003;CommandLine='java -jar KoLmafia-29462.jar'}
$refused=$false
try { Stop-Mafia } catch { $refused=$true }
Assert-Owned ($refused -and $script:lookedUp.Count -eq 0) 'An unknown Mafia process prevents any stop or login'

# Exercise actual CLI argument construction against a fake launcher as well.
$invokeAst=$runnerAst.Find({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Invoke-MafiaCli'}, $true)
Invoke-Expression $invokeAst.Extent.Text
$MafiaRoot=$spaceRoot; $logDir=Join-Path $fixtureBase 'launch-logs'; $stamp='fixture';$IdleMinutes=1
$null=New-Item -ItemType Directory -Force -Path $logDir,(Join-Path $MafiaRoot 'scripts')
function Get-NewestJar { return [pscustomobject]@{Name='KoLmafia-29462.jar'} }
function Get-JavaExe { return 'fixture-java.exe' }
function Start-Process {
 param($FilePath,$WorkingDirectory,$WindowStyle,[switch]$PassThru,$ArgumentList,$RedirectStandardInput,$RedirectStandardOutput,$RedirectStandardError)
 $script:launchArguments=$ArgumentList; $script:launchStyle=$WindowStyle
 Set-Content $RedirectStandardOutput 'fixture CLI output'; Set-Content $RedirectStandardError ''
 $fixtureProcess=[pscustomobject]@{Handle=0;ExitCode=0}
 $fixtureProcess | Add-Member ScriptMethod WaitForExit {param($milliseconds) return $true}
 return $fixtureProcess
}
$fixtureResult=Invoke-MafiaCli 'fixture' @('fixture command') 1
Assert-Owned ($script:launchArguments -contains ('-Dcodex.kol.root="' + [IO.Path]::GetFullPath($spaceRoot) + '"')) 'Launch tags the exact root, including spaces'
Assert-Owned ($script:launchArguments -contains ('"' + (Join-Path $spaceRoot 'KoLmafia-29462.jar') + '"')) 'Launch uses a quoted absolute jar path'
Assert-Owned ($script:launchStyle -eq 'Hidden') 'Background CLI launches without a visible console'
Assert-Owned ($fixtureResult.ExitCode -eq 0 -and $fixtureResult.Text -match 'fixture CLI output') 'CLI output and successful exit are preserved'

Write-Output "PASS kol-daily-ownership: $script:ownershipChecks checks; no real process APIs executed"
