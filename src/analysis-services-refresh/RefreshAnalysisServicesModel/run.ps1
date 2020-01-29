# Input bindings are passed in via param block.
param($Timer)

$databaseName = $env:AnalysisServicesDatabaseName

# Transform the Analysis Services server URI into the resource URI we need to request a token for (see https://docs.microsoft.com/en-us/azure/analysis-services/analysis-services-async-refresh#base-url).
$analysisServicesServerUri = [System.Uri]$env:AnalysisServicesServerUri
$refreshType = 'automatic'
$resourceUri = "https://$($analysisServicesServerUri.Host)/"

# Obtain a token using the function app's managed identity.
Write-Host "Obtaining a token to access the Analysis Services API at $resourceURI using the function app's managed identity."
$tokenAuthURI = $env:MSI_ENDPOINT + "?resource=$resourceURI&api-version=2017-09-01"
$tokenResponse = Invoke-RestMethod -Method Get -Headers @{"Secret"="$env:MSI_SECRET"} -Uri $tokenAuthURI
$accessToken = ConvertTo-SecureString $tokenResponse.access_token -AsPlainText -Force

# Access the Analysis Services API to trigger the refresh.
# We have to do this using the REST API directly instead of Invoke-ProcessASDatabase because Invoke-ProcessASDatabase doesn't work with PowerShell Core (as at version 21.1.18218 of the SqlServer module).
$refreshApiUrl = "https://$($analysisServicesServerUri.Host)/servers/$env:AnalysisServicesServerName/models/$databaseName/refreshes"
$requestBodyObject = @{
    Type = $refreshType
}
$requestBody = $requestBodyObject | ConvertTo-Json -Depth 4
$response = try { Invoke-WebRequest -Uri $refreshApiUrl -Method Post -Body $requestBody -ContentType application/json -Authentication Bearer -Token $accessToken } catch { $_.Exception.Response }

# Log the error header
($response.Headers | Where-Object { $_.Key -eq 'x-ms-xmlaerror-extended' }).Value
