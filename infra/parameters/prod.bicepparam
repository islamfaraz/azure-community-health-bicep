using '../main.bicep'

param environment = 'prod'
param location = 'eastus2'
param projectName = 'communityhealth'
param tags = {
  Environment: 'prod'
  Project: 'CommunityHealthPlatform'
  ManagedBy: 'Bicep'
  CostCenter: 'Production'
}
