#
# Adapted from https://github.com/Azure-Samples/MyDriving
#

# create resource group
Param(
   [string] [Parameter(Mandatory=$true)] $resourceGroupName,
   [string] [Parameter(Mandatory=$true)] $location,
   [string] [Parameter(Mandatory=$false)] $applicationName = 'AutomationAdApp',
   [string] [Parameter(Mandatory=$false)] $inputDataContainerName = 'input-data',
   [string] [Parameter(Mandatory=$false)] $outputDataContainerName = 'misc',
   [string] [Parameter(Mandatory=$false)] $usqlDataContainerName = 'misc',
   [string] [Parameter(Mandatory=$false)] $miscContainerName = 'misc'
)

$dbSchemaDB = "..\src\SqlDatabase\CustomerAndAddressTables.sql" 

Write-Host ""
Write-Host "**************************************************************************************************"
Write-Host "* Create resource group..."
Write-Host "**************************************************************************************************"

Get-AzureRmResourceGroup -Name $resourceGroupName -ev resourceGroupNotFound -ea 0

if ($resourceGroupNotFound)
{
    new-azurermresourcegroup -Name $resourceGroupName -Location $location
	Write-Host("Resource group '$resourceGroupName' created")
}
else
{
	Write-Host("Resource group '$resourceGroupName' already exists")
}

Write-Host ""
Write-Host "**************************************************************************************************"
Write-Host "* Create Azure AD application..."
Write-Host "**************************************************************************************************"

# define Azure AD application credentials
$applicationUri = "http://" + $applicationName
$KeyValue = [guid]::NewGuid()
$creds = New-Object Microsoft.Azure.Commands.Resources.Models.ActiveDirectory.PSADPasswordCredential
$startDate = Get-Date
$creds.StartDate = $startDate
$creds.EndDate = $startDate.AddYears(1)
$creds.KeyId = [guid]::NewGuid()
$creds.Password = $KeyValue

write-host $applicationUri

# create Azure AD application (delete it first if it already exists)
$app = get-azurermadapplication -IdentifierUri "http://$applicationName"
if ($app){
    remove-azurermadapplication -ObjectId $app.ObjectId -Force
}

$app = New-AzureRmADApplication –DisplayName $applicationName `
-IdentifierUris ("http://" + $applicationName) `
-PasswordCredentials $creds

# create service principal
New-AzureRmADServicePrincipal -ApplicationId $app.ApplicationId
$princ = Get-AzureRmADServicePrincipal -SearchString $applicationName

Write-Host "sleep for 30 seconds to allow service principal time to get created"
Start-Sleep -s 30

# assign Contributor role at subscription level
$sub = get-azurermcontext | select-object Subscription
$scope = "/subscriptions/" + $sub.Subscription
New-AzureRmRoleAssignment -RoleDefinitionName Contributor -ObjectId $princ.Id -scope $scope

$displayName = $app.DisplayName
Write-Output "The application '$displayName' with secret '$keyValue' has been created/re-created."

Write-Host ""
Write-Host "**************************************************************************************************"
Write-Host "* Deploy ARM template..."
Write-Host "**************************************************************************************************"

$deployment = New-AzureRmResourceGroupDeployment -Name $resourceGroupName -ResourceGroupName $resourceGroupName `
    -Mode Incremental -Verbose `
    -TemplateFile "azuredeploy.json" `
    -TemplateParameterFile "azuredeploy.parameters.json" `
	-clientId $app.ApplicationId `
	-clientSecret $keyValue

Write-Host "Template deployment complete"

Write-Host ""
Write-Host "**************************************************************************************************"
Write-Host "* Create storage account containers..."
Write-Host "**************************************************************************************************"

Set-AzureRmCurrentStorageAccount -ResourceGroupName $resourceGroupName -Name $deployment.Outputs.inputStorageAccountName.Value
Get-AzureStorageContainer -Name $inputDataContainerName -EV inputDataContainerNotFound -EA 0

if ($inputDataContainerNotFound)
{
    New-AzureStorageContainer -Name $inputDataContainerName
	Write-Host("Container $inputDataContainerName created")
}
else
{
    write-host("$inputDataContainerName container already exists")
}

Get-AzureStorageContainer -Name $outputDataContainerName -EV outputDataContainerNotFound -EA 0

if ($outputDataContainerNotFound)
{
    New-AzureStorageContainer -Name $outputDataContainerName
	Write-Host("Container $outputDataContainerName created")
}
else
{
    write-host("$outputDataContainerName Container already exists")
}

Get-AzureStorageContainer -Name $usqlDataContainerName -EV usqlDataContainerNotFound -EA 0

if ($usqlDataContainerNotFound)
{
    New-AzureStorageContainer -Name $usqlDataContainerName
	Write-Host("Container $usqlDataContainerName created")
}
else
{
    write-host("$usqlDataContainerName container already exists")
}

Get-AzureStorageContainer -Name $miscContainerName -EV miscContainerNotFound -EA 0

if ($miscContainerNotFound)
{
    New-AzureStorageContainer -Name $miscContainerName
	Write-Host("Container $miscContainerName created")
}
else
{
	Write-Host("$miscContainerName container already exists")
}


Write-Host ""
Write-Host "**************************************************************************************************"
Write-Host "* Initialize target database tables..."
Write-Host "**************************************************************************************************"

$databaseName = $deployment.Outputs.sqlDBName.Value
Write-Host "Initializing the '$databaseName' database..."
.\setupDb.ps1 -ServerName $deployment.Outputs.sqlServerFullyQualifiedDomainName.Value `
						-AdminLogin $deployment.Outputs.sqlServerAdminLogin.Value `
						-AdminPassword $deployment.Outputs.sqlServerAdminPassword.Value `
						-DatabaseName $deployment.Outputs.sqlDBName.Value `
						-ScriptPath $dbSchemaDB
Write-Host "'$databaseName' initialized"

Write-Host ""
Write-Host "**************************************************************************************************"
Write-Host "* Deploy Azure Function..."
Write-Host "**************************************************************************************************"

Compress-Archive -Path ..\src\CustomerDataBlobTriggerFunction -DestinationPath ..\src\CustomerDataBlobTriggerFunction -Update
Write-Host "Source files compressed"

Write-Host "resource group = " $resourceGroupName
$pathToZipFile = "..\src\CustomerDataBlobTriggerFunction.zip"
$functionAppName = $deployment.Outputs.functionAppName.Value
$creds = Invoke-AzureRmResourceAction -ResourceGroupName $resourceGroupName -ResourceType Microsoft.Web/sites/config `
            -ResourceName $functionAppName/publishingcredentials -Action list -ApiVersion 2015-08-01 -Force

$username = $creds.Properties.PublishingUserName
$password = $creds.Properties.PublishingPassword
Write-Host "Azure function scm credentials retrieved (username'"$username"')"

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password)))
$userAgent = "powershell/1.0"

$apiUrl = "https://" + $functionAppName + ".scm.azurewebsites.net/api/zip/site/wwwroot"
Write-Host "Deploying Azure function via Kudu API (url" $apiUrl ")"
invoke-RestMethod -Uri $apiUrl -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Method PUT -infile $pathToZipFile -UserAgent $userAgent

Write-Host "Deployment is now finished."

