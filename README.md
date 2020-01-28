# Automatically refreshing an Analysis Services model

This sample demonstrates how to use an Azure Functions app (written using PowerShell) to trigger an Analyis Services model to refresh every night at 0000 UTC.

## Instructions to run

1. Create a service principal, and create a client secret for it to use. Note the application ID (sometimes also called the client ID) and the client secret.
2. Run the `deploy.ps1` PowerShell script as follows:

```powershell
.\deploy.ps1 -ServicePrincipalApplicationId '<your application/client ID>' -ServicePrincipalClientSecret '<your client secret>' -ResourceGroupName <your resource group name> -ResourceGroupLocation australiaeast -AnalysisServicesDatabaseName adventureworks
```

3. If you are just testing this out, create a sample Analysis Services model. You can use the Azure Portal to create an `adventureworks` model with sample data (although note you will need to add yourself to the 'Analysis Services Admins' list for the server to accept the request).
4. Use the Azure Portal to invoke the function and verify that it triggers the model refresh.

Note that this sample deploys a function app with an app service plan. It does this to allow for a known set of outbound IP addresses to be added to the Analysis Services firewall.

## Known issues

 * Once the refresh is triggered, the function does not wait for it to complete. It may take some time for the operation to be queued and processed.
 * This sample does not use a managed identity for the function app to communicate with Analysis Services. There appears to be a limitation with using managed identities for this purpose currently, so a service principal is used instead.
 * The Analysis Services management cmdlets are currently not supported in the Azure Functions PowerShell integration ([due to an incompatability with .NET Core](https://github.com/PowerShell/PowerShell/issues/7876#issuecomment-578962186)). The sample instead invokes the Analysis Services REST API directly.
 * Because the sample invokes the Analysis Services REST API directly, it needs to obtain an access token to do so. The [MSAL.PS](https://www.powershellgallery.com/packages/MSAL.PS/) open-source PowerShell module is used to obtain this token. Version 4.7.1.2 of the module has been embedded into the repository because the MSAL.PS module appears not to work using the Azure Functions [dependency management for PowerShell](https://docs.microsoft.com/azure/azure-functions/functions-reference-powershell#dependency-management).
 * The service principal is granted owner rights on the Analysis Services server using the Azure RBAC system. [This is required by the Analysis Services service.]https://docs.microsoft.com/azure/analysis-services/analysis-services-addservprinc-admins#add-service-principal-to-server-administrators-role)
