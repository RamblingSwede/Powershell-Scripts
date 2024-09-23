cls

Import-Module  C:\Users\joel.ljungdahl\Documents\PowerShell\Modules\ImportExcel
Connect-MgGraph -Scopes "User.Read.All","Group.ReadWrite.All, Organization.Read.All"

$path = 'C:\Temp\file.xlsx'
$users = Import-Excel -Path $path

cls
write-host '===Choose License==='
write-host '1 - E1 license'
write-host '2 - E3 license'

$choice = read-host 'Choose a license to assign to the list of users' 
switch ($choice){
    "1" {$li = 'STANDARDPACK'}
    "2" {$li = 'ENTERPRISEPACK'}
}

$EmsSku = Get-MgSubscribedSku -All | Where SkuPartNumber -eq $li
$RemoveSku = Get-MgSubscribedSku -All | Where SkuPartNumber -eq 'STANDARDWOFFPACK'
$disabledPlans = $EmsSku.ServicePlans | where ServicePlanName -in ("YAMMER_ENTERPRISE") | Select -ExpandProperty ServicePlanId
$addLicenses = @(
  @{SkuId = $EmsSku.SkuId
  DisabledPlans = $disabledPlans}
  )

foreach ($user in $users){
    Set-MgUserLicense -UserId $user.Email -AddLicenses $addlicenses  -RemoveLicenses @()
    Set-MgUserLicense -UserId $user.Email -AddLicenses @() -RemoveLicenses @($RemoveSku.SkuId)
}

Disconnect-MgGraph
Get-PSSession | Remove-PSSession
Continue
Exit