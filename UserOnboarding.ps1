Start-Transcript -Path "C:\Automation\User_Transcript.txt"

#Requires -Modules ActiveDirectory
#Requires -Modules ExchangeOnlineManagement
#Requires -Modules PnP.Powershell

#Pre-requisites, all need to be installed and imported for script to function.
#PnP is used to integrate with Sharepoint
#ActiveDirectory is used to integrate with.... ActiveDirectory
#ExchangeOnlineManagement is needed as we work in a hybrid environment, lets the script connect to our on-prem server and create the account directly for it to then sync over to AD
Import-Module PnP.Powershell -Force
Import-module ActiveDirectory -Force
Import-module ExchangeOnlineManagement -Force

#Imports a generic password for initial creation
$Password = Import-Clixml -Path Redacted 

#Pulls a list of all currently existing AD accounts
$CheckUser = ( Get-ADUser -Filter * -ErrorAction Stop | Sort Name ).Name

#Connects to the on-prem exchange server
$OnPrem = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://Redacted/Powershell -Authentication Kerberos
Import-PSSession $OnPrem -AllowClobber

#Connects to the IT-Team sharepoint site to pull user details from our Onboarding list
$SiteUrl = Redacted
$Credentials = Import-Clixml Redacted
Connect-PnPOnline $SiteUrl -ClientId Redacted -ClientSecret Redacted

#Declares the fields to pull from the Shareppoint list
$Fields =  "FullName", "LastName", "Site", "JobTitle", "Department", "Requester"
$Listitems = (Get-PnPListItem -PageSize 1000 -List Onboarding -fields $Fields).fieldvalues

#Loops through each list item (User) found on Sharepoint, creating a new user and filling in the relevant fields in AD. Default AD groups and logonscript are also added
#Any errors will be output into Redacted - Automation\Onboarding\Error Log\Errorlog.txt
foreach ($User in $ListItems)
{
$ID = $User.ID

$FirstName = $User.FullName
$LastName = $User.LastName -replace [char]39
$Site = $User.Site
$JobTitle = $User.JobTitle
$Department = $User.Department

$Fullname = "$FirstName $LastName"
$LogonName = "$FirstName.$LastName"
$SamAccountName = $LogonName.Substring(0, [System.Math]::Min(20,$LogonName.Length)).ToLower() 
$Domain = Redacted
$Email = "$LogonName@$Domain"
$Email = $Email.tolower()

$Time = get-date -Format "ddMMyyhhmm"
$Path = "C:\Automation\Documents\Errorlog_$Time.txt" 

$CheckExists = $False
$CheckExists = $CheckUser -contains $Fullname
if($CheckExists -eq "True") {Write-Output "$Fullname already exists, please check AD"  |  Out-File "C:\Automation\Documents\Errorlog_$Time.txt" -Append 
Sleep 10
Add-PnPFile -Path $Path -folder "Shared Documents/Automation/Onboarding/Error Log/"
}
else {
Try { 
New-RemoteMailbox -Name "$Fullname" -FirstName "$Firstname" -LastName "$Lastname" -OnPremisesOrganizationalUnit Redacted -UserPrincipalName "$Email" -SamAccountName $SamAccountName -Password $Password -ErrorAction Stop  | Out-Null
Sleep 1 
Get-ADUser -Identity "$SamAccountName"| Set-ADUser -Description "$JobTitle" -Office "$Department" -OfficePhone Redacted -HomePage "www.$Domain" -StreetAddress Redacted -City Redacted -State Redacted -PostalCode Redacted -Country Redacted -Title "$Jobtitle" -Department "$Department" -Manager $Manager -Company Redacted -ScriptPath logon.bat 
Sleep 1
Get-Aduser -Identity "$SamAccountName"| Add-ADPrincipalGroupMembership -MemberOf Redacted, Redacted, Redacted, Redacted
Sleep 80

#Remove-PnPListItem -List Onboarding -Identity $ID -Force
 }

Catch {
$Time = get-date -Format "ddMMyyhhmm"
$Path = "C:\Automation\Documents\Errorlog_$Time.txt" 
$_| Out-File -FilePath $Path 
Sleep 10
Add-PnPFile -Path $Path -folder "Shared Documents/Automation/Onboarding/Error Log/"
  }
 }
}
Disconnect-PnPOnline
Get-PSSession | Remove-PSSession 

Stop-Transcript