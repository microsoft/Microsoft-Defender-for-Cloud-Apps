# Discovered Apps API via Microsoft Graph

### Contacts
| Name | Role          |
| --------------- | -- |
| Itai Cohen      | PM |
| Douglas Santos  | PM |
| Keith Fleming   | PM |


### Background:
This API will allow customers to GET all the data available in Discovered Apps page via an API; including filters, ‘select’ (https://learn.microsoft.com/en-us/graph/query-parameters?tabs=http#odata-system-query-options) and more. 

### Basic Features Functionality:
1.	Run the following GET command to get an high-level summary of the Discovery streams enabled on your tenant: 
https://graph.microsoft.com/beta/security/dataDiscovery/cloudAppDiscovery/uploadedStreams
  ![image](https://github.com/microsoft/Microsoft-Defender-for-Cloud-Apps/assets/116388443/2ad17c97-c9f4-4736-9f2c-7827bd61db10)
  
2. Copy the relevant 'streamID': 
  
  ![image](https://github.com/microsoft/Microsoft-Defender-for-Cloud-Apps/assets/116388443/3f944016-5e08-49cc-8495-737f5aa39601)

3.	Run the following GET command using the 'streamID':
  
  ```HTML 
  GET https://graph.microsoft.com/beta/security/dataDiscovery/cloudAppDiscovery/uploadedStreams/<streamId>/aggregatedAppsDetails(period=duration'P90D')
  ```
  
### Permissions Requirements: 
| Permissions	| Type	| Entities/APIs Covered |
| --- | --- | --- |
| CloudApp-Discovery.Read.All	| Read Discovered Apps data.	| Allows the app to read all available data pertaining to Discovered Cloud Apps from Microsoft Defender for Cloud Apps.|
  
## Top Use Cases and Examples
### See all the apps discovered this week: 

#### Code or REST operation example:
```HTML 
GET  https://graph.microsoft.com/beta/security/dataDiscovery/cloudAppDiscovery/uploadedStreams/<streamId>/aggregatedAppsDetails (period=duration 'P7D') 
```

Expected response:
```JSON
Response:{
  "value": [
    {
      "@odata.type": "#microsoft.security.DiscoveredCloudAppDetail",
      "id": 13203423542,
      "displayName": "Microsoft Exchange Online",
      "riskScore": 10,
      "totalNetworkTrafficInBytes": 243453345,
      "uploadNetworkTrafficInBytes": 934564,
      "downloadNetworkTraficInBytes": 242518781,
      "transactionCount": 52,
      "userCount": 49,
      "ipAddressCount": 33,
      "lastSeenDateTime": "2022-08-14",
      "tags": ["Sanctioned"],
      "category": "Marketing",
      "domains": ["*.outlook.office.com", "*.outlook.office365.com", "*.mail.onmicrosoft.com", "*.o365weve.com",...]      
    },
    { "id": 845938765493, "displayName": "Dropbox", "riskScore": 9 }
  ]
}
```
#### Using $select, and $filter see only the app name of all the apps discovered in the last 30 days with risk score lower or equal to 4:
```HTML 
GET https://graph.microsoft.com/beta/security/dataDiscovery/cloudAppDiscovery/uploadedStreams/<streamId>/aggregatedAppsDetails (period=duration'P30D')?$filter=riskRating  le 4 &$select=displayName Response:
```

Expected response:
```JSON
  Response:{
    "value": [
      {"displayName": "ShareASale"},
      {"displayName": "PubNub"}
    ]
}
```
#### Get the userIdentifier of all users (or devices or IPaddresses) using a specific app

```HTML 
GET  https://graph.microsoft.com/beta/security/dataDiscovery/cloudAppDiscovery/uploadedStreams/<streamId>/aggregatedAppsDetails (period=duration'P30D')/ <id>/users 
```

Expected response:

```JSON
Response:{
  "value": [
    { "userIdentifier": "Broderick@fabrikan.com"}, {" userIdentifier": "temp@fabrikan.com"}
  ]
}
```
*same for a collection of entities called Collection(discoveredCloudAppsipAddress) with 1 property called "ipAddress"

*same for a collection of entities called Collection(discoveredCloudAppsDevice) with 1 property called "name". Note applicable only if the stream is Endpoint Stream.

#### Using filters, see all apps which are categorized as Marketing and are not Hippa or GDPR compliant

```HTML
GET  https://graph.microsoft.com/beta/security/dataDiscovery/cloudAppDiscovery/uploadedStreams/<MDEstreamId>/aggregatedAppsDetails (period=duration 'P30D')?$filter= (appInfo/Hippa eq 'false' or appInfo/GDPR eq 'false') and category eq 'Marketing' 
```

Expected response:

```JSON
Response:
{
  "value": [
    {
      "@odata.type": "#microsoft.security.endpointDiscoveredCloudAppDetail",
      "id": 13203423542,
      "displayName": "Microsoft Exchange Online",
      "riskScore": 10,
      "totalNetworkTrafficInBytes": 243453345,
      "uploadNetworkTrafficInBytes": 934564,
      "downloadNetworkTraficInBytes": 242518781,
      "transactionCount": 52,
      "userCount": 49,
      "deviceCount": 37,
      "ipAddressCount": 33,
      "lastSeenDateTime": "2022-08-14",
      "tags": ["Sanctioned"],
      "category": "Marketing",
      "domains": ["*.outlook.office.com", "*.outlook.office365.com", "*.mail.onmicrosoft.com", "*.o365weve.com",...]      

    },
    { "id": 845938765493, "displayName": "Dropbox", "riskScore": 9 }
  ]
}
```

### Best practices of how to use Graph API



 
  
