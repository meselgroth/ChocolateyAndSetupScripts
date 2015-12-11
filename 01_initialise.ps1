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
 
cinst git
regsvr32 /u $gitShellPath
# http://stackoverflow.com/questions/2459763/how-do-i-remove-msysgits-right-click-menu-options
 
cinst notepadplusplus

cinst boxstarter
Set-ExplorerOptions -showHidenFilesFoldersDrives -showProtectedOSFiles -showFileExtensions
Enable-RemoteDesktop

Write-Host "Finished."