param name string
param location string
param environment string

// https://docs.microsoft.com/en-us/azure/templates/microsoft.managedidentity/userassignedidentities?tabs=bicep
resource userAssignedManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: name
  location: location
  tags: {
    EnvironmentName: environment
    GeneratedBy: 'symphony'
  }
}

output userAssignedManagedIdentityId string = userAssignedManagedIdentity.id
output userAssignedManagedIdentityPrincipalId string = userAssignedManagedIdentity.properties.principalId
