cinstm VisualStudio2013Ultimate
Set-ItemProperty -Path HKCU:\Software\Microsoft\VisualStudio\12.0\General -Name SuppressUppercaseConversion -Type DWord -Value 1

cinst sqlce40rtw -source webpi
cinst sqlcevstools -source webpi
cinst SqlServerLocalDb

#VS azure extension

#cinstm VisualStudio2012Ultimate
#Set-ItemProperty -Path HKCU:\Software\Microsoft\VisualStudio\11.0\General -Name SuppressUppercaseConversion -Type DWord -Value 1

Write-Host "Finished installing "
Read-Host