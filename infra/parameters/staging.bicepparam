using '../main.bicep'

param environment = 'staging'
param location = 'eastus2'
param projectName = 'communityhealth'
param tags = {
  Environment: 'staging'
  Project: 'CommunityHealthPlatform'
  ManagedBy: 'Bicep'
  CostCenter: 'Staging'
}
