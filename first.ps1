cinstm VisualStudio2012Ultimate
Set-ItemProperty -Path HKCU:\Software\Microsoft\VisualStudio\11.0\General -Name SuppressUppercaseConversion -Type DWord -Value 1
cinstm VisualStudio2013Ultimate
Set-ItemProperty -Path HKCU:\Software\Microsoft\VisualStudio\12.0\General -Name SuppressUppercaseConversion -Type DWord -Value 1

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

cinst nodejs.install

choco install IsePester

Write-Host "Finished installing "
Read-Host