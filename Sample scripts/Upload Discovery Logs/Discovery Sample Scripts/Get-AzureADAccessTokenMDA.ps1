<################################################################################################################################################
  
   Note: This script is provided as sample, so you can customize it to your own needs.
         
################################################################################################################################################>
<#
.SYNOPSIS
    Retrieves an Azure AD access token using client credentials.
.DESCRIPTION
    This function retrieves an Azure AD access token using client credentials. The access token is used to authenticate requests to the Microsoft Graph API.
.PARAMETER ClientId
    The client ID of the Azure AD application.
.PARAMETER TenantId
    The tenant ID of the Azure AD directory.
.PARAMETER ClientSecret
    The client secret of the Azure AD application.
.EXAMPLE
    PS C:\> Get-AzureADAccessToken -ClientId "12345678-1234-1234-1234-1234567890ab" -TenantId "12345678-1234-1234-1234-1234567890ab" -ClientSecret "MyClientSecret"
    Retrieves an Azure AD access token using the specified client ID, tenant ID, and client secret.
#>

$global:AzureADAccessTokenMDA = $null
$global:AzureADAccessTokenMDAExpiration = [DateTime]::MinValue

function Get-AzureADAccessTokenMDA {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ClientId,
        [Parameter(Mandatory = $true)]
        [string]$TenantId,
        [Parameter(Mandatory = $true)]
        [string]$ClientSecret
    )

    Begin {
        $ErrorActionPreference = 'Stop'
    }

    Process {
        try {
            $resourceAppIdUri = '05a65629-4c1b-48c1-a78b-804c4abdd4af' #this represents the MDA APP 
            $body = [Ordered] @{
                'resource'      = $resourceAppIdUri
                'client_id'     = $ClientId
                'client_secret' = $ClientSecret
                'grant_type'    = 'client_credentials'
                #'resource'      = 'https://graph.microsoft.com'
            }
            $response = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantId/oauth2/token" -Method Post -Body $body
            $global:AzureADAccessTokenMDA = $response.access_token
            $global:AzureADAccessTokenMDAExpiration = (Get-Date).AddSeconds($response.expires_in)
            write-host "Access token expires at $($global:AzureADAccessTokenMDAExpiration)"
            write-host "------------------------------------------------------------------------"
        }
        catch {
            Write-Error $_.Exception.Message
        }
    }
}

