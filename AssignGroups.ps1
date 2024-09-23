#Declares pre-requisites for the script to run
#Requires -Modules exchangeonlinemanagement
#Requires -Modules MicrosoftTeams

#Establishes credentials to use for signing into the O365 services
$Credentials = Get-Credential
cls

#Connects to the various O365 services we'll need
Write-Output "Connecting to O365 services"
Connect-MgGraph -Scopes "User.Read.All","Group.ReadWrite.All, Organization.Read.All"
Write-Output "Waiting for ExchangeOnline..."
Connect-MicrosoftTeams -Credential $Credentials > $null
Connect-ExchangeOnline -Credential $Credentials > $null

#This is where each departments accesses are declared
$Redacted = @{"Listnumber" = 0; "OU" = "OU=Redacted,OU=Redacted,DC=Redacted,DC=Redacted,DC=Redacted,DC=Redacted"; "Department" = "IT"; "Groups" = Redacted, Redacted; "Mailboxes" = Redacted; "TeamsID" = Redacted}
$Redacted = @{"Listnumber" = 1; "OU" = "OU=Redacted,OU=Redacted,OU=Redacted,DC=Redacted,DC=Redacted,DC=Redacted,DC=Redacted"; "Department" = Redacted; "Groups" = Redacted, Redacted; "Mailboxes" = Redacted, Redacted; "TeamsID" = Redacted} 
$Redacted = @{"Listnumber" = 2; "OU" = "OU=Redacted,OU=Redacted,DC=Redacted,DC=Redacted,DC=Redacted,DC=Redacted"; "Department" = Redacted; "Groups" = Redacted, Redacted; "Mailboxes" = Redacted; "TeamsID" = Redacted}
$Redacted = @{"Listnumber" = 3; "OU" = "OU=Redacted,OU=Redacted,DC=Redacted,DC=Redacted,DC=Redacted,DC=Redacted"; "Department" = Redacted; "Groups" = Redacted; "Mailboxes" = Redacted; "TeamsID" = Redacted}

#Requests a user and verifies the provided user exists
function verify_user {
$Continue = "N"
While ($Continue -eq "N"){
cls
$global:User = Read-Host "Please input User (firstname.lastname) to provide accesses for or type 'quit' to quit"
If ($User -eq "quit") {
    cls
    Read-Host "See you later Space Cowboy (Press Enter to exit)"
    Disconnect-MgGraph
    Disconnect-ExchangeOnline -Confirm:$false
    Disconnect-MicrosoftTeams
    Exit
}
cls
$global:User = $User.ToLower()
$global:UserEmail = "$User@woodgreen.org.uk"
Get-ADUser -Identity $User -Properties "Title" | Select Name, Title | FT
$Continue = Read-Host "Is this the correct user? (Y/N)"
 }
}

#Provides a selection menu of available departments
function department_menu {
$Continue = "N"
While ($Continue -eq "N"){
cls
Write-Host "====== Choose Department ======"
Write-Host $Redacted.Listnumber "-" $Redacted.Department
Write-Host $Redacted.Listnumber "-" $Redacted.Department
Write-Host $Redacted.Listnumber "-" $Redacted.Department
Write-Host $Redacted.Listnumber "-" $Redacted.Department
Write-Host "B - Choose another user"

$global:Menu_choice = Read-Host "Please choose a department"
switch ($Menu_choice){
    "b" {verify_user}
    "0" {$Department = $Redacted.Department}
    "1" {$Department = $Redacted.Department}
    "2" {$Department = $Redacted.Department}
    "3" {$Department = $Redacted.Department}
    Default {
        Read-Host "Not a valid input, press Enter to try again"
        department_menu
     }
   }
cls
$Continue = Read-Host "Proceed with adding $User to $Department (Y/N)"
cls
 }
}

#Loops through the various accesses required and adds them to the user
function add_accesses ($dep) {
    cls
    Get-ADUser -Identity $User | Move-ADObject -TargetPath $dep.OU
    Get-ADuser -Identity $User | Add-ADPrincipalGroupMembership -MemberOf $dep.Groups
    foreach ($mailbox in $dep.Mailboxes) {
        Add-MailboxPermission -Identity $mailbox -AccessRights FullAccess -InheritanceType All -AutoMapping:$true -User $User
        Add-RecipientPermission -Identity $mailbox -AccessRights SendAs -Confirm:$false -Trustee $User
    }
    Add-TeamUser -GroupId $dep.TeamsID -User $UserEmail
}

#This is the main loop of the script
$Continue = "Y"
While ($Continue -eq "Y") {
verify_user
department_menu
switch ($Menu_choice){
    "0" {add_accesses $Redacted}
    "1" {add_accesses $Redacted}
    "2" {add_accesses $Redacted}
    "3" {add_accesses $Redacted}
}
cls
$Continue = Read-Host "Accesses granted, proceed with another user? (Y/N)"
If ($Continue -eq "N"){
    cls
    Read-Host "See you later Space Cowboy (Press Enter to exit)"
    Disconnect-MgGraph 
    Disconnect-ExchangeOnline -Confirm:$false
    Disconnect-MicrosoftTeams
    Exit
    }
}