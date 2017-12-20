chocolatey feature enable -n allowGlobalConfirmation
cinst git

$progFiles86 = ${env:ProgramFiles(x86)}
$gitShellPath = Join-Path $progFiles86 "Git\git-cheetah\git_shell_ext64.dll"	

$gitCmd = "$progFiles86\Git\cmd"
 

regsvr32 /u $gitShellPath
# http://stackoverflow.com/questions/2459763/how-do-i-remove-msysgits-right-click-menu-options
 
cinst notepadplusplus
cinst visualstudiocode

Write-Host "Finished."