<# 
.DESCRIPTION
    Get the list of discovery streams. 
    Discovery streams are a reference to where the discovery data is stored.
    For example, Defender for Endpoint automatically uploads to a discovery stream called "Win10 Endpoint Users"
    You may have multiple discovery streams if you have multiple sources of discovery data.
#>
# Check if access token is still valid
if ($null -eq $global:AzureADAccessToken -or $global:AzureADAccessTokenExpiration -lt $now) {
    Write-Host "Access token is not valid. Please run the Get-AzureADAccessToken cmdlet again."
    return
}
# Call the API to get the list of discovery streams
$resourceGraph = "https://graph.microsoft.com"
$discoveryStreamsEndpoint = "$resourceGraph/beta/security/dataDiscovery/cloudAppDiscovery/uploadedStreams"
$headers = @{
    'Authorization' = "Bearer $($global:AzureADAccessToken)"
}
$response = Invoke-RestMethod -Uri $discoveryStreamsEndpoint -Headers $headers -Method GET
$DiscoveryStreams = $response.value
$DiscoveryStreams
#Optional: Export each stream to excel
#$DiscoveryStreams | Export-Csv -Path "<FolderPath>\MDA_DiscoveryStreams.csv"
