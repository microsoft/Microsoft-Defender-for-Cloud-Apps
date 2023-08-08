<# 
.DESCRIPTION
    Get the list of continuous discovery reports in Defender for Cloud Apps. 
    Discovery reports are a reference to where the discovery data is stored.
    
#>
<################################################
   Setting variables
################################################>

$TenantAPIURL = "<Your Tenant URL>" # you can find this at https://security.microsoft.com/cloudapps/settings?tabid=about
$LogSource = "PALO_ALTO" #Change to your log source (Refernce https://learn.microsoft.com/en-us/defender-cloud-apps/api-discovery-initiate#request-url-parameters)
$ReportsFolder = "<Folder>\Discovery\Reports" #This is the folder where the PowerShell scripts are


# Check if access token is still valid
if ($null -eq $global:AzureADAccessTokenMDA -or $global:AzureADAccessTokenMDAExpiration -lt $now) {
    Write-Host "Access token is not valid. Please run the Get-AzureADAccessToken cmdlet again."
    return
}


<################################################
   Getting the List of continuous reports
################################################>

    Write-Host "+ Getting report..." 

    #Calling the API 
    $APIEndpoint = '/api/discovery/streams/'

    <# Construct Graph API call #>
    $Headers = @{
        "Authorization" = "Bearer $($global:AzureADAccessTokenMDA)"
        "Content-type"  = "application/json"
    }

    try {
        $apiUri = $TenantAPIURL+$APIEndpoint
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
        Write-Host "Error: " -ForegroundColor Red -NoNewline
        Write-Error $_.Exception.Message
        $ex = $_.Exception
        #$errorResponse = $ex.Response.GetResponseStream()
        #$reader = New-Object System.IO.StreamReader($errorResponse)
        #$reader.BaseStream.Position = 0
        #$reader.DiscardBufferedData()
        #$responseBody = $reader.ReadToEnd();
        Write-Error "Request to $apiUri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        write-host
        break
    }


