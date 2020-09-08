
## Support functions
function Get-TimeStamp {
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date) 
}

function Remove-OldLogs($logpath) {
    if (!($LogRetentionTime)) { $LogRetentionTime = 180 }
    if ($logpath) {
        $LogfilesToRemove = Get-ChildItem $logpath | Where { $_.LastWriteTime -lt $(get-date).adddays(-$LogRetentionTime) -and $_.Name -like "*log" }
        if ($LogfilesToRemove) {
            if ($logging) {
                write-LogFile "Removing old logfiles (older than 180 days)"
                    foreach ($file in $LogfilesToRemove) {
                        write-LogFile "Removing logfile: $($file.name)"
                    }
            }
            $LogfilesToRemove | Remove-Item
        }
        else { 
            if ($logging) {
                write-LogFile "No old logfiles to remove"
            }
         }
    }
}

Function Create-LogFile($logfile) {
    if ($logging) { 
            if (-not (Test-Path $logfile)) { 
            New-Item -ItemType File -Path $logfile
        }
    }
}


Function write-LogFile($logmessage) {
    if ($logging) {
        write-output "$(Get-TimeStamp) $logmessage" | Out-file $logfile -append
    }
}

## Mandatory attributes

#$logpath = "c:\Temp\"
#$filename = "Logs-$(get-date -Format ddMMyy-hhmm).log"
#$Logfile = $logpath + $filename
#[SWITCH]$logging = $false

## Optional attributes

#$LogRetentionTime = "90"

