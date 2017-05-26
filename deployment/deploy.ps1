

# create resource group
$resourceGroupName = 'SwimLanes'
$location = 'west us'
Get-AzureRmResourceGroup -Name $resourceGroupName -ev notPresent -ea 0

if ($notPresent)
{
    new-azurermresourcegroup -Name $resourceGroupName -Location $location
}


# deploy input storage account
New-AzureRmResourceGroupDeployment -Name $resourceGroupName -ResourceGroupName $resourceGroupName `
    -Mode Incremental -Verbose `
    -TemplateFile "storageaccounts.azuredeploy.json" `
    -TemplateParameterFile "storageaccounts.parameters.json"

# deploy function(s)
New-AzureRmResourceGroupDeployment -Name $resourceGroupName -ResourceGroupName $resourceGroupName `
    -Mode Incremental -Verbose `
    -TemplateFile "functions.azuredeploy.json" `
    -TemplateParameterFile "functions.parameters.json"

# deploy sql database
New-AzureRmResourceGroupDeployment -Name $resourceGroupName -ResourceGroupName $resourceGroupName `
    -Mode Incremental -Verbose `
    -TemplateFile "database.azuredeploy.json" `
    -TemplateParameterFile "database.parameters.json"