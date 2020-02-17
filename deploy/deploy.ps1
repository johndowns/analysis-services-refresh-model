param(
    $ResourceGroupName,
    $ResourceGroupLocation,
    $AnalysisServicesDatabaseName
)

Write-Host "Creating resource group $ResourceGroupName in location $ResourceGroupLocation."
az group create -n $ResourceGroupName -l $ResourceGroupLocation

Write-Host 'Starting first deployment of ARM template.'
$templateFilePath = Join-Path $PSScriptRoot 'template.json'
$deploymentOutputsJson = az group deployment create -j -g $ResourceGroupName --template-file $templateFilePath --parameters analysisServicesDatabaseName=$AnalysisServicesDatabaseName
$deploymentOutputs = $deploymentOutputsJson | ConvertFrom-Json
$functionsAppIdentityObjectId = $deploymentOutputs.properties.outputs.functionsAppIdentityObjectId.value

# Get the app ID of the function app's managed identity, for Analysis Services to register as an administrator
$functionsAppIdentityAppId = az ad sp show --id $functionsAppIdentityObjectId --query appId -o tsv

Write-Host 'Re-deploying ARM template with managed identity application ID.'
$deploymentOutputsJson = az group deployment create -j -g $ResourceGroupName --template-file $templateFilePath --parameters analysisServicesDatabaseName=$AnalysisServicesDatabaseName functionsAppIdentityAppId=$functionsAppIdentityAppId
$deploymentOutputs = $deploymentOutputsJson | ConvertFrom-Json
$functionAppName = $deploymentOutputs.properties.outputs.functionsAppName.value

Write-Host "Deploying to Azure Functions app $functionAppName."
$functionAppFolder = Join-Path $PSScriptRoot '..' 'src' 'analysis-services-refresh'
Push-Location $functionAppFolder
func azure functionapp publish $functionAppName
Pop-Location
