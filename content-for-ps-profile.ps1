
Import-Module posh-git
#Import-Module posh-docker # PowerShell parameter completion shim for the dotnet CLI 

# PowerShell parameter completion shim for the dotnet CLI 
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
     param($commandName, $wordToComplete, $cursorPosition)
         dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
         }
 }

function open-hostfile { Invoke-Item -Path C:\Windows\System32\drivers\etc\hosts }
set-alias openh open-hostfile