#Login-AzureRmAccount
foreach($vm in Get-AzureRmVM) {
    $startResult = $vm | Stop-AzureRmVM
    echo $vm.Name
    echo $startResult
    }