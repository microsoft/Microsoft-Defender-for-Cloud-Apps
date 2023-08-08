<# 
.DESCRIPTION
    Get the list of users for a specific App, within a specific stream 
.PARAMETER StreamID, AppID, StreamTimeFrame
    You need to specify these three paramaters in order to obtain information about the users using this App in the given time frame. 
#>
#Define the Stream ID
$StreamID = "5fc7b832ec839dcf131de937"
#Define the App ID
$AppID = "20893"
#Define the Stream Time Frame (Valid values are P7D P30D P90D)
$streamTimeFrame = "P30D"

# Check if access token is still valid
if ($null -eq $global:AzureADAccessToken -or $global:AzureADAccessTokenExpiration -lt $now) {
    Write-Host "Access token is not valid. Please run the Get-AzureADAccessToken cmdlet again."
    return
}
# Call the API to get the list of users for a specific App, within a specific stream
$resourceGraph = "https://graph.microsoft.com"
$discoveredAppsEndpoint = "$resourceGraph/beta/security/dataDiscovery/cloudAppDiscovery/uploadedStreams/$streamID/aggregatedAppsDetails(period=duration'$streamTimeFrame')/$AppID"
$discoveredUsersEndpoint = "$resourceGraph/beta/security/dataDiscovery/cloudAppDiscovery/uploadedStreams/$streamID/aggregatedAppsDetails(period=duration'$streamTimeFrame')/$appID/users"
$headers = @{
    'Authorization' = "Bearer $($global:AzureADAccessToken)"
}
$response1 = Invoke-RestMethod -Uri $discoveredAppsEndpoint -Headers $headers -Method GET
$DiscoveredAppName = $response1.displayName
$DiscoveredAppUsers = $response1.usercount
write-host "Discovered App Name: " $DiscoveredAppName
write-host "Discovered App Users: " $DiscoveredAppUsers

$response2 = Invoke-RestMethod -Uri $discoveredUsersEndpoint -Headers $headers -Method GET
$DiscoveredUsersList = $response2.value 

$count = 0
$DiscoveredUsersListArray = @()
#get a list of users to remove duplicates
foreach ($DiscoveredUsersList in $DiscoveredUsersList) {
    $DiscoveredUsersListArray += "$DiscoveredUsersList",""
    $count++
}
$DiscoveredUsersListArray = $DiscoveredUsersListArray | Where-Object {$_ -ne ""} | Select-Object -Unique 
write-host "Discovered Users: " $DiscoveredUsersListArray 


