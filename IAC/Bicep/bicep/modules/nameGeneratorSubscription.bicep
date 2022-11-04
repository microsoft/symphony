targetScope = 'subscription'

@maxLength(12)
param name string

@maxLength(1)
param delimiter string = '-'

@maxLength(6)
param prefix string = ''

@maxLength(6)
param suffix string = ''

@maxLength(6)
param uniqueToken string =  ''

@maxValue(6)
@minValue(0)
param suffixLength int = 3

param suffixGenerated bool = true

var outputPrefix = empty(prefix) ? name : '${prefix}${delimiter}${name}'
var outputSuffixTemp = suffixGenerated ? substring(uniqueString(uniqueToken,subscription().id,guid(outputPrefix)), 0, suffixLength) : suffix
var output = empty(outputSuffixTemp) ? outputPrefix : '${outputPrefix}${delimiter}${outputSuffixTemp}'

output name string = output
