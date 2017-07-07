#r "System.Runtime"

using System;
using System.Net;
using System.Threading.Tasks;
using Newtonsoft.Json;
using Microsoft.Azure;
using Microsoft.Azure.Common;
using Microsoft.Azure.Management.DataFactories;
using Microsoft.Azure.Management.DataFactories.Models;
using Microsoft.IdentityModel.Clients.ActiveDirectory;
using System.Configuration;

/// <summary>
/// Adapted from http://eatcodelive.com/2016/02/24/starting-an-azure-data-factory-pipeline-from-c-net/
/// </summary>
/// <param name="myBlob"></param>
/// <param name="name"></param>
/// <param name="log"></param>
public static void Run(Stream myBlob, string name, TraceWriter log)
{
    if (!name.ToLower().StartsWith("signal")) {
        // no-op
        log.Info("No work here. Will only be triggered by a file that starts with 'signal'.");
        return;
    }

    var activeDirectoryEndpoint = "https://login.windows.net/";
    var resourceManagerEndpoint = "https://management.azure.com/";
    var windowsManagementUri = "https://management.core.windows.net/";
 
	var subscriptionId = ConfigurationManager.AppSettings["subscriptionId"];
    var activeDirectoryTenantId = ConfigurationManager.AppSettings["tenantId"];
    var clientId = ConfigurationManager.AppSettings["clientId"];
    var clientSecret = ConfigurationManager.AppSettings["clientSecret"];
    var resourceGroupName = ConfigurationManager.AppSettings["resourceGroupName"];
    var dataFactoryName = ConfigurationManager.AppSettings["dataFactoryName"];
    var pipelineName = ConfigurationManager.AppSettings["pipelineName"];
    
    var authenticationContext = new AuthenticationContext(activeDirectoryEndpoint + activeDirectoryTenantId);
    var credential = new ClientCredential(clientId: clientId, clientSecret: clientSecret);
    var result = authenticationContext.AcquireTokenAsync(resource: windowsManagementUri, clientCredential: credential).Result;
     
    if (result == null){
         throw new InvalidOperationException("Failed to obtain the JWT token");
    }

    var token = result.AccessToken;
    var aadTokenCredentials = new TokenCloudCredentials(subscriptionId, token);
    var resourceManagerUri = new Uri(resourceManagerEndpoint);
    var client = new DataFactoryManagementClient(aadTokenCredentials, resourceManagerUri);
    
    try
    {
	    var now = DateTime.UtcNow.AddDays(-1);
        var pl = client.Pipelines.Get(resourceGroupName, dataFactoryName, pipelineName);

        pl.Pipeline.Properties.Start = now;
        pl.Pipeline.Properties.End = now;
        pl.Pipeline.Properties.IsPaused = false;

        client.Pipelines.CreateOrUpdate(resourceGroupName, dataFactoryName, new PipelineCreateOrUpdateParameters()
        {
            Pipeline = pl.Pipeline
        });
        log.Info("Pipeline successfully updated");
    }
    catch (Exception e)
    {
        log.Error(e.Message, e);
        throw;
    }
}