New-AzureRmResourceGroupDeployment -Name [deployment name] -ResourceGroupName [resource-group-name] `
    -Mode Incremental -Verbose `
    -TemplateFile "azuredeploy.json" `
    -TemplateParameterFile "azuredeploy.parameters.json"