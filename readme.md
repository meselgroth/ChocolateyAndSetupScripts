Open powershell admin window
Set-ExecutionPolicy RemoteSigned
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

copy 01_initialise.ps1 into window
start new window
copy 02_general_dev.ps1
