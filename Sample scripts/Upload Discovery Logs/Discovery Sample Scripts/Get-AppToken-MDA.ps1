<################################################################################################################################################
   Pre-requisites
   1. Make sure to configure the Get-AppToken-MDA.ps1 script with the necessary variables, withouth it you won't be able to obtain the token
   2. (line 13) Make sure the $TenatID is set with the Azure AD tenant ID where the App was created
   3. (line 14) Make sure the $appId name matches with the App you created in Azure AD to automate the task
   4. (line 15) Make sure the $appSecret matches with the secret value from the App you created 
   
   Note: This script is provided as sample, so you can customize it to your own needs.
         
################################################################################################################################################>
# This script acquires the App Context Token and stores it in the variable $token for later use in the script.

$tenantId = '<Your Tenant ID>' ### Paste your tenant ID here
$appId = '<Your app ID>' ### Paste your Application ID here
$appSecret = '<Your App secret key value>' ### Paste your Application key here

$resourceAppIdUri = '05a65629-4c1b-48c1-a78b-804c4abdd4af' #this represents the MDA APP 
$oAuthUri = "https://login.microsoftonline.com/$TenantId/oauth2/token"
$authBody = [Ordered] @{
    resource = "$resourceAppIdUri"
    client_id = "$appId"
    client_secret = "$appSecret"
    grant_type = 'client_credentials'
}
$authResponse = Invoke-RestMethod -Method Post -Uri $oAuthUri -Body $authBody -ErrorAction Stop
$token = $authResponse.access_token
#Save token to a file
Out-File -FilePath "./MDADiscovery-token.txt" -InputObject $token
return $token


