# Input bindings are passed in via param block.
param($Timer)

$databaseName = $env:AnalysisServicesDatabaseName

# Transform the Analysis Services server URI into the resource URI we need to request a token for (see https://docs.microsoft.com/en-us/azure/analysis-services/analysis-services-async-refresh#base-url).
$analysisServicesServerUri = [System.Uri]$env:AnalysisServicesServerUri
$refreshType = 'automatic'
$resourceUri = "https://$($analysisServicesServerUri.Host)/.default" # The convention with Azure AD is to use this format as a scope instead of a resource URI.

# Obtain a token for the service principal. (Currently Azure Analysis Services does not appear to support managed identities calling its REST API.)
$clientSecret = ConvertTo-SecureString $env:ServicePrincipalClientSecret -AsPlainText -Force
$tokenResponse = Get-MsalToken -ClientId $env:ServicePrincipalApplicationId -ClientSecret $clientSecret -TenantId $env:ServicePrincipalTenantId -Scopes $resourceUri
$accessToken = ConvertTo-SecureString $tokenResponse.AccessToken -AsPlainText -Force

# Access the Analysis Services API to trigger the refresh.
# We have to do this using the REST API directly instead of Invoke-ProcessASDatabase because Invoke-ProcessASDatabase doesn't work with PowerShell Core (as at version 21.1.18218 of the SqlServer module).
$refreshApiUrl = "https://$($analysisServicesServerUri.Host)/servers/$env:AnalysisServicesServerName/models/$databaseName/refreshes"
$requestBodyObject = @{
    Type = $refreshType
}
$requestBody = $requestBodyObject | ConvertTo-Json -Depth 4
$response = Invoke-RestMethod -Uri $refreshApiUrl -Method Post -Body $requestBody -ContentType application/json -Authentication Bearer -Token $accessToken
Write-Host "Successfully queued refresh operation '$($response.operationId)'."
