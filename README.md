# azure-data-processing
Import data using blob storage, Azure functions, Azure Data Lake Analytics (and more to come at a later time.)

### Deployment Instructions
1. Clone or download repository
2. Open PowerShell and run as administrator
3. Within PowerShell, Navigate to the **Deployment** cloned/downloaded source code
4. Login to your Azure subscription.
* If you have multiple subscriptions, be sure to set the context to the desired subscription.
5. Execute deploy.ps1 as shown below.

```powershell
Login-AzureRmAccount
set-azurermcontext -SubscriptionId [subscription Id] -TenantId [tenant Id] 

.\deploy.ps1 -resourceGroupName [resource group name] -location [location/region name]
```

The deployment script performs the following:
1. Creates the specified resource group
2. Creates an Azure AD application and a corresponding service principal. For convenience, the service principal is granted Contributor permission at the subscription level. Both are deleted and re-created each time the script is executed.
3. Deploys an ARM template (.\Deployment\azuredeploy.json, .\Deployment\azuredeploy.parameters.json)
4. Defines containers within the input data blob storage
5. Creates SQL Database tables (currently not used)
6. Deploys an Azure Function (using the Kudu API)

### ARM Template Details

To be continued...