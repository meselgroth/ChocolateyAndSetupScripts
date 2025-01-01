chocolatey feature enable -n allowGlobalConfirmation
choco install choco-shim-redirects
cinst git --params /NoShellIntegration
 
cinst notepadplusplus
cinst visualstudiocode

Write-Host "Finished."
