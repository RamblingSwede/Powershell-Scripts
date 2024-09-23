CLS

#This scripts pings the exchange server every 5 minutes to check if the requested account has been created and synced. When the account is found, an E2 license is assigned.

#Connects to O365 Admin
Connect-MgGraph -Scopes "User.Read.All","Group.ReadWrite.All, Organization.Read.All"

#User account is declared
$User = Read-Host "Input Username (firstname.lastname)"
$User = $User.tolower()
$Email = "$User@woodgreen.org.uk"
$Email = $Email.tolower()

#This checks how many loops of the script has run, passing it to the $TimesChecked value further down
$TimesChecked = 0

#This is the core script, contained in a loop that continues until the requested account is successfully found.
Do

{
CLS
$Usercheck = Get-MgUser -Filter "UserPrincipalName eq '$Email'"
If ($Usercheck -eq $Null) {Write-host "Account not synced yet, please wait... (This may take a very long time)"
$TimesChecked++
Write-Host "This will update once every 5 minutes."
Write-Host "--------------------------------------"
Write-Host "Times checked: $TimesChecked"  
Sleep 300
 }
}
Until ($Usercheck -ne $Null)

#Below is where the Licenses are assigned. It also removes Yammer *shudder* and Microsoft StaffHub ("Deskless")
If ($Usercheck -ne $Null)

{
CLS
Write-Host "Assigning Licenses..."
Update-mguser -userid $email -usagelocation GB
$EmsSku = Get-MgSubscribedSku -All | Where SkuPartNumber -eq 'ENTERPRISEPACK'
$FlowSku = Get-MgSubscribedSku -All | Where SkuPartNumber -eq 'FLOW_FREE'
$BiSku = Get-MgSubscribedSku -All | Where SkuPartNumber -eq 'POWER_BI_STANDARD'
$disabledPlans = $EmsSku.ServicePlans | where ServicePlanName -in ("YAMMER_ENTERPRISE", "Deskless") | Select -ExpandProperty ServicePlanId
$addLicenses = @(
  @{SkuId = $EmsSku.SkuId
  DisabledPlans = $disabledPlans},
  @{SkuId = $FlowSku.SkuId},
  @{SkuId = $BiSku.SkuId}
  )
Set-MgUserLicense -UserId $email -AddLicenses $addlicenses -RemoveLicenses @()

Sleep 1

Write-Host "E3 License assigned"
Write-Host "Total checks: $TimesChecked" 
Write-Host ""
Read-Host "Please press Enter to continue."
}

Disconnect-MgGraph