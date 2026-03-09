// ============================================================================
// Event Hub Module
// ============================================================================

@description('Name prefix for resources')
param namePrefix string

@description('Azure region')
param location string

@description('Resource tags')
param tags object

@description('Environment name')
@allowed(['dev', 'staging', 'prod'])
param environment string

// ============================================================================
// Variables
// ============================================================================

var skuName = environment == 'prod' ? 'Standard' : 'Basic'
var skuCapacity = environment == 'prod' ? 2 : 1
var partitionCount = environment == 'prod' ? 8 : 2
var messageRetentionInDays = environment == 'prod' ? 7 : 1

// ============================================================================
// Resources
// ============================================================================

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2024-01-01' = {
  name: '${namePrefix}-evhns'
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: skuName
    capacity: skuCapacity
  }
  properties: {
    isAutoInflateEnabled: environment == 'prod'
    maximumThroughputUnits: environment == 'prod' ? 10 : 0
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
    zoneRedundant: environment == 'prod'
  }
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2024-01-01' = {
  parent: eventHubNamespace
  name: 'health-events'
  properties: {
    partitionCount: partitionCount
    messageRetentionInDays: messageRetentionInDays
  }
}

resource consumerGroup 'Microsoft.EventHub/namespaces/eventhubs/consumergroups@2024-01-01' = {
  parent: eventHub
  name: 'health-processor'
  properties: {}
}

resource sendAuthRule 'Microsoft.EventHub/namespaces/authorizationRules@2024-01-01' = {
  parent: eventHubNamespace
  name: 'SendPolicy'
  properties: {
    rights: ['Send']
  }
}

resource listenAuthRule 'Microsoft.EventHub/namespaces/authorizationRules@2024-01-01' = {
  parent: eventHubNamespace
  name: 'ListenPolicy'
  properties: {
    rights: ['Listen']
  }
}

// ============================================================================
// Outputs
// ============================================================================

output namespaceName string = eventHubNamespace.name
output eventHubName string = eventHub.name
output connectionString string = sendAuthRule.listKeys().primaryConnectionString
output namespaceId string = eventHubNamespace.id
