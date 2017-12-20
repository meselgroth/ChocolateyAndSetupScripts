cinst gitextensions
cinst NugetPackageExplorer
cinst NugetPackageManager
cinst webpicommandline

cinst kdiff3
cinst procExp
cinst fiddler
cinst baretail
cinst putty

cinst specflow 
cinst conemu 
choco install greenshot
$codeDir = "c:\code"
$gitHubScriptDir = "$codeDir\ChocolateyAndSetupScripts"
mkdir $codeDir

git clone https://github.com/meselgroth/ChocolateyAndSetupScripts.git $gitHubScriptDir
cp "$gitHubScriptDir\ConEmu.xml" $env:APPDATA
& rundll32 syssetup,SetupInfObjectInstallAction DefaultInstall 128 $gitHubScriptDir\powershellhere.inf
git config --global --add difftool.prompt false
#git config --global credential.helper wincred
git config --global alias.lga “log --graph --oneline --all --decorate”

#cinst psget
#This isn't required after a successful git installation, left it here just in case needed
#[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$gitCmd", [EnvironmentVariableTarget]::Machine)
install-module posh-git

cinst linqpad4
cinst ilmerge
cinst dotPeek

#cinst msbuild.communitytasks

cinst nodejs.install
cinst virtualbox

#Network debuggin https://gallery.technet.microsoft.com/scriptcenter/Invoke-TSPingSweep-b71f1b9b
iex ((New-Object System.Net.WebClient).DownloadString('https://gallery.technet.microsoft.com/scriptcenter/Invoke-TSPingSweep-b71f1b9b/file/60234/1/Invoke-TSPingSweep.ps1'))



Write-Host "Finished installing "
Read-Host