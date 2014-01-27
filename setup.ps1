function _cmd($command) {
  $result = cmd.exe /c "$command 2>&1" #stderr hack  
  return $result
}

function Install-NeededFor {
param([string] $packageName = '', [bool] $defaultAnswer = $true)
    if ($packageName -eq '') {return $false}
    
    $yes = '6'
    $no = '7'
    $msgBoxTimout='-1'
    $defaultAnswerDisplay = 'Yes'
    $buttonType = 0x4;
    if (!$defaultAnswer) {$defaultAnswerDisplay = 'No'; $buttonType= 0x104;}
    
    $answer = $msgBoxTimeout
    try {
        $timeout = 10
        $question = "Do you need to install $($packageName)? Defaults to `'$defaultAnswerDisplay`' after $timeout seconds"
        $msgBox = New-Object -ComObject WScript.Shell
        $answer = $msgBox.Popup($question, $timeout, "Install $packageName", $buttonType)
    }
    catch {
    }
    
    if ($answer -eq $yes -or ($answer -eq $msgBoxTimeout -and $defaultAnswer -eq $true)) {
        write-host "Installing $packageName"
        return $true
    }
    
    write-host "Not installing $packageName"
    return $false
}

function is64Bit
{
    if ([System.IntPtr]::Size -eq 8)
    {
        return $true
    }
    else
    {
        return $false
    }
}

$install_location = "\\uat-nas02.durrants.uat\software$\Build\Core"
$progFiles86 = $env:ProgramFiles
if (is64Bit)
{
    $progFiles86 = ${env:ProgramFiles(x86)}
    "This machine is 64bit"
}
else {
    "This machine is 32bit"
}
"Using $progFiles86 for program files"

$installVim = Install-NeededFor 'vim'
$installhg = Install-NeededFor 'mecurial'
$installdropbox = Install-NeededFor 'dropbox'
$installskydrive = Install-NeededFor 'skydrive'
$installemacs = Install-NeededFor 'emacs'
$installintellij = Install-NeededFor 'InteliJ'
$installiis = Install-NeededFor 'IIS' $false

$currentPath = Split-Path -parent $MyInvocation.MyCommand.Definition
$packagePath = Join-Path $currentPath VS_Extensions\davearkell.vsextensions

& setuptnsNames\setuptnsNames.ps1


# install ruby.devkit, and ruby if they are missing


if ($installVim) {
    cinstm KickAssVim
}
if ($installhg) {
    cinstm Posh-GIT-HG
}
else {
    cinstm Poshgit
}
$gitBinDir = Join-Path $progFiles86 "git\bin"
if(-not ($env:PATH.Split(';') -contains $gitBinDir)) {
  Write-Host "Adding $($gitBinDir) to your working path"
  [System.Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";$gitBinDir", "Machine")
}

if ($installdropbox) {
    cinstm dropbox
}
if ($installskydrive) {
    cinstm SkyDrive
}
if ($installemacs) {
    cinstm Emacs
}
if ($installintellij) {
    $intellijPath = Join-Path $currentPath IntelliJIDEA.11.1.2
    cinst IntelliJIDEA -source $intellijPath
}

[System.Diagnostics.Process]::Start("c:\chocolatey\bin\cinst", "GnuWin")

if (Test-Path $install_location)
{
    if (-Not (Test-Path(Join-Path $progFiles86 "Microsoft SDKs\Silverlight\v4.0\Toolkit\Apr10\")))
    {
        "Installing Silverlight 4"
        _cmd "$install_location\Silverlight4_Tools.exe /q:a /c:""setup.exe /q /norestart"" /norestart"
        _cmd "C:\windows\system32\msiexec.exe /qb /i ""$install_location\silverlight_4_Toolkit_April_2010.msi"""
    }
    
    if (-Not (Test-Path(Join-Path $progFiles86 "Microsoft SDKs\Expression\Blend\Silverlight")))
    {
        "Installing BlendSLSDK"
        _cmd "C:\Windows\System32\msiexec.exe /qb /i ""$install_location\BlendSLSDK_en.msi"""
    }
    
    if (-Not (Test-Path(Join-Path $progFiles86 "Microsoft SDKs\Expression\Blend\.NETFramework\v4.0")))
    {
        "Installing BlendWPFSDK"
        _cmd "C:\Windows\System32\msiexec.exe /qb /i ""$install_location\BlendWPFSDK_en.msi"""
    }
    
    if (-Not (Test-Path(Join-Path $progFiles86 "Telerik\RadControls for WPF Q2 2010 SP2")))
    {
        "Installing Telerik Controls"
        _cmd "C:\Windows\System32\msiexec.exe /qb /i ""$install_location\RadControls_for_WPF40_2010_2_0924_DEV.msi"""
    }
    
    if (-Not (Test-Path(Join-Path $progFiles86 "Keyoti Inc\RapidSpell WPF")))
    {
        "Installing Keyoti RapidSpell"
        _cmd "C:\Windows\System32\msiexec.exe /qb /i ""$install_location\RapidSpellWPF-2.0.0-UD-Setup.msi"""
    }
    
    if (-Not (Test-Path(Join-Path $progFiles86 "Actipro Software\WPFStudio\v11.1.0540")))
    {
        "Installing Actipro"
        _cmd "C:\Windows\System32\msiexec.exe /qb /i ""$install_location\ActiProSyntaxEditor\Setup.msi"""
    }

    if (-Not (Test-Path "C:\Program Files\SVNCommandLine\bin\svn.exe"))
    {
        "Installing SVNCommand Line"
        Copy-Item $install_location\SVNCommandLine "C:\Program Files\" -recurse
    }
    $msbuildPath = Join-Path $progFiles86 "MSBuild"
    Copy-Item $install_location\VDProjSettingsModifier.exe $msbuildPath
    Copy-Item $install_location\MsiProductCodeExtractor.exe $msbuildPath
    
    if (-Not (Test-Path(Join-Path $progFiles86 "Microsoft Silverlight\4.0.51204.0")))
    {
        "Installing Silverlight Developer"
        _cmd "$install_location\Silverlight_Developer.exe /q"
    }
    
    if (-Not (Test-Path(Join-Path $progFiles86 "MSBuild\Microsoft\VisualStudio\TextTemplating\v10.0")))
    {
        "Installing Visual Studio 2010 SDK and Visual Studio 2010 Modelling & Visualisation SDK for T4 build time transformation support"
        Copy-Item $install_location\VisualStudio2010SDK $env:Temp -recurse
        Copy-Item $install_location\VisualStudio2010ModellingAndVisualisationSDK $env:Temp -recurse
        _cmd "C:\windows\system32\msiexec.exe /qb /i ""$env:Temp\VisualStudio2010SDK\vssdk.msi"""
        _cmd "C:\windows\system32\msiexec.exe /qb /i ""$env:Temp\VisualStudio2010ModellingAndVisualisationSDK\vs_vmsdk.msi"""
        Remove-Item $env:Temp\VisualStudio2010SDK -recurse
        Remove-Item $env:Temp\VisualStudio2010ModellingAndVisualisationSDK -recurse
    }
	
	if (-Not (Test-Path(Join-Path $progFiles86 "Java\jdk1.6.0_24")))
    {
        "Installing Java JDK"
        _cmd "$install_location\jdk-6u24-windows-i586.exe /s /v""/qn REBOOT=Suppress"""
    }
    
     if (-Not (Test-Path "C:\Program Files\JavaBuildTools\apache-ant-1.8.2\INSTALL"))
    {
        "Installing Java Build tools"
        Copy-Item $install_location\JavaBuildTools "C:\Program Files\" -recurse
    }
    
    if (-Not (Test-Path(Join-Path $progFiles86 "Microsoft ASP.NET\ASP.NET 2.0 AJAX Extensions\v1.0.61025")))
    {
        "Installing Ajax Web Extensions"
        _cmd "C:\windows\system32\msiexec.exe /qb /i ""$install_location\AJAX Web Extentions.msi"""
    }
}
else
{
    "Not installing old batch file stuff, as I can't access the shared drive"
}

if (-Not (Test-Path(Join-Path $progFiles86 "Terminals")))
{
    "Installing Terminals"
    _cmd "C:\Windows\System32\msiexec.exe /qb /i ""SetupTerminals_v2.0.msi"""
    Copy-Item Terminals.config $progFiles86\Terminals
    Copy-Item Credentials.xml $progFiles86\Terminals
}

cinstm ruby.devkit

#perform ruby updates and get gems
_cmd "C:\ruby193\bin\gem update --system"
cgem rake
cgem bundler
cgem win32console
cgem colorize
cgem mustache

#restore the nuget packages
#$nugetConfigs = Get-ChildItem '.\' -Recurse | ?{$_.name -match "packages\.config"} | select
#foreach ($nugetConfig in $nugetConfigs) {
#  Write-Host "restoring packages from $($nugetConfig.FullName)"
#  nuget install $($nugetConfig.FullName) /OutputDirectory packages
#}

#rake

cinstm virtualbox
cinstm Firefox
cinstm GoogleChrome.Dev

cinstm python
#cinstm easy.install             # issue here
#cinstm pip                      # issue here
cinstm vlc
cinstm sysinternals
cinstm gitextensions
cinstm kdiff3
cinstm tortoisesvn
cinstm svn
cinstm notepadplusplus
cinstm 7zip
cinstm 7zip.commandline
cinstm fiddler
cinstm putty
cinstm windirstat
cinstm curl
cinstm skype
cinstm wget
cinstm FoxitReader
cinst SourceCodePro
cinst ConEmu -Version 12.4.17.1

$conemuProgFiles = $progFiles86.Replace("\", "\\")
Get-Content conEmu.reg | Foreach-Object{$_ -replace "PROGFILES", "$conemuProgFiles"} | Set-Content 'conEmu2.reg'
reg Import conEmu2.reg
"c:\program files\conemu.exe /UpdateJumpList"
Remove-Item conEmu2.reg

cinstm linqpad4
cinstm ilmerge
cinstm dotPeek
cinstm kaxaml
cinstm msbuild.communitytasks
#cinstm Silverlight
#cinstm Silverlight5SDK
cinstm specflow


cinst SQLExpressManagementStudio -source webpi
Write-Host "Finished checking for/installing Visual Studio Items."

cinst davearkell.vsextensions -source $packagePath -force

if ($installiis) {
  cinst ASPNET -source webpi
  cinst ASPNET_REGIIS -source webpi
  cinst DefaultDocument -source webpi
  cinst DynamicContentCompression -source webpi
  cinst HTTPRedirection -source webpi
  cinst IIS7_ExtensionLessURLs -source webpi
  cinst IISExpress -source webpi
  cinst IISExpress_7_5 -source webpi
  cinst IISManagementConsole -source webpi
  cinst ISAPIExtensions -source webpi
  cinst ISAPIFilters -source webpi
  cinst NETExtensibility -source webpi
  cinst RequestFiltering -source webpi
  cinst StaticContent -source webpi
  cinst StaticContentCompression -source webpi
  cinst UrlRewrite2 -source webpi
  cinst WindowsAuthentication -source webpi
}