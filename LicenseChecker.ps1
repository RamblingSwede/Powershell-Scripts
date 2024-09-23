#Connects to MgGraph to pull license information
Connect-MgGraph -Scopes "User.Read.All","Group.ReadWrite.All, Organization.Read.All" -NoWelcome

#Query to find users with
$users = get-aduser -Identity "joel.ljungdahl"

#Path to save file to, has to include filetype
$path = '.\file.csv'

#Outer loop, loops through every user in environment
foreach ($user in $users){

    #Finds all licenses user has assigned
    $licenses = @(Get-MgUserLicenseDetail -UserId $user.UserPrincipalName)

    #Empty list that the next loop will add translated license names to
    $license_names = @()

    #Empty dictionary that the next loop will add key(Name) and value(Email, License list) pairs to
    $dict = @{}

    #Loops through all licenses assigned to user, translating Microsofts useless internal names to something that makes sense
    #Needs to be manually expanded on following below syntax, translations found here: https://learn.microsoft.com/en-us/entra/identity/users/licensing-service-plan-reference
    #Only add to switch, Default needs to be left as is
    foreach ($license in $licenses){

        switch($license.SkuPartNumber){
            "ENTERPRISEPACK" {$licensename = "Office 365 E3"}
            "FLOW_FREE" {$licensename = "Microsoft Power Automate Free"}
            "POWER_BI_STANDARD" {$licensename = "Microsoft Fabric (Free)"}
            "AAD_PREMIUM_P2" {$licensename = "Microsoft Entra ID P2"}
        Default{
            $licensename = $license.SkuPartNumber}
        }
        #Adds the translated license names to the empty list
        $license_names += $licensename
    } 

    #Black magic (export csv is the bane of my life)
    #To avoid export-csv printing nonsense each individual value has to be converted to a custom powershell object
    #Once finished appends to a .csv
    $dict += @{Name=$user.name; Email=$user.UserPrincipalName; Licenses=[PSCustomObject]$license_names}
    [PSCustomObject]$dict | Select-Object Name, Email, Licenses |
    Export-Csv -Path $path -NoTypeInformation -Append

}

Disconnect-MgGraph