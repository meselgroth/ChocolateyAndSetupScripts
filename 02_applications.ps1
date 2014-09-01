cinstm VisualStudio2012Ultimate
Set-ItemProperty -Path HKCU:\Software\Microsoft\VisualStudio\11.0\General -Name SuppressUppercaseConversion -Type DWord -Value 1
cinstm VisualStudio2013Ultimate
Set-ItemProperty -Path HKCU:\Software\Microsoft\VisualStudio\12.0\General -Name SuppressUppercaseConversion -Type DWord -Value 1

cinst sqlce40rtw -source webpi
cinst sqlcevstools -source webpi
cinst SqlServerLocalDb

cinst linqpad4
cinst ilmerge
cinst kaxaml
cinst msbuild.communitytasks

cinst nodejs.install

cinst dropbox
cinst googledrive
cinst skype
cinst firefox

cinst virtualbox

choco install IsePester

Write-Host "Finished installing "
Read-Host