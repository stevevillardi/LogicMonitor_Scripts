$pollingInterval = 300

#Get current time in UTC Epoch in milliseconds
$unixEpochStart = new-object DateTime 1970, 1, 1, 0, 0, 0, ([DateTimeKind]::Utc)

#Calcualte start and end time for parsing log file
$startTime = [int64]([DateTime]::UtcNow.AddSeconds(-$pollingInterval) - $unixEpochStart).TotalMilliseconds
$endTime = [int64]([DateTime]::UtcNow - $unixEpochStart).TotalMilliseconds

#Load SQL Log and parse headers
$filePath = "C:\InetPub\Logs\LogFiles\W3SVC1\u_ex$(Get-Date -F 'yyMMdd').log"
$headers = @((Get-Content -Path $filePath -ReadCount 4 -TotalCount 4)[3].split(' ') | Where-Object { $_ -ne '#Fields:' });
$content = (Get-Content -Path $filePath | Where-Object { $_ -notmatch '^#' });

#Connect to LM API
Connect-LMAccount -AccessId rpqbY28eQTffxSyL8b8J -AccessKey "F758+(+Gud-2b=9vcrx94H^SeE2jT(}4_K7p(2+^" -AccountName lmstevenvillardi

#Process Log entries add latest ones to the message queue
$messageArray = @()
Foreach ($entry in $content) {
    #Convert log entry time to utc epoch in milliseconds
    $entryTime = ([datetime]::parseexact($($entry.split(" ")[0..1] -join " "), 'yyyy-MM-dd HH:mm:ss', $null) - $unixEpochStart).TotalMilliseconds
    If ($entryTime -ge $startTime -and $entryTime -le $endTime) {
        #Send LM Log Message
        $messageArray += @{
            "message"         = $entry.ToString()
            "timestamp"       = $entryTime
            '_lm.resourceId'  = @{"system.displayname" = "lmstevenvillardi-wincol02" }
            "request-date"    = $entry.split(" ")[0]
            "request-time"    = $entry.split(" ")[1]
            "s-ip"            = $entry.split(" ")[2]
            "cs-method"       = $entry.split(" ")[3]
            "cs-uri-stem"     = $entry.split(" ")[4]
            "cs-uri-query"    = $entry.split(" ")[5]
            "s-port"          = $entry.split(" ")[6]
            "cs-username"     = $entry.split(" ")[7]
            "c-ip"            = $entry.split(" ")[8]
            "cs(User-Agent)"  = $entry.split(" ")[9]
            "cs(Referer)"     = $entry.split(" ")[10]
            "sc-status"       = $entry.split(" ")[11]
            "sc-substatus"    = $entry.split(" ")[12]
            "sc-win32-status" = $entry.split(" ")[13]
            "time-taken"      = $entry.split(" ")[14]
        }
    }
}
#Send our array of messages
Send-LMLogMessage -MessageArray $messageArray -Verbose

#Close LM API Session
Disconnect-LMAccount