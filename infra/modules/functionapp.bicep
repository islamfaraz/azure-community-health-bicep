// ============================================================================
// Function App Module
// ============================================================================

@description('Name prefix for resources')
param namePrefix string

@description('Azure region')
param location string

@description('Resource tags')
param tags object

@description('Unique suffix for globally unique names')
param uniqueSuffix string

@description('Application Insights instrumentation key')
param appInsightsInstrumentationKey string

@description('Application Insights connection string')
param appInsightsConnectionString string

@description('Storage account name for Function App')
param storageAccountName string

@description('Cosmos DB endpoint')
param cosmosDbEndpoint string

@description('Cosmos DB primary key')
@secure()
param cosmosDbKey string

@description('Event Hub name')
param eventHubName string

@description('Event Hub connection string')
@secure()
param eventHubConnectionString string

@description('Key Vault URI')
param keyVaultUri string

@description('Key Vault name for Key Vault references')
param keyVaultName string

// ============================================================================
// Resources
// ============================================================================

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: '${namePrefix}-asp'
  location: location
  tags: tags
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    reserved: true
  }
  kind: 'linux'
}

resource functionApp 'Microsoft.Web/sites@2023-12-01' = {
  name: 'func-${take(namePrefix, 15)}-${take(uniqueSuffix, 6)}'
  location: location
  tags: union(tags, { 'azd-service-name': 'health-api' })
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOTNET-ISOLATED|8.0'
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
      appSettings: [
        {
          name: 'AzureWebJobsStorage__accountName'
          value: storageAccountName
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${az.environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower('func-${namePrefix}')
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'CosmosDb__Endpoint'
          value: cosmosDbEndpoint
        }
        {
          name: 'CosmosDb__Key'
          value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=CosmosDbKey)'
        }
        {
          name: 'CosmosDb__DatabaseName'
          value: 'HealthPlatformDB'
        }
        {
          name: 'EventHub__ConnectionString'
          value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=EventHubConnectionString)'
        }
        {
          name: 'EventHub__Name'
          value: eventHubName
        }
        {
          name: 'KeyVault__Uri'
          value: keyVaultUri
        }
      ]
    }
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

// ============================================================================
// Outputs
// ============================================================================

output functionAppName string = functionApp.name
output functionAppId string = functionApp.id
output defaultHostName string = functionApp.properties.defaultHostName
output principalId string = functionApp.identity.principalId
