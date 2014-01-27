cinstm VisualStudio2012Professional
cinst sqlce40rtw -source webpi
cinst sqlcevstools -source webpi

# install nuget
cinstm nuget.commandline
cinst NugetPackageExplorer
cinst NugetPackageManager

cinst baretail

cinstm procExp

cinstm GoogleChrome.Dev

cinstm notepadplusplus
cinstm fiddler
cinstm putty
cinstm kdiff3
cinstm 7zip

cinstm linqpad4
cinstm ilmerge
cinstm dotPeek
cinstm kaxaml
cinstm msbuild.communitytasks
cinstm specflow

cinst MVC3 -source webpi
cinst MVC3Loc -source webpi
cinst MVC4 -source webpi

cinst dropbox
cinst googledrive

cinstm virtualbox


Write-Host "Finished installing "
Read-Host