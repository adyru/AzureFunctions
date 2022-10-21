# Input bindings are passed in via param block.
param($Timer)

# Add all your Azure Subscription Ids below
$subscriptionids = @"
[
"11ea78cb-5ef1-45ed-9c98-b0112105adce"
]
"@ | ConvertFrom-Json

# Convert UTC to West Europe Standard Time zone
$date = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([DateTime]::Now,"W. Europe Standard Time")

foreach ($subscriptionid in $subscriptionids) {
# Selecting Azure Sub
Set-AzContext -SubscriptionId $SubscriptionID | Out-Null

$CurrentSub = (Get-AzContext).Subscription.Id
If ($CurrentSub -ne $SubscriptionID) {
Throw "Could not switch to SubscriptionID: $SubscriptionID"
}

$vms = Get-AzVM -Status | Where-Object {($_.tags.AutoShutdown -ne $null) -and ($_.tags.AutoStart -ne $null)}
$now = $date

foreach ($vm in $vms) {

if (($vm.PowerState -eq 'VM running') -and ($now -gt $(get-date $($vm.tags.AutoShutdown))) ) {
Stop-AzVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Confirm:$false -NoWait -Force
Write-Warning "Stop VM - $($vm.Name)"
}
elseif (($vm.PowerState -ne 'VM running') -and ($now -gt $(get-date $($vm.tags.AutoStart))) -and ($now -lt $(get-date $($vm.tags.AutoShutdown))) ) {
Start-AzVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -NoWait
Write-Warning "Start VM - $($vm.Name)"
}

}
}
