# create resource group
Param(
   [string] [Parameter(Mandatory=$true)] $resourceGroupName,
   [string] [Parameter(Mandatory=$true)] $location,
   [string] [Parameter(Mandatory=$false)] $inputDataContainerName = 'input-data',
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
Write-Host "* Deploy ARM template..."
Write-Host "**************************************************************************************************"

$deployment = New-AzureRmResourceGroupDeployment -Name $resourceGroupName -ResourceGroupName $resourceGroupName `
    -Mode Incremental -Verbose `
    -TemplateFile "azuredeploy.json" `
    -TemplateParameterFile "azuredeploy.parameters.json"

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
	Write-Host("Container '$inputDataContainerName' created")
}
else
{
    write-host("Container already exists")
	Write-Host("Container '$inputDataContainerName' already exists")
}

Get-AzureStorageContainer -Name $miscContainerName -EV miscContainerNotFound -EA 0

if ($miscContainerNotFound)
{
    New-AzureStorageContainer -Name $miscContainerName
	Write-Host("Container '$miscContainerName' created")
}
else
{
    write-host("Container already exists")
	Write-Host("Container '$miscContainerName' already exists")
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

Compress-Archive -Path ..\src\BlobTriggerFunction -DestinationPath ..\src\BlobTriggerFunction -Update
Write-Host "Source files compressed"

Write-Host "resource group = " $resourceGroupName
$pathToZipFile = "..\src\BlobTriggerFunction.zip"
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

