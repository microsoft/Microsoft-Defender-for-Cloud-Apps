<# 
.DESCRIPTION
    Get the list of discovered Apps for a specific Discovery Stream 
.PARAMETER StreamID, StreamTimeFrame
    You need to specify these two paramaters in order to obtain information about this App in the given time frame. 
#>
#Define the Stream ID
$StreamID = "5fc7b832ec839dcf131de937"
#Define the Stream Time Frame (Valid values are P7D P30D P90D)
$streamTimeFrame = "P7D"

# Check if access token is still valid
if ($null -eq $global:AzureADAccessToken -or $global:AzureADAccessTokenExpiration -lt $now) {
    Write-Host "Access token is not valid. Please run the Get-AzureADAccessToken cmdlet again."
    return
}

# Call the API to get the list of discovered Apps for a specific Discovery Stream 
$resourceGraph = "https://graph.microsoft.com"
$discoveredAppsEndpoint = "$resourceGraph/beta/security/dataDiscovery/cloudAppDiscovery/uploadedStreams/$streamID/aggregatedAppsDetails(period=duration'$streamTimeFrame')"
$headers = @{
    'Authorization' = "Bearer $($global:AzureADAccessToken)"
}
$response = Invoke-RestMethod -Uri $discoveredAppsEndpoint -Headers $headers -Method GET
$DiscoveredApps = $response.value
$DiscoveredApps
#Optional: Export the list of Apps to excel
#$DiscoveredApps | Export-Csv -Path "<FolderPath>\MDA_DiscoveredApps.csv"

