<################################################
   Setting variables
################################################>

$TenantURL = "<Your Tenant URL>" # you can find this at https://security.microsoft.com/cloudapps/settings?tabid=about
$LogSource = "PALO_ALTO" #Change to your log source (Refernce https://learn.microsoft.com/en-us/defender-cloud-apps/api-discovery-initiate#request-url-parameters)

$sourceScriptFolder = "<Folder>\Discovery" #This is the folder where the PowerShell scripts are
$ReportsFolder = "<Folder>\Discovery\Reports" #This is the folder where the PowerShell scripts are

#Testing if Get-AppToken-MDA.ps1 exists and obtaining a new token
if (Test-Path "$sourceScriptFolder\Get-AppToken-MDA.ps1"){
        Write-Host "Powershell file found, running it to get the access token"
        $token = ./Get-AppToken-MDA.ps1
        if($token){
            Write-Host "Token acquired!"
        }else { 
            Write-Host "Something went wrong and we couldn't get a token, please verify if Get-AppToken-MDA.ps1 is configured properly" -f Red
        break
        }
}else { 
        Write-Host "Powershell file not found, please copy Get-AppToken-MDA.ps1 to this folder" -f Red
        break
}


<################################################
   Getting the List of continuous reports
################################################>

    Write-Host "+ Getting report..." 

    #Calling the API 
    $APIEndpoint = '/api/discovery/streams/'

    <# Construct Graph API call #>
    $Headers = @{
        "Authorization" = "Bearer $($token)"
        "Content-type"  = "application/json"
    }

    try {
        $apiUri = $TenantURL+$APIEndpoint
        $GetList = (Invoke-RestMethod -Headers $Headers -Uri $apiUri -Method GET)
        if($GetList) 
        {
            Write-Host "| - Report obtained succesfully: "
            Write-Host "| - Number of reports: " ($GetList.streams).count
            
            foreach ($item in $GetList.streams){
            $ReportName = $item.displayName
            write-host "Item:" $ReportName -ForegroundColor Black -BackgroundColor White
            write-host "|- Number for input received: " $item.logFilesHistoryCount
            write-host "|- Last data received: " $item.lastDataReceived 
            #Optional: Export each stream to excel
            #$item | Export-Csv -Path "$ReportsFolder\MDA_Continuous_Reports_$ReportName.csv"
            }
            
            #Exporting all streams to JSON
            $JSON = $GetList.streams | ConvertTo-Json
            Set-Content -Path "$ReportsFolder\MDA_Continuous_Reports_ALL.json" -Value $JSON -Encoding UTF8

        }else{
            Write-Host "| -Something went wrong, the API response is empty" -f Red
            break
        }

    } 
    catch {
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content for getting Upload URL:`n$responseBody" -f Red
        Write-Error "Request to $apiUri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        write-host
        break
    }


