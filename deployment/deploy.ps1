# deploy input storage account

# deploy function(s)
New-AzureRmResourceGroupDeployment -Name [deployment name] -ResourceGroupName [resource-group-name] `
    -Mode Incremental -Verbose `
    -TemplateFile "functions.azuredeploy.json" `
    -TemplateParameterFile "functions.parameters.json"

# deploy sql database