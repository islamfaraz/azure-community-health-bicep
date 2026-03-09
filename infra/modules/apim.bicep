// ============================================================================
// API Management Module
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

@description('Application Insights instrumentation key')
param appInsightsInstrumentationKey string

@description('Function App default host name')
param functionAppDefaultHostName string

// ============================================================================
// Variables
// ============================================================================

var skuName = environment == 'prod' ? 'Standard' : 'Developer'
var skuCapacity = 1

// ============================================================================
// Resources
// ============================================================================

resource apim 'Microsoft.ApiManagement/service@2023-09-01-preview' = {
  name: '${namePrefix}-apim'
  location: location
  tags: tags
  sku: {
    name: skuName
    capacity: skuCapacity
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherEmail: 'admin@communityhealth.org'
    publisherName: 'Community Health Platform'
  }
}

resource appInsightsLogger 'Microsoft.ApiManagement/service/loggers@2023-09-01-preview' = {
  parent: apim
  name: 'appinsights-logger'
  properties: {
    loggerType: 'applicationInsights'
    credentials: {
      instrumentationKey: appInsightsInstrumentationKey
    }
  }
}

resource healthApi 'Microsoft.ApiManagement/service/apis@2023-09-01-preview' = {
  parent: apim
  name: 'health-data-api'
  properties: {
    displayName: 'Health Data API'
    description: 'API for community health data collection and analytics'
    subscriptionRequired: true
    path: 'health'
    protocols: ['https']
    serviceUrl: 'https://${functionAppDefaultHostName}/api'
    apiType: 'http'
  }
}

resource getHealthRecords 'Microsoft.ApiManagement/service/apis/operations@2023-09-01-preview' = {
  parent: healthApi
  name: 'get-health-records'
  properties: {
    displayName: 'Get Health Records'
    method: 'GET'
    urlTemplate: '/records/{regionId}'
    templateParameters: [
      {
        name: 'regionId'
        type: 'string'
        required: true
      }
    ]
    responses: [
      {
        statusCode: 200
        description: 'Success'
      }
    ]
  }
}

resource postHealthRecord 'Microsoft.ApiManagement/service/apis/operations@2023-09-01-preview' = {
  parent: healthApi
  name: 'post-health-record'
  properties: {
    displayName: 'Submit Health Record'
    method: 'POST'
    urlTemplate: '/records'
    responses: [
      {
        statusCode: 201
        description: 'Created'
      }
    ]
  }
}

resource getVaccinationStats 'Microsoft.ApiManagement/service/apis/operations@2023-09-01-preview' = {
  parent: healthApi
  name: 'get-vaccination-stats'
  properties: {
    displayName: 'Get Vaccination Statistics'
    method: 'GET'
    urlTemplate: '/vaccinations/{facilityId}/stats'
    templateParameters: [
      {
        name: 'facilityId'
        type: 'string'
        required: true
      }
    ]
    responses: [
      {
        statusCode: 200
        description: 'Success'
      }
    ]
  }
}

resource getDiseaseAlerts 'Microsoft.ApiManagement/service/apis/operations@2023-09-01-preview' = {
  parent: healthApi
  name: 'get-disease-alerts'
  properties: {
    displayName: 'Get Disease Alerts'
    method: 'GET'
    urlTemplate: '/alerts'
    responses: [
      {
        statusCode: 200
        description: 'Success'
      }
    ]
  }
}

resource rateLimitPolicy 'Microsoft.ApiManagement/service/apis/policies@2023-09-01-preview' = {
  parent: healthApi
  name: 'policy'
  properties: {
    value: '''
      <policies>
        <inbound>
          <base />
          <rate-limit calls="100" renewal-period="60" />
          <cors>
            <allowed-origins>
              <origin>https://portal.communityhealth.org</origin>
            </allowed-origins>
            <allowed-methods>
              <method>GET</method>
              <method>POST</method>
            </allowed-methods>
          </cors>
        </inbound>
        <backend>
          <base />
        </backend>
        <outbound>
          <base />
        </outbound>
        <on-error>
          <base />
        </on-error>
      </policies>
    '''
    format: 'xml'
  }
}

// ============================================================================
// Outputs
// ============================================================================

output apimName string = apim.name
output gatewayUrl string = apim.properties.gatewayUrl
output apimId string = apim.id
