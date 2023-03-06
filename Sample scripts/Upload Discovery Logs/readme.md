# Automate uploading logs to Defender for Cloud Apps Cloud Discovery

This sample guide/scripts will help you automate uploading firewall logs to Defender for Cloud Apps using API.
This helps eliminate the need to deploy a log collector, and makes it more flexible to deploy and maintain.

In addition, this guide is using the Microsoft Graph API, instead of the legacy Defender for Cloud Apps APIs, which is in a path to being deprecated in the future.

Note from Managing API tokens - Microsoft Defender for Cloud Apps | Microsoft Learn



This guide is based on the following documentation, but some customization is needed as described below to use it for Shadow IT Discovery purposes .


  ----------------- -----------------------------------------------------------------------------------------------
  Intro:           [[REST API - Microsoft Defender for Cloud Apps]](https://learn.microsoft.com/en-us/defender-cloud-apps/api-introduction)
 
  Authentication   [[Managing API tokens - Microsoft Defender for Cloud Apps]](https://learn.microsoft.com/en-us/defender-cloud-apps/api-authentication)
 
  Discovery API    [[Defender for Cloud Apps Cloud Discovery API - Microsoft Defender for Cloud Apps]](https://learn.microsoft.com/en-us/defender-cloud-apps/api-discovery)
  ---------------- ------------------------------------------------------------------------------------------------

Here are the main tasks:

1.  Create an Azure AD App
2.  Give the App permissions over Defender for Cloud Apps APIs
3.  Document key elements from the App, such as App ID, Tenant ID and App Secret
4.  Document the Defender for Cloud Apps API URL
5.  Create a new Data Source in Defender for Cloud Apps to receive the logs
6.  Configure the PowerShell scripts with the data collected above and test it.
7.  Schedule the script to run according to your preferences.

For detailed steps, please download the "Discovery Sample Scrips.zip file and read the PDF file.

Contributors:
[[Douglas Santos]](https://github.com/doug-msft)
