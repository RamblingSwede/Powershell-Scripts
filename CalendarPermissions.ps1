#Declares pre-requisites for the script to run
#Requires -Modules exchangeonlinemanagement
#Requires -Modules ActiveDirectory

Connect-ExchangeOnline

while ($continue -ne "Y"){
    Clear-Host

    $calendar = read-host "Input the full email address of the calendar you want to tweak"
    get-aduser -filter 'userprincipalname -like $calendar' -properties Name, Title | Select-Object Name, Title | Format-Table
    $continue = read-host "Continue with this calendar? (Y/N)"
    }

function main {
    $continue = "N"
    while ($continue -ne "Y"){
    Clear-Host 
    
    $user = read-host "Input the name of the user you want to provide with calendar rights (firstname.lastname)"
    get-aduser -identity $user -properties Name, Title | Select-Object Name, Title | Format-Table
    $continue = read-host "Continue with this user? (Y/N)"
    }
    
    Clear-Host
    
    write-host "1. Owner (Full Access)"
    write-host "2. Editor (Create, read, modify, delete all items)"
    write-host "3. Author (Create, read, modify, delete any items they have created)" 
    $accessrights = read-host "What level of permission do you want to grant the user?"
    switch ($accessrights){
        "1" {$accessrights = "Owner"}
        "2" {$accessrights = "Editor"}
        "3" {$accessrights = "Author"}
	    "4" {$accessrights = "Reviewer"}
        Default {Read-Host "Not a valid input, press Enter to try again"}
        }

add-mailboxfolderpermission -identity ${calendar}:\Calendar -user $user -accessrights $accessrights

$repeat = read-host "Add any more users to this calendar? (Y/N)" 
if ($repeat -eq "N"){ Disconnect-ExchangeOnline -Confirm:$false}
else {main}
}

main