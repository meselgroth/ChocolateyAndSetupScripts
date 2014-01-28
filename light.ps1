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

cinst SqlServerLocalDb

cinstm nuget.commandline
cinst NugetPackageExplorer
cinst NugetPackageManager
cinst webpicommandline
cinstm procExp

cinst git
regsvr32 /u $gitShellPath
# http://stackoverflow.com/questions/2459763/how-do-i-remove-msysgits-right-click-menu-options
cinst gitextensions
cinst githubforwindows

cinstm GoogleChrome

cinstm notepadplusplus
cinstm fiddler
cinstm putty
cinstm dotPeek
cinstm specflow

cinst vlc

cinst nodejs.install

Write-Host "Finished."
Read-Host