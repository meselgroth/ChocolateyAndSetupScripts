cinst gitextensions
cinst githubforwindows

cinst nuget.commandline
cinst NugetPackageExplorer
cinst NugetPackageManager
cinst webpicommandline

cinst kdiff3
cinst procExp
cinst fiddler
cinst baretail
cinst putty
cinst dotPeek
cinst specflow 
cinst conemu 
$codeDir = "c:\code"
$gitHubScriptDir = "$codeDir\ChocolateyAndSetupScripts"

git clone https://github.com/meselgroth/ChocolateyAndSetupScripts.git $gitHubScriptDir
cp "$gitHubScriptDir\ConEmu.xml" $env:APPDATA
& rundll32 syssetup,SetupInfObjectInstallAction DefaultInstall 128 $gitHubScriptDir\powershellhere.inf
git config --global --add difftool.prompt false
git config --global credential.helper wincred

cinst psget
#This isn't required after a successful git installation, left it here just in case needed
#[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$gitCmd", [EnvironmentVariableTarget]::Machine)
install-module posh-git

cinst linqpad4
cinst ilmerge

cinst msbuild.communitytasks

cinst dropbox
cinst googledrive
cinst skype
cinst vlc

cinst virtualbox

choco install IsePester

Write-Host "Finished installing "
Read-Host