Start-Transcript -Path "C:\Automation\E2_Transcript.txt"

Connect-MgGraph -ClientID Redacted -TenantId Redacted -CertificateThumbPrint Redacted -NoWelcome

#Connects to Exchange and Sharepoint
$Credentials = Import-Clixml Redacted
$SiteUrl = Redacted
Connect-PnPOnline $SiteUrl -ClientId Redacted -ClientSecret Redacted
#Declares the fields to pull  
$Fields =  "FullName", "LastName", "E2Provisioned"
$Listitems = (Get-PnPListItem -PageSize 1000 -List Onboarding -fields $Fields).fieldvalues

#Loops through each list item (User) and assigns the information needed to variables
foreach ($User in $ListItems){
$ID = $User.ID

$FirstName = $User.FullName
$LastName = $User.LastName 
$E2Provisioned = $User.E2Provisioned

$Fullname = "$FirstName $LastName"
$LogonName = "$FirstName.$LastName" -replace [char]39
$Email = "$LogonName@Redacted"
$Email = $Email.tolower()

#Checks the User against Exchange(cloud) to see if they have synced over. If they have, an E2 license will be assigned and the list item (User) will be removed from the onboarding list
Do{
$Usercheck = Get-MgUser -Filter "UserPrincipalName eq '$Email'" -ErrorAction SilentlyContinue
}
Until ($Usercheck -ne $Null)
If ($Usercheck -ne $Null){
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

Set-PnPListItem -List Onboarding -Identity $ID -Values @{"E2Provisioned" = "Yes"}
Sleep 80

Remove-PnPListItem -List Onboarding -Identity $ID -Force
 }
}

Disconnect-MgGraph

Stop-Transcript