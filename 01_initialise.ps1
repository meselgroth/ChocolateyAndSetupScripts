function is64Bit
{
    if ([System.IntPtr]::Size -eq 8)
    {
        return $true
    }
    else
    {
        return $false
    }
}
 
$progFiles86 = $env:ProgramFiles
$gitShellPath = Join-Path $progFiles86 "Git\git-cheetah\git_shell_ext.dll"
 
if (is64Bit)
{
    "This machine is 64bit"
    $progFiles86 = ${env:ProgramFiles(x86)}
    $gitShellPath = Join-Path $progFiles86 "Git\git-cheetah\git_shell_ext64.dll"	
}
 
$gitCmd = "$progFiles86\Git\cmd"
$codeDir = "c:\code"
$gitHubScriptDir = "$codeDir\ChocolateyAndSetupScripts"
 
 
cinst git
regsvr32 /u $gitShellPath
# http://stackoverflow.com/questions/2459763/how-do-i-remove-msysgits-right-click-menu-options
cinst gitextensions
cinst githubforwindows
 
cinst notepadplusplus
 
#This isn't required after a successful git installation, left it here just in case needed
#[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$gitCmd", [EnvironmentVariableTarget]::Machine)
install-module posh-git

cinst boxstarter
Set-ExplorerOptions -showHidenFilesFoldersDrives -showProtectedOSFiles -showFileExtensions
Enable-RemoteDesktop

git clone https://github.com/meselgroth/ChocolateyAndSetupScripts.git $gitHubScriptDir
cp "$gitHubScriptDir\ConEmu.xml" $env:APPDATA
& rundll32 syssetup,SetupInfObjectInstallAction DefaultInstall 128 $gitHubScriptDir\powershellhere.inf

Write-Host "Finished."