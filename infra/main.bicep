// ============================================================================
// Azure Community Health Platform - Main Bicep Template
// ============================================================================
// Description: Deploys a serverless health data analytics platform for
//              community health organizations to collect, analyze, and
//              visualize public health data (vaccination rates, disease
//              trends, facility utilization).
// ============================================================================

targetScope = 'resourceGroup'

// ============================================================================
// Parameters
// ============================================================================

@description('Environment name (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environment string

@description('Azure region for resource deployment')
param location string = resourceGroup().location

@description('Project name used for resource naming')
param projectName string = 'commhealth'

@description('Tags to apply to all resources')
param tags object = {
  Project: 'CommunityHealthPlatform'
  Environment: environment
  ManagedBy: 'Bicep'
}

// ============================================================================
// Variables
// ============================================================================

var uniqueSuffix = uniqueString(resourceGroup().id)
var namePrefix = '${projectName}-${environment}'

// ============================================================================
// Modules
// ============================================================================

module appInsights 'modules/appinsights.bicep' = {
  name: 'deploy-appinsights'
  params: {
    namePrefix: namePrefix
    location: location
    tags: tags
  }
}

module keyVault 'modules/keyvault.bicep' = {
  name: 'deploy-keyvault'
  params: {
    namePrefix: namePrefix
    location: location
    tags: tags
    uniqueSuffix: uniqueSuffix
  }
}

module storage 'modules/storage.bicep' = {
  name: 'deploy-storage'
  params: {
    namePrefix: namePrefix
    location: location
    tags: tags
    uniqueSuffix: uniqueSuffix
  }
}

module cosmosDb 'modules/cosmosdb.bicep' = {
  name: 'deploy-cosmosdb'
  params: {
    namePrefix: namePrefix
    location: location
    tags: tags
    environment: environment
  }
}

module eventHub 'modules/eventhub.bicep' = {
  name: 'deploy-eventhub'
  params: {
    namePrefix: namePrefix
    location: location
    tags: tags
    environment: environment
  }
}

module functionApp 'modules/functionapp.bicep' = {
  name: 'deploy-functionapp'
  params: {
    namePrefix: namePrefix
    location: location
    tags: tags
    uniqueSuffix: uniqueSuffix
    appInsightsInstrumentationKey: appInsights.outputs.instrumentationKey
    appInsightsConnectionString: appInsights.outputs.connectionString
    storageAccountName: storage.outputs.storageAccountName
    cosmosDbEndpoint: cosmosDb.outputs.endpoint
    cosmosDbKey: cosmosDb.outputs.endpoint // Placeholder — actual key stored in Key Vault
    eventHubName: eventHub.outputs.eventHubName
    eventHubConnectionString: eventHub.outputs.connectionString
    keyVaultUri: keyVault.outputs.vaultUri
    keyVaultName: keyVault.outputs.keyVaultName
  }
}

module apim 'modules/apim.bicep' = {
  name: 'deploy-apim'
  params: {
    namePrefix: namePrefix
    location: location
    tags: tags
    environment: environment
    appInsightsInstrumentationKey: appInsights.outputs.instrumentationKey
    functionAppDefaultHostName: functionApp.outputs.defaultHostName
  }
}

// ============================================================================
// Outputs
// ============================================================================

output resourceGroupName string = resourceGroup().name
output appInsightsName string = appInsights.outputs.appInsightsName
output cosmosDbEndpoint string = cosmosDb.outputs.endpoint
output functionAppName string = functionApp.outputs.functionAppName
output apimGatewayUrl string = apim.outputs.gatewayUrl
output eventHubNamespace string = eventHub.outputs.namespaceName
output storageAccountName string = storage.outputs.storageAccountName
output keyVaultName string = keyVault.outputs.keyVaultName
