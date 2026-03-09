using '../main.bicep'

param environment = 'dev'
param location = 'eastus2'
param projectName = 'communityhealth'
param tags = {
  Environment: 'dev'
  Project: 'CommunityHealthPlatform'
  ManagedBy: 'Bicep'
  CostCenter: 'Development'
}
