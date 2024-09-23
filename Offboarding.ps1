#Clears the console.
CLS

#Connects to O365 Admin.
Connect-mgGraph -Scopes "User.ReadWrite.All","Group.ReadWrite.All"

#A .txt file with the users current groups,shared mailboxes and assigned Licenses (before being offboarded) will be saved here. 
$Path = "../Offboarding"

Function main_loop {
CLS

#Generates a random password and converts it into a secure string.
Add-Type -AssemblyName System.Web
$password = [System.Web.Security.Membership]::GeneratePassword(15, 0)
$password = ConvertTo-SecureString -String $password -AsPlainText -Force

#Prompts for user
$Continue = "N"
While ($Continue -like "N"){
$global:User = Read-Host "Please input user to offboard (firstname.lastname) or type 'quit' to exit"

#Lets you gracefully exit the script
If ($User -eq "quit") {
CLS
Read-Host "See you later Space Cowboy (Press Enter to exit)"
Disconnect-MgGraph
Get-PSSession | Remove-PSSession
Exit
}

#Sets all the variables the script needs
Else {
$global:User = $User.ToLower()
$UserEmail = "$User@Redacted"
$Licenses = Get-MgUserLicenseDetail -UserId $UserEmail | Select-object SkuPartNumber
CLS
$AdGroups = Get-ADPrincipalGroupMembership -Identity $User 
Get-ADUser -Identity $User -Properties “LastLogonDate”, "Title" | Select Name, Title, LastLogonDate | FT
$Continue = Read-Host "Offboard user? (Y/N)"
CLS
}

#Removes assigned licenses, keeping E2.
If ($Continue -like "Y"){ 
Write-Output $Licenses | out-file $Path\$User.txt -Append
Write-Output "Removing assigned Licenses.."
Foreach ($License in $Licenses){
If ($License.SkuPartNumber -ne "ENTERPRISEPACK"){
$EmsSku = Get-MgSubscribedSku -All | Where SkuPartNumber -eq $License.SkuPartNumber
Set-MgUserLicense -UserId $UserEmail -AddLicenses @() -RemoveLicenses @($EmsSku.SkuId)
  }
 }

Write-Output "Assigned Licenses removed!"
Sleep 1
CLS

#Removes ADgroups from user, adds them to nonMFA-users if needed.
Write-Output $AdGroups | Select-Object SamAccountName | out-file $Path\$User.txt -Append
Write-Output "Removing group memberships..."
Foreach ($Group in $AdGroups){ 
If ($Group -notlike "*Redacted*" -and $Group -notlike "*Redacted*"){
Remove-ADPrincipalGroupMembership -Identity $User -MemberOf $Group -Confirm:$false 
$Null = Add-ADPrincipalGroupMembership -Identity $User -MemberOf "Non MFA Users" 
 }
}
Write-Output "Group memberships removed!"
Sleep 1 
CLS

#Moves user to the disabled users OU
Write-Output "Moving $user to Disabled Users OU..."
$ADUser = Get-ADUser -Identity $User
Move-ADObject -Identity $ADUser -TargetPath "OU=Redacted,DC=Redacted,DC=Redacted,DC=Redacted,DC=Redacted"
Write-Output "$user moved"
Sleep 1
CLS

#Resets the users password
Set-ADaccountPassword -Reset -Identity $User -NewPassword $password
Write-Output "Password Reset!"
Sleep 1 
CLS

#Hides user from address list via Exchange Online Powershell
Write-Output "Hiding $user from global address list..."
$OnPrem = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://Redacted/Powershell -Authentication Kerberos 
Import-PSSession $OnPrem -AllowClobber

Set-RemoteMailbox -Identity $User -HiddenFromAddressListsEnabled $True 
Write-Output "$user hidden from global address list!"
Sleep 1 
CLS
    }
  }
}

$Continue = "Y"
While ($Continue -like "Y"){
main_loop
$Continue = Read-Host "$User successfully offboarded, offboard another user? (Y/N)"

If ($Continue -like "N"){
Disconnect-MgGraph
Get-PSSession | Remove-PSSession
cls
Exit
}

else {
  main_loop
  } 
}
