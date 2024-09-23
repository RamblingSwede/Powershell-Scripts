CLS
#Requires -Modules ActiveDirectory
#Requires -Modules ExchangeOnlineManagement

#Pre-requisites
Write-Output "Importing Active Directory Module"
Import-module ActiveDirectory
Write-Host "AD Module Imported"

Write-Output "Importing Exchange module"
Import-module ExchangeOnlineManagement
$OnPrem = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://Redacted/Powershell -Authentication Kerberos 
Import-PSSession $OnPrem -AllowClobber
Write-Host "EAC Module Imported"
Sleep 3
CLS
 
#Variables to define
$Firstname = Read-Host "Please input Firstname" 
$Lastname = Read-Host "Please input Lastname" 
$Password = Read-Host "Please choose a password" -AsSecureString
 
$JobTitle = Read-Host "Please input Job Title"
$Department = Read-Host "Please input Department"

$Fullname = "$Firstname $Lastname"
$LogonName = "$Firstname.$Lastname"
$Domain = Redacted
$Email = "$Firstname.$Lastname@$Domain"
$Email = $Email.tolower()

#Main Query
CLS
Write-Host "Creating Account..."
New-RemoteMailbox -Name "$Fullname" -FirstName "$Firstname" -LastName "$Lastname" -OnPremisesOrganizationalUnit Redacted -UserPrincipalName "$Email" -Password $Password | Out-Null 
Write-Host "Account created!" 
Sleep 3 

Write-Host "Adding AD attributes..." 
Get-ADUser -Identity "$LogonName"| Set-ADUser -Description "$JobTitle" -Office "$Department" -OfficePhone Redacted -HomePage Redacted -StreetAddress Redacted -City Redacted -State Redacted -PostalCode Redacted -Country "GB" -Title "$Jobtitle" -Department "$Department" -Company "Wood Green, The Animals Charity" 
Write-Host "AD attributes configured!"
Sleep 3 

Write-Host "Adding AD Groups..." 
Get-ADuser -Identity "$LogonName"| Add-ADPrincipalGroupMembership -MemberOf Redacted
Write-Host "Groups Added!"
Sleep 3 

CLS
$AddManager = Read-Host "Would you like to add a manager? (Y/N)" 
If ($AddManager -eq "Y")
{
CLS
$Manager = Read-Host "Please input Manager (name.lastname)" 
CLS
Write-Host "Populating Manager field..." 
Get-ADuser -Identity "$LogonName" | Set-Aduser -Manager "$Manager" 
Write-Host "Manager field populated!"
Write-Host "($FullName) has been created, don't forget to move to the correct OU"
Write-Host ""
Read-Host "Press Enter to continue" | CLS
}
Else 
{
CLS
Write-Host "Manager field left blank." 
Write-Host "($FullName) has been created, don't forget to move to the correct OU"
Write-Host ""
Read-Host "Press Enter to continue" | CLS
}

Get-PSSession | Remove-PSSession 
