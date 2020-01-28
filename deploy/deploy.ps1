param(
    $ServicePrincipalApplicationId,
    $ServicePrincipalClientSecret,
    $ResourceGroupName,
    $ResourceGroupLocation
)

Write-Host "Creating resource group $ResourceGroupName in location $ResourceGroupLocation."
az group create -n $ResourceGroupName -l $ResourceGroupLocation

Write-Host "Looking up service principal object ID for application ID $ServicePrincipalApplicationId."
$servicePrincipalObjectId = az ad sp list --filter "appId eq '$ServicePrincipalApplicationId'" --query '[].[objectId]' -o tsv
Write-Host "Found service principal object ID $servicePrincipalObjectId."

Write-Host 'Starting deployment of ARM template.'
$templateFilePath = Join-Path $PSScriptRoot 'template.json'
$deploymentOutputsJson = az group deployment create -j -g $ResourceGroupName --template-file $templateFilePath --parameters servicePrincipalApplicationId=$ServicePrincipalApplicationId servicePrincipalClientSecret=$ServicePrincipalClientSecret servicePrincipalObjectId=$servicePrincipalObjectId --verbose
$deploymentOutputs = $deploymentOutputsJson | ConvertFrom-Json
$functionAppName = $deploymentOutputs.properties.outputs.functionsAppName.value

# TODO create sample model? - user running this needs to be an admin

$functionAppFolder = Join-Path $PSScriptRoot '..' 'src' 'analysis-services-refresh'
Write-Host "Deploying to Azure Functions app $functionAppName from folder '$functionAppFolder'."
Push-Location $functionAppFolder
func azure functionapp publish $functionAppName
Pop-Location
