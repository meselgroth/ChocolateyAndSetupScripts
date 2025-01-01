chocolatey feature enable -n allowGlobalConfirmation
choco install choco-shim-redirects
cinst git --params /NoShellIntegration
 
#cinst notepadplusplus
cinst visualstudiocode

Set-ExplorerOptions -showHidenFilesFoldersDrives -showProtectedOSFiles -showFileExtensions
Write-Host "Finished."
