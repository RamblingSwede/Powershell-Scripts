CLS

Import-module ActiveDirectory

$OnPrem = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://Redacted/Powershell -Authentication Kerberos 
Import-PSSession $OnPrem -AllowClobber

#Exchange parameters
CLS
$Name = Read-Host "Desired Mailbox DisplayName"
$Email = Read-Host "Desired Mailbox EmailAddress"
$Department = Read-Host "Requester department"
$Email = $Email.tolower()
$Password = Read-Host "Input Password" -AsSecureString

New-RemoteMailbox -Name "$Name" -OnPremisesOrganizationalUnit "Redacted" -UserPrincipalName "$Email@Redacted" -Password $Password | Out-Null 

#AD parameters
$Name = $Name.tolower()
Get-ADUser -Identity "$Email" | Set-ADUser -Description "$Department Shared Mailbox" -Office $Department -OfficePhone "Redacted" -HomePage "Redacted" -StreetAddress "Redacted" -City "Redacted" -State "Redacted" -PostalCode "Redacted" -Country "Redacted" -Title "$Department Shared Mailbox" -Department "$Department" -Company "Redacted"
CLS
Write-Host "$Email successfully created"

Get-PSSession | Remove-PSSession 