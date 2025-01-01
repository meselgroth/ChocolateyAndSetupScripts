Set-ExecutionPolicy Bypass -Scope Process
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

chocolatey feature enable -n allowGlobalConfirmation
choco install choco-shim-redirects
cinst git --params /NoShellIntegration
 
#cinst notepadplusplus
cinst visualstudiocode

Set-ExplorerOptions -showHidenFilesFoldersDrives -showProtectedOSFiles -showFileExtensions
Write-Host "Finished."
