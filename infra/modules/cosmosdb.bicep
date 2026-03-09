// ============================================================================
// Cosmos DB Module
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

var throughput = environment == 'prod' ? 1000 : 400

// ============================================================================
// Resources
// ============================================================================

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-02-15-preview' = {
  name: '${namePrefix}-cosmos'
  location: location
  tags: tags
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: environment == 'prod'
      }
    ]
    enableAutomaticFailover: environment == 'prod'
    enableMultipleWriteLocations: false
    publicNetworkAccess: environment == 'prod' ? 'Disabled' : 'Enabled'
    disableKeyBasedMetadataWriteAccess: true
    backupPolicy: {
      type: 'Periodic'
      periodicModeProperties: {
        backupIntervalInMinutes: 240
        backupRetentionIntervalInHours: 720
        backupStorageRedundancy: environment == 'prod' ? 'Geo' : 'Local'
      }
    }
  }
}

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-02-15-preview' = {
  parent: cosmosAccount
  name: 'HealthPlatformDB'
  properties: {
    resource: {
      id: 'HealthPlatformDB'
    }
  }
}

resource healthRecordsContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-02-15-preview' = {
  parent: database
  name: 'HealthRecords'
  properties: {
    resource: {
      id: 'HealthRecords'
      partitionKey: {
        paths: ['/regionId']
        kind: 'Hash'
      }
      indexingPolicy: {
        automatic: true
        indexingMode: 'consistent'
        includedPaths: [{ path: '/*' }]
        excludedPaths: [{ path: '/"_etag"/?' }]
      }
      defaultTtl: -1
    }
    options: {
      throughput: throughput
    }
  }
}

resource vaccinationContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-02-15-preview' = {
  parent: database
  name: 'VaccinationRecords'
  properties: {
    resource: {
      id: 'VaccinationRecords'
      partitionKey: {
        paths: ['/facilityId']
        kind: 'Hash'
      }
      defaultTtl: -1
    }
    options: {
      throughput: throughput
    }
  }
}

resource facilityContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-02-15-preview' = {
  parent: database
  name: 'HealthFacilities'
  properties: {
    resource: {
      id: 'HealthFacilities'
      partitionKey: {
        paths: ['/district']
        kind: 'Hash'
      }
    }
    options: {
      throughput: throughput
    }
  }
}

resource alertsContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-02-15-preview' = {
  parent: database
  name: 'DiseaseAlerts'
  properties: {
    resource: {
      id: 'DiseaseAlerts'
      partitionKey: {
        paths: ['/alertType']
        kind: 'Hash'
      }
      defaultTtl: 2592000 // 30 days
    }
    options: {
      throughput: throughput
    }
  }
}

// ============================================================================
// Outputs
// ============================================================================

output accountName string = cosmosAccount.name
output endpoint string = cosmosAccount.properties.documentEndpoint
output databaseName string = database.name
output accountId string = cosmosAccount.id
