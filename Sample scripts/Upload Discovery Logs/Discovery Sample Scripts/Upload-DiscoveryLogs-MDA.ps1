<################################################################################################################################################
   Pre-requisites
   1. Make sure to configure the Get-AppToken-MDA.ps1 script with the necessary variables, withouth it you won't be able to obtain the token
   2. (line 15) Make sure the $TenantURL is set to the tenant you want to send the logs to
   3. (line 16) Make sure that the $LogSource name matches what kind of logs you are uploading
   4. (line 17) Make sure the $DataSourceName matches with the name of the Data Source created in Defender for Cloud Apps
   5. (line 18) Replace <Folder> with the path to the "Discovery" folder
   Note: This script is configured to output to host each step to help with testing before automating the execution.
         This script is provided as sample, so you can customize it to your own needs.
################################################################################################################################################>

<################################################################################################################################################
   Setting variables
################################################################################################################################################>
$TenantURL = "<Your Tenant URL>" # you can find this at https://security.microsoft.com/cloudapps/settings?tabid=about
$LogSource = "PALO_ALTO" #Change to your log source (Refernce https://learn.microsoft.com/en-us/defender-cloud-apps/api-discovery-initiate#request-url-parameters)
$DataSourceName = "PaloAltoDemo" #Create a Data Source in "Automatic log upload" in https://security.microsoft.com/cloudapps/settings?tabid=discovery-autoUpload&innertab=dataSources
$sourceScriptFolder = "<Ex:C:\Scripts\Discover>" #This is the path to the Discover folder where the PowerShell scripts are
$sourceLogFolder = $sourceScriptFolder+"\NewLogs" #This is the folder where you copy the firewall logs to
$destinationLogFolder = $sourceScriptFolder+"\ArchivedLogs" #This is the folder where you want to move the processed logs to

<################################################################################################################################################
   function GetUploadURL
   This function will connect to your tenant to obtain a link to upload the log files.
################################################################################################################################################>

function GetUploadURL {
    
    param (
        $token, $fileName
    )

    Write-Host "+ Getting upload URL..." 

    #Calling the API 
    $APIEndpoint = '/api/v1/discovery/upload_url/'
    
    $GetUploadURL_Uri = $TenantURL+$APIEndpoint+"?filename=$fileName&source=$LogSource"
    Write-Host "| - Upload URL API Uri: " $GetUploadURL_Uri
    Write-Host "| - For fileName:" $fileName

    <# Construct Graph API call #>
    $Headers = @{
        "Authorization" = "Bearer $($token)"
        "Content-type"  = "application/json"
    }

    try {

        $MDAGetUploadURL = (Invoke-RestMethod -Headers $Headers -Uri $GetUploadURL_Uri -Method GET).url
        if($MDAGetUploadURL) 
        {
            Write-Host "| - Upload URL obtained succesfully: "
            Write-Host "| - Upload:"$MDAGetUploadURL
            return $MDAGetUploadURL
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
        Write-Error "Request to $GetUploadURL_Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        write-host
        break
    }

}


<################################################################################################################################################
   Function InitiateUpload

   Uploading the file to Defender for Cloud Apps 
   You can upload individual files of up to 5 GB. 
   If you need to upload larger files, break the 
   Cloud Discovery data into multiple chunks.
################################################################################################################################################>

function InitiateUpload {
    
    param (
        $UploadURL , $file
    )
    
    Write-Host "+ Uploadding log file..." 
    Write-Host "| - File name:" $file


    <# Construct Graph API call #>
    $Headers = @{
            "x-ms-blob-type" = "BlockBlob"
        }

        try {
            $UploadapiUri = $UploadURL
            $Uploadresponse = Invoke-RestMethod -Headers $Headers -Uri $UploadapiUri -InFile $file -Method PUT
            Write-Host "| - Log file uploaded successufly" 
            Write-Host "| - Uploadrepsonse:" $Uploadresponse
        } 
        catch {
            $ex = $_.Exception
            $errorResponse = $ex.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorResponse)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd();
            Write-Host "Response content:`n$responseBody" -f Red
            Write-Error "Request to $UploadapiUri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
            write-host
            break
        }
}

<################################################################################################################################################
  Finilizing the upload 
################################################################################################################################################>

function CompleteUpload {

    param(
        $token,$UploadURL,$TenantURL,$DataSourceName
    )
    Write-Host "+ Finalizing upload..." 
    Write-Host "| - Tenant URL:" $TenantURL
    Write-Host "| - MDA Source:" $DataSourceName
    
    <# Construct Graph API call #>
    $Headers = @{
            "Authorization" = "Bearer $($token)";
            "Content-type"  = "application/json"
    }

    $body = @{
        uploadUrl = $UploadURL;
        inputStreamName = $DataSourceName 
    }

    $APIEndpoint2 = "/api/v1/discovery/done_upload/"
    $FinalizeapiUri = $TenantURL+$APIEndpoint2
    write-host "| - Finilize API Uri:" $FinalizeapiUri    
   
        try {
            
            $FinalizeresponseStatus = Invoke-RestMethod -Headers $Headers -Uri $FinalizeapiUri -Body ($body | ConvertTo-Json) -Method POST
            if($FinalizeresponseStatus) 
            {
                Write-Host "| - Finalized sucessufly" 
                write-host "| - Upload status: " $FinalizeresponseStatus.success
                write-host "| - Input Stream ID: " $FinalizeresponseStatus.inputStreamId
                return $FinalizeresponseStatus
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
            Write-Host "Finalize upload error! Response content:`n$responseBody" -f Red
            Write-Error "Request to $FinalizeapiUri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
            write-host
            break
        }
}


if (Get-ChildItem $sourceLogFolder)
{
$LogFilesCount = (Get-ChildItem $sourceLogFolder).Count
Write-Host "Found" $LogFilesCount "log files" -BackgroundColor White -ForegroundColor Black
Write-Host "Beginning upload sequence..." -BackgroundColor White -ForegroundColor Black

#Testing if Get-AppToken-MDA.ps1 exists and obtaining a new token
if (Test-Path "$sourceScriptFolder\Get-AppToken-MDA.ps1"){
        Write-Host "Powershell file found, running it to get the access token"
        $token = .$sourceScriptFolder/Get-AppToken-MDA.ps1
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

#Initiate loop to process each log file
Get-ChildItem $sourceLogFolder | ForEach-Object {
   
    $file = $_.FullName
    $fileName = $_.Name
    Write-Host "Processing file:" $fileName -BackgroundColor White -ForegroundColor Black

     #Checking file size
    $fileSize = $_.Length
    if ($fileSize -gt 5GB) {
        Write-Host "File size is greater than 5 GB, please chose files in smaller chunks" -f Red
        Write-Host "Skipping file:" $file
    }else{

        # Get upload URL
        $UploadURL = GetUploadURL $token $fileName

        # Initiate Upload
        $UploadStatus = InitiateUpload $UploadURL $file

        # Complete Upload
        $CompletionStatus = CompleteUpload $token $UploadURL $TenantURL $DataSourceName 
    
        # Move the processed file to the destination folder
        Move-Item $file -Destination $destinationLogFolder
    }
}


}else{
Write-Host "No logs found. Skipping this cycle" -ForegroundColor Red
}
