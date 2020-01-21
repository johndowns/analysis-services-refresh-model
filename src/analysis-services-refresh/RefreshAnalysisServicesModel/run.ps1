# Input bindings are passed in via param block.
param($Timer)

# Transform the Analysis Services server URI into the resource URI we need to request a token for (see https://docs.microsoft.com/en-us/azure/analysis-services/analysis-services-async-refresh#base-url).
$analysisServicesServerUri = [System.Uri]$env:AnalysisServicesServerUri
$resourceURI = "https://$($analysisServicesServerUri.Host)/"

# Obtain a token using the function app's managed identity.
Write-Host "Obtaining a token to access the Analysis Services API at $resourceURI using the function app's managed identity."
$tokenAuthURI = $env:MSI_ENDPOINT + "?resource=$resourceURI&api-version=2017-09-01"
$tokenResponse = Invoke-RestMethod -Method Get -Headers @{"Secret"="$env:MSI_SECRET"} -Uri $tokenAuthURI
$accessToken = ConvertTo-SecureString $tokenResponse.access_token -AsPlainText -Force

# Access the Analysis Services API to trigger the refresh.
# We have to do this using the REST API directly instead of Invoke-ProcessASDatabase because Invoke-ProcessASDatabase doesn't support managed identities yet.
$databaseName = 'adventureworks' # TODO
$refreshType = 'automatic'
$refreshApiUrl = $resourceUri + "servers/$env:AnalysisServicesServerName/models/$databaseName/refreshes"
$requestBodyObject = @{
    Type = $refreshType
}
$requestBody = $requestBodyObject | ConvertTo-Json -Depth 4
Invoke-RestMethod -Uri $refreshApiUrl -Method Post -Body $requestBody -ContentType application/json -Authentication Bearer -Token $accessToken
