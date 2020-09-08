<#	
	.NOTES
	===========================================================================
     Created on:   	17.04.2020
     Version:       2.2
     LastUpdated:   12.05.2020
	 Created by:   	Steffen.Lysaker
	 Organization: 	ROR-IKT
	 Filename:     	ExpandNestedGroupmembership
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>


#Logging module
Import-Module LoggingFunction.psm1

#Enable logging?
[SWITCH]$logging = $true
#Logging params
$logpath = "C:\Logs\ScriptLogs\"
$filename = "ExpandNestedGroupmembershipLogs-$(get-date -Format ddMMyy-hhmm).log"
$Logfile = $logpath + $filename
Create-LogFile $Logfile

write-LogFile "Starting script: ExpandNestedGroupmembership"

Write-LogFile "Changing LogRetetionTime to 10 days"
$LogRetentionTime = "10"
Remove-OldLogs $logpath



#Script begin


#Finding group to expand
Write-LogFile "Getting groups to expand nested membership"
$GroupsToExpand = get-adgroup -Filter 'extensionAttribute11 -eq "ExpandNested"'

write-LogFile "Found $($GroupsToExpand.count) group to expand"
foreach ($group in $GroupsToExpand) {

    $x++
    write-LogFile "Expanding group $x of $($GroupsToExpand.count): $($group.SamAccountName)"
    $DirectUserMembership =  (get-adgroup $group -Properties members ).members | where {$_ -match "brukere"}
    $GroupMembership = (get-adgroup $group -Properties members ).members | where {$_ -match "grupper"}

    #Loop through all groups
        $totalNestedGroups = @()
        $totalNestedGroups += $GroupMembership
        $NestedGroupToTest = $GroupMembership

            do {
                $NewNestedGroups = $NestedGroupToTest | foreach { (get-adgroup -Identity $_ -Properties members).members | where {$_ -match "grupper"} }
                if ($NewNestedGroups) { 
                    $NestedGroupToTest = foreach ($g in $NewNestedGroups) {
                        if (!($totalNestedGroups -contains $g)) { $g }
                    }        
                }
                $totalNestedGroups += $NewNestedGroups | foreach { if ($totalNestedGroups -notcontains $NewNestedGroups) {$_ } }
            }
            while ( $NewNestedGroups ) 
    
    write-LogFile "Getting nested group members"
    $NestedGroupMembership = @()
    foreach ($childGroup in $totalNestedGroups) {
        $NestedGroupMembership += (Get-ADGroup $childGroup -Properties members).members | where {$_ -match "brukere"} 
    }
    $UniqueNestedGroupMembership = $NestedGroupMembership | select -Unique

    #Clean up group and remove user that should no longer have access
    if ($DirectUserMembership) {
        write-LogFile "Finding users to remove from group"
        foreach ($user in $DirectUserMembership) {
            if ($UniqueNestedGroupMembership.SamAccountName -notcontains $user.SamAccountName) {
                write-LogFile "Removing user $($user.SamAccountName) from group" 
                Remove-ADGroupMember -Identity $group -Members $user -Confirm:$false
            }
        }
    }

    #Adding DirectUserMembership to nested group members
    if ($UniqueNestedGroupMembership) {
        write-LogFile "Adding/updating group with $($UniqueNestedGroupMembership.count) users"
        Add-ADGroupMember -Identity $group -Members $UniqueNestedGroupMembership
    }

}
