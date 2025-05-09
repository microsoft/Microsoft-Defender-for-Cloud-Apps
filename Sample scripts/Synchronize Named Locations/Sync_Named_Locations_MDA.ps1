# Created by the MDA CXE team for demonstration purposes.  This script is meant to be used as a sample and is not supported by Microsoft.
# Use at your own risk or modify as needed.  This script is provided as is with no warranty or support.
# The purpose of this script is to synchronize named locations from Entra ID to MDA.  This script will create new named locations in MDA if they don't exist 
# or update existing named locations if the IP ranges have changed.  This script will not delete named locations in MDA if they are removed from Entra ID.
# ---------------------------------------------------------------------------------------
# To utilize this script you will need to create an app registration in Entra ID with the following permissions:
# Microsoft Graph - Policy.Read.All and then make sure it has also been consented to by an admin
# Cloud App Security - will require an API token from the MDA portal
#---------------------------------------------------------------------------------------
# Client ID, Secret, and Tenant ID for your Entra ID App Registration
$clientId = "client ID from app registration"
$clientSecret = "client secret from app registration"
$tenantId = "Entra ID tenant ID"
$mdaToken = "API token from MDA"
$mdaHeader = @{Authorization = "Token " + $mdaToken }

#---------------------------------------------------------------------------------------
#Define the organization / ISP that will be registered in MDA when the range is created this should
# be your organization name
$organization = "Your Organization Name"

#---------------------------------------------------------------------------------------
# Define the API endpoints needed to get named location and write to MDA
#---------------------------------------------------------------------------------------
$resourceGraph = "https://graph.microsoft.com"
#---------------------------------------------------------------------------------------
#replace this entry with the MDA endpoint for your tenant this is typically https://tenant.datacenter.portal.cloudappsecurity.com
# for example https://contoso.us3.portal.cloudappsecurity.com
#----------------------------------------------------------------
$mdaEndpoint = "https://tenant.datacenter.portal.cloudappsecurity.com"
$createEndpoint = $mdaEndpoint + "/api/v1/subnet/create_rule/"
$listEndpoint = $mdaEndpoint + "/api/v1/subnet/"


function getNamedLocations {
    # Construct URI for token
    $uri = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

    # Construct body for the token
    $body = @{
        client_id     = $clientId
        client_secret = $clientSecret
        scope         = "https://graph.microsoft.com/.default" # You might need to adjust the scope
        grant_type    = "client_credentials"
    }
    # Get token
    $token = Invoke-RestMethod -Method Post -Uri $uri -Body $body -ContentType "application/x-www-form-urlencoded"

    $accessToken = $token.access_token

    # Store auth token into header for future use
$headers = @{
        'Content-Type' = 'application/json'
        ##Accept = 'application/json'
        Authorization = "Bearer $accessToken"
    }
    # Get Entra ID named locations
    $namedLocationsUri = "$resourceGraph/v1.0/identity/conditionalAccess/namedLocations"
  
    $namedLocationsResponse = Invoke-RestMethod -Headers $headers -Uri $namedLocationsUri -Method Get
  
    return $namedLocationsResponse
    
   
 }
    



#---------------------------------------------------------------------------------------
# Get the update endpoint for MDA to update the IP ranges and display name
#---------------------------------------------------------------------------------------
function getUpdateEndpoint {
    param ([string]$subnetId)
    $updateEndpoint = $mdaEndpoint + "/api/v1/subnet/" + $subnetId + "/update_rule/"
    return $updateEndpoint
}

#---------------------------------------------------------------------------------------
#normalize the IP ranges so the input can be converted to what's returned from graph to MDA endpoint
#---------------------------------------------------------------------------------------
function normalize_IP_Ranges {
    param([string]$ipRanges)
    if ($ipRanges.Contains(' ')) {
        $ranges = $ipRanges.Replace(' ', '","')
    }
    else {
        $ranges = $ipRanges
    }
    return $ranges
}

#---------------------------------------------------------------------------------------
#Get the existing ranges from MDA to compare against the named locations. This function
# doesn't implement paging. If you have more than 100 entries you'll need to implement pagin
# error handling is also not implemented in the event the API call is throttled for fails for some 
# other reason
#---------------------------------------------------------------------------------------
function getCloudAppRanges {
    #construct the header for the API call filters for corporate and VPN
    #category 1 = corporate, 4 = VPN
    $listBody = 
    '{
        "skip": "0",
        "limit": "100",
        "filters":{"category":{"eq":[1,4]}}
    }'

    #make the API call to get the existing ranges
    $list = Invoke-RestMethod -uri $listEndpoint -Headers $mdaHeader -Method POST -Body $listBody

    #add the value to an array so it can be accessed later with a couple of indexes
    $existingList = new-object System.Collections.ArrayList
    foreach ($item in $list.data) {
        $existingList.add(@{name=$item.name;id=$item._id})
    }
    return $existingList
}

#---------------------------------------------------------------------------------------
#Create a new range in MDA, by default this will all be corporate ranges.  If you want to create
# VPN ranges you'll need to change the category to 4
#---------------------------------------------------------------------------------------
function createNewRange {
    param([string]$displayName, [string]$ipRange)
    $type = 1 
    $tags = "Entra ID Named Location"
    $createBody = 
    '{
    "name": "'+ $location.displayName + '",
    "category": "'+ $type + '",
    "organization": "'+ $organization + '",
    "subnets": ["'+ $ipRange + '"],
    "tags": ["'+ $tags + '"]
}'
    write-host $createbody
    $create = Invoke-RestMethod  -Uri $createEndpoint -Headers $mdaHeader -Method POST -body $createBody -Verbose
    return $create
}

#---------------------------------------------------------------------------------------
# update an existing range in MDA.  This will update the IP ranges and the display name in the event
# the named location ranges have changed with new items or removed items.  This also adds based on
# corporate ranges, if you want to add VPN ranges you'll need to change the category to 4.
# no error handling is implemented in the event the API call is throttled or fails for some other reason
#---------------------------------------------------------------------------------------
function updateRange{
    param([string]$displayName,[string]$ipRange,[string]$subnetId)
    write-host $subnetId
    $type = 1 
    $tags = "Named_Location_Sync"
    $updateBody = 
    '{
    "tags": ["'+ $subnetId + '"],
    "category": "'+ $type + '",
    "organization": "'+ $organization + '",
    "subnets": ["'+ $ipRange + '"],
    "tags": ["'+ $tags + '"],
    "_id":"'+ $subnetId + '",
    "name":"'+ $displayName + '"
    }'
    write-host $updateBody
    $endpoint = getUpdateEndpoint -subnetId $subnetId
    write-host $endpoint
    $update = Invoke-RestMethod  -Uri $endpoint -Headers $mdaHeader -Method POST -body $updateBody -Verbose
    return $update
}
#---------------------------------------------------------------
#main body script body
#---------------------------------------------------------------
$namedLocations = getNamedLocations
$mdaRanges = getCloudAppRanges


#---------------------------------------------------------------
#loop through the named locations and compare against the existing ranges in MDA.
# check to see if the range already exists, if it does update it, if not create it.
# also check to see if the named location is trusted, if it's not trusted it won't be added.
# It also must be a named location based on IP ranges rather than a country or region
#---------------------------------------------------------------
foreach ($location in $namedLocations.value) {
    if ($location.'@odata.type' -eq '#microsoft.graph.ipNamedLocation' -and $location.isTrusted -eq $true) {
        write-host $location.displayName
        $ipRange = normalize_IP_Ranges -ipRanges $location.ipRanges.cidrAddress
        if ($mdaRanges.name.Contains($location.displayName)) {
            $subnetId = $mdaRanges | where-object {$_.name -eq $location.displayName} 
            write-host $subnetId.id
            updateRange -displayName $location.displayName -ipRange $ipRange -subnetId $subnetId.id
        }
        else 
        {
          createNewRange -displayName $location.displayName -ipRange $ipRange
        }
    }
}
